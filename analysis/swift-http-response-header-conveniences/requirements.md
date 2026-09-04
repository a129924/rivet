# Swift HTTP Response and Header Conveniences：需求

## Goal

在既有 `RivetHTTPClient` internal transport foundation 補足日常 header 與 raw response body 的便利讀取方式。呼叫端可使用穩定的常見 header name 常數、以大小寫無關方式讀取任意 header，並依明確指定的 encoding 將 `HTTPResponse.body` 解為文字。

此 topic 不是新的 Bounded Context；package 仍是 GitHub Integration 可採用的內部 transport foundation，且不改變既有 `HTTPClient → Requester → Transport` chain。

## In Scope

- 新增 public `HTTPHeaderName` namespace，提供九個 lower-case `String` constants：`accept`、`authorization`、`contentType`、`userAgent`、`etag`、`ifNoneMatch`、`location`、`link`、`retryAfter`。
- 為 `HTTPHeaders` 新增 `value(for: String) -> String?` case-insensitive lookup，並持續接受任意自訂 header name；同時新增九個對應常見 header 的 read-only computed properties：`accept`、`authorization`、`contentType`、`userAgent`、`etag`、`ifNoneMatch`、`location`、`link`、`retryAfter`。
- 為 `HTTPResponse` 新增 `text(encoding: String.Encoding = .utf8) -> String?`，只依呼叫端指定的 encoding 解碼 raw `body`。
- 擴充既有 request/header 與 response test surface，驗證 constants、lookup 與文字解碼的成功／失敗行為。

## Out of Scope

- JSON、`Decodable`、`JSONDecoder`、`JSONSerialization` 或任何 decode policy。
- 依 `Content-Type` 自動推論 charset。
- status validation、retry、error mapping、多值 header／`Set-Cookie`。
- GitHub-specific header constants、URLSession 或任何 concrete transport。
- `HTTPClient`、`Requester`、`Transport`、package manifest、Bounded Context 文件或 architecture diagrams 的修改。

## Success Criteria

- `headers.value(for: "Content-Type")`、`headers.value(for: "content-type")` 與 `headers.value(for: HTTPHeaderName.contentType)` 均取得同一值。
- `headers.contentType`、`headers.authorization` 與其餘七個點語法 property 均可讀取對應 header，且不同大小寫輸入均回傳同一值。
- 非預定義 custom header 維持可讀取；既有 lower-case storage、duplicate later-wins 行為與 `values` public contract 不變。
- 九個點語法 property 都是只讀 computed property，統一委派 `value(for:)` 與 `HTTPHeaderName` 常數；不新增 setter、subscript setter、`mutating` API、builder API 或 dynamic-member lookup。
- `response.text()` 正確解碼 UTF-8 body；指定 encoding 時只依該 encoding 解碼。
- 無法依指定 encoding 解碼時回傳 `nil`，不新增 package error type。
- `HTTPResponse.body` 仍是 canonical raw `Data`，不因 headers 或 JSON 改變行為。
