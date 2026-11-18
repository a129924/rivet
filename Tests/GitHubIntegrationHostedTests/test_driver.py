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

    def signing_fixture(self, directory, *, host=True, nested=True, decoy=False):
        root=Path(directory).resolve()
        products=root/'DerivedData/Build/Products/Live'
        app=products/(DRIVER.HOST+'.app')
        bundle=app/'Contents/PlugIns'/(DRIVER.BUNDLE+'.xctest')
        products.mkdir(parents=True)
        if host: (app/'Contents').mkdir(parents=True)
        if nested: bundle.mkdir(parents=True)
        if decoy: (products/(DRIVER.BUNDLE+'.xctest')).mkdir()
        profile=root/'synthetic.profile';profile.write_bytes(b'offline-mock-profile')
        value=context();value['profilePath']=str(profile)
        return root,app,bundle,value

    def test_signing_uses_nested_bundle_before_host(self):
        with tempfile.TemporaryDirectory() as directory:
            root,app,bundle,value=self.signing_fixture(directory,decoy=True)
            events=[]
            def record_command(argv,log=None): events.append(('sign',argv[-1]))
            with (
                patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                patch.object(DRIVER,'command',side_effect=record_command),
                patch.object(DRIVER,'verify_signing',side_effect=lambda *_: events.append(('verify',str(app)))),
            ):
                DRIVER.sign_products(root,value)
            self.assertEqual(events,[('sign',str(bundle)),('sign',str(app)),('verify',str(app))])

    def assert_missing_signing_product(self, *, host, nested, decoy):
        with tempfile.TemporaryDirectory() as directory:
            root,_,_,value=self.signing_fixture(directory,host=host,nested=nested,decoy=decoy)
            with (
                patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                patch.object(DRIVER,'command') as command,
                patch.object(DRIVER,'verify_signing') as verify,
            ):
                with self.assertRaises(DRIVER.Failure): DRIVER.sign_products(root,value)
                command.assert_not_called();verify.assert_not_called()
            self.assertFalse((root/'signing.entitlements').exists())

    def test_missing_host_stops_before_signing(self):
        self.assert_missing_signing_product(host=False,nested=False,decoy=False)

    def test_missing_nested_bundle_stops_before_signing(self):
        self.assert_missing_signing_product(host=True,nested=False,decoy=False)

    def test_external_decoy_does_not_replace_nested_bundle(self):
        self.assert_missing_signing_product(host=True,nested=False,decoy=True)

    def native_file(self, path, file_type=6):
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(b'\xcf\xfa\xed\xfe'+(0x0100000C).to_bytes(4,'little')+b'\0'*4
                         +file_type.to_bytes(4,'little')+b'\0'*16)
        return path

    def framework_fixture(self, parent, name, versioned=False):
        framework=parent/(name+'.framework')
        if versioned:
            version=framework/'Versions/A'
            info=version/'Resources/Info.plist'
            executable=version/name
        else:
            info=framework/'Resources/Info.plist'
            executable=framework/name
        info.parent.mkdir(parents=True,exist_ok=True)
        info.write_bytes(DRIVER.plistlib.dumps({'CFBundleExecutable':name}))
        self.native_file(executable)
        if versioned:
            (framework/'Versions/Current').symlink_to('A',target_is_directory=True)
            (framework/name).symlink_to('Versions/Current/'+name)
            (framework/'Resources').symlink_to('Versions/Current/Resources',target_is_directory=True)
        return framework

    def test_embedded_code_inside_out_same_identity_host_only_entitlements(self):
        with tempfile.TemporaryDirectory() as directory:
            root,app,bundle,value=self.signing_fixture(directory)
            frameworks=app/'Contents/Frameworks'
            testing=self.framework_fixture(frameworks,'Testing',versioned=True)
            xctest=self.framework_fixture(frameworks,'XCTest')
            outer=self.framework_fixture(bundle/'Contents/Frameworks','Outer')
            inner=self.framework_fixture(outer/'Frameworks','Inner')
            dylib=self.native_file(frameworks/'libSupport.dylib')
            (frameworks/'TestingAlias.framework').symlink_to(testing,target_is_directory=True)
            calls=[]
            with (patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                  patch.object(DRIVER,'command',side_effect=lambda argv,log=None: calls.append(argv)),
                  patch.object(DRIVER,'verify_signing') as verify):
                DRIVER.sign_products(root,value)
            targets=[Path(argv[-1]) for argv in calls]
            expected={testing,xctest,outer,inner,dylib,bundle,app}
            self.assertEqual(set(targets),expected)
            self.assertEqual(len(targets),len(expected))
            self.assertLess(targets.index(inner),targets.index(outer))
            self.assertEqual(targets[-2:],[bundle,app])
            for argv in calls:
                self.assertEqual(argv[argv.index('--sign')+1],value['signingIdentitySHA1'])
                self.assertNotIn('--deep',argv)
            self.assertEqual([argv[-1] for argv in calls if '--entitlements' in argv],[str(app)])
            verify.assert_called_once_with(root,value)

    def test_resource_only_bundle_and_non_runtime_files_are_not_signed(self):
        with tempfile.TemporaryDirectory() as directory:
            root,app,bundle,value=self.signing_fixture(directory)
            resource=app/'Contents/Resources/Assets.bundle'
            resource.mkdir(parents=True)
            (resource/'Info.plist').write_bytes(DRIVER.plistlib.dumps({'CFBundlePackageType':'BNDL'}))
            (resource/'image.dat').write_bytes(b'ordinary-resource')
            self.native_file(resource/'object.o',file_type=1)
            (resource/'java.class').write_bytes(b'\xca\xfe\xba\xbe'+b'\0\0\0='*6)
            calls=[]
            with (patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                  patch.object(DRIVER,'command',side_effect=lambda argv,log=None: calls.append(argv[-1])),
                  patch.object(DRIVER,'verify_signing')):
                DRIVER.sign_products(root,value)
            self.assertEqual(calls,[str(bundle),str(app)])

    def test_external_framework_symlink_stops_before_any_signing(self):
        with tempfile.TemporaryDirectory() as directory:
            root,app,_,value=self.signing_fixture(directory)
            outside=self.framework_fixture(root/'outside','External')
            frameworks=app/'Contents/Frameworks';frameworks.mkdir()
            (frameworks/'External.framework').symlink_to(outside,target_is_directory=True)
            with (patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                  patch.object(DRIVER,'command') as command,patch.object(DRIVER,'verify_signing') as verify):
                with self.assertRaises(DRIVER.Failure): DRIVER.sign_products(root,value)
                command.assert_not_called();verify.assert_not_called()

    def test_external_executable_symlink_stops_before_any_signing(self):
        with tempfile.TemporaryDirectory() as directory:
            root,app,_,value=self.signing_fixture(directory)
            outside=self.native_file(root/'outside.dylib')
            frameworks=app/'Contents/Frameworks';frameworks.mkdir()
            (frameworks/'alias.dylib').symlink_to(outside)
            with (patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                  patch.object(DRIVER,'command') as command,patch.object(DRIVER,'verify_signing') as verify):
                with self.assertRaises(DRIVER.Failure): DRIVER.sign_products(root,value)
                command.assert_not_called();verify.assert_not_called()

    def test_inner_signing_failure_prevents_parent_signing(self):
        with tempfile.TemporaryDirectory() as directory:
            root,app,_,value=self.signing_fixture(directory)
            inner=self.framework_fixture(app/'Contents/Frameworks','Inner')
            calls=[]
            def fail(argv,log=None):
                calls.append(argv[-1])
                raise DRIVER.Failure('syntheticInnerSigningFailure')
            with (patch.object(DRIVER,'live_assets',return_value={'TeamIdentifier':['MOCK'],'Entitlements':{}}),
                  patch.object(DRIVER,'command',side_effect=fail),patch.object(DRIVER,'verify_signing') as verify):
                with self.assertRaises(DRIVER.Failure): DRIVER.sign_products(root,value)
                verify.assert_not_called()
            self.assertEqual(calls,[str(inner)])

    def test_native_macho_detection_supports_thin_and_fat_not_resources(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            thin=self.native_file(root/'thin.dylib')
            self.assertTrue(DRIVER.is_native_executable(thin))
            payload=thin.read_bytes()
            fat=root/'fat.dylib'
            fat.write_bytes(b'\xca\xfe\xba\xbe'+(1).to_bytes(4,'big')
                            +b'\0'*8+(32).to_bytes(4,'big')+len(payload).to_bytes(4,'big')+b'\0'*4
                            +b'\0'*4+payload)
            self.assertTrue(DRIVER.is_native_executable(fat))
            obj=self.native_file(root/'object.o',file_type=1)
            self.assertFalse(DRIVER.is_native_executable(obj))
            resource=root/'resource';resource.write_bytes(b'ordinary-data')
            self.assertFalse(DRIVER.is_native_executable(resource))

    def test_default_is_offline(self):
        with patch.object(DRIVER,'offline',return_value=0) as offline:
            self.assertEqual(DRIVER.main([]),0);offline.assert_called_once()


if __name__=='__main__':
    unittest.main()
