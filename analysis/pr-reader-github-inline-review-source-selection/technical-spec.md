# PR Reader 行內留言來源選擇技術規格

## 套件內入口

`RivetPRReaderGitHub` 的 `GitHubInlineReviewContentSource` 為 `package`、`Sendable`，以 `init(graphql: any GitHubGraphQLServing, rest: any GitHubRestClient)` 建立並持有 `GitHubReviewThreadsSource` 與 `GitHubInlineReviewCommentsSource`。`fetchInlineReviewContent(for: ReaderPullRequestID) async -> Outcome<ReaderInlineReviewContent, PRReaderFailure>` 接受原 PR 識別。

`ReaderInlineReviewContent: Equatable, Sendable` 保持 `package` 可見性。其 `.graphQLThreads([ReaderReviewThread])` 和 `.restComments([ReaderInlineReviewComment])` 直接承載既有資料，包含合法空陣列。保留來源識別與順序。REST 成功 case 的型別本身不帶 thread 狀態或 thread 分組。

## 選擇與取消

| 條件 | 結果 |
| --- | --- |
| 入口開始前已取消 | `.failure(.unavailable)`，兩來源皆零請求。 |
| GraphQL 成功且呼叫端尚未取消 | `.success(.graphQLThreads(threads))`，REST 零請求。 |
| GraphQL 回 `.notReadable` 或 `.contentNotRepresentable` 且呼叫端尚未取消 | 原失敗，REST 零請求。 |
| GraphQL 回 `.unavailable` 且呼叫端尚未取消 | 將原識別交給 REST 來源一次。成功包為 `.restComments`，失敗原樣返回。 |
| GraphQL 或 REST 返回後觀察到取消 | `.failure(.unavailable)`。捨棄返回值，尚未開始 REST 時不啟動。 |

依序在呼叫端原 Task 內 await，不建立額外 Task。入口在 GraphQL 前、GraphQL 返回與切換決策之間、REST 返回後觀察取消。分頁、驗證、失敗映射與請求期間的取消檢查沿用各來源。GraphQL 已累積的資料只在來源成功時可被交付。來源切換只依 Reader failure 和 Task 取消狀態。

完整快照、公開 `ReaderInlineThread`、`PRContentSource` 與其他內容接線留待後續 topic。原始 Apollo／REST 資料與技術錯誤留在各既有 adapter。 [需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-inline-review-source-selection/pr-reader-github-inline-review-source-selection.plan.md)
