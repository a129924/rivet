from contextlib import ExitStack
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('e016', Path(__file__).parents[1] / 'scripts/e016_live.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

class LaunchChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.root.chmod(0o700)
        self.app = self.root / 'E016LogoutProbe.app'
        self.executable = self.app / 'Contents/MacOS/E016LogoutProbe'
        self.executable.parent.mkdir(parents=True)
        self.executable.write_bytes(b'fake-unsigned')
        self.source = {'commit': 'fake', 'files': {}, 'dirty': ''}
        self.frozen = {'app': str(self.app), 'executable': str(self.executable),
                       'run_id': 'fake-run', 'source': self.source,
                       'binary_hash': MODULE.sha(self.executable.read_bytes()),
                       'source_hash': MODULE.sha(MODULE.canonical(self.source)),
                       'bundle_hash': 'b' * 64, 'profile_hash': 'c' * 64, 'transition_hash': 'd' * 64}
        MODULE.write_once(self.root / 'frozen.json', self.frozen)
        self.hello = {'pid': 1234, 'path': str(self.executable), 'binary_hash': self.frozen['binary_hash'],
                      'phase': 'first', 'run_id': 'fake-run'}
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        for name, value in [('source_manifest', self.source), ('signed_info', self.frozen),
                            ('verify_transition', self.frozen['transition_hash']),
                            ('related_processes_absent', None),
                            ('process_info', {'start': 'fake-start', 'path': str(self.executable)})]:
            self.stack.enter_context(patch.object(MODULE, name, return_value=value))
        self.popen = self.stack.enter_context(patch.object(MODULE.subprocess, 'Popen'))
        self.wait_file = self.stack.enter_context(patch.object(MODULE, 'wait_file', return_value=self.hello))

    def assert_not_authorized(self, phase='first'):
        self.assertFalse((self.root / (phase + '-authorize.json')).exists())

    def first_private(self, **overrides):
        machine = {'schema': 'e016.v1', 'phase': 'first', 'outcome': 'passed', 'failureKind': 'none',
                   **dict.fromkeys(['seed_absent', 'seed_readback', 'write_attempted', 'signout_returned',
                                   'same_process_absent', 'configuration_intact', 'sentinel_intact'], True)}
        value = {'pid': 1234, 'start': 'fake-start', 'terminated': True, 'machine': machine,
                 'frozen_hash': MODULE.sha(MODULE.canonical(self.frozen))}
        value.update(overrides)
        MODULE.write_once(self.root / 'first-private.json', value)

    def test_launch_consumes_before_popen_interrupt_cannot_launch_again(self):
        def on_launch(*args, **kwargs):
            self.assertTrue((self.root / 'first-consumed.json').exists())
            raise MODULE.ProtocolError('simulated launch interruption')
        self.popen.side_effect = on_launch
        for _ in range(2):
            with self.assertRaises(MODULE.ProtocolError):
                MODULE.launch_phase(self.app, self.root, 'first')
        self.assertEqual(self.popen.call_count, 1)
        self.assert_not_authorized()

    def test_source_mismatch_never_launches_or_authorizes(self):
        MODULE.source_manifest.return_value = {'commit': 'changed'}
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'first')
        self.popen.assert_not_called()
        self.assert_not_authorized()

    def test_binary_mismatch_never_launches_or_authorizes(self):
        MODULE.signed_info.return_value = {**self.frozen, 'binary_hash': 'e' * 64}
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'first')
        self.popen.assert_not_called()
        self.assert_not_authorized()

    def test_actual_process_mismatch_never_authorizes(self):
        MODULE.process_info.return_value = {'start': 'fake-start', 'path': '/different/app'}
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'first')
        self.assertEqual(self.popen.call_count, 1)
        self.assert_not_authorized()

    def test_hello_binary_mismatch_never_authorizes(self):
        self.wait_file.return_value = {**self.hello, 'binary_hash': 'e' * 64}
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'first')
        self.assert_not_authorized()

    def test_fresh_requires_first_receipt(self):
        with self.assertRaises(FileNotFoundError):
            MODULE.launch_phase(self.app, self.root, 'fresh')
        self.popen.assert_not_called()

    def test_fresh_requires_passed_first(self):
        self.first_private(machine={'schema': 'e016.v1', 'phase': 'first', 'outcome': 'failed'})
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'fresh')
        self.popen.assert_not_called()

    def test_fresh_requires_termination_receipt(self):
        self.first_private(terminated=False)
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'fresh')
        self.popen.assert_not_called()

    def test_fresh_rechecks_actual_process_exit(self):
        self.first_private()
        with patch.object(MODULE, 'stopped', return_value=False):
            with self.assertRaises(MODULE.ProtocolError):
                MODULE.launch_phase(self.app, self.root, 'fresh')
        self.popen.assert_not_called()

    def test_fresh_rejects_changed_first_provenance(self):
        self.first_private(frozen_hash='wrong')
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'fresh')
        self.popen.assert_not_called()

    def test_changed_signing_transition_never_launches(self):
        MODULE.verify_transition.return_value = 'e' * 64
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.launch_phase(self.app, self.root, 'first')
        self.popen.assert_not_called()

class SigningChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / 'E016LogoutProbe.app'
        self.exe = self.app / 'Contents/MacOS/E016LogoutProbe'
        self.exe.parent.mkdir(parents=True)
        self.exe.write_bytes(b'unsigned')
        self.source = {'commit': 'fake', 'files': {}, 'dirty': ''}
        self.build = {'source': self.source, 'unsigned_binary_hash': MODULE.sha(b'unsigned')}
        MODULE.write_once(self.app.with_suffix('.build-source.json'), self.build)
        self.profile = self.root / 'profile'
        self.profile.write_bytes(b'fake-profile')

    def test_replaced_unsigned_build_never_signs(self):
        self.exe.write_bytes(b'replaced-build')
        with patch.object(MODULE, 'source_manifest', return_value=self.source), patch.object(MODULE, 'command') as command:
            with self.assertRaises(MODULE.ProtocolError):
                MODULE.sign_prepared(self.app, self.profile)
        command.assert_not_called()
        self.assertFalse(self.app.with_suffix('.signing.json').exists())

    def test_sign_records_checked_unsigned_to_signed_transition(self):
        signed = {'binary_hash': MODULE.sha(b'signed'), 'bundle_hash': 'b' * 64, 'profile_hash': MODULE.sha(b'fake-profile')}
        def codesign(*args):
            self.exe.write_bytes(b'signed')
            return b''
        with patch.object(MODULE, 'source_manifest', return_value=self.source), \
             patch.object(MODULE, 'PROFILE_HASH', MODULE.sha(b'fake-profile')), \
             patch.object(MODULE, 'command', side_effect=codesign), \
             patch.object(MODULE, 'signed_info', return_value=signed):
            MODULE.sign_prepared(self.app, self.profile)
        self.assertEqual(MODULE.verify_transition(self.app, signed, self.source),
                         MODULE.sha(self.app.with_suffix('.signing.json').read_bytes()))
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.verify_transition(self.app, {**signed, 'binary_hash': 'e' * 64}, self.source)
        with self.assertRaises(MODULE.ProtocolError):
            MODULE.verify_transition(self.app, signed, {'commit': 'other'})

    def test_preflight_requires_signing_chain(self):
        with patch.object(MODULE, 'related_processes_absent'), patch.object(MODULE, 'signed_info', return_value={}), \
             patch.object(MODULE, 'source_manifest', return_value=self.source):
            with self.assertRaises(FileNotFoundError):
                MODULE.preflight(self.app, self.root / 'run')
        self.assertFalse((self.root / 'run').exists())

class ReceiptChecks(unittest.TestCase):
    def test_projection_rejects_payload_path_and_identity(self):
        for key in ('accessToken', 'path', 'identity', 'error', 'pid'):
            with self.assertRaises(MODULE.ProtocolError): MODULE.public_receipt({key: 'private'})
    def test_unknown_prompt_not_zero(self):
        self.assertEqual(MODULE.public_receipt({'prompt_count_class': 'unknown'})['prompt_count_class'], 'unknown')

if __name__ == '__main__': unittest.main()
