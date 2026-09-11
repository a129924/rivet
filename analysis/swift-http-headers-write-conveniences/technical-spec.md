# Swift HTTP Headers Write Conveniences：技術規格

## Locked API Contract

`HTTPHeaderName` 由僅含裸 `String` static constants 的 namespace 改為 package-owned typed value：

```swift
public struct HTTPHeaderName: Hashable, Sendable {
  public let rawValue: String

  public static let accept: Self
  public static let authorization: Self
  public static let contentType: Self
  public static let userAgent: Self
  public static let etag: Self
  public static let ifNoneMatch: Self
  public static let location: Self
  public static let link: Self
  public static let retryAfter: Self

  public static func custom(_ name: String) -> Self
}
```

- 所有 `rawValue` 都是 canonical lower-case header name；標準 member 對應既有九個 wire names。
- custom name 必須透過 `.custom(String)`；不提供 String-literal conversion，也不保留裸 `String` static constants namespace。

`HTTPHeaders` 的 dictionary literal key 是 `HTTPHeaderName`，並提供下列 access surface：

```swift
public func value(for name: HTTPHeaderName) -> String?
public func value(for name: String) -> String?
public subscript(_ name: HTTPHeaderName) -> String? { get set }
```

- typed subscript 的 setter 指定 value 時寫入 canonical key；指定 `nil` 時移除 canonical key。
- 不提供 String-keyed writable subscript。`value(for: String)` 保持 read-only compatibility lookup；新 code 優先使用 typed overload。
- 九個既有 `String?` standard property conveniences 保留為 get/set computed properties；getter 使用 typed lookup，setter 委派 typed subscript，`nil` 具有相同移除語意。
- 保留 `HTTPHeaders.init(_ values: [String: String] = [:])`。它是 transport／dynamic String header input 的 read-only canonicalization boundary：仍將 input keys lower-case canonicalize，且不構成 String-keyed writable subscript 或 String-keyed dictionary-literal compatibility。

## Invariants and Boundaries

- `HTTPHeaders` 僅為 request-local value；不得新增 `HTTPClient` default 或 shared headers state。
- `HTTPHeaderName.custom(_:)`、typed static members、typed literal、typed lookup 與 typed subscript 均依既有 lower-case canonicalization 運作。
- 同一 canonical name 的 dictionary-literal entries 維持 later-wins；custom names 繼續受支援。
- `values` 繼續對外唯讀；只允許必要的內部 mutation，以保留 `HTTPHeaders` value semantics。
- 不變更 `HTTPClient → Requester → Transport`、transport、URL ownership、response policy、Requester、URL composition 或 response contracts。
- 唯一授權的文件 writeback 是 `docs/architecture/README.md`：將「read-only convenience」修正為與本 topic 實際 header read/write convenience 一致的敘述，且不延伸或重開 architecture／BC decision。

## Authorized Modify Targets

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaderName.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/RequesterTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/HTTPRequestTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Response/HTTPResponseTests.swift`
- `docs/architecture/README.md`

所有其他 product source、test files、manifest、BC 文件與 architecture diagrams 均為 read-only。不得新增 test surface；測試調整只可修改上述既有 files。

## Required Verification

- Test scope 限於既有 `HTTPClientTests.swift`、`RequesterTests.swift`、`TestDoubles.swift`、`HTTPRequestTests.swift` 與 `HTTPResponseTests.swift`；其 header dictionary-literal setup、test double 與 response/request regression 必須全部遷移至 typed key contract，不新增 test file。
- `.accept`、`.contentType` 與其餘七個標準 members 可作為 typed dictionary-literal keys，並儲存正確 canonical names。
- `.custom("X-Rivet-Trace")` 與大小寫變形的 custom input 共用 canonical key。
- typed subscript 可寫入、覆蓋、讀取及以 `nil` 移除；九個 property convenience 對應同樣行為。
- typed lookup 與 `value(for: String)` 都是大小寫無關的 read-only lookup；不存在 String-keyed writable subscript。
- `HTTPHeaders.init(_ values: [String: String] = [:])` 對 dynamic String input 維持 lower-case canonicalization，且其建立的 headers 可與 typed subscript、typed lookup 及 property mutation 互通。
- canonical `values`、duplicate later-wins、request-local scope 與 value semantics 的既有 regression 持續成立。
