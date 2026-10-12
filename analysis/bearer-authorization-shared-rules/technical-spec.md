# 既有 Bearer Authorization 入口共用規則：技術規格

## 共用純轉換

- 保持 `AuthorizationHeader.bearerValue(token:)`、`applyingBearer(token:to:)` 與 `AuthorizationHeaderError` 的 public 契約不變。
- 在 `AuthorizationHeader` 抽出唯一 internal、nonthrowing `replacingAuthorization(value:in:)`：移除所有 ASCII 大小寫 Authorization 變體，再寫入單一標準欄位，保留其他 dictionary entries，不修改輸入。
- 既有 public `applyingBearer` 驗證及 formatting 後委派此 helper；不新增第二套清理規則。

## BearerAuth public 契約與委派

```swift
public init(token: String) throws(AuthorizationHeaderError)

public func applying(to headers: [String: String]) -> [String: String]

public func applying(to request: HTTPRequest) -> HTTPRequest
```

- 初始化僅透過 `AuthorizationHeader.bearerValue` 驗證及 formatting，保存 `private let authorizationValue: String`，內容為完整合法 Header value。
- Headers overload 使用該 immutable value，直接委派 internal replacement helper。
- Request overload 將 `request.headers.values` 交給 Headers overload，經 `HTTPHeaders` 重建 Headers，再重建保留 URL、Method、Body 的 `HTTPRequest`。
- 維持 redacted description／debug description 與空 custom mirror。
- 禁止重複驗證或 formatting、`try!`、吞錯、舊邏輯 fallback，以及新增 public 中介型別。

## GraphQL 使用路徑

```swift
var authenticatedRequest = request
do {
  let auth = try BearerAuth(token: token.rawValue)
  authenticatedRequest.allHTTPHeaderFields =
    auth.applying(to: request.allHTTPHeaderFields ?? [:])
} catch AuthorizationHeaderError.invalidToken {
  throw GitHubGraphQLClientError.invalidAuthorizationToken
}
```

- 保持既有取消檢查與 TaskLocal Token 取得順序；缺少 Token 的處理不變。
- GraphQL 不直接呼叫 `AuthorizationHeader`，也不將 `URLRequest` 轉成 `HTTPRequest` 再轉回。
- `next`、response 後取消檢查與 HTTP status 分類皆在局部 catch 外。
- 新錯誤維持 internal、無 associated value。Wrapper 已原樣傳遞 `GitHubGraphQLClientError`，不修改 wrapper、executor 或 provider。
- 本地 Token 錯誤不進入僅處理 `.httpStatus(401)` 的 recovery 分支。
- Static isolation 僅對指定 Interceptor 放行 `RivetHTTPClient`；Manifest 已有依賴，不修改。

## 測試與文件介面

- 直接 Interceptor 測試可捕捉 Request 後由 `next` 拋 test sentinel，不新增 production seam。
- Fake fetcher 增加 test-only `replacementToken: String = "replacement"`；預設行為維持。
- 既有 `BearerAuthTests` 使用一般 module import，直接呼叫 Headers overload 驗證 public 可見性；不新增 consumer fixture 修改。
- 更新架構文字中的入口委派、source-breaking initializer、新 public overload 與本地錯誤邊界。REST 仍 deferred。
- Diagram applicability：N/A；既有圖表唯讀，不修改責任邊界或 lifecycle。

需求見 [requirements.md](requirements.md)；allowlist、T1–T6 與命令見 [plan](../../plan/bearer-authorization-shared-rules/bearer-authorization-shared-rules.plan.md)。
