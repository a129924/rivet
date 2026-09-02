# GraphQL Write Actions

所有 operation 的 request body 都使用 `POST https://api.github.com/graphql`。本文件是後續能力的官方參考，不授權目前 MVP 實作寫入操作。

最後官方校驗：2026-09-02。

## File Viewed

| Operation | 重要輸入 | 成功結果 | 認證／權限 | 狀態 | 官方來源 |
| --- | --- | --- | --- | --- |
| `markFileAsViewed` | `pullRequestId`、`path` | 更新後的 `pullRequest` | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#markfileasviewedinput)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |
| `unmarkFileAsViewed` | `pullRequestId`、`path` | 更新後的 `pullRequest` | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#unmarkfileasviewedinput)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

這兩個 mutation 操作 GitHub API 的 pull request file viewed state；本 catalog 不宣稱 GitHub 網頁的同步行為。

## Review Thread Resolution

| Operation | 重要輸入 | 成功結果 | 認證／權限 | 狀態 | 官方來源 |
| --- | --- | --- | --- | --- |
| `resolveReviewThread` | `threadId` | 更新後的 thread | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#resolvereviewthreadinput)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |
| `unresolveReviewThread` | `threadId` | 更新後的 thread | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#unresolvereviewthreadinput)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`threadId` 是 `PullRequestReviewThread.id`，不是 REST inline comment id。

## Merge Pull Request

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入 |
| Operation | `mergePullRequest` |
| 重要輸入 | `pullRequestId`、`expectedHeadOid`、`mergeMethod` |
| 併發安全 | 若提供 `expectedHeadOid`，PR head OID 必須相符才允許 merge。以目前 `headRefOid` 作為輸入及失敗後重新載入，皆是未來 Rivet UX policy。 |
| 認證／權限 | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 |
| 官方來源 | [MergePullRequestInput](https://docs.github.com/en/graphql/reference/pulls#mergepullrequestinput)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

REST 替代方案為 `PUT /repos/{owner}/{repo}/pulls/{pull_number}/merge`，可帶 `sha` 與 `merge_method`；後續實作 topic 才選定 protocol 與 UX。

## Sources

- [GraphQL Pull requests mutations](https://docs.github.com/en/graphql/reference/pulls)
- [Merge a pull request](https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request)
