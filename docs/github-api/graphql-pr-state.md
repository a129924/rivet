# GraphQL PR State

GraphQL 有 request body 的 query 與 mutation 使用 `POST https://api.github.com/graphql`；本文件以 query field 與 object 分類，而非誤將每個 field 當成獨立 REST endpoint。

最後官方校驗：2026-09-02。

## Changed Files and Viewed State

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續唯讀 |
| Query path | `PullRequest.files(first: ...)` → `PullRequestChangedFile` |
| 重要欄位 | `path`、`additions`、`deletions`、`changeType`、`viewerViewedState` |
| Viewed state | `UNVIEWED`、`VIEWED`、`DISMISSED`；`DISMISSED` 表示上次 viewed 後檔案有新 changes。 |
| 分頁 | connection 的 `pageInfo` 與 cursor。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest files and PullRequestChangedFile](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`viewerViewedState` 是 GitHub API 回傳的遠端資料；本 catalog 不對其內部計算或本機持久化作額外宣稱。

## Review Threads

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Query path | `PullRequest.reviewThreads(first: ...)` → `PullRequestReviewThreadConnection` → `PullRequestReviewThread` |
| 重要欄位 | `id`、`path`、`line`、`diffSide`、`startLine`、`comments`、`isResolved`、`isOutdated`、`resolvedBy` |
| 權限能力 | `viewerCanResolve`、`viewerCanUnresolve` 可供未來 UI 判斷。 |
| 分頁 | review thread 與 comments connection 都須使用 cursor。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest reviewThreads](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[PullRequestReviewThread](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`isResolved` 與 `isOutdated` 是 `PullRequestReviewThread` 的 GitHub API fields；REST inline comments 的資料範圍見其獨立 endpoint reference。

## Review and Merge State

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Query path | `PullRequest.reviewDecision`、`mergeable`、`mergeStateStatus`、`isDraft`、`headRefOid` |
| 用途 | 顯示整體 review decision、merge conflict 或 gating 狀態，以及目前 head SHA。 |
| 注意事項 | `mergeable` 或 merge state 可能暫時未知；UI 不得將未知解讀為可 merge。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest state fields](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

## Sources

- [GraphQL Pull requests reference](https://docs.github.com/en/graphql/reference/pulls)
- [GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
