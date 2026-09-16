# Swift HTTP Client User-Facing Configuration：需求

## Goal

讓 `RivetHTTPClient` 的使用者可建立具通用預設值的 `HTTPClient`，以 Foundation `URL` 發送 absolute HTTP request，或在設定並驗證 `baseURL` 後以 relative `path` 發送 request，而無須每次自行建立 `HTTPURL`。呼叫結果仍是既有 raw `HTTPResponse`。

這是 `RivetHTTPClient` 的 generic、GitHub-unaware technical foundation convenience；不是新的 Bounded Context，也不引入 GitHub endpoint 或 domain policy。

## In-Scope

- `HTTPClient.Configuration`：optional `baseURL`、default headers、timeout；預設 timeout 為 60 秒，且只接受 finite 正數。relative-backed `baseURL` 必須先正規化為 `absoluteURL`，再驗證與儲存。
- `HTTPClient()` 與 `HTTPClient(configuration:)` 採 package-owned `URLSessionTransport`；保留既有 transport injection，並提供 configuration 與 injected transport 的組合入口。
- 既有 `HTTPURL` request／method facades 與 `execute(_:)` 繼續可用；configured client 的每個 entry 都套用 timeout 與 default headers。
- Foundation `URL` absolute request／method facades，以及 `path: String` relative request／method facades。
- absolute URL precedence、base URL subpath preservation、slash-boundary join、relative raw query preservation、case-insensitive default/request header merge。
- relative path 以 `//` 開頭（包含 `///`）時，必須在 transport 前以 `.relativePathIsNotRelative` 拒絕。
- transport 前的 URL/path/configuration validation，以及 validation failure 與既有 transport failure 的可區分性。
- 對 HTTP client architecture overview 與既有 package structure canvas 做最小長期事實回寫；canvas 的 `BUILD.md` 僅可調整 title、kicker、subtitle，使其與 configured `HTTPClient` scene 和 rebuilt `index.html` 一致，不改變任何其他 canvas workflow。

Validation failure 使用既有 `unsupportedScheme`、`missingHost`，以及已鎖定新增的 `invalidTimeout`、`missingBaseURL`、`baseURLHasQuery`、`baseURLHasFragment`、`baseURLHasDotSegment`、`relativePathIsNotRelative`、`relativePathHasFragment`、`relativePathHasDotSegment`、`malformedRelativePath`、`malformedRelativePathPercentEncoding`；不得以 aggregate case 取代這些可觀察分類。

## Out-of-Scope

- Endpoint、Path、Query builder；auth、OAuth、token refresh；retry、circuit breaker、cookie、cache、redirect 或 session delegate policy。
- GitHub host、API version、endpoint、DTO、pagination、GraphQL 或任一 Domain BC dependency。
- HTTP status、Content-Type、response decode validation／policy。
- 移除或改變既有 `HTTPURL`、`HTTPRequest`、`Requester`、`Transport` advanced contract；standalone `Requester` 不取得 client configuration 語意。
- 新增、刪除、搬移或更名 source、test、manifest、BC 文件或其他 topic artifacts；Git／PR／release 動作不屬本 artifact 建立工作。

## Success Criteria

- 零設定 client 可透過有效 absolute Foundation `URL` 發送 request。
- configured client 可對 relative path 合成正確 absolute HTTP URL，並保留 base URL 的 subpath。
- absolute URL 不受 base URL 改寫；相鄰 slash 合成穩定且 relative raw query 保留。
- default headers 套用，且同名（case-insensitive）per-request headers 優先。
- configured client 的 request execution 使用 configuration timeout。
- 缺少 base URL 的 relative path 與所有無效 URL/path/configuration 都在抵達 transport 前失敗；`HTTPURLValidationError` 與 `HTTPClientError` 可被呼叫端區分。
- raw response、HTTP status transparency、bare execution 與 transport-error passthrough regression 維持成立。
