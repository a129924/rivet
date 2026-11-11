"""Synthetic Python-only tests. No live caller/target imports or external commands."""
import datetime as dt
import importlib.util
import os
from pathlib import Path
import stat
import tempfile
import unittest
from unittest import mock

HERE=Path(__file__).absolute().parent
spec=importlib.util.spec_from_file_location('rp_external',HERE/'retention_pruner.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
NOW=dt.datetime(2026,11,10,8,30,tzinfo=dt.timezone.utc)


class PrunerTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='rivet-RP-synthetic-',dir='/private/tmp')
        self.base=Path(self.tmp.name);self.root=self.base/'synthetic-root';self.root.mkdir(mode=0o700)
        self.job=self.base/'synthetic-job';self.job.mkdir(mode=0o700)
        self.budget=p.Budget('2026-11-10T09:00:00Z',lambda:NOW)
        for directory in ('configured','frozen-source','gui/p0/Products','hosts/p0.app','reference','proofs'):
            (self.root/directory).mkdir(parents=True,exist_ok=True)
            (self.root/directory/'necessary.dat').write_bytes(directory.encode())
        (self.root/'global.json').write_bytes(p.canonical({'namespace':p.NS}))
        (self.root/'DerivedData').mkdir();(self.root/'DerivedData/cache').write_bytes(b'cache')
        self.fd=os.open(self.job,p.FLAGS)
    def tearDown(self):
        os.close(self.fd);self.tmp.cleanup()
    def manifest(self):return p.scan(str(self.root),self.budget)
    def plan(self,m=None,records=None):
        m=m or self.manifest();return m,p.make_plan(m,str(self.root),records or {})
    def review(self,m,plan):
        return {'candidateSHA256':p.sha(p.canonical(p.safe_candidate(plan,m))),
                'readabilityACK':True,'safetyACK':True,'verdict':'approved'}
    def execute(self,m,plan,budget=None,handle=lambda:True,persist=lambda value:None):
        return p.execute(str(self.root),m,plan,budget or self.budget,self.fd,self.review(m,plan),handle,persist)
    def test_exact_cache_allowlist_preserves_root_and_products(self):
        m,plan=self.plan();self.assertEqual(plan['delete'],['DerivedData/cache','DerivedData'])
        result=self.execute(m,plan)
        self.assertTrue(result['cleanupComplete']);self.assertTrue(result['minimumComplete'])
        self.assertTrue(self.root.exists());self.assertTrue((self.root/'gui/p0/Products/necessary.dat').exists())
    def test_raw_uncovered_retains_unknown_and_no_blanket_ack(self):
        (self.root/'raw').mkdir();(self.root/'raw/random.stdout').write_bytes(b'PRIVATE-SENTINEL')
        m,plan=self.plan();self.assertFalse(plan['minimumCompleteEligible']);self.assertEqual(len(plan['rawMap']),1)
        row=plan['rawMap'][0];self.assertEqual(row['stage'],'unknown');self.assertEqual(row['coverage'],'not-proven')
        result=self.execute(m,plan);self.assertTrue(result['allowlistComplete']);self.assertFalse(result['cleanupComplete']);self.assertTrue(result['recoveryRequired'])
        self.assertTrue((self.root/'raw/random.stdout').exists())
        candidate=p.canonical(p.safe_candidate(plan,m));self.assertNotIn(b'PRIVATE-SENTINEL',candidate);self.assertNotIn(b'random.stdout',candidate)
    def test_symlink_external_target_never_opened(self):
        external=self.base/'outside';external.write_bytes(b'NOT-READ')
        (self.root/'DerivedData/link').symlink_to(external)
        m,plan=self.plan();self.assertIsNone(m['nodes']['DerivedData/link']['SHA256'])
        result=self.execute(m,plan);self.assertTrue(result['cleanupComplete']);self.assertEqual(external.read_bytes(),b'NOT-READ')
    def test_hardlink_is_rejected(self):
        os.link(self.root/'DerivedData/cache',self.root/'second-link')
        with self.assertRaisesRegex(p.Refused,'hardlink'):self.manifest()
    def test_foreign_owner_and_cross_device_are_rejected(self):
        value={'uid':os.getuid()+1,'dev':1,'type':stat.S_IFREG,'nlink':1}
        with self.assertRaisesRegex(p.Refused,'foreignOwner'):p.owned(value,os.getuid(),1)
        value['uid']=os.getuid()
        with self.assertRaisesRegex(p.Refused,'crossDevice'):p.owned(value,os.getuid(),2)
    def test_entryset_and_content_drift_refuse_before_mutation(self):
        m,plan=self.plan();(self.root/'DerivedData/cache').write_bytes(b'changed')
        result=self.execute(m,plan);self.assertEqual(result['failed'],'drift');self.assertEqual(result['completed'],[])
        self.assertTrue((self.root/'DerivedData/cache').exists())
    def test_first_deadline_guard_precedes_all_filesystem_calls(self):
        expired=p.Budget('2026-11-10T08:00:00Z',lambda:NOW)
        with mock.patch.object(p.os,'open',side_effect=AssertionError('must not open')):
            with self.assertRaisesRegex(p.Refused,'deadline'):p.scan('/never-read',expired)
        m,plan=self.plan();result=self.execute(m,plan,expired)
        self.assertEqual(result['failed'],'deadline');self.assertEqual(os.listdir(self.job),[])
    def test_per_step_deadline_honest_partial_no_retry(self):
        m,plan=self.plan();clock=[NOW]
        budget=p.Budget('2026-11-10T08:31:00Z',lambda:clock[0])
        def persist(result):
            if len(result['completed'])==1:clock[0]=NOW+dt.timedelta(minutes=2)
        result=self.execute(m,plan,budget,persist=persist)
        self.assertEqual(result['failed'],'deadline');self.assertEqual(len(result['completed']),1)
        self.assertFalse((self.root/'DerivedData/cache').exists());self.assertTrue((self.root/'DerivedData').exists())
        result2=self.execute(m,plan);self.assertEqual(result2['failed'],'alreadyDispatched')
    def test_evidence_persist_failure_prevents_first_mutation(self):
        m,plan=self.plan()
        def fail(result):raise OSError('synthetic-private-path')
        result=self.execute(m,plan,persist=fail)
        self.assertEqual(result['failed'],'unexpected');self.assertEqual(result['completed'],[])
        self.assertTrue((self.root/'DerivedData/cache').exists())
    def test_typed_reference_keeps_complete_cache_dependency_subtree(self):
        m,plan=self.plan(records={'proofs/asset.json':{'appPath':str(self.root/'DerivedData/cache')}})
        self.assertEqual(plan['delete'],[]);self.assertIn('DerivedData/cache',plan['retain'])
    def test_unresolved_dependency_stops_cache_deletion_not_fallback(self):
        m,plan=self.plan(records={'proofs/asset.json':{'proofRelative':'missing.json','proofSHA256':'0'*64}})
        self.assertEqual(plan['delete'],[]);self.assertFalse(plan['minimumCompleteEligible'])
        self.assertEqual(plan['dependencies'][0]['status'],'unresolved')
    def test_occupied_and_missing_review_no_delete(self):
        m,plan=self.plan();result=self.execute(m,plan,handle=lambda:False)
        self.assertEqual(result['failed'],'occupied');self.assertEqual(result['completed'],[])
        self.assertTrue((self.root/'DerivedData/cache').exists())
    def test_source_path_boundaries_no_string_prefix_fallback(self):
        with self.assertRaises(p.Refused):p.relative_reference(str(self.root)+'-other/secret',str(self.root))
        with self.assertRaises(p.Refused):p.relative_reference('../outside',str(self.root))
    def test_malformed_reference_hash_is_finite_refusal_never_public(self):
        m=self.manifest()
        for invalid in ('SYNTHETIC_PRIVATE_HASH_SENTINEL','0'*63,'g'*64,{'private':'SENTINEL'},True,17):
            with self.subTest(kind=type(invalid).__name__):
                with self.assertRaisesRegex(p.Refused,'coverage'):
                    p.make_plan(m,str(self.root),{'proofs/asset.json':{'proofRelative':'missing.json','proofSHA256':invalid}})
        plan=p.make_plan(m,str(self.root),{})
        plan['dependencies']=[{'expectedSHA256':'SYNTHETIC_PRIVATE_HASH_SENTINEL'}]
        with self.assertRaisesRegex(p.Refused,'coverage'):p.safe_candidate(plan,m)
        # Valid-format but nonmatching hash remains a safe unresolved dependency.
        plan=p.make_plan(m,str(self.root),{'proofs/asset.json':{'proofRelative':'missing.json','proofSHA256':'0'*64}})
        self.assertEqual(plan['dependencies'][0]['status'],'unresolved')
        self.assertNotIn(b'SYNTHETIC_PRIVATE_HASH_SENTINEL',p.canonical(p.safe_candidate(plan,m)))
        plan['dependencies'][0]['privateExtra']='SYNTHETIC_PRIVATE_HASH_SENTINEL'
        self.assertNotIn(b'SYNTHETIC_PRIVATE_HASH_SENTINEL',p.canonical(p.safe_candidate(plan,m)))
        plan['dependencies'][0]['status']='SYNTHETIC_PRIVATE_HASH_SENTINEL'
        with self.assertRaisesRegex(p.Refused,'coverage'):p.safe_candidate(plan,m)
        plan=p.make_plan(m,str(self.root),{})
        plan['rawMap']=[{'opaqueID':'0'*64,'rawSHA256':'SYNTHETIC_PRIVATE_HASH_SENTINEL','stage':'unknown',
                        'toolContext':'unknown','safeRefSHA256':None,'safeRefPointer':None,
                        'coverage':'not-proven','disposition':'retain-uncovered','reason':'producer-did-not-persist-provenance'}]
        with self.assertRaisesRegex(p.Refused,'coverage'):p.safe_candidate(plan,m)

    def test_lsof_timeout_preserves_partial_bytes_closed_capture(self):
        calls=[]
        with mock.patch.object(p.subprocess,'run',side_effect=p.subprocess.TimeoutExpired('lsof',1,output=b'PARTIAL',stderr=b'ERR')):
            with self.assertRaisesRegex(p.Refused,'handlesUnproven'):
                p.handles_clear(str(self.root),self.budget,lambda *args:calls.append(args))
        self.assertEqual(calls,[('handles-timeout',b'PARTIAL',b'ERR')])


class CallerTests(unittest.TestCase):
    def test_actual_diagnose_execute_functions_with_only_synthetic_files(self):
        import sys
        sys.modules['retention_pruner']=p
        spec=importlib.util.spec_from_file_location('rp_caller',HERE/'retention_caller.py')
        caller=importlib.util.module_from_spec(spec);spec.loader.exec_module(caller)
        fixture=PrunerTests();fixture.setUp()
        try:
            sources={'synthetic-source':'0'*64};bindings={'actionSHA256':'1'*64,'callerSHA256':'2'*64,'parameterSHA256':'3'*64}
            root_id=p.identity(os.stat(fixture.root));binding={'device':root_id['dev'],'inode':root_id['ino'],'ownerUID':root_id['uid'],'mode':root_id['mode']}
            (fixture.root/'frozen-source/synthetic-source').write_bytes(b'source')
            sources={'synthetic-source':p.sha(b'source')}
            anchor={'namespace':p.NS,'sourceSHA256':sources,'rootBinding':binding}
            (fixture.root/'anchor.json').write_bytes(p.canonical(anchor))
            (fixture.root/'windows').mkdir();(fixture.root/'windows/1.json').write_bytes(b'{}')
            (fixture.root/'bootstrap').mkdir();(fixture.root/'bootstrap/actual-proof.json').write_bytes(b'{}')
            app=fixture.root/'gui/p0/Products/DPKContinuityProbe.app';app.mkdir();(app/'main').write_bytes(b'host')
            # Replace synthetic host payload to match exact source app-hash semantics.
            (fixture.root/'hosts/p0.app/necessary.dat').unlink();(fixture.root/'hosts/p0.app/main').write_bytes(b'host')
            app_sha=p.sha(p.canonical({'main':p.sha(b'host')}));cer=p.sha(b'CER')
            (fixture.root/'reference/original.cer').write_bytes(b'CER')
            (fixture.root/'reference/original-leaf.json').write_bytes(p.canonical({'certificateSHA256':cer}))
            (fixture.root/'proofs/p0.json').write_bytes(p.canonical({'frozenHost':str(fixture.root/'hosts/p0.app'),'certificateSHA256':cer,'appSHA256':app_sha}))
            global_value={'kind':'E010-global','namespace':p.NS,'synthetic':False,'backend':'dpk','sourceSHA256':sources,
                'globalDeadlineUTC':p.D,'rootBinding':binding,'rootBindingSHA256':p.sha(p.canonical(binding)),
                'anchorSHA256':p.sha(p.canonical(anchor)),'window1SHA256':p.sha(b'{}'),'actualSetupProofSHA256':p.sha(b'{}')}
            (fixture.root/'global.json').write_bytes(p.canonical(global_value))
            caller.write(fixture.fd,'window.private.json',{'synthetic':True},fixture.budget)
            caller.write(fixture.fd,'bindings.private.json',bindings,fixture.budget)
            with mock.patch.object(p,'handles_clear',return_value=True) as handles:
                result=caller.diagnose(str(fixture.root),fixture.fd,fixture.budget,sources,bindings)
                handles.assert_called_once()
                self.assertEqual(result['status'],'review-required')
                raw=(fixture.job/'inventory.private.json').read_bytes();plan_raw=(fixture.job/'plan.private.json').read_bytes()
                plan=__import__('json').loads(plan_raw);candidate=(fixture.job/'candidate.safe.json').read_bytes()
                review={'phase':'RP-live-execution','verdict':'approved','requiredFixes':[],
                        'readabilityACK':True,'safetyACK':True,'candidateSHA256':p.sha(candidate),
                        'manifestSHA256':p.sha(raw),'planSHA256':p.sha(plan_raw),'mapSHA256':plan['mapSHA256'],
                        'retainListSHA256':plan['retainListSHA256'],'deleteListSHA256':plan['deleteListSHA256'],**bindings}
                result=caller.execute(str(fixture.root),fixture.fd,fixture.budget,bindings,review)
                self.assertTrue(result['allowlistComplete']);self.assertTrue(fixture.root.exists())
        finally:fixture.tearDown()

    def test_cli_deadline_guard_before_any_parameter_or_private_read(self):
        import sys
        sys.modules['retention_pruner']=p
        spec=importlib.util.spec_from_file_location('rp_caller_guard',HERE/'retention_caller.py')
        caller=importlib.util.module_from_spec(spec);spec.loader.exec_module(caller)
        with mock.patch.object(p,'utc',return_value=p.stamp('2026-11-10T10:00:00Z')), mock.patch.object(caller,'safe_read',side_effect=AssertionError('no read')) as read, mock.patch('sys.stdout'):
            code=caller.cli(['--phase','execute','--params','not-read','--params-sha','0'*64,'--offline-review','not-read','--c0','2026-11-10T08:30:00Z'])
        self.assertEqual(code,2);read.assert_not_called()


if __name__=='__main__':unittest.main()
