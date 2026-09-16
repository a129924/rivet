# Swift HTTP Client User-Facing Configuration：技術規格

## Locked Public Contract

`HTTPClient.Configuration` 是一般使用者的 configuration value：

```swift
public struct HTTPClient.Configuration: Equatable, Sendable {
  public let baseURL: URL?
  public let timeout: TimeInterval
  public let defaultHeaders: HTTPHeaders

  public init(
    baseURL: URL? = nil,
    timeout: TimeInterval = 60,
    defaultHeaders: HTTPHeaders = HTTPHeaders()
  ) throws(HTTPURLValidationError)
}
```

`HTTPClient` 具下列建構入口：

```swift
public init()
public init(configuration: Configuration)
public init(transport: any Transport)
public init(configuration: Configuration, transport: any Transport)
```

前兩者使用 package-owned `URLSessionTransport`。既有 `init(transport:)` 保留，且採 default configuration。最後一個入口是 advanced transport injection 與 configured client 的唯一組合入口。

既有 `execute(_:)` 與接受 `HTTPURL` 的 `request(method:url:headers:body:)`、`get`、`post`、`put`、`patch`、`delete` 保留原有 typed-throws `HTTPClientError` contract。新增對稱的 Foundation `URL` 與 relative `path: String` overload；每個新入口回傳 `HTTPResponse`、採一般 `async throws`，因其可拋出 validation failure 或未改寫的 `HTTPClientError`。

新 overload 的共同 parameters 為既有 `method`／`headers`／`body` contract：headers 預設空 `HTTPHeaders`，body 預設 `nil`。method facades 固定 `.get`、`.post`、`.put`、`.patch`、`.delete`；不新增 `HEAD`、`OPTIONS` 或 streaming API。

## Configuration、Headers 與 Execution

- timeout 必須 finite 且大於零；zero、負數、`NaN`、正／負 infinity 都拋 `.invalidTimeout`。
- `baseURL` 存在時，先正規化為其 `absoluteURL`，再通過既有 HTTP/HTTPS-with-host `HTTPURL` validation 與本 topic 的 base URL constraints，並儲存該 absolute URL。
- configured `HTTPClient` 的 `execute(_:)`、既有 `HTTPURL` facades、Foundation `URL` facades 與 relative path facades 都先將 configuration default headers 與 request headers 做大小寫無關 merge；request value 覆寫同名 default value。
- configured `HTTPClient` 的所有執行入口都把 configuration timeout 設為 outbound `URLRequest.timeoutInterval`。`Requester` 的既有 public standalone contract 不變；它只提供 `HTTPClient` 所需的非公開 timeout forwarding，不能取得 default headers 或 base URL policy。
- Foundation `URL` facade 先以既有 `HTTPURL` validation 建立 request URL，且永不與 configured `baseURL` 合成。
- `HTTPClientError` 持續代表 cancellation、transport/network/non-HTTP 與 underlying failure。新 validation 不得呼叫 transport，亦不得包裝、映射或混入 `HTTPClientError`。

`HTTPURLValidationError` 保留 `unsupportedScheme` 與 `missingHost`，並且只以以下 additive public cases 表達本 topic validation：`.invalidTimeout`、`.missingBaseURL`、`.baseURLHasQuery`、`.baseURLHasFragment`、`.baseURLHasDotSegment`、`.relativePathIsNotRelative`、`.relativePathHasFragment`、`.relativePathHasDotSegment`、`.malformedRelativePath`、`.malformedRelativePathPercentEncoding`。不得新增、使用或以 aggregate case 等效取代這些分類。因為這是 public non-frozen enum 的新增 cases，下游 exhaustive `switch` 是 source-breaking，必須在 release notes／review 中如實呈現；本 topic 不移除或改名任何既有 case。

## URL Validation and Composition

- absolute Foundation `URL` 遵循既有 `HTTPURL` contract；base URL restrictions 不套用到 absolute request URL。
- base URL 的 query、fragment、literal／decoded dot-segment 分別拋 `.baseURLHasQuery`、`.baseURLHasFragment`、`.baseURLHasDotSegment`；可有 path 與 trailing slash。base validation 僅基於 Foundation 可觀察的 canonical `percentEncodedPath` 和 URL components，不宣稱能回復或拒絕 Foundation `URL` 建構前已遺失的 malformed source spelling。
- relative input 可含 path 與 raw query；scheme、authority，或以 `//` 開頭（包含 `///`）者拋 `.relativePathIsNotRelative`，fragment 拋 `.relativePathHasFragment`，literal／percent-decoded dot-segment 拋 `.relativePathHasDotSegment`。結構不合格的 relative path 拋 `.malformedRelativePath`；malformed percent escape 拋 `.malformedRelativePathPercentEncoding`。raw `percentEncodedQuery` 原樣帶入合成 URL。
- 合成時保留 base URL subpath，只把 base 尾端與 path 開頭相鄰 slash 正規化為一個 slash。`%2F` 是 segment data，不是 path separator；dot-segment check 在各 raw segment decode 後執行。
- 未設定 base URL 的 relative entry 拋 `.missingBaseURL`。所有 base、absolute 或 relative validation failure 都必須在 fake transport capture 前發生。

## Architecture Writeback and Verification

- `RivetHTTPClient` 仍是 BC 外、GitHub-unaware 的 generic technical foundation。base URL/path 是 generic client convenience，非 Endpoint composition 或 GitHub policy。
- 長期文件僅更新 `docs/architecture/README.md` 與既有 HTTP client package structure canvas，記錄 configuration、absolute/relative request convenience 與既有 raw chain；不得更動 Bounded Context map 或 BC ownership files。
- canvas 可修改 `scene.js`，並依其 `BUILD.md` workflow 生成 `index.html`。`BUILD.md` 只可修改 title、kicker、subtitle，使其與 configured `HTTPClient` canvas scene 及 rebuilt `index.html` 一致；不得變動其他 workflow 內容、手改 generated artifact 或發布 artifact.cafe。
