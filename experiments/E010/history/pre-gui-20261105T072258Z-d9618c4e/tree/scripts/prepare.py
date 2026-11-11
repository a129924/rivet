"""Unsigned preparation; explicit MAIN-only direct build. Never launches or provisions."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import os
import signal
import time
import tempfile
import uuid
from continuity import Rejected, canonical, file_hash, utc


def commands(source, output, namespace):
    bundle = 'local.rivet.dpkcontinuity.' + namespace.replace('-', '')
    return [['/usr/bin/xcodebuild', 'build', '-project', str(source/'DPKContinuityProbe.xcodeproj'),
             '-scheme', 'DPKContinuityProbe', '-configuration', config, '-derivedDataPath', str(output/config),
             'CODE_SIGNING_ALLOWED=NO', 'CODE_SIGNING_REQUIRED=NO', 'E010_BUNDLE_IDENTIFIER='+bundle]
            for config in ('Debug', 'Rebuilt')]


# Fixed MAIN build path. This is executable only with live intent + current package
# controls; synthetic tests inject the subprocess boundary, never invoke Xcode.
BUILD_INPUTS=('DPKContinuityProbe.xcodeproj/project.pbxproj','DPKContinuityProbe.xcodeproj/xcshareddata/xcschemes/DPKContinuityProbe.xcscheme','Sources/DPKContinuityProbe/AppMain.swift','Sources/DPKContinuityProbe/LiveGate.swift','Sources/DPKContinuityProbe/LiveStore.swift','Sources/DPKContinuityProbe/ProbeCore.swift','Resources/Info.plist','Resources/DPKContinuityProbe.entitlements')
XCODEBUILD='/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild'


def build_environment(base):
    """Finite child environment. Never inherits xcconfig/build/signing/dyld overrides."""
    import os
    home=os.environ.get('HOME')
    if not home or '\x00' in home:raise Rejected('buildHomeUnavailable')
    temporary=base/'TemporaryItems';temporary.mkdir(mode=0o700,exist_ok=True)
    return {'HOME':home,'PATH':'/usr/bin:/bin:/usr/sbin:/sbin','DEVELOPER_DIR':str(Path(XCODEBUILD).parents[2]),'TMPDIR':str(temporary)+'/', 'LANG':'en_US.UTF-8','LC_ALL':'en_US.UTF-8'}


def process_snapshot():
    """Read-only process metadata; retain only this build's new session/descendants."""
    result=subprocess.run(['/bin/ps','-axo','uid=,pid=,ppid=,pgid=,lstart=,comm='],capture_output=True,text=True,timeout=3)
    if result.returncode:raise Rejected('buildProcessOwnershipUnconfirmed')
    records=[]
    for line in result.stdout.splitlines():
        parts=line.split(None,9)
        if len(parts)!=10:raise Rejected('buildProcessOwnershipUnconfirmed')
        try:uid,pid,ppid,pgid=map(int,parts[:4])
        except ValueError:raise Rejected('buildProcessOwnershipUnconfirmed') from None
        records.append(dict(uid=uid,pid=pid,ppid=ppid,pgid=pgid,started=' '.join(parts[4:9]),comm=parts[9]))
    return records


def run_owned_build(command,log,environment,timeout):
    """One isolated build session. Never signals pre-existing/shared services."""
    from types import SimpleNamespace
    before=process_snapshot();preexisting={(p['pid'],p['started'],p['comm']) for p in before};owned={}
    code=None;classification='completed';confirmed=False;process=None
    def fingerprint(record):return (record['uid'],record['pid'],record['pgid'],record['started'],record['comm'])
    def refresh():
        records=process_snapshot()
        current={p['pid']:p for p in records}
        leader=current.get(process.pid)
        if not owned and leader and leader['uid']==os.getuid() and leader['comm']==command[0] and (leader['pid'],leader['started'],leader['comm']) not in preexisting:owned[leader['pid']]=leader
        changed=True
        while changed:
            changed=False
            verified={pid for pid,value in owned.items() if pid in current and fingerprint(current[pid])==fingerprint(value)}
            group_proven=any(current[pid]['pgid']==process.pid for pid in verified)
            for p in records:
                if p['uid']!=os.getuid() or (p['pid'],p['started'],p['comm']) in preexisting:continue
                if (group_proven and p['pgid']==process.pid) or p['ppid'] in verified:
                    if p['pid'] not in owned:owned[p['pid']]=p;changed=True
        if not owned and any(p['pgid']==process.pid for p in records):raise Rejected('buildProcessOwnershipUnconfirmed')
        return [p for p in records if p['pid'] in owned and fingerprint(p)==fingerprint(owned[p['pid']])]
    with log.open('xb') as stream:
        try:
            process=subprocess.Popen(command,stdout=stream,stderr=subprocess.STDOUT,env=dict(environment),start_new_session=True)
            end=time.monotonic()+timeout
            while True:
                refresh();remaining=end-time.monotonic()
                if remaining<=0:classification='timeout';break
                try:code=process.wait(timeout=min(.2,remaining));break
                except subprocess.TimeoutExpired:continue
            remaining_owned=refresh()
            if classification=='completed' and (code!=0 or remaining_owned):classification='failed' if code else 'ownedDescendantsRemaining'
            if not remaining_owned:confirmed=True
        except KeyboardInterrupt:classification='interrupted'
        except (OSError,Rejected,subprocess.SubprocessError):classification='ownershipUnconfirmed'
        if process is not None and not confirmed:
            try:
                current=refresh()
                # PID birth/executable/session identity must still match immediately before signal.
                for record in sorted(current,key=lambda p:p['pid']==process.pid):
                    latest={p['pid']:p for p in process_snapshot()}.get(record['pid'])
                    if latest is None:continue
                    if fingerprint(latest)!=fingerprint(record):raise Rejected('buildProcessIdentityChanged')
                    try:os.kill(record['pid'],signal.SIGTERM)
                    except ProcessLookupError:pass
                end=time.monotonic()+3
                while time.monotonic()<end:
                    if not refresh():confirmed=True;break
                    time.sleep(.05)
            except (OSError,Rejected,KeyboardInterrupt):confirmed=False
        if process is not None:
            try:process.wait(timeout=.1)
            except (subprocess.TimeoutExpired,KeyboardInterrupt):pass
        stream.flush();os.fsync(stream.fileno())
    return SimpleNamespace(returncode=code,classification=classification,ownedProcessesExited=confirmed,ownedProcessRecords=list(owned.values()))


def ensure_builds_exited(context):
    from continuity import read,safe
    for phase in ('p0','p1','rebuilt','recovery'):
        base=safe(context.root,'builds/'+phase)
        if not (base/'attempt.json').exists():continue
        if not (base/'result.json').exists():raise Rejected('buildProcessExitUnconfirmed')
        result,_=read(context.root,'builds/'+phase+'/result.json')
        if result.get('ownedProcessesExited') is not True:raise Rejected('buildProcessExitUnconfirmed')


def signed_build(context,phase,executor=None,cleanup_attempt=None):
    import os,platform,plistlib,shutil
    from continuity import (Bootstrap,check_main,exclusive,read,safe,stamp,package_gate,require_recovery)
    from proof import source_hashes,guard_scope
    if phase not in ('p0','p1','rebuilt','recovery'):raise Rejected('signedBuildPhaseRejected')
    if context.synthetic and executor is None:raise Rejected('syntheticCannotBuildSignedHost')
    check_main(context);guard_scope(context);ensure_builds_exited(context)
    if isinstance(context,Bootstrap):
        if phase!='p0':raise Rejected('signedBuildPhaseRejected')
        context.setup_ready();window,window_sha=context.validate()
    else:
        number={'p1':2,'rebuilt':3}.get(phase)
        if phase=='recovery':
            require_recovery(context,cleanup_attempt)
            number=max(n for n in (1,2,3) if safe(context.root,'windows/'+str(n)+'.json').exists())
        if number is None:raise Rejected('signedBuildPhaseRejected')
        window,window_sha=context.window(number,cleanup=phase=='recovery')
        if phase!='recovery':
            stage={'p1':'p1-setup','rebuilt':'rebuild-setup'}[phase]
            previous=context.events[-1][1] if context.events else context.global_hash
            gate,_=package_gate(context,stage,previous,'gates/'+stage+'.json',number)
            context.require_ready(stage,gate)
    request,request_sha=read(context.root,'build-requests/'+phase+'.json')
    config='Rebuilt' if phase=='rebuilt' else 'Debug';bundle=context.manifest['bundleIdentifier']
    if (request.get('namespace')!=context.manifest['namespace'] or request.get('phase')!=phase or
        request.get('sourceSHA256')!=context.manifest['sourceSHA256'] or request.get('bundleIdentifier')!=bundle or
        __import__('re').fullmatch('[A-Z0-9]{10}',request.get('teamIdentifier','')) is None or
        __import__('re').fullmatch('[0-9a-fA-F]{40}',request.get('certificateSHA1','')) is None or
        __import__('re').fullmatch('[0-9a-f]{64}',request.get('certificateSHA256','')) is None):raise Rejected('signedBuildRequestRejected')
    try:uuid.UUID(request['profileUUID'])
    except (ValueError,KeyError,TypeError):raise Rejected('signedBuildRequestRejected') from None
    profile=safe(context.root,'assets/'+phase+'.provisionprofile')
    if file_hash(profile)!=request.get('profileSHA256'):raise Rejected('selectedBuildProfileChanged')
    leaf=safe(context.root,'assets/selected-leaf.der');leaf_bytes=leaf.read_bytes()
    if hashlib.sha1(leaf_bytes).hexdigest().lower()!=request['certificateSHA1'].lower() or hashlib.sha256(leaf_bytes).hexdigest()!=request['certificateSHA256']:raise Rejected('selectedBuildCertificateChanged')
    if phase!='p0':
        baseline,_=read(context.root,'proofs/'+('p1' if phase=='rebuilt' else 'p0')+'.json')
        if request['certificateSHA256']!=baseline['certificateSHA256'] or (phase=='rebuilt' and request['profileSHA256']!=baseline['profileSHA256']):raise Rejected('profileOnlyBuildControlChanged')
    base=safe(context.root,'builds/'+phase)
    if base.exists():raise Rejected('signedBuildAlreadyAttempted')
    # Three immutable main slots plus a single cleanup slot; no retry/extra build.
    slots=[p for p in safe(context.root,'builds').glob('*') if (p/'attempt.json').exists()]
    if sum(p.name!='recovery' for p in slots)>=3 and phase!='recovery':raise Rejected('signedBuildBudgetExhausted')
    if phase=='recovery' and any(p.name=='recovery' for p in slots):raise Rejected('signedBuildBudgetExhausted')
    base.mkdir(mode=0o700,parents=True);source=Path(__file__).resolve().parents[1]
    frozen=base/'source';frozen.mkdir(mode=0o700)
    hashes={}
    for rel in BUILD_INPUTS:
        src=source/rel;raw=src.read_bytes()
        if src.is_symlink() or file_hash(src)!=context.manifest['sourceSHA256'].get(rel):raise Rejected('buildSourceChanged')
        dest=frozen/rel;dest.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
        fd=os.open(dest,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
        with os.fdopen(fd,'wb') as f:f.write(raw);f.flush();os.fsync(f.fileno())
        hashes[rel]=file_hash(dest)
    products=base/'Products';app=products/'DPKContinuityProbe.app'
    arch=platform.machine()
    if arch not in ('arm64','x86_64'):raise Rejected('nativeMacDestinationRejected')
    command=[XCODEBUILD,'build','-project',str(frozen/'DPKContinuityProbe.xcodeproj'),'-scheme','DPKContinuityProbe','-configuration',config,'-destination','platform=macOS,arch='+arch,'-derivedDataPath',str(base/'DerivedData'),'CODE_SIGNING_ALLOWED=YES','CODE_SIGNING_REQUIRED=YES','CODE_SIGN_STYLE=Manual','DEVELOPMENT_TEAM='+request['teamIdentifier'],'CODE_SIGN_IDENTITY='+request['certificateSHA1'],'PROVISIONING_PROFILE='+request['profileUUID'],'PROVISIONING_PROFILE_SPECIFIER=','E010_BUNDLE_IDENTIFIER='+bundle,'CONFIGURATION_BUILD_DIR='+str(products),'SYMROOT='+str(base/'Build'),'OBJROOT='+str(base/'Intermediates.noindex')]
    environment=build_environment(base)
    environment_sha=hashlib.sha256(canonical(environment)).hexdigest()
    config_value={'effectiveEnvironment':environment,'effectiveEnvironmentSHA256':environment_sha,'configuration':config,'scheme':'DPKContinuityProbe','destination':'platform=macOS,arch='+arch,'command':command,'expectedAppRelative':str(app.relative_to(context.root)),'requestSHA256':request_sha,'sourceSHA256':hashes,'windowSHA256':window_sha,'mainConsentSHA256':context.manifest['mainConsentSHA256']}
    from continuity import digest
    config_sha=digest(canonical(config_value));start=context.clock();limit=stamp(window['deadlineUTC'] if phase=='recovery' else window['cutoffUTC'])
    if start>=limit:raise Rejected('signedBuildDeadline')
    attempt=dict(config_value,kind='signed-build-attempt',phase=phase,namespace=context.manifest['namespace'],synthetic=context.synthetic,startedUTC=start.isoformat(),configurationSHA256=config_sha)
    exclusive(context.root,str((base/'attempt.json').relative_to(context.root)),attempt)
    log=base/'build.raw.log'
    from types import SimpleNamespace
    try:
        if executor is None:result=run_owned_build(command,log,environment,max(1,(limit-start).total_seconds()))
        else:result=executor(command,log,app,config,bundle,dict(environment))
    except (Exception,KeyboardInterrupt):
        if not log.exists():log.touch(mode=0o600)
        result=SimpleNamespace(returncode=None,classification='executorUnconfirmed',ownedProcessesExited=False,ownedProcessRecords=[])
    exited=getattr(result,'ownedProcessesExited',context.synthetic and executor is not None)
    classification=getattr(result,'classification','completed' if result.returncode==0 else 'failed')
    end=context.clock()
    if result.returncode==0 and end>=limit and classification=='completed':classification='late'
    result_value={'kind':'signed-build-result','phase':phase,'namespace':context.manifest['namespace'],'synthetic':context.synthetic,'attemptSHA256':file_hash(base/'attempt.json'),'configurationSHA256':config_sha,'sourceSHA256':hashes,'sourceRoot':str(frozen),'appPath':str(app),'configuration':config,'buildLogSHA256':file_hash(log),'exitCode':result.returncode,'startedUTC':start.isoformat(),'endedUTC':end.isoformat(),'profileSHA256':request['profileSHA256'],'certificateSHA256':request['certificateSHA256'],'signedHostVerified':False,'effectiveEnvironmentSHA256':environment_sha,'ownedProcessesExited':exited,'classification':classification,'recoveryRequired':not exited,'ownedProcessRecords':getattr(result,'ownedProcessRecords',[])}
    if result.returncode==0 and end<limit and exited and classification=='completed':
        try:
            from proof import app_hash
            info=plistlib.loads((app/'Contents/Info.plist').read_bytes());marker='rebuilt' if phase=='rebuilt' else 'initial'
            if info.get('CFBundleIdentifier')!=bundle or info.get('CFBundleExecutable')!='DPKContinuityProbe' or info.get('E010BuildMarker')!=marker:raise Rejected('builtAppIdentityRejected')
            result_value.update(appSHA256=app_hash(app),executableSHA256=file_hash(app/'Contents/MacOS/DPKContinuityProbe'),InfoSHA256=file_hash(app/'Contents/Info.plist'))
        except (OSError,ValueError,Rejected):result_value['classification']='invalidProduct'
    relative=str((base/'result.json').relative_to(context.root));exclusive(context.root,relative,result_value)
    if result.returncode!=0 or end>=limit or not exited or result_value['classification']!='completed':raise Rejected('signedBuildFailedOrLate')
    selection={'appPath':str(app),'sourceRoot':str(frozen),'buildReceiptRelative':relative}
    destination='selection/'+phase+'.json' if phase!='recovery' else 'recovery-attempts/'+cleanup_attempt+'/selection.json'
    exclusive(context.root,destination,selection)
    return selection


def failed_build_control(context,phase):
    """Verify failed-attempt control bytes, never inspect or accept an App as a host."""
    from continuity import check_main,read,safe,digest,stamp
    check_main(context);ensure_builds_exited(context)
    if phase not in ('p0','p1','rebuilt','recovery'):raise Rejected('signedBuildPhaseRejected')
    base=safe(context.root,'builds/'+phase);result,result_sha=read(context.root,'builds/'+phase+'/result.json');attempt,attempt_sha=read(context.root,'builds/'+phase+'/attempt.json')
    if (result.get('namespace')!=context.manifest['namespace'] or result.get('synthetic') is not context.synthetic or result.get('phase')!=phase or
        result.get('attemptSHA256')!=attempt_sha or result.get('ownedProcessesExited') is not True or
        result.get('classification') not in ('failed','late','timeout','interrupted','ownershipUnconfirmed','ownedDescendantsRemaining','invalidProduct','executorUnconfirmed') or
        (result.get('exitCode')==0 and result.get('classification')=='completed') or file_hash(base/'build.raw.log')!=result.get('buildLogSHA256') or
        attempt.get('mainConsentSHA256')!=context.manifest['mainConsentSHA256']):raise Rejected('failedBuildControlChanged')
    keys=('configuration','scheme','destination','command','expectedAppRelative','requestSHA256','sourceSHA256','windowSHA256','mainConsentSHA256','effectiveEnvironment','effectiveEnvironmentSHA256')
    config={key:attempt[key] for key in keys}
    if digest(canonical(config))!=result.get('configurationSHA256') or digest(canonical(attempt['effectiveEnvironment']))!=result.get('effectiveEnvironmentSHA256'):raise Rejected('failedBuildControlChanged')
    if not stamp(result['startedUTC'])<=stamp(result['endedUTC'])<=context.clock():raise Rejected('failedBuildControlChanged')
    for relative in BUILD_INPUTS:
        sha=context.manifest['sourceSHA256'].get(relative)
        if result['sourceSHA256'].get(relative)!=sha or attempt['sourceSHA256'].get(relative)!=sha or file_hash(safe(base/'source',relative))!=sha:raise Rejected('failedBuildSourceChanged')
    return result,result_sha


def verify_build_provenance(selection,context):
    from continuity import read,safe,stamp,check_main
    from proof import app_hash
    import plistlib
    check_main(context);ensure_builds_exited(context)
    rel=selection.get('buildReceiptRelative')
    if rel not in ('builds/p0/result.json','builds/p1/result.json','builds/rebuilt/result.json','builds/recovery/result.json'):raise Rejected('directBuildProvenanceRequired')
    result,result_sha=read(context.root,rel);base=safe(context.root,str(Path(rel).parent));attempt,attempt_sha=read(context.root,str(Path(rel).parent/'attempt.json'))
    phase=base.name;config='Rebuilt' if phase=='rebuilt' else 'Debug'
    expected=base/'Products/DPKContinuityProbe.app';source=base/'source'
    if (result.get('namespace')!=context.manifest['namespace'] or result.get('synthetic') is not context.synthetic or result.get('exitCode')!=0 or result.get('ownedProcessesExited') is not True or result.get('classification')!='completed' or
        result.get('attemptSHA256')!=attempt_sha or result.get('configuration')!=config or result.get('sourceRoot')!=str(source) or
        result.get('appPath')!=str(expected) or selection.get('appPath')!=str(expected) or selection.get('sourceRoot')!=str(source) or
        attempt.get('mainConsentSHA256')!=context.manifest['mainConsentSHA256'] or attempt.get('phase')!=phase or
        attempt.get('scheme')!='DPKContinuityProbe' or attempt.get('configuration')!=config or
        attempt.get('configurationSHA256')!=result.get('configurationSHA256') or file_hash(base/'build.raw.log')!=result.get('buildLogSHA256') or
        app_hash(expected)!=result.get('appSHA256') or file_hash(expected/'Contents/MacOS/DPKContinuityProbe')!=result.get('executableSHA256') or
        file_hash(expected/'Contents/Info.plist')!=result.get('InfoSHA256')):raise Rejected('directBuildProvenanceChanged')
    for rel in BUILD_INPUTS:
        sha=context.manifest['sourceSHA256'].get(rel)
        if file_hash(safe(source,rel))!=sha or attempt['sourceSHA256'].get(rel)!=sha or result['sourceSHA256'].get(rel)!=sha:raise Rejected('directBuildSourceChanged')
    config_value={k:attempt[k] for k in ('configuration','scheme','destination','command','expectedAppRelative','requestSHA256','sourceSHA256','windowSHA256','mainConsentSHA256','effectiveEnvironment','effectiveEnvironmentSHA256')}
    from continuity import digest
    if digest(canonical(config_value))!=result['configurationSHA256'] or digest(canonical(attempt['effectiveEnvironment']))!=result.get('effectiveEnvironmentSHA256') or result.get('effectiveEnvironmentSHA256')!=attempt.get('effectiveEnvironmentSHA256'):raise Rejected('directBuildConfigurationChanged')
    window_no={'p0':1,'p1':2,'rebuilt':3}.get(phase)
    if window_no is None:window_no=max(n for n in (1,2,3) if safe(context.root,'windows/'+str(n)+'.json').exists())
    window,_=read(context.root,'windows/'+str(window_no)+'.json')
    if not stamp(window['startUTC'])<=stamp(result['startedUTC'])<=stamp(result['endedUTC'])<stamp(window['deadlineUTC'] if phase=='recovery' else window['cutoffUTC']):raise Rejected('directBuildTimeRejected')
    return result,result_sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path)
    parser.add_argument('--live',action='store_true')
    parser.add_argument('--signed-build',choices=('p0','p1','rebuilt','recovery'))
    parser.add_argument('--root',type=Path)
    parser.add_argument('--cleanup-attempt')
    parser.add_argument('--unsigned-build', action='store_true')
    args = parser.parse_args(); output = args.out
    if args.signed_build:
        if not args.live or args.root is None or output is not None or args.unsigned_build:raise Rejected('explicitSignedBuildIntentRequired')
        from continuity import Bootstrap,Run
        context=Bootstrap(args.root) if args.signed_build=='p0' else Run(args.root)
        signed_build(context,args.signed_build,cleanup_attempt=args.cleanup_attempt)
        print('Direct build ended; actual signed-material proof is still required.');return 0
    if args.live or args.root is not None or output is None:raise Rejected('unsignedPreparationIntentRequired')
    if output.exists() or output.is_symlink(): raise Rejected('freshPreparationOutputRequired')
    parent = output.parent.resolve()
    if not (parent.is_relative_to(Path('/private/tmp')) or parent.is_relative_to(Path(tempfile.gettempdir()).resolve())):
        raise Rejected('temporaryUnsignedOutputRequired')
    output.mkdir(mode=0o700, parents=True)
    source = Path(__file__).resolve().parents[1]; namespace = str(uuid.uuid4())
    inputs = [p for folder in ('Sources', 'Resources', 'DPKContinuityProbe.xcodeproj') for p in (source/folder).rglob('*') if p.is_file()]
    receipt = {'kind':'unsigned-preparation', 'synthetic':True, 'liveExecuted':False, 'namespace':namespace,
               'appLaunched':False, 'assetsInspected':False, 'SecurityCalls':0, 'clockArmed':False,
               'startedUTC':utc().isoformat(), 'buildInputsSHA256':{str(p.relative_to(source)):file_hash(p) for p in sorted(inputs)}, 'configurations':{}}
    for name, cmd in zip(('Debug','Rebuilt'), commands(source, output, namespace)):
        item = {'performed':args.unsigned_build, 'signingAllowed':False, 'signingRequired':False}
        if args.unsigned_build:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
            (output/(name+'.build.log')).write_text(result.stdout+result.stderr)
            item['exitCode'] = result.returncode
            if result.returncode:
                receipt['configurations'][name] = item; (output/'preparation.json').write_bytes(canonical(receipt))
                print('Unsigned compile failed; no App launched. See external build log.'); return 2
            executable = output/name/'Build/Products'/name/'DPKContinuityProbe.app/Contents/MacOS/DPKContinuityProbe'
            item['mainSHA256'] = file_hash(executable)
            item['debugDylibAbsent'] = not list(executable.parent.glob('*.debug.dylib'))
        receipt['configurations'][name] = item
    receipt['endedUTC'] = utc().isoformat(); (output/'preparation.json').write_bytes(canonical(receipt))
    print('Unsigned preparation complete; no signed build, App launch or live clock.'); return 0

if __name__ == '__main__':
    try: raise SystemExit(main())
    except (Rejected, OSError, ValueError, subprocess.SubprocessError):
        print('Preparation stopped; no live run.'); raise SystemExit(2)
