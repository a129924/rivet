#!/usr/bin/env python3
"""E018 only. No token/secret/response body ever leaves the signed host."""
import argparse
import base64
import datetime as dt
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import secrets
import shutil
import stat
import subprocess
import sys
import tempfile
import time

REPO = Path(__file__).resolve().parents[3]
EXPERIMENT = REPO / "experiments/E018"
SERVICE = "local.rivet.github-connection-verification.oauth.v1"
HOST = "E018OAuthStartupProbe"
PHASES = ("first", "fresh")


class Failure(Exception):
    def __init__(self, code):
        self.code = code


def require(condition, code="guard"):
    if not condition:
        raise Failure(code)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def secure(path):
    path = Path(path)
    info = path.lstat()
    require(not stat.S_ISLNK(info.st_mode) and info.st_uid == os.getuid(), "ownership")
    require(not info.st_mode & 0o077, "permissions")
    return path


def read_json(path):
    path = secure(path)
    require(path.is_file() and path.stat().st_size <= 1024 * 1024, "control")
    return json.loads(path.read_text())


def exclusive(path, value):
    data = (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
    except BaseException:
        # A partial file still consumes its slot; never unlink it to retry.
        raise


def command(argv, *, log=None):
    result = subprocess.run(argv, cwd=REPO, capture_output=True)
    if log:
        descriptor = os.open(log, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "wb") as output:
            output.write(result.stdout + result.stderr)
    require(result.returncode == 0, "command")
    return result


def profile(path):
    result = command(["security", "cms", "-D", "-i", str(path)])
    value = plistlib.loads(result.stdout)
    expiry = value["ExpirationDate"].replace(tzinfo=dt.timezone.utc)
    require(expiry > dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=120), "profileExpired")
    return value


def entitlements(app):
    return plistlib.loads(command(["codesign", "-d", "--entitlements", ":-", str(app)]).stdout)


def leaf(app, root):
    directory = Path(tempfile.mkdtemp(prefix="cert-check-", dir=root))
    command(["codesign", "-d", "--extract-certificates=" + str(directory / "leaf-"), str(app)])
    return (directory / "leaf-0").read_bytes()


def source_manifest():
    paths = [REPO / "Package.swift", REPO / "Package.resolved",
             REPO / "packages/RivetHTTPClient/Package.swift"]
    for directory in [REPO / "Sources/BoundedContexts/GitHubIntegration",
                      REPO / "packages/RivetHTTPClient/Sources", EXPERIMENT]:
        for path in directory.rglob("*"):
            if path.is_file() and path.suffix in {
                ".swift", ".py", ".pbxproj", ".plist", ".entitlements", ".xcscheme", ".resolved"
            } and not any(part in {".build", "__pycache__", "xcuserdata"} for part in path.parts):
                paths.append(path)
    entries = {p.relative_to(REPO).as_posix(): digest(p) for p in sorted(set(paths))}
    canonical = json.dumps(entries, sort_keys=True, separators=(",", ":")).encode()
    return {"files": entries, "sha256": hashlib.sha256(canonical).hexdigest()}


def related_absent():
    text = command(["ps", "-axo", "comm="]).stdout.decode()
    require(not any(line.strip().endswith("/" + name) for line in text.splitlines()
                    for name in [HOST, "GitHubConnectionVerification"]), "writerPresent")


def select_assets(root):
    old = Path.home() / "Applications/GitHubConnectionVerification.app"
    require(old.is_dir(), "oldHostUnavailable")
    old_entitlements = entitlements(old)
    groups = old_entitlements.get("keychain-access-groups", [])
    require(len(groups) == 1 and "*" not in groups[0], "group")
    old_leaf = leaf(old, root)
    identities = set(re.findall(rb"\b[0-9A-F]{40}\b", command(
        ["security", "find-identity", "-v", "-p", "codesigning"]).stdout))
    choices = []
    location = Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"
    for candidate in location.iterdir():
        if not candidate.is_file():
            continue
        try:
            value = profile(candidate)
        except Exception:
            continue
        ent = value.get("Entitlements", {})
        app_id = ent.get("com.apple.application-identifier", ent.get("application-identifier", ""))
        permits = ent.get("keychain-access-groups", [])
        fingerprint = hashlib.sha1(old_leaf).hexdigest().upper().encode()
        if "*" in app_id or not app_id or old_leaf not in value.get("DeveloperCertificates", []):
            continue
        if fingerprint not in identities or not any(fnmatch.fnmatchcase(groups[0], p) for p in permits):
            continue
        hardware = json.loads(command(["system_profiler", "SPHardwareDataType", "-json"]).stdout)
        info = hardware["SPHardwareDataType"][0]
        device = info.get("provisioning_UDID", info.get("provisioning_udid"))
        require(device and device.upper() in {p.upper() for p in value.get("ProvisionedDevices", [])}, "device")
        team = value["TeamIdentifier"][0]
        require(app_id.startswith(team + "."), "appID")
        choices.append({"profile": str(candidate), "profileSHA256": digest(candidate),
                        "applicationID": app_id, "bundleID": app_id[len(team) + 1:],
                        "group": groups[0], "team": team,
                        "identity": fingerprint.decode(), "leafSHA256": hashlib.sha256(old_leaf).hexdigest(),
                        "getTaskAllow": bool(ent.get("get-task-allow", False))})
    require(len(choices) == 1, "assetsAmbiguousOrUnavailable")
    return choices[0]


def prepare(root):
    os.umask(0o077)
    root.mkdir(mode=0o700, parents=False, exist_ok=False)
    assets = select_assets(root)
    exclusive(root / "assets.json", assets)
    frozen = source_manifest()
    exclusive(root / "source.json", frozen)
    control = {"runID": secrets.token_hex(16), "group": assets["group"], "service": SERVICE,
               "keyBase64": base64.b64encode(secrets.token_bytes(32)).decode(), "bundleID": assets["bundleID"]}
    exclusive(root / "control.json", control)
    command(["xcodebuild", "-project", str(EXPERIMENT / (HOST + ".xcodeproj")),
             "-scheme", HOST, "-configuration", "Debug", "-destination", "platform=macOS,arch=arm64",
             "-derivedDataPath", str(root / "DerivedData"), "CODE_SIGNING_ALLOWED=NO",
             "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY=", "DEVELOPMENT_TEAM=" + assets["team"],
             "PRODUCT_BUNDLE_IDENTIFIER=" + assets["bundleID"], "RIVET_VALIDATION_GROUP=" + assets["group"],
             "build"], log=root / "unsigned-build.log")
    require(source_manifest() == frozen, "sourceChanged")
    app = root / "DerivedData/Build/Products/Debug" / (HOST + ".app")
    binary = app / "Contents/MacOS" / HOST
    result = command([str(binary), "--self-test"], log=root / "self-test.log")
    require(json.loads(result.stdout) == {"selfTestPassed": True, "liveOperations": 0}, "selfTest")
    exclusive(root / "build.json", {"app": str(app), "unsignedBinarySHA256": digest(binary),
                                    "sourceSHA256": frozen["sha256"]})
    return {"status": "unsignedReady", "sourceSHA256": frozen["sha256"], "liveOperations": 0}


def signed_info(app, assets, root):
    command(["codesign", "--verify", "--deep", "--strict", str(app)])
    embedded = app / "Contents/embedded.provisionprofile"
    require(digest(embedded) == assets["profileSHA256"], "profileChanged")
    profile(embedded)
    ent = entitlements(app)
    require(ent.get("keychain-access-groups") == [assets["group"]], "group")
    app_id = ent.get("com.apple.application-identifier", ent.get("application-identifier"))
    require(app_id == assets["applicationID"], "appID")
    require(hashlib.sha256(leaf(app, root)).hexdigest() == assets["leafSHA256"], "certificate")
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    require(info["CFBundleIdentifier"] == assets["bundleID"], "bundle")
    return {"binarySHA256": digest(app / "Contents/MacOS" / HOST),
            "profileSHA256": digest(embedded)}


def sign(root):
    assets = read_json(root / "assets.json")
    build = read_json(root / "build.json")
    require(source_manifest() == read_json(root / "source.json"), "sourceChanged")
    app = Path(build["app"])
    require(digest(app / "Contents/MacOS" / HOST) == build["unsignedBinarySHA256"], "binaryChanged")
    profile(assets["profile"])
    require(digest(assets["profile"]) == assets["profileSHA256"], "profileChanged")
    exclusive(root / "sign.attempt.json", {"started": True})
    shutil.copyfile(assets["profile"], app / "Contents/embedded.provisionprofile")
    ent = {"com.apple.application-identifier": assets["applicationID"],
           "com.apple.developer.team-identifier": assets["team"],
           "keychain-access-groups": [assets["group"]]}
    if assets["getTaskAllow"]:
        ent["get-task-allow"] = True
    (root / "signing.entitlements").write_bytes(plistlib.dumps(ent))
    command(["codesign", "--force", "--sign", assets["identity"], "--timestamp=none",
             "--entitlements", str(root / "signing.entitlements"), str(app)], log=root / "sign.log")
    proof = signed_info(app, assets, root)
    proof["sourceSHA256"] = build["sourceSHA256"]
    exclusive(root / "signed.json", proof)
    return {"status": "signedReady", **proof, "liveOperations": 0}


def preflight(root):
    frozen = read_json(root / "source.json")
    require(source_manifest() == frozen, "sourceChanged")
    proof = read_json(root / "signed.json")
    build = read_json(root / "build.json")
    assets = read_json(root / "assets.json")
    require(signed_info(Path(build["app"]), assets, root) == {
        "binarySHA256": proof["binarySHA256"], "profileSHA256": proof["profileSHA256"]}, "binaryChanged")
    require(proof["sourceSHA256"] == frozen["sha256"], "sourceChanged")
    related_absent()
    return proof, Path(build["app"])


def project(machine, proof, phase, *, same_credential=None, same_account=None):
    require(machine.get("schema") == "e018.machine.v1" and machine.get("phase") == phase, "receipt")
    keys = {"schema", "phase", "outcome", "failureKind", "phasePassed", "prepare", "final",
            "initiallyExpired", "initialCredentialTag", "finalCredentialTag", "accountTag",
            "apiAuthenticated", "completeReadback", "configurationUnchanged", "naturalRefreshObserved"}
    require(set(machine) in (keys, keys | {"promptCount"}) and machine.get("promptCount") is None, "receipt")
    for key in ["initialCredentialTag", "finalCredentialTag", "accountTag"]:
        require(isinstance(machine[key], str) and (machine[key] == "" or re.fullmatch(r"[0-9a-f]{64}", machine[key])), "receipt")
    require(set(proof) == {"binarySHA256", "profileSHA256", "sourceSHA256"} and all(isinstance(v, str) and re.fullmatch(r"[0-9a-f]{64}", v) for v in proof.values()), "receipt")
    allowed = {"configurationLoads", "credentialLoads", "refreshAttempts", "refreshAccepted", "saveAttempts", "saves"}
    for key in ["prepare", "final"]:
        require(set(machine[key]) == allowed and all(type(v) is int and 0 <= v <= 16 for v in machine[key].values()), "receipt")
    for key in ["phasePassed", "initiallyExpired", "apiAuthenticated", "completeReadback", "configurationUnchanged", "naturalRefreshObserved"]:
        require(type(machine[key]) is bool, "receipt")
    require(machine["outcome"] in {"ready", "incomplete"}, "receipt")
    require(not machine["naturalRefreshObserved"] or (machine["initiallyExpired"]
            and machine["prepare"]["refreshAccepted"] > 0 and machine["prepare"]["saves"] > 0), "receipt")
    failures = {"none", "control", "notConfigured", "notSignedIn", "authenticationRequired", "cancelled", "busy",
                "configurationStore", "configurationLoad", "fetcherCreation", "preparationFailed", "invalidAuthorizationToken",
                "restore", "refresh", "persist", "api", "verification", "readbackOrStore"}
    require(machine["failureKind"] in failures, "receipt")
    local_checks = machine["outcome"] == "ready" and all(machine[k] for k in
        ["apiAuthenticated", "completeReadback", "configurationUnchanged"])
    passed = machine["phasePassed"] and local_checks and (phase == "first" or (same_credential is True and same_account is True))
    return {"schema": "e018.public.v1", "phase": phase, "passed": passed,
            "outcome": machine["outcome"], "failureKind": machine["failureKind"],
            "prepare": machine["prepare"], "final": machine["final"],
            "initiallyExpired": machine["initiallyExpired"], "apiAuthenticated": machine["apiAuthenticated"],
            "completeReadback": machine["completeReadback"], "configurationUnchanged": machine["configurationUnchanged"],
            "naturalRefreshObserved": machine["naturalRefreshObserved"], "sameCredential": same_credential,
            "sameAccount": same_account, "promptObservation": "pending", **proof}


def first_ready(root):
    public = read_json(root / "first.public.json")
    human = read_json(root / "first.human.json")
    ended = read_json(root / "first.exit.json")
    require(public["passed"] and ended["terminated"] and ended["exitCode"] == 0, "firstIncomplete")
    require(human["machineSHA256"] == digest(root / "first.machine.json") and human["fullyObserved"] is True, "humanObservation")
    return read_json(root / "first.machine.json")


def launch(root, phase):
    proof, app = preflight(root)
    previous = first_ready(root) if phase == "fresh" else None
    exclusive(root / (phase + ".attempt.json"), {"phase": phase, **proof})
    control = read_json(root / "control.json")
    binary = app / "Contents/MacOS" / HOST
    stdout_path = root / (phase + ".stdout")
    descriptor = os.open(stdout_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "wb") as output:
        proc = subprocess.Popen([str(binary), "--run-root", str(root), "--phase", phase],
                                stdout=output, stderr=output, start_new_session=True)
        authorized = False
        try:
            start = time.monotonic()
            hello_path = root / (phase + ".hello.json")
            while not hello_path.exists():
                require(proc.poll() is None and time.monotonic() - start < 25, "hello")
                time.sleep(0.1)
            hello = read_json(hello_path)
            require(set(hello) == {"runID", "phase", "pid", "executable"}, "hello")
            require(hello["runID"] == control["runID"] and hello["phase"] == phase and hello["pid"] == str(proc.pid), "process")
            actual = command(["ps", "-p", str(proc.pid), "-o", "comm="]).stdout.decode().strip()
            started = command(["ps", "-p", str(proc.pid), "-o", "lstart="]).stdout.decode().strip()
            require(started and os.path.samefile(actual, binary) and os.path.samefile(hello["executable"], binary), "process")
            require(source_manifest() == read_json(root / "source.json") and digest(binary) == proof["binarySHA256"], "sourceChanged")
            exclusive(root / (phase + ".process.json"), {"pid": proc.pid, "start": started, "executable": actual, **proof})
            exclusive(root / (phase + ".authorize.json"), {"runID": control["runID"], "phase": phase})
            authorized = True
            proc.wait(timeout=max(1, 120 - (time.monotonic() - start)))
        finally:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait(timeout=5)
            exclusive(root / (phase + ".exit.json"), {"terminated": proc.poll() is not None,
                                                       "exitCode": proc.returncode, "authorized": authorized})
    machine = read_json(root / (phase + ".machine.json"))
    same_credential = same_account = None
    if previous:
        same_credential = bool(machine["initialCredentialTag"] and machine["initialCredentialTag"] == previous["finalCredentialTag"])
        same_account = bool(machine["accountTag"] and machine["accountTag"] == previous["accountTag"])
    public = project(machine, proof, phase, same_credential=same_credential, same_account=same_account)
    public["machineSHA256"] = digest(root / (phase + ".machine.json"))
    public["processTerminated"] = proc.poll() is not None and proc.returncode == 0
    public["passed"] = public["passed"] and public["processTerminated"] and authorized
    exclusive(root / (phase + ".public.json"), public)
    return public


def attest(root, phase, prompts):
    machine = root / (phase + ".machine.json")
    require(type(prompts) is int and 0 <= prompts <= 20, "prompts")
    value = {"fullyObserved": True, "promptCount": prompts, "machineSHA256": digest(machine)}
    exclusive(root / (phase + ".human.json"), value)
    return {"status": "humanRecorded", "phase": phase, **value}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=["prepare", "sign", "preflight", "first", "fresh", "attest"])
    parser.add_argument("--run-root", required=True)
    parser.add_argument("--phase", choices=PHASES)
    parser.add_argument("--prompts", type=int)
    args = parser.parse_args()
    root = Path(args.run_root).resolve()
    try:
        os.umask(0o077)
        if args.operation == "prepare":
            result = prepare(root)
        else:
            secure(root)
            if args.operation == "sign":
                result = sign(root)
            elif args.operation == "preflight":
                proof, _ = preflight(root)
                result = {"status": "preflightReady", **proof, "liveOperations": 0}
            elif args.operation in PHASES:
                result = launch(root, args.operation)
            else:
                require(args.phase and args.prompts is not None, "arguments")
                result = attest(root, args.phase, args.prompts)
        print(json.dumps(result, sort_keys=True))
        return 0
    except Exception as error:
        print(json.dumps({"status": "stopped", "failureKind": error.code if isinstance(error, Failure) else "internal",
                          "noAutomaticRetry": True}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
