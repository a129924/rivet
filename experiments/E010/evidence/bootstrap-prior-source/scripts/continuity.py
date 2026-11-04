"""E008 fixed three-window protocol. No background work; live backend is lazy/grant gated."""
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
    if not valid or root.name != 'rivet-E008-' + namespace: raise Rejected('namespaceRejected')
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
    identity=manifest.get('hostBinding')
    if not isinstance(identity,dict) or identity != local_identity(synthetic) or manifest.get('hostBindingSHA256') != digest(canonical(identity)): raise Rejected('hostBindingChanged')
    start, deadline = stamp(manifest['startUTC']), stamp(manifest['globalDeadlineUTC'])
    if deadline - start != dt.timedelta(days=10) or start > now: raise Rejected('globalWindowRejected')
    for kind in ('assets', 'retention', 'recovery'):
        grant, sha = read(root, 'grants/' + kind + '.json')
        checked_grant(grant, kind, manifest['namespace'], root, deadline, synthetic)
        if manifest['grantSHA256'].get(kind) != sha: raise Rejected('grantChanged')
    return True


def create_global(root, namespace, p0_expiry, certificate_expiry, source_hashes, synthetic=False, clock=utc, public_out=None):
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
    manifest = {'hostBinding':identity, 'hostBindingSHA256':digest(canonical(identity)), 'kind': 'E008-global', 'namespace': namespace, 'synthetic': synthetic, 'backend': 'dpk',
                'startUTC': now.isoformat(), 'globalDeadlineUTC': deadline.isoformat(), 'maxWindows': 3,
                'p0ExpiryUTC': p0_expiry, 'certificateNotAfterUTC': certificate_expiry,
                'grantSHA256': grants, 'sourceSHA256': source_hashes,
                'bundleIdentifier': 'local.rivet.dpkcontinuity.' + namespace.replace('-', ''),
                'service': 'local.rivet.experiments.E008.' + namespace, 'account': 'oauth-bundle',
                'fixture': FAKE_A, 'fixtureSHA256': digest(canonical(FAKE_A)),
                'publicEvidenceDirectory': str(Path(public_out).resolve()) if public_out else None}
    sha = exclusive(root, 'global.json', manifest)
    exclusive(root, 'global.binding.json', {'globalSHA256': sha})
    return manifest


def validate_human(value, machine, machine_sha, synthetic, now=None):
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
    if machine['stage'] in ('seed', 'fresh', 'p1-read', 'rebuilt-read') and count > limit:
        raise Rejected('uxCriterionExceeded')


class Run:
    def __init__(self, root, synthetic=False, clock=utc):
        self.root, self.synthetic, self.clock = Path(root), synthetic, clock
        self.manifest, self.global_hash = read(self.root, 'global.json')
        binding, _ = read(self.root, 'global.binding.json')
        if binding.get('globalSHA256') != self.global_hash: raise Rejected('manifestChanged')
        self.namespace = self.manifest['namespace']
        authorize(root, self.manifest, clock(), synthetic)
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
        if type(number) is not int or number not in STAGES or not isinstance(ready, str) or not ready.strip(): raise Rejected('windowOrReadyRejected')
        if now >= stamp(self.manifest['globalDeadlineUTC']) or now >= start + dt.timedelta(minutes=25): raise Rejected('measurementDeadline')
        if number > 1:
            retained, _ = read(self.root, 'retained-' + str(number - 1) + '.json')
            stage = 'fresh' if number == 2 else 'p1-read'
            event, sha = read(self.root, 'receipts/' + stage + '.machine.json')
            human, _ = read(self.root, 'human/' + stage + '.json'); validate_human(human, event, sha, self.synthetic, self.clock())
            if (retained.get('machineReceiptSHA256') != sha or retained.get('globalSHA256') != self.global_hash or retained.get('grantSHA256') != self.manifest['grantSHA256']['retention'] or retained.get('humanReceiptSHA256') != file_hash(safe(self.root, 'human/'+stage+'.json'))): raise Rejected('retentionChanged')
        if number == 2 and now < stamp(self.manifest['p0ExpiryUTC']): raise Rejected('naturalExpiryNotReached')
        value = {'namespace': self.namespace, 'number': number, 'synthetic': self.synthetic,
                 'globalSHA256': self.global_hash, 'startUTC': start.isoformat(),
                 'cutoffUTC': (start + dt.timedelta(minutes=25)).isoformat(),
                 'deadlineUTC': (start + dt.timedelta(minutes=30)).isoformat(), 'humanReadyStatement': ready}
        window_hash = exclusive(self.root, 'windows/' + str(number) + '.json', value)
        exclusive(self.root, 'windows/' + str(number) + '.binding.json', {'windowSHA256': window_hash})
        return value

    def window(self, number, cleanup=False):
        value, sha = read(self.root, 'windows/' + str(number) + '.json')
        binding, _ = read(self.root, 'windows/' + str(number) + '.binding.json')
        start = stamp(value['startUTC']); now = self.clock()
        if (binding.get('windowSHA256') != sha or (number == 1 and start != stamp(self.manifest['startUTC'])) or value.get('number') != number or value.get('globalSHA256') != self.global_hash or
                value.get('namespace') != self.namespace or value.get('synthetic') is not self.synthetic or
                start > now or stamp(value['cutoffUTC']) - start != dt.timedelta(minutes=25) or
                stamp(value['deadlineUTC']) - start != dt.timedelta(minutes=30)):
            raise Rejected('windowChanged')
        if not cleanup and (now >= stamp(value['cutoffUTC']) or now >= stamp(self.manifest['globalDeadlineUTC']) or safe(self.root, 'abort.json').exists()):
            raise Rejected('measurementDeadline')
        return value, sha

    def check_ready(self, stage, gate, previous, archived=False):
        number = next(n for n, stages in STAGES.items() if stage in stages)
        window, _ = self.window(number, cleanup=archived)
        now=self.clock(); ready=stamp(gate.get('recordedUTC'))
        if (gate.get('namespace') != self.namespace or gate.get('stage') != stage or
                gate.get('synthetic') is not self.synthetic or not isinstance(gate.get('humanReadyStatement'), str) or not gate['humanReadyStatement'].strip() or
                gate.get('humanReady') is not True or ready > now or ready < stamp(window['startUTC'])):
            raise Rejected('freshHumanReadyRequired')
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
        sha = exclusive(self.root, 'receipts/' + stage + '.machine.json', value)
        self.reload(); return value, sha

    def retain(self, number):
        if number not in (1, 2): raise Rejected('retentionNotAllowed')
        expected = 'fresh' if number == 1 else 'p1-read'
        if not self.events or self.events[-1][0]['stage'] != expected: raise Rejected('baselineIncomplete')
        self.window(number)
        authorize(self.root, self.manifest, self.clock(), self.synthetic)
        # Every stage in this window must have complete observation, not just its last one.
        for stage in STAGES[number]:
            event, sha = read(self.root, 'receipts/' + stage + '.machine.json')
            human, _ = read(self.root, 'human/' + stage + '.json'); validate_human(human, event, sha, self.synthetic, self.clock())
            if event.get('completed') is not True: raise Rejected('baselineIncomplete')
        return exclusive(self.root, 'retained-' + str(number) + '.json',
                         {'namespace': self.namespace, 'globalSHA256': self.global_hash,
                          'machineReceiptSHA256': self.events[-1][1], 'humanReceiptSHA256': file_hash(safe(self.root, 'human/'+expected+'.json')), 'grantSHA256': self.manifest['grantSHA256']['retention'],
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


def require_recovery(run,attempt):
    try: valid=str(uuid.UUID(attempt))==attempt
    except (ValueError,TypeError): valid=False
    if not valid: raise Rejected('recoveryAttemptRejected')
    authorize(run.root,run.manifest,run.clock(),run.synthetic)
    if not safe(run.root,'receipts/seed.machine.json').exists(): raise Rejected('ownedItemNotProven')
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
    if not clean or not human_path.exists(): return {'cleanupComplete':False,'recoveryRequired':True,'keychainItemAbsentConfirmed':clean}
    human,_=read(run.root,str(human_path.relative_to(run.root)));validate_human(human,event,sha,run.synthetic,run.clock())
    complete=backend.finalize(run) is True
    return {'cleanupComplete':complete,'recoveryRequired':not complete,'keychainItemAbsentConfirmed':True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--window', type=int, choices=(1, 2, 3))
    parser.add_argument('--cleanup-only', metavar='ATTEMPT_UUID')
    parser.add_argument('--ready-statement')
    parser.add_argument('--begin', action='store_true')
    parser.add_argument('--p0-expiry')
    parser.add_argument('--certificate-expiry')
    parser.add_argument('--public-out', type=Path)
    args = parser.parse_args()
    if not args.live: raise Rejected('preparationOnlyNoLiveCommands')
    # No live backend import/construction or commands precede matching actual grants.
    namespace = args.root.name.removeprefix('rivet-E008-')
    if args.begin:
        from proof import source_hashes
        create_global(args.root, namespace, args.p0_expiry, args.certificate_expiry, source_hashes(), public_out=args.public_out)
    run = Run(args.root)
    from proof import ManualStages
    if args.cleanup_only:
        if args.begin or args.window is not None: raise Rejected('cleanupOnlyCannotResumeMeasurement')
        result=run_cleanup_only(run,args.cleanup_only,ManualStages(run))
        print('Cleanup-only stopped; consult immutable recovery receipts. No measurements resumed.')
        return 0 if result['cleanupComplete'] else 2
    if args.window is None: raise Rejected('windowRequired')
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
        print('E008 stopped; cleanupComplete=false, recoveryRequired=true if an earlier item/private run exists. Keep recovery material; no automatic resume or prompt inference.')
        raise SystemExit(2)
