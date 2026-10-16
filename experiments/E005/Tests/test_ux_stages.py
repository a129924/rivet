"""Synthetic immutable UX protocol tests; never invoke Keychain or GUI."""
import datetime
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from ux_stages import UXStages, exclusive_json, utc_now


class UXProtocol(unittest.TestCase):
    def fixture(self, human_only=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        ux = UXStages('synthetic-namespace', root / 'evidence', root / 'control', utc_now() + datetime.timedelta(minutes=1), human_only=human_only)
        digest = ux.complete(0, {'startedUTC': utc_now().isoformat(), 'finishedUTC': utc_now().isoformat()})
        gate = {'namespace': ux.namespace, 'phase': 1, 'previousReceiptSHA256': digest,
                'humanReady': True, 'desktopConnected': True, 'humanReadyStatement': 'synthetic ready'}
        human = {'namespace': ux.namespace, 'phase': 0, 'machineReceiptSHA256': digest,
                 'observedWholeStage': True, 'phaseIdentified': True, 'promptCount': 0, 'actions': [], 'purposes': []}
        return ux, gate, human

    def test_valid_observation_and_fresh_ready_accepted(self):
        ux, gate, human = self.fixture()
        exclusive_json(ux.evidence / 'phase-0.human.json', human)
        exclusive_json(ux.control / 'gate-1.json', gate)
        self.assertEqual(ux.wait_ready(1), gate)

    def test_human_only_requires_explicit_consistent_mode_without_fake_connection(self):
        for wrong in (None, 'missing-gate-mode', 'fake-connection', 'missing-human-mode'):
            with self.subTest(wrong=wrong):
                ux, gate, human = self.fixture(human_only=True)
                gate.update(observationMode='human-only', desktopConnected=None)
                human['observationMode'] = 'human-only'
                if wrong == 'missing-gate-mode':
                    del gate['observationMode']
                elif wrong == 'fake-connection':
                    gate['desktopConnected'] = True
                elif wrong == 'missing-human-mode':
                    del human['observationMode']
                exclusive_json(ux.evidence / 'phase-0.human.json', human)
                exclusive_json(ux.control / 'gate-1.json', gate)
                if wrong:
                    with self.assertRaises(RuntimeError):
                        ux.wait_ready(1)
                else:
                    ux.wait_ready(1)
                    receipt = json.loads((ux.evidence / 'phase-0.machine.json').read_text())
                    self.assertEqual(receipt['observationMode'], 'human-only')
                    self.assertFalse(receipt['desktopConnectionRequired'])

    def test_default_native_mode_rejects_human_only_gate(self):
        ux, gate, human = self.fixture()
        gate.update(observationMode='human-only', desktopConnected=None)
        human['observationMode'] = 'human-only'
        exclusive_json(ux.evidence / 'phase-0.human.json', human)
        exclusive_json(ux.control / 'gate-1.json', gate)
        with self.assertRaisesRegex(RuntimeError, 'uxGateMismatchOrNotReady'):
            ux.wait_ready(1)

    def test_wrong_namespace_phase_sha_or_ready_blocked(self):
        for field, value in (('namespace', 'other'), ('phase', 3), ('previousReceiptSHA256', 'wrong'),
                             ('humanReady', False), ('desktopConnected', False)):
            with self.subTest(field=field):
                ux, gate, human = self.fixture()
                gate[field] = value
                exclusive_json(ux.evidence / 'phase-0.human.json', human)
                exclusive_json(ux.control / 'gate-1.json', gate)
                with self.assertRaisesRegex(RuntimeError, 'uxGateMismatchOrNotReady'):
                    ux.wait_ready(1)

    def test_missing_or_incomplete_observation_blocked(self):
        for field, value in ((None, None), ('observedWholeStage', False), ('phaseIdentified', False),
                             ('machineReceiptSHA256', 'wrong'), ('promptCount', None), ('promptCount', 1)):
            with self.subTest(field=field):
                ux, gate, human = self.fixture()
                if field:
                    human[field] = value
                    exclusive_json(ux.evidence / 'phase-0.human.json', human)
                exclusive_json(ux.control / 'gate-1.json', gate)
                with self.assertRaisesRegex(RuntimeError, 'uxPreviousHumanObservation'):
                    ux.wait_ready(1)

    def test_machine_receipt_tamper_detected(self):
        ux, gate, human = self.fixture()
        exclusive_json(ux.evidence / 'phase-0.human.json', human)
        exclusive_json(ux.control / 'gate-1.json', gate)
        (ux.evidence / 'phase-0.machine.json').write_text('{}\n')
        with self.assertRaisesRegex(RuntimeError, 'uxMachineReceiptChanged'):
            ux.wait_ready(1)

    def test_receipt_cannot_be_overwritten(self):
        ux, _, _ = self.fixture()
        original = (ux.evidence / 'phase-0.machine.json').read_bytes()
        with self.assertRaises(FileExistsError):
            ux.complete(0, {'replacement': True})
        self.assertEqual((ux.evidence / 'phase-0.machine.json').read_bytes(), original)

    def test_deadline_abort_and_controlled_stop_allow_finally_cleanup(self):
        for outcome in ('deadline', 'abort', 'signal'):
            with self.subTest(outcome=outcome):
                ux, _, _ = self.fixture()
                cleanup = []
                if outcome == 'deadline':
                    ux.deadline = utc_now() - datetime.timedelta(seconds=1)
                elif outcome == 'abort':
                    exclusive_json(ux.control / 'abort.json', {'reason': 'synthetic abort'})
                try:
                    with patch('ux_stages.time.sleep', side_effect=RuntimeError('controlledSignalStop:SIGTERM')):
                        with self.assertRaises(RuntimeError):
                            ux.wait_ready(1)
                finally:
                    cleanup.append('synthetic cleanup executed')
                self.assertEqual(cleanup, ['synthetic cleanup executed'])


if __name__ == '__main__':
    unittest.main()
