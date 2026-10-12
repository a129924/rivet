# GitHub authenticated GET foundation — Technical Spec

## Boundary
GitHubIntegration/REST 的 internal concrete GitHubHTTPClient 持有同一 OAuthTokenProvider 與 bare HTTPClient。既有 Package.swift 已提供 RivetHTTPClient dependency。不新增 public client/protocol、BC contract 或 generic HTTP policy。

## Execution
executeGET(_ original: HTTPRequest) 先檢查 method == .get，URL 必須是 https://api.github.com、無 userinfo、fragment 或非標準 port，再檢查 caller cancellation。取得 provider.snapshot() 並保存完整 TokenSnapshot，對 original 套用 BearerAuth 後執行 HTTPClient.execute。僅首次 raw 401 將使用的 snapshot 傳給 replacementSnapshot(afterUnauthorized:)，再從 original 套用 replacement Bearer，執行一次。第二次 401 終止；其他 status 原樣返回。

## Failures and cancellation
Internal GitHubHTTPClientError 僅有 invalidRequest、authenticationRequired、credentialLifecycle(stage: restore|refresh|persist)、executionFailed；不保留 token、body 或 underlying credential。Provider .missingCredential／.authenticationRequired 與第二次 401 轉 authenticationRequired；.restore／.refresh／.persist 轉對應 technical stage。CancellationError、URLError.cancelled、HTTPClientError.cancelled 及 provider 包裝的 OAuthTokenRefreshError.cancelled 正規化為 CancellationError。每個 await 前後及 catch path 檢查 caller cancellation；client 不取消 provider shared refresh，亦不保證等待立即結束。

## Destination and redirect
Production internal initializer 建立帶有拒絕所有 HTTP redirect delegate 的 URLSession，透過 URLSessionTransport 建立 bare HTTPClient；3xx 原樣回傳。沿用 HTTPClient 原有 configuration 語意。只有 internal tests 可注入 fake transport，不對跨 target 公開任意 sender。
