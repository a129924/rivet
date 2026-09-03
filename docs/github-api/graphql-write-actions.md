# GraphQL Write Actions

所有 operation 的 request body 都使用 `POST https://api.github.com/graphql`。本文件是後續能力的官方參考，不授權目前 MVP 實作寫入操作。

最後官方校驗：2026-09-03。

## File Viewed

| Operation | 重要輸入 | 成功結果 | 認證／權限 | 狀態 | 官方來源 |
| --- | --- | --- | --- | --- |
| `markFileAsViewed` | `pullRequestId`、`path` | 更新後的 `pullRequest` | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#markfileasviewedinput)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |
| `unmarkFileAsViewed` | `pullRequestId`、`path` | 更新後的 `pullRequest` | GitHub 要求有效 token 且可存取目標 repository；reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#unmarkfileasviewedinput)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

這兩個 mutation 操作 GitHub API 的 pull request file viewed state；本 catalog 不宣稱 GitHub 網頁的同步行為。

## Review Thread Resolution

| Operation | 重要輸入 | 成功結果 | 認證／權限 | 狀態 | 官方來源 |
| --- | --- | --- | --- | --- |
| `resolveReviewThread` | `threadId` | 更新後的 thread | GitHub 要求有效 token 且可存取目標 repository；呼叫前 `PullRequestReviewThread.viewerCanResolve` 必須為 true。reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#resolvereviewthreadinput)、[thread capability](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |
| `unresolveReviewThread` | `threadId` | 更新後的 thread | GitHub 要求有效 token 且可存取目標 repository；呼叫前 `PullRequestReviewThread.viewerCanUnresolve` 必須為 true。reference 未列出 operation-specific fine-grained permission。 | 後續寫入 | [mutation/input](https://docs.github.com/en/graphql/reference/pulls#unresolvereviewthreadinput)、[thread capability](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)、[transport/auth](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

`threadId` 是 `PullRequestReviewThread.id`，不是 REST inline comment id。

## Merge Pull Request

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入 |
| Operation | `mergePullRequest` |
| 重要輸入 | `pullRequestId`、`expectedHeadOid`、`mergeMethod` |
| merge method gate | `mergeMethod` 為 `MERGE`、`SQUASH` 或 `REBASE`；呼叫前分別確認 `Repository.mergeCommitAllowed`、`squashMergeAllowed` 或 `rebaseMergeAllowed` 為 true。 |
| 成功結果 | `MergePullRequestPayload.pullRequest` 為已合併的 PR。 |
| 併發安全 | 若提供 `expectedHeadOid`，PR head OID 必須相符才允許 merge。以目前 `headRefOid` 作為輸入及失敗後重新載入，皆是未來 Rivet UX policy。 |
| 認證／權限 | 有效 token 與 repository read access 並不足夠；呼叫者必須具備 GitHub 允許合併該 PR 的寫入權限。fine-grained token 的 REST merge reference 要求 `Contents` permission（write）；`viewerCanMergeAsAdmin` 僅表示可略過 branch protection 並立即 merge。 |
| 官方來源 | [merge mutation/payload/input](https://docs.github.com/en/graphql/reference/pulls#mergepullrequest)、[MergePullRequestInput](https://docs.github.com/en/graphql/reference/pulls#mergepullrequestinput)、[PullRequest merge method enum](https://docs.github.com/en/graphql/reference/pulls#pullrequestmergemethod)、[Repository merge settings](https://docs.github.com/en/graphql/reference/repos#repository)、[PullRequest viewerCanMergeAsAdmin](https://docs.github.com/en/graphql/reference/pulls#pullrequest)、[REST merge permission](https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request)、[GraphQL transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api) |

REST 替代方案為 `PUT /repos/{owner}/{repo}/pulls/{pull_number}/merge`，可帶 `sha` 與 `merge_method`；後續實作 topic 才選定 protocol 與 UX。

## Sources

- [GraphQL Pull requests mutations](https://docs.github.com/en/graphql/reference/pulls)
- [Merge a pull request](https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request)
