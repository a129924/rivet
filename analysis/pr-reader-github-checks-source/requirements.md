# 讀取單一 PR 的 Checks 需求

Topic 為 `pr-reader-github-checks-source`，Primary BC 為 PR Reader。Human 已核准對話版計畫、獨立 worktree 實作與有條件的交付。執行基線固定於 `97e3db851348d2dc0305fc371aa792ce84b257ae`，包含 PR #102 的 Reader Apollo 基線。 [PR #102](https://github.com/a129924/rivet/pull/102)

## 使用情境與結果

完成合併前自查的套件內呼叫端，持有目標 GitHub.com PR 的 `ReaderPullRequestID` 和可讀取該 PR 的 `GitHubGraphQLServing`。讀取成功時，Caller 取得該 PR head 的 checks 整體狀態，以及包含 `CheckRun` 和 `StatusContext` 的完整有序明細，或確認該 PR 合法沒有 rollup。存在但為空的 rollup 仍須交付整體狀態。讀取不完整時，交付單一 Reader failure。 [Checks API 規格](../../docs/github-api/graphql-pr-state.md#checks)

## 驗收條件

- **CK01｜入口與映射。** 以套件內入口取得 rollup 與兩種明細，核對定位、整體狀態、原序、合法缺值，以及無 rollup 和帶狀態的空明細。
- **CK02｜分頁與歸屬。** 受控案例覆蓋跨頁原序、同名異 ID、游標、明細完整性，以及 repository、PR、head、rollup、state 或總數的可辨識變動。任何續頁或完整性核對失敗都回單一 failure。
- **CK03｜失敗與取消。** 區分 `.notReadable`、`.unavailable` 及 `.contentNotRepresentable`。必要資料的 GraphQL 錯誤、無法完成分頁或取消都不得交付部分明細。 [PR Reader Failure Contract](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)
- **CK04｜重現與回歸。** 在固定 Reader Apollo 基線驗證離線重生。既有 operation 與新的 Checks operation 一起產碼，並執行既有 Reader 與 GitHubIntegration 回歸。

## 影響範圍

本題交付 Reader Infra 查詢與映射、受控驗證及 BC 契約回寫。Check ID 僅在 Infra 驗證分頁。整體 review decision、合併判定、重跑 checks、產品 UI、完整 Reader 快照、REST fallback、持久化和 live 驗收留待後續需求。 [技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-checks-source/pr-reader-github-checks-source.plan.md)
