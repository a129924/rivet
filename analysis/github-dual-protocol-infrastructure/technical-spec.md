# GitHub Dual-Protocol Infrastructure：技術規格

## Locked Contract

```swift
public enum HTTPClientError: Error {
  case cancelled(underlying: any Error)
  case networkFailure(URLError)
  case nonHTTPResponse
  case underlyingFailure(any Error)
}

public protocol Transport: Sendable {
  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse
}
```

`Requester.execute(_:)`、`HTTPClient.execute(_:)` 與所有 public HTTP facade 都採用相同的 `throws(HTTPClientError)` contract。

## Behavior

- `URLSessionTransport` 以 injected `URLSession` 執行原始 `URLRequest`；預設 session 為 `.shared`。
- `HTTPURLResponse` 的 `statusCode`、headers 與 raw `Data` 映射為既有 `HTTPResponse`。
- HTTP status 不帶成功／失敗語意；2xx、4xx、5xx 均回傳 `HTTPResponse`。
- `URLError.cancelled` 與 `CancellationError` 映射為 `.cancelled(underlying:)`；其他 `URLError` 映射為 `.networkFailure`；非 HTTP response 映射為 `.nonHTTPResponse`；其他 error 映射為 `.underlyingFailure`。
- `HTTPClientError` 不宣告 `Equatable` 或 `Sendable`；`any Error` payload 保留原始底層 error。

## Boundaries

`RivetHTTPClient` 不知道 GitHub、REST endpoint、GraphQL、Apollo、token、認證、decode、retry 或 status policy。未來 GitHub Integration 才建立 `GitHubRESTAdapter` 與封裝 Apollo `ApolloClient` 的 `GitHubGraphQLAdapter`；上層／Domain 不直接依賴這兩種 client。
