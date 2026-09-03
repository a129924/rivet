# HTTP Client interface：需求

## Goal

在既有 `RivetHTTPClient` package 建立可測試的最小 HTTP interface vertical slice：

`HTTPURL → HTTPRequest → HTTPClient → Requester → injected Transport → HTTPResponse`

本 topic 的成果是可由 future GitHub Integration Adapter 採用的 interface contract，不是 HTTP transport 底層。

## In-Scope

- `HTTPURL` public value object，包裝 `Foundation.URL` 並只接受有 host 的 http／https URL。
- `HTTPURLValidationError` typed validation error：`unsupportedScheme(String?)`、`missingHost`。
- `HTTPRequest`、`HTTPMethod`、`HTTPHeaders`、raw `HTTPResponse`。
- `HTTPClient`、`Requester`、injected `Transport` 與 Foundation `URLRequest` mapping。
- package product／source target／test target 與 Swift Testing。
- 將 architecture docs 與既有 HTTP Client canvas 回寫為此 interface 的長期真相。

## Out-Of-Scope

- Endpoint、Base URL、Path、Query 或 URL composition API。
- `URLSessionTransport`、真實網路呼叫、status code validation、retry、token refresh、decode policy。
- 統一 `HTTPClientError`，或對 Transport error 的 wrapping／mapping。
- Root `Package.swift` dependency、GitHub Adapter 實作與其他 Bounded Context 的變更。

## Success Criteria

- `HTTPURL` 接受 http／https URL，並以 typed error 拒絕不支援的 scheme 或缺少 host。
- Requester 正確映射 URL、method、headers、body 到 `URLRequest`。
- fake Transport 可證明完整呼叫鏈、raw response 與未包裝的 Transport error。
- 本 topic 的分析、規格、計畫與 ledger 可獨立說明本次工作，不需查閱 baseline topic 才能理解。
