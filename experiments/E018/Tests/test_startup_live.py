import copy
import importlib.util
import json
import os
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("startup_live", Path(__file__).parents[1] / "scripts/startup_live.py")
LIVE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LIVE)


def machine(phase="first"):
    counts = {"configurationLoads": 1, "credentialLoads": 1, "refreshAttempts": 0,
              "refreshAccepted": 0, "saveAttempts": 0, "saves": 0}
    return {"schema": "e018.machine.v1", "phase": phase, "outcome": "ready", "failureKind": "none",
            "phasePassed": True, "prepare": counts.copy(), "final": counts.copy(),
            "initiallyExpired": False, "initialCredentialTag": "a" * 64,
            "finalCredentialTag": "a" * 64, "accountTag": "b" * 64,
            "apiAuthenticated": True, "completeReadback": True,
            "configurationUnchanged": True, "naturalRefreshObserved": False}


PROOF = {"binarySHA256": "1" * 64, "profileSHA256": "2" * 64, "sourceSHA256": "3" * 64}


class ControllerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        os.chmod(self.root, 0o700)

    def tearDown(self):
        self.temp.cleanup()

    def write(self, name, value):
        LIVE.exclusive(self.root / name, value)

    def seed_first(self, observed=True, digest_matches=True):
        self.write("first.machine.json", machine())
        self.write("first.public.json", {"passed": True})
        self.write("first.exit.json", {"terminated": True, "exitCode": 0})
        self.write("first.human.json", {"fullyObserved": observed, "promptCount": 0,
                   "machineSHA256": LIVE.digest(self.root / "first.machine.json") if digest_matches else "0" * 64})

    def test_projection_does_not_expose_private_tags_or_paths(self):
        public = LIVE.project(machine(), PROOF, "first")
        self.assertTrue(public["passed"])
        for key in ["initialCredentialTag", "finalCredentialTag", "accountTag", "executable", "group", "keyBase64"]:
            self.assertNotIn(key, public)

    def test_invalid_failure_string_never_passes_through(self):
        value = machine()
        value["failureKind"] = "SYNTHETIC_SECRET_MUST_NOT_ESCAPE"
        with self.assertRaises(LIVE.Failure):
            LIVE.project(value, PROOF, "first")

    def test_unknown_keys_are_rejected(self):
        value = machine()
        value["rawSecret"] = "SYNTHETIC_SECRET"
        with self.assertRaises(LIVE.Failure):
            LIVE.project(value, PROOF, "first")

    def test_boolean_counts_and_unbounded_counts_are_rejected(self):
        for bad in [True, -1, 17, "1"]:
            with self.subTest(bad=bad):
                value = machine()
                value["final"]["saves"] = bad
                with self.assertRaises(LIVE.Failure):
                    LIVE.project(value, PROOF, "first")

    def test_api_recovery_is_not_natural_expiry_evidence(self):
        value = machine()
        value["naturalRefreshObserved"] = True
        value["final"].update(refreshAttempts=1, refreshAccepted=1, saveAttempts=1, saves=1)
        with self.assertRaises(LIVE.Failure):
            LIVE.project(value, PROOF, "first")

    def test_private_proof_extra_is_rejected(self):
        with self.assertRaises(LIVE.Failure):
            LIVE.project(machine(), {**PROOF, "rawPrivatePath": "SYNTHETIC"}, "first")

    def test_fresh_requires_both_full_credential_and_account_match(self):
        for credential, account in [(True, False), (False, True), (None, None)]:
            self.assertFalse(LIVE.project(machine("fresh"), PROOF, "fresh",
                                         same_credential=credential, same_account=account)["passed"])
        self.assertTrue(LIVE.project(machine("fresh"), PROOF, "fresh",
                                    same_credential=True, same_account=True)["passed"])

    def test_machine_ready_without_api_or_readback_cannot_pass(self):
        for field in ["apiAuthenticated", "completeReadback", "configurationUnchanged"]:
            value = machine()
            value[field] = False
            self.assertFalse(LIVE.project(value, PROOF, "first")["passed"])

    def test_exclusive_attempt_remains_unchanged_on_replay(self):
        path = self.root / "first.attempt.json"
        LIVE.exclusive(path, {"consumed": True})
        original = path.read_bytes()
        with self.assertRaises(FileExistsError):
            LIVE.exclusive(path, {"consumed": False})
        self.assertEqual(path.read_bytes(), original)

    def test_symlink_control_is_rejected(self):
        self.write("real.json", {})
        (self.root / "link.json").symlink_to(self.root / "real.json")
        with self.assertRaises(LIVE.Failure):
            LIVE.read_json(self.root / "link.json")

    def test_fresh_without_complete_human_observation_is_rejected(self):
        self.seed_first(observed=False)
        with self.assertRaises(LIVE.Failure):
            LIVE.first_ready(self.root)

    def test_human_observation_must_bind_exact_machine_receipt(self):
        self.seed_first(digest_matches=False)
        with self.assertRaises(LIVE.Failure):
            LIVE.first_ready(self.root)

    def test_complete_first_permits_only_the_followup_stage(self):
        self.seed_first()
        self.assertEqual(LIVE.first_ready(self.root), machine())

    def test_preflight_failure_does_not_launch_or_consume_phase(self):
        with patch.object(LIVE, "preflight", side_effect=LIVE.Failure("sourceChanged")), \
                patch.object(LIVE.subprocess, "Popen") as popen:
            with self.assertRaises(LIVE.Failure):
                LIVE.launch(self.root, "first")
            popen.assert_not_called()
        self.assertFalse((self.root / "first.attempt.json").exists())

    def test_repeated_launch_never_reaches_popen(self):
        self.write("first.attempt.json", {"consumed": True})
        with patch.object(LIVE, "preflight", return_value=(PROOF, self.root)), \
                patch.object(LIVE.subprocess, "Popen") as popen:
            with self.assertRaises(FileExistsError):
                LIVE.launch(self.root, "first")
            popen.assert_not_called()

    def test_invalid_actual_process_never_gets_authorization(self):
        self.write("control.json", {"runID": "offline-run"})
        self.write("first.hello.json", {"runID": "offline-run", "phase": "first",
                                      "pid": "different-pid", "executable": "offline"})
        class FakeProcess:
            pid = 123
            returncode = None
            def poll(self): return self.returncode
            def terminate(self): self.returncode = -15
            def wait(self, timeout=None): return self.returncode
        with patch.object(LIVE, "preflight", return_value=(PROOF, self.root)), \
                patch.object(LIVE.subprocess, "Popen", return_value=FakeProcess()):
            with self.assertRaises(LIVE.Failure):
                LIVE.launch(self.root, "first")
        self.assertTrue((self.root / "first.attempt.json").exists())
        self.assertFalse((self.root / "first.authorize.json").exists())
        self.assertFalse(LIVE.read_json(self.root / "first.exit.json")["authorized"])


if __name__ == "__main__":
    unittest.main()
