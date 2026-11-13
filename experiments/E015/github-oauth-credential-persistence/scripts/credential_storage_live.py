#!/usr/bin/env python3
"""Bounded preparation and staged live controls. No command runs implicitly."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import platform
import re
import shutil
import stat
import subprocess
import sys
import uuid

PHASES = ("setup", "save-a", "read-a", "replace-b", "read-b", "rebuild",
          "rebuilt-read-b", "cleanup")
FIELDS = ("accessToken", "refreshToken", "accessTokenExpiresAt",
          "refreshTokenExpiresAt", "tokenType", "grantedScopes")
IDENTITY_HASHES = ("profileSHA256", "certificateSHA256", "appIDSHA256",
                   "groupSHA256", "drSHA256", "locationSHA256")
HASH_KEYS = IDENTITY_HASHES + ("sourceSHA256", "binarySHA256", "manifestSHA256", "machineSHA256")
BOOL_KEYS = ("validity", "sameIdentity", "sameLocation", "sameSource", "differentBinary",
             "freshProcess", "previousTerminated", "absenceConfirmed", "writeAttempted",
             "owned", "deleted", "readAbsent", "compiledMarker", "buildVerified")
FAILURES = ("guard", "credentialDenied", "credentialUnavailable", "credentialCorrupt",
            "identityMismatch", "invalidConfiguration", "comparison", "cleanup", "build", "other")
SOURCE_FILES = (
    "Package.swift",
    "Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift",
    "Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift",
    "Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift",
)
PROJECT_FILES = (
    "CredentialStorageProbe.xcodeproj/project.pbxproj",
    "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme",
    "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme",
    "Sources/main.swift", "Resources/Info.plist", "Resources/CredentialStorageProbe.entitlements",
)
TEMPLATE = "experiments/E015/github-oauth-credential-persistence"
# This bounded retry belongs only to the already-observed run. Hashes are safe evidence.
RETRY_PINS = {
    "runUUID": "8ad8fb3b-51d9-4162-98fb-067521a37b4e",
    "manifestSHA256": "7223cc870fb02861c31b73aa5b4866c10dda5d3c96620f65d305b62669390b0c",
    "identitySHA256": "b2f84e2c45ff65ccef212f6d15abc4bbfd36ebec8d8e516f3f8cc2ebe652b550",
    "projectSHA256": "15ad13e1575ab7ccad88737efe28587a4022daefebbf00f6bf7bfe0c4177c4dd",
    "originalMachineSHA256": "899ed35b0279c730e6c39bb1c4bc927612f7e6c81897b2d3062ff13a5db46d19",
    "originalHumanSHA256": "6229797bb5271fa44158be28b63ddf77a46794c154f240bfef2d43e238056154",
    "bootstrapDRSHA256": "85c3e82e98159c68fa1ff3888339c7dea3795b0f962a7844f2f0aaabf41a17a2",
    "profileSHA256": "adae3b48b74bd053391083b3312c135e43efdd6670f58acd1172438cb52cb55c",
    "certificateSHA256": "5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440",
}
FORBIDDEN_PERMISSIONS = ("allowprovisioningupdates", "allowprovisioningdeviceregistration",
                         "authenticationkeypath", "authenticationkeyid", "authenticationkeyissuerid")


class SafeParser(argparse.ArgumentParser):
    def error(self, message):
        print('{"status":"rejected","failureKind":"guard"}')
        raise SystemExit(2)


class Rejected(Exception):
    """Deliberately carries no paths, IDs, payload, or underlying error."""


def require(condition):
    if not condition:
        raise Rejected()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def is_hash(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def service(run):
    return "local.rivet.github.oauth.validation." + run


def validate_namespace(run, selected_service):
    try:
        parsed = uuid.UUID(run)
    except (ValueError, TypeError, AttributeError):
        raise Rejected() from None
    require(str(parsed) == run and parsed.version == 4 and selected_service == service(run))


def load(path):
    require(not Path(path).is_symlink())
    with Path(path).open("rb") as stream:
        value = json.load(stream)
    require(isinstance(value, dict))
    return value


def exclusive_json(path, value):
    path = Path(path)
    require(path.parent.is_dir() and not path.parent.is_symlink())
    raw = (json.dumps(value, ensure_ascii=True, sort_keys=True, indent=2,
                      allow_nan=False) + "\n").encode()
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
    except BaseException:
        # Preserve failed/incomplete proof; never silently reuse an existing filename.
        raise
    return digest(raw)


def owned_root(root, run):
    root = Path(root)
    validate_namespace(run, service(run))
    require(not root.is_symlink() and root.name == "rivet-credential-storage-" + run)
    info = root.stat()
    require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid()
            and stat.S_IMODE(info.st_mode) == 0o700)
    require(root.absolute() == root.resolve())


def contained(root, path):
    root, path = Path(root).resolve(), Path(path)
    require(path.is_absolute() and ".." not in path.parts and not path.is_symlink())
    try:
        relative = path.relative_to(root)
    except ValueError:
        raise Rejected() from None
    cursor = root
    for item in relative.parts:
        cursor /= item
        require(not cursor.is_symlink())
    require(path.resolve().is_relative_to(root))
    return path


def verify_sources(sources):
    require(isinstance(sources, dict) and bool(sources))
    for name, expected in sources.items():
        path = Path(name)
        require(path.is_file() and not path.is_symlink() and is_hash(expected))
        require(digest(path.read_bytes()) == expected)


def validate_ready(value, run, phase):
    require(value.get("runUUID") == run and value.get("phase") == phase
            and value.get("ready") is True)
    token = value.get("readyUUID")
    require(isinstance(token, str))
    validate_namespace(token, service(token))


def validate_observation(human, run, phase, machine_sha):
    require(isinstance(human, dict) and human.get("runUUID") == run
            and human.get("phase") == phase and human.get("machineSHA256") == machine_sha
            and is_hash(machine_sha))
    count = human.get("promptCount")
    require(count is None or (type(count) is int and count >= 0))
    require(type(human.get("wholeStageObserved")) is bool)
    actions = human.get("actions")
    require(isinstance(actions, list) and all(action in
            ("none", "allow", "deny", "authenticate", "other") for action in actions))
    if count == 0:
        require(actions in ([], ["none"]))
    elif count is not None:
        require(len(actions) == count and "none" not in actions)


def public_machine(raw):
    out = {"schemaVersion": 1}
    if isinstance(raw.get("runUUID"), str):
        validate_namespace(raw["runUUID"], service(raw["runUUID"]))
        out["runUUID"] = raw["runUUID"]
    if raw.get("phase") in PHASES:
        out["phase"] = raw["phase"]
    if raw.get("status") in ("success", "failure", "unknown", "notExecuted"):
        out["status"] = raw["status"]
    for key in HASH_KEYS:
        if is_hash(raw.get(key)):
            out[key] = raw[key]
    for key in BOOL_KEYS:
        if type(raw.get(key)) is bool:
            out[key] = raw[key]
    if raw.get("failureKind") in FAILURES:
        out["failureKind"] = raw["failureKind"]
    comparison = raw.get("comparison")
    if isinstance(comparison, dict):
        out["comparison"] = {key: comparison[key] for key in FIELDS
                             if type(comparison.get(key)) is bool}
    return out


def public_human(raw):
    validate_observation(raw, raw.get("runUUID"), raw.get("phase"), raw.get("machineSHA256"))
    validate_namespace(raw["runUUID"], service(raw["runUUID"]))
    require(raw["phase"] in PHASES)
    return {key: raw[key] for key in
            ("runUUID", "phase", "machineSHA256", "promptCount", "wholeStageObserved", "actions")}


def classify(machine, human, sha):
    if human is None:
        return "unknown"
    validate_observation(human, machine.get("runUUID"), machine.get("phase"), sha)
    if human["promptCount"] is None or not human["wholeStageObserved"]:
        return "unknown"
    if machine.get("status") == "failure":
        return "failure"
    if machine.get("status") != "success":
        return "unknown"
    if machine.get("phase") == "cleanup" and machine.get("writeAttempted") is False:
        valid = all(machine.get(key) is True for key in ("owned", "previousTerminated", "sameSource"))
        valid &= machine.get("deleted") is not True and machine.get("readAbsent") is not True
        return "success" if valid else "unknown"
    if any(machine.get(key) is not True for key in
           ("sameSource", "sameIdentity", "sameLocation", "validity")):
        return "unknown"
    phase = machine["phase"]
    if phase not in ("setup", "rebuild"):
        if any(machine.get(key) is not True for key in ("freshProcess", "previousTerminated")):
            return "unknown"
    if phase in ("save-a", "read-a", "replace-b", "read-b", "rebuilt-read-b"):
        if set(machine.get("comparison", {})) != set(FIELDS):
            return "unknown"
        if not all(machine["comparison"].values()):
            return "failure"
    if phase == "cleanup" and not all(machine.get(key) is True
                                      for key in ("owned", "deleted", "readAbsent")):
        return "unknown"
    limit = 1 if phase == "save-a" else 0 if phase in (
        "read-a", "read-b", "rebuilt-read-b") else None
    if limit is not None and human["promptCount"] > limit:
        return "failure"
    return "success"


def require_previous(phase, outcomes):
    require(phase in PHASES)
    if phase == "cleanup":  # recovery bypasses stage order, never ownership or fresh ready
        return
    for previous in PHASES[:PHASES.index(phase)]:
        require(outcomes.get(previous) == "success")


def alive(pid):
    require(type(pid) is int and pid > 1)
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def validate_process(current, previous, pid_alive=alive):
    require(type(current.get("pid")) is int and current["pid"] > 1)
    try:
        require(str(uuid.UUID(current.get("processUUID"))) == current["processUUID"])
    except (ValueError, TypeError, AttributeError):
        raise Rejected() from None
    for old in previous:
        require(current["pid"] != old["pid"] and current["processUUID"] != old["processUUID"])
        require(not pid_alive(old["pid"]))


def validate_ownership(manifest, proof, manifest_sha):
    validate_namespace(manifest["runUUID"], manifest["service"])
    require(manifest["account"] == "credential" and isinstance(manifest["group"], str)
            and bool(manifest["group"]) and "*" not in manifest["group"])
    for key in ("runUUID", "service", "group", "account"):
        require(proof.get(key) == manifest[key])
    require(proof.get("manifestSHA256") == manifest_sha
            and proof.get("absenceConfirmed") is True and proof.get("writeAttempted") is True)


def validate_rebuild(first, second):
    require(first.get("compiledMarker") is False and second.get("compiledMarker") is True
            and first.get("buildVerified") is True and second.get("buildVerified") is True
            and first.get("validity") is True and second.get("validity") is True)
    for key in IDENTITY_HASHES + ("sourceSHA256",):
        require(is_hash(first.get(key)) and first[key] == second.get(key))
    require(is_hash(second.get("binarySHA256"))
            and first.get("binarySHA256") != second["binarySHA256"])


def launch_command(app, request, sha):
    require(is_hash(sha))
    return ["/usr/bin/open", "-W", "-a", str(app), "--args",
            "--request", str(request), "--request-sha", sha]


def private_command(command, directory, basename):
    """Exact selected tools only; stdout/stderr never escape the private root."""
    require(not any(flag in item.lower() for item in command for flag in FORBIDDEN_PERMISSIONS))
    output = Path(directory) / (basename + ".stdout")
    error = Path(directory) / (basename + ".stderr")
    with output.open("xb") as out, error.open("xb") as err:
        os.chmod(output, 0o600)
        os.chmod(error, 0o600)
        result = subprocess.run(command, stdout=out, stderr=err, check=False)
    require(result.returncode == 0)
    return output.read_bytes(), error.read_bytes()


def source_table(repo):
    return {str(repo / name): digest((repo / name).read_bytes()) for name in SOURCE_FILES}


def prepare(repo, parent, run):
    repo, parent = Path(repo).resolve(), Path(parent).resolve()
    validate_namespace(run, service(run))
    require((repo / "Package.swift").is_file() and parent.is_dir())
    require(not parent.is_relative_to(repo))
    root = parent / ("rivet-credential-storage-" + run)
    root.mkdir(mode=0o700)  # exclusive; never resets an old round
    owned_root(root, run)
    (root / "private").mkdir(mode=0o700)
    project = root / "project"
    project.mkdir(mode=0o700)
    copied = {}
    for name in PROJECT_FILES:
        source = repo / TEMPLATE / name
        require(source.is_file() and not source.is_symlink())
        target = project / name
        target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        data = source.read_bytes()
        if name.endswith("project.pbxproj"):
            require(data.count(b'relativePath = "../../..";') == 1)
            replacement = json.dumps(str(repo)).encode()
            data = data.replace(b'relativePath = "../../..";', b"relativePath = " + replacement + b";")
        with target.open("xb") as stream:
            stream.write(data)
        if not name.endswith("project.pbxproj"):
            copied[str(target)] = digest(data)
    manifest = {"schemaVersion": 1, "runUUID": run, "ownerUID": os.getuid(),
                "repo": str(repo), "service": service(run), "account": "credential",
                "sources": source_table(repo), "copiedSources": copied,
                "ownedDirectories": ["project", "derived-debug", "derived-rebuilt", "current"],
                "fixedApp": str(root / "current/CredentialStorageProbe.app"),
                "templateProjectSHA256": digest((repo / TEMPLATE / PROJECT_FILES[0]).read_bytes())}
    exclusive_json(root / "run.json", manifest)
    return {"runUUID": run, "status": "prepared"}


def context(root, check_sources=True):
    root = Path(root).absolute()
    run = load(root / "run.json")
    owned_root(root, run["runUUID"])
    require(run["ownerUID"] == os.getuid() and run["service"] == service(run["runUUID"])
            and run["account"] == "credential")
    require(run["fixedApp"] == str(root / "current/CredentialStorageProbe.app"))
    require(run["ownedDirectories"] == ["project", "derived-debug", "derived-rebuilt", "current"])
    if check_sources:
        verify_sources(run["sources"])
        verify_sources(run["copiedSources"])
    identity_path = root / "identity.json"
    if check_sources and identity_path.exists():
        require(load(identity_path)["projectSHA256"] == digest(
            (root / "project" / PROJECT_FILES[0]).read_bytes()))
    return root, run


def source_digest(run):
    return digest(json.dumps({"sources": run["sources"], "copied": run["copiedSources"]},
                             sort_keys=True).encode())


def phase_storage(root, recovery=None):
    if recovery is None:
        return root / "private"
    validate_namespace(recovery, service(recovery))
    return root / "private/recovery" / recovery


def binding_path(storage, phase):
    return storage / (phase + ".public-machine.json")


def retry_storage(root):
    return root / "private/setup-retry-1"


def retry_present(root):
    storage = retry_storage(root)
    return os.path.lexists(storage) or os.path.lexists(storage / "attempt.json")


def private_owned(root, path):
    path = contained(root, Path(path))
    cursor = root
    for part in path.relative_to(root).parts:
        cursor /= part
        require(cursor.stat().st_uid == os.getuid())
    return path


def validate_frozen_retry(root, run):
    require(run["runUUID"] == RETRY_PINS["runUUID"])
    for name, key in (("run.json", "manifestSHA256"), ("identity.json", "identitySHA256"),
                      ("project/" + PROJECT_FILES[0], "projectSHA256")):
        require(digest(private_owned(root, root / name).read_bytes()) == RETRY_PINS[key])
    identity = load(root / "identity.json")
    require(identity["projectSHA256"] == RETRY_PINS["projectSHA256"])
    profile = private_owned(root, Path(identity["profilePath"]))
    require(digest(profile.read_bytes()) == RETRY_PINS["profileSHA256"])
    return identity


def validate_retry_attempt(root):
    storage = private_owned(root, retry_storage(root))
    require(storage.is_dir() and stat.S_IMODE(storage.stat().st_mode) == 0o700)
    attempt = load(private_owned(root, storage / "attempt.json"))
    keys = {"schemaVersion", "runUUID", "phase", "attempt", "originalMachineSHA256",
            "originalHumanSHA256", "manifestSHA256", "identitySHA256", "projectSHA256",
            "runnerSHA256", "policySHA256", "bootstrapDRSHA256", "readyUUID"}
    require(set(attempt) == keys and type(attempt["schemaVersion"]) is int
            and attempt["schemaVersion"] == 1 and attempt["phase"] == "setup"
            and attempt["attempt"] == "retry-1")
    for key in ("runUUID", "originalMachineSHA256", "originalHumanSHA256", "manifestSHA256",
                "identitySHA256", "projectSHA256", "bootstrapDRSHA256"):
        require(attempt[key] == RETRY_PINS[key])
    require(is_hash(attempt["runnerSHA256"]) and is_hash(attempt["policySHA256"]))
    policy = private_owned(root, root / "private/setup-retry-1-policy.json")
    require(digest(policy.read_bytes()) == attempt["policySHA256"])
    ready = load(private_owned(root, storage / "setup.ready.json"))
    validate_ready(ready, attempt["runUUID"], "setup")
    require(ready["readyUUID"] == attempt["readyUUID"])
    consumed = load(root / "private" / ("consumed-ready-" + ready["readyUUID"] + ".json"))
    require(consumed == public_ready(ready))
    return attempt


def phase_outcome(storage, phase):
    machine = storage / (phase + ".machine.json")
    human = storage / (phase + ".human.json")
    if not machine.is_file():
        return "unknown" if (storage / (phase + ".ready.json")).exists() else "notExecuted"
    if not human.is_file() or not binding_path(storage, phase).is_file():
        return "unknown"
    raw = load(machine)
    require(load(binding_path(storage, phase)) == public_machine(raw))
    return classify(raw, load(human), digest(binding_path(storage, phase).read_bytes()))


def setup_outcome(root, retry=False):
    storage = retry_storage(root) if retry else root / "private"
    if retry and not retry_present(root):
        return "notExecuted"
    try:
        if retry:
            validate_retry_attempt(root)
        result = phase_outcome(storage, "setup")
        if result == "success":
            proof = load(storage / "setup.build-proof.json")
            require(proof.get("validity") is True and proof.get("buildVerified") is True
                    and proof.get("compiledMarker") is False)
            machine = load(storage / "setup.machine.json")
            for key in IDENTITY_HASHES + ("binarySHA256", "sourceSHA256"):
                require(is_hash(proof.get(key)) and proof[key] == machine.get(key))
            if retry:
                validate_retry_build(root, load(root / "run.json"), proof)
        return result
    except (Rejected, OSError, ValueError, KeyError, TypeError):
        return "unknown"


def effective_setup_storage(root):
    return retry_storage(root) if retry_present(root) else root / "private"


def effective_setup_proof(root):
    require(setup_outcome(root, retry_present(root)) == "success")
    return load(effective_setup_storage(root) / "setup.build-proof.json")


def completed_outcomes(root):
    outcomes = {"setup": setup_outcome(root, retry_present(root))}
    for phase in PHASES[1:]:
        outcomes[phase] = phase_outcome(root / "private", phase)
    return outcomes


def existing_processes(root):
    previous = []
    paths = [root / "private" / (phase + ".app.json") for phase in PHASES]
    paths += list((root / "private/recovery").glob("*/cleanup.app.json"))
    for path in paths:
        if path.exists():
            value = load(path)
            if "pid" in value and "processUUID" in value:
                previous.append(value)
    return previous


def profile_data(path, private, prefix):
    raw, _ = private_command(["/usr/bin/security", "cms", "-D", "-i", str(path)], private, prefix)
    profile = plistlib.loads(raw)
    require(isinstance(profile, dict))
    expiry, created = profile.get("ExpirationDate"), profile.get("CreationDate")
    require(isinstance(expiry, dt.datetime) and isinstance(created, dt.datetime)
            and created.replace(tzinfo=dt.timezone.utc) <= dt.datetime.now(dt.timezone.utc)
            < expiry.replace(tzinfo=dt.timezone.utc))
    return profile


def freeze_identity(root, identity_file):
    identity = load(identity_file)
    require(set(identity) == {"team", "appID", "group", "certificateSHA1", "profilePath"})
    for key in ("team", "appID", "group"):
        require(isinstance(identity[key], str) and bool(identity[key])
                and re.fullmatch(r"[A-Za-z0-9.-]+", identity[key]) is not None)
    require(identity["group"].startswith(identity["team"] + "."))
    require(re.fullmatch(r"[0-9A-Fa-f]{40}", identity["certificateSHA1"]) is not None)
    profile_path = Path(identity["profilePath"]).absolute()
    require(profile_path.is_file() and not profile_path.is_symlink())
    identity["profilePath"] = str(profile_path)
    identity["projectSHA256"] = digest((root / "project" / PROJECT_FILES[0]).read_bytes())
    if (root / "identity.json").exists():
        require(load(root / "identity.json") == identity)
    else:
        exclusive_json(root / "identity.json", identity)
    return identity


def build_selected(root, run, phase, storage=None):
    """Human has already selected an existing identity/profile; no provisioning allowed."""
    identity = load(root / "identity.json")
    private = storage if storage is not None else root / "private"
    if retry_present(root):
        validate_frozen_retry(root, run)
    selected_profile = Path(identity["profilePath"])
    profile = profile_data(selected_profile, private, phase + ".selected-profile")
    require(profile.get("TeamIdentifier") == [identity["team"]])
    entitlements = profile.get("Entitlements", {})
    app_identifier = identity["team"] + "." + identity["appID"]
    require(entitlements.get("com.apple.application-identifier",
                             entitlements.get("application-identifier")) == app_identifier)
    allowed_groups = entitlements.get("keychain-access-groups", [])
    require(any(group == identity["group"] or
                (isinstance(group, str) and group.endswith(".*")
                 and identity["group"].startswith(group[:-1])) for group in allowed_groups))
    certificates = profile.get("DeveloperCertificates", [])
    require(any(hashlib.sha1(cert).hexdigest().lower() == identity["certificateSHA1"].lower()
                for cert in certificates if isinstance(cert, bytes)))
    rebuilt = phase == "rebuild"
    config = "Rebuilt" if rebuilt else "Debug"
    scheme = "CredentialStorageProbeRebuilt" if rebuilt else "CredentialStorageProbe"
    derived = root / ("derived-rebuilt" if rebuilt else "derived-debug")
    command = ["/usr/bin/xcodebuild", "-project",
               str(root / "project/CredentialStorageProbe.xcodeproj"),
               "-scheme", scheme, "-configuration", config, "-derivedDataPath", str(derived),
               "-destination", "platform=macOS,arch=" + platform.machine(),
               "clean", "build",
               "ENABLE_DEBUG_DYLIB=NO", "ENABLE_APP_SANDBOX=NO"]
    exclusive_json(private / (phase + ".build-request.json"),
                   {"command": command, "sourceSHA256": source_digest(run),
                    "sourceRevision": private_revision(Path(run["repo"])),
                    "manifestSHA256": digest((root / "run.json").read_bytes())})
    private_command(command, private, phase + ".build")
    candidate = derived / ("Build/Products/" + config + "/CredentialStorageProbe.app")
    contained(root, candidate)
    require(candidate.is_dir() and not candidate.is_symlink())
    proof = inspect_selected(candidate, selected_profile, identity, private, phase)
    proof.update(sourceSHA256=source_digest(run), buildVerified=True, compiledMarker=rebuilt,
                 locationSHA256=digest(run["fixedApp"].encode()))
    context(root)  # Recheck frozen source/project after build, before installing anything.
    if retry_present(root):
        validate_frozen_retry(root, run)
        validate_retry_build(root, run, proof)
    if rebuilt:
        validate_rebuild(effective_setup_proof(root), proof)
    current = root / "current"
    current.mkdir(mode=0o700, exist_ok=True)
    installed = Path(run["fixedApp"])
    contained(root, installed)
    if installed.exists():
        require(phase == "rebuild")
        shutil.rmtree(installed)
    shutil.copytree(candidate, installed, symlinks=True)
    proof.update(sourceSHA256=source_digest(run), buildVerified=True, compiledMarker=rebuilt,
                 locationSHA256=digest(str(installed).encode()))
    exclusive_json(private / (phase + ".build-proof.json"), proof)
    return proof


def private_revision(repo):
    result = subprocess.run(["/usr/bin/git", "-C", str(repo), "rev-parse", "HEAD"],
                            capture_output=True, check=False)
    require(result.returncode == 0)
    value = result.stdout.decode().strip()
    require(re.fullmatch(r"[0-9a-f]{40}", value) is not None)
    return value


def extract_certificate(app, private, prefix, receipt):
    require(prefix.parent == private)
    private_command(["/usr/bin/codesign", "-d", "--extract-certificates=" + str(prefix), str(app)],
                    private, receipt)
    certificate = Path(str(prefix) + "0")
    require(certificate.is_file() and not certificate.is_symlink())
    data = certificate.read_bytes()
    require(bool(data))
    return data


def inspect_selected(app, selected_profile, identity, private, phase):
    private_command(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)],
                    private, phase + ".verify")
    _, details_raw = private_command(["/usr/bin/codesign", "-d", "--verbose=4", str(app)],
                                    private, phase + ".details")
    details = details_raw.decode(errors="replace")
    require("Signature=adhoc" not in details and "Authority=Apple Development:" in details)
    require("Identifier=" + identity["appID"] + "\n" in details
            and "TeamIdentifier=" + identity["team"] + "\n" in details)
    entitlement_raw, _ = private_command(
        ["/usr/bin/codesign", "-d", "--entitlements", ":-", str(app)], private, phase + ".entitlements")
    entitlements = plistlib.loads(entitlement_raw)
    require(entitlements.get("keychain-access-groups") == [identity["group"]])
    require(entitlements.get("com.apple.security.app-sandbox", False) is False)
    embedded = app / "Contents/embedded.provisionprofile"
    require(embedded.is_file() and embedded.read_bytes() == selected_profile.read_bytes())
    profile_data(embedded, private, phase + ".embedded-profile")
    dr_out, dr_err = private_command(["/usr/bin/codesign", "-d", "-r-", str(app)],
                                     private, phase + ".dr")
    body = designated_requirement(dr_out + b"\n" + dr_err)
    canonical, _ = private_command(["/usr/bin/csreq", "-r=" + body, "-t"],
                                   private, phase + ".canonical-dr")
    canonical = canonical.strip()
    require(bool(canonical) and len(canonical.decode("utf-8").splitlines()) == 1)
    prefix = private / (phase + ".cert")
    certificate = extract_certificate(app, private, prefix, phase + ".extract-cert")
    require(hashlib.sha1(certificate).hexdigest().lower() == identity["certificateSHA1"].lower())
    dates, _ = private_command(["/usr/bin/openssl", "x509", "-inform", "DER", "-in",
                                str(prefix) + "0", "-noout", "-startdate", "-enddate"],
                               private, phase + ".cert-validity")
    lines = dict(line.split("=", 1) for line in dates.decode().splitlines())
    before = dt.datetime.strptime(lines["notBefore"], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=dt.timezone.utc)
    after = dt.datetime.strptime(lines["notAfter"], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=dt.timezone.utc)
    require(before <= dt.datetime.now(dt.timezone.utc) < after)
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    binary = app / "Contents/MacOS" / info["CFBundleExecutable"]
    require(binary.is_file() and not (app / "Contents/MacOS/CredentialStorageProbe.debug.dylib").exists())
    return {"validity": True, "profileSHA256": digest(embedded.read_bytes()),
            "certificateSHA256": digest(certificate), "appIDSHA256": digest(identity["appID"].encode()),
            "groupSHA256": digest(identity["group"].encode()), "drSHA256": digest(canonical),
            "binarySHA256": digest(binary.read_bytes())}


def validate_retry_build(root, run, proof):
    identity = load(root / "identity.json")
    expected = {"profileSHA256": RETRY_PINS["profileSHA256"],
                "certificateSHA256": RETRY_PINS["certificateSHA256"],
                "drSHA256": RETRY_PINS["bootstrapDRSHA256"],
                "appIDSHA256": digest(identity["appID"].encode()),
                "groupSHA256": digest(identity["group"].encode()),
                "locationSHA256": digest(run["fixedApp"].encode()),
                "sourceSHA256": source_digest(run)}
    for key, value in expected.items():
        require(proof.get(key) == value)
    require(proof.get("validity") is True and proof.get("buildVerified") is True)


def retry_setup(root, ready_file, policy_file):
    root, run = context(root)
    private = private_owned(root, root / "private")
    require(not retry_present(root))
    validate_frozen_retry(root, run)
    require(not os.path.lexists(private / "finalized.json")
            and not os.path.lexists(private / "write-attempt.json")
            and not os.path.lexists(private / "setup.build-proof.json")
            and not os.path.lexists(Path(run["fixedApp"])))
    for phase in PHASES[1:]:
        require(not any(private.glob(phase + ".*")))
    require(not settled_children(root, run))
    machine_path = private_owned(root, private / "setup.machine.json")
    binding = private_owned(root, binding_path(private, "setup"))
    human_path = private_owned(root, private / "setup.human.json")
    require(digest(binding.read_bytes()) == RETRY_PINS["originalMachineSHA256"]
            and digest(human_path.read_bytes()) == RETRY_PINS["originalHumanSHA256"])
    initial, human = load(machine_path), load(human_path)
    require(initial.get("runUUID") == run["runUUID"] and initial.get("phase") == "setup"
            and initial.get("status") == "unknown" and initial.get("failureKind") == "build"
            and load(binding) == public_machine(initial))
    validate_observation(human, run["runUUID"], "setup", digest(binding.read_bytes()))
    require(human["wholeStageObserved"] is True and human["promptCount"] is not None)
    ready_path = private_owned(root, Path(ready_file).absolute())
    policy_path = private_owned(root, Path(policy_file).absolute())
    require(ready_path == private / "setup-retry-1-fresh-ready.json"
            and policy_path == private / "setup-retry-1-policy.json")
    ready, policy = load(ready_path), load(policy_path)
    validate_ready(ready, run["runUUID"], "setup")
    require(set(policy) == {"schemaVersion", "runUUID", "policy", "attempt", "adopted"}
            and type(policy["schemaVersion"]) is int and policy["schemaVersion"] == 1
            and policy["runUUID"] == run["runUUID"] and policy["adopted"] is True
            and policy["policy"] == "automaticCachedNoPortalUpdates" and policy["attempt"] == "retry-1")
    for path in private.glob("*.json"):
        if path == ready_path:
            continue
        old = load(private_owned(root, path))
        require(old.get("readyUUID") != ready["readyUUID"])
    storage = retry_storage(root)
    storage.mkdir(mode=0o700)  # Directory itself permanently spends the one retry quota.
    try:
        attempt = {key: RETRY_PINS[key] for key in (
            "runUUID", "originalMachineSHA256", "originalHumanSHA256", "manifestSHA256",
            "identitySHA256", "projectSHA256", "bootstrapDRSHA256")}
        attempt.update(schemaVersion=1, phase="setup", attempt="retry-1",
                       runnerSHA256=digest(Path(__file__).read_bytes()),
                       policySHA256=digest(policy_path.read_bytes()), readyUUID=ready["readyUUID"])
        # Reviewed-version authority is external Tester/Reviewer handoff, not this hash.
        exclusive_json(storage / "attempt.json", attempt)
        exclusive_json(private / ("consumed-ready-" + ready["readyUUID"] + ".json"), public_ready(ready))
        exclusive_json(storage / "setup.ready.json", public_ready(ready))
        proof = build_selected(root, run, "setup", storage)
        validate_retry_build(root, run, proof)
        machine = dict(proof, runUUID=run["runUUID"], phase="setup", status="success",
                       sameSource=True, sameIdentity=True, sameLocation=True)
    except (Rejected, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError,
            plistlib.InvalidFileException):
        machine = {"runUUID": run["runUUID"], "phase": "setup", "status": "unknown",
                   "failureKind": "build"}
    machine.update(schemaVersion=1, manifestSHA256=digest((root / "run.json").read_bytes()))
    exclusive_json(storage / "setup.machine.json", machine)
    sha = exclusive_json(binding_path(storage, "setup"), public_machine(machine))
    return {"runUUID": run["runUUID"], "phase": "setup", "machineSHA256": sha,
            "status": "awaitingHumanObservation"}


def stage(root, phase, ready_file, identity_file=None, recovery=False, built_app=None):
    root, run = context(root)
    require(phase in PHASES)
    require(phase != "setup" or not retry_present(root))
    require_previous(phase, completed_outcomes(root))
    ready = load(ready_file)
    validate_ready(ready, run["runUUID"], phase)
    private = root / "private"
    require(not (private / "finalized.json").exists() or recovery)
    recovery_id = str(uuid.uuid4()) if recovery else None
    require(not recovery or phase == "cleanup")
    storage = phase_storage(root, recovery_id)
    if recovery:
        storage.mkdir(mode=0o700, parents=True)
    exclusive_json(private / ("consumed-ready-" + ready["readyUUID"] + ".json"), public_ready(ready))
    exclusive_json(storage / (phase + ".ready.json"), public_ready(ready))
    # Once ready is consumed, every attempted phase has finite bytes for actual Human observation.
    try:
        previous = existing_processes(root)
        for old in previous:
            require(not alive(old["pid"]))
        machine = attempt_stage(root, run, phase, storage, previous, recovery_id, identity_file, built_app)
    except (Rejected, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError,
            plistlib.InvalidFileException):
        machine = {"runUUID": run["runUUID"], "phase": phase, "status": "unknown",
                   "failureKind": "build" if phase in ("setup", "rebuild") else "guard"}
        # Deliberately do not claim identity, validity, process freshness, or absent item.
    machine["schemaVersion"] = 1
    machine["manifestSHA256"] = digest((root / "run.json").read_bytes())
    exclusive_json(storage / (phase + ".machine.json"), machine)
    sha = exclusive_json(binding_path(storage, phase), public_machine(machine))
    return {"runUUID": run["runUUID"], "phase": phase, "machineSHA256": sha,
            "recoveryUUID": recovery_id, "status": "awaitingHumanObservation"}


def attempt_stage(root, run, phase, storage, previous, recovery_id, identity_file, built_app):
    private = root / "private"
    if phase == "cleanup" and not os.path.lexists(private / "write-attempt.json"):
        require_no_possible_write(root, run)
        return {"runUUID": run["runUUID"], "phase": phase, "status": "success",
                "owned": True, "writeAttempted": False, "previousTerminated": True, "sameSource": True}
    if phase == "cleanup":
        settled_children(root, run)
    if phase == "setup":
        require((identity_file is not None) != (built_app is not None))
        if built_app is not None:
            identity_file = identity_from_built_app(root, built_app, storage)
        freeze_identity(root, identity_file)
        proof = build_selected(root, run, phase)
        return dict(proof, runUUID=run["runUUID"], phase=phase, status="success",
                    sameSource=True, sameIdentity=True, sameLocation=True)
    if phase == "rebuild":
        proof = build_selected(root, run, phase)
        validate_rebuild(effective_setup_proof(root), proof)
        return dict(proof, runUUID=run["runUUID"], phase=phase, status="success",
                    sameSource=True, sameIdentity=True, sameLocation=True, differentBinary=True)
    identity = load(root / "identity.json")
    proof_phase = "rebuild" if phase == "rebuilt-read-b" else (
        "rebuild" if (private / "rebuild.build-proof.json").exists() else "setup")
    proof = (effective_setup_proof(root) if proof_phase == "setup" else
             load(private / (proof_phase + ".build-proof.json")))
    require(proof["validity"] is True)
    inspected = inspect_selected(Path(run["fixedApp"]), Path(identity["profilePath"]),
                                 identity, storage, phase)
    for key in IDENTITY_HASHES[:-1] + ("binarySHA256",):
        require(inspected[key] == proof[key])
    request = {"runUUID": run["runUUID"], "phase": phase, "root": str(root),
               "service": run["service"], "group": identity["group"], "account": "credential",
               "clientID": "rivet-validation-fake-client",
               "manifestSHA256": digest((root / "run.json").read_bytes()),
               "identitySHA256": digest((root / "identity.json").read_bytes()),
               "compiledMarker": proof["compiledMarker"], "recoveryUUID": recovery_id}
    if phase == "cleanup":
        ownership = load(private / "write-attempt.json")
        validate_ownership(dict(run, group=identity["group"]), ownership, request["manifestSHA256"])
    request_path = storage / (phase + ".request.json")
    sha = exclusive_json(request_path, request)
    boundary = {"runUUID": run["runUUID"], "phase": phase,
                "manifestSHA256": request["manifestSHA256"]}
    exclusive_json(storage / (phase + ".launch-attempt.json"), boundary)
    private_command(launch_command(Path(run["fixedApp"]), request_path, sha),
                    storage, phase + ".launch")
    exclusive_json(storage / (phase + ".launch-settled.json"), boundary)
    receipt = load(storage / (phase + ".app.json"))
    require(receipt.get("runUUID") == run["runUUID"] and receipt.get("phase") == phase
            and receipt.get("compiledMarker") is proof["compiledMarker"])
    validate_process(receipt, previous)
    require(not alive(receipt["pid"]))
    machine = dict(proof, **receipt)
    machine.update(sameSource=True, sameIdentity=True, sameLocation=True, validity=True,
                   freshProcess=True, previousTerminated=True)
    return machine


def settled_children(root, run):
    private = contained(root, root / "private")
    history, observed = [], []
    storages = [private]
    recovery = private / "recovery"
    if recovery.exists():
        contained(root, recovery)
        for child in recovery.iterdir():
            require(child.is_dir())
            storages.append(contained(root, child))
    manifest_sha = digest((root / "run.json").read_bytes())
    for storage in storages:
        for phase in PHASES:
            names = (phase + ".request.json", phase + ".launch-attempt.json",
                     phase + ".launch-settled.json", phase + ".app.json")
            paths = [contained(root, storage / name) for name in names]
            if not any(path.exists() for path in paths):
                continue
            require(all(path.is_file() for path in paths))
            request, launched, settled, receipt = map(load, paths)
            for value in (request, launched, settled, receipt):
                require(value.get("runUUID") == run["runUUID"] and value.get("phase") == phase)
            require(request.get("manifestSHA256") == manifest_sha
                    and launched.get("manifestSHA256") == manifest_sha
                    and settled.get("manifestSHA256") == manifest_sha)
            require(request.get("service") == run["service"] and request.get("account") == "credential")
            validate_process(receipt, history, pid_alive=alive)
            require(not alive(receipt["pid"]))
            history.append(receipt)
            observed.append((phase, receipt))
    return observed


def require_no_possible_write(root, run):
    """Unknown child or any possible write keeps all recovery material intact."""
    private = contained(root, root / "private")
    require(not os.path.lexists(private / "write-attempt.json"))
    require(load(root / "run.json") == run)
    for phase, receipt in settled_children(root, run):
        require(phase == "save-a" and receipt.get("status") == "failure"
                and receipt.get("writeAttempted", False) is False)
    require(not os.path.lexists(private / "write-attempt.json"))


def designated_requirement(raw):
    text = raw.decode("utf-8")
    lines = [line.strip() for line in text.splitlines()
             if line.strip().startswith("designated =>")]
    require(len(lines) == 1)
    require(lines[0].startswith("designated => "))
    body = lines[0][len("designated => "):].strip()
    require(bool(body) and not any(ord(character) < 32 for character in body))
    return body


def identity_from_built_app(root, built_app, private):
    """Read only the exact owned Debug product selected after setup fresh ready."""
    app = contained(root, Path(built_app).absolute())
    require(app == root / "derived-debug/Build/Products/Debug/CredentialStorageProbe.app")
    require(app.is_dir())
    private_command(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)],
                    private, "setup.bootstrap-verify")
    _, raw = private_command(["/usr/bin/codesign", "-d", "--verbose=4", str(app)],
                             private, "setup.bootstrap-details")
    details = raw.decode("utf-8")
    require("Signature=adhoc" not in details and "Authority=Apple Development:" in details)
    def field(name):
        values = re.findall(r"^" + re.escape(name) + r"=(.+)$", details, re.MULTILINE)
        require(len(values) == 1 and bool(values[0]))
        return values[0]
    app_id, team = field("Identifier"), field("TeamIdentifier")
    ent_raw, _ = private_command(
        ["/usr/bin/codesign", "-d", "--entitlements", ":-", str(app)],
        private, "setup.bootstrap-entitlements")
    groups = plistlib.loads(ent_raw).get("keychain-access-groups")
    require(isinstance(groups, list) and len(groups) == 1 and isinstance(groups[0], str))
    group = groups[0]
    require(group.startswith(team + ".") and "*" not in group)
    embedded = app / "Contents/embedded.provisionprofile"
    require(embedded.is_file() and not embedded.is_symlink())
    profile_data(embedded, private, "setup.bootstrap-profile")
    prefix = private / "setup.bootstrap-cert"
    certificate_sha1 = hashlib.sha1(
        extract_certificate(app, private, prefix, "setup.bootstrap-extract")).hexdigest()
    # clean build will remove the manual product; retain only an owned private copy of its profile.
    copied_profile = private / "setup.selected.provisionprofile"
    fd = os.open(copied_profile, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(embedded.read_bytes())
        stream.flush()
        os.fsync(stream.fileno())
    identity = {"team": team, "appID": app_id, "group": group,
                "certificateSHA1": certificate_sha1, "profilePath": str(copied_profile)}
    inspect_selected(app, copied_profile, identity, private, "setup.bootstrap")
    path = private / "setup.bootstrap-identity.json"
    exclusive_json(path, identity)
    return path


def public_ready(value):
    return {key: value[key] for key in ("runUUID", "phase", "ready", "readyUUID")}


def observe(root, phase, human_file, recovery=None, setup_attempt=None):
    root, run = context(root, check_sources=False)
    require(setup_attempt is None or (setup_attempt == "retry-1" and phase == "setup" and recovery is None))
    storage = retry_storage(root) if setup_attempt is not None else phase_storage(root, recovery)
    if setup_attempt is not None:
        validate_retry_attempt(root)
    require(recovery is None or phase == "cleanup")
    require(not (root / "private/finalized.json").exists() or recovery is not None)
    machine_path = storage / (phase + ".machine.json")
    machine = load(machine_path)
    sha = digest(binding_path(storage, phase).read_bytes())
    human = load(human_file)
    validate_observation(human, run["runUUID"], phase, sha)
    exclusive_json(storage / (phase + ".human.json"), public_human(human))
    return {"runUUID": run["runUUID"], "phase": phase, "status": classify(machine, human, sha)}


def export_one(root, expected, phase, storage, name, final):
    machine_path, human_path = storage / (phase + ".machine.json"), storage / (phase + ".human.json")
    if not machine_path.exists():
        return
    machine = load(machine_path)
    projection = load(binding_path(storage, phase))
    require(projection == public_machine(machine))
    target = expected / (name + ".machine.json")
    if not target.exists():
        exclusive_json(target, projection)
    sha = digest(binding_path(storage, phase).read_bytes())
    require(digest(target.read_bytes()) == sha)
    target_human = expected / (name + ".human.json")
    if human_path.exists():
        human = load(human_path)
        validate_observation(human, load(root / "run.json")["runUUID"], phase, sha)
        if not target_human.exists():
            exclusive_json(target_human, public_human(human))
        require(load(target_human) == public_human(human))
    elif final and not target_human.exists():
        exclusive_json(target_human, public_human({
            "runUUID": load(root / "run.json")["runUUID"], "phase": phase,
            "machineSHA256": sha, "promptCount": None,
            "wholeStageObserved": False, "actions": []}))


def export_receipts(root, destination, final=False):
    root, run = context(root, check_sources=False)
    expected = Path(run["repo"]) / "plan/github-oauth-credential-persistence/evidence/live" / run["runUUID"]
    require(Path(destination).absolute() == expected.absolute())
    require(not expected.is_symlink())
    expected.mkdir(parents=True, exist_ok=True)
    require(expected.resolve() == expected.absolute())
    outcomes = completed_outcomes(root)
    for phase in PHASES:
        export_one(root, expected, phase, root / "private", phase, final)
    if retry_present(root):
        contained(root, retry_storage(root))
        export_one(root, expected, "setup", retry_storage(root), "setup-retry-1", final)
    if final:
        attempts = {"initial": setup_outcome(root), "retry-1": setup_outcome(root, True)}
        effective = "retry-1" if retry_present(root) else "initial"
        if outcomes["setup"] != "success":
            effective = None
        history = list(outcomes.values()) + [value for value in attempts.values() if value != "notExecuted"]
        status = "success" if all(value == "success" for value in history) else "unknown"
        if "failure" in history:
            status = "failure"
        exclusive_json(expected / "run-summary.json", {"schemaVersion": 2,
            "runUUID": run["runUUID"], "status": status, "phases": outcomes,
            "setupAttempts": attempts, "effectiveSetupAttempt": effective})
        exclusive_json(root / "private/finalized.json", {"runUUID": run["runUUID"], "status": status})
    return {"runUUID": run["runUUID"], "phases": outcomes}


def cleanup_files(root):
    root, run = context(root)
    require((root / "private/finalized.json").exists())
    cleaned = False
    storages = [root / "private"] + list((root / "private/recovery").glob("*"))
    for storage in storages:
        machine_path, human_path = storage / "cleanup.machine.json", storage / "cleanup.human.json"
        if machine_path.exists() and human_path.exists():
            machine = load(machine_path)
            success = classify(machine, load(human_path),
                               digest(binding_path(storage, "cleanup").read_bytes())) == "success"
            if success and machine.get("writeAttempted") is False:
                require_no_possible_write(root, run)
            cleaned |= success
    require(cleaned)
    settled_children(root, run)
    for name in run["ownedDirectories"]:
        path = contained(root, root / name)
        if path.exists():
            shutil.rmtree(path)
    exclusive_json(root / "private/files-cleaned.json",
                   {"runUUID": run["runUUID"], "ownedFilesRemoved": True,
                    "privateProofRetained": True})
    return {"runUUID": run["runUUID"], "status": "ownedFilesRemovedProofRetained"}


DIAGNOSTIC_PURPOSES = ("diagnostic-only", "namespace-read-only")
DIAGNOSTIC_STAGES = ("bootstrap", "args", "request", "root", "source", "identity", "bundle", "entitlement", "completed")
DIAGNOSTIC_SOURCES = ("README.md", "Sources/main.swift", "scripts/credential_storage_live.py", "Tests/test_live_protocol.py")


def diagnostic_context(manifest_file, manifest_sha):
    path = Path(manifest_file).absolute()
    require(is_hash(manifest_sha) and path.name == "diagnostic.json")
    root = path.parent
    require(root.resolve() == root and not root.is_symlink())
    value = load(private_owned(root, path))
    require(digest(path.read_bytes()) == manifest_sha)
    keys = {"schemaVersion", "diagnosticUUID", "legacyRunUUID", "purpose", "legacyRoot", "expectedApp",
            "sourceHashes", "binarySHA256", "legacyManifestSHA256", "legacyIdentitySHA256",
            "legacySaveMachineSHA256", "legacySaveHumanSHA256"}
    require(set(value) == keys and type(value["schemaVersion"]) is int and value["schemaVersion"] == 1)
    validate_namespace(value["diagnosticUUID"], service(value["diagnosticUUID"]))
    require(root.name == "rivet-credential-storage-diagnostic-" + value["diagnosticUUID"])
    require(root.stat().st_uid == os.getuid() and stat.S_IMODE(root.stat().st_mode) == 0o700)
    require(value["legacyRunUUID"] == RETRY_PINS["runUUID"] and value["purpose"] in DIAGNOSTIC_PURPOSES)
    legacy = Path(value["legacyRoot"])
    owned_root(legacy, value["legacyRunUUID"])
    app = root / "app/CredentialStorageProbe.app"
    require(value["expectedApp"] == str(app))
    private_owned(root, app)
    binary = private_owned(root, app / "Contents/MacOS/CredentialStorageProbe")
    require(is_hash(value["binarySHA256"]) and digest(binary.read_bytes()) == value["binarySHA256"])
    sources = value["sourceHashes"]
    require(isinstance(sources, dict) and set(sources) == {str(root / "source" / leaf) for leaf in DIAGNOSTIC_SOURCES})
    for name, expected in sources.items():
        require(is_hash(expected) and digest(private_owned(root, Path(name)).read_bytes()) == expected)
    for name, key in (("run.json", "legacyManifestSHA256"), ("identity.json", "legacyIdentitySHA256"),
                      ("private/save-a.public-machine.json", "legacySaveMachineSHA256"),
                      ("private/save-a.human.json", "legacySaveHumanSHA256")):
        require(is_hash(value[key]) and digest(private_owned(legacy, legacy / name).read_bytes()) == value[key])
    require(load(legacy / "run.json")["runUUID"] == value["legacyRunUUID"])
    return root, value, legacy


def diagnostic_projection(raw):
    require(type(raw.get("schemaVersion")) is int and raw["schemaVersion"] == 1)
    validate_namespace(raw.get("diagnosticUUID"), service(raw.get("diagnosticUUID")))
    require(raw.get("legacyRunUUID") == RETRY_PINS["runUUID"]
            and raw.get("purpose") in DIAGNOSTIC_PURPOSES
            and raw.get("stage") in DIAGNOSTIC_STAGES
            and raw.get("status") in ("success", "failure", "unknown"))
    out = {key: raw[key] for key in ("schemaVersion", "diagnosticUUID", "legacyRunUUID", "purpose", "stage", "status")}
    if "failureKind" in raw:
        require(raw["failureKind"] in ("input", "guard", "unavailable", "other"))
        out["failureKind"] = raw["failureKind"]
    for key in ("manifestSHA256", "sourceSHA256", "binarySHA256"):
        if key in raw:
            require(is_hash(raw[key])); out[key] = raw[key]
    if "diagnosticCopy" in raw:
        require(type(raw["diagnosticCopy"]) is bool); out["diagnosticCopy"] = raw["diagnosticCopy"]
    if "state" in raw:
        require(raw["purpose"] == "namespace-read-only" and raw["state"] in (
            "absent", "present", "denied", "unavailable", "corrupt", "identityMismatch", "unknown"))
        out["state"] = raw["state"]
    return out


def diagnostic_stage(manifest_file, manifest_sha, ready_file):
    root, manifest, legacy = diagnostic_context(manifest_file, manifest_sha)
    prefix = "diagnostic" if manifest["purpose"] == "diagnostic-only" else "namespace"
    ready_path = private_owned(root, Path(ready_file).absolute())
    require(ready_path == root / (prefix + ".ready.json"))
    ready = load(ready_path)
    require(set(ready) == {"diagnosticUUID", "purpose", "ready", "readyUUID"}
            and ready["diagnosticUUID"] == manifest["diagnosticUUID"]
            and ready["purpose"] == manifest["purpose"] and ready["ready"] is True)
    validate_namespace(ready["readyUUID"], service(ready["readyUUID"]))
    consumed = root / (prefix + ".consumed-ready.json")
    machine = root / (prefix + ".machine.json")
    require(not os.path.lexists(consumed) and not os.path.lexists(machine)
            and not os.path.lexists(root / (prefix + ".human.json")))
    request = private_owned(legacy, legacy / "private/save-a.request.json")
    command = ["/usr/bin/open", "-W", "-a", manifest["expectedApp"],
               "--env", "RIVET_DIAGNOSTIC_MANIFEST=" + str(root / "diagnostic.json"),
               "--env", "RIVET_DIAGNOSTIC_SHA256=" + manifest_sha,
               "--args", "--request", str(request), "--request-sha", digest(request.read_bytes())]
    # External operator must first verify D05 signing/source freeze and obtain this purpose's actual ready.
    exclusive_json(consumed, {"schemaVersion": 1, "diagnosticUUID": manifest["diagnosticUUID"],
                   "purpose": manifest["purpose"], "readyUUID": ready["readyUUID"],
                   "readySHA256": digest(ready_path.read_bytes())})
    try:
        private_command(command, root, prefix + ".launch")
        raw = load(private_owned(root, machine))
        require(raw == diagnostic_projection(raw))
        require(raw["diagnosticUUID"] == manifest["diagnosticUUID"] and raw["purpose"] == manifest["purpose"]
                and raw.get("manifestSHA256") == manifest_sha
                and raw.get("binarySHA256") == manifest["binarySHA256"])
        return {"diagnosticUUID": manifest["diagnosticUUID"], "purpose": manifest["purpose"],
                "status": "awaitingHumanObservation", "machineSHA256": digest(machine.read_bytes())}
    except (Rejected, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        # Never fabricate an App receipt; marker remains spent even if launch/receipt failed.
        return {"diagnosticUUID": manifest["diagnosticUUID"], "purpose": manifest["purpose"],
                "status": "unknown", "appReceiptPresent": machine.is_file()}


def diagnostic_observe(manifest_file, manifest_sha, human_file):
    root, manifest, _ = diagnostic_context(manifest_file, manifest_sha)
    prefix = "diagnostic" if manifest["purpose"] == "diagnostic-only" else "namespace"
    machine_path = private_owned(root, root / (prefix + ".machine.json"))
    raw = load(machine_path)
    require(raw == diagnostic_projection(raw) and raw["diagnosticUUID"] == manifest["diagnosticUUID"]
            and raw["purpose"] == manifest["purpose"] and raw.get("manifestSHA256") == manifest_sha)
    human = load(private_owned(root, Path(human_file).absolute()))
    require(set(human) == {"diagnosticUUID", "purpose", "machineSHA256", "promptCount", "wholeStageObserved", "actions"}
            and human["diagnosticUUID"] == manifest["diagnosticUUID"] and human["purpose"] == manifest["purpose"])
    sha = digest(machine_path.read_bytes())
    validate_observation(dict(human, runUUID=manifest["diagnosticUUID"], phase=manifest["purpose"]),
                         manifest["diagnosticUUID"], manifest["purpose"], sha)
    exclusive_json(root / (prefix + ".human.json"), human)
    success = (raw["status"] == "success" and human["wholeStageObserved"]
               and human["promptCount"] is not None
               and (manifest["purpose"] == "diagnostic-only" or raw.get("state") == "absent"))
    return {"diagnosticUUID": manifest["diagnosticUUID"], "purpose": manifest["purpose"],
            "status": "success" if success else "unknown"}



LAUNCHER_ATTEMPT = "diagnostic-launch-amendment-1"
LAUNCHER_WAIT_SECONDS = 30
LAUNCHER_PINS = {
    "diagnostic.json": "15e4e4fbcc09524cbabdca03b24f98e136f77f7c4ee99ea8351ee6cce06cd02e",
    "build.machine.json": "1b5be269b6f9e086c3215b8146d621307e4c7a834040575f1f421bcf5c8930eb",
    "build.human.json": "f49397b75c4839bb35fa2e4e5675b69d1cbd39a5d390a4770d884233f0965f3d",
    "diagnostic.consumed-ready.json": "cbdb03661df37a634a97ba6e973377ea87a220f0891cd70c44a82fa297991a31",
    "diagnostic.launch.stdout": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "diagnostic.launch.stderr": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "binarySHA256": "94a4cee1c1f26b8da62e633784b0fd0bbafae2ee6c3766fc5222bd253fe1108f",
}


def launcher_ancestors(path):
    path = Path(path)
    require(path.is_absolute() and path.resolve(strict=True) == path and ".." not in path.parts)
    require(all(not item.is_symlink() for item in (path, *path.parents)))


def launcher_owned(root, path, directory=False):
    path = private_owned(root, path)
    launcher_ancestors(path)
    info = path.stat()
    require(info.st_uid == os.getuid())
    if directory:
        require(stat.S_ISDIR(info.st_mode) and stat.S_IMODE(info.st_mode) == 0o700)
    else:
        require(stat.S_ISREG(info.st_mode) and stat.S_IMODE(info.st_mode) == 0o600)
    return path


def launcher_flush_directory(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def launcher_write(path, value):
    sha = exclusive_json(path, value)
    launcher_flush_directory(Path(path).parent)
    return sha



LAUNCHER_PUBLICATIONS = {"launcher.machine.json": "launcher.machine.pending.json",
                         "caller-result.json": "caller-result.pending.json"}
LAUNCHER_MACHINE_KEYS = {"schemaVersion", "diagnosticUUID", "attempt", "purpose", "manifestSHA256",
    "binarySHA256", "runnerSHA256", "attemptSHA256", "readySHA256", "originalConsumedSHA256", "status",
    "stage", "spawnAttempted", "nativeSpawned", "nativePID", "nativeReturnCode", "nativeSignal",
    "nativeSettled", "exceptionKind", "timedOut", "appReceiptPresent", "appReceiptValidity",
    "appReceiptSHA256", "appReceiptAttributable", "hostConfirmed"}


def launcher_publish(path, value):
    """Sync pending before atomically publishing an immutable observable name; no crash-survival claim."""
    path = Path(path)
    require(path.name in LAUNCHER_PUBLICATIONS and path.parent.name == LAUNCHER_ATTEMPT)
    root = path.parent.parent
    launcher_owned(root, root, directory=True)
    launcher_owned(root, path.parent, directory=True)
    pending = path.parent / LAUNCHER_PUBLICATIONS[path.name]
    require(not os.path.lexists(path) and not os.path.lexists(pending))
    sha = launcher_write(pending, value)  # Exclusive payload fsync and pending-directory fsync.
    os.link(pending, path, follow_symlinks=False)  # Exclusive publication is the final fallible I/O.
    return sha


def launcher_publication(root, path):
    """Pending alone is never bindable, regardless of how complete its JSON looks."""
    require(path.name in LAUNCHER_PUBLICATIONS)
    if not os.path.lexists(path):
        return None
    final = launcher_owned(root, path)
    pending = launcher_owned(root, path.parent / LAUNCHER_PUBLICATIONS[path.name])
    first, second = final.stat(), pending.stat()
    require((first.st_dev, first.st_ino) == (second.st_dev, second.st_ino))
    raw = final.read_bytes()
    require(raw == pending.read_bytes())
    value = json.loads(raw)
    require(isinstance(value, dict))
    return value, digest(raw)



LAUNCHER_GUARD_POINTS = {"context", "ready", "quota", "request", "snapshot-platform", "snapshot-library",
    "snapshot-list-size", "snapshot-list-read", "snapshot-open-path", "snapshot-name", "snapshot-metadata", "snapshot-instance", "snapshot-classification", "snapshot-path", "snapshot-args-size",
    "snapshot-args-read", "snapshot-args-decode", "snapshot-match", "caller-source", "output", "unknown"}


def launcher_guard_mark(observation, point):
    if observation is not None:
        observation.update(guardPoint=point, apiOutcome="notCalled", apiReturn="notAvailable", errnoKind="none")


def launcher_errno_kind(number):
    import errno
    if number in (errno.ENOENT, errno.ESRCH):
        return "notFound"
    if number in (errno.EACCES, errno.EPERM):
        return "permissionDenied"
    if number == errno.EINTR:
        return "interrupted"
    if number in (errno.ENOSYS, errno.ENOTSUP, errno.EOPNOTSUPP):
        return "unsupported"
    return "other" if isinstance(number, int) and number != 0 else "unknown"


def launcher_guard_api(observation, function, *arguments, zero_success=False, native_result=None):
    """Observe this existing native call once, without changing its result or guard."""
    import ctypes
    ctypes.set_errno(0)
    try:
        result = function(*arguments)
    except Exception as error:
        if observation is not None:
            observation.update(apiOutcome="exception", apiReturn="notAvailable",
                               errnoKind=launcher_errno_kind(getattr(error, "errno", None)))
        raise
    native_errno = ctypes.get_errno()  # Read before any later operation can overwrite it.
    if native_result is not None:
        native_result["errno"] = native_errno  # Local collector for this path call only, never serialized raw.
    if observation is not None:
        returned = "negative" if result < 0 else "zero" if result == 0 else "positive"
        succeeded = result == 0 if zero_success else result > 0
        observation.update(apiOutcome="returned", apiReturn=returned,
                           errnoKind="none" if succeeded else launcher_errno_kind(native_errno))
    return result


def launcher_guard_projection(observation, error):
    if observation.get("apiOutcome") == "notCalled":
        observation.update(apiOutcome="guard" if isinstance(error, Rejected) else "exception",
                           errnoKind="none" if isinstance(error, Rejected)
                           else launcher_errno_kind(getattr(error, "errno", None)))
    allowed = {"guardPoint": LAUNCHER_GUARD_POINTS, "apiOutcome": {"notCalled", "returned", "exception", "guard"},
               "apiReturn": {"notAvailable", "negative", "zero", "positive"},
               "errnoKind": {"none", "notFound", "permissionDenied", "interrupted", "unsupported", "other", "unknown"}}
    fallback = {"guardPoint": "unknown", "apiOutcome": "exception", "apiReturn": "notAvailable", "errnoKind": "unknown"}
    return {key: observation[key] if observation.get(key) in values else fallback[key]
            for key, values in allowed.items()}


def launcher_open_arguments(raw):
    """Parse only argc argv from KERN_PROCARGS2; never expose the environment tail."""
    import struct
    require(len(raw) >= 5)
    argc = struct.unpack_from("=i", raw)[0]
    require(0 < argc <= 4096)
    end = raw.find(b"\0", 4)
    require(end >= 4)
    offset = end + 1
    while offset < len(raw) and raw[offset] == 0:
        offset += 1
    arguments = []
    for _ in range(argc):
        end = raw.find(b"\0", offset)
        require(end >= offset)
        arguments.append(os.fsdecode(raw[offset:end]))
        offset = end + 1
    require(bool(arguments[0]))
    return arguments


def launcher_name_candidate(name, paths):
    """Name is only an exclusion prefilter; ambiguous names still require the full path."""
    known = {Path(path).name for path in paths} | {"open"}
    # Fixed names are ASCII. A different encoding/alias contract cannot prove exclusion.
    if not name.isascii() or any(not target or not target.isascii() for target in known):
        return True
    if not all(character.isalnum() or character in "._-" for character in name):
        return True
    folded = name.casefold()
    aliases = {target[:limit].casefold() for target in known for limit in (15, 31, len(target))}
    return any(alias.startswith(folded) for alias in aliases)


def launcher_bsdinfo_type():
    """Public SDK sys/proc_info.h layout, independently checked against its C header."""
    import ctypes
    class BSDInfo(ctypes.Structure):
        _fields_ = [(key, ctypes.c_uint32) for key in (
            "pbi_flags", "pbi_status", "pbi_xstatus", "pbi_pid", "pbi_ppid", "pbi_uid",
            "pbi_gid", "pbi_ruid", "pbi_rgid", "pbi_svuid", "pbi_svgid", "rfu_1")] + [
            ("pbi_comm", ctypes.c_char * 16), ("pbi_name", ctypes.c_char * 32)] + [
            (key, ctypes.c_uint32) for key in ("pbi_nfiles", "pbi_pgid", "pbi_pjobc", "e_tdev", "e_tpgid")] + [
            ("pbi_nice", ctypes.c_int32), ("pbi_start_tvsec", ctypes.c_uint64),
            ("pbi_start_tvusec", ctypes.c_uint64)]
    return BSDInfo


def launcher_process_defaults():
    return dict(decision="notChecked", zombieObserved=False, zombieExcluded=False,
                noncandidateExcluded=False, instanceChecked=False, instanceChanged=False,
                conflictObserved=False, checksFinished=False)


def launcher_process_note(observation, decision, **facts):
    if observation is not None:
        observation.setdefault("_process", launcher_process_defaults()).update(decision=decision, **facts)


def launcher_process_projection(observation):
    defaults = launcher_process_defaults()
    decisions = {"notChecked", "noncandidate", "zombieExcluded", "metadataUnavailable", "metadataInvalid",
                 "permissionDenied", "instanceChanged", "classificationChanged", "targetHost", "targetOpen",
                 "candidateOther", "pathUnavailable", "argsUnavailable"}
    try:
        value = observation.get("_process", defaults)
        require(set(value) == set(defaults) and value["decision"] in decisions)
        require(all(type(value[key]) is bool for key in defaults if key != "decision"))
        return {key: value[key] for key in defaults}
    except Exception:
        return defaults  # Observation can never supply permission to launch.


def launcher_read_metadata(lib, pid, observation=None, point="snapshot-metadata", identity_observation=None):
    import ctypes
    launcher_guard_mark(observation, point)
    launcher_process_note(observation, "metadataUnavailable")
    kind = launcher_bsdinfo_type()
    info = kind()
    result = launcher_guard_api(observation, lib.proc_pidinfo, pid, 3, 1,
                                ctypes.byref(info), ctypes.sizeof(info))
    if result != 0:
        launcher_process_note(observation, "metadataInvalid")
    require(result == ctypes.sizeof(info))
    require(info.pbi_start_tvsec > 0 and info.pbi_start_tvusec < 1000000)
    require(info.pbi_status in (2, 3, 4, 5))  # SDK SRUN/SSLEEP/SSTOP/SZOMB; SIDL is not ready.
    record = dict(pid=info.pbi_pid, uid=info.pbi_uid, status=info.pbi_status,
                  start=(info.pbi_start_tvsec, info.pbi_start_tvusec))
    if identity_observation is not None:
        identity_observation.update(record)  # Full-size, valid status/time; comparison only, not permission.
    require(info.pbi_pid == pid and info.pbi_uid == os.getuid())
    if info.pbi_status == 5:
        if observation is not None:
            observation.setdefault("_process", launcher_process_defaults())["zombieObserved"] = True
        return record  # Positive status, even if no process name remains.
    names = {}
    for field, width in (("pbi_name", 32), ("pbi_comm", 16)):
        raw = ctypes.string_at(ctypes.addressof(info) + getattr(kind, field).offset, width)
        require(b"\0" in raw)
        names[field] = raw.split(b"\0", 1)[0].decode("utf-8", errors="strict")
        record[field] = raw
    record["name"] = names["pbi_name"] or names["pbi_comm"]
    require(bool(record["name"]))
    return record


def launcher_path_failure_defaults():
    return {"pass": "none", "postState": "notRead", "nameMatchKind": "notChecked", "pathErrno": "notCalled",
            "pathFailure": dict(guardPoint="unknown", apiOutcome="notCalled", apiReturn="notAvailable", errnoKind="none")}


def launcher_path_failure_projection(observation):
    defaults = launcher_path_failure_defaults()
    allowed = {"pass": {"none", "first", "second"},
               "postState": {"notRead", "liveSame", "zombieSame", "instanceChanged", "classificationChanged",
                             "permissionDenied", "unavailable", "invalid", "unknown"},
               "nameMatchKind": {"notChecked", "full", "alias15", "alias31", "prefixOnly", "ambiguous"},
               "pathErrno": {"notCalled", "ENOENT", "ESRCH", "EPERM", "EACCES", "zero", "other", "unknown"}}
    try:
        value = observation.get("_pathFailure", defaults)
        require(set(value) == set(defaults))
        require(all(value[key] in values for key, values in allowed.items()))
        raw_guard = value["pathFailure"]
        require(set(raw_guard) == {"guardPoint", "apiOutcome", "apiReturn", "errnoKind"})
        guard = launcher_guard_projection(dict(raw_guard), Rejected())
        require(guard == raw_guard)
        return {**{key: value[key] for key in allowed}, "pathFailure": guard}
    except Exception:
        return defaults


def launcher_name_match_kind(record, paths):
    name_raw = record["pbi_name"].split(b"\0", 1)[0]
    comm_raw = record["pbi_comm"].split(b"\0", 1)[0]
    raw, width = (name_raw, 31) if name_raw else (comm_raw, 15)
    name = raw.decode("utf-8", errors="strict").casefold()
    known = {Path(path).name for path in paths} | {"open"}
    if any(name == target.casefold() for target in known):
        return "full"
    if raw.isascii() and len(raw) == width and any(
            len(target.encode("utf-8")) > width and name == target[:width].casefold() for target in known):
        return "alias31" if width == 31 else "alias15"
    if name and raw.isascii() and any(target.casefold().startswith(name) for target in known):
        return "prefixOnly"
    return "ambiguous"


def launcher_path_errno(number):
    import errno
    for symbol in ("ENOENT", "ESRCH", "EPERM", "EACCES"):
        if number == getattr(errno, symbol):
            return symbol
    return "zero" if number == 0 else "other" if isinstance(number, int) else "unknown"


def launcher_post_path_failure(lib, pid, first, paths, pass_label, observation, native_errno):
    original = launcher_guard_projection(dict(observation), Rejected())
    event = {"pass": pass_label, "postState": "notRead", "nameMatchKind": launcher_name_match_kind(first, paths),
             "pathErrno": launcher_path_errno(native_errno), "pathFailure": original}
    observation["_pathFailure"] = event
    post_observation, post_identity = {}, {}
    post, caught = None, None
    try:
        post = launcher_read_metadata(lib, pid, post_observation, identity_observation=post_identity)
    except Exception as error:
        caught = error  # Classified below; no error text or partial metadata is serialized.
    identity = lambda value: (value["pid"], value["uid"], value["start"])
    if post is not None:
        launcher_process_note(observation, "pathUnavailable", instanceChecked=True)
        if post["status"] == 5:
            observation["_process"]["zombieObserved"] = True
    if post_identity and identity(first) != identity(post_identity):
        event["postState"] = "instanceChanged"
        launcher_process_note(observation, "pathUnavailable", instanceChanged=True)
    elif post is not None and post["status"] == 5:
        event["postState"] = "zombieSame"
        launcher_process_note(observation, "zombieExcluded", zombieObserved=True, zombieExcluded=True)
        return True
    elif post is not None:
        event["postState"] = "liveSame" if first == post else "classificationChanged"
    elif post_observation.get("errnoKind") == "permissionDenied":
        event["postState"] = "permissionDenied"
    elif post_observation.get("apiOutcome") == "returned" and post_observation.get("apiReturn") == "zero":
        event["postState"] = "unavailable"
    elif isinstance(caught, (Rejected, ValueError)):
        event["postState"] = "invalid"
    else:
        event["postState"] = "unknown"
    require(False)  # Preserve the original path failure; no path retry, list reread or fallback.


def launcher_pid_classification(lib, libc, pid, paths, commands, open_paths, observation, first, pass_label):
    import ctypes
    launcher_guard_mark(observation, "snapshot-path")
    launcher_process_note(observation, "pathUnavailable")
    buffer = ctypes.create_string_buffer(4096)
    native_result = {}
    returned = launcher_guard_api(observation, lib.proc_pidpath, pid, buffer, len(buffer), native_result=native_result)
    if returned <= 0:
        if launcher_post_path_failure(lib, pid, first, paths, pass_label, observation, native_result.get("errno")):
            return None  # This same instance is positively observed as zombie, not a successful path lookup.
    executable = os.fsdecode(buffer.value)
    if executable in paths:
        launcher_process_note(observation, "targetHost", conflictObserved=True)
        launcher_guard_mark(observation, "snapshot-classification")
        require(False)
    arguments = None
    if executable in open_paths:
        launcher_process_note(observation, "argsUnavailable")
        mib = (ctypes.c_int * 3)(1, 49, pid)
        length = ctypes.c_size_t(0)
        launcher_guard_mark(observation, "snapshot-args-size")
        require(launcher_guard_api(observation, libc.sysctl, mib, 3, None, ctypes.byref(length), None, 0,
                                   zero_success=True) == 0)
        require(0 < length.value <= 1024 * 1024)
        data = ctypes.create_string_buffer(length.value)
        launcher_guard_mark(observation, "snapshot-args-read")
        require(launcher_guard_api(observation, libc.sysctl, mib, 3, data, ctypes.byref(length), None, 0,
                                   zero_success=True) == 0 and length.value <= len(data))
        launcher_guard_mark(observation, "snapshot-args-decode")
        arguments = launcher_open_arguments(data.raw[:length.value])
        if arguments in commands:
            launcher_process_note(observation, "targetOpen", conflictObserved=True)
            launcher_guard_mark(observation, "snapshot-classification")
            require(False)
    return executable, arguments


def launcher_process_snapshot(paths, commands, observation=None):
    """Bounded own-UID observation, not an atomic or historically complete process inventory."""
    import ctypes
    observation = {} if observation is None else observation
    observation["_process"] = launcher_process_defaults()
    launcher_guard_mark(observation, "snapshot-platform")
    require(platform.system() == "Darwin")
    launcher_guard_mark(observation, "snapshot-library")
    lib = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
    libc = ctypes.CDLL(None, use_errno=True)
    lib.proc_listpids.argtypes = (ctypes.c_uint32, ctypes.c_uint32, ctypes.c_void_p, ctypes.c_int)
    lib.proc_listpids.restype = ctypes.c_int
    lib.proc_pidinfo.argtypes = (ctypes.c_int, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_int)
    lib.proc_pidinfo.restype = ctypes.c_int
    lib.proc_pidpath.argtypes = (ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32)
    lib.proc_pidpath.restype = ctypes.c_int
    libc.sysctl.argtypes = (ctypes.POINTER(ctypes.c_int), ctypes.c_uint, ctypes.c_void_p,
                           ctypes.POINTER(ctypes.c_size_t), ctypes.c_void_p, ctypes.c_size_t)
    libc.sysctl.restype = ctypes.c_int
    launcher_guard_mark(observation, "snapshot-list-size")
    size = launcher_guard_api(observation, lib.proc_listpids, 4, os.getuid(), None, 0)
    require(size > 0)
    slots = size // ctypes.sizeof(ctypes.c_int) + 32
    pids = (ctypes.c_int * slots)()
    launcher_guard_mark(observation, "snapshot-list-read")
    used = launcher_guard_api(observation, lib.proc_listpids, 4, os.getuid(), pids, ctypes.sizeof(pids))
    require(0 < used < ctypes.sizeof(pids) and used % ctypes.sizeof(ctypes.c_int) == 0)
    launcher_guard_mark(observation, "snapshot-open-path")
    open_paths = {"/usr/bin/open", str(Path("/usr/bin/open").resolve(strict=True))}
    try:
        for pid in pids[:used // ctypes.sizeof(ctypes.c_int)]:
            if pid <= 0:
                continue
            first = launcher_read_metadata(lib, pid, observation)
            if first["status"] == 5:
                launcher_process_note(observation, "zombieExcluded", zombieObserved=True, zombieExcluded=True)
                continue
            if not launcher_name_candidate(first["name"], paths):
                launcher_process_note(observation, "noncandidate", noncandidateExcluded=True)
                continue
            before = launcher_pid_classification(lib, libc, pid, paths, commands, open_paths, observation, first, "first")
            if before is None:
                continue
            after = launcher_pid_classification(lib, libc, pid, paths, commands, open_paths, observation, first, "second")
            if after is None:
                continue
            launcher_guard_mark(observation, "snapshot-classification")
            launcher_process_note(observation, "classificationChanged")
            require(before == after)
            second = launcher_read_metadata(lib, pid, observation, "snapshot-instance")
            identity = lambda value: (value["pid"], value["uid"], value["start"])
            launcher_process_note(observation, "instanceChanged", instanceChecked=True)
            if identity(first) != identity(second):
                launcher_process_note(observation, "instanceChanged", instanceChanged=True)
                require(False)
            launcher_process_note(observation, "classificationChanged")
            require(first == second)
            launcher_process_note(observation, "candidateOther", instanceChecked=True)
    except Exception:
        if observation.get("errnoKind") == "permissionDenied":
            launcher_process_note(observation, "permissionDenied")
        raise
    observation["_process"]["checksFinished"] = True
    return []  # Any observed real conflict has already stopped this invocation.


def launcher_process_state(paths, commands, observation=None):
    snapshot = launcher_process_snapshot(paths, commands, observation)
    matching_apps = sum(executable in paths for executable, _ in snapshot)
    matching_open = sum(executable == "/usr/bin/open" and arguments in commands
                        for executable, arguments in snapshot)
    return {"processCheckComplete": True, "matchingAppCount": matching_apps,
            "legacyWorkerSettled": matching_open == 0}  # Current absence only, never historical settlement.


def launcher_context(manifest_file, manifest_sha):
    root, manifest, legacy = diagnostic_context(manifest_file, manifest_sha)
    launcher_owned(root, root, directory=True)
    require(manifest["purpose"] == "diagnostic-only" and manifest["binarySHA256"] == LAUNCHER_PINS["binarySHA256"])
    for leaf, expected in LAUNCHER_PINS.items():
        if leaf != "binarySHA256":
            path = launcher_owned(root, root / leaf)
            require(digest(path.read_bytes()) == expected)
    require(manifest_sha == LAUNCHER_PINS["diagnostic.json"])
    machine = load(root / "build.machine.json")
    human = load(root / "build.human.json")
    require(machine.get("status") == "success" and machine.get("stage") == "completed"
            and machine.get("buildVerified") is True)
    validate_observation(human, manifest["diagnosticUUID"], "host-build-sign", LAUNCHER_PINS["build.machine.json"])
    require(human["wholeStageObserved"] and human["promptCount"] is not None)
    ready = load(launcher_owned(root, root / "diagnostic.ready.json"))
    used = load(root / "diagnostic.consumed-ready.json")
    require(used.get("diagnosticUUID") == manifest["diagnosticUUID"]
            and used.get("purpose") == "diagnostic-only" and used.get("readyUUID") == ready.get("readyUUID")
            and used.get("readySHA256") == digest((root / "diagnostic.ready.json").read_bytes()))
    return root, manifest, legacy, ready


def launcher_spawn(command, output, error):
    return subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=output, stderr=error)


def launcher_receipt(root, manifest, manifest_sha):
    path = root / "diagnostic.machine.json"
    try:
        info = path.lstat()
    except FileNotFoundError:
        return False, "absent", None
    except OSError:
        return None, "unreadable", None
    try:
        require(stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid())
        launcher_owned(root, path)
        raw = path.read_bytes()
    except (Rejected, OSError):
        return None, "unreadable", None
    sha = digest(raw)
    try:
        value = json.loads(raw)
        require(value == diagnostic_projection(value)
                and value["diagnosticUUID"] == manifest["diagnosticUUID"]
                and value["legacyRunUUID"] == RETRY_PINS["runUUID"]
                and value["purpose"] == "diagnostic-only"
                and value.get("manifestSHA256") == manifest_sha
                and value.get("binarySHA256") == manifest["binarySHA256"])
        return True, "valid", sha
    except (Rejected, ValueError, KeyError, TypeError, AttributeError):
        return True, "invalid", sha


def launcher_amendment(manifest_file, manifest_sha, ready_uuid, ready_confirmed, observation=None):
    launcher_guard_mark(observation, "context")
    root, manifest, legacy, old_ready = launcher_context(manifest_file, manifest_sha)
    launcher_guard_mark(observation, "ready")
    require(ready_confirmed is True)
    validate_namespace(ready_uuid, service(ready_uuid))
    require(ready_uuid != old_ready["readyUUID"])
    directory = root / LAUNCHER_ATTEMPT
    launcher_guard_mark(observation, "quota")
    require(not os.path.lexists(directory) and not os.path.lexists(root / "diagnostic.machine.json"))
    launcher_guard_mark(observation, "request")
    request = private_owned(legacy, legacy / "private/save-a.request.json")
    require(request.is_file())
    request_sha = digest(request.read_bytes())
    known_commands = [launch_command(legacy / "current/CredentialStorageProbe.app", request, request_sha),
                      ["/usr/bin/open", "-W", "-a", manifest["expectedApp"],
                       "--env", "RIVET_DIAGNOSTIC_MANIFEST=" + str(root / "diagnostic.json"),
                       "--env", "RIVET_DIAGNOSTIC_SHA256=" + manifest_sha,
                       "--args", "--request", str(request), "--request-sha", request_sha]]
    launcher_guard_mark(observation, "snapshot-platform")
    state = launcher_process_state({str(Path(manifest["expectedApp"]) / "Contents/MacOS/CredentialStorageProbe"),
                                    str(legacy / "current/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe")},
                                   known_commands, observation)
    launcher_guard_mark(observation, "snapshot-match")
    require(state == {"processCheckComplete": True, "matchingAppCount": 0, "legacyWorkerSettled": True})
    launcher_guard_mark(observation, "caller-source")
    actual_runner_sha = digest(Path(__file__).read_bytes())
    launcher_guard_mark(observation, "output")
    directory.mkdir(mode=0o700)  # Exclusive; existence/partial is permanently spent.
    launcher_owned(root, directory, directory=True)
    if observation is not None:
        observation["_trusted"] = True
    command = ["/usr/bin/open", "-W", "-a", manifest["expectedApp"],
               "--env", "RIVET_DIAGNOSTIC_MANIFEST=" + str(root / "diagnostic.json"),
               "--env", "RIVET_DIAGNOSTIC_SHA256=" + manifest_sha,
               "--args", "--launcher-amendment-only"]
    machine = {"schemaVersion": 1, "diagnosticUUID": manifest["diagnosticUUID"],
               "attempt": LAUNCHER_ATTEMPT, "purpose": "launcher-only", "manifestSHA256": manifest_sha,
               "binarySHA256": manifest["binarySHA256"], "runnerSHA256": actual_runner_sha,
               "attemptSHA256": None, "readySHA256": None,
               "originalConsumedSHA256": LAUNCHER_PINS["diagnostic.consumed-ready.json"], "status": "unknown",
               "stage": "consume", "spawnAttempted": False, "nativeSpawned": False, "nativePID": None,
               "nativeReturnCode": None, "nativeSignal": None, "nativeSettled": False, "exceptionKind": None,
               "timedOut": False, "appReceiptPresent": None, "appReceiptValidity": "unchecked",
               "appReceiptSHA256": None, "appReceiptAttributable": False, "hostConfirmed": False}
    primary_sha = caller_sha = None
    write_failed = False
    try:
        launcher_flush_directory(root)
        attempt = {key: machine[key] for key in ("schemaVersion", "diagnosticUUID", "attempt", "purpose",
                   "manifestSHA256", "binarySHA256", "runnerSHA256", "originalConsumedSHA256")}
        attempt.update(command=command, **state)
        machine["attemptSHA256"] = launcher_write(directory / "attempt.json", attempt)
        ready = {"schemaVersion": 1, "diagnosticUUID": manifest["diagnosticUUID"], "attempt": LAUNCHER_ATTEMPT,
                 "purpose": "launcher-only", "ready": True, "readyUUID": ready_uuid}
        machine["readySHA256"] = launcher_write(directory / "ready.json", ready)
        launcher_write(directory / "consumed-ready.json", {"schemaVersion": 1,
                       "diagnosticUUID": manifest["diagnosticUUID"], "attempt": LAUNCHER_ATTEMPT,
                       "readyUUID": ready_uuid, "readySHA256": machine["readySHA256"],
                       "attemptSHA256": machine["attemptSHA256"]})
        machine["stage"] = "log-open"
        descriptors = []
        try:
            for leaf in ("launch.stdout", "launch.stderr"):
                fd = os.open(directory / leaf, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
                descriptors.append(os.fdopen(fd, "wb"))
            launcher_flush_directory(directory)
            machine["stage"], machine["spawnAttempted"] = "spawn", True
            child = launcher_spawn(command, *descriptors)
            machine.update(nativeSpawned=True, nativePID=child.pid, stage="wait")
            result = child.wait(timeout=LAUNCHER_WAIT_SECONDS)  # Popen.wait does not kill on timeout.
            require(type(result) is int)
            machine.update(nativeReturnCode=result, nativeSignal=-result if result < 0 else None,
                           nativeSettled=True, stage="receipt-check")
        finally:
            for stream in descriptors:
                try:
                    stream.flush()
                    os.fsync(stream.fileno())
                finally:
                    stream.close()
    except subprocess.TimeoutExpired:
        machine["timedOut"] = True
    except KeyboardInterrupt:
        machine["exceptionKind"] = "interrupted"
    except OSError:
        machine["exceptionKind"] = "spawnOS" if machine["stage"] == "spawn" else "waitOS" if machine["stage"] == "wait" else "guard"
    except subprocess.SubprocessError:
        machine["exceptionKind"] = "subprocess"
    except (Rejected, ValueError, KeyError, TypeError):
        machine["exceptionKind"] = "guard"
    except Exception:
        machine["exceptionKind"] = "other"
    finally:
        present, validity, sha = launcher_receipt(root, manifest, manifest_sha)
        machine.update(appReceiptPresent=present, appReceiptValidity=validity, appReceiptSHA256=sha)
        if machine["nativeSettled"] and machine["exceptionKind"] is None:
            machine["stage"] = "completed"
        try:
            primary_sha = launcher_publish(directory / "launcher.machine.json", machine)
        except (OSError, Rejected, ValueError, TypeError):
            write_failed = True
        caller = {"schemaVersion": 1, "diagnosticUUID": manifest["diagnosticUUID"],
                  "attempt": LAUNCHER_ATTEMPT, "purpose": "launcher-only", "status": "unknown",
                  "primaryReceiptWritten": primary_sha is not None, "primaryMachineSHA256": primary_sha,
                  "failureKind": "receiptWrite" if write_failed else None,
                  "humanBinding": "primary" if primary_sha is not None else "caller-result"}
        try:
            caller_sha = launcher_publish(directory / "caller-result.json", caller)
        except (OSError, Rejected, ValueError, TypeError):
            write_failed = True
    return {"status": "unknown", "failureKind": "receiptWrite" if write_failed else None,
            "primaryReceiptWritten": primary_sha is not None, "callerResultWritten": caller_sha is not None,
            "bindingReceiptSHA256": primary_sha if primary_sha is not None else caller_sha}, 2 if write_failed else 1


def launcher_amendment_observe(manifest_file, manifest_sha, binding_sha, prompt_count, actions, whole):
    root, manifest, _, _ = launcher_context(manifest_file, manifest_sha)
    directory = launcher_owned(root, root / LAUNCHER_ATTEMPT, directory=True)
    primary = launcher_publication(root, directory / "launcher.machine.json")
    caller = launcher_publication(root, directory / "caller-result.json")
    require(primary is not None or caller is not None)
    if primary is not None:
        value, primary_sha = primary
        require(set(value) == LAUNCHER_MACHINE_KEYS
                and type(value["schemaVersion"]) is int and value["schemaVersion"] == 1
                and value["diagnosticUUID"] == manifest["diagnosticUUID"]
                and value["attempt"] == LAUNCHER_ATTEMPT and value["purpose"] == "launcher-only"
                and value["status"] == "unknown" and value["manifestSHA256"] == manifest_sha
                and value["binarySHA256"] == manifest["binarySHA256"]
                and value["hostConfirmed"] is False and value["appReceiptAttributable"] is False)
    if caller is not None:
        result, _ = caller
        require(set(result) == {"schemaVersion", "diagnosticUUID", "attempt", "purpose", "status",
                               "primaryReceiptWritten", "primaryMachineSHA256", "failureKind", "humanBinding"}
                and type(result["schemaVersion"]) is int and result["schemaVersion"] == 1
                and result["diagnosticUUID"] == manifest["diagnosticUUID"]
                and result["attempt"] == LAUNCHER_ATTEMPT and result["purpose"] == "launcher-only"
                and result["status"] == "unknown")
        if result["primaryReceiptWritten"] is True:
            require(primary is not None and result["humanBinding"] == "primary"
                    and result["failureKind"] is None and result["primaryMachineSHA256"] == primary[1])
        else:
            require(result["primaryReceiptWritten"] is False and primary is None
                    and result["humanBinding"] == "caller-result" and result["primaryMachineSHA256"] is None
                    and result["failureKind"] == "receiptWrite")
    value, actual_sha = primary if primary is not None else caller
    kind = "primary" if primary is not None else "caller-result"
    require(binding_sha == actual_sha)
    count = None if prompt_count == "unknown" else int(prompt_count)
    observation = {"runUUID": manifest["diagnosticUUID"], "phase": "launcher-only", "machineSHA256": actual_sha,
                   "promptCount": count, "actions": actions.split(","), "wholeStageObserved": whole == "yes"}
    validate_observation(observation, manifest["diagnosticUUID"], "launcher-only", actual_sha)
    human = {"schemaVersion": 1, "diagnosticUUID": manifest["diagnosticUUID"], "attempt": LAUNCHER_ATTEMPT,
             "purpose": "launcher-only", "bindingKind": kind, "bindingReceiptSHA256": actual_sha,
             "promptCount": count, "actions": observation["actions"], "wholeStageObserved": observation["wholeStageObserved"]}
    launcher_write(directory / "launcher.human.json", human)
    return {"status": "unknown", "failureKind": None, "primaryReceiptWritten": kind == "primary",
            "callerResultWritten": caller is not None, "bindingReceiptSHA256": actual_sha}, 1


# Launch-report binding is independent of legacy credential contexts and capabilities.
BINDING_PURPOSE = "launch-report-only"
BINDING_SOURCES = tuple(dict.fromkeys((*PROJECT_FILES, "scripts/credential_storage_live.py", "Tests/test_live_protocol.py", "README.md")))
BINDING_KEYS = {"schemaVersion", "purpose", "attemptUUID", "contextSHA256", "requestSHA256", "expectedBinarySHA256"}
BINDING_BOOLS = {"hostAttributed", "bindingMatched", "liveInstanceVerified", "binaryVerified", "nativeSettled"}
BINDING_HASHES = ("requestSHA256", "reportSHA256", "ackSHA256", "finalSHA256", "machineSHA256", "entrySHA256", "failureSHA256")
BINDING_STAGES = {"preflight", "consume", "spawn", "report", "instance", "ack", "final", "settle", "publish"}
BINDING_FAILURES = {"none", "input", "context", "binary", "signature", "instance", "replay", "path", "missing", "timeout", "write", "native", "other"}
BINDING_MACHINE_EXTRA = {"readyUUID", "runnerSHA256", "consumedSHA256", "evidenceMode", "stage", "outcome", "failureKind",
    *BINDING_BOOLS, "nativeReturnKind", "spawnAttempted", "nativePID", "nativeReturnCode", "nativeSignal", "nativeExceptionKind",
    "reportSHA256", "ackSHA256", "finalSHA256", "entrySHA256", "failureSHA256", "appOutput"}
BINDING_PUBLICATIONS = {leaf: leaf.replace(".json", ".pending.json") for leaf in
                       ("host.entry.json", "host.failure.json", "host.report.json", "ack.json", "host.final.json", "launcher.machine.json")}


BINDING_CERTIFICATE_SHA256 = "5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440"
BINDING_PROOF_COMMON = {"schemaVersion", "purpose", "variant", "evidenceMode"}


def binding_validate_proof(kind, value, mode):
    dpk = value.get("purpose") == DPK_PURPOSE if type(value) is dict else False
    fields = {
        "build": {"sourceHashes", "compileConditions", "scheme", "configuration", "commandSHA256", "unsignedBinarySHA256", "buildSucceeded"},
        "signing": {"buildProofSHA256", "binarySHA256", "certificateDER_SHA256", "teamIdentifierSHA256", "bundleIdentifierSHA256", "codeIdentifierSHA256", "designatedRequirementSHA256", "entitlementsEmpty", "embeddedProfilePresent", "signatureValid", "certificateValidNow"},
    }
    if dpk and "authoritySHA256" in value: fields[kind] |= {"authoritySHA256"}
    if dpk: fields["signing"] |= {"profileSHA256", "entitlementsSHA256", "groupSHA256"}
    require(kind in fields and type(value) is dict and set(value) == BINDING_PROOF_COMMON | fields[kind])
    require(type(value["schemaVersion"]) is int and value["schemaVersion"] == 1)
    require(value["purpose"] == (DPK_PURPOSE if dpk else BINDING_PURPOSE) and value["variant"] == ("dpk-entitled" if dpk else "profile-free"))
    require(mode in ("signed-host", "fake-only") and value["evidenceMode"] == mode)
    for key, item in value.items():
        if key.endswith("SHA256"): require(type(item) is str and is_hash(item))
    if kind == "build":
        require(type(value["sourceHashes"]) is dict and set(value["sourceHashes"]) == set(BINDING_SOURCES))
        require(all(type(item) is str and is_hash(item) for item in value["sourceHashes"].values()))
        require(type(value["compileConditions"]) is list and value["compileConditions"] == (["DEBUG", "DPK_VALIDATION_ONLY"] + (["CREDENTIAL_STORAGE_REBUILT"] if value["configuration"] == "Rebuilt" else []) if dpk else ["DEBUG", "LAUNCH_REPORT_ONLY"]))
        require((value["scheme"], value["configuration"]) in (("CredentialStorageProbe", "Debug"), ("CredentialStorageProbeRebuilt", "Rebuilt")) if dpk else value["scheme"] == "CredentialStorageProbe" and value["configuration"] == "Debug")
        require(type(value["buildSucceeded"]) is bool and value["buildSucceeded"] is True)
    else:
        require(value["certificateDER_SHA256"] == BINDING_CERTIFICATE_SHA256)
        require(type(value["entitlementsEmpty"]) is bool and value["entitlementsEmpty"] is (not dpk))
        for key in ("signatureValid", "certificateValidNow"):
            require(type(value[key]) is bool and value[key] is True)
        require(type(value["embeddedProfilePresent"]) is bool and value["embeddedProfilePresent"] is dpk)
    return value


def binding_profile_free_proofs(root, context, mode, phase=None):
    prefix = "rebuild." if phase == "rebuilt-read-b" else ""
    build, build_sha = binding_read(root, root / (prefix + "build.machine.json"))
    signing, signing_sha = binding_read(root, root / (prefix + "signing.machine.json"))
    binding_validate_proof("build", build, mode)
    binding_validate_proof("signing", signing, mode)
    if "authoritySHA256" in context:
        require(build.get("authoritySHA256") == signing.get("authoritySHA256") == context["authoritySHA256"])
    else: require("authoritySHA256" not in build and "authoritySHA256" not in signing)
    require(build_sha == context["buildProofSHA256"] == signing["buildProofSHA256"])
    require(signing_sha == context["signingProofSHA256"])
    require(build["sourceHashes"] == context["sourceHashes"])
    require(signing["binarySHA256"] == context["expectedBinarySHA256"])
    return signing


def binding_code_command(command, timeout):
    require(timeout > 0)
    result = subprocess.run(command, stdin=subprocess.DEVNULL, capture_output=True, timeout=timeout)
    require(result.returncode == 0)
    return result.stdout, result.stderr


def binding_preparation_evidence():
    return dict(guardPoint="derPin", decoderPart="none", decoderOutcome="notStarted", decoderReturnCode=None,
                subjectOUCount="unknown", derPinned=None, subjectValid=None, dateValid=None, classValid=None)


def binding_certificate_arguments(part):
    require(part in ("subject", "dates", "class"))
    options = {"subject": ["-subject", "-nameopt", "RFC2253"], "dates": ["-dates"],
               "class": ["-text", "-nameopt", "RFC2253"]}
    return ["/usr/bin/openssl", "x509", "-inform", "DER", "-noout", *options[part]]


def binding_certificate_text(der, part, *, evidence=None, run=None, window=None, phase=None):
    # Public DER only. All three independent outputs consume the same already pinned bytes.
    evidence = evidence if evidence is not None else binding_preparation_evidence()
    evidence.update(guardPoint=part + "Decode", decoderPart=part, decoderOutcome="notStarted", decoderReturnCode=None)
    try:
        def invoke(arguments,timeout):
            return (run or subprocess.run)(arguments,input=der,capture_output=True,
                timeout=timeout,env={"LC_ALL":"C","OPENSSL_CONF":"/dev/null"})
        arguments=binding_certificate_arguments(part)
        result = window.native(invoke,arguments,10,phase=phase) if window is not None else invoke(arguments,10)
    except subprocess.TimeoutExpired:
        evidence["decoderOutcome"] = "timeout"
        raise
    except Exception:
        evidence["decoderOutcome"] = "exception"
        raise  # Keep the actual native exception private; never replace it with a guessed cause.
    if type(result.returncode) is not int:
        evidence["decoderOutcome"] = "unknown"
        raise Rejected()
    evidence.update(decoderReturnCode=result.returncode,
                    decoderOutcome="zero" if result.returncode == 0 else "signal" if result.returncode < 0 else "nonzero")
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, result.args, output=result.stdout, stderr=result.stderr)
    try:
        return result.stdout.decode("utf-8", errors="strict")
    except (UnicodeError, AttributeError):
        evidence["decoderOutcome"] = "decodeInvalid"
        raise


def binding_subject_team(subject, evidence):
    require(type(subject) is str)
    line = subject[:-1] if subject.endswith("\n") else subject
    require("\n" not in line and "\r" not in line and line.startswith("subject="))
    name = line[len("subject="):]
    if name.startswith(" "): name = name[1:]  # OpenSSL's optional label separator, not an RDN value space.
    require(bool(name))
    # Split only unescaped RFC2253 RDN separators. Keep escapes for strict UTF-8 decoding below.
    attributes, start, i = [], 0, 0
    while i < len(name):
        char = name[i]
        if char == "\\":
            require(i + 1 < len(name))
            if name[i + 1] in "0123456789abcdefABCDEF":
                require(i + 2 < len(name) and name[i + 2] in "0123456789abcdefABCDEF")
                i += 3
            else:
                require(name[i + 1] in ' ,=+<>#;"\\')
                i += 2
            continue
        require(char not in '+"<>;\x00')  # No multi-valued RDNs, quoted legacy names, or controls.
        if char == ",":
            attributes.append(name[start:i]); start = i + 1
        i += 1
    attributes.append(name[start:])
    values = []
    for attribute in attributes:
        key, separator, value = attribute.partition("=")
        require(separator == "=" and re.fullmatch(r"(?:[A-Za-z][A-Za-z0-9]*|[0-9]+(?:\.[0-9]+)+)", key) is not None)
        require(bool(value) and not value.startswith((" ", "#")))
        data, index, last_escaped = bytearray(), 0, False
        while index < len(value):
            char = value[index]
            if char == "\\":
                escaped = value[index + 1]
                if escaped in "0123456789abcdefABCDEF":
                    data.append(int(value[index + 1:index + 3], 16)); index += 3
                else:
                    data.extend(escaped.encode("utf-8")); index += 2
                last_escaped = True
            else:
                require(char not in '=+"<>;\x00' and ord(char) >= 32 and ord(char) != 127)
                data.extend(char.encode("utf-8")); index += 1; last_escaped = False
        require(not value.endswith(" ") or last_escaped)
        decoded = data.decode("utf-8", errors="strict")
        require(all(ord(char) >= 32 and ord(char) != 127 for char in decoded))
        if key in ("OU", "2.5.4.11"): values.append(decoded)
    evidence["subjectOUCount"] = "zero" if not values else "one" if len(values) == 1 else "multiple"
    require(len(values) == 1 and re.fullmatch(r"[A-Z0-9]+", values[0]) is not None)
    return values[0]


def binding_certificate_team(der, *, decode=None, evidence=None, window=None, phase=None):
    evidence = evidence if evidence is not None else binding_preparation_evidence()
    evidence["guardPoint"] = "derPin"
    evidence["derPinned"] = type(der) is bytes and digest(der) == BINDING_CERTIFICATE_SHA256
    require(evidence["derPinned"])
    if decode is None:
        def decode(raw,part,*,evidence):
            return binding_certificate_text(raw,part,evidence=evidence,window=window,phase=phase)
    if window is not None:
        raw_decode=decode
        def decode(raw,part,*,evidence):
            window.check(phase=phase,reserve=15)
            result=raw_decode(raw,part,evidence=evidence)
            window.check(phase=phase)
            return result
    subject = decode(der, "subject", evidence=evidence)
    evidence.update(guardPoint="subjectParse", subjectValid=False)
    team = binding_subject_team(subject, evidence)
    evidence["subjectValid"] = True
    dates = decode(der, "dates", evidence=evidence)
    evidence.update(guardPoint="datesParse", dateValid=False)
    require(type(dates) is str)
    lines = dates.splitlines()
    require(len(lines) == 2 and all(line.count("=") == 1 for line in lines))
    pairs = [line.split("=", 1) for line in lines]
    require({key for key, _ in pairs} == {"notBefore", "notAfter"})
    values = dict(pairs)
    before, after = (dt.datetime.strptime(values[key], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=dt.timezone.utc)
                     for key in ("notBefore", "notAfter"))
    require(before <= dt.datetime.now(dt.timezone.utc) < after)
    evidence["dateValid"] = True
    certificate = decode(der, "class", evidence=evidence)
    evidence.update(guardPoint="classParse", classValid=False)
    require(type(certificate) is str and re.search(
        r"(?m)^[ \t]*X509v3 Extended Key Usage:(?:[ \t]*critical)?[ \t]*\n[ \t]+[^\n]*\bCode Signing\b", certificate) is not None)
    for oid in ("1.2.840.113635.100.6.1.2", "1.2.840.113635.100.6.1.12"):
        require(re.search(r"(?<![0-9.])" + re.escape(oid) + r"(?![0-9.])", certificate) is not None)
    evidence["classValid"] = True
    if window is not None:window.check(phase=phase)
    return team

def binding_original_certificate(keychain, *, query=binding_code_command):
    """FUTURE AUTHORIZED WINDOW ONLY: public certificate query can request Keychain authorization."""
    import base64
    keychain = Path(keychain)
    launcher_ancestors(keychain)
    require(keychain.name == "login.keychain-db" and keychain.parent.name == "Keychains")
    require(keychain.is_file() and keychain.stat().st_uid == os.getuid())
    # The selected original certificate family only, in the explicitly selected login keychain.
    out, _ = query(["/usr/bin/security", "find-certificate", "-a", "-c", "Apple Development", "-p", str(keychain)], 30)
    found = set()
    for body in re.findall(rb"-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END CERTIFICATE-----", out, re.S):
        der = base64.b64decode(re.sub(rb"\s+", b"", body), validate=True)
        if digest(der) == BINDING_CERTIFICATE_SHA256: found.add(der)
    require(len(found) == 1)
    return found.pop()  # Memory only. Never print raw certificate names, selectors, or query errors.


def binding_sign_preparation(der, keychain, app, expected_identifier, *, decode=None, evidence=None, window=None, phase=None):
    """Return a private argv; no signing or auth. Pass an evidence dict to retain a rejected preparation."""
    evidence = evidence if evidence is not None else {}
    require(type(evidence) is dict)
    evidence.clear(); evidence.update(binding_preparation_evidence())
    team = binding_certificate_team(der, decode=decode, evidence=evidence,window=window,phase=phase)
    app, keychain = Path(app), Path(keychain)
    evidence["guardPoint"] = "keychainPath"
    launcher_ancestors(keychain)
    require(keychain.name == "login.keychain-db" and keychain.parent.name == "Keychains")
    require(keychain.is_file() and keychain.stat().st_uid == os.getuid())
    evidence["guardPoint"] = "appPath"
    launcher_ancestors(app)
    require(app.suffix == ".app" and app.stat().st_uid == os.getuid())
    evidence["guardPoint"] = "profileAbsent"
    require(not os.path.lexists(app / "Contents/embedded.provisionprofile"))
    evidence["guardPoint"] = "infoBundle"
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    require(type(info) is dict and info.get("CFBundleIdentifier") == expected_identifier and type(expected_identifier) is str and bool(expected_identifier))
    evidence["guardPoint"] = "infoExecutable"
    require(info.get("CFBundleExecutable") == "CredentialStorageProbe")
    selector = hashlib.sha1(der).hexdigest()
    if window is not None:window.check(phase=phase)
    evidence["guardPoint"] = "prepared"
    return dict(certificateDER_SHA256=digest(der), certificateSHA1=selector, preparation=dict(evidence),
                teamIdentifierSHA256=digest(team.encode()), bundleIdentifierSHA256=digest(expected_identifier.encode()),
                signCommand=["/usr/bin/codesign", "--force", "--sign", selector, "--keychain", str(keychain),
                             "--options", "runtime", "--identifier", expected_identifier, str(app)])


def binding_code_identity(target, *, command=binding_code_command, timeout=30, expected_entitlements=None, window=None, phase=None):
    """Read/verify only the already selected app or exact reported PID; no Keychain search/signing."""
    import tempfile
    deadline = __import__("time").monotonic() + timeout
    def call(arguments):
        remaining = deadline - __import__("time").monotonic()
        require(remaining > 0)
        return window.native(command,arguments,remaining,phase=phase) if window is not None else command(arguments,remaining)
    selected = str(target)
    call(["/usr/bin/codesign", "--verify", "--strict", "-v", selected])
    out, err = call(["/usr/bin/codesign", "-d", "--verbose=4", selected])
    details = (out + b"\n" + err).decode("utf-8", errors="strict")
    require("Signature=adhoc" not in details)
    def detail(key):
        found = re.findall(r"^" + re.escape(key) + r"=(.+)$", details, re.M)
        require(len(found) == 1 and bool(found[0]))
        return found[0]
    identifier, team = detail("Identifier"), detail("TeamIdentifier")
    require(team != "not set")
    out, err = call(["/usr/bin/codesign", "-d", "--entitlements", "-", "--xml", selected])
    # An absent entitlement blob is represented by empty stdout, never by swallowing a failed command.
    entitlements = plistlib.loads(out) if out.strip() else {}
    require(type(entitlements) is dict and (not entitlements if expected_entitlements is None else entitlements == expected_entitlements))
    out, err = call(["/usr/bin/codesign", "-d", "-r-", selected])
    requirement = designated_requirement(out + b"\n" + err)
    canonical, _ = call(["/usr/bin/csreq", "-r=" + requirement, "-t"])
    canonical = canonical.strip()
    require(bool(canonical) and len(canonical.decode("utf-8").splitlines()) == 1)
    # Public DER only; owned ordinary inspection scratch is separate from the immutable context.
    with tempfile.TemporaryDirectory(prefix="rivet-binding-inspect-") as temporary:
        prefix = Path(temporary) / "certificate"
        call(["/usr/bin/codesign", "-d", "--extract-certificates=" + str(prefix), selected])
        leaf = Path(str(prefix) + "0")
        require(leaf.is_file() and not leaf.is_symlink())
        cert = leaf.read_bytes()
        require(digest(cert) == BINDING_CERTIFICATE_SHA256)
        def decode(raw, part, *, evidence):
            def run(arguments, **options):
                require(type(raw) is bytes and digest(raw) == BINDING_CERTIFICATE_SHA256)
                require(arguments == binding_certificate_arguments(part) and type(options["input"]) is bytes
                        and options["input"] == raw)
                remaining = deadline - __import__("time").monotonic()
                require(remaining > 0)
                options["timeout"] = min(options["timeout"], remaining)
                # Preserve the pinned memory bytes at the actual subprocess boundary, not a file reread.
                return subprocess.run(arguments, **options)
            if window is None:return binding_certificate_text(raw,part,evidence=evidence,run=run)
            return binding_certificate_text(raw,part,evidence=evidence,run=run,window=window,phase=phase)
        require(binding_certificate_team(cert, decode=decode,window=window,phase=phase) == team)
    if window is not None:window.check(phase=phase)
    return dict(certificateDER_SHA256=BINDING_CERTIFICATE_SHA256, teamIdentifierSHA256=digest(team.encode()),
                codeIdentifierSHA256=digest(identifier.encode()), designatedRequirementSHA256=digest(canonical))


def binding_verify_static(root, context, binary, *, command=binding_code_command, phase=None, mode="signed-host", window=None):
    if "authoritySHA256" in context:
        require(window is not None and window.sha == context["authoritySHA256"])
    app = binary.parents[2]
    dpk = context["purpose"] == DPK_PURPOSE
    expected = None
    if dpk:
        values, _ = dpk_round(root)
        expected = dpk_entitlements(root, values,window=window)
        require(digest(binding_owned(root, app / "Contents/embedded.provisionprofile", executable=True).read_bytes()) == values["profileSHA256"])
    else:
        require(not os.path.lexists(app / "Contents/embedded.provisionprofile"))
    info_url = binding_owned(root, app / "Contents/Info.plist", executable=True)
    info = plistlib.loads(info_url.read_bytes())
    require(type(info) is dict and info.get("CFBundleExecutable") == "CredentialStorageProbe")
    bundle = info.get("CFBundleIdentifier")
    require(type(bundle) is str and bool(bundle))
    # Expected bundle/code identifier comes from the frozen original target, not the proof's self-claim.
    project = (root / "source" / PROJECT_FILES[0]).read_text()
    identifiers = {v.strip('" ') for v in re.findall(r"PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);", project)}
    require(identifiers == {bundle})
    signing = binding_profile_free_proofs(root, context, mode, phase)
    observed = binding_code_identity(app, command=command, expected_entitlements=expected,window=window,phase=phase)
    require(all(signing[key] == value for key, value in observed.items()))
    if dpk:
        require(signing["entitlementsSHA256"] == digest(plistlib.dumps(expected,sort_keys=True)))
        require(signing["groupSHA256"] == digest(values["group"].encode()) and signing["profileSHA256"] == values["profileSHA256"])
    require(signing["bundleIdentifierSHA256"] == signing["codeIdentifierSHA256"] == digest(bundle.encode()))
    if window is not None:window.check(phase=phase)
    return signing


def binding_verify_process(pid, signing, remaining, *, command=binding_code_command, expected_entitlements=None, window=None, phase=None):
    if "authoritySHA256" in signing:require(window is not None and signing["authoritySHA256"]==window.sha)
    require(type(pid) is int and pid > 0 and remaining > 0)
    observed = binding_code_identity(pid, command=command, timeout=remaining, expected_entitlements=expected_entitlements,window=window,phase=phase)
    require(all(signing[key] == value for key, value in observed.items()))
    if window is not None:window.check(phase=phase)


def binding_uuid(value):
    require(type(value) is str)
    require(str(uuid.UUID(value)) == value and uuid.UUID(value).version == 4)



class BindingHostFailure(Rejected):
    pass


def binding_app_output(root=None, phase=None):
    value = dict(stdoutState="unreadable", stderrState="unreadable", stdoutBytes=None, stderrBytes=None,
                 stdoutSHA256=None, stderrSHA256=None)
    if root is not None:
        for stream in ("stdout", "stderr"):
            try:
                path = binding_owned(root, root / ("phases/" + phase if phase else "attempt") / ("app." + stream))
                size = path.stat().st_size
                value[stream + "Bytes"] = size
                if size > 65536: value[stream + "State"] = "oversize"
                else:
                    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
                    with os.fdopen(fd, "rb") as handle:
                        info = os.fstat(handle.fileno())
                        require(stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) == 0o600)
                        content = handle.read(65537)
                    require(len(content) == size)
                    value[stream + "State"] = "empty" if not content else "bounded"
                    value[stream + "SHA256"] = digest(content)
            except (OSError, Rejected):
                value[stream + "State"] = "unreadable"
                value[stream + "Bytes"] = value[stream + "SHA256"] = None
    return value


def binding_validate_app_output(value):
    require(type(value) is dict and set(value) == {"stdoutState", "stderrState", "stdoutBytes", "stderrBytes", "stdoutSHA256", "stderrSHA256"})
    for stream in ("stdout", "stderr"):
        state, size, sha = (value[stream + suffix] for suffix in ("State", "Bytes", "SHA256"))
        require(state in ("unreadable", "empty", "bounded", "oversize"))
        if state == "unreadable": require(size is None and sha is None)
        else:
            require(type(size) is int and size >= 0)
            if state == "oversize": require(size > 65536 and sha is None)
            else:
                require(type(sha) is str and is_hash(sha) and size <= 65536)
                require((state == "empty" and size == 0 and sha == digest(b"")) or (state == "bounded" and size > 0))


def binding_validate(kind, value, expected=None):
    require(type(value) is dict)
    dpk = value.get("purpose") == DPK_PURPOSE
    bkeys = BINDING_KEYS | ({"roundSHA256", "phase"} if dpk else set())
    keys = {
        "context": {"schemaVersion", "purpose", "contextUUID", "sourceHashes", "expectedBinarySHA256", "buildProofSHA256", "signingProofSHA256"},
        "request": (bkeys - {"requestSHA256"}) | {"createdAtUnixMicroseconds"},
        "entry": bkeys | {"stage", "outcome", "wire", "observedBinarySHA256", "pid", "startSeconds", "startMicroseconds"},
        "failure": bkeys | {"stage", "outcome", "wire", "observedBinarySHA256", "pid", "startSeconds", "startMicroseconds", "failureKind"},
        "report": bkeys | {"observedBinarySHA256", "pid", "startSeconds", "startMicroseconds", "processUUID", "stage", "outcome"},
        "ack": bkeys | {"hostReportSHA256"},
        "final": bkeys | {"hostReportSHA256", "ackSHA256", "outcome"},
        "consume": bkeys | {"readyUUID", "readyConfirmed", "runnerSHA256", "evidenceMode"},
        "machine": bkeys | BINDING_MACHINE_EXTRA,
    }
    if dpk:
        keys["context"] |= {"roundSHA256", "profileSHA256"}
        if "authoritySHA256" in value and kind == "context": keys["context"] |= {"authoritySHA256"}
        keys["final"] |= {"operationResult"}
        keys["machine"] |= {"operationResultSHA256", "operationVerified"}
    require(kind in keys and set(value) == keys[kind])
    require(type(value["schemaVersion"]) is int and value["schemaVersion"] == 1 and value["purpose"] == (DPK_PURPOSE if dpk else BINDING_PURPOSE))
    nullable_hashes = {"reportSHA256", "ackSHA256", "finalSHA256", "entrySHA256", "failureSHA256"} if kind == "machine" else {"observedBinarySHA256"} if kind in ("entry", "failure") else set()
    if dpk and kind != "context": require(value["phase"] in DPK_PHASES)
    if dpk and kind == "machine": nullable_hashes |= {"operationResultSHA256"}
    for key, item in value.items():
        if key.endswith("SHA256"):
            require((item is None and key in nullable_hashes) or (type(item) is str and is_hash(item)))
        if key.endswith("UUID"):
            binding_uuid(item)
    if expected is not None:
        require(all(key in value and value[key] == item for key, item in expected.items()))
    if kind == "context":
        require(type(value["sourceHashes"]) is dict and set(value["sourceHashes"]) == set(BINDING_SOURCES))
        require(all(type(v) is str and is_hash(v) for v in value["sourceHashes"].values()))
    if kind == "request":
        require(type(value["createdAtUnixMicroseconds"]) is int and value["createdAtUnixMicroseconds"] > 0)
    if kind in ("entry", "failure"):
        wire = value["wire"]
        require(type(wire) is dict and set(wire) == {"argvShape", "argvPair", "envPair", "channelsMatch"})
        require(wire["argvShape"] in ("expected", "invalid", "missing"))
        require(all(wire[k] in ("valid", "partial", "missing", "invalid") for k in ("argvPair", "envPair")))
        require(wire["channelsMatch"] is None or type(wire["channelsMatch"]) is bool)
        instance = [value[k] for k in ("pid", "startSeconds", "startMicroseconds")]
        require(all(v is None for v in instance) or (all(type(v) is int for v in instance) and instance[0] > 0 and instance[1] > 0 and 0 <= instance[2] < 1000000))
        if kind == "entry": require(value["stage"] == "bootstrap" and value["outcome"] == "entered")
        else:
            require(value["stage"] in ("wire", "context", "proof", "source", "binary", "instance", "clock", "publish", "ack", *( ("operation",) if dpk else () )))
            require(value["outcome"] in ("rejected", "unknown") and value["failureKind"] in ("input", "path", "schema", "binding", "binary", "instance", "clock", "write", "timeout", "other", *( ("operation", "deadline") if dpk else () )))
    if kind == "report":
        require(all(type(value[key]) is int and value[key] > 0 for key in ("pid", "startSeconds")))
        require(type(value["startMicroseconds"]) is int and 0 <= value["startMicroseconds"] < 1000000)
        require(value["stage"] == "report" and value["outcome"] == "awaitingAck")
        require(value["observedBinarySHA256"] == value["expectedBinarySHA256"])
    if kind == "final":
        require(value["outcome"] == "completed")
        if dpk: dpk_result(value["operationResult"], value["phase"])
    if kind in ("consume", "machine"):
        require(value["evidenceMode"] in ("fake-only", "signed-host"))
    if kind == "consume": require(type(value["readyConfirmed"]) is bool and value["readyConfirmed"] is True)
    if kind == "machine":
        binding_validate_app_output(value["appOutput"])
        require(value["stage"] in BINDING_STAGES and value["failureKind"] in BINDING_FAILURES | ({"deadline"} if dpk else set()))
        require(value["outcome"] in ("hostAttributed", "rejected", "unknown"))
        require(all(type(value[key]) is bool for key in BINDING_BOOLS | {"spawnAttempted"}))
        require(value["nativeReturnKind"] in ("notStarted", "zero", "nonzero", "signal", "unknown"))
        require(value["nativeExceptionKind"] in (None, "spawnOS", "waitOS", "timeout", "subprocess", "guard", "other"))
        for key in ("nativePID", "nativeSignal"):
            require(value[key] is None or (type(value[key]) is int and value[key] > 0))
        rc = value["nativeReturnCode"]
        require(rc is None or type(rc) is int)
        if value["nativeSettled"]:
            require(value["nativePID"] is not None and rc is not None)
            require(value["nativeReturnKind"] == ("zero" if rc == 0 else "signal" if rc < 0 else "nonzero"))
            require(value["nativeSignal"] == (-rc if rc < 0 else None))
        else:
            require(rc is None and value["nativeSignal"] is None)
            require(value["nativeReturnKind"] == ("unknown" if value["spawnAttempted"] else "notStarted"))
        if not value["spawnAttempted"]: require(value["nativePID"] is None and not value["nativeSettled"])
        if value["ackSHA256"] is not None:
            require(value["reportSHA256"] is not None and value["binaryVerified"] and value["liveInstanceVerified"])
        if value["finalSHA256"] is not None: require(value["reportSHA256"] is not None and value["ackSHA256"] is not None)
        if value["bindingMatched"]: require(value["finalSHA256"] is not None)
        if value["evidenceMode"] == "fake-only": require(not value["hostAttributed"] and value["outcome"] == "unknown")
        if dpk:
            require(type(value["operationVerified"]) is bool)
            if value["operationVerified"]: require(is_hash(value["operationResultSHA256"]) and value["bindingMatched"])
        if value["outcome"] == "hostAttributed" or value["hostAttributed"]:
            if dpk: require(value["operationVerified"] and is_hash(value["operationResultSHA256"]))
            require(value["entrySHA256"] is not None and value["failureSHA256"] is None)
            require(value["evidenceMode"] == "signed-host" and value["outcome"] == "hostAttributed")
            require(value["stage"] == "publish" and value["failureKind"] == "none" and all(value[k] for k in BINDING_BOOLS))
            require(value["spawnAttempted"] and value["nativeReturnKind"] == "zero" and value["nativeExceptionKind"] is None)
            require(all(value[k] is not None for k in ("reportSHA256", "ackSHA256", "finalSHA256")))
    return value


def binding_owned(root, path, directory=False, executable=False):
    path, root = Path(path), Path(root)
    require(path == root or root in path.parents)
    launcher_ancestors(path)
    info = path.stat()
    require(info.st_uid == os.getuid())
    for ancestor in path.parents if path != root else ():
        if ancestor == root: break
        require(ancestor.stat().st_uid == os.getuid())
    if directory:
        require(stat.S_ISDIR(info.st_mode) and stat.S_IMODE(info.st_mode) == 0o700)
    else:
        require(stat.S_ISREG(info.st_mode))
        require((not info.st_mode & 0o022) if executable else stat.S_IMODE(info.st_mode) == 0o600)
    return path


def binding_read(root, path):
    path = binding_owned(root, path)
    require(path.stat().st_size <= 65536)
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(fd, "rb") as handle:
        info = os.fstat(handle.fileno())
        require(stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) == 0o600)
        raw = handle.read(65537)
    require(len(raw) <= 65536)
    value = json.loads(raw)
    require(type(value) is dict)
    return value, digest(raw)


def binding_publish(root, path, value):
    path = Path(path)
    binding_owned(root, root, directory=True)
    binding_owned(root, path.parent, directory=True)
    expected = root / "phases" / value["phase"] if value.get("purpose") == DPK_PURPOSE else root / "attempt"
    require(path.parent == expected and path.name in BINDING_PUBLICATIONS)
    pending = path.parent / BINDING_PUBLICATIONS[path.name]
    require(not os.path.lexists(path) and not os.path.lexists(pending))
    sha = launcher_write(pending, value)
    os.link(pending, path, follow_symlinks=False)
    return sha


def binding_published(root, leaf, phase=None):
    final = root / ("phases/" + phase if phase else "attempt") / leaf
    require(leaf in BINDING_PUBLICATIONS)
    if not os.path.lexists(final): return None
    pending = binding_owned(root, final.parent / BINDING_PUBLICATIONS[leaf])
    first = binding_owned(root, final).stat(); second = pending.stat()
    require((first.st_dev, first.st_ino) == (second.st_dev, second.st_ino))
    value, sha = binding_read(root, final)
    require(final.read_bytes() == pending.read_bytes())
    return value, sha


def binding_observe_process(pid):
    import ctypes
    lib = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
    lib.proc_pidinfo.argtypes = (ctypes.c_int, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_int)
    lib.proc_pidinfo.restype = ctypes.c_int
    lib.proc_pidpath.argtypes = (ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32)
    lib.proc_pidpath.restype = ctypes.c_int
    info = launcher_read_metadata(lib, pid)
    require(info["status"] in (2, 3, 4))
    path = ctypes.create_string_buffer(4096)
    require(lib.proc_pidpath(pid, path, len(path)) > 0)
    return dict(pid=info["pid"], uid=info["uid"], startSeconds=info["start"][0],
                startMicroseconds=info["start"][1], executable=os.fsdecode(path.value), live=True)


def binding_hooks():
    import time
    # Context SHA/frozen proof approval remains an external trusted-operator boundary.
    return dict(evidenceMode="signed-host", wall=lambda: time.time_ns() // 1000,
                monotonic=time.monotonic, sleep=time.sleep, spawn=launcher_spawn,
                inspect=binding_observe_process, verify=binding_verify_static, verify_process=binding_verify_process)


def binding_context(path, expected_sha, mode="signed-host", phase=None, window=None):
    path = Path(path).absolute(); root = path.parent
    require(path.name == ("context-rebuilt.json" if phase == "rebuilt-read-b" else "context.json") and type(expected_sha) is str and is_hash(expected_sha))
    binding_owned(root, root, directory=True)
    context, actual = binding_read(root, path)
    require(actual == expected_sha)
    binding_validate("context", context)
    for leaf, sha in context["sourceHashes"].items():
        file = binding_owned(root, root / "source" / leaf)
        require(digest(file.read_bytes()) == sha)
    binding_profile_free_proofs(root, context, mode, phase)
    if context["purpose"] == DPK_PURPOSE:
        dpk_validate_round_context(root, context, phase, window=window)
    else: require(phase is None)
    binary = binding_owned(root, root / "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe", executable=True)
    require(digest(binary.read_bytes()) == context["expectedBinarySHA256"])
    return root, context, binary


def binding_launch(context_file, context_sha, attempt_uuid, ready_uuid, ready_confirmed, hooks=None, phase=None, phase_ready=None):
    hooks = binding_hooks() if hooks is None else hooks
    mode = hooks["evidenceMode"]
    require(mode in ("fake-only", "signed-host"))
    output = dict(evidenceMode=mode, stage="preflight", outcome="unknown", failureKind="input",
                  hostAttributed=False, bindingMatched=False, liveInstanceVerified=False, binaryVerified=False,
                  nativeSettled=False, nativeReturnKind="notStarted", appOutput=binding_app_output(), **{key: None for key in BINDING_HASHES})
    machine = root = process = None
    window = None
    last_observed_wall = None
    def observe_wall():
        nonlocal last_observed_wall
        current = hooks["wall"]()
        require(type(current) is int and current > 0)
        require(last_observed_wall is None or current >= last_observed_wall)
        last_observed_wall = current
        return current
    try:
        pre_root=Path(context_file).absolute().parent
        pre_context,_=binding_read(pre_root,Path(context_file).absolute())
        if pre_context.get("purpose")==DPK_PURPOSE and "authoritySHA256" in pre_context:
            window=DPKWindow.read(pre_root,mode=mode,sample=hooks.get("window_sample",dpk_window_sample))
            require(window.sha==pre_context["authoritySHA256"])
            window.fresh_ready(phase_ready,phase)
            require(phase_ready["readyUUID"]==ready_uuid)
        root, context, binary = binding_context(context_file, context_sha, mode, phase,window)
        dpk = context["purpose"] == DPK_PURPOSE
        if dpk:
            if window is None: dpk_time(120,now=observe_wall()/1000000)
            else: window.check(phase=phase,reserve=120)
        attempt_dir = root / ("phases/" + phase if phase else "attempt")
        consumed_file = attempt_dir / "binding-consumed.json" if dpk else root / "binding-consumed.json"
        signing = (binding_verify_static(root,context,binary,phase=phase,mode=mode,window=window) if window is not None and hooks["verify"] is binding_verify_static else hooks["verify"](root, context, binary))  # No self-issued review approval.
        binding_uuid(attempt_uuid); binding_uuid(ready_uuid); require(ready_confirmed is True)
        if window is not None:
            for previous_phase in DPK_PHASES:
                previous_path=root/"phases"/previous_phase/"binding-consumed.json"
                if os.path.lexists(previous_path):
                    prior,_=binding_read(root,previous_path)
                    require(prior.get("readyUUID")!=ready_uuid)
        require(not os.path.lexists(consumed_file) and not os.path.lexists(attempt_dir))
        created = observe_wall()
        request = dict(schemaVersion=1, purpose=context["purpose"], attemptUUID=attempt_uuid, contextSHA256=context_sha,
                       expectedBinarySHA256=context["expectedBinarySHA256"], createdAtUnixMicroseconds=created)
        if dpk: request.update(roundSHA256=context["roundSHA256"], phase=phase)
        binding_validate("request", request)
        # Match the existing exclusive_json byte representation before consuming the attempt.
        raw_request = (json.dumps(request, ensure_ascii=True, sort_keys=True, indent=2, allow_nan=False) + "\n").encode()
        binding = {key: request[key] for key in BINDING_KEYS | ({"roundSHA256", "phase"} if dpk else set()) if key != "requestSHA256"} | {"requestSHA256": digest(raw_request)}
        consume = dict(binding, readyUUID=ready_uuid, readyConfirmed=True, runnerSHA256=digest(Path(__file__).read_bytes()), evidenceMode=mode)
        binding_validate("consume", consume)
        output.update(stage="consume")
        if dpk:
            binding_owned(root, root / "phases", directory=True)
            attempt_dir.mkdir(mode=0o700)
        if dpk: dpk_time(window=window,phase=phase)
        consumed_sha = launcher_write(consumed_file, consume)
        if not dpk: attempt_dir.mkdir(mode=0o700)
        request_sha = launcher_write(attempt_dir / "request.json", request)
        require(request_sha == binding["requestSHA256"])
        machine = dict(binding, readyUUID=ready_uuid, runnerSHA256=consume["runnerSHA256"], consumedSHA256=consumed_sha,
            evidenceMode=mode, stage="consume", outcome="unknown", failureKind="none", hostAttributed=False,
            bindingMatched=False, liveInstanceVerified=False, binaryVerified=False, nativeSettled=False,
            nativeReturnKind="notStarted", spawnAttempted=False, nativePID=None, nativeReturnCode=None,
            nativeSignal=None, nativeExceptionKind=None, reportSHA256=None, ackSHA256=None, finalSHA256=None,
            entrySHA256=None, failureSHA256=None, appOutput=binding_app_output())
        if dpk: machine.update(operationResultSHA256=None, operationVerified=False)
        deadline = hooks["monotonic"]() + 30
        def poll_native():
            if process is None or machine["nativeSettled"] or machine["nativeExceptionKind"] == "waitOS": return
            try: rc = process.poll()
            except OSError:
                machine["nativeExceptionKind"] = "waitOS"; raise
            if rc is not None:
                require(type(rc) is int)
                machine.update(nativeSettled=True, nativeReturnCode=rc, nativeSignal=-rc if rc < 0 else None,
                               nativeReturnKind="zero" if rc == 0 else "signal" if rc < 0 else "nonzero")
        def wait_receipt(leaf):
            while hooks["monotonic"]() < deadline:
                poll_native()
                entry = binding_published(root, "host.entry.json", phase)
                if entry is not None:
                    binding_validate("entry", entry[0], binding); machine["entrySHA256"] = entry[1]
                failure = binding_published(root, "host.failure.json", phase)
                if failure is not None:
                    binding_validate("failure", failure[0], binding); machine["failureSHA256"] = failure[1]
                    raise BindingHostFailure()
                value = binding_published(root, leaf, phase)
                if value is not None:
                    require(machine["entrySHA256"] is not None)
                    return value
                if dpk: dpk_time(window=window,phase=phase)
                require(observe_wall() >= created)
                hooks["sleep"](0.01)
            raise TimeoutError()
        command = ["/usr/bin/open", "-W", "-a", str(binary.parents[2]), "--env",
            ("RIVET_DPK_REQUEST=" if dpk else "RIVET_LAUNCH_REPORT_REQUEST=") + str(attempt_dir / "request.json"), "--env",
            ("RIVET_DPK_REQUEST_SHA256=" if dpk else "RIVET_LAUNCH_REPORT_REQUEST_SHA256=") + request_sha,
            "--stdout", str(attempt_dir / "app.stdout"), "--stderr", str(attempt_dir / "app.stderr"),
            "--args", "--dpk-validation-only" if dpk else "--launch-binding-only", "--request", str(attempt_dir / "request.json"), "--request-sha", request_sha]
        for name in ("launch.stdout", "launch.stderr", "app.stdout", "app.stderr"):
            fd = os.open(attempt_dir / name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
            os.close(fd)
        if dpk: dpk_time(window=window,phase=phase)
        machine.update(stage="spawn", spawnAttempted=True, nativeReturnKind="unknown")
        try:
            with (attempt_dir / "launch.stdout").open("ab") as stdout, (attempt_dir / "launch.stderr").open("ab") as stderr:
                process = hooks["spawn"](command, stdout, stderr)
            machine["nativePID"] = process.pid
        except OSError:
            machine["nativeExceptionKind"] = "spawnOS"; raise
        machine["stage"] = "report"
        report, report_sha = wait_receipt("host.report.json")
        binding_validate("report", report, binding)
        machine["reportSHA256"] = report_sha
        machine["stage"] = "instance"
        for _ in range(2):
            if dpk: dpk_time(window=window,phase=phase)
            observed = hooks["inspect"](report["pid"])
            if dpk: dpk_time(window=window,phase=phase,reserve=max(0,deadline-hooks["monotonic"]())+5)
            hooks["verify_process"](report["pid"], signing, deadline - hooks["monotonic"]())
            require(observed["live"] is True and observed["uid"] == os.getuid())
            require(all(observed[key] == report[key] for key in ("pid", "startSeconds", "startMicroseconds")))
            require(observed["executable"] == str(binary) and digest(binary.read_bytes()) == context["expectedBinarySHA256"])
            start = observed["startSeconds"] * 1000000 + observed["startMicroseconds"]
            require(created <= start <= observe_wall() and hooks["monotonic"]() < deadline)
        machine.update(liveInstanceVerified=True, binaryVerified=True)
        machine["stage"] = "ack"
        if dpk: dpk_time(window=window,phase=phase)
        ack = dict(binding, hostReportSHA256=report_sha); binding_validate("ack", ack, binding)
        machine["ackSHA256"] = binding_publish(root, attempt_dir / "ack.json", ack)
        machine["stage"] = "final"
        final, final_sha = wait_receipt("host.final.json")
        binding_validate("final", final, dict(binding, hostReportSHA256=report_sha, ackSHA256=machine["ackSHA256"]))
        machine.update(finalSHA256=final_sha, bindingMatched=True, stage="settle")
        if dpk:
            dpk_result(final["operationResult"], phase)
            machine.update(operationResultSHA256=digest(json.dumps(final["operationResult"],sort_keys=True,separators=(",",":")).encode()),operationVerified=True)
        try:
            remaining = deadline - hooks["monotonic"](); require(remaining > 0)
            rc = process.wait(timeout=remaining)
        except OSError:
            machine["nativeExceptionKind"] = "waitOS"; raise
        machine.update(nativeSettled=True, nativeReturnCode=rc, nativeSignal=-rc if rc < 0 else None,
                       nativeReturnKind="zero" if rc == 0 else "signal" if rc < 0 else "nonzero")
        require(rc == 0 and observe_wall() >= created)
        if dpk: dpk_time(window=window,phase=phase)
        machine.update(stage="publish", hostAttributed=mode == "signed-host",
                       outcome="hostAttributed" if mode == "signed-host" else "unknown")
    except DPKDeadlineRejected:
        if machine is not None: machine.update(failureKind="deadline",outcome="unknown",hostAttributed=False)
        output.update(failureKind="deadline",outcome="unknown",hostAttributed=False)
    except (TimeoutError, subprocess.TimeoutExpired) as error:
        if machine is not None:
            machine["failureKind"] = "timeout"
            if isinstance(error, subprocess.TimeoutExpired) and machine["nativeExceptionKind"] is None:
                machine["nativeExceptionKind"] = "timeout"
        output.update(failureKind="timeout")
    except Exception as error:
        if machine is not None:
            failure = "native" if machine["nativeExceptionKind"] is not None or machine["stage"] == "settle" else "instance" if machine["stage"] == "instance" else "input"
            machine.update(failureKind=failure)
        output.update(failureKind="write" if isinstance(error, OSError) and machine is None else "input")
    if machine is not None:
        try:
            poll_native()
        except Exception:
            if machine["nativeExceptionKind"] is None: machine["nativeExceptionKind"] = "other"
            machine["failureKind"] = "native"
        machine["appOutput"] = binding_app_output(root, phase)
        try:
            consume_now, consume_sha = binding_read(root, consumed_file)
            binding_validate("consume", consume_now, {key: machine[key] for key in BINDING_KEYS | ({"roundSHA256", "phase"} if dpk else set()) | {"readyUUID", "runnerSHA256", "evidenceMode"}})
            require(consume_sha == machine["consumedSHA256"])
            binding_validate("machine", machine)
            machine_sha = binding_publish(root, attempt_dir / "launcher.machine.json", machine)
            output.update({key: machine[key] for key in output if key in machine})
            output["machineSHA256"] = machine_sha
        except Exception:
            output.update(stage="publish", outcome="unknown", failureKind="write", hostAttributed=False, machineSHA256=None)
    if machine is not None and "operationVerified" in machine:
        output.update(operationVerified=machine["operationVerified"], operationResultSHA256=machine["operationResultSHA256"])
    return output, 0 if output["hostAttributed"] else 1



DPK_PURPOSE = "dpk-credential-validation"
DPK_PHASES = ("save-a", "read-a", "replace-b", "read-b", "rebuilt-read-b")
DPK_DEADLINE = 1793786789
DPK_ROUND_KEYS = {"schemaVersion", "purpose", "roundUUID", "service", "account", "clientID", "group", "deadlineUTC", "parentLG59MachineSHA256", "parentLG64ResultSHA256", "sourceHashes", "profileSHA256", "certificateSHA256", "initialBuildProofSHA256", "initialSigningProofSHA256"}


DPK_WINDOW_PHASES = ('sign-debug','context','save-a','read-a','replace-b','read-b','rebuild','sign-rebuilt','context-rebuilt','rebuilt-read-b')
DPK_BOOT_POLICY = 'darwin-kern.bootsessionuuid-sha256-v1'
DPK_PROMPTS = dict(saveMaxPrompts=1, freshReadMaxPrompts=0, replaceMaxPrompts=0, buildSignMaxKeyAuthorizations=1)
DPK_DESCRIPTOR_KEYS = {'schemaVersion','purpose','roundUUID','sourceHashes','operationalSourceHashes','callerSHA256','controllerSHA256','unsignedDebugBinarySHA256','unsignedRebuiltBinarySHA256','profileSHA256','certificateSHA256','identityInputsSHA256','parentLG59MachineSHA256','parentLG64ResultSHA256','parentOfflineFreezeSHA256','maximumWindowSeconds','bootSessionPolicy','allowedPhases','promptLimits'}
DPK_HUMAN_KEYS = {'schemaVersion','purpose','descriptorSHA256','liveAuthorized','ready','readyUUID','readyAtUnixSeconds','readyAtMonotonicNanoseconds','bootSessionSHA256','windowSeconds','acceptedPromptLimits'}
DPK_AUTHORITY_KEYS = {'schemaVersion','purpose','evidenceMode','windowUUID','roundUUID','descriptorSHA256','humanAuthorizationSHA256','startsAtUnixSeconds','expiresAtUnixSeconds','startsAtMonotonicNanoseconds','expiresAtMonotonicNanoseconds','bootSessionSHA256','allowedPhases','promptLimits'}


class DPKDeadlineRejected(Rejected):
    """Finite DPK-only deadline/boot/observed-clock rejection; no raw kernel data."""


def dpk_boot_hash(raw):
    require(type(raw) is bytes and len(raw) == 37 and raw[-1:] == b'\0')
    text = raw[:-1].decode('ascii', errors='strict')
    require(re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}',text) is not None)
    require(uuid.UUID(text).int != 0)
    return digest(b'rivet.dpk.boot-session.v1\n' + text.lower().encode('ascii') + b'\n')


def dpk_window_sample():
    """Read-only local kernel clocks/boot; no process enumeration or signing assets."""
    import ctypes,time
    libc=ctypes.CDLL('/usr/lib/libSystem.B.dylib',use_errno=True)
    libc.sysctlbyname.argtypes=(ctypes.c_char_p,ctypes.c_void_p,ctypes.POINTER(ctypes.c_size_t),ctypes.c_void_p,ctypes.c_size_t)
    libc.sysctlbyname.restype=ctypes.c_int
    def boot():
        data=ctypes.create_string_buffer(64);size=ctypes.c_size_t(64)
        require(libc.sysctlbyname(b'kern.bootsessionuuid',data,ctypes.byref(size),None,0)==0 and size.value==37)
        return dpk_boot_hash(data.raw[:size.value])
    first=boot()
    class Timebase(ctypes.Structure):_fields_=[('numer',ctypes.c_uint32),('denom',ctypes.c_uint32)]
    libc.mach_timebase_info.argtypes=(ctypes.POINTER(Timebase),);libc.mach_timebase_info.restype=ctypes.c_int
    libc.mach_continuous_time.argtypes=();libc.mach_continuous_time.restype=ctypes.c_uint64
    base=Timebase();require(libc.mach_timebase_info(ctypes.byref(base))==0 and base.numer>0 and base.denom>0)
    wall=time.time_ns()//1_000_000_000;mono=libc.mach_continuous_time()*base.numer//base.denom
    require(first==boot())
    return wall,mono,first


def dpk_window_schema(kind,value):
    fields={'descriptor':DPK_DESCRIPTOR_KEYS,'human':DPK_HUMAN_KEYS,'authority':DPK_AUTHORITY_KEYS}
    require(kind in fields and type(value) is dict and set(value)==fields[kind])
    require(type(value['schemaVersion']) is int and value['schemaVersion']==1 and value['purpose']==DPK_PURPOSE)
    for key,item in value.items():
        if key.endswith('SHA256'):require(type(item) is str and is_hash(item))
        if key.endswith('UUID'):binding_uuid(item)
    if kind=='descriptor':
        for key in ('sourceHashes','operationalSourceHashes'):
            require(type(value[key]) is dict and set(value[key])==set(BINDING_SOURCES) and all(type(v) is str and is_hash(v) for v in value[key].values()))
        require(type(value['maximumWindowSeconds']) is int and value['maximumWindowSeconds']==3600 and value['bootSessionPolicy']==DPK_BOOT_POLICY)
        require(value['certificateSHA256']==BINDING_CERTIFICATE_SHA256)
    if kind=='human':
        require(value['liveAuthorized'] is True and value['ready'] is True)
        require(type(value['windowSeconds']) is int and 1<=value['windowSeconds']<=3600)
        numeric=('readyAtUnixSeconds','readyAtMonotonicNanoseconds')
    elif kind=='authority':
        require(value['evidenceMode'] in ('signed-host','fake-only'))
        numeric=('startsAtUnixSeconds','expiresAtUnixSeconds','startsAtMonotonicNanoseconds','expiresAtMonotonicNanoseconds')
    else:numeric=()
    require(all(type(value[k]) is int and value[k]>0 for k in numeric))
    if kind!='human':require(type(value['allowedPhases']) is list and value['allowedPhases']==list(DPK_WINDOW_PHASES))
    policy=value['acceptedPromptLimits' if kind=='human' else 'promptLimits']
    require(type(policy) is dict and set(policy)==set(DPK_PROMPTS) and all(type(v) is int for v in policy.values()) and policy==DPK_PROMPTS)
    return value


class DPKWindow:
    """One participant's explicit verified-window state, never a process-global override."""
    def __init__(self,value,sha,descriptor,human,*,mode='signed-host',sample=dpk_window_sample):
        dpk_window_schema('authority',value);dpk_window_schema('descriptor',descriptor);dpk_window_schema('human',human)
        require(value['evidenceMode']==mode and mode in ('signed-host','fake-only'))
        require(value['roundUUID']==descriptor['roundUUID'] and value['bootSessionSHA256']==human['bootSessionSHA256'])
        require(value['allowedPhases']==descriptor['allowedPhases'] and value['promptLimits']==descriptor['promptLimits']==human['acceptedPromptLimits'])
        seconds=human['windowSeconds']
        require(value['startsAtUnixSeconds']==human['readyAtUnixSeconds'] and value['startsAtMonotonicNanoseconds']==human['readyAtMonotonicNanoseconds'])
        require(value['expiresAtUnixSeconds']==value['startsAtUnixSeconds']+seconds and value['expiresAtMonotonicNanoseconds']==value['startsAtMonotonicNanoseconds']+seconds*1_000_000_000)
        self.value,self.sha,self.descriptor,self.human,self.sample=value,sha,descriptor,human,sample
        self.last=None

    @classmethod
    def read(cls,root,*,mode='signed-host',sample=dpk_window_sample):
        root=Path(root);value,sha=binding_read(root,root/'live-authority.json')
        dpk_window_schema('authority',value)
        require(value['evidenceMode']==mode and mode in ('signed-host','fake-only'))
        seconds=value['expiresAtUnixSeconds']-value['startsAtUnixSeconds']
        require(1<=seconds<=3600 and value['expiresAtMonotonicNanoseconds']-value['startsAtMonotonicNanoseconds']==seconds*1_000_000_000)
        window=cls.__new__(cls)
        window.value,window.sha,window.sample,window.last=value,sha,sample,None
        window.check();return window

    def check(self,*,phase=None,reserve=0):
        require(phase is None or phase in self.value['allowedPhases'])
        require(type(reserve) in (int,float) and reserve>=0)
        try:
            wall,mono,boot=self.sample()
            require(type(wall) is int and type(mono) is int and wall>0 and mono>0)
            require(boot==self.value['bootSessionSHA256'])
            require(self.last is None or wall>=self.last[0] and mono>=self.last[1])
            require(self.value['startsAtUnixSeconds']<=wall and self.value['startsAtMonotonicNanoseconds']<=mono)
            require(wall+reserve<self.value['expiresAtUnixSeconds'] and mono+int(reserve*1_000_000_000)<self.value['expiresAtMonotonicNanoseconds'])
            self.last=(wall,mono)
        except Exception as error:raise DPKDeadlineRejected() from error
        return wall

    def native(self,command,args,timeout,*,phase):
        require(type(timeout) in (int,float) and timeout>0)
        self.check(phase=phase,reserve=timeout+5)
        return command(args,timeout)  # Preserve the original rc/exception; no post-expiry follow-up.

    def fresh_ready(self,ready,phase):
        require(type(ready) is dict and set(ready)=={'roundUUID','phase','readyUUID','ready','authoritySHA256','readyAtUnixSeconds','readyAtMonotonicNanoseconds'})
        require(ready['roundUUID']==self.value['roundUUID'] and ready['phase']==phase and ready['ready'] is True and ready['authoritySHA256']==self.sha)
        binding_uuid(ready['readyUUID']);self.check(phase=phase)
        for key,index in (('readyAtUnixSeconds',0),('readyAtMonotonicNanoseconds',1)):
            require(type(ready[key]) is int and ready[key]>0)
            age=self.last[index]-ready[key]
            require(0<=age<=60*(1 if index==0 else 1_000_000_000))
        require(ready['readyAtUnixSeconds']>=self.value['startsAtUnixSeconds'] and ready['readyAtMonotonicNanoseconds']>=self.value['startsAtMonotonicNanoseconds'])
        # Initial ready identity is checked by the caller against its immutable Human record.


def dpk_open_window(root,descriptor_sha,human_path,*,asset_expiry,sample=dpk_window_sample,evidence_mode='signed-host'):
    """Caller factory only. External operator checks actual Human/review; this does not authenticate them."""
    root=Path(root);binding_owned(root,root,directory=True)
    require(Path(human_path)==root/'human-window.json')
    descriptor,actual=binding_read(root,root/'descriptor.json');human,human_sha=binding_read(root,Path(human_path))
    dpk_window_schema('descriptor',descriptor);dpk_window_schema('human',human)
    require(actual==descriptor_sha==human['descriptorSHA256'])
    require(type(asset_expiry) is int and human['readyAtUnixSeconds']+human['windowSeconds']<=asset_expiry)
    for leaf in ('window-open-consumed.json','live-authority.pending.json','live-authority.json'):require(not os.path.lexists(root/leaf))
    value=dict(schemaVersion=1,purpose=DPK_PURPOSE,evidenceMode=evidence_mode,windowUUID=str(uuid.uuid4()),roundUUID=descriptor['roundUUID'],descriptorSHA256=actual,humanAuthorizationSHA256=human_sha,
        startsAtUnixSeconds=human['readyAtUnixSeconds'],expiresAtUnixSeconds=human['readyAtUnixSeconds']+human['windowSeconds'],
        startsAtMonotonicNanoseconds=human['readyAtMonotonicNanoseconds'],expiresAtMonotonicNanoseconds=human['readyAtMonotonicNanoseconds']+human['windowSeconds']*1_000_000_000,
        bootSessionSHA256=human['bootSessionSHA256'],allowedPhases=descriptor['allowedPhases'],promptLimits=descriptor['promptLimits'])
    window=DPKWindow(value,None,descriptor,human,mode=evidence_mode,sample=sample);window.check()
    require(window.last[0]-human['readyAtUnixSeconds']<=60 and window.last[1]-human['readyAtMonotonicNanoseconds']<=60_000_000_000)
    launcher_write(root/'window-open-consumed.json',dict(schemaVersion=1,purpose=DPK_PURPOSE,descriptorSHA256=actual,humanAuthorizationSHA256=human_sha))
    sha=launcher_write(root/'live-authority.pending.json',value)
    os.link(root/'live-authority.pending.json',root/'live-authority.json',follow_symlinks=False)
    return sha


def dpk_time(reserve=0, *, now=None, window=None, phase=None):
    if window is not None:
        require(now is None)
        return window.check(reserve=reserve,phase=phase)
    now = __import__("time").time() if now is None else now
    require(type(now) in (int,float) and type(reserve) in (int,float) and reserve >= 0 and now + reserve < DPK_DEADLINE)
    return now


def dpk_result(value, phase):
    require(type(value) is dict and set(value) == {"phase", "comparison", "ownershipVerified"})
    require(phase in DPK_PHASES and value["phase"] == phase and value["ownershipVerified"] is True)
    comparison = value["comparison"]
    require(type(comparison) is dict and set(comparison) == set(FIELDS))
    require(all(type(v) is bool and v for v in comparison.values()))
    return value


def dpk_round(root):
    value, sha = binding_read(root, root / "round.json")
    require(set(value) == DPK_ROUND_KEYS | ({"authoritySHA256"} if "authoritySHA256" in value else set()) and type(value["schemaVersion"]) is int and value["schemaVersion"] == 1 and value["purpose"] == DPK_PURPOSE)
    binding_uuid(value["roundUUID"])
    validate_namespace(value["roundUUID"], value["service"])
    require(value["account"] == "credential" and value["clientID"] == "rivet-validation-fake-client")
    require(type(value["group"]) is str and bool(value["group"]) and "*" not in value["group"])
    require(value["certificateSHA256"] == BINDING_CERTIFICATE_SHA256)
    if "authoritySHA256" not in value: require(value["deadlineUTC"] == "2026-11-04T10:06:29Z")
    for key, item in value.items():
        if key.endswith("SHA256"): require(type(item) is str and is_hash(item))
    return value, sha


def dpk_validate_round_context(root, context, phase, *, window=None):
    if "authoritySHA256" in context:
        require(window is not None and window.sha == context["authoritySHA256"])
    else: require(window is None)
    dpk_time(window=window,phase=phase)
    value, sha = dpk_round(root)
    if window is not None:
        require(value.get("authoritySHA256") == window.sha and value["roundUUID"] == window.value["roundUUID"])
        expected=dt.datetime.fromtimestamp(window.value["expiresAtUnixSeconds"],dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        require(value["deadlineUTC"] == expected)
    else: require("authoritySHA256" not in value)
    require(phase in DPK_PHASES and sha == context["roundSHA256"] and value["profileSHA256"] == context["profileSHA256"])
    require(value["sourceHashes"] == context["sourceHashes"])
    profile = binding_owned(root, root / "profile.provisionprofile")
    require(digest(profile.read_bytes()) == value["profileSHA256"])
    return value


def dpk_entitlements(root, value, *, window=None):
    expected = plistlib.loads(binding_owned(root, root / "entitlements.plist").read_bytes())
    require(type(expected) is dict and set(expected) == {"com.apple.application-identifier", "com.apple.developer.team-identifier", "keychain-access-groups"})
    require(expected["keychain-access-groups"] == [value["group"]] and expected["com.apple.application-identifier"] == value["group"])
    require(type(expected["com.apple.developer.team-identifier"]) is str and bool(expected["com.apple.developer.team-identifier"]))
    raw = binding_owned(root,root / "profile.provisionprofile").read_bytes()
    require(digest(raw) == value["profileSHA256"])
    dpk_time(window=window,reserve=15)
    decoded = subprocess.run(["/usr/bin/openssl","cms","-verify","-noverify","-nosigs","-inform","DER"],input=raw,capture_output=True,timeout=10)
    require(decoded.returncode == 0)
    profile = plistlib.loads(decoded.stdout)
    now = dt.datetime.now(dt.timezone.utc)
    require(profile["CreationDate"].replace(tzinfo=dt.timezone.utc) <= now < profile["ExpirationDate"].replace(tzinfo=dt.timezone.utc))
    claims = profile["Entitlements"]
    require(profile["TeamIdentifier"] == [expected["com.apple.developer.team-identifier"]])
    require(claims.get("com.apple.application-identifier",claims.get("application-identifier")) == value["group"])
    require(any(group == value["group"] or group.endswith(".*") and value["group"].startswith(group[:-1]) for group in claims["keychain-access-groups"]))
    require(any(digest(cert) == BINDING_CERTIFICATE_SHA256 for cert in profile["DeveloperCertificates"]))
    return expected


def dpk_previous_gone(report, *, library=None):
    """Only the exact reported own instance; never enumerate UID processes or inspect other argv."""
    import ctypes, errno
    require(type(report["pid"]) is int and report["pid"] > 0)
    lib = library or ctypes.CDLL("/usr/lib/libproc.dylib",use_errno=True)
    lib.proc_pidinfo.argtypes=(ctypes.c_int,ctypes.c_int,ctypes.c_uint64,ctypes.c_void_p,ctypes.c_int)
    lib.proc_pidinfo.restype=ctypes.c_int
    info=launcher_bsdinfo_type()(); size=ctypes.sizeof(info)
    ctypes.set_errno(0)
    count=lib.proc_pidinfo(report["pid"],3,1,ctypes.byref(info),size)
    failure=ctypes.get_errno()
    # ESRCH is usable only for this exact previously verified PID after its native open settled zero.
    if count == 0: return failure == errno.ESRCH
    require(count == size and info.pbi_pid == report["pid"] and info.pbi_uid == os.getuid())
    require(info.pbi_start_tvsec > 0 and info.pbi_start_tvusec < 1000000)
    same=(info.pbi_start_tvsec,info.pbi_start_tvusec)==(report["startSeconds"],report["startMicroseconds"])
    require(info.pbi_status in (2,3,4,5))
    return not same or info.pbi_status == 5


def dpk_prepare(repo_path,parent_path,profile_path):
    """No credentials/context: ordinary no-sign build products and immutable preparation inputs only."""
    import shutil,tempfile,time
    dpk_time(540)
    repo=Path(repo_path).resolve(); parent=Path(parent_path).resolve(); profile=Path(profile_path).absolute()
    require((repo/"experiments/E015/github-oauth-credential-persistence").is_dir())
    binding_owned(parent,parent,directory=True)
    require(profile == parent/"profile-acquisition-1/profile.provisionprofile")
    binding_owned(parent,profile)
    baseline=load(parent/"config-report-timeout-amendment-1.json")
    require(baseline["repo"] == str(repo))
    workspace=Path(tempfile.mkdtemp(prefix="rivet-dpk-preparation-",dir=parent))
    source=repo/"experiments/E015/github-oauth-credential-persistence"
    for leaf in PROJECT_FILES:
        target=workspace/"project"/leaf;target.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
        data=(source/leaf).read_bytes()
        if leaf.endswith("pbxproj"):
            require(data.count(b'relativePath = "../../..";')==1)
            data=data.replace(b'relativePath = "../../..";',("relativePath = "+json.dumps(str(repo))+";").encode())
        fd=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
        with os.fdopen(fd,"wb") as handle: handle.write(data);handle.flush();os.fsync(handle.fileno())
    hashes={leaf:digest((source/leaf).read_bytes()) for leaf in BINDING_SOURCES}
    outputs={}
    for configuration,scheme,flag in (("Debug","CredentialStorageProbe",""),("Rebuilt","CredentialStorageProbeRebuilt"," CREDENTIAL_STORAGE_REBUILT")):
        dpk_time(540)
        command=list(baseline["buildCommand"])
        for key,value in (("-project",workspace/"project/CredentialStorageProbe.xcodeproj"),("-derivedDataPath",workspace/("derived-"+configuration.lower())),("-scheme",scheme),("-configuration",configuration)):
            require(key in command);command[command.index(key)+1]=str(value)
        command=[arg for arg in command if not arg.startswith("SWIFT_ACTIVE_COMPILATION_CONDITIONS=")]
        command.append("SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG DPK_VALIDATION_ONLY"+flag)
        require("CODE_SIGNING_ALLOWED=NO" in command and "CODE_SIGNING_REQUIRED=NO" in command and "CODE_SIGN_STYLE=Manual" in command)
        require(not any(arg in command for arg in ("-allowProvisioningUpdates","-allowProvisioningDeviceRegistration","-authenticationKeyPath")))
        exclusive_json(workspace/(configuration+".command.json"),command)
        with (workspace/(configuration+".stdout")).open("xb") as out,(workspace/(configuration+".stderr")).open("xb") as err:
            result=subprocess.run(command,stdout=out,stderr=err,timeout=min(480,DPK_DEADLINE-time.time()-30))
        require(result.returncode==0)
        product=workspace/("derived-"+configuration.lower())/"Build/Products"/configuration/"CredentialStorageProbe.app"
        require(product.is_dir() and not product.is_symlink() and not (product/"Contents/embedded.provisionprofile").exists())
        kept=workspace/("unsigned-"+configuration.lower())/"CredentialStorageProbe.app";kept.parent.mkdir(mode=0o700);shutil.copytree(product,kept,symlinks=False)
        outputs[configuration]={"app":str(kept),"binarySHA256":digest((kept/"Contents/MacOS/CredentialStorageProbe").read_bytes()),"commandSHA256":digest(json.dumps(command,sort_keys=True).encode())}
    require(outputs["Debug"]["binarySHA256"]!=outputs["Rebuilt"]["binarySHA256"])
    exclusive_json(workspace/"preparation.json",{"sourceHashes":hashes,"profileSHA256":digest(profile.read_bytes()),"products":outputs,"signed":False,"contextCreated":False})
    for directory, directories, files in os.walk(workspace,followlinks=False):
        current=Path(directory);require(not current.is_symlink() and current.stat().st_uid==os.getuid());os.chmod(current,0o700)
        for leaf in files:
            path=current/leaf
            if not path.is_symlink():
                require(path.stat().st_uid==os.getuid());os.chmod(path,0o700 if path.stat().st_mode & 0o111 else 0o600)
    return {"prepared":True,"preparationSHA256":digest((workspace/"preparation.json").read_bytes()),"signed":False,"contextCreated":False}


def dpk_stage(root_path, phase, ready_file, hooks=None):
    root = Path(root_path).absolute(); binding_owned(root,root,directory=True)
    require(root.name == "dpk-acceptance-1" and phase in DPK_PHASES)
    value, round_sha = dpk_round(root)
    ready, _ = binding_read(root, Path(ready_file))
    window=None
    if "authoritySHA256" in value:
        window=DPKWindow.read(root,mode=hooks["evidenceMode"] if hooks else "signed-host",sample=hooks.get("window_sample",dpk_window_sample) if hooks else dpk_window_sample)
        require(window.sha==value["authoritySHA256"])
        window.check(phase=phase,reserve=120);window.fresh_ready(ready,phase)
    else:
        dpk_time(120)
        require(set(ready) == {"roundUUID", "phase", "readyUUID", "ready"} and ready["roundUUID"] == value["roundUUID"] and ready["phase"] == phase and ready["ready"] is True)
    binding_uuid(ready["readyUUID"])
    index = DPK_PHASES.index(phase)
    if index:
        previous = DPK_PHASES[index-1]
        human, _ = binding_read(root,root / "phases" / previous / "human.json")
        machine = binding_published(root,"launcher.machine.json",previous)
        require(machine is not None and human["machineSHA256"] == machine[1] and human["wholeStageObserved"] is True)
        binding_validate("machine",machine[0]); require(machine[0]["operationVerified"] and (machine[0]["hostAttributed"] or hooks is not None and hooks["evidenceMode"] == "fake-only" and machine[0]["bindingMatched"]))
        require(machine[0]["purpose"] == DPK_PURPOSE and machine[0]["roundSHA256"] == round_sha and machine[0]["phase"] == previous)
        report = binding_published(root,"host.report.json",previous)
        require(report is not None and is_hash(machine[0]["reportSHA256"]) and report[1] == machine[0]["reportSHA256"])
        previous_binding = {key: machine[0][key] for key in BINDING_KEYS | {"roundSHA256", "phase"}}
        binding_validate("report", report[0], previous_binding)
        # Exact previous instance must be positively absent, not merely another PID/UUID.
        dpk_time(window=window,phase=phase)
        observer = hooks.get("previous_gone") if hooks is not None else dpk_previous_gone
        require(observer is not None and observer(report[0]) is True)
    context_file = root / ("context-rebuilt.json" if phase == "rebuilt-read-b" else "context.json")
    if hooks is None:
        expected = dpk_entitlements(root,value,window=window)
        hooks = binding_hooks()
        hooks["verify"] = lambda r,c,b: binding_verify_static(r,c,b,phase=phase,window=window)
        hooks["verify_process"] = lambda pid,proof,remaining: binding_verify_process(pid,proof,remaining,expected_entitlements=expected,window=window,phase=phase)
    return binding_launch(context_file,digest(context_file.read_bytes()),str(uuid.uuid4()),ready["readyUUID"],True,hooks,phase,ready if window is not None else None)


def dpk_observe(root_path, phase, human_file):
    root=Path(root_path).absolute(); value,_=dpk_round(root)
    # Recording already-observed Human facts after expiry is permitted; no next action unlocked here.
    require(phase in DPK_PHASES)
    machine=binding_published(root,"launcher.machine.json",phase); require(machine is not None)
    binding_validate("machine",machine[0]); human,_=binding_read(root,Path(human_file))
    require(set(human)=={"roundUUID","phase","machineSHA256","promptCount","wholeStageObserved","actions"})
    require(human["roundUUID"]==value["roundUUID"] and human["phase"]==phase and human["machineSHA256"]==machine[1])
    require(type(human["promptCount"]) is int and human["promptCount"]>=0 and human["wholeStageObserved"] is True)
    require(type(human["actions"]) is list and all(a in ("none","allow","deny","authenticate","other") for a in human["actions"]))
    require(human["promptCount"] <= (1 if phase=="save-a" else 0))
    require(len(human["actions"]) == human["promptCount"] or human["promptCount"]==0 and human["actions"]==["none"])
    require(machine[0]["hostAttributed"] and machine[0]["operationVerified"])
    return launcher_write(root/"phases"/phase/"human.json",human)


def main():
    parser = SafeParser(description="Staged credential storage validation; no automatic live run.")
    sub = parser.add_subparsers(dest="command", required=True)
    prep = sub.add_parser("prepare")
    prep.add_argument("--repo", required=True)
    prep.add_argument("--parent", required=True)
    prep.add_argument("--uuid", default=None)
    active = sub.add_parser("stage")
    active.add_argument("--root", required=True)
    active.add_argument("--phase", choices=PHASES, required=True)
    active.add_argument("--ready-file", required=True)
    active.add_argument("--identity-file")
    active.add_argument("--built-app")
    obs = sub.add_parser("observe")
    obs.add_argument("--root", required=True)
    obs.add_argument("--phase", choices=PHASES, required=True)
    obs.add_argument("--human-file", required=True)
    obs.add_argument("--recovery-id")
    obs.add_argument("--setup-attempt", choices=("retry-1",))
    retry = sub.add_parser("retry-setup")
    retry.add_argument("--root", required=True)
    retry.add_argument("--ready-file", required=True)
    retry.add_argument("--policy-adoption-file", required=True)
    recover = sub.add_parser("recover-cleanup")
    recover.add_argument("--root", required=True)
    recover.add_argument("--ready-file", required=True)
    inspect = sub.add_parser("inspect-built")
    inspect.add_argument("--root", required=True)
    inspect.add_argument("--ready-file", required=True)
    inspect.add_argument("--identity-file", required=True)
    inspect.add_argument("--built-app", required=True)
    exp = sub.add_parser("export")
    exp.add_argument("--root", required=True)
    exp.add_argument("--destination", required=True)
    exp.add_argument("--final", action="store_true")
    files = sub.add_parser("cleanup-files")
    files.add_argument("--root", required=True)
    diagnostic = sub.add_parser("diagnostic-stage")
    diagnostic.add_argument("--manifest", required=True)
    diagnostic.add_argument("--manifest-sha", required=True)
    diagnostic.add_argument("--ready-file", required=True)
    diagnostic_obs = sub.add_parser("diagnostic-observe")
    diagnostic_obs.add_argument("--manifest", required=True)
    diagnostic_obs.add_argument("--manifest-sha", required=True)
    diagnostic_obs.add_argument("--human-file", required=True)
    amendment = sub.add_parser("launcher-amendment")
    amendment.add_argument("--manifest", required=True)
    amendment.add_argument("--manifest-sha", required=True)
    amendment.add_argument("--ready-uuid", required=True)
    amendment.add_argument("--ready-confirmed", action="store_true", required=True)
    amendment_observe = sub.add_parser("launcher-amendment-observe")
    amendment_observe.add_argument("--manifest", required=True)
    amendment_observe.add_argument("--manifest-sha", required=True)
    amendment_observe.add_argument("--binding-receipt-sha", required=True)
    amendment_observe.add_argument("--prompt-count", required=True)
    amendment_observe.add_argument("--actions", required=True)
    amendment_observe.add_argument("--whole-observed", choices=("yes", "no"), required=True)
    binding = sub.add_parser("binding-launch")
    binding.add_argument("--context", required=True)
    binding.add_argument("--context-sha", required=True)
    binding.add_argument("--attempt-uuid", required=True)
    binding.add_argument("--ready-uuid", required=True)
    binding.add_argument("--ready-confirmed", action="store_true", required=True)
    for name in ("dpk-stage", "dpk-observe"):
        dp = sub.add_parser(name)
        dp.add_argument("--root",required=True)
        dp.add_argument("--phase",choices=DPK_PHASES,required=True)
        dp.add_argument("--ready-file" if name=="dpk-stage" else "--human-file",required=True)
    dprep=sub.add_parser("dpk-prepare")
    for name in ("repo","parent","profile"): dprep.add_argument("--"+name,required=True)
    args = parser.parse_args()
    if args.command=="dpk-prepare":
        try: result,code=dpk_prepare(args.repo,args.parent,args.profile),0
        except (Rejected,OSError,ValueError,KeyError,TypeError,subprocess.TimeoutExpired):result,code={"status":"unknown","failureKind":"prepare"},1
        print(json.dumps(result,sort_keys=True));return code
    if args.command in ("dpk-stage","dpk-observe"):
        try:
            if args.command=="dpk-stage": result,code=dpk_stage(args.root,args.phase,args.ready_file)
            else: result,code={"humanSHA256":dpk_observe(args.root,args.phase,args.human_file)},0
        except (Rejected,OSError,ValueError,KeyError,TypeError): result,code={"status":"unknown","failureKind":"guard"},1
        print(json.dumps(result,sort_keys=True));return code
    if args.command == "binding-launch":
        result, code = binding_launch(args.context, args.context_sha, args.attempt_uuid, args.ready_uuid, args.ready_confirmed)
        print(json.dumps(result, sort_keys=True))
        return code
    if args.command in ("launcher-amendment", "launcher-amendment-observe"):
        observation = {} if args.command == "launcher-amendment" else None
        if observation is not None:
            launcher_guard_mark(observation, "unknown")
        try:
            if args.command == "launcher-amendment":
                result, code = launcher_amendment(args.manifest, args.manifest_sha, args.ready_uuid, args.ready_confirmed, observation)
            else:
                result, code = launcher_amendment_observe(args.manifest, args.manifest_sha,
                    args.binding_receipt_sha, args.prompt_count, args.actions, args.whole_observed)
        except Exception as error:
            preflight = observation is not None and not observation.get("_trusted", False)
            if not preflight and not isinstance(error, (Rejected, OSError, ValueError, KeyError, TypeError, AttributeError)):
                raise  # Preserve the existing observe/trusted-output exception boundary.
            result, code = {"status": "unknown", "failureKind": "guard", "primaryReceiptWritten": False,
                            "callerResultWritten": False, "bindingReceiptSHA256": None}, 1
            if preflight:
                try:
                    result.update(launcher_guard_projection(observation, error))
                except Exception:
                    result.update(guardPoint="unknown", apiOutcome="exception", apiReturn="notAvailable", errnoKind="unknown")
        if observation is not None:
            result["processEvidence"] = launcher_process_projection(observation)
            result["pathFailureEvidence"] = launcher_path_failure_projection(observation)
        print(json.dumps(result, sort_keys=True))
        return code
    try:
        if args.command == "diagnostic-stage":
            result = diagnostic_stage(args.manifest, args.manifest_sha, args.ready_file)
        elif args.command == "diagnostic-observe":
            result = diagnostic_observe(args.manifest, args.manifest_sha, args.human_file)
        elif args.command == "prepare":
            result = prepare(args.repo, args.parent, args.uuid or str(uuid.uuid4()))
        elif args.command == "stage":
            result = stage(args.root, args.phase, args.ready_file, args.identity_file, built_app=args.built_app)
        elif args.command == "observe":
            result = observe(args.root, args.phase, args.human_file, args.recovery_id, args.setup_attempt)
        elif args.command == "retry-setup":
            result = retry_setup(args.root, args.ready_file, args.policy_adoption_file)
        elif args.command == "recover-cleanup":
            result = stage(args.root, "cleanup", args.ready_file, recovery=True)
        elif args.command == "inspect-built":
            root, run = context(args.root)
            ready = load(args.ready_file)
            validate_ready(ready, run["runUUID"], "setup")
            exclusive_json(root / "private" / ("consumed-ready-" + ready["readyUUID"] + ".json"),
                           public_ready(ready))
            identity = freeze_identity(root, args.identity_file)
            selected = contained(root, Path(args.built_app).absolute())
            inspect_selected(selected, Path(identity["profilePath"]), identity,
                             root / "private", "manual-" + ready["readyUUID"])
            result = {"runUUID": run["runUUID"], "status": "selectedAppPreflightOnly"}
        elif args.command == "export":
            result = export_receipts(args.root, args.destination, args.final)
        else:
            result = cleanup_files(args.root)
        print(json.dumps(result, sort_keys=True))
    except (Rejected, OSError, ValueError, KeyError, TypeError, plistlib.InvalidFileException):
        print('{"status":"rejected","failureKind":"guard","privateProofRetained":true}')
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
