# 單一 PR 審閱與合併狀態技術規格

`RivetPRReaderGitHub` 以 `package GitHubPullRequestReviewMergeStateSource.init(client:)` 注入 `any GitHubGraphQLServing`。`fetchReviewMergeState(for:)` 接受 `ReaderPullRequestID`，非同步回傳 `Outcome<ReaderPullRequestReviewMergeState, PRReaderFailure>`。結果和 Reader 自有的 `ReaderMergeableState`、`ReaderMergeStateStatus` 為 `package`、`Sendable`、`Equatable`。審閱沿用 `ReviewDecision?`。

- 新增單一 `PullRequestReviewMergeState` operation。GraphQL 變數為 `owner`、`name`、`number`。輸入採既有身份驗證和 `Int32(exactly:)`。在同一回應核對外層 `nameWithOwner`（不分大小寫）、PR number，以及外層 repository ID 與 PR 所屬 repository ID。
- 一次邏輯 fetch 沿用既有網路讀取、Bearer 與 401 recovery。正常路徑只有一筆請求。
- 顯式 `reviewDecision: null` 保留 `nil`。依固定 SDL 保留兩種已知 `UNKNOWN` 及詳細狀態的 `DRAFT`。直接採用 `isDraft`，`headRefOid` 驗證非空白後保留原字串。
- 沿用 Checks 的失敗分類。只有乾淨的 repository／PR 缺席、全部 GraphQL 錯誤明確證實 `repository`／`repository.pullRequest` 定位拒絕或缺席，及 client 最終認證拒絕可回 `.notReadable`。GraphQL 定位型別為 `NOT_FOUND` 或 `FORBIDDEN`，頂層與 extensions 同時提供 type 時必須一致。無效輸入也回 `.notReadable`。
- 回應歸屬不符、欄位層級拒絕、混合錯誤、回應不完整、裸 403、限流、傳輸與解碼失敗都回 `.unavailable`。已解碼的 schema 未知 enum 或空白必要身分值及 head OID 回 `.contentNotRepresentable`。取消優先，在 fetch 前、await 後及交付前都檢查，晚到回應或錯誤交付 `.unavailable`。
- 固定既有 SDL 與 Apollo 2.1.2 離線再生成。正式 Apollo 網路路徑須區分顯式 null、遺漏及型別錯誤。 [Reader 契約](../../docs/architecture/bounded-contexts/pr-reader.md)
