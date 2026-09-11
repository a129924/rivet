# Swift HTTP Response JSON Sendable Contract

## Summary

收緊 `HTTPResponse` 兩個 JSON decoded payload APIs 的 public generic constraint，讓 decoded payload 必須為 `Decodable & Sendable`。這是預期的 source-breaking contract 變更；除直接 decoded payload test fixtures 外，不變更任何既有行為或所有權邊界。

## Implementation Changes

- 將 `HTTPResponse.json(_:decoder:)` 更新為 `json<T: Decodable & Sendable>(_:decoder:) throws -> T`。
- 將 `HTTPResponse.jsonSemantic(_:decoder:)` 更新為 `jsonSemantic<T: Decodable & Sendable>(_:decoder:) throws -> T`。
- 僅為直接傳入兩個 JSON APIs 的 decoded payload test fixtures 補上 `Sendable` conformance。

## Swift Implementation Handoff

### Goal

讓 `HTTPResponse` 的 decoded JSON payload APIs 具有 `Sendable` contract。

### Non-Goal

- 不讓 `JSONSemanticDecodingError`、`underlyingError` 或其他 error payload 符合 `Sendable`。
- 不變更 raw response、HTTP execution chain、decoder ownership、HTTP metadata policy、manifest、architecture docs 或 diagrams。

### In-Scope

- `HTTPResponse.json` 與 `HTTPResponse.jsonSemantic` 的 `T: Decodable & Sendable` 泛型 constraints。
- 直接作為兩個 APIs decoded payload 的 test fixtures `Sendable` conformance。
- 本 topic 的四份 planning artifacts、topic-scoped commit、push、draft PR 與 human review handoff。

### Out-Of-Scope

- `JSONSemanticDecodingError`、underlying error、error payload 與 semantic decoding error behavior。
- `HTTPClient → Requester → Transport`、raw `HTTPResponse`、decoder instance ownership、HTTP status／headers／`Content-Type` validation policy。
- package manifest、architecture docs／diagrams、既有 locked topics，以及合併、release 或後續整合。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/` 與 `packages/RivetHTTPClient/Package.swift`：只供 boundary verification 與 standalone checks。
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/JSONSemanticDecodingError.swift`：error contract 不得變更。
- 既有 JSON decoding 與 semantic decoding topics、architecture docs 及 diagrams。

### Written

- `analysis/swift-http-response-json-sendable-contract/requirements.md`
- `analysis/swift-http-response-json-sendable-contract/technical-spec.md`
- `plan/swift-http-response-json-sendable-contract/swift-http-response-json-sendable-contract.plan.md`
- `plan/swift-http-response-json-sendable-contract/swift-http-response-json-sendable-contract.step.md`

### Deleted

- 無；不得刪除、搬移或更名既有 API、source、tests、artifacts 或 docs。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`：僅收緊兩個 JSON APIs 的泛型 constraints。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Response/HTTPResponseTests.swift`：僅讓直接 decoded payload fixtures 符合 `Sendable`。

### TestCase

- `json` success 與 configured decoder。
- `jsonSemantic` success 與 configured decoder。
- `json` raw `DecodingError` passthrough。
- `jsonSemantic` semantic error mapping 與 underlying error retention。
- metadata non-validation 與 raw response regression。
- `RivetHTTPClient` standalone `swift build` 與 `swift test`。

## Delivery and Human Boundary

- 僅在獨立 Plan-Reviewer 明示 `approved` 後開始實作。
- 僅在獨立 Tester 與 Reviewer 的驗證結果可前進、且實作沒有重大問題時，建立單一 topic-scoped commit、push feature branch，並開啟以 `dev` 為 base 的 draft PR。
- draft PR 建立後即進入 human review boundary；不得自動 merge、release、刪除 branch 或執行後續整合。

## Assumptions

- 呼叫端 payload 未符合 `Sendable` 時必須自行修正，以接受這項 source-breaking API contract。
- 若實作需要觸及 ReadOnly 或 Out-Of-Scope 範圍，停止並回報 human check；不得自行擴張。
