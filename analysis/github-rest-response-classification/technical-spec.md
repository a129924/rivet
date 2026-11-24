# GitHub REST 回應分類 Phase A 技術規格

同一來源檔定義無狀態的 `internal struct GitHubResponseClassifier: Sendable` 與 `internal enum GitHubAPIFailure: Error, Sendable, Equatable`。純分類入口為 `classifyFailure(_ response: HTTPResponse) -> GitHubAPIFailure`。輸入由 Endpoint／Operation 依自身契約先行判定拒絕。本階段的呼叫來自合成回應的測試。

| HTTP 狀態 | 結果 |
| --- | --- |
| 401 | `.unauthorized` |
| 403 | 依下方證據 |
| 404 | `.notFound` |
| 429 | `.rateLimited` |
| 500–599 | `.serverError(statusCode:)` |
| 其他，包含被拒絕的 2xx／3xx | `.unexpectedStatus(statusCode:)` |

403 使用既有 `HTTPResponse.json` 解碼頂層字串 `message`。用換行或後接空白的句點分句，去除首尾空白與尾端句點，以英文大小寫無關比對完整句：

- 權限為 `Resource not accessible by integration` 或 `Resource not accessible by personal access token`。
- Secondary 限流為 `You have exceeded a secondary rate limit`，或該句接上 ` and have been temporarily blocked from content creation`。

兩種明示原因同時出現回 `.unclassifiedForbidden`。只有明示權限回 `.forbidden`，即使剩餘額度為零。只有明示 secondary 限流回 `.rateLimited`，與剩餘額度無關。缺少明示原因時，使用 `HTTPHeaders` 的大小寫無關查詢，去除 `X-RateLimit-Remaining` 首尾空白，接受可解析為非負 `Int` 的完整 ASCII 十進位。合法零值回 `.rateLimited`，其餘回 `.unclassifiedForbidden`。Retry-After、Reset 與必要權限 header 單獨出現時仍為原因不明。

依據：[GitHub REST 限流](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api#exceeding-the-rate-limit) · [GitHub 權限錯誤](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api#resource-not-accessible)。

既有 REST client 在首次 401 後取得 replacement snapshot 才重送，最多一次。重送仍為 401 拋出 `.authenticationRequired`。非 401 交付 raw response。Local validation、credential lifecycle、execution error 與取消沿既有 execution 路徑傳遞，與新分類入口分立。
