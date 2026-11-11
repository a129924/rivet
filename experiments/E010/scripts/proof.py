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
                        file_hash, private_root, public_result, read, safe, stamp, utc, is_main, check_main)


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
        if phase == 'rebuilt' and (asset['DRSHA256'] != baseline['DRSHA256'] or asset['profileSHA256'] != baseline['profileSHA256'] or asset['executableSHA256'] == baseline['executableSHA256'] or asset['buildMarker'] != 'rebuilt'):
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
    if isinstance(run,__import__('continuity').Bootstrap): run.setup_ready()
    else: authorize(run.root, run.manifest, utc(), False)
    build_result=build_sha=None;gui_result=gui_sha=None
    selected_command=command
    if run.manifest.get('authorizationMode')=='gui-package':
        from gui_build import verify_provenance,capture_command
        gui_result,gui_sha=verify_provenance(selection,run)
        selected_command=lambda args:capture_command(run,args,phase=selection['guiPhase'])
    elif is_main(run.manifest):
        from prepare import verify_build_provenance
        build_result,build_sha=verify_build_provenance(selection,run)
    elif not selection.get('humanFreePersonalTeamStatement') or not selection.get('humanSourceAndMarkerStatement'):
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
    selected_command(['/usr/bin/codesign', '--verify', '--strict', '--verbose=0', str(app)])
    out, _ = selected_command(['/usr/bin/codesign', '-d', '--entitlements', ':-', str(app)])
    begin = out.find(b'<?xml')
    if begin < 0: raise Rejected('entitlementsMissing')
    ent = plistlib.loads(out[begin:])
    _, detail = selected_command(['/usr/bin/codesign', '-d', '-vvv', str(app)])
    if b'Authority=Apple Development:' not in detail or b'Signature=adhoc' in detail: raise Rejected('appleDevelopmentRequired')
    out, err = selected_command(['/usr/bin/codesign', '-d', '-r-', str(app)])
    match = re.search(r'designated => (.+)', (out+err).decode(errors='replace'))
    if not match: raise Rejected('designatedRequirementMissing')
    profile_file = app/'Contents/embedded.provisionprofile'
    raw_directory=safe(run.root,'raw') if run.manifest.get('authorizationMode')=='gui-package' else None
    if raw_directory is not None:raw_directory.mkdir(mode=0o700,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='E010-selected-only-',dir=raw_directory) as temp:
        temp = Path(temp)
        # Verify CMS content signature, rather than treating a plist decode as signature evidence.
        verified = temp/'verified.plist'; signer = temp/'signer.pem'
        selected_command(['/usr/bin/openssl', 'cms', '-verify', '-inform', 'DER', '-in', str(profile_file),
                 '-noverify', '-signer', str(signer), '-out', str(verified)])
        selected_command(['/usr/bin/security', 'verify-cert', '-p', 'basic', '-c', str(signer)])
        profile = plistlib.loads(verified.read_bytes())
        prefix = str(temp/'leaf-')
        selected_command(['/usr/bin/codesign', '-d', '--extract-certificates='+prefix, str(app)])
        certs = sorted(temp.glob('leaf-*'))
        if not certs or certs[0].name != 'leaf-0': raise Rejected('selectedLeafMissing')
        leaf = certs[0].read_bytes()
        if leaf not in profile.get('DeveloperCertificates', []): raise Rejected('selectedCertificateNotInProfile')
        verify = ['/usr/bin/security', 'verify-cert', '-p', 'codeSign']
        for cert in certs: verify += ['-c', str(cert)]
        selected_command(verify)
        dates, _ = selected_command(['/usr/bin/openssl', 'x509', '-inform', 'DER', '-in', str(certs[0]), '-noout', '-dates'])
        values = dict(line.split('=', 1) for line in dates.decode().splitlines())
        cert_date = lambda key: dt.datetime.strptime(values[key], '%b %d %H:%M:%S %Y %Z').replace(tzinfo=UTC).isoformat()
        cert_before, cert_after = cert_date('notBefore'), cert_date('notAfter')
    hardware, _ = selected_command(['/usr/sbin/system_profiler', 'SPHardwareDataType', '-json'])
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
    if build_result and (build_result['profileSHA256']!=file_hash(profile_file) or build_result['certificateSHA256']!=digest(leaf)):raise Rejected('directBuildActualSigningChanged')
    result={'hostBindingSHA256':run.manifest['hostBindingSHA256'], 'synthetic': False, 'appPath': str(app), 'sourceRoot': str(source), 'device': device,
            'bundleIdentifier': info['CFBundleIdentifier'], 'buildMarker': info.get('E010BuildMarker'),
            'executableName': name, 'executableSHA256': file_hash(executable), 'appSHA256': app_sha,
            'profileSHA256': file_hash(profile_file), 'certificateSHA256': digest(leaf),
            'certificateNotBeforeUTC': cert_before, 'certificateNotAfterUTC': cert_after,
            'profileCreationUTC': profile_date('CreationDate'), 'profileExpiryUTC': profile_date('ExpirationDate'),
            'DR': match.group(1), 'DRSHA256': digest(match.group(1).encode()),
            'entitlements': ent, 'profile': serial_profile, 'sourceSHA256': source_hashes(),
            'profileSignatureVerified': True, 'certificateInProfile': True, 'appleDevelopmentChainVerified': True}
    if build_result:result.update(buildProvenanceSHA256=build_sha,buildLogSHA256=build_result['buildLogSHA256'],sourceConfigSHA256=build_result['configurationSHA256'])
    if gui_result:
        from gui_build import reference
        if result['certificateSHA256']!=reference(run)[0]['certificateSHA256']:raise Rejected('originalLeafMismatch')
        result.update(evidenceType='gui-hooks-v1',GUIProvenanceSHA256=gui_sha,originalLeafReferenceSHA256=gui_result['originalLeafReferenceSHA256'])
    return result


def public_view(asset):
    keep = ('hostBindingSHA256', 'executableSHA256', 'appSHA256', 'profileSHA256', 'certificateSHA256',
            'profileCreationUTC', 'profileExpiryUTC', 'certificateNotBeforeUTC', 'certificateNotAfterUTC',
            'DRSHA256', 'evidenceType','GUIProvenanceSHA256','originalLeafReferenceSHA256', 'sourceSHA256', 'buildProvenanceSHA256', 'buildLogSHA256', 'sourceConfigSHA256', 'profileSignatureVerified', 'certificateInProfile', 'appleDevelopmentChainVerified')
    return {k: asset[k] for k in keep if k in asset}


def inspect_bootstrap(context):
    ready_sha=context.setup_ready();window,window_sha=context.validate()
    selection,_=read(context.root,'selection/p0.json')
    asset=__import__('gui_build').accepted_asset(context,'p0') if context.manifest.get('authorizationMode')=='gui-package' else inspect_selected(selection,context)
    __import__('continuity').bootstrap_asset(context,asset)
    destination=safe(context.root,'hosts/p0.app')
    if destination.exists(): raise Rejected('hostAlreadyFrozen')
    destination.parent.mkdir(mode=0o700,exist_ok=True);shutil.copytree(selection['appPath'],destination)
    if app_hash(destination)!=asset['appSHA256']: raise Rejected('frozenHostChanged')
    asset['frozenHost']=str(destination)
    sha=exclusive(context.root,'bootstrap/actual-proof.json',asset)
    exclusive(context.root,'bootstrap/proof.binding.json',{'anchorSHA256':context.anchor_hash,'windowSHA256':window_sha,'setupReadySHA256':ready_sha,'actualProofSHA256':sha})
    return asset,sha


def bootstrap_public(context):
    """Only explicit public controls; private statements/identifiers never leave the root."""
    context.validate(cleanup=True);root=context.root;values={}
    keys=('authorizationMode','mainConsentSHA256','buildEvidenceType','guiBeginSyncSHA256','rootBindingSHA256','namespace','synthetic','stage','startUTC','startedUTC','endedUTC','callAttempted','OSStatus','promptCount','completed','globalDeadlineUTC','maxWindows','hostBindingSHA256','sourceSHA256','grantSHA256','beginReadySHA256','fixtureSHA256','anchorSHA256','windowSHA256','globalSHA256','previousReceiptSHA256','previousHumanSHA256','humanReady','recordedUTC','completedUTC','actualProofSHA256','completionSHA256','setupReadySHA256')
    for relative in ('anchor.json','anchor.binding.json','bootstrap/begin.ready.json','bootstrap/begin.machine.json','bootstrap/setup.ready.json','bootstrap/proof.binding.json','bootstrap/complete.json','bootstrap/setup.machine.json','bootstrap/seed.ready.json'):
        if not safe(root,relative).exists():continue
        value,sha=read(root,relative);view={key:value[key] for key in keys if key in value}
        view['privateReceiptSHA256']=sha
        if 'humanReadyStatement' in value:view['humanReadyStatementPresent']=bool(value['humanReadyStatement'])
        values[relative.removesuffix('.json')+'.public.json']=view
    if context.manifest.get('authorizationMode')=='gui-package':
        sync,sha=read(root,'gui-begin-sync.json')
        if sha!=context.manifest.get('guiBeginSyncSHA256'):raise Rejected('GUIBeginSyncChanged')
        values['gui-begin-sync.public.json']={key:sync[key] for key in ('kind','namespace','synthetic','sourceSHA256','grantSHA256','humanCanBeginNow','recordedUTC')}
        values['gui-begin-sync.public.json'].update(privateReceiptSHA256=sha,statementPresent=bool(sync.get('statement')))
    for stage in ('begin','setup'):
        relative='bootstrap/'+stage+'.human.json'
        if not safe(root,relative).exists():continue
        value,sha=read(root,relative);machine,machine_sha=read(root,'bootstrap/'+stage+'.machine.json')
        __import__('continuity').validate_human(value,machine,machine_sha,context.synthetic,context.clock())
        values[relative]=value
    if safe(root,'bootstrap/actual-proof.json').exists():
        asset,sha=read(root,'bootstrap/actual-proof.json');values['bootstrap/actual-proof.public.json']=dict(public_view(asset),privateReceiptSHA256=sha)
    for path in safe(root,'bootstrap').glob('stopped-*.machine.json'):
        relative=str(path.relative_to(root));values[relative]=read(root,relative)[0]
    return values


def build_public_views(context):
    """Success keeps actual product proof; failures export only verified finite controls."""
    from prepare import ensure_builds_exited,verify_build_provenance,failed_build_control
    if context.manifest.get('authorizationMode')=='gui-package':return __import__('gui_build').public_views(context)
    ensure_builds_exited(context);views={}
    for phase in ('p0','p1','rebuilt','recovery'):
        if not safe(context.root,'builds/'+phase+'/result.json').exists():continue
        result,_=read(context.root,'builds/'+phase+'/result.json')
        success=result.get('exitCode')==0 and result.get('classification')=='completed'
        if success:
            selected={'appPath':result['appPath'],'sourceRoot':result['sourceRoot'],'buildReceiptRelative':'builds/'+phase+'/result.json'}
            verified,result_sha=verify_build_provenance(selected,context)
        else:verified,result_sha=failed_build_control(context,phase)
        keep=('kind','phase','namespace','synthetic','attemptSHA256','configurationSHA256','effectiveEnvironmentSHA256','sourceSHA256','configuration','buildLogSHA256','exitCode','classification','ownedProcessesExited','recoveryRequired','startedUTC','endedUTC','profileSHA256','certificateSHA256')
        view={key:verified[key] for key in keep if key in verified}
        if success:view.update({key:verified[key] for key in ('appSHA256','executableSHA256','InfoSHA256')})
        view.update(privateBuildResultSHA256=result_sha,scheme='DPKContinuityProbe',hostProofAvailable=success,actualSigningProofRequiredSeparately=True)
        views['builds/'+phase+'.public.json']=view
    return views


def stop_bootstrap(context):
    """Filesystem-only controlled stop; never infer absence after any App attempt."""
    context.validate(cleanup=True);root=private_root(context.root,context.namespace,context.synthetic)
    package=is_main(context.manifest)
    if package:
        if context.archive_only:raise Rejected('archiveOnlyContext')
        __import__('prepare').ensure_builds_exited(context)
    possible=__import__('continuity').owned_write_possible(root,context.namespace,context.synthetic) or any(safe(root,folder).exists() and any(safe(root,folder).iterdir()) for folder in ('control','process','consumed')) or safe(root,'receipts/seed.machine.json').exists()
    if possible:raise Rejected('keychainCleanupHostRequired')
    output=Path(context.manifest['publicEvidenceDirectory'])
    if output.is_symlink() or output.resolve().is_relative_to(root.resolve()) or not output.parent.is_dir() or output.parent.stat().st_uid!=os.getuid():raise Rejected('unsafePublicDestination')
    if any(parent.is_symlink() for parent in [output,*output.parents]):raise Rejected('unsafePublicDestination')
    public_output=output
    if context.manifest.get('authorizationMode')=='gui-package':output=safe(root,'safe-candidates');output.mkdir(mode=0o700,exist_ok=True)
    output.mkdir(mode=0o700,exist_ok=True);archive=safe(output,'setup-stop-main' if package else 'setup-stop-'+str(uuid.uuid4()));archive.mkdir(mode=0o700,exist_ok=package)
    indexed={}
    def publish(name,value):
        path=safe(archive,name);raw=canonical(value)
        if package and path.exists():
            if path.read_bytes()!=raw:raise Rejected('publicReceiptCollision')
            return digest(raw)
        return exclusive(archive,name,value)
    for name,value in bootstrap_public(context).items():indexed[name]=publish(name,value)
    if package:
        for name,value in build_public_views(context).items():indexed[name]=publish(name,value)
    window,window_sha=context.validate(cleanup=True);view={k:window[k] for k in ('namespace','synthetic','number','anchorSHA256','startUTC','cutoffUTC','deadlineUTC')};view['privateWindowSHA256']=window_sha
    indexed['windows/1.public.json']=publish('windows/1.public.json',view)
    # exclusive() fsyncs the complete canonical bytes. Verify the safe index and all
    # referenced exports before any irreversible private deletion.
    pre_index={'namespace':context.namespace,'synthetic':context.synthetic,'phase':'before-private-delete','files':dict(indexed),'privateRootRetained':True,'cleanupComplete':False}
    pre_sha=publish('pre-cleanup.index.json',pre_index)
    published,verified_sha=read(archive,'pre-cleanup.index.json')
    if published!=pre_index or verified_sha!=pre_sha or any(file_hash(safe(archive,name))!=sha for name,sha in indexed.items()):raise Rejected('preCleanupExportUnconfirmed')
    indexed['pre-cleanup.index.json']=pre_sha
    if package:
        context.validate(cleanup=True);__import__('prepare').ensure_builds_exited(context)
        path=safe(root,'publication-ack.json');accepted=False
        if path.exists():
            ack,_=read(root,'publication-ack.json')
            accepted=(ack.get('kind')=='safe-candidate-model-ack' and ack.get('namespace')==context.namespace and ack.get('anchorSHA256')==context.anchor_hash and ack.get('candidateIndexSHA256')==pre_sha and ack.get('readabilityAcknowledged') is True and ack.get('safetyAcknowledged') is True and stamp(context.manifest['startUTC'])<=stamp(ack.get('recordedUTC'))<=context.clock())
        if not accepted:return {'namespace':context.namespace,'synthetic':context.synthetic,'keychainItemCreated':False,'privateRootAbsent':False,'cleanupComplete':False,'recoveryRequired':True,'awaitingSafeEvidenceACK':True,'candidateIndexSHA256':pre_sha}
        context.validate(cleanup=True)
        if context.manifest.get('authorizationMode')=='gui-package':
            module=__import__('gui_build');module.closed_for_cleanup(context)
            archive=module.copy_candidate(archive,public_output/'setup-stop-main')
    complete=False
    try:
        if any(p.is_symlink() or p.stat().st_uid!=os.getuid() for p in root.rglob('*')):raise Rejected('privateOwnershipUnconfirmed')
        shutil.rmtree(root);complete=not root.exists()
    except OSError:pass
    result={'namespace':context.namespace,'synthetic':context.synthetic,'noSecItemWriteAttempted':True,'keychainItemCreated':False,'privateRootAbsent':complete,'cleanupComplete':complete,'recoveryRequired':not complete,'appleAssetsRetained':True,'endedUTC':context.clock().isoformat()}
    try:
        indexed['cleanup.machine.json']=exclusive(archive,'cleanup.machine.json',result)
        exclusive(archive,'index.json',{'namespace':context.namespace,'synthetic':context.synthetic,'files':indexed,'cleanupComplete':complete,'evidencePublicationComplete':True})
    except OSError:
        # A publication error cannot undo deletion. Keep the durable pre-index and
        # report physical cleanup separately; never claim private material remains.
        failed={'namespace':context.namespace,'synthetic':context.synthetic,'preCleanupIndexSHA256':pre_sha,'privateRootAbsent':not root.exists(),'privateMaterialRetained':root.exists(),'privateCleanupComplete':complete,'cleanupComplete':False,'evidencePublicationComplete':False,'recoveryRequired':True,'endedUTC':context.clock().isoformat()}
        try:exclusive(archive,'completion-publication-failed.machine.json',failed)
        except OSError:pass  # Pre-index still exists even if no further publication is possible.
        print('Setup private root absent='+str(not root.exists()).lower()+'; durable pre-cleanup index saved; completion evidence publication incomplete.')
        raise
    return result


def guard_scope(run):
    authorize(run.root,run.manifest,run.clock(),run.synthetic)
    if source_hashes()!=run.manifest['sourceSHA256']: raise Rejected('sourceChanged')
    if is_main(run.manifest):__import__('prepare').ensure_builds_exited(run)


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
        if stage=='preflight' and run.manifest.get('anchorSHA256'):
            asset,sha=read(run.root,'proofs/p0.json');validate_asset(asset,run.manifest,run.clock(),phase='p0')
            if sha!=run.manifest['actualSetupProofSHA256'] or app_hash(Path(asset['frozenHost']))!=asset['appSHA256']: raise Rejected('setupProofChanged')
            return asset,sha
        name = {'preflight':'p0', 'p1-setup':'p1', 'rebuild-setup':'rebuilt'}[stage]
        selection, _ = read(run.root, 'selection/'+name+'.json')
        asset = __import__('gui_build').accepted_asset(run,name) if run.manifest.get('authorizationMode')=='gui-package' else inspect_selected(selection,run)
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
        if is_main(run.manifest):__import__('prepare').ensure_builds_exited(run)
        self.ensure_exited()
        root = private_root(run.root, run.namespace, run.synthetic)
        output_value = run.manifest.get('publicEvidenceDirectory')
        if not isinstance(output_value, str): raise Rejected('publicEvidenceDestinationRequired')
        output = Path(output_value)
        public_output=output
        gui_mode=run.manifest.get('authorizationMode')=='gui-package'
        if output.is_symlink() or output.resolve().is_relative_to(root.resolve()): raise Rejected('unsafePublicDestination')
        for parent in [output.parent, *output.parent.parents]:
            if parent.is_symlink(): raise Rejected('unsafePublicDestination')
        if not output.parent.is_dir() or output.parent.stat().st_uid != os.getuid(): raise Rejected('publicDestinationOwnerRequired')
        if gui_mode:output=safe(root,'safe-candidates');output.mkdir(mode=0o700,exist_ok=True)
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
            try: __import__('continuity').validate_human(value, event, sha, run.synthetic, run.clock(),enforce_ux=not is_main(run.manifest))
            except Rejected: continue  # Never export invalid/free-form private input as valid observation.
            indexed[str(path.relative_to(root))] = publish(str(path.relative_to(root)), value)
        for path in sorted(safe(root, 'proofs').glob('*.json')):
            value, sha = read(root, str(path.relative_to(root)))
            view = dict(public_view(value), privateProofSHA256=sha)
            name = 'proofs/'+path.stem+'.public.json'; indexed[name] = publish(name, view)
        # Archive safe control fields AND original private byte hashes before deleting them.
        for number in (1,2,3):
            if not safe(root,'windows/'+str(number)+'.json').exists(): continue
            window,sha=run.window(number,cleanup=True,archived=True)
            view={key:window[key] for key in ('namespace','number','synthetic','globalSHA256','anchorSHA256','startUTC','cutoffUTC','deadlineUTC') if key in window}
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
                view.update({key:gate[key] for key in ('namespace','synthetic','stage','previousReceiptSHA256','humanReady','recordedUTC','authorizationMode','mainConsentSHA256','sourceSHA256','windowSHA256') if key in gate})
                if is_main(run.manifest):view['observation']='not-implied-by-authorization'
                else:
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
        if safe(root,'anchor.json').exists():
            context=__import__('continuity').Bootstrap(root,run.synthetic,run.clock,archived=True)
            for name,value in bootstrap_public(context).items():indexed[name]=publish(name,value)
        public_global = {key:run.manifest[key] for key in ('namespace','synthetic','startUTC','globalDeadlineUTC','p0ExpiryUTC','certificateNotAfterUTC','sourceSHA256','fixtureSHA256','grantSHA256','hostBindingSHA256')}
        public_global.update({key:run.manifest[key] for key in ('anchorSHA256','window1SHA256','actualSetupProofSHA256','setupProofBindingSHA256') if key in run.manifest})
        public_global.update({key:run.manifest[key] for key in ('authorizationMode','mainConsentSHA256','buildEvidenceType','guiBeginSyncSHA256','rootBindingSHA256','originalLeafReferenceSHA256','originalCertificateSHA256') if key in run.manifest})
        if is_main(run.manifest):
            consent,consent_sha=read(root,'main-consent.json')
            view={key:consent[key] for key in ('kind','authorizationMode','namespace','synthetic','approved','approvedUTC','latestStartUTC','grantsValidUntilUTC','sourceSHA256','actions','maxMainSignedBuilds','maxCleanupSignedBuilds')}
            view.update(privateConsentSHA256=consent_sha,statementPresent=True,observationsNotImplied=True)
            indexed['main-consent.public.json']=publish('main-consent.public.json',view)
        if is_main(run.manifest):
            for name,value in build_public_views(run).items():indexed[name]=publish(name,value)
        public_global['privateGlobalSHA256']=run.global_hash
        indexed['global.public.json'] = publish('global.public.json', public_global)
        pre_sha=publish('pre-cleanup.index.json', {'namespace':run.namespace, 'synthetic':run.synthetic, 'files':dict(indexed), 'privateCleanupConfirmed':False})
        indexed['pre-cleanup.index.json']=pre_sha
        if is_main(run.manifest):
            number=max(n for n in (1,2,3) if safe(root,'windows/'+str(n)+'.json').exists());run.window(number,cleanup=True);check_main(run)
            absence=[]
            for relative in ['receipts/cleanup.machine.json',*[str(p.relative_to(root)) for p in safe(root,'recovery').glob('*.machine.json')],*[str(p.relative_to(root)) for p in safe(root,'recovery-attempts').glob('*/machine.json')]]:
                if safe(root,relative).exists():absence.append(read(root,relative)[0])
            if not any(v.get('completed') is True and v.get('absent') is True for v in absence):raise Rejected('exactItemAbsenceRequired')
            ack_path=safe(root,'publication-ack.json')
            if not ack_path.exists():return False  # Safe pre-index is reviewable; raw stays private pending actual ACK.
            ack,_=read(root,'publication-ack.json')
            if (ack.get('kind')!='safe-candidate-model-ack' or ack.get('namespace')!=run.namespace or ack.get('globalSHA256')!=run.global_hash or ack.get('candidateIndexSHA256')!=pre_sha or ack.get('readabilityAcknowledged') is not True or ack.get('safetyAcknowledged') is not True or not stamp(run.manifest['startUTC'])<=stamp(ack.get('recordedUTC'))<=run.clock()):raise Rejected('safeEvidenceACKRequired')
        if gui_mode:
            module=__import__('gui_build');module.closed_for_cleanup(run)
            output=module.copy_candidate(output,public_output)
        # Export is durable first. Refuse symlinks or uncertain owned processes before private deletion.
        self.ensure_exited()
        if is_main(run.manifest):
            run.window(number,cleanup=True);check_main(run)
            if any(path.stat().st_uid!=os.getuid() for path in root.rglob('*')):raise Rejected('privateOwnershipUnconfirmed')
        if any(path.is_symlink() for path in root.rglob('*')): raise Rejected('privateSymlinkRecoveryRequired')
        shutil.rmtree(root)
        if root.exists(): raise Rejected('privateCleanupIncomplete')
        completion = {'namespace':run.namespace, 'synthetic':run.synthetic, 'privateRootAbsent':True,
                      'cleanupComplete':True, 'recoveryRequired':False, 'endedUTC':utc().isoformat(),
                      'appleDeveloperAssetsRetained':True,'GUIProjectClosedNoHandlesConfirmed':gui_mode}
        indexed['private-cleanup.machine.json'] = publish('private-cleanup.machine.json', completion)
        publish('final.index.json', {'namespace':run.namespace, 'synthetic':run.synthetic, 'files':indexed, 'cleanupComplete':True})
        return True

    def inspect_recovery(self,attempt):
        run=self.run;grant,ready=__import__('continuity').require_recovery(run,attempt)
        self.ensure_exited()
        gui_recovery=run.manifest.get('authorizationMode')=='gui-package'
        selection,_=read(run.root,'selection/recovery.json' if gui_recovery else 'recovery-attempts/'+attempt+'/selection.json')
        asset=__import__('gui_build').accepted_asset(run,'recovery') if gui_recovery else inspect_selected(selection,run)
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
        if stage=='seed':exclusive(run.root,'write-attempts/'+ticket_id+'.launch.json',{'namespace':run.namespace,'synthetic':False,'operation':'seed-read-a','state':'launch-may-add','ticket':ticket_id,'proofSHA256':proof_sha,'recordedUTC':utc().isoformat()})
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
        if is_main(run.manifest):return
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
