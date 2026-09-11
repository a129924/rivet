# Swift HTTP Response JSON Sendable Contract：技術規格

## Locked Public API Contract

`HTTPResponse` 的兩個 public synchronous throwing JSON APIs 為下列 source-breaking signatures：

```swift
public func json<T: Decodable & Sendable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T

public func jsonSemantic<T: Decodable & Sendable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T
```

兩者維持既有 body decode 行為與 caller-supplied `JSONDecoder` ownership；唯一 production contract 變更是 `T` 新增 `Sendable` 約束。

## Locked Boundaries

- 不修改 `JSONSemanticDecodingError`、其 `Kind`、`underlyingError` 或 error handling。
- 不修改 raw `HTTPResponse` properties、HTTP execution chain、decoder ownership、HTTP status／headers／`Content-Type` metadata policy 或 package manifest。
- 不修改 architecture docs、diagrams 或既有 locked topics。
- test 僅更新直接傳給 `json` 或 `jsonSemantic` 作為 decoded payload 的 local fixture conformance；不改變 test scenario 或 error fixture contract。

## Required Verification

- 保留 `json` 與 `jsonSemantic` 的 success 與 configured decoder coverage。
- 保留 raw `DecodingError` passthrough、semantic error mapping 與 `underlyingError` retention coverage。
- 保留 metadata non-validation 與 raw response regression coverage。
- 在 `RivetHTTPClient` standalone package 執行 `swift build` 與 `swift test`。
