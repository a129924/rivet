#!/usr/bin/env python3
"""E017 local verification controls. No live action without --human-ready."""
import argparse
import datetime as dt
import errno
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat
import subprocess
import sys
import time
import uuid

TOPIC = "github-pat-dpk-storage"
HOST = f"experiments/E017/{TOPIC}"
SOURCES = [
    "Package.swift", "Package.resolved",
    "Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift",
    "Sources/BoundedContexts/GitHubIntegration/Contracts/LoginAuthentication.swift",
    f"{HOST}/Sources/main.swift", f"{HOST}/Resources/Info.plist",
    f"{HOST}/Resources/PATStorageProbe.entitlements",
    f"{HOST}/PATStorageProbe.xcodeproj/project.pbxproj",
    f"{HOST}/scripts/pat_storage_probe.py",
]
PHASES = ["save-a", "read-a", "replace-b", "read-b", "rebuilt-read-b", "cleanup"]
LIMITS = {phase: (1 if phase == "save-a" else 0) for phase in PHASES}
LIMITS["cleanup"] = None  # Record cleanup prompts; no additional UX threshold.
RECOVERY_PHASE = "verify-absence"
LIMITS[RECOVERY_PHASE] = 0


class GuardError(Exception):
    pass


def require(value):
    if not value:
        raise GuardError()


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def secure(path, directory=False):
    value = Path(path)
    info = value.lstat()
    require(info.st_uid == os.getuid())
    require(stat.S_ISDIR(info.st_mode) if directory else stat.S_ISREG(info.st_mode))
    require(stat.S_IMODE(info.st_mode) == (0o700 if directory else 0o600))
    return value


def read(path):
    target = secure(path)
    require(target.stat().st_size <= 1_048_576)
    return json.loads(target.read_text())


def publish(path, value):
    path = Path(path)
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, "w") as handle:
        json.dump(value, handle, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    parent = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(parent)
    finally:
        os.close(parent)


def sources(repo):
    return {name: digest(repo / name) for name in SOURCES}


def context(root):
    root = Path(root).absolute()
    require(root == root.resolve())
    secure(root, directory=True)
    run = read(root / "run.json")
    require(str(uuid.UUID(run["runID"])) == run["runID"])
    require(run["service"] == "local.rivet.github.pat.validation." + run["runID"])
    private = read(root / "source.json")
    repo = Path(private["repo"])
    require(sources(repo) == private["sources"])
    return root, run, repo, private


def command(argv, timeout=30):
    return subprocess.run(argv, check=True, capture_output=True, timeout=timeout)


def prepare(args):
    repo = Path(args.repo).resolve(strict=True)
    parent = Path(args.parent).resolve(strict=True)
    require(args.access_group.strip() and "*" not in args.access_group)
    run_id = str(uuid.uuid4())
    root = parent / ("rivet-pat-storage-" + run_id)
    root.mkdir(mode=0o700)
    run = {"runID": run_id, "service": "local.rivet.github.pat.validation." + run_id,
           "accessGroup": args.access_group}
    publish(root / "run.json", run)
    commit = command(["git", "-C", str(repo), "rev-parse", "HEAD"]).stdout.decode().strip()
    publish(root / "source.json", {"repo": str(repo), "commit": commit, "sources": sources(repo)})
    print(root)


def application_identifier(claims):
    require(isinstance(claims, dict))
    values = [claims[key] for key in ("com.apple.application-identifier", "application-identifier")
              if key in claims]
    require(values and all(isinstance(value, str) and value and "*" not in value for value in values))
    require(all(value == values[0] for value in values))
    return values[0]


def profile_allows_group(allowed_groups, group):
    require(isinstance(allowed_groups, list))
    return any(isinstance(allowed, str) and
               (allowed == group or (allowed.endswith(".*") and allowed.count("*") == 1
                                     and group.startswith(allowed[:-1])))
               for allowed in allowed_groups)


def inspect(app, group, root):
    require(isinstance(group, str) and group.strip() and "*" not in group)
    command(["codesign", "--verify", "--deep", "--strict", str(app)])
    details = command(["codesign", "-d", "--verbose=4", str(app)]).stderr.decode()
    require("Signature=adhoc" not in details)
    fields = dict(line.split("=", 1) for line in details.splitlines() if "=" in line)
    require(fields.get("Identifier") == "local.rivet.pat-storage-probe")
    require(fields.get("TeamIdentifier") not in (None, "", "not set"))
    claims = plistlib.loads(command(["codesign", "-d", "--entitlements", ":-", str(app)]).stdout)
    require(isinstance(claims, dict) and claims.get("keychain-access-groups") == [group])
    embedded = app / "Contents/embedded.provisionprofile"
    profile = plistlib.loads(command(["security", "cms", "-D", "-i", str(embedded)]).stdout)
    profile_name = profile.get("Name")
    require(isinstance(profile_name, str) and profile_name.strip())
    expiry = profile["ExpirationDate"].replace(tzinfo=dt.timezone.utc)
    require(expiry > dt.datetime.now(dt.timezone.utc))
    require(fields["TeamIdentifier"] in profile["TeamIdentifier"])
    entitlements = profile["Entitlements"]
    require(isinstance(entitlements, dict))
    require(profile_allows_group(entitlements.get("keychain-access-groups", []), group))
    expected_identifier = fields["TeamIdentifier"] + "." + fields["Identifier"]
    require(application_identifier(entitlements) == application_identifier(claims) == expected_identifier)
    prefix = root / ("certificate-" + str(uuid.uuid4()) + "-")
    command(["codesign", "-d", "--extract-certificates=" + str(prefix), str(app)])
    certificate = Path(str(prefix) + "0")
    cert_bytes = certificate.read_bytes()
    require(cert_bytes in profile["DeveloperCertificates"])
    command(["openssl", "x509", "-inform", "DER", "-in", str(certificate), "-checkend", "0", "-noout"])
    certificate.unlink()
    requirement_output = command(["codesign", "-d", "-r-", str(app)]).stdout.decode()
    requirements = [line for line in requirement_output.splitlines() if line.startswith("designated =>")]
    require(len(requirements) == 1)
    requirement = requirements[0]
    return {"identifier": fields["Identifier"], "team": fields["TeamIdentifier"],
            "group": group, "certificateSHA256": hashlib.sha256(cert_bytes).hexdigest(),
            "certificateSHA1": hashlib.sha1(cert_bytes).hexdigest(), "profileName": profile_name,
            "profileSHA256": digest(embedded), "requirement": requirement}


def acceptance_binding(root, phase, machine):
    variant = machine["buildVariant"]
    require(variant in ("debug", "rebuilt"))
    run = read(root / "run.json")
    binding = {"runID": run["runID"], "phase": phase,
            "attemptSHA256": digest(root / (phase + ".attempt.json")),
            "hostSHA256": digest(root / (phase + ".host.json")),
            "buildProofSHA256": digest(root / ("build-" + variant + ".json")),
            "sourceProofSHA256": digest(root / "source.json")}
    if "recoveryID" in run:
        require(phase == RECOVERY_PHASE and machine.get("recoveryID") == run["recoveryID"])
        verify_recovery_links(root)
        binding.update(recoveryID=run["recoveryID"], amendmentSHA256=digest(root / "amendment.json"),
                       controllerSHA256=digest(root / "controller.py"))
    return binding


def accepted(root, phase, machine):
    path = root / (phase + ".accepted.json")
    if not path.exists():
        return False
    try:
        proof = read(path)
        expected = acceptance_binding(root, phase, machine)
        return (proof == expected and machine["runID"] == expected["runID"]
                and machine["phase"] == phase and machine["outcome"] == "completed")
    except (FileNotFoundError, KeyError, TypeError, ValueError, GuardError):
        return False


def observed(root, phase):
    machine = read(root / (phase + ".host.json"))
    human = read(root / (phase + ".observation.json"))
    require(accepted(root, phase, machine))
    require(machine["outcome"] == "completed")
    require(human["machineSHA256"] == digest(root / (phase + ".host.json")))
    require(human["wholeStageObserved"] is True and type(human["promptCount"]) is int)
    require(human["promptCount"] >= 0)
    if LIMITS[phase] is not None:
        require(human["promptCount"] <= LIMITS[phase])


def no_active_host(app):
    target = str(app / "Contents/MacOS/PATStorageProbe")
    listing = command(["ps", "-axo", "pid=,comm="]).stdout.decode()
    require(not any(line.strip().split(None, 1)[-1] == target for line in listing.splitlines() if line.strip()))


def recovery_trace(root, run):
    source = read(root / "source.json")
    return ("recoveryID" in run or root.name.startswith("recovery-") or
            "recoveryID" in source or "recoveryPurpose" in source or
            any(os.path.lexists(root / leaf) for leaf in ("amendment.json", "controller.py")))


def build(args):
    require(args.human_ready)
    root, run, repo, _ = context(args.root)
    require(not recovery_trace(root, run))
    variant = args.variant
    if variant == "rebuilt":
        observed(root, "read-b")
    settings = read(args.settings)
    require(set(settings) == {"team", "identity", "profile"})
    require(all(isinstance(value, str) and value.strip() and "\n" not in value for value in settings.values()))
    require(len(settings["identity"]) == 40 and
            all(character in "0123456789abcdef" for character in settings["identity"].lower()))
    signing_style = getattr(args, "signing_style", "manual")
    require(signing_style in ("manual", "automatic"))
    no_active_host(root / "current/PATStorageProbe.app")
    attempt = root / ("build-" + variant + ".attempt.json")
    publish(attempt, {"variant": variant})
    configuration = "Debug" if variant == "debug" else "Rebuilt"
    derived = root / ("derived-" + variant)
    argv = ["xcodebuild", "-project", str(repo / HOST / "PATStorageProbe.xcodeproj"),
            "-scheme", "PATStorageProbe" if variant == "debug" else "PATStorageProbeRebuilt",
            "-configuration", configuration, "-derivedDataPath", str(derived),
            "DEVELOPMENT_TEAM=" + settings["team"]]
    if signing_style == "automatic":
        argv += ["CODE_SIGN_STYLE=Automatic", "CODE_SIGN_IDENTITY=Apple Development",
                 "PROVISIONING_PROFILE_SPECIFIER="]
    else:
        argv += ["CODE_SIGN_STYLE=Manual", "CODE_SIGN_IDENTITY=" + settings["identity"],
                 "PROVISIONING_PROFILE_SPECIFIER=" + settings["profile"]]
    argv += ["RIVET_VALIDATION_GROUP=" + run["accessGroup"], "clean", "build"]
    result = command(argv, timeout=600)
    publish(root / ("build-" + variant + ".private.json"), {"argv": argv,
            "stdout": result.stdout.decode(errors="replace"), "stderr": result.stderr.decode(errors="replace")})
    context(root)
    app = derived / "Build/Products" / configuration / "PATStorageProbe.app"
    identity = inspect(app, run["accessGroup"], root)
    require(identity["team"] == settings["team"] and identity["profileName"] == settings["profile"]
            and identity["certificateSHA1"].lower() == settings["identity"].lower())
    current = root / "current"
    current.mkdir(mode=0o700, exist_ok=True)
    destination = current / "PATStorageProbe.app"
    if variant == "rebuilt":
        require(identity == read(root / "identity.json"))
        old_binary = digest(destination / "Contents/MacOS/PATStorageProbe")
        require(old_binary != digest(app / "Contents/MacOS/PATStorageProbe"))
        shutil.rmtree(destination)  # Exact owned build output; never a Keychain or signing asset.
    else:
        require(not destination.exists())
        publish(root / "identity.json", identity)
    shutil.copytree(app, destination)
    require(inspect(destination, run["accessGroup"], root) == identity)
    publish(root / ("build-" + variant + ".json"), {"variant": variant,
            "binarySHA256": digest(destination / "Contents/MacOS/PATStorageProbe")})
    print("build-completed; build/sign prompt observation remains separate")


def receipt_snapshot(path):
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as handle:
        info = os.fstat(handle.fileno())
        require(info.st_uid == os.getuid() and stat.S_ISREG(info.st_mode)
                and stat.S_IMODE(info.st_mode) == 0o600 and info.st_size <= 1_048_576)
        raw = handle.read(1_048_577)
    require(len(raw) <= 1_048_576)
    return json.loads(raw), hashlib.sha256(raw).hexdigest()


def validate_receipt(root, run, phase, proof, variant, receipt, history_roots):
    require(receipt["runID"] == run["runID"] and receipt["phase"] == phase)
    require(receipt["binarySHA256"] == proof["binarySHA256"] and receipt["buildVariant"] == variant)
    require(receipt["outcome"] == "completed")
    require(type(receipt["processID"]) is int and receipt["processID"] > 0)
    require(type(receipt["processStartSeconds"]) is int and receipt["processStartSeconds"] > 0)
    require(type(receipt["processStartMicroseconds"]) is int
            and 0 <= receipt["processStartMicroseconds"] < 1_000_000)
    require(isinstance(receipt["processInstance"], str) and receipt["processInstance"])
    if "recoveryID" in run:
        attempt = read(root / (phase + ".attempt.json"))
        amendment = read(root / "amendment.json")
        require(phase == RECOVERY_PHASE and receipt.get("recoveryID") == run["recoveryID"]
                == attempt.get("recoveryID") == amendment.get("recoveryID"))
        require(attempt.get("amendmentSHA256") == digest(root / "amendment.json"))
    for previous_root in history_roots:
        for other in PHASES + [RECOVERY_PHASE]:
            previous = previous_root / (other + ".host.json")
            if previous == root / (phase + ".host.json") or not previous.exists():
                continue
            prior = read(previous)
            require(prior["processInstance"] != receipt["processInstance"])
            require((prior["processID"], prior["processStartSeconds"], prior["processStartMicroseconds"])
                    != (receipt["processID"], receipt["processStartSeconds"], receipt["processStartMicroseconds"]))


def wait_for_receipt_exit(root, run, phase, proof, variant, history_roots, timeout=120):
    deadline = time.monotonic() + timeout
    first_sha = None
    path = root / (phase + ".host.json")
    while time.monotonic() < deadline:
        try:
            receipt, snapshot_sha = receipt_snapshot(path)
        except (FileNotFoundError, json.JSONDecodeError):
            time.sleep(0.05)
            continue
        validate_receipt(root, run, phase, proof, variant, receipt, history_roots)
        require(first_sha is None or first_sha == snapshot_sha)
        first_sha = snapshot_sha
        try:
            os.kill(receipt["processID"], 0)  # Existence check only; never sends a signal.
        except ProcessLookupError:
            break
        except OSError as error:
            if error.errno == errno.ESRCH:
                break
            raise
        time.sleep(0.05)
    else:
        raise GuardError()
    final, final_sha = receipt_snapshot(path)
    require(final_sha == first_sha)
    validate_receipt(root, run, phase, proof, variant, final, history_roots)
    return final, final_sha


def launch_verified(root, run, phase, variant, proof, history_roots):
    app = root / "current/PATStorageProbe.app"
    require(inspect(app, run["accessGroup"], root) == read(root / "identity.json"))
    require(digest(app / "Contents/MacOS/PATStorageProbe") == proof["binarySHA256"])
    no_active_host(app)
    require(not (root / (phase + ".host.json")).exists())
    attempt = {"phase": phase, "runID": run["runID"], "attemptID": str(uuid.uuid4())}
    if "recoveryID" in run:
        verify_recovery_links(root)
        attempt.update(recoveryID=run["recoveryID"], amendmentSHA256=digest(root / "amendment.json"),
                       controllerSHA256=digest(root / "controller.py"))
    publish(root / (phase + ".attempt.json"), attempt)
    result = command(["open", "-a", str(app), "--args", "--root", str(root), "--phase", phase], timeout=120)
    require(result.returncode == 0)
    receipt, stable_sha = wait_for_receipt_exit(root, run, phase, proof, variant, history_roots)
    context(root)
    require(inspect(app, run["accessGroup"], root) == read(root / "identity.json"))
    require(digest(app / "Contents/MacOS/PATStorageProbe") == proof["binarySHA256"])
    final, final_sha = receipt_snapshot(root / (phase + ".host.json"))
    require(final_sha == stable_sha and final == receipt)
    validate_receipt(root, run, phase, proof, variant, final, history_roots)
    binding = acceptance_binding(root, phase, final)
    require(binding["hostSHA256"] == stable_sha)
    publish(root / (phase + ".accepted.json"), binding)
    print("runner-accepted; Human observation pending")


def launch(args):
    require(args.human_ready)
    root, run, _, _ = context(args.root)
    require(not recovery_trace(root, run))
    phase = args.phase
    require(phase in PHASES)
    if phase != "cleanup":
        index = PHASES.index(phase)
        if index:
            observed(root, PHASES[index - 1])
    variant = "rebuilt" if phase == "rebuilt-read-b" else "debug"
    if phase == "cleanup":
        variant = "rebuilt" if (root / "build-rebuilt.json").exists() else "debug"
    proof = read(root / ("build-" + variant + ".json"))
    launch_verified(root, run, phase, variant, proof, [root])


def original_recovery_context(original):
    original = Path(original).absolute()
    require(original == original.resolve())
    secure(original, directory=True)
    run = read(original / "run.json")
    require(set(run) == {"runID", "service", "accessGroup"})
    require(str(uuid.UUID(run["runID"])) == run["runID"])
    require(run["service"] == "local.rivet.github.pat.validation." + run["runID"])
    require(isinstance(run["accessGroup"], str) and run["accessGroup"].strip() and "*" not in run["accessGroup"])
    for marker in ("absence", "write-attempt"):
        require(read(original / (marker + ".json")) == run)
    private = read(original / "source.json")
    commit = private["commit"]
    require(isinstance(commit, str) and len(commit) == 40 and all(c in "0123456789abcdef" for c in commit))
    require(set(private["sources"]) == set(SOURCES))
    repo = Path(private["repo"])
    require(repo.is_absolute() and repo == repo.resolve())
    for name in SOURCES:
        raw = command(["git", "-C", str(repo), "show", commit + ":" + name]).stdout
        require(hashlib.sha256(raw).hexdigest() == private["sources"][name])
    return original, run, private


def verify_recovery_links(root):
    run = read(root / "run.json")
    recovery_id = run["recoveryID"]
    require(str(uuid.UUID(recovery_id)) == recovery_id and root.name == "recovery-" + recovery_id)
    amendment = read(root / "amendment.json")
    require(amendment["recoveryID"] == recovery_id and amendment["originalRunID"] == run["runID"])
    require(amendment["purpose"] == "verify-owned-absence")
    source = read(root / "source.json")
    require(source.get("recoveryPurpose") == "verify-owned-absence" and source.get("recoveryID") == recovery_id)
    require(set(run) == {"runID", "service", "accessGroup", "recoveryID"})
    require({key: value for key, value in run.items() if key != "recoveryID"}
            == read(Path(amendment["originalRoot"]) / "run.json"))
    require(digest(root / "controller.py") == amendment["controllerSHA256"])
    require(digest(root / "source.json") == amendment["recoverySourceProofSHA256"])
    for key in ("originalFiles", "hostFiles"):
        parent = Path(amendment["originalRoot" if key == "originalFiles" else "hostRoot"])
        require(parent.is_absolute() and parent == parent.resolve())
        secure(parent, directory=True)
        for name, expected in amendment[key].items():
            require(name in {"run.json", "source.json", "identity.json", "absence.json", "write-attempt.json",
                             "build-debug.json", "build-rebuilt.json"} or
                    any(name == phase + suffix for phase in PHASES
                        for suffix in (".attempt.json", ".host.json", ".accepted.json", ".observation.json")))
            secure(parent / name)
            require(digest(parent / name) == expected)
    require(digest(Path(amendment["originalRoot"]) / "source.json") == amendment["originalSourceProofSHA256"])
    require(read(root / "absence.json") == read(Path(amendment["originalRoot"]) / "absence.json"))
    require(read(root / "write-attempt.json") == read(Path(amendment["originalRoot"]) / "write-attempt.json"))


def recover_absence(args):
    require(args.human_ready)
    original, old_run, old_source = original_recovery_context(args.original_root)
    host_root, host_run, _, new_source = context(args.host_root)
    require(not recovery_trace(host_root, host_run) and host_root != original)
    require(host_run["accessGroup"] == old_run["accessGroup"])
    controller = Path(__file__)
    require(digest(controller) == new_source["sources"][HOST + "/scripts/pat_storage_probe.py"])
    old_identity = read(original / "identity.json")
    identity = read(host_root / "identity.json")
    require(identity == old_identity and identity["group"] == old_run["accessGroup"])
    variant = "rebuilt" if (host_root / "build-rebuilt.json").exists() else "debug"
    old_variant = "rebuilt" if (original / "build-rebuilt.json").exists() else "debug"
    proof = read(host_root / ("build-" + variant + ".json"))
    old_proof = read(original / ("build-" + old_variant + ".json"))
    app = host_root / "current/PATStorageProbe.app"
    old_app = original / "current/PATStorageProbe.app"
    require(inspect(old_app, old_run["accessGroup"], host_root) == old_identity)
    require(inspect(app, old_run["accessGroup"], host_root) == identity)
    require(digest(old_app / "Contents/MacOS/PATStorageProbe") == old_proof["binarySHA256"])
    require(digest(app / "Contents/MacOS/PATStorageProbe") == proof["binarySHA256"])
    no_active_host(old_app)
    no_active_host(app)
    original_names = {"run.json", "source.json", "identity.json", "absence.json", "write-attempt.json",
                      "build-" + old_variant + ".json"}
    for phase in PHASES:
        for suffix in (".attempt.json", ".host.json", ".accepted.json", ".observation.json"):
            if (original / (phase + suffix)).exists():
                original_names.add(phase + suffix)
    original_files = {name: digest(secure(original / name)) for name in original_names}
    host_names = {"run.json", "source.json", "identity.json", "build-" + variant + ".json"}
    host_files = {name: digest(secure(host_root / name)) for name in host_names}
    recovery_id = str(uuid.uuid4())
    recovery = original / ("recovery-" + recovery_id)
    recovery.mkdir(mode=0o700)
    publish(recovery / "run.json", dict(old_run, recoveryID=recovery_id))
    publish(recovery / "source.json", dict(new_source, recoveryID=recovery_id,
                                          recoveryPurpose="verify-owned-absence"))
    for marker in ("absence", "write-attempt"):
        publish(recovery / (marker + ".json"), read(original / (marker + ".json")))
    publish(recovery / "identity.json", identity)
    publish(recovery / ("build-" + variant + ".json"), proof)
    descriptor = os.open(recovery / "controller.py", os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, "wb") as handle:
        handle.write(controller.read_bytes())
        handle.flush()
        os.fsync(handle.fileno())
    (recovery / "current").mkdir(mode=0o700)
    shutil.copytree(app, recovery / "current/PATStorageProbe.app")
    amendment = {"recoveryID": recovery_id, "originalRunID": old_run["runID"], "purpose": "verify-owned-absence",
                 "originalRoot": str(original), "hostRoot": str(host_root),
                 "originalSourceCommit": old_source["commit"], "newSourceCommit": new_source["commit"],
                 "originalSourceProofSHA256": original_files["source.json"],
                 "recoverySourceProofSHA256": digest(recovery / "source.json"),
                 "controllerSHA256": digest(recovery / "controller.py"),
                 "originalFiles": original_files, "hostFiles": host_files}
    publish(recovery / "amendment.json", amendment)
    verify_recovery_links(recovery)
    launch_verified(recovery, read(recovery / "run.json"), RECOVERY_PHASE, variant, proof,
                    [recovery, original, host_root])
    print(recovery)


def observe(args):
    root, _, _, _ = context(args.root)
    path = root / (args.phase + ".host.json")
    read(path)
    require(args.prompts is None or args.prompts >= 0)
    publish(root / (args.phase + ".observation.json"), {
        "machineSHA256": digest(path), "promptCount": args.prompts,
        "wholeStageObserved": args.whole_stage_observed})
    print("observation-recorded")


def export(args):
    root, run, _, private = context(args.root)
    result = {"runID": run["runID"], "sourceCommit": private["commit"],
              "sources": private["sources"], "phases": {}}
    if "recoveryID" in run:
        verify_recovery_links(root)
        result.update(recoveryID=run["recoveryID"], originalRunID=run["runID"],
                      amendmentSHA256=digest(root / "amendment.json"))
    for phase in ([RECOVERY_PHASE] if "recoveryID" in run else PHASES):
        path = root / (phase + ".host.json")
        if not path.exists():
            result["phases"][phase] = {"outcome": "unknown" if (root / (phase + ".attempt.json")).exists() else "notExecuted", "promptCount": None}
            continue
        machine = read(path)
        observation = root / (phase + ".observation.json")
        human = read(observation) if observation.exists() else {}
        bound = human.get("machineSHA256") == digest(path)
        require(machine["outcome"] in ("completed", "failed"))
        require(machine["buildVariant"] in ("debug", "rebuilt"))
        require(len(machine["binarySHA256"]) == 64 and all(c in "0123456789abcdef" for c in machine["binarySHA256"]))
        runner_accepted = accepted(root, phase, machine)
        result["phases"][phase] = {"outcome": "completed" if runner_accepted else "unknown",
            "hostOutcome": machine["outcome"], "runnerAccepted": runner_accepted,
            "binarySHA256": machine["binarySHA256"], "buildVariant": machine["buildVariant"],
            "promptCount": human.get("promptCount") if bound else None,
            "wholeStageObserved": human.get("wholeStageObserved", False) if bound else False,
            "observationBound": bound}
    publish(args.destination, result)
    print("finite-evidence-exported")


def parser():
    cli = argparse.ArgumentParser(description=__doc__)
    commands = cli.add_subparsers(dest="command", required=True)
    item = commands.add_parser("prepare")
    for name in ("repo", "parent", "access-group"):
        item.add_argument("--" + name, required=True)
    item.set_defaults(action=prepare)
    item = commands.add_parser("build")
    item.add_argument("--variant", choices=["debug", "rebuilt"], required=True)
    item.add_argument("--settings", required=True)
    item.add_argument("--signing-style", choices=["manual", "automatic"], default="manual")
    item.add_argument("--human-ready", action="store_true")
    item.set_defaults(action=build)
    item = commands.add_parser("run")
    item.add_argument("--phase", choices=PHASES, required=True)
    item.add_argument("--human-ready", action="store_true")
    item.set_defaults(action=launch)
    item = commands.add_parser("recover-absence")
    item.add_argument("--original-root", required=True)
    item.add_argument("--host-root", required=True)
    item.add_argument("--human-ready", action="store_true")
    item.set_defaults(action=recover_absence)
    item = commands.add_parser("observe")
    item.add_argument("--phase", choices=PHASES + [RECOVERY_PHASE], required=True)
    item.add_argument("--prompts", type=int)
    item.add_argument("--whole-stage-observed", action="store_true")
    item.set_defaults(action=observe)
    item = commands.add_parser("export")
    item.add_argument("--destination", required=True)
    item.set_defaults(action=export)
    for name, item in commands.choices.items():
        if name not in ("prepare", "recover-absence"):
            item.add_argument("--root", required=True)
    return cli


def main():
    args = parser().parse_args()
    try:
        args.action(args)
    except (GuardError, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        # Never print native errors, signing identifiers, paths, PAT or arbitrary child output.
        print("probe: guard-or-operation-failed; retain run for review/owned cleanup", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
