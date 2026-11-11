"""MAIN-RF01--04: pure process/build/control boundaries, no actual build or assets."""
import datetime as dt
import json
import os
from pathlib import Path
import signal
import subprocess
import unittest
from unittest import mock
import uuid
import test_main_policy as fixtures
import continuity as c
import proof
import prepare

class MainReviewFixTests(unittest.TestCase):
    setUp=fixtures.MainPolicyTests.setUp
    begin=fixtures.MainPolicyTests.begin
    build_request=fixtures.MainPolicyTests.build_request
    fake_build=fixtures.MainPolicyTests.fake_build
    def completed(self):
        original=proof.inspect_bootstrap
        def qualify(ctx):
            proof.inspect_selected.return_value['certificateSHA256']=c.digest(b'synthetic selected leaf')
            return original(ctx)
        with mock.patch.object(proof,'inspect_bootstrap',side_effect=qualify):return fixtures.MainPolicyTests.completed(self)
    def test_RF01_injected_config_and_environment_cannot_reach_executor(self):
        ctx=self.begin();self.build_request(ctx);seen={};self.build_commands=[]
        def execute(command,log,app,config,bundle,environment):
            seen.update(environment);return self.fake_build(command,log,app,config,bundle)
        with mock.patch.dict(os.environ,{'XCODE_XCCONFIG_FILE':'/synthetic/evil.xcconfig','CODE_SIGNING_ALLOWED':'NO','CONFIGURATION_BUILD_DIR':'/synthetic/escape','SDKROOT':'evil','DYLD_INSERT_LIBRARIES':'/synthetic/evil.dylib'}):
            selection=prepare.signed_build(ctx,'p0',executor=execute)
        for key in ('XCODE_XCCONFIG_FILE','CODE_SIGNING_ALLOWED','CONFIGURATION_BUILD_DIR','SDKROOT','DYLD_INSERT_LIBRARIES'):self.assertNotIn(key,seen)
        self.assertEqual(seen['DEVELOPER_DIR'],str(Path(prepare.XCODEBUILD).parents[2]))
        self.assertEqual(seen['PATH'],'/usr/bin:/bin:/usr/sbin:/sbin')
        result,_=prepare.verify_build_provenance(selection,ctx);attempt,_=c.read(self.root,'builds/p0/attempt.json')
        self.assertEqual(result['effectiveEnvironmentSHA256'],c.digest(c.canonical(seen)))
        self.assertEqual(attempt['effectiveEnvironmentSHA256'],result['effectiveEnvironmentSHA256'])
    def test_RF02_timeout_always_records_failure_and_blocks_following_operations(self):
        ctx=self.begin();self.build_request(ctx)
        def timeout(*args):raise subprocess.TimeoutExpired('synthetic fixed build',1)
        with self.assertRaises((c.Rejected,subprocess.TimeoutExpired)):prepare.signed_build(ctx,'p0',executor=timeout)
        result,_=c.read(self.root,'builds/p0/result.json')
        self.assertEqual(result['classification'],'executorUnconfirmed');self.assertFalse(result['ownedProcessesExited']);self.assertTrue(result['recoveryRequired'])
        with self.assertRaises(c.Rejected):prepare.ensure_builds_exited(ctx)
        with self.assertRaises(c.Rejected):proof.stop_bootstrap(ctx)
        with self.assertRaises(c.Rejected):proof.SetupVerifier.finalize(type('Files',(),{'ensure_exited':lambda _:None})(),ctx)
        self.assertFalse(self.out.exists())
        self.assertTrue(self.root.exists());self.assertFalse((self.root/'selection/p0.json').exists())
    def test_RF02_owned_timeout_terminates_only_proven_new_descendants(self):
        # The shared service existed before launch and is in a different session.
        shared={'uid':os.getuid(),'pid':700,'ppid':1,'pgid':700,'started':'old','comm':'XCBBuildService'}
        leader={'uid':os.getuid(),'pid':800,'ppid':10,'pgid':800,'started':'new','comm':prepare.XCODEBUILD}
        child={'uid':os.getuid(),'pid':801,'ppid':800,'pgid':800,'started':'new','comm':'clang'}
        class Process:
            pid=800
            def poll(_):return None
            def wait(_,timeout=None):raise subprocess.TimeoutExpired('mock',timeout)
        snapshots=iter([[shared],*[[shared,leader,child] for _ in range(5)],[shared]])
        with mock.patch.object(prepare,'process_snapshot',side_effect=lambda:next(snapshots,[shared])),mock.patch.object(prepare.subprocess,'Popen',return_value=Process()) as popen,mock.patch.object(prepare.os,'kill') as kill,mock.patch.object(prepare.time,'monotonic',side_effect=[0,2,3,4,5,6,7,8]),mock.patch.object(prepare.time,'sleep'):
            result=prepare.run_owned_build([prepare.XCODEBUILD],self.root/'synthetic.log',{},1)
        self.assertEqual(result.classification,'timeout');self.assertTrue(result.ownedProcessesExited)
        self.assertEqual({call.args[0] for call in kill.call_args_list},{800,801});self.assertTrue(all(call.args[1]==signal.SIGTERM for call in kill.call_args_list))
        self.assertTrue(popen.call_args.kwargs['start_new_session'])
        class Success:
            pid=800
            def wait(_,timeout=None):return 0
        with mock.patch.object(prepare,'process_snapshot',side_effect=[[shared],[shared,leader],[shared]]),mock.patch.object(prepare.subprocess,'Popen',return_value=Success()),mock.patch.object(prepare.os,'kill') as no_signal,mock.patch.object(prepare.time,'monotonic',side_effect=[0,.1]):
            completed=prepare.run_owned_build([prepare.XCODEBUILD],self.root/'normal.log',{},5)
        self.assertEqual(completed.classification,'completed');self.assertTrue(completed.ownedProcessesExited);no_signal.assert_not_called()
    def test_RF02_residual_or_unknown_process_identity_remains_recovery_required(self):
        shared={'uid':os.getuid(),'pid':700,'ppid':1,'pgid':700,'started':'old','comm':'XCBBuildService'}
        leader={'uid':os.getuid(),'pid':800,'ppid':10,'pgid':800,'started':'new','comm':prepare.XCODEBUILD}
        class Process:
            pid=800
            def poll(_):return None
            def wait(_,timeout=None):raise KeyboardInterrupt()
        with mock.patch.object(prepare,'process_snapshot',side_effect=[[shared],*[ [shared,leader] for _ in range(20)]]),mock.patch.object(prepare.subprocess,'Popen',return_value=Process()),mock.patch.object(prepare.os,'kill') as kill,mock.patch.object(prepare.time,'monotonic',side_effect=[0,1,2,3,10,11,12,13]),mock.patch.object(prepare.time,'sleep'):
            result=prepare.run_owned_build([prepare.XCODEBUILD],self.root/'synthetic.log',{},5)
        self.assertEqual(result.classification,'interrupted');self.assertFalse(result.ownedProcessesExited)
        self.assertTrue(all(call.args[0]==800 for call in kill.call_args_list));self.assertNotIn(700,[call.args[0] for call in kill.call_args_list])
    def stage_backend(self):
        owner=self
        class Backend:
            def stage(_,stage,run):
                now=owner.clock().isoformat();result=dict(startedUTC=now,endedUTC=now,completed=True,callAttempted=stage not in ('preflight','expired'),OSStatus=None)
                if stage in ('seed','fresh','p1-read','rebuilt-read'):result['fields']={k:True for k in c.FIELDS}
                return result,'a'*64
            def cleanup(_,run):return False
            def finalize(_,run):return proof.SetupVerifier.finalize(type('Files',(),{'ensure_exited':lambda _:None})(),run)
            def recover(_,run,attempt):
                owner.build_request(run,'recovery');owner.build_commands=[]
                prepare.signed_build(run,'recovery',executor=owner.fake_build,cleanup_attempt=attempt)
                return dict(completed=True,absent=True,callAttempted=True,OSStatus=0)
        return Backend()
    def test_RF03_failed_P1_exports_as_control_only_and_recovery_can_finish(self):
        run=self.completed();backend=self.stage_backend()
        for stage in ('preflight','seed','fresh'):c.run_main_stage(run,1,stage,backend)
        self.now=self.start+dt.timedelta(days=7,seconds=1);c.run_main_stage(run,2,'expired',backend)
        self.build_request(run,'p1')
        def fail(command,log,app,config,bundle,environment=None):
            log.write_bytes(b'synthetic signing error; private raw');return type('Result',(),{'returncode':65,'ownedProcessesExited':True,'classification':'failed'})()
        with self.assertRaises(c.Rejected):prepare.signed_build(run,'p1',executor=fail)
        self.assertFalse((self.root/'selection/p1.json').exists())
        attempt=str(uuid.uuid4());outcome=c.run_cleanup_only(run,attempt,backend)
        self.assertTrue(outcome['keychainItemAbsentConfirmed']);self.assertTrue(self.root.exists())
        failure,_=c.read(self.out,'builds/p1.public.json');self.assertEqual(failure['classification'],'failed');self.assertFalse(failure['hostProofAvailable'])
        self.assertNotIn('appSHA256',failure);self.assertNotIn('sourceRoot',failure)
        candidate=c.file_hash(self.out/'pre-cleanup.index.json')
        c.exclusive(self.root,'publication-ack.json',dict(kind='safe-candidate-model-ack',namespace=self.ns,globalSHA256=run.global_hash,candidateIndexSHA256=candidate,readabilityAcknowledged=True,safetyAcknowledged=True,recordedUTC=self.clock().isoformat()))
        self.assertTrue(backend.finalize(run));self.assertFalse(self.root.exists())
    def test_RF03_LATE_exit_zero_at_cutoff_is_control_only_and_recovery_can_finish(self):
        run=self.completed();backend=self.stage_backend()
        for stage in ('preflight','seed','fresh'):c.run_main_stage(run,1,stage,backend)
        self.now=self.start+dt.timedelta(days=7,seconds=1);c.run_main_stage(run,2,'expired',backend)
        self.build_request(run,'p1');self.build_commands=[]
        original_window=(self.root/'windows/2.json').read_bytes()
        def late(command,log,app,config,bundle,environment):
            result=self.fake_build(command,log,app,config,bundle,environment)
            self.now=c.stamp(c.read(self.root,'windows/2.json')[0]['cutoffUTC'])
            return result
        with self.assertRaises(c.Rejected):prepare.signed_build(run,'p1',executor=late)
        result,_=c.read(self.root,'builds/p1/result.json')
        self.assertEqual(result['exitCode'],0);self.assertEqual(result['classification'],'late')
        self.assertNotIn('appSHA256',result);self.assertFalse((self.root/'selection/p1.json').exists())
        attempt=str(uuid.uuid4());outcome=c.run_cleanup_only(run,attempt,backend)
        self.assertTrue(outcome['keychainItemAbsentConfirmed']);self.assertTrue(self.root.exists())
        failure,_=c.read(self.out,'builds/p1.public.json')
        self.assertEqual(failure['classification'],'late');self.assertFalse(failure['hostProofAvailable']);self.assertNotIn('appSHA256',failure)
        self.assertEqual((self.root/'windows/2.json').read_bytes(),original_window)
        candidate=c.file_hash(self.out/'pre-cleanup.index.json')
        c.exclusive(self.root,'publication-ack.json',dict(kind='safe-candidate-model-ack',namespace=self.ns,globalSHA256=run.global_hash,candidateIndexSHA256=candidate,readabilityAcknowledged=True,safetyAcknowledged=True,recordedUTC=self.clock().isoformat()))
        self.assertTrue(backend.finalize(run));self.assertFalse(self.root.exists())
        self.assertEqual(c.read(self.out,'final.index.json')[0]['files']['pre-cleanup.index.json'],candidate)

    def test_RF04_setup_stop_retains_raw_until_same_candidate_dual_ACK(self):
        ctx=self.begin();self.out.mkdir()
        first=proof.stop_bootstrap(ctx)
        self.assertFalse(first['cleanupComplete']);self.assertTrue(first['awaitingSafeEvidenceACK']);self.assertTrue(self.root.exists())
        pre=next(self.out.glob('setup-stop-*/pre-cleanup.index.json'));sha=c.file_hash(pre)
        ack=dict(kind='safe-candidate-model-ack',namespace=self.ns,anchorSHA256=ctx.anchor_hash,candidateIndexSHA256=sha,readabilityAcknowledged=True,safetyAcknowledged=False,recordedUTC=self.clock().isoformat())
        c.exclusive(self.root,'publication-ack.json',ack)
        self.assertFalse(proof.stop_bootstrap(ctx)['cleanupComplete'])
        self.assertTrue(self.root.exists());ack['safetyAcknowledged']=True;(self.root/'publication-ack.json').write_bytes(c.canonical(ack))
        result=proof.stop_bootstrap(ctx);self.assertTrue(result['cleanupComplete']);self.assertFalse(self.root.exists());self.assertEqual(c.file_hash(pre),sha)
    def test_RF04_setup_stop_after_original_deadline_keeps_private_root(self):
        ctx=self.begin();original=(self.root/'anchor.json').read_bytes();self.now=self.start+dt.timedelta(minutes=30)
        with self.assertRaises(c.Rejected):proof.stop_bootstrap(ctx)
        self.assertTrue(self.root.exists());self.assertEqual((self.root/'anchor.json').read_bytes(),original)

if __name__=='__main__':unittest.main()
