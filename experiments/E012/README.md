# E012：Reader fixture 功能驗收環境

來源 topic：`pr-reader-webview-runtime-reading`。集中既有host、專用Runtime／fixture／HTML-CSS-JS資源與專屬測試，不改寫原功能驗收為事前實驗。正式Core／WebView bridge與正式測試、TS pipeline留原處，沿用root products／targets／dependencies。
逐檔路徑、hash與允許差異只見 [topic唯一清單](../../analysis/verification-artifact-ownership/technical-spec.md#唯一逐檔清單)。

## 離線建置與必要測試

由repository root在可啟動SwiftPM標準sandbox的正常本機上下文執行，不使用--disable-sandbox。先指定APOLLO_CACHE_SOURCE為既有barecache；缺少固定revision時停止，不下載或更新依賴。使用既有lockfile相符的TS node_modules，缺少時停止，不安裝新版本。

```sh
(cd surfaces/pr-reader-webview && bun run check && bun test && bun run bundle:reader) || exit 1
B1_RUN="$(mktemp -d -t rivet-ownership-b1)" || exit 1
mkdir -p "$B1_RUN/scratch" "$B1_RUN/cache" "$B1_RUN/modules" "$B1_RUN/logs"
# APOLLO_CACHE_SOURCE 由使用者指定為既有 Apollo bare repository cache。
# 未提供／缺少固定 revision 時立即停止；不由此命令下載或更新依賴。
: "${APOLLO_CACHE_SOURCE:?請先指向既有的 Apollo bare cache}"
APOLLO_REVISION="$(python3 - <<'PY_PIN'
import json
from pathlib import Path
pins = json.loads(Path("Package.resolved").read_text())["pins"]
print(next(p["state"]["revision"] for p in pins if p["identity"] == "apollo-ios"))
PY_PIN
)" || exit 1
test "$(git --git-dir="$APOLLO_CACHE_SOURCE" rev-parse --is-bare-repository)" = true || exit 1
test "$(git --git-dir="$APOLLO_CACHE_SOURCE" rev-parse "$APOLLO_REVISION^{commit}")" = "$APOLLO_REVISION" || exit 1
mkdir -p "$B1_RUN/cache/repositories"
APOLLO_CACHE_COPY="$B1_RUN/cache/repositories/apollo-ios-b9a1b528"
test ! -e "$APOLLO_CACHE_COPY" || exit 1
cp -R "$APOLLO_CACHE_SOURCE" "$APOLLO_CACHE_COPY" || exit 1
test "$(git --git-dir="$APOLLO_CACHE_COPY" rev-parse "$APOLLO_REVISION^{commit}")" = "$APOLLO_REVISION" || exit 1
b2_swift() {
  local action="$1"
  shift
  env GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0=protocol.https.allow GIT_CONFIG_VALUE_0=never \
    GIT_CONFIG_KEY_1=protocol.http.allow GIT_CONFIG_VALUE_1=never \
    swift "$action" --skip-update --disable-automatic-resolution \
      --disable-keychain --disable-netrc \
      --scratch-path "$B1_RUN/scratch" --cache-path "$B1_RUN/cache" \
      --manifest-cache local \
      -Xbuild-tools-swiftc -module-cache-path -Xbuild-tools-swiftc "$B1_RUN/modules" \
      -Xswiftc -module-cache-path -Xswiftc "$B1_RUN/modules" \
      -Xcc "-fmodules-cache-path=$B1_RUN/modules" "$@"
}
b2_swift build --product RivetPRReaderHarness || exit 1
b2_swift test --filter 'ReaderHarnessTests|BridgeSessionTests|WireContractTests|StaticIsolationTests' || exit 1
```

TS bundle輸出已接至本目錄內既有resource；必須與唯一表的原bytes相同。Swift指定tests包含真WKWebView資源／Viewed往返、失敗／逾時及外部導覽拒絕，blocked／skipped不得視為必要驗證通過。

## 既有原生入口與暫存wrapper觀察

root product不變，可沿既有 `swift run RivetPRReaderHarness` 操作；視窗是本地fixture，不連GitHub、不持久化Viewed。若需CUA辨識，沿用歷史暫存app-wrapper模式：下列只包本次相同binary，不改簽章／profile／產品行為。

```sh
BIN_DIR="$(b2_swift build --show-bin-path)"
APP="$B1_RUN/native/RivetPRReaderHarness.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/RivetPRReaderHarness" "$APP/Contents/MacOS/RivetPRReaderHarness"
cp -R "$BIN_DIR/Rivet_RivetPRReaderHarnessRuntime.bundle" "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>RivetPRReaderHarness</string>
	<key>CFBundleIdentifier</key>
	<string>local.rivet.reader-harness-verification</string>
	<key>CFBundleName</key>
	<string>RivetPRReaderHarness</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>LSMinimumSystemVersion</key>
	<string>15.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST
open "$APP"
```

本輪基線使用SwiftPM build-bundle fallback載入本地index.html，因此必須保留同次BIN_DIR內的Rivet_RivetPRReaderHarnessRuntime.bundle；暫存wrapper不是可攜式產品交付。必須核對實際file URL，不能以wrapper內拷貝存在代替資源載入證據。
確認六狀態added／removed／modified／renamed／copied／typeChanged、四patch及兩metadata-only提示。點第一檔「標記 Viewed」後應顯示「已 Viewed · 取消」，再取消恢復；只存本次Swift記憶體。
操作前先確認並結束同一測試wrapper的既有程序，不停止不明程序、不併行多個同身分版本。結果及獨立verdict見 [topic帳本](../../plan/verification-artifact-ownership/verification-artifact-ownership.step.md)；此說明不宣稱真人API或原topic完整Human重驗。
