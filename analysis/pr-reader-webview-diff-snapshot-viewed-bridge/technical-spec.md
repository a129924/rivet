# PR Reader WebView Diff 快照交付與 Viewed 回傳：技術規格

## Locked Decisions

### Boundary and target

新增 root SwiftPM `RivetPRReaderWebViewBridge` library product／target，target path 固定為 `Sources/PRReaderWebViewBridge`，只依賴 `RivetPRReader`；tests 位於 `Tests/RivetPRReaderWebViewBridgeTests`。此 path 不與 `Sources/Presentation` 重疊，`RivetPresentation` 保持不依賴 BC。Swift bridge 不改 Reader Core。TS adapter 是現有 WebView diff 模組內 callable boundary；本 topic 不實作 WKWebView host 或 runtime transport。

### Swift session contract

Swift 提供 `@MainActor` bridge session，包含 `publish(_:)`、`receiveViewedChange(_:)`、`invalidate()`，並注入 viewed authority 與 snapshot sink。Authority 為 Reader PR／file reference 提供當下 viewed 值並接收更新；sink 一次接收完整 wire snapshot。`publish` 的轉換、authority 讀取、sink 交付 failure 屬 Swift bridge bounded failure，不混入 `DiffRenderOutcome`。`receiveViewedChange` 為 best-effort 單向通知：無 acknowledgement、retry 或 optimistic WebView snapshot mutation；authority 更新失敗只留在 Swift 診斷邊界。

`pullRequestId` 採固定版本前綴、owner／repository 的 UTF-8 byte-length 前綴與十進位 PR number，保留原字串 bytes，不使用分隔字元的猜測切分。`snapshotId` 是 session UUID 加不重用 publish 序號；每次成功發布須與之前發布可區分。`fileId` 為 `f:<zero-based index>`，只在單一 snapshot 內有意義，registry 保存每個 ID 對原始 `ReaderFileReference` 的映射。snapshot identity 不進 Core，WebView 不解讀其內容。

在 sink 前驗證 snapshot 必要 identity、檔案 reference 唯一、path／previousPath 與非負安全整數計數可供 TS validator 接受，讀取所有 viewed 值，再完整建立 `DiffSnapshot`。保留 file 順序；`path → filename`、`previousPath → previousFilename`、`change → status`、patch／count 原樣對應，nil patch 缺席、空字串 patch 存在。對 `snapshot.id` 建立 PR context；PR 切換時使舊 registry 失效。sink 單次成功後才啟用新 registry；失敗候選不啟用，也不交付部分 snapshot。發布序號不得因失敗而導致已發布 ID 重用。

Viewed event 只有在 active registry 的 `pullRequestId`、`snapshotId`、`fileId` 全部相符時才回查 Reader reference，並送交 Swift authority。未知或過期事件靜默忽略，且可由測試 spy 或診斷觀察。`invalidate()` 清除 active registry；後續事件不能改狀態。

### TypeScript contract and pipeline

`DiffFileStatus` additive 擴充 `copied`、`typeChanged`。Validator 對任意 status 均接受合法的 optional `previousFilename`，若存在則原樣保留，不以 status 推斷或合成。`filename` 與 `previousFilename` 維持既有 raw nonempty path 規則。Parser／template 支援六狀態、有 patch／無 patch／空 patch；copied 有來源才保留來源語意，無來源時不虛構來源；typeChanged 不虛構 mode。metadata-only 走既有 bounded render path，不因缺 patch 而失敗。保持原四狀態的行為與 `invalid-input`、`parse-error`、`render-error`、`output-error` outcome。

`DiffSnapshotAdapter.receiveSnapshot` 變更為呼叫 `DiffFacade.present` 一次並回傳 `DiffRenderOutcome`；這是 TS callable adapter 的公開介面變更，相關 consumer／tests 同步更新。Swift sink 與 TS callable adapter 透過共用 JSON fixture 驗證 wire shape；fixture 不代表已實作 live transport。Facade／UseCase 的 stage order、Output ownership 與其他 Port 不變。

## Failure and Edge Cases

- Reader snapshot 必要資料無法無碰撞或無損轉換、重複 reference、非法 path／計數、viewed 讀取失敗：Swift bounded failure，sink 零次呼叫；不可截斷檔案後成功。
- sink 交付失敗：不啟用新 registry；舊 registry 是否仍有效由目前 active PR context 決定，不能把失敗候選標為 current snapshot。
- TS 解析／render／output failure：原樣回傳既有 outcome，不轉成 Swift bridge failure。
- stale／unknown／mismatched viewed event：零 authority update；不等待 WebView 確認。

## File Impact

完整且互斥的 ReadOnly／Written／Modify／Deleted ledger 與 TestCase 見 [執行計畫](../../plan/pr-reader-webview-diff-snapshot-viewed-bridge/pr-reader-webview-diff-snapshot-viewed-bridge.plan.md)。

## Validation Contract

Swift／TS 共用 fixture 驗證 wire field、order、六種狀態與 optional presence；Swift 測 identity collision、連續／失敗 publish、registry、viewed routing、全部或零交付；TS 測 validator、parser、template、adapter outcome 與四狀態 regression。root `swift test`、Bun check／test／coverage、diagram verification、`git diff --check` 與 changed-path／dependency audit 必須提供證據。架構圖依 `architecture-canvas`／`archify` 的既有驗證程序重建，不自行發布。

## Last Updated

2026-09-24；Plan-Creator 首次建立，待獨立 Plan-Reviewer 審查。
