# E011：Login 功能驗收展示

來源 topic：`rivet-login-ui`。這是已存在的假資料 Demo／控制介面／Runtime／專屬測試的集中收納，不是重新執行可行性實驗，也不撤回既有 UI 採用或改寫驗收結果。
正式 `RivetPresentation`、資源與正式測試仍在正式來源區。沿用 root package 的 products／targets／dependencies，不另建 package。
逐檔 old/new、baseline hashes、允許差異與回復依據僅見 [topic 唯一清單](../../analysis/verification-artifact-ownership/technical-spec.md#唯一逐檔清單)，本目錄不維護另一份清單。

## 建置與必要測試

由 repository root 執行。使用能啟動 SwiftPM 標準 sandbox 的正常本機執行環境；不能用 --disable-sandbox。固定既有 Package.resolved 與本機 cache；缺少固定版本依賴時先停止，不自行更新版本。
以下 B1_RUN 是本次獨立可寫暫存根；不改 HOME 或任何全域設定。若採本 topic 的既有基線，可沿用其 scratch/cache/modules。

```sh
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
b1_swift() {
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
b1_swift build --product RivetLoginDemo || exit 1
b1_swift test --filter 'LoginDemoModelTests|RivetLoginPresentationTests|StaticIsolationTests' || exit 1
```

blocked、skipped、unknown 或只過 manifest 不算 B1 完整驗證。必要驗證與實際結果見 [本 topic plan](../../plan/verification-artifact-ownership/verification-artifact-ownership.plan.md)／[step](../../plan/verification-artifact-ownership/verification-artifact-ownership.step.md)。

## 原生 wrapper 與離線操作入口

使用與既有 wrapper 相同的 Info.plist 身分與 debug binary／Presentation resource bundle 包裝方式，不簽新身分、不覆蓋歷史 wrapper。若已存在本次 app，先確認並結束該 app，再另選新暫存根，不併行啟動同身分的舊／新版。

```sh
BIN_DIR="$(b1_swift build --show-bin-path)"
APP="$B1_RUN/native/RivetLoginDemo.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/RivetLoginDemo" "$APP/Contents/MacOS/RivetLoginDemo"
cp -R "$BIN_DIR/Rivet_RivetPresentation.bundle" "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>RivetLoginDemo</string>
	<key>CFBundleIdentifier</key>
	<string>local.rivet.login-ui-demo</string>
	<key>CFBundleName</key>
	<string>RivetLoginDemo</string>
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

啟動後確認 Welcome、GitHub 圖示與「No GitHub requests or credential storage」footer，再操作模擬等待／取消、假資料表單及 Demo Controls。只使用範例輸入；沒有真正 browser、GitHub API、Keychain 或憑證儲存。
這是本次位置修正的必要入口／資源驗證，不代替原 topic 的完整 Human／VoiceOver／七態 UI 採用結論。

## 本次位置修正驗證

本 topic 主對話已完成 E011 source 的實際編譯、62項相關測試，以及新wrapper／PDF圖示／模擬等待取消／本地表單／Demo Controls至模擬Connected的原生操作。獨立Tester另親跑62pass、0fail、0skip並核對artifact；成果審查狀態以topic帳本為準。
這些結果只屬 B1 位置修正，不新增真正登入能力，也不改寫原topic採用與歷史驗收。
