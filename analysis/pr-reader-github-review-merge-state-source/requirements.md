# 單一 PR 審閱與合併狀態需求

Topic `pr-reader-github-review-merge-state-source`。使用者已核准對話版計畫、獨立 feature worktree 實作，以及驗證與審查通過後的單一 topic commit、推送與 Draft PR。

PR 自查者需要辨識 GitHub 目前如何判定指定 PR 的整體審閱與合併狀態。套件呼叫端提供 `ReaderPullRequestID`，從同一筆可核對歸屬的 GitHub.com PR 取得 `reviewDecision`、`mergeable`、`mergeStateStatus`、`isDraft` 及 `headRefOid`，或收到單一 `PRReaderFailure`。審閱缺值、兩種合併未知值及查詢失敗須可區分。 [API Catalog](../../docs/github-api/graphql-pr-state.md#review-and-merge-state)

- 保留顯式的 `reviewDecision: null`、兩個 enum 各自的 `UNKNOWN`、原始 Draft 標記與 head OID。
- 可確認的 PR 缺席或拒絕回 `.notReadable`。無法確認完整回應、錯誤歸屬或取消回 `.unavailable`。已解碼而無法保真表達的必要資料回 `.contentNotRepresentable`。
- 範圍止於套件內唯讀入口。審閱與合併寫入、合併許可推導、現有 Checks 與審閱對話改造、完整快照、UI 和持久化另案。

基線為 `10610d0be88c1d2bce37d5418fa5bae3171f8526`。 [技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-review-merge-state-source/pr-reader-github-review-merge-state-source.plan.md)
