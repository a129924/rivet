"""Pure E007 controls; never invokes Security, signing, provisioning or App launch."""
import copy
import datetime as dt
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import subprocess
import unittest
import uuid
from types import SimpleNamespace
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/run_profile_renewal.py"
spec = importlib.util.spec_from_file_location("renewal", SCRIPT)
renewal = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renewal)


class ProtocolTests(unittest.TestCase):
    def setUp(self):
        self.start = dt.datetime(2026, 10, 19, 9, tzinfo=dt.timezone.utc)
        self.namespace = str(uuid.uuid4())
        self.window = renewal.make_window(self.namespace, self.start, "Human fresh ready", "same free Personal Team")
        self.first = {
            "bundleID": "local.rivet.renewalprobe." + self.namespace.replace("-", ""),
            "group": "TEAM.local.rivet.renewalprobe." + self.namespace.replace("-", ""),
            "certificateSHA256": "a" * 64, "profileSHA256": "b" * 64,
            "requirementSHA256": "c" * 64, "executableSHA256": "d" * 64,
            "expiresUTC": (self.start + dt.timedelta(days=1)).isoformat(),
            "certificateExpiresUTC": (self.start + dt.timedelta(days=1)).isoformat(),
            "signatureValid": True, "developmentIdentity": True,
            "profileAuthorizesGroup": True, "profileContainsDevice": True,
            "sandboxEnabled": False, "debugDylibPresent": False,
        }
        self.updated = dict(self.first, profileSHA256="e" * 64)

    def test_window_is_one_setup_inclusive_45_minute_window(self):
        renewal.validate_window(self.window, self.start, measurement=True)
        self.assertEqual(renewal.timestamp(self.window["cutoffUTC"]) - self.start, dt.timedelta(minutes=35))
        self.assertEqual(renewal.timestamp(self.window["deadlineUTC"]) - self.start, dt.timedelta(minutes=45))

    def test_cutoff_forbids_measurement_but_cleanup_is_still_allowed(self):
        late = self.start + dt.timedelta(minutes=36)
        with self.assertRaises(renewal.Rejected):
            renewal.validate_window(self.window, late, measurement=True)
        renewal.validate_window(self.window, late, measurement=False)
        renewal.validate_window(self.window, self.start + dt.timedelta(minutes=46), measurement=False)

    def test_window_cannot_be_reset_or_forged(self):
        for key in ("cutoffUTC", "deadlineUTC"):
            altered = dict(self.window)
            altered[key] = (renewal.timestamp(altered[key]) + dt.timedelta(seconds=1)).isoformat()
            with self.assertRaises(renewal.Rejected):
                renewal.validate_window(altered, self.start, measurement=True)
        with self.assertRaises(renewal.Rejected):
            renewal.make_window(self.namespace, self.start, "", "free")

    def test_same_profile_is_not_renewal(self):
        with self.assertRaises(renewal.Rejected):
            renewal.validate_pair(self.first, self.first, self.window)
        renewal.validate_pair(self.first, self.updated, self.window)

    def test_same_binary_with_genuine_new_profile_is_allowed(self):
        self.assertEqual(self.first["executableSHA256"], self.updated["executableSHA256"])
        renewal.validate_pair(self.first, self.updated, self.window)

    def test_app_group_certificate_and_requirement_cannot_change(self):
        for key in ("bundleID", "group", "certificateSHA256", "requirementSHA256"):
            altered = dict(self.updated, **{key: "other"})
            with self.assertRaises(renewal.Rejected):
                renewal.validate_pair(self.first, altered, self.window)

    def test_signing_profile_device_and_host_conditions_are_required(self):
        for key in ("signatureValid", "developmentIdentity", "profileAuthorizesGroup", "profileContainsDevice"):
            with self.assertRaises(renewal.Rejected):
                renewal.validate_pair(self.first, dict(self.updated, **{key: False}), self.window)
        for key in ("sandboxEnabled", "debugDylibPresent"):
            with self.assertRaises(renewal.Rejected):
                renewal.validate_pair(self.first, dict(self.updated, **{key: True}), self.window)
        for key in ("expiresUTC", "certificateExpiresUTC"):
            altered = dict(self.updated, **{key: (self.start + dt.timedelta(minutes=44)).isoformat()})
            with self.assertRaises(renewal.Rejected):
                renewal.validate_pair(self.first, altered, self.window)

    def observation(self, count=0):
        return {"namespace": self.namespace, "phase": 1, "machineReceiptSHA256": "f" * 64,
                "wholeStageObserved": True, "promptCount": count,
                "actions": ["allowed"] * count, "purposes": ["credential access"] * count}

    def test_human_observation_is_bound_to_phase_and_exact_machine_bytes(self):
        renewal.validate_observation(self.observation(), self.namespace, 1, "f" * 64)
        for key, value in (("namespace", "other"), ("phase", 2), ("wholeStageObserved", False),
                           ("machineReceiptSHA256", "0" * 64), ("promptCount", True)):
            with self.assertRaises(renewal.Rejected):
                renewal.validate_observation(dict(self.observation(), **{key: value}), self.namespace, 1, "f" * 64)

    def test_outcome_distinguishes_negative_result_and_missing_evidence(self):
        self.assertEqual(renewal.classify(True, True, self.observation(0), True), "成功")
        self.assertEqual(renewal.classify(True, True, self.observation(1), True), "失敗")
        self.assertEqual(renewal.classify(True, False, self.observation(0), True), "失敗")
        self.assertEqual(renewal.classify(False, True, self.observation(0), True), "無法判定")
        self.assertEqual(renewal.classify(True, True, None, True), "無法判定")
        self.assertEqual(renewal.classify(True, True, self.observation(0), False), "無法判定")

    def test_public_receipt_drops_paths_identifiers_payload_and_underlying_errors(self):
        raw = {"phase": 1, "completed": True, "promptCount": None,
               "profileSHA256": "b" * 64, "token": "PRIVATE", "secret": "PRIVATE",
               "path": "/private/example", "accessGroup": "PRIVATE", "rawError": "PRIVATE", "error": "PRIVATE"}
        out = renewal.public_receipt(raw)
        self.assertEqual(out, {"phase": 1, "completed": True, "promptCount": None, "profileSHA256": "b" * 64, "error": "guardRejected"})
        self.assertNotIn("PRIVATE", json.dumps(out))

    def test_private_run_root_and_exclusive_receipts(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / ("rivet-E007-" + self.namespace)
            root.mkdir(mode=0o700)
            renewal.private_root(root, self.namespace)
            receipt = root / "receipt.json"
            renewal.exclusive_json(receipt, {"completed": True})
            with self.assertRaises(renewal.Rejected):
                renewal.exclusive_json(receipt, {"completed": False})
            root.chmod(0o755)
            with self.assertRaises(renewal.Rejected):
                renewal.private_root(root, self.namespace)

    def test_symlink_receipt_is_never_followed(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            target.write_text("untouched")
            link = Path(temp) / "receipt.json"
            link.symlink_to(target)
            with self.assertRaises(renewal.Rejected):
                renewal.exclusive_json(link, {"completed": False})
            self.assertEqual(target.read_text(), "untouched")


    def test_begin_requires_live_and_does_not_create_run_without_it(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / ("rivet-E007-" + self.namespace)
            args = SimpleNamespace(root=root, namespace=self.namespace, live=False,
                                   human_ready="fresh", free_personal_team="free")
            with self.assertRaises(renewal.Rejected):
                renewal.begin(args)
            self.assertFalse(root.exists())

    def make_run(self, root):
        root.mkdir(mode=0o700)
        (root / "private").mkdir()
        (root / "receipts").mkdir()
        renewal.exclusive_json(root / "window.json", self.window)
        renewal.exclusive_json(root / "private/first.json", self.first)
        renewal.exclusive_json(root / "private/updated.json", self.updated)
        for phase in (1, 2, 3):
            name = "cleanup" if phase == 3 else f"phase-{phase}"
            proof = self.updated if phase == 2 else self.first
            machine = root / "receipts" / (name + ".machine.json")
            renewal.exclusive_json(machine, {"namespace": self.namespace, "phase": phase,
                "synthetic": False, "observationMode": "human-only", "promptCount": None,
                "profileSHA256": proof["profileSHA256"], "executableSHA256": proof["executableSHA256"],
                "windowSHA256": renewal.digest(root / "window.json"),
                "startedUTC": (self.start + dt.timedelta(minutes=5)).isoformat(),
                "endedUTC": (self.start + dt.timedelta(minutes=10)).isoformat(),
                "completed": True, "absent": True, "readAttempted": True,
                "fields": dict.fromkeys(renewal.FIELDS, True)})
            human = dict(self.observation(), phase=phase, machineReceiptSHA256=renewal.digest(machine),
                         statement="PRIVATE-SECRET /private/human/profile")
            renewal.exclusive_json(root / "receipts" / (name + ".human.json"), human)

    def rewrite_machine_and_rebind_human(self, root, changes):
        machine_path = root / "receipts/phase-2.machine.json"
        machine = json.loads(machine_path.read_text())
        machine.update(changes)
        if machine.get("completed") is False:
            machine.pop("fields", None)
        machine_path.write_text(json.dumps(machine))
        human_path = root / "receipts/phase-2.human.json"
        human = json.loads(human_path.read_text())
        human["machineReceiptSHA256"] = renewal.digest(machine_path)
        human_path.write_text(json.dumps(human))

    def outcome(self, changes=None, invalid_human=False):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / ("rivet-E007-" + self.namespace)
            self.make_run(root)
            if changes:
                self.rewrite_machine_and_rebind_human(root, changes)
            if invalid_human:
                path = root / "receipts/phase-2.human.json"
                human = json.loads(path.read_text())
                human["machineReceiptSHA256"] = "0" * 64
                path.write_text(json.dumps(human))
            with mock.patch("builtins.print"):
                renewal.finalize(SimpleNamespace(root=root, namespace=self.namespace))
            return json.loads((root / "receipts/outcome.json").read_text())["result"]

    def test_invalid_human_sha_cannot_be_classified_success(self):
        self.assertEqual(self.outcome(invalid_human=True), "無法判定")

    def test_valid_read_and_observation_can_be_classified_success(self):
        self.assertEqual(self.outcome(), "成功")

    def test_guard_or_technical_failure_before_valid_read_is_indeterminate(self):
        for changes in (
                {"completed": False, "readAttempted": False, "error": "guardRejected"},
                {"completed": False, "readAttempted": True, "error": "interactionUnavailable"},
                {"completed": False, "readAttempted": True, "error": "securityFailure"}):
            self.assertEqual(self.outcome(changes), "無法判定")

    def test_invalid_machine_identity_or_shape_is_indeterminate(self):
        for changes in (
                {"namespace": "other"}, {"phase": 1}, {"windowSHA256": "0" * 64},
                {"profileSHA256": "0" * 64}, {"readAttempted": False},
                {"completed": True, "fields": {}}):
            self.assertEqual(self.outcome(changes), "無法判定")

    def test_actual_read_rejection_and_mismatch_are_failures(self):
        for error in ("accessDenied", "missing", "invalidData", "comparison"):
            self.assertEqual(self.outcome({"completed": False, "readAttempted": True, "error": error, "status": -25293}), "失敗")

    def test_public_human_projection_preserves_counts_and_machine_binding_only(self):
        human = dict(self.observation(1), statement="PRIVATE-SECRET",
                     actions=["PRIVATE-SECRET /private/action"], purposes=["PRIVATE-SECRET profile ID"])
        result = renewal.public_observation(human, "a" * 64)
        text = json.dumps(result)
        self.assertNotIn("PRIVATE-SECRET", text)
        self.assertNotIn("/private/", text)
        self.assertNotIn("statement", result)
        self.assertEqual(result["machineReceiptSHA256"], human["machineReceiptSHA256"])
        self.assertEqual(result["privateObservationSHA256"], "a" * 64)
        self.assertEqual(result["promptCount"], 1)
        self.assertEqual(result["actions"], ["other"])
        self.assertEqual(result["purposes"], ["other"])

    def test_export_does_not_copy_human_free_text_to_repository(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / ("rivet-E007-" + self.namespace)
            self.make_run(root)
            renewal.exclusive_json(root / "private/permit-1.json", {"mayHaveWritten": True})
            # The export test exercises projection, independently of read-outcome validation.
            for name in ("phase-1", "phase-2", "cleanup"):
                path = root / "receipts" / (name + ".machine.json")
                value = json.loads(path.read_text())
                value.pop("readAttempted", None)
                path.write_text(json.dumps(value))
                human_path = root / "receipts" / (name + ".human.json")
                human = json.loads(human_path.read_text())
                human["machineReceiptSHA256"] = renewal.digest(path)
                human_path.write_text(json.dumps(human))
            fake_source = Path(temp) / "fake-E007-source"
            for relative in ("Sources/ProfileRenewalProbe.swift", "scripts/run_profile_renewal.py",
                             "ProfileRenewalProbe.xcodeproj/project.pbxproj",
                             "Resources/Info.plist", "Resources/ProfileRenewalProbe.entitlements"):
                path = fake_source / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("synthetic fixture")
            with mock.patch.object(renewal, "SOURCE", fake_source), mock.patch("builtins.print"):
                renewal.export_clean(SimpleNamespace(root=root, namespace=self.namespace,
                                                    human_project_closed="closed"))
            outputs = list((fake_source / "evidence").rglob("*.json"))
            self.assertTrue(outputs)
            for path in outputs:
                self.assertNotIn("PRIVATE-SECRET", path.read_text())
                self.assertNotIn("/private/human/profile", path.read_text())
            self.assertFalse(root.exists())

    def test_export_requires_credential_cleanup_after_any_possible_write(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / ("rivet-E007-" + self.namespace)
            root.mkdir(mode=0o700)
            (root / "private").mkdir()
            renewal.exclusive_json(root / "window.json", self.window)
            renewal.exclusive_json(root / "private/permit-1.json", {"mayHaveWritten": True})
            with self.assertRaises(renewal.Rejected):
                renewal.export_clean(SimpleNamespace(root=root, namespace=self.namespace,
                                                    human_project_closed="closed"))
            self.assertTrue(root.is_dir())


class SwiftCoreTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="rivet-E007-pure-")
        cls.binary = Path(cls.temporary.name) / "probe-core-tests"
        harness = Path(cls.temporary.name) / "Harness.swift"
        harness.write_text(r"""
import Foundation

final class MemoryStore: ProbeStore {
  var value: Data?
  var adds = 0
  var deletes = 0
  func add(_ data: Data) throws { adds += 1; value = data }
  func load() throws -> Data? { value }
  func delete() throws { deletes += 1; value = nil }
}

@main enum Tests {
  static func main() throws {
    let store = MemoryStore()
    let core = ProbeCore(store: store)
    switch CommandLine.arguments[1] {
    case "roundtrip":
      let a = try core.perform(phase: 1)
      let b = try core.perform(phase: 2)
      guard let first = a["fields"] as? [String: Bool],
        let second = b["fields"] as? [String: Bool],
        first.count == 6, first.values.allSatisfy({ $0 }), first == second,
        store.adds == 1 else { fatalError("roundtrip") }
    case "readonly":
      _ = try core.perform(phase: 1)
      let previous = store.value
      _ = try core.perform(phase: 2)
      guard store.value == previous, store.adds == 1, store.deletes == 0 else {
        fatalError("readonly")
      }
    case "cleanup":
      _ = try core.perform(phase: 1)
      let result = try core.perform(phase: 3)
      guard result["absent"] as? Bool == true, store.value == nil, store.deletes == 1 else {
        fatalError("cleanup")
      }
    case "corrupt":
      store.value = Data("{}".utf8)
      do { _ = try core.perform(phase: 2); fatalError("accepted corrupt") }
      catch ProbeFailure.invalidData {}
      guard store.adds == 0, store.deletes == 0 else { fatalError("mutated corrupt") }
    case "redaction":
      for text in [String(describing: FakeBundle.fixture), String(reflecting: FakeBundle.fixture),
                   Mirror(reflecting: FakeBundle.fixture).children.map { String(describing: $0.value) }.joined()] {
        guard !text.contains("fake-E007"), text.contains("redacted") else { fatalError("redaction") }
      }
    case "marker":
      guard !core.readAttempted else { fatalError("marker starts true") }
      do { _ = try core.perform(phase: 4); fatalError("accepted phase") }
      catch ProbeFailure.guardRejected {}
      guard !core.readAttempted else { fatalError("guard marked as read") }
      do { _ = try core.perform(phase: 2); fatalError("accepted missing") }
      catch ProbeFailure.missing {}
      guard core.readAttempted, store.adds == 0, store.deletes == 0 else { fatalError("read marker") }
    case "time":
      let start = Date(timeIntervalSince1970: 2_000_000_000)
      let cutoff = start.addingTimeInterval(2100)
      let deadline = start.addingTimeInterval(2700)
      do {
        try ProbeFiles.validateTime(start: start, cutoff: cutoff, deadline: deadline,
                                    now: cutoff, phase: 2)
        fatalError("cutoff accepted")
      } catch ProbeFailure.guardRejected {}
      try ProbeFiles.validateTime(start: start, cutoff: cutoff, deadline: deadline,
                                  now: deadline.addingTimeInterval(60), phase: 3)
    default: fatalError("unknown test")
    }
    print("ok")
  }
}
""")
        source = SCRIPT.parents[1] / "Sources/ProfileRenewalProbe.swift"
        result = subprocess.run(["/usr/bin/xcrun", "swiftc", "-swift-version", "6",
                                 "-D", "E007_TESTING", "-module-cache-path",
                                 str(Path(cls.temporary.name) / "module-cache"),
                                 str(source), str(harness), "-o", str(cls.binary)],
                                capture_output=True, text=True, timeout=120)
        if result.returncode:
            cls.temporary.cleanup()
            raise RuntimeError("Swift pure harness compilation failed:\n" + result.stderr)

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def check_case(self, name):
        result = subprocess.run([str(self.binary), name], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "ok")

    def test_swift_six_field_roundtrip(self):
        self.check_case("roundtrip")

    def test_swift_renewal_read_never_writes(self):
        self.check_case("readonly")

    def test_swift_exact_cleanup_and_read_absent(self):
        self.check_case("cleanup")

    def test_swift_corrupt_data_does_not_mutate(self):
        self.check_case("corrupt")

    def test_swift_description_debug_and_reflection_are_redacted(self):
        self.check_case("redaction")

    def test_swift_marker_distinguishes_guard_from_actual_read(self):
        self.check_case("marker")

    def test_swift_measurement_cutoff_and_late_cleanup(self):
        self.check_case("time")


if __name__ == "__main__":
    unittest.main()
