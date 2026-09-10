# Typed HTTPHeaders API Correction

## Summary

將既有 `HTTPHeaders` 的裸 `String` header-name 設計收斂為 typed Swift API，並新增 request-local header 的 typed 寫入便利性。這是既有 topic 的 planning correction：不重開 mission、phase、驗收、workflow 或其他 boundary。

## Implementation Changes

- 將 `HTTPHeaderName` 改為具 canonical lower-case `rawValue` 的 typed `struct: Hashable, Sendable`；九個標準 names 成為 typed static members，custom name 僅經 `.custom(String)` 建立。
- 將 `HTTPHeaders` dictionary literal key 改為 `HTTPHeaderName`；新增 typed read/write subscript 與 typed lookup。subscript 設為 `nil` 即移除 canonical header。
- 保留 `value(for: String)` 為 read-only compatibility lookup，新增／優先使用 typed lookup；不提供 String-keyed writable subscript。
- 保留 `HTTPHeaders.init(_ values: [String: String] = [:])` 作為 transport／dynamic String header input 的 read-only canonicalization boundary；它維持 lower-case canonicalization，不形成 String-keyed writable subscript 或 String-keyed dictionary-literal compatibility。
- 保留九個標準 `String?` property conveniences，並讓 setter 委派 typed subscript。`values` 對外維持唯讀，僅調整內部可變性以支援 value-type mutation。
- 更新所有受 dictionary-literal key 變更影響的既有 header test files，並最小更新 architecture README 的 header convenience 描述；不變更任何 architecture 或 BC boundary。

### Swift Implementation Handoff

#### Goal

提供 typed header names、typed dictionary literal 與 request-local `HTTPHeaders` mutation，且不改變 HTTP execution chain。

#### Non-Goal

不新增 `HTTPClient` default／shared headers、transport、Requester、URL composition、response policy、multi-value headers、builder、dynamic-member lookup 或 String-keyed writable subscript。

#### In-Scope

- `HTTPHeaderName` typed value、九個標準 typed static members及 `.custom(String)`。
- `HTTPHeaders` typed dictionary literal、typed lookup、typed read/write subscript、標準 property setter 與 `nil` removal。
- `HTTPHeaders.init(_ values: [String: String] = [:])` 對 dynamic String input 的既有 lower-case canonicalization boundary。
- String read-only compatibility lookup、所有已知受影響既有 header test files 與 architecture README 的事實性描述更正。

#### Out-Of-Scope

- header validation、trim、wire-format policy、`Set-Cookie`／multi-value model、JSON、retry、status validation 或 error-policy changes。
- `HTTPClient` state、`Requester`、`Transport`、`HTTPURL`、`HTTPRequest`、`HTTPResponse`、package manifest、BC 文件與 architecture diagrams。
- Git、PR、release 或任何 workflow automation。

#### ReadOnly

- 除下列 Modify targets 外的所有 product source、test files、package manifest、BC 文件與 architecture diagrams。
- `HTTPClient → Requester → Transport` execution、URL、request 與 response contracts。

#### Modify

- `Packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaderName.swift`：typed header-name value、標準 members及 custom factory。
- `Packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`：typed literal／lookup／subscript、標準 property setters與必要 internal mutability。
- `Packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`、`Execution/RequesterTests.swift`、`Execution/TestDoubles.swift`：修正 dictionary-literal key 型別變更所影響的既有 header setup／test doubles。
- `Packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/HTTPRequestTests.swift`、`Response/HTTPResponseTests.swift`：修正 dictionary-literal key 型別變更，並涵蓋 typed API、dynamic String initializer 與既有 regression。
- `docs/architecture/README.md`：header convenience 的事實性 read-only description 更正。

#### Written

無新增 product、test surface、manifest、BC 或 diagram files；僅修改既有 Modify targets。

#### Deleted

無。不得刪除、搬移或更名任何檔案、API 或 test。

#### TestCase

- 在既有 `HTTPClientTests.swift`、`RequesterTests.swift`、`TestDoubles.swift`、`HTTPRequestTests.swift` 與 `HTTPResponseTests.swift` 修正所有受 dictionary-literal key 型別變更影響的 header setup／test double，且不新增 test file。
- `.accept`、`.contentType` 與其餘標準 member 可用於 typed dictionary literal，並產生 canonical keys。
- `.custom("X-Rivet-Trace")` 的大小寫變形共用同一 canonical key。
- typed subscript 與九個標準 properties 都可寫入、覆蓋、讀取及以 `nil` 移除，且不影響無關 header。
- `value(for: String)` 與 `value(for: HTTPHeaderName)` 都維持大小寫無關的 read-only lookup；沒有 String-keyed writable subscript。
- `HTTPHeaders.init(_ values: [String: String] = [:])` 對 dynamic String input 持續 lower-case canonicalize，且能和 typed lookup、typed subscript 與 property mutation 互通。
- 維持 duplicate later-wins、`values` 對外唯讀、request-local scope 與 value semantics。
- 執行 standalone `RivetHTTPClient` 的 build 與既有 test checks。

## Assumptions

- 九個標準 header names 沿用既有 contract：`accept`、`authorization`、`contentType`、`userAgent`、`etag`、`ifNoneMatch`、`location`、`link`、`retryAfter`。
- `HTTPHeaderName` 的 public surface 僅為 typed static members、`.custom(String)` 與 canonical `rawValue`；不引入 String-literal conversion。
- 實作只可在獨立 feature worktree 進行，並以獨立 Reviewer 的明示 approval 與後續 human delivery authority 為前提。
