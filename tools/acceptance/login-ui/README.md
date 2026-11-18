# Login UI 原生驗收工具

本目錄是獨立的最小 SwiftPM acceptance package，非產品 App、非認證實作。只以 local path dependency 取 root `RivetPresentation` product；root package／target／lock／設定不改。只有 Support、executable、tests 三個 tool-local targets，不依賴 E011／LoginDemoModel／GitHubIntegration，不複製正式 View 或登入 VO。

## 責任與操作

主窗只組合正式 `RivetLoginView`，預設 `.standard`，footer 為工具自有中性 `Connect your GitHub account to Rivet.`，兩種 failure 也使用工具 fixtures 的中性文案。沒有獨立 Controls 窗、overlay 或登入畫面內的測試欄位。

App/Quit、標準 Edit 與 Acceptance menu 分開。Acceptance 僅有八種 phase、13／17／21 pt、Standard／Controlled copy、Enable token creation、Reset 與唯讀 last event kind/count；不設新快捷鍵，不占用截圖按鍵。Menu 及正式 UI callbacks 更新同一 parent／同一視窗，沒有 timer、Task 或自動完成。Controlled copy 只在明確選擇後顯示。

Parent 不保存 PAT：submit callback 不綁定、檢視、複製、記錄、hash 或保留 associated String，只記有限 enum kind 與接受次數。違反目前 phase 的事件忽略；create 只在啟用表單內記一次 receipt，不開 browser、不改 phase。驗證中／成功／失敗由人工 phase menu 提供，不暗示有認證服務。

同一 form generation 下的 PAT entry↔token failure、字級、copy 及建立可用性更新保持 root identity；只有 Reset 改 generation。Reset 清除局部表單及 event receipt，保留目前 phase／字級／copy／可用性，方便同畫面驗清除。這些 parent unit tests 不能證明實際 View 點擊、focus 或 VoiceOver。

## 建置、固定依賴與新 artifact

先備：Xcode／Swift tools6.0、Swift6、macOS15，以及既有 Apollo 2.1.2 bare cache。雖只建 Presentation，SwiftPM 解析 local root manifest 仍需 transitive Apollo manifests/cache；不宣稱零解析需求。

從 feature checkout 執行，`ACCEPTANCE_RUN` 必須在 checkout 外；未指定則腳本建立新的系統暫存根。`APOLLO_CACHE_SOURCE` 可指定已存在 bare cache，預設讀 feature 的 `.build/repositories/apollo-ios-b9a1b528`。不安裝或下載依賴，cache 缺少／固定 revision 不符就停止。

```sh
ACCEPTANCE_RUN="$EXTERNAL_TOPIC_RUN" \
  tools/acceptance/login-ui/scripts/build-app.sh
```

腳本核對 root lock pin，複製既有 cache 至外部 run，禁止 Git HTTP／HTTPS，使用標準 SwiftPM sandbox，不用 `--disable-sandbox`，不改 HOME／全域設定。工具有自己的 Package.resolved，pins 與 root 相同；新工具 originHash 不必等於 root。若沒有自身 lock，只以本機固定 cache 明確 resolve，再核對 pins，絕不更新 root lock。

產物為 `$ACCEPTANCE_RUN/native/RivetLoginAcceptance.app`、ID `local.rivet.login-ui-acceptance`；它是新 identity，不能沿用舊 preview 的接受或啟動確認。腳本拒絕覆寫已存在的 app 產物，複製實際 build 所產生的 Presentation resource bundle，不假定歷史 wrapper 的位置。`acceptance-build.json` 記 source、binary、resource 清單與整個 app tree SHA；不含 token，nativeLaunch 保持 not-run。Root manifest／lock／gitignore 有前後 hash guard。

腳本不 launch、不停止 app。新 binary 必須先經獨立 source review，提出 exact app／source／binary SHA 與有限案例並取得當下確認，才可做必要 native／Human 聲音差異驗證；不能把舊 HC01 直接填成此 app 已接受。

## 工具自身測試

在已準備的外部 run 使用同一 cache/modules 與固定 lock：

```sh
env GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=protocol.https.allow GIT_CONFIG_VALUE_0=never \
  GIT_CONFIG_KEY_1=protocol.http.allow GIT_CONFIG_VALUE_1=never \
  swift test --package-path tools/acceptance/login-ui \
    --scratch-path "$ACCEPTANCE_RUN/scratch" --cache-path "$ACCEPTANCE_RUN/cache" \
    --manifest-cache local --skip-update --disable-automatic-resolution \
    --disable-keychain --disable-netrc \
    -Xbuild-tools-swiftc -module-cache-path -Xbuild-tools-swiftc "$ACCEPTANCE_RUN/modules" \
    -Xswiftc -module-cache-path -Xswiftc "$ACCEPTANCE_RUN/modules" \
    -Xcc "-fmodules-cache-path=$ACCEPTANCE_RUN/modules"
```

SwiftPM description可能列出root其他target的planned commands，不能據此稱它們都實際編譯／連結。應以product build log及Objects.LinkFileList核對；tool tests可能編譯Apollo的Install CLI plugin，不能把plugin編譯當作已執行安裝。本輪未執行安裝。

啟動時不需要舊 `--preview` flag，只有初始選擇：

```text
RivetLoginAcceptance
  [--state welcome|pat|waiting|verifying-account|verifying-token|browser-failure|token-failure|completed]
  [--appearance system|light|dark]
  [--text-size <finite 13...21>]
```

未知、重複、缺值及非有限／越界字級在建窗前拒絕。測試只證 tool config／parent，不是正式 View integration 證據；#Preview 真 Canvas、Return/Escape／同窗實際 callback、focus／資源載入與 Human 聲音另依 topic 帳本補驗。

## 歷史與歸屬

E011 source 凍結於 `d2332bf` 的 tree `b6a1e6e1196e64999af9591ec32f09211f1936c6`，不再作本輪驗收入口。Frozen host 不傳 content，HEAD 重建會使用現行產品 `.standard`；可編譯不表示舊展示文案逐字／語意相同。歷史原貌只由完整 freeze revision 或原 binary 支持，不新增 formal demo mode／footer／bundle 特判。

原 I01/I02、native／VoiceOver 證據及 Human 接受依其來源保留；工具存在、測試通過或能建置，不等於產品已接認證／儲存／session，也不等於新 host 已由 Human 接受。
