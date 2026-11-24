# PR Reader GitHub PR 詳情端點技術規格

Topic `pr-reader-github-pr-detail-endpoint`，規劃基線為 `dev` `386af9e`。依 Draft PR #84 的 Human Review 決策，Reader 與 PR #81 的 Inbox 共用 GitHub REST 技術分類。

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
- 所有非 `200` 回應，包括 `403`，交給 `GitHubResponseClassifier().classifyFailure(response)`。Reader Infra 將 `.unauthorized`、`.notFound`、`.forbidden`、`.unclassifiedForbidden` 映為 `.notReadable`，將 `.rateLimited`、`.serverError`、`.unexpectedStatus` 映為 `.unavailable`。
- `403` 由共用分類器辨識。只有 `Retry-After` 時分類為 `.unclassifiedForbidden`，可辨識的次級限流訊息分類為 `.rateLimited`，明確權限拒絕搭配剩餘額度 `0` 時分類為 `.forbidden`。
- 無效識別及 client 的 `.authenticationRequired`、`.invalidRequest` 映為 `.notReadable`。其他執行失敗、憑證生命週期失敗、headers 組合失敗及取消映為 `.unavailable`。對外僅交付 Reader 的資料或 failure。

[GitHub REST 限流](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api#exceeding-the-rate-limit)

- [需求](requirements.md)
- [執行計畫](../../plan/pr-reader-github-pr-detail-endpoint/pr-reader-github-pr-detail-endpoint.plan.md)
