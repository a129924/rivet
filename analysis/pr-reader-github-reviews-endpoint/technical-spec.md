# PR Reader 審閱紀錄端點技術規格

## 契約

- 在 `RivetPRReaderGitHub` 定義 internal `GitHubPullRequestReviewsEndpoint`，以 `init(id: ReaderPullRequestID)` 保存識別，`method: HTTPMethod` 為 `.get`。
- 同步 `makeURL(page: Int = 1) throws -> HTTPURL` 先驗證 `page > 0`，再使用既有 `GitHubPullRequestDetailEndpoint.validateIdentity(_:)`。
- 以 `GitHubRESTDestination.makeURL(path:queryItems:)` 建構 `https://api.github.com/repos/{owner}/{repo}/pulls/{number}/reviews`，依序加入十進位 `page`、`per_page=100`。保留識別原大小寫。
- 驗證失敗時拋出錯誤。同步端點的責任到 HTTP 方法和目的地為止。

## 預期同步呼叫樹

```text
GitHubPullRequestReviewsEndpoint.makeURL(page:)
├─ 驗證頁碼 > 0
├─ GitHubPullRequestDetailEndpoint.validateIdentity(_:)
└─ GitHubRESTDestination.makeURL(path:queryItems:)
```

[需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-reviews-endpoint/pr-reader-github-reviews-endpoint.plan.md)
