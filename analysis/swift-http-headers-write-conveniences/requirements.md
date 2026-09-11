# Swift HTTP Headers Write Conveniences：需求

## Goal

在既有 request-local `HTTPHeaders` 補上型別化的 header name 與可寫入便利 API。呼叫端可以標準 typed member、明確 custom factory、typed dictionary literal、typed subscript 或既有標準 property 設定單一 request 的 headers；指定 `nil` 移除對應 header。

此 topic 只修正 header-name API 的表達方式，不新增 `HTTPClient` default／shared headers state，也不改變既有 HTTP execution chain。

## In Scope

- `HTTPHeaderName` 為 package-owned typed value：`struct HTTPHeaderName: Hashable, Sendable`，對外提供 canonical lower-case 的唯讀 `rawValue`。
- 九個既有標準 headers 以 typed static members 表達：`accept`、`authorization`、`contentType`、`userAgent`、`etag`、`ifNoneMatch`、`location`、`link`、`retryAfter`。
- custom header 只透過顯式 typed factory `.custom(String)` 建立。
- `HTTPHeaders` dictionary literal 的 key 改為 `HTTPHeaderName`；duplicate canonical name 維持 later-wins。
- `HTTPHeaders` 提供 `HTTPHeaderName`-keyed read/write subscript；寫入 `nil` 時移除該 canonical header。
- 保留九個標準 `String?` property conveniences，並使其 setter 委派 typed subscript。
- 保留 `value(for: String) -> String?` 作為 read-only source-compatible lookup，新增並優先使用 `value(for: HTTPHeaderName) -> String?`。
- 保留 `HTTPHeaders.init(_ values: [String: String] = [:])` 作為 transport／dynamic String header input 的 read-only canonicalization boundary；它繼續 lower-case canonicalize，且不是 String-keyed writable subscript 或 String-keyed dictionary-literal compatibility。
- `values` 對外維持唯讀；只調整內部可變性以支援 `HTTPHeaders` 的 value-type mutation。
- 僅更新既有 header test files（`HTTPRequestTests`、`HTTPClientTests`、`RequesterTests`、`TestDoubles`、`HTTPResponseTests`），以及 `docs/architecture/README.md` 對 header convenience 的事實性描述。

## Out of Scope

- `HTTPClient` 的 default／shared headers state。
- transport、`Requester`、URL composition、response policy、request execution chain 或 package manifest。
- header validation、trim、wire-format policy、multi-value headers、`Set-Cookie`、builder、dynamic-member lookup，或 String-keyed writable subscript。
- Bounded Context 文件、architecture diagram 或任何 Bounded Context／architecture decision。

## Success Criteria

- 以下 typed dictionary literal 能編譯並儲存 canonical header names：

  ```swift
  let headers: HTTPHeaders = [
    .accept: "application/json",
    .contentType: "application/json",
  ]
  ```

- `.custom("X-Rivet-Trace")` 支援 custom header，並和大小寫不同但 canonical name 相同的輸入視為同一 header。
- typed subscript 與九個標準 properties 都可以寫入、覆蓋、讀取，並以 `nil` 移除。
- `value(for: String)` 繼續提供大小寫無關的 read-only lookup；typed lookup 提供相同 canonical semantics。
- dynamic String input 經既有 initializer 繼續 canonicalize，且能和後續 typed mutation 共用同一 header value。
- 維持 request-local scope、case-insensitive canonicalization、duplicate later-wins、`values` 對外唯讀與 `HTTPHeaders` value semantics。
