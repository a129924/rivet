"""E010 fixed three-window protocol. No background work; live backend is lazy/grant gated."""
import argparse
import datetime as dt
import hashlib
import json
import os
import re
from pathlib import Path
import stat
import time
import uuid

UTC = dt.timezone.utc
FIELDS = ('accessToken', 'refreshToken', 'accessTokenExpiresAt', 'refreshTokenExpiresAt', 'tokenType', 'grantedScopes')
FAKE_A = dict(zip(FIELDS, ('fake-access-A', 'fake-refresh-A', 2000000120.125, 2000008640.5, 'bearer', 'repo read:user')))
STAGES = {1: ('preflight', 'seed', 'fresh'), 2: ('expired', 'p1-setup', 'p1-read'), 3: ('rebuild-setup', 'rebuilt-read', 'cleanup')}
ORDER = sum(STAGES.values(), ())


class Rejected(Exception):
    """Finite classifications only; never expose raw asset/process diagnostics."""


def utc():
    return dt.datetime.now(UTC)


def stamp(value):
    if not isinstance(value, str): raise Rejected('invalidTime')
    try:
        value = dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
        if value.tzinfo is None: raise ValueError()
        return value.astimezone(UTC)
    except ValueError: raise Rejected('invalidTime') from None


def canonical(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + '\n').encode('utf-8')


def digest(raw): return hashlib.sha256(raw).hexdigest()


def file_hash(path): return digest(Path(path).read_bytes())


def safe(root, relative):
    root = Path(root)
    rel = Path(relative)
    if not root.is_dir() or root.is_symlink() or rel.is_absolute() or '..' in rel.parts:
        raise Rejected('unsafePath')
    for part in [root, *root.parents]:
        if part.is_symlink(): raise Rejected('unsafePath')
    current = root
    for part in rel.parts:
        current /= part
        if current.is_symlink(): raise Rejected('unsafePath')
    if not current.resolve().is_relative_to(root.resolve()): raise Rejected('unsafePath')
    return current


def private_root(root, namespace, synthetic):
    root = Path(root)
    try: valid = str(uuid.UUID(namespace)) == namespace
    except (ValueError, TypeError): valid = False
    if not valid or root.name != 'rivet-E010-' + namespace: raise Rejected('namespaceRejected')
    safe(root, '.')
    if root.stat().st_uid != os.getuid() or stat.S_IMODE(root.stat().st_mode) != 0o700:
        raise Rejected('privateRootRejected')
    if not synthetic:
        if any((p/'.git').exists() for p in [root, *root.parents]): raise Rejected('persistentRootRequired')
        if root.resolve().is_relative_to(Path('/private/tmp')) or root.resolve().is_relative_to(Path('/tmp').resolve()) or root.resolve().is_relative_to(Path('/private/var/folders')):
            raise Rejected('persistentRootRequired')
    return root


def exclusive(root, relative, value):
    path = safe(root, relative)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    raw = canonical(value)
    try: fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    except FileExistsError: raise Rejected('immutableFileExists') from None
    with os.fdopen(fd, 'wb') as stream:
        stream.write(raw)
        stream.flush()
        os.fsync(stream.fileno())
    return digest(raw)


def read(root, relative):
    raw = safe(root, relative).read_bytes()
    try: value = json.loads(raw)
    except (ValueError, UnicodeError): raise Rejected('invalidJSON') from None
    if raw != canonical(value): raise Rejected('nonCanonicalJSON')
    return value, digest(raw)


def checked_grant(grant, kind, namespace, root, deadline, synthetic):
    if (grant.get('kind') != 'human-grant' or grant.get('scope') != kind or
            grant.get('namespace') != namespace or grant.get('synthetic') is not synthetic or
            grant.get('approved') is not True or not isinstance(grant.get('statement'), str) or
            not grant['statement'].strip() or grant.get('retentionRoot') != str(Path(root)) or
            stamp(grant.get('validUntilUTC')) < deadline):
        raise Rejected('matchingHumanGrantRequired')
    if kind == 'recovery' and (not grant.get('procedure') or not grant.get('residualItemAccepted')):
        raise Rejected('recoveryPlanRequired')
    return digest(canonical(grant))


def local_identity(synthetic):
    if synthetic: return {'mac':'synthetic-mac', 'uid':1}
    # Private hardware binding, distinct from ProvisioningUDID used for profile membership.
    # In-process OS read only; never runs during preparation or synthetic tests.
    import ctypes as ct
    cf=ct.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
    io=ct.CDLL('/System/Library/Frameworks/IOKit.framework/IOKit')
    cf.CFStringCreateWithCString.argtypes=[ct.c_void_p,ct.c_char_p,ct.c_uint32];cf.CFStringCreateWithCString.restype=ct.c_void_p
    cf.CFStringGetCString.argtypes=[ct.c_void_p,ct.c_void_p,ct.c_long,ct.c_uint32];cf.CFStringGetCString.restype=ct.c_bool
    cf.CFRelease.argtypes=[ct.c_void_p]
    io.IOServiceMatching.argtypes=[ct.c_char_p];io.IOServiceMatching.restype=ct.c_void_p
    io.IOServiceGetMatchingService.argtypes=[ct.c_uint,ct.c_void_p];io.IOServiceGetMatchingService.restype=ct.c_uint
    io.IORegistryEntryCreateCFProperty.argtypes=[ct.c_uint,ct.c_void_p,ct.c_void_p,ct.c_uint];io.IORegistryEntryCreateCFProperty.restype=ct.c_void_p
    io.IOObjectRelease.argtypes=[ct.c_uint]
    service=io.IOServiceGetMatchingService(0,io.IOServiceMatching(b'IOPlatformExpertDevice'))
    if not service: raise Rejected('hostBindingUnavailable')
    key=cf.CFStringCreateWithCString(None,b'IOPlatformUUID',0x08000100);value=None
    try:
        value=io.IORegistryEntryCreateCFProperty(service,key,None,0);buffer=ct.create_string_buffer(128)
        if not value or not cf.CFStringGetCString(value,buffer,len(buffer),0x08000100): raise Rejected('hostBindingUnavailable')
        mac=buffer.value.decode('ascii');uuid.UUID(mac)
        return {'mac':mac,'uid':os.getuid()}
    finally:
        if value: cf.CFRelease(value)
        if key: cf.CFRelease(key)
        io.IOObjectRelease(service)


def authorize(root, manifest, now, synthetic):
    private_root(root, manifest['namespace'], synthetic)
    if manifest.get('synthetic') is not synthetic or manifest.get('backend') != 'dpk': raise Rejected('backendRejected')
    if (manifest.get('kind') not in ('E010-global', 'E010-anchor') or
            manifest.get('service') != 'local.rivet.experiments.E010.' + manifest['namespace'] or
            manifest.get('bundleIdentifier') != 'local.rivet.dpkcontinuity.' + manifest['namespace'].replace('-', '') or
            manifest.get('account') != 'oauth-bundle'):
        raise Rejected('experimentIdentityRejected')
    identity=manifest.get('hostBinding')
    if not isinstance(identity,dict) or identity != local_identity(synthetic) or manifest.get('hostBindingSHA256') != digest(canonical(identity)): raise Rejected('hostBindingChanged')
    start, deadline = stamp(manifest['startUTC']), stamp(manifest['globalDeadlineUTC'])
    if deadline - start != dt.timedelta(days=10) or start > now: raise Rejected('globalWindowRejected')
    for kind in ('assets', 'retention', 'recovery'):
        grant, sha = read(root, 'grants/' + kind + '.json')
        checked_grant(grant, kind, manifest['namespace'], root, deadline, synthetic)
        if manifest['grantSHA256'].get(kind) != sha: raise Rejected('grantChanged')
    if is_main(manifest):
        _,sha=main_consent(root,manifest['namespace'],manifest['sourceSHA256'],synthetic,now,start)
        if sha!=manifest.get('mainConsentSHA256'): raise Rejected('mainPackageChanged')
    return True


def create_global(root, namespace, p0_expiry, certificate_expiry, source_hashes, synthetic=False, clock=utc, public_out=None):
    if not synthetic: raise Rejected('bootstrapAnchorRequired')  # Historical pure fixtures only; never a live entry.
    root = private_root(root, namespace, synthetic)
    if not synthetic and not public_out: raise Rejected('publicEvidenceDestinationRequired')
    if public_out and Path(public_out).resolve().is_relative_to(root.resolve()): raise Rejected('publicEvidenceOutsidePrivateRootRequired')
    now = clock(); deadline = now + dt.timedelta(days=10)
    # Dates are immutable proposed constraints; actual selected material MUST match before seed.
    if not now < stamp(p0_expiry) <= deadline - dt.timedelta(minutes=30): raise Rejected('p0ExpiryOutsideBudget')
    if stamp(certificate_expiry) < deadline + dt.timedelta(minutes=35): raise Rejected('certificateTooShort')
    grants = {}
    for kind in ('assets', 'retention', 'recovery'):
        value, sha = read(root, 'grants/' + kind + '.json')
        checked_grant(value, kind, namespace, root, deadline, synthetic); grants[kind] = sha
    identity=local_identity(synthetic)
    manifest = {'hostBinding':identity, 'hostBindingSHA256':digest(canonical(identity)), 'kind': 'E010-global', 'namespace': namespace, 'synthetic': synthetic, 'backend': 'dpk',
                'startUTC': now.isoformat(), 'globalDeadlineUTC': deadline.isoformat(), 'maxWindows': 3,
                'p0ExpiryUTC': p0_expiry, 'certificateNotAfterUTC': certificate_expiry,
                'grantSHA256': grants, 'sourceSHA256': source_hashes,
                'bundleIdentifier': 'local.rivet.dpkcontinuity.' + namespace.replace('-', ''),
                'service': 'local.rivet.experiments.E010.' + namespace, 'account': 'oauth-bundle',
                'fixture': FAKE_A, 'fixtureSHA256': digest(canonical(FAKE_A)),
                'publicEvidenceDirectory': str(Path(public_out).resolve()) if public_out else None}
    sha = exclusive(root, 'global.json', manifest)
    exclusive(root, 'global.binding.json', {'globalSHA256': sha})
    return manifest


def matching_write(root,relative,value):
    path=safe(root,relative);raw=canonical(value)
    if path.exists():
        if path.read_bytes()!=raw: raise Rejected('partialBootstrapChanged')
        return digest(raw)
    return exclusive(root,relative,value)


# Current Human-approved MAIN package only. Historical per-stage mode is unchanged.
MAIN_STATEMENT = '確認批准整包，包含跨週留存、本人認證／跨日喚起，以及第7項故障殘留交接例外。'
MAIN_S = '2026-11-04T08:56:05Z'
MAIN_LATEST = '2026-11-05T08:56:05Z'
MAIN_VALID = '2026-11-15T08:56:05Z'


def is_main(manifest):
    mode=manifest.get('authorizationMode')
    if mode not in (None,'main-package','gui-package'): raise Rejected('authorizationModeRejected')
    return mode in ('main-package','gui-package')


def main_consent(root, namespace, source, synthetic, now, start=None):
    consent,sha=read(root,'main-consent.json');mode=consent.get('authorizationMode');gui=mode=='gui-package'
    approved='2026-11-05T07:14:10Z' if gui else MAIN_S
    latest='2026-11-06T07:14:10Z' if gui else MAIN_LATEST
    valid='2026-11-16T07:14:10Z' if gui else MAIN_VALID
    kind='E010-gui-package-consent' if gui else 'E010-main-package-consent'
    statement=consent.get('statement')
    if (consent.get('kind')!=kind or mode not in ('main-package','gui-package') or consent.get('namespace')!=namespace or
        consent.get('synthetic') is not synthetic or consent.get('approved') is not True or not isinstance(statement,str) or not statement.strip() or
        (not gui and statement!=MAIN_STATEMENT) or consent.get('approvedUTC')!=approved or consent.get('latestStartUTC')!=latest or
        consent.get('grantsValidUntilUTC')!=valid or consent.get('retentionRoot')!=str(Path(root)) or consent.get('sourceSHA256')!=source or
        consent.get('actions')!=list(ORDER) or consent.get('maxMainSignedBuilds')!=3 or consent.get('maxCleanupSignedBuilds')!=1 or
        now<stamp(approved) or now>=stamp(valid)):raise Rejected('mainPackageConsentRejected')
    if gui and (consent.get('originalLeafBeforeAutoRequired') is not True or consent.get('automaticCertificateSideEffectsAccepted') is not True or consent.get('CUAProhibited') is not True or consent.get('buildEvidenceType')!='gui-hooks-v1'):raise Rejected('GUIApprovedPolicyRequired')
    first=now if start is None else start
    if not stamp(approved)<=first<=stamp(latest) or now>=first+dt.timedelta(days=10):raise Rejected('mainPackageTimeRejected')
    for kind in ('assets','retention','recovery'):
        grant,_=read(root,'grants/'+kind+'.json');checked_grant(grant,kind,namespace,root,first+dt.timedelta(days=10),synthetic)
        if grant.get('authorizationMode')!=mode or grant.get('mainConsentSHA256')!=sha or grant.get('sourceSHA256')!=source or grant.get('validUntilUTC')!=valid:raise Rejected('mainPackageGrantRejected')
    return consent,sha


def check_main(context):
    manifest=context.manifest
    if not is_main(manifest): raise Rejected('mainPackageRequired')
    _,sha=main_consent(context.root,manifest['namespace'],manifest['sourceSHA256'],context.synthetic,context.clock(),stamp(manifest['startUTC']))
    if sha!=manifest.get('mainConsentSHA256'): raise Rejected('mainPackageChanged')
    return sha


def package_gate(context, stage, previous, relative, number=1):
    consent_sha=check_main(context)
    if isinstance(context,Bootstrap): window,window_sha=context.validate()
    else: window,window_sha=context.window(number,cleanup=stage in ('cleanup','cleanup-only'))
    path=safe(context.root,relative)
    gate={'kind':'package-action','authorizationMode':context.manifest['authorizationMode'],'namespace':context.manifest['namespace'],
          'synthetic':context.synthetic,'stage':stage,'mainConsentSHA256':consent_sha,
          'sourceSHA256':context.manifest['sourceSHA256'],'windowSHA256':window_sha,
          'previousReceiptSHA256':previous,'recordedUTC':context.clock().isoformat()}
    if context.manifest.get('kind')=='E010-global':gate['globalSHA256']=context.global_hash
    else:gate['anchorSHA256']=context.anchor_hash
    if path.exists():
        existing,_=read(context.root,relative);gate['recordedUTC']=existing.get('recordedUTC')
        if gate!=existing: raise Rejected('packageActionChanged')
    else:exclusive(context.root,relative,gate)
    validate_package_gate(context,stage,gate,previous,number)
    return gate,file_hash(path)


def validate_package_gate(context,stage,gate,previous,number,archived=False):
    consent_sha=check_main(context)
    window,window_sha=(context.validate() if isinstance(context,Bootstrap) else context.window(number,cleanup=True,archived=archived))
    if (gate.get('kind')!='package-action' or gate.get('authorizationMode')!=context.manifest['authorizationMode'] or
        gate.get('namespace')!=context.manifest['namespace'] or gate.get('synthetic') is not context.synthetic or
        gate.get('stage')!=stage or gate.get('mainConsentSHA256')!=consent_sha or gate.get('sourceSHA256')!=context.manifest['sourceSHA256'] or
        gate.get('windowSHA256')!=window_sha or gate.get('previousReceiptSHA256')!=previous or
        any(key in gate for key in ('humanReady','humanReadyStatement','wholeStageObserved','promptCount')) or
        not stamp(window['startUTC'])<=stamp(gate.get('recordedUTC'))<=context.clock()): raise Rejected('packageActionRejected')
    key='globalSHA256' if context.manifest['kind']=='E010-global' else 'anchorSHA256'
    if gate.get(key)!=(context.global_hash if key=='globalSHA256' else context.anchor_hash): raise Rejected('packageActionRejected')


def observation_status(run,stage):
    path=safe(run.root,'human/'+stage+'.json')
    unknown={'observation':'not-observed','promptCount':None,'UX':'unknown','humanReceiptSHA256':None}
    if not path.exists():return unknown
    event,sha=read(run.root,'receipts/'+stage+'.machine.json');human,human_sha=read(run.root,'human/'+stage+'.json')
    try:validate_human(human,event,sha,run.synthetic,run.clock(),enforce_ux=False)
    except Rejected:return unknown
    limit=1 if stage=='seed' else 0
    return {'observation':'whole-stage-human','promptCount':human['promptCount'],'UX':'failed' if human['promptCount']>limit and stage in ('seed','fresh','p1-read','rebuilt-read') else 'observed','humanReceiptSHA256':human_sha}


def begin_anchor(root,namespace,source_sha,public_out,synthetic=False,clock=utc):
    root=private_root(root,namespace,synthetic);now=clock();deadline=now+dt.timedelta(days=10)
    if not public_out or Path(public_out).resolve().is_relative_to(root.resolve()): raise Rejected('publicEvidenceOutsidePrivateRootRequired')
    grants={}
    for kind in ('assets','retention','recovery'):
        grant,sha=read(root,'grants/'+kind+'.json');checked_grant(grant,kind,namespace,root,deadline,synthetic);grants[kind]=sha
    package=safe(root,'main-consent.json').exists()
    if package:
        consent,ready_sha=main_consent(root,namespace,source_sha,synthetic,now)
    else:
        ready,ready_sha=read(root,'bootstrap/begin.ready.json')
        if (ready.get('namespace')!=namespace or ready.get('synthetic') is not synthetic or ready.get('stage')!='begin-anchor' or ready.get('humanReady') is not True or not isinstance(ready.get('humanReadyStatement'),str) or not ready['humanReadyStatement'].strip() or ready.get('sourceSHA256')!=source_sha or ready.get('grantSHA256')!=grants or ready.get('retentionRoot')!=str(root) or not now-dt.timedelta(minutes=5)<=stamp(ready.get('recordedUTC'))<=now): raise Rejected('beginReadyRequired')
    sync_sha=None
    if package and consent['authorizationMode']=='gui-package':
        sync,sync_sha=read(root,'gui-begin-sync.json')
        if (sync.get('kind')!='human-begin-sync' or sync.get('namespace')!=namespace or sync.get('synthetic') is not synthetic or sync.get('sourceSHA256')!=source_sha or sync.get('grantSHA256')!=grants or sync.get('retentionRoot')!=str(root) or sync.get('humanCanBeginNow') is not True or not isinstance(sync.get('statement'),str) or not sync['statement'].strip() or not stamp(consent['approvedUTC'])<=stamp(sync.get('recordedUTC'))<=now):raise Rejected('GUIBeginSyncRequired')
    identity=local_identity(synthetic)
    anchor={'kind':'E010-anchor','namespace':namespace,'synthetic':synthetic,'backend':'dpk','startUTC':now.isoformat(),'globalDeadlineUTC':deadline.isoformat(),'maxWindows':3,'hostBinding':identity,'hostBindingSHA256':digest(canonical(identity)),'sourceSHA256':source_sha,'grantSHA256':grants,'beginReadySHA256':ready_sha,'bundleIdentifier':'local.rivet.dpkcontinuity.'+namespace.replace('-',''),'service':'local.rivet.experiments.E010.'+namespace,'account':'oauth-bundle','fixture':FAKE_A,'fixtureSHA256':digest(canonical(FAKE_A)),'publicEvidenceDirectory':str(Path(public_out).resolve())}
    if package:
        anchor.pop('beginReadySHA256');anchor.update(authorizationMode=consent['authorizationMode'],mainConsentSHA256=ready_sha)
        if consent['authorizationMode']=='gui-package':
            binding=root.stat();root_binding={'device':binding.st_dev,'inode':binding.st_ino,'ownerUID':binding.st_uid,'mode':binding.st_mode & 0o777}
            anchor.update(buildEvidenceType='gui-hooks-v1',guiBeginSyncSHA256=sync_sha,rootBinding=root_binding,rootBindingSHA256=digest(canonical(root_binding)))
    sha=exclusive(root,'anchor.json',anchor);exclusive(root,'anchor.binding.json',{'anchorSHA256':sha})
    window={'namespace':namespace,'synthetic':synthetic,'number':1,'anchorSHA256':sha,'startUTC':now.isoformat(),'cutoffUTC':(now+dt.timedelta(minutes=25)).isoformat(),'deadlineUTC':(now+dt.timedelta(minutes=30)).isoformat(),'beginReadySHA256':ready_sha}
    if package:
        window.pop('beginReadySHA256');window.update(authorizationMode=consent['authorizationMode'],mainConsentSHA256=ready_sha)
    window_sha=exclusive(root,'windows/1.json',window);exclusive(root,'windows/1.binding.json',{'windowSHA256':window_sha})
    exclusive(root,'bootstrap/begin.machine.json',{'namespace':namespace,'synthetic':synthetic,'stage':'begin-anchor','anchorSHA256':sha,'windowSHA256':window_sha,'startedUTC':now.isoformat(),'endedUTC':clock().isoformat(),'callAttempted':False,'OSStatus':None,'promptCount':None})
    return anchor


class Bootstrap:
    """Only first-setting bookkeeping/selected inspection; never an App executor context."""
    def __init__(self,root,synthetic=False,clock=utc,archived=False):
        self.root,self.synthetic,self.clock=Path(root),synthetic,clock
        self.archive_only=archived
        self.manifest,self.anchor_hash=read(self.root,'anchor.json');self.namespace=self.manifest['namespace']
        binding,_=read(self.root,'anchor.binding.json')
        if binding!={'anchorSHA256':self.anchor_hash} or self.manifest.get('kind')!='E010-anchor' or 'p0ExpiryUTC' in self.manifest or 'certificateNotAfterUTC' in self.manifest: raise Rejected('anchorChanged')
        self.validate(cleanup=True)
    def validate(self,cleanup=False):
        authorize(self.root,self.manifest,self.clock(),self.synthetic)
        from proof import source_hashes
        if source_hashes()!=self.manifest['sourceSHA256']: raise Rejected('sourceChanged')
        if is_main(self.manifest):check_main(self)
        else:
            begin,_=read(self.root,'bootstrap/begin.ready.json')
            if file_hash(safe(self.root,'bootstrap/begin.ready.json'))!=self.manifest['beginReadySHA256']: raise Rejected('beginReadyChanged')
        window,sha=read(self.root,'windows/1.json');binding,_=read(self.root,'windows/1.binding.json')
        start=stamp(self.manifest['startUTC'])
        if (binding!={'windowSHA256':sha} or window.get('anchorSHA256')!=self.anchor_hash or 'globalSHA256' in window or window.get('namespace')!=self.namespace or window.get('synthetic') is not self.synthetic or window.get('number')!=1 or stamp(window['startUTC'])!=start or stamp(window['cutoffUTC'])!=start+dt.timedelta(minutes=25) or stamp(window['deadlineUTC'])!=start+dt.timedelta(minutes=30)): raise Rejected('bootstrapWindowChanged')
        if is_main(self.manifest) and not self.archive_only and cleanup and (self.clock()>=stamp(window['deadlineUTC']) or self.clock()>=stamp(self.manifest['globalDeadlineUTC'])):raise Rejected('mainCleanupDeadline')
        if self.archive_only and not cleanup:raise Rejected('archiveOnlyContext')
        if not cleanup and (self.clock()>=stamp(window['cutoffUTC']) or safe(self.root,'abort.json').exists()): raise Rejected('measurementDeadline')
        return window,sha
    def setup_ready(self):
        if is_main(self.manifest):
            window,_=self.validate();machine,machine_sha=read(self.root,'bootstrap/begin.machine.json')
            if stamp(machine['endedUTC'])>self.clock(): raise Rejected('packageActionTimeRejected')
            return package_gate(self,'setup-only',machine_sha,'bootstrap/setup.ready.json')[1]
        window,window_sha=self.validate();gate,sha=read(self.root,'bootstrap/setup.ready.json')
        machine,machine_sha=read(self.root,'bootstrap/begin.machine.json');human,human_sha=read(self.root,'bootstrap/begin.human.json')
        validate_human(human,machine,machine_sha,self.synthetic,self.clock())
        if (gate.get('namespace')!=self.namespace or gate.get('synthetic') is not self.synthetic or gate.get('stage')!='setup-only' or gate.get('anchorSHA256')!=self.anchor_hash or gate.get('windowSHA256')!=window_sha or gate.get('grantSHA256')!=self.manifest['grantSHA256'] or gate.get('sourceSHA256')!=self.manifest['sourceSHA256'] or gate.get('previousReceiptSHA256')!=machine_sha or gate.get('previousHumanSHA256')!=human_sha or gate.get('humanReady') is not True or not isinstance(gate.get('humanReadyStatement'),str) or not gate['humanReadyStatement'].strip() or not stamp(human['recordedUTC'])<stamp(gate.get('recordedUTC'))<=self.clock()): raise Rejected('setupReadyRequired')
        return sha


def bootstrap_asset(context,asset,at=None):
    from proof import validate_asset
    view=dict(context.manifest,p0ExpiryUTC=asset['profileExpiryUTC'],certificateNotAfterUTC=asset['certificateNotAfterUTC'])
    if stamp(view['p0ExpiryUTC'])>stamp(view['globalDeadlineUTC'])-dt.timedelta(minutes=30): raise Rejected('p0ExpiryOutsideBudget')
    validate_asset(asset,view,context.clock() if at is None else at,phase='p0')
    if context.manifest.get('authorizationMode')=='gui-package':
        from gui_build import reference
        leaf,leaf_sha=reference(context)
        if asset.get('certificateSHA256')!=leaf['certificateSHA256'] or asset.get('evidenceType')!='gui-hooks-v1':raise Rejected('originalLeafMismatch')
        view.update(originalLeafReferenceSHA256=leaf_sha,originalCertificateSHA256=leaf['certificateSHA256'],buildEvidenceType='gui-hooks-v1')
    return view


def complete_global(context):
    from proof import app_hash
    ready_sha=context.setup_ready();window,window_sha=context.validate()
    asset,proof_sha=read(context.root,'bootstrap/actual-proof.json');proof_binding,binding_sha=read(context.root,'bootstrap/proof.binding.json')
    if proof_binding!={'anchorSHA256':context.anchor_hash,'windowSHA256':window_sha,'setupReadySHA256':ready_sha,'actualProofSHA256':proof_sha}: raise Rejected('setupProofChanged')
    if app_hash(Path(asset['frozenHost']))!=asset['appSHA256']: raise Rejected('frozenHostChanged')
    manifest=bootstrap_asset(context,asset);manifest.update(kind='E010-global',anchorSHA256=context.anchor_hash,window1SHA256=window_sha,actualSetupProofSHA256=proof_sha,setupProofBindingSHA256=binding_sha)
    global_sha=matching_write(context.root,'global.json',manifest)
    matching_write(context.root,'global.binding.json',{'globalSHA256':global_sha})
    matching_write(context.root,'proofs/p0.json',asset)
    marker_path=safe(context.root,'bootstrap/complete.json')
    if marker_path.exists():
        marker,_=read(context.root,'bootstrap/complete.json')
        if safe(context.root,'bootstrap/setup.machine.json').exists(): raise Rejected('immutableFileExists')
        completed=marker['completedUTC']
    else: completed=context.clock().isoformat()
    marker={'globalSHA256':global_sha,'anchorSHA256':context.anchor_hash,'windowSHA256':window_sha,'actualProofSHA256':proof_sha,'completedUTC':completed}
    marker_sha=matching_write(context.root,'bootstrap/complete.json',marker)
    matching_write(context.root,'bootstrap/setup.machine.json',dict(public_result(asset),namespace=context.namespace,synthetic=context.synthetic,stage='setup-only',globalSHA256=global_sha,anchorSHA256=context.anchor_hash,windowSHA256=window_sha,actualProofSHA256=proof_sha,completionSHA256=marker_sha,startedUTC=window['startUTC'],endedUTC=completed,completed=True,callAttempted=False,OSStatus=None,promptCount=None))
    return manifest


def bootstrap_complete(root,manifest,global_sha,synthetic,clock):
    context=Bootstrap(root,synthetic,clock,archived=True);window,window_sha=context.validate(cleanup=True)
    asset,proof_sha=read(root,'bootstrap/actual-proof.json');pb,pb_sha=read(root,'bootstrap/proof.binding.json')
    marker,marker_sha=read(root,'bootstrap/complete.json')
    completed=stamp(marker['completedUTC'])
    if not stamp(context.manifest['startUTC'])<=completed<stamp(window['cutoffUTC']) or completed>clock(): raise Rejected('partialBootstrap')
    expected=bootstrap_asset(context,asset,completed);expected.update(kind='E010-global',anchorSHA256=context.anchor_hash,window1SHA256=window_sha,actualSetupProofSHA256=proof_sha,setupProofBindingSHA256=pb_sha)
    if manifest!=expected or pb!={'anchorSHA256':context.anchor_hash,'windowSHA256':window_sha,'setupReadySHA256':file_hash(safe(root,'bootstrap/setup.ready.json')),'actualProofSHA256':proof_sha} or file_hash(safe(root,'proofs/p0.json'))!=proof_sha: raise Rejected('bootstrapChainChanged')
    marker,marker_sha=read(root,'bootstrap/complete.json');machine,_=read(root,'bootstrap/setup.machine.json')
    if marker.get('globalSHA256')!=global_sha or marker.get('anchorSHA256')!=context.anchor_hash or marker.get('windowSHA256')!=window_sha or marker.get('actualProofSHA256')!=proof_sha or machine.get('completionSHA256')!=marker_sha or machine.get('globalSHA256')!=global_sha: raise Rejected('partialBootstrap')
    return context


def seed_ready(run):
    if is_main(run.manifest):
        machine,machine_sha=read(run.root,'bootstrap/setup.machine.json')
        if machine.get('completed') is not True or stamp(machine['endedUTC'])>run.clock():raise Rejected('partialBootstrap')
        return package_gate(run,'seed-ready',machine_sha,'bootstrap/seed.ready.json')
    gate,sha=read(run.root,'bootstrap/seed.ready.json');machine,machine_sha=read(run.root,'bootstrap/setup.machine.json');human,human_sha=read(run.root,'bootstrap/setup.human.json')
    validate_human(human,machine,machine_sha,run.synthetic,run.clock())
    if (gate.get('namespace')!=run.namespace or gate.get('synthetic') is not run.synthetic or gate.get('stage')!='seed-ready' or gate.get('globalSHA256')!=run.global_hash or gate.get('anchorSHA256')!=run.manifest['anchorSHA256'] or gate.get('windowSHA256')!=run.manifest['window1SHA256'] or gate.get('previousReceiptSHA256')!=machine_sha or gate.get('previousHumanSHA256')!=human_sha or gate.get('humanReady') is not True or not isinstance(gate.get('humanReadyStatement'),str) or not gate['humanReadyStatement'].strip() or not stamp(human['recordedUTC'])<stamp(gate.get('recordedUTC'))<=run.clock()): raise Rejected('independentSeedReadyRequired')
    return gate,sha


def validate_human(value, machine, machine_sha, synthetic, now=None, enforce_ux=True):
    allowed = {'namespace', 'synthetic', 'stage', 'machineReceiptSHA256', 'wholeStageObserved', 'phaseIdentified', 'promptCount', 'actions', 'purposes', 'recordedUTC'}
    if set(value) - allowed: raise Rejected('humanPublicSchemaRejected')
    count = value.get('promptCount')
    if (value.get('synthetic') is not synthetic or value.get('namespace') != machine['namespace'] or
            value.get('stage') != machine['stage'] or value.get('machineReceiptSHA256') != machine_sha or
            value.get('wholeStageObserved') is not True or value.get('phaseIdentified') is not True or
            type(count) is not int or count < 0): raise Rejected('humanObservationRejected')
    for key in ('actions', 'purposes'):
        if not isinstance(value.get(key), list) or len(value[key]) != count or any(not isinstance(x, str) or not x.strip() for x in value[key]):
            raise Rejected('humanObservationRejected')
    if any(x not in {'允許', '永遠允許', '拒絕', '密碼', '指紋', '其他（私有紀錄）'} for x in value['actions']) or any(x not in {'設定／簽章', '憑證存取', '清理', '其他（私有紀錄）'} for x in value['purposes']): raise Rejected('humanPublicSchemaRejected')
    observed=stamp(value.get('recordedUTC'))
    if observed < stamp(machine['endedUTC']) or observed > (now if now is not None else utc()): raise Rejected('humanObservationTimeRejected')
    limit = 1 if machine['stage'] == 'seed' else 0
    if enforce_ux and machine['stage'] in ('seed', 'fresh', 'p1-read', 'rebuilt-read') and count > limit:
        raise Rejected('uxCriterionExceeded')


class Run:
    def __init__(self, root, synthetic=False, clock=utc):
        self.root, self.synthetic, self.clock = Path(root), synthetic, clock
        self.manifest, self.global_hash = read(self.root, 'global.json')
        binding, _ = read(self.root, 'global.binding.json')
        if binding.get('globalSHA256') != self.global_hash: raise Rejected('manifestChanged')
        self.namespace = self.manifest['namespace']
        authorize(root, self.manifest, clock(), synthetic)
        if safe(self.root,'anchor.json').exists() or not synthetic: bootstrap_complete(self.root,self.manifest,self.global_hash,synthetic,clock)
        self.reload()

    def reload(self):
        self.events = []
        previous = self.global_hash
        gap = False
        for stage in ORDER:
            path = safe(self.root, 'receipts/' + stage + '.machine.json')
            if not path.exists(): gap = True; continue
            if gap: raise Rejected('stageOrderRejected')
            value, sha = read(self.root, str(path.relative_to(self.root)))
            if (value.get('namespace') != self.namespace or value.get('stage') != stage or
                    value.get('synthetic') is not self.synthetic or value.get('globalSHA256') != self.global_hash or
                    value.get('previousSHA256') != previous): raise Rejected('receiptChainChanged')
            self.events.append((value, sha)); previous = sha

    def arm_window(self, number, ready):
        authorize(self.root, self.manifest, self.clock(), self.synthetic)
        now = self.clock(); start = stamp(self.manifest['startUTC']) if number == 1 else now
        if type(number) is not int or number not in STAGES or (not is_main(self.manifest) and (not isinstance(ready,str) or not ready.strip())):raise Rejected('windowOrReadyRejected')
        if now >= stamp(self.manifest['globalDeadlineUTC']) or now >= start + dt.timedelta(minutes=25): raise Rejected('measurementDeadline')
        if number==1 and self.manifest.get('anchorSHA256'):
            value,_=self.window(1);seed_ready(self)
            exclusive(self.root,'windows/1.baseline-entry.json',{'globalSHA256':self.global_hash,'enteredUTC':now.isoformat()})
            return value
        if number > 1:
            retained, _ = read(self.root, 'retained-' + str(number - 1) + '.json')
            stage = 'fresh' if number == 2 else 'p1-read'
            event, sha = read(self.root, 'receipts/' + stage + '.machine.json')
            if is_main(self.manifest):
                # Retention freezes only the observation available then. A later
                # truthful sidecar may inform UX without invalidating retained A.
                human_sha=retained.get('humanReceiptSHA256')
                if human_sha is not None and observation_status(self,stage)['humanReceiptSHA256']!=human_sha:raise Rejected('retentionChanged')
            else:
                human, _ = read(self.root, 'human/' + stage + '.json'); validate_human(human, event, sha, self.synthetic, self.clock());human_sha=file_hash(safe(self.root,'human/'+stage+'.json'))
            if (retained.get('machineReceiptSHA256') != sha or retained.get('globalSHA256') != self.global_hash or retained.get('grantSHA256') != self.manifest['grantSHA256']['retention'] or retained.get('humanReceiptSHA256') != human_sha): raise Rejected('retentionChanged')
        if number == 2 and now < stamp(self.manifest['p0ExpiryUTC']): raise Rejected('naturalExpiryNotReached')
        value = {'namespace': self.namespace, 'number': number, 'synthetic': self.synthetic,
                 'globalSHA256': self.global_hash, 'startUTC': start.isoformat(),
                 'cutoffUTC': (start + dt.timedelta(minutes=25)).isoformat(),
                 'deadlineUTC': (start + dt.timedelta(minutes=30)).isoformat(), 'humanReadyStatement': ready}
        if is_main(self.manifest):
            value.pop('humanReadyStatement');value.update(authorizationMode=self.manifest['authorizationMode'],mainConsentSHA256=check_main(self))
        window_hash = exclusive(self.root, 'windows/' + str(number) + '.json', value)
        exclusive(self.root, 'windows/' + str(number) + '.binding.json', {'windowSHA256': window_hash})
        return value

    def window(self, number, cleanup=False, archived=False):
        value, sha = read(self.root, 'windows/' + str(number) + '.json')
        binding, _ = read(self.root, 'windows/' + str(number) + '.binding.json')
        start = stamp(value['startUTC']); now = self.clock()
        if (binding.get('windowSHA256') != sha or (number == 1 and start != stamp(self.manifest['startUTC'])) or value.get('number') != number or (value.get('anchorSHA256')!=self.manifest.get('anchorSHA256') or sha!=self.manifest.get('window1SHA256') if number==1 and self.manifest.get('anchorSHA256') else value.get('globalSHA256')!=self.global_hash) or
                value.get('namespace') != self.namespace or value.get('synthetic') is not self.synthetic or
                start > now or stamp(value['cutoffUTC']) - start != dt.timedelta(minutes=25) or
                stamp(value['deadlineUTC']) - start != dt.timedelta(minutes=30)):
            raise Rejected('windowChanged')
        if is_main(self.manifest) and not archived and (now>=stamp(value['deadlineUTC']) or now>=stamp(self.manifest['globalDeadlineUTC'])):raise Rejected('mainCleanupDeadline')
        if not cleanup and (now >= stamp(value['cutoffUTC']) or now >= stamp(self.manifest['globalDeadlineUTC']) or safe(self.root, 'abort.json').exists()):
            raise Rejected('measurementDeadline')
        return value, sha

    def check_ready(self, stage, gate, previous, archived=False):
        number = next(n for n, stages in STAGES.items() if stage in stages)
        window, _ = self.window(number, cleanup=archived or (is_main(self.manifest) and stage=='cleanup'),archived=archived)
        now=self.clock(); ready=stamp(gate.get('recordedUTC'))
        if is_main(self.manifest):
            expected=previous[1] if previous else self.global_hash
            validate_package_gate(self,stage,gate,expected,number,archived=archived)
            if previous and ready<stamp(previous[0]['endedUTC']):raise Rejected('packageActionTimeRejected')
            return
        if (gate.get('namespace') != self.namespace or gate.get('stage') != stage or
                gate.get('synthetic') is not self.synthetic or not isinstance(gate.get('humanReadyStatement'), str) or not gate['humanReadyStatement'].strip() or
                gate.get('humanReady') is not True or ready > now or ready < stamp(window['startUTC'])):
            raise Rejected('freshHumanReadyRequired')
        if previous is None and self.manifest.get('anchorSHA256'):
            independent,_=seed_ready(self)
            if ready<stamp(independent['recordedUTC']): raise Rejected('independentSeedReadyRequired')
        expected_sha=previous[1] if previous else self.global_hash
        if gate.get('previousReceiptSHA256') != expected_sha: raise Rejected('readySHAChanged')
        if previous:
            human, _ = read(self.root,'human/'+previous[0]['stage']+'.json')
            validate_human(human,previous[0],previous[1],self.synthetic,now)
            if ready <= stamp(human['recordedUTC']): raise Rejected('staleReady')

    def require_ready(self, stage, gate):
        expected=ORDER[len(self.events)] if len(self.events)<len(ORDER) else None
        if expected!=stage: raise Rejected('stageOrderRejected')
        self.check_ready(stage,gate,self.events[-1] if self.events else None)
        relative='gates/'+stage+'.json';path=safe(self.root,relative)
        if path.exists():
            if read(self.root,relative)[1]!=digest(canonical(gate)): raise Rejected('readyChanged')
        else: exclusive(self.root,relative,gate)

    def record(self, stage, number, result, proof_sha):
        _,window_sha=self.window(number, cleanup=stage == 'cleanup')
        expected = ORDER[len(self.events)] if len(self.events) < len(ORDER) else None
        if stage != expected or stage not in STAGES[number]: raise Rejected('stageOrderRejected')
        value = public_result(result)
        value.update(namespace=self.namespace, stage=stage, window=number, synthetic=self.synthetic,
                     globalSHA256=self.global_hash, previousSHA256=self.events[-1][1] if self.events else self.global_hash,
                     proofSHA256=proof_sha, readySHA256=file_hash(safe(self.root,'gates/'+stage+'.json')), windowSHA256=window_sha, promptCount=None)
        if is_main(self.manifest):value.update(authorizationMode=self.manifest['authorizationMode'],mainConsentSHA256=self.manifest['mainConsentSHA256'],observation='not-observed',UX='unknown')
        sha = exclusive(self.root, 'receipts/' + stage + '.machine.json', value)
        self.reload(); return value, sha

    def retain(self, number):
        if number not in (1, 2): raise Rejected('retentionNotAllowed')
        expected = 'fresh' if number == 1 else 'p1-read'
        if not self.events or self.events[-1][0]['stage'] != expected: raise Rejected('baselineIncomplete')
        self.window(number)
        authorize(self.root, self.manifest, self.clock(), self.synthetic)
        # Historical mode requires complete observation. MAIN separates data from optional UX evidence.
        for stage in STAGES[number]:
            event, sha = read(self.root, 'receipts/' + stage + '.machine.json')
            if not is_main(self.manifest):
                human, _ = read(self.root, 'human/' + stage + '.json');validate_human(human,event,sha,self.synthetic,self.clock())
            if event.get('completed') is not True: raise Rejected('baselineIncomplete')
        return exclusive(self.root, 'retained-' + str(number) + '.json',
                         {'namespace': self.namespace, 'globalSHA256': self.global_hash,
                          'machineReceiptSHA256': self.events[-1][1], 'humanReceiptSHA256': observation_status(self,expected)['humanReceiptSHA256'] if is_main(self.manifest) else file_hash(safe(self.root,'human/'+expected+'.json')), 'grantSHA256': self.manifest['grantSHA256']['retention'],
                          'state': 'retained-no-background-process', 'synthetic': self.synthetic, 'retainedUTC':self.clock().isoformat()})


def public_result(raw):
    names = ('startedUTC', 'endedUTC', 'completed', 'launch', 'guard', 'callAttempted', 'OSStatus',
             'absent', 'cleanupComplete', 'recoveryRequired', 'availabilityInterrupted',
             'executableSHA256', 'appSHA256', 'profileSHA256', 'certificateSHA256', 'DRSHA256',
             'profileCreationUTC', 'profileExpiryUTC', 'classification')
    value = {k: raw[k] for k in names if k in raw}
    finite = {'completed', 'missing', 'invalidData', 'comparison', 'accessDenied', 'securityFailure', 'interactionUnavailable', 'missingEntitlement', 'guardRejected', 'launchOrAppGuardUnobserved'}
    if 'classification' in value and value['classification'] not in finite: value['classification'] = 'guardRejected'
    for key, val in value.items():
        if key.endswith('SHA256') and (not isinstance(val, str) or re.fullmatch('[0-9a-f]{64}', val) is None): raise Rejected('invalidPublicHash')
        if key.endswith('UTC'): stamp(val)
        if key in ('completed', 'callAttempted', 'absent', 'cleanupComplete', 'recoveryRequired', 'availabilityInterrupted') and type(val) is not bool: raise Rejected('invalidPublicBool')
    if value.get('launch') not in (None, 'started', 'rejected', 'no-receipt', 'not-requested'): raise Rejected('invalidPublicLaunch')
    if value.get('guard') not in (None, 'passed', 'rejected', 'not-observed'): raise Rejected('invalidPublicGuard')
    if value.get('OSStatus') is not None and type(value['OSStatus']) is not int: raise Rejected('invalidPublicStatus')
    if not raw.get('callAttempted'):
        value['callAttempted'] = False; value['OSStatus'] = None
    fields = raw.get('fields')
    if isinstance(fields, dict): value['fields'] = {k: fields[k] for k in FIELDS if type(fields.get(k)) is bool}
    return value


def run_window(run, number, backend, wait_gate):
    """Actual coordinator branch used by mocks and the gated future CLI. Never auto-resume."""
    retained = False; complete = False; may_have_item = number > 1; finalization_attempted = False
    try:
        for stage in STAGES[number]:
            run.window(number)
            gate = wait_gate(stage); run.require_ready(stage, gate)
            # Existing retained item may exist even when inspection/ready fails.
            if stage == 'seed': may_have_item = True
            result, proof_sha = backend.stage(stage, run)
            if stage == 'expired':
                if result.get('callAttempted') is False and result.get('OSStatus') is not None: raise Rejected('falseSecItemClaim')
            run.record(stage, number, result, proof_sha)
            if stage != 'expired' and result.get('completed') is not True: raise Rejected('operationIncomplete')
            if stage in ('seed', 'fresh', 'p1-read', 'rebuilt-read'):
                if result.get('fields') != {k: True for k in FIELDS}: raise Rejected('sixFieldComparisonFailed')
        backend.wait_observation(STAGES[number][-1], run)
        if number < 3:
            run.retain(number); retained = True
        else:
            event, sha = run.events[-1]; human, _ = read(run.root, 'human/cleanup.json')
            validate_human(human, event, sha, run.synthetic, run.clock())
            if event.get('absent') is not True: raise Rejected('cleanupUnconfirmed')
            may_have_item = False; finalization_attempted = True
            complete = backend.finalize(run) is True
            if not complete: raise Rejected('privateCleanupIncomplete')
        return {'completed': complete, 'retained': retained, 'cleanupComplete': complete,
                'recoveryRequired': False, 'synthetic': run.synthetic}
    finally:
        if not retained and not complete:
            clean = not may_have_item
            if may_have_item:
                try: clean = backend.cleanup(run) is True
                except (Exception, KeyboardInterrupt): clean = False
            # This is the state before archive/private cleanup; later public completion is separate.
            if run.root.exists():
                exclusive(run.root, 'failures/' + str(uuid.uuid4()) + '.json',
                          {'namespace': run.namespace, 'synthetic': run.synthetic,
                           'keychainItemAbsentConfirmed': clean, 'cleanupComplete': False,
                           'recoveryRequired': True, 'possibleOwnedItemRetained': not clean,
                           'privateMaterialRetained': True, 'endedUTC': run.clock().isoformat()})
            if clean and not finalization_attempted:
                try: backend.finalize(run)
                except (Exception, KeyboardInterrupt): pass  # Keep exact recovery material; never claim complete.


def owned_write_possible(root,namespace,synthetic):
    if safe(root,'receipts/seed.machine.json').exists():return True
    markers=list(safe(root,'write-attempts').glob('*.json'))
    for path in markers:
        value,_=read(root,str(path.relative_to(root)))
        if value.get('namespace')!=namespace or value.get('synthetic') is not synthetic or value.get('operation')!='seed-read-a' or value.get('state') not in ('launch-may-add','add-starting'):raise Rejected('writeAttemptOwnershipUnconfirmed')
    return bool(markers)


def require_recovery(run,attempt):
    try: valid=str(uuid.UUID(attempt))==attempt
    except (ValueError,TypeError): valid=False
    if not valid: raise Rejected('recoveryAttemptRejected')
    authorize(run.root,run.manifest,run.clock(),run.synthetic)
    if not owned_write_possible(run.root,run.namespace,run.synthetic):raise Rejected('ownedItemNotProven')
    if is_main(run.manifest):
        number=max(n for n in (1,2,3) if safe(run.root,'windows/'+str(n)+'.json').exists());run.window(number,cleanup=True)
        previous=run.events[-1][1] if run.events else run.global_hash
        _,ready_sha=package_gate(run,'cleanup-only',previous,'recovery-attempts/'+attempt+'/ready.json',number)
        return run.manifest['grantSHA256']['recovery'],ready_sha
    grant,sha=read(run.root,'recovery-attempts/'+attempt+'/grant.json')
    ready,ready_sha=read(run.root,'recovery-attempts/'+attempt+'/ready.json');now=run.clock()
    if (grant.get('kind')!='human-grant' or grant.get('scope')!='cleanup-only' or grant.get('namespace')!=run.namespace or grant.get('synthetic') is not run.synthetic or grant.get('approved') is not True or grant.get('assetInspectionApproved') is not True or grant.get('globalSHA256')!=run.global_hash or not isinstance(grant.get('statement'),str) or not grant['statement'].strip() or not stamp(grant.get('recordedUTC'))<=now<stamp(grant.get('validUntilUTC'))): raise Rejected('cleanupGrantRequired')
    if (ready.get('namespace')!=run.namespace or ready.get('attempt')!=attempt or ready.get('synthetic') is not run.synthetic or ready.get('globalSHA256')!=run.global_hash or ready.get('grantSHA256')!=sha or ready.get('humanReady') is not True or not isinstance(ready.get('humanReadyStatement'),str) or not ready['humanReadyStatement'].strip() or not stamp(grant['recordedUTC'])<stamp(ready.get('recordedUTC'))<=now): raise Rejected('cleanupReadyRequired')
    last=max((stamp(v['endedUTC']) for v,_ in run.events),default=stamp(run.manifest['startUTC']))
    for path in safe(run.root,'failures').glob('*.json'):
        failure,_=read(run.root,str(path.relative_to(run.root)));last=max(last,stamp(failure['endedUTC']))
    if stamp(ready['recordedUTC'])<=last: raise Rejected('cleanupReadyStale')
    return sha,ready_sha


def run_cleanup_only(run,attempt,backend):
    """Manual recovery only: no arm, seed, normal stage resume, or measurement-window reset."""
    grant_sha,ready_sha=require_recovery(run,attempt)
    relative='recovery-attempts/'+attempt+'/machine.json';path=safe(run.root,relative)
    if not path.exists():
        started=run.clock().isoformat()
        try: result=public_result(backend.recover(run,attempt))
        except (Exception,KeyboardInterrupt): result={'completed':False,'callAttempted':False,'OSStatus':None,'recoveryRequired':True,'classification':'guardRejected'}
        number=max(n for n in (1,2,3) if safe(run.root,'windows/'+str(n)+'.json').exists())
        window,window_sha=run.window(number,cleanup=True)
        result.update(namespace=run.namespace,synthetic=run.synthetic,stage='recovery-cleanup',globalSHA256=run.global_hash,grantSHA256=grant_sha,readySHA256=ready_sha,windowSHA256=window_sha,startedUTC=started,endedUTC=run.clock().isoformat(),promptCount=None,afterOriginalDeadline=run.clock()>stamp(window['deadlineUTC']))
        exclusive(run.root,relative,result)
    event,sha=read(run.root,relative)
    clean=event.get('absent') is True and event.get('completed') is True
    human_path=safe(run.root,'recovery-attempts/'+attempt+'/human.json')
    if clean and is_main(run.manifest):
        complete=backend.finalize(run) is True
        return {'cleanupComplete':complete,'recoveryRequired':not complete,'keychainItemAbsentConfirmed':True,'awaitingSafeEvidenceACK':not complete}
    if not clean or not human_path.exists(): return {'cleanupComplete':False,'recoveryRequired':True,'keychainItemAbsentConfirmed':clean}
    human,_=read(run.root,str(human_path.relative_to(run.root)));validate_human(human,event,sha,run.synthetic,run.clock())
    complete=backend.finalize(run) is True
    return {'cleanupComplete':complete,'recoveryRequired':not complete,'keychainItemAbsentConfirmed':True}


def run_main_stage(run,number,stage,backend):
    """One fixed ordered stage; agent may provision between calls, never resets a window."""
    check_main(run)
    if stage not in STAGES.get(number,()):raise Rejected('stageOrderRejected')
    if not safe(run.root,'windows/'+str(number)+'.json').exists():run.arm_window(number,None)
    elif number==1 and not safe(run.root,'windows/1.baseline-entry.json').exists():run.arm_window(1,None)
    run.window(number,cleanup=stage=='cleanup')
    previous=run.events[-1][1] if run.events else run.global_hash
    gate,_=package_gate(run,stage,previous,'gates/'+stage+'.json',number);run.require_ready(stage,gate)
    may_have_item=stage=='seed' or any(value['stage']=='seed' for value,_ in run.events)
    try:
        result,proof_sha=backend.stage(stage,run)
        if stage=='expired' and not result.get('callAttempted') and result.get('OSStatus') is not None:raise Rejected('falseSecItemClaim')
        run.record(stage,number,result,proof_sha)
        if stage!='expired' and result.get('completed') is not True:raise Rejected('operationIncomplete')
        if stage in ('seed','fresh','p1-read','rebuilt-read') and result.get('fields')!={k:True for k in FIELDS}:raise Rejected('sixFieldComparisonFailed')
        if stage in ('fresh','p1-read'):run.retain(number)
        if stage=='cleanup':
            if result.get('absent') is not True:raise Rejected('cleanupUnconfirmed')
            complete=backend.finalize(run) is True
            return {'stageCompleted':True,'keychainItemAbsentConfirmed':True,'cleanupComplete':complete,'awaitingSafeEvidenceACK':not complete,'UX':observation_status(run,stage)['UX'] if run.root.exists() else 'unknown'}
        return {'stageCompleted':True,'retained':stage in ('fresh','p1-read'),'UX':observation_status(run,stage)['UX'],'promptCount':observation_status(run,stage)['promptCount']}
    except (Exception,KeyboardInterrupt):
        if not safe(run.root,'abort.json').exists():exclusive(run.root,'abort.json',{'namespace':run.namespace,'synthetic':run.synthetic,'stage':stage,'endedUTC':run.clock().isoformat()})
        clean=not may_have_item
        if may_have_item:
            try:clean=backend.cleanup(run) is True
            except (Exception,KeyboardInterrupt):clean=False
        exclusive(run.root,'failures/'+str(uuid.uuid4())+'.json',{'namespace':run.namespace,'synthetic':run.synthetic,'endedUTC':run.clock().isoformat(),'keychainItemAbsentConfirmed':clean,'cleanupComplete':False,'recoveryRequired':True,'possibleOwnedItemRetained':not clean,'privateMaterialRetained':True})
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--window', type=int, choices=(1, 2, 3))
    parser.add_argument('--cleanup-only', metavar='ATTEMPT_UUID')
    parser.add_argument('--ready-statement')
    parser.add_argument('--stage',choices=ORDER)
    parser.add_argument('--finalize-only',action='store_true')
    parser.add_argument('--begin', action='store_true')
    parser.add_argument('--begin-anchor',action='store_true')
    parser.add_argument('--setup-only',action='store_true')
    parser.add_argument('--complete-global',action='store_true')
    parser.add_argument('--stop-setup',action='store_true')
    parser.add_argument('--p0-expiry')
    parser.add_argument('--certificate-expiry')
    parser.add_argument('--public-out', type=Path)
    args = parser.parse_args()
    if not args.live: raise Rejected('preparationOnlyNoLiveCommands')
    # No live backend import/construction or commands precede matching actual grants.
    namespace = args.root.name.removeprefix('rivet-E010-')
    if args.begin: raise Rejected('legacyBeginDisabled')
    modes=sum((args.begin_anchor,args.setup_only,args.complete_global,args.stop_setup))
    if modes:
        if modes!=1 or args.window is not None or args.cleanup_only: raise Rejected('bootstrapModeRequired')
        from proof import source_hashes,inspect_bootstrap,stop_bootstrap
        if args.begin_anchor: begin_anchor(args.root,namespace,source_hashes(),args.public_out,clock=utc)
        else:
            context=Bootstrap(args.root,clock=utc)
            try:
                if args.stop_setup:
                    stopped=stop_bootstrap(context)
                    print('Setup cleanup stopped; inspect explicit cleanupComplete/recoveryRequired receipt.')
                    return 0 if stopped['cleanupComplete'] else 2
                elif args.setup_only: inspect_bootstrap(context)
                else: complete_global(context)
            except (Exception,KeyboardInterrupt):
                if context.root.exists():
                    exclusive(context.root,'bootstrap/stopped-'+str(uuid.uuid4())+'.machine.json',{'namespace':context.namespace,'synthetic':context.synthetic,'stage':'bootstrap-stopped','noSecItemWriteAttempted':True,'cleanupComplete':False,'recoveryRequired':True,'privateSetupMaterialRetained':True,'appleAssetsRetained':True,'endedUTC':utc().isoformat()})
                raise
        print('Bootstrap stage stopped; no App launched or Keychain item written.');return 0
    run = Run(args.root)
    from proof import ManualStages
    if args.cleanup_only:
        if args.begin or args.window is not None: raise Rejected('cleanupOnlyCannotResumeMeasurement')
        result=run_cleanup_only(run,args.cleanup_only,ManualStages(run))
        print('Cleanup-only stopped; consult immutable recovery receipts. No measurements resumed.')
        return 0 if result['cleanupComplete'] else 2
    if args.finalize_only:
        if not is_main(run.manifest) or args.window is not None or args.stage is not None:raise Rejected('mainFinalizationOnlyRequired')
        complete=ManualStages(run).finalize(run) is True
        print('Private cleanup complete.' if complete else 'Safe candidate saved; independent model ACK required before private deletion.');return 0 if complete else 2
    if args.window is None: raise Rejected('windowRequired')
    if is_main(run.manifest):
        if args.stage is None or args.ready_statement is not None:raise Rejected('fixedMainStageRequired')
        result=run_main_stage(run,args.window,args.stage,ManualStages(run))
        print('Main stage stopped; consult machine receipts. Observation unknown unless separately recorded.');return 0 if result['stageCompleted'] else 2
    if args.stage is not None:raise Rejected('mainPackageRequired')
    run.arm_window(args.window, args.ready_statement)
    backend = ManualStages(run)
    def wait_gate(stage):
        path = safe(run.root, 'gates/' + stage + '.json')
        while not path.exists(): run.window(args.window); time.sleep(.2)
        return read(run.root, str(path.relative_to(run.root)))[0]
    result = run_window(run, args.window, backend, wait_gate)
    print('Window ended; inspect immutable receipts. No background process retained.')
    return 0 if result['retained'] or result['completed'] else 2


if __name__ == '__main__':
    try: raise SystemExit(main())
    except (Rejected, KeyError, ValueError, OSError, KeyboardInterrupt):
        print('E010 stopped; cleanupComplete=false, recoveryRequired=true if an earlier item/private run exists. Keep recovery material; no automatic resume or prompt inference.')
        raise SystemExit(2)
