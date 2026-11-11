"""Reviewed RP caller; offline default has NO target IO.
Future argv: --phase diagnose|execute --params SAFE_JSON --params-sha SHA
             --offline-review SAFE_JSON --c0 UTC [--execution-review SAFE_JSON]
No caller loads private data until the fixed C0 clock and offline tuple pass.
"""
import argparse
import base64
import datetime as dt
import json
import os
import stat
import sys
from pathlib import Path
import retention_pruner as p

TARGET_REL = 'Library/Application Support/RivetExperiments/rivet-E010-' + p.NS
JOB_REL = 'Library/Application Support/RivetExperiments/E010-retention-prune-rp-20261110T081057Z'


def safe_read(path, limit=16*1024*1024):
    fd=os.open(path, os.O_RDONLY|os.O_NOFOLLOW)
    try:
        s=os.fstat(fd)
        if not stat.S_ISREG(s.st_mode) or s.st_uid != os.getuid() or s.st_nlink != 1 or s.st_size > limit:
            raise p.Refused('binding')
        return os.read(fd, limit+1)
    finally: os.close(fd)


def source_check(params):
    base=Path(__file__).absolute().parents[2]
    # This file is evidence/<job>/caller: parents[2] is E010. Never invoke live scripts.
    raw=safe_read(base/params['sourceManifestRelative'])
    if p.sha(raw)!=params['sourceManifestFileSHA256']: raise p.Refused('sourceChanged')
    manifest=json.loads(raw)
    if manifest['sourceManifestSHA256'] != p.SOURCE_AGGREGATE: raise p.Refused('sourceChanged')
    for relative, expected in manifest['sourceSHA256'].items():
        p.parts(relative)
        if p.sha(safe_read(base/relative))!=expected: raise p.Refused('sourceChanged')
    return manifest['sourceSHA256']


def verify_offline(params_raw, params, review):
    if review.get('phase')!='RP05-offline' or review.get('verdict')!='approved' or review.get('requiredFixes')!=[]:
        raise p.Refused('reviewMissing')
    actual={'parameterSHA256':p.sha(params_raw), 'actionSHA256':p.sha(safe_read(Path(__file__).with_name('retention_pruner.py'))),
            'callerSHA256':p.sha(safe_read(__file__))}
    if any(review.get(k)!=v for k,v in actual.items()): raise p.Refused('reviewMissing')
    if p.stamp(review['approvedUTC'])>p.stamp(p.OFFLINE_END): raise p.Refused('deadline')
    if params.get('namespace')!=p.NS or params.get('targetHomeRelative')!=TARGET_REL or params.get('jobHomeRelative')!=JOB_REL or params.get('retentionDeadlineUTC')!=p.D:
        raise p.Refused('binding')
    return actual


def window(c0):
    start=p.stamp(c0); now=p.utc()
    if start>now or start<p.stamp(p.R0) or start>p.stamp('2026-11-10T09:35:00Z'):
        raise p.Refused('deadline')
    deadline=min(start+dt.timedelta(minutes=30),p.stamp(p.TOTAL_END))
    return {'C0':c0,'diagnosticStopUTC':(start+dt.timedelta(minutes=20)).isoformat(),
            'targetStopUTC':deadline.isoformat(),'retentionDeadlineUTC':p.D}


def create_job(job, budget):
    parent, leaf=os.path.split(job)
    fd, chain=p.open_chain(parent,budget)
    try:
        if os.fstat(fd).st_uid!=os.getuid(): raise p.Refused('foreignOwner')
        budget.tick();os.mkdir(leaf,0o700,dir_fd=fd)
        child=os.open(leaf,p.FLAGS,dir_fd=fd)
        got=p.identity(os.fstat(child));p.owned(got,os.getuid(),os.fstat(fd).st_dev)
        if got['mode']!=0o700:os.close(child);raise p.Refused('binding')
        os.fsync(fd);return child
    finally:os.close(fd)


def job_open(job, budget):
    fd, chain=p.open_chain(job,budget)
    got=p.identity(os.fstat(fd));p.owned(got,os.getuid())
    if got['mode']!=0o700:os.close(fd);raise p.Refused('binding')
    return fd


def private_read(fd,name,budget):
    return p.read_at(fd,name,budget,os.getuid(),os.fstat(fd).st_dev)


def write(fd,name,value,budget):
    return p.exclusive_at(fd,name,p.canonical(value),budget)


def capture(fd,budget,kind,stdout,stderr):
    # Only newly generated native diagnostic; no original raw is moved here.
    streams={}
    for name,value in (('stdout',stdout),('stderr',stderr)):
        if value is None:streams[name]={'present':False};continue
        raw=value if isinstance(value,bytes) else value.encode('utf-8','surrogatepass')
        streams[name]={'present':True,'type':'bytes' if isinstance(value,bytes) else 'text',
                       'originalBytes':isinstance(value,bytes),'SHA256':p.sha(raw),
                       'encoding':None if isinstance(value,bytes) else 'utf-8-surrogatepass',
                       'base64':base64.b64encode(raw).decode('ascii')}
    write(fd,'native-failure.private.json',{'kind':kind,'streams':streams,
          'uniqueDiagnostic':True,'mayDeleteWithoutSpecificACK':False},budget)


def diagnose(target,jobfd,budget,sources,bindings):
    budget.tick(5)
    manifest=p.scan(target,budget)
    rootfd,chain=p.open_chain(target,budget,manifest['parentChain'])
    try:
        global_raw=p.read_at(rootfd,'global.json',budget,os.getuid(),manifest['rootIdentity']['dev'],manifest['nodes']['global.json']['identity'])
        global_value=json.loads(global_raw)
        if global_value.get('namespace')!=p.NS or global_value.get('sourceSHA256')!=sources or p.stamp(global_value.get('globalDeadlineUTC',''))!=p.stamp(p.D):
            raise p.Refused('namespace')
        records={}
        for path,node in manifest['nodes'].items():
            if node['identity']['type']==stat.S_IFREG and path.endswith('.json') and p.parts(path)[0] not in ('raw',)+p.CACHE_ROOTS:
                raw=p.read_at(rootfd,path,budget,os.getuid(),manifest['rootIdentity']['dev'],node['identity'])
                try:records[path]=json.loads(raw)
                except (ValueError,UnicodeError):records[path]={'path':'unresolved-invalid-json'}
    finally:os.close(rootfd)
    retained_state=p.verify_retained_state(manifest,target,records,sources)
    p.handles_clear(target,budget,lambda *args:capture(jobfd,budget,*args))
    plan=p.make_plan(manifest,target,records)
    plan['retainedStateFileProof']=retained_state
    job_identity=p.identity(os.fstat(jobfd))
    job_stable={k:job_identity[k] for k in ('dev','ino','uid','mode','type')}
    plan['jobIdentity']=job_stable
    plan['binding']=bindings
    map_value={'dependencies':plan['dependencies'],'rawMap':plan['rawMap']}
    plan['mapSHA256']=p.sha(p.canonical(map_value))
    candidate=p.safe_candidate(plan,manifest)
    plan['candidateSHA256']=p.sha(p.canonical(candidate))
    # Save evidence first, immutable and read-verified. Candidate contains no raw paths/IDs.
    write(jobfd,'inventory.private.json',manifest,budget)
    write(jobfd,'map.private.json',map_value,budget)
    write(jobfd,'plan.private.json',plan,budget)
    write(jobfd,'candidate.safe.json',candidate,budget)
    return {'status':'review-required','candidateSHA256':plan['candidateSHA256'],
            'privateManifestSHA256':plan['manifestSHA256'],'privatePlanSHA256':p.sha(p.canonical(plan)), 'privateMapSHA256':plan['mapSHA256'],
            'retainSHA256':plan['retainListSHA256'],'deleteSHA256':plan['deleteListSHA256'],
            'deleteCount':len(plan['delete']),'unknownCount':len(plan['unknownDependencyIDs']),
            'rawUncoveredCount':len(plan['rawMap']),'minimumComplete':False,'recoveryRequired':True}


def execute(target,jobfd,budget,bindings,review):
    budget.tick(5)  # BEFORE loading private inventory/map/plan.
    raw=private_read(jobfd,'inventory.private.json',budget);manifest=json.loads(raw)
    plan_raw=private_read(jobfd,'plan.private.json',budget);plan=json.loads(plan_raw)
    candidate_raw=private_read(jobfd,'candidate.safe.json',budget)
    map_raw=private_read(jobfd,'map.private.json',budget)
    if p.sha(map_raw)!=plan['mapSHA256']:raise p.Refused('drift')
    expected_files={'window.private.json','bindings.private.json','inventory.private.json','map.private.json','plan.private.json','candidate.safe.json'}
    budget.tick()
    with os.scandir(jobfd) as entries:
        names=set()
        for entry in entries:budget.tick();names.add(entry.name)
    if names!=expected_files:raise p.Refused('binding')
    expected={'phase':'RP-live-execution','verdict':'approved','requiredFixes':[],
              'readabilityACK':True,'safetyACK':True,'candidateSHA256':p.sha(candidate_raw),
              'manifestSHA256':p.sha(raw),'planSHA256':p.sha(plan_raw),'mapSHA256':p.sha(map_raw),
              'retainListSHA256':plan['retainListSHA256'],'deleteListSHA256':plan['deleteListSHA256'],**bindings}
    job_identity=p.identity(os.fstat(jobfd))
    if {k:job_identity[k] for k in ('dev','ino','uid','mode','type')}!=plan['jobIdentity']:raise p.Refused('binding')
    if review!=expected or plan['binding']!=bindings:raise p.Refused('reviewMissing')
    counter=[0]
    def persist(result):
        # Only bounded safe facts. No target path or raw payload reaches this stream.
        counter[0]+=1
        write(jobfd,'progress-%06d.safe.json'%counter[0],result,budget)
    handle=lambda:p.handles_clear(target,budget,lambda *args:capture(jobfd,budget,*args))
    result=p.execute(target,manifest,plan,budget,jobfd,
                     {k:review[k] for k in ('candidateSHA256','readabilityACK','safetyACK','verdict')},handle,persist,lambda error:capture(jobfd,budget,'execution-exception',str(error),None))
    return result


def cli(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase',choices=('diagnose','execute'),required=True)
    parser.add_argument('--params',required=True);parser.add_argument('--params-sha',required=True)
    parser.add_argument('--offline-review',required=True);parser.add_argument('--c0',required=True)
    parser.add_argument('--execution-review')
    args=parser.parse_args(argv);jobfd=None;result={'status':'refused','error':'unexpected','targetIOAttempted':False}
    try:
        # Fixed hard guard before params/private reads. No global deadline extension.
        if p.utc()>=p.stamp(p.TOTAL_END):raise p.Refused('deadline')
        win=window(args.c0)
        stop=win['diagnosticStopUTC'] if args.phase=='diagnose' else win['targetStopUTC']
        budget=p.Budget(stop);budget.tick(5)
        here=Path(__file__).absolute().parent
        if Path(args.params).absolute()!=here/'execution-parameters.safe.json' or Path(args.offline_review).absolute()!=here/'offline-review-approval.safe.json':raise p.Refused('binding')
        if args.execution_review and Path(args.execution_review).absolute()!=here/'execution-review-approval.safe.json':raise p.Refused('binding')
        raw=safe_read(args.params)
        if p.sha(raw)!=args.params_sha:raise p.Refused('binding')
        params=json.loads(raw);review=json.loads(safe_read(args.offline_review))
        bindings=verify_offline(raw,params,review)
        sources=source_check(params)
        home=os.path.expanduser('~');target=os.path.join(home,TARGET_REL);job=os.path.join(home,JOB_REL)
        # Home and every later parent must be owned; system ancestors uid0 are allowed.
        homefd,_=p.open_chain(home,budget)
        try:
            if os.fstat(homefd).st_uid!=os.getuid():raise p.Refused('foreignOwner')
        finally:os.close(homefd)
        budget.tick(5)
        if args.phase=='diagnose':
            jobfd=create_job(job,budget);write(jobfd,'window.private.json',win,budget)
            write(jobfd,'bindings.private.json',bindings,budget)
            result['targetIOAttempted']=True
            result=diagnose(target,jobfd,budget,sources,bindings)
        else:
            jobfd=job_open(job,budget)
            if json.loads(private_read(jobfd,'window.private.json',budget))!=win:raise p.Refused('binding')
            if not args.execution_review:raise p.Refused('reviewMissing')
            actual_review=json.loads(safe_read(args.execution_review))
            result['targetIOAttempted']=True
            result=execute(target,jobfd,budget,bindings,actual_review)
        result_sha=p.sha(p.canonical(result))
        if args.phase=='execute':
            try:write(jobfd,'execution-result.safe.json',result,budget)
            except BaseException:result['finalPublicationComplete']=False
        summary={k:v for k,v in result.items() if k in ('status','error','candidateSHA256','privateManifestSHA256','privatePlanSHA256','privateMapSHA256','retainSHA256','deleteSHA256','deleteCount','unknownCount','rawUncoveredCount','minimumComplete','recoveryRequired','cleanupComplete','allowlistComplete','startedUTC','endedUTC','failed','finalUnknown','prechecks','finalPublicationComplete')}
        summary.update(resultSHA256=result_sha,completedCount=len(result.get('completed',[])),attemptedCount=len(result.get('attempted',[])))
        print(p.canonical(summary).decode('utf-8'),end='')
        return 0 if result.get('cleanupComplete') else 2
    except BaseException as error:
        captured=False
        if jobfd is not None and not isinstance(error,p.Refused):
            try:capture(jobfd,budget,'caller-exception',str(error),None);captured=True
            except BaseException:pass
        result={'privateFailureCaptured':captured,'status':'refused','error':error.reason if isinstance(error,p.Refused) else 'unexpected',
                'minimumComplete':False,'recoveryRequired':True}
        # No exception strings, repr, traceback, private names, or raw streams.
        print(p.canonical(result).decode('utf-8'),end='');return 2
    finally:
        if jobfd is not None:os.close(jobfd)


if __name__=='__main__':sys.exit(cli())
