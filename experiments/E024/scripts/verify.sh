#!/usr/bin/env bash
set -euo pipefail

experiment="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
repository="$(cd -- "$experiment/../.." && pwd -P)"
run="${INBOX_I1_RUN:-$(mktemp -d "${TMPDIR:-/tmp}/rivet-inbox-i1.XXXXXX")}"
run="$(cd -- "$run" && pwd -P)"
case "$run/" in "$repository/"*) echo "Choose a run directory outside the checkout." >&2; exit 1;; esac
mode="${1:-}"
case "$mode" in test|build) ;; *) echo "Usage: bash experiments/E024/scripts/verify.sh test|build" >&2; exit 2;; esac

main_checkout="$(dirname -- "$(git -C "$repository" rev-parse --path-format=absolute --git-common-dir)")"
cache_source="${APOLLO_CACHE_SOURCE:-$main_checkout/.build/repositories/apollo-ios-b9a1b528}"
read_pins() {
  python3 - "$1" <<'PY'
import json
import sys

with open(sys.argv[1]) as file:
    pins = json.load(file)["pins"]
print(json.dumps({pin["identity"]: pin["state"] for pin in pins}, sort_keys=True))
PY
}
root_pins="$(read_pins "$repository/Package.resolved")"
revision="$(python3 -c 'import json, sys; print(json.loads(sys.argv[1])["apollo-ios"]["revision"])' "$root_pins")"
if ! git --git-dir="$cache_source" cat-file -e "$revision^{commit}"; then
  echo "Set APOLLO_CACHE_SOURCE to an existing bare Apollo cache containing the root pin." >&2
  exit 1
fi

mkdir -p "$run/cache/repositories" "$run/modules"
cache="$run/cache/repositories/apollo-ios-b9a1b528"
if [[ ! -d "$cache" ]]; then cp -R "$cache_source" "$cache"; fi
git --git-dir="$cache" cat-file -e "$revision^{commit}"
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0=protocol.https.allow GIT_CONFIG_VALUE_0=never
export GIT_CONFIG_KEY_1=protocol.http.allow GIT_CONFIG_VALUE_1=never
options=(
  --package-path "$experiment" --scratch-path "$run/scratch" --cache-path "$run/cache"
  --manifest-cache local --skip-update --disable-keychain --disable-netrc
  -Xbuild-tools-swiftc -module-cache-path -Xbuild-tools-swiftc "$run/modules"
  -Xswiftc -module-cache-path -Xswiftc "$run/modules" -Xcc "-fmodules-cache-path=$run/modules"
)

if [[ ! -f "$experiment/Package.resolved" ]]; then
  swift package "${options[@]}" resolve
fi
if [[ "$(read_pins "$experiment/Package.resolved")" != "$root_pins" ]]; then
  echo "E024 and the root package must resolve the same pinned revisions." >&2
  exit 1
fi
options+=(--disable-automatic-resolution)
if [[ "$mode" == test ]]; then
  swift test "${options[@]}"
  exit
fi

swift build "${options[@]}" --product InboxI1Verification
bin_dir="$(swift build "${options[@]}" --show-bin-path)"
python3 - "$bin_dir" "$run" <<'PY'
import plistlib
import shutil
import sys
from pathlib import Path

binary_root, run = map(Path, sys.argv[1:])
name = "InboxI1Verification"
app = run / f"{name}.app"
executables = app / "Contents" / "MacOS"
bundles = list(binary_root.glob("*_RivetPresentation.bundle"))
if not (binary_root / name).is_file() or len(bundles) != 1:
    raise SystemExit("Expected the built executable and its Presentation resource bundle")
executables.mkdir(parents=True)
shutil.copy2(binary_root / name, executables / name)
shutil.copytree(bundles[0], app / bundles[0].name)
with (app / "Contents" / "Info.plist").open("wb") as info:
    plistlib.dump({
        "CFBundleExecutable": name,
        "CFBundleIdentifier": "local.rivet.inbox-i1-verification",
        "CFBundleName": "Inbox I1 驗證",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
        "LSMinimumSystemVersion": "15.0",
        "NSHighResolutionCapable": True,
        "NSPrincipalClass": "NSApplication",
    }, info)
print(app)
PY
