# GraphQL PR State

GraphQL 有 request body 的 query 與 mutation 使用 `POST https://api.github.com/graphql`；本文件以 query field 與 object 分類，而非誤將每個 field 當成獨立 REST endpoint。

最後官方校驗：2026-09-03。

## 共通 PR 定位

本文件所有 query 都先以 `repository(owner: ..., name: ...) { pullRequest(number: ...) }` 定位目標 PR；因此必要輸入為 repository `owner`、repository `name` 與 PR `number`。`Repository.pullRequest` 的 `number` 為必填輸入。

## Checks

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Query path | `PullRequest.statusCheckRollup` → `StatusCheckRollup` |
| 重要欄位 | 整體為 `state`。`contexts(first: ...)` 的 `nodes` 是 `StatusCheckRollupContext` union，需選取 `__typename`：`CheckRun` 使用 `name`、`status`、`conclusion`、`detailsUrl`；`StatusContext` 使用 `context`、`state`、`targetUrl`。 |
| 分頁 | `contexts` 是 connection，使用 cursor 與 `pageInfo`。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest statusCheckRollup](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[StatusCheckRollup and union](https://docs.github.com/en/graphql/reference/commits#statuscheckrollup)、[CheckRun](https://docs.github.com/en/graphql/reference/checks#checkrun)、[Repository pullRequest](https://docs.github.com/en/graphql/reference/repos#repository)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

## Changed Files and Viewed State

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續唯讀 |
| 必要定位輸入 | 依「共通 PR 定位」提供 `owner`、`name`、`number`；`files` 另需 `first`。 |
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
| 必要定位輸入 | 依「共通 PR 定位」提供 `owner`、`name`、`number`；外層使用 `reviewThreads(first: ..., after: ...)`，每個 thread 的巢狀 comments 使用 `comments(first: ..., after: ...)`。 |
| Query path | `PullRequest.reviewThreads(first: ...)` → `PullRequestReviewThreadConnection` → `PullRequestReviewThread` |
| 重要欄位 | `id`、`path`、`line`、`startLine`、`originalLine`、`originalStartLine`、`diffSide`、`comments`、`isResolved`、`isOutdated`、`resolvedBy` |
| 權限能力 | `viewerCanResolve`、`viewerCanUnresolve` 可供未來 UI 判斷。 |
| 分頁 | 外層與每個巢狀 comments connection 都各自使用 `pageInfo` 的 cursor；不可將外層 cursor 用於 thread comments。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest reviewThreads](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[PullRequestReviewThread](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`isResolved` 與 `isOutdated` 是 `PullRequestReviewThread` 的 GitHub API fields；REST inline comments 的資料範圍見其獨立 endpoint reference。

## Review and Merge State

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| 必要定位輸入 | 依「共通 PR 定位」提供 `owner`、`name`、`number`。 |
| Query path | `PullRequest.reviewDecision`、`mergeable`、`mergeStateStatus`、`isDraft`、`headRefOid` |
| 用途 | 顯示整體 review decision、merge conflict 或 gating 狀態，以及目前 head SHA。 |
| 注意事項 | `mergeable` 或 merge state 可能暫時未知；UI 不得將未知解讀為可 merge。 |
| 認證／權限 | GitHub 要求有效 token；token 必須可存取目標 repository。此 GraphQL field reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [PullRequest state fields](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

## Sources

- [GraphQL Pull requests reference](https://docs.github.com/en/graphql/reference/pulls)
- [GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
