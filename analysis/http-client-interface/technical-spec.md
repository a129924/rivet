# HTTP Client interface：技術規格

## Locked Decisions

### URL ownership and validation

`Endpoint` 不屬於 `RivetHTTPClient`。Endpoint、Base URL、Path、Query 與其 URL composition 都留在呼叫端或其 domain layer。

`HTTPURL` 是 package-owned public value object，公開 `value: URL`，並且只以以下 initializer 建構：

```swift
init(_ value: URL) throws(HTTPURLValidationError)
```

它接受 `http`、`https` scheme，且 URL 必須有非空的 host。錯誤型別為封閉的 package-owned `HTTPURLValidationError`，至少包含：

```swift
case unsupportedScheme(String?)
case missingHost
```

### Request and execution contract

`HTTPRequest` 直接持有已驗證的 `HTTPURL`，以及 `HTTPMethod`、`HTTPHeaders`、`body: Data?`；initializer 不 throws。

`HTTPHeaders` 將 name 正規化為小寫。dictionary literal 若包含相同或僅大小寫不同的 name，採用後者覆蓋前者的 deterministic 行為；不得以 `Dictionary(uniqueKeysWithValues:)` 造成 runtime trap。

`HTTPClient` 維持一般 throws：

```swift
func execute(_ request: HTTPRequest) async throws -> HTTPResponse
```

`Transport` 同樣維持一般 `async throws`。typed throws 不擴張到 HTTP call chain，因為 concrete Transport 的 error model 尚未穩定或被授權。不得建立 `HTTPClientError`，也不得包裝或改寫 Transport 原始 error。

### Requester boundary

Requester 將 `HTTPRequest` 映射為 Foundation `URLRequest`，並交給 injected `Transport`。它不驗證 URL，因為驗證已在 `HTTPURL` construction 完成。

`Requester` 與 `HTTPClient` 都符合 `Sendable`，可安全由隔離的 UI 或 domain state 傳遞。

`HTTPResponse` 是 Transport 直接回傳的 raw response contract；本 topic 不新增 status 或 decode policy。

### Exclusions

不實作 `URLSessionTransport`、網路呼叫、status code validation、retry、token refresh、decode policy 或 API domain Endpoint 設計。根 package 保持沒有 local dependency。

既有 Swift format、SwiftLint 與 coverage scripts 必須偵測並驗證包含 Swift source 的 standalone package。

## File Organization

source 依責任分為 `URL/`、`Request/`、`Response/`、`Execution/`；每個 public type 位於其責任對應的 Swift file。tests 使用相同的 `URL/`、`Request/`、`Response/`、`Execution/` 分組，Execution test doubles 與 execution tests 放在一起。此調整不改變 public API 或 execution behavior。
