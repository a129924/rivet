#!/usr/bin/env bash
set -euo pipefail

experiment="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
repository="$(cd -- "$experiment/../.." && pwd -P)"
run="${INBOX_I3_RUN:-$(mktemp -d "${TMPDIR:-/tmp}/rivet-inbox-i3.XXXXXX")}"
run="$(cd -- "$run" && pwd -P)"
case "$run/" in "$repository/"*) echo "Use a run directory outside the checkout." >&2; exit 1;; esac

case "${1:-}" in
  test|build) package="$experiment" ;;
  regression) package="$repository" ;;
  *) echo "Usage: bash experiments/E026/scripts/verify.sh test|build|regression" >&2; exit 2 ;;
esac

if [[ -z "${APOLLO_CACHE_SOURCE:-}" ]]; then
  main_checkout="$(dirname -- "$(git -C "$repository" rev-parse --path-format=absolute --git-common-dir)")"
  APOLLO_CACHE_SOURCE="$main_checkout/.build/repositories/apollo-ios-b9a1b528"
fi
cache="$run/cache/repositories/apollo-ios-b9a1b528"
mkdir -p "$run/cache/repositories" "$run/modules"
revision="$(python3 - "$repository/Package.resolved" "$experiment/Package.resolved" <<'PY'
import json
import sys
from pathlib import Path

def states(path):
    return {pin["identity"]: pin["state"] for pin in json.loads(Path(path).read_text())["pins"]}

root, experiment = map(states, sys.argv[1:])
if experiment != root:
    raise SystemExit("E026 and the root package must use the same pinned revisions.")
print(root["apollo-ios"]["revision"])
PY
)"
if [[ ! -d "$cache" ]]; then
  git --git-dir="$APOLLO_CACHE_SOURCE" cat-file -e "$revision^{commit}"
  cp -R "$APOLLO_CACHE_SOURCE" "$cache"
fi
git --git-dir="$cache" cat-file -e "$revision^{commit}"

export GIT_CONFIG_COUNT=3
export GIT_CONFIG_KEY_0=protocol.https.allow GIT_CONFIG_VALUE_0=never
export GIT_CONFIG_KEY_1=protocol.http.allow GIT_CONFIG_VALUE_1=never
export GIT_CONFIG_KEY_2=protocol.ssh.allow GIT_CONFIG_VALUE_2=never
options=(
  --package-path "$package" --scratch-path "$run/build-$([[ "$1" == regression ]] && echo root || echo i3)"
  --cache-path "$run/cache" --manifest-cache local --disable-keychain --disable-netrc
  --disable-automatic-resolution
  -Xbuild-tools-swiftc -module-cache-path -Xbuild-tools-swiftc "$run/modules"
  -Xswiftc -module-cache-path -Xswiftc "$run/modules" -Xcc "-fmodules-cache-path=$run/modules"
)
if [[ "${INBOX_I3_DISABLE_SWIFTPM_SANDBOX:-0}" == 1 ]]; then
  options+=(--disable-sandbox)
fi

case "$1" in
  test) exec swift test "${options[@]}" ;;
  regression)
    exec swift test "${options[@]}" --filter 'GitHubSelfReviewSourceTests|PRInbox|RivetPresentationTests'
    ;;
esac

name=InboxI3Verification
swift build "${options[@]}" --product "$name" >&2
bin_dir="$(swift build "${options[@]}" --show-bin-path)"
bundle_dir="$(mktemp -d "$run/app.XXXXXXXX")"
python3 - "$bin_dir" "$bundle_dir" "$name" <<'PY'
import plistlib
import shutil
import sys
from pathlib import Path

binary_root, bundle_dir = map(Path, sys.argv[1:3])
name = sys.argv[3]
app = bundle_dir / f"{name}.app"
executables = app / "Contents" / "MacOS"
bundles = list(binary_root.glob("*.bundle"))
if not (binary_root / name).is_file() or not any(
    bundle.name.endswith("_RivetPresentation.bundle") for bundle in bundles
):
    raise SystemExit("Expected the built executable and its Presentation resource bundle")
info = {
    "CFBundleExecutable": name,
    "CFBundleIdentifier": "local.rivet.inbox-i3-verification",
    "CFBundleName": "Inbox I3 驗證",
    "CFBundlePackageType": "APPL",
    "CFBundleVersion": "1",
    "CFBundleShortVersionString": "1.0",
    "LSMinimumSystemVersion": "15.0",
    "NSHighResolutionCapable": True,
    "NSPrincipalClass": "NSApplication",
}
executables.mkdir(parents=True)
shutil.copy2(binary_root / name, executables / name)
for bundle in bundles:
    shutil.copytree(bundle, app / bundle.name)
with (app / "Contents" / "Info.plist").open("wb") as file:
    plistlib.dump(info, file)
print(app)
PY
