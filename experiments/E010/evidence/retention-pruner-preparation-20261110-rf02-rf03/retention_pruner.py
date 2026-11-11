"""RP one-off file job. No experiment imports, no App/Keychain operations.
Only the separately reviewed caller may enable a live phase. Import is inert.
"""
import datetime as dt
import hashlib
import json
import os
import re
import stat
import subprocess
from pathlib import PurePosixPath

NS = 'b90f5f16-d3c8-452f-af91-86b88d6dc64e'
D = '2026-11-20T07:22:03.379959Z'
R0 = '2026-11-10T08:10:57Z'
OFFLINE_END = '2026-11-10T09:10:57Z'
TOTAL_END = '2026-11-10T09:55:57Z'
SOURCE_AGGREGATE = 'b8c567355bcccad218b4949a4e7c5c21aa806b37550cd6332f904203d9c2330d'
FLAGS = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
CACHE_ROOTS = ('DerivedData', 'intermediates', 'build-output')
REQUIRED_ROOTS = ('configured', 'frozen-source', 'gui', 'hosts', 'reference', 'proofs',
                  'grants', 'windows', 'gates', 'receipts', 'human', 'processes',
                  'write-attempts', 'consumed', 'tickets', 'bootstrap', 'controls', 'selection')
REQUIRED_FILES = ('anchor.json', 'global.json', 'main-consent.json', 'original-leaf.json',
                  'normal-retained-1.json', 'selection.json', 'binding.json')
# Fixed source-schema references; no arbitrary string becomes a resolved dependency.
FILE_REFS = {'proofRelative': 'proofSHA256', 'buildReceiptRelative': 'buildReceiptSHA256',
             'machineRelative': 'machineSHA256', 'windowRelative': 'windowSHA256'}
PATH_FIELDS = {'frozenHost', 'appPath', 'sourceRoot', 'productRelative', 'projectRelative',
               'relativePath', 'retentionRoot', 'root', 'path', 'proofRelative',
               'buildReceiptRelative', 'machineRelative', 'windowRelative'}
SAFE_ERRORS = {'deadline', 'unsafePath', 'binding', 'foreignOwner', 'crossDevice',
               'hardlink', 'unknownType', 'drift', 'occupied', 'handlesUnproven',
               'sourceChanged', 'reviewMissing', 'alreadyDispatched', 'coverage',
               'namespace', 'writeFailed', 'unexpected', 'dependencyMissing'}


def canonical(value):
    return (json.dumps(value, sort_keys=True, ensure_ascii=False, indent=2,
                       allow_nan=False) + '\n').encode('utf-8')


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def stamp(value):
    return dt.datetime.fromisoformat(value.replace('Z', '+00:00'))


def utc():
    return dt.datetime.now(dt.timezone.utc)


class Refused(Exception):
    def __init__(self, reason):
        self.reason = reason if reason in SAFE_ERRORS else 'unexpected'
        super().__init__(self.reason)


class Budget:
    def __init__(self, deadline, clock=utc):
        self.deadline, self.clock = stamp(deadline), clock

    def tick(self, margin=0):
        remaining = (self.deadline - self.clock()).total_seconds()
        if remaining <= margin:
            raise Refused('deadline')
        return remaining


def parts(relative):
    if not isinstance(relative, str) or not relative or '\\' in relative or '\x00' in relative:
        raise Refused('unsafePath')
    value = PurePosixPath(relative)
    if value.is_absolute() or any(p in ('', '.', '..') for p in relative.split('/')):
        raise Refused('unsafePath')
    return value.parts


def identity(value):
    return {'dev': value.st_dev, 'ino': value.st_ino, 'uid': value.st_uid,
            'mode': stat.S_IMODE(value.st_mode), 'type': stat.S_IFMT(value.st_mode),
            'size': value.st_size, 'mtimeNS': value.st_mtime_ns, 'nlink': value.st_nlink}


def same_object(a, b):
    return all(a[k] == b[k] for k in ('dev', 'ino', 'uid', 'mode', 'type'))


def owned(value, uid, device=None):
    if value['uid'] != uid:
        raise Refused('foreignOwner')
    if device is not None and value['dev'] != device:
        raise Refused('crossDevice')
    if value['type'] == stat.S_IFREG and value['nlink'] != 1:
        raise Refused('hardlink')
    if value['type'] not in (stat.S_IFREG, stat.S_IFDIR, stat.S_IFLNK):
        raise Refused('unknownType')


def open_chain(path, budget, expected=None):
    """Absolute chain, no resolve()/entry.path and no symlink following.
    System ancestors may be uid0; home and all later ancestors must be caller-owned.
    Every identity is captured and compared on resume. Synthetic /private/tmp is valid.
    """
    budget.tick()
    if not os.path.isabs(path):
        raise Refused('unsafePath')
    names = parts(path[1:])
    fd = os.open('/', FLAGS)
    budget.tick()
    chain = [identity(os.fstat(fd))]
    home_parts = PurePosixPath(os.path.expanduser('~')).parts[1:]
    try:
        for index, name in enumerate(names):
            budget.tick()
            before = identity(os.stat(name, dir_fd=fd, follow_symlinks=False))
            if before['type'] != stat.S_IFDIR or before['uid'] not in (0, os.getuid()):
                raise Refused('binding')
            if names[:len(home_parts)] == home_parts and index >= len(home_parts)-1 and before['uid'] != os.getuid():
                raise Refused('foreignOwner')
            child = os.open(name, FLAGS, dir_fd=fd)
            budget.tick()
            after = identity(os.fstat(child))
            if not same_object(before, after):
                os.close(child)
                raise Refused('drift')
            os.close(fd)
            fd = child
            chain.append(after)
        if expected is not None and not chain_equal(chain, expected):
            raise Refused('binding')
        return fd, chain
    except BaseException:
        os.close(fd)
        raise


def chain_equal(actual, expected):
    return len(actual) == len(expected) and all(same_object(a, b) for a, b in zip(actual, expected))


def read_at(rootfd, relative, budget, uid, device, expected=None):
    names = parts(relative)
    current = os.dup(rootfd)
    try:
        for name in names[:-1]:
            budget.tick()
            child = os.open(name, FLAGS, dir_fd=current)
            got = identity(os.fstat(child)); owned(got, uid, device)
            os.close(current); current = child
        budget.tick()
        leaf = os.open(names[-1], os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=current)
        try:
            before = identity(os.fstat(leaf)); owned(before, uid, device)
            if before['type'] != stat.S_IFREG or (expected and before != expected):
                raise Refused('drift')
            chunks = []
            while True:
                budget.tick()
                chunk = os.read(leaf, 65536)
                if not chunk: break
                chunks.append(chunk)
            budget.tick()
            if identity(os.fstat(leaf)) != before:
                raise Refused('drift')
            return b''.join(chunks)
        finally:
            os.close(leaf)
    finally:
        os.close(current)


def scan(root, budget, expected_chain=None):
    budget.tick()  # Strictly before first root/parent IO.
    fd, chain = open_chain(root, budget, expected_chain)
    root_id = identity(os.fstat(fd)); owned(root_id, os.getuid())
    if root_id['type'] != stat.S_IFDIR or root_id['mode'] != 0o700:
        os.close(fd); raise Refused('binding')
    nodes = {}
    def visit(parent, prefix):
        budget.tick()
        with os.scandir(parent) as listing:
            names=[]
            for entry in listing:
                budget.tick();names.append(entry.name)
            names.sort()
        for name in names:
            budget.tick()
            relative = name if not prefix else prefix + '/' + name
            parts(relative)
            before = identity(os.stat(name, dir_fd=parent, follow_symlinks=False))
            owned(before, os.getuid(), root_id['dev'])
            row = {'relative': relative, 'identity': before, 'SHA256': None}
            nodes[relative] = row
            if before['type'] == stat.S_IFDIR:
                child = os.open(name, FLAGS, dir_fd=parent)
                try:
                    if identity(os.fstat(child)) != before: raise Refused('drift')
                    visit(child, relative)
                    # Directory size/mtime may vary only with concurrent mutation: reject.
                    if identity(os.fstat(child)) != before: raise Refused('drift')
                finally: os.close(child)
            elif before['type'] == stat.S_IFREG:
                raw = read_at(fd, relative, budget, os.getuid(), root_id['dev'], before)
                row['SHA256'] = sha(raw)
            # Symlink contents and targets are NEVER read. Identity is explicit, hash null.
        budget.tick()
    try:
        visit(fd, '')
        if identity(os.fstat(fd)) != root_id: raise Refused('drift')
        return {'namespace': NS, 'rootIdentity': root_id, 'parentChain': chain,
                'nodes': nodes, 'capturedUTC': budget.clock().isoformat()}
    finally: os.close(fd)


def fingerprint(nodes, selected):
    return sha(canonical({p: nodes[p] for p in sorted(selected)}))


def node_id(relative):
    return sha(relative.encode('utf-8'))


def within(relative, root):
    a, b = parts(relative), parts(root)
    return a[:len(b)] == b


def relative_reference(value, root):
    if not isinstance(value, str): raise Refused('unsafePath')
    if os.path.isabs(value):
        target_parts = PurePosixPath(root).parts
        value_parts = PurePosixPath(value).parts
        if value_parts[:len(target_parts)] != target_parts: raise Refused('unsafePath')
        value = '/'.join(value_parts[len(target_parts):])
    parts(value)
    return value


def valid_hash(value):
    return isinstance(value,str) and re.fullmatch(r'[0-9a-fA-F]{64}',value) is not None


def closure(manifest, root, json_records):
    """Private records ONLY; exact schema/pointer/version and SHA facts retained.
    Unknown references never get a fallback. An unresolved path blocks cache deletion
    conservatively; raw bytes are never parsed as JSON or offered to a model.
    """
    nodes = manifest['nodes']; retain = set(); reasons = {}; dependencies = []; unknown = []; unresolved_refs = []
    for path in nodes:
        top = parts(path)[0]
        if top in REQUIRED_ROOTS or path in REQUIRED_FILES:
            retain.add(path); reasons[path] = 'source-required-material'
        elif top not in CACHE_ROOTS and top != 'raw':
            retain.add(path); reasons[path] = 'unclassified-retained'; unknown.append(node_id(path))
    def add_ref(origin, pointer, value, expected=None):
        # Private reference fields are not trusted to be hashes merely by their key.
        if expected is not None and not valid_hash(expected):raise Refused('coverage')
        row = {'originID': node_id(origin), 'pointer': pointer, 'sourceVersion': SOURCE_AGGREGATE,
               'recordedPath': value, 'expectedSHA256': expected, 'status': 'unresolved'}
        try:
            path = relative_reference(value, root)
            matched = [p for p in nodes if p == path or within(p, path)]
            if not matched: raise Refused('dependencyMissing')
            if expected is not None and (path not in nodes or nodes[path]['SHA256'] != expected):
                raise Refused('drift')
            retain.update(matched)
            for p in matched: reasons[p] = 'typed-dependency'
            row['status'] = 'resolved-exact' if expected else 'retained-path-only'
        except Refused:
            missing=sha(canonical([origin, pointer]));unknown.append(missing);unresolved_refs.append(missing)
        dependencies.append(row)
    def walk(origin, value, pointer=''):
        if isinstance(value, dict):
            for key, item in value.items():
                p = pointer + '/' + key.replace('~','~0').replace('/','~1')
                if key in FILE_REFS or key in PATH_FIELDS:
                    # A recognized dependency is never silently skipped for a wrong type.
                    # Absent optional stream has no path; every other null is unresolved.
                    if item is None:
                        if key=='relativePath' and value.get('present') is False:continue
                        add_ref(origin,p,None,value.get(FILE_REFS[key]) if key in FILE_REFS else None)
                        continue
                    if not isinstance(item,str):raise Refused('coverage')
                    if key not in FILE_REFS and item==root:continue
                    add_ref(origin,p,item,value.get(FILE_REFS[key]) if key in FILE_REFS else None)
                elif isinstance(item, (dict, list)): walk(origin, item, p)
        elif isinstance(value, list):
            for i, item in enumerate(value): walk(origin, item, pointer + '/' + str(i))
    for origin, record in json_records.items(): walk(origin, record)
    # Required source paths must be present before any pruning can be proposed.
    for required in ('configured', 'frozen-source', 'gui/p0/Products', 'hosts/p0.app', 'reference', 'proofs'):
        if not any(p == required or within(p, required) for p in nodes):
            missing=sha(('missing-required:' + required).encode());unknown.append(missing);unresolved_refs.append(missing)
    # Ancestors of every preserved file cannot be removed.
    for p in list(retain):
        for i in range(1, len(parts(p))): retain.add('/'.join(parts(p)[:i]))
    return retain, reasons, dependencies, sorted(set(unknown)), sorted(set(unresolved_refs))


def verify_retained_state(manifest, root, records, sources):
    """Frozen-source/schema-only file proof. No certificate/API revalidation."""
    nodes=manifest['nodes'];global_value=records['global.json'];anchor=records['anchor.json']
    root_id=manifest['rootIdentity']
    binding={'device':root_id['dev'],'inode':root_id['ino'],'ownerUID':root_id['uid'],'mode':root_id['mode']}
    if (global_value.get('kind')!='E010-global' or global_value.get('namespace')!=NS or global_value.get('synthetic') is not False
        or global_value.get('backend')!='dpk' or global_value.get('sourceSHA256')!=sources
        or stamp(global_value.get('globalDeadlineUTC',''))!=stamp(D)
        or anchor.get('namespace')!=NS or anchor.get('sourceSHA256')!=sources
        or global_value.get('rootBinding')!=binding or anchor.get('rootBinding')!=binding
        or global_value.get('rootBindingSHA256')!=sha(canonical(binding))):raise Refused('binding')
    refs={'anchorSHA256':'anchor.json','window1SHA256':'windows/1.json','actualSetupProofSHA256':'bootstrap/actual-proof.json'}
    for key,path in refs.items():
        if global_value.get(key)!=nodes.get(path,{}).get('SHA256'):raise Refused('drift')
    for path,expected in sources.items():
        parts(path)
        if nodes.get('frozen-source/'+path,{}).get('SHA256')!=expected:raise Refused('sourceChanged')
    asset=records['proofs/p0.json'];leaf=records['reference/original-leaf.json']
    if asset.get('frozenHost')!=root+'/hosts/p0.app' or asset.get('certificateSHA256')!=leaf.get('certificateSHA256'):
        raise Refused('binding')
    if nodes.get('reference/original.cer',{}).get('SHA256')!=leaf.get('certificateSHA256'):raise Refused('drift')
    for app in ('hosts/p0.app','gui/p0/Products/DPKContinuityProbe.app'):
        rows={p[len(app)+1:]:node['SHA256'] for p,node in nodes.items() if p!=app and within(p,app) and node['identity']['type']==stat.S_IFREG}
        if not rows or any(node['identity']['type']==stat.S_IFLNK for p,node in nodes.items() if within(p,app)) or sha(canonical(rows))!=asset.get('appSHA256'):
            raise Refused('drift')
    return {'originalRootBinding':True,'source22FrozenBytes':True,'globalAnchorW1ProofChain':True,
            'P0HostAndGUIProductFileHashes':True,'originalCERFileHash':True,'DPKReadAttempted':False}


def make_plan(manifest, root, json_records):
    retain, reasons, dependencies, unknown, unresolved_refs = closure(manifest, root, json_records)
    nodes = manifest['nodes']; raw_rows = []; delete = []
    for path, node in nodes.items():
        top = parts(path)[0]
        if top == 'raw':
            retain.add(path); reasons[path] = 'retain-uncovered-raw'
            if node['identity']['type'] == stat.S_IFDIR: continue
            raw_rows.append({'opaqueID': node_id(path), 'rawSHA256': node['SHA256'],
                             'stage': 'unknown', 'toolContext': 'unknown',
                             'safeRefSHA256': None, 'safeRefPointer': None,
                             'coverage': 'not-proven', 'disposition': 'retain-uncovered',
                             'reason': 'producer-did-not-persist-provenance'})
        elif top in CACHE_ROOTS and path not in retain:
            if unresolved_refs:
                retain.add(path); reasons[path] = 'retain-unresolved-dependency'
            else:
                delete.append(path)
    # Never mutate a cache ancestor whose identity/content fingerprint must be retained.
    for cache in CACHE_ROOTS:
        if any(within(p, cache) for p in retain):
            for path in nodes:
                if within(path, cache):
                    retain.add(path); reasons.setdefault(path, 'retained-cache-dependency-subtree')
            delete = [p for p in delete if not within(p, cache)]
    # Child-before-parent order; root is never an allowlist element.
    delete.sort(key=lambda p: (-len(parts(p)), p))
    keep = sorted(set(nodes) - set(delete))
    for p in keep: reasons.setdefault(p, 'structural-ancestor')
    plan = {'namespace': NS, 'sourceAggregateSHA256': SOURCE_AGGREGATE,
            'manifestSHA256': sha(canonical(manifest)), 'retentionDeadlineUTC': D,
            'delete': delete, 'retain': keep, 'retainFingerprintSHA256': fingerprint(nodes, keep),
            'deleteListSHA256': sha(canonical(delete)), 'retainListSHA256': sha(canonical(keep)),
            'dependencies': dependencies, 'unknownRetentionIDs': unknown, 'unknownDependencyIDs': unresolved_refs, 'rawMap': raw_rows,
            'retainReasons': reasons, 'minimumCompleteEligible': not unknown and not raw_rows and all(row['status']=='resolved-exact' for row in dependencies),
            'fileProofOnly': True}
    return plan


def safe_candidate(plan, manifest):
    # Defense at the public boundary as well as at the private schema parser.
    if any(row.get('expectedSHA256') is not None and not valid_hash(row['expectedSHA256']) for row in plan['dependencies']):raise Refused('coverage')
    for key in ('manifestSHA256','retainListSHA256','deleteListSHA256','retainFingerprintSHA256'):
        if not valid_hash(plan[key]):raise Refused('coverage')
    for key in ('unknownDependencyIDs','unknownRetentionIDs'):
        if any(not valid_hash(value) for value in plan[key]):raise Refused('coverage')
    rows = []
    for path, node in manifest['nodes'].items():
        if node['SHA256'] is not None and not valid_hash(node['SHA256']):raise Refused('coverage')
        rows.append({'opaqueID': node_id(path), 'parentID': node_id('/'.join(parts(path)[:-1])) if len(parts(path)) > 1 else None,
                     'type': {stat.S_IFREG:'regular', stat.S_IFDIR:'directory', stat.S_IFLNK:'symlink'}[node['identity']['type']],
                     'identitySHA256': sha(canonical(node['identity'])), 'contentSHA256': node['SHA256'],
                     'disposition': 'delete-source-cache' if path in plan['delete'] else 'retain',
                     'reason': 'source-disposable-cache' if path in plan['delete'] else plan['retainReasons'][path]})
    deps=[]
    for row in plan['dependencies']:
        if (not valid_hash(row['originID']) or row['sourceVersion']!=SOURCE_AGGREGATE
            or row['status'] not in ('resolved-exact','retained-path-only','unresolved')
            or not isinstance(row['pointer'],str)):raise Refused('coverage')
        field=row['pointer'].split('/')[-1]
        deps.append({'originID':row['originID'],'sourceVersion':SOURCE_AGGREGATE,
                     'expectedSHA256':row['expectedSHA256'],'status':row['status'],
                     'pointerSHA256':sha(row['pointer'].encode()),
                     'fieldCode':field if field in PATH_FIELDS else 'unknown'})
    raw_rows=[]
    for row in plan['rawMap']:
        if (not valid_hash(row['opaqueID']) or (row['rawSHA256'] is not None and not valid_hash(row['rawSHA256']))
            or row['stage']!='unknown' or row['toolContext']!='unknown' or row['safeRefSHA256'] is not None
            or row['safeRefPointer'] is not None or row['coverage']!='not-proven'
            or row['disposition']!='retain-uncovered' or row['reason']!='producer-did-not-persist-provenance'):raise Refused('coverage')
        raw_rows.append({'opaqueID':row['opaqueID'],'rawSHA256':row['rawSHA256'],
                         'stage':'unknown','toolContext':'unknown','safeRefSHA256':None,'safeRefPointer':None,
                         'coverage':'not-proven','disposition':'retain-uncovered','reason':'producer-did-not-persist-provenance'})
    value = {'namespace': NS, 'manifestSHA256': plan['manifestSHA256'],
            'retainListSHA256': plan['retainListSHA256'], 'deleteListSHA256': plan['deleteListSHA256'],
            'retainFingerprintSHA256': plan['retainFingerprintSHA256'], 'nodes': rows,
            'dependencies': deps, 'rawMap': raw_rows,
            'unknownDependencyIDs': plan['unknownDependencyIDs'], 'unknownRetentionIDs':plan['unknownRetentionIDs'],
            'minimumCompleteEligible': plan['minimumCompleteEligible'],
            'retentionDeadlineUTC': D, 'actualDPKRead': False,
            'captureNecessity': {'inventory':'exact-identity-content-evidence', 'map':'dependency-raw-coverage-evidence',
                                 'plan':'review-binding', 'dispatch':'single-batch-proof', 'result':'partial-or-postcondition-proof',
                                 'nativeFailure':'unique-diagnostic-until-specific-ACK-not-blanket-retention'}}
    if 'jobIdentity' in plan:value['jobIdentitySHA256']=sha(canonical(plan['jobIdentity']))
    if 'mapSHA256' in plan:
        if not valid_hash(plan['mapSHA256']):raise Refused('coverage')
        value['mapSHA256']=plan['mapSHA256']
    if 'retainedStateFileProof' in plan:value['retainedStateFileProof']=plan['retainedStateFileProof']
    return value


def exclusive_at(fd, name, raw, budget):
    parts(name)
    if '/' in name: raise Refused('unsafePath')
    budget.tick()
    leaf = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=fd)
    try:
        offset = 0
        while offset < len(raw):
            budget.tick(); written = os.write(leaf, raw[offset:offset+65536])
            if written <= 0: raise Refused('writeFailed')
            offset += written
        budget.tick();os.fsync(leaf)
    finally: os.close(leaf)
    budget.tick(); os.fsync(fd)
    got = read_at(fd, name, budget, os.getuid(), os.fstat(fd).st_dev)
    if got != raw: raise Refused('writeFailed')
    return sha(raw)


def handles_clear(root, budget, capture):
    timeout = min(10.0, budget.tick(3) - 3)
    try:
        result = subprocess.run(['/usr/sbin/lsof', '-nP', '+D', root],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)
    except subprocess.TimeoutExpired as error:
        capture('handles-timeout', error.stdout, error.stderr)
        raise Refused('handlesUnproven') from None
    budget.tick()
    if result.returncode != 1 or result.stdout.strip() or result.stderr.strip():
        capture('handles-not-clear', result.stdout, result.stderr)
        raise Refused('occupied')
    return True


def delete_one(root, relative, expected, budget, expected_chain):
    budget.tick()
    rootfd, chain = open_chain(root, budget, expected_chain)
    current = rootfd
    try:
        root_identity = identity(os.fstat(rootfd))
        names = parts(relative)
        for i, name in enumerate(names[:-1]):
            budget.tick()
            before = identity(os.stat(name, dir_fd=current, follow_symlinks=False))
            original = expected['/'.join(names[:i+1])]['identity']
            if not same_object(before, original): raise Refused('drift')
            child = os.open(name, FLAGS, dir_fd=current)
            if not same_object(identity(os.fstat(child)), original):
                os.close(child); raise Refused('drift')
            if current != rootfd: os.close(current)
            current = child
        budget.tick()
        actual = identity(os.stat(names[-1], dir_fd=current, follow_symlinks=False))
        original = expected[relative]['identity']
        # Directory size/mtime changes after our own child removals; identity remains exact.
        if not same_object(actual, original): raise Refused('drift')
        owned(actual, os.getuid(), root_identity['dev'])
        if actual['type'] != stat.S_IFDIR and actual != original:raise Refused('drift')
        if actual['type'] == stat.S_IFREG:
            raw = read_at(rootfd, relative, budget, os.getuid(), root_identity['dev'], actual)
            if sha(raw) != expected[relative]['SHA256']: raise Refused('drift')
        budget.tick()
        if actual['type'] == stat.S_IFDIR: os.rmdir(names[-1], dir_fd=current)
        else: os.unlink(names[-1], dir_fd=current)  # Symlink itself only.
        budget.tick();os.fsync(current)
    finally:
        if current != rootfd: os.close(current)
        os.close(rootfd)


def execute(root, manifest, plan, budget, jobfd, reviewer, handle_check, persist, capture_failure=None):
    """No retries. persist writes durable safe per-step facts outside target.
    Caller verifies code/params/source/reviewer tuple before calling this function.
    """
    result = {'startedUTC': budget.clock().isoformat(), 'attempted': [], 'completed': [],
              'failed': None, 'finalUnknown': True, 'cleanupComplete': False, 'allowlistComplete': False,
              'minimumComplete': False, 'recoveryRequired': True, 'retained': [],
              'fileProofOnly': True, 'prechecks': {}}
    try:
        budget.tick(3)
        if reviewer != {'candidateSHA256': sha(canonical(safe_candidate(plan, manifest))),
                        'readabilityACK': True, 'safetyACK': True, 'verdict': 'approved'}:
            raise Refused('reviewMissing')
        if plan['manifestSHA256'] != sha(canonical(manifest)) or plan['retainListSHA256'] != sha(canonical(plan['retain'])) or plan['deleteListSHA256'] != sha(canonical(plan['delete'])):
            raise Refused('drift')
        # Durable dispatch BEFORE any mutation, including failures with zero completed.
        try: exclusive_at(jobfd, 'dispatch.json', canonical({'planSHA256':sha(canonical(plan)), 'atUTC':budget.clock().isoformat()}), budget)
        except FileExistsError: raise Refused('alreadyDispatched') from None
        fresh = scan(root, budget, manifest['parentChain'])
        if fresh['rootIdentity'] != manifest['rootIdentity'] or fresh['nodes'] != manifest['nodes']:
            raise Refused('drift')
        result['prechecks']['identityAndEntryset'] = True
        if fingerprint(fresh['nodes'], plan['retain']) != plan['retainFingerprintSHA256']:
            raise Refused('drift')
        result['prechecks']['retainFingerprint'] = True
        if not handle_check(): raise Refused('occupied')
        result['prechecks']['handlesClear'] = True
        # Blocking helper may overlap external mutation. Recheck BEFORE first delete.
        after_handles=scan(root,budget,manifest['parentChain'])
        if (after_handles['rootIdentity']!=manifest['rootIdentity'] or after_handles['nodes']!=manifest['nodes']
            or fingerprint(after_handles['nodes'],plan['retain'])!=plan['retainFingerprintSHA256']):raise Refused('drift')
        result['prechecks']['postHandlesIdentityEntrysetAndRetain'] = True
        for relative in plan['delete']:
            budget.tick(2)
            if relative in plan['retain'] or parts(relative)[0] not in CACHE_ROOTS:
                raise Refused('binding')
            result['attempted'].append(node_id(relative)); persist(result)
            delete_one(root, relative, manifest['nodes'], budget, manifest['parentChain'])
            result['completed'].append(node_id(relative)); persist(result)
        post = scan(root, budget, manifest['parentChain'])
        if set(post['nodes']) != set(plan['retain']) or fingerprint(post['nodes'], plan['retain']) != plan['retainFingerprintSHA256']:
            raise Refused('drift')
        result.update(finalUnknown=False, retained=[node_id(p) for p in plan['retain']],
                      allowlistComplete=True, cleanupComplete=plan['minimumCompleteEligible'], minimumComplete=plan['minimumCompleteEligible'],
                      recoveryRequired=not plan['minimumCompleteEligible'])
    except BaseException as error:
        result['failed'] = error.reason if isinstance(error, Refused) else 'unexpected'
        if not isinstance(error, Refused) and capture_failure is not None:
            try: capture_failure(error); result['privateFailureCaptured'] = True
            except BaseException: result['privateFailureCaptured'] = False
        result['retained'] = [node_id(p) for p in plan['retain']]
    result['endedUTC'] = budget.clock().isoformat()
    try: persist(result)
    except BaseException: result['finalPublicationComplete'] = False
    # In-memory safe facts may be reported after cutoff; no post-cutoff filesystem IO.
    return result
