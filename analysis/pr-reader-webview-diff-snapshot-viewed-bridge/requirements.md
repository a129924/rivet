# PR Reader WebView Diff 快照交付與 Viewed 回傳：需求

## Goal

當 Swift 已持有一份 `PRContentSnapshot`，將所有 Reader files 依原順序與完整狀態交付 WebView diff pipeline；WebView 的有效 viewed 通知須精確回查同一 PR、同一 snapshot 與同一 Reader file，交給 Swift viewed authority 更新。

## Actor and Success

主要 actor 是 PR Reader Presentation integration。成功時，一次發布完整且 identity 一致的 `DiffSnapshot`，六種合法 file status 均可進入既有 pipeline，初始 viewed 來自 Swift authority；只有目前有效的 viewed event 能更新相應檔案。

## In-Scope

- 獨立 Swift bridge target，依賴 `RivetPRReader`，以可注入 viewed authority 和 snapshot sink 提供 snapshot delivery、事件回查與 session invalidation。
- 將 `ReaderPullRequestID` 無碰撞編碼為 WebView `pullRequestId`；每次發布建立 opaque `snapshotId`；每檔建立 snapshot-local `fileId` 並保存 `fileId → ReaderFileReference` 回查。
- 保持 Reader 檔案原始順序，保真轉換 path、任意 status 上的 optional previousPath、六種 file status、optional patch、additions、deletions 與 Swift-authoritative viewed。保留 patch 缺席與空字串差異；metadata-only 檔案可通過 pipeline。
- TS contract、validator、parser、template 接受 `added`、`removed`、`modified`、`renamed`、`copied`、`typeChanged`；callable adapter 回傳既有 render outcome。
- 接收 `ViewedStateChange`，驗證 `pullRequestId`、`snapshotId`、`fileId`；未知、過期或不相符事件不更新 authority。任一必要資料無法完整轉換時，不交付部分 snapshot。
- Swift／TS 共用 wire fixture、雙側測試、既有四狀態與四種 render error 回歸、受影響的 PR Reader 長期架構文字與圖。

## Out-Of-Scope

- GitHub REST／GraphQL source、operation、DTO、mapper、候選 SDL 的 ownership／target 整合、Reader production content adapter。
- viewed database／檔案格式／跨啟動儲存、GitHub mark-file-viewed／unviewed、WebView optimistic update、acknowledgement、retry、可靠傳輸。
- WKWebView host、真實 Swift／JavaScript runtime transport、具體 Output、DOM、完整 Reader UI、Facade／UseCase render 協調順序變更。
- 大型 diff 分段／lazy loading／cache、comments／reviews／checks 顯示、blob SHA／`resolvedBy` 等 Core 欄位擴充、PR Inbox compile-time dependency。

## Non-Goal

本 topic 不宣稱已從 GitHub 取得 Reader snapshot、不提供跨啟動 viewed persistence、不交付產品 UI 或 DOM Output，也不改 PR Reader Core API。

## Acceptance Criteria

1. PR identity 往返一致且編碼不因 owner／repository 常見字元組合碰撞；不同已發布 snapshot 有可區分的 opaque ID。
2. `fileId` 在單一 snapshot 內唯一，能回查原始 Reader reference；多檔順序、路徑、optional previous path、狀態、計數及 patch presence 保持不變。
3. 六種狀態皆有對應 TS status，不降級；copied 的來源路徑若存在即保留，缺席時不虛構；metadata-only 檔案不因無 patch 失敗。
4. 初始 viewed 由 Swift authority 提供；有效事件只更新相應檔案；過期、未知或 identity 不一致事件不更新狀態。
5. 轉換、viewed 讀取或交付失敗不發布部分 snapshot；Swift bridge failure 與既有 TS render outcome 分開表達。
6. 原四狀態及既有 render outcome 相容，Core 不新增 WebView identity、viewed、WebKit 或 TypeScript 依賴。

## Confirmed Decisions and Constraints

Human 已接受 TS 六狀態擴充、任意 status 上存在的 `previousPath` 均保留、Swift viewed authority 僅為本 Mission 的連接邊界（永久儲存另立 topic），以及可注入 Swift bridge 與 callable TS adapter。工作只在 feature worktree；`dev` worktree 不得修改。正式實作需獨立 Plan-Reviewer 明示 `approved`；完成後交獨立 Tester 與 Reviewer，最後停於 Human Review。

## Existing Evidence

- `RivetPRReader` Core 已有 `PRContentSnapshot`、六種 `FileChange`、逐檔 optional patch，沒有 WebView identity 或 viewed。
- TS `DiffViewModel` 現有四狀態，`DiffSnapshotAdapter.receiveSnapshot` 目前回傳 `void`；Validator 僅允許 renamed 帶 `previousFilename`。Parser 對無 patch 走 metadata-unavailable，template 只有四狀態。
- PR Reader 長期文件將 Swift 設為 viewed authority；Output、DOM、Swift bridge、viewed persistence 目前未交付。

## Last Updated

2026-09-24；Plan-Creator 首次建立，待獨立 Plan-Reviewer 審查。
