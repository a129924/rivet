#!/usr/bin/env python3
"""One experiment owns cleanup. Child writer/reader exit deliberately keeps its item."""
import argparse
import hashlib
import signal
import datetime
import json
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path
from build_probe import build, identity, public_identity


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", choices=["legacy"], required=True,
                        help="DPK is not eligible until its free profile preflight is established")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--stop-after-write", action="store_true",
                        help="Separate isolated run verifying whole-experiment early-exit cleanup")
    args = parser.parse_args()
    namespace, negative = str(uuid.uuid4()), str(uuid.uuid4())
    scratch = Path(tempfile.mkdtemp(prefix="rivet-E005-"))
    app, backup = scratch / "KeychainProbe.app", scratch / "Original.app"
    report = {"startedUTC": now(), "backend": args.backend,
              "primaryNamespace": namespace, "negativeNamespace": negative,
              "selectionBeforeFirstWrite": True,
              "selectionReason": "free DPK profile not established; explicitly select legacy",
              "data": "fixed fake credentials only", "commands": [], "cleanup": [],
              "promptObservation": "unobserved: no human/system-dialog observation supplied",
              "trueDenial": "未執行: no naturally observed denial prompt",
              "experimentStatus": "無法判定", "validationTaskComplete": False,
              "forcedEarlyExit": args.stop_after_write}
    attempted = []
    executable = None
    report["sourceSHA256"] = {
        name: hashlib.sha256((Path(__file__).resolve().parents[1] / name).read_bytes()).hexdigest()
        for name in ("Sources/KeychainProbe.swift", "scripts/build_probe.py", "scripts/run_probe.py")
    }
    report["controlledStopSignals"] = ["SIGINT", "SIGTERM"]

    def request_stop(signum, _frame):
        raise RuntimeError("controlledSignalStop:" + signal.Signals(signum).name)

    signal.signal(signal.SIGINT, request_stop)
    signal.signal(signal.SIGTERM, request_stop)

    def command(mode, item):
        entry = {"mode": mode, "namespace": item, "startedUTC": now(), "promptCount": None}
        report["commands"].append(entry)
        print("probe: " + mode, flush=True)
        try:
            result = subprocess.run([str(executable), mode, args.backend, item],
                                    capture_output=True, text=True, timeout=20)
            entry["exitCode"] = result.returncode
            entry["output"] = [json.loads(line) for line in result.stdout.splitlines() if line]
            # Never retain raw stderr or OS dialogs, which may contain personal information.
            entry["stderrPresent"] = bool(result.stderr)
            return result.returncode == 0
        except subprocess.TimeoutExpired:
            entry["timedOut"] = True
            return False
        except (OSError, json.JSONDecodeError):
            entry["executionOrOutputFailure"] = True
            return False
        finally:
            entry["finishedUTC"] = now()

    try:
        executable = build(app)
        before = identity(app)
        report["hostBefore"] = public_identity(before)
        report["preflight"] = {"host": "app-like CLI", "signing": "ad-hoc, no certificate/profile",
                               "paidQualificationRequired": False, "DPKEligible": False,
                               "DPKFreeProfile": "not established; no account operation attempted"}
        if not before["signatureValid"] or not before["adHoc"] or before["profilePresent"]:
            raise RuntimeError("hostPreflightFailed")
        shutil.copytree(app, backup)
        if not command("synthetic-check", namespace):
            raise RuntimeError("syntheticClassificationFailed")
        attempted.append(namespace)  # Register before attempting the write, even if it fails.
        if not command("write-a", namespace):
            raise RuntimeError("writeAFailed")
        if args.stop_after_write:
            raise RuntimeError("injected whole-experiment stop after first write")
        else:
            first = command("read-a", namespace)
            second = command("read-a", namespace)
            report["T02Data"] = "成功" if first and second else "失敗"
            if not first or not second:
                raise RuntimeError("readAFailed")
            executable = build(app, rebuilt=True)
            after = identity(app)
            report["hostAfter"] = public_identity(after)
            checks = {"binaryChanged": before["binarySHA256"] != after["binarySHA256"],
                      "designatedRequirementEqual": bool(before["_requirement"]) and
                          before["_requirement"] == after["_requirement"],
                      "entitlementsEqual": before["entitlementsReadSucceeded"] and after["entitlementsReadSucceeded"] and before["_entitlements"] == after["_entitlements"],
                      "accessGroupsEqual": before["entitlementsReadSucceeded"] and after["entitlementsReadSucceeded"] and before["_entitlements"] == after["_entitlements"],
                      "bundleIdentifierEqual": before["_bundleID"] == after["_bundleID"],
                      "hostPathEqual": True, "signingMethodEqual": before["adHoc"] and after["adHoc"]}
            report["rebuildComparison"] = checks
            if checks["binaryChanged"] and checks["designatedRequirementEqual"] and after["signatureValid"]:
                report["T03Data"] = "成功" if command("read-a", namespace) else "失敗"
            else:
                report["T03Data"] = "無法判定"
                report["T03Reason"] = "rebuilt binary has no demonstrated stable designated requirement; no acceptance read"
            # Restore original identity only for independent T04/T05 and cleanup, never as T03 evidence.
            shutil.rmtree(app)
            shutil.copytree(backup, app)
            executable = app / "Contents/MacOS/keychain-probe"
            report["originalIdentityRestoredForT04AndCleanup"] = identity(app)["_requirement"] == before["_requirement"]
            replaced = command("replace-b", namespace)
            read_b = command("read-b", namespace) if replaced else False
            report["T04Data"] = "成功" if replaced and read_b else "失敗"
            if not replaced or not read_b:
                raise RuntimeError("replaceBFailed")
            # Normal phase has ended. Negative operations use a distinct UUID item.
            absent = command("read-absent", negative)
            attempted.append(negative)
            invalid_write = command("write-invalid", negative)
            invalid_read = command("read-invalid", negative) if invalid_write else False
            report["T05AbsentAndMalformed"] = "成功" if absent and invalid_write and invalid_read else "失敗"
    except Exception as error:
        # Our explicit stage names are non-secret; suppress arbitrary external exception text.
        report["stopReason"] = str(error) if isinstance(error, RuntimeError) else type(error).__name__
        report["stopReason"] = report["stopReason"].replace(str(scratch), "<scratch>")
    finally:
        # A repeated catchable stop must not interrupt cleanup or receipt persistence.
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        # Whole-experiment cleanup: child process normal exit does not delete anything.
        if backup.exists():
            try:
                if app.exists():
                    shutil.rmtree(app)
                shutil.copytree(backup, app)
                executable = app / "Contents/MacOS/keychain-probe"
            except OSError:
                report["cleanupHostRestoreFailed"] = True
        for item in attempted:
            deleted = command("delete", item) if executable else False
            absent = command("read-absent", item) if deleted else False
            report["cleanup"].append({"namespace": item, "deleteSucceeded": deleted,
                                      "absenceConfirmed": absent})
        clean = all(entry["absenceConfirmed"] for entry in report["cleanup"]) and not report.get("cleanupHostRestoreFailed", False)
        report["cleanupComplete"] = clean
        report["finishedUTC"] = now()
        # Unknown UX and unmet same-identity rebuild precondition preclude overall success.
        report["limitations"] = ["normal system authorization prompts not observed",
                                 "DPK free host/profile not verified",
                                 "same-identity rebuild not established if designated requirement changed",
                                 "true denial not observed; synthetic classification is separate",
                                 "SIGKILL, process crash and host failure cannot guarantee finally cleanup"]
        report["validationTaskComplete"] = clean and report.get("T02Data") == "成功" and report.get("T04Data") == "成功" and report.get("T05AbsentAndMalformed") == "成功" and not args.stop_after_write
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
        if clean:
            shutil.rmtree(scratch)
        else:
            print("cleanup incomplete: retain isolated host for remediation; see namespaces in receipt", flush=True)
    print(json.dumps({"experimentStatus": report["experimentStatus"],
                      "cleanupComplete": report["cleanupComplete"],
                      "validationTaskComplete": report["validationTaskComplete"]}, ensure_ascii=False))
    return 0 if report["cleanupComplete"] and (report.get("T04Data") == "成功" or args.stop_after_write) else 1


if __name__ == "__main__":
    raise SystemExit(main())
