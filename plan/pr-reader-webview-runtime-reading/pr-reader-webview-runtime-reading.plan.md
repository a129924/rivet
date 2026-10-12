# PR Reader WebView 可視化 Runtime 閱讀 — Execution Plan

## Goal / Non-Goal

Goal：以 `swift run RivetPRReaderHarness` 啟動本地 fixture 驅動的真實 WKWebView Reader，顯示經既有 Swift bridge 與 TypeScript pipeline 產生的多檔 diff，並讓 Viewed 往返 Swift 記憶體 authority。Non-Goal：真實 GitHub PR、永久 Viewed、完整 Reader UI、公開 bridge／TS contract 或 PR Reader Core 改動。

## In-Scope / Out-Of-Scope

In-Scope：可啟動 harness 與 bundled assets、live 雙向 transport、具體 Output／DOM、可見失敗、三重 identity 與頁面世代防護、自動化 runtime 測試及人工驗收、長期架構 truth 更新。Out-Of-Scope：GitHub source／write、Inbox、comments／reviews、大型 diff 分段、cache／retry／可靠傳輸。

## 受限實作

1. 四份正式 artifacts 曾經 `PR-01 needs-rework → PC-02 → PR-02 approved` 進入 `IM-01`。完整 Swift suite 發現單一 graph test 的兩個 exact-set failures 後，IM-01 暫停；PC-03 僅補入該檔 expected sets 的受限 scope，須取得新的獨立 `PR-03 approved` 才可恢復。既有 `PR-02 approved` 不追溯涵蓋此修訂。實作基線仍是 `dev` 合併 HEAD `9c61af8`，不使用未合併 EOF correction，亦不回填其他 topic gate。
2. 建立 SwiftPM harness／runtime／fixture 與打包的 HTML／CSS／TS browser bundle。ready 後 `publish`；同步 sink 返回只表示交付已被 host 接受，host 追蹤當前頁面與 snapshot 的 DOM 完成、失敗、逾時。
3. 實作 DOM Output，依 render plan 順序顯示六狀態、檔案資訊、patch 或 metadata-only。文字用 `textContent`，diff HTML 清理後插入；限制本地資源讀取與導覽。
4. 實作 Viewed 標記／取消：TS 發既有通知，Swift host 先核對頁面世代，bridge 再核對 PR／snapshot／file identity。host-owned authority 的 `setViewed` 成功寫入後才經 callback 排程下一個 main-actor turn 的新 `publish`，排程執行時再次核對頁面世代；identity ignore 或寫入拋錯均不通知／刷新。不可由 `receiveViewedChange` 的 `void` 返回值推定成功，也不可做 optimistic update。
5. 完成 runtime 與既有回歸驗證、browser bundle 可重建比對及人工驗收說明；更新 PR Reader 架構文字與 canvas/dataflow 圖 source、HTML，依圖表 skill 驗證，交獨立 Tester 與 Reviewer。
6. 無重大問題且 Reviewer 明示通過後，依既有 commit 規範與使用者授權在 feature worktree 做 topic commit、push、開 base `dev` 的 Draft PR，停在人類 review；不在 dev worktree 修改檔案。

## File Operations

| Category | Concrete paths |
| --- | --- |
| ReadOnly | `Sources/BoundedContexts/PRReader/Core/`；`Sources/PRReaderWebViewBridge/{BridgeSession.swift,WireContracts.swift}`；`surfaces/pr-reader-webview/src/diff-rendering/{contracts,ports,adapters,facades,usecases,concrete-stages}/`；既有 bridge／TS tests 及下述單一 graph assertion 以外的既有 tests；`surfaces/pr-reader-webview/test-fixtures/diff-bridge-contract.json`；其他 topic artifacts。 |
| Written | `analysis/pr-reader-webview-runtime-reading/{requirements.md,technical-spec.md}`；`plan/pr-reader-webview-runtime-reading/{pr-reader-webview-runtime-reading.plan.md,pr-reader-webview-runtime-reading.step.md}`；`Sources/RivetPRReaderHarness/main.swift`；`Sources/RivetPRReaderHarnessRuntime/{ReaderHarness.swift,ReaderFixture.swift,Resources/index.html,Resources/reader.css,Resources/reader.js}`；`Tests/RivetPRReaderHarnessRuntimeTests/ReaderHarnessTests.swift`；`surfaces/pr-reader-webview/src/diff-rendering/output/{dom-diff-output.ts,dom-diff-output.test.ts}`；`surfaces/pr-reader-webview/src/runtime/{webview-runtime.ts,webview-runtime.test.ts}`。 |
| Deleted | 無。 |
| Modify | `Package.swift`；`Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 僅改 `packageDeclaresTheLockedTargetGraph` 的兩個 exact expected sets，加入 `RivetPRReaderHarnessRuntime` library product／target、`RivetPRReaderHarness` executable product／target 與 `RivetPRReaderHarnessRuntimeTests` target，保留所有既有 GitHubIntegration／bridge isolation assertions 與 format／lint 約束；`surfaces/pr-reader-webview/package.json`；交付後 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/{scene.js,diff-render-flow.dataflow.json,index.html,diff-render-flow.html}`。 |

若實際 bundle、測試或圖表驗證需要超出上列的 repo-tracked path，先交 Plan-Reviewer 判定受限修訂；不得自行擴張。

## TestCase / Acceptance

- TC-01：真實 WKWebView 中確認 fixture → Swift bridge → live transport → TS pipeline → DOM；多檔順序、六狀態、patch、metadata-only 正確。
- TC-02：Viewed 標記／取消只更新 Swift 目標 reference；authority 成功寫入 callback 下一個 main-actor turn 發新 snapshot。舊頁面、舊 snapshot、PR／snapshot／file 不符不得呼叫 `setViewed`／callback；authority throw 不得 re-publish。
- TC-03：資源、交付、render、逾時、process 失敗可見；diff 惡意字元／markup 不執行，導覽與資源限制生效。
- TC-04：`swift test` 的 exact package graph 集合只增加兩個 products／三個 targets，所有既有 GitHubIntegration／bridge isolation assertions 保留並通過；`bun run check`、`bun test`、Swift format／lint、bundle 重建比對與圖表驗證通過；人工啟動、閱讀與 Viewed 往返可重現。

## Assumptions / Stop Conditions

- fixture 僅提供本地多檔內容；Viewed authority 僅在 harness 生命週期存在。沿用公開六狀態、四種 render outcome、best-effort Viewed 與原三重 identity 驗證。
- 本 topic 只使用 `dev` HEAD `9c61af8` 的已合併 bridge／concrete-stages；原 topic 未交付 EOF correction 的 `RV-17 blocked`、`RV-18`／`DL-10` pending 不是本 Mission 硬依賴，bridge `HC-01` pending 仍保留。若測試觸及該 EOF 缺陷，停下並路由原 topic，不修改 ReadOnly stages。公開 contract 變動、資料來源擴張或無法安全清理 HTML 亦停下回規劃／human decision。
