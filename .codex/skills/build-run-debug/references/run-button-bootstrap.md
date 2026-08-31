# Run Button Bootstrap

This is the canonical bootstrap contract for the macOS Build plugin's local run
loop.

When a project does not already have an established macOS run entrypoint:

1. Create one project-local `script/build_and_run.sh`.
2. Make it executable.
3. Use it as the single kill + build + run entrypoint.
4. Support optional `--debug`, `--logs`, `--telemetry`, and `--verify` flags.
5. Write `.codex/environments/environment.toml` so the Codex app exposes a
   `Run` action wired to that script.

## `script/build_and_run.sh`

Use one project-specific script with a tiny mode switch and a default no-flag
path that stops a verified target process, builds, and launches. Keep raw
executable launch only for true command-line tools. For SwiftPM AppKit/SwiftUI
GUI apps, stage a project-local `.app` bundle and launch that bundle with
`/usr/bin/open` (without `-n`).

### SwiftPM CLI executable

Use this shape for true command-line tools:

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MyTool"
APP_PROCESS_NAME="$APP_NAME" # 必須能唯一識別此工具的 process

stop_running_process() {
  local matched_pids pid_count target_pid
  matched_pids="$(pgrep -x "$APP_PROCESS_NAME" || true)"
  [[ -z "$matched_pids" ]] && return 0
  pid_count="$(printf '%s\n' "$matched_pids" | awk 'NF { count++ } END { print count + 0 }')"
  if [[ "$pid_count" -ne 1 ]]; then
    echo "multiple processes matched '$APP_PROCESS_NAME'; nothing was stopped. A human must provide a unique selector before retrying." >&2
    return 2
  fi
  target_pid="$matched_pids"
  kill "$target_pid"
  for _ in {1..25}; do
    kill -0 "$target_pid" 2>/dev/null || return 0
    sleep 0.2
  done
  echo "target process did not stop: $target_pid" >&2
  return 1
}

stop_running_process

swift build
APP_BINARY="$(swift build --show-bin-path)/$APP_NAME"

case "$MODE" in
  run)
    "$APP_BINARY"
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    "$APP_BINARY" &
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    "$APP_BINARY" &
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"com.example.MyTool\""
    ;;
  --verify|verify)
    "$APP_BINARY" &
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
```

### SwiftPM AppKit/SwiftUI GUI app

Use this shape for SwiftPM GUI apps so they launch as a real foreground app
bundle with Dock activation and bundle metadata:

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MyApp"
APP_PROCESS_NAME="$APP_NAME" # 必須能唯一識別此 app 的 process
BUNDLE_ID="com.example.MyApp"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

stop_running_app() {
  local matched_pids pid_count target_pid
  matched_pids="$(pgrep -x "$APP_PROCESS_NAME" || true)"
  [[ -z "$matched_pids" ]] && return 0
  pid_count="$(printf '%s\n' "$matched_pids" | awk 'NF { count++ } END { print count + 0 }')"
  if [[ "$pid_count" -ne 1 ]]; then
    echo "multiple processes matched '$APP_PROCESS_NAME'; nothing was stopped. A human must provide a unique selector before retrying." >&2
    return 2
  fi
  target_pid="$matched_pids"
  kill "$target_pid"
  for _ in {1..25}; do
    kill -0 "$target_pid" 2>/dev/null || return 0
    sleep 0.2
  done
  echo "target app process did not stop: $target_pid" >&2
  return 1
}

stop_running_app

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
```

Launching a SwiftPM GUI binary directly can produce no Dock icon, no foreground
activation, and missing bundle identifier warnings. If the `.app` bundle opens
but the main window still does not come forward, the app entrypoint may need
`NSApp.setActivationPolicy(.regular)` and
`NSApp.activate(ignoringOtherApps: true)`.

`APP_PROCESS_NAME` 是本 bootstrap 唯一可用的 target selector。零個匹配時繼續；僅一個 PID 匹配時才可 stop。多個 PID 匹配時不得 stop、不得採用替代 stop method、不得以 `open -n` 繞過；停止並要求人類提供可使 `APP_PROCESS_NAME` 唯一匹配的 selector 後再重試。

Adapt the build step for Xcode projects by replacing `swift build` with
`xcodebuild -project ...` or `xcodebuild -workspace ...`, then launch the built
`.app` binary from DerivedData or a deterministic project-local build path. Keep
the one-script interface and mode flags the same.

## `.codex/environments/environment.toml`

Write the environment file at this exact path:

`.codex/environments/environment.toml`

with this action shape:

```toml
# THIS IS AUTOGENERATED. DO NOT EDIT MANUALLY
version = 1
name = "<project-name>"

[setup]
script = ""

[[actions]]
name = "Run"
icon = "run"
command = "./script/build_and_run.sh"
```

If the project already has an environment file, update the existing `Run`
action to point at `./script/build_and_run.sh` instead of adding a duplicate.
