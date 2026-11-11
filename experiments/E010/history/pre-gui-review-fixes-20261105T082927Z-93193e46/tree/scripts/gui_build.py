"""Fixed E010 GUI hook protocol. CLI emits finite safe summaries only; never drives Xcode/UI."""
import argparse
import copy
import datetime as dt
import difflib
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import uuid
import xml.etree.ElementTree as ET
import continuity as c

EVIDENCE='gui-hooks-v1'
TARGET='DPKContinuityProbe'
PHASES={'p0':(1,'Debug','DPKContinuityProbe'),'p1':(2,'Debug','DPKContinuityProbe'),'rebuilt':(3,'Rebuilt','DPKContinuityProbe-Rebuilt'),'recovery':(None,'Debug','DPKContinuityProbe')}
INPUTS=('DPKContinuityProbe.xcodeproj/project.pbxproj','DPKContinuityProbe.xcodeproj/xcshareddata/xcschemes/DPKContinuityProbe.xcscheme','DPKContinuityProbe.xcodeproj/xcshareddata/xcschemes/DPKContinuityProbe-Rebuilt.xcscheme','Sources/DPKContinuityProbe/AppMain.swift','Sources/DPKContinuityProbe/LiveGate.swift','Sources/DPKContinuityProbe/LiveStore.swift','Sources/DPKContinuityProbe/ProbeCore.swift','Resources/Info.plist','Resources/DPKContinuityProbe.entitlements')


def gui(context):
    if context.manifest.get('authorizationMode')!='gui-package' or context.manifest.get('buildEvidenceType')!=EVIDENCE:raise c.Rejected('GUIEvidenceRequired')
    c.check_main(context)
    stat=context.root.stat();binding={'device':stat.st_dev,'inode':stat.st_ino,'ownerUID':stat.st_uid,'mode':stat.st_mode & 0o777}
    if context.manifest.get('rootBinding')!=binding or context.manifest.get('rootBindingSHA256')!=c.digest(c.canonical(binding)):raise c.Rejected('GUIRootBindingChanged')
    from proof import source_hashes
    if source_hashes()!=context.manifest['sourceSHA256']:raise c.Rejected('sourceChanged')


def window(context,phase):
    gui(context)
    if phase not in PHASES:raise c.Rejected('GUIPhaseRejected')
    number=PHASES[phase][0]
    if phase=='recovery':
        number=max(n for n in (1,2,3) if c.safe(context.root,'windows/'+str(n)+'.json').exists())
    if isinstance(context,c.Bootstrap):
        if phase!='p0':raise c.Rejected('GUIPhaseRejected')
        return context.validate()
    if phase=='rebuilt' and not c.safe(context.root,'windows/3.json').exists():context.arm_window(3,None)
    return context.window(number,cleanup=phase=='recovery')


def write_private(root,relative,raw):
    p=c.safe(root,relative);p.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
    fd=os.open(p,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
    with os.fdopen(fd,'wb') as f:f.write(raw);f.flush();os.fsync(f.fileno())
    return c.digest(raw)


def capture_command(context,args,phase='p0'):
    """Raw command output stays private, including failures. No default logging/traceback."""
    if context.synthetic:raise c.Rejected('syntheticCannotInspectAssets')
    win,_=window(context,phase);remaining=(c.stamp(win['deadlineUTC'] if phase=='recovery' else win['cutoffUTC'])-context.clock()).total_seconds()
    if remaining<=0:raise c.Rejected('GUICommandDeadline')
    prefix='raw/command-'+str(uuid.uuid4())
    try:result=subprocess.run(args,capture_output=True,timeout=min(30,remaining))
    except (OSError,subprocess.SubprocessError) as error:
        write_private(context.root,prefix+'.exception.txt',repr(error).encode())
        raise c.Rejected('localVerificationUnavailable') from None
    write_private(context.root,prefix+'.stdout',result.stdout);write_private(context.root,prefix+'.stderr',result.stderr)
    if result.returncode:raise c.Rejected('localVerificationRejected')
    return result.stdout,result.stderr


def inspect_public_leaf(context,path):
    capture_command(context,['/usr/bin/security','verify-cert','-p','codeSign','-c',str(path)])
    out,_=capture_command(context,['/usr/bin/openssl','x509','-inform','DER','-in',str(path),'-noout','-dates'])
    try:
        values=dict(line.split('=',1) for line in out.decode().splitlines())
        date=lambda k:dt.datetime.strptime(values[k],'%b %d %H:%M:%S %Y %Z').replace(tzinfo=c.UTC).isoformat()
        return dict(certificateSHA256=c.file_hash(path),certificateNotBeforeUTC=date('notBefore'),certificateNotAfterUTC=date('notAfter'),codeSignTrustVerified=True)
    except (ValueError,KeyError,UnicodeError):raise c.Rejected('publicLeafMetadataRejected') from None


def freeze_leaf(context,inspector=None):
    window(context,'p0')
    if c.safe(context.root,'configured').exists() or c.safe(context.root,'gui/p0/arm.json').exists():raise c.Rejected('leafMustPrecedeAutomatic')
    path=c.safe(context.root,'inbox/original.cer')
    if not path.is_file() or path.is_symlink() or path.stat().st_uid!=os.getuid():raise c.Rejected('selectedPublicDERRequired')
    os.chmod(path,0o600)
    if not path.read_bytes().startswith(b'0'):raise c.Rejected('publicDERRequired')
    if context.synthetic and inspector is None:raise c.Rejected('mockLeafInspectorRequired')
    value=(inspector(path) if inspector else inspect_public_leaf(context,path))
    if (value.get('certificateSHA256')!=c.file_hash(path) or value.get('codeSignTrustVerified') is not True or
        c.stamp(value.get('certificateNotBeforeUTC'))>context.clock() or c.stamp(value.get('certificateNotAfterUTC'))<c.stamp(context.manifest['globalDeadlineUTC'])+dt.timedelta(minutes=35)):raise c.Rejected('originalLeafNotQualified')
    window(context,'p0');write_private(context.root,'reference/original.cer',path.read_bytes())
    record={key:value[key] for key in ('certificateSHA256','certificateNotBeforeUTC','certificateNotAfterUTC','codeSignTrustVerified')}
    record.update(kind='original-public-leaf-reference',namespace=context.namespace,synthetic=context.synthetic,anchorSHA256=context.anchor_hash,sourceSHA256=context.manifest['sourceSHA256'],frozenUTC=context.clock().isoformat())
    c.exclusive(context.root,'reference/original-leaf.json',record)
    return record


def reference(context):
    gui(context)
    if not c.safe(context.root,'reference/original-leaf.json').exists():raise c.Rejected('originalLeafReferenceRequired')
    value,sha=c.read(context.root,'reference/original-leaf.json')
    if (value.get('namespace')!=context.manifest['namespace'] or value.get('synthetic') is not context.synthetic or value.get('sourceSHA256')!=context.manifest['sourceSHA256'] or value.get('anchorSHA256')!=context.manifest.get('anchorSHA256',getattr(context,'anchor_hash',None)) or value.get('codeSignTrustVerified') is not True or c.file_hash(c.safe(context.root,'reference/original.cer'))!=value.get('certificateSHA256') or c.stamp(value['certificateNotAfterUTC'])<c.stamp(context.manifest['globalDeadlineUTC'])+dt.timedelta(minutes=35)):raise c.Rejected('originalLeafReferenceChanged')
    return value,sha


def patch_project(raw):
    text=raw.decode();file_id='AA0000000000000000000098'
    if file_id in text:raise c.Rejected('configuredTemplateChanged')
    text=text.replace('objects = {','objects = {\n'+file_id+' = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = private.xcconfig; sourceTree = SOURCE_ROOT; };',1)
    count=0
    def config(m):
        nonlocal count;count+=1
        return m.group(1)+'baseConfigurationReference = '+file_id+'; '+m.group(2)
    text=re.sub(r'([A-F0-9]{24} = \{isa = XCBuildConfiguration; )(buildSettings = \{)',config,text)
    if count!=4:raise c.Rejected('fourConfigurationsRequired')
    text=text.replace('CC0000000000000000000002 = {isa = PBXGroup; children = (','CC0000000000000000000002 = {isa = PBXGroup; children = ('+file_id+', ',1)
    return text.encode()


def config_bytes(context,phase=None,nonce=None,product=None):
    values={'CODE_SIGN_STYLE':'Automatic','CODE_SIGNING_ALLOWED':'YES','CODE_SIGNING_REQUIRED':'YES','E010_BUNDLE_IDENTIFIER':context.manifest['bundleIdentifier'],'E010_CONTROL_ROOT':str(context.root),'E010_GUI_PHASE':phase or 'unarmed','E010_GUI_NONCE':nonce or 'unarmed','SYMROOT':str(context.root/'build-output'),'OBJROOT':str(context.root/'intermediates'),'CONFIGURATION_BUILD_DIR':str(product or context.root/'unarmed-products')}
    return ('\n'.join(k+' = '+v for k,v in values.items())+'\n').encode()


def configure(context):
    window(context,'p0');reference(context)
    source=Path(__file__).resolve().parents[1]
    if c.safe(context.root,'configured').exists():raise c.Rejected('configuredCopyAlreadyExists')
    # Keep canonical source separate from Human-private Team settings.
    for relative,sha in context.manifest['sourceSHA256'].items():
        raw=(source/relative).read_bytes()
        if c.digest(raw)!=sha:raise c.Rejected('sourceChanged')
        write_private(context.root,'frozen-source/'+relative,raw)
    for relative in INPUTS:write_private(context.root,'configured/'+relative,(source/relative).read_bytes() if not relative.endswith('project.pbxproj') else patch_project((source/relative).read_bytes()))
    write_private(context.root,'configured/private.xcconfig',config_bytes(context))
    workspace='configured/DPKContinuityProbe.xcodeproj/project.xcworkspace/'
    write_private(context.root,workspace+'contents.xcworkspacedata',b'<?xml version="1.0"?><Workspace version="1.0"><FileRef location="self:"/></Workspace>\n')
    import getpass
    settings={'DerivedDataLocationStyle':'AbsolutePath','DerivedDataCustomLocation':str(context.root/'DerivedData')}
    write_private(context.root,workspace+'xcuserdata/'+getpass.getuser()+'.xcuserdatad/WorkspaceSettings.xcsettings',plistlib.dumps(settings,sort_keys=True))
    c.exclusive(context.root,'gui/configured.json',{'namespace':context.namespace,'synthetic':context.synthetic,'sourceSHA256':context.manifest['sourceSHA256'],'originalLeafReferenceSHA256':reference(context)[1],'createdUTC':context.clock().isoformat()})


def private_project_shape(context):
    def parse(raw):return json.loads(subprocess.run(['/usr/bin/plutil','-convert','json','-o','-','-'],input=raw,capture_output=True,check=True).stdout)
    baseline=patch_project((Path(__file__).resolve().parents[1]/'DPKContinuityProbe.xcodeproj/project.pbxproj').read_bytes())
    actual=c.safe(context.root,'configured/DPKContinuityProbe.xcodeproj/project.pbxproj').read_bytes()
    def normalize(value):
        value=copy.deepcopy(value)
        for obj in value['objects'].values():
            if obj.get('isa')=='XCBuildConfiguration':
                settings=obj['buildSettings']
                if settings.get('CODE_SIGN_STYLE','Automatic')!='Automatic':raise c.Rejected('GUIAutomaticRequired')
                if settings.get('CODE_SIGN_IDENTITY','Apple Development') not in ('','Apple Development'):raise c.Rejected('GUIIdentityOverrideRejected')
                if any(settings.get(k,'') for k in ('PROVISIONING_PROFILE','PROVISIONING_PROFILE_SPECIFIER')):raise c.Rejected('GUIManualProfileRejected')
                for key in ('DEVELOPMENT_TEAM','CODE_SIGN_STYLE','CODE_SIGN_IDENTITY','PROVISIONING_PROFILE','PROVISIONING_PROFILE_SPECIFIER'):settings.pop(key,None)
            if obj.get('isa')=='PBXProject':
                for attrs in obj.get('attributes',{}).get('TargetAttributes',{}).values():
                    if attrs.get('ProvisioningStyle')!='Automatic':raise c.Rejected('GUIAutomaticRequired')
                    attrs.pop('DevelopmentTeam',None)
        return value
    if normalize(parse(actual))!=normalize(parse(baseline)):raise c.Rejected('privateProjectOutsideApprovedFields')


def current_config(context,phase):
    private_project_shape(context)
    scheme=PHASES[phase][2]+'.xcscheme';base=c.safe(context.root,'configured')
    for relative,sha in context.manifest['sourceSHA256'].items():
        if relative.startswith(('Sources/','Resources/')) and c.file_hash(c.safe(base,relative))!=sha:raise c.Rejected('configuredCompiledSourceChanged')
    return {'projectSHA256':c.file_hash(base/'DPKContinuityProbe.xcodeproj/project.pbxproj'),'schemeSHA256':c.file_hash(base/'DPKContinuityProbe.xcodeproj/xcshareddata/xcschemes'/scheme),'xcconfigSHA256':c.file_hash(base/'private.xcconfig')}


def arm(context,phase):
    if not isinstance(context,c.Bootstrap) and phase in ('p1','rebuilt') and (not context.events or c.ORDER[len(context.events)]!={'p1':'p1-setup','rebuilt':'rebuild-setup'}[phase]):raise c.Rejected('GUIPhaseOrderRejected')
    win,win_sha=window(context,phase);_,leaf_sha=reference(context)
    configured,_=c.read(context.root,'gui/configured.json')
    if configured.get('sourceSHA256')!=context.manifest['sourceSHA256']:raise c.Rejected('configuredSourceChanged')
    if phase!='p0':
        expected={'p1':'p1-setup','rebuilt':'rebuild-setup'}.get(phase)
        if expected and (not context.events or c.ORDER[len(context.events)]!=expected):raise c.Rejected('GUIPhaseOrderRejected')
        if phase=='recovery' and not c.owned_write_possible(context.root,context.namespace,context.synthetic):raise c.Rejected('ownedItemNotProven')
    product='gui/'+phase+'/Products';nonce=str(uuid.uuid4())
    if c.safe(context.root,product).exists():raise c.Rejected('GUIFreshProductRequired')
    record={'kind':'gui-phase-arm','evidenceType':EVIDENCE,'namespace':context.namespace,'synthetic':context.synthetic,'phase':phase,'nonce':nonce,'windowSHA256':win_sha,'configuration':PHASES[phase][1],'scheme':PHASES[phase][2],'target':TARGET,'projectRelative':'configured/DPKContinuityProbe.xcodeproj','productRelative':product,'originalLeafReferenceSHA256':leaf_sha,'sourceSHA256':context.manifest['sourceSHA256'],'armedUTC':context.clock().isoformat(),'cutoffUTC':win['deadlineUTC'] if phase=='recovery' else win['cutoffUTC'],'deadlineUTC':win['deadlineUTC']}
    # Exclusive consumption precedes any config/output preparation. Failure never frees this slot.
    c.exclusive(context.root,'gui/'+phase+'/arm.json',record)
    c.safe(context.root,product).mkdir(mode=0o700,parents=True)
    path=c.safe(context.root,'configured/private.xcconfig');raw=config_bytes(context,phase,nonce,c.safe(context.root,product))
    with path.open('r+b') as stream:stream.write(raw);stream.truncate();stream.flush();os.fsync(stream.fileno())
    c.exclusive(context.root,'gui/'+phase+'/config.json',current_config(context,phase))
    return record


def verify_arm(context,phase):
    window(context,phase);record,sha=c.read(context.root,'gui/'+phase+'/arm.json');configuration,_=c.read(context.root,'gui/'+phase+'/config.json')
    if (record.get('namespace')!=context.manifest['namespace'] or record.get('synthetic') is not context.synthetic or record.get('evidenceType')!=EVIDENCE or record.get('sourceSHA256')!=context.manifest['sourceSHA256'] or record.get('phase')!=phase or record.get('originalLeafReferenceSHA256')!=reference(context)[1] or configuration!=current_config(context,phase) or not c.stamp(record['armedUTC'])<=context.clock()<c.stamp(record['cutoffUTC'])):raise c.Rejected('GUIArmOrSourceChanged')
    return record,sha,configuration


def hook(context,kind,environment):
    phase=environment.get('E010_GUI_PHASE');record,arm_sha,configuration=verify_arm(context,phase)
    expected={'E010_CONTROL_ROOT':str(context.root),'E010_GUI_PHASE':phase,'E010_GUI_NONCE':record['nonce'],'PROJECT_DIR':str(context.root/'configured'),'PROJECT_FILE_PATH':str(context.root/'configured/DPKContinuityProbe.xcodeproj'),'TARGET_NAME':TARGET,'PRODUCT_NAME':TARGET,'CONFIGURATION':record['configuration'],'PRODUCT_BUNDLE_IDENTIFIER':context.manifest['bundleIdentifier'],'TARGET_BUILD_DIR':str(context.root/record['productRelative']),'WRAPPER_NAME':TARGET+'.app','EXECUTABLE_PATH':TARGET+'.app/Contents/MacOS/'+TARGET}
    if kind not in ('pre','post') or any(environment.get(key)!=value for key,value in expected.items()):raise c.Rejected('GUIBuildEnvironmentRejected')
    app=c.safe(context.root,record['productRelative']+'/'+TARGET+'.app')
    value={'kind':'gui-'+kind+'-action','evidenceType':EVIDENCE,'namespace':context.manifest['namespace'],'synthetic':context.synthetic,'phase':phase,'nonce':record['nonce'],'armSHA256':arm_sha,'sourceSHA256':context.manifest['sourceSHA256'],'configurationSHA256':c.digest(c.canonical(configuration)),'recordedUTC':context.clock().isoformat(),'compilerExitCode':None,'fullCompilerLogAvailable':False}
    if kind=='pre':
        if app.exists():raise c.Rejected('GUIOldProductRejected')
    else:
        pre,pre_sha=c.read(context.root,'gui/'+phase+'/pre.json')
        if pre.get('nonce')!=record['nonce'] or pre.get('armSHA256')!=arm_sha:raise c.Rejected('GUIHookChainRejected')
        from proof import app_hash
        info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
        marker='rebuilt' if phase=='rebuilt' else 'initial'
        if info.get('CFBundleIdentifier')!=context.manifest['bundleIdentifier'] or info.get('CFBundleExecutable')!=TARGET or info.get('E010BuildMarker')!=marker:raise c.Rejected('GUIActualProductRejected')
        value.update(preSHA256=pre_sha,appSHA256=app_hash(app),executableSHA256=c.file_hash(app/'Contents/MacOS'/TARGET),InfoSHA256=c.file_hash(app/'Contents/Info.plist'),profileSHA256=c.file_hash(app/'Contents/embedded.provisionprofile'))
    c.exclusive(context.root,'gui/'+phase+'/'+kind+'.json',value)
    return value


def attest(context,phase,status,did_not_run):
    record,_,_=verify_arm(context,phase)
    post_sha=c.read(context.root,'gui/'+phase+'/post.json')[1] if c.safe(context.root,'gui/'+phase+'/post.json').exists() else None
    if status=='reported-success' and post_sha is None:raise c.Rejected('GUIPostHookRequired')
    if status not in ('reported-success','reported-failure') or did_not_run is not True:raise c.Rejected('limitedHumanBuildAttestationRequired')
    return c.exclusive(context.root,'gui/'+phase+'/human-build.json',{'kind':'limited-human-GUI-build-attestation','namespace':context.manifest['namespace'],'synthetic':context.synthetic,'phase':phase,'nonce':record['nonce'],'postSHA256':post_sha,'status':status,'didNotRun':True,'recordedUTC':context.clock().isoformat(),'humanExactUTC':None,'wholeStageObserved':None,'promptCount':None})


def verify_provenance(selection,context):
    phase=selection.get('guiPhase');record,arm_sha,configuration=verify_arm(context,phase)
    if selection.get('evidenceType')!=EVIDENCE or selection.get('appPath')!=str(context.root/record['productRelative']/(TARGET+'.app')) or selection.get('sourceRoot')!=str(context.root/'configured'):raise c.Rejected('GUIOnlyProductRequired')
    pre,pre_sha=c.read(context.root,'gui/'+phase+'/pre.json');post,post_sha=c.read(context.root,'gui/'+phase+'/post.json');human,human_sha=c.read(context.root,'gui/'+phase+'/human-build.json')
    for event in (pre,post):
        if event.get('armSHA256')!=arm_sha or event.get('nonce')!=record['nonce'] or event.get('sourceSHA256')!=context.manifest['sourceSHA256'] or event.get('configurationSHA256')!=c.digest(c.canonical(configuration)) or not c.stamp(record['armedUTC'])<=c.stamp(event['recordedUTC'])<=context.clock():raise c.Rejected('GUIHookChainRejected')
    if (post.get('preSHA256')!=pre_sha or human.get('namespace')!=context.manifest['namespace'] or human.get('nonce')!=record['nonce'] or human.get('postSHA256')!=post_sha or human.get('status')!='reported-success' or human.get('didNotRun') is not True or not c.stamp(post['recordedUTC'])<=c.stamp(human['recordedUTC'])<=context.clock()):raise c.Rejected('limitedHumanBuildAttestationRequired')
    from proof import app_hash
    app=Path(selection['appPath'])
    if app_hash(app)!=post['appSHA256'] or c.file_hash(app/'Contents/MacOS'/TARGET)!=post['executableSHA256'] or c.file_hash(app/'Contents/Info.plist')!=post['InfoSHA256'] or c.file_hash(app/'Contents/embedded.provisionprofile')!=post['profileSHA256']:raise c.Rejected('GUIProductChanged')
    return dict(post,armSHA256=arm_sha,postSHA256=post_sha,humanAttestationSHA256=human_sha,originalLeafReferenceSHA256=reference(context)[1]),post_sha


def finalize(context,phase,inspector=None):
    record,_,_=verify_arm(context,phase)
    selected={'evidenceType':EVIDENCE,'guiPhase':phase,'appPath':str(context.root/record['productRelative']/(TARGET+'.app')),'sourceRoot':str(context.root/'configured')}
    provenance,provenance_sha=verify_provenance(selected,context)
    if context.synthetic and inspector is None:raise c.Rejected('mockAssetInspectorRequired')
    from proof import inspect_selected,validate_asset
    asset=inspector(selected) if inspector else inspect_selected(selected,context)
    leaf,_=reference(context)
    if asset.get('certificateSHA256')!=leaf['certificateSHA256']:raise c.Rejected('originalLeafMismatch')
    asset.update(evidenceType=EVIDENCE,GUIProvenanceSHA256=provenance_sha,originalLeafReferenceSHA256=provenance['originalLeafReferenceSHA256'])
    if phase=='p0':c.bootstrap_asset(context,asset)
    else:
        baseline,_=c.read(context.root,'proofs/'+('p1' if phase=='rebuilt' else 'p0')+'.json')
        validate_asset(asset,context.manifest,context.clock(),baseline,'cleanup' if phase=='recovery' else phase)
    verify_arm(context,phase)
    asset_sha=c.exclusive(context.root,'gui/'+phase+'/actual-proof.json',asset)
    c.exclusive(context.root,'gui/'+phase+'/finalized.json',{'evidenceType':EVIDENCE,'namespace':context.manifest['namespace'],'phase':phase,'assetSHA256':asset_sha,'GUIProvenanceSHA256':provenance_sha,'sourceSHA256':context.manifest['sourceSHA256'],'completedUTC':context.clock().isoformat(),'postActionIsCompilerSuccessProof':False})
    c.exclusive(context.root,'selection/'+phase+'.json',selected)
    return asset


def accepted_asset(context,phase):
    selected,_=c.read(context.root,'selection/'+phase+'.json');provenance,sha=verify_provenance(selected,context)
    asset,asset_sha=c.read(context.root,'gui/'+phase+'/actual-proof.json');marker,_=c.read(context.root,'gui/'+phase+'/finalized.json')
    if marker.get('assetSHA256')!=asset_sha or marker.get('GUIProvenanceSHA256')!=sha or marker.get('sourceSHA256')!=context.manifest['sourceSHA256'] or asset.get('certificateSHA256')!=reference(context)[0]['certificateSHA256'] or asset.get('evidenceType')!=EVIDENCE:raise c.Rejected('GUIAcceptedProofChanged')
    return asset


def public_views(context):
    """Schema-aware finite projections only; never export paths, env, subjects or raw logs."""
    gui(context);views={}
    allowed=('kind','evidenceType','namespace','synthetic','phase','nonce','armSHA256','windowSHA256','sourceSHA256','configurationSHA256','originalLeafReferenceSHA256','armedUTC','cutoffUTC','deadlineUTC','recordedUTC','completedUTC','frozenUTC','certificateNotBeforeUTC','certificateNotAfterUTC','certificateSHA256','codeSignTrustVerified','configuration','scheme','target','preSHA256','postSHA256','appSHA256','executableSHA256','InfoSHA256','profileSHA256','assetSHA256','GUIProvenanceSHA256','status','didNotRun','humanExactUTC','wholeStageObserved','promptCount','compilerExitCode','fullCompilerLogAvailable','postActionIsCompilerSuccessProof','buildStopped','projectClosed','lastArmSHA256')
    finite={'kind':{'original-public-leaf-reference','gui-phase-arm','gui-pre-action','gui-post-action','limited-human-GUI-build-attestation','GUI-close-attestation'},'evidenceType':{EVIDENCE},'phase':set(PHASES),'configuration':{'Debug','Rebuilt'},'scheme':{'DPKContinuityProbe','DPKContinuityProbe-Rebuilt'},'target':{TARGET},'status':{'reported-success','reported-failure'}}
    paths=['reference/original-leaf.json','gui/cleanup-human.json']+[f'gui/{phase}/{leaf}.json' for phase in PHASES for leaf in ('arm','pre','post','human-build','finalized')]
    for relative in paths:
        if not c.safe(context.root,relative).exists():continue
        raw,sha=c.read(context.root,relative);view={key:raw[key] for key in allowed if key in raw}
        for key,value in view.items():
            if key in finite and value not in finite[key]:raise c.Rejected('GUISafeProjectionRejected')
            if key=='namespace' and value!=context.manifest['namespace']:raise c.Rejected('GUISafeProjectionRejected')
            if key=='sourceSHA256' and value!=context.manifest['sourceSHA256']:raise c.Rejected('GUISafeProjectionRejected')
            if key.endswith('SHA256') and key!='sourceSHA256' and not (key in ('lastArmSHA256','postSHA256') and value is None) and (not isinstance(value,str) or re.fullmatch('[0-9a-f]{64}',value) is None):raise c.Rejected('GUISafeProjectionRejected')
            if key.endswith('UTC') and value is not None:c.stamp(value)
            if key=='nonce' and str(uuid.UUID(value))!=value:raise c.Rejected('GUISafeProjectionRejected')
            if key in ('promptCount','wholeStageObserved','humanExactUTC','compilerExitCode') and value is not None:raise c.Rejected('GUISafeProjectionRejected')
            if key in ('synthetic','codeSignTrustVerified','didNotRun','fullCompilerLogAvailable','postActionIsCompilerSuccessProof','buildStopped','projectClosed') and type(value) is not bool:raise c.Rejected('GUISafeProjectionRejected')
        view['privateReceiptSHA256']=sha
        views[relative.removesuffix('.json')+'.public.json']=view
    return views


def copy_candidate(source,destination):
    """Only a durable, already safe-indexed candidate; byte verify before public export."""
    source=Path(source);destination=Path(destination)
    if destination.is_symlink() or any(p.is_symlink() for p in destination.parents):raise c.Rejected('unsafePublicDestination')
    index,index_sha=c.read(source,'pre-cleanup.index.json');files=dict(index['files']);files['pre-cleanup.index.json']=index_sha
    destination.mkdir(mode=0o700,parents=True,exist_ok=True)
    for relative,sha in files.items():
        raw=c.safe(source,relative).read_bytes()
        if c.digest(raw)!=sha:raise c.Rejected('safeCandidateChanged')
        target=c.safe(destination,relative)
        if target.exists():
            if target.read_bytes()!=raw:raise c.Rejected('publicReceiptCollision')
        else:write_private(destination,relative,raw)
    return destination


def handles_absent(context):
    if context.synthetic:raise c.Rejected('mockHandleVerifierRequired')
    result=subprocess.run(['/usr/sbin/lsof','-nP','+D',str(context.root)],capture_output=True,timeout=10)
    prefix='raw/cleanup-handles-'+str(uuid.uuid4())
    write_private(context.root,prefix+'.stdout',result.stdout);write_private(context.root,prefix+'.stderr',result.stderr)
    return result.returncode==1 and not result.stdout.strip() and not result.stderr.strip()


def record_closed(context,build_stopped,project_closed):
    gui(context)
    if isinstance(context,c.Bootstrap):context.validate(cleanup=True)
    else:context.window(max(n for n in (1,2,3) if c.safe(context.root,'windows/'+str(n)+'.json').exists()),cleanup=True)
    arms=[c.read(context.root,'gui/'+p+'/arm.json') for p in PHASES if c.safe(context.root,'gui/'+p+'/arm.json').exists()]
    last=max(arms,key=lambda item:c.stamp(item[0]['armedUTC']))[1] if arms else None
    if build_stopped is not True or project_closed is not True:raise c.Rejected('GUIBuildStoppedProjectClosedRequired')
    return c.exclusive(context.root,'gui/cleanup-human.json',{'kind':'GUI-close-attestation','namespace':context.manifest['namespace'],'synthetic':context.synthetic,'sourceSHA256':context.manifest['sourceSHA256'],'lastArmSHA256':last,'buildStopped':True,'projectClosed':True,'recordedUTC':context.clock().isoformat(),'humanExactUTC':None})


def closed_for_cleanup(context,handles=None):
    gui(context)
    if not c.safe(context.root,'configured').exists() and not any(c.safe(context.root,'gui/'+p+'/arm.json').exists() for p in PHASES):
        absent=handles(context.root) if handles else handles_absent(context)
        if not absent:raise c.Rejected('GUIOwnedHandlesUnconfirmed')
        return
    value,_=c.read(context.root,'gui/cleanup-human.json')
    arms=[c.read(context.root,'gui/'+p+'/arm.json') for p in PHASES if c.safe(context.root,'gui/'+p+'/arm.json').exists()]
    latest=max(arms,key=lambda item:c.stamp(item[0]['armedUTC'])) if arms else None
    if value.get('namespace')!=context.manifest['namespace'] or value.get('synthetic') is not context.synthetic or value.get('sourceSHA256')!=context.manifest['sourceSHA256'] or value.get('lastArmSHA256')!=(latest[1] if latest else None) or value.get('buildStopped') is not True or value.get('projectClosed') is not True or not (c.stamp(latest[0]['armedUTC']) if latest else c.stamp(context.manifest['startUTC']))<=c.stamp(value['recordedUTC'])<=context.clock():raise c.Rejected('GUIBuildStoppedProjectClosedRequired')
    absent=handles(context.root) if handles else handles_absent(context)
    if not absent:raise c.Rejected('GUIOwnedHandlesUnconfirmed')


def safe_summary(value):
    view={'classification':'completed-local-GUI-control','rawExported':False,'candidateOnly':True,'UX':'unknown'}
    if not isinstance(value,dict):return view
    keep=('certificateSHA256','certificateNotBeforeUTC','certificateNotAfterUTC','profileSHA256','profileCreationUTC','profileExpiryUTC','executableSHA256','appSHA256','DRSHA256','GUIProvenanceSHA256','originalLeafReferenceSHA256','codeSignTrustVerified','phase','configuration')
    for key in keep:
        if key not in value:continue
        item=value[key]
        if key.endswith('SHA256') and (not isinstance(item,str) or re.fullmatch('[0-9a-f]{64}',item) is None):raise c.Rejected('GUISafeProjectionRejected')
        if key.endswith('UTC'):c.stamp(item)
        if key=='phase' and item not in PHASES:raise c.Rejected('GUISafeProjectionRejected')
        if key=='configuration' and item not in ('Debug','Rebuilt'):raise c.Rejected('GUISafeProjectionRejected')
        if key=='codeSignTrustVerified' and type(item) is not bool:raise c.Rejected('GUISafeProjectionRejected')
        view[key]=item
    return view


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--live',action='store_true');parser.add_argument('--root',type=Path,required=True)
    modes=parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--record-closed',action='store_true');modes.add_argument('--freeze-public-leaf',action='store_true');modes.add_argument('--configure',action='store_true');modes.add_argument('--arm',choices=PHASES);modes.add_argument('--hook',choices=('pre','post'));modes.add_argument('--attest',choices=PHASES);modes.add_argument('--finalize',choices=PHASES)
    parser.add_argument('--build-stopped',action='store_true');parser.add_argument('--project-closed',action='store_true');parser.add_argument('--reported-success',action='store_true');parser.add_argument('--did-not-run',action='store_true');args=parser.parse_args()
    if not args.live:raise c.Rejected('preparationOnlyNoLiveCommands')
    context=c.Run(args.root) if c.safe(args.root,'global.json').exists() else c.Bootstrap(args.root)
    global _raw_context
    _raw_context=context
    result=None
    if args.record_closed:result=record_closed(context,args.build_stopped,args.project_closed)
    elif args.freeze_public_leaf:result=freeze_leaf(context)
    elif args.configure:result=configure(context)
    elif args.arm:result=arm(context,args.arm)
    elif args.hook:result=hook(context,args.hook,dict(os.environ))
    elif args.attest:result=attest(context,args.attest,'reported-success' if args.reported_success else 'reported-failure',args.did_not_run)
    else:result=finalize(context,args.finalize)
    print(json.dumps(safe_summary(result),sort_keys=True))

if __name__=='__main__':
    try:main()
    except (Exception,KeyboardInterrupt) as error:
        context=globals().get('_raw_context')
        if context is not None and context.root.exists():
            try:write_private(context.root,'raw/exception-'+str(uuid.uuid4())+'.txt',repr(error).encode())
            except Exception:pass
        # Never print str(exception), traceback, target environment or command stderr.
        print('{"classification":"GUI-control-stopped","rawExported":false}');raise SystemExit(2)
