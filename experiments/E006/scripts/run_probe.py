"""Future authorized single-run coordinator. Default/unauthorized invocation does nothing live."""
import argparse
import datetime as dt
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import uuid

import preflight
from ux_stages import (Rejected, UXStages, exclusive_json, now_utc, private_root,
                       public_receipt, read_json, safe_path, sha256, timestamp, load_window)



def setup_root(root, namespace):
    root=private_root(root,namespace)
    if not root.resolve().is_relative_to(Path(tempfile.gettempdir()).resolve()) and not root.resolve().is_relative_to(Path('/private/tmp').resolve()):
        raise Rejected('temporaryRootRequired')
    return root


def begin_window(root, namespace, statement):
    root=setup_root(root,namespace)
    if any(root.iterdir()) or not isinstance(statement,str) or not statement.strip():
        raise Rejected('freshWindowAndHumanSetupReadyRequired')
    start=now_utc()
    value={'namespace':namespace,'kind':'setup-window','synthetic':False,'observationMode':'human-only',
           'humanReadyStatement':statement,'startUTC':start.isoformat(),
           'cutoffUTC':(start+dt.timedelta(minutes=25)).isoformat(),
           'deadlineUTC':(start+dt.timedelta(minutes=30)).isoformat()}
    exclusive_json(root/'window.json',value)
    print('Setup window recorded. Human settings, later proof and measurement share this t0; no assets inspected or App launched.',flush=True)


def bound_window(root, manifest, proof):
    # Cleanup may be past deadline: verify original binding without resetting/extending it.
    if (sha256(safe_path(root,'window.json'))!=manifest['windowSHA256'] or
            proof.get('windowSHA256')!=manifest['windowSHA256']):
        raise Rejected('setupWindowChanged')

def controlled_run(body, cleanup):
    """Same finally path for normal, rejected, timeout and caught signal exits."""
    state={'mayHaveWritten':False}
    result={'completed':False,'cleanup':'not-attempted','cleanupComplete':True,'recoveryRequired':False}
    try:
        body(state)
        result['completed']=True
    except (Exception, KeyboardInterrupt):
        result['error']='controlledStop'
    finally:
        if state['mayHaveWritten']:
            try:
                clean=cleanup() is True
            except (Exception, KeyboardInterrupt):
                clean=False
            result.update(cleanup='delete-read-absent',cleanupComplete=clean,recoveryRequired=not clean)
    return result


def verify_installed(root, proof, expected):
    app=safe_path(root,'current/DPKProbe.app')
    # Recheck the selected installed artifact, not caller booleans. No SecItem.
    with tempfile.TemporaryDirectory(prefix='E006-installed-check-') as temp:
        actual=preflight.inspect_app(app,temp)
    if (actual['hash'] != expected or actual['profileHash'] != proof['profileSHA256'] or
            actual['certificateHash'] != proof['certificateSHA256'] or
            actual['requirement'] != proof['requirement'] or actual['entitlements'] != proof['entitlements']):
        raise Rejected('installedIdentityChanged')
    source_root=Path(__file__).resolve().parents[1]
    if any(sha256(source_root/name) != digest for name,digest in proof['sourceSHA256'].items()):
        raise Rejected('sourceChangedAfterPreflight')
    return app


def stop_owned_process(root, phase, binary, require_record=False):
    path=safe_path(root,f'control/process-{phase}.json')
    if not path.exists():
        if require_record: raise Rejected('ownedProcessExitUnconfirmed')
        return
    record=json.loads(path.read_text())
    pid=record.get('pid')
    namespace=root.name.removeprefix('rivet-E006-')
    if (type(pid) is not int or pid<=1 or record.get('namespace')!=namespace or
            type(record.get('phase')) is not int or record.get('phase')!=phase):
        raise Rejected('ownedProcessExitUnconfirmed')
    probe=subprocess.run(['/bin/ps','-p',str(pid),'-o','comm='],capture_output=True,text=True)
    if probe.returncode==0:
        if probe.stdout.strip()!=str(binary):
            # PID was reused by a different executable: original process has exited.
            # Do not signal that unrelated process.
            if not probe.stdout.strip(): raise Rejected('ownedProcessExitUnconfirmed')
            return
        try: os.kill(pid,signal.SIGTERM)
        except ProcessLookupError: return
        end=time.monotonic()+3
        while time.monotonic()<end:
            try: os.kill(pid,0)
            except ProcessLookupError: return
            time.sleep(.05)
        raise Rejected('ownedAppDidNotExit')
    if probe.returncode==1 and not probe.stdout.strip():
        try: os.kill(pid,0)
        except ProcessLookupError: return
    # ps failure/permissions are not proof of exit. No broad kill or SIGKILL.
    raise Rejected('ownedProcessExitUnconfirmed')


def ensure_owned_processes_exited(root, binary):
    """Gate every new launch/bundle mutation, including finally cleanup."""
    namespace=root.name.removeprefix('rivet-E006-')
    for phase in range(1,5):
        launched=safe_path(root,f'control/launch-{phase}.json')
        exited=safe_path(root,f'control/exit-{phase}.json')
        process=safe_path(root,f'control/process-{phase}.json')
        if launched.exists():
            launch=json.loads(launched.read_text())
            if launch.get('namespace')!=namespace or type(launch.get('phase')) is not int or launch['phase']!=phase:
                raise Rejected('ownedProcessExitUnconfirmed')
        if exited.exists():
            record=json.loads(exited.read_text())
            if (record.get('namespace')!=namespace or type(record.get('phase')) is not int or
                    record.get('phase')!=phase or record.get('exitConfirmed') is not True):
                raise Rejected('ownedProcessExitUnconfirmed')
        if process.exists() or (launched.exists() and not exited.exists()):
            stop_owned_process(root,phase,binary,require_record=True)
            if launched.exists() and not exited.exists():
                exclusive_json(exited,{'namespace':namespace,'phase':phase,'exitConfirmed':True})


def launch_once(root, manifest, proof, phase, operation, expected):
    bound_window(root,manifest,proof)
    app=safe_path(root,'current/DPKProbe.app')
    binary=preflight.executable(app)[0]
    ensure_owned_processes_exited(root,binary)
    app=verify_installed(root,proof,expected)
    limit=timestamp(manifest['cutoffUTC'] if phase<4 else manifest['deadlineUTC'])
    remaining=(limit-now_utc()).total_seconds()
    if phase<4 and remaining<=0:
        raise Rejected('measurementDeadline')
    # Emergency cleanup is allowed after deadline, bounded separately and never measurement.
    timeout=max(1,min(remaining,60)) if remaining>0 else 15
    command=['/usr/bin/open','-W','-n',str(app),'--args','--scratch',str(root),
             '--namespace',manifest['namespace'],'--phase',str(phase),'--operation',operation]
    exclusive_json(safe_path(root,f'control/launch-{phase}.json'),{'namespace':manifest['namespace'],'phase':phase})
    process=subprocess.Popen(command,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    wrapper_exited_normally=False
    try:
        if process.wait(timeout=timeout)!=0:
            raise Rejected('launchFailed')
        wrapper_exited_normally=True
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=3)
        # Never allow another App or replace the bundle while an owned phase survives.
        stop_owned_process(root,phase,binary,require_record=not wrapper_exited_normally)
        exclusive_json(safe_path(root,f'control/exit-{phase}.json'),
                       {'namespace':manifest['namespace'],'phase':phase,'exitConfirmed':True})
    receipt=read_json(root,f'receipts/phase-{phase}.machine.json')
    if (receipt.get('namespace') != manifest['namespace'] or receipt.get('phase') != phase or
            receipt.get('synthetic') is not False or receipt.get('completed') is not True or
            receipt.get('proofSHA256') != manifest['proofSHA256'] or receipt.get('executableSHA256') != expected):
        raise Rejected('operationReceiptRejected')
    if phase<4 and (len(receipt.get('fields',{}))!=6 or not all(value is True for value in receipt['fields'].values())):
        raise Rejected('sixFieldComparisonFailed')
    return receipt


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live',action='store_true')
    parser.add_argument('--human-asset-authorization',action='store_true')
    parser.add_argument('--begin-window',action='store_true')
    parser.add_argument('--namespace')
    parser.add_argument('--human-ready-statement')
    parser.add_argument('--selection',type=Path)
    parser.add_argument('--scratch',type=Path,required=True)
    parser.add_argument('--out',type=Path)
    args=parser.parse_args()
    if args.begin_window:
        if args.live or args.human_asset_authorization or args.selection or args.out or not args.namespace:
            raise Rejected('bookkeepingOnlyModeRequired')
        begin_window(args.scratch,args.namespace,args.human_ready_statement)
        return 0
    if not args.live or not args.human_asset_authorization or not args.selection or not args.out:
        raise Rejected('explicitHumanAuthorizationRequired')
    selection=json.loads(args.selection.read_text())
    namespace=selection['namespace']
    root=setup_root(args.scratch,namespace)
    window,window_hash=load_window(root,namespace,now_utc())
    if 'startUTC' in selection and timestamp(selection['startUTC'])!=timestamp(window['startUTC']):
        raise Rejected('selectionCannotResetWindow')
    if any(path.name!='window.json' for path in root.iterdir()): raise Rejected('freshWindowScratchRequired')
    if args.out.resolve().is_relative_to(root.resolve()): raise Rejected('externalEvidenceRequired')
    # Existing run files are never reused. Caller creates a fresh private scratch only.
    for name in ('run.json','preflight.json','current','receipts','control'):
        if safe_path(root,name).exists(): raise Rejected('runAlreadyExists')
    if args.out.exists() or args.out.is_symlink(): raise Rejected('receiptAlreadyExists')
    start=timestamp(window['startUTC'])
    selection={**selection,'startUTC':window['startUTC'],'windowSHA256':window_hash}
    (root/'receipts').mkdir(mode=0o700); (root/'control').mkdir(mode=0o700); (root/'current').mkdir(mode=0o700)
    try:
        proof=preflight.live_preflight(selection,True,window_root=root)
        if proof.get('windowSHA256')!=window_hash:
            raise Rejected('setupWindowProofMismatch')
    except BaseException:
        # This root was verified fresh and empty before we created its owned files.
        # No App or SecItem has run; selected external developer assets stay untouched.
        shutil.rmtree(root)
        raise
    exclusive_json(root/'preflight.json',proof)
    manifest={'namespace':namespace,'observationMode':'human-only','synthetic':False,'backend':'dpk',
              'startUTC':window['startUTC'],'cutoffUTC':window['cutoffUTC'],
              'deadlineUTC':window['deadlineUTC'],'windowSHA256':window_hash,
              'firstHash':proof['firstHash'],'secondHash':proof['secondHash'],
              'proofSHA256':sha256(root/'preflight.json'),
              'service':'local.rivet.experiments.E006.'+namespace,'account':'oauth-bundle'}
    exclusive_json(root/'run.json',manifest)
    stages=UXStages(root,manifest)
    current_hash=proof['firstHash']
    cleanup_done=False
    cleanup_blocker=None
    def interrupted(signum, frame): raise Rejected('controlledSignal')
    old={s:signal.signal(s,interrupted) for s in (signal.SIGINT,signal.SIGTERM)}
    def cleanup():
        nonlocal cleanup_done, cleanup_blocker
        # Repeated caught signals cannot interrupt the finally cleanup attempt.
        for s in old: signal.signal(s,signal.SIG_IGN)
        try:
            ensure_owned_processes_exited(root,preflight.executable(safe_path(root,'current/DPKProbe.app'))[0])
        except (Rejected,OSError,ValueError):
            cleanup_blocker='ownedProcessExitUnconfirmed'
            return False
        if cleanup_done: return True
        if not (root/'cleanup-request.json').exists():
            exclusive_json(root/'cleanup-request.json',{'namespace':namespace,'proofSHA256':manifest['proofSHA256'],'mayHaveWritten':True})
        receipt_path=safe_path(root,'receipts/phase-4.machine.json')
        if receipt_path.exists():
            # An attempted cleanup is not rerun under the same immutable phase.
            value=json.loads(receipt_path.read_text())
        else:
            value=launch_once(root,manifest,proof,4,'delete-read-absent',current_hash)
        cleanup_done=value.get('completed') is True and value.get('absent') is True
        return cleanup_done
    def body(state):
        nonlocal current_hash, cleanup_done
        shutil.copytree(proof['firstApp'],root/'current/DPKProbe.app',symlinks=False)
        verify_installed(root,proof,current_hash)
        exclusive_json(root/'receipts/phase-0.machine.json',{
            'namespace':namespace,'phase':0,'observationMode':'human-only','synthetic':False,
            'startedUTC':start.isoformat(),'endedUTC':now_utc().isoformat(),
            'proofSHA256':manifest['proofSHA256'],'executableSHA256':current_hash,
            'completed':True,'promptCount':None})
        print('Setup complete. Paused for phase 0 Human observation and phase 1 ready.',flush=True)
        for phase, operation in ((1,'save-read-a'),(2,'read-a'),(3,'read-a')):
            stages.wait_ready(phase)
            if phase==3:
                # Recheck every owned process before replacing/removing the fixed bundle.
                ensure_owned_processes_exited(root,preflight.executable(safe_path(root,'current/DPKProbe.app'))[0])
                shutil.rmtree(root/'current/DPKProbe.app')
                shutil.copytree(proof['secondApp'],root/'current/DPKProbe.app',symlinks=False)
                current_hash=proof['secondHash']
            if phase==1: state['mayHaveWritten']=True
            launch_once(root,manifest,proof,phase,operation,current_hash)
            print(f'Phase {phase} complete; paused for Human observation.',flush=True)
        stages.wait_ready(4)
        value=launch_once(root,manifest,proof,4,'delete-read-absent',current_hash)
        cleanup_done=value.get('absent') is True
        if not cleanup_done: raise Rejected('cleanupIncomplete')
    try:
        result=controlled_run(body,cleanup)
        if result['cleanupComplete']:
            try:
                ensure_owned_processes_exited(root,preflight.executable(safe_path(root,'current/DPKProbe.app'))[0])
            except (Rejected,OSError,ValueError):
                cleanup_blocker='ownedProcessExitUnconfirmed'
                result.update(cleanupComplete=False,recoveryRequired=True)
        if not result['cleanupComplete']: result['error']='cleanupIncomplete'
        # Prompt/UX classification requires final Human sidecar; machine never guesses it.
        result.update(namespace=namespace,synthetic=False,observationMode='human-only',promptCount=None,
                      startedUTC=start.isoformat(),endedUTC=now_utc().isoformat(),
                      proofSHA256=manifest['proofSHA256'])
        evidence={'machine':public_receipt(result),'manifest':{k:v for k,v in manifest.items() if k!='service'},
                  'phaseReceipts':{},'developerAssets':'Human-owned retained; never deleted',
                  'uxResult':'無法判定：等待完整 Human sidecars 與獨立驗證',
                  'realDataOperationsAttempted':(root/'control/process-1.json').exists(),
                  'cleanupBlocker':cleanup_blocker,'windowSHA256':window_hash}
        for item in sorted((root/'receipts').glob('phase-*.machine.json')):
            evidence['phaseReceipts'][item.name]={'sha256':sha256(item),'receipt':public_receipt(json.loads(item.read_text()))}
        exclusive_json(args.out,evidence)
        if result['cleanupComplete']:
            # Sidecars are collected separately while paused; copy safe receipts before final removal.
            destination=args.out.parent/(args.out.stem+'-phases')
            destination.mkdir(mode=0o700,exist_ok=False)
            for item in sorted((root/'receipts').glob('*.json')):
                shutil.copyfile(item,destination/item.name)
            shutil.copyfile(root/'window.json',destination/'window.json')
            control=destination/'control'; control.mkdir(mode=0o700)
            for pattern in ('gate-*.json','notice-*.json','launch-*.json','exit-*.json'):
                for item in sorted((root/'control').glob(pattern)):
                    shutil.copyfile(item,control/item.name)
            exclusive_json(destination/'index.json',{'namespace':namespace,
                'files':{str(p.relative_to(destination)):sha256(p) for p in sorted(destination.rglob('*.json'))}})
            shutil.rmtree(root)
        else:
            exclusive_json(root/'recovery.json',{'namespace':namespace,'operation':'delete-read-absent',
                'phase':4,'proofSHA256':manifest['proofSHA256'],'cleanupBlocker':cleanup_blocker,
                'warning':'Keep signed App and private proof. If owned exit is unconfirmed, do not launch another App or replace/remove the bundle. Human intervention required; no measurement retry.'})
        print('Run stopped. See safe machine receipt; Human observations remain separate.',flush=True)
        return 0 if result['completed'] and result['cleanupComplete'] else 2
    finally:
        for s,handler in old.items(): signal.signal(s,handler)

if __name__=='__main__':
    try: raise SystemExit(main())
    except (Rejected,KeyError,ValueError,OSError,subprocess.SubprocessError):
        print('Coordinator rejected; inspect finite guards, do not retry live automatically.')
        raise SystemExit(2)
