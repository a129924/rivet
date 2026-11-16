#!/usr/bin/env python3
"""E016 local verification controls. No live action without --human-ready."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat
import subprocess
import sys
import uuid

TOPIC = "github-pat-dpk-storage"
HOST = f"experiments/E016/{TOPIC}"
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


def inspect(app, group, root):
    command(["codesign", "--verify", "--deep", "--strict", str(app)])
    details = command(["codesign", "-d", "--verbose=4", str(app)]).stderr.decode()
    require("Signature=adhoc" not in details)
    fields = dict(line.split("=", 1) for line in details.splitlines() if "=" in line)
    require(fields.get("Identifier") == "local.rivet.pat-storage-probe")
    require(fields.get("TeamIdentifier") not in (None, "not set"))
    claims = plistlib.loads(command(["codesign", "-d", "--entitlements", ":-", str(app)]).stdout)
    require(claims.get("keychain-access-groups") == [group])
    embedded = app / "Contents/embedded.provisionprofile"
    profile = plistlib.loads(command(["security", "cms", "-D", "-i", str(embedded)]).stdout)
    expiry = profile["ExpirationDate"].replace(tzinfo=dt.timezone.utc)
    require(expiry > dt.datetime.now(dt.timezone.utc))
    require(fields["TeamIdentifier"] in profile["TeamIdentifier"])
    entitlements = profile["Entitlements"]
    require(group in entitlements.get("keychain-access-groups", []))
    require(entitlements.get("com.apple.application-identifier") == claims.get("com.apple.application-identifier"))
    prefix = root / ("certificate-" + str(uuid.uuid4()) + "-")
    command(["codesign", "-d", "--extract-certificates", str(prefix), str(app)])
    certificate = Path(str(prefix) + "0")
    cert_bytes = certificate.read_bytes()
    require(cert_bytes in profile["DeveloperCertificates"])
    command(["openssl", "x509", "-inform", "DER", "-in", str(certificate), "-checkend", "0", "-noout"])
    certificate.unlink()
    requirement_output = command(["codesign", "-d", "-r-", str(app)]).stderr.decode()
    requirements = [line for line in requirement_output.splitlines() if line.startswith("designated =>")]
    require(len(requirements) == 1)
    requirement = requirements[0]
    return {"identifier": fields["Identifier"], "team": fields["TeamIdentifier"],
            "group": group, "certificateSHA256": hashlib.sha256(cert_bytes).hexdigest(),
            "profileSHA256": digest(embedded), "requirement": requirement}


def acceptance_binding(root, phase, machine):
    variant = machine["buildVariant"]
    require(variant in ("debug", "rebuilt"))
    return {"runID": read(root / "run.json")["runID"], "phase": phase,
            "attemptSHA256": digest(root / (phase + ".attempt.json")),
            "hostSHA256": digest(root / (phase + ".host.json")),
            "buildProofSHA256": digest(root / ("build-" + variant + ".json")),
            "sourceProofSHA256": digest(root / "source.json")}


def accepted(root, phase, machine):
    path = root / (phase + ".accepted.json")
    if not path.exists():
        return False
    try:
        proof = read(path)
        expected = acceptance_binding(root, phase, machine)
        return (proof == expected and machine["runID"] == expected["runID"]
                and machine["phase"] == phase and machine["outcome"] == "completed")
    except (FileNotFoundError, KeyError, TypeError, ValueError):
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


def build(args):
    require(args.human_ready)
    root, run, repo, _ = context(args.root)
    variant = args.variant
    if variant == "rebuilt":
        observed(root, "read-b")
    settings = read(args.settings)
    require(set(settings) == {"team", "identity", "profile"})
    require(all(isinstance(value, str) and value.strip() and "\n" not in value for value in settings.values()))
    no_active_host(root / "current/PATStorageProbe.app")
    attempt = root / ("build-" + variant + ".attempt.json")
    publish(attempt, {"variant": variant})
    configuration = "Debug" if variant == "debug" else "Rebuilt"
    derived = root / ("derived-" + variant)
    argv = ["xcodebuild", "-project", str(repo / HOST / "PATStorageProbe.xcodeproj"),
            "-scheme", "PATStorageProbe" if variant == "debug" else "PATStorageProbeRebuilt",
            "-configuration", configuration, "-derivedDataPath", str(derived),
            "DEVELOPMENT_TEAM=" + settings["team"], "CODE_SIGN_IDENTITY=" + settings["identity"],
            "PROVISIONING_PROFILE_SPECIFIER=" + settings["profile"],
            "RIVET_VALIDATION_GROUP=" + run["accessGroup"], "clean", "build"]
    result = command(argv, timeout=600)
    publish(root / ("build-" + variant + ".private.json"), {"argv": argv,
            "stdout": result.stdout.decode(errors="replace"), "stderr": result.stderr.decode(errors="replace")})
    context(root)
    app = derived / "Build/Products" / configuration / "PATStorageProbe.app"
    identity = inspect(app, run["accessGroup"], root)
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


def launch(args):
    require(args.human_ready)
    root, run, _, _ = context(args.root)
    phase = args.phase
    if phase != "cleanup":
        index = PHASES.index(phase)
        if index:
            observed(root, PHASES[index - 1])
    variant = "rebuilt" if phase == "rebuilt-read-b" else "debug"
    if phase == "cleanup":
        variant = "rebuilt" if (root / "build-rebuilt.json").exists() else "debug"
    proof = read(root / ("build-" + variant + ".json"))
    app = root / "current/PATStorageProbe.app"
    require(inspect(app, run["accessGroup"], root) == read(root / "identity.json"))
    require(digest(app / "Contents/MacOS/PATStorageProbe") == proof["binarySHA256"])
    no_active_host(app)
    require(not (root / (phase + ".host.json")).exists())
    publish(root / (phase + ".attempt.json"), {
        "phase": phase, "runID": run["runID"], "attemptID": str(uuid.uuid4())})
    # -W waits for the one launched app to exit; no -n and no raw live executable.
    command(["open", "-W", "-a", str(app), "--args", "--root", str(root), "--phase", phase], timeout=120)
    receipt = read(root / (phase + ".host.json"))
    require(receipt["runID"] == run["runID"] and receipt["phase"] == phase)
    require(receipt["binarySHA256"] == proof["binarySHA256"] and receipt["buildVariant"] == variant)
    for other in PHASES:
        previous = root / (other + ".host.json")
        if other != phase and previous.exists():
            prior = read(previous)
            require(prior["processInstance"] != receipt["processInstance"])
            require((prior["processID"], prior["processStartSeconds"], prior["processStartMicroseconds"])
                    != (receipt["processID"], receipt["processStartSeconds"], receipt["processStartMicroseconds"]))
    require(receipt["outcome"] == "completed")
    publish(root / (phase + ".accepted.json"), acceptance_binding(root, phase, receipt))
    print("runner-accepted; Human observation pending")


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
    for phase in PHASES:
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
    item.add_argument("--human-ready", action="store_true")
    item.set_defaults(action=build)
    item = commands.add_parser("run")
    item.add_argument("--phase", choices=PHASES, required=True)
    item.add_argument("--human-ready", action="store_true")
    item.set_defaults(action=launch)
    item = commands.add_parser("observe")
    item.add_argument("--phase", choices=PHASES, required=True)
    item.add_argument("--prompts", type=int)
    item.add_argument("--whole-stage-observed", action="store_true")
    item.set_defaults(action=observe)
    item = commands.add_parser("export")
    item.add_argument("--destination", required=True)
    item.set_defaults(action=export)
    for name, item in commands.choices.items():
        if name != "prepare":
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
