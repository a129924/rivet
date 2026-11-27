# GitHub REST 預設重新導向政策技術規格

## 責任與接線

- 在 `Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPRedirectDelegate.swift` 宣告 internal `RedirectPolicy: Sendable`。其同步方法為 `func allows(_ proposedRequest: URLRequest, from response: HTTPURLResponse) -> Bool`。
- 同檔的 internal `DefaultGitHubRESTRedirectPolicy` 為無狀態 struct，對每次 Foundation 提出的重新導向回傳 `false`。
- 同檔的 internal final `GitHubHTTPRedirectDelegate` conform `NSObject`、`URLSessionTaskDelegate` 與 `Sendable`。initializer 注入 `any RedirectPolicy`，由 private immutable property 持有。回呼把原始 response 與原樣 proposed request 交給 policy，依 Boolean 以原樣 proposed request 或 `nil` 呼叫 completion handler 恰一次。
- `GitHubHTTPClient.makeSession(configuration:)` 建立 `GitHubHTTPRedirectDelegate(policy: DefaultGitHubRESTRedirectPolicy())`。自 `GitHubHTTPClient.swift` 移除舊 blocker 宣告。既有 session configuration、工廠和 public／package signature 沿用。新 Swift 檔位於既有 target 的路徑下。
- `HTTPResponse` 仍透過既有 transport 回傳。分類器、認證復原、目的地驗證、取消正規化皆依原有責任。此 topic 無配置介面或生產允許政策。

## Show Me

```text
OAuth REST／共用 REST factory／登入帳號探查
  └─ makeHTTPClient → makeSession
       └─ GitHubHTTPRedirectDelegate
            ├─ policy.allows(proposedRequest, from: response)
            └─ completionHandler(原 proposedRequest 或 nil)
  ← 預設拒絕時，REST transport 回傳原始 302
```

以受控 fixture 分別觀察 policy 決策、delegate 轉譯、預設 session 接線及 raw response；以既有 client 攔截資料驗證認證復原次數。 [需求](requirements.md) · [驗收](../../plan/github-rest-redirect-policy/github-rest-redirect-policy.plan.md)
