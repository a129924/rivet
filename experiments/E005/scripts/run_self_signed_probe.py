#!/usr/bin/env python3
"""Authorized isolated certificate trial; default is signing preflight only."""
import argparse
import ctypes
import datetime
import hashlib
import json
import os
import re
from pathlib import Path
import secrets
import shutil
import signal
import subprocess
import tempfile
import time
import uuid
from build_probe import build, identity, public_identity


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--pem-import', action='store_true', help='One transport-format check; no policy changes')
    parser.add_argument('--signing-selector', choices=('common-name', 'certificate-sha1'), default='common-name', help='Select the same experiment identity by certificate hash; never changes trust or search list')
    parser.add_argument('--diagnose', action='store_true', help='Read only this trial keychain identity counts and known errors')
    parser.add_argument('--trust-code-signing', action='store_true', help='Explicitly authorized temporary user-domain codeSign trust only')
    parser.add_argument('--observer-gate', type=Path, help='External same-run Human ready gate; must initially be absent')
    parser.add_argument('--ready-notice', type=Path, help='External non-secret preflight completion notice')
    parser.add_argument('--measurement-deadline-utc', help='Hard stop for waiting/new measurements, ISO UTC')
    parser.add_argument('--measure', action='store_true', help='Also measure fake OAuth items after signing preflight')
    args = parser.parse_args()
    if args.signing_selector == 'certificate-sha1' and not (args.trust_code_signing and args.diagnose):
        parser.error('certificate hash selection requires the limited-trust explicit-keychain diagnostic path')
    if args.trust_code_signing and not args.pem_import:
        parser.error('limited trust trial requires the established PEM path')
    measurement_deadline = None
    if args.trust_code_signing and args.measure:
        if not args.observer_gate or not args.ready_notice or not args.measurement_deadline_utc:
            parser.error('limited-trust measurement requires post-preflight observer gate, notice and deadline')
        if args.observer_gate.exists() or args.ready_notice.exists():
            parser.error('use fresh external gate and notice paths for this run')
        measurement_deadline = datetime.datetime.fromisoformat(args.measurement_deadline_utc)
        if measurement_deadline.tzinfo is None or measurement_deadline.utcoffset() != datetime.timedelta(0):
            parser.error('measurement deadline must explicitly be UTC')
    scratch = Path(tempfile.mkdtemp(prefix='rivet-E005-selfsigned-'))
    os.chmod(scratch, 0o700)
    app = scratch / 'KeychainProbe.app'
    keychain_path = scratch / 'signing.keychain'
    label = 'Rivet-E005-' + str(uuid.uuid4())
    selector_value = label
    primary, negative = str(uuid.uuid4()), str(uuid.uuid4())
    report = {'startedUTC': now(), 'backend': 'legacy', 'signing': 'isolated self-signed certificate',
              'paidQualificationRequired': False, 'measurementRequested': args.measure,
              'importFormat': 'PEM' if args.pem_import else 'PKCS12',
              'diagnosticRequested': args.diagnose,
              'signingSelector': args.signing_selector,
              'limitedTrustRequested': args.trust_code_signing, 'humanReadyForMeasurement': False,
              'primaryNamespace': primary, 'negativeNamespace': negative,
              'experimentStatus': '無法判定', 'validationTaskComplete': False,
              'promptObservation': 'unobserved; separate human receipt required',
              'commands': [], 'cleanup': [], 'setupCommands': [],
              'sourceSHA256': {name: hashlib.sha256((Path(__file__).parent / name).read_bytes()).hexdigest()
                               for name in ('build_probe.py', 'run_self_signed_probe.py')}}
    security = ctypes.CDLL('/System/Library/Frameworks/Security.framework/Security')
    security.SecKeychainCreate.argtypes = [ctypes.c_char_p, ctypes.c_uint32, ctypes.c_void_p,
                                          ctypes.c_bool, ctypes.c_void_p, ctypes.POINTER(ctypes.c_void_p)]
    security.SecKeychainCreate.restype = ctypes.c_int32
    security.SecKeychainDelete.argtypes = [ctypes.c_void_p]
    security.SecKeychainDelete.restype = ctypes.c_int32
    keychain = ctypes.c_void_p()
    attempted = []
    executable = None
    snapshots = None
    trust_attempted = False
    trust_baseline_absent = False
    trust_helper = scratch / 'trust-probe'
    certificate_der = scratch / 'certificate.der'

    def stop(signum, _frame):
        raise RuntimeError('controlledSignalStop:' + signal.Signals(signum).name)
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    def settings():
        values = []
        for operation in ('default-keychain', 'list-keychains'):
            result = subprocess.run(['security', operation], capture_output=True, timeout=10)
            if result.returncode:
                raise RuntimeError('settingsSnapshotFailed')
            values.append(result.stdout)
        return values  # Private paths stay in memory only.

    def trust_command(mode, timeout=10):
        if mode == 'add-code-signing' and measurement_deadline is not None and datetime.datetime.now(datetime.timezone.utc) >= measurement_deadline:
            raise RuntimeError('trustAddDeadlineReached')
        entry = {'operation': mode, 'startedUTC': now()}
        report.setdefault('trustCommands', []).append(entry)
        try:
            result = subprocess.run([str(trust_helper), mode, str(certificate_der)],
                                    capture_output=True, text=True, timeout=timeout)
            entry['exitCode'] = result.returncode
            entry['output'] = json.loads(result.stdout)
            return entry['output'], result.returncode == 0
        except subprocess.TimeoutExpired:
            entry['timedOut'] = True
            raise RuntimeError('trustCommandTimeout:' + mode)
        finally:
            entry['finishedUTC'] = now()

    def trust_absent(state):
        return all(state.get(domain, {}).get('absent') is True for domain in ('user', 'admin', 'system'))

    def known_diagnostics(data):
        # Return only exact public error phrases, never arbitrary stderr or identity names.
        phrases = (b'no identity found', b'no identities found', b'ambiguous',
                   b'The specified item could not be found in the keychain',
                   b'User interaction is not allowed', b'The user name or passphrase you entered is not correct',
                   b'CSSMERR_TP_NOT_TRUSTED', b'CSSMERR_TP_INVALID_CERTIFICATE',
                   b'CSSMERR_TP_CERT_EXPIRED', b'CSSMERR_TP_CERT_NOT_VALID_YET',
                   b'errSecInternalComponent', b'errSecInteractionNotAllowed',
                   b'unable to build chain to self-signed root', b'invalid or unsupported format',
                   b'code object is not signed at all', b'replacing existing signature',
                   b'certificate is not trusted', b'identity not found', b'keychain is locked')
        return [phrase.decode('ascii') for phrase in phrases if phrase.lower() in data.lower()]

    def setup(stage, argv):
        if measurement_deadline is not None and datetime.datetime.now(datetime.timezone.utc) >= measurement_deadline:
            raise RuntimeError('preflightDeadlineReached')
        result = subprocess.run(argv, capture_output=True, timeout=20)
        entry = {'stage': stage, 'exitCode': result.returncode, 'stderrPresent': bool(result.stderr)}
        report['setupCommands'].append(entry)
        if result.returncode:
            # Never persist raw diagnostics or attempt trust/ACL/partition-list changes.
            entry['certificateTrustError'] = b'CSSMERR_TP_NOT_TRUSTED' in result.stderr
            entry['internalComponentError'] = b'errSecInternalComponent' in result.stderr
            entry['macVerificationFailed'] = b'MAC verification failed' in result.stderr
            entry['unsupportedFormat'] = b'Unknown format' in result.stderr or b'unsupported' in result.stderr.lower()
            entry['knownSecurityStatus'] = re.findall(rb'(?<![0-9])-(?:25|67)[0-9]{3,4}(?![0-9])', result.stderr)
            entry['knownSecurityStatus'] = [x.decode('ascii') for x in entry['knownSecurityStatus']]
            entry['knownDiagnostics'] = known_diagnostics(result.stdout + result.stderr)
            raise RuntimeError(stage + 'Failed')

    def signed_build(rebuilt):
        build(app, rebuilt=rebuilt)
        setup('signRebuilt' if rebuilt else 'signFirst',
              ['/usr/bin/codesign', '--force', '--sign', selector_value, '--keychain', str(keychain_path),
               '--timestamp=none', str(app)])
        return identity(app)

    def restore(name, expected_hash):
        if app.exists():
            shutil.rmtree(app)
        shutil.copytree(scratch / name, app)
        candidate = app / 'Contents/MacOS/keychain-probe'
        if hashlib.sha256(candidate.read_bytes()).hexdigest() != expected_hash:
            raise RuntimeError('restoredBinaryHashMismatch')
        return candidate

    def command(mode, namespace, cleanup=False):
        if measurement_deadline is not None and not cleanup and datetime.datetime.now(datetime.timezone.utc) >= measurement_deadline:
            raise RuntimeError('measurementDeadlineReached')
        entry = {'mode': mode, 'namespace': namespace, 'startedUTC': now(), 'promptCount': None,
                 'actualBinarySHA256': hashlib.sha256(executable.read_bytes()).hexdigest()}
        report['commands'].append(entry)
        print('probe: ' + mode, flush=True)
        try:
            result = subprocess.run([str(executable), mode, 'legacy', namespace], capture_output=True,
                                    text=True, timeout=20)
            entry.update(exitCode=result.returncode, stderrPresent=bool(result.stderr),
                         output=[json.loads(line) for line in result.stdout.splitlines() if line])
            return result.returncode == 0
        except subprocess.TimeoutExpired:
            entry['timedOut'] = True
            return False
        finally:
            entry['finishedUTC'] = now()

    try:
        snapshots = settings()
        password = secrets.token_bytes(32).hex().encode()
        status = security.SecKeychainCreate(os.fsencode(keychain_path), len(password), password,
                                             False, None, ctypes.byref(keychain))
        report['keychainCreateStatus'] = status
        del password
        if status:
            raise RuntimeError('privateKeychainCreateFailed')
        current = settings()
        report['settingsAfterCreate'] = {'defaultEqual': current[0] == snapshots[0],
                                         'searchListEqual': current[1] == snapshots[1]}
        if current != snapshots:
            raise RuntimeError('globalSettingsChangedStop')
        config = scratch / 'certificate.cnf'
        config.write_text('[req]\nprompt=no\ndistinguished_name=dn\nx509_extensions=ext\n'
                          '[dn]\nCN=' + label + '\n[ext]\nbasicConstraints=critical,CA:TRUE\n'
                          'keyUsage=critical,digitalSignature,keyCertSign\nextendedKeyUsage=codeSigning\n')
        # Secret material remains only within the 0700 scratch; no secret argv or stdout.
        setup('generateCertificate', ['openssl', 'req', '-new', '-x509', '-newkey', 'rsa:2048',
              '-noenc', '-days', '1', '-config', str(config), '-keyout', str(scratch / 'key.pem'),
              '-out', str(scratch / 'cert.pem')])
        os.chmod(scratch / 'key.pem', 0o600)
        if args.pem_import:
            setup('encodePrivateKey', ['openssl', 'pkey', '-in', str(scratch / 'key.pem'),
                  '-traditional', '-out', str(scratch / 'import-key.pem')])
            os.chmod(scratch / 'import-key.pem', 0o600)
            setup('importCertificate', ['security', 'import', str(scratch / 'cert.pem'), '-k',
                  str(keychain_path), '-t', 'cert', '-f', 'openssl'])
            setup('importPrivateKey', ['security', 'import', str(scratch / 'import-key.pem'), '-k',
                  str(keychain_path), '-t', 'priv', '-f', 'openssl', '-x', '-T', '/usr/bin/codesign'])
        else:
            setup('packageCertificate', ['openssl', 'pkcs12', '-export', '-legacy', '-inkey',
                  str(scratch / 'key.pem'), '-in', str(scratch / 'cert.pem'), '-name', label,
                  '-out', str(scratch / 'identity.p12'), '-passout', 'pass:'])
            os.chmod(scratch / 'identity.p12', 0o600)
            setup('importCertificate', ['security', 'import', str(scratch / 'identity.p12'), '-k',
                  str(keychain_path), '-f', 'pkcs12', '-P', '', '-x', '-T', '/usr/bin/codesign'])
        if args.trust_code_signing:
            helper_source = Path(__file__).resolve().parents[1] / 'Sources/TrustProbe.swift'
            report['trustHelperSourceSHA256'] = hashlib.sha256(helper_source.read_bytes()).hexdigest()
            setup('buildTrustHelper', ['swiftc', '-swift-version', '6', '-parse-as-library',
                  '-module-cache-path', str(scratch / 'ModuleCache'), str(helper_source), '-o', str(trust_helper)])
            setup('encodeCertificateDER', ['openssl', 'x509', '-in', str(scratch / 'cert.pem'),
                  '-outform', 'DER', '-out', str(certificate_der)])
            if args.signing_selector == 'certificate-sha1':
                selector_value = hashlib.sha1(certificate_der.read_bytes()).hexdigest()
            baseline, ok = trust_command('inspect')
            trust_baseline_absent = ok and trust_absent(baseline)
            report['trustBaselineAbsent'] = trust_baseline_absent
            if not trust_baseline_absent:
                raise RuntimeError('trustBaselineNotAbsent')
            # Register ownership before add, including timeout/partial-add failures.
            trust_attempted = True
            add_result, added = trust_command('add-code-signing', timeout=60)
            if add_result.get('mutationAttempted') is False:
                trust_attempted = False
                raise RuntimeError('helperDeclinedTrustMutation')
            added_state, inspected = trust_command('inspect')
            limited = inspected and added_state.get('user', {}).get('codeSigningOnly') is True and all(
                added_state.get(domain, {}).get('absent') is True for domain in ('admin', 'system'))
            report['limitedTrustReadbackVerified'] = limited
            if not added or not limited:
                raise RuntimeError('limitedTrustAddOrReadbackFailed')
        if args.diagnose:
            # An explicit target prevents any global identity inventory.
            result = subprocess.run(['security', 'find-identity', '-p', 'codesigning', str(keychain_path)],
                                    capture_output=True, timeout=10)
            data = result.stdout + result.stderr
            counts = {}
            for name, pattern in (('matching', rb'^\s*(\d+) identities found\s*$'),
                                  ('valid', rb'^\s*(\d+) valid identities found\s*$')):
                match = re.search(pattern, data, re.MULTILINE)
                counts[name] = int(match.group(1)) if match else None
            report['isolatedIdentityDiagnostic'] = {'exitCode': result.returncode,
                'counts': counts, 'knownDiagnostics': known_diagnostics(data), 'explicitPrivateKeychainOnly': True}
            if args.signing_selector == 'certificate-sha1':
                hashes = re.findall(rb'^\s*\d+\)\s+([0-9a-fA-F]{40})\b', data, re.MULTILINE)
                matched = selector_value.lower() in {value.decode('ascii').lower() for value in hashes}
                report['selectedCertificateMatchedIsolatedIdentity'] = matched
                if not matched:
                    raise RuntimeError('selectedCertificateNotInIsolatedIdentityDiagnostic')
        first = signed_build(False)
        report['hostFirst'] = public_identity(first)
        shutil.copytree(app, scratch / 'First.app')
        second = signed_build(True)
        report['hostSecond'] = public_identity(second)
        shutil.copytree(app, scratch / 'Second.app')
        checks = {'binaryChanged': first['binarySHA256'] != second['binarySHA256'],
                  'designatedRequirementEqual': bool(first['_requirement']) and first['_requirement'] == second['_requirement'],
                  'signaturesValid': first['signatureValid'] and second['signatureValid'],
                  'certificateBacked': not first['adHoc'] and not second['adHoc'],
                  'entitlementsEqual': first['entitlementsReadSucceeded'] and second['entitlementsReadSucceeded'] and first['_entitlements'] == second['_entitlements'],
                  'bundleIdentifierEqual': first['_bundleID'] == second['_bundleID'],
                  'profileAbsent': not first['profilePresent'] and not second['profilePresent'],
                  'hostPathEqual': True}
        report['rebuildComparison'] = checks
        report['signingPreflightComplete'] = all(checks.values())
        if not report['signingPreflightComplete']:
            raise RuntimeError('stableSigningPreflightFailed')
        if args.measure:
            if args.trust_code_signing:
                notice = {'phase': 'awaitingHumanT03Ready', 'namespace': primary,
                          'recordedUTC': now(), 'rebuildComparison': checks,
                          'hostFirst': public_identity(first), 'hostSecond': public_identity(second),
                          'limitedTrustReadbackVerified': report['limitedTrustReadbackVerified']}
                args.ready_notice.parent.mkdir(parents=True, exist_ok=True)
                args.ready_notice.write_text(json.dumps(notice, ensure_ascii=False, indent=2) + '\n')
                print('preflight complete; waiting for same-run Human T03 readiness', flush=True)
                while not args.observer_gate.exists():
                    if datetime.datetime.now(datetime.timezone.utc) >= measurement_deadline:
                        raise RuntimeError('observerReadyDeadlineReached')
                    time.sleep(0.25)
                gate = json.loads(args.observer_gate.read_text())
                if gate.get('namespace') != primary or gate.get('humanReady') is not True:
                    raise RuntimeError('observerGateNotForThisRun')
                if datetime.datetime.now(datetime.timezone.utc) >= measurement_deadline:
                    raise RuntimeError('measurementDeadlineReachedBeforeWrite')
                report['humanReadyForMeasurement'] = True
                report['humanReadyAcceptedUTC'] = now()
            executable = restore('First.app', first['binarySHA256'])
            attempted.append(primary)
            if not command('write-a', primary):
                raise RuntimeError('writeAFailed')
            if not command('read-a', primary) or not command('read-a', primary):
                raise RuntimeError('freshReadAFailed')
            report['T02Data'] = '成功'
            executable = restore('Second.app', second['binarySHA256'])
            report['T03Data'] = '成功' if command('read-a', primary) else '失敗'
            if report['T03Data'] != '成功':
                raise RuntimeError('rebuiltReadAFailed')
            if not command('replace-b', primary) or not command('read-b', primary):
                raise RuntimeError('replaceBFailed')
            report['T04Data'] = '成功'
            absent = command('read-absent', negative)
            attempted.append(negative)
            invalid_write = command('write-invalid', negative)
            invalid_read = command('read-invalid', negative) if invalid_write else False
            report['T05AbsentAndMalformed'] = '成功' if absent and invalid_write and invalid_read else '失敗'
    except Exception as error:
        report['stopReason'] = str(error) if isinstance(error, RuntimeError) else type(error).__name__
        if isinstance(error, subprocess.TimeoutExpired):
            report['stopReason'] = 'subprocessTimeout: no settings bypass attempted'
    finally:
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        # If a new binary cannot read, the writer remains available for exact cleanup.
        if attempted and (scratch / 'First.app').exists():
            try:
                executable = restore('First.app', report['hostFirst']['binarySHA256'])
            except Exception:
                report['cleanupHostRestoreFailed'] = True
        for namespace in attempted:
            try:
                deleted = command('delete', namespace, cleanup=True)
                absent = command('read-absent', namespace, cleanup=True) if deleted else False
            except Exception:
                deleted, absent = False, False
            report['cleanup'].append({'namespace': namespace, 'deleteSucceeded': deleted,
                                      'absenceConfirmed': absent})
        clean_items = all(x['absenceConfirmed'] for x in report['cleanup'])
        # A pre-existing/unknown baseline is never ours to remove.
        trust_clean = True
        if trust_baseline_absent and trust_attempted:
            trust_clean = False
            try:
                _, removed = trust_command('remove-user', timeout=60)
                removed_state, inspected = trust_command('inspect')
                trust_clean = removed and inspected and trust_absent(removed_state)
            except Exception:
                report['trustCleanupOperationFailed'] = True
            report['trustRemovalVerifiedAbsent'] = trust_clean
        report['trustCleanupComplete'] = trust_clean
        # Keep exact-certificate recovery material if trust removal/verification failed.
        if clean_items and trust_clean and keychain.value:
            report['keychainDeleteStatus'] = security.SecKeychainDelete(keychain)
        report['privateKeychainAbsent'] = not keychain_path.exists() and not Path(str(keychain_path) + '-db').exists()
        if snapshots is not None:
            try:
                final = settings()
                report['settingsAfterCleanup'] = {'defaultEqual': final[0] == snapshots[0],
                                                   'searchListEqual': final[1] == snapshots[1]}
            except Exception:
                report['settingsAfterCleanup'] = {'snapshotFailed': True}
        globals_clean = report.get('settingsAfterCleanup') == {'defaultEqual': True, 'searchListEqual': True}
        if clean_items and trust_clean and report['privateKeychainAbsent']:
            shutil.rmtree(scratch)
        report['secretScratchAbsent'] = not scratch.exists()
        report['cleanupComplete'] = clean_items and trust_clean and report['privateKeychainAbsent'] and report['secretScratchAbsent'] and globals_clean
        if not report['cleanupComplete']:
            report['recoveryRequired'] = {'experimentCertificateLabel': label,
                'retainExactCertificateAndPrivateScratch': scratch.exists(),
                'reason': 'see individual trust, OAuth and keychain cleanup fields'}
        report['validationTaskComplete'] = report['cleanupComplete'] and (report.get('signingPreflightComplete', False) if not args.measure else all(report.get(k) == '成功' for k in ('T02Data', 'T03Data', 'T04Data', 'T05AbsentAndMalformed')))
        report['finishedUTC'] = now()
        report['limitations'] = ['human prompt receipt required for UX; historical zero prompts do not cover this host',
                                 'DPK free profile not verified', 'true denial not observed',
                                 'SIGKILL, process crash and host failure cannot guarantee cleanup',
                                 'self-signed identity deleted after this trial; future builds need a retained stable identity']
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: report.get(k) for k in ('signingPreflightComplete', 'cleanupComplete', 'validationTaskComplete', 'stopReason')}))
    return 0 if report['validationTaskComplete'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
