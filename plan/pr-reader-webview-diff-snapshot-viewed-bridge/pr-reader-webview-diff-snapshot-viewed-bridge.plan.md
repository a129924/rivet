# PR Reader WebView Diff 快照交付與 Viewed 回傳：執行計畫

## Goal

在 feature worktree 完成 `PRContentSnapshot → DiffSnapshot → WebView diff pipeline` 的保真交付與 `ViewedStateChange → Swift viewed authority` 的有效事件回傳。topic slug 為 `pr-reader-webview-diff-snapshot-viewed-bridge`。

## In-Scope

- 獨立 Swift bridge target、可注入 viewed authority／snapshot sink、collision-free PR encoding、snapshot-local identity registry、三重 identity 事件驗證及 bounded failure。
- 六種 TS status、任意 status 上存在的 previous path 保留、patch presence 保真、metadata-only pipeline、callable adapter 回傳既有 render outcome。
- 雙側 JSON wire fixture、Swift／TS tests、四狀態與 render outcome 回歸、相關長期架構文字及圖回寫。

## Out-Of-Scope

GitHub content source／mapper／SDL ownership、viewed 永久儲存或 GitHub 寫入、WKWebView host／live transport／具體 Output／DOM／完整 UI、optimistic viewed 更新、acknowledgement／retry、大型 diff 分段／cache、非 diff content 顯示、PR Reader Core API／PR Inbox dependency 及 Facade／UseCase orchestration 改動。

## Non-Goal

本次不宣稱真實 GitHub snapshot、跨啟動 viewed、產品 DOM rendering 或完整 Reader UI 已交付。

## Implementation Contract

1. 建立 `RivetPRReaderWebViewBridge` product／target，path 為 `Sources/PRReaderWebViewBridge`、只依賴 `RivetPRReader`。`@MainActor` session 提供 `publish(_:)`、`receiveViewedChange(_:)`、`invalidate()` 與可注入 viewed authority／snapshot sink。
2. PR ID 使用版本前綴與 owner／repository UTF-8 byte-length 前綴、十進位 number；snapshot ID 為 session UUID 加不重用 publish 序號；file ID 為 `f:<zero-based index>`，registry 回查 Reader reference。
3. 完整驗證、讀取所有 viewed 並建立 snapshot 後才呼叫 sink 一次；成功才啟用新 registry。轉換、讀取或交付失敗不發布部分 snapshot。PR context 切換或 invalidate 使舊事件失效。
4. TS contract、validator、parser、template 支援 copied、typeChanged 及任意 status 的合法 previous filename；不虛構 copied source 或 typeChanged mode，維持 patch 缺席／空字串區別。`DiffSnapshotAdapter.receiveSnapshot` 呼叫 Facade 一次並回傳既有 outcome；Swift bridge failure 與 render outcome 分開。
5. Viewed event 的三個 identity 必須全符才更新 Swift authority；其餘忽略。完成後更新 PR Reader BC truth 與兩份既有架構圖，圖內容為繁體中文並通過各 skill 驗證。

## ReadOnly

- Reader Core：`Sources/BoundedContexts/PRReader/Core/ReaderIdentity.swift`、`Sources/BoundedContexts/PRReader/Core/ReaderContent.swift`。
- 既有 isolation tests：`Tests/RivetPRReaderTests/StaticIsolationTests.swift`、`Tests/RivetPRInboxTests/StaticIsolationTests.swift`。
- TS 既有邊界：`surfaces/pr-reader-webview/src/diff-rendering/contracts/diff-snapshot.ts`、`surfaces/pr-reader-webview/src/diff-rendering/contracts/viewed-state-change.ts`、`surfaces/pr-reader-webview/src/diff-rendering/facades/diff-facade.ts`、`surfaces/pr-reader-webview/src/diff-rendering/usecases/diff-render-use-case.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/diff-renderer.ts`。
- 工具與圖表契約：`surfaces/pr-reader-webview/package.json`、`surfaces/pr-reader-webview/bun.lock`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/BUILD.md`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/build-diagram.sh`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/verify-dataflow-contract.js`。
- `README.md`、`docs/design-principles.md` 及其他未列入 Modify／Written 的既有 source／tests 僅供參照。

## Written

- 規劃 artifacts：`analysis/pr-reader-webview-diff-snapshot-viewed-bridge/requirements.md`、`analysis/pr-reader-webview-diff-snapshot-viewed-bridge/technical-spec.md`、`plan/pr-reader-webview-diff-snapshot-viewed-bridge/pr-reader-webview-diff-snapshot-viewed-bridge.plan.md`、`plan/pr-reader-webview-diff-snapshot-viewed-bridge/pr-reader-webview-diff-snapshot-viewed-bridge.step.md`。
- Swift bridge：`Sources/PRReaderWebViewBridge/WireContracts.swift`、`Sources/PRReaderWebViewBridge/BridgeSession.swift`。
- Swift tests：`Tests/RivetPRReaderWebViewBridgeTests/BridgeSessionTests.swift`、`Tests/RivetPRReaderWebViewBridgeTests/WireContractTests.swift`。
- 雙側契約證據：`surfaces/pr-reader-webview/test-fixtures/diff-bridge-contract.json`、`surfaces/pr-reader-webview/src/diff-rendering/adapters/diff-bridge-contract.test.ts`。

## Modify

- Package graph：`Package.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；後者只同步新增 product／targets 的 exact graph assertions，保留既有 entries 與檢查。
- TS contract／adapter：`surfaces/pr-reader-webview/src/diff-rendering/contracts/diff-view-model.ts`、`surfaces/pr-reader-webview/src/diff-rendering/contracts/diff-view-model.test.ts`、`surfaces/pr-reader-webview/src/diff-rendering/index.test.ts`、`surfaces/pr-reader-webview/src/diff-rendering/adapters/diff-snapshot-adapter.ts`、`surfaces/pr-reader-webview/src/diff-rendering/adapters/diff-snapshot-adapter.test.ts`。
- TS pipeline：`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/diff-view-model-validator.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/diff-view-model-validator.test.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/git-diff-template.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/git-diff-template.test.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/diff-parser.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/diff-parser.test.ts`、`surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/diff-rendering-concrete-stages.integration.test.ts`。
- 長期架構真相：`docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/scene.js`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/diff-render-flow.dataflow.json`，及由既有腳本產生的 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/index.html`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/diff-render-flow.html`。

## Deleted

無。

## TestCase

| ID | Trigger | Observable expected result | Evidence |
| --- | --- | --- | --- |
| TC-01 | owner／repository 含分隔符、Unicode、空字串及不同組合 | 不同 Reader PR identity 不產生相同 `pullRequestId` | Swift identity tests |
| TC-02 | 連續 publish、失敗 publish、invalidate、PR 切換 | 成功 snapshot ID 不重用；失敗候選不啟用；舊事件不更新 | Swift session tests、authority spy |
| TC-03 | 多檔、六狀態、任意 status 的 previous path、patch 缺席與空字串 | 一次交付完整有序 snapshot、欄位保真、file lookup 正確 | Swift mapping tests、雙側 JSON fixture |
| TC-04 | 重複 reference、無效 path／計數、viewed 讀取失敗 | sink 零呼叫，不交付部分 snapshot | Swift failure tests、sink spy |
| TC-05 | 有效、過期、未知或 identity 不符的 viewed event | 有效事件只更新對應檔案；其他事件零更新 | Swift event tests、authority spy |
| TC-06 | copied 有／無來源、typeChanged、六狀態有 patch／缺 patch／空 patch | 合法輸入產生保真 render plan；無來源 copied 不虛構來源 | TS validator、parser、template、integration tests |
| TC-07 | callable adapter 接收 snapshot 與既有 render failures | 呼叫 Facade 一次，原樣回傳 success 或四種既有 error | TS adapter／pipeline tests |
| TC-08 | 新增 Swift target 後執行完整 checks | bridge source 不被 `RivetPresentation` 編入；隔離、回歸與圖表驗證通過 | `swift test`、Bun check/test/coverage、diagram verification、`git diff --check` |

## Delivery and Gates

只在 feature worktree 寫入；`dev` worktree 不得修改。Plan-Creator 寫四份 artifacts 後交獨立 Plan-Reviewer；只有明示 `approved` 才進入 Implementer。Implementer 完成後交獨立 Tester、Reviewer；無重大問題且 Reviewer `approved` 後，依已授權的 topic commit／push／draft PR 流程交付，停止於 Human Review。不 merge、不 release。commit 前仍依 staged diff 檢查語意邊界並提出 message；人類確認要求以既有使用者明示授權與 repository 規範判斷，不得由 agent 自行宣稱替代。

## Last Updated

2026-09-24；Plan-Creator 首次建立，待獨立 Plan-Reviewer 審查。
