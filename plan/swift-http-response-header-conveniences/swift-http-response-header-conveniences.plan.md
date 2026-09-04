# Swift HTTP Response and Header Conveniences

## Summary

在既有 `RivetHTTPClient` 新增 common HTTP header name constants、case-insensitive header lookup 與 explicit-encoding response text convenience。這是 internal transport foundation 的局部便利性增強；維持 raw response、header storage 與 `HTTPClient → Requester → Transport` chain 的既有契約。

## Implementation Changes

- 新增 `Request/HTTPHeaderName.swift`，宣告僅含九個指定 lower-case `String` constants 的 public `HTTPHeaderName` enum namespace。
- 在 `Request/HTTPHeaders.swift` 新增 `value(for:)`，以現有 `lowercased()` canonicalization 查詢；並新增九個對應 `HTTPHeaderName` constants 的 read-only computed properties。它們只委派 `value(for:)`，不變更 immutable storage、`values`、custom header 或 duplicate later-wins 行為。
- 在 `Response/HTTPResponse.swift` 新增 `text(encoding:)`，僅將 raw `body` 依參數 encoding 轉成 `String?`；不依 header 推論 charset，失敗回傳 `nil`。
- 在現有 request/header tests 與 response tests 增加 API contract、大小寫無關／custom header lookup、指定 encoding、解碼失敗與既有 raw contract regression coverage。

### Swift Implementation Handoff

**Goal**

提供已鎖定的 header constants、lookup 與 raw response text convenience，且不擴張 response policy 或 transport responsibility。

**Non-Goal**

不納入 JSON 或 decoder policy、Content-Type charset inference、status validation、retry、error mapping、多值 header／`Set-Cookie`、GitHub-specific header、URLSession 或 concrete transport。

**In-Scope**

- `HTTPHeaderName` 的九個既定 lower-case `String` constants。
- `HTTPHeaders.value(for: String) -> String?` 的大小寫無關 custom-header lookup。
- `HTTPHeaders` 的九個 public read-only computed properties：`accept`、`authorization`、`contentType`、`userAgent`、`etag`、`ifNoneMatch`、`location`、`link`、`retryAfter`。每個 property 只以對應 `HTTPHeaderName` constant 委派 `value(for:)`。
- `HTTPResponse.text(encoding: String.Encoding = .utf8) -> String?` 與對應既有 test surface 的 contract coverage。

**Out-Of-Scope**

- setter、subscript setter、`mutating` API、builder API 或 dynamic-member lookup。
- immutable header storage、duplicate later-wins 或 public `values` contract 的任何變更。
- `HTTPClient → Requester → Transport` chain、raw `Data` contract、charset inference、JSON／decode policy、status validation、retry、error mapping、多值 headers、GitHub-specific headers 或 concrete transport。

**ReadOnly**

- `Execution/HTTPClient.swift`、`Execution/Requester.swift`、`Execution/Transport.swift`、package manifest、GitHub Integration BC 文件與 architecture diagrams：僅供理解與 regression verification，禁止寫入。

**Modify**

- `Request/HTTPHeaders.swift`：新增既定 lookup API 與九個 read-only computed properties。
- `Response/HTTPResponse.swift`：新增既定 text API。
- 既有 request/header 與 response test surface：新增本 topic contract tests。

**Written**

僅新增 `Request/HTTPHeaderName.swift`；其餘 write target 僅限上述既有 source 與 test surface。不得新增其他 product、target、manifest、adapter、BC 或 diagram surface。

**Deleted**

無。不得刪除、搬移或更名既有檔案、API 或 tests。

## Test Plan

- TC-01：九個 `HTTPHeaderName` constants 對應精確的 lower-case header name。
- TC-02：九個 computed properties 各自讀取對應 header。
- TC-03：不同大小寫輸入的 header，均可由對應點語法 property 取得相同值。
- TC-04：任意 custom header 仍可經 `value(for:)` 以不同大小寫讀取。
- TC-05：點語法 getters 不改變 canonical `values`、duplicate later-wins 或 immutable behavior。
- TC-06：`text()` 解碼 UTF-8 raw body；顯式 encoding 解碼對應 body。
- TC-07：無法依指定 encoding 解碼的 bytes 回傳 `nil`；raw `body: Data`、status 與 headers 不被 convenience 改寫。
- 執行 standalone `RivetHTTPClient` 的既有 Swift build 與 test checks；任何超出三個 source target、既有 test surface 或本 plan exclusions 的需要，停止並回報 Scope Gap。

## Assumptions

- 已存在的 `HTTPHeaders` lower-case canonicalization 是本 topic 唯一 lookup normalization 規則。
- 九個點語法 properties 全數以對應 `HTTPHeaderName` constant 呼叫 `value(for:)`，不直接存取 storage。
- `String.Encoding` 為既定 Foundation API，可直接作為 `text(encoding:)` 的 public parameter；不需建立 package decode or error contract。
- 本 topic 不產生 architecture 長期 truth writeback，因 locked path 明確禁止修改 BC docs 與 diagrams。
