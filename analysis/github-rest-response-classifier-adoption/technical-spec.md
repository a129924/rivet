# PR Inbox 採用 GitHub REST 回應分類器技術規格

## 可見性與責任

`GitHubAPIFailure` 與 `GitHubResponseClassifier` 由 `internal` 調整為 `package`。為分類器宣告 `package init()`，並將 `classifyFailure(_ response: HTTPResponse) -> GitHubAPIFailure` 調整為 `package`。同一 Swift package 內的 `RivetPRInboxGitHub` 沿用既有 `GitHubIntegration` target 依賴。保留原有型別 conformances、分類規則、關聯值及 private helper。外部 API 與 `Package.swift` 維持目前契約。 [分類器](../../Sources/BoundedContexts/GitHubIntegration/REST/GitHubResponseClassifier.swift)

## 呼叫順序

在 `GitHubSelfReviewSource` 的共用私有 `get` 維持請求前後的 `Task.checkCancellation()`、REST GET 呼叫與既有 200 guard。200 原樣交回呼叫端走既有 DTO 解碼與業務驗證。拒絕分支呼叫分類器，使用 Adapter 自有且無 `default` 的 exhaustive switch，涵蓋所有七個 case，映射並拋出 `PRInboxFailure.unavailable`。既有外層 `catch` 仍交付 `.failure(.unavailable)`。成功與失敗路徑共用帳號查詢及搜尋每頁的 `get`。 [Inbox Adapter](../../Sources/PRInboxGitHub/GitHubSelfReviewSource.swift)

| GitHub 回應或失敗 | 採用前 Inbox 結果 | 採用後 |
| --- | --- | --- |
| 原始 401、明確權限拒絕 403、未知 403、404 | `.unavailable` | `.unauthorized`、`.forbidden`、`.unclassifiedForbidden`、`.notFound` 各映射 `.unavailable`。 |
| 限流 403 或 429、5xx、其他非 200 | `.unavailable` | `.rateLimited`、`.serverError`、`.unexpectedStatus` 各映射 `.unavailable`。 |
| 200 的解碼或業務驗證失敗 | `.unavailable` | 沿用既有路徑與結果。 |
| 認證需求、無效請求、傳輸、憑證生命週期、取消 | `.unavailable` | 沿用既有拋錯路徑與結果。 |

正式 REST client 持有首次 401 復原與至多一次原請求重送，第二次 401 拋出 `.authenticationRequired`。測試替身可直接提供 raw 401 給 Adapter，藉此驗證此分支的映射。執行階段拋錯與解碼失敗皆維持各自既有路徑。PR Inbox Port 只交付業務結果，GitHubIntegration 只回傳技術分類。

## Show Me

```text
REST client 回傳 HTTP 200 → 既有 DTO 解碼與業務驗證
REST client 回傳非 200   → GitHubResponseClassifier → Inbox .unavailable
請求或取消檢查拋錯      → 既有 catch → Inbox .unavailable

合成案例    缺少已知原因與限流證據的 403 → .unclassifiedForbidden → .unavailable
```

驗證後以受測程式碼核對示意。正式 401 復原及分頁由既有回歸測試覆蓋。
