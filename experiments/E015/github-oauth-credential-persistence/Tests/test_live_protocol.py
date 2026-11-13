"""Pure controls only: never signs, launches an App, provisions, or accesses Security."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
import uuid

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/credential_storage_live.py"
spec = importlib.util.spec_from_file_location("live", SCRIPT)
live = importlib.util.module_from_spec(spec)
spec.loader.exec_module(live)
RAW_PRIVATE_COMMAND = live.private_command


class Controls(unittest.TestCase):
    def setUp(self):
        self.run = str(uuid.uuid4())
        self.machine = {"schemaVersion": 1, "runUUID": self.run, "phase": "save-a",
                        "status": "success", "freshProcess": True, "previousTerminated": True,
                        "sameSource": True, "sameIdentity": True, "sameLocation": True,
                        "validity": True, "absenceConfirmed": True, "writeAttempted": True,
                        "comparison": {key: True for key in live.FIELDS}}
        self.sha = "a" * 64

    def _ownership_fixture(self, temporary):
        formal = (
            "Package.swift",
            "Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift",
            "Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift",
            "Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift",
        )
        projects = (
            "CredentialStorageProbe.xcodeproj/project.pbxproj",
            "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme",
            "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme",
            "Sources/main.swift",
            "Resources/Info.plist",
            "Resources/CredentialStorageProbe.entitlements",
        )
        bindings = projects + (
            "scripts/credential_storage_live.py", "Tests/test_live_protocol.py", "README.md",
        )
        self.assertEqual(live.SOURCE_FILES, formal)
        self.assertEqual(live.PROJECT_FILES, projects)
        self.assertEqual(live.BINDING_SOURCES, bindings)
        root = Path(temporary).resolve()
        repo, parent = root / "repository", root / "caller"
        repo.mkdir(mode=0o700)
        parent.mkdir(mode=0o700)
        template = Path("experiments/E015/github-oauth-credential-persistence")

        def write(path, data):
            path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(descriptor, "wb") as stream:
                stream.write(data)

        original = {}
        relatives = tuple(Path(name) for name in formal) + tuple(template / name for name in bindings)
        for index, relative in enumerate(relatives):
            data = ("synthetic-source-" + str(index) + ":" + str(relative) + "\n").encode()
            if relative == template / projects[0]:
                data = (b'ROOT = { relativePath = "../../.."; };\n'
                        b'KEEP = { relativePath = "fixture/unchanged"; };\n')
            path = repo / relative
            write(path, data)
            original[path] = data
        self.assertFalse((repo / "validation/github-oauth-credential-persistence").exists())
        return {"repo": repo, "parent": parent, "template": template, "original": original,
                "formal": formal, "projects": projects, "bindings": bindings, "write": write}

    def _ownership_assert_copy(self, fixture, project):
        import re
        raw = (project / fixture["projects"][0]).read_bytes()
        root = re.search(rb'^ROOT = \{ relativePath = (".*"); \};$', raw, re.MULTILINE)
        self.assertIsNotNone(root)
        self.assertEqual(json.loads(root.group(1)), str(fixture["repo"]))
        self.assertEqual(raw.splitlines(),
                         [b"ROOT = { relativePath = " + json.dumps(str(fixture["repo"])).encode() + b"; };",
                          b'KEEP = { relativePath = "fixture/unchanged"; };'])
        for leaf in fixture["projects"][1:]:
            self.assertEqual((project / leaf).read_bytes(),
                             fixture["original"][fixture["repo"] / fixture["template"] / leaf])

    def test_ownership_prepare_uses_relocated_template(self):
        import hashlib
        from contextlib import ExitStack
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self._ownership_fixture(temporary)
            with ExitStack() as stack:
                guards = [
                    stack.enter_context(patch.object(owner, name,
                                                     side_effect=AssertionError("external operation")))
                    for owner, name in (
                        (live, "private_command"), (live, "profile_data"),
                        (live, "build_selected"), (live, "private_revision"),
                        (live.subprocess, "run"), (live.subprocess, "Popen"),
                    )
                ]
                result = live.prepare(fixture["repo"], fixture["parent"], self.run)
            self.assertEqual(result, {"runUUID": self.run, "status": "prepared"})
            root = fixture["parent"] / ("rivet-credential-storage-" + self.run)
            self._ownership_assert_copy(fixture, root / "project")
            manifest = json.loads((root / "run.json").read_text())
            self.assertEqual(manifest["sources"], {
                str(fixture["repo"] / name):
                    hashlib.sha256(fixture["original"][fixture["repo"] / name]).hexdigest()
                for name in fixture["formal"]
            })
            self.assertEqual(manifest["copiedSources"], {
                str(root / "project" / leaf):
                    hashlib.sha256(fixture["original"][fixture["repo"] / fixture["template"] / leaf]).hexdigest()
                for leaf in fixture["projects"][1:]
            })
            self.assertEqual(manifest["templateProjectSHA256"],
                             hashlib.sha256(fixture["original"][
                                 fixture["repo"] / fixture["template"] / fixture["projects"][0]]).hexdigest())
            for path, data in fixture["original"].items():
                self.assertEqual(path.read_bytes(), data)
            for guard in guards:
                guard.assert_not_called()

    def test_ownership_dpk_prepare_copies_then_stops_before_build(self):
        from collections import Counter
        from contextlib import ExitStack
        from unittest.mock import call, patch

        class StopBeforeBuild(Exception):
            pass

        with tempfile.TemporaryDirectory() as temporary:
            fixture = self._ownership_fixture(temporary)
            profile = fixture["parent"] / "profile-acquisition-1/profile.provisionprofile"
            config = fixture["parent"] / "config-report-timeout-amendment-1.json"
            fixture["write"](profile, b"FAKE_ONLY_NOT_A_PROFILE")
            fixture["write"](config, json.dumps({"repo": str(fixture["repo"])}).encode())
            allowed = {fixture["repo"] / fixture["template"] / leaf for leaf in fixture["bindings"]}
            reads = []
            real_read, real_load = Path.read_bytes, live.load
            sentinel = StopBeforeBuild()

            def checked_read(path):
                self.assertIn(Path(path), allowed)
                reads.append(Path(path))
                return real_read(path)

            def checked_load(path):
                self.assertEqual(Path(path), config)
                return real_load(path)

            with ExitStack() as stack:
                guards = [
                    stack.enter_context(patch.object(owner, name,
                                                     side_effect=AssertionError("external operation")))
                    for owner, name in (
                        (live, "private_command"), (live, "profile_data"),
                        (live, "build_selected"), (live, "private_revision"),
                        (live.subprocess, "run"), (live.subprocess, "Popen"),
                    )
                ]
                clock = stack.enter_context(patch.object(
                    live, "dpk_time", side_effect=[live.DPK_DEADLINE - 600, sentinel]))
                digests = stack.enter_context(patch.object(live, "digest", wraps=live.digest))
                stack.enter_context(patch.object(live, "load", side_effect=checked_load))
                stack.enter_context(patch.object(Path, "read_bytes", checked_read))
                with self.assertRaises(StopBeforeBuild) as caught:
                    live.dpk_prepare(fixture["repo"], fixture["parent"], profile)
            self.assertIs(caught.exception, sentinel)
            self.assertEqual(clock.call_args_list, [call(540), call(540)])
            self.assertEqual(digests.call_args_list, [
                call(fixture["original"][fixture["repo"] / fixture["template"] / leaf])
                for leaf in fixture["bindings"]
            ])
            self.assertEqual(Counter(reads), Counter({
                fixture["repo"] / fixture["template"] / leaf:
                    2 if leaf in fixture["projects"] else 1
                for leaf in fixture["bindings"]
            }))
            self.assertNotIn(profile, reads)
            workspaces = list(fixture["parent"].glob("rivet-dpk-preparation-*"))
            self.assertEqual(len(workspaces), 1)
            self._ownership_assert_copy(fixture, workspaces[0] / "project")
            for leaf in ("Debug.command.json", "Rebuilt.command.json", "preparation.json"):
                self.assertFalse((workspaces[0] / leaf).exists())
            for path, data in fixture["original"].items():
                self.assertEqual(path.read_bytes(), data)
            for guard in guards:
                guard.assert_not_called()

    def human(self, phase="save-a", count=0):
        return {"runUUID": self.run, "phase": phase, "machineSHA256": self.sha,
                "promptCount": count, "wholeStageObserved": True,
                "actions": ["none"] if count == 0 else ["allow"] * count}

    def test_uuid_and_service_are_exact(self):
        live.validate_namespace(self.run, live.service(self.run))
        for other in ("*", self.run.upper(), "../" + self.run, "not-uuid"):
            with self.assertRaises(live.Rejected):
                live.validate_namespace(other, live.service(self.run))
        with self.assertRaises(live.Rejected):
            live.validate_namespace(self.run, live.service(self.run) + ".extra")

    def test_immutable_json_is_private_and_exclusive(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "receipt.json"
            live.exclusive_json(path, {"x": 1})
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(FileExistsError):
                live.exclusive_json(path, {"x": 2})

    def test_root_and_symlink_guards(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve() / ("rivet-credential-storage-" + self.run)
            root.mkdir(mode=0o700)
            live.owned_root(root, self.run)
            root.chmod(0o755)
            with self.assertRaises(live.Rejected):
                live.owned_root(root, self.run)
            root.chmod(0o700)
            link = Path(temp) / "link"
            link.symlink_to(root)
            with self.assertRaises(live.Rejected):
                live.owned_root(link, self.run)
            with self.assertRaises(live.Rejected):
                live.contained(root, root / "../escape")

    def test_readiness_is_stage_specific_exclusive_and_boolean(self):
        ready = {"runUUID": self.run, "phase": "save-a", "ready": True, "readyUUID": str(uuid.uuid4())}
        live.validate_ready(ready, self.run, "save-a")
        for key, value in (("phase", "read-a"), ("runUUID", str(uuid.uuid4())),
                           ("ready", 1), ("ready", False)):
            with self.assertRaises(live.Rejected):
                live.validate_ready(dict(ready, **{key: value}), self.run, "save-a")

    def test_human_exact_binding_unknown_and_negative_counts(self):
        live.validate_observation(self.human(), self.run, "save-a", self.sha)
        for key, value in (("machineSHA256", "b" * 64), ("phase", "read-a"),
                           ("promptCount", True), ("promptCount", -1), ("actions", ["PRIVATE"])):
            with self.assertRaises(live.Rejected):
                live.validate_observation(dict(self.human(), **{key: value}),
                                          self.run, "save-a", self.sha)
        for human in (None, dict(self.human(), promptCount=None),
                      dict(self.human(), wholeStageObserved=False)):
            self.assertEqual(live.classify(self.machine, human, self.sha), "unknown")

    def test_observation_thresholds_are_per_stage(self):
        self.assertEqual(live.classify(self.machine, self.human(count=1), self.sha), "success")
        self.assertEqual(live.classify(self.machine, self.human(count=2), self.sha), "failure")
        machine = dict(self.machine, phase="read-a")
        self.assertEqual(live.classify(machine, self.human("read-a", 1), self.sha), "failure")
        machine = dict(self.machine, phase="replace-b")
        self.assertEqual(live.classify(machine, self.human("replace-b", 2), self.sha), "success")

    def test_machine_and_human_projection_drop_private_data(self):
        raw = dict(self.machine, pid=123, group="PRIVATE", token="PRIVATE", path="/PRIVATE",
                   arbitrary="PRIVATE", failureKind="RAW_PRIVATE_ERROR",
                   comparison=dict(self.machine["comparison"], token="PRIVATE"))
        out = live.public_machine(raw)
        self.assertNotIn("PRIVATE", json.dumps(out))
        raw_human = dict(self.human(count=1), statement="PRIVATE", actions=["other"])
        self.assertNotIn("PRIVATE", json.dumps(live.public_human(raw_human)))
        self.assertEqual(set(out["comparison"]), set(live.FIELDS))

    def test_unknown_or_failure_cannot_unlock_next_phase(self):
        receipts = {}
        with self.assertRaises(live.Rejected):
            live.require_previous("read-a", receipts)
        receipts["save-a"] = "unknown"
        with self.assertRaises(live.Rejected):
            live.require_previous("read-a", receipts)
        receipts.update(setup="success", **{"save-a": "success"})
        live.require_previous("read-a", receipts)
        live.require_previous("cleanup", {})  # recovery still separately requires ownership/ready

    def test_fresh_process_rejects_reuse_and_live_previous_pid(self):
        live.validate_process({"pid": 200, "processUUID": str(uuid.uuid4())},
                              [{"pid": 100, "processUUID": str(uuid.uuid4())}], lambda _: False)
        token = str(uuid.uuid4())
        for current, previous, alive in (
            ({"pid": 200, "processUUID": token}, [{"pid": 100, "processUUID": token}], False),
            ({"pid": 100, "processUUID": token}, [{"pid": 100, "processUUID": str(uuid.uuid4())}], False),
            ({"pid": 200, "processUUID": token}, [{"pid": 100, "processUUID": str(uuid.uuid4())}], True)):
            with self.assertRaises(live.Rejected):
                live.validate_process(current, previous, lambda _: alive)

    def test_cleanup_requires_absence_and_prewrite_ownership(self):
        manifest = {"runUUID": self.run, "service": live.service(self.run),
                    "group": "TEAM.private", "account": "credential"}
        proof = dict(manifest, absenceConfirmed=True, writeAttempted=True, manifestSHA256=self.sha)
        live.validate_ownership(manifest, proof, self.sha)
        for key, value in (("group", "other"), ("account", "*"),
                           ("writeAttempted", False), ("absenceConfirmed", False),
                           ("manifestSHA256", "b" * 64)):
            with self.assertRaises(live.Rejected):
                live.validate_ownership(manifest, dict(proof, **{key: value}), self.sha)

    def test_clean_build_and_full_identity_evidence_are_required(self):
        first = {key: self.sha for key in live.IDENTITY_HASHES}
        first.update(validity=True, buildVerified=True, sourceSHA256=self.sha,
                     compiledMarker=False, binarySHA256="b" * 64)
        second = dict(first, compiledMarker=True, binarySHA256="c" * 64)
        live.validate_rebuild(first, second)
        for key, value in (("profileSHA256", "d" * 64), ("buildVerified", False),
                           ("compiledMarker", False), ("binarySHA256", "b" * 64),
                           ("validity", False), ("sourceSHA256", "d" * 64)):
            with self.assertRaises(live.Rejected):
                live.validate_rebuild(first, dict(second, **{key: value}))

    def test_failing_machine_does_not_become_success(self):
        self.assertEqual(live.classify(dict(self.machine, status="failure"), self.human(), self.sha),
                         "failure")
        for key in ("sameSource", "sameIdentity", "sameLocation", "validity", "freshProcess"):
            self.assertEqual(live.classify(dict(self.machine, **{key: False}),
                                          self.human(), self.sha), "unknown")

    def test_all_six_comparisons_are_required(self):
        for key in live.FIELDS:
            comparison = dict(self.machine["comparison"])
            comparison[key] = False
            self.assertEqual(live.classify(dict(self.machine, comparison=comparison),
                                          self.human(), self.sha), "failure")

    def test_source_drift_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "source.swift"
            path.write_text("first")
            sources = {str(path): live.digest(path.read_bytes())}
            live.verify_sources(sources)
            path.write_text("changed")
            with self.assertRaises(live.Rejected):
                live.verify_sources(sources)

    def test_child_launch_command_is_only_launchservices_sequential(self):
        cmd = live.launch_command(Path("/private/example.app"), Path("/private/request.json"), self.sha)
        self.assertEqual(cmd[:3], ["/usr/bin/open", "-W", "-a"])
        self.assertNotIn("-n", cmd)
        self.assertIn("--args", cmd)



class StageFixture:
    """Exercise the actual runner entrypoints with a fake child and fixture-only context."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve() / "fixture"
        self.root.mkdir(mode=0o700)
        (self.root / "private").mkdir(mode=0o700)
        self.run_uuid = str(uuid.uuid4())
        self.repo = Path(self.temp.name).resolve() / "repository"
        self.repo.mkdir()
        self.run = {"runUUID": self.run_uuid, "repo": str(self.repo),
                    "service": live.service(self.run_uuid), "account": "credential",
                    "fixedApp": str(self.root / "current/CredentialStorageProbe.app"),
                    "ownedDirectories": ["project", "derived-debug", "derived-rebuilt", "current"]}
        live.exclusive_json(self.root / "run.json", self.run)
        live.exclusive_json(self.root / "identity.json",
                            {"group": "TEAM.fixture", "profilePath": str(self.root / "fixture-profile")})
        self.proof = {key: "a" * 64 for key in live.IDENTITY_HASHES}
        self.proof.update(validity=True, buildVerified=True, compiledMarker=False,
                          binarySHA256="b" * 64, sourceSHA256="c" * 64)
        live.exclusive_json(self.root / "private/setup.build-proof.json", self.proof)
        self.old_uuid = str(uuid.uuid4())
        self.current_uuid = str(uuid.uuid4())
        self.current_pid = 202
        self.child_status = "success"
        self.child_calls = 0
        from unittest.mock import patch
        self.addCleanup(patch.stopall)
        patch.object(live, "context", return_value=(self.root, self.run)).start()
        patch.object(live, "inspect_selected", return_value=dict(self.proof)).start()
        patch.object(live, "alive", return_value=False).start()
        patch.object(live, "private_command", side_effect=self.child).start()
        self.seed("setup")
        self.seed("save-a")
        boundary = {"runUUID": self.run_uuid, "phase": "save-a",
                    "manifestSHA256": live.digest((self.root / "run.json").read_bytes())}
        live.exclusive_json(self.root / "private/save-a.request.json",
                            dict(boundary, service=self.run["service"], account="credential"))
        for name in ("launch-attempt", "launch-settled"):
            live.exclusive_json(self.root / "private" / ("save-a." + name + ".json"), boundary)
        live.exclusive_json(self.root / "private/save-a.app.json",
                            {"runUUID": self.run_uuid, "phase": "save-a", "pid": 101,
                             "processUUID": self.old_uuid, "status": "success",
                             "writeAttempted": True})

    def seed(self, phase):
        storage = self.root / "private"
        machine = dict(self.proof, schemaVersion=1, runUUID=self.run_uuid, phase=phase,
                       status="success", sameSource=True, sameIdentity=True, sameLocation=True,
                       freshProcess=True, previousTerminated=True,
                       comparison={key: True for key in live.FIELDS})
        live.exclusive_json(storage / (phase + ".machine.json"), machine)
        sha = live.exclusive_json(live.binding_path(storage, phase), live.public_machine(machine))
        live.exclusive_json(storage / (phase + ".human.json"),
                            self.human(phase, sha))

    def ready(self, phase):
        path = self.root / ("ready-" + str(uuid.uuid4()) + ".json")
        live.exclusive_json(path, {"runUUID": self.run_uuid, "phase": phase,
                                  "ready": True, "readyUUID": str(uuid.uuid4())})
        return path

    def human(self, phase, sha, count=0):
        return {"runUUID": self.run_uuid, "phase": phase, "machineSHA256": sha,
                "promptCount": count, "wholeStageObserved": True, "actions": ["none"]}

    def child(self, command, storage, basename):
        # Only fake launch calls enter here; never execute a subprocess or Security API.
        self.assertEqual(command[:3], ["/usr/bin/open", "-W", "-a"])
        self.child_calls += 1
        request = live.load(Path(command[command.index("--request") + 1]))
        phase = request["phase"]
        receipt = {"runUUID": self.run_uuid, "phase": phase, "status": self.child_status,
                   "compiledMarker": False, "pid": self.current_pid,
                   "processUUID": self.current_uuid, "comparison": {key: True for key in live.FIELDS},
                   "owned": True, "deleted": self.child_status == "success",
                   "readAbsent": self.child_status == "success",
                   "token": "PRIVATE_NEVER_EXPORT", "path": "/PRIVATE_NEVER_EXPORT"}
        live.exclusive_json(storage / (phase + ".app.json"), receipt)
        return b"", b""

    def destination(self):
        return self.repo / "plan/github-oauth-credential-persistence/evidence/live" / self.run_uuid

    def observe_result(self, phase, result, recovery=None):
        human_file = self.root / ("human-" + str(uuid.uuid4()) + ".json")
        live.exclusive_json(human_file, self.human(phase, result["machineSHA256"]))
        return live.observe(self.root, phase, human_file, recovery)

    def own(self):
        ownership = dict(self.run, group="TEAM.fixture", absenceConfirmed=True, writeAttempted=True,
                         manifestSHA256=live.digest((self.root / "run.json").read_bytes()))
        live.exclusive_json(self.root / "private/write-attempt.json", ownership)



class StageIntegration(StageFixture, unittest.TestCase):
    def test_stage_rejects_historical_process_uuid_reuse(self):
        self.current_uuid = self.old_uuid
        result = live.stage(self.root, "read-a", self.ready("read-a"))
        machine = live.load(self.root / "private/read-a.machine.json")
        self.assertEqual(machine["status"], "unknown")
        self.assertIsNot(machine.get("freshProcess"), True)
        self.assertEqual(self.observe_result("read-a", result)["status"], "unknown")

    def test_stage_accepts_new_uuid_but_rejects_pid_reuse(self):
        self.current_pid = 101
        result = live.stage(self.root, "read-a", self.ready("read-a"))
        self.assertEqual(self.observe_result("read-a", result)["status"], "unknown")

    def test_stage_rejects_still_live_history_before_child(self):
        from unittest.mock import patch
        with patch.object(live, "alive", return_value=True):
            result = live.stage(self.root, "read-a", self.ready("read-a"))
            self.assertEqual(self.observe_result("read-a", result)["status"], "unknown")
        self.assertEqual(self.child_calls, 0)

    def test_stage_observe_export_bind_exact_public_bytes_and_keep_projection(self):
        result = live.stage(self.root, "read-a", self.ready("read-a"))
        self.assertEqual(self.observe_result("read-a", result)["status"], "success")
        live.export_receipts(self.root, self.destination())
        machine = self.destination() / "read-a.machine.json"
        human = live.load(self.destination() / "read-a.human.json")
        self.assertEqual(live.digest(machine.read_bytes()), result["machineSHA256"])
        self.assertEqual(human["machineSHA256"], result["machineSHA256"])
        self.assertNotIn("PRIVATE_NEVER_EXPORT", machine.read_text())

    def test_stage_ready_replay_and_bad_observation_sha_are_rejected(self):
        ready = self.ready("read-a")
        result = live.stage(self.root, "read-a", ready)
        bad = self.root / "bad-human.json"
        live.exclusive_json(bad, self.human("read-a", "d" * 64))
        with self.assertRaises(live.Rejected):
            live.observe(self.root, "read-a", bad)
        self.assertFalse((self.root / "private/read-a.human.json").exists())
        self.observe_result("read-a", result)
        with self.assertRaises((live.Rejected, FileExistsError)):
            live.stage(self.root, "read-a", ready)
        self.assertEqual(self.child_calls, 1)

    def test_unobserved_stage_stops_dependency_final_unknown_is_immutable(self):
        result = live.stage(self.root, "read-a", self.ready("read-a"))
        with self.assertRaises(live.Rejected):
            live.stage(self.root, "replace-b", self.ready("replace-b"))
        live.export_receipts(self.root, self.destination(), final=True)
        human = self.destination() / "read-a.human.json"
        frozen = human.read_bytes()
        self.assertIsNone(live.load(human)["promptCount"])
        with self.assertRaises(live.Rejected):
            self.observe_result("read-a", result)
        with self.assertRaises(FileExistsError):
            live.export_receipts(self.root, self.destination(), final=True)
        self.assertEqual(human.read_bytes(), frozen)

    def test_cleanup_failure_same_root_fresh_recovery_retains_foreign_files(self):
        self.own()
        self.child_status = "failure"
        old_ready = self.ready("cleanup")
        first = live.stage(self.root, "cleanup", old_ready)
        self.assertEqual(self.observe_result("cleanup", first)["status"], "failure")
        live.export_receipts(self.root, self.destination(), final=True)
        public_failure = (self.destination() / "cleanup.machine.json").read_bytes()
        with self.assertRaises(FileExistsError):
            live.stage(self.root, "cleanup", old_ready, recovery=True)
        self.child_status = "success"
        self.current_pid = 303
        self.current_uuid = str(uuid.uuid4())
        result = live.stage(self.root, "cleanup", self.ready("cleanup"), recovery=True)
        self.assertEqual(self.observe_result("cleanup", result, result["recoveryUUID"])["status"],
                         "success")
        for directory in self.run["ownedDirectories"]:
            (self.root / directory).mkdir()
        foreign = self.root / "foreign-sentinel"
        foreign.write_text("keep")
        live.cleanup_files(self.root)
        self.assertTrue(foreign.exists())
        self.assertTrue((self.root / "private/write-attempt.json").exists())
        self.assertEqual((self.destination() / "cleanup.machine.json").read_bytes(), public_failure)



class DRInspection(unittest.TestCase):
    def test_inspect_hashes_only_canonical_requirement_across_locations(self):
        import hashlib
        import plistlib
        import subprocess
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            private = root / "private"
            private.mkdir()
            profile = root / "selected-profile"
            profile.write_bytes(b"fixture-profile")
            cert = b"fixture-certificate"
            identity = {"appID": "local.rivet.fixture", "team": "TEAM",
                        "group": "TEAM.fixture", "certificateSHA1": hashlib.sha1(cert).hexdigest()}
            requirement = 'identifier "local.rivet.fixture" and anchor apple generic'
            raw = {}
            def command(argv, directory, basename):
                if argv[0] == "/usr/bin/csreq":
                    result = subprocess.run(argv, capture_output=True, check=False)
                    live.require(result.returncode == 0)
                    return result.stdout, result.stderr
                if "--verify" in argv:
                    return b"", b""
                if "--verbose=4" in argv:
                    return b"", (b"Identifier=local.rivet.fixture\nTeamIdentifier=TEAM\n"
                                  b"Authority=Apple Development: Fixture\n")
                if "--entitlements" in argv:
                    return plistlib.dumps({"keychain-access-groups": ["TEAM.fixture"]}), b""
                if "-r-" in argv:
                    return b"", raw["value"]
                if any(value.startswith("--extract-certificates") for value in argv):
                    self.assertEqual(len(argv), 4)
                    self.assertEqual(argv[:2], ["/usr/bin/codesign", "-d"])
                    self.assertTrue(argv[2].startswith("--extract-certificates="))
                    self.assertEqual(argv[3], raw["app"])
                    prefix = argv[2].split("=", 1)[1]
                    self.assertEqual(Path(prefix).parent, directory)
                    Path(prefix + "0").write_bytes(cert)
                    return b"", b""
                if argv[0] == "/usr/bin/openssl":
                    return b"notBefore=Jan  1 00:00:00 2020 GMT\nnotAfter=Jan  1 00:00:00 2050 GMT\n", b""
                raise AssertionError("unexpected tool")
            def inspect(label, expression, body=None):
                app = root / label / "CredentialStorageProbe.app"
                (app / "Contents/MacOS").mkdir(parents=True, exist_ok=True)
                (app / "Contents/embedded.provisionprofile").write_bytes(profile.read_bytes())
                (app / "Contents/Info.plist").write_bytes(
                    plistlib.dumps({"CFBundleExecutable": "CredentialStorageProbe"}))
                (app / "Contents/MacOS/CredentialStorageProbe").write_bytes(label.encode())
                raw["app"] = str(app)
                raw["value"] = body if body is not None else (
                    "Executable=" + str(app) + "\nwarning: fixture display metadata\n"
                    "designated => " + expression + "\n").encode()
                return live.inspect_selected(app, profile, identity, private, label)
            with patch.object(live, "private_command", side_effect=command), \
                 patch.object(live, "profile_data", return_value={}):
                first = inspect("derived-debug", requirement)
                current = inspect("current", requirement)
                rebuilt = inspect("derived-rebuilt", requirement.replace(" and ", "  and   "))
                self.assertEqual(first["drSHA256"], current["drSHA256"])
                self.assertEqual(first["drSHA256"], rebuilt["drSHA256"])
                first.update(compiledMarker=False, buildVerified=True, sourceSHA256="a"*64,
                             locationSHA256="b"*64)
                rebuilt.update(compiledMarker=True, buildVerified=True, sourceSHA256="a"*64,
                               locationSHA256="b"*64)
                live.validate_rebuild(first, rebuilt)
                different = inspect("different", requirement + ' and certificate leaf[subject.CN] = "Other"')
                different.update(compiledMarker=True, buildVerified=True, sourceSHA256="a"*64,
                                 locationSHA256="b"*64)
                with self.assertRaises(live.Rejected):
                    live.validate_rebuild(first, different)
                for index, body in enumerate((
                    b"Executable=fixture\n",
                    ("designated => " + requirement + "\ndesignated => " + requirement + "\n").encode(),
                    b"designated => not valid requirement syntax\n",
                    b"designated => \n",
                )):
                    with self.assertRaises(live.Rejected):
                        inspect("invalid" + str(index), requirement, body=body)


class FailedStageIntegration(StageFixture, unittest.TestCase):
    def clear_history(self, identity=False):
        for path in (self.root / "private").iterdir():
            if path.is_file():
                path.unlink()
        if identity and (self.root / "identity.json").exists():
            (self.root / "identity.json").unlink()

    def assert_observable_unknown(self, phase, result):
        machine = live.load(self.root / "private" / (phase + ".machine.json"))
        self.assertEqual(machine["status"], "unknown")
        self.assertNotIn("PRIVATE", json.dumps(live.public_machine(machine)))
        self.assertIsNot(machine.get("freshProcess"), True)
        human = self.human(phase, result["machineSHA256"], count=1)
        human["actions"] = ["authenticate"]
        path = self.root / ("observed-" + str(uuid.uuid4()) + ".json")
        live.exclusive_json(path, human)
        observed = live.observe(self.root, phase, path)
        self.assertEqual(observed["status"], "unknown")
        live.export_receipts(self.root, self.destination())
        self.assertEqual(live.load(self.destination() / (phase + ".human.json"))["promptCount"], 1)

    def test_setup_build_error_is_observable_and_stops_dependency(self):
        from unittest.mock import patch
        self.clear_history(identity=True)
        with patch.object(live, "freeze_identity", return_value={}), \
             patch.object(live, "build_selected", side_effect=OSError("PRIVATE_RAW_BUILD_ERROR")):
            result = live.stage(self.root, "setup", self.ready("setup"), self.root / "unused")
        self.assert_observable_unknown("setup", result)
        with self.assertRaises(live.Rejected):
            live.stage(self.root, "save-a", self.ready("save-a"))
        self.assertEqual(self.child_calls, 0)

    def test_runtime_inspection_error_is_observable_before_launch(self):
        from unittest.mock import patch
        with patch.object(live, "inspect_selected", side_effect=live.Rejected):
            result = live.stage(self.root, "read-a", self.ready("read-a"))
        self.assert_observable_unknown("read-a", result)
        self.assertEqual(self.child_calls, 0)

    def test_launch_error_retains_write_proof_and_is_observable(self):
        from unittest.mock import patch
        self.own()
        with patch.object(live, "private_command", side_effect=OSError("PRIVATE_LAUNCH_ERROR")):
            result = live.stage(self.root, "read-a", self.ready("read-a"))
        self.assert_observable_unknown("read-a", result)
        self.assertTrue((self.root / "private/write-attempt.json").exists())

    def test_missing_child_receipt_and_post_guard_failure_are_observable(self):
        from unittest.mock import patch
        with patch.object(live, "private_command", return_value=(b"", b"")):
            result = live.stage(self.root, "read-a", self.ready("read-a"))
        self.assert_observable_unknown("read-a", result)

    def test_historical_uuid_guard_has_unknown_machine_not_fresh_claim(self):
        self.current_uuid = self.old_uuid
        result = live.stage(self.root, "read-a", self.ready("read-a"))
        self.assert_observable_unknown("read-a", result)

    def test_setup_failure_files_only_cleanup_requires_fresh_ready_observe_and_final(self):
        from unittest.mock import patch
        self.clear_history(identity=True)
        for name in self.run["ownedDirectories"]:
            (self.root / name).mkdir()
        foreign = self.root / "foreign-sentinel"
        foreign.write_text("keep")
        with patch.object(live, "freeze_identity", return_value={}), \
             patch.object(live, "build_selected", side_effect=live.Rejected):
            failed = live.stage(self.root, "setup", self.ready("setup"), self.root / "unused")
        self.assert_observable_unknown("setup", failed)
        invalid = self.ready("cleanup")
        value = live.load(invalid)
        value["ready"] = False
        invalid.write_text(json.dumps(value))
        with self.assertRaises(live.Rejected):
            live.stage(self.root, "cleanup", invalid)
        result = live.stage(self.root, "cleanup", self.ready("cleanup"))
        machine = live.load(self.root / "private/cleanup.machine.json")
        self.assertIs(machine["writeAttempted"], False)
        self.assertIsNot(machine.get("deleted"), True)
        self.assertIsNot(machine.get("readAbsent"), True)
        with self.assertRaises(live.Rejected):
            live.cleanup_files(self.root)
        self.assertEqual(self.observe_result("cleanup", result)["status"], "success")
        live.export_receipts(self.root, self.destination(), final=True)
        live.cleanup_files(self.root)
        self.assertEqual(self.child_calls, 0)
        self.assertTrue(foreign.exists())
        self.assertTrue((self.root / "private/finalized.json").exists())
        self.assertTrue(all(not (self.root/name).exists() for name in self.run["ownedDirectories"]))

    def test_prewrite_child_failure_files_only_cleanup_without_delete(self):
        self.clear_history()
        live.exclusive_json(self.root / "private/setup.build-proof.json", self.proof)
        self.seed("setup")
        from unittest.mock import patch
        def failed_child(command, storage, basename):
            self.child_calls += 1
            live.exclusive_json(storage / "save-a.app.json", {
                "runUUID": self.run_uuid, "phase": "save-a", "status": "failure",
                "compiledMarker": False, "pid": 202, "processUUID": self.current_uuid,
                "failureKind": "credentialDenied"})
            return b"", b""
        with patch.object(live, "private_command", side_effect=failed_child):
            first = live.stage(self.root, "save-a", self.ready("save-a"))
        self.observe_result("save-a", first)
        result = live.stage(self.root, "cleanup", self.ready("cleanup"))
        self.assertEqual(self.child_calls, 1)  # cleanup launched no child
        self.assertEqual(self.observe_result("cleanup", result)["status"], "success")
        live.export_receipts(self.root, self.destination(), final=True)
        live.cleanup_files(self.root)
        self.assertFalse((self.root / "private/write-attempt.json").exists())

    def test_no_write_shortcut_rejects_unresolved_or_live_child_and_attempt_marker(self):
        self.clear_history(identity=True)
        # An unresolved launch remains unsafe even if no marker has appeared yet.
        live.exclusive_json(self.root / "private/save-a.request.json",
                            {"runUUID": self.run_uuid, "phase": "save-a"})
        result = live.stage(self.root, "cleanup", self.ready("cleanup"))
        self.assertNotEqual(self.observe_result("cleanup", result)["status"], "success")
        live.export_receipts(self.root, self.destination(), final=True)
        with self.assertRaises(live.Rejected):
            live.cleanup_files(self.root)

    def test_live_history_cannot_be_claimed_no_write(self):
        from unittest.mock import patch
        self.clear_history()
        live.exclusive_json(self.root / "private/save-a.app.json", {
            "runUUID": self.run_uuid, "phase": "save-a", "pid": 202,
            "processUUID": self.current_uuid, "status": "failure", "compiledMarker": False})
        with patch.object(live, "alive", return_value=True):
            result = live.stage(self.root, "cleanup", self.ready("cleanup"))
            self.assertNotEqual(self.observe_result("cleanup", result)["status"], "success")
            live.export_receipts(self.root, self.destination(), final=True)
            with self.assertRaises(live.Rejected):
                live.cleanup_files(self.root)

    def test_unknown_context_ownership_never_deletes_files(self):
        from unittest.mock import patch
        (self.root / "project").mkdir()
        with patch.object(live, "context", side_effect=live.Rejected):
            with self.assertRaises(live.Rejected):
                live.cleanup_files(self.root)
        self.assertTrue((self.root / "project").exists())

    def test_exact_owned_manual_app_bootstrap_derives_private_identity_then_clean_build(self):
        from unittest.mock import patch
        import hashlib
        import plistlib
        self.clear_history(identity=True)
        app = self.root / "derived-debug/Build/Products/Debug/CredentialStorageProbe.app"
        (app / "Contents").mkdir(parents=True)
        (app / "Contents/embedded.provisionprofile").write_bytes(b"private-owned-profile")
        project = self.root / "project/CredentialStorageProbe.xcodeproj/project.pbxproj"
        project.parent.mkdir(parents=True)
        project.write_text("private-human-selected-project")
        cert = b"private-fixture-certificate"
        calls = []
        def selected_command(argv, storage, basename):
            calls.append(argv)
            self.assertEqual(argv[0], "/usr/bin/codesign")
            if "--verify" in argv:
                return b"", b""
            if "--verbose=4" in argv:
                return b"", (b"Identifier=local.rivet.fixture\nTeamIdentifier=TEAM\n"
                              b"Authority=Apple Development: Fixture\n")
            if "--entitlements" in argv:
                return plistlib.dumps({"keychain-access-groups": ["TEAM.fixture"]}), b""
            if any(value.startswith("--extract-certificates") for value in argv):
                self.assertEqual(argv, [
                    "/usr/bin/codesign", "-d",
                    "--extract-certificates=" + str(self.root / "private/setup.bootstrap-cert"),
                    str(app)])
                prefix = argv[2].split("=", 1)[1]
                Path(prefix + "0").write_bytes(cert)
                return b"", b""
            raise AssertionError("unexpected tool")
        def formal_build(root, run, phase):
            self.assertEqual(phase, "setup")
            identity = live.load(root / "identity.json")
            self.assertEqual(identity["certificateSHA1"], hashlib.sha1(cert).hexdigest())
            self.assertEqual(identity["group"], "TEAM.fixture")
            self.assertEqual(Path(identity["profilePath"]).read_bytes(), b"private-owned-profile")
            self.assertNotEqual(identity["profilePath"], str(app / "Contents/embedded.provisionprofile"))
            self.assertTrue(identity["projectSHA256"])
            return dict(self.proof)
        with patch.object(live, "private_command", side_effect=selected_command), \
             patch.object(live, "profile_data", return_value={}), \
             patch.object(live, "build_selected", side_effect=formal_build) as build:
            result = live.stage(self.root, "setup", self.ready("setup"), built_app=app)
        self.assertEqual(build.call_count, 1)
        self.assertTrue(calls)
        self.assertEqual(self.observe_result("setup", result)["status"], "success")
        live.export_receipts(self.root, self.destination())
        self.assertNotIn("TEAM.fixture", (self.destination() / "setup.machine.json").read_text())

    def test_bootstrap_refuses_any_other_app_and_records_unknown(self):
        from unittest.mock import patch
        self.clear_history(identity=True)
        with patch.object(live, "private_command") as command:
            result = live.stage(self.root, "setup", self.ready("setup"),
                                built_app=self.root / "other.app")
        command.assert_not_called()
        self.assert_observable_unknown("setup", result)

    def test_attempt_marker_prevents_files_only_shortcut_without_signed_host(self):
        self.clear_history(identity=True)
        self.own()
        result = live.stage(self.root, "cleanup", self.ready("cleanup"))
        self.assertNotEqual(self.observe_result("cleanup", result)["status"], "success")
        live.export_receipts(self.root, self.destination(), final=True)
        with self.assertRaises(live.Rejected):
            live.cleanup_files(self.root)
        self.assertTrue((self.root / "private/write-attempt.json").exists())
        self.assertEqual(self.child_calls, 0)

    def test_unresolved_launch_blocks_even_owned_item_cleanup(self):
        from unittest.mock import patch
        self.own()
        with patch.object(live, "private_command", side_effect=OSError("private")):
            first = live.stage(self.root, "read-a", self.ready("read-a"))
        self.observe_result("read-a", first)
        result = live.stage(self.root, "cleanup", self.ready("cleanup"))
        self.assertEqual(self.observe_result("cleanup", result)["status"], "unknown")
        self.assertEqual(self.child_calls, 0)
        self.assertTrue((self.root / "private/write-attempt.json").exists())

class RetryPreparation(StageFixture, unittest.TestCase):
    """Actual retry/stage/observe/export entrypoints; all build/signing calls are fakes."""
    def setUp(self):
        super().setUp()
        from unittest.mock import patch
        import hashlib
        for path in (self.root / "private").iterdir():
            path.unlink()
        (self.root / "project/CredentialStorageProbe.xcodeproj").mkdir(parents=True)
        project = self.root / "project" / live.PROJECT_FILES[0]
        project.write_bytes(b"fixture-frozen-target-Automatic")
        self.cert = b"fixture-certificate"
        self.profile = self.root / "private/adopted-profile"
        self.profile.write_bytes(b"fixture-profile")
        identity = {"team": "TEAM", "appID": "local.rivet.fixture", "group": "TEAM.fixture",
                    "certificateSHA1": hashlib.sha1(self.cert).hexdigest(),
                    "profilePath": str(self.profile), "projectSHA256": live.digest(project.read_bytes())}
        (self.root / "identity.json").write_text(json.dumps(identity))
        self.run.update(sources={"fixture": "a"*64}, copiedSources={"fixture": "b"*64})
        (self.root / "run.json").write_text(json.dumps(self.run))
        initial = {"schemaVersion": 1, "runUUID": self.run_uuid, "phase": "setup",
                   "status": "unknown", "failureKind": "build"}
        private = self.root / "private"
        live.exclusive_json(private / "setup.machine.json", initial)
        sha = live.exclusive_json(private / "setup.public-machine.json", initial)
        live.exclusive_json(private / "setup.human.json", self.human("setup", sha))
        self.pins = {"runUUID": self.run_uuid,
                     "manifestSHA256": live.digest((self.root / "run.json").read_bytes()),
                     "identitySHA256": live.digest((self.root / "identity.json").read_bytes()),
                     "projectSHA256": identity["projectSHA256"],
                     "originalMachineSHA256": sha,
                     "originalHumanSHA256": live.digest((private / "setup.human.json").read_bytes()),
                     "bootstrapDRSHA256": "a"*64,
                     "profileSHA256": live.digest(self.profile.read_bytes()),
                     "certificateSHA256": live.digest(self.cert)}
        self.proof.update(profileSHA256=self.pins["profileSHA256"],
                          certificateSHA256=self.pins["certificateSHA256"],
                          appIDSHA256=live.digest(identity["appID"].encode()),
                          groupSHA256=live.digest(identity["group"].encode()),
                          locationSHA256=live.digest(self.run["fixedApp"].encode()),
                          drSHA256=self.pins["bootstrapDRSHA256"], sourceSHA256=live.source_digest(self.run))
        live.inspect_selected.return_value = dict(self.proof)
        patch.object(live, "RETRY_PINS", self.pins, create=True).start()
        self.policy = private / "setup-retry-1-policy.json"
        self.retry_ready = private / "setup-retry-1-fresh-ready.json"
        live.exclusive_json(self.policy, {"schemaVersion": 1, "runUUID": self.run_uuid,
                            "policy": "automaticCachedNoPortalUpdates", "attempt": "retry-1", "adopted": True})
        live.exclusive_json(self.retry_ready, {"runUUID": self.run_uuid, "phase": "setup",
                            "ready": True, "readyUUID": str(uuid.uuid4())})
        self.original = {p.name: p.read_bytes() for p in private.glob("setup.*.json")}

    def retry(self):
        return live.retry_setup(self.root, self.retry_ready, self.policy)

    def fake_build(self, root, run, phase, storage=None):
        self.assertEqual(storage, self.root / "private/setup-retry-1")
        live.exclusive_json(storage / "setup.build-proof.json", self.proof)
        return dict(self.proof)

    def observe_retry(self, result, whole=True, sha=None):
        human = self.root / ("retry-human-" + str(uuid.uuid4()) + ".json")
        value = self.human("setup", sha or result["machineSHA256"])
        value["wholeStageObserved"] = whole
        live.exclusive_json(human, value)
        return live.observe(self.root, "setup", human, setup_attempt="retry-1")

    def assert_original(self):
        for name, data in self.original.items():
            self.assertEqual((self.root / "private" / name).read_bytes(), data)

    def test_retry_success_observe_export_preserves_both_histories_and_summary(self):
        from unittest.mock import patch
        with patch.object(live, "build_selected", side_effect=self.fake_build):
            result = self.retry()
        self.assertEqual(live.completed_outcomes(self.root)["setup"], "unknown")
        with self.assertRaises(live.Rejected):
            live.stage(self.root, "save-a", self.ready("save-a"))
        with self.assertRaises(live.Rejected):
            self.observe_retry(result, sha="f"*64)
        self.assertEqual(self.observe_retry(result)["status"], "success")
        save = live.stage(self.root, "save-a", self.ready("save-a"))
        self.assertEqual(self.observe_result("save-a", save)["status"], "success")
        live.export_receipts(self.root, self.destination(), final=True)
        summary = live.load(self.destination() / "run-summary.json")
        self.assertEqual(summary["schemaVersion"], 2)
        self.assertEqual(summary["setupAttempts"], {"initial": "unknown", "retry-1": "success"})
        self.assertEqual(summary["effectiveSetupAttempt"], "retry-1")
        self.assertEqual(summary["phases"]["setup"], "success")
        self.assertEqual(summary["status"], "unknown")
        receipt = live.load(self.destination() / "setup-retry-1.machine.json")
        self.assertEqual((receipt["schemaVersion"], receipt["phase"]), (1, "setup"))
        self.assertEqual(live.digest((self.destination()/"setup.machine.json").read_bytes()),
                         self.pins["originalMachineSHA256"])
        self.assertNotIn("TEAM", json.dumps(summary)+json.dumps(receipt))
        self.assert_original()

    def test_retry_failed_build_is_observable_unknown_retains_attempt_and_rejects_third(self):
        from unittest.mock import patch
        with patch.object(live, "build_selected", side_effect=live.Rejected):
            result = self.retry()
        self.assertEqual(self.observe_retry(result)["status"], "unknown")
        attempt = live.load(self.root / "private/setup-retry-1/attempt.json")
        self.assertEqual(attempt["originalHumanSHA256"], self.pins["originalHumanSHA256"])
        self.assertEqual(attempt["runnerSHA256"], live.digest(SCRIPT.read_bytes()))
        with self.assertRaises((live.Rejected, FileExistsError)):
            self.retry()
        self.assert_original()

    def test_directory_only_and_partial_attempt_never_fallback_or_reuse(self):
        storage = self.root / "private/setup-retry-1"
        storage.mkdir(mode=0o700)
        for partial in (False, True):
            if partial:
                (storage / "attempt.json").write_bytes(b"{")
            with self.subTest(partial=partial):
                self.assertEqual(live.completed_outcomes(self.root)["setup"], "unknown")
                with self.assertRaises(live.Rejected):
                    live.stage(self.root, "save-a", self.ready("save-a"))
                with self.assertRaises((live.Rejected, FileExistsError)):
                    self.retry()
        live.export_receipts(self.root, self.destination(), final=True)
        summary = live.load(self.destination() / "run-summary.json")
        self.assertEqual(summary["setupAttempts"]["retry-1"], "unknown")
        self.assertIsNone(summary["effectiveSetupAttempt"])
        self.assertEqual(summary["phases"]["setup"], "unknown")
        self.assert_original()

    def test_actual_retry_crash_after_mkdir_before_attempt_is_unknown_and_spends_quota(self):
        from unittest.mock import patch
        original_json = live.exclusive_json
        def interrupt(path, value):
            if Path(path).name == "attempt.json":
                raise KeyboardInterrupt()
            return original_json(path, value)
        with patch.object(live, "exclusive_json", side_effect=interrupt):
            with self.assertRaises(KeyboardInterrupt):
                self.retry()
        storage = self.root / "private/setup-retry-1"
        self.assertTrue(storage.is_dir())
        self.assertFalse((storage / "attempt.json").exists())
        self.assertEqual(live.completed_outcomes(self.root)["setup"], "unknown")
        with self.assertRaises(live.Rejected):
            self.retry()
        with self.assertRaises(live.Rejected):
            live.stage(self.root, "save-a", self.ready("save-a"))
        live.export_receipts(self.root, self.destination(), final=True)
        summary = live.load(self.destination() / "run-summary.json")
        self.assertEqual(summary["setupAttempts"]["retry-1"], "unknown")
        self.assertIsNone(summary["effectiveSetupAttempt"])
        self.assert_original()

    def test_retry_preflight_wrong_policy_old_ready_source_and_identity_drift(self):
        from unittest.mock import patch
        cases = [(self.policy, "adopted", False), (self.policy, "runUUID", str(uuid.uuid4())),
                 (self.retry_ready, "phase", "read-a"), (self.retry_ready, "ready", False)]
        for path, key, value in cases:
            raw = path.read_bytes();changed=json.loads(raw);changed[key]=value
            path.write_text(json.dumps(changed))
            with self.subTest(key=key), patch.object(live,"build_selected") as build:
                with self.assertRaises(live.Rejected): self.retry()
                build.assert_not_called()
                self.assertFalse((self.root / "private/setup-retry-1").exists())
            path.write_bytes(raw)
        token = live.load(self.retry_ready)
        old = self.root / "private/setup-fresh-ready.json"
        live.exclusive_json(old, token)
        with self.assertRaises(live.Rejected): self.retry()
        old.unlink()
        identity = self.root / "identity.json";raw=identity.read_bytes();identity.write_bytes(raw+b" ")
        with self.assertRaises(live.Rejected): self.retry()
        identity.write_bytes(raw)
        self.assert_original()

    def test_retry_unknown_observation_blocks_and_replay_is_exclusive(self):
        from unittest.mock import patch
        with patch.object(live, "build_selected", side_effect=self.fake_build): result=self.retry()
        self.assertEqual(self.observe_retry(result, whole=False)["status"], "unknown")
        with self.assertRaises(live.Rejected): live.stage(self.root,"save-a",self.ready("save-a"))
        with self.assertRaises(FileExistsError): self.observe_retry(result)
        with self.assertRaises((live.Rejected, FileExistsError)): self.retry()
        self.assert_original()

    def test_retry_rebuild_uses_effective_proof_not_missing_initial_proof(self):
        from unittest.mock import patch
        with patch.object(live,"build_selected",side_effect=self.fake_build): result=self.retry()
        self.observe_retry(result)
        for phase in ("save-a","read-a","replace-b","read-b"): self.seed(phase)
        rebuilt=dict(self.proof, compiledMarker=True,binarySHA256="d"*64)
        with patch.object(live,"build_selected",return_value=rebuilt):
            result=live.stage(self.root,"rebuild",self.ready("rebuild"))
        self.assertEqual(self.observe_result("rebuild",result)["status"],"success")
        self.assertFalse((self.root/"private/setup.build-proof.json").exists())

    def actual_build_result(self, failure=None):
        from unittest.mock import patch
        profile={"TeamIdentifier":["TEAM"],"UUID":"fixture-only",
                 "Entitlements":{"com.apple.application-identifier":"TEAM.local.rivet.fixture",
                                  "keychain-access-groups":["TEAM.fixture"]},
                 "DeveloperCertificates":[self.cert]}
        candidate=self.root/"derived-debug/Build/Products/Debug/CredentialStorageProbe.app"
        command_calls=[]
        def command(argv,directory,basename):
            self.assertEqual(argv[0],"/usr/bin/xcodebuild")
            for prefix in ("CODE_SIGN_STYLE=","DEVELOPMENT_TEAM=","PRODUCT_BUNDLE_IDENTIFIER=",
                           "CODE_SIGN_IDENTITY=","PROVISIONING_PROFILE_SPECIFIER=","RIVET_VALIDATION_GROUP="):
                self.assertFalse(any(arg.startswith(prefix) for arg in argv),prefix)
            self.assertEqual(directory,self.root/"private/setup-retry-1")
            command_calls.append(argv)
            if failure == "cache":
                raise live.Rejected()
            candidate.mkdir(parents=True,exist_ok=True)
            if failure == "project":
                (self.root / "project" / live.PROJECT_FILES[0]).write_bytes(b"drift")
            return b"",b""
        inspected = dict(self.proof)
        if failure in ("drSHA256", "profileSHA256", "certificateSHA256", "groupSHA256", "appIDSHA256"):
            inspected[failure] = "f" * 64
        with patch.object(live,"inspect_selected",return_value=inspected), \
             patch.object(live,"profile_data",return_value=profile), \
             patch.object(live,"private_revision",return_value="e"*40), \
             patch.object(live,"private_command",side_effect=command):
            result=self.retry()
        self.assertTrue(command_calls)
        return result

    def test_build_argv_no_global_signing_and_exact_baseline_before_install(self):
        result = self.actual_build_result()
        self.assertEqual(self.observe_retry(result)["status"], "success")
        self.assertTrue(Path(self.run["fixedApp"]).is_dir())

    def assert_rejected_product(self, failure):
        result = self.actual_build_result(failure)
        self.assertEqual(self.observe_retry(result)["status"], "unknown")
        self.assertFalse(Path(self.run["fixedApp"]).exists())
        self.assertEqual(self.child_calls, 0)
        self.assert_original()

    def test_cache_missing_in_actual_build_path_stops_without_install(self):
        self.assert_rejected_product("cache")

    def test_bootstrap_dr_mismatch_in_actual_build_path_stops_without_install(self):
        self.assert_rejected_product("drSHA256")

    def test_profile_mismatch_in_actual_build_path_stops_without_install(self):
        self.assert_rejected_product("profileSHA256")

    def test_certificate_mismatch_in_actual_build_path_stops_without_install(self):
        self.assert_rejected_product("certificateSHA256")

    def test_group_mismatch_in_actual_build_path_stops_without_install(self):
        self.assert_rejected_product("groupSHA256")

    def test_app_id_mismatch_in_actual_build_path_stops_without_install(self):
        self.assert_rejected_product("appIDSHA256")

    def test_postbuild_frozen_project_drift_stops_without_install(self):
        self.assert_rejected_product("project")

    def test_cli_retry_and_observe_selector_use_bounded_entrypoints(self):
        import contextlib
        import io
        from unittest.mock import patch
        with patch.object(live, "build_selected", side_effect=self.fake_build), \
             patch.object(live.sys, "argv", [str(SCRIPT), "retry-setup", "--root", str(self.root),
                 "--ready-file", str(self.retry_ready), "--policy-adoption-file", str(self.policy)]), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(live.main(), 0)
        result = json.loads(output.getvalue())
        human = self.root / "cli-human.json"
        live.exclusive_json(human, self.human("setup", result["machineSHA256"]))
        with patch.object(live.sys, "argv", [str(SCRIPT), "observe", "--root", str(self.root),
                 "--phase", "setup", "--human-file", str(human), "--setup-attempt", "retry-1"]), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(live.main(), 0)
        self.assertEqual(json.loads(output.getvalue())["status"], "success")
        with self.assertRaises(live.Rejected):
            live.observe(self.root, "save-a", human, setup_attempt="retry-1")

    def test_private_command_rejects_all_provisioning_and_auth_permissions(self):
        from unittest.mock import patch
        for flag in ("-allowProvisioningUpdates","-allowProvisioningDeviceRegistration",
                     "-authenticationKeyPath=x","-authenticationKeyID","-authenticationKeyIssuerID"):
            with self.subTest(flag=flag),patch.object(live.subprocess,"run") as run:
                with self.assertRaises(live.Rejected):
                    RAW_PRIVATE_COMMAND(["/usr/bin/xcodebuild",flag],self.root/"private",str(uuid.uuid4()))
                run.assert_not_called()


class DiagnosticRunnerControls(unittest.TestCase):
    def setUp(self):
        from unittest.mock import patch
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name).resolve()
        self.uuid = str(uuid.uuid4())
        self.root = base / ("rivet-credential-storage-diagnostic-" + self.uuid)
        self.root.mkdir(mode=0o700)
        self.legacy = base / ("rivet-credential-storage-" + live.RETRY_PINS["runUUID"])
        self.legacy.mkdir(mode=0o700)
        (self.legacy / "private").mkdir()
        self.purpose = "diagnostic-only"
        for leaf in ("run.json", "identity.json", "private/save-a.public-machine.json", "private/save-a.human.json", "private/save-a.request.json"):
            live.exclusive_json(self.legacy / leaf, {"runUUID": live.RETRY_PINS["runUUID"]})
        self.app = self.root / "app/CredentialStorageProbe.app"
        binary = self.app / "Contents/MacOS/CredentialStorageProbe"
        binary.parent.mkdir(parents=True)
        binary.write_bytes(b"fixture-unsigned-not-run")
        self.sources = {}
        for leaf in ("README.md", "Sources/main.swift", "scripts/credential_storage_live.py", "Tests/test_live_protocol.py"):
            path = self.root / "source" / leaf
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"fixture-source")
            self.sources[str(path)] = live.digest(path.read_bytes())
        self.manifest = {"schemaVersion": 1, "diagnosticUUID": self.uuid,
                         "legacyRunUUID": live.RETRY_PINS["runUUID"], "purpose": self.purpose,
                         "legacyRoot": str(self.legacy), "expectedApp": str(self.app),
                         "sourceHashes": self.sources, "binarySHA256": live.digest(binary.read_bytes())}
        for leaf, key in (("run.json", "legacyManifestSHA256"), ("identity.json", "legacyIdentitySHA256"),
                          ("private/save-a.public-machine.json", "legacySaveMachineSHA256"),
                          ("private/save-a.human.json", "legacySaveHumanSHA256")):
            self.manifest[key] = live.digest((self.legacy / leaf).read_bytes())
        self.path = self.root / "diagnostic.json"
        live.exclusive_json(self.path, self.manifest)
        self.ready = self.root / "diagnostic.ready.json"
        live.exclusive_json(self.ready, {"diagnosticUUID": self.uuid, "purpose": self.purpose,
                                       "ready": True, "readyUUID": str(uuid.uuid4())})
        self.original = {str(p): p.read_bytes() for p in self.legacy.rglob("*.json")}
        self.calls = 0
        self.write_receipt = True
        self.reject_launch = False
        self.addCleanup(patch.stopall)
        patch.object(live, "private_command", side_effect=self.launch).start()

    def launch(self, argv, directory, basename):
        self.calls += 1
        self.assertEqual(argv[:4], ["/usr/bin/open", "-W", "-a", str(self.app)])
        self.assertNotIn("-n", argv)
        self.assertIn("RIVET_DIAGNOSTIC_MANIFEST=" + str(self.path), argv)
        self.assertIn("RIVET_DIAGNOSTIC_SHA256=" + live.digest(self.path.read_bytes()), argv)
        consumed = live.load(self.root / "diagnostic.consumed-ready.json")
        self.assertEqual(consumed["readySHA256"], live.digest(self.ready.read_bytes()))
        if self.reject_launch:
            raise live.Rejected()
        if self.write_receipt:
            live.exclusive_json(self.root / "diagnostic.machine.json", {
                "schemaVersion": 1, "diagnosticUUID": self.uuid, "legacyRunUUID": live.RETRY_PINS["runUUID"],
                "purpose": self.purpose, "stage": "completed", "status": "success", "diagnosticCopy": True,
                "manifestSHA256": live.digest(self.path.read_bytes()),
                "binarySHA256": self.manifest["binarySHA256"], "sourceSHA256": "a" * 64})
        return b"", b""

    def stage(self):
        return live.diagnostic_stage(self.path, live.digest(self.path.read_bytes()), self.ready)

    def test_actual_dispatch_consumes_before_launch_and_binds_human_without_old_writes(self):
        import contextlib
        import io
        from unittest.mock import patch
        with patch.object(live.sys, "argv", [str(SCRIPT), "diagnostic-stage", "--manifest", str(self.path),
             "--manifest-sha", live.digest(self.path.read_bytes()), "--ready-file", str(self.ready)]), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(live.main(), 0)
        result = json.loads(output.getvalue())
        self.assertEqual(result["status"], "awaitingHumanObservation")
        human = self.root / "human-input.json"
        live.exclusive_json(human, {"diagnosticUUID": self.uuid, "purpose": self.purpose,
             "machineSHA256": result["machineSHA256"], "promptCount": 0,
             "wholeStageObserved": True, "actions": ["none"]})
        self.assertEqual(live.diagnostic_observe(self.path, live.digest(self.path.read_bytes()), human)["status"], "success")
        with self.assertRaises((live.Rejected, FileExistsError)): self.stage()
        for path, data in self.original.items(): self.assertEqual(Path(path).read_bytes(), data)
        self.assertFalse((self.legacy / "private/absence.json").exists())
        self.assertFalse((self.legacy / "private/write-attempt.json").exists())

    def test_missing_host_receipt_remains_unknown_and_cannot_replay(self):
        self.write_receipt = False
        self.assertEqual(self.stage()["status"], "unknown")
        self.assertFalse((self.root / "diagnostic.machine.json").exists())
        with self.assertRaises(live.Rejected): self.stage()
        self.assertEqual(self.calls, 1)

    def test_launch_error_has_no_fabricated_app_receipt_and_no_retry(self):
        self.reject_launch = True
        self.assertEqual(self.stage()["status"], "unknown")
        self.assertFalse((self.root / "diagnostic.machine.json").exists())
        with self.assertRaises(live.Rejected): self.stage()

    def test_partial_consumed_marker_is_spent_before_any_launch(self):
        (self.root / "diagnostic.consumed-ready.json").write_bytes(b"{")
        with self.assertRaises(live.Rejected): self.stage()
        self.assertEqual(self.calls, 0)

    def test_wrong_ready_sha_and_source_are_rejected_before_marker(self):
        with self.assertRaises(live.Rejected): live.diagnostic_stage(self.path, "f" * 64, self.ready)
        value = live.load(self.ready); value["purpose"] = "namespace-read-only"
        self.ready.write_text(json.dumps(value))
        with self.assertRaises(live.Rejected): self.stage()
        self.assertEqual(self.calls, 0)
        self.assertFalse((self.root / "diagnostic.consumed-ready.json").exists())

    def test_projection_is_finite_and_drops_secrets(self):
        result = live.diagnostic_projection({"schemaVersion": 1, "diagnosticUUID": self.uuid,
             "legacyRunUUID": live.RETRY_PINS["runUUID"], "purpose": self.purpose,
             "stage": "entitlement", "status": "failure", "failureKind": "guard",
             "token": "PRIVATE", "path": "PRIVATE", "arbitrary": "PRIVATE", "diagnosticCopy": True})
        self.assertNotIn("PRIVATE", json.dumps(result))
        self.assertEqual(result["stage"], "entitlement")
        with self.assertRaises(live.Rejected):
            live.diagnostic_projection(dict(result, stage="PRIVATE"))

    def test_marker_write_failure_never_launches(self):
        from unittest.mock import patch
        original = live.exclusive_json
        def fail(path, value):
            if Path(path).name == "diagnostic.consumed-ready.json": raise OSError("PRIVATE")
            return original(path, value)
        with patch.object(live, "exclusive_json", side_effect=fail):
            with self.assertRaises(OSError): self.stage()
        self.assertEqual(self.calls, 0)


class SwiftDiagnosticOperations(unittest.TestCase):
    def test_new_swift_actual_shared_diagnostic_guards_with_fakes_only(self):
        import subprocess
        binary = os.environ.get("RIVET_DIAGNOSTIC_PROBE_BINARY")
        if not binary:
            self.skipTest("requires newly compiled diagnostic main; old binary is not evidence")
        result = subprocess.run([binary, "--self-test-diagnostics"], capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0)
        report = json.loads(result.stdout)
        self.assertEqual(report["mode"], "diagnostic-fake-only")
        self.assertEqual(report["failures"], [])
        required = {"bootstrap-sha-zero-output", "bootstrap-purpose-zero-output",
                    "bootstrap-path-zero-output", "exclusive-receipt", "args-failure",
                    "request-failure", "identity-failure", "bundle-failure", "entitlement-failure",
                    "source-failure", "diagnostic-zero-load", "readonly-absent", "readonly-present",
                    "readonly-error-zero-write"}
        self.assertTrue(required.issubset(set(report["caseIDs"])))


class SwiftSharedOperations(unittest.TestCase):
    def test_actual_host_operation_path_with_fakes_only(self):
        import subprocess
        binary = os.environ.get("RIVET_FAKE_PROBE_BINARY")
        if not binary:
            self.skipTest("set RIVET_FAKE_PROBE_BINARY to the compiled unsigned probe for fake-only tests")
        result = subprocess.run([binary, "--self-test-fakes"], capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, "fake-only Swift checks failed")
        report = json.loads(result.stdout)
        self.assertEqual(report["mode"], "fake-only")
        self.assertEqual(report["failures"], [])
        self.assertGreaterEqual(report["passed"], 10)



class FullinfoSDKAndKnownChild(unittest.TestCase):
    """Only the SDK header and one directly owned finite native child; never enumerate PIDs."""
    def test_public_sdk_layout_static_asserts_match_ctypes(self):
        import ctypes
        import subprocess
        kind = live.launcher_bsdinfo_type()
        source = "#include <stddef.h>\n#include <sys/proc_info.h>\n"
        source += f'_Static_assert(sizeof(struct proc_bsdinfo)=={ctypes.sizeof(kind)}, "size");\n'
        source += f'_Static_assert(_Alignof(struct proc_bsdinfo)=={ctypes.alignment(kind)}, "align");\n'
        for field, _ in kind._fields_:
            source += (f'_Static_assert(offsetof(struct proc_bsdinfo,{field})=='
                       f'{getattr(kind, field).offset}, "offset");\n')
        result = subprocess.run(["/usr/bin/clang", "-std=c11", "-fsyntax-only", "-x", "c", "-"],
                                input=source.encode(), capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, "SDK layout assertion failed; no process API queried")

    def test_one_original_native_child_running_zombie_reaped_arg0_arg1(self):
        import ctypes
        import subprocess
        import time
        lib = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
        lib.proc_pidinfo.argtypes = (ctypes.c_int, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_int)
        lib.proc_pidinfo.restype = ctypes.c_int
        child = subprocess.Popen(["rivet-finite-fixture", "1"], executable="/bin/sleep",
                                 stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            running = None
            deadline = time.monotonic() + 0.8
            while time.monotonic() < deadline:
                try:
                    candidate = live.launcher_read_metadata(lib, child.pid)
                    if candidate["status"] in (2, 3, 4) and candidate["name"] == "sleep":
                        running = candidate
                        break
                except live.Rejected:
                    pass  # Known fixture only, bounded deadline, never production retry.
                time.sleep(0.01)
            self.assertIsNotNone(running, "known native running stage was not observed")
            zombie = None
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline:
                candidate = live.launcher_read_metadata(lib, child.pid)
                if candidate["status"] == 5:
                    zombie = candidate
                    break
                time.sleep(0.01)
            self.assertIsNotNone(zombie, "known native zombie stage was not observed")
            self.assertTrue(running["start"] == zombie["start"], "own child instance changed")
            kind = live.launcher_bsdinfo_type()
            raw = kind()
            ctypes.set_errno(0)
            arg0 = lib.proc_pidinfo(child.pid, 3, 0, ctypes.byref(raw), ctypes.sizeof(raw))
            arg0_errno = ctypes.get_errno()
            self.assertTrue(arg0 == 0 and arg0_errno != 0, "arg0 zombie behavior did not match source")
        finally:
            child.wait(timeout=5)  # Sole known finite child is reaped; never kill or inspect another PID.
        self.assertEqual(child.returncode, 0)
        observation = {}
        with self.assertRaises(live.Rejected):
            live.launcher_read_metadata(lib, child.pid, observation)
        self.assertEqual(live.launcher_process_projection(observation)["decision"], "metadataUnavailable")


class LauncherAmendmentControls(unittest.TestCase):
    """Real CLI dispatch and finite own child; never invokes open or an App."""
    launch = DiagnosticRunnerControls.launch
    def setUp(self):
        import subprocess
        from unittest.mock import patch
        DiagnosticRunnerControls.setUp(self)
        self.children = []
        self.addCleanup(lambda: [child.wait(timeout=3) for child in self.children])
        self.ready_uuid = str(uuid.uuid4())
        self.d = self.root / "diagnostic-launch-amendment-1"
        self.old_ready = live.load(self.ready)
        live.exclusive_json(self.root / "diagnostic.consumed-ready.json", {
            "schemaVersion": 1, "diagnosticUUID": self.uuid, "purpose": self.purpose,
            "readyUUID": self.old_ready["readyUUID"],
            "readySHA256": live.digest(self.ready.read_bytes())})
        for leaf in ("diagnostic.launch.stdout", "diagnostic.launch.stderr"):
            (self.root / leaf).write_bytes(b"")
            (self.root / leaf).chmod(0o600)
        live.exclusive_json(self.root / "build.machine.json", {
            "status": "success", "stage": "completed", "buildVerified": True})
        machine_sha = live.digest((self.root / "build.machine.json").read_bytes())
        live.exclusive_json(self.root / "build.human.json", {
            "runUUID": self.uuid, "phase": "host-build-sign", "machineSHA256": machine_sha,
            "promptCount": 0, "actions": ["none"], "wholeStageObserved": True})
        self.pins = {leaf: live.digest((self.root / leaf).read_bytes()) for leaf in (
            "diagnostic.json", "build.machine.json", "build.human.json",
            "diagnostic.consumed-ready.json", "diagnostic.launch.stdout", "diagnostic.launch.stderr")}
        self.pins["binarySHA256"] = self.manifest["binarySHA256"]
        self.raw_popen = subprocess.Popen
        self.kind, self.child_rc, self.delay = "absent", 0, 0
        self.spawn_error = self.wait_error = False
        self.commands = []
        patch.object(live, "LAUNCHER_PINS", self.pins, create=True).start()
        self.process_state_function = live.launcher_process_state
        patch.object(live, "launcher_process_state", return_value={
            "processCheckComplete": True, "matchingAppCount": 0,
            "legacyWorkerSettled": True}, create=True).start()
        patch.object(live, "launcher_spawn", side_effect=self.spawn, create=True).start()
        self.old_bytes = {str(path): path.read_bytes() for path in self.root.rglob("*") if path.is_file()}

    def spawn(self, command, out, err):
        import subprocess
        self.commands.append(command)
        self.assertEqual(command, ["/usr/bin/open", "-W", "-a", str(self.app),
            "--env", "RIVET_DIAGNOSTIC_MANIFEST=" + str(self.path),
            "--env", "RIVET_DIAGNOSTIC_SHA256=" + live.digest(self.path.read_bytes()),
            "--args", "--launcher-amendment-only"])
        self.assertNotIn("--request", command)
        self.assertTrue((self.d / "consumed-ready.json").is_file())
        if self.spawn_error:
            raise OSError("PRIVATE_EXCEPTION")
        receipt = {"schemaVersion": 1, "diagnosticUUID": self.uuid,
            "legacyRunUUID": live.RETRY_PINS["runUUID"], "purpose": "diagnostic-only",
            "stage": "args", "status": "failure", "failureKind": "input",
            "manifestSHA256": live.digest(self.path.read_bytes()),
            "binarySHA256": self.manifest["binarySHA256"], "diagnosticCopy": True}
        payload = json.dumps(receipt)
        if self.kind == "invalid-binding":
            payload = json.dumps(dict(receipt, manifestSHA256="f" * 64))
        elif self.kind == "malformed":
            payload = "{PRIVATE_INVALID"
        code = ("import sys,time,pathlib,os; time.sleep(float(sys.argv[1])); "
                "p=pathlib.Path(sys.argv[2]); kind=sys.argv[3]; "
                "(p.write_text(sys.argv[4]),p.chmod(0o600)) if kind!='absent' else None; "
                "print(sys.argv[6:]); os.kill(os.getpid(),-int(sys.argv[5])) if int(sys.argv[5])<0 else None; sys.exit(int(sys.argv[5]))")
        child = self.raw_popen([__import__('sys').executable, "-c", code, str(self.delay),
            str(self.root / "diagnostic.machine.json"), self.kind, payload,
            str(self.child_rc), *command], stdout=out, stderr=err, stdin=subprocess.DEVNULL)
        self.children.append(child)
        if self.wait_error:
            from unittest.mock import Mock
            return Mock(pid=child.pid, wait=Mock(side_effect=OSError("PRIVATE_WAIT")))
        return child

    def cli(self, *extra, observe=False):
        import contextlib
        import io
        from unittest.mock import patch
        command = "launcher-amendment-observe" if observe else "launcher-amendment"
        args = [str(SCRIPT), command, "--manifest", str(self.path), "--manifest-sha",
                live.digest(self.path.read_bytes())]
        if not observe:
            args += ["--ready-uuid", self.ready_uuid, "--ready-confirmed"]
        output = io.StringIO()
        with patch.object(live.sys, "argv", args + list(extra)), contextlib.redirect_stdout(output):
            result = live.main()
        return result, json.loads(output.getvalue())

    def machine(self):
        return live.load(self.d / "launcher.machine.json")

    def test_native_zero_missing_receipt_is_unknown_and_actual_argv_is_sentinel(self):
        rc, output = self.cli()
        self.assertEqual(rc, 1)
        self.assertEqual(output["status"], "unknown")
        machine = self.machine()
        self.assertEqual(machine["nativeReturnCode"], 0)
        self.assertTrue(machine["nativeSettled"])
        self.assertEqual(machine["appReceiptValidity"], "absent")
        self.assertFalse(machine["hostConfirmed"])
        self.assertEqual(len(self.children), 1)
        for path, raw in self.old_bytes.items(): self.assertEqual(Path(path).read_bytes(), raw)
        self.assertNotIn("PRIVATE", json.dumps(output))
        self.assertEqual(self.cli()[0], 1)
        self.assertEqual(len(self.children), 1)

    def test_spawn_os_error_is_persisted_with_no_fabricated_return(self):
        self.spawn_error = True
        self.assertEqual(self.cli()[0], 1)
        m = self.machine()
        self.assertTrue(m["spawnAttempted"])
        self.assertFalse(m["nativeSpawned"])
        self.assertIsNone(m["nativeReturnCode"])
        self.assertEqual(m["exceptionKind"], "spawnOS")

    def test_native_nonzero_is_not_hidden(self):
        self.child_rc = 7
        self.assertEqual(self.cli()[0], 1)
        self.assertEqual(self.machine()["nativeReturnCode"], 7)

    def test_valid_receipt_is_unbound_and_does_not_confirm_host(self):
        self.kind = "valid"
        self.cli()
        m = self.machine()
        self.assertEqual(m["appReceiptValidity"], "valid")
        self.assertFalse(m["appReceiptAttributable"])
        self.assertFalse(m["hostConfirmed"])

    def test_malformed_and_bad_binding_are_invalid(self):
        self.kind = "malformed"
        self.cli()
        self.assertEqual(self.machine()["appReceiptValidity"], "invalid")
        self.assertFalse(self.machine()["hostConfirmed"])

    def test_wait_error_does_not_claim_native_settlement(self):
        self.wait_error = True
        self.cli()
        self.assertEqual(self.machine()["exceptionKind"], "waitOS")
        self.assertFalse(self.machine()["nativeSettled"])

    def test_timeout_does_not_kill_own_finite_child(self):
        from unittest.mock import patch
        self.delay = 0.15
        with patch.object(live, "LAUNCHER_WAIT_SECONDS", 0.01, create=True): self.cli()
        self.assertTrue(self.machine()["timedOut"])
        self.assertIsNone(self.children[0].poll())
        self.assertEqual(self.children[0].wait(timeout=3), 0)

    def test_primary_write_failure_has_fallback_and_nonzero_cli(self):
        from unittest.mock import patch
        original = getattr(live, "launcher_write", None)
        def fail(path, value):
            if Path(path).name == "launcher.machine.pending.json": raise OSError("PRIVATE_DISK")
            return original(path, value)
        with patch.object(live, "launcher_write", side_effect=fail, create=True): rc, out = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(out["primaryReceiptWritten"])
        self.assertTrue(out["callerResultWritten"])
        self.assertEqual(live.load(self.d / "caller-result.json")["humanBinding"], "caller-result")
        self.assertNotIn("PRIVATE", json.dumps(out))

    def test_partial_attempt_rejects_before_spawn(self):
        self.d.mkdir(mode=0o700)
        self.assertEqual(self.cli()[0], 1)
        self.assertEqual(self.commands, [])

    def test_invalid_receipt_context_binding_stays_unknown(self):
        self.kind = "invalid-binding"
        self.cli()
        m = self.machine()
        self.assertEqual(m["appReceiptValidity"], "invalid")
        self.assertEqual(m["status"], "unknown")
        self.assertFalse(m["appReceiptAttributable"])

    def test_unreadable_app_receipt_has_unknown_presence(self):
        from unittest.mock import patch
        self.kind = "valid"
        original = Path.read_bytes
        def read(path):
            if path == self.root / "diagnostic.machine.json": raise OSError("PRIVATE_READ")
            return original(path)
        with patch.object(Path, "read_bytes", read): self.cli()
        self.assertIsNone(self.machine()["appReceiptPresent"])
        self.assertEqual(self.machine()["appReceiptValidity"], "unreadable")
        self.assertFalse(self.machine()["hostConfirmed"])

    def test_actual_native_signal_is_recorded(self):
        self.child_rc = -15
        self.cli()
        self.assertEqual(self.machine()["nativeReturnCode"], -15)
        self.assertEqual(self.machine()["nativeSignal"], 15)

    def test_both_receipt_writes_failing_has_no_invented_sha(self):
        from unittest.mock import patch
        original = live.launcher_write
        def fail(path, value):
            if Path(path).name in ("launcher.machine.pending.json", "caller-result.pending.json"):
                raise OSError("PRIVATE_DISK")
            return original(path, value)
        with patch.object(live, "launcher_write", side_effect=fail): rc, out = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(out["primaryReceiptWritten"])
        self.assertFalse(out["callerResultWritten"])
        self.assertIsNone(out["bindingReceiptSHA256"])
        self.assertNotIn("PRIVATE", json.dumps(out))

    def test_partial_primary_fsync_failure_preserves_bytes_and_uses_fallback(self):
        from unittest.mock import patch
        original = live.launcher_write
        calls = []
        def fail(path, value):
            result = original(path, value)
            if Path(path).name == "launcher.machine.pending.json":
                calls.append(Path(path).read_bytes())
                raise OSError("PRIVATE_FSYNC")
            return result
        with patch.object(live, "launcher_write", side_effect=fail): rc, out = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(out["primaryReceiptWritten"])
        self.assertEqual(len(calls), 1)
        self.assertFalse((self.d / "launcher.machine.json").exists())
        self.assertEqual((self.d / "launcher.machine.pending.json").read_bytes(), calls[0])
        self.assertEqual(out["bindingReceiptSHA256"], live.digest((self.d / "caller-result.json").read_bytes()))
        args = ["--binding-receipt-sha", out["bindingReceiptSHA256"], "--prompt-count", "unknown",
                "--actions", "other", "--whole-observed", "no"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertEqual(live.load(self.d / "launcher.human.json")["bindingKind"], "caller-result")

    def test_uncommitted_primary_with_missing_caller_cannot_be_observed(self):
        from unittest.mock import patch
        original = live.launcher_write
        attempts = []
        def fail(path, value):
            leaf = Path(path).name
            if leaf == "caller-result.pending.json":
                raise OSError("PRIVATE_FALLBACK_BEFORE_WRITE")
            result = original(path, value)
            if leaf == "launcher.machine.pending.json":
                attempts.append(Path(path).read_bytes())
                raise OSError("PRIVATE_PRIMARY_FSYNC")
            return result
        with patch.object(live, "launcher_write", side_effect=fail): rc, output = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(output["primaryReceiptWritten"])
        self.assertFalse(output["callerResultWritten"])
        self.assertIsNone(output["bindingReceiptSHA256"])
        self.assertEqual(len(attempts), 1)
        primary = self.d / "launcher.machine.pending.json"
        self.assertFalse((self.d / "launcher.machine.json").exists())
        self.assertEqual(primary.read_bytes(), attempts[0])
        self.assertFalse((self.d / "caller-result.json").exists())
        args = ["--binding-receipt-sha", live.digest(primary.read_bytes()), "--prompt-count", "0",
                "--actions", "none", "--whole-observed", "yes"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertFalse((self.d / "launcher.human.json").exists())
        self.assertEqual(primary.read_bytes(), attempts[0])

    def test_inconsistent_caller_cannot_select_primary_fallback(self):
        self.cli()
        caller_path = self.d / "caller-result.json"
        original = caller_path.read_bytes()
        primary_sha = live.digest((self.d / "launcher.machine.json").read_bytes())
        variants = [dict(live.load(caller_path), humanBinding="none"),
                    dict(live.load(caller_path), primaryMachineSHA256="f" * 64),
                    dict(live.load(caller_path), primaryReceiptWritten=False,
                         primaryMachineSHA256=None, humanBinding="primary", failureKind="receiptWrite")]
        for value in variants:
            caller_path.write_text(json.dumps(value))  # Corruption only in this owned fixture.
            args = ["--binding-receipt-sha", primary_sha, "--prompt-count", "0",
                    "--actions", "none", "--whole-observed", "yes"]
            self.assertEqual(self.cli(*args, observe=True)[0], 1)
            self.assertFalse((self.d / "launcher.human.json").exists())
        caller_path.write_bytes(original)

    def test_uncommitted_complete_fallback_cannot_be_observed(self):
        from unittest.mock import patch
        original = live.launcher_write
        leftovers = []
        def fail(path, value):
            leaf = Path(path).name
            if leaf in ("launcher.machine.json", "launcher.machine.pending.json"):
                raise OSError("PRIVATE_PRIMARY_BEFORE_WRITE")
            result = original(path, value)
            if leaf in ("caller-result.json", "caller-result.pending.json"):
                leftovers.append((Path(path), Path(path).read_bytes()))
                raise OSError("PRIVATE_FALLBACK_FSYNC")
            return result
        with patch.object(live, "launcher_write", side_effect=fail): rc, output = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(output["primaryReceiptWritten"])
        self.assertFalse(output["callerResultWritten"])
        self.assertIsNone(output["bindingReceiptSHA256"])
        self.assertEqual(len(leftovers), 1)
        path, raw = leftovers[0]
        args = ["--binding-receipt-sha", live.digest(raw), "--prompt-count", "unknown",
                "--actions", "other", "--whole-observed", "no"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertFalse((self.d / "launcher.human.json").exists())
        self.assertEqual(path.read_bytes(), raw)

    def pending_sync_fault(self, leaf, directory=False):
        from unittest.mock import patch
        original = live.os.fsync
        self.sync_failure_bytes = []
        def sync(fd):
            target = self.d / leaf
            if target.exists() and not self.sync_failure_bytes:
                info = os.fstat(fd)
                selected = self.d.stat() if directory else target.stat()
                if (info.st_dev, info.st_ino) == (selected.st_dev, selected.st_ino):
                    self.sync_failure_bytes.append(target.read_bytes())
                    raise OSError("PRIVATE_PREPUBLICATION_FSYNC")
            return original(fd)
        return patch.object(live.os, "fsync", side_effect=sync)

    def assert_fallback_sync_failure_is_unpublished(self, directory):
        from unittest.mock import patch
        original = live.launcher_write
        def no_primary(path, value):
            if Path(path).name == "launcher.machine.pending.json": raise OSError("PRIVATE_PRIMARY")
            return original(path, value)
        with patch.object(live, "launcher_write", side_effect=no_primary), \
                self.pending_sync_fault("caller-result.pending.json", directory):
            rc, result = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(result["primaryReceiptWritten"])
        self.assertFalse(result["callerResultWritten"])
        self.assertIsNone(result["bindingReceiptSHA256"])
        self.assertEqual(len(self.sync_failure_bytes), 1)
        raw = self.sync_failure_bytes[0]
        self.assertIsInstance(json.loads(raw), dict)  # Complete bytes, still not published.
        self.assertFalse((self.d / "caller-result.json").exists())
        args = ["--binding-receipt-sha", live.digest(raw), "--prompt-count", "unknown",
                "--actions", "other", "--whole-observed", "no"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertFalse((self.d / "launcher.human.json").exists())
        self.assertEqual((self.d / "caller-result.pending.json").read_bytes(), raw)

    def test_fallback_payload_fsync_failure_cannot_publish_or_bind(self):
        self.assert_fallback_sync_failure_is_unpublished(False)

    def test_fallback_directory_fsync_failure_cannot_publish_or_bind(self):
        self.assert_fallback_sync_failure_is_unpublished(True)

    def assert_primary_sync_failure_binds_only_published_fallback(self, directory):
        with self.pending_sync_fault("launcher.machine.pending.json", directory): rc, result = self.cli()
        self.assertEqual(rc, 2)
        self.assertFalse(result["primaryReceiptWritten"])
        self.assertTrue(result["callerResultWritten"])
        self.assertFalse((self.d / "launcher.machine.json").exists())
        self.assertIsInstance(json.loads(self.sync_failure_bytes[0]), dict)
        args = ["--binding-receipt-sha", result["bindingReceiptSHA256"], "--prompt-count", "0",
                "--actions", "none", "--whole-observed", "yes"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertEqual(live.load(self.d / "launcher.human.json")["bindingKind"], "caller-result")

    def test_primary_payload_fsync_failure_keeps_only_fallback_bindable(self):
        self.assert_primary_sync_failure_binds_only_published_fallback(False)

    def test_primary_directory_fsync_failure_keeps_only_fallback_bindable(self):
        self.assert_primary_sync_failure_binds_only_published_fallback(True)

    def test_published_primary_remains_bindable_after_caller_sync_failure(self):
        with self.pending_sync_fault("caller-result.pending.json"): rc, result = self.cli()
        self.assertEqual(rc, 2)
        self.assertTrue(result["primaryReceiptWritten"])
        self.assertFalse(result["callerResultWritten"])
        sha = live.digest((self.d / "launcher.machine.json").read_bytes())
        self.assertEqual(result["bindingReceiptSHA256"], sha)
        self.assertFalse((self.d / "caller-result.json").exists())
        args = ["--binding-receipt-sha", sha, "--prompt-count", "0", "--actions", "none", "--whole-observed", "yes"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertEqual(live.load(self.d / "launcher.human.json")["bindingKind"], "primary")

    def test_publication_never_overwrites_existing_final(self):
        self.d.mkdir(mode=0o700)
        target = self.d / "launcher.machine.json"
        target.write_bytes(b"FOREIGN_KEEP")
        target.chmod(0o600)
        with self.assertRaises(live.Rejected): live.launcher_publish(target, {"status": "unknown"})
        self.assertEqual(target.read_bytes(), b"FOREIGN_KEEP")
        self.assertFalse((self.d / "launcher.machine.pending.json").exists())
        from unittest.mock import patch
        other = self.d / "caller-result.json"
        raw_link = live.os.link
        def collision(source, destination, **kwargs):
            Path(destination).write_bytes(b"RACE_KEEP")
            Path(destination).chmod(0o600)
            return raw_link(source, destination, **kwargs)
        with patch.object(live.os, "link", side_effect=collision):
            with self.assertRaises(FileExistsError): live.launcher_publish(other, {"status": "unknown"})
        self.assertEqual(other.read_bytes(), b"RACE_KEEP")
        self.assertTrue((self.d / "caller-result.pending.json").exists())

    def test_wrong_publication_inode_rejects_human_even_with_same_json(self):
        self.cli()
        pending = self.d / "launcher.machine.pending.json"
        raw = pending.read_bytes()
        pending.unlink()  # Corrupt only this owned ordinary fixture.
        pending.write_bytes(raw)
        pending.chmod(0o600)
        args = ["--binding-receipt-sha", live.digest(raw), "--prompt-count", "0", "--actions", "none", "--whole-observed", "yes"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertFalse((self.d / "launcher.human.json").exists())

    def test_inconsistent_publication_bytes_reject_human(self):
        from unittest.mock import patch
        self.cli()
        raw = (self.d / "launcher.machine.json").read_bytes()
        original = Path.read_bytes
        def read(path):
            if path == self.d / "launcher.machine.pending.json": return b"PRIVATE_INCONSISTENT"
            return original(path)
        args = ["--binding-receipt-sha", live.digest(raw), "--prompt-count", "0", "--actions", "none", "--whole-observed", "yes"]
        with patch.object(Path, "read_bytes", read): self.assertEqual(self.cli(*args, observe=True)[0], 1)
        self.assertFalse((self.d / "launcher.human.json").exists())

    def native_guard_fixture(self, failure, error=0, raised=False, boundary=False):
        """Only fake ctypes providers; no Darwin process API is called."""
        import ctypes
        import struct
        from unittest.mock import Mock, patch
        lib, libc = Mock(), Mock()
        payload = getattr(self, "native_payload", struct.pack("=i", -1) + b"PRIVATE_ARGV_ENV_PATH_PID\0")
        calls = {"list": 0, "metadata": 0, "path": 0, "args": 0}
        self.native_calls = calls
        def outcome(point, normal):
            if point == failure:
                ctypes.set_errno(error)
                if raised: raise OSError(error or None, "PRIVATE_RAW_ERROR", "/PRIVATE_PATH")
                return -1 if point.startswith("args") else 0
            return normal
        def list_pids(kind, uid, buffer, size):
            self.assertEqual(kind, 4)
            self.assertEqual(uid, os.getuid())
            calls["list"] += 1
            if buffer is None: return outcome("list-size", 8)
            selected_pids = getattr(self, "native_pids", [12345])
            for index, pid in enumerate(selected_pids): buffer[index] = pid
            if boundary: return size
            return outcome("list-read", 4 * len(selected_pids))
        def pid_info(pid, flavor, arg, buffer, size):
            calls["metadata"] += 1
            self.assertEqual((flavor, arg), (3, 1))
            info_type = live.launcher_bsdinfo_type()
            self.assertEqual(size, ctypes.sizeof(info_type))
            info = ctypes.cast(buffer, ctypes.POINTER(info_type)).contents
            info.pbi_pid, info.pbi_uid = pid, os.getuid()
            info.pbi_status = getattr(self, "native_status", 3)
            info.pbi_start_tvsec, info.pbi_start_tvusec = 123, 456
            raw = getattr(self, "native_name", b"open")
            info.pbi_name = raw
            info.pbi_comm = raw[:15]
            changes = getattr(self, "metadata_changes", [{}])
            for key, value in changes[min(calls["metadata"] - 1, len(changes) - 1)].items():
                setattr(info, key, value)
            metadata_failure = getattr(self, "metadata_failures", {}).get(calls["metadata"])
            if metadata_failure is not None:
                result, number, exception = metadata_failure
                ctypes.set_errno(number)
                if exception == "os": raise OSError(number, "PRIVATE_POST_METADATA")
                if exception == "unknown": raise RuntimeError("PRIVATE_POST_UNKNOWN")
                return result
            return outcome("metadata", getattr(self, "native_metadata_size", size))
        def pid_path(pid, buffer, size):
            calls["path"] += 1
            paths = getattr(self, "native_paths", [b"/usr/bin/open"])
            buffer.value = paths[min(calls["path"] - 1, len(paths) - 1)]
            if failure == "path" and calls["path"] != getattr(self, "path_failure_pass", calls["path"]):
                return len(buffer.value)
            return outcome("path", len(buffer.value))
        def args(mib, count, buffer, length, new, size):
            calls["args"] += 1
            payloads = getattr(self, "native_payloads", [payload])
            selected_payload = payloads[min((calls["args"] - 1) // 2, len(payloads) - 1)]
            pointer = ctypes.cast(length, ctypes.POINTER(ctypes.c_size_t))
            if buffer is None:
                pointer[0] = len(selected_payload)
                return outcome("args-size", 0)
            ctypes.memmove(buffer, selected_payload, len(selected_payload))
            pointer[0] = len(selected_payload)
            return outcome("args-read", 0)
        lib.proc_listpids.side_effect = list_pids
        lib.proc_pidinfo.side_effect = pid_info
        lib.proc_pidpath.side_effect = pid_path
        libc.sysctl.side_effect = args
        return (patch.object(live.platform, "system", return_value="Darwin"),
                patch.object(ctypes, "CDLL", side_effect=[lib, libc]),
                patch.object(live, "launcher_process_state", wraps=self.process_state_function))

    def run_native_guard(self, failure, error=0, raised=False, boundary=False):
        import contextlib
        with contextlib.ExitStack() as stack:
            for patcher in self.native_guard_fixture(failure, error, raised, boundary): stack.enter_context(patcher)
            rc, result = self.cli()
        self.assertEqual(rc, 1)
        self.assertFalse(self.d.exists())
        self.assertEqual(self.commands, [])
        self.assertNotIn("PRIVATE", json.dumps(result))
        return result

    def assert_unrelated_name_skips_path(self, name):
        import contextlib
        self.native_name = name
        with contextlib.ExitStack() as stack:
            for patcher in self.native_guard_fixture("none"): stack.enter_context(patcher)
            rc, result = self.cli()
        self.assertEqual(rc, 1)  # Native observation remains unknown, never host success.
        self.assertTrue(self.d.exists())
        self.assertEqual(self.native_calls, {"list": 2, "metadata": 1, "path": 0, "args": 0})
        self.assertFalse(self.machine()["hostConfirmed"])
        self.assertNotIn(name.decode(), json.dumps(result))

    def test_name_positive_unrelated_skips_path_and_args_actual_cli(self):
        self.assert_unrelated_name_skips_path(b"unrelated")

    def test_name_disjoint_15_bytes_is_not_global_candidate(self):
        self.assert_unrelated_name_skips_path(b"z" * 15)

    def test_name_disjoint_31_bytes_is_not_global_candidate(self):
        self.assert_unrelated_name_skips_path(b"z" * 31)

    def test_name_compatible_alias_prefix_and_ambiguity_still_require_path(self):
        import errno
        for name in (b"open", b"op", self.app.stem.encode(), self.app.stem.encode()[:15],
                     b"CredentialStorageProbe", b"CredentialStorageProbe"[:15],
                     "未知".encode()):
            with self.subTest(name=name):
                self.native_name = name
                result = self.run_native_guard("path", errno.ESRCH)
                self.assertEqual(result["guardPoint"], "snapshot-path")
                self.assertEqual(result["errnoKind"], "notFound")
                self.assertEqual(self.native_calls["path"], 1)
                self.assertEqual(self.native_calls["args"], 0)

    def test_name_failures_formats_and_errno_are_guarded_without_leaks(self):
        import errno
        for failure, raw, returned, number, raised in (
                ("metadata", b"PRIVATE_NAME", 136, errno.ESRCH, False),
                ("metadata", b"PRIVATE_NAME", 136, errno.ENOENT, False),
                ("metadata", b"PRIVATE_NAME", 136, errno.EACCES, True),
                ("none", b"", 136, 0, False),
                ("none", b"\xff", 136, 0, False),
                ("none", b"x" * 32, 136, 0, False),
                ("none", b"PRIVATE_NAME", 135, 0, False),
                ("none", b"PRIVATE_NAME", None, 0, False)):
            with self.subTest(failure=failure, returned=returned, number=number):
                self.native_name, self.native_metadata_size = raw, returned
                result = self.run_native_guard(failure, number, raised)
                self.assertEqual(result["guardPoint"], "snapshot-metadata")
                self.assertEqual(self.native_calls["path"], 0)
                self.assertEqual(self.native_calls["args"], 0)
                self.assertNotIn("PRIVATE", json.dumps(result))

    def test_fullinfo_zombie_is_positive_exclusion_even_with_empty_name(self):
        import contextlib
        self.native_status, self.native_name = 5, b""
        with contextlib.ExitStack() as stack:
            for patcher in self.native_guard_fixture("none"): stack.enter_context(patcher)
            rc, result = self.cli()
        self.assertEqual(rc, 1)
        evidence = result["processEvidence"]
        self.assertTrue(evidence["zombieObserved"] and evidence["zombieExcluded"] and evidence["checksFinished"])
        self.assertFalse(evidence["instanceChecked"] or evidence["conflictObserved"])
        self.assertEqual(evidence["decision"], "zombieExcluded")
        self.assertEqual(self.native_calls, {"list": 2, "metadata": 1, "path": 0, "args": 0})

    def test_fullinfo_invalid_identity_status_starttime_and_size_reject(self):
        changes = [{"pbi_pid": 7}, {"pbi_uid": os.getuid() + 1}, {"pbi_status": 1},
                   {"pbi_status": 100}, {"pbi_start_tvsec": 0}, {"pbi_start_tvusec": 1000000}]
        for change in changes:
            with self.subTest(change=change):
                self.metadata_changes = [change]
                result = self.run_native_guard("none")
                self.assertEqual(result["processEvidence"]["decision"], "metadataInvalid")
                self.assertEqual(self.native_calls["path"], 0)
        self.metadata_changes = [{}]
        for size in (0, 135, 137, None):
            self.native_metadata_size = size
            result = self.run_native_guard("none")
            self.assertFalse(result["processEvidence"]["checksFinished"])

    def test_fullinfo_candidate_consistent_two_classifications_and_instance(self):
        import contextlib
        self.native_name, self.native_paths = b"CredentialStorageProbe", [b"/fixture/other"]
        with contextlib.ExitStack() as stack:
            for patcher in self.native_guard_fixture("none"): stack.enter_context(patcher)
            rc, result = self.cli()
        self.assertEqual(rc, 1)
        self.assertEqual(self.native_calls, {"list": 2, "metadata": 2, "path": 2, "args": 0})
        self.assertTrue(result["processEvidence"]["instanceChecked"])
        self.assertEqual(result["processEvidence"]["decision"], "candidateOther")

    def test_fullinfo_instance_and_classification_change_reject_actual_cli(self):
        self.native_name, self.native_paths = b"CredentialStorageProbe", [b"/fixture/other"]
        for change in ({"pbi_start_tvsec": 124}, {"pbi_status": 2}, {"pbi_name": b"different"},
                       {"pbi_comm": b"different"}, {"pbi_uid": os.getuid() + 1}):
            with self.subTest(change=change):
                self.metadata_changes = [{}, change]
                result = self.run_native_guard("none")
                self.assertIn(result["processEvidence"]["decision"],
                              {"instanceChanged", "classificationChanged", "metadataInvalid"})
                self.assertFalse(result["processEvidence"]["checksFinished"])
        self.metadata_changes = [{}]
        self.native_paths = [b"/fixture/first", b"/fixture/second"]
        result = self.run_native_guard("none")
        self.assertEqual(result["processEvidence"]["decision"], "classificationChanged")

    def test_fullinfo_target_host_and_open_are_conflicts_without_more_reads(self):
        import struct
        from unittest.mock import patch
        for target in ("host", "open"):
            with self.subTest(target=target):
                self.native_name = b"CredentialStorageProbe" if target == "host" else b"open"
                self.native_paths = [str(self.app / "Contents/MacOS/CredentialStorageProbe").encode()
                                     if target == "host" else b"/usr/bin/open"]
                self.native_payload = struct.pack("=i", 1) + b"/usr/bin/open\0\0/usr/bin/open\0"
                with patch.object(live, "launcher_open_arguments", return_value=live.launch_command(
                        self.legacy / "current/CredentialStorageProbe.app",
                        self.legacy / "private/save-a.request.json",
                        live.digest((self.legacy / "private/save-a.request.json").read_bytes()))):
                    result = self.run_native_guard("none")
                self.assertEqual(result["processEvidence"]["decision"], "targetHost" if target == "host" else "targetOpen")
                self.assertTrue(result["processEvidence"]["conflictObserved"])
                self.assertEqual(self.native_calls["metadata"], 1)
                self.assertEqual(self.native_calls["path"], 1)

    def test_fullinfo_selected_open_reads_both_argv_and_rejects_changes(self):
        import struct
        def argv_payload(argument):
            return struct.pack("=i", 2) + b"/usr/bin/open\0\0/usr/bin/open\0" + argument + b"\0"
        self.native_payloads = [argv_payload(b"first"), argv_payload(b"second")]
        result = self.run_native_guard("none")
        self.assertEqual(result["processEvidence"]["decision"], "classificationChanged")
        self.assertEqual(self.native_calls["args"], 4)
        self.assertEqual(self.native_calls["metadata"], 1)

    def test_fullinfo_aggregate_keeps_positive_zombie_before_later_path_failure(self):
        import errno
        self.native_pids = [12345, 12346]
        self.metadata_changes = [{"pbi_status": 5}, {}]
        result = self.run_native_guard("path", errno.ENOENT)
        evidence = result["processEvidence"]
        self.assertTrue(evidence["zombieObserved"] and evidence["zombieExcluded"])
        self.assertFalse(evidence["checksFinished"])
        self.assertEqual(evidence["decision"], "pathUnavailable")
        self.assertEqual(self.native_calls["metadata"], 3)  # Initial zombie, next live A, one failed-path post.

    def test_fullinfo_process_evidence_is_finite_and_resets_on_next_cli(self):
        from unittest.mock import patch
        self.assertEqual(live.launcher_process_projection({"_process": {"decision": "PRIVATE"}}),
                         live.launcher_process_defaults())
        self.assert_unrelated_name_skips_path(b"unrelated")
        rc, result = self.cli()  # Spent fixture must reject before process checks.
        self.assertEqual(rc, 1)
        self.assertEqual(result["processEvidence"], live.launcher_process_defaults())
        with patch.object(live, "launcher_context", side_effect=ValueError("PRIVATE_METADATA")):
            self.assertNotIn("PRIVATE", json.dumps(self.cli()[1]))

    def assert_path_post_zombie(self, pass_number):
        import contextlib
        import errno
        self.native_name, self.native_paths = b"CredentialStorageProbe", [b"/fixture/other"]
        self.path_failure_pass = pass_number
        self.metadata_changes = [{}, {"pbi_status": 5}]
        with contextlib.ExitStack() as stack:
            for patcher in self.native_guard_fixture("path", errno.ESRCH): stack.enter_context(patcher)
            rc, result = self.cli()
        self.assertEqual(rc, 1)
        self.assertTrue(self.d.exists())
        evidence = result["pathFailureEvidence"]
        self.assertEqual(evidence["pass"], "first" if pass_number == 1 else "second")
        self.assertEqual(evidence["postState"], "zombieSame")
        self.assertEqual(evidence["pathErrno"], "ESRCH")
        self.assertEqual(evidence["pathFailure"], {"guardPoint": "snapshot-path", "apiOutcome": "returned",
                                                 "apiReturn": "zero", "errnoKind": "notFound"})
        self.assertEqual(self.native_calls["metadata"], 2)
        self.assertEqual(self.native_calls["path"], pass_number)
        self.assertTrue(result["processEvidence"]["zombieExcluded"])

    def test_path_post_zombie_first_pass_excludes_without_retry(self):
        self.assert_path_post_zombie(1)

    def test_path_post_zombie_second_pass_excludes_without_normal_b(self):
        self.assert_path_post_zombie(2)

    def test_path_post_states_first_second_preserve_original_failure(self):
        import errno
        self.native_name, self.native_paths = b"CredentialStorageProbe", [b"/fixture/other"]
        states = [("liveSame", {}, None), ("instanceChanged", {"pbi_start_tvsec": 124}, None),
                  ("instanceChanged", {"pbi_uid": os.getuid() + 1}, None),
                  ("classificationChanged", {"pbi_name": b"different"}, None),
                  ("classificationChanged", {"pbi_status": 2}, None),
                  ("permissionDenied", {}, (0, errno.EPERM, "os")),
                  ("unavailable", {}, (0, errno.ESRCH, None)),
                  ("invalid", {}, (135, 0, None)), ("unknown", {}, (0, 0, "unknown")),
                  ("instanceChanged", {"pbi_start_tvsec": 124, "pbi_status": 5}, None)]
        for pass_number in (1, 2):
            for state, change, failure in states:
                with self.subTest(pass_number=pass_number, state=state, change=change):
                    self.path_failure_pass = pass_number
                    self.metadata_changes, self.metadata_failures = [{}, change], {2: failure} if failure else {}
                    result = self.run_native_guard("path", errno.ENOENT)
                    self.assertEqual(result["pathFailureEvidence"]["postState"], state)
                    self.assertEqual(result["guardPoint"], "snapshot-path")
                    self.assertEqual(result["apiReturn"], "zero")
                    self.assertEqual(result["errnoKind"], "notFound")
                    self.assertEqual(result["pathFailureEvidence"]["pathErrno"], "ENOENT")
                    self.assertEqual(self.native_calls["metadata"], 2)
                    self.assertEqual(self.native_calls["path"], pass_number)
                    self.assertFalse(result["processEvidence"]["zombieExcluded"])

    def test_path_post_errno_symbols_are_native_and_not_inferred(self):
        import errno
        from unittest.mock import patch
        for number, symbol in ((errno.ENOENT, "ENOENT"), (errno.ESRCH, "ESRCH"),
                               (errno.EPERM, "EPERM"), (errno.EACCES, "EACCES"),
                               (0, "zero"), (errno.EIO, "other")):
            with self.subTest(symbol=symbol):
                result = self.run_native_guard("path", number)
                self.assertEqual(result["pathFailureEvidence"]["pathErrno"], symbol)
                self.assertEqual(result["pathFailureEvidence"]["pathFailure"]["errnoKind"], result["errnoKind"])
        with patch("ctypes.get_errno", return_value=None):
            result = self.run_native_guard("path", errno.ENOENT)
        self.assertEqual(result["pathFailureEvidence"]["pathErrno"], "unknown")

    def test_path_post_name_source_classification_does_not_change_prefilter(self):
        import errno
        cases = [(b"CredentialStorageProbe", b"CredentialStora", "full"),
                 (b"", b"CredentialStora", "alias15"),
                 (b"Cred", b"Cred", "prefixOnly"), ("未知".encode(), b"unknown", "ambiguous")]
        for name, comm, expected in cases:
            with self.subTest(expected=expected):
                self.metadata_changes = [{"pbi_name": name, "pbi_comm": comm}]
                result = self.run_native_guard("path", errno.ESRCH)
                self.assertEqual(result["pathFailureEvidence"]["nameMatchKind"], expected)
        long_target = "LongTargetNameWithMoreThanThirtyXYZ"
        record = {"pbi_name": long_target.encode()[:31] + b"\0", "pbi_comm": long_target.encode()[:15] + b"\0"}
        self.assertEqual(live.launcher_name_match_kind(record, {"/fixture/" + long_target}), "alias31")

    def test_path_post_zombie_then_later_failure_keeps_latest_event(self):
        import errno
        self.native_pids = [12345, 12346]
        self.native_name = b"CredentialStorageProbe"
        self.metadata_changes = [{}, {"pbi_status": 5}, {}, {}]
        result = self.run_native_guard("path", errno.ESRCH)
        self.assertTrue(result["processEvidence"]["zombieExcluded"])
        self.assertEqual(result["pathFailureEvidence"]["postState"], "liveSame")
        self.assertEqual(result["pathFailureEvidence"]["pass"], "first")
        self.assertEqual(self.native_calls, {"list": 2, "metadata": 4, "path": 2, "args": 0})

    def test_path_post_older_checked_instance_does_not_confirm_failed_iteration(self):
        import errno
        self.native_pids = [12345, 12346]
        self.native_name, self.native_paths = b"CredentialStorageProbe", [b"/fixture/other"]
        self.path_failure_pass = 3
        self.metadata_failures = {4: (0, errno.ESRCH, None)}
        result = self.run_native_guard("path", errno.ENOENT)
        self.assertTrue(result["processEvidence"]["instanceChecked"])
        self.assertEqual(result["pathFailureEvidence"]["postState"], "unavailable")
        self.assertEqual(result["pathFailureEvidence"]["pass"], "first")
        self.assertEqual(result["pathFailureEvidence"]["pathErrno"], "ENOENT")
        self.assertEqual(self.native_calls["metadata"], 4)

    def test_path_post_defaults_reset_and_older_aggregate_are_not_attribution(self):
        import errno
        self.native_pids = [12344, 12345]
        self.metadata_changes = [{"pbi_name": b"other", "pbi_comm": b"other"}, {}]
        result = self.run_native_guard("path", errno.ENOENT)
        self.assertTrue(result["processEvidence"]["noncandidateExcluded"])
        self.assertEqual(result["pathFailureEvidence"]["postState"], "liveSame")
        rc, result = self.cli("--ready-uuid", "invalid")
        self.assertEqual(rc, 1)
        self.assertEqual(result["pathFailureEvidence"], live.launcher_path_failure_defaults())

    def test_preflight_native_errno_and_fixed_guardpoints(self):
        import errno
        cases = [("list-size", errno.EACCES, "snapshot-list-size", "zero", "permissionDenied"),
                 ("list-read", 0, "snapshot-list-read", "zero", "unknown"),
                 ("path", errno.ESRCH, "snapshot-path", "zero", "notFound"),
                 ("args-size", errno.ENOSYS, "snapshot-args-size", "negative", "unsupported"),
                 ("args-read", errno.EINTR, "snapshot-args-read", "negative", "interrupted")]
        for failure, error, point, returned, kind in cases:
            with self.subTest(point=point):
                result = self.run_native_guard(failure, error)
                self.assertEqual(result["guardPoint"], point)
                self.assertEqual(result["apiOutcome"], "returned")
                self.assertEqual(result["apiReturn"], returned)
                self.assertEqual(result["errnoKind"], kind)

    def test_preflight_unknown_errno_exceptions_and_decode_do_not_leak(self):
        import ctypes
        import errno
        for error, kind in ((0, "unknown"), (errno.EIO, "other"), (errno.EPERM, "permissionDenied")):
            result = self.run_native_guard("path", error, raised=True)
            self.assertEqual(result["guardPoint"], "snapshot-path")
            self.assertEqual(result["apiOutcome"], "exception")
            self.assertEqual(result["apiReturn"], "notAvailable")
            self.assertEqual(result["errnoKind"], kind)
        ctypes.set_errno(errno.EACCES)
        result = self.run_native_guard("path", 0)
        self.assertEqual(result["errnoKind"], "unknown")
        result = self.run_native_guard("decode")
        self.assertEqual(result["guardPoint"], "snapshot-args-decode")
        self.assertEqual(result["apiOutcome"], "guard")
        self.assertEqual(result["errnoKind"], "none")
        result = self.run_native_guard("none", boundary=True)
        self.assertEqual(result["guardPoint"], "snapshot-list-read")
        self.assertEqual(result["apiReturn"], "positive")
        self.assertEqual(result["errnoKind"], "none")

    def test_preflight_context_ready_quota_and_match_are_isolated(self):
        from unittest.mock import patch
        self.pins["diagnostic.json"] = "f" * 64
        self.assertEqual(self.cli()[1]["guardPoint"], "context")
        self.pins["diagnostic.json"] = live.digest(self.path.read_bytes())
        saved = self.ready_uuid
        self.ready_uuid = self.old_ready["readyUUID"]
        result = self.cli()[1]
        self.assertEqual(result["guardPoint"], "ready")
        self.assertEqual(result["errnoKind"], "none")
        self.ready_uuid = saved
        self.d.mkdir(mode=0o700)
        self.assertEqual(self.cli()[1]["guardPoint"], "quota")
        self.d.rmdir()  # Ordinary fixture only, never a real spent attempt.
        with patch.object(live, "launcher_process_state", return_value={"processCheckComplete": True,
                "matchingAppCount": 1, "legacyWorkerSettled": True}): result = self.cli()[1]
        self.assertEqual(result["guardPoint"], "snapshot-match")
        self.assertEqual(result["apiOutcome"], "guard")
        self.assertEqual(result["apiReturn"], "notAvailable")
        self.assertFalse(self.d.exists())

    def test_preflight_file_source_and_output_exceptions_are_finite(self):
        import errno
        from unittest.mock import patch
        original_read, original_mkdir = Path.read_bytes, Path.mkdir
        targets = [(self.legacy / "private/save-a.request.json", "request"), (SCRIPT, "caller-source")]
        for selected, point in targets:
            def read(path):
                if path == selected: raise OSError(errno.EACCES, "PRIVATE_ERROR", "/PRIVATE_ID")
                return original_read(path)
            with patch.object(Path, "read_bytes", read): rc, result = self.cli()
            self.assertEqual(rc, 1)
            self.assertEqual(result["guardPoint"], point)
            self.assertEqual(result["errnoKind"], "permissionDenied")
            self.assertNotIn("PRIVATE", json.dumps(result))
        def mkdir(path, *args, **kwargs):
            if path == self.d: raise OSError(errno.EPERM, "PRIVATE_OUTPUT")
            return original_mkdir(path, *args, **kwargs)
        with patch.object(Path, "mkdir", mkdir): result = self.cli()[1]
        self.assertEqual(result["guardPoint"], "output")
        self.assertFalse(self.d.exists())

    def test_preflight_platform_library_open_path_and_success_schema(self):
        import ctypes
        from unittest.mock import patch
        with patch.object(live, "launcher_process_state", wraps=self.process_state_function), \
             patch.object(live.platform, "system", return_value="OTHER_PRIVATE"):
            self.assertEqual(self.cli()[1]["guardPoint"], "snapshot-platform")
        with patch.object(live, "launcher_process_state", wraps=self.process_state_function), \
             patch.object(live.platform, "system", return_value="Darwin"), \
             patch.object(ctypes, "CDLL", side_effect=OSError(None, "PRIVATE_LIBRARY")):
            result = self.cli()[1]
        self.assertEqual(result["guardPoint"], "snapshot-library")
        self.assertEqual(result["errnoKind"], "unknown")
        original = Path.resolve
        def resolve(path, *args, **kwargs):
            if path == Path("/usr/bin/open"): raise OSError(None, "PRIVATE_OPEN_PATH")
            return original(path, *args, **kwargs)
        import contextlib
        with contextlib.ExitStack() as stack:
            for patcher in self.native_guard_fixture("none"): stack.enter_context(patcher)
            stack.enter_context(patch.object(Path, "resolve", resolve))
            result = self.cli()[1]
        self.assertEqual(result["guardPoint"], "snapshot-open-path")
        self.assertNotIn("PRIVATE", json.dumps(result))
        rc, result = self.cli()  # Existing ordinary child seam; trusted-D schema is unchanged.
        self.assertEqual(rc, 1)
        self.assertEqual(set(result), {"status", "failureKind", "primaryReceiptWritten",
                                      "callerResultWritten", "bindingReceiptSHA256", "processEvidence", "pathFailureEvidence"})

    def test_pin_drift_and_existing_symlink_reject_before_any_child(self):
        self.pins["diagnostic.json"] = "f" * 64
        self.assertEqual(self.cli()[0], 1)
        self.assertFalse(self.d.exists())
        self.assertEqual(self.commands, [])
        self.pins["diagnostic.json"] = live.digest(self.path.read_bytes())
        self.d.symlink_to(self.legacy, target_is_directory=True)
        self.assertEqual(self.cli()[0], 1)
        self.assertEqual(self.commands, [])

    def test_old_ready_and_ambiguous_worker_reject_without_attempt(self):
        from unittest.mock import patch
        self.ready_uuid = self.old_ready["readyUUID"]
        self.assertEqual(self.cli()[0], 1)
        self.assertFalse(self.d.exists())
        self.ready_uuid = str(uuid.uuid4())
        with patch.object(live, "launcher_process_state", side_effect=live.Rejected):
            self.assertEqual(self.cli()[0], 1)
        self.assertFalse(self.d.exists())
        self.assertEqual(self.commands, [])

    def test_known_open_or_host_match_blocks_entrypoint(self):
        from unittest.mock import patch
        for state in ({"processCheckComplete": True, "matchingAppCount": 1, "legacyWorkerSettled": True},
                      {"processCheckComplete": True, "matchingAppCount": 0, "legacyWorkerSettled": False},
                      {"processCheckComplete": False, "matchingAppCount": 0, "legacyWorkerSettled": True}):
            with patch.object(live, "launcher_process_state", return_value=state):
                self.assertEqual(self.cli()[0], 1)
                self.assertFalse(self.d.exists())
        self.assertEqual(self.commands, [])

    def test_human_bad_sha_or_count_cannot_create_sidecar(self):
        self.cli()
        for sha, count in (("f" * 64, "0"),
                           (live.digest((self.d / "launcher.machine.json").read_bytes()), "-1")):
            args = ["--binding-receipt-sha", sha, "--prompt-count", count, "--actions", "none", "--whole-observed", "yes"]
            self.assertEqual(self.cli(*args, observe=True)[0], 1)
            self.assertFalse((self.d / "launcher.human.json").exists())

    def test_process_snapshot_parser_and_exact_command_comparison_with_fixtures(self):
        import struct
        from unittest.mock import patch
        command = ["/usr/bin/open", "-W", "-a", str(self.app)]
        raw = struct.pack("=i", len(command)) + b"/usr/bin/open\0\0" + b"\0".join(x.encode() for x in command) + b"\0PRIVATE_ENV=secret\0"
        self.assertEqual(live.launcher_open_arguments(raw), command)
        for invalid in (b"", raw[:5], struct.pack("=i", -1) + b"x\0"):
            with self.assertRaises((live.Rejected, ValueError)): live.launcher_open_arguments(invalid)
        with patch.object(live, "launcher_process_snapshot", return_value=[("/usr/bin/open", command)]):
            # Test the real implementation; the class patches process state for all entrypoint fixtures.
            real = self.process_state_function({str(self.app)}, [command])
        self.assertFalse(real["legacyWorkerSettled"])
        with patch.object(live, "launcher_process_snapshot", return_value=[]):
            self.assertTrue(self.process_state_function({str(self.app)}, [command])["legacyWorkerSettled"])

    def test_human_is_bound_to_real_machine_bytes_and_exclusive(self):
        self.cli()
        sha = live.digest((self.d / "launcher.machine.json").read_bytes())
        args = ["--binding-receipt-sha", sha, "--prompt-count", "0", "--actions", "none", "--whole-observed", "yes"]
        self.assertEqual(self.cli(*args, observe=True)[0], 1)
        human = live.load(self.d / "launcher.human.json")
        self.assertEqual(human["bindingReceiptSHA256"], sha)
        self.assertTrue(human["wholeStageObserved"])
        self.assertEqual(self.cli(*args, observe=True)[0], 1)


def profile_free_fixture(root, sources, binary, mode="fake-only"):
    build = dict(schemaVersion=1, purpose="launch-report-only", variant="profile-free", evidenceMode=mode,
        sourceHashes=sources, compileConditions=["DEBUG", "LAUNCH_REPORT_ONLY"], scheme="CredentialStorageProbe",
        configuration="Debug", commandSHA256="a" * 64, unsignedBinarySHA256=live.digest(binary.read_bytes()), buildSucceeded=True)
    signing = dict(schemaVersion=1, purpose="launch-report-only", variant="profile-free", evidenceMode=mode,
        buildProofSHA256=live.digest((json.dumps(build, ensure_ascii=True, sort_keys=True, indent=2, allow_nan=False) + "\n").encode()),
        binarySHA256=live.digest(binary.read_bytes()), certificateDER_SHA256="5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440",
        teamIdentifierSHA256="b" * 64, bundleIdentifierSHA256="c" * 64, codeIdentifierSHA256="c" * 64,
        designatedRequirementSHA256="d" * 64, entitlementsEmpty=True, embeddedProfilePresent=False,
        signatureValid=True, certificateValidNow=True)
    return build, signing


class SwiftLaunchBindingOperations(unittest.TestCase):
    def test_actual_new_swift_shared_launch_binding_branch(self):
        import subprocess
        binary = os.environ.get("RIVET_LAUNCH_BINDING_PROBE_BINARY")
        if not binary:
            self.skipTest("requires newly compiled launch-binding fake-only main")
        result = subprocess.run([binary, "--self-test-launch-binding"], capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, "new fake-only Swift binding checks failed")
        value = json.loads(result.stdout)
        self.assertEqual(value["mode"], "launch-binding-fake-only")
        self.assertEqual(value["failures"], [])
        self.assertGreaterEqual(value["passed"], 22)


class SwiftProfileFreeVariant(unittest.TestCase):
    def test_compiled_variant_rejects_old_fake_and_legacy_entrypoints(self):
        import subprocess
        binary = os.environ.get("RIVET_PROFILE_FREE_PROBE_BINARY")
        if not binary:
            self.skipTest("requires final main compiled with LAUNCH_REPORT_ONLY")
        cases = [[], ["--self-test-fakes"], ["--self-test-diagnostics"], ["--self-test-launch-binding"],
            ["--request", "DO_NOT_READ", "--request-sha", "a" * 64], ["--unknown"], ["--launch-binding-only"]]
        env = {"PATH": "/usr/bin:/bin", "RIVET_DIAGNOSTIC_MANIFEST": "DO_NOT_READ"}
        for arguments in cases:
            with self.subTest(arguments=arguments):
                result = subprocess.run([binary, *arguments], env=env, capture_output=True, timeout=10)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b"")
                value = json.loads(result.stderr)
                self.assertEqual(set(value), {"purpose", "stage", "failureKind", "argvShape", "envPair"})
                self.assertEqual(value["purpose"], "launch-report-only")
                self.assertNotIn("DO_NOT_READ", result.stderr.decode())


class ProfileFreeCodeVerification(unittest.TestCase):
    """All command results are injected; never run codesign/openssl or query a real process."""
    def setUp(self):
        from unittest.mock import patch
        self.cert = b"FAKE_PUBLIC_CERTIFICATE"
        self.cert_sha = live.digest(self.cert)
        patcher = patch.object(live, "BINDING_CERTIFICATE_SHA256", self.cert_sha)
        patcher.start(); self.addCleanup(patcher.stop)
        self.calls = []
        self.entitlements = {}
        self.wrong_cert = False
        self.missing_mac_oid = False
        self.native_calls = []
        native = patch.object(live.subprocess, "run", side_effect=self.native)
        native.start(); self.addCleanup(native.stop)

    def native(self, command, **options):
        self.native_calls.append((command, options))
        out, err = self.command(command, options["timeout"])
        return live.subprocess.CompletedProcess(command, 0, out, err)

    def command(self, command, timeout):
        self.assertGreater(timeout, 0)
        self.calls.append(command)
        if command[0] == "/usr/libexec/csreq": return b'identifier "FAKE-BID" and anchor apple generic\n', b""
        if command[0] == "/usr/bin/csreq": return b'identifier "FAKE-BID" and anchor apple generic\n', b""
        if command[0] == "/usr/bin/openssl":
            mac = "" if self.missing_mac_oid else "1.2.840.113635.100.6.1.12: critical\n"
            if "-subject" in command:
                return b"subject=CN=PRIVATE-NAME,OU=FAKETEAM,O=PRIVATE-ORG\n", b""
            if "-dates" in command:
                return b"notBefore=Jan  1 00:00:00 2020 GMT\nnotAfter=Jan  1 00:00:00 2099 GMT\n", b""
            self.assertIn("-text", command)
            return ("Certificate:\n Issuer: CN=PRIVATE-ISSUER,OU=ISSUERTEAM\n"
                " Subject: CN=PRIVATE-NAME,OU=FAKETEAM,O=PRIVATE-ORG\n"
                " X509v3 Extended Key Usage:\n  Code Signing\n"
                "1.2.840.113635.100.6.1.2: critical\n" + mac).encode(), b""
        extract = next((x for x in command if x.startswith("--extract-certificates=")), None)
        if extract:
            Path(extract.split("=", 1)[1] + "0").write_bytes(b"WRONG" if self.wrong_cert else self.cert)
            return b"", b""
        if "--verify" in command: return b"", b""
        if "--verbose=4" in command: return b"", b"Identifier=FAKE-BID\nTeamIdentifier=FAKETEAM\n"
        if "--entitlements" in command: return live.plistlib.dumps(self.entitlements), b""
        if "-r-" in command: return b"", b'designated => identifier "FAKE-BID" and anchor apple generic\n'
        raise AssertionError("Unexpected bounded command")

    def test_dynamic_verification_targets_only_exact_pid_and_pinned_certificate(self):
        result = live.binding_code_identity(4321, command=self.command, timeout=3)
        self.assertEqual(result["certificateDER_SHA256"], self.cert_sha)
        self.assertEqual(result["teamIdentifierSHA256"], live.digest(b"FAKETEAM"))
        for command in self.calls:
            if command[0] == "/usr/bin/codesign": self.assertEqual(command[-1], "4321")
        self.assertTrue(any("--extract-certificates=" in x for command in self.calls for x in command))
        expected = dict(result, codeIdentifierSHA256="e" * 64)
        with self.assertRaises(live.Rejected): live.binding_verify_process(4321, expected, 3, command=self.command)

    def test_shared_native_postverify_uses_pinned_stdin_for_all_three_decoders(self):
        # Do not inject command/run wrappers: only subprocess.run is fake.
        result = live.binding_code_identity(4321, timeout=3)
        self.assertEqual(result["certificateDER_SHA256"], self.cert_sha)
        calls = [(command, options) for command, options in self.native_calls if command[0] == "/usr/bin/openssl"]
        self.assertEqual(len(calls), 3)
        self.assertEqual([command for command, _ in calls], [live.binding_certificate_arguments(part)
                         for part in ("subject", "dates", "class")])
        for command, options in calls:
            self.assertNotIn("-in", command)
            self.assertEqual(options["input"], self.cert)
            self.assertIs(options["input"], calls[0][1]["input"])
            self.assertNotIn("stdin", options)
            self.assertTrue(0 < options["timeout"] <= 3)
            self.assertEqual(options["env"], {"LC_ALL": "C", "OPENSSL_CONF": "/dev/null"})
            self.assertIs(options["capture_output"], True)

    def test_shared_native_decoder_failures_keep_original_results(self):
        from unittest.mock import patch
        cases = [("subject", 7), ("dates", -9), ("class", live.subprocess.TimeoutExpired("PRIVATE", 10)),
                 ("subject", OSError("PRIVATE"))]
        for failed_part, failure in cases:
            with self.subTest(part=failed_part, failureType=type(failure).__name__):
                self.native_calls.clear(); self.calls.clear()
                def native(command, **options):
                    if command == live.binding_certificate_arguments(failed_part):
                        self.native_calls.append((command, options))
                        if isinstance(failure, Exception): raise failure
                        return live.subprocess.CompletedProcess(command, failure, b"PRIVATE_OUT", b"PRIVATE_ERR")
                    return self.native(command, **options)
                error = type(failure) if isinstance(failure, Exception) else live.subprocess.CalledProcessError
                with patch.object(live.subprocess, "run", side_effect=native):
                    with self.assertRaises(error) as caught: live.binding_code_identity(4321, timeout=3)
                if isinstance(failure, Exception): self.assertIs(caught.exception, failure)
                else:
                    self.assertEqual(caught.exception.returncode, failure)
                    self.assertEqual(caught.exception.stderr, b"PRIVATE_ERR")
                decoders = [(c, o) for c, o in self.native_calls if c[0] == "/usr/bin/openssl"]
                self.assertEqual(len(decoders), ("subject", "dates", "class").index(failed_part) + 1)
                self.assertTrue(all(o["input"] == self.cert and "-in" not in c for c, o in decoders))

    def test_shared_wrapper_rejects_mutated_input_type_bytes_or_command_before_native(self):
        from unittest.mock import patch
        original_text = live.binding_certificate_text
        for mutation in ("bytes", "type", "command"):
            with self.subTest(mutation=mutation):
                self.native_calls.clear(); self.calls.clear()
                def text(raw, part, *, evidence, run):
                    def changed(arguments, **options):
                        if mutation == "bytes": options["input"] = b"WRONG"
                        if mutation == "type": options["input"] = bytearray(raw)
                        if mutation == "command": arguments = [*arguments, "-in", "DO_NOT_READ"]
                        return run(arguments, **options)
                    return original_text(raw, part, evidence=evidence, run=changed)
                with patch.object(live, "binding_certificate_text", side_effect=text):
                    with self.assertRaises(live.Rejected): live.binding_code_identity(4321, timeout=3)
                self.assertFalse(any(c[0] == "/usr/bin/openssl" for c, _ in self.native_calls))

    def test_window_cross_boot_after_extract_blocks_every_decoder_native(self):
        expected=live.binding_code_identity(4321,command=self.command,timeout=3)
        self.native_calls.clear();self.calls.clear()
        fixture=DPKWindowControls(methodName="runTest")
        with tempfile.TemporaryDirectory() as temp:
            _,_,window=fixture.opened(Path(temp).resolve())
            def command(argv,timeout):
                result=self.command(argv,timeout)
                if any(x.startswith("--extract-certificates=") for x in argv):fixture.sample[2]="f"*64
                return result
            with self.assertRaises(live.DPKDeadlineRejected):
                live.binding_verify_process(4321,expected,3,command=command,window=window,phase="save-a")
            self.assertFalse(any(c[0]=="/usr/bin/openssl" for c,o in self.native_calls))

    def test_window_shared_decoder_stdin_timeout_and_final_acceptance_guard(self):
        from unittest.mock import patch
        expected=live.binding_code_identity(4321,command=self.command,timeout=3)
        fixture=DPKWindowControls(methodName="runTest")
        for transition,expected_count in ((None,3),("subject",1),("class",3)):
            with self.subTest(transition=transition),tempfile.TemporaryDirectory() as temp:
                _,_,window=fixture.opened(Path(temp).resolve())
                self.native_calls.clear();self.calls.clear()
                def native(argv,**options):
                    result=self.native(argv,**options)
                    if transition and argv==live.binding_certificate_arguments(transition):
                        if transition=="subject":fixture.sample[2]="f"*64
                        else:fixture.sample[0]=2_000_004_000
                    return result
                with patch.object(live.subprocess,"run",side_effect=native):
                    if transition:
                        with self.assertRaises(live.DPKDeadlineRejected):
                            live.binding_verify_process(4321,expected,3,window=window,phase="save-a")
                    else:live.binding_verify_process(4321,expected,3,window=window,phase="save-a")
                calls=[(c,o) for c,o in self.native_calls if c[0]=="/usr/bin/openssl"]
                self.assertEqual(len(calls),expected_count)
                for command,options in calls:
                    self.assertIs(options["input"],calls[0][1]["input"])
                    self.assertEqual(options["input"],self.cert)
                    self.assertNotIn("-in",command);self.assertNotIn("stdin",options)
                    self.assertTrue(0<options["timeout"]<=3)

    def test_window_decoder_native_failure_remains_original_after_clock_changes(self):
        from unittest.mock import patch
        fixture=DPKWindowControls(methodName="runTest")
        with tempfile.TemporaryDirectory() as temp:
            _,_,window=fixture.opened(Path(temp).resolve())
            self.native_calls.clear()
            def native(argv,**options):
                if argv==live.binding_certificate_arguments("subject"):
                    self.native_calls.append((argv,options));fixture.sample[2]="f"*64
                    return live.subprocess.CompletedProcess(argv,17,b"PRIVATE_OUT",b"PRIVATE_ERR")
                return self.native(argv,**options)
            with patch.object(live.subprocess,"run",side_effect=native):
                with self.assertRaises(live.subprocess.CalledProcessError) as caught:
                    live.binding_code_identity(4321,window=window,phase="save-a",timeout=3)
            self.assertEqual(caught.exception.returncode,17)
            self.assertEqual(caught.exception.stderr,b"PRIVATE_ERR")
            self.assertEqual(len([c for c,o in self.native_calls if c[0]=="/usr/bin/openssl"]),1)

    def test_nonempty_entitlements_are_rejected(self):
        self.entitlements = {"keychain-access-groups": ["PRIVATE_GROUP"]}
        with self.assertRaises(live.Rejected): live.binding_code_identity(4321, command=self.command)
        self.assertFalse(any(x[0] == "/usr/bin/openssl" for x in self.calls))

    def test_wrong_der_or_unknown_certificate_class_is_rejected(self):
        self.wrong_cert = True
        with self.assertRaises(live.Rejected): live.binding_code_identity(4321, command=self.command)
        self.wrong_cert = False; self.missing_mac_oid = True
        with self.assertRaises(live.Rejected): live.binding_code_identity(4321, command=self.command)

    def test_dynamic_deadline_or_unknown_signature_is_rejected(self):
        with self.assertRaises(live.Rejected): live.binding_verify_process(4321, {}, 0, command=self.command)
        def fail(command, timeout): raise OSError("PRIVATE_NATIVE_ERROR")
        with self.assertRaises(OSError): live.binding_code_identity(4321, command=fail)
        self.assertFalse(self.calls)


    def test_public_certificate_preparation_pins_before_sha1_and_never_signs(self):
        import base64
        from unittest.mock import Mock
        with tempfile.TemporaryDirectory(prefix="rivet-sign-prep-fake-") as temporary:
            root = Path(temporary).resolve()
            chain = root / "Keychains/login.keychain-db"
            chain.parent.mkdir(); chain.write_bytes(b"FAKE_KEYCHAIN_NO_NATIVE_QUERY")
            app = root / "CredentialStorageProbe.app"
            (app / "Contents").mkdir(parents=True)
            (app / "Contents/Info.plist").write_bytes(live.plistlib.dumps({
                "CFBundleIdentifier": "FAKE-BID", "CFBundleExecutable": "CredentialStorageProbe"}))
            pem = b"-----BEGIN CERTIFICATE-----\n" + base64.b64encode(self.cert) + b"\n-----END CERTIFICATE-----\n"
            query = Mock(return_value=(pem, b""))
            der = live.binding_original_certificate(chain, query=query)
            self.assertEqual(der, self.cert)
            self.assertEqual(query.call_args.args[0][-1], str(chain))
            def decode(raw, part, *, evidence):
                return self.command(live.binding_certificate_arguments(part), 3)[0].decode()
            result = live.binding_sign_preparation(der, chain, app, "FAKE-BID", decode=decode)
            self.assertEqual(result["certificateSHA1"], live.hashlib.sha1(self.cert).hexdigest())
            self.assertIn(result["certificateSHA1"], result["signCommand"])
            self.assertNotIn(self.cert_sha, result["signCommand"])
            self.assertNotIn("--entitlements", result["signCommand"])
            with self.assertRaises(live.Rejected):
                live.binding_sign_preparation(b"WRONG", chain, app, "FAKE-BID", decode=Mock(side_effect=AssertionError()))


class CertificatePreparationControls(unittest.TestCase):
    """Real preparation helper with fake public-DER command output; zero native tools."""
    SUBJECT = "subject=CN=PRIVATE-NAME,OU=FAKETEAM,O=PRIVATE-ORG\n"
    DATES = "notBefore=Jan  1 00:00:00 2020 GMT\nnotAfter=Jan  1 00:00:00 2099 GMT\n"
    CLASS = ("Certificate:\n    Data:\n        Issuer: CN=PRIVATE-ISSUER,OU=ISSUERTEAM,O=PRIVATE-ORG\n"
             "        Subject: CN=PRIVATE-NAME,OU=FAKETEAM,O=PRIVATE-ORG\n"
             "        X509v3 Extended Key Usage:\n            Code Signing\n"
             "        1.2.840.113635.100.6.1.2: critical\n"
             "        1.2.840.113635.100.6.1.12: critical\n")

    def setUp(self):
        from unittest.mock import patch
        self.temp = tempfile.TemporaryDirectory(prefix="rivet-certificate-fake-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.chain = self.root / "Keychains/login.keychain-db"
        self.chain.parent.mkdir(); self.chain.write_bytes(b"FAKE_NO_KEYCHAIN_QUERY")
        self.app = self.root / "to-be-signed/CredentialStorageProbe.app"
        (self.app / "Contents").mkdir(parents=True)
        (self.app / "Contents/Info.plist").write_bytes(live.plistlib.dumps({
            "CFBundleIdentifier": "FAKE-BID", "CFBundleExecutable": "CredentialStorageProbe"}))
        # Exact original caller-config shape. Private production values are never read by tests.
        self.config = dict(buildCommand=[], buildCommandSHA256="a" * 64, buildProofSHA256="b" * 64,
            expectedBundleIdentifier="FAKE-BID", expectedCertificateDER_SHA256=live.digest(b"FAKE_PUBLIC_DER"),
            expectedCodeIdentifier="FAKE-BID", loginKeychain=str(self.chain), packageInputs={},
            plannedContext=str(self.root / "future-context"), privateProjectSHA256="c" * 64,
            purpose="launch-report-only", repo=str(self.root / "fake-repo"), root=str(self.root), schemaVersion=1,
            sourceHashes={}, unsignedAppTreeSHA256="d" * 64, unsignedBinarySHA256="e" * 64)
        self.der = b"FAKE_PUBLIC_DER"
        pin = patch.object(live, "BINDING_CERTIFICATE_SHA256", live.digest(self.der))
        pin.start(); self.addCleanup(pin.stop)
        self.parts = {"subject": self.SUBJECT, "dates": self.DATES, "class": self.CLASS}
        self.calls = []
        command = patch.object(live.subprocess, "run", side_effect=self.decode_command)
        command.start(); self.addCleanup(command.stop)

    def decode_command(self, command, **options):
        self.calls.append((command, options))
        self.assertEqual(command[:5], ["/usr/bin/openssl", "x509", "-inform", "DER", "-noout"])
        self.assertEqual(options, dict(input=self.der, capture_output=True, timeout=10,
                                      env={"LC_ALL": "C", "OPENSSL_CONF": "/dev/null"}))
        if "-text" in command:
            # Original combined command gets all requested records, matching actual tool output shape.
            text = self.parts["class"]
            if "-subject" in command: text = self.parts["subject"] + text
            if "-dates" in command: text = self.parts["dates"] + text
        elif "-subject" in command: text = self.parts["subject"]
        else: text = self.parts["dates"]
        return live.subprocess.CompletedProcess(command, 0, text.encode(), b"")

    def prepare(self, **options):
        prepared = live.binding_sign_preparation(self.der, self.config["loginKeychain"], self.app,
                                                self.config["expectedCodeIdentifier"], **options)
        self.assertEqual(prepared["bundleIdentifierSHA256"], live.digest(self.config["expectedBundleIdentifier"].encode()))
        return prepared

    def test_actual_default_decoder_separates_subject_dates_class(self):
        prepared = self.prepare()
        self.assertEqual(prepared["teamIdentifierSHA256"], live.digest(b"FAKETEAM"))
        self.assertEqual([c for c, _ in self.calls], [
            ["/usr/bin/openssl", "x509", "-inform", "DER", "-noout", "-subject", "-nameopt", "RFC2253"],
            ["/usr/bin/openssl", "x509", "-inform", "DER", "-noout", "-dates"],
            ["/usr/bin/openssl", "x509", "-inform", "DER", "-noout", "-text", "-nameopt", "RFC2253"]])
        self.assertFalse(any(c[0] == "/usr/bin/codesign" for c, _ in self.calls))


    def test_preparation_exact_finite_evidence_and_private_result(self):
        evidence = live.binding_preparation_evidence()
        prepared = self.prepare(evidence=evidence)
        self.assertEqual(evidence, dict(guardPoint="prepared", decoderPart="class", decoderOutcome="zero",
            decoderReturnCode=0, subjectOUCount="one", derPinned=True, subjectValid=True, dateValid=True, classValid=True))
        self.assertEqual(prepared["preparation"], evidence)
        self.assertNotIn("PRIVATE", json.dumps(evidence))
        self.assertNotIn("FAKETEAM", json.dumps(evidence))
        self.assertNotIn(str(self.root), json.dumps(evidence))
        self.assertIn(live.hashlib.sha1(self.der).hexdigest(), prepared["signCommand"])
        self.assertNotIn(self.config["expectedCertificateDER_SHA256"], prepared["signCommand"])

    def test_rfc2253_escaped_attributes_do_not_inject_team(self):
        for name in (r"CN=PRIVATE\,OU\=IMPOSTOR,OU=FAKETEAM,O=PRIVATE",
                     r"CN=PRIVATE\+OU\=IMPOSTOR,OU=FAKETEAM",
                     r"CN=PRIVATE\20NAME,OU=FAKE\54EAM",
                     r"CN=\#PRIVATE,OU=FAKETEAM", r"CN=PRIVATE\\NAME,OU=FAKETEAM",
                     r"CN=PRIVATE\C3\A9,OU=FAKETEAM", "CN=PRIVATE,2.5.4.11=FAKETEAM"):
            with self.subTest(nameShape=live.digest(name.encode())):
                self.parts["subject"] = "subject=" + name + "\n"
                self.assertEqual(self.prepare()["teamIdentifierSHA256"], live.digest(b"FAKETEAM"))

    def test_invalid_subject_records_escapes_and_multiple_ous_stop_before_dates_or_sign(self):
        cases = [self.SUBJECT + self.SUBJECT, self.SUBJECT + "Issuer: OU=OTHER\n",
            "subject=CN=PRIVATE,OU=FAKETEAM,OU=FAKETEAM\n", "subject=OU=FAKETEAM,2.5.4.11=FAKETEAM\n",
            "subject=CN=PRIVATE\n", "subject=CN=PRIVATE,OU=faketeam\n", "subject=CN=PRIVATE,OU=\n",
            "subject=CN=PRIVATE+OU=FAKETEAM\n", "subject=CN=PRIVATE, OU=FAKETEAM\n",
            "subject=CN=PRIVATE\\\n", r"subject=CN=PRIVATE\Q,OU=FAKETEAM" + "\n",
            r"subject=CN=PRIVATE\A,OU=FAKETEAM" + "\n", r"subject=CN=PRIVATE\FF,OU=FAKETEAM" + "\n",
            r"subject=CN=PRIVATE\00,OU=FAKETEAM" + "\n", "subject=CN=#0011,OU=FAKETEAM\n",
            self.SUBJECT + "\n", self.SUBJECT.replace("\n", "\r\n")]
        for value in cases:
            with self.subTest(inputSHA=live.digest(value.encode())):
                self.calls.clear(); self.parts["subject"] = value
                evidence = live.binding_preparation_evidence()
                with self.assertRaises((live.Rejected, UnicodeError)):
                    self.prepare(evidence=evidence)
                self.assertEqual(evidence["guardPoint"], "subjectParse")
                self.assertIs(evidence["subjectValid"], False)
                self.assertEqual(len(self.calls), 1)
                self.assertFalse(any(c[0] == "/usr/bin/codesign" for c, _ in self.calls))
        self.assertEqual(evidence["decoderOutcome"], "zero")

    def test_date_and_class_checks_remain_required(self):
        cases = [("dates", self.DATES.replace("notAfter", "notBefore"), "datesParse", "dateValid"),
            ("dates", self.DATES + self.DATES, "datesParse", "dateValid"),
            ("dates", self.DATES.replace("2099", "2001"), "datesParse", "dateValid"),
            ("dates", self.DATES.replace("2020", "2098"), "datesParse", "dateValid"),
            ("dates", self.DATES.replace("GMT", "OTHER"), "datesParse", "dateValid"),
            ("class", self.CLASS.replace("Code Signing", "OTHER"), "classParse", "classValid"),
            ("class", self.CLASS.replace("X509v3 Extended Key Usage:", "OTHER:"), "classParse", "classValid"),
            ("class", self.CLASS.replace("1.2.840.113635.100.6.1.2:", "1.2.840.113635.100.6.1.20:"), "classParse", "classValid"),
            ("class", self.CLASS.replace("1.2.840.113635.100.6.1.12:", "OTHER:"), "classParse", "classValid")]
        for part, text, point, checked in cases:
            with self.subTest(part=part, inputSHA=live.digest(text.encode())):
                self.parts = {"subject": self.SUBJECT, "dates": self.DATES, "class": self.CLASS}
                self.parts[part] = text; self.calls.clear()
                evidence = live.binding_preparation_evidence()
                with self.assertRaises((live.Rejected, ValueError)): self.prepare(evidence=evidence)
                self.assertEqual(evidence["guardPoint"], point); self.assertIs(evidence[checked], False)
                self.assertEqual(evidence["decoderOutcome"], "zero")
                self.assertFalse(any(c[0] == "/usr/bin/codesign" for c, _ in self.calls))

    def test_decoder_actual_return_and_exception_survive_without_sensitive_projection(self):
        from unittest.mock import patch
        cases = [(live.subprocess.CompletedProcess([], 7, b"PRIVATE", b"PRIVATE"), "nonzero", 7, live.subprocess.CalledProcessError),
            (live.subprocess.CompletedProcess([], -9, b"PRIVATE", b"PRIVATE"), "signal", -9, live.subprocess.CalledProcessError),
            (live.subprocess.CompletedProcess([], 0, b"\xffPRIVATE", b""), "decodeInvalid", 0, UnicodeError),
            (live.subprocess.TimeoutExpired("PRIVATE", 10), "timeout", None, live.subprocess.TimeoutExpired),
            (OSError("PRIVATE_NATIVE_ERROR"), "exception", None, OSError)]
        for result, outcome, code, error in cases:
            with self.subTest(outcome=outcome):
                evidence = live.binding_preparation_evidence()
                kwargs = dict(side_effect=result) if isinstance(result, Exception) else dict(return_value=result)
                with patch.object(live.subprocess, "run", **kwargs) as native:
                    with self.assertRaises(error) as caught: self.prepare(evidence=evidence)
                if isinstance(result, Exception): self.assertIs(caught.exception, result)
                if isinstance(caught.exception, live.subprocess.CalledProcessError):
                    self.assertEqual(caught.exception.stderr, b"PRIVATE")
                    self.assertEqual(caught.exception.returncode, code)
                self.assertEqual(native.call_count, 1)
                self.assertEqual(evidence["guardPoint"], "subjectDecode")
                self.assertEqual(evidence["decoderOutcome"], outcome)
                self.assertEqual(evidence["decoderReturnCode"], code)
                self.assertIsNone(evidence["subjectValid"])
                self.assertNotIn("PRIVATE", json.dumps(evidence))

    def test_wrong_pin_precedes_every_decoder_and_path(self):
        evidence = live.binding_preparation_evidence()
        self.der = b"WRONG"
        with self.assertRaises(live.Rejected): self.prepare(evidence=evidence)
        self.assertEqual(self.calls, [])
        self.assertEqual(evidence["guardPoint"], "derPin"); self.assertIs(evidence["derPinned"], False)
        self.assertIsNone(evidence["subjectValid"])

    def test_actual_config_path_info_profile_guards_never_sign(self):
        for field, value, expected in (("expectedCodeIdentifier", "WRONG", "infoBundle"),
                                       ("loginKeychain", "RELATIVE_PRIVATE", "keychainPath")):
            with self.subTest(field=field):
                old = self.config[field]; self.config[field] = value
                evidence = live.binding_preparation_evidence()
                with self.assertRaises(live.Rejected): self.prepare(evidence=evidence)
                self.assertEqual(evidence["guardPoint"], expected); self.config[field] = old
        profile = self.app / "Contents/embedded.provisionprofile"; profile.write_bytes(b"FAKE")
        evidence = live.binding_preparation_evidence()
        with self.assertRaises(live.Rejected): self.prepare(evidence=evidence)
        self.assertEqual(evidence["guardPoint"], "profileAbsent"); profile.unlink()
        (self.app / "Contents/Info.plist").write_bytes(live.plistlib.dumps({
            "CFBundleIdentifier": "FAKE-BID", "CFBundleExecutable": "WRONG"}))
        with self.assertRaises(live.Rejected): self.prepare(evidence=evidence)
        self.assertEqual(evidence["guardPoint"], "infoExecutable")
        self.assertFalse(any(c[0] == "/usr/bin/codesign" for c, _ in self.calls))


class LaunchStartupControls(unittest.TestCase):
    def setUp(self):
        self.fixture = LaunchBindingControls(methodName="test_binding_complete_fake_protocol_never_claims_signed_host")
        self.fixture.setUp(); self.addCleanup(self.fixture.doCleanups)

    def test_missing_report_preserves_observed_native_zero(self):
        f = self.fixture; f.no_report = True
        _, output = f.cli()
        machine = live.load(f.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeReturnCode"], 0)
        self.assertTrue(machine["nativeSettled"])
        self.assertEqual(output["failureKind"], "timeout")
        self.assertFalse(output["hostAttributed"])

    def test_missing_report_preserves_observed_native_signal(self):
        f = self.fixture; f.no_report = True; f.native_rc = -15
        f.cli(); machine = live.load(f.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeReturnCode"], -15)
        self.assertEqual(machine["nativeSignal"], 15)

    def test_transport_has_explicit_app_streams_and_five_binding_arguments(self):
        f = self.fixture; spawn = f.spawn; observed = []
        def record(command, out, err):
            observed.append(command); return spawn(command, out, err)
        f.hooks["spawn"] = record
        f.cli(); self.assertEqual(len(observed), 1)
        command = observed[0]
        self.assertIn("--stdout", command); self.assertIn("--stderr", command)
        self.assertEqual(command[-5:], ["--launch-binding-only", "--request", str(f.root / "attempt/request.json"),
                         "--request-sha", live.digest((f.root / "attempt/request.json").read_bytes())])
        self.assertNotIn("-n", command)


    def test_bound_failure_is_recorded_without_ack_or_attribution(self):
        f = self.fixture; original = f.spawn
        def spawn(command, out, err):
            child = original(command, out, err)
            value = dict(f.b(), stage="wire", outcome="rejected", failureKind="input",
                observedBinarySHA256=None, pid=None, startSeconds=None, startMicroseconds=None,
                wire=dict(argvShape="expected", argvPair="valid", envPair="missing", channelsMatch=None))
            live.binding_publish(f.root, f.root / "attempt/host.failure.json", value)
            return child
        f.hooks["spawn"] = spawn
        _, result = f.cli()
        self.assertIsNotNone(result["failureSHA256"])
        self.assertFalse(result["hostAttributed"])
        self.assertFalse((f.root / "attempt/ack.json").exists())

    def test_poll_error_is_finite_and_does_not_fake_settlement(self):
        from unittest.mock import Mock
        f = self.fixture; original = f.spawn
        def spawn(command, out, err):
            child = original(command, out, err); child.poll = Mock(side_effect=OSError("PRIVATE_POLL")); return child
        f.hooks["spawn"] = spawn
        _, result = f.cli(); machine = live.load(f.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeExceptionKind"], "waitOS")
        self.assertFalse(machine["nativeSettled"])
        self.assertIsNone(machine["nativeReturnCode"])
        self.assertNotIn("PRIVATE", json.dumps(result))

    def test_app_stream_snapshot_is_bounded_and_separate_from_native_streams(self):
        f = self.fixture; original = f.spawn
        def spawn(command, out, err):
            (f.root / "attempt/app.stdout").write_bytes(b"x" * 65537)
            (f.root / "attempt/app.stderr").write_bytes(b"PRIVATE_DIAGNOSTIC")
            return original(command, out, err)
        f.hooks["spawn"] = spawn
        _, result = f.cli(); value = result["appOutput"]
        self.assertEqual((value["stdoutState"], value["stdoutBytes"], value["stdoutSHA256"]), ("oversize", 65537, None))
        self.assertEqual(value["stderrSHA256"], live.digest(b"PRIVATE_DIAGNOSTIC"))
        self.assertNotIn("PRIVATE", json.dumps(result))
        self.assertEqual((f.root / "attempt/launch.stderr").read_bytes(), b"")

    def test_actual_finite_child_native_exit_survives_missing_report(self):
        import subprocess, sys
        f = self.fixture
        def spawn(command, out, err):
            child = subprocess.Popen([sys.executable, "-c", "raise SystemExit(7)"], stdin=subprocess.DEVNULL, stdout=out, stderr=err)
            child.wait(timeout=5)  # Only this known finite non-App fixture child, never production timeout behavior.
            return child
        f.hooks["spawn"] = spawn
        _, result = f.cli(); machine = live.load(f.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeReturnCode"], 7)
        self.assertTrue(machine["nativeSettled"])
        self.assertEqual(result["failureKind"], "timeout")
        self.assertFalse(result["hostAttributed"])

    def test_diagnostic_exact_schema_binding_and_nullability(self):
        f = self.fixture; f.cli()
        entry = live.load(f.root / "attempt/host.entry.json")
        for changed in (dict(entry, extra=True), dict(entry, pid=True), dict(entry, observedBinarySHA256=False),
                        dict(entry, requestSHA256="f" * 64)):
            with self.assertRaises(live.Rejected): live.binding_validate("entry", changed, f.b())
        for key in entry:
            changed = dict(entry); changed.pop(key)
            with self.assertRaises(live.Rejected): live.binding_validate("entry", changed, f.b())


class SwiftLaunchStartupControls(unittest.TestCase):
    def binary(self):
        binary = os.environ.get("RIVET_LAUNCH_BINDING_PROBE_BINARY")
        if not binary: self.skipTest("requires final ordinary unsigned startup CLI")
        return binary

    def test_actual_filesystem_number_bridge_and_self_only_native_accessor(self):
        import subprocess
        result = subprocess.run([self.binary(), "--self-test-launch-startup"], capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0)
        value = json.loads(result.stdout)
        for key in ("physicalCanonicalAccepted", "modeRejected", "symlinkRejected", "ownerRejected", "integerValid",
                    "booleanRejected", "fractionRejected", "nativeSelfValid", "sdkLayoutPositive", "sizeRejected", "typeRejected", "fileModeRejected", "passed"):
            self.assertIs(value[key], True)

    def test_original_captured_bytes_use_actual_swift_core_and_real_filesystem(self):
        import shutil, subprocess
        source = os.environ.get("RIVET_CAPTURED_REPLAY_SOURCE")
        if not source: self.skipTest("requires read-only captured context source from trusted operator")
        source = Path(source).resolve()
        request_sha = live.digest((source / "attempt/request.json").read_bytes())
        self.assertEqual(request_sha, "297a4dd546bb28f262cf4c7f00f437e95ad238e21867827867dbb7e316ffdfa6")
        with tempfile.TemporaryDirectory(prefix="rivet-lg54-replay-") as temporary:
            root = Path(temporary).resolve(); root.chmod(0o700)
            for leaf in ("source", "app"): shutil.copytree(source / leaf, root / leaf)
            (root / "attempt").mkdir(mode=0o700)
            leaves = ["context.json", "build.machine.json", "signing.machine.json", "binding-consumed.json", "attempt/request.json"]
            for leaf in leaves: shutil.copy2(source / leaf, root / leaf)
            before = {leaf: live.digest((root / leaf).read_bytes()) for leaf in leaves}
            env = dict(os.environ, RIVET_CAPTURED_REPLAY_ROOT=str(root))
            result = subprocess.run([self.binary(), "--self-test-launch-startup"], env=env, capture_output=True, timeout=30)
            self.assertEqual(result.returncode, 0)
            value = json.loads(result.stdout)
            self.assertTrue(value["capturedCoreCompleted"])
            self.assertEqual(value["capturedRequestSHA256"], request_sha)
            self.assertTrue(all(before[leaf] == live.digest((root / leaf).read_bytes()) for leaf in leaves))
            # New entry is actually produced by Swift, not synthesized by the Python fixture.
            entry = live.load(root / "attempt/host.entry.json")
            live.binding_validate("entry", entry)
            self.assertEqual(entry["requestSHA256"], request_sha)


class LaunchBindingControls(unittest.TestCase):
    """Ordinary fake scratch and injected providers, never a real diagnostic context/App."""
    def setUp(self):
        from unittest.mock import patch
        self.temp = tempfile.TemporaryDirectory(prefix="rivet-binding-fake-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.root.chmod(0o700)
        self.attempt, self.ready = str(uuid.uuid4()), str(uuid.uuid4())
        self.binary = self.root / "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe"
        self.binary.parent.mkdir(parents=True)
        self.binary.write_bytes(b"FAKE_ONLY_NOT_AN_EXECUTABLE")
        self.binary.chmod(0o700)
        sources = {}
        for leaf in live.BINDING_SOURCES:
            path = self.root / "source" / leaf
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"FAKE_SOURCE")
            path.chmod(0o600)
            sources[leaf] = live.digest(path.read_bytes())
        build, signing = profile_free_fixture(self.root, sources, self.binary)
        live.exclusive_json(self.root / "build.machine.json", build)
        live.exclusive_json(self.root / "signing.machine.json", signing)
        self.context = dict(schemaVersion=1, purpose="launch-report-only", contextUUID=str(uuid.uuid4()),
            sourceHashes=sources, expectedBinarySHA256=live.digest(self.binary.read_bytes()),
            buildProofSHA256=live.digest((self.root / "build.machine.json").read_bytes()),
            signingProofSHA256=live.digest((self.root / "signing.machine.json").read_bytes()))
        live.exclusive_json(self.root / "context.json", self.context)
        self.context_sha = live.digest((self.root / "context.json").read_bytes())
        self.ticks, self.calls, self.inspect_calls = 0, 0, 0
        self.report_change, self.final_change, self.process_change = {}, {}, {}
        self.no_report = self.no_final = self.spawn_error = False
        self.native_rc = 0
        self.hooks = dict(evidenceMode="fake-only", wall=lambda: 2000000000000000 + int(self.ticks * 1000000),
            monotonic=lambda: self.ticks, sleep=self.tick, spawn=self.spawn,
            inspect=self.inspect, verify=lambda *args: None, verify_process=lambda *args: None)
        patcher = patch.object(live, "binding_hooks", return_value=self.hooks)
        patcher.start(); self.addCleanup(patcher.stop)

    def b(self):
        request = live.load(self.root / "attempt/request.json")
        return {key: request[key] for key in live.BINDING_KEYS if key != "requestSHA256"} | {
            "requestSHA256": live.digest((self.root / "attempt/request.json").read_bytes())}

    def spawn(self, command, out, err):
        from unittest.mock import Mock
        self.calls += 1
        self.assertTrue((self.root / "binding-consumed.json").is_file())
        self.assertEqual(command[:4], ["/usr/bin/open", "-W", "-a", str(self.binary.parents[2])])
        self.assertEqual(command[-6:-4], ["--args", "--launch-binding-only"])
        self.assertEqual(command[-4:], ["--request", str(self.root / "attempt/request.json"), "--request-sha", self.b()["requestSHA256"]])
        self.assertEqual(command[command.index("--stdout") + 1], str(self.root / "attempt/app.stdout"))
        self.assertEqual(command[command.index("--stderr") + 1], str(self.root / "attempt/app.stderr"))
        if self.spawn_error: raise OSError("PRIVATE_NATIVE_ERROR")
        self.report = dict(self.b(), observedBinarySHA256=self.context["expectedBinarySHA256"],
            pid=54321, startSeconds=2000000000, startMicroseconds=0,
            processUUID=str(uuid.uuid4()), stage="report", outcome="awaitingAck")
        self.report.update(self.report_change)
        entry = dict(self.b(), stage="bootstrap", outcome="entered", observedBinarySHA256=None,
            pid=None, startSeconds=None, startMicroseconds=None,
            wire=dict(argvShape="expected", argvPair="valid", envPair="valid", channelsMatch=True))
        live.binding_publish(self.root, self.root / "attempt/host.entry.json", entry)
        if not self.no_report:
            live.binding_publish(self.root, self.root / "attempt/host.report.json", self.report)
        return Mock(pid=12345, wait=Mock(return_value=self.native_rc), poll=Mock(return_value=self.native_rc))

    def inspect(self, pid):
        self.inspect_calls += 1
        return dict(pid=pid, uid=os.getuid(), startSeconds=2000000000, startMicroseconds=0,
                    executable=str(self.binary), live=True) | self.process_change

    def tick(self, duration):
        self.ticks += max(duration, 0.1)
        ack = self.root / "attempt/ack.json"
        if ack.exists() and not self.no_final and not (self.root / "attempt/host.final.json").exists():
            final = dict(self.b(), hostReportSHA256=live.digest((self.root / "attempt/host.report.json").read_bytes()),
                         ackSHA256=live.digest(ack.read_bytes()), outcome="completed")
            final.update(self.final_change)
            live.binding_publish(self.root, self.root / "attempt/host.final.json", final)

    def cli(self, **changes):
        import contextlib, io
        from unittest.mock import patch
        args = [str(SCRIPT), "binding-launch", "--context", str(self.root / "context.json"),
            "--context-sha", self.context_sha, "--attempt-uuid", self.attempt,
            "--ready-uuid", self.ready, "--ready-confirmed"]
        output = io.StringIO()
        with patch.object(live.sys, "argv", args), contextlib.redirect_stdout(output):
            rc = live.main()
        value = json.loads(output.getvalue())
        self.assertNotIn("PRIVATE", json.dumps(value))
        return rc, value

    def test_binding_complete_fake_protocol_never_claims_signed_host(self):
        rc, result = self.cli()
        self.assertEqual(rc, 1)
        self.assertEqual(result["evidenceMode"], "fake-only")
        self.assertFalse(result["hostAttributed"])
        self.assertTrue(result["bindingMatched"] and result["liveInstanceVerified"] and result["binaryVerified"])
        self.assertIsNotNone(result["machineSHA256"])
        self.assertEqual((self.calls, self.inspect_calls), (1, 2))
        self.assertNotIn("machineSHA256", live.load(self.root / "attempt/launcher.machine.json"))
        self.assertEqual(self.cli()[0], 1)
        self.assertEqual(self.calls, 1)

    def test_binding_old_or_wrong_report_rejects_before_ack(self):
        self.report_change = {"attemptUUID": str(uuid.uuid4())}
        _, result = self.cli()
        self.assertFalse(result["hostAttributed"])
        self.assertFalse((self.root / "attempt/ack.json").exists())

    def test_binding_pid_reuse_and_uuid_only_do_not_verify(self):
        self.process_change = {"startSeconds": 1999999999}
        _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertFalse((self.root / "attempt/ack.json").exists())

    def test_binding_native_zero_without_receipt_is_unknown(self):
        self.no_report = True
        _, result = self.cli()
        self.assertEqual(result["outcome"], "unknown")
        self.assertFalse(result["hostAttributed"])
        self.assertIsNone(result["reportSHA256"])

    def test_binding_no_final_times_out_without_relaunch(self):
        self.no_final = True
        _, result = self.cli()
        self.assertEqual(result["failureKind"], "timeout")
        self.assertEqual(self.calls, 1)
        self.assertFalse(result["hostAttributed"])

    def test_binding_partial_consume_is_spent_even_if_unparseable(self):
        path = self.root / "binding-consumed.json"
        path.write_bytes(b"{"); path.chmod(0o600)
        _, result = self.cli()
        self.assertEqual(self.calls, 0)
        self.assertFalse(result["hostAttributed"])

    def test_binding_consume_and_machine_schema_fail_closed(self):
        self.cli()
        consume = live.load(self.root / "binding-consumed.json")
        machine = live.load(self.root / "attempt/launcher.machine.json")
        for kind, value in (("consume", consume), ("machine", machine)):
            for key in value:
                changed = dict(value); changed.pop(key)
                with self.assertRaises(live.Rejected): live.binding_validate(kind, changed)
            for changed in (dict(value, extra=True), dict(value, schemaVersion=True), dict(value, contextSHA256=None)):
                with self.assertRaises(live.Rejected): live.binding_validate(kind, changed)

    def test_binding_changed_context_stops_before_consumption(self):
        self.context_sha = "a" * 64
        _, result = self.cli()
        self.assertFalse(result["hostAttributed"])
        self.assertEqual(self.calls, 0)
        self.assertFalse((self.root / "binding-consumed.json").exists())

    def test_binding_changed_binary_stops_before_consumption(self):
        self.binary.write_bytes(b"CHANGED")
        _, result = self.cli()
        self.assertEqual(self.calls, 0)
        self.assertFalse(result["binaryVerified"])

    def test_binding_symlink_source_rejected_before_spawn(self):
        file = self.root / "source" / live.BINDING_SOURCES[0]
        file.unlink()
        file.symlink_to(self.binary)
        _, result = self.cli()
        self.assertEqual(self.calls, 0)
        self.assertIsNone(result["machineSHA256"])

    def test_binding_uuid_only_receipt_never_replaces_kernel_instance(self):
        self.process_change = {"live": False}
        _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertFalse((self.root / "attempt/ack.json").exists())

    def test_binding_unknown_process_preserves_report_without_ack(self):
        from unittest.mock import Mock
        self.hooks["inspect"] = Mock(side_effect=OSError("SECRET_UNKNOWN_PID"))
        _, result = self.cli()
        self.assertIsNotNone(result["reportSHA256"])
        self.assertIsNone(result["ackSHA256"])
        self.assertFalse(result["hostAttributed"])
        self.assertNotIn("SECRET", json.dumps(result))

    def test_binding_clock_reversal_never_acknowledges(self):
        self.hooks["wall"] = lambda: 2000000000000000 if self.calls == 0 else 1
        _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertIsNone(result["ackSHA256"])

    def test_binding_changed_final_link_is_rejected(self):
        self.final_change = {"ackSHA256": "e" * 64}
        _, result = self.cli()
        self.assertFalse(result["bindingMatched"])
        self.assertIsNone(result["finalSHA256"])

    def test_binding_spawn_error_is_finite_and_preserved(self):
        self.spawn_error = True
        _, result = self.cli()
        machine = live.load(self.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeExceptionKind"], "spawnOS")
        self.assertTrue(machine["spawnAttempted"])
        self.assertIsNone(machine["nativePID"])
        self.assertEqual(machine["nativeReturnKind"], "unknown")
        self.assertNotIn("PRIVATE_NATIVE_ERROR", json.dumps(result))

    def test_binding_native_nonzero_preserved_after_protocol_chain(self):
        self.native_rc = 7
        _, result = self.cli()
        machine = live.load(self.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeReturnCode"], 7)
        self.assertEqual(machine["nativeReturnKind"], "nonzero")
        self.assertEqual(result["failureKind"], "native")
        self.assertFalse(result["hostAttributed"])

    def test_binding_native_signal_preserved_after_protocol_chain(self):
        self.native_rc = -15
        _, result = self.cli()
        machine = live.load(self.root / "attempt/launcher.machine.json")
        self.assertEqual(machine["nativeSignal"], 15)
        self.assertEqual(machine["nativeReturnCode"], -15)
        self.assertEqual(result["nativeReturnKind"], "signal")

    def test_binding_machine_complete_pending_is_not_published_on_sync_failure(self):
        from unittest.mock import patch
        original = live.launcher_write
        def fail(path, value):
            sha = original(path, value)
            if Path(path).name == "launcher.machine.pending.json": raise OSError("PRIVATE_SYNC")
            return sha
        with patch.object(live, "launcher_write", side_effect=fail):
            _, result = self.cli()
        self.assertTrue((self.root / "attempt/launcher.machine.pending.json").exists())
        self.assertFalse((self.root / "attempt/launcher.machine.json").exists())
        self.assertIsNone(result["machineSHA256"])
        self.assertFalse(result["hostAttributed"])
        self.assertEqual(result["failureKind"], "write")

    def test_binding_ack_write_failure_does_not_publish_final(self):
        from unittest.mock import patch
        original = live.launcher_write
        def fail(path, value):
            if Path(path).name == "ack.pending.json": raise OSError("PRIVATE_ACK")
            return original(path, value)
        with patch.object(live, "launcher_write", side_effect=fail):
            _, result = self.cli()
        self.assertFalse(result["bindingMatched"])
        self.assertIsNone(result["ackSHA256"])
        self.assertFalse((self.root / "attempt/host.final.json").exists())

    def test_binding_published_pair_must_share_inode_and_never_overwrite(self):
        self.cli()
        final = self.root / "attempt/launcher.machine.json"
        raw = final.read_bytes()
        with self.assertRaises(live.Rejected): live.binding_publish(self.root, final, {})
        self.assertEqual(final.read_bytes(), raw)
        pending = self.root / "attempt/launcher.machine.pending.json"
        pending.unlink()
        pending.write_bytes(raw)
        pending.chmod(0o600)
        with self.assertRaises(live.Rejected): live.binding_published(self.root, final.name)

    def test_binding_all_private_schema_fields_are_required_and_bound(self):
        import copy
        self.cli()
        consume = live.load(self.root / "binding-consumed.json")
        machine = live.load(self.root / "attempt/launcher.machine.json")
        for kind, value in (("consume", consume), ("machine", machine)):
            for field in value:
                changed = copy.deepcopy(value)
                del changed[field]
                with self.subTest(kind=kind, missing=field), self.assertRaises(live.Rejected):
                    live.binding_validate(kind, changed)
            for field in (live.BINDING_KEYS | {"readyUUID", "runnerSHA256", "evidenceMode"}):
                changed = copy.deepcopy(value)
                changed[field] = "a" * 64 if field.endswith("SHA256") else str(uuid.uuid4()) if field.endswith("UUID") else "wrong"
                with self.subTest(kind=kind, mismatch=field), self.assertRaises(live.Rejected):
                    live.binding_validate(kind, changed, value)
        changed = copy.deepcopy(machine)
        changed.update(evidenceMode="fake-only", hostAttributed=True, outcome="hostAttributed")
        with self.assertRaises(live.Rejected): live.binding_validate("machine", changed)

    def test_binding_observed_wall_reversal_above_created_rejects_second_instance(self):
        base = 2000000000000000
        samples = iter((base, base + 10000000, base + 5000000))
        self.hooks["wall"] = lambda: next(samples, base + 5000000)
        _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertIsNone(result["ackSHA256"])
        self.assertFalse((self.root / "attempt/ack.json").exists())
        self.assertFalse((self.root / "attempt/host.final.json").exists())

    def test_binding_observed_wall_reversal_after_report_wait_rejects_first_instance(self):
        base = 2000000000000000
        samples = iter((base, base + 10000000, base + 5000000))
        self.hooks["wall"] = lambda: next(samples, base + 5000000)
        self.no_report = True
        original_tick = self.tick
        def delayed_report(duration):
            original_tick(duration)
            if not (self.root / "attempt/host.report.json").exists():
                live.binding_publish(self.root, self.root / "attempt/host.report.json", self.report)
        self.hooks["sleep"] = delayed_report
        _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertIsNone(result["ackSHA256"])
        self.assertFalse((self.root / "attempt/ack.json").exists())


    def test_profile_free_proof_schema_rejects_legacy_opaque_receipts(self):
        with self.assertRaises(live.Rejected):
            live.binding_validate_proof("build", {"evidenceMode": "fake-only"}, "fake-only")

    def test_profile_free_proof_strict_identity_and_claims(self):
        build, signing = profile_free_fixture(self.root, self.context["sourceHashes"], self.binary)
        for field, invalid in (("purpose", "namespace-read-only"), ("variant", "DPK"),
                ("certificateDER_SHA256", "e" * 64), ("embeddedProfilePresent", True),
                ("entitlementsEmpty", False), ("signatureValid", 1)):
            bad = dict(signing, **{field: invalid})
            with self.subTest(field=field), self.assertRaises(live.Rejected):
                live.binding_validate_proof("signing", bad, "fake-only")
        live.binding_validate_proof("build", build, "fake-only")
        live.binding_validate_proof("signing", signing, "fake-only")
        with self.assertRaises(live.Rejected): live.binding_validate_proof("signing", signing, "signed-host")


    def test_profile_free_dynamic_identity_mismatch_never_acknowledges(self):
        from unittest.mock import patch
        signing = live.load(self.root / "signing.machine.json")
        self.hooks["verify"] = lambda *args: signing
        self.hooks["verify_process"] = live.binding_verify_process
        with patch.object(live, "binding_code_identity", return_value={"certificateDER_SHA256": "e" * 64}):
            _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertIsNone(result["ackSHA256"])
        self.assertFalse((self.root / "attempt/ack.json").exists())

    def test_profile_free_embedded_profile_is_rejected_before_signature_command(self):
        from unittest.mock import Mock
        (self.binary.parents[1] / "embedded.provisionprofile").write_bytes(b"FAKE_PROFILE")
        command = Mock(side_effect=AssertionError("must reject before native command"))
        with self.assertRaises(live.Rejected):
            live.binding_verify_static(self.root, self.context, self.binary, command=command)
        command.assert_not_called()


    def test_profile_free_exact_proof_keys_types_and_context_hashes(self):
        build, signing = profile_free_fixture(self.root, self.context["sourceHashes"], self.binary)
        for kind, value in (("build", build), ("signing", signing)):
            for field in value:
                invalid = dict(value); del invalid[field]
                with self.subTest(kind=kind, missing=field), self.assertRaises(live.Rejected):
                    live.binding_validate_proof(kind, invalid, "fake-only")
            with self.assertRaises(live.Rejected): live.binding_validate_proof(kind, dict(value, extra=True), "fake-only")
            with self.assertRaises(live.Rejected): live.binding_validate_proof(kind, dict(value, schemaVersion=True), "fake-only")
        with self.assertRaises(live.Rejected):
            live.binding_validate_proof("build", dict(build, compileConditions=["DEBUG"]), "fake-only")
        with self.assertRaises(live.Rejected):
            live.binding_validate_proof("signing", dict(signing, certificateDER_SHA256=None), "fake-only")
        for key in ("buildProofSHA256", "signingProofSHA256", "expectedBinarySHA256"):
            with self.subTest(context=key), self.assertRaises(live.Rejected):
                live.binding_profile_free_proofs(self.root, dict(self.context, **{key: "f" * 64}), "fake-only")



if __name__ == "__main__":
    unittest.main()


class DPKWindowControls(unittest.TestCase):
    """Synthetic window data only; no Human authority or native OS probes."""
    def fixture(self, root):
        phases = list(live.DPK_WINDOW_PHASES)
        policy = dict(saveMaxPrompts=1, freshReadMaxPrompts=0, replaceMaxPrompts=0, buildSignMaxKeyAuthorizations=1)
        descriptor = dict(schemaVersion=1, purpose=live.DPK_PURPOSE, roundUUID=str(uuid.uuid4()),
            sourceHashes={k:"a"*64 for k in live.BINDING_SOURCES}, operationalSourceHashes={k:"b"*64 for k in live.BINDING_SOURCES},
            callerSHA256="c"*64, controllerSHA256="d"*64, unsignedDebugBinarySHA256="e"*64,
            unsignedRebuiltBinarySHA256="f"*64, profileSHA256="a"*64, certificateSHA256=live.BINDING_CERTIFICATE_SHA256,
            identityInputsSHA256="b"*64, parentLG59MachineSHA256="c"*64, parentLG64ResultSHA256="d"*64,
            parentOfflineFreezeSHA256="e"*64, maximumWindowSeconds=3600, bootSessionPolicy=live.DPK_BOOT_POLICY,
            allowedPhases=phases, promptLimits=policy)
        live.exclusive_json(root/"descriptor.json",descriptor)
        self.boot=live.dpk_boot_hash(b"11111111-1111-4111-8111-111111111111\x00")
        human=dict(schemaVersion=1,purpose=live.DPK_PURPOSE,descriptorSHA256=live.digest((root/"descriptor.json").read_bytes()),
            liveAuthorized=True,ready=True,readyUUID=str(uuid.uuid4()),readyAtUnixSeconds=2_000_000_000,
            readyAtMonotonicNanoseconds=10_000_000_000,bootSessionSHA256=self.boot,windowSeconds=3600,acceptedPromptLimits=policy)
        live.exclusive_json(root/"human-window.json",human)
        self.sample=[2_000_000_001,11_000_000_000,self.boot]
        self.clock=lambda:tuple(self.sample)
        return descriptor,human

    def opened(self,root):
        descriptor,human=self.fixture(root)
        live.dpk_open_window(root,human["descriptorSHA256"],root/"human-window.json",asset_expiry=2_000_004_000,
            sample=self.clock,evidence_mode="fake-only")
        return descriptor,human,live.DPKWindow.read(root,mode="fake-only",sample=self.clock)

    def test_canonical_boot_and_malformed_are_rejected(self):
        self.assertEqual(live.dpk_boot_hash(b"AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA\x00"),
                         live.dpk_boot_hash(b"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa\x00"))
        for raw in (b"x",b"00000000-0000-0000-0000-000000000000\x00",b"a"*36,b" "+b"a"*36+b"\x00"):
            with self.assertRaises(live.Rejected):live.dpk_boot_hash(raw)

    def test_factory_real_files_schema_publication_and_once(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp).resolve();_,human,window=self.opened(root)
            window.check(phase="save-a",reserve=120)
            self.assertEqual(window.value["humanAuthorizationSHA256"],live.digest((root/"human-window.json").read_bytes()))
            self.assertEqual((root/"live-authority.json").stat().st_ino,(root/"live-authority.pending.json").stat().st_ino)
            with self.assertRaises(live.Rejected):live.dpk_open_window(root,human["descriptorSHA256"],root/"human-window.json",asset_expiry=2_000_004_000,sample=self.clock,evidence_mode="fake-only")
            with self.assertRaises(live.Rejected):live.DPKWindow.read(root,sample=self.clock)

    def test_boot_reversal_remaining_and_scope_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            _,_,window=self.opened(Path(temp).resolve());window.check(phase="read-a")
            for sample in ([2_000_000_002,12_000_000_000,"f"*64],[2_000_000_000,12_000_000_000,self.boot],
                           [2_000_000_002,10_000_000_000,self.boot],[2_000_003_599,3_609_000_000_000,self.boot]):
                self.sample[:]=sample
                with self.assertRaises(live.DPKDeadlineRejected):window.check(phase="read-a",reserve=120)
            self.sample[:]=[2_000_000_002,12_000_000_000,self.boot]
            with self.assertRaises(live.Rejected):window.check(phase="cleanup")

    def test_unknown_extra_type_and_partial_authority_fail_closed(self):
        from unittest.mock import patch
        for mutation in (lambda h:h.update(ready=1),lambda h:h.update(windowSeconds=True),lambda h:h.update(extra=True),
                         lambda h:h.pop("bootSessionSHA256"),lambda h:h.update(bootSessionSHA256="f"*64)):
            with tempfile.TemporaryDirectory() as temp:
                root=Path(temp).resolve();_,human=self.fixture(root);mutation(human)
                with patch.object(live,"binding_read",side_effect=lambda r,p:(human,"a"*64) if p.name=="human-window.json" else (json.loads(p.read_bytes()),live.digest(p.read_bytes()))):
                    with self.assertRaises(live.Rejected):live.dpk_open_window(root,"a"*64,root/"human-window.json",asset_expiry=2_000_004_000,sample=self.clock,evidence_mode="fake-only")
                self.assertFalse((root/"window-open-consumed.json").exists())
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp).resolve();_,human=self.fixture(root);live.exclusive_json(root/"live-authority.pending.json",{})
            with self.assertRaises(live.Rejected):live.dpk_open_window(root,human["descriptorSHA256"],root/"human-window.json",asset_expiry=2_000_004_000,sample=self.clock,evidence_mode="fake-only")


    def test_fresh_phase_ready_and_expired_native_preserves_original_error(self):
        import subprocess
        with tempfile.TemporaryDirectory() as temp:
            descriptor,human,window=self.opened(Path(temp).resolve())
            ready=dict(roundUUID=descriptor["roundUUID"],phase="read-a",readyUUID=str(uuid.uuid4()),ready=True,
                authoritySHA256=window.sha,readyAtUnixSeconds=2_000_000_001,readyAtMonotonicNanoseconds=11_000_000_000)
            window.fresh_ready(ready,"read-a")
            for key,value in (("ready",1),("authoritySHA256","f"*64),("readyAtUnixSeconds",1),("phase","cleanup")):
                with self.assertRaises(live.Rejected):window.fresh_ready(dict(ready,**{key:value}),"read-a")
            seen=[]
            native_error=subprocess.CalledProcessError(17,["FINITE_FAKE"],output=b"private-native-output")
            def native(args,timeout):
                seen.append(args);self.sample[0]=2_000_004_000
                raise native_error
            with self.assertRaises(subprocess.CalledProcessError) as caught:
                window.native(native,["FINITE_FAKE"],10,phase="read-a")
            self.assertIs(caught.exception,native_error)
            with self.assertRaises(live.DPKDeadlineRejected):window.native(native,["MUST_NOT_START"],10,phase="read-a")
            self.assertEqual(seen,[["FINITE_FAKE"]])

    def test_stale_ready_asset_expiry_and_unavailable_clock_consume_nothing(self):
        for mode in ("stale","asset","unavailable"):
            with tempfile.TemporaryDirectory() as temp:
                root=Path(temp).resolve();_,human=self.fixture(root)
                if mode=="stale":self.sample[:2]=[2_000_000_061,71_000_000_000]
                def unavailable():raise OSError("PRIVATE_KERNEL_ERROR")
                with self.assertRaises(live.Rejected):
                    live.dpk_open_window(root,human["descriptorSHA256"],root/"human-window.json",asset_expiry=2_000_003_599 if mode=="asset" else 2_000_004_000,sample=unavailable if mode=="unavailable" else self.clock,evidence_mode="fake-only")
                self.assertFalse((root/"window-open-consumed.json").exists())


class DPKControls(unittest.TestCase):
    """DPK controls in ordinary fake scratch; never Security or an App."""
    def test_absolute_deadline_and_start_reserve(self):
        end = 1793786789
        self.assertEqual(live.dpk_time(60, now=end - 61), end - 61)
        for now in (end - 59, end, end + 1):
            with self.assertRaises(live.Rejected): live.dpk_time(60, now=now)

    def test_operation_result_exact_boolean_fields(self):
        result = dict(phase="save-a", comparison={k: True for k in live.FIELDS}, ownershipVerified=True)
        live.dpk_result(result, "save-a")
        for key, value in (("ownershipVerified", 1), ("phase", "cleanup")):
            changed = dict(result); changed[key] = value
            with self.assertRaises(live.Rejected): live.dpk_result(changed, "save-a")
        changed = dict(result, comparison=dict(result["comparison"], accessToken=1))
        with self.assertRaises(live.Rejected): live.dpk_result(changed, "save-a")

    def test_dpk_binding_rejects_profile_free_and_wrong_phase(self):
        b = dict(schemaVersion=1, purpose="dpk-credential-validation", attemptUUID=str(uuid.uuid4()),
                 contextSHA256="a"*64, expectedBinarySHA256="b"*64, roundSHA256="c"*64,
                 phase="save-a", createdAtUnixMicroseconds=1)
        live.binding_validate("request", b)
        for phase in ("cleanup", "setup", "save-A"):
            with self.assertRaises(live.Rejected): live.binding_validate("request", dict(b, phase=phase))
        with self.assertRaises(live.Rejected): live.binding_validate("request", dict(b, purpose="launch-report-only"))

    def test_dpk_final_result_required_and_bound(self):
        b = dict(schemaVersion=1, purpose="dpk-credential-validation", attemptUUID=str(uuid.uuid4()),
                 contextSHA256="a"*64, expectedBinarySHA256="b"*64, roundSHA256="c"*64,
                 requestSHA256="d"*64, phase="save-a", hostReportSHA256="e"*64, ackSHA256="f"*64,
                 outcome="completed")
        with self.assertRaises(live.Rejected): live.binding_validate("final", b)
        good = dict(b, operationResult=dict(phase="save-a", comparison={k: True for k in live.FIELDS}, ownershipVerified=True))
        live.binding_validate("final", good)
        good["operationResult"]["phase"] = "read-a"
        with self.assertRaises(live.Rejected): live.binding_validate("final", good)


class DPKWire(unittest.TestCase):
    def test_actual_runner_phase_wire_and_publication_with_finite_native_child(self):
        import subprocess
        import sys
        import time
        fixture = LaunchBindingControls(methodName="runTest")
        fixture.setUp(); self.addCleanup(fixture.doCleanups)
        parent = fixture.root
        root = parent / "dpk-acceptance-1"
        root.mkdir(mode=0o700)
        for original in list(parent.iterdir()):
            if original != root: original.rename(root / original.name)
        fixture.root = root
        fixture.binary = root / "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe"
        profile = b"FAKE_ONLY_PROFILE"
        (root / "profile.provisionprofile").write_bytes(profile)
        (root / "profile.provisionprofile").chmod(0o600)
        build = live.load(root / "build.machine.json")
        signing = live.load(root / "signing.machine.json")
        for item in (build, signing): item.update(purpose=live.DPK_PURPOSE, variant="dpk-entitled")
        build["compileConditions"] = ["DEBUG", "DPK_VALIDATION_ONLY"]
        (root / "build.machine.json").unlink(); live.exclusive_json(root / "build.machine.json", build)
        signing.update(buildProofSHA256=live.digest((root / "build.machine.json").read_bytes()),
                       entitlementsEmpty=False, embeddedProfilePresent=True,
                       profileSHA256=live.digest(profile), entitlementsSHA256="a"*64,
                       groupSHA256=live.digest(b"FAKEGROUP.local.probe"))
        (root / "signing.machine.json").unlink(); live.exclusive_json(root / "signing.machine.json", signing)
        run = str(uuid.uuid4())
        window_fixture=DPKWindowControls(methodName="runTest")
        descriptor,human,window=window_fixture.opened(root)
        run=descriptor["roundUUID"]
        for leaf in ("build.machine.json","signing.machine.json"):
            proof=live.load(root/leaf);proof["authoritySHA256"]=window.sha
            if leaf=="signing.machine.json":proof["buildProofSHA256"]=live.digest((root/"build.machine.json").read_bytes())
            (root/leaf).unlink();live.exclusive_json(root/leaf,proof)
        signing=live.load(root/"signing.machine.json")
        value = dict(schemaVersion=1, purpose=live.DPK_PURPOSE, roundUUID=run,
                     service=live.service(run), account="credential", clientID="rivet-validation-fake-client",
                     group="FAKEGROUP.local.probe", deadlineUTC="2033-05-18T04:33:20Z",authoritySHA256=window.sha,
                     parentLG59MachineSHA256="a"*64, parentLG64ResultSHA256="b"*64,
                     sourceHashes=fixture.context["sourceHashes"], profileSHA256=live.digest(profile),
                     certificateSHA256=live.BINDING_CERTIFICATE_SHA256,
                     initialBuildProofSHA256=signing["buildProofSHA256"],
                     initialSigningProofSHA256=live.digest((root / "signing.machine.json").read_bytes()))
        value["deadlineUTC"]=live.dt.datetime.fromtimestamp(window.value["expiresAtUnixSeconds"],live.dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        live.exclusive_json(root / "round.json", value)
        fixture.context.update(authoritySHA256=window.sha,purpose=live.DPK_PURPOSE, roundSHA256=live.digest((root / "round.json").read_bytes()),
            profileSHA256=live.digest(profile), buildProofSHA256=value["initialBuildProofSHA256"],
            signingProofSHA256=value["initialSigningProofSHA256"])
        (root / "context.json").unlink(); live.exclusive_json(root / "context.json", fixture.context)
        (root / "phases").mkdir(mode=0o700)
        phase = "save-a"; folder = root / "phases" / phase
        epoch = 2_000_000_001_000_000
        hooks = fixture.hooks.copy()
        hooks["wall"] = lambda: epoch + int(fixture.ticks * 1000000)
        hooks["window_sample"]=lambda:(2_000_000_001+int(fixture.ticks),11_000_000_000+int(fixture.ticks*1e9),window_fixture.boot)
        shared = {}
        def spawn(command, out, err):
            self.assertIn("--dpk-validation-only", command)
            self.assertTrue(any(x.startswith("RIVET_DPK_REQUEST=") for x in command))
            self.assertFalse(any(x.startswith("RIVET_LAUNCH_REPORT_REQUEST=") for x in command))
            request = live.load(folder / "request.json")
            binding = {k: request[k] for k in live.BINDING_KEYS | {"roundSHA256", "phase"} if k != "requestSHA256"}
            binding["requestSHA256"] = live.digest((folder / "request.json").read_bytes())
            self.assertEqual(command[-4:], ["--request", str(folder / "request.json"), "--request-sha", binding["requestSHA256"]])
            process = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(0.15)"], stdout=out, stderr=err)
            self.addCleanup(lambda: process.wait(timeout=3))
            shared.update(binding=binding, process=process)
            entry = dict(binding, stage="bootstrap", outcome="entered", wire=dict(argvShape="expected", argvPair="valid", envPair="valid", channelsMatch=True),observedBinarySHA256=None,pid=None,startSeconds=None,startMicroseconds=None)
            live.binding_publish(root, folder / "host.entry.json", entry)
            report = dict(binding, observedBinarySHA256=fixture.context["expectedBinarySHA256"],pid=process.pid,
                startSeconds=epoch//1000000,startMicroseconds=epoch%1000000,processUUID=str(uuid.uuid4()),stage="report",outcome="awaitingAck")
            shared["report"]=report
            live.binding_publish(root,folder/"host.report.json",report)
            return process
        def inspect(pid):
            report=shared["report"]
            return dict(pid=pid,uid=os.getuid(),startSeconds=report["startSeconds"],startMicroseconds=report["startMicroseconds"],executable=str(fixture.binary),live=True)
        def tick(duration):
            fixture.ticks += max(duration,0.01)
            if (folder/"ack.json").exists() and not (folder/"host.final.json").exists():
                ack=live.load(folder/"ack.json")
                final=dict(ack,ackSHA256=live.digest((folder/"ack.json").read_bytes()),outcome="completed",operationResult=dict(phase=phase,comparison={k:True for k in live.FIELDS},ownershipVerified=True))
                live.binding_publish(root,folder/"host.final.json",final)
        hooks.update(spawn=spawn,inspect=inspect,sleep=tick)
        blocked,blocked_code=live.binding_launch(root/"context.json",live.digest((root/"context.json").read_bytes()),str(uuid.uuid4()),str(uuid.uuid4()),True,hooks,phase)
        self.assertEqual(blocked_code,1);self.assertFalse(blocked["hostAttributed"])
        self.assertEqual(shared,{})
        self.assertFalse(folder.exists())
        ready_id=str(uuid.uuid4())
        phase_ready=dict(roundUUID=run,phase=phase,readyUUID=ready_id,ready=True,authoritySHA256=window.sha,readyAtUnixSeconds=2_000_000_001,readyAtMonotonicNanoseconds=11_000_000_000)
        output,code=live.binding_launch(root/"context.json",live.digest((root/"context.json").read_bytes()),str(uuid.uuid4()),ready_id,True,hooks,phase,phase_ready)
        self.assertEqual(code,1)  # Fake-only never acquires signed-host attribution.
        self.assertTrue(output["operationVerified"])
        self.assertTrue(output["bindingMatched"])
        self.assertTrue(output["nativeSettled"])
        self.assertFalse(output["hostAttributed"])
        self.assertEqual(live.binding_published(root,"host.final.json",phase)[0]["operationResult"]["comparison"],{k:True for k in live.FIELDS})
        original_process=shared["process"]
        rejected, rejected_code=live.binding_launch(root/"context.json","a"*64,str(uuid.uuid4()),str(uuid.uuid4()),True,hooks,phase)
        self.assertEqual(rejected_code,1)
        self.assertFalse(rejected["hostAttributed"])
        self.assertIsNone(rejected["machineSHA256"])
        self.assertIs(shared["process"],original_process)

        # RF-LG68-01: the predecessor machine is immutable while a valid paired report is substituted.
        from unittest.mock import patch
        machine, machine_sha = live.binding_published(root,"launcher.machine.json","save-a")
        human=dict(roundUUID=run,phase="save-a",machineSHA256=machine_sha,promptCount=0,wholeStageObserved=True,actions=[])
        live.exclusive_json(folder/"human.json",human)
        ready=root/"read-a.ready.json"
        live.exclusive_json(ready,dict(roundUUID=run,phase="read-a",readyUUID=str(uuid.uuid4()),ready=True,authoritySHA256=window.sha,readyAtUnixSeconds=2_000_000_001,readyAtMonotonicNanoseconds=11_000_000_000))
        observed=[]
        stage_hooks=hooks | {"previous_gone":lambda report: observed.append(report) or True}
        with patch.object(live,"binding_launch",return_value=({"fake":True},1)) as delegate:
            live.dpk_stage(root,"read-a",ready,stage_hooks)
            self.assertEqual(len(observed),1)
            delegate.assert_called_once()
        observed.clear()
        previous_report=folder/"host.report.json"
        tampered=live.load(previous_report)
        tampered.update(attemptUUID=str(uuid.uuid4()),pid=tampered["pid"]+1)
        previous_report.write_text(json.dumps(tampered,sort_keys=True))  # Same inode as pending, only ordinary fixture.
        self.assertNotEqual(live.digest(previous_report.read_bytes()),machine["reportSHA256"])
        with patch.object(live,"binding_launch",return_value=({"fake":True},1)) as delegate:
            with self.assertRaises(live.Rejected): live.dpk_stage(root,"read-a",ready,stage_hooks)
            delegate.assert_not_called()
            self.assertEqual(observed,[])
        self.assertFalse((root/"phases/read-a").exists())


class SwiftDPKChecks(unittest.TestCase):
    def test_actual_new_swift_dpk_handshake_shared_operation(self):
        import subprocess
        binary=os.environ.get("RIVET_DPK_PROBE_BINARY")
        if not binary: self.skipTest("new DPK unsigned CLI required")
        result=subprocess.run([binary,"--self-test-dpk"],capture_output=True,timeout=15)
        self.assertEqual(result.returncode,0)
        value=json.loads(result.stdout)
        self.assertEqual(value["mode"],"dpk-fake-only")
        self.assertEqual(value["windowPassed"],14)
        self.assertEqual(value["passed"],9)
        self.assertEqual(value["failures"],[])
        for argv in ([],["--request","PRIVATE_PATH","--request-sha","a"*64],["--launcher-amendment-only"]):
            rejected=subprocess.run([binary,*argv],env={"PATH":"/usr/bin:/bin"},capture_output=True,timeout=5)
            self.assertNotEqual(rejected.returncode,0)
            self.assertEqual(json.loads(rejected.stderr)["purpose"],live.DPK_PURPOSE)
            self.assertNotIn(b"PRIVATE_PATH",rejected.stderr)


class DPKInstanceControls(unittest.TestCase):
    def test_exact_previous_instance_absence_and_unknown_are_distinct(self):
        import ctypes
        import errno
        from types import SimpleNamespace
        report=dict(pid=42,startSeconds=100,startMicroseconds=7)
        for error,expected in ((errno.ESRCH,True),(errno.ENOENT,False),(errno.EPERM,False),(0,False)):
            def call(*args):
                ctypes.set_errno(error);return 0
            self.assertIs(live.dpk_previous_gone(report,library=SimpleNamespace(proc_pidinfo=call)),expected)
        for status,seconds,expected in ((2,100,False),(5,100,True),(2,101,True)):
            def call(pid,flavor,arg,pointer,size):
                self.assertEqual((pid,flavor,arg),(42,3,1))
                info=pointer._obj;info.pbi_pid=pid;info.pbi_uid=os.getuid();info.pbi_status=status
                info.pbi_start_tvsec=seconds;info.pbi_start_tvusec=7
                return size
            self.assertIs(live.dpk_previous_gone(report,library=SimpleNamespace(proc_pidinfo=call)),expected)


class StaticEvidenceModeControls(unittest.TestCase):
    def test_default_rejects_fake_explicit_fake_uses_real_validator_wrong_mode_rejects(self):
        import plistlib
        fixture=LaunchBindingControls(methodName="runTest");fixture.setUp();self.addCleanup(fixture.doCleanups)
        root=fixture.root;bundle="local.fixture.dpk"
        der_path=os.environ.get("RIVET_DPK_PUBLIC_DER")
        if not der_path:self.skipTest("pinned public DER fixture required; no Keychain lookup")
        der=Path(der_path).read_bytes();self.assertEqual(live.digest(der),live.BINDING_CERTIFICATE_SHA256)
        team=live.binding_certificate_team(der)
        info=root/"app/CredentialStorageProbe.app/Contents/Info.plist";info.write_bytes(plistlib.dumps(dict(CFBundleExecutable="CredentialStorageProbe",CFBundleIdentifier=bundle)));info.chmod(0o600)
        project=root/"source"/live.PROJECT_FILES[0];project.write_text("PRODUCT_BUNDLE_IDENTIFIER = "+bundle+";")
        native=[]
        def command(argv,timeout):
            native.append(argv)
            if argv[0]=="/usr/bin/csreq":return b'identifier "local.fixture.dpk" and anchor apple generic',b""
            if "--verbose=4" in argv:return b"",("Identifier="+bundle+"\nTeamIdentifier="+team+"\n").encode()
            if "--entitlements" in argv:return plistlib.dumps({}),b""
            if "-r-" in argv:return b"",b'designated => identifier "local.fixture.dpk" and anchor apple generic'
            for item in argv:
                if item.startswith("--extract-certificates="):
                    Path(item.split("=",1)[1]+"0").write_bytes(der)
            return b"",b""
        observed=live.binding_code_identity(fixture.binary.parents[2],command=command)
        build=live.load(root/"build.machine.json");build["sourceHashes"][live.PROJECT_FILES[0]]=live.digest(project.read_bytes())
        (root/"build.machine.json").unlink();live.exclusive_json(root/"build.machine.json",build)
        signing=live.load(root/"signing.machine.json");signing.update(observed,buildProofSHA256=live.digest((root/"build.machine.json").read_bytes()),bundleIdentifierSHA256=live.digest(bundle.encode()))
        (root/"signing.machine.json").unlink();live.exclusive_json(root/"signing.machine.json",signing)
        fixture.context.update(sourceHashes=build["sourceHashes"],buildProofSHA256=signing["buildProofSHA256"],signingProofSHA256=live.digest((root/"signing.machine.json").read_bytes()))
        (root/"context.json").unlink();live.exclusive_json(root/"context.json",fixture.context)
        live.binding_context(root/"context.json",live.digest((root/"context.json").read_bytes()),"fake-only")
        native.clear()
        with self.assertRaises(live.Rejected):live.binding_verify_static(root,fixture.context,fixture.binary,command=command)
        self.assertEqual(native,[])
        value=live.binding_verify_static(root,fixture.context,fixture.binary,command=command,mode="fake-only")
        self.assertEqual(value["evidenceMode"],"fake-only")
        self.assertTrue(native)
        native.clear()
        with self.assertRaises(live.Rejected):live.binding_verify_static(root,fixture.context,fixture.binary,command=command,mode="invalid")
        self.assertEqual(native,[])
