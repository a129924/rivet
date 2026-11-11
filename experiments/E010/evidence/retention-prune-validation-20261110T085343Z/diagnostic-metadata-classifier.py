"""RP07 sealed-metadata-only classifier. Never opens a target node or log content."""
import argparse
import collections
import datetime as dt
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat

STOP = dt.datetime.fromisoformat('2026-11-10T09:13:43.881395+00:00')
JOB = 'Library/Application Support/RivetExperiments/E010-retention-prune-rp-20261110T081057Z'
EXPECTED = {'inventory.private.json':'b39281cf2a186a5da18e3927250a5c7629b88a0fdce7c9208ec079e96d79655a', 'plan.private.json':'f43e4dd240ecac47250dce744852df4868a614c737a133fef315d38050cc7871'}
DELETE_SHA = '70653b0362dba8a66484d57256a9ba8fb6837f7d536d5adc53271d8ae819f243'
EXTENSIONS = ('.xcactivitylog','.xcresult','.log','.dia','.diagnostic','.trace','.ips','.crash')

def sha(raw): return hashlib.sha256(raw).hexdigest()
def canonical(v): return (json.dumps(v,sort_keys=True,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def tick():
    if dt.datetime.now(dt.timezone.utc)>=STOP: raise ValueError('deadline')
def parts(value):
    if not isinstance(value,str) or not value or '\\' in value or '\0' in value or PurePosixPath(value).is_absolute() or any(x in ('','.','..') for x in value.split('/')): raise ValueError('metadata-schema')
    return value.split('/')
def open_sidecar(path):
    tick()
    expected=os.path.join(os.path.expanduser('~'),JOB)
    if path!=expected: raise ValueError('binding')
    flags=os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW
    fd=os.open('/',flags)
    try:
        for piece in parts(path[1:]):
            tick();s=os.stat(piece,dir_fd=fd,follow_symlinks=False)
            if not stat.S_ISDIR(s.st_mode) or s.st_uid not in (0,os.getuid()):raise ValueError('binding')
            child=os.open(piece,flags,dir_fd=fd);got=os.fstat(child)
            if (s.st_dev,s.st_ino,s.st_uid,s.st_mode)!=(got.st_dev,got.st_ino,got.st_uid,got.st_mode):os.close(child);raise ValueError('drift')
            os.close(fd);fd=child
        s=os.fstat(fd)
        if s.st_uid!=os.getuid() or stat.S_IMODE(s.st_mode)!=0o700:raise ValueError('binding')
        return fd
    except BaseException:os.close(fd);raise

def read_sealed(fd,name):
    tick();leaf=os.open(name,os.O_RDONLY|os.O_NOFOLLOW,dir_fd=fd)
    try:
        s=os.fstat(leaf)
        if not stat.S_ISREG(s.st_mode) or s.st_uid!=os.getuid() or s.st_nlink!=1:raise ValueError('binding')
        chunks=[]
        while True:
            tick();chunk=os.read(leaf,65536)
            if not chunk:break
            chunks.append(chunk)
        after=os.fstat(leaf)
        if (s.st_dev,s.st_ino,s.st_size,s.st_mtime_ns)!=(after.st_dev,after.st_ino,after.st_size,after.st_mtime_ns):raise ValueError('drift')
        raw=b''.join(chunks)
        if sha(raw)!=EXPECTED[name]:raise ValueError('hash')
        return json.loads(raw)
    finally:os.close(leaf)

def classify(manifest,plan):
    if sha(canonical(plan['delete']))!=DELETE_SHA or plan['manifestSHA256']!=EXPECTED['inventory.private.json']:raise ValueError('binding')
    nodes=manifest['nodes'];diagnostic=set();location=collections.Counter();suffix=collections.Counter();diagnostic_types=collections.Counter();module=set();index=set();direct_suffix=set()
    for relative in plan['delete']:
        tick();pieces=parts(relative)
        if pieces[0]!='DerivedData' or relative not in nodes:raise ValueError('metadata-schema')
        node=nodes[relative];kind=node['identity']['type']
        if kind not in (stat.S_IFREG,stat.S_IFDIR,stat.S_IFLNK):raise ValueError('metadata-schema')
        lowered=[piece.casefold() for piece in pieces]
        reasons=[]
        if 'logs' in lowered:location['logs-subtree']+=1;reasons.append('logs-subtree')
        if 'logstore' in lowered:location['logstore-subtree']+=1;reasons.append('logstore-subtree')
        for extension in EXTENSIONS:
            if any(piece.endswith(extension) for piece in lowered):suffix[extension]+=1;reasons.append('diagnostic-suffix-subtree')
            if lowered[-1].endswith(extension):direct_suffix.add(relative)
        if any(piece in ('modulecache','modulecache.noindex') or piece.startswith('modulecache-') for piece in lowered):module.add(relative)
        if any(piece in ('index','index.noindex','indexstore','indexstore.noindex') for piece in lowered):index.add(relative)
        if reasons:
            diagnostic.add(relative);diagnostic_types[{stat.S_IFREG:'regular',stat.S_IFDIR:'directory',stat.S_IFLNK:'symlink'}[kind]]+=1
    return {'kind':'E010-RP07-sealed-delete-metadata-diagnostic-classification','recordedUTC':dt.datetime.now(dt.timezone.utc).isoformat(),'manifestSHA256':EXPECTED['inventory.private.json'],'privatePlanSHA256':EXPECTED['plan.private.json'],'deleteListSHA256':DELETE_SHA,'classifierSHA256':sha(Path(__file__).read_bytes()),'deleteCount':len(plan['delete']),'classificationBasis':'sealed-relative-path-metadata-only','diagnosticLocationSubtreeCounts':dict(location),'diagnosticSuffixSubtreeCounts':dict(suffix),'diagnosticUnionNodeCount':len(diagnostic),'diagnosticUnionTypeCounts':dict(diagnostic_types),'directDiagnosticSuffixNodeCount':len(direct_suffix),'diagnosticOpaqueIDs':sorted(sha(path.encode()) for path in diagnostic),'moduleCacheNameMatchedNodes':len(module),'indexNameMatchedNodes':len(index),'sourceProvenRebuildableNodes':None,'sourceProvenRebuildability':'not-established-by-sealed-metadata-or-current-cache-root-allowlist','remainingOutsideDiagnosticClassifierNodeCount':len(plan['delete'])-len(diagnostic),'unknownMayIncludeOtherDiagnosticKinds':True,'allDiagnosticKindsCovered':False,'originalRawMappingAppliesToTheseDiagnostics':False,'diagnosticContentRead':False,'targetNodesReadOrScanned':False,'newInventoryOrPlanProduced':False,'originalPlanOrAllowlistChanged':False,'actualDeleteBatchCount':0,'uniqueOrIrreplaceableContentDetermined':False,'blocker':'diagnostic-bearing-candidates-require-evidence-coverage-and-specific-review-before-deletion' if diagnostic else 'metadata-alone-does-not-prove-all-delete-candidates-rebuildable','scopeReason':'Current make_plan selects all unreferenced DerivedData nodes; rawMap only accounts for top-level raw and has no diagnostic exclusion for these cache-subtree nodes.'}

def main():
    tick();parser=argparse.ArgumentParser();parser.add_argument('--sidecar',required=True);parser.add_argument('--out',required=True);args=parser.parse_args()
    fd=open_sidecar(args.sidecar)
    try:manifest=read_sealed(fd,'inventory.private.json');plan=read_sealed(fd,'plan.private.json')
    finally:os.close(fd)
    value=classify(manifest,plan);raw=canonical(value)
    if b'/Users/' in raw:raise ValueError('public-schema')
    target=Path(args.out);f=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
    with os.fdopen(f,'wb') as stream:stream.write(raw);stream.flush();os.fsync(stream.fileno())
    if target.read_bytes()!=raw:raise ValueError('write')
    print(json.dumps({k:value[k] for k in ('diagnosticUnionNodeCount','diagnosticUnionTypeCounts','diagnosticLocationSubtreeCounts','diagnosticSuffixSubtreeCounts','directDiagnosticSuffixNodeCount','moduleCacheNameMatchedNodes','indexNameMatchedNodes','remainingOutsideDiagnosticClassifierNodeCount','actualDeleteBatchCount','recordedUTC')}|{'summarySHA256':sha(raw),'classifierSHA256':value['classifierSHA256']},sort_keys=True))

if __name__=='__main__':
    try:main()
    except BaseException as error:print(json.dumps({'metadataClassificationStopped':True,'errorType':type(error).__name__,'rawExported':False,'actualDeleteBatchCount':0}))
