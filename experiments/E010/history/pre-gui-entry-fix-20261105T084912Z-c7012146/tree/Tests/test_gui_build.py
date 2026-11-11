"""GUI evidence fixtures only; no real Xcode, certificate, App or Keychain calls."""
import datetime as dt
import json
import os
from pathlib import Path
import plistlib
import sys
import unittest
from unittest import mock
import uuid
import test_main_policy as prior
import continuity as c
import proof

class GUIBuildTests(unittest.TestCase):
    setUpBase=prior.MainPolicyTests.setUp
    def setUp(self):
        self.setUpBase();self.now=dt.datetime(2026,11,5,7,20,tzinfo=c.UTC);self.start=self.now
        consent=json.loads((self.root/'main-consent.json').read_bytes())
        consent.update(kind='E010-gui-package-consent',authorizationMode='gui-package',statement='synthetic approved GUI package',approvedUTC='2026-11-05T07:14:10Z',latestStartUTC='2026-11-06T07:14:10Z',grantsValidUntilUTC='2026-11-16T07:14:10Z',originalLeafBeforeAutoRequired=True,automaticCertificateSideEffectsAccepted=True,CUAProhibited=True,buildEvidenceType='gui-hooks-v1')
        (self.root/'main-consent.json').write_bytes(c.canonical(consent));sha=c.file_hash(self.root/'main-consent.json')
        for kind in ('assets','retention','recovery'):
            p=self.root/'grants'/ (kind+'.json');value=json.loads(p.read_bytes());value.update(authorizationMode='gui-package',mainConsentSHA256=sha,validUntilUTC='2026-11-16T07:14:10Z');p.write_bytes(c.canonical(value))
    def begin(self):
        if not (self.root/'gui-begin-sync.json').exists():
            c.exclusive(self.root,'gui-begin-sync.json',dict(kind='human-begin-sync',namespace=self.ns,synthetic=True,sourceSHA256=self.source,grantSHA256={kind:c.file_hash(self.root/'grants'/(kind+'.json')) for kind in ('assets','retention','recovery')},retentionRoot=str(self.root),humanCanBeginNow=True,statement='synthetic one-time begin collaboration',recordedUTC=self.clock().isoformat()))
        c.begin_anchor(self.root,self.ns,self.source,self.out,True,self.clock);return c.Bootstrap(self.root,True,self.clock)
    def leaf(self,ctx):
        import gui_build as g
        p=self.root/'inbox/original.cer';p.parent.mkdir(mode=0o700);p.write_bytes(b'\x30synthetic-public-certificate')
        self.leaf_sha=c.file_hash(p)
        g.freeze_leaf(ctx,inspector=lambda _:dict(certificateSHA256=self.leaf_sha,certificateNotBeforeUTC=(self.start-dt.timedelta(days=1)).isoformat(),certificateNotAfterUTC=(self.start+dt.timedelta(days=20)).isoformat(),codeSignTrustVerified=True))
    def phase(self):
        import gui_build as g
        ctx=self.begin();self.leaf(ctx);g.configure(ctx);arm=g.arm(ctx,'p0');return ctx,arm
    def environment(self,ctx,arm):
        return {'E010_CONTROL_ROOT':str(self.root),'E010_GUI_PHASE':arm['phase'],'E010_GUI_NONCE':arm['nonce'],'PROJECT_DIR':str(self.root/'configured'),'PROJECT_FILE_PATH':str(self.root/'configured/DPKContinuityProbe.xcodeproj'),'TARGET_NAME':'DPKContinuityProbe','PRODUCT_NAME':'DPKContinuityProbe','CONFIGURATION':arm['configuration'],'PRODUCT_BUNDLE_IDENTIFIER':ctx.manifest['bundleIdentifier'],'TARGET_BUILD_DIR':str(self.root/arm['productRelative']),'WRAPPER_NAME':'DPKContinuityProbe.app','EXECUTABLE_PATH':'DPKContinuityProbe.app/Contents/MacOS/DPKContinuityProbe'}
    def product(self,ctx,arm,marker='initial'):
        app=self.root/arm['productRelative']/'DPKContinuityProbe.app';(app/'Contents/MacOS').mkdir(parents=True)
        (app/'Contents/MacOS/DPKContinuityProbe').write_bytes(('synthetic-main-'+marker).encode())
        (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':ctx.manifest['bundleIdentifier'],'CFBundleExecutable':'DPKContinuityProbe','E010BuildMarker':marker}))
        (app/'Contents/embedded.provisionprofile').write_bytes(b'synthetic profile not CMS')
        return app
    def asset(self,ctx,app):
        group='SYNTHETIC.'+ctx.manifest['bundleIdentifier']
        return {'synthetic':True,'hostBindingSHA256':ctx.manifest['hostBindingSHA256'],'appPath':str(app),'appSHA256':proof.app_hash(app),'executableSHA256':c.file_hash(app/'Contents/MacOS/DPKContinuityProbe'),'profileSHA256':c.file_hash(app/'Contents/embedded.provisionprofile'),'certificateSHA256':self.leaf_sha,'DRSHA256':'d'*64,'bundleIdentifier':ctx.manifest['bundleIdentifier'],'buildMarker':'initial','sourceSHA256':ctx.manifest['sourceSHA256'],'entitlements':{'com.apple.application-identifier':group,'keychain-access-groups':[group]},'profile':{'ApplicationIdentifierPrefix':['SYNTHETIC'],'ProvisionedDevices':['synthetic-device'],'Platform':['OSX'],'Entitlements':{'com.apple.application-identifier':'SYNTHETIC.*','keychain-access-groups':['SYNTHETIC.*']}},'device':'synthetic-device','profileCreationUTC':(self.start-dt.timedelta(days=1)).isoformat(),'profileExpiryUTC':(self.start+dt.timedelta(days=7)).isoformat(),'certificateNotBeforeUTC':(self.start-dt.timedelta(days=1)).isoformat(),'certificateNotAfterUTC':(self.start+dt.timedelta(days=20)).isoformat(),'profileSignatureVerified':True,'certificateInProfile':True,'appleDevelopmentChainVerified':True,'evidenceType':'gui-hooks-v1'}
    def test_GUI_consent_leaf_before_auto_and_unique_slot(self):
        import gui_build as g
        ctx=self.begin()
        with self.assertRaises(c.Rejected):g.configure(ctx)
        self.leaf(ctx);g.configure(ctx);arm=g.arm(ctx,'p0')
        self.assertEqual(arm['evidenceType'],'gui-hooks-v1');self.assertEqual(arm['configuration'],'Debug')
        with self.assertRaises(c.Rejected):g.arm(ctx,'p0')
        self.assertFalse((self.root/'global.json').exists())
    def test_valid_hooks_actual_product_and_human_attestation_form_GUI_proof(self):
        import gui_build as g
        ctx,arm=self.phase();env=self.environment(ctx,arm);g.hook(ctx,'pre',env)
        app=self.product(ctx,arm);g.hook(ctx,'post',env)
        with self.assertRaises((c.Rejected,OSError)):g.finalize(ctx,'p0',inspector=lambda _:self.asset(ctx,app))
        g.attest(ctx,'p0','reported-success',did_not_run=True)
        asset=g.finalize(ctx,'p0',inspector=lambda _:self.asset(ctx,app))
        self.assertEqual(asset['certificateSHA256'],self.leaf_sha);self.assertEqual(asset['evidenceType'],'gui-hooks-v1')
        proof.inspect_bootstrap(ctx);c.complete_global(ctx);run=c.Run(self.root,True,self.clock)
        self.assertEqual(run.manifest['authorizationMode'],'gui-package');self.assertIsNone(c.observation_status(run,'seed')['promptCount'])
    def test_missing_duplicate_late_wrong_target_nonce_source_and_old_product_reject(self):
        import gui_build as g
        ctx,arm=self.phase();env=self.environment(ctx,arm)
        for key,bad in [('TARGET_NAME','Other'),('CONFIGURATION','Rebuilt'),('E010_GUI_NONCE',str(uuid.uuid4())),('PROJECT_DIR',str(self.root.parent))]:
            with self.subTest(key=key),self.assertRaises(c.Rejected):g.hook(ctx,'pre',dict(env,**{key:bad}))
        old=self.root/arm['productRelative']/'DPKContinuityProbe.app';old.mkdir()
        with self.assertRaises(c.Rejected):g.hook(ctx,'pre',env)
        old.rmdir()
        g.hook(ctx,'pre',env)
        with self.assertRaises(c.Rejected):g.hook(ctx,'pre',env)
        app=self.product(ctx,arm);g.hook(ctx,'post',env);g.attest(ctx,'p0','reported-success',did_not_run=True)
        self.now=self.start+dt.timedelta(minutes=25)
        with self.assertRaises(c.Rejected):g.finalize(ctx,'p0',inspector=lambda _:self.asset(ctx,app))
        self.assertFalse((self.root/'selection/p0.json').exists())
    def test_wrong_original_leaf_never_becomes_new_baseline_or_manual_fallback(self):
        import gui_build as g,prepare
        ctx,arm=self.phase();env=self.environment(ctx,arm);g.hook(ctx,'pre',env);app=self.product(ctx,arm);g.hook(ctx,'post',env);g.attest(ctx,'p0','reported-success',did_not_run=True)
        bad=self.asset(ctx,app);bad['certificateSHA256']='f'*64
        with self.assertRaises(c.Rejected):g.finalize(ctx,'p0',inspector=lambda _:bad)
        with self.assertRaises(c.Rejected):prepare.signed_build(ctx,'p0',executor=lambda *args:None)
        self.assertFalse((self.root/'selection/p0.json').exists());self.assertEqual(c.read(self.root,'reference/original-leaf.json')[0]['certificateSHA256'],self.leaf_sha)
    def test_ambiguous_seed_launch_without_receipt_requires_owned_cleanup(self):
        ctx=self.begin();c.exclusive(self.root,'write-attempts/'+str(uuid.uuid4())+'.json',{'namespace':self.ns,'synthetic':True,'operation':'seed-read-a','state':'launch-may-add'})
        self.assertTrue(c.owned_write_possible(self.root,self.ns,True))
        with self.assertRaises(c.Rejected):proof.stop_bootstrap(ctx)
        self.assertTrue(self.root.exists())

    def test_schemes_provide_one_target_and_explicit_Debug_Rebuilt(self):
        import xml.etree.ElementTree as ET
        source=Path(__file__).resolve().parents[1]
        for name,config in [('DPKContinuityProbe','Debug'),('DPKContinuityProbe-Rebuilt','Rebuilt')]:
            tree=ET.fromstring((source/'DPKContinuityProbe.xcodeproj/xcshareddata/xcschemes'/(name+'.xcscheme')).read_bytes())
            self.assertEqual(tree.find('LaunchAction').get('buildConfiguration'),config)
            entry=tree.findall('.//BuildActionEntry/BuildableReference');self.assertEqual(len(entry),1)
            for tag,mode in [('PreActions','pre'),('PostActions','post')]:
                action=tree.find('BuildAction/'+tag+'/ExecutionAction/ActionContent')
                self.assertIsNotNone(action);self.assertIn('--hook '+mode,action.get('scriptText'))
                self.assertEqual(action.find('EnvironmentBuildable/BuildableReference').get('BlueprintIdentifier'),entry[0].get('BlueprintIdentifier'))
    def prepared_gui(self):
        import gui_build as g
        ctx,arm=self.phase();env=self.environment(ctx,arm);g.hook(ctx,'pre',env);app=self.product(ctx,arm);g.hook(ctx,'post',env);g.attest(ctx,'p0','reported-success',True)
        g.finalize(ctx,'p0',inspector=lambda _:self.asset(ctx,app));proof.inspect_bootstrap(ctx);c.complete_global(ctx)
        return c.Run(self.root,True,self.clock)
    def backend(self):
        owner=self
        class Backend:
            adds=0
            def stage(_,stage,run):
                now=owner.clock().isoformat()
                if stage in ('preflight','p1-setup','rebuild-setup'):
                    verifier=type('Verifier',(),{'run':run,'ensure_exited':lambda _:None,'asset':lambda _,name:proof.frozen_asset(run,name)})()
                    with mock.patch.object(proof,'utc',side_effect=owner.clock):asset,sha=proof.SetupVerifier.inspect_stage(verifier,stage)
                else:asset,sha,proof_name=proof.operation_proof(run,stage,stage=='cleanup')
                value=dict(startedUTC=now,endedUTC=now,completed=True,callAttempted=stage not in ('preflight','p1-setup','rebuild-setup','expired'),OSStatus=None)
                if stage in ('seed','fresh','p1-read','rebuilt-read'):
                    if stage=='seed':_.adds+=1
                    value['fields']={k:True for k in c.FIELDS}
                if stage=='cleanup':value['absent']=True
                if stage=='expired':value.update(launch='rejected',guard='not-observed',availabilityInterrupted=True,callAttempted=False,OSStatus=None)
                return value,sha
            def cleanup(_,run):return False
            def finalize(_,run):return proof.SetupVerifier.finalize(type('Files',(),{'ensure_exited':lambda _:None})(),run)
        return Backend()
    def test_GUI_three_windows_original_leaf_P1_true_rebuild_and_ACK_cleanup(self):
        import gui_build as g
        run=self.prepared_gui();backend=self.backend()
        for stage in ('preflight','seed','fresh'):c.run_main_stage(run,1,stage,backend)
        original=(self.root/'receipts/seed.machine.json').read_bytes()
        self.now=self.start+dt.timedelta(days=7,seconds=1);c.run_main_stage(run,2,'expired',backend)
        arm=g.arm(run,'p1');env=self.environment(run,arm);g.hook(run,'pre',env);app=self.product(run,arm)
        p1bytes=b'synthetic P1 profile';(app/'Contents/embedded.provisionprofile').write_bytes(p1bytes)
        g.hook(run,'post',env);g.attest(run,'p1','reported-success',True)
        asset=self.asset(run,app);asset.update(profileCreationUTC=self.now.isoformat(),profileExpiryUTC=(self.now+dt.timedelta(days=7)).isoformat())
        g.finalize(run,'p1',inspector=lambda _:asset)
        for stage in ('p1-setup','p1-read'):c.run_main_stage(run,2,stage,backend)
        self.now+=dt.timedelta(seconds=1);arm=g.arm(run,'rebuilt');env=self.environment(run,arm);g.hook(run,'pre',env);app=self.product(run,arm,'rebuilt');(app/'Contents/embedded.provisionprofile').write_bytes(p1bytes)
        g.hook(run,'post',env);g.attest(run,'rebuilt','reported-success',True)
        rebuilt=self.asset(run,app);rebuilt.update(buildMarker='rebuilt',profileCreationUTC=asset['profileCreationUTC'],profileExpiryUTC=asset['profileExpiryUTC'])
        g.finalize(run,'rebuilt',inspector=lambda _:rebuilt)
        for stage in ('rebuild-setup','rebuilt-read'):c.run_main_stage(run,3,stage,backend)
        g.record_closed(run,True,True)
        with mock.patch.object(g,'handles_absent',return_value=True):outcome=c.run_main_stage(run,3,'cleanup',backend)
        self.assertTrue(outcome['awaitingSafeEvidenceACK']);self.assertFalse(self.out.exists());self.assertEqual(backend.adds,1)
        self.assertEqual((self.root/'receipts/seed.machine.json').read_bytes(),original)
        candidate=c.file_hash(self.root/'safe-candidates/pre-cleanup.index.json')
        public=b''.join(p.read_bytes() for p in (self.root/'safe-candidates').rglob('*.json'))
        self.assertNotIn(str(self.root).encode(),public);self.assertNotIn(b'keychain-access-groups',public)
        c.exclusive(self.root,'publication-ack.json',dict(kind='safe-candidate-model-ack',namespace=self.ns,globalSHA256=run.global_hash,candidateIndexSHA256=candidate,readabilityAcknowledged=True,safetyAcknowledged=True,recordedUTC=self.clock().isoformat()))
        with mock.patch.object(g,'handles_absent',return_value=True):self.assertTrue(backend.finalize(run))
        self.assertFalse(self.root.exists());self.assertEqual(c.read(self.out,'final.index.json')[0]['files']['pre-cleanup.index.json'],candidate)
    def test_actual_pure_Swift_GUI_chain_matches_Python_and_wrong_reference_rejects(self):
        import subprocess
        run=self.prepared_gui();run.arm_window(1,None)
        source=Path(__file__).resolve().parents[1];binary=Path(self.tmp.name)/'gui-chain'
        # No AppMain/LiveStore/Security are compiled or initialized; this only calls the chain validator.
        subprocess.run(['swiftc','-module-cache-path',str(Path(self.tmp.name)/'swift-cache'),str(source/'Sources/DPKContinuityProbe/ProbeCore.swift'),str(source/'Sources/DPKContinuityProbe/LiveGate.swift'),str(source/'Tests/WindowChainProbe.swift'),'-o',str(binary)],check=True,capture_output=True,timeout=120)
        def invoke():return subprocess.run([str(binary),str(self.root),'1',str(self.now.timestamp())],capture_output=True,timeout=10).returncode
        self.assertEqual(invoke(),0)
        path=self.root/'reference/original.cer';raw=path.read_bytes();path.write_bytes(b'wrong public certificate')
        self.assertEqual(invoke(),2);path.write_bytes(raw)
        self.assertEqual(invoke(),0)
    def test_private_source_raw_safety_no_handles_and_no_live_inspector_in_prep(self):
        import gui_build as g
        ctx,arm=self.phase();env=self.environment(ctx,arm)
        path=self.root/'configured/Sources/DPKContinuityProbe/AppMain.swift';original=path.read_bytes();path.write_bytes(original+b'\n// changed')
        with self.assertRaises(c.Rejected):g.hook(ctx,'pre',env)
        path.write_bytes(original)
        with mock.patch.object(g.subprocess,'run') as command,self.assertRaises(c.Rejected):g.capture_command(ctx,['private raw subject must never run'])
        command.assert_not_called()
        g.record_closed(ctx,True,True)
        with self.assertRaises(c.Rejected):g.closed_for_cleanup(ctx,handles=lambda _:False)
        g.closed_for_cleanup(ctx,handles=lambda _:True)

    def test_one_begin_sync_is_required_before_anchor(self):
        with self.assertRaises((c.Rejected,OSError)):c.begin_anchor(self.root,self.ns,self.source,self.out,True,self.clock)
        self.assertFalse((self.root/'anchor.json').exists())
        ctx=self.begin();self.assertIn('guiBeginSyncSHA256',ctx.manifest)
    def test_ambiguous_seed_without_receipt_still_has_cleanup_only_authority(self):
        run=self.prepared_gui();backend=self.backend();c.run_main_stage(run,1,'preflight',backend)
        c.exclusive(self.root,'write-attempts/'+str(uuid.uuid4())+'.json',{'namespace':self.ns,'synthetic':True,'operation':'seed-read-a','state':'launch-may-add'})
        self.assertFalse((self.root/'receipts/seed.machine.json').exists())
        grant,ready=c.require_recovery(run,str(uuid.uuid4()));self.assertEqual(grant,run.manifest['grantSHA256']['recovery']);self.assertEqual(len(ready),64)
    def test_P1_old_profile_cannot_be_retried_or_reseeded(self):
        import gui_build as g
        run=self.prepared_gui();backend=self.backend()
        for stage in ('preflight','seed','fresh'):c.run_main_stage(run,1,stage,backend)
        self.now=self.start+dt.timedelta(days=7,seconds=1);c.run_main_stage(run,2,'expired',backend)
        arm=g.arm(run,'p1');env=self.environment(run,arm);g.hook(run,'pre',env);app=self.product(run,arm);g.hook(run,'post',env);g.attest(run,'p1','reported-success',True)
        with self.assertRaises(c.Rejected):g.finalize(run,'p1',inspector=lambda _:self.asset(run,app))
        with self.assertRaises(c.Rejected):g.arm(run,'p1')
        self.assertFalse((self.root/'selection/p1.json').exists());self.assertEqual(backend.adds,1)

    def test_missing_hook_failure_is_only_control_and_safe_output_cannot_include_raw(self):
        import gui_build as g
        ctx,arm=self.phase();env=self.environment(ctx,arm);g.hook(ctx,'pre',env)
        g.attest(ctx,'p0','reported-failure',True)
        views=g.public_views(ctx);human=views['gui/p0/human-build.public.json']
        self.assertEqual(human['status'],'reported-failure');self.assertIsNone(human['postSHA256'])
        safe=g.safe_summary({'certificateSHA256':'a'*64,'TeamName':'synthetic private name','rawError':'synthetic secret'})
        self.assertNotIn('TeamName',safe);self.assertNotIn('rawError',safe);self.assertEqual(safe['UX'],'unknown')
        with self.assertRaises(c.Rejected):g.safe_summary({'profileExpiryUTC':'synthetic raw exception'})
        g.record_closed(ctx,True,True);pending=proof.stop_bootstrap(ctx)
        self.assertFalse(pending['cleanupComplete']);self.assertTrue(self.root.exists());self.assertFalse(self.out.exists())
        candidate=pending['candidateIndexSHA256']
        c.exclusive(self.root,'publication-ack.json',dict(kind='safe-candidate-model-ack',namespace=self.ns,anchorSHA256=ctx.anchor_hash,candidateIndexSHA256=candidate,readabilityAcknowledged=True,safetyAcknowledged=True,recordedUTC=self.clock().isoformat()))
        with mock.patch.object(g,'handles_absent',return_value=True):self.assertTrue(proof.stop_bootstrap(ctx)['cleanupComplete'])
        self.assertFalse(self.root.exists())

    def test_GUI_RF01_actual_CLI_unexpected_exception_is_closed_and_saved_privately(self):
        import contextlib,io,subprocess
        run=self.prepared_gui();original=c.Run;sentinel='SYNTHETIC_PRIVATE_RAW_SENTINEL'
        error=subprocess.CalledProcessError(1,['/private/synthetic/module.py',sentinel],stderr=b'private raw')
        backend=type('Backend',(),{'stage':lambda *args:(_ for _ in ()).throw(error),'cleanup':lambda *args:False})()
        out=io.StringIO();err=io.StringIO()
        with mock.patch.object(c,'Run',side_effect=lambda root:original(root,True,self.clock)),mock.patch.object(proof,'ManualStages',return_value=backend),mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--window','1','--stage','preflight']),contextlib.redirect_stdout(out),contextlib.redirect_stderr(err):
            code=c.cli_entrypoint()
        self.assertEqual(code,2);self.assertEqual(err.getvalue(),'')
        for raw in (sentinel,'Traceback','/private/synthetic/module.py',str(self.root)):self.assertNotIn(raw,out.getvalue()+err.getvalue())
        summary=json.loads(out.getvalue());self.assertTrue(summary['rawExceptionSaved']);self.assertEqual(summary['itemState'],'not-inferred')
        saved=list((self.root/'raw').glob('cli-exception-*.json'));self.assertEqual(len(saved),1)
        self.assertIn(sentinel,saved[0].read_text())
        c.exclusive(self.root,'write-attempts/'+str(uuid.uuid4())+'.json',dict(namespace=self.ns,synthetic=True,operation='seed-read-a',state='launch-may-add'))
        original_bootstrap=c.Bootstrap;out=io.StringIO()
        with mock.patch.object(c,'Bootstrap',side_effect=lambda root,clock:original_bootstrap(root,True,self.clock)),mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--stop-setup']),contextlib.redirect_stdout(out):c.cli_entrypoint()
        stopped=list((self.root/'bootstrap').glob('stopped-*.machine.json'));self.assertTrue(stopped)
        self.assertTrue(all(json.loads(p.read_bytes())['noSecItemWriteAttempted'] is False for p in stopped))
        self.assertEqual(json.loads(out.getvalue())['itemState'],'not-inferred')
    def test_GUI_RF01_invalid_expired_or_symlink_root_is_safe_refusal_and_help_survives(self):
        import contextlib,io
        ctx=self.begin();outside=self.root.parent/'outside';outside.mkdir();(self.root/'raw').symlink_to(outside,target_is_directory=True)
        self.assertFalse(c.persist_cli_exception(ctx,RuntimeError('SYNTHETIC_PRIVATE_RAW')));self.assertEqual(list(outside.iterdir()),[])
        (self.root/'raw').unlink();self.now=self.start+dt.timedelta(minutes=30)
        self.assertFalse(c.persist_cli_exception(ctx,RuntimeError('SYNTHETIC_PRIVATE_RAW')));self.assertFalse((self.root/'raw').exists())
        out=io.StringIO();err=io.StringIO()
        with mock.patch.object(sys,'argv',['continuity.py','--unknown','SYNTHETIC_PRIVATE_RAW']),contextlib.redirect_stdout(out),contextlib.redirect_stderr(err):code=c.cli_entrypoint()
        self.assertEqual(code,2);self.assertNotIn('SYNTHETIC_PRIVATE_RAW',out.getvalue()+err.getvalue());self.assertEqual(err.getvalue(),'')
        self.assertEqual(json.loads(out.getvalue())['classification'],'safeRefusal')
        out=io.StringIO()
        with mock.patch.object(sys,'argv',['continuity.py','--help']),contextlib.redirect_stdout(out),self.assertRaises(SystemExit) as help_result:c.cli_entrypoint()
        self.assertEqual(help_result.exception.code,0);self.assertIn('usage:',out.getvalue())
    def test_GUI_RF02_timeout_partial_bytes_and_text_are_preserved_without_public_leak(self):
        import gui_build as g,subprocess
        ctx=self.begin()
        for stdout,stderr,kind in [(b'\x00SYNTHETIC_PARTIAL\xff',b'\xfeprivate stderr','bytes'),('局部文字SYNTHETIC_PARTIAL','文字stderr','text')]:
            with self.subTest(kind=kind):
                before=set((self.root/'raw').glob('*.partial-streams.json')) if (self.root/'raw').exists() else set()
                def timed_out(*args,**kwargs):raise subprocess.TimeoutExpired('synthetic selected verifier',1,output=stdout,stderr=stderr)
                with self.assertRaises(c.Rejected):g.capture_command(ctx,['synthetic-only'],runner=timed_out)
                added=set((self.root/'raw').glob('*.partial-streams.json'))-before;self.assertEqual(len(added),1)
                metadata=json.loads(next(iter(added)).read_bytes())
                for name,value in [('stdout',stdout),('stderr',stderr)]:
                    stream=metadata['streams'][name];actual=(self.root/stream['relativePath']).read_bytes()
                    self.assertEqual(actual,value if isinstance(value,bytes) else value.encode('utf-8',errors='surrogatepass'))
                    self.assertEqual(stream['originalType'],kind);self.assertEqual(stream['originalProcessBytesAvailable'],isinstance(value,bytes))
                    self.assertEqual(stream['encoding'],None if isinstance(value,bytes) else 'utf-8-surrogatepass')
                self.assertTrue(metadata['partialOutputOnly'])
        self.assertTrue(self.root.exists());self.assertEqual(len(list((self.root/'raw').glob('*.partial-streams.json'))),2)

if __name__=='__main__':unittest.main()
