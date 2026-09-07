# GitHub Dual-Protocol Infrastructure

## Summary

本 topic 只在 `RivetHTTPClient` 加入 `URLSessionTransport` 與 `HTTPClientError`。它是通用 HTTP transport，不新增 GitHub API adapter、Apollo 或任何 Domain 功能。

## Swift Implementation Handoff

### Goal

建立唯一的 production HTTP transport，並令所有 package transport failure 經 `HTTPClientError` 對外表達。

### Non-Goal

- 不建立 `GitHubRESTClient`、`GitHubGraphQLClient`、`GitHubIntegrationClient` 或新的 GitHub Integration package／target。
- 不實作 Apollo dependency、schema、codegen、token interceptor、GraphQL operation、OAuth、PAT、Keychain、登入 UI 或 refresh。
- 不加入 endpoint、decode、retry、status policy、快取、pagination、PR Domain、UI 或 GitHub 寫入。

### In-Scope

- `URLSessionTransport` 實作 `Transport`。
- 新增 `HTTPClientError`，並將 `Transport.execute(_:)`、`Requester.execute(_:)`、`HTTPClient.execute(_:)` 與所有 public facade 改為 `throws(HTTPClientError)`。
- response mapping、底層 error mapping、既有 test doubles 與 tests。
- 回寫所有「尚未有 URLSessionTransport／真實網路呼叫／統一 package error」的長期文件與兩份既有 canvas。

### Out-Of-Scope

- HTTP status validation：4xx／5xx 是成功取得的 raw response。
- 改變 `HTTPURL` validation、`HTTPRequest`、`HTTPResponse` raw contract 或 `HTTPClient → Requester → Transport` chain。
- 將 Apollo 強制通過 `RivetHTTPClient.Transport`。

### ReadOnly

- PR Inbox、PR Reader、其他 Bounded Context 與 GitHub API catalog。
- architecture canvas 的既有 rebuild、enhance 與 accessibility verification workflow。

### Written

- `HTTPClientError`、`URLSessionTransport`、其 fixture-based test suite，以及同 slug 的四份正式 artifacts。

### Modify

- `Transport`、`Requester`、`HTTPClient` 的 typed-throws signatures。
- transport test doubles、failure assertions 與 helper signatures。
- architecture README、GitHub Integration BC 文件、GitHub Integration／HTTP boundary canvas 與 HTTP client package structure canvas。

### Deleted

- 無。

### TestCase

- `HTTPClient → Requester → URLSessionTransport` 完整轉送 URL、method、headers、body。
- 2xx、4xx、5xx status、headers、body 都正確映射為 `HTTPResponse`。
- 非 HTTP response 映射為 `.nonHTTPResponse`。
- `URLError.cancelled` 與 `CancellationError` 映射為 `.cancelled(underlying:)`；其他 `URLError` 映射為 `.networkFailure` 並保留 code。
- 非預期底層 error 映射為 `.underlyingFailure` 並保留 underlying error。
- 所有測試只使用 injected ephemeral `URLSession` 與本地 `URLProtocol` fixture。

## Assumptions

- 本 topic 只有一個 production HTTP transport：`URLSessionTransport`。
- REST 與 Apollo 的雙 adapter 是未來 GitHub Integration topic 的架構決策，不是本次實作內容。
- 未來 GitHub Integration 必須在跨 Domain Port 前將 package error 映射為各自的 failure contract。
