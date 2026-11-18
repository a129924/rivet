import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('hosted_driver', ROOT / 'scripts/check-github-integration-hosted-tests.py')
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)


def summary():
    return {'result':'Passed','totalTestCount':1,'passedTests':1,'failedTests':0,'skippedTests':0,'expectedFailures':0}


def context():
    return {'schemaVersion':1,'runID':'mock-authorization-0001','authorizationRef':'offline-mock-only',
            'bundleID':'local.rivet.mock','signingIdentitySHA1':'A'*40,'profilePath':'/nonexistent/mock.profile',
            'profileSHA256':'a'*64,'accessGroup':'MOCK.exact','service':'mock.service',
            'fixture':'existing','budget':{'first':1,'fresh':1}}


class DriverTests(unittest.TestCase):
    def test_failed_empty_skipped_and_expected_failure_never_pass(self):
        values=[{}, {'result':'Passed','totalTestCount':0}]
        for field,value in [('result','Failed'),('totalTestCount',2),('passedTests',0),
                            ('failedTests',1),('skippedTests',1),('expectedFailures',1)]:
            changed=summary();changed[field]=value;values.append(changed)
        for value in values:
            with self.assertRaises(DRIVER.Failure): DRIVER.check_summary(value)

    def test_one_native_test_passes(self):
        DRIVER.check_summary(summary())

    def test_duplicate_phase_never_retries(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'first.attempt.json'
            DRIVER.exclusive(path,{'phase':'first'})
            with self.assertRaises(FileExistsError): DRIVER.exclusive(path,{'phase':'first'})

    def test_owner_only_context_required(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'context.json';path.write_text('{}');path.chmod(0o644)
            with self.assertRaises(DRIVER.Failure): DRIVER.read_json(path)

    def test_symlink_context_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);DRIVER.exclusive(root/'real',{})
            (root/'link').symlink_to(root/'real')
            with self.assertRaises(DRIVER.Failure): DRIVER.read_json(root/'link')

    def test_context_contract_and_no_secret_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'context.json';value=context();DRIVER.exclusive(path,value)
            self.assertEqual(DRIVER.validate_context(path),value)
            for key in ['token','clientSecret','oldRunRoot']:
                value=context();value[key]='forbidden'
                path.write_text(json.dumps(value))
                with self.assertRaises(DRIVER.Failure): DRIVER.validate_context(path)

    def test_old_experiment_context_rejected_before_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);path=root/'context.json'
            DRIVER.exclusive(path,{'runID':'old','group':'old','service':'old','keyBase64':'old'})
            with patch.object(DRIVER,'command') as command:
                self.assertEqual(DRIVER.main(['--live','--context',str(path),'--run-root',str(root/'run'),'--phase','first']),2)
                command.assert_not_called()

    def test_context_cannot_reset_budget_by_changing_root(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);path=root/'context.json';value=context();DRIVER.exclusive(path,value)
            DRIVER.bind_context(path,value,root/'first',True)
            with self.assertRaises(DRIVER.Failure): DRIVER.bind_context(path,value,root/'second',False)
            with self.assertRaises(FileExistsError): DRIVER.bind_context(path,value,root/'second',True)

    def test_missing_context_is_blocked_without_subprocess(self):
        with tempfile.TemporaryDirectory() as directory,patch.object(DRIVER,'command') as command:
            root=Path(directory)
            self.assertEqual(DRIVER.main(['--live','--context',str(root/'missing'),'--run-root',str(root/'run'),'--phase','first']),2)
            command.assert_not_called()

    def test_live_protocol_is_only_mocked(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);path=root/'context.json';value=context();DRIVER.exclusive(path,value)
            with patch.object(DRIVER,'live_assets') as assets,patch.object(DRIVER,'root_control') as control,\
                 patch.object(DRIVER,'build') as build,patch.object(DRIVER,'execute_phase',return_value=3) as phase:
                self.assertEqual(DRIVER.main(['--live','--context',str(path),'--run-root',str(root/'run'),'--phase','first']),3)
                assets.assert_called_once();control.assert_called_once();build.assert_called_once()
                phase.assert_called_once_with((root/'run').resolve(),'first','live')

    def test_missing_human_blocks_fresh_before_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);path=root/'context.json';value=context();DRIVER.exclusive(path,value)
            DRIVER.bind_context(path,value,root/'run',True)
            with patch.object(DRIVER,'verify_signing') as signing,patch.object(DRIVER,'execute_phase') as phase:
                self.assertEqual(DRIVER.main(['--live','--context',str(path),'--run-root',str(root/'run'),'--phase','fresh']),2)
                signing.assert_not_called();phase.assert_not_called()

    def write_phase(self,root):
        DRIVER.exclusive(root/'first.machine.json',{'schema':'test'})
        machine=DRIVER.digest(root/'first.machine.json')
        DRIVER.exclusive(root/'first.result.json',{'passed':True,'machineSHA256':machine})
        DRIVER.exclusive(root/'first.exit.json',{'terminated':True,'exitCode':0})
        return machine

    def test_attestation_binds_original_bytes_and_allows_fresh(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);machine=self.write_phase(root)
            self.assertEqual(DRIVER.attest(root,'first',True,0),0)
            self.assertEqual(DRIVER.read_json(root/'first.human.json')['machineSHA256'],machine)
            DRIVER.first_ready(root)
            (root/'first.machine.json').write_text('{}')
            with self.assertRaises(DRIVER.Failure): DRIVER.first_ready(root)

    def test_prompt_or_incomplete_observation_cannot_pass(self):
        for observed,prompts in [(True,1),(False,0)]:
            with tempfile.TemporaryDirectory() as directory:
                root=Path(directory);self.write_phase(root)
                self.assertEqual(DRIVER.attest(root,'first',observed,prompts),1)
                with self.assertRaises(DRIVER.Failure): DRIVER.first_ready(root)

    def test_failed_or_running_native_phase_cannot_be_attested(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);self.write_phase(root)
            (root/'first.exit.json').write_text(json.dumps({'terminated':False,'exitCode':0}))
            with self.assertRaises(DRIVER.Failure): DRIVER.attest(root,'first',True,0)

    def test_profile_hash_fails_before_security_command(self):
        with tempfile.TemporaryDirectory() as directory,patch.object(DRIVER,'command') as command:
            path=Path(directory)/'profile';path.write_bytes(b'mock')
            value=context();value['profilePath']=str(path)
            with self.assertRaises(DRIVER.Failure): DRIVER.live_assets(value)
            command.assert_not_called()

    def test_phase_failure_exit_is_one(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);path=root/'context.json';DRIVER.exclusive(path,context())
            with patch.object(DRIVER,'live_assets'),patch.object(DRIVER,'root_control'),patch.object(DRIVER,'build'),\
                 patch.object(DRIVER,'execute_phase',side_effect=DRIVER.Failure('nativeExecution')):
                self.assertEqual(DRIVER.main(['--live','--context',str(path),'--run-root',str(root/'run'),'--phase','first']),1)

    def test_default_is_offline(self):
        with patch.object(DRIVER,'offline',return_value=0) as offline:
            self.assertEqual(DRIVER.main([]),0);offline.assert_called_once()


if __name__=='__main__':
    unittest.main()
