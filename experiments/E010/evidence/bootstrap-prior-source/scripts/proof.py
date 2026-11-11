"""Selected-material verifier / fixed App launcher. Imported live only after manifest+grants.
No inventory, signing, provisioning, trust changes, or fallback. Never prints command output.
"""
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import signal
import subprocess
import tempfile
import time
import uuid

from continuity import (Rejected, UTC, FIELDS, Run, authorize, canonical, digest, exclusive,
                        file_hash, private_root, public_result, read, safe, stamp, utc)


def source_hashes():
    root = Path(__file__).resolve().parents[1]
    paths = [p for folder in ('Sources', 'Resources', 'scripts', 'Tests', 'DPKContinuityProbe.xcodeproj')
             for p in (root/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    return {str(p.relative_to(root)): file_hash(p) for p in sorted(paths)}


def covers(pattern, value):
    return isinstance(pattern, str) and (pattern == value or
        (pattern.endswith('*') and pattern.count('*') == 1 and value.startswith(pattern[:-1])))


def app_hash(app):
    app = Path(app)
    if app.is_symlink() or not app.is_dir() or any(p.is_symlink() for p in app.rglob('*')):
        raise Rejected('selectedAppPathRejected')
    return digest(canonical({str(p.relative_to(app)): file_hash(p) for p in sorted(app.rglob('*')) if p.is_file()}))


def validate_asset(asset, manifest, now, baseline=None, phase='p0'):
    if asset.get('synthetic') is not manifest['synthetic']: raise Rejected('syntheticProofRejected')
    if asset.get('hostBindingSHA256') != manifest.get('hostBindingSHA256'): raise Rejected('hostBindingChanged')
    identifier = manifest['bundleIdentifier']; ent = asset['entitlements']; group = ent.get('com.apple.application-identifier')
    profile = asset['profile']; allowed = profile.get('Entitlements', {})
    if (not isinstance(group, str) or '*' in group or not group.endswith('.'+identifier) or
            ent.get('keychain-access-groups') != [group] or asset['bundleIdentifier'] != identifier or
            group[:-(len(identifier)+1)] not in profile.get('ApplicationIdentifierPrefix', [])):
        raise Rejected('completeGroupRejected')
    if (not covers(allowed.get('com.apple.application-identifier'), group) or
            not any(covers(x, group) for x in allowed.get('keychain-access-groups', []))):
        raise Rejected('profileGroupNotAuthorized')
    if (asset['device'] not in profile.get('ProvisionedDevices', []) or
            (profile.get('Platform') and 'OSX' not in profile['Platform']) or
            not asset.get('profileSignatureVerified') or not asset.get('certificateInProfile') or
            not asset.get('appleDevelopmentChainVerified')): raise Rejected('profileBindingRejected')
    created, expiry = stamp(asset['profileCreationUTC']), stamp(asset['profileExpiryUTC'])
    if created > now or stamp(asset['certificateNotBeforeUTC']) > now or stamp(asset['certificateNotAfterUTC']) <= now or stamp(asset['certificateNotAfterUTC']) < stamp(manifest['globalDeadlineUTC']) + dt.timedelta(minutes=35):
        raise Rejected('certificateOrCreationRejected')
    if stamp(asset['certificateNotAfterUTC']) != stamp(manifest['certificateNotAfterUTC']): raise Rejected('selectedCertificateDateChanged')
    if asset['sourceSHA256'] != manifest['sourceSHA256']: raise Rejected('frozenSourceChanged')
    if phase == 'expired':
        if not baseline or now < expiry or asset['profileSHA256'] != baseline['profileSHA256'] or asset['appSHA256'] != baseline['appSHA256']:
            raise Rejected('originalNaturalExpiryProofRequired')
    elif expiry <= now or (phase != 'p0' and expiry < now+dt.timedelta(minutes=35)):
        raise Rejected('validProfileRequired')
    if phase == 'p0' and expiry != stamp(manifest['p0ExpiryUTC']): raise Rejected('actualP0DateDiffersFromManifest')
    if baseline:
        for key in ('certificateSHA256', 'bundleIdentifier', 'entitlements', 'sourceSHA256', 'device', 'hostBindingSHA256'):
            if asset[key] != baseline[key]: raise Rejected('profileOnlyControlChanged')
        if phase == 'p1':
            if asset['profileSHA256'] == baseline['profileSHA256'] or created <= stamp(baseline['profileCreationUTC']) or expiry <= stamp(baseline['profileExpiryUTC']):
                raise Rejected('profileDidNotChange')
        if phase == 'rebuilt' and (asset['profileSHA256'] != baseline['profileSHA256'] or asset['executableSHA256'] == baseline['executableSHA256'] or asset['buildMarker'] != 'rebuilt'):
            raise Rejected('genuineRebuildRequired')
    if phase in ('p0', 'p1') and asset['buildMarker'] != 'initial': raise Rejected('baselineMarkerRequired')
    return group


def command(args):
    p = subprocess.run(args, capture_output=True, timeout=30)
    if p.returncode: raise Rejected('selectedMaterialVerificationFailed')
    return p.stdout, p.stderr


def inspect_selected(selection, run, allow_expired=False):
    # This function is never reached from preparation/default CLI or a synthetic Run.
    if run.synthetic: raise Rejected('mockCannotInspectLiveAssets')
    authorize(run.root, run.manifest, utc(), False)
    if not selection.get('humanFreePersonalTeamStatement') or not selection.get('humanSourceAndMarkerStatement'):
        raise Rejected('humanSelectedMaterialStatementRequired')
    if os.getuid() == 0 or os.stat('/dev/console').st_uid != os.getuid(): raise Rejected('guiUserRequired')
    source = Path(selection['sourceRoot'])
    for relative, sha in run.manifest['sourceSHA256'].items():
        # Source/config snapshot is selected explicitly; no account or profile-directory scan.
        if relative.startswith(('Sources/', 'Resources/')) and file_hash(source/relative) != sha:
            raise Rejected('selectedCompiledSourceChanged')
    app = Path(selection['appPath'])
    app_sha = app_hash(app)
    info = plistlib.loads((app/'Contents/Info.plist').read_bytes())
    name = info.get('CFBundleExecutable')
    if not isinstance(name, str) or '/' in name or name in ('.', '..'): raise Rejected('selectedExecutableRejected')
    executable = app/'Contents/MacOS'/name
    command(['/usr/bin/codesign', '--verify', '--strict', '--verbose=0', str(app)])
    out, _ = command(['/usr/bin/codesign', '-d', '--entitlements', ':-', str(app)])
    begin = out.find(b'<?xml')
    if begin < 0: raise Rejected('entitlementsMissing')
    ent = plistlib.loads(out[begin:])
    _, detail = command(['/usr/bin/codesign', '-d', '-vvv', str(app)])
    if b'Authority=Apple Development:' not in detail or b'Signature=adhoc' in detail: raise Rejected('appleDevelopmentRequired')
    out, err = command(['/usr/bin/codesign', '-d', '-r-', str(app)])
    match = re.search(r'designated => (.+)', (out+err).decode(errors='replace'))
    if not match: raise Rejected('designatedRequirementMissing')
    profile_file = app/'Contents/embedded.provisionprofile'
    with tempfile.TemporaryDirectory(prefix='E008-selected-only-') as temp:
        temp = Path(temp)
        # Verify CMS content signature, rather than treating a plist decode as signature evidence.
        verified = temp/'verified.plist'; signer = temp/'signer.pem'
        command(['/usr/bin/openssl', 'cms', '-verify', '-inform', 'DER', '-in', str(profile_file),
                 '-noverify', '-signer', str(signer), '-out', str(verified)])
        command(['/usr/bin/security', 'verify-cert', '-p', 'basic', '-c', str(signer)])
        profile = plistlib.loads(verified.read_bytes())
        prefix = str(temp/'leaf-')
        command(['/usr/bin/codesign', '-d', '--extract-certificates='+prefix, str(app)])
        certs = sorted(temp.glob('leaf-*'))
        if not certs or certs[0].name != 'leaf-0': raise Rejected('selectedLeafMissing')
        leaf = certs[0].read_bytes()
        if leaf not in profile.get('DeveloperCertificates', []): raise Rejected('selectedCertificateNotInProfile')
        verify = ['/usr/bin/security', 'verify-cert', '-p', 'codeSign']
        for cert in certs: verify += ['-c', str(cert)]
        command(verify)
        dates, _ = command(['/usr/bin/openssl', 'x509', '-inform', 'DER', '-in', str(certs[0]), '-noout', '-dates'])
        values = dict(line.split('=', 1) for line in dates.decode().splitlines())
        cert_date = lambda key: dt.datetime.strptime(values[key], '%b %d %H:%M:%S %Y %Z').replace(tzinfo=UTC).isoformat()
        cert_before, cert_after = cert_date('notBefore'), cert_date('notAfter')
    hardware, _ = command(['/usr/sbin/system_profiler', 'SPHardwareDataType', '-json'])
    records = json.loads(hardware).get('SPHardwareDataType')
    if not isinstance(records, list) or len(records) != 1: raise Rejected('provisioningDeviceRejected')
    device = records[0].get('provisioning_UDID')
    if not isinstance(device, str) or re.fullmatch(r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}', device) is None: raise Rejected('provisioningDeviceRejected')
    def profile_date(key):
        value = profile.get(key)
        if not isinstance(value, dt.datetime): raise Rejected('profileDateRejected')
        return value.replace(tzinfo=UTC).isoformat()
    # Raw identifiers remain private; only explicit public_view below can be exported.
    serial_profile = {'ApplicationIdentifierPrefix': profile.get('ApplicationIdentifierPrefix', []),
                      'ProvisionedDevices': profile.get('ProvisionedDevices', []),
                      'Platform': profile.get('Platform', []), 'Entitlements': profile.get('Entitlements', {})}
    return {'hostBindingSHA256':run.manifest['hostBindingSHA256'], 'synthetic': False, 'appPath': str(app), 'sourceRoot': str(source), 'device': device,
            'bundleIdentifier': info['CFBundleIdentifier'], 'buildMarker': info.get('E008BuildMarker'),
            'executableName': name, 'executableSHA256': file_hash(executable), 'appSHA256': app_sha,
            'profileSHA256': file_hash(profile_file), 'certificateSHA256': digest(leaf),
            'certificateNotBeforeUTC': cert_before, 'certificateNotAfterUTC': cert_after,
            'profileCreationUTC': profile_date('CreationDate'), 'profileExpiryUTC': profile_date('ExpirationDate'),
            'DR': match.group(1), 'DRSHA256': digest(match.group(1).encode()),
            'entitlements': ent, 'profile': serial_profile, 'sourceSHA256': source_hashes(),
            'profileSignatureVerified': True, 'certificateInProfile': True, 'appleDevelopmentChainVerified': True}


def public_view(asset):
    keep = ('hostBindingSHA256', 'executableSHA256', 'appSHA256', 'profileSHA256', 'certificateSHA256',
            'profileCreationUTC', 'profileExpiryUTC', 'certificateNotBeforeUTC', 'certificateNotAfterUTC',
            'DRSHA256', 'sourceSHA256', 'profileSignatureVerified', 'certificateInProfile', 'appleDevelopmentChainVerified')
    return {k: asset[k] for k in keep if k in asset}


def guard_scope(run):
    authorize(run.root,run.manifest,run.clock(),run.synthetic)
    if source_hashes()!=run.manifest['sourceSHA256']: raise Rejected('sourceChanged')


def frozen_asset(run,name):
    asset,sha=read(run.root,'proofs/'+name+'.json')
    if name.startswith('recovery-'):
        attempt=name.removeprefix('recovery-');grant,ready=__import__('continuity').require_recovery(run,attempt)
        binding,_=read(run.root,'recovery-attempts/'+attempt+'/proof.binding.json')
        if binding!={'globalSHA256':run.global_hash,'proofSHA256':sha,'grantSHA256':grant,'readySHA256':ready}: raise Rejected('frozenProofChanged')
    else:
        stage={'p0':'preflight','p1':'p1-setup','rebuilt':'rebuild-setup'}[name]
        event,_=read(run.root,'receipts/'+stage+'.machine.json')
        if event.get('proofSHA256')!=sha: raise Rejected('frozenProofChanged')
    return asset,sha


def operation_proof(run,stage,cleanup=False,name=None):
    name=name or ('p0' if stage in ('seed','fresh','expired') else 'rebuilt' if stage in ('rebuilt-read','cleanup') else 'p1')
    asset,sha=frozen_asset(run,name)
    baseline=frozen_asset(run,'p1')[0] if stage=='rebuilt-read' and not cleanup else frozen_asset(run,'p0')[0]
    phase='cleanup' if cleanup else 'expired' if stage=='expired' else 'p0' if name=='p0' else 'rebuilt' if name=='rebuilt' else 'p1'
    validate_asset(asset,run.manifest,run.clock(),baseline if phase!='p0' else None,phase)
    if app_hash(Path(asset['frozenHost']))!=asset['appSHA256']: raise Rejected('frozenHostChanged')
    return asset,sha,name


class SetupVerifier:
    """Selected-material inspection / owned files only. No App-launch method."""
    def __init__(self,run):
        if run.synthetic: raise Rejected('syntheticVerifierForbidden')
        guard_scope(run);self.run=run

    def confirm_ticket_exit(self, ticket, wrapper_exited=False):
        root = self.run.root
        process_path = safe(root, 'process/'+ticket+'.json')
        if not process_path.exists():
            if not wrapper_exited: raise Rejected('ownedProcessUnconfirmed')
        else:
            value, _ = read(root, str(process_path.relative_to(root)))
            pid = value.get('pid'); expected = str(safe(root, 'current/DPKContinuityProbe.app/Contents/MacOS/DPKContinuityProbe'))
            if type(pid) is not int or pid <= 1 or value.get('namespace') != self.run.namespace or value.get('ticket') != ticket:
                raise Rejected('ownedProcessUnconfirmed')
            result = subprocess.run(['/bin/ps', '-p', str(pid), '-o', 'uid=,comm='], capture_output=True, text=True)
            parts = result.stdout.strip().split(None, 1)
            if result.returncode == 1 and not parts: pass
            elif result.returncode or len(parts) != 2: raise Rejected('ownedProcessUnconfirmed')
            elif parts[0] == str(os.getuid()) and parts[1] == expected:
                try: os.kill(pid, signal.SIGTERM)
                except ProcessLookupError: pass
                else:
                    end = time.monotonic()+3
                    while time.monotonic() < end:
                        try: os.kill(pid, 0)
                        except ProcessLookupError: break
                        time.sleep(.05)
                    else: raise Rejected('ownedAppDidNotExit')
            # Different uid/executable means PID reused; never signal that unrelated process.
        exit_path = safe(root, 'control/exit-'+ticket+'.json')
        if not exit_path.exists(): exclusive(root, str(exit_path.relative_to(root)), {'namespace':self.run.namespace, 'ticket':ticket, 'exitConfirmed':True})

    def ensure_exited(self):
        for path in sorted(safe(self.run.root, 'control').glob('launch-*.json')):
            value, _ = read(self.run.root, str(path.relative_to(self.run.root)))
            ticket = value.get('ticket')
            if value.get('namespace') != self.run.namespace or not isinstance(ticket, str) or str(uuid.UUID(ticket)) != ticket:
                raise Rejected('ownedProcessUnconfirmed')
            exit_path = safe(self.run.root, 'control/exit-'+ticket+'.json')
            if exit_path.exists():
                record, _ = read(self.run.root, str(exit_path.relative_to(self.run.root)))
                if record != {'namespace':self.run.namespace, 'ticket':ticket, 'exitConfirmed':True}: raise Rejected('ownedProcessUnconfirmed')
            else: self.confirm_ticket_exit(ticket)

    def asset(self,name): return frozen_asset(self.run,name)

    def inspect_stage(self, stage):
        run = self.run
        name = {'preflight':'p0', 'p1-setup':'p1', 'rebuild-setup':'rebuilt'}[stage]
        selection, _ = read(run.root, 'selection/'+name+'.json')
        asset = inspect_selected(selection, run)
        baseline = self.asset('p0')[0] if name == 'p1' else self.asset('p1')[0] if name == 'rebuilt' else None
        validate_asset(asset, run.manifest, utc(), baseline, name)
        self.ensure_exited()
        destination = safe(run.root, 'hosts/'+name+'.app')
        if destination.exists(): raise Rejected('hostAlreadyFrozen')
        destination.parent.mkdir(mode=0o700, exist_ok=True)
        shutil.copytree(selection['appPath'], destination)
        if app_hash(destination) != asset['appSHA256']: raise Rejected('frozenHostChanged')
        asset['frozenHost'] = str(destination)
        sha = exclusive(run.root, 'proofs/'+name+'.json', asset)
        return asset, sha

    def wait_observation(self, stage, run):
        number = next(n for n, stages in __import__('continuity').STAGES.items() if stage in stages)
        path = safe(run.root, 'human/'+stage+'.json')
        while not path.exists(): run.window(number); time.sleep(.2)

    def finalize(self, run):
        """Filesystem-only finalization, also independently exercised on synthetic temp fixtures."""
        self.ensure_exited()
        root = private_root(run.root, run.namespace, run.synthetic)
        output_value = run.manifest.get('publicEvidenceDirectory')
        if not isinstance(output_value, str): raise Rejected('publicEvidenceDestinationRequired')
        output = Path(output_value)
        if output.is_symlink() or output.resolve().is_relative_to(root.resolve()): raise Rejected('unsafePublicDestination')
        for parent in [output.parent, *output.parent.parents]:
            if parent.is_symlink(): raise Rejected('unsafePublicDestination')
        if not output.parent.is_dir() or output.parent.stat().st_uid != os.getuid(): raise Rejected('publicDestinationOwnerRequired')
        output.mkdir(mode=0o700, exist_ok=True)
        ownership = {'namespace':run.namespace, 'globalSHA256':run.global_hash, 'synthetic':run.synthetic}
        def publish(relative, value):
            target = safe(output, relative); raw = canonical(value)
            if target.exists():
                if target.read_bytes() != raw: raise Rejected('publicReceiptCollision')
                return digest(raw)
            return exclusive(output, relative, value)
        indexed = {'ownership.json':publish('ownership.json', ownership)}
        for folder in ('receipts', 'failures', 'recovery'):
            for path in sorted(safe(root, folder).glob('*.json')):
                value, _ = read(root, str(path.relative_to(root)))
                indexed[str(path.relative_to(root))] = publish(str(path.relative_to(root)), value)
        for path in sorted(safe(root, 'human').glob('*.json')):
            value, _ = read(root, str(path.relative_to(root)))
            stage = value.get('stage')
            if stage not in __import__('continuity').ORDER: continue
            event, sha = read(root, 'receipts/'+stage+'.machine.json')
            try: __import__('continuity').validate_human(value, event, sha, run.synthetic, run.clock())
            except Rejected: continue  # Never export invalid/free-form private input as valid observation.
            indexed[str(path.relative_to(root))] = publish(str(path.relative_to(root)), value)
        for path in sorted(safe(root, 'proofs').glob('*.json')):
            value, sha = read(root, str(path.relative_to(root)))
            view = dict(public_view(value), privateProofSHA256=sha)
            name = 'proofs/'+path.stem+'.public.json'; indexed[name] = publish(name, view)
        # Archive safe control fields AND original private byte hashes before deleting them.
        for number in (1,2,3):
            if not safe(root,'windows/'+str(number)+'.json').exists(): continue
            window,sha=run.window(number,cleanup=True)
            view={key:window[key] for key in ('namespace','number','synthetic','globalSHA256','startUTC','cutoffUTC','deadlineUTC')}
            view.update(privateWindowSHA256=sha,humanReadyStatementPresent=bool(window.get('humanReadyStatement')))
            name='windows/'+str(number)+'.public.json';indexed[name]=publish(name,view)
            binding,_=read(root,'windows/'+str(number)+'.binding.json');name='windows/'+str(number)+'.binding.json';indexed[name]=publish(name,binding)
        previous=None
        for stage in __import__('continuity').ORDER:
            path=safe(root,'gates/'+stage+'.json')
            if not path.exists(): continue
            gate,sha=read(root,str(path.relative_to(root)));accepted=False
            event_path=safe(root,'receipts/'+stage+'.machine.json')
            if event_path.exists():
                event,event_sha=read(root,str(event_path.relative_to(root)))
                try:
                    run.check_ready(stage,gate,previous,archived=True)
                    if event.get('readySHA256')!=sha or stamp(gate['recordedUTC'])>stamp(event['startedUTC']): raise Rejected('readyMachineMismatch')
                    accepted=True
                except (Rejected,OSError,KeyError): pass
            view={'privateReadySHA256':sha,'stage':stage,'accepted':accepted}
            if accepted:
                view.update({key:gate[key] for key in ('namespace','synthetic','stage','previousReceiptSHA256','humanReady','recordedUTC')})
                view['humanReadyStatementPresent']=True
                if previous: view['previousHumanSHA256']=file_hash(safe(root,'human/'+previous[0]['stage']+'.json'))
            name='gates/'+stage+'.public.json';indexed[name]=publish(name,view)
            if event_path.exists(): previous=(event,event_sha)
        for number in (1,2):
            path=safe(root,'retained-'+str(number)+'.json')
            if not path.exists(): continue
            value,sha=read(root,str(path.relative_to(root)))
            allowed={'namespace','globalSHA256','machineReceiptSHA256','humanReceiptSHA256','grantSHA256','state','synthetic','retainedUTC'}
            if set(value)!=allowed or value['namespace']!=run.namespace or value['state']!='retained-no-background-process': raise Rejected('retentionArchiveRejected')
            name='retained-'+str(number)+'.json';indexed[name]=publish(name,value)
        for kind in ('assets','retention','recovery'):
            grant,sha=read(root,'grants/'+kind+'.json')
            view={key:grant[key] for key in ('kind','scope','namespace','synthetic','approved','validUntilUTC')}
            view.update(privateGrantSHA256=sha,statementPresent=bool(grant.get('statement')))
            name='grants/'+kind+'.public.json';indexed[name]=publish(name,view)
        for attempt_dir in sorted(safe(root,'recovery-attempts').glob('*')):
            if not attempt_dir.is_dir() or str(uuid.UUID(attempt_dir.name))!=attempt_dir.name: raise Rejected('recoveryArchiveRejected')
            prefix='recovery-attempts/'+attempt_dir.name+'/'
            for leaf in ('grant','ready'):
                path=safe(root,prefix+leaf+'.json')
                if not path.exists(): continue
                value,sha=read(root,prefix+leaf+'.json')
                keep=('scope','namespace','synthetic','approved','assetInspectionApproved','globalSHA256','grantSHA256','attempt','humanReady','recordedUTC','validUntilUTC')
                view={'privateReceiptSHA256':sha}
                # A failed attempt may contain invalid caller input: export only finite safe values.
                for key in keep:
                    if key not in value: continue
                    item=value[key]
                    if key.endswith('SHA256') and (not isinstance(item,str) or re.fullmatch('[0-9a-f]{64}',item) is None): continue
                    if key.endswith('UTC'):
                        try: stamp(item)
                        except Rejected: continue
                    if key=='namespace' and item!=run.namespace: continue
                    if key=='attempt' and item!=attempt_dir.name: continue
                    if key=='scope' and item!='cleanup-only': continue
                    if key in ('synthetic','approved','assetInspectionApproved','humanReady') and type(item) is not bool: continue
                    view[key]=item
                name=prefix+leaf+'.public.json';indexed[name]=publish(name,view)
            for leaf in ('proof.binding','machine','human'):
                path=safe(root,prefix+leaf+'.json')
                if not path.exists(): continue
                value,sha=read(root,prefix+leaf+'.json')
                if leaf=='human':
                    event,event_sha=read(root,prefix+'machine.json')
                    __import__('continuity').validate_human(value,event,event_sha,run.synthetic,run.clock())
                name=prefix+leaf+'.json';indexed[name]=publish(name,value)
        public_global = {key:run.manifest[key] for key in ('namespace','synthetic','startUTC','globalDeadlineUTC','p0ExpiryUTC','certificateNotAfterUTC','sourceSHA256','fixtureSHA256','grantSHA256','hostBindingSHA256')}
        public_global['privateGlobalSHA256']=run.global_hash
        indexed['global.public.json'] = publish('global.public.json', public_global)
        pre_sha=publish('pre-cleanup.index.json', {'namespace':run.namespace, 'synthetic':run.synthetic, 'files':dict(indexed), 'privateCleanupConfirmed':False})
        indexed['pre-cleanup.index.json']=pre_sha
        # Export is durable first. Refuse symlinks or uncertain owned processes before private deletion.
        self.ensure_exited()
        if any(path.is_symlink() for path in root.rglob('*')): raise Rejected('privateSymlinkRecoveryRequired')
        shutil.rmtree(root)
        if root.exists(): raise Rejected('privateCleanupIncomplete')
        completion = {'namespace':run.namespace, 'synthetic':run.synthetic, 'privateRootAbsent':True,
                      'cleanupComplete':True, 'recoveryRequired':False, 'endedUTC':utc().isoformat(),
                      'appleDeveloperAssetsRetained':True}
        indexed['private-cleanup.machine.json'] = publish('private-cleanup.machine.json', completion)
        publish('final.index.json', {'namespace':run.namespace, 'synthetic':run.synthetic, 'files':indexed, 'cleanupComplete':True})
        return True

    def inspect_recovery(self,attempt):
        run=self.run;grant,ready=__import__('continuity').require_recovery(run,attempt)
        self.ensure_exited()
        selection,_=read(run.root,'recovery-attempts/'+attempt+'/selection.json')
        asset=inspect_selected(selection,run)
        validate_asset(asset,run.manifest,run.clock(),self.asset('p0')[0],'cleanup')
        name='recovery-'+attempt;destination=safe(run.root,'hosts/'+name+'.app')
        if destination.exists(): raise Rejected('hostAlreadyFrozen')
        destination.parent.mkdir(mode=0o700,exist_ok=True);shutil.copytree(selection['appPath'],destination)
        if app_hash(destination)!=asset['appSHA256']: raise Rejected('frozenHostChanged')
        asset['frozenHost']=str(destination);sha=exclusive(run.root,'proofs/'+name+'.json',asset)
        exclusive(run.root,'recovery-attempts/'+attempt+'/proof.binding.json',{'globalSHA256':run.global_hash,'proofSHA256':sha,'grantSHA256':grant,'readySHA256':ready})
        return name


class LiveBackend(SetupVerifier):
    """App-capable executor exists only after current ready and applicable actual proof."""
    def __init__(self,run,stage=None,cleanup=False,name=None):
        if run.synthetic: raise Rejected('syntheticBackendForbidden')
        guard_scope(run)
        if not cleanup:
            gate,_=read(run.root,'gates/'+str(stage)+'.json');run.require_ready(stage,gate)
        asset,sha,name=operation_proof(run,stage,cleanup,name)
        self.run,self.stage_name,self.cleanup_only,self.proof_name=run,stage,cleanup,name
        self.prepared_asset,self.prepared_sha=asset,sha

    def launch(self, stage, asset, proof_sha, cleanup=False):
        run = self.run
        guard_scope(run)
        if stage!=self.stage_name or cleanup!=self.cleanup_only or proof_sha!=self.prepared_sha: raise Rejected('executorScopeChanged')
        asset,actual_sha,_=operation_proof(run,stage,cleanup,self.proof_name)
        if actual_sha!=proof_sha: raise Rejected('frozenProofChanged')
        number = next(n for n, stages in __import__('continuity').STAGES.items() if stage in stages) if stage in __import__('continuity').ORDER else 3
        if cleanup:
            number = max(n for n in (1, 2, 3) if safe(run.root, 'windows/'+str(n)+'.json').exists())
        self.ensure_exited()  # Must precede all copies/removal/new launch, including failure cleanup.
        phase = 'expired' if stage == 'expired' else 'p0' if stage in ('seed', 'fresh') else 'rebuilt' if stage == 'rebuilt-read' else 'p1'
        if not cleanup: validate_asset(asset, run.manifest, utc(), self.asset('p0')[0] if phase == 'expired' else None, phase)
        else: validate_asset(asset, run.manifest, utc(), None, 'cleanup')
        frozen = Path(asset['frozenHost'])
        if app_hash(frozen) != asset['appSHA256']: raise Rejected('frozenHostChanged')
        installed = safe(run.root, 'current/DPKContinuityProbe.app'); installed.parent.mkdir(mode=0o700, exist_ok=True)
        if installed.exists(): shutil.rmtree(installed)
        shutil.copytree(frozen, installed)
        if app_hash(installed) != asset['appSHA256']: raise Rejected('installedHostChanged')
        window, window_sha = run.window(number, cleanup=cleanup)
        ticket_id = str(uuid.uuid4())
        ticket = {'namespace': run.namespace, 'stage': stage, 'window': number, 'synthetic': False,
                  'globalSHA256': run.global_hash, 'proofSHA256': proof_sha,
                  'proofRelative': 'proofs/'+('p0' if stage in ('seed', 'fresh', 'expired') else 'rebuilt' if stage == 'rebuilt-read' else 'p1')+'.json',
                  'windowSHA256': window_sha, 'operation': 'seed-read-a' if stage == 'seed' else 'delete-read-absent' if cleanup or stage == 'cleanup' else 'read-original-a',
                  'cleanup': cleanup or stage == 'cleanup', 'issuedUTC': utc().isoformat()}
        ticket['proofRelative']='proofs/'+self.proof_name+'.json'
        if not cleanup and stage != 'cleanup':
            ticket['readySHA256'] = file_hash(safe(run.root, 'gates/'+stage+'.json'))
        exclusive(run.root, 'tickets/'+ticket_id+'.json', ticket)
        started = utc().isoformat(); receipt = safe(run.root, 'app-receipts/'+ticket_id+'.json')
        exclusive(run.root, 'control/launch-'+ticket_id+'.json', {'namespace':run.namespace, 'ticket':ticket_id})
        wrapper_exited = False
        process = subprocess.Popen(['/usr/bin/open', '-W', '-n', str(installed), '--args', '--root', str(run.root), '--ticket', ticket_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            remaining = max(1, (stamp(window['deadlineUTC'] if cleanup else window['cutoffUTC']) - utc()).total_seconds())
            code = process.wait(timeout=min(60 if not cleanup else 15, remaining)); wrapper_exited = True
        except subprocess.TimeoutExpired:
            process.terminate(); process.wait(timeout=3); raise Rejected('launchTimeout') from None
        finally: self.confirm_ticket_exit(ticket_id, wrapper_exited)
        if not receipt.exists():
            if stage != 'expired': raise Rejected('appReceiptMissing')
            return {'startedUTC': started, 'endedUTC': utc().isoformat(), 'completed': True,
                    'launch': 'rejected' if code else 'no-receipt', 'guard': 'not-observed', 'callAttempted': False,
                    'OSStatus': None, 'availabilityInterrupted': True, 'classification': 'launchOrAppGuardUnobserved'}
        result, _ = read(run.root, 'app-receipts/'+ticket_id+'.json')
        if (result.get('namespace') != run.namespace or result.get('ticket') != ticket_id or
                result.get('executableSHA256') != asset['executableSHA256'] or result.get('proofSHA256') != proof_sha): raise Rejected('appReceiptRejected')
        result.update(public_view(asset))
        if stage == 'expired': result['completed'] = True; result['availabilityInterrupted'] = result.get('fields') != {k: True for k in FIELDS}
        return result


class ManualStages:
    """Fixed CLI stage driver. Construction cannot inspect assets or launch Apps."""
    def __init__(self,run): self.run=run
    def stage(self,stage,run):
        guard_scope(run)
        gate,_=read(run.root,'gates/'+stage+'.json');run.require_ready(stage,gate)
        started=run.clock().isoformat()
        if stage in ('preflight','p1-setup','rebuild-setup'):
            verifier=SetupVerifier(run);asset,sha=verifier.inspect_stage(stage)
            return dict(public_view(asset),startedUTC=started,endedUTC=run.clock().isoformat(),completed=True,launch='not-requested',guard='passed',callAttempted=False,OSStatus=None),sha
        asset,sha,name=operation_proof(run,stage,stage=='cleanup')
        executor=LiveBackend(run,stage,stage=='cleanup',name)
        return executor.launch(stage,asset,sha,cleanup=stage=='cleanup'),sha
    def wait_observation(self,stage,run):
        number=next(n for n,stages in __import__('continuity').STAGES.items() if stage in stages)
        while not safe(run.root,'human/'+stage+'.json').exists(): run.window(number);time.sleep(.2)
    def cleanup(self,run):
        guard_scope(run)
        for name in ('rebuilt','p1','p0'):
            if not safe(run.root,'proofs/'+name+'.json').exists(): continue
            try:
                asset,sha,_=operation_proof(run,'cleanup',True,name)
                executor=LiveBackend(run,'cleanup',True,name)
                result=executor.launch('cleanup',asset,sha,cleanup=True)
                exclusive(run.root,'recovery/'+str(uuid.uuid4())+'.machine.json',dict(public_result(result),namespace=run.namespace,synthetic=run.synthetic,proofSHA256=sha,promptCount=None))
                return result.get('absent') is True and result.get('completed') is True
            except Rejected: continue
        return False
    def recover(self,run,attempt):
        guard_scope(run);__import__('continuity').require_recovery(run,attempt)
        name='recovery-'+attempt
        if not safe(run.root,'proofs/'+name+'.json').exists(): name=SetupVerifier(run).inspect_recovery(attempt)
        asset,sha,_=operation_proof(run,'cleanup',True,name)
        executor=LiveBackend(run,'cleanup',True,name)
        return dict(executor.launch('cleanup',asset,sha,cleanup=True),proofSHA256=sha)
    def finalize(self,run): return SetupVerifier(run).finalize(run)
