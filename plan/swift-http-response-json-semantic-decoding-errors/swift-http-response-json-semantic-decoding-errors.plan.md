# Swift HTTP Response JSON Semantic Decoding Errors

## Summary

在 `HTTPResponse` 新增以 caller-supplied `JSONDecoder` 解碼 raw body 的 semantic opt-in API。它只將 decode failure 包裝為 `JSONSemanticDecodingError`；既有 raw-preserving `json(_:decoder:)` 不變。

## Implementation Changes

- 新增 `JSONSemanticDecodingError` source，集中由 internal initializer 分類 caught error 並保存 underlying error。
- 在 `HTTPResponse` 以最小 `do`／`catch` 加入 `jsonSemantic(_:decoder:)`；不接觸 HTTP metadata 或 execution chain。
- 在 response tests 實作 red-green coverage，驗證成功、decoder configuration、已知與未知 error mapping、underlying error retention、raw response metadata 與既有 `json` passthrough。
- 只回寫兩份指定 architecture 文件；不改動 diagrams。

## Swift Implementation Handoff

### Goal

提供 `jsonSemantic(_:decoder:) throws -> T` 與 public `JSONSemanticDecodingError`，讓 caller 取得有限 failure kind 與完整 underlying error。

### Non-Goal

- 不改變 `json(_:decoder:)`、decoder ownership、HTTP validation、raw response 或 execution chain。
- 不提供 default/shared decoder、error 文案、serialization、`Equatable`、`Sendable` 或其他 decode API。

### In-Scope

- 指定的 semantic API、error type、五個 fixed kind、internal initializer 與 response tests。
- 四份正式 topic artifacts，以及 architecture README 和 GitHub Integration BC 的最小事實回寫。

### Out-Of-Scope

- 既有 json decoding topic artifacts 與 locked contract。
- package manifest、HTTP client chain、transport behavior、status/header/content-type validation、other BC、architecture diagrams。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/` 與 `Package.swift`：只供 chain boundary 與 standalone verification。
- `analysis/swift-http-response-json-decoding/` 與 `plan/swift-http-response-json-decoding/`：既有 locked contract，只供 boundary verification。
- 未提交的其他 topic worktree 內容與所有 architecture diagrams。

### Written

- 本 topic 的四份 artifacts。
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/JSONSemanticDecodingError.swift`。

### Deleted

- 無；不得刪除、搬移或更名既有 API、source、test、artifact 或 diagram。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`：僅加入 `jsonSemantic(_:decoder:)`。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Response/HTTPResponseTests.swift`：新增本 topic tests。
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/github-integration.md`：最小長期事實回寫。

### TestCase

- semantic success 與 caller decoder configuration。
- `dataCorrupted`、`keyNotFound`、`typeMismatch`、`valueNotFound` 的 kind 和可辨識 underlying error。
- custom `Decodable` 的 non-`DecodingError` 映射 `.other` 並保留 custom underlying error。
- semantic helper 忽略 status、headers、`Content-Type`，且不改變 raw body、status、headers。
- 原始 `json(_:decoder:)` failure 仍直接為 `DecodingError`，不是 wrapper。
- standalone package build 和完整 test suite。

## Assumptions

- `JSONSemanticDecodingError` 的 internal initializer 接收 caught error 並在 type 內完成 mapping。
- 沒有 scope gap 時，完成驗證後以單一 topic commit 推送並建立以 `dev` 為 base 的 draft PR，交由 human review。
