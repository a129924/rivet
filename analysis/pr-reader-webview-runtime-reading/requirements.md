# PR Reader WebView 可視化 Runtime 閱讀 — Requirements

## Goal

以本地 `PRContentSnapshot` fixture 啟動最小 macOS Reader harness；使用者在真正的 WKWebView 中閱讀多檔 diff，切換 Viewed 後由 Swift 記憶體 authority 更新，並看見新快照的狀態。此結果是 fixture 驅動的 runtime E2E。

## Non-Goal

- 不宣稱已開啟真實 GitHub PR、寫回 GitHub、永久保存 Viewed，或交付完整 Reader 產品 UI。
- 不變更 PR Reader Core、公開 Swift bridge 或 TypeScript snapshot／Viewed contracts、六狀態及四種 render outcome。

## In-Scope

- 可重現建置、打包資源並以 `swift run RivetPRReaderHarness` 開啟的 macOS WKWebView harness；畫面標示本地 fixture。
- Swift bridge `DiffSnapshotWire` 至 TypeScript diff pipeline 的 live delivery、具體 Output／DOM，以及 best-effort Viewed 通知回到 Swift authority。
- 依來源順序顯示多檔名稱、六種狀態、增刪數、patch 與明確的 metadata-only 提示；Viewed 支援標記及取消。
- 可見的啟動、資源載入、交付、render、逾時及 WebView process 失敗結果；過期／不符 identity 的通知不得更新 authority。
- 自動化 runtime 驗證、可重現人工目視驗收，及交付後的架構文字與圖表真相更新。

## Out-Of-Scope

- GitHub Content Source／Mapper、登入、真實 PR 資料取得或 Viewed GitHub 寫入。
- 跨啟動 Viewed persistence、Inbox 導覽、完整 Reader tabs、comments、reviews 與產品級 UI。
- 大型 diff 分段、lazy loading、cache、retry 或可靠訊息傳輸；既有 HTML prototype 不充當產品 runtime。

## Success Criteria

1. `swift run RivetPRReaderHarness` 開啟實際 WKWebView 視窗，從本地 Reader fixture 經 Swift bridge、live transport 與既有 TypeScript pipeline 生成 DOM；diff HTML 不是預先寫死的內容。
2. 畫面可辨識多檔順序、檔名、六種狀態、patch 與 metadata-only 檔案，並明示 fixture 資料來源。
3. Viewed 標記與取消只更新 Swift authority 中對應的 file reference；新快照呈現更新。WebView 不做 optimistic snapshot 更新。
4. 舊頁面、舊 snapshot 或 PR／snapshot／file identity 不符的事件不修改目前 authority。
5. 載入與 render 失敗有明確可見結果；特殊字元或惡意 diff 文字不會執行為 DOM 程式碼。
6. 自動化 runtime 證據與人工啟動、閱讀、切換 Viewed、確認刷新流程均可重現。

## File Impact

| Category | Paths / policy |
| --- | --- |
| ReadOnly | `Sources/BoundedContexts/PRReader/Core/`、`Sources/PRReaderWebViewBridge/{BridgeSession.swift,WireContracts.swift}`、`surfaces/pr-reader-webview/src/diff-rendering/{contracts,ports,adapters,facades,usecases,concrete-stages}/`、既有 bridge／TS tests、`surfaces/pr-reader-webview/test-fixtures/diff-bridge-contract.json`、除下列單一 graph assertion 之外的既有 tests，以及其他 topic artifacts；僅核對其 contract 與 gate，不修改。 |
| Written | `analysis/pr-reader-webview-runtime-reading/{requirements.md,technical-spec.md}`、`plan/pr-reader-webview-runtime-reading/{pr-reader-webview-runtime-reading.plan.md,pr-reader-webview-runtime-reading.step.md}`；新增 `Sources/RivetPRReaderHarness/main.swift`、`Sources/RivetPRReaderHarnessRuntime/{ReaderHarness.swift,ReaderFixture.swift,Resources/index.html,Resources/reader.css,Resources/reader.js}`、`Tests/RivetPRReaderHarnessRuntimeTests/ReaderHarnessTests.swift`、`surfaces/pr-reader-webview/src/diff-rendering/output/{dom-diff-output.ts,dom-diff-output.test.ts}`、`surfaces/pr-reader-webview/src/runtime/{webview-runtime.ts,webview-runtime.test.ts}`。`reader.js` 為 TS build 產物，須可重建。 |
| Deleted | 無。 |
| Modify | `Package.swift` 增加 harness／runtime／tests 與 resources；`Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 僅更新 `packageDeclaresTheLockedTargetGraph` 預期 product／target 集合，加入 `RivetPRReaderHarnessRuntime` library product／target、`RivetPRReaderHarness` executable product／target、`RivetPRReaderHarnessRuntimeTests` target；保留其他 GitHubIntegration／bridge isolation assertions 與 format／lint 約束；`surfaces/pr-reader-webview/package.json` 增加 browser bundle 指令；交付後更新 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/{scene.js,diff-render-flow.dataflow.json,index.html,diff-render-flow.html}`，維持文字、圖 source 與重建產物一致。 |

## TestCase

- TC-01：真實 WKWebView 內確認 fixture → Swift bridge → live transport → TypeScript pipeline → DOM；多檔順序、六狀態、patch、metadata-only 均可辨識。
- TC-02：Viewed 標記及取消只更新目標 Swift file reference；host-owned authority 成功寫入後才通知 host 在下一個 main-actor turn 發新快照，畫面隨之刷新。identity 不符不得呼叫 `setViewed` 或刷新；authority 寫入拋錯不得通知或刷新。
- TC-03：資源、交付、render、逾時與 process 失敗產生可見結果；特殊字元及惡意 diff 文字不執行為程式碼。
- TC-04：Swift package graph 精確集合只增加上述兩個 products／三個 targets，既有 GitHubIntegration／bridge isolation assertions 全部保留且通過；完整 Swift／TypeScript 回歸、format／lint 與 browser asset 重建比對通過；人工啟動、閱讀與 Viewed 往返流程可重現。

## 已知研究與 Gate

- `BridgeSession.publish` 目前同步呼叫 `DiffSnapshotSink.receiveSnapshot`，成功僅能表示 sink 接受交付；WKWebView 的非同步 load、JavaScript 執行及 DOM 呈現需要 host 自行追蹤完成與失敗。
- 本 topic 的實作基線僅為 `dev` HEAD `9c61af8`：bridge PR #43 已於 2026-09-29T03:34:35Z merge，merge SHA 與 HEAD 相同；concrete-stages PR #13 已於 2026-09-09 merge。既有 concrete-stages ledger 的 `RV-17` blocked、`RV-18`／`DL-10` pending 是另一條未交付 correction route；此路線不是本 Mission 的硬依賴，因本 Mission 使用已合併的 pipeline contract，不要求其 EOF correction。測試若發現受該 correction 影響的 EOF 行為，停止本 topic 並路由回原 topic，不修改本 topic ReadOnly stages。bridge topic `HC-01` 仍為 pending 的 ledger 記錄，不回填成已核准。
- 若實作必須改公開 bridge／TS contract 或擴大外部權限，先停在規劃／human decision，不自行擴張本 Mission。
- `IM-01` 的完整 Swift suite 已回報 134 tests 中僅 `packageDeclaresTheLockedTargetGraph` 有兩個 exact-set assertion failures，因新增 harness products／targets 未列入預期。此受限測試檔 scope 修訂屬 PC-03，須取得 fresh `PR-03 approved` 才可回到實作；不以既有 `PR-02 approved` 追溯放行。
