# PR Reader GitHub PR 詳情端點技術規格

Topic `pr-reader-github-pr-detail-endpoint`，規劃基線為 `dev` `386af9e`。#80、#81 與 #82 已提供 package 內可用的 REST 分類器與 headers factory。本切片採用兩者並保留已確認的 Reader `403` 語意。

## Target 與入口

`RivetPRReaderGitHub` 來源限定 `Sources/BoundedContexts/PRReader/Infra/GitHub/REST`，依賴 `RivetPRReader`、`GitHubIntegration`、`RivetHTTPClient`。供同一 Swift package 呼叫，無新增 library product。以 package 可見性的 `GitHubPullRequestBackgroundSource(client: any GitHubRestClient)` 提供 `fetchBackground(for: ReaderPullRequestID) async -> Outcome<ReaderBackground, PRReaderFailure>`。端點和 DTO 留在 Infra。Reader Core、既有 Port、Bridge、其他 BC 及共用 client 的正式程式碼屬唯讀範圍。

## 請求

1. 呼叫前檢查取消。沿用 `/user` 與 `/search/issues` 的 instance 形式，`GitHubPullRequestDetailEndpoint(id:)` 提供 `method: HTTPMethod = .get` 及 `makeURL() throws -> HTTPURL`。
2. `makeURL()` 驗證 `owner` 和 `repository` 僅含 ASCII 英數、`.`、`_`、`-`，拒絕空字串與 `.`、`..`，保留大小寫。PR 編號須為正整數。由 `GitHubRESTDestination` 建立 `https://api.github.com/repos/{owner}/{repo}/pulls/{number}`，無 query。無效識別在 client 前返回。
3. Adapter 使用 private static throwing `headers` getter 呼叫 `GitHubHeadersFactory.standard.make(requirements: [.standardREST])`，取得 `Accept: application/vnd.github+json`、`User-Agent: Rivet` 與 `X-GitHub-Api-Version: 2026-03-10`。目前單一需求不會組合衝突，拋錯時回 `.unavailable`。
4. 取得 URL 後呼叫一次 `try await client.get(url: url, headers: Self.headers, body: nil)`。預設 `get` 組裝 `HTTPRequest` 並委派 `executeGet`，認證及既有 `401` 恢復歸 client。Reader 不新增重試。等待回應期間的取消及 client 返回後觀察到的取消均回 `.unavailable`。

[GitHub PR 詳情](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)

## 回應與失敗

- 只有 `200` 解碼 DTO。取 `title`、`body` 與 `user.login`，合法字串原樣保留，其他欄位忽略。`body` 或 `user` 缺席或為 `null` 映為 `nil`。`title` 及存在的 `user` 物件中的 `login` 必須是字串。JSON 無法解碼、必要資料缺失或欄位型別錯誤映為 `.contentNotRepresentable`。
- 原始 `403` 由 Reader 先依 headers 處理。比對名稱忽略大小寫，值先去除首尾空白。若 `X-RateLimit-Remaining` 為 `0` 或 `Retry-After` 非空，回 `.unavailable`，其餘回 `.notReadable`。此分支不讀 body。共用分類器會讀 `message`、不以單有 `Retry-After` 作為限流證據，且權限訊息可優先於零剩餘額度，所以不將 Reader 的原始 `403` 交給它。
- 其餘非 `200` 呼叫 `GitHubResponseClassifier().classifyFailure(response)`。`.unauthorized`、`.notFound` 映為 `.notReadable`。`.rateLimited`、`.serverError`、`.unexpectedStatus` 映為 `.unavailable`。Exhaustive switch 中的 `.forbidden`、`.unclassifiedForbidden` 也映為 `.notReadable`，實際的原始 `403` 已提前處理。
- 無效識別及 client 的 `.authenticationRequired`、`.invalidRequest` 映為 `.notReadable`。其他執行失敗、憑證生命週期失敗、headers 組合失敗及取消映為 `.unavailable`。對外僅交付 Reader 的資料或 failure。

[GitHub REST 限流](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api#exceeding-the-rate-limit)

- [需求](requirements.md)
- [執行計畫](../../plan/pr-reader-github-pr-detail-endpoint/pr-reader-github-pr-detail-endpoint.plan.md)
