# PR Inbox 自查 REST Endpoint 技術契約

- `Sources/BoundedContexts/GitHubIntegration/REST/Endpoints/GitHubAuthenticatedUserEndpoint.swift` 的 `package struct GitHubAuthenticatedUserEndpoint` 提供 `package init()`、`package static let shared`、`package var method: HTTPMethod` 與 `package func makeURL() throws -> HTTPURL`。固定 GitHub.com `GET /user` 且沒有 query。登入和 Inbox 取用同一實例，沿用各自原入口。
- `Sources/PRInboxGitHub/Endpoints/GitHubSelfReviewSearchEndpoint.swift` 的 internal struct 提供 `init(author: String)`、GET、搜尋 path、query、page size 和 URL 組裝。Inbox 先驗證登入名，再建立一次並用於首請求及分頁。Query 為 `is:pr is:open author:<login>`、`per_page=100`。
- `Sources/BoundedContexts/GitHubIntegration/REST/GitHubRESTDestination.swift` 提供 package 層的 `makeURL(path:queryItems:)` 與 `isAllowed(_:)`。HTTPS 與 `api.github.com` 忽略大小寫，允許省略 port 或使用 443，拒絕其他 scheme、host、port、帳密與 fragment。REST client 在 token snapshot 前驗證 method 與目的地，保留 redirect 阻擋及 401 recovery。Inbox 的 next Link 和 `repository_url` 共用判定。
- `GitHubSelfReviewSource` 沿用 `GitHubRestClient.get(url:headers:body:)`，負責 Link 解析、分頁上限及完成條件、DTO 路徑與欄位、失敗回傳。Next 可省略，出現時最多一條。同實例比對原始 percent-encoded path、解碼後的精確 query 與 `page=current+1`。既有等值編碼與 query 順序均可，通過後送原 URL。拒絕重複、缺少或多餘欄位。
