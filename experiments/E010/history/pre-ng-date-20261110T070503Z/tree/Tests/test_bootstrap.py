import copy
import datetime as dt
import io
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest
from unittest import mock
import uuid
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import continuity as c
import proof

class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='E010-bootstrap-pure-');self.addCleanup(self.temp.cleanup)
        self.ns=str(uuid.uuid4());self.root=Path(self.temp.name).resolve()/('rivet-E010-'+self.ns);self.root.mkdir(mode=0o700)
        self.now=dt.datetime(2030,1,1,tzinfo=c.UTC);self.start=self.now;self.clock=lambda:self.now;self.source=proof.source_hashes();self.out=Path(self.temp.name).resolve()/'public'
        self.grants={}
        for kind in ('assets','retention','recovery'):
            self.grants[kind]=c.exclusive(self.root,'grants/'+kind+'.json',{'kind':'human-grant','scope':kind,'namespace':self.ns,'synthetic':True,'approved':True,'statement':'synthetic grant','retentionRoot':str(self.root),'validUntilUTC':(self.now+dt.timedelta(days=11)).isoformat(),'procedure':'synthetic same-group recovery','residualItemAccepted':True})
        c.exclusive(self.root,'bootstrap/begin.ready.json',{'namespace':self.ns,'synthetic':True,'stage':'begin-anchor','humanReady':True,'humanReadyStatement':'synthetic begin ready','sourceSHA256':self.source,'grantSHA256':self.grants,'retentionRoot':str(self.root),'recordedUTC':self.now.isoformat()})
    def begin(self):
        c.begin_anchor(self.root,self.ns,self.source,self.out,True,self.clock);return c.Bootstrap(self.root,True,self.clock)
    def human(self,relative,machine_relative):
        machine,sha=c.read(self.root,machine_relative)
        c.exclusive(self.root,relative,{'namespace':self.ns,'synthetic':True,'stage':machine['stage'],'machineReceiptSHA256':sha,'wholeStageObserved':True,'phaseIdentified':True,'promptCount':0,'actions':[],'purposes':[],'recordedUTC':self.now.isoformat()})
    def setup_ready(self,ctx):
        self.human('bootstrap/begin.human.json','bootstrap/begin.machine.json');self.now+=dt.timedelta(microseconds=1)
        c.exclusive(self.root,'bootstrap/setup.ready.json',{'namespace':self.ns,'synthetic':True,'stage':'setup-only','anchorSHA256':ctx.anchor_hash,'windowSHA256':c.file_hash(self.root/'windows/1.json'),'grantSHA256':self.grants,'sourceSHA256':self.source,'previousReceiptSHA256':c.file_hash(self.root/'bootstrap/begin.machine.json'),'previousHumanSHA256':c.file_hash(self.root/'bootstrap/begin.human.json'),'humanReady':True,'humanReadyStatement':'synthetic setup ready','recordedUTC':self.now.isoformat()})
    def asset(self,ctx):
        app=self.root/'selected.app';app.mkdir();(app/'fake').write_text('synthetic bytes; never executed')
        c.exclusive(self.root,'selection/p0.json',{'appPath':str(app),'sourceRoot':str(self.root),'humanFreePersonalTeamStatement':'synthetic','humanSourceAndMarkerStatement':'synthetic'})
        group='SYNTHETIC.'+ctx.manifest['bundleIdentifier']
        return {'synthetic':True,'hostBindingSHA256':ctx.manifest['hostBindingSHA256'],'appPath':str(app),'appSHA256':proof.app_hash(app),'executableSHA256':'a'*64,'profileSHA256':'b'*64,'certificateSHA256':'c'*64,'DRSHA256':'d'*64,'bundleIdentifier':ctx.manifest['bundleIdentifier'],'buildMarker':'initial','sourceSHA256':self.source,'entitlements':{'com.apple.application-identifier':group,'keychain-access-groups':[group]},'profile':{'ApplicationIdentifierPrefix':['SYNTHETIC'],'ProvisionedDevices':['synthetic-device'],'Platform':['OSX'],'Entitlements':{'com.apple.application-identifier':'SYNTHETIC.*','keychain-access-groups':['SYNTHETIC.*']}},'device':'synthetic-device','profileCreationUTC':(self.start-dt.timedelta(days=1)).isoformat(),'profileExpiryUTC':(self.start+dt.timedelta(days=7)).isoformat(),'certificateNotBeforeUTC':(self.start-dt.timedelta(days=1)).isoformat(),'certificateNotAfterUTC':(self.start+dt.timedelta(days=20)).isoformat(),'profileSignatureVerified':True,'certificateInProfile':True,'appleDevelopmentChainVerified':True}
    def prepared(self):
        ctx=self.begin();self.setup_ready(ctx);asset=self.asset(ctx)
        with mock.patch.object(proof,'inspect_selected',return_value=asset):proof.inspect_bootstrap(ctx)
        return ctx
    def test_anchor_has_no_guessed_dates_and_original_time_survives_setup(self):
        ctx=self.begin();self.assertNotIn('p0ExpiryUTC',ctx.manifest);self.assertNotIn('certificateNotAfterUTC',ctx.manifest)
        original={p:c.file_hash(self.root/p) for p in ('anchor.json','windows/1.json')};self.now+=dt.timedelta(minutes=10);self.setup_ready(ctx);asset=self.asset(ctx)
        with mock.patch.object(proof,'inspect_selected',return_value=asset),mock.patch.object(proof,'LiveBackend') as executor,mock.patch.object(proof.subprocess,'Popen') as launch:
            proof.inspect_bootstrap(ctx);self.now+=dt.timedelta(minutes=2);manifest=c.complete_global(ctx);executor.assert_not_called();launch.assert_not_called()
        self.assertEqual(c.stamp(manifest['startUTC']),self.start);self.assertEqual(c.stamp(manifest['globalDeadlineUTC']),self.start+dt.timedelta(days=10));self.assertEqual(c.stamp(c.read(self.root,'windows/1.json')[0]['cutoffUTC']),self.start+dt.timedelta(minutes=25))
        for p,sha in original.items():self.assertEqual(c.file_hash(self.root/p),sha)
        run=c.Run(self.root,True,self.clock)
        with self.assertRaises((c.Rejected,OSError)):run.arm_window(1,'ready without independent seed-ready')
    def test_missing_setup_ready_grant_binding_source_or_future_ready_is_zero_inspection(self):
        ctx=self.begin()
        with mock.patch.object(proof,'inspect_selected') as inspect,mock.patch.object(proof,'LiveBackend') as executor,mock.patch.object(proof,'command') as command:
            with self.assertRaises((c.Rejected,OSError)):proof.inspect_bootstrap(ctx)
            self.setup_ready(ctx);path=self.root/'bootstrap/setup.ready.json';original=path.read_bytes();gate=json.loads(original);gate['recordedUTC']=(self.now+dt.timedelta(seconds=1)).isoformat();path.write_bytes(c.canonical(gate))
            with self.assertRaises(c.Rejected):proof.inspect_bootstrap(ctx)
            path.write_bytes(original)
            with mock.patch.object(c,'local_identity',return_value={'mac':'other','uid':1}),self.assertRaises(c.Rejected):proof.inspect_bootstrap(ctx)
            with mock.patch.object(proof,'source_hashes',return_value={}),self.assertRaises(c.Rejected):proof.inspect_bootstrap(ctx)
            grant=self.root/'grants/assets.json';raw=grant.read_bytes();grant.unlink()
            with self.assertRaises((c.Rejected,OSError)):proof.inspect_bootstrap(ctx)
            grant.write_bytes(raw);inspect.assert_not_called();executor.assert_not_called();command.assert_not_called()
    def test_actual_dates_budget_cutoff_and_tampered_proof_cannot_complete(self):
        ctx=self.begin();self.setup_ready(ctx);asset=self.asset(ctx);asset['profileExpiryUTC']=(self.start+dt.timedelta(days=11)).isoformat()
        with mock.patch.object(proof,'inspect_selected',return_value=asset),self.assertRaises(c.Rejected):proof.inspect_bootstrap(ctx)
        self.assertFalse((self.root/'global.json').exists());self.assertFalse((self.root/'bootstrap/actual-proof.json').exists())
        asset['profileExpiryUTC']=(self.start+dt.timedelta(days=7)).isoformat();asset['certificateNotAfterUTC']=(self.start+dt.timedelta(days=10)).isoformat()
        with mock.patch.object(proof,'inspect_selected',return_value=asset),self.assertRaises(c.Rejected):proof.inspect_bootstrap(ctx)
        asset['certificateNotAfterUTC']=(self.start+dt.timedelta(days=20)).isoformat()
        with mock.patch.object(proof,'inspect_selected',return_value=asset):proof.inspect_bootstrap(ctx)
        self.now=self.start+dt.timedelta(minutes=25)
        with self.assertRaises(c.Rejected):c.complete_global(ctx)
        self.assertFalse((self.root/'global.json').exists())
    def test_partial_complete_crash_resume_is_same_bytes_and_no_early_run(self):
        ctx=self.prepared();proof_path=self.root/'bootstrap/actual-proof.json';proof_raw=proof_path.read_bytes();bad=json.loads(proof_raw);bad['certificateSHA256']='f'*64;proof_path.write_bytes(c.canonical(bad))
        with self.assertRaises(c.Rejected):c.complete_global(ctx)
        self.assertFalse((self.root/'global.json').exists());proof_path.write_bytes(proof_raw)
        original=c.matching_write
        def fail_binding(root,name,value):
            if name=='global.binding.json':raise OSError('synthetic crash')
            return original(root,name,value)
        with mock.patch.object(c,'matching_write',side_effect=fail_binding),self.assertRaises(OSError):c.complete_global(ctx)
        before=(self.root/'global.json').read_bytes()
        with self.assertRaises((c.Rejected,OSError)):c.Run(self.root,True,self.clock)
        self.now+=dt.timedelta(minutes=1);c.complete_global(c.Bootstrap(self.root,True,self.clock));self.assertEqual((self.root/'global.json').read_bytes(),before)
        with self.assertRaises(c.Rejected):c.complete_global(ctx)
        self.assertEqual((self.root/'global.json').read_bytes(),before)
    def test_anchor_tamper_and_duplicate_begin_never_reset_clock(self):
        ctx=self.begin();raw=(self.root/'anchor.json').read_bytes()
        self.now+=dt.timedelta(minutes=1)
        with self.assertRaises(c.Rejected):c.begin_anchor(self.root,self.ns,self.source,self.out,True,self.clock)
        self.assertEqual((self.root/'anchor.json').read_bytes(),raw)
        value=json.loads(raw);value['startUTC']=self.now.isoformat();(self.root/'anchor.json').write_bytes(c.canonical(value))
        with self.assertRaises(c.Rejected):c.Bootstrap(self.root,True,self.clock)
    def test_actual_cli_legacy_begin_is_blocked_and_bootstrap_modes_never_make_executor(self):
        with mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--begin']),mock.patch.object(proof,'command') as command:
            with self.assertRaises(c.Rejected):c.main()
            command.assert_not_called()
        original_begin=c.begin_anchor;original_context=c.Bootstrap
        with mock.patch.object(c,'begin_anchor',side_effect=lambda root,ns,source,out,clock:original_begin(root,ns,source,out,True,self.clock)),mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--begin-anchor','--public-out',str(self.out)]),mock.patch('sys.stdout',new_callable=io.StringIO):self.assertEqual(c.main(),0)
        ctx=original_context(self.root,True,self.clock);self.setup_ready(ctx);asset=self.asset(ctx)
        with mock.patch.object(c,'Bootstrap',side_effect=lambda root,clock:original_context(root,True,self.clock)),mock.patch.object(proof,'inspect_selected',return_value=asset),mock.patch.object(proof,'LiveBackend') as executor,mock.patch.object(proof.subprocess,'Popen') as launch,mock.patch('sys.stdout',new_callable=io.StringIO):
            for mode in ('--setup-only','--complete-global'):
                with mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),mode]):self.assertEqual(c.main(),0)
            executor.assert_not_called();launch.assert_not_called()

    def test_actual_swift_w1_helper_and_later_window_regression(self):
        ctx=self.prepared();c.complete_global(ctx);run=c.Run(self.root,True,self.clock)
        self.human('bootstrap/setup.human.json','bootstrap/setup.machine.json');self.now+=dt.timedelta(seconds=1)
        c.exclusive(self.root,'bootstrap/seed.ready.json',{'namespace':self.ns,'synthetic':True,'stage':'seed-ready','globalSHA256':run.global_hash,'anchorSHA256':ctx.anchor_hash,'windowSHA256':run.manifest['window1SHA256'],'previousReceiptSHA256':c.file_hash(self.root/'bootstrap/setup.machine.json'),'previousHumanSHA256':c.file_hash(self.root/'bootstrap/setup.human.json'),'humanReady':True,'humanReadyStatement':'synthetic independent seed ready','recordedUTC':self.now.isoformat()})
        exp=Path(__file__).resolve().parents[1];producer=Path(self.temp.name)/'window-chain-probe'
        subprocess.run(['swiftc','-module-cache-path',str(Path(self.temp.name)/'module-cache'),str(exp/'Sources/DPKContinuityProbe/ProbeCore.swift'),str(exp/'Sources/DPKContinuityProbe/LiveGate.swift'),str(exp/'Tests/WindowChainProbe.swift'),'-o',str(producer)],check=True,capture_output=True,timeout=120)
        def probe(number,accepted):
            result=subprocess.run([str(producer),str(self.root),str(number),str(self.now.timestamp())],capture_output=True,text=True,timeout=10)
            self.assertEqual(result.returncode,0 if accepted else 2,result.stdout+result.stderr)
        probe(1,True)
        for relative in ('anchor.json','anchor.binding.json','bootstrap/complete.json','bootstrap/seed.ready.json','bootstrap/actual-proof.json'):
            path=self.root/relative;raw=path.read_bytes();path.unlink();probe(1,False);path.write_bytes(raw)
        path=self.root/'anchor.json';raw=path.read_bytes();value=json.loads(raw);value['service']='tamper';path.write_bytes(c.canonical(value));probe(1,False);path.write_bytes(raw)
        path=self.root/'global.json';raw=path.read_bytes();path.write_bytes(c.canonical(ctx.manifest));probe(1,False);path.write_bytes(raw)
        for number in (2,3):
            window={'number':number,'globalSHA256':run.global_hash};c.exclusive(self.root,'windows/'+str(number)+'.json',window);c.exclusive(self.root,'windows/'+str(number)+'.binding.json',{'windowSHA256':c.file_hash(self.root/('windows/'+str(number)+'.json'))});probe(number,True)
            # Self-consistent legacy IDs must still be rejected; no App/Security is linked into this helper.
            global_path=self.root/'global.json';original_global=global_path.read_bytes()
            for key,old in [('kind','E008-global'),('service','local.rivet.experiments.E008.'+self.ns),('bundleIdentifier','local.rivet.experiments.E008.'+self.ns)]:
                bad=json.loads(original_global);bad[key]=old;global_path.write_bytes(c.canonical(bad))
                legacy_window=dict(window,globalSHA256=c.file_hash(global_path));(self.root/('windows/'+str(number)+'.json')).write_bytes(c.canonical(legacy_window));(self.root/('windows/'+str(number)+'.binding.json')).write_bytes(c.canonical({'windowSHA256':c.file_hash(self.root/('windows/'+str(number)+'.json'))}));probe(number,False)
            global_path.write_bytes(original_global)
            old_root=self.root;legacy_root=self.root.parent/('rivet-E008-'+self.ns);old_root.rename(legacy_root);self.root=legacy_root
            try:probe(number,False)
            finally:legacy_root.rename(old_root);self.root=old_root
            window.pop('globalSHA256');window['anchorSHA256']=ctx.anchor_hash;(self.root/('windows/'+str(number)+'.json')).write_bytes(c.canonical(window));(self.root/('windows/'+str(number)+'.binding.json')).write_bytes(c.canonical({'windowSHA256':c.file_hash(self.root/('windows/'+str(number)+'.json'))}));probe(number,False)

    def seed_ready(self,ctx,run):
        self.human('bootstrap/setup.human.json','bootstrap/setup.machine.json');self.now+=dt.timedelta(seconds=1)
        c.exclusive(self.root,'bootstrap/seed.ready.json',{'namespace':self.ns,'synthetic':True,'stage':'seed-ready','globalSHA256':run.global_hash,'anchorSHA256':ctx.anchor_hash,'windowSHA256':run.manifest['window1SHA256'],'previousReceiptSHA256':c.file_hash(self.root/'bootstrap/setup.machine.json'),'previousHumanSHA256':c.file_hash(self.root/'bootstrap/setup.human.json'),'humanReady':True,'humanReadyStatement':'synthetic independent seed ready','recordedUTC':self.now.isoformat()})
    def test_bootstrap_archive_survives_private_cleanup_and_later_resume(self):
        ctx=self.prepared();c.complete_global(ctx);run=c.Run(self.root,True,self.clock);self.seed_ready(ctx,run)
        # Baseline phase uses immutable W1, and only a matching independent seed-ready.
        run.arm_window(1,'synthetic baseline ready');self.assertNotIn('globalSHA256',c.read(self.root,'windows/1.json')[0])
        with self.assertRaises(c.Rejected):run.arm_window(1,'no duplicate baseline entry')
        self.now=self.start+dt.timedelta(days=7,seconds=1);c.Run(self.root,True,self.clock) # P0 snapshot validation does not demand P0 still valid after natural expiry.
        fake=type('Files',(),{'ensure_exited':lambda self:None})()
        proof.SetupVerifier.finalize(fake,run)
        index=json.loads((self.out/'final.index.json').read_text());self.assertFalse(self.root.exists())
        for relative,sha in index['files'].items():self.assertEqual(c.file_hash(self.out/relative),sha)
        global_view=json.loads((self.out/'global.public.json').read_text());anchor=json.loads((self.out/'anchor.public.json').read_text());window=json.loads((self.out/'windows/1.public.json').read_text())
        self.assertEqual(global_view['anchorSHA256'],anchor['privateReceiptSHA256']);self.assertEqual(global_view['window1SHA256'],window['privateWindowSHA256']);self.assertEqual(global_view['startUTC'],anchor['startUTC'])
        setup_ready=json.loads((self.out/'bootstrap/setup.ready.public.json').read_text());human=json.loads((self.out/'bootstrap/begin.human.json').read_text());self.assertGreater(c.stamp(setup_ready['recordedUTC']),c.stamp(human['recordedUTC']))
        public=''.join(p.read_text() for p in self.out.rglob('*.json'));self.assertNotIn('synthetic independent seed ready',public);self.assertNotIn('synthetic-mac',public);self.assertNotIn(str(self.root),public)
    def test_setup_failure_actual_cli_receipt_and_controlled_stop_zero_item(self):
        ctx=self.begin();self.setup_ready(ctx);self.asset(ctx);original_context=c.Bootstrap
        with mock.patch.object(c,'Bootstrap',side_effect=lambda root,clock:original_context(root,True,self.clock)),mock.patch.object(proof,'inspect_selected',side_effect=c.Rejected('syntheticAssetFailure')),mock.patch.object(proof,'LiveBackend') as executor,mock.patch.object(proof.subprocess,'Popen') as launch,mock.patch.object(c,'utc',self.clock):
            with mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--setup-only']),self.assertRaises(c.Rejected):c.main()
            stop=json.loads(next((self.root/'bootstrap').glob('stopped-*.machine.json')).read_text());self.assertTrue(stop['noSecItemWriteAttempted']);self.assertFalse(stop['cleanupComplete'])
            with mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--stop-setup']),mock.patch('sys.stdout',new_callable=io.StringIO):self.assertEqual(c.main(),0)
            executor.assert_not_called();launch.assert_not_called()
        self.assertFalse(self.root.exists());archive=next(self.out.glob('setup-stop-*'));index=json.loads((archive/'index.json').read_text());self.assertTrue(index['cleanupComplete'])
        for relative,sha in index['files'].items():self.assertEqual(c.file_hash(archive/relative),sha)
        self.assertTrue(json.loads((archive/'cleanup.machine.json').read_text())['appleAssetsRetained'])

    def test_controlled_setup_cleanup_failure_records_residual_and_cli_nonzero(self):
        ctx=self.begin();original_context=c.Bootstrap
        with mock.patch.object(c,'Bootstrap',side_effect=lambda root,clock:original_context(root,True,self.clock)),mock.patch.object(proof.shutil,'rmtree',side_effect=OSError('synthetic removal unavailable')),mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(self.root),'--stop-setup']),mock.patch('sys.stdout',new_callable=io.StringIO):self.assertEqual(c.main(),2)
        self.assertTrue(self.root.exists());archive=next(self.out.glob('setup-stop-*'));cleanup=json.loads((archive/'cleanup.machine.json').read_text());self.assertFalse(cleanup['cleanupComplete']);self.assertTrue(cleanup['recoveryRequired']);self.assertTrue(cleanup['noSecItemWriteAttempted'])

    def test_actual_stop_driver_pre_export_and_completion_publication_faults(self):
        for fault in ('anchor.public.json','pre-cleanup.index.json','cleanup.machine.json','index.json'):
            with self.subTest(fault=fault):
                fixture=BootstrapTests();fixture.setUp()
                try:
                    fixture.begin();anchor_raw=(fixture.root/'anchor.json').read_bytes();original_context=c.Bootstrap;original_write=proof.exclusive;original_remove=proof.shutil.rmtree
                    def fail_selected(root,relative,value):
                        if relative==fault:raise OSError('synthetic selected publication fault')
                        return original_write(root,relative,value)
                    with mock.patch.object(c,'Bootstrap',side_effect=lambda root,clock:original_context(root,True,fixture.clock)),mock.patch.object(proof,'exclusive',side_effect=fail_selected),mock.patch.object(proof.shutil,'rmtree',wraps=original_remove) as remove,mock.patch.object(proof,'LiveBackend') as executor,mock.patch.object(proof,'command') as command,mock.patch.object(proof.subprocess,'Popen') as launch,mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(fixture.root),'--stop-setup']),mock.patch('sys.stdout',new_callable=io.StringIO):
                        with self.assertRaises(OSError):c.main()
                        executor.assert_not_called();command.assert_not_called();launch.assert_not_called()
                        archive=next(fixture.out.glob('setup-stop-*'))
                        if fault in ('anchor.public.json','pre-cleanup.index.json'):
                            self.assertTrue(fixture.root.exists());self.assertEqual((fixture.root/'anchor.json').read_bytes(),anchor_raw);remove.assert_not_called()
                        else:
                            self.assertFalse(fixture.root.exists());self.assertTrue((archive/'pre-cleanup.index.json').exists())
                            index=json.loads((archive/'pre-cleanup.index.json').read_text())
                            for relative,sha in index['files'].items():self.assertEqual(c.file_hash(archive/relative),sha)
                            failure=json.loads((archive/'completion-publication-failed.machine.json').read_text());self.assertTrue(failure['privateRootAbsent']);self.assertFalse(failure['privateMaterialRetained']);self.assertFalse(failure['evidencePublicationComplete']);self.assertFalse(failure['cleanupComplete'])
                finally:fixture.doCleanups()
