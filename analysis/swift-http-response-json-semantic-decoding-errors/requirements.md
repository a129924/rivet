# Swift HTTP Response JSON Semantic Decoding Errors：需求

## Goal

在 `RivetHTTPClient` 的既有 raw `HTTPResponse` 上新增 opt-in JSON semantic decoding convenience。呼叫端顯式提供 `JSONDecoder` 與目標 `Decodable` 型別；API 只解碼既有 raw `body`，但將 decode failure 包裝為有限的 semantic kind，並保留完整原始 error。

## In Scope

- `HTTPResponse.jsonSemantic(_:decoder:)` 與 `JSONSemanticDecodingError`。
- `DecodingError` 的四個既有 case 對應同名 semantic kind；未知 decoding case 與非 decoding error 對應 `.other`。
- caller-owned decoder configuration、原始 underlying error、raw response regression 與 standalone package 驗證。
- 對 HTTP response decode convenience 的最小長期文件回寫。

## Out of Scope

- 既有 `swift-http-response-json-decoding` topic 的 locked contract；其 `json(_:decoder:)` 必須維持原始 decoder error passthrough。
- HTTP status、headers 或 `Content-Type` validation，以及 decoder 的 default、shared 或 library-owned configuration。
- `HTTPClient → Requester → Transport`、package manifest、raw response contract、其他 Bounded Context 與 architecture diagrams。
- error 文案、`DecodingError.Context`、coding path、target type、key、serialization、`Equatable` 或 `Sendable` contract。

## Success Criteria

- 呼叫端能以自己的 decoder 成功解碼 semantic JSON convenience。
- 已知 decoding failure 映射正確 kind，且 wrapper 的 `underlyingError` 保留原始可辨識 error。
- 非 decoding error 映射 `.other`。
- 原始 `json(_:decoder:)` 仍直接拋出原始 `DecodingError`。
- raw body、status 與 headers 以及 HTTP execution chain 維持不變。
