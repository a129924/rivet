# Swift HTTP Client Method Facade：技術規格

## Locked API Contract

`HTTPClient` 保留既有 advanced entry：

```swift
public func execute(_ request: HTTPRequest) async throws -> HTTPResponse
```

新增一般 request entry：

```swift
public func request(
  method: HTTPMethod,
  url: HTTPURL,
  headers: HTTPHeaders = HTTPHeaders(),
  body: Data? = nil
) async throws -> HTTPResponse
```

新增五個固定 method facade，皆使用與 `request(...)` 相同的參數預設與回傳／throws contract：

```swift
public func get(url: HTTPURL, headers: HTTPHeaders = HTTPHeaders(), body: Data? = nil) async throws -> HTTPResponse
public func post(url: HTTPURL, headers: HTTPHeaders = HTTPHeaders(), body: Data? = nil) async throws -> HTTPResponse
public func put(url: HTTPURL, headers: HTTPHeaders = HTTPHeaders(), body: Data? = nil) async throws -> HTTPResponse
public func patch(url: HTTPURL, headers: HTTPHeaders = HTTPHeaders(), body: Data? = nil) async throws -> HTTPResponse
public func delete(url: HTTPURL, headers: HTTPHeaders = HTTPHeaders(), body: Data? = nil) async throws -> HTTPResponse
```

`request(...)` 接受任意既有 `HTTPMethod`；五個 verb 分別固定 `.get`、`.post`、`.put`、`.patch`、`.delete`。此 contract 不新增 `HEAD` 或 `OPTIONS` entry。

## Behavior and Boundaries

- 各 facade 以其 method、已驗證 `HTTPURL`、`HTTPHeaders` 與可選 `Data` 建立既有不 throws 的 `HTTPRequest`。
- `request(...)` 與每個 verb 都必須委派 `execute(_:)`；不得直連 `Requester` 或 `Transport`，也不得複製 URL request mapping。
- headers 預設為空 `HTTPHeaders`，body 預設為 `nil`；未提供時的 request semantics 與直接建立 `HTTPRequest` 的預設相同。
- `HTTPURL` construction 的 typed throws 仍是唯一 validation boundary。facade 不接受 `URL`、String、Endpoint、path 或 query 片段，且不新增 validation。
- `HTTPResponse` 是 raw response contract；facade 不新增 status 或 decode policy。
- facade、`execute(_:)`、`Requester` 與 `Transport` 皆維持一般 `async throws`。transport error 不得包裝、映射或改寫；不得建立 `HTTPClientError`。
- `Requester` 的既有 public visibility、URLRequest mapping 與 responsibility 不變。

## Architecture Writeback

只回寫現有 HTTP client architecture 文件與既有 package structure canvas，使其長期事實包含 `HTTPClient` 的 public method facade 與其委派至既有 `execute → Requester → Transport` 鏈。回寫不得改變 GitHub Integration／核心 BC 邊界、BC Map、URL ownership，或宣稱 concrete transport、session lifecycle、Endpoint composition 已存在。

若 implementation 修改 canvas，必須依 `architecture-canvas` workflow 重建並驗證該 artifact；本 planning topic 不產生或修改圖。

## Required Verification

- 每個 verb 的 captured request 有正確固定 method，並保留傳入的 URL、headers、body。
- `request(...)` 將自訂或既有任意 `HTTPMethod`、URL、headers、body 無損傳至 fake transport。
- facade 形成的 request 與等價 `HTTPRequest` 經 `execute(_:)` 所形成的 request 等價。
- 所有新 entry 均抵達 fake transport、回傳同一 raw `HTTPResponse`，並原樣拋出 fake transport 的 error。
- `execute(_:)` 既有成功與 error passthrough regression tests 維持通過。
