# GraphQL PR State

GraphQL requests 共用 `POST https://api.github.com/graphql`；本文件以 query field 與 object 分類，而非誤將每個 field 當成獨立 REST endpoint。

最後官方校驗：2026-09-02。

## Changed Files and Viewed State

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入（讀取本身可用） |
| Query path | `PullRequest.files(first: ...)` → `PullRequestChangedFile` |
| 重要欄位 | `path`、`additions`、`deletions`、`changeType`、`viewerViewedState` |
| Viewed state | `UNVIEWED`、`VIEWED`、`DISMISSED`；`DISMISSED` 表示上次 viewed 後檔案有新 changes。 |
| 分頁 | connection 的 `pageInfo` 與 cursor。 |

GitHub 已計算 viewed invalidation；不得以 local diff hash 自行重建。

## Review Threads

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Query path | `PullRequest.reviewThreads(first: ...)` → `PullRequestThread` |
| 重要欄位 | `id`、`path`、`line`、`diffSide`、`startLine`、`comments`、`isResolved`、`isOutdated`、`resolvedBy` |
| 權限能力 | `viewerCanResolve`、`viewerCanUnresolve` 可供未來 UI 判斷。 |
| 分頁 | review thread 與 comments connection 都須使用 cursor。 |

`isResolved` 與 `isOutdated` 為 GitHub 判定；REST inline comments 不提供相同的 thread lifecycle view。

## Review and Merge State

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Query path | `PullRequest.reviewDecision`、`mergeable`、`mergeStateStatus`、`isDraft`、`headRefOid` |
| 用途 | 顯示整體 review decision、merge conflict 或 gating 狀態，以及目前 head SHA。 |
| 注意事項 | `mergeable` 或 merge state 可能暫時未知；UI 不得將未知解讀為可 merge。 |

## Sources

- [GraphQL Pull requests reference](https://docs.github.com/en/graphql/reference/pulls)
- [GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
