"""Offline controls only. No Security, signing, app launch or provider calls."""
import argparse
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/pat_storage_probe.py"
SPEC = importlib.util.spec_from_file_location("pat_probe", SCRIPT)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class ProbeControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="rivet-pat-offline-")
        self.parent = Path(self.temp.name).resolve()
        self.repo = self.parent / "repo"
        self.repo.mkdir()
        for path in probe.SOURCES:
            target = self.repo / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("synthetic source")
        result = subprocess.CompletedProcess([], 0, stdout=b"a" * 40 + b"\n")
        with patch.object(probe, "command", return_value=result), contextlib.redirect_stdout(io.StringIO()):
            probe.prepare(argparse.Namespace(repo=str(self.repo), parent=str(self.parent), access_group="test.group"))
        self.root = next(self.parent.glob("rivet-pat-storage-*"))
        self.run = probe.read(self.root / "run.json")

    def tearDown(self):
        self.temp.cleanup()

    def machine(self, phase, outcome="completed"):
        probe.publish(self.root / (phase + ".host.json"), {
            "runID": self.run["runID"], "phase": phase, "outcome": outcome,
            "binarySHA256": "b" * 64, "buildVariant": "debug"})
        probe.publish(self.root / (phase + ".attempt.json"), {"phase": phase})
        if not (self.root / "build-debug.json").exists():
            probe.publish(self.root / "build-debug.json", {"variant": "debug"})
        machine = probe.read(self.root / (phase + ".host.json"))
        probe.publish(self.root / (phase + ".accepted.json"), probe.acceptance_binding(self.root, phase, machine))

    def observation(self, phase, count, whole=True):
        probe.publish(self.root / (phase + ".observation.json"), {
            "machineSHA256": probe.digest(self.root / (phase + ".host.json")),
            "promptCount": count, "wholeStageObserved": whole})

    def signing_fixture(self, app, expired=False, wrong_group=False, requirement_stream="stdout",
                        signed_claims=None, profile_claims=None):
        app.mkdir()
        (app / "Contents").mkdir()
        (app / "Contents/embedded.provisionprofile").write_bytes(b"synthetic-profile")
        defaults = {"keychain-access-groups": ["wrong" if wrong_group else "test.group"],
                    "com.apple.application-identifier": "TEAM.local.rivet.pat-storage-probe"}
        claims = dict(defaults) if signed_claims is None else signed_claims
        entitlements = dict(defaults) if profile_claims is None else profile_claims
        profile = {"ExpirationDate": probe.dt.datetime(2000 if expired else 2099, 1, 1),
                   "TeamIdentifier": ["TEAM"], "Entitlements": entitlements,
                   "DeveloperCertificates": [b"synthetic-certificate"]}

        def fake_command(argv, timeout=30):
            stdout, stderr = b"", b""
            if "--verbose=4" in argv:
                stderr = b"Identifier=local.rivet.pat-storage-probe\nTeamIdentifier=TEAM\n"
            elif "--entitlements" in argv:
                stdout = probe.plistlib.dumps(claims)
            elif argv[0] == "security":
                stdout = probe.plistlib.dumps(profile)
            elif any(arg.startswith("--extract-certificates=") for arg in argv):
                option = next(arg for arg in argv if arg.startswith("--extract-certificates="))
                prefix = option.split("=", 1)[1]
                Path(prefix + "0").write_bytes(b"synthetic-certificate")
            elif "-r-" in argv:
                stderr = ("Executable=" + str(app) + "\n").encode()
                requirement = b"designated => identifier signed-host\n"
                if requirement_stream == "stdout":
                    stdout = requirement
                else:
                    stderr += requirement
            return subprocess.CompletedProcess(argv, 0, stdout=stdout, stderr=stderr)
        return fake_command

    def test_signing_identity_ignores_copy_location_but_keeps_requirement(self):
        identities = []
        for name in ("built.app", "installed.app"):
            app = self.root / name
            with patch.object(probe, "command", side_effect=self.signing_fixture(app)):
                identities.append(probe.inspect(app, "test.group", self.root))
        self.assertEqual(identities[0], identities[1])
        self.assertEqual(identities[0]["requirement"], "designated => identifier signed-host")

    def test_certificate_extraction_uses_equals_flag_and_one_app_operand(self):
        app = self.root / "certificate-option.app"
        fake = self.signing_fixture(app)
        extractions = []

        def checked_command(argv, timeout=30):
            if any(arg.startswith("--extract-certificates") for arg in argv):
                extractions.append(argv)
                self.assertEqual(argv[:2], ["codesign", "-d"])
                self.assertEqual(len(argv), 4)
                self.assertTrue(argv[2].startswith("--extract-certificates="))
                self.assertEqual(argv[3], str(app))
            return fake(argv, timeout=timeout)

        with patch.object(probe, "command", side_effect=checked_command):
            identity = probe.inspect(app, "test.group", self.root)
        self.assertEqual(len(extractions), 1)
        self.assertEqual(identity["identifier"], "local.rivet.pat-storage-probe")

    def test_designated_requirement_is_read_from_stdout(self):
        app = self.root / "stdout.app"
        with patch.object(probe, "command", side_effect=self.signing_fixture(app)):
            identity = probe.inspect(app, "test.group", self.root)
        self.assertEqual(identity["requirement"], "designated => identifier signed-host")

    def test_stderr_only_designated_requirement_is_rejected(self):
        app = self.root / "stderr-only.app"
        fake = self.signing_fixture(app, requirement_stream="stderr")
        with patch.object(probe, "command", side_effect=fake):
            with self.assertRaises(probe.GuardError):
                probe.inspect(app, "test.group", self.root)

    def test_expired_profile_rejected_before_certificate_use(self):
        app = self.root / "expired.app"
        with patch.object(probe, "command", side_effect=self.signing_fixture(app, expired=True)):
            with self.assertRaises(probe.GuardError):
                probe.inspect(app, "test.group", self.root)

    def test_unexpected_entitled_group_rejected(self):
        app = self.root / "wrong.app"
        with patch.object(probe, "command", side_effect=self.signing_fixture(app, wrong_group=True)):
            with self.assertRaises(probe.GuardError):
                probe.inspect(app, "test.group", self.root)

    def test_profile_allows_exact_or_single_terminal_wildcard_prefix(self):
        for index, groups in enumerate((["test.group"], ["test.*"], ["wrong.*", "test.*"])):
            with self.subTest(groups=groups):
                app = self.root / ("profile-group-" + str(index) + ".app")
                profile_claims = {"keychain-access-groups": groups,
                                  "application-identifier": "TEAM.local.rivet.pat-storage-probe"}
                fake = self.signing_fixture(app, profile_claims=profile_claims)
                with patch.object(probe, "command", side_effect=fake):
                    self.assertEqual(probe.inspect(app, "test.group", self.root)["group"], "test.group")

    def test_profile_rejects_wrong_prefix_and_malformed_wildcards(self):
        for index, allowed in enumerate(("wrong.*", "test*", "*", "test*.*", "test.*.group", "test.**")):
            with self.subTest(allowed=allowed):
                app = self.root / ("bad-profile-group-" + str(index) + ".app")
                profile_claims = {"keychain-access-groups": [allowed],
                                  "com.apple.application-identifier": "TEAM.local.rivet.pat-storage-probe"}
                fake = self.signing_fixture(app, profile_claims=profile_claims)
                with patch.object(probe, "command", side_effect=fake):
                    with self.assertRaises(probe.GuardError):
                        probe.inspect(app, "test.group", self.root)

    def test_signed_groups_stay_exact_and_single(self):
        for index, groups in enumerate((["test.*"], ["test.group", "other.group"], [])):
            with self.subTest(groups=groups):
                app = self.root / ("bad-signed-group-" + str(index) + ".app")
                signed = {"keychain-access-groups": groups,
                          "application-identifier": "TEAM.local.rivet.pat-storage-probe"}
                profile_claims = {"keychain-access-groups": ["test.*"],
                                  "application-identifier": "TEAM.local.rivet.pat-storage-probe"}
                fake = self.signing_fixture(app, signed_claims=signed, profile_claims=profile_claims)
                with patch.object(probe, "command", side_effect=fake):
                    with self.assertRaises(probe.GuardError):
                        probe.inspect(app, "test.group", self.root)

    def test_caller_group_must_be_explicit_without_wildcard(self):
        for index, group in enumerate(("", " ", "test.*", None)):
            with self.subTest(group=group):
                app = self.root / ("bad-caller-group-" + str(index) + ".app")
                signed = {"keychain-access-groups": [group] if group is not None else [],
                          "com.apple.application-identifier": "TEAM.local.rivet.pat-storage-probe"}
                fake = self.signing_fixture(app, signed_claims=signed, profile_claims=signed)
                with patch.object(probe, "command", side_effect=fake):
                    with self.assertRaises(probe.GuardError):
                        probe.inspect(app, group, self.root)

    def test_application_identifier_canonical_fallback_and_equal_dual_keys(self):
        identifier = "TEAM.local.rivet.pat-storage-probe"
        variants = [{"com.apple.application-identifier": identifier},
                    {"application-identifier": identifier},
                    {"com.apple.application-identifier": identifier, "application-identifier": identifier}]
        for signed_index, signed_id in enumerate(variants):
            for profile_index, profile_id in enumerate(variants):
                with self.subTest(signed=signed_index, profile=profile_index):
                    app = self.root / ("id-" + str(signed_index) + "-" + str(profile_index) + ".app")
                    signed = dict(signed_id, **{"keychain-access-groups": ["test.group"]})
                    profile_claims = dict(profile_id, **{"keychain-access-groups": ["test.group"]})
                    fake = self.signing_fixture(app, signed_claims=signed, profile_claims=profile_claims)
                    with patch.object(probe, "command", side_effect=fake):
                        identity = probe.inspect(app, "test.group", self.root)
                    self.assertEqual(identity["identifier"], "local.rivet.pat-storage-probe")

    def test_invalid_application_identifiers_rejected_on_either_side(self):
        identifier = "TEAM.local.rivet.pat-storage-probe"
        variants = [{}, {"com.apple.application-identifier": ""}, {"application-identifier": ""},
                    {"com.apple.application-identifier": 17}, {"application-identifier": 17},
                    {"com.apple.application-identifier": identifier, "application-identifier": "OTHER.wrong"},
                    {"com.apple.application-identifier": "TEAM.wrong-app"},
                    {"application-identifier": "TEAM.*"}]
        valid = {"keychain-access-groups": ["test.group"], "com.apple.application-identifier": identifier}
        for side in ("signed", "profile"):
            for index, invalid_id in enumerate(variants):
                with self.subTest(side=side, index=index):
                    app = self.root / ("invalid-id-" + side + "-" + str(index) + ".app")
                    invalid = dict(invalid_id, **{"keychain-access-groups": ["test.group"]})
                    fake = self.signing_fixture(app, signed_claims=invalid if side == "signed" else valid,
                                                profile_claims=invalid if side == "profile" else valid)
                    with patch.object(probe, "command", side_effect=fake):
                        with self.assertRaises(probe.GuardError):
                            probe.inspect(app, "test.group", self.root)

    def test_both_missing_or_same_wrong_application_identifier_rejected(self):
        for index, identifier in enumerate((None, "TEAM.wrong-app", "TEAM.*")):
            with self.subTest(identifier=identifier):
                app = self.root / ("both-invalid-id-" + str(index) + ".app")
                claims = {"keychain-access-groups": ["test.group"]}
                if identifier is not None:
                    claims["application-identifier"] = identifier
                fake = self.signing_fixture(app, signed_claims=claims, profile_claims=claims)
                with patch.object(probe, "command", side_effect=fake):
                    with self.assertRaises(probe.GuardError):
                        probe.inspect(app, "test.group", self.root)

    def launch_fixture(self, mutation=None):
        app = self.root / "current/PATStorageProbe.app"
        (app / "Contents/MacOS").mkdir(parents=True)
        binary = app / "Contents/MacOS/PATStorageProbe"
        binary.write_bytes(b"synthetic executable")
        identity = {"identity": "controlled"}
        probe.publish(self.root / "identity.json", identity)
        probe.publish(self.root / "build-debug.json", {"binarySHA256": probe.digest(binary), "variant": "debug"})
        machine = {"runID": self.run["runID"], "phase": "save-a", "outcome": "completed",
                   "binarySHA256": probe.digest(binary), "buildVariant": "debug",
                   "processInstance": "fresh", "processID": 100,
                   "processStartSeconds": 200, "processStartMicroseconds": 3}
        if mutation == "binary":
            machine["binarySHA256"] = "f" * 64
        if mutation == "variant":
            machine["buildVariant"] = "rebuilt"
        if mutation == "same-process":
            previous = dict(machine, phase="read-a", processInstance="different-random-id")
            probe.publish(self.root / "read-a.host.json", previous)

        def child(argv, timeout=30):
            self.assertEqual(argv[0], "open")
            probe.publish(self.root / "save-a.host.json", machine)
            if mutation == "timeout":
                raise subprocess.TimeoutExpired(argv, timeout)
            return subprocess.CompletedProcess(argv, 0, stdout=b"", stderr=b"")
        return identity, child

    def test_launch_acceptance_requires_all_post_host_guards(self):
        # A raw completed host receipt plus truthful Human prompts cannot bypass a rejected launch.
        for mutation in ("binary", "variant", "same-process", "timeout"):
            with self.subTest(mutation=mutation):
                case = ProbeControls()
                case.setUp()
                try:
                    identity, child = case.launch_fixture(mutation)
                    with patch.object(probe, "inspect", return_value=identity), \
                         patch.object(probe, "no_active_host"), \
                         patch.object(probe, "command", side_effect=child):
                        with case.assertRaises((probe.GuardError, subprocess.TimeoutExpired)):
                            probe.launch(argparse.Namespace(root=str(case.root), phase="save-a", human_ready=True))
                    case.observation("save-a", 0)
                    with case.assertRaises(probe.GuardError):
                        probe.observed(case.root, "save-a")
                    case.assertFalse((case.root / "save-a.accepted.json").exists())
                    destination = case.root / "public.json"
                    with contextlib.redirect_stdout(io.StringIO()):
                        probe.export(argparse.Namespace(root=str(case.root), destination=str(destination)))
                    phase = probe.read(destination)["phases"]["save-a"]
                    case.assertEqual(phase["hostOutcome"], "completed")
                    case.assertEqual(phase["outcome"], "unknown")
                    case.assertFalse(phase["runnerAccepted"])
                finally:
                    case.tearDown()

    def test_valid_launch_durably_accepts_then_observation_allows_advance(self):
        identity, child = self.launch_fixture()
        with patch.object(probe, "inspect", return_value=identity), \
             patch.object(probe, "no_active_host"), \
             patch.object(probe, "command", side_effect=child), \
             contextlib.redirect_stdout(io.StringIO()):
            probe.launch(argparse.Namespace(root=str(self.root), phase="save-a", human_ready=True))
        self.observation("save-a", 0)
        probe.observed(self.root, "save-a")
        proof = probe.read(self.root / "save-a.accepted.json")
        self.assertEqual(proof["attemptSHA256"], probe.digest(self.root / "save-a.attempt.json"))
        self.assertEqual(proof["buildProofSHA256"], probe.digest(self.root / "build-debug.json"))

    def test_changed_build_proof_invalidates_acceptance(self):
        self.machine("save-a")
        self.observation("save-a", 0)
        (self.root / "build-debug.json").write_text('{"changed":true}')
        with self.assertRaises(probe.GuardError):
            probe.observed(self.root, "save-a")

    def test_prepare_and_context_bind_source_and_unique_namespace(self):
        _, run, repo, _ = probe.context(self.root)
        self.assertEqual(repo, self.repo)
        self.assertEqual(run["service"], "local.rivet.github.pat.validation." + run["runID"])
        self.assertEqual(self.root.stat().st_mode & 0o777, 0o700)
        self.assertEqual((self.root / "run.json").stat().st_mode & 0o777, 0o600)

    def test_changed_source_is_rejected(self):
        (self.repo / probe.SOURCES[0]).write_text("changed")
        with self.assertRaises(probe.GuardError):
            probe.context(self.root)

    def test_existing_receipt_cannot_be_overwritten(self):
        self.machine("save-a")
        with self.assertRaises(FileExistsError):
            self.machine("save-a", "failed")
        self.assertEqual(probe.read(self.root / "save-a.host.json")["outcome"], "completed")

    def test_symlink_and_wrong_mode_rejected(self):
        path = self.root / "run.json"
        link = self.root / "link.json"
        link.symlink_to(path)
        with self.assertRaises(probe.GuardError):
            probe.read(link)
        path.chmod(0o644)
        with self.assertRaises(probe.GuardError):
            probe.read(path)

    def test_no_readiness_means_zero_subprocess_calls(self):
        with patch.object(probe, "command") as command:
            for action in (probe.build, probe.launch):
                with self.assertRaises(probe.GuardError):
                    action(argparse.Namespace(human_ready=False))
            command.assert_not_called()

    def test_runtime_thresholds_require_whole_human_observation(self):
        for phase in probe.PHASES:
            self.machine(phase)
            self.observation(phase, probe.LIMITS[phase] if probe.LIMITS[phase] is not None else 3)
            probe.observed(self.root, phase)
        self.assertEqual(probe.LIMITS["replace-b"], 0)

    def test_unknown_observation_cannot_advance(self):
        self.machine("save-a")
        self.observation("save-a", None, False)
        with self.assertRaises(probe.GuardError):
            probe.observed(self.root, "save-a")

    def test_boolean_prompt_count_is_rejected(self):
        self.machine("read-a")
        self.observation("read-a", True)
        with self.assertRaises(probe.GuardError):
            probe.observed(self.root, "read-a")

    def test_prompt_over_limit_is_rejected(self):
        self.machine("replace-b")
        self.observation("replace-b", 1)
        with self.assertRaises(probe.GuardError):
            probe.observed(self.root, "replace-b")

    def test_machine_failure_cannot_advance(self):
        self.machine("save-a", "failed")
        self.observation("save-a", 0)
        with self.assertRaises(probe.GuardError):
            probe.observed(self.root, "save-a")

    def test_changed_machine_receipt_invalidates_observation(self):
        self.machine("save-a")
        self.observation("save-a", 0)
        path = self.root / "save-a.host.json"
        path.write_text(json.dumps({"outcome": "failed"}))
        with self.assertRaises(probe.GuardError):
            probe.observed(self.root, "save-a")

    def test_attempt_without_receipt_exports_unknown(self):
        probe.publish(self.root / "save-a.attempt.json", {"phase": "save-a"})
        destination = self.root / "unknown.json"
        with contextlib.redirect_stdout(io.StringIO()):
            probe.export(argparse.Namespace(root=str(self.root), destination=str(destination)))
        self.assertEqual(probe.read(destination)["phases"]["save-a"]["outcome"], "unknown")

    def test_unbound_observation_not_exported_as_human_success(self):
        self.machine("save-a")
        probe.publish(self.root / "save-a.observation.json", {
            "machineSHA256": "wrong", "promptCount": 0, "wholeStageObserved": True})
        destination = self.root / "unbound.json"
        with contextlib.redirect_stdout(io.StringIO()):
            probe.export(argparse.Namespace(root=str(self.root), destination=str(destination)))
        phase = probe.read(destination)["phases"]["save-a"]
        self.assertFalse(phase["observationBound"])
        self.assertFalse(phase["wholeStageObserved"])
        self.assertIsNone(phase["promptCount"])

    def test_export_is_finite_and_preserves_not_executed(self):
        self.machine("save-a")
        destination = self.root / "public.json"
        with contextlib.redirect_stdout(io.StringIO()):
            probe.export(argparse.Namespace(root=str(self.root), destination=str(destination)))
        result = probe.read(destination)
        text = destination.read_text()
        self.assertNotIn("test.group", text)
        self.assertNotIn(str(self.repo), text)
        self.assertNotIn("processID", text)
        self.assertIsNone(result["phases"]["save-a"]["promptCount"])
        self.assertEqual(result["phases"]["cleanup"]["outcome"], "notExecuted")


if __name__ == "__main__":
    unittest.main()
