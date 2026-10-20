"""E007: bounded, fake-only profile renewal protocol. No live operation by default."""
import argparse
import datetime as dt
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat
import subprocess
import sys
import tempfile
import uuid

SOURCE = Path(__file__).resolve().parents[1]
FIELDS = {"accessToken", "refreshToken", "accessTokenExpiresAt",
          "refreshTokenExpiresAt", "tokenType", "grantedScopes"}


class Rejected(Exception):
    """Finite classification; never include subprocess output or private values."""


def now_utc():
    return dt.datetime.now(dt.timezone.utc)


def timestamp(value):
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            raise ValueError()
        return parsed.astimezone(dt.timezone.utc)
    except (ValueError, TypeError, AttributeError):
        raise Rejected("invalidTime") from None


def digest(path):
    try:
        return hashlib.sha256(Path(path).read_bytes()).hexdigest()
    except OSError:
        raise Rejected("fileUnavailable") from None


def exclusive_json(path, value):
    path = Path(path)
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    except OSError:
        raise Rejected("exclusiveReceiptRejected") from None
    with os.fdopen(fd, "w") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2, sort_keys=True)
        stream.write("\n")


def private_root(root, namespace):
    root = Path(root)
    try:
        valid = str(uuid.UUID(namespace)) == namespace
        if (not valid or root.name != "rivet-E007-" + namespace or root.is_symlink()
                or not root.is_dir() or root.stat().st_uid != os.getuid()
                or stat.S_IMODE(root.stat().st_mode) != 0o700):
            raise Rejected("privateRootRejected")
    except (ValueError, OSError, AttributeError):
        raise Rejected("privateRootRejected") from None
    return root


def safe(root, relative):
    if Path(relative).is_absolute() or ".." in Path(relative).parts:
        raise Rejected("unsafePath")
    current = Path(root)
    for part in Path(relative).parts:
        current /= part
        if current.is_symlink():
            raise Rejected("symlinkRejected")
    return current


def read_json(root, relative):
    try:
        return json.loads(safe(root, relative).read_text())
    except (OSError, ValueError):
        raise Rejected("receiptMissingOrInvalid") from None


def make_window(namespace, start, ready, free_team):
    if (str(uuid.UUID(namespace)) != namespace or start.tzinfo is None
            or not isinstance(ready, str) or not ready.strip()
            or not isinstance(free_team, str) or not free_team.strip()):
        raise Rejected("humanReadyRequired")
    return {"namespace": namespace, "kind": "setup-window", "synthetic": False,
            "observationMode": "human-only", "humanReadyStatement": ready,
            "freePersonalTeamStatement": free_team, "startUTC": start.isoformat(),
            "cutoffUTC": (start + dt.timedelta(minutes=35)).isoformat(),
            "deadlineUTC": (start + dt.timedelta(minutes=45)).isoformat()}


def validate_window(window, now, measurement):
    start, cutoff, deadline = map(timestamp, (window.get("startUTC"),
                                            window.get("cutoffUTC"), window.get("deadlineUTC")))
    if (window.get("kind") != "setup-window" or window.get("synthetic") is not False
            or window.get("observationMode") != "human-only"
            or not window.get("humanReadyStatement") or not window.get("freePersonalTeamStatement")
            or cutoff - start != dt.timedelta(minutes=35)
            or deadline - start != dt.timedelta(minutes=45)
            or now < start or (measurement and now >= cutoff)):
        raise Rejected("setupWindowRejected")


def validate_host(item, window):
    for key in ("signatureValid", "developmentIdentity", "profileAuthorizesGroup", "profileContainsDevice"):
        if item.get(key) is not True:
            raise Rejected("hostPremiseRejected")
    if item.get("sandboxEnabled") is not False or item.get("debugDylibPresent") is not False:
        raise Rejected("hostPremiseRejected")
    expected = "local.rivet.renewalprobe." + window["namespace"].replace("-", "")
    if item.get("bundleID") != expected or not item.get("group", "").endswith("." + expected):
        raise Rejected("identityRejected")
    deadline = timestamp(window["deadlineUTC"])
    if timestamp(item.get("expiresUTC")) < deadline or timestamp(item.get("certificateExpiresUTC")) < deadline:
        raise Rejected("assetValidityRejected")
    for key in ("profileSHA256", "certificateSHA256", "requirementSHA256", "executableSHA256"):
        value = item.get(key)
        if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
            raise Rejected("digestRejected")


def validate_pair(first, updated, window):
    validate_host(first, window)
    validate_host(updated, window)
    for key in ("bundleID", "group", "certificateSHA256", "requirementSHA256"):
        if first[key] != updated[key]:
            raise Rejected("renewalIdentityChanged")
    if first["profileSHA256"] == updated["profileSHA256"]:
        raise Rejected("profileDidNotChange")


def validate_observation(human, namespace, phase, machine_sha):
    count = human.get("promptCount")
    if (human.get("namespace") != namespace or type(human.get("phase")) is not int
            or human["phase"] != phase or human.get("machineReceiptSHA256") != machine_sha
            or human.get("wholeStageObserved") is not True or type(count) is not int or count < 0):
        raise Rejected("humanObservationRejected")
    for key in ("actions", "purposes"):
        values = human.get(key)
        if (not isinstance(values, list) or len(values) != count
                or any(not isinstance(value, str) or not value.strip() for value in values)):
            raise Rejected("humanObservationRejected")


def classify(premises, fields_match, human, cleanup_complete):
    if not premises or human is None or human.get("wholeStageObserved") is not True or not cleanup_complete:
        return "無法判定"
    if type(human.get("promptCount")) is not int:
        return "無法判定"
    return "成功" if fields_match and human["promptCount"] == 0 else "失敗"


def public_receipt(raw):
    allowed = {"namespace", "phase", "startedUTC", "endedUTC", "completed", "absent",
               "promptCount", "profileSHA256", "executableSHA256", "certificateSHA256",
               "requirementSHA256", "windowSHA256", "synthetic", "observationMode",
               "cleanupComplete", "completedBeforeDeadline", "result", "taskComplete", "readAttempted",
               "profileChanged", "sameIdentity", "sourceSHA256", "error", "status"}
    value = {key: val for key, val in raw.items() if key in allowed}
    if "error" in value:
        allowed_errors = {"missing", "invalidData", "comparison", "accessDenied", "securityFailure",
                          "interactionUnavailable", "guardRejected", "profileUpdateNotValidated"}
        if value["error"] not in allowed_errors:
            value["error"] = "guardRejected"
    if "fields" in raw:
        value["fields"] = {key: val for key, val in raw["fields"].items()
                           if key in FIELDS and type(val) is bool}
    return value



def public_observation(human, private_sha):
    """Keep numeric/phase facts; free text is private and never copied to the repo."""
    actions = {"allow", "alwaysAllow", "deny", "cancel", "enterPasswordThenAllow", "other"}
    purposes = {"credentialRead", "credentialWrite", "credentialDelete", "codeSigning", "profileSetup", "other"}
    result = {key: human[key] for key in ("namespace", "phase", "machineReceiptSHA256",
                                         "wholeStageObserved", "promptCount")}
    result.update(privateObservationSHA256=private_sha, freeTextOmitted=True,
                  actions=[value if value in actions else "other" for value in human["actions"]],
                  purposes=[value if value in purposes else "other" for value in human["purposes"]])
    if "recordedUTC" in human:
        result["recordedUTC"] = timestamp(human["recordedUTC"]).isoformat()
    return result


def valid_machine_identity(machine, proof, window, phase, window_sha, measurement):
    try:
        if (machine.get("namespace") != window["namespace"] or type(machine.get("phase")) is not int
                or machine["phase"] != phase or machine.get("synthetic") is not False
                or machine.get("observationMode") != "human-only" or machine.get("promptCount") is not None
                or machine.get("windowSHA256") != window_sha
                or machine.get("profileSHA256") != proof["profileSHA256"]
                or machine.get("executableSHA256") != proof["executableSHA256"]
                or machine.get("readAttempted") is not True):
            return False
        start, end = timestamp(machine.get("startedUTC")), timestamp(machine.get("endedUTC"))
        return (timestamp(window["startUTC"]) <= start <= end
                and (not measurement or end < timestamp(window["cutoffUTC"])))
    except (Rejected, KeyError):
        return False


def read_outcome(machine, proof, window, phase, window_sha):
    """True/False are credible read outcomes; None is insufficient/technical evidence."""
    if not valid_machine_identity(machine, proof, window, phase, window_sha, measurement=True):
        return None
    if machine.get("completed") is True and "error" not in machine:
        fields = machine.get("fields")
        if (isinstance(fields, dict) and set(fields) == FIELDS
                and all(type(value) is bool and value for value in fields.values())):
            return True
        return None
    if machine.get("completed") is False and "fields" not in machine:
        error = machine.get("error")
        if error in ("missing", "invalidData", "comparison"):
            return False
        if error == "accessDenied" and type(machine.get("status")) is int and machine["status"] in (-25293, -128):
            return False
    return None


def e006_helpers():
    # Reuse reviewed inspection, not its same-profile live-run gate.
    directory = SOURCE.parent / "E006/scripts"
    sys.path.insert(0, str(directory))
    spec = importlib.util.spec_from_file_location("e006_preflight", directory / "preflight.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def inspect_selected(app, root, window):
    if os.getuid() == 0 or os.stat("/dev/console").st_uid != os.getuid():
        raise Rejected("guiUserSessionRequired")
    helpers = e006_helpers()
    try:
        with tempfile.TemporaryDirectory(prefix="selected-", dir=root) as temporary:
            item = helpers.inspect_app(app, temporary)
            hardware, _ = helpers.command(["/usr/sbin/system_profiler", "SPHardwareDataType", "-json"])
            device = helpers.provisioning_device_id(hardware)
            helpers.validate_profile(item["profile"], item["entitlements"], device,
                                     timestamp(window["startUTC"]), validated_at=now_utc())
        entitlements = item["entitlements"]
        identifier = entitlements.get("com.apple.application-identifier")
        groups = entitlements.get("keychain-access-groups")
        if not isinstance(identifier, str) or groups != [identifier] or "*" in identifier:
            raise Rejected("privateGroupRejected")
        bundle_id = item["info"].get("CFBundleIdentifier")
        minimum = item["info"].get("LSMinimumSystemVersion", "")
        if not isinstance(minimum, str) or int(minimum.split(".")[0]) < 15:
            raise Rejected("minimumHostVersionRejected")
        prefix = identifier[:-(len(bundle_id) + 1)]
        if prefix not in item["profile"].get("ApplicationIdentifierPrefix", []):
            raise Rejected("profilePrefixRejected")
        normalized = {
            "bundleID": bundle_id, "group": identifier,
            "certificateSHA256": item["certificateHash"], "profileSHA256": item["profileHash"],
            "requirementSHA256": hashlib.sha256(item["requirement"].encode()).hexdigest(),
            "executableSHA256": item["hash"],
            "expiresUTC": item["profile"]["ExpirationDate"].replace(tzinfo=dt.timezone.utc).isoformat(),
            "certificateExpiresUTC": item["certificateExpiry"].isoformat(),
            "signatureValid": True, "developmentIdentity": True, "profileAuthorizesGroup": True,
            "profileContainsDevice": True, "sandboxEnabled": entitlements.get("com.apple.security.app-sandbox", False),
            "debugDylibPresent": any(Path(app).glob("Contents/MacOS/*.debug.dylib")),
        }
        validate_host(normalized, window)
        normalized["requirement"] = item["requirement"]  # Private, never exported.
        normalized["entitlements"] = entitlements
        return normalized
    except Rejected:
        raise
    except Exception:
        raise Rejected("selectedHostRejected") from None


def begin(args):
    if not args.live:
        raise Rejected("explicitLiveRequired")
    window = make_window(args.namespace, now_utc(), args.human_ready, args.free_personal_team)
    root = Path(args.root)
    if root.exists() or root.is_symlink():
        raise Rejected("runAlreadyExists")
    root.mkdir(mode=0o700)
    private_root(root, args.namespace)
    exclusive_json(root / "window.json", window)  # Frozen before setup or Xcode.
    for directory in ("receipts", "private", "current", "initial", "Setup"):
        (root / directory).mkdir(mode=0o700)
    for name in ("Sources", "Resources", "ProfileRenewalProbe.xcodeproj"):
        shutil.copytree(SOURCE / name, root / "Setup" / name)
    project = root / "Setup/ProfileRenewalProbe.xcodeproj/project.pbxproj"
    project.write_text(project.read_text().replace("local.rivet.renewalprobe.unconfigured",
                       "local.rivet.renewalprobe." + args.namespace.replace("-", "")))
    exclusive_json(root / "private/source.json", {"probeSHA256": digest(SOURCE / "Sources/ProfileRenewalProbe.swift")})
    print("Setup prepared; original 35/45-minute window is active. No Security operation performed.")


def ensure_previous_process_exited(root):
    for path in safe(root, "private").glob("process-*.json"):
        pid = read_json(root, str(path.relative_to(root))).get("pid")
        if type(pid) is not int or pid <= 1:
            raise Rejected("processReceiptRejected")
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            continue
        except OSError:
            raise Rejected("processStateUnknown") from None
        raise Rejected("previousProcessStillPresent")


def phase(args):
    root = private_root(args.root, args.namespace)
    window = read_json(root, "window.json")
    cleanup = args.phase == "cleanup"
    number = {"save": 1, "read": 2, "cleanup": 3}[args.phase]
    validate_window(window, now_utc(), measurement=not cleanup)
    if window["namespace"] != args.namespace or not args.human_ready.strip():
        raise Rejected("freshHumanReadyRequired")
    ensure_previous_process_exited(root)
    expected_source = read_json(root, "private/source.json")["probeSHA256"]
    if (expected_source != digest(SOURCE / "Sources/ProfileRenewalProbe.swift")
            or expected_source != digest(root / "Setup/Sources/ProfileRenewalProbe.swift")):
        raise Rejected("sourceChanged")
    if number == 2:
        previous = root / "receipts/phase-1.machine.json"
        human = read_json(root, "receipts/phase-1.human.json")
        validate_observation(human, args.namespace, 1, digest(previous))
        if human["promptCount"] > 1 or not read_json(root, "receipts/phase-1.machine.json").get("completed"):
            raise Rejected("initialStageFailed")
    selected = Path(args.app) if not cleanup else root / "initial/ProfileRenewalProbe.app"
    proof = inspect_selected(selected, root, window)
    if number == 1:
        if safe(root, "private/first.json").exists():
            raise Rejected("initialStageAlreadyPrepared")
        exclusive_json(root / "private/first.json", proof)
        shutil.copytree(selected, root / "initial/ProfileRenewalProbe.app")
    elif number == 2:
        first = read_json(root, "private/first.json")
        validate_pair(first, proof, window)
        helpers = e006_helpers()
        try:
            helpers.command(["/usr/bin/codesign", "--verify", "--strict", "-R=" + first["requirement"], str(selected)])
            helpers.command(["/usr/bin/codesign", "--verify", "--strict", "-R=" + proof["requirement"],
                             str(root / "initial/ProfileRenewalProbe.app")])
        except Exception:
            raise Rejected("crossRequirementRejected") from None
        exclusive_json(root / "private/updated.json", proof)
        exclusive_json(root / "receipts/preflight.machine.json",
                       public_receipt(dict(proof, namespace=args.namespace, completed=True, profileChanged=True,
                                           sameIdentity=True, synthetic=False, observationMode="human-only",
                                           windowSHA256=digest(root / "window.json"))))
    else:
        first = read_json(root, "private/first.json")
        if any(proof[key] != first[key] for key in ("bundleID", "group", "certificateSHA256", "profileSHA256")):
            raise Rejected("cleanupIdentityRejected")
    # current is a dedicated copy owned by this run; no other app path is replaced.
    current = safe(root, "current/ProfileRenewalProbe.app")
    if current.exists():
        shutil.rmtree(current)
    shutil.copytree(selected, current)
    installed = inspect_selected(current, root, window)
    if any(installed[key] != proof[key] for key in ("profileSHA256", "executableSHA256", "certificateSHA256", "group")):
        raise Rejected("installedHostChanged")
    permit = {"namespace": args.namespace, "phase": number, "operation": args.phase,
              "windowSHA256": digest(root / "window.json"), "profileSHA256": proof["profileSHA256"],
              "executableSHA256": proof["executableSHA256"], "bundleID": proof["bundleID"],
              "group": proof["group"], "humanReadyStatement": args.human_ready,
              "createdUTC": now_utc().isoformat(), "sourceSHA256": digest(SOURCE / "Sources/ProfileRenewalProbe.swift")}
    if number == 2:
        permit["initialProfileSHA256"] = read_json(root, "private/first.json")["profileSHA256"]
        permit["previousHumanSHA256"] = digest(root / "receipts/phase-1.human.json")
    exclusive_json(root / f"private/permit-{number}.json", permit)
    validate_window(window, now_utc(), measurement=not cleanup)
    try:
        result = subprocess.run(["/usr/bin/open", "-W", "-n", str(current), "--args",
                                 "--root", str(root), "--namespace", args.namespace, "--phase", str(number)],
                                capture_output=True, timeout=120, check=False)
    except subprocess.TimeoutExpired:
        raise Rejected("probeTimeoutNeedsHumanCleanup") from None
    machine_path = root / ("receipts/cleanup.machine.json" if cleanup else f"receipts/phase-{number}.machine.json")
    if result.returncode or not machine_path.is_file():
        raise Rejected("probeReceiptMissingNeedsCleanup")
    machine = read_json(root, str(machine_path.relative_to(root)))
    ensure_previous_process_exited(root)
    print(json.dumps(public_receipt(machine), ensure_ascii=False, sort_keys=True))


def observe(args):
    root = private_root(args.root, args.namespace)
    relative = "receipts/cleanup.machine.json" if args.phase == 3 else f"receipts/phase-{args.phase}.machine.json"
    machine_path = safe(root, relative)
    human = {"namespace": args.namespace, "phase": args.phase, "machineReceiptSHA256": digest(machine_path),
             "wholeStageObserved": args.whole_stage, "promptCount": args.prompt_count,
             "actions": args.action, "purposes": args.purpose, "statement": args.statement,
             "recordedUTC": now_utc().isoformat()}
    validate_observation(human, args.namespace, args.phase, digest(machine_path))
    output = "receipts/cleanup.human.json" if args.phase == 3 else f"receipts/phase-{args.phase}.human.json"
    exclusive_json(root / output, human)
    print("Human observation recorded against exact machine receipt; machine promptCount remains null.")


def finalize(args):
    root = private_root(args.root, args.namespace)
    window = read_json(root, "window.json")
    premises = False
    try:
        first = read_json(root, "private/first.json")
        updated = read_json(root, "private/updated.json")
        validate_pair(first, updated, window)
        premises = True
    except Rejected:
        pass
    human = None
    initial_ok = False
    try:
        h1 = read_json(root, "receipts/phase-1.human.json")
        validate_observation(h1, args.namespace, 1, digest(root / "receipts/phase-1.machine.json"))
        initial_ok = h1["promptCount"] <= 1
        initial_machine = read_json(root, "receipts/phase-1.machine.json")
        if read_outcome(initial_machine, read_json(root, "private/first.json"), window, 1,
                        digest(root / "window.json")) is not True:
            premises = False
        candidate = read_json(root, "receipts/phase-2.human.json")
        validate_observation(candidate, args.namespace, 2, digest(root / "receipts/phase-2.machine.json"))
        human = candidate
    except Rejected:
        pass
    fields_match = False
    try:
        machine = read_json(root, "receipts/phase-2.machine.json")
        read_result = read_outcome(machine, read_json(root, "private/updated.json"), window, 2,
                                   digest(root / "window.json"))
        fields_match = read_result is True
        if read_result is None:
            premises = False
    except Rejected:
        pass
    cleanup_complete = False
    try:
        machine = read_json(root, "receipts/cleanup.machine.json")
        hc = read_json(root, "receipts/cleanup.human.json")
        validate_observation(hc, args.namespace, 3, digest(root / "receipts/cleanup.machine.json"))
        cleanup_complete = (machine.get("absent") is True and machine.get("completed") is True
                            and valid_machine_identity(machine, read_json(root, "private/first.json"),
                                                       window, 3, digest(root / "window.json"), measurement=False))
        cleanup_on_time = timestamp(machine["endedUTC"]) <= timestamp(window["deadlineUTC"])
    except Rejected:
        cleanup_on_time = False
    result = classify(premises, fields_match and initial_ok, human, cleanup_complete and cleanup_on_time)
    public = public_receipt(dict(namespace=args.namespace, synthetic=False, observationMode="human-only",
                               result=result, taskComplete=False, cleanupComplete=cleanup_complete,
                               completedBeforeDeadline=cleanup_on_time,
                               startedUTC=window["startUTC"], endedUTC=now_utc().isoformat()))
    exclusive_json(root / "receipts/outcome.json", public)  # Private, final task judgment belongs to Tester/Reviewer.
    print(json.dumps(public, ensure_ascii=False, sort_keys=True))
    print("Private file cleanup and independent validation remain required; this is not adoption approval.")



def export_clean(args):
    """Export only bounded public receipts, then remove this proven-owned private run."""
    root = private_root(args.root, args.namespace)
    window = read_json(root, "window.json")
    if not args.human_project_closed.strip():
        raise Rejected("humanProjectClosureRequired")
    ensure_previous_process_exited(root)
    may_have_written = safe(root, "private/permit-1.json").exists()
    if may_have_written:
        cleanup = read_json(root, "receipts/cleanup.machine.json")
        if cleanup.get("completed") is not True or cleanup.get("absent") is not True:
            raise Rejected("credentialCleanupRequired")
        human = read_json(root, "receipts/cleanup.human.json")
        validate_observation(human, args.namespace, 3, digest(root / "receipts/cleanup.machine.json"))
    start = timestamp(window["startUTC"]).strftime("%Y%m%dT%H%M%SZ")
    output = SOURCE / "evidence" / ("run-" + start + "-" + args.namespace)
    if output.exists() or output.is_symlink():
        raise Rejected("publicEvidenceAlreadyExists")
    output.mkdir(parents=True, mode=0o700)
    summary = {key: window[key] for key in ("namespace", "kind", "synthetic", "observationMode",
                                          "startUTC", "cutoffUTC", "deadlineUTC")}
    summary.update(privateWindowSHA256=digest(root / "window.json"),
                   humanSetupReadyDeclared=True, freePersonalTeamDeclared=True)
    exclusive_json(output / "window.json", summary)
    names = ("preflight.machine.json", "phase-1.machine.json", "phase-1.human.json",
             "phase-2.machine.json", "phase-2.human.json", "cleanup.machine.json", "cleanup.human.json")
    for name in names:
        source = safe(root, "receipts/" + name)
        if source.exists():
            # Machine bytes are already bounded by ProbeMain; keep observation SHA links exact.
            value = read_json(root, "receipts/" + name)
            if name.endswith(".machine.json") and value != public_receipt(value):
                raise Rejected("unboundedMachineReceipt")
            if name.endswith(".human.json"):
                phase_number = 3 if name.startswith("cleanup") else int(name.split("-")[1].split(".")[0])
                machine_name = "cleanup.machine.json" if phase_number == 3 else f"phase-{phase_number}.machine.json"
                validate_observation(value, args.namespace, phase_number, digest(root / "receipts" / machine_name))
                exclusive_json(output / name, public_observation(value, digest(source)))
            else:
                (output / name).write_bytes(source.read_bytes())
    if not (output / "preflight.machine.json").exists():
        exclusive_json(output / "preflight.machine.json",
                       {"namespace": args.namespace, "completed": False, "synthetic": False,
                        "observationMode": "human-only", "error": "profileUpdateNotValidated"})
    source_hashes = {str(path.relative_to(SOURCE)): digest(path) for path in (
        SOURCE / "Sources/ProfileRenewalProbe.swift", SOURCE / "scripts/run_profile_renewal.py",
        SOURCE / "ProfileRenewalProbe.xcodeproj/project.pbxproj",
        SOURCE / "Resources/Info.plist", SOURCE / "Resources/ProfileRenewalProbe.entitlements")}
    # root was exclusively created by begin; never remove selected source Apps or Apple assets.
    shutil.rmtree(root)
    removed = not root.exists() and not root.is_symlink()
    ended = now_utc()
    index = {"namespace": args.namespace, "synthetic": False, "observationMode": "human-only",
             "privateFilesRemoved": removed, "humanProjectClosedDeclared": True,
             "cleanupComplete": removed and (may_have_written is False or cleanup.get("absent") is True),
             "completedBeforeDeadline": ended <= timestamp(window["deadlineUTC"]),
             "endedUTC": ended.isoformat(), "sourceSHA256": source_hashes,
             "scope": "live receipts; independent Tester/Reviewer receipts are added separately",
             "files": {path.name: {"sha256": digest(path), "bytes": path.stat().st_size}
                       for path in sorted(output.iterdir()) if path.is_file()}}
    exclusive_json(output / "final.index.json", index)
    print("Public bounded receipts exported; proven-owned private run removed. Apple assets retained.")
    print("Independent Tester/Reviewer and Human adoption remain required.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("begin", "phase", "observe", "finalize", "export-clean"):
        command = commands.add_parser(name)
        command.add_argument("--root", type=Path, required=True)
        command.add_argument("--namespace", required=True)
    start = commands.choices["begin"]
    start.add_argument("--live", action="store_true")
    start.add_argument("--human-ready", required=True)
    start.add_argument("--free-personal-team", required=True)
    run = commands.choices["phase"]
    run.add_argument("--phase", choices=("save", "read", "cleanup"), required=True)
    run.add_argument("--app", type=Path)
    run.add_argument("--human-ready", required=True)
    human = commands.choices["observe"]
    human.add_argument("--phase", type=int, choices=(1, 2, 3), required=True)
    human.add_argument("--whole-stage", action="store_true")
    human.add_argument("--prompt-count", type=int, required=True)
    human.add_argument("--action", action="append", default=[])
    human.add_argument("--purpose", action="append", default=[])
    human.add_argument("--statement", required=True)
    clean = commands.choices["export-clean"]
    clean.add_argument("--human-project-closed", required=True)
    args = parser.parse_args()
    try:
        {"begin": begin, "phase": phase, "observe": observe, "finalize": finalize, "export-clean": export_clean}[args.command](args)
        return 0
    except Rejected as error:
        print("E007 stopped: " + str(error) + ". No outcome or prompt count inferred.")
        return 2
    except Exception:
        print("E007 stopped: controlledTechnicalFailure. Preserve private evidence; cleanup may be required.")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
