# GraphQL Write Actions

所有 operation 都使用 `POST https://api.github.com/graphql`。本文件是後續能力的官方參考，不授權目前 MVP 實作寫入操作。

最後官方校驗：2026-09-02。

## File Viewed

| Operation | 重要輸入 | 成功結果 | 狀態 |
| --- | --- | --- | --- |
| `markFileAsViewed` | `pullRequestId`、`path` | 更新後的 `pullRequest` | 後續寫入 |
| `unmarkFileAsViewed` | `pullRequestId`、`path` | 更新後的 `pullRequest` | 後續寫入 |

這兩個 mutation 寫入的是 GitHub-side viewed state，與 GitHub 網頁共用。

## Review Thread Resolution

| Operation | 重要輸入 | 成功結果 | 狀態 |
| --- | --- | --- | --- |
| `resolveReviewThread` | `threadId` | 更新後的 thread | 後續寫入 |
| `unresolveReviewThread` | `threadId` | 更新後的 thread | 後續寫入 |

`threadId` 是 `PullRequestThread.id`，不是 REST inline comment id。

## Merge Pull Request

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入 |
| Operation | `mergePullRequest` |
| 重要輸入 | `pullRequestId`、`expectedHeadOid`、`mergeMethod` |
| 併發安全 | 使用目前讀取到的 `headRefOid` 作為 expected head；head 已變動時，操作應失敗並要求重新載入。 |

REST 替代方案為 `PUT /repos/{owner}/{repo}/pulls/{pull_number}/merge`，可帶 `sha` 與 `merge_method`；後續實作 topic 才選定 protocol 與 UX。

## Sources

- [GraphQL Pull requests mutations](https://docs.github.com/en/graphql/reference/pulls)
- [Merge a pull request](https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request)
