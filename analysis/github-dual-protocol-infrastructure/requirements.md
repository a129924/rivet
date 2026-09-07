# GitHub Dual-Protocol Infrastructure：需求

## Goal

在既有 `RivetHTTPClient` package 實作唯一的 production HTTP transport：`URLSessionTransport`，並以 `HTTPClientError` 統一 package 對外的 transport failure。

## In Scope

- `URLSessionTransport` 實作既有 `Transport`，完整執行 `URLRequest`，並回傳 HTTP status、headers 與 raw body。
- `HTTPClientError`、typed throws propagation、transport test doubles 與回歸測試。
- 長期架構文件與既有 HTTP client canvas 的最小回寫。

## Out of Scope

- GitHub REST／GraphQL adapter、Apollo、GitHub DTO、token 或認證。
- status validation、decode、retry、快取、pagination、PR Domain、UI 與所有寫入操作。
- OAuth、PAT、Keychain、登入 UI 與 token refresh。

## Success Criteria

- 任何 package caller 僅會收到 `HTTPClientError`。
- HTTP response（包含 4xx／5xx）保留為 raw `HTTPResponse`，不轉為 transport error。
- `URLError`、non-HTTP response 與其他底層 error 均依鎖定 contract 映射且保留原始資訊。
- 測試不呼叫 GitHub.com 或其他外部網路。
