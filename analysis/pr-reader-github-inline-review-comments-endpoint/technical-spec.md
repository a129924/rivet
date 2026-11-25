# PR Reader 行內審閱留言端點技術規格

## 契約

- 在 `RivetPRReaderGitHub` 定義 internal `GitHubInlineReviewCommentsEndpoint`。以 `init(id: ReaderPullRequestID)` 保存同一筆識別，`method: HTTPMethod` 為 `.get`。
- 同步 `makeURL(page: Int = 1) throws -> HTTPURL` 先驗證 `page > 0`。非正數頁碼拋出私有驗證錯誤 `invalidPage`。其餘正整數包含 `Int.max`。
- 細部識別驗證使用 `GitHubPullRequestDetailEndpoint.validateIdentity(_:)`，沿用既有錯誤行為。
- 呼叫 `GitHubRESTDestination.makeURL(path:queryItems:)` 建構 `https://api.github.com/repos/{owner}/{repo}/pulls/{number}/comments?page={page}&per_page=100`。保留 owner、repository 原大小寫，依序加入十進位 `page` 和固定的 `per_page=100`。端點的責任止於方法與目的地。 [GitHub REST 端點規格](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request)

## Show Me 同步呼叫樹

```text
GitHubInlineReviewCommentsEndpoint.makeURL(page:)
├─ 驗證頁碼 > 0，失敗則拋出 invalidPage
├─ GitHubPullRequestDetailEndpoint.validateIdentity(_:)
└─ GitHubRESTDestination.makeURL(path:queryItems:)
```

以實際程式碼及 IC01、IC02 核對呼叫順序及結果，將核對結果和差異記入本機審閱證據。

[需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-inline-review-comments-endpoint/pr-reader-github-inline-review-comments-endpoint.plan.md)
