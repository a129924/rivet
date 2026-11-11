import copy
import datetime as dt
import json
from pathlib import Path
import unittest
from unittest import mock
import uuid
from test_continuity import Fixture, Backend
import continuity as c
import proof

class ReviewFixTests(Fixture):
    def preflight(self):
        self.run.arm_window(1,'synthetic window ready')
        self.run.require_ready('preflight',self.ready('preflight'))
        value,sha=Backend(self).stage('preflight',self.run)
        self.run.record('preflight',1,value,sha)
    def test_ready_must_follow_human_report_and_human_cannot_be_future(self):
        self.preflight(); self.clock.now+=dt.timedelta(seconds=5); human=self.human('preflight')
        gate=self.ready('seed'); gate['recordedUTC']=(self.clock()-dt.timedelta(seconds=1)).isoformat()
        with self.assertRaises(c.Rejected): self.run.require_ready('seed',gate)
        path=self.root/'human/preflight.json'; human['recordedUTC']=(self.clock()+dt.timedelta(seconds=5)).isoformat();path.write_bytes(c.canonical(human))
        with self.assertRaises(c.Rejected): self.run.require_ready('seed',self.ready('seed'))
        human['recordedUTC']=self.clock().isoformat();path.write_bytes(c.canonical(human));self.clock.now+=dt.timedelta(seconds=1)
        self.run.require_ready('seed',self.ready('seed'))
    def test_mac_user_binding_missing_or_changed_is_zero_command(self):
        with mock.patch.object(proof,'command') as command,mock.patch.object(proof.subprocess,'Popen') as launch:
            for identity in ({'mac':'other-mac','uid':1},{'mac':'synthetic-mac','uid':999}):
                with self.subTest(identity=identity),mock.patch.object(c,'local_identity',return_value=identity),self.assertRaises(c.Rejected): c.Run(self.root,True,self.clock)
            manifest=copy.deepcopy(self.manifest);manifest.pop('hostBinding');self.assertRaises(c.Rejected,c.authorize,self.root,manifest,self.clock(),True)
            command.assert_not_called();launch.assert_not_called()
    def test_profile_same_certificate_on_other_device_is_rejected(self):
        self.clock.now+=dt.timedelta(days=7,seconds=1);p0=self.asset();p1=self.asset('p1');p1['device']='other-device';p1['profile']['ProvisionedDevices']=['other-device']
        with self.assertRaises(c.Rejected):proof.validate_asset(p1,self.manifest,self.clock(),p0,'p1')
    def failed_w2(self):
        self.baseline();self.clock.now=self.start+dt.timedelta(days=7,seconds=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(2,'W2 ready')
        with self.assertRaises(c.Rejected):c.run_window(self.run,2,Backend(self,fail='p1-setup',clean=False),self.ready)
    def recovery_grant(self,attempt):
        grant={'kind':'human-grant','scope':'cleanup-only','namespace':self.ns,'synthetic':True,'approved':True,'assetInspectionApproved':True,'statement':'private cleanup authorization','globalSHA256':self.run.global_hash,'recordedUTC':self.clock().isoformat(),'validUntilUTC':(self.clock()+dt.timedelta(minutes=30)).isoformat()}
        sha=c.exclusive(self.root,'recovery-attempts/'+attempt+'/grant.json',grant);self.clock.now+=dt.timedelta(microseconds=1)
        c.exclusive(self.root,'recovery-attempts/'+attempt+'/ready.json',{'namespace':self.ns,'synthetic':True,'attempt':attempt,'globalSHA256':self.run.global_hash,'grantSHA256':sha,'humanReady':True,'humanReadyStatement':'private recovery ready','recordedUTC':self.clock().isoformat()})
    def test_cleanup_only_after_failed_w2_preserves_clock_and_never_reseeds(self):
        self.failed_w2();attempt=str(uuid.uuid4());frozen={p:c.file_hash(self.root/p) for p in ('global.json','windows/1.json','windows/2.json','receipts/seed.machine.json','receipts/expired.machine.json')}
        driver=proof.ManualStages(self.run);driver.recover=mock.Mock(wraps=driver.recover);driver.finalize=mock.Mock(return_value=True)
        with self.assertRaises((c.Rejected,OSError)):c.run_cleanup_only(self.run,attempt,driver)
        driver.recover.assert_not_called();self.recovery_grant(attempt)
        # Real selected-material/freeze/control path; only external verifier and App executor are mocked.
        selected=self.root/'selected-recovery.app';selected.mkdir();(selected/'fixture').write_text('synthetic unsigned fixture, never launched')
        asset=self.asset('p1');asset['appPath']=str(selected);asset['appSHA256']=proof.app_hash(selected)
        c.exclusive(self.root,'recovery-attempts/'+attempt+'/selection.json',{'appPath':str(selected),'humanFreePersonalTeamStatement':'synthetic selection','humanSourceAndMarkerStatement':'synthetic selection'})
        verifier=object.__new__(proof.SetupVerifier);verifier.run=self.run;verifier.ensure_exited=mock.Mock()
        original_frozen=proof.frozen_asset
        def frozen_loader(run,name): return (self.asset(),'a'*64) if name=='p0' else original_frozen(run,name)
        executor=mock.Mock();executor.launch.return_value={'completed':True,'callAttempted':True,'OSStatus':0,'absent':True,'startedUTC':self.clock().isoformat(),'endedUTC':self.clock().isoformat()}
        with mock.patch.object(proof,'source_hashes',return_value=self.manifest['sourceSHA256']),mock.patch.object(proof,'SetupVerifier',return_value=verifier),mock.patch.object(proof,'inspect_selected',return_value=asset),mock.patch.object(proof,'frozen_asset',side_effect=frozen_loader),mock.patch.object(proof,'LiveBackend',return_value=executor) as factory,mock.patch.object(proof,'command') as command,mock.patch.object(proof.subprocess,'Popen') as launch:
            result=c.run_cleanup_only(self.run,attempt,driver);self.assertTrue(result['recoveryRequired']);self.assertFalse(result['cleanupComplete'])
            machine,sha=c.read(self.root,'recovery-attempts/'+attempt+'/machine.json')
            c.exclusive(self.root,'recovery-attempts/'+attempt+'/human.json',{'namespace':self.ns,'synthetic':True,'stage':'recovery-cleanup','machineReceiptSHA256':sha,'wholeStageObserved':True,'phaseIdentified':True,'promptCount':0,'actions':[],'purposes':[],'recordedUTC':self.clock().isoformat()})
            result=c.run_cleanup_only(self.run,attempt,driver);self.assertTrue(result['cleanupComplete']);driver.recover.assert_called_once();driver.finalize.assert_called_once();factory.assert_called_once();self.assertEqual(executor.launch.call_args.kwargs,{'cleanup':True});command.assert_not_called();launch.assert_not_called()
        for path,sha in frozen.items():self.assertEqual(c.file_hash(self.root/path),sha)
        self.assertFalse((self.root/'windows/3.json').exists())
    def test_cleanup_only_no_host_or_unconfirmed_process_keeps_recovery(self):
        self.failed_w2();attempt=str(uuid.uuid4());self.recovery_grant(attempt);backend=mock.Mock();backend.recover.side_effect=c.Rejected('validHostUnavailable')
        result=c.run_cleanup_only(self.run,attempt,backend);self.assertTrue(result['recoveryRequired']);backend.finalize.assert_not_called();self.assertTrue(self.root.exists())
    def test_public_archive_retains_window_ready_human_and_retention_chain(self):
        self.baseline();self.clock.now=self.start+dt.timedelta(days=7,seconds=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(2,'private W2 ready');c.run_window(self.run,2,Backend(self),self.ready)
        self.clock.now+=dt.timedelta(minutes=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(3,'private W3 ready');backend=Backend(self);backend.ensure_exited=mock.Mock();backend.finalize=lambda run:proof.LiveBackend.finalize(backend,run)
        c.run_window(self.run,3,backend,self.ready);output=Path(self.manifest['publicEvidenceDirectory']);self.assertFalse(self.root.exists())
        index=json.loads((output/'final.index.json').read_text())
        for name,sha in index['files'].items():self.assertEqual(c.file_hash(output/name),sha)
        for n in (1,2,3):
            window=json.loads((output/('windows/'+str(n)+'.public.json')).read_text());self.assertEqual(c.stamp(window['cutoffUTC'])-c.stamp(window['startUTC']),dt.timedelta(minutes=25));self.assertEqual(c.stamp(window['deadlineUTC'])-c.stamp(window['startUTC']),dt.timedelta(minutes=30))
        for stage in c.ORDER:
            event=json.loads((output/('receipts/'+stage+'.machine.json')).read_text());gate=json.loads((output/('gates/'+stage+'.public.json')).read_text());self.assertEqual(event['readySHA256'],gate['privateReadySHA256']);self.assertTrue(gate['accepted']);window=json.loads((output/('windows/'+str(event['window'])+'.public.json')).read_text());self.assertEqual(event['windowSHA256'],window['privateWindowSHA256'])
            if stage!='preflight':
                previous=c.ORDER[c.ORDER.index(stage)-1];human=json.loads((output/('human/'+previous+'.json')).read_text());self.assertGreater(c.stamp(gate['recordedUTC']),c.stamp(human['recordedUTC']));self.assertEqual(gate['previousHumanSHA256'],c.file_hash(output/('human/'+previous+'.json')))
        for n in (1,2):self.assertEqual(json.loads((output/('retained-'+str(n)+'.json')).read_text())['state'],'retained-no-background-process')
        raw=''.join(p.read_text() for p in output.rglob('*.json'));self.assertNotIn('private W2 ready',raw);self.assertNotIn('synthetic ready now',raw);self.assertNotIn('synthetic-mac',raw)
    def test_absent_ready_or_proof_never_constructs_app_backend(self):
        self.preflight();self.human('preflight');self.clock.now+=dt.timedelta(seconds=1)
        driver=proof.ManualStages(self.run)
        with mock.patch.object(proof,'LiveBackend') as factory,mock.patch.object(proof,'command') as command,mock.patch.object(proof.subprocess,'Popen') as launch,mock.patch.object(proof,'source_hashes',return_value=self.manifest['sourceSHA256']):
            with self.assertRaises((c.Rejected,OSError)):driver.stage('seed',self.run)
            gate=self.ready('seed');c.exclusive(self.root,'gates/seed.json',gate)
            with self.assertRaises((c.Rejected,OSError)):driver.stage('seed',self.run)
            factory.assert_not_called();command.assert_not_called();launch.assert_not_called()

    def test_recovery_unconfirmed_owned_process_never_inspects_or_launches(self):
        self.failed_w2();attempt=str(uuid.uuid4());self.recovery_grant(attempt)
        verifier=object.__new__(proof.SetupVerifier);verifier.run=self.run;verifier.ensure_exited=mock.Mock(side_effect=c.Rejected('ownedAppDidNotExit'))
        with mock.patch.object(proof,'source_hashes',return_value=self.manifest['sourceSHA256']),mock.patch.object(proof,'SetupVerifier',return_value=verifier),mock.patch.object(proof,'inspect_selected') as inspect,mock.patch.object(proof,'LiveBackend') as factory,mock.patch.object(proof.subprocess,'Popen') as launch:
            result=c.run_cleanup_only(self.run,attempt,proof.ManualStages(self.run));self.assertTrue(result['recoveryRequired']);inspect.assert_not_called();factory.assert_not_called();launch.assert_not_called()
        self.assertTrue(self.root.exists())
    def test_valid_ready_and_control_proof_precede_app_executor_construction(self):
        self.preflight();self.human('preflight');self.clock.now+=dt.timedelta(seconds=1);gate=self.ready('seed');c.exclusive(self.root,'gates/seed.json',gate)
        asset=self.asset();host=self.root/'synthetic-host.app';host.mkdir();asset['frozenHost']=str(host);asset['appSHA256']=proof.app_hash(host)
        driver=proof.ManualStages(self.run)
        with mock.patch.object(proof,'source_hashes',return_value=self.manifest['sourceSHA256']),mock.patch.object(proof,'frozen_asset',return_value=(asset,'a'*64)),mock.patch.object(proof,'LiveBackend') as factory,mock.patch.object(proof,'command') as command,mock.patch.object(proof.subprocess,'Popen') as launch:
            with mock.patch.object(proof,'source_hashes',return_value={}),self.assertRaises(c.Rejected):driver.stage('seed',self.run)
            with mock.patch.dict(self.run.manifest,{'namespace':'wrong'}),self.assertRaises(c.Rejected):driver.stage('seed',self.run)
            grant=self.root/'grants/assets.json';raw=grant.read_bytes();grant.unlink()
            with self.assertRaises((c.Rejected,OSError)):driver.stage('seed',self.run)
            grant.write_bytes(raw)
            bad=copy.deepcopy(asset);bad['hostBindingSHA256']='f'*64
            with mock.patch.object(proof,'frozen_asset',return_value=(bad,'a'*64)),self.assertRaises(c.Rejected):driver.stage('seed',self.run)
            factory.assert_not_called();command.assert_not_called();launch.assert_not_called()
            factory.return_value.launch.return_value={'completed':True}
            driver.stage('seed',self.run);factory.assert_called_once();command.assert_not_called();launch.assert_not_called()
    def test_actual_archive_collision_keeps_private_root(self):
        self.preflight();output=Path(self.manifest['publicEvidenceDirectory']);output.mkdir();c.exclusive(output,'ownership.json',{'namespace':'someone-else'})
        backend=Backend(self);backend.ensure_exited=mock.Mock()
        with self.assertRaises(c.Rejected):proof.SetupVerifier.finalize(backend,self.run)
        self.assertTrue(self.root.exists());self.assertTrue((self.root/'global.json').exists())
