# Swift HTTP Response JSON Sendable Contract：需求

## Goal

讓 `RivetHTTPClient` 的 `HTTPResponse` decoded JSON payload APIs 明確要求 payload 符合 `Sendable`，使成功解碼所得值具備跨並行邊界傳遞的型別契約。

## In Scope

- 將 `HTTPResponse.json(_:decoder:)` 的泛型 payload 約束收緊為 `Decodable & Sendable`。
- 將 `HTTPResponse.jsonSemantic(_:decoder:)` 的泛型 payload 約束收緊為 `Decodable & Sendable`。
- 讓直接作為上述 APIs decoded payload 的 test fixtures 明確符合 `Sendable`。

## Out of Scope

- `JSONSemanticDecodingError`、其 `underlyingError`，以及任何 error payload 的 `Sendable` contract。
- raw `HTTPResponse`、`HTTPClient → Requester → Transport` execution chain、decoder ownership 與 HTTP metadata policy。
- package manifest、architecture docs 或 diagrams，以及既有 locked topics。

## Success Criteria

- 兩個 public JSON APIs 的 payload 型別都必須同時符合 `Decodable` 與 `Sendable`。
- 成功解碼、caller-provided decoder configuration、raw error passthrough、semantic error mapping 與 underlying error retention 維持既有行為。
- HTTP metadata 不參與 decode validation，且 raw response regression 維持通過。
- `RivetHTTPClient` standalone `swift build` 與 `swift test` 通過。
