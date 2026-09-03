# GraphQL PR State

GraphQL 有 request body 的 query 與 mutation 使用 `POST https://api.github.com/graphql`；本文件以 query field 與 object 分類，而非誤將每個 field 當成獨立 REST endpoint。

最後官方校驗：2026-09-03。

## 共通 PR 定位

本文件所有 query 都先以 `repository(owner: ..., name: ...) { pullRequest(number: ...) }` 定位目標 PR；因此必要輸入為 repository `owner`、repository `name` 與 PR `number`。`Repository.pullRequest` 的 `number` 為必填輸入。

`Query.repository` 與 `Repository.pullRequest` 的 type 都沒有 non-null 標記，可能為 `null`；呼叫端必須逐層判空。本 catalog 不對 null 的原因或後續 failure mapping 作推論。

## Checks

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Query path | nullable `PullRequest.statusCheckRollup` → `StatusCheckRollup.contexts(first: ..., after: ...)` |
| 重要欄位 | 整體為 `state`。`contexts` 的 `nodes` 是 `StatusCheckRollupContext` union，需選取 `__typename`：`CheckRun` 使用 `name`、`status`、`conclusion`、`detailsUrl`；`StatusContext` 使用 `context`、`state`、`targetUrl`。 |
| Nullability | `statusCheckRollup` type 沒有 non-null 標記，可能為 `null`；不得直接取其 `contexts`。`CheckRun.conclusion`、`CheckRun.detailsUrl` 與 `StatusContext.targetUrl` 也沒有 non-null 標記，必須保留 nullable 語意。本 catalog 不推論任何 null 的原因。 |
| 分頁 | 所有 GraphQL connection 必須提供 `first` 或 `last`（1–100）。前向分頁以 `pageInfo.hasNextPage` 判斷，並把 `pageInfo.endCursor` 傳入下一頁的 `after`。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest statusCheckRollup](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[StatusCheckRollup and union](https://docs.github.com/en/graphql/reference/commits#statuscheckrollup)、[CheckRun](https://docs.github.com/en/graphql/reference/checks#checkrun)、[Repository pullRequest](https://docs.github.com/en/graphql/reference/repos#repository)、[GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

## Changed Files and Viewed State

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續唯讀 |
| 必要定位輸入 | 依「共通 PR 定位」提供 `owner`、`name`、`number`；`files` 使用 `first` 與後續頁的 `after`。 |
| Query path | nullable `PullRequest.files(first: ..., after: ...)` → `PullRequestChangedFile` |
| 重要欄位 | `path`、`additions`、`deletions`、`changeType`、`viewerViewedState` |
| Viewed state | `UNVIEWED`、`VIEWED`、`DISMISSED`；`DISMISSED` 表示上次 viewed 後檔案有新 changes。 |
| Nullability | `files` type 沒有 non-null 標記，可能為 `null`；必須先判空，才可取 connection 的 `nodes` 或 `pageInfo`。本 catalog 不推論 null 的原因。 |
| 分頁 | 所有 GraphQL connection 必須提供 `first` 或 `last`（1–100）。前向分頁以 `pageInfo.hasNextPage` 判斷，並把 `pageInfo.endCursor` 傳入下一頁的 `after`。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest files and PullRequestChangedFile](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`viewerViewedState` 是 GitHub API 回傳的遠端資料；本 catalog 不對其內部計算或本機持久化作額外宣稱。

## Review Threads

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| 必要定位輸入 | 依「共通 PR 定位」提供 `owner`、`name`、`number`；外層使用 `reviewThreads(first: ..., after: ...)`，每個 thread 的巢狀 comments 使用 `comments(first: ..., after: ...)`。 |
| Query path | `PullRequest.reviewThreads(first: ...)` → `PullRequestReviewThreadConnection` → `PullRequestReviewThread` |
| 重要欄位 | `id`、`path`、`subjectType`、`line`、`startLine`、`startDiffSide`、`originalLine`、`originalStartLine`、`diffSide`、`comments`、`isResolved`、`isOutdated`、`resolvedBy` |
| Nullability | `line`、`startLine`、`startDiffSide`、`originalLine`、`originalStartLine` 與 `resolvedBy` 都沒有 non-null 標記，必須保留 nullable 語意。 |
| Target kind | `subjectType` 表示 thread 目標是 diff line 或 file。 |
| Comment node 輸出 | `comments.nodes` 選取 `PullRequestReviewComment.id`、`body`、`author`（nullable）、`createdAt`、`updatedAt`、`replyTo`（nullable）與 `url`，以提供 inline content、作者、時間與回覆關係。 |
| 權限能力 | `viewerCanResolve`、`viewerCanUnresolve` 可供未來 UI 判斷。 |
| 分頁 | 外層 `reviewThreads` 以其 `pageInfo.hasNextPage` 判斷，將其 `pageInfo.endCursor` 帶入下一個 `reviewThreads(after: ...)`，直到 `hasNextPage` 為 false。每個 thread 的巢狀 `comments` connection 也各自依自己的 `hasNextPage`／`endCursor` 推進 `comments(after: ...)`；不可交叉使用兩層 cursor。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest reviewThreads](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[PullRequestReviewThread](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)、[GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`isResolved` 與 `isOutdated` 是 `PullRequestReviewThread` 的 GitHub API fields；REST inline comments 的資料範圍見其獨立 endpoint reference。

## Review and Merge State

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| 必要定位輸入 | 依「共通 PR 定位」提供 `owner`、`name`、`number`。 |
| Query path | `PullRequest.reviewDecision`、`mergeable`、`mergeStateStatus`、`isDraft`、`headRefOid` |
| 用途 | 顯示整體 review decision、merge conflict 或 gating 狀態，以及目前 head SHA。 |
| Nullability | `reviewDecision` type 沒有 non-null 標記，可能為 `null`；不得將其解讀為任一 review 結果，亦不由本 catalog 推論 null 的原因。`mergeable` 或 merge state 也可能暫時未知；UI 不得將未知解讀為可 merge。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest state fields](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

## Sources

- [GraphQL Pull requests reference](https://docs.github.com/en/graphql/reference/pulls)
- [GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
