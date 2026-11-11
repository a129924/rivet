import copy
from contextlib import closing
import datetime as dt
import importlib.util
import io
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
import continuity as c
import proof

class Clock:
    def __init__(self): self.now = dt.datetime(2030, 1, 1, tzinfo=c.UTC)
    def __call__(self): return self.now

class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='E010-pure-')
        self.ns = str(uuid.uuid4()); self.root = Path(self.temp.name).resolve()/('rivet-E010-'+self.ns)
        self.root.mkdir(mode=0o700); self.clock = Clock(); self.start = self.clock()
        for kind in ('assets', 'retention', 'recovery'):
            c.exclusive(self.root, 'grants/'+kind+'.json', {'kind':'human-grant', 'scope':kind,
                'namespace':self.ns, 'synthetic':True, 'approved':True, 'statement':'synthetic Human grant',
                'retentionRoot':str(self.root), 'validUntilUTC':(self.start+dt.timedelta(days=11)).isoformat(),
                'procedure':'Human obtains same-group valid cleanup host', 'residualItemAccepted':True})
        self.manifest = c.create_global(self.root, self.ns, (self.start+dt.timedelta(days=7)).isoformat(),
            (self.start+dt.timedelta(days=20)).isoformat(), {'Sources/core.swift':'a'*64}, synthetic=True, clock=self.clock, public_out=Path(self.temp.name).resolve()/('public-'+self.ns))
        self.run = c.Run(self.root, synthetic=True, clock=self.clock)
    def tearDown(self): self.temp.cleanup()
    def human(self, stage, count=0, whole=True):
        event, sha = c.read(self.root, 'receipts/'+stage+'.machine.json')
        value = {'namespace':self.ns, 'synthetic':True, 'stage':stage, 'machineReceiptSHA256':sha,
                 'wholeStageObserved':whole, 'phaseIdentified':True, 'promptCount':count,
                 'actions':['允許']*count, 'purposes':['憑證存取']*count, 'recordedUTC':self.clock().isoformat()}
        c.exclusive(self.root, 'human/'+stage+'.json', value); return value
    def ready(self, stage):
        if self.run.events:
            previous, sha = self.run.events[-1]
            if not c.safe(self.root, 'human/'+previous['stage']+'.json').exists(): self.human(previous['stage'])
            self.clock.now+=dt.timedelta(microseconds=1)
        else: sha = self.run.global_hash
        return {'namespace':self.ns, 'synthetic':True, 'stage':stage, 'previousReceiptSHA256':sha,
                'humanReady':True, 'humanReadyStatement':'synthetic ready now', 'recordedUTC':self.clock().isoformat()}
    def asset(self, name='p0'):
        bundle = self.manifest['bundleIdentifier']; group = 'SYNTHETIC.'+bundle
        renewed = name in ('p1', 'rebuilt'); rebuilt = name == 'rebuilt'
        return {'hostBindingSHA256':self.manifest['hostBindingSHA256'], 'synthetic':True, 'bundleIdentifier':bundle, 'buildMarker':'rebuilt' if rebuilt else 'initial',
                'entitlements':{'com.apple.application-identifier':group, 'keychain-access-groups':[group]},
                'profile':{'ApplicationIdentifierPrefix':['SYNTHETIC'], 'ProvisionedDevices':['fake-device'],
                           'Platform':['OSX'], 'Entitlements':{'com.apple.application-identifier':'SYNTHETIC.*', 'keychain-access-groups':['SYNTHETIC.*']}},
                'device':'fake-device', 'profileSignatureVerified':True, 'certificateInProfile':True,
                'appleDevelopmentChainVerified':True, 'sourceSHA256':self.manifest['sourceSHA256'],
                'profileSHA256':('b' if renewed else 'a')*64, 'certificateSHA256':'d'*64,
                'executableSHA256':('c' if rebuilt else 'a')*64, 'appSHA256':('c' if rebuilt else 'b' if renewed else 'a')*64,
                'DRSHA256':('e' if renewed else 'f')*64,
                'profileCreationUTC':(self.start+dt.timedelta(days=7) if renewed else self.start-dt.timedelta(days=1)).isoformat(),
                'profileExpiryUTC':(self.start+dt.timedelta(days=14 if renewed else 7)).isoformat(),
                'certificateNotBeforeUTC':(self.start-dt.timedelta(days=1)).isoformat(),
                'certificateNotAfterUTC':self.manifest['certificateNotAfterUTC']}
    def baseline(self):
        self.run.arm_window(1, 'synthetic setup ready')
        backend = Backend(self); result = c.run_window(self.run, 1, backend, self.ready)
        self.assertTrue(result['retained']); return backend

class Backend:
    def __init__(self, fixture, fail=None, clean=True): self.f=fixture; self.fail=fail; self.clean=clean; self.calls=[]; self.cleanup_calls=0
    def stage(self, stage, run):
        self.calls.append(stage)
        if stage == self.fail: raise c.Rejected('syntheticExecutionFailed')
        if stage in ('preflight', 'p1-setup', 'rebuild-setup', 'expired'):
            name = {'preflight':'p0', 'expired':'p0', 'p1-setup':'p1', 'rebuild-setup':'rebuilt'}[stage]
            baseline = self.f.asset('p0') if name == 'p1' or stage == 'expired' else self.f.asset('p1') if name == 'rebuilt' else None
            proof.validate_asset(self.f.asset(name), run.manifest, self.f.clock(), baseline, 'expired' if stage == 'expired' else name)
        result = {'startedUTC':self.f.clock().isoformat(), 'endedUTC':self.f.clock().isoformat(),
                  'completed':True, 'callAttempted':stage not in ('preflight','expired','p1-setup','rebuild-setup'),
                  'OSStatus':0 if stage not in ('preflight','expired','p1-setup','rebuild-setup') else None,
                  'launch':'rejected' if stage=='expired' else 'not-requested', 'guard':'not-observed' if stage=='expired' else 'passed'}
        if stage in ('seed','fresh','p1-read','rebuilt-read'): result['fields']={k:True for k in c.FIELDS}
        if stage=='expired':result['availabilityInterrupted']=True
        if stage=='cleanup':result['absent']=True
        return result, 'a'*64
    def wait_observation(self, stage, run): self.f.human(stage)
    def cleanup(self, run): self.cleanup_calls+=1; return self.clean
    def finalize(self, run): return True

class SerializationTests(unittest.TestCase):
    def test_canonical_utf8_sorted_one_lf(self):
        raw=c.canonical({'z':'階段','a':1});self.assertEqual(raw,b'{\n  "a": 1,\n  "z": "'+'階段'.encode()+b'"\n}\n');self.assertEqual(raw,c.canonical({'a':1,'z':'階段'}))
    def test_actual_v6_eof_fixer_does_not_change_canonical_bytes(self):
        database=Path.home()/'.cache/pre-commit/db.db'
        if not database.exists():self.skipTest('existing EOF formatter cache unavailable')
        with closing(sqlite3.connect('file:'+str(database)+'?mode=ro',uri=True)) as conn:
            row=conn.execute('select path from repos where repo=? and ref=?',('https://github.com/pre-commit/pre-commit-hooks','v6.0.0')).fetchone()
        if not row:self.skipTest('pinned EOF formatter cache unavailable')
        spec=importlib.util.spec_from_file_location('actual_eof',Path(row[0])/'pre_commit_hooks/end_of_file_fixer.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        raw=c.canonical({'synthetic':True,'promptCount':None});stream=io.BytesIO(raw);self.assertEqual(module.fix_file(stream),0);self.assertEqual(stream.getvalue(),raw)
    def test_no_nan_and_redaction_allowlist(self):
        with self.assertRaises(ValueError):c.canonical({'bad':float('nan')})
        value=c.public_result({'callAttempted':False,'OSStatus':-1,'classification':'private /Users/person token','accessToken':'secret','device':'secret'})
        self.assertEqual(value,{'callAttempted':False,'OSStatus':None,'classification':'guardRejected'})
        with self.assertRaises(c.Rejected):c.public_result({'executableSHA256':'/Users/private'})

class SwiftReceiptRoundTripTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='E010-pure-swift-receipts-')
        cls.scratch = Path(cls.temp.name).resolve()
        cls.producer = cls.scratch/'receipt-producer'
        exp = Path(__file__).resolve().parents[1]
        subprocess.run(['swiftc', '-module-cache-path', str(cls.scratch/'module-cache'),
                        str(exp/'Sources/DPKContinuityProbe/ProbeCore.swift'),
                        str(exp/'Tests/ReceiptProducer.swift'), '-o', str(cls.producer)],
                       check=True, capture_output=True, timeout=120)
    @classmethod
    def tearDownClass(cls): cls.temp.cleanup()
    def test_actual_swift_producer_to_actual_python_reader(self):
        cases = {
            'no-call': {'stage':'expired', 'callAttempted':False, 'OSStatus':None, 'promptCount':None, 'fields':{}},
            'six-fields': {'stage':'fresh', 'callAttempted':True, 'OSStatus':0, 'fields':{key:True for key in c.FIELDS}, 'completed':True},
            'cleanup': {'stage':'cleanup', 'callAttempted':True, 'OSStatus':0, 'fields':{}, 'absent':True},
            'unicode': {'OSStatus':-25308, 'z':['é','中','😀','"\\/\n\t\x01'], 'é':'a', '中':'b', '\ue000':'c', '\U00010000':'d', '😀':'e'}
        }
        for name, expected in cases.items():
            with self.subTest(receipt=name):
                root = self.scratch/name; root.mkdir(mode=0o700)
                raw = subprocess.run([str(self.producer),name], check=True, capture_output=True, timeout=10).stdout
                with (root/'receipt.json').open('xb') as stream: stream.write(raw)
                value, actual_sha = c.read(root,'receipt.json')
                self.assertEqual(value,expected); self.assertEqual(raw,c.canonical(expected))
                self.assertEqual(actual_sha,c.digest(raw))
                with self.assertRaises(c.Rejected): c.exclusive(root,'receipt.json',expected)
                self.assertEqual((root/'receipt.json').read_bytes(),raw)

class ProtocolTests(Fixture):
    def test_duplicate_exclusive_and_symlink_never_overwrite(self):
        raw=(self.root/'global.json').read_bytes()
        with self.assertRaises(c.Rejected):c.exclusive(self.root,'global.json',{})
        self.assertEqual((self.root/'global.json').read_bytes(),raw)
        (self.root/'escape').symlink_to(Path(self.temp.name).resolve())
        with self.assertRaises(c.Rejected):c.exclusive(self.root,'escape/new.json',{})
        with self.assertRaises(c.Rejected):c.safe(self.root,'../new.json')
    def test_manifest_tamper_rejected(self):
        value=copy.deepcopy(self.manifest);value['fixture']['accessToken']='changed';(self.root/'global.json').write_bytes(c.canonical(value))
        with self.assertRaises(c.Rejected):c.Run(self.root,True,self.clock)
    def test_missing_or_changed_grant_is_zero_live_construction(self):
        (self.root/'grants/assets.json').unlink()
        with mock.patch.object(proof,'command') as commands,mock.patch.object(proof.subprocess,'Popen') as launch:
            with self.assertRaises((c.Rejected,OSError)):c.Run(self.root,True,self.clock)
            commands.assert_not_called();launch.assert_not_called()
    def test_synthetic_run_cannot_construct_live_backend(self):
        with mock.patch.object(proof,'command') as commands:
            with self.assertRaises(c.Rejected):proof.LiveBackend(self.run)
            commands.assert_not_called()
    def test_live_cli_default_and_fake_begin_fail_without_root_or_asset_commands(self):
        with mock.patch.object(sys,'argv',['continuity.py','--root',str(self.root)]),mock.patch.object(proof,'command') as command:
            with self.assertRaises(c.Rejected):c.main()
            command.assert_not_called()
        with mock.patch.object(sys,'argv',['continuity.py','--root',str(self.root),'--live','--begin','--window','1']),mock.patch.object(proof,'command') as command:
            with self.assertRaises(c.Rejected):c.main()
            command.assert_not_called()
    def test_original_window_start_does_not_reset_after_setup(self):
        self.clock.now+=dt.timedelta(minutes=10);window=self.run.arm_window(1,'ready after setup')
        self.assertEqual(c.stamp(window['startUTC']),self.start)
        self.assertEqual(c.stamp(window['cutoffUTC']),self.start+dt.timedelta(minutes=25))
        with self.assertRaises(c.Rejected):self.run.arm_window(1,'no reset')
    def test_window_hash_tamper_and_future_start_rejected(self):
        self.run.arm_window(1,'ready');p=self.root/'windows/1.json';v=json.loads(p.read_text());v['startUTC']=(self.start+dt.timedelta(hours=1)).isoformat();p.write_bytes(c.canonical(v))
        with self.assertRaises(c.Rejected):self.run.window(1)
    def test_cutoff_blocks_measurements_but_cleanup_uses_original_deadline(self):
        self.run.arm_window(1,'ready');self.clock.now+=dt.timedelta(minutes=25)
        with self.assertRaises(c.Rejected):self.run.window(1)
        window,_=self.run.window(1,cleanup=True);self.assertEqual(c.stamp(window['deadlineUTC']),self.start+dt.timedelta(minutes=30))
    def test_global_budget_no_fourth_window_or_premature_expiry(self):
        self.baseline()
        for number in (True,4,2):
            with self.subTest(number=number),self.assertRaises(c.Rejected):self.run.arm_window(number,'ready')
        self.clock.now=self.start+dt.timedelta(days=10)
        with self.assertRaises(c.Rejected):self.run.arm_window(2,'expired global')
        self.assertEqual(c.stamp(self.run.manifest['globalDeadlineUTC']),self.start+dt.timedelta(days=10))
    def test_stale_ready_sha_and_partial_observation_rejected(self):
        self.run.arm_window(1,'ready');gate=self.ready('preflight');gate['recordedUTC']=(self.start-dt.timedelta(seconds=1)).isoformat()
        with self.assertRaises(c.Rejected):self.run.require_ready('preflight',gate)
        gate=self.ready('preflight');gate['previousReceiptSHA256']='f'*64
        with self.assertRaises(c.Rejected):self.run.require_ready('preflight',gate)
        self.run.require_ready('preflight',self.ready('preflight'));result,sha=Backend(self).stage('preflight',self.run);self.run.record('preflight',1,result,sha);self.human('preflight',whole=False)
        with self.assertRaises(c.Rejected):self.run.require_ready('seed',{'namespace':self.ns,'synthetic':True,'stage':'seed','previousReceiptSHA256':self.run.events[-1][1],'humanReady':True,'humanReadyStatement':'ready','recordedUTC':self.clock().isoformat()})
    def test_skip_reseed_and_retention_before_complete_rejected(self):
        self.run.arm_window(1,'ready')
        with self.assertRaises(c.Rejected):self.run.require_ready('fresh',self.ready('fresh'))
        with self.assertRaises(c.Rejected):self.run.retain(1)
        backend=Backend(self);c.run_window(self.run,1,backend,self.ready)
        with self.assertRaises(c.Rejected):self.run.require_ready('seed',self.ready('seed'))
    def test_whole_fixed_three_window_cycle_is_synthetic_and_no_rewrite(self):
        backend=self.baseline();self.assertEqual(backend.cleanup_calls,0)
        self.clock.now=self.start+dt.timedelta(days=7,seconds=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(2,'W2 fresh ready');backend=Backend(self)
        self.assertTrue(c.run_window(self.run,2,backend,self.ready)['retained'])
        expired,_=c.read(self.root,'receipts/expired.machine.json');self.assertFalse(expired['callAttempted']);self.assertIsNone(expired['OSStatus']);self.assertTrue(expired['availabilityInterrupted'])
        self.clock.now+=dt.timedelta(minutes=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(3,'W3 fresh ready');backend=Backend(self)
        result=c.run_window(self.run,3,backend,self.ready);self.assertTrue(result['completed']);self.assertTrue(result['cleanupComplete']);self.assertTrue(result['synthetic']);self.assertEqual(sum(x[0]['stage']=='seed' for x in self.run.events),1)
    def test_actual_coordinator_failure_cleanup_or_recovery_not_fake_success(self):
        for clean in (True,False):
            if clean:self.run.arm_window(1,'ready')
            backend=Backend(self,fail='fresh',clean=clean)
            if not clean:break  # Separate root needed; tested by next case.
            with self.assertRaises(c.Rejected):c.run_window(self.run,1,backend,self.ready)
            self.assertEqual(backend.cleanup_calls,1);self.assertFalse((self.root/'retained-1.json').exists())
            failures=list((self.root/'failures').glob('*.json'));self.assertTrue(json.loads(failures[0].read_text())['keychainItemAbsentConfirmed'])
    def test_actual_coordinator_cleanup_unavailable_records_owned_residual(self):
        self.run.arm_window(1,'ready');backend=Backend(self,fail='fresh',clean=False)
        with self.assertRaises(c.Rejected):c.run_window(self.run,1,backend,self.ready)
        value=json.loads(next((self.root/'failures').glob('*.json')).read_text());self.assertFalse(value['cleanupComplete']);self.assertTrue(value['recoveryRequired']);self.assertTrue(value['possibleOwnedItemRetained'])
    def test_coordinator_cleanup_exception_keeps_recovery_material(self):
        self.run.arm_window(1,'ready');backend=Backend(self,fail='fresh');backend.ensure_exited=mock.Mock(side_effect=c.Rejected('ownedAppDidNotExit'));backend.cleanup=lambda run:backend.ensure_exited()
        with mock.patch.object(proof.subprocess,'Popen') as launch,mock.patch.object(proof.shutil,'rmtree') as remove:
            with self.assertRaises(c.Rejected):c.run_window(self.run,1,backend,self.ready)
            launch.assert_not_called();remove.assert_not_called()
        self.assertTrue((self.root/'global.json').exists());self.assertTrue(json.loads(next((self.root/'failures').glob('*.json')).read_text())['recoveryRequired'])
    def test_filesystem_finalizer_copies_safe_evidence_before_deleting_synthetic_root(self):
        self.baseline(); self.clock.now=self.start+dt.timedelta(days=7,seconds=1)
        self.run=c.Run(self.root,True,self.clock);self.run.arm_window(2,'ready');c.run_window(self.run,2,Backend(self),self.ready)
        self.clock.now+=dt.timedelta(minutes=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(3,'ready')
        backend=Backend(self);backend.ensure_exited=mock.Mock();backend.finalize=lambda run:proof.LiveBackend.finalize(backend,run)
        with mock.patch.object(proof,'command') as command,mock.patch.object(proof.subprocess,'Popen') as launch:
            result=c.run_window(self.run,3,backend,self.ready)
            command.assert_not_called();launch.assert_not_called()
        self.assertTrue(result['cleanupComplete']);self.assertFalse(self.root.exists())
        output=Path(self.manifest['publicEvidenceDirectory']);index=json.loads((output/'final.index.json').read_text())
        self.assertTrue(index['cleanupComplete'])
        for relative,digest in index['files'].items():self.assertEqual(c.file_hash(output/relative),digest)
        self.assertNotIn(str(self.root),''.join(p.read_text() for p in output.rglob('*.json')))
    def test_item_absent_does_not_hide_private_export_failure(self):
        self.baseline();self.clock.now=self.start+dt.timedelta(days=7,seconds=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(2,'ready');c.run_window(self.run,2,Backend(self),self.ready)
        self.clock.now+=dt.timedelta(minutes=1);self.run=c.Run(self.root,True,self.clock);self.run.arm_window(3,'ready');backend=Backend(self);backend.finalize=lambda run:False
        with self.assertRaises(c.Rejected):c.run_window(self.run,3,backend,self.ready)
        failure=json.loads(next((self.root/'failures').glob('*.json')).read_text());self.assertTrue(failure['keychainItemAbsentConfirmed']);self.assertFalse(failure['cleanupComplete']);self.assertFalse(failure['possibleOwnedItemRetained']);self.assertTrue(failure['privateMaterialRetained'])
    def test_unconfirmed_launch_without_pid_is_not_permission_for_cleanup(self):
        backend=Backend(self);backend.run=self.run;ticket=str(uuid.uuid4());c.exclusive(self.root,'control/launch-'+ticket+'.json',{'namespace':self.ns,'ticket':ticket})
        with mock.patch.object(proof.subprocess,'Popen') as launch:
            with self.assertRaises(c.Rejected):proof.LiveBackend.confirm_ticket_exit(backend,ticket,wrapper_exited=False)
            launch.assert_not_called()
    def test_retention_requires_unchanged_matching_grant(self):
        self.baseline();p=self.root/'grants/retention.json';v=json.loads(p.read_text());v['statement']='replacement grant';p.write_bytes(c.canonical(v));self.clock.now+=dt.timedelta(days=7,seconds=1)
        with self.assertRaises(c.Rejected):self.run.arm_window(2,'ready')
    def test_declared_expiry_and_certificate_budget_rejected_before_seed(self):
        for expiry,certificate in ((self.start+dt.timedelta(days=11),self.start+dt.timedelta(days=20)),(self.start+dt.timedelta(days=7),self.start+dt.timedelta(days=10))):
            with self.assertRaises(c.Rejected):c.create_global(self.root,self.ns,expiry.isoformat(),certificate.isoformat(),{},True,self.clock)

class AssetTests(Fixture):
    def test_wildcard_full_prefix_group_and_p0_actual_date(self):
        self.assertEqual(proof.validate_asset(self.asset(),self.manifest,self.clock()),'SYNTHETIC.'+self.manifest['bundleIdentifier'])
        value=self.asset();value['profileExpiryUTC']=(self.start+dt.timedelta(days=6)).isoformat()
        with self.assertRaises(c.Rejected):proof.validate_asset(value,self.manifest,self.clock())
    def test_p1_requires_different_profile_not_different_binary(self):
        self.clock.now+=dt.timedelta(days=7,seconds=1);p0=self.asset();p1=self.asset('p1')
        self.assertEqual(p0['executableSHA256'],p1['executableSHA256']);proof.validate_asset(p1,self.manifest,self.clock(),p0,'p1')
        p1['profileSHA256']=p0['profileSHA256'];p1['executableSHA256']='e'*64
        with self.assertRaises(c.Rejected):proof.validate_asset(p1,self.manifest,self.clock(),p0,'p1')
    def test_invalid_identity_platform_device_expiry_signature_source_fail_closed(self):
        self.clock.now+=dt.timedelta(days=7,seconds=1);base=self.asset();valid=self.asset('p1')
        changes=[('certificateSHA256','f'*64),('profileSignatureVerified',False),('certificateInProfile',False),('sourceSHA256',{}),('profileExpiryUTC',self.clock().isoformat()),('certificateNotBeforeUTC',(self.clock()+dt.timedelta(minutes=1)).isoformat())]
        for key,value in changes:
            asset=copy.deepcopy(valid);asset[key]=value
            with self.subTest(key=key),self.assertRaises(c.Rejected):proof.validate_asset(asset,self.manifest,self.clock(),base,'p1')
        for key,value in [('Platform',['iOS']),('ProvisionedDevices',[])]:
            asset=copy.deepcopy(valid);asset['profile'][key]=value
            with self.subTest(key=key),self.assertRaises(c.Rejected):proof.validate_asset(asset,self.manifest,self.clock(),base,'p1')
    def test_expired_diagnostic_is_original_host_and_read_only_scope(self):
        p0=self.asset()
        with self.assertRaises(c.Rejected):proof.validate_asset(p0,self.manifest,self.clock(),p0,'expired')
        self.clock.now+=dt.timedelta(days=7,seconds=1);proof.validate_asset(p0,self.manifest,self.clock(),p0,'expired')
        changed=copy.deepcopy(p0);changed['appSHA256']='b'*64
        with self.assertRaises(c.Rejected):proof.validate_asset(changed,self.manifest,self.clock(),p0,'expired')
    def test_true_rebuild_requires_same_p1_new_main_and_marker(self):
        self.clock.now+=dt.timedelta(days=7,seconds=1);p1=self.asset('p1');rebuilt=self.asset('rebuilt');proof.validate_asset(rebuilt,self.manifest,self.clock(),p1,'rebuilt')
        for key,value in [('profileSHA256','f'*64),('executableSHA256',p1['executableSHA256']),('buildMarker','initial')]:
            bad=copy.deepcopy(rebuilt);bad[key]=value
            with self.subTest(key=key),self.assertRaises(c.Rejected):proof.validate_asset(bad,self.manifest,self.clock(),p1,'rebuilt')
    def test_public_asset_view_does_not_emit_group_device_paths_or_dr(self):
        asset=self.asset();asset.update(appPath='/private/private-app',DR='private requirement',certSubject='person')
        raw=c.canonical(proof.public_view(asset)).decode();self.assertNotIn('fake-device',raw);self.assertNotIn('SYNTHETIC.',raw);self.assertNotIn('/private/',raw);self.assertNotIn('private requirement',raw)


class RenumberingIdentityTests(unittest.TestCase):
    """Only synthetic namespaces; never inspect or execute any old item/host."""
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='E010-identity-pure-');self.addCleanup(self.temp.cleanup)
        self.ns=str(uuid.uuid4());self.root=Path(self.temp.name).resolve()/('rivet-E010-'+self.ns);self.root.mkdir(mode=0o700)
        self.now=dt.datetime(2030,1,1,tzinfo=c.UTC)
        for scope in ('assets','retention','recovery'):
            c.exclusive(self.root,'grants/'+scope+'.json',{'kind':'human-grant','scope':scope,'namespace':self.ns,'synthetic':True,'approved':True,'statement':'synthetic E010 scope','retentionRoot':str(self.root),'validUntilUTC':(self.now+dt.timedelta(days=11)).isoformat(),'procedure':'synthetic same-group recovery','residualItemAccepted':True})
    def manifest(self):
        return c.create_global(self.root,self.ns,(self.now+dt.timedelta(days=7)).isoformat(),(self.now+dt.timedelta(days=20)).isoformat(),{},True,lambda:self.now)
    def test_e010_root_global_service_and_generic_app_identity(self):
        value=self.manifest()
        self.assertEqual(value['kind'],'E010-global');self.assertEqual(value['service'],'local.rivet.experiments.E010.'+self.ns)
        self.assertEqual(value['bundleIdentifier'],'local.rivet.dpkcontinuity.'+self.ns.replace('-',''))
        with mock.patch.object(proof,'LiveBackend') as backend,mock.patch.object(proof,'command') as command:
            c.Run(self.root,True,lambda:self.now);backend.assert_not_called();command.assert_not_called()
    def test_old_kind_service_bundle_or_grant_root_fail_before_live_backend(self):
        value=self.manifest()
        with mock.patch.object(proof,'LiveBackend') as backend,mock.patch.object(proof,'command') as command:
            for key,old in [('kind','E008-global'),('kind','E008-anchor'),('service','local.rivet.experiments.E008.'+self.ns),('bundleIdentifier','local.rivet.experiments.E008.'+self.ns)]:
                with self.subTest(key=key,old=old),self.assertRaises(c.Rejected):c.authorize(self.root,dict(value,**{key:old}),self.now,True)
            grant,_=c.read(self.root,'grants/assets.json');grant['retentionRoot']=str(self.root.parent/('rivet-E008-'+self.ns))
            with self.assertRaises(c.Rejected):c.checked_grant(grant,'assets',self.ns,self.root,self.now+dt.timedelta(days=10),True)
            backend.assert_not_called();command.assert_not_called()
    def test_old_cli_root_rejected_before_command_or_executor(self):
        old=self.root.parent/('rivet-E008-'+self.ns)
        with mock.patch.object(sys,'argv',['continuity.py','--live','--root',str(old),'--begin-anchor','--public-out',str(self.root.parent/'public')]),mock.patch.object(proof,'command') as command,mock.patch.object(proof,'LiveBackend') as backend:
            with self.assertRaises(c.Rejected):c.main()
            command.assert_not_called();backend.assert_not_called();self.assertFalse(old.exists())

class RenumberingMapTests(unittest.TestCase):
    def test_prior_evidence_manifest_digest_is_not_a_file_reference(self):
        repo=Path(__file__).resolve().parents[3];exp=Path(__file__).resolve().parents[1]
        mapping=json.loads((exp/'history/renumbering-map.json').read_bytes())
        aggregate=mapping['nonFileDigests'];self.assertEqual(len(aggregate),3)
        expected={('experiments/E008/evidence/controlled-stop-20261022-dfc25e14-closure.json','/frozenRunSnapshotFromIndependentTester/priorEvidenceManifestSHA256'),('experiments/E008/evidence/controlled-stop-20261022-dfc25e14-tester-verification.json','/frozenSnapshot/priorEvidenceManifestSHA256'),('experiments/E008/evidence/run-20261022T054623Z-dfc25e14/scope-and-begin-consent.human.json','/priorEvidenceManifestSHA256')}
        self.assertEqual({(x['referringOriginGitPath'],x['jsonPointer']) for x in aggregate},expected)
        file_refs={(x['referringOriginGitPath'],x['jsonPointer']) for x in mapping['references'] if x['kind']=='json-receipt'}
        self.assertTrue(expected.isdisjoint(file_refs))
        for item in aggregate:
            self.assertEqual(item['kind'],'non-file-digest');self.assertIs(item['fileLookupAttempted'],False)
            self.assertEqual(item['recordedDigestSHA256'],'9740194ede6f0e58f00e5e47508b0f8e7992c1253c4c4755fe2bd15522566fe2')
            target=repo/'experiments/E010'/Path(item['referringOriginGitPath']).relative_to('experiments/E008')
            value=json.loads(target.read_bytes())
            for key in item['jsonPointer'].split('/')[1:]:value=value[key]
            self.assertEqual(value,item['recordedDigestSHA256'])

    def test_origin_accounting_and_exact_history_preservation(self):
        repo=Path(__file__).resolve().parents[3];exp=Path(__file__).resolve().parents[1]
        source=json.loads((exp/'history/pr67-422d0c7/original-files.json').read_bytes())
        mapping=json.loads((exp/'history/renumbering-map.json').read_bytes())
        self.assertEqual(mapping['originCommit'],'422d0c7dd07bf9a746a142d6a07a5cad60c947ed')
        self.assertEqual(mapping['originalFilesManifestSHA256'],c.file_hash(exp/'history/pr67-422d0c7/original-files.json'))
        self.assertEqual(len(mapping['pathMoves']),193);self.assertEqual(len(mapping['archivedFiles']),22)
        self.assertEqual({x['originGitPath'] for x in mapping['pathMoves']},{x['gitPath'] for x in source['files']})
        for entry in mapping['archivedFiles']+[x for x in mapping['pathMoves'] if x['disposition']=='byte-preserved-move']:
            self.assertEqual(c.file_hash(repo/entry['destinationPath']),entry['originSHA256'])
        indexes=[e for e in mapping['pathMoves'] if '/evidence/run-' in e['originGitPath'] and e['originGitPath'].endswith(('index.json','.index.json'))]
        self.assertEqual(len(indexes),14)
    def test_typed_references_are_context_bound_and_missing_versions_stay_unknown(self):
        repo=Path(__file__).resolve().parents[3];exp=Path(__file__).resolve().parents[1]
        mapping=json.loads((exp/'history/renumbering-map.json').read_bytes());keys=[]
        self.assertEqual(len(mapping['sourceVersions']),27);self.assertEqual(sum(x['status']=='resolved' for x in mapping['sourceVersions']),22)
        self.assertEqual(len(mapping['unavailableSources']),5)
        for missing in mapping['unavailableSources']:
            self.assertEqual(missing['status'],'content-unavailable-in-published-snapshot');self.assertIsNone(missing['originCommit']);self.assertIsNone(missing['originBlobOID']);self.assertIsNone(missing['resolvedContentPath'])
        origins={x['originGitPath']:x['destinationPath'] for x in mapping['pathMoves'] if x['disposition']=='byte-preserved-move'}
        origins.update({x['originGitPath']:x['destinationPath'] for x in mapping['archivedFiles']})
        decoded={}
        for ref in mapping['references']:
            if ref['kind']=='json-receipt':
                if (ref['referringOriginGitPath'].endswith('controlled-stop-20261021-8e279f70-closure.json') and ref['jsonPointer'].startswith('/runEvidenceSHA256/')) or (ref['referringOriginGitPath'].endswith('pre-cleanup-controls/S06-scope-consent.json') and ref['jsonPointer'].startswith('/protectedPriorEvidenceSHA256/')):
                    self.assertEqual(ref['status'],'resolved',ref['jsonPointer'])
                original=origins[ref['referringOriginGitPath']]
                self.assertEqual(c.file_hash(repo/original),ref['referringOriginSHA256'])
                if original not in decoded:decoded[original]=json.loads((repo/original).read_bytes())
                value=decoded[original]
                for part in ref['jsonPointer'].split('/')[1:]:
                    part=part.replace('~1','/').replace('~0','~');value=value[int(part)] if isinstance(value,list) else value[part]
                self.assertEqual(value,ref['expectedSHA256'] if ref['expectedSHA256'] is not None else ref['recordedPath'])
                self.assertIn('jsonPointer',ref);self.assertNotIn('linkLocator',ref)
                keys.append((ref['referringOriginBlobOID'],ref['referringOriginGitPath'],ref['jsonPointer'],ref['recordedPath'],ref['expectedSHA256'],ref['recordedVersion']))
            else:
                self.assertIn('linkLocator',ref);self.assertIn('resolutionContext',ref);self.assertNotIn('jsonPointer',ref)
            if ref['status']=='resolved':
                target=repo/ref['resolvedContentPath'];self.assertTrue(target.is_file());self.assertFalse(target.is_symlink())
                if ref.get('expectedSHA256'):self.assertEqual(c.file_hash(target),ref['expectedSHA256'])
                self.assertFalse(ref['resolvedContentPath'].startswith('experiments/E008/'))
            else:self.assertIsNone(ref['resolvedContentPath'])
        self.assertEqual(len(keys),len(set(keys)))

if __name__=='__main__':unittest.main()
