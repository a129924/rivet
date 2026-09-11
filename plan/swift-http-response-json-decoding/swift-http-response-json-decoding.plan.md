# Swift HTTP Response JSON Decoding

## Summary

在 `HTTPResponse` 新增由呼叫端提供 `JSONDecoder` 的泛型 JSON decode convenience。此能力只解碼既有 raw `body`，不改變 HTTP execution chain，也不將 decoder configuration、response validation 或錯誤 policy 交由 `RivetHTTPClient` 擁有。

## Implementation Changes

- 在 `HTTPResponse` 新增 `json(_:decoder:) throws -> T`，以傳入的 `JSONDecoder` 對 raw `body` 解碼。
- 直接傳遞 decoder 原始錯誤；不新增 package error、optional API、預設 decoder、動態 JSON API、status validation 或 `Content-Type` validation。
- 新增 response contract tests，涵蓋 caller-supplied decoder configuration、raw error passthrough 與 status／header 對 decode 的非影響性。
- 最小更新 HTTP client architecture 文件與既有 HTTP client package-structure diagram，記錄 caller-owned decoder convenience 及 raw response boundary；已退役 GitHub Integration assets 不再是 writeback target，且不指定 replacement target；generated `index.html` 僅經 artifact-local workflow rebuild。

## Swift Implementation Handoff

### Goal

提供下列 public API，使呼叫端以自己的 `JSONDecoder` 將 `HTTPResponse.body` 解碼為指定型別：

```swift
public func json<T: Decodable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T
```

### Non-Goal

- 不讓 `RivetHTTPClient` 擁有 decoder configuration、status validation、`Content-Type` validation 或 response error mapping policy。
- 不建立 default／shared decoder、package decoding error、optional API、`JSONSerialization`、動態 JSON API、concrete transport、retry、token refresh、Endpoint 或 URL composition。

### In-Scope

- `HTTPResponse.json(_:decoder:)` 只以傳入 decoder 解碼既有 `body`，並保留原始 decoder／`DecodingError`。
- 有效 JSON、decoder configuration、error passthrough、忽略 HTTP status、忽略／缺少 `Content-Type` 與 raw response regression tests。
- HTTP client architecture 文件與既有 HTTP client package-structure diagram 的最小事實回寫，說明 caller-owned decoder convenience 不改變 raw response dataflow；已退役 GitHub Integration assets 不再作為 writeback target。

### Out-Of-Scope

- `HTTPClient`、`Requester`、`Transport`、request API、header storage、package manifest、GitHub adapter、Bounded Context Map 與既有 `swift-http-response-header-conveniences` topic。
- 本 topic 已排除的 validation、decode policy ownership、error mapping、concrete transport、networking 與 API domain capabilities。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`：既有 raw response execution boundary，僅供理解及驗證。
- `packages/RivetHTTPClient/Package.swift`：既有 package contract，僅供理解及 standalone package checks。
- `analysis/swift-http-response-header-conveniences/` 與 `plan/swift-http-response-header-conveniences/`：既有 locked topic，僅供理解及 boundary verification。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`：加入已鎖定的 `json(_:decoder:)`。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Response/HTTPResponseTests.swift`：加入本 topic 的 decode contract 與 regression tests。
- `docs/architecture/README.md`：最小回寫 package 提供 caller-owned decode convenience 的長期事實。
- `docs/architecture/diagrams/http-client-package-structure/scene.js`：最小回寫 HTTP response convenience 與既有 ownership boundary。已刪除的 `docs/architecture/bounded-contexts/github-integration.md` 與舊 GitHub Integration authorization boundary asset 已由 `github-integration-boundary-redefinition` topic supersede，不是 writeback target，且不指定 replacement target。

### Written

- `analysis/swift-http-response-json-decoding/requirements.md`、`analysis/swift-http-response-json-decoding/technical-spec.md`、`plan/swift-http-response-json-decoding/swift-http-response-json-decoding.plan.md`、`plan/swift-http-response-json-decoding/swift-http-response-json-decoding.step.md`。
- 僅當 package-structure `scene.js` 有變更時，依其 artifact-local workflow 產生並寫入 `index.html`；不得直接手改生成檔或發布 artifact.cafe。

### Deleted

- 無。不得刪除、搬移或更名既有 API、source、test、planning artifact 或 diagram artifact。

### TestCase

- 有效 JSON body 能解碼為指定 `Decodable` 型別。
- 傳入的 `JSONDecoder` configuration 確實生效。
- 無效或型別不相容 JSON 時，呼叫端接收原始 `DecodingError`。
- 非成功 HTTP status 仍可依有效 raw body 解碼。
- 非 JSON 或缺少 `Content-Type` 仍可依有效 raw body 解碼。
- 既有 `HTTPResponse` 的 raw `body`、`statusCode`、headers contract 持續通過；執行 standalone package checks 與 package-structure diagram 的 validate、build、enhance、accessibility verification。retired GitHub Integration asset 不要求 writeback 或 verification，且不改變本 topic 的 API/test scope。

## Test Plan

- 為每個 decode scenario 建立局部 `HTTPResponse` fixture，驗證成功值或原始 error identity。
- 保留既有 raw transport response values regression test，並以 package 原有驗證命令執行 standalone `RivetHTTPClient` checks。
- 當 package-structure diagram source 有變更，依其 `BUILD.md` 執行 validate、build、enhance 與 accessibility verification；確認 generated artifact 由 workflow 產生。retired GitHub Integration asset 不提供 replacement target。

## Assumptions

- `HTTPResponse.body` 是 canonical raw `Data`；`json(...)` 是同步、無快取、無副作用的 caller-invoked convenience。
- 呼叫端對 decoder 的 key、date、data 與其他 decoding strategies 負全部設定責任。
- 若實作需要修改 execution chain、manifest、既有 locked topic，或新增任何 validation／error policy，停止並回報 Scope Gap；不得自行擴張。
