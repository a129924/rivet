#!/usr/bin/env python3
"""Build an app-like, ad-hoc-signed CLI without root package or account changes."""
import hashlib
import plistlib
import subprocess
from pathlib import Path

BUNDLE_ID = "com.rivet.experiments.E005.KeychainProbe"
EXPERIMENT = Path(__file__).resolve().parents[1]
REPOSITORY = EXPERIMENT.parents[1]
CONTRACTS = REPOSITORY / "Sources/BoundedContexts/GitHubIntegration/Contracts"

def build(app: Path, rebuilt=False):
    executable = app / "Contents/MacOS/keychain-probe"
    executable.parent.mkdir(parents=True, exist_ok=True)
    info = {"CFBundleIdentifier": BUNDLE_ID, "CFBundleExecutable": "keychain-probe",
            "CFBundleName": "KeychainProbe", "CFBundlePackageType": "APPL",
            "CFBundleVersion": "1"}
    (app / "Contents/Info.plist").write_bytes(plistlib.dumps(info))
    command = ["swiftc", "-swift-version", "6", "-parse-as-library",
               "-module-name", "KeychainProbe", "-module-cache-path", str(app.parent / "ModuleCache")]
    if rebuilt:
        command += ["-D", "REBUILT"]
    command += [str(CONTRACTS / name) for name in
                ("CredentialTypes.swift", "GitHubOAuthCredentialBundle.swift", "OAuthCredentialStore.swift")]
    command += [str(EXPERIMENT / "Sources/KeychainProbe.swift"), "-o", str(executable)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=120)
    if result.returncode:
        # Compiler diagnostics can contain local paths: sanitize before returning them.
        diagnostics = result.stderr.replace(str(REPOSITORY), "<repository>").replace(str(app.parent), "<scratch>")
        raise RuntimeError("compilerFailure: " + diagnostics)
    subprocess.run(["codesign", "--force", "--sign", "-", "--identifier", BUNDLE_ID, str(app)],
                   check=True, capture_output=True, timeout=20)
    return executable

def identity(app: Path):
    executable = app / "Contents/MacOS/keychain-probe"
    details = subprocess.run(["codesign", "-dvv", str(app)], capture_output=True, text=True, timeout=20)
    requirement = subprocess.run(["codesign", "-d", "-r-", str(app)], capture_output=True, text=True, timeout=20)
    entitlements = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)],
                                 capture_output=True, timeout=20)
    verification = subprocess.run(["codesign", "--verify", "--strict", str(app)], capture_output=True, timeout=20)
    # Keep raw requirement/entitlement bytes only in memory for the before/after comparison.
    requirement_line = next((line for line in (requirement.stdout + requirement.stderr).splitlines()
                             if line.lstrip("# ").startswith("designated =>")), "").lstrip("# ")
    return {"binarySHA256": hashlib.sha256(executable.read_bytes()).hexdigest(),
            "signatureValid": verification.returncode == 0,
            "adHoc": "Signature=adhoc" in details.stderr,
            "teamIdentifierPresent": "TeamIdentifier=not set" not in details.stderr,
            "profilePresent": (app / "Contents/embedded.provisionprofile").exists(),
            "requirementAvailable": bool(requirement_line),
            "entitlementsReadSucceeded": entitlements.returncode == 0,
            "_requirement": requirement_line,
            "_entitlements": entitlements.stdout,
            "_bundleID": plistlib.loads((app / "Contents/Info.plist").read_bytes())["CFBundleIdentifier"]}

def public_identity(value):
    return {key: item for key, item in value.items() if not key.startswith("_")}
