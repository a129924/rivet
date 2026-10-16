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
import uuid
from build_probe import build, identity, public_identity


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--pem-import', action='store_true', help='One transport-format check; no policy changes')
    parser.add_argument('--measure', action='store_true', help='Also measure fake OAuth items after signing preflight')
    args = parser.parse_args()
    scratch = Path(tempfile.mkdtemp(prefix='rivet-E005-selfsigned-'))
    os.chmod(scratch, 0o700)
    app = scratch / 'KeychainProbe.app'
    keychain_path = scratch / 'signing.keychain'
    label = 'Rivet-E005-' + str(uuid.uuid4())
    primary, negative = str(uuid.uuid4()), str(uuid.uuid4())
    report = {'startedUTC': now(), 'backend': 'legacy', 'signing': 'isolated self-signed certificate',
              'paidQualificationRequired': False, 'measurementRequested': args.measure,
              'importFormat': 'PEM' if args.pem_import else 'PKCS12',
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

    def setup(stage, argv):
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
            raise RuntimeError(stage + 'Failed')

    def signed_build(rebuilt):
        build(app, rebuilt=rebuilt)
        setup('signRebuilt' if rebuilt else 'signFirst',
              ['/usr/bin/codesign', '--force', '--sign', label, '--keychain', str(keychain_path),
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

    def command(mode, namespace):
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
                deleted = command('delete', namespace)
                absent = command('read-absent', namespace) if deleted else False
            except Exception:
                deleted, absent = False, False
            report['cleanup'].append({'namespace': namespace, 'deleteSucceeded': deleted,
                                      'absenceConfirmed': absent})
        clean_items = all(x['absenceConfirmed'] for x in report['cleanup'])
        # Do not destroy the remedial signing identity if OAuth cleanup failed.
        if clean_items and keychain.value:
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
        if clean_items and report['privateKeychainAbsent']:
            shutil.rmtree(scratch)
        report['secretScratchAbsent'] = not scratch.exists()
        report['cleanupComplete'] = clean_items and report['privateKeychainAbsent'] and report['secretScratchAbsent'] and globals_clean
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
