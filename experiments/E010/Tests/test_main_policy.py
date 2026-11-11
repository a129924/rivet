"""Main-package control fixtures only: no live assets, clocks, App or Security calls."""
import copy
import datetime as dt
import json
import pathlib
import sys
import tempfile
import unittest
from unittest import mock
import uuid
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'scripts'))
import continuity as c
import proof
import prepare

class MainPolicyTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='E010-main-pure-');self.addCleanup(self.tmp.cleanup)
        self.ns=str(uuid.uuid4());self.root=pathlib.Path(self.tmp.name).resolve()/('rivet-E010-'+self.ns);self.root.mkdir(mode=0o700)
        self.now=dt.datetime(2026,11,4,9,0,tzinfo=c.UTC);self.start=self.now;self.clock=lambda:self.now
        self.source=proof.source_hashes();self.out=self.root.parent/'public'
        consent={'kind':'E010-main-package-consent','authorizationMode':'main-package','namespace':self.ns,'synthetic':True,'approved':True,'statement':'確認批准整包，包含跨週留存、本人認證／跨日喚起，以及第7項故障殘留交接例外。','approvedUTC':'2026-11-04T08:56:05Z','latestStartUTC':'2026-11-05T08:56:05Z','grantsValidUntilUTC':'2026-11-15T08:56:05Z','retentionRoot':str(self.root),'sourceSHA256':self.source,'actions':list(c.ORDER),'maxMainSignedBuilds':3,'maxCleanupSignedBuilds':1}
        self.consent_sha=c.exclusive(self.root,'main-consent.json',consent)
        for kind in ('assets','retention','recovery'):
            c.exclusive(self.root,'grants/'+kind+'.json',{'kind':'human-grant','scope':kind,'namespace':self.ns,'synthetic':True,'approved':True,'statement':'synthetic approved whole package','retentionRoot':str(self.root),'validUntilUTC':'2026-11-15T08:56:05Z','procedure':'same leaf/full-group exact cleanup; D-after Human handoff only','residualItemAccepted':True,'authorizationMode':'main-package','mainConsentSHA256':self.consent_sha,'sourceSHA256':self.source})
    def begin(self):
        c.begin_anchor(self.root,self.ns,self.source,self.out,True,self.clock)
        return c.Bootstrap(self.root,True,self.clock)
    def completed(self):
        ctx=self.begin();ctx.setup_ready()
        app=self.root/'synthetic-selected.app';app.mkdir();(app/'fake').write_text('never launched')
        group='SYNTHETIC.'+ctx.manifest['bundleIdentifier']
        asset={'synthetic':True,'hostBindingSHA256':ctx.manifest['hostBindingSHA256'],'appPath':str(app),'appSHA256':proof.app_hash(app),'executableSHA256':'a'*64,'profileSHA256':'b'*64,'certificateSHA256':'c'*64,'DRSHA256':'d'*64,'bundleIdentifier':ctx.manifest['bundleIdentifier'],'buildMarker':'initial','sourceSHA256':self.source,'entitlements':{'com.apple.application-identifier':group,'keychain-access-groups':[group]},'profile':{'ApplicationIdentifierPrefix':['SYNTHETIC'],'ProvisionedDevices':['synthetic-device'],'Platform':['OSX'],'Entitlements':{'com.apple.application-identifier':'SYNTHETIC.*','keychain-access-groups':['SYNTHETIC.*']}},'device':'synthetic-device','profileCreationUTC':(self.start-dt.timedelta(days=1)).isoformat(),'profileExpiryUTC':(self.start+dt.timedelta(days=7)).isoformat(),'certificateNotBeforeUTC':(self.start-dt.timedelta(days=1)).isoformat(),'certificateNotAfterUTC':(self.start+dt.timedelta(days=20)).isoformat(),'profileSignatureVerified':True,'certificateInProfile':True,'appleDevelopmentChainVerified':True}
        c.exclusive(self.root,'selection/p0.json',{'appPath':str(app)})
        with mock.patch.object(proof,'inspect_selected',return_value=asset):proof.inspect_bootstrap(ctx)
        c.complete_global(ctx)
        return c.Run(self.root,True,self.clock)
    def test_whole_package_bootstrap_is_not_future_ready_or_observation(self):
        run=self.completed();run.arm_window(1,None)
        self.assertEqual(run.manifest['authorizationMode'],'main-package')
        self.assertEqual(run.manifest['mainConsentSHA256'],self.consent_sha)
        self.assertFalse((self.root/'bootstrap/begin.human.json').exists())
        self.assertFalse((self.root/'bootstrap/setup.human.json').exists())
        for relative in ('bootstrap/setup.ready.json','bootstrap/seed.ready.json'):
            gate,_=c.read(self.root,relative)
            self.assertEqual(gate['authorizationMode'],'main-package');self.assertNotIn('humanReady',gate)
            self.assertNotIn('wholeStageObserved',gate)
        self.assertEqual(c.observation_status(run,'seed')['UX'],'unknown')
    def test_bad_package_source_namespace_grants_and_start_are_zero_live_capability(self):
        original=(self.root/'main-consent.json').read_bytes()
        for key,value in [('namespace',str(uuid.uuid4())),('sourceSHA256',{}),('approved',False),('actions',['seed']),('approvedUTC','2026-11-05T08:56:05Z')]:
            with self.subTest(key=key):
                bad=json.loads(original);bad[key]=value;(self.root/'main-consent.json').write_bytes(c.canonical(bad))
                with mock.patch.object(proof,'command') as command,mock.patch.object(proof,'LiveBackend') as backend:
                    with self.assertRaises(c.Rejected):self.begin()
                    command.assert_not_called();backend.assert_not_called()
                self.assertFalse((self.root/'anchor.json').exists())
        (self.root/'main-consent.json').write_bytes(original)
        self.now=dt.datetime(2026,11,5,8,56,6,tzinfo=c.UTC)
        with self.assertRaises(c.Rejected):self.begin()
        self.assertFalse((self.root/'anchor.json').exists())

    def test_fixed_stage_no_reseed_and_observation_unknown_do_not_block_data(self):
        run=self.completed();calls=[]
        class Backend:
            def stage(_,stage,r):
                calls.append(stage);now=self.clock().isoformat()
                return dict(startedUTC=now,endedUTC=now,completed=True,callAttempted=stage!='preflight',OSStatus=0 if stage!='preflight' else None,fields={k:True for k in c.FIELDS}),'a'*64
            def cleanup(_,r):return False
        backend=Backend()
        for stage in ('preflight','seed','fresh'):
            outcome=c.run_main_stage(run,1,stage,backend);self.assertEqual(outcome['UX'],'unknown')
        self.assertEqual(calls,['preflight','seed','fresh'])
        self.assertIsNone(c.read(self.root,'retained-1.json')[0]['humanReceiptSHA256'])
        seed_before=(self.root/'receipts/seed.machine.json').read_bytes()
        with self.assertRaises(c.Rejected):c.run_main_stage(run,1,'seed',backend)
        self.assertEqual(calls,['preflight','seed','fresh']);self.assertEqual((self.root/'receipts/seed.machine.json').read_bytes(),seed_before)
        event,event_sha=c.read(self.root,'receipts/fresh.machine.json')
        c.exclusive(self.root,'human/fresh.json',dict(namespace=self.ns,synthetic=True,stage='fresh',machineReceiptSHA256=event_sha,wholeStageObserved=True,phaseIdentified=True,promptCount=0,actions=[],purposes=[],recordedUTC=self.clock().isoformat()))
        self.assertEqual(c.observation_status(run,'fresh')['UX'],'observed')
        self.now=self.start+dt.timedelta(days=7,seconds=1);run=c.Run(self.root,True,self.clock);run.arm_window(2,None)
        self.assertEqual(c.read(self.root,'windows/2.json')[0]['authorizationMode'],'main-package')
        self.now+=dt.timedelta(minutes=30)
        with self.assertRaises(c.Rejected):run.window(2,cleanup=True)
    def test_real_observation_is_optional_but_never_inferred_from_consent(self):
        run=self.completed();run.arm_window(1,None)
        now=self.clock().isoformat();gate,_=c.package_gate(run,'preflight',run.global_hash,'gates/preflight.json');run.require_ready('preflight',gate)
        event,sha=run.record('preflight',1,dict(startedUTC=now,endedUTC=now,completed=True,callAttempted=False),'a'*64)
        human=dict(namespace=self.ns,synthetic=True,stage='preflight',machineReceiptSHA256=sha,wholeStageObserved=False,phaseIdentified=False,promptCount=None,actions=[],purposes=[],recordedUTC=now)
        c.exclusive(self.root,'human/preflight.json',human)
        self.assertEqual(c.observation_status(run,'preflight')['UX'],'unknown')
        gate,_=c.package_gate(run,'seed',sha,'gates/seed.json');run.require_ready('seed',gate)
        future=copy.deepcopy(gate);future['recordedUTC']=(self.now+dt.timedelta(seconds=1)).isoformat()
        with self.assertRaises(c.Rejected):run.check_ready('seed',future,run.events[-1])
        bogus=copy.deepcopy(gate);bogus['humanReady']=True
        with self.assertRaises(c.Rejected):run.check_ready('seed',bogus,run.events[-1])
    def build_request(self,ctx,phase='p0'):
        raw=b'synthetic selected profile; not CMS';c.exclusive(self.root,'fixture-placeholder.json',{'synthetic':True}) if not (self.root/'fixture-placeholder.json').exists() else None
        asset=self.root/'assets'/ (phase+'.provisionprofile');asset.parent.mkdir(mode=0o700,exist_ok=True);asset.write_bytes(raw)
        (self.root/'assets/selected-leaf.der').write_bytes(b'synthetic selected leaf')
        c.exclusive(self.root,'build-requests/'+phase+'.json',{'namespace':self.ns,'phase':phase,'sourceSHA256':ctx.manifest['sourceSHA256'],'bundleIdentifier':ctx.manifest['bundleIdentifier'],'teamIdentifier':'SYNTHETIC1','certificateSHA1':__import__('hashlib').sha1(b'synthetic selected leaf').hexdigest(),'certificateSHA256':c.digest(b'synthetic selected leaf'),'profileUUID':str(uuid.uuid4()),'profileSHA256':c.digest(raw)})
    def fake_build(self,command,log,app,config,bundle,environment=None):
        import plistlib
        self.build_commands.append(command)
        log.write_bytes(b'synthetic fixed build log\n')
        (app/'Contents/MacOS').mkdir(parents=True)
        (app/'Contents/MacOS/DPKContinuityProbe').write_bytes(b'synthetic executable not launched')
        (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':bundle,'CFBundleExecutable':'DPKContinuityProbe','E010BuildMarker':'rebuilt' if config=='Rebuilt' else 'initial'}))
        return type('Result',(),{'returncode':0})()
    def test_direct_build_actual_producer_receipt_binds_source_log_config_and_owned_app(self):
        ctx=self.begin();self.build_request(ctx);self.build_commands=[]
        selected=prepare.signed_build(ctx,'p0',executor=self.fake_build)
        result,result_sha=prepare.verify_build_provenance(selected,ctx)
        self.assertFalse(result['signedHostVerified']);self.assertEqual(len(self.build_commands),1)
        command=self.build_commands[0]
        self.assertEqual(command[0],prepare.XCODEBUILD);self.assertIn('CODE_SIGNING_ALLOWED=YES',command)
        self.assertNotIn('-showBuildSettings',command);self.assertNotIn('-allowProvisioningUpdates',command)
        self.assertEqual(result['configuration'],'Debug');self.assertEqual(len(result['sourceSHA256']),8)
        self.assertEqual(c.file_hash(pathlib.Path(selected['appPath'])/'Contents/MacOS/DPKContinuityProbe'),result['executableSHA256'])
        with self.assertRaises(c.Rejected):prepare.signed_build(ctx,'p0',executor=self.fake_build)
        log=self.root/'builds/p0/build.raw.log';log.write_bytes(b'tampered')
        with self.assertRaises(c.Rejected):prepare.verify_build_provenance(selected,ctx)
        self.assertEqual(len(self.build_commands),1)
    def test_signed_build_bad_request_or_clock_never_constructs_executor(self):
        ctx=self.begin();self.build_request(ctx);self.build_commands=[]
        p=self.root/'build-requests/p0.json';raw=p.read_bytes();bad=json.loads(raw);bad['bundleIdentifier']='other.app';p.write_bytes(c.canonical(bad))
        with self.assertRaises(c.Rejected):prepare.signed_build(ctx,'p0',executor=self.fake_build)
        self.assertEqual(self.build_commands,[]);self.assertFalse((self.root/'builds/p0').exists())
        p.write_bytes(raw);self.now=self.start+dt.timedelta(minutes=25)
        with self.assertRaises(c.Rejected):prepare.signed_build(ctx,'p0',executor=self.fake_build)
        self.assertEqual(self.build_commands,[])
    def test_python_producer_to_actual_swift_main_chain_rejects_tamper_without_human_files(self):
        import subprocess
        run=self.completed();run.arm_window(1,None)
        exp=pathlib.Path(__file__).resolve().parents[1];probe=pathlib.Path(self.tmp.name)/'main-chain-probe'
        subprocess.run(['swiftc','-module-cache-path',str(pathlib.Path(self.tmp.name)/'cache'),str(exp/'Sources/DPKContinuityProbe/ProbeCore.swift'),str(exp/'Sources/DPKContinuityProbe/LiveGate.swift'),str(exp/'Tests/WindowChainProbe.swift'),'-o',str(probe)],check=True,capture_output=True,timeout=120)
        def verify(accepted):
            result=subprocess.run([str(probe),str(self.root),'1',str(self.now.timestamp())],capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0 if accepted else 2,result.stdout+result.stderr)
        verify(True)
        for rel in ('main-consent.json','grants/assets.json','bootstrap/seed.ready.json','bootstrap/actual-proof.json'):
            p=self.root/rel;raw=p.read_bytes();bad=json.loads(raw)
            if rel.endswith('seed.ready.json'):bad['humanReady']=True
            elif rel.endswith('actual-proof.json'):bad['profileSHA256']='f'*64
            else:bad['namespace']=str(uuid.uuid4())
            p.write_bytes(c.canonical(bad));verify(False);p.write_bytes(raw)
        verify(True)

    def test_safe_candidate_ack_is_required_before_exact_private_cleanup(self):
        run=self.completed()
        fake=type('FilesystemVerifier',(),{'ensure_exited':lambda _:None})()
        class Backend:
            def stage(_,stage,r):
                now=self.clock().isoformat();value=dict(startedUTC=now,endedUTC=now,completed=True,callAttempted=stage not in ('preflight','expired','p1-setup','rebuild-setup'),OSStatus=None)
                if stage in ('seed','fresh','p1-read','rebuilt-read'):value['fields']={k:True for k in c.FIELDS}
                if stage=='cleanup':value['absent']=True
                return value,'a'*64
            def cleanup(_,r):return False
            def finalize(_,r):return proof.SetupVerifier.finalize(fake,r)
        backend=Backend()
        for number in (1,2,3):
            if number==2:self.now=self.start+dt.timedelta(days=7,seconds=1)
            if number==3:self.now+=dt.timedelta(seconds=1)
            for stage in c.STAGES[number]:outcome=c.run_main_stage(run,number,stage,backend)
        self.assertTrue(outcome['keychainItemAbsentConfirmed']);self.assertTrue(outcome['awaitingSafeEvidenceACK']);self.assertFalse(outcome['cleanupComplete'])
        self.assertTrue(self.root.exists());self.assertTrue((self.out/'pre-cleanup.index.json').exists())
        public=b''.join(p.read_bytes() for p in self.out.rglob('*.json'))
        self.assertNotIn(str(self.root).encode(),public);self.assertNotIn(c.MAIN_STATEMENT.encode(),public)
        candidate=c.file_hash(self.out/'pre-cleanup.index.json')
        c.exclusive(self.root,'publication-ack.json',dict(kind='safe-candidate-model-ack',namespace=self.ns,globalSHA256=run.global_hash,candidateIndexSHA256=candidate,readabilityAcknowledged=True,safetyAcknowledged=True,recordedUTC=self.clock().isoformat()))
        self.assertTrue(proof.SetupVerifier.finalize(fake,run));self.assertFalse(self.root.exists())
        index=json.loads((self.out/'final.index.json').read_bytes());self.assertTrue(index['cleanupComplete'])
        self.assertEqual(index['files']['pre-cleanup.index.json'],candidate)

if __name__=='__main__':unittest.main()
