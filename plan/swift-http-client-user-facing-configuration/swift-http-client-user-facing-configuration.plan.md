# Swift HTTP Client User-Facing Configuration

## Summary

在 `RivetHTTPClient` 完成使用者導向的 configured client capability：使用者可藉 `HTTPClient.Configuration` 以 absolute Foundation `URL` 或 configured `baseURL` 下的 relative `path` 取得既有 raw `HTTPResponse`。此 topic 維持 generic、GitHub-unaware raw HTTP boundary，並保留 advanced transport injection、bare execution 及 transport error passthrough。

## Implementation Changes

- 在 `HTTPClient` 加入 validated `Configuration`、default `URLSessionTransport` constructors，以及 configuration + injected transport constructor；既有 `init(transport:)`、`execute(_:)`、`HTTPURL` request facades 保留。
- 新增 Foundation `URL` 與 `path: String` request／五個 HTTP method facades。absolute URL 不合成 base URL；relative path 只在已設定 base URL 下合成，並遵守已鎖定的 slash、subpath、query、percent encoding 與 dot-segment rules。
- 擴充 `HTTPURLValidationError` 的 additive public cases：`invalidTimeout`、`missingBaseURL`、`baseURLHasQuery`、`baseURLHasFragment`、`baseURLHasDotSegment`、`relativePathIsNotRelative`、`relativePathHasFragment`、`relativePathHasDotSegment`、`malformedRelativePath`、`malformedRelativePathPercentEncoding`；不使用 aggregate case。實作 finite positive timeout 與 base/relative validation，明確標示 exhaustive switches 的 source-breaking impact。validation failure 不得抵達 transport，transport failure 維持 `HTTPClientError`。
- 讓 configured client 的所有入口合併 default/request headers（case-insensitive、request precedence），並設定 outbound request timeout；standalone `Requester` 不變，只提供非公開 timeout forwarding。
- 補齊 capture-based contract and regression tests，並最小回寫 architecture overview 與 existing package canvas；`BUILD.md` 僅調整 title、kicker、subtitle，使其與 configured `HTTPClient` scene 和 rebuilt `index.html` 一致；generated canvas artifact 只由既定 workflow 產生，其他 workflow 不變。

## Swift Implementation Handoff

### Goal

提供設定式 `HTTPClient`，讓使用者以 validated base URL/default headers/timeout 執行 absolute URL 或 relative path raw HTTP request，而不需自行組裝 `HTTPURL`。

### Non-Goal

- 不提供 Endpoint、Path 或 Query builder、auth/retry/cache/cookie/redirect/session delegate policy、status/Content-Type/decode policy。
- 不引入 GitHub-specific host、endpoint、headers、DTO、pagination、GraphQL 或 Domain BC dependency。
- 不改變 standalone `Requester`、`Transport` execution/error responsibility，亦不移除既有 `HTTPURL`、`HTTPRequest` 或 raw response API。

### In-Scope

- `HTTPClient.Configuration`、default transport constructors、configuration + injected transport constructor，以及 existing transport injection preservation。
- Foundation `URL` and `path: String` request/facades；configured `execute(_:)` 與 existing `HTTPURL` facades 的 default-header merge/timeout propagation。
- strict base URL／relative path validation、已鎖定十個 additive `HTTPURLValidationError` cases、deterministic composition、source-breaking enum impact documentation。
- 指定 source/tests 與最小 architecture writeback；適用的 standalone package、diff 與 canvas workflow verification。

### Out-of-Scope

- 任何上述 Non-Goal capability、root/package manifest、GitHubIntegration、Bounded Context documents、其他 topic artifacts、另建 source/test/diagram surface。
- Git commit、push、draft PR 與 human review 不屬本 feature scope；僅能在 Reviewer approval 後依獨立派遣與另行授權處理。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`、`URLSessionTransport.swift`、`AuthRequester.swift`、`HTTPClientError.swift`：既有 transport/auth/error boundary。
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`、`HTTPHeaders.swift`、`HTTPMethod.swift`、`HTTPHeaderName.swift`，以及 `Response/HTTPResponse.swift`：既有 raw request/header/response contract。
- Auth runtime/tests、`Packages/RivetHTTPClient/Package.swift`、root manifest、`GitHubIntegration`、`docs/architecture/bounded-contexts/`、其他 topic artifacts 與未列於 Modify 的 diagram tooling。

### Written

- 無。implementation 不得新增檔案；package canvas 的 generated `index.html` 是既有檔案的受限修改，且只可由既有 workflow 寫入。

### Deleted

- 無。不得刪除、搬移或更名檔案、public API、tests 或 architecture artifacts。

### Modify

- `Packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `Packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `Packages/RivetHTTPClient/Sources/RivetHTTPClient/URL/HTTPURL.swift`
- `Packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `Packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`
- `Packages/RivetHTTPClient/Tests/RivetHTTPClientTests/URL/HTTPURLTests.swift`
- `docs/architecture/README.md`
- `docs/architecture/diagrams/http-client-package-structure/scene.js`
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`：僅修正 title、kicker、subtitle，使其與 configured `HTTPClient` scene 與 rebuilt `index.html` 一致；不得改變其他 canvas workflow。
- `docs/architecture/diagrams/http-client-package-structure/index.html`

### TestCase

| ID | Scenario | Expected result |
| --- | --- | --- |
| TC-01 | Default configuration and transport boundary | injected capture verifies `init(transport:)` uses nil base URL, empty headers and 60-second timeout; `HTTPClient()` default `URLSessionTransport` is verified only at source/API boundary, with no live network request. |
| TC-02 | Configuration validation | zero, negative, `NaN`, positive/negative infinity timeout throw `.invalidTimeout`; invalid base URL restrictions throw validation errors. |
| TC-03 | Configured entry propagation | `execute(_:)`, existing `HTTPURL`, Foundation `URL` and path facades all use configuration timeout/default headers with injected capture. |
| TC-04 | Header merge | defaults persist; same-name request header in any casing replaces the default value. |
| TC-05 | Base composition | root/subpath with all leading/trailing slash boundaries preserve subpath and produce a deterministic URL. |
| TC-06 | Absolute precedence | absolute URL is sent unchanged despite a configured base URL. |
| TC-07 | Relative query and encoding | raw relative query is preserved; encoded slash remains segment data; malformed percent and literal/decoded dot-segments fail validation. |
| TC-08 | Validation before transport | generic invalid base `HTTPURL` maps to `unsupportedScheme`／`missingHost`; base query→`baseURLHasQuery`; base fragment→`baseURLHasFragment`; base literal/decoded dot-segment→`baseURLHasDotSegment`; missing base→`missingBaseURL`; relative scheme/authority→`relativePathIsNotRelative`; fragment→`relativePathHasFragment`; literal/decoded dot-segment→`relativePathHasDotSegment`; malformed relative structure→`malformedRelativePath`; malformed percent→`malformedRelativePathPercentEncoding`; every condition has zero fake transport calls. |
| TC-09 | Regression | raw response, all HTTP statuses, existing `HTTPURL` APIs, bare execution, standalone `Requester` behavior and `HTTPClientError` passthrough remain unchanged. |
| TC-10 | Repository checks | applicable standalone SwiftPM build/test, formatter/linter if configured, `git diff --check`, and canvas validate/build/enhance/accessibility verification pass. |

## Assumptions

- `HTTPURL`、`HTTPHeaders`、`HTTPRequest`、`HTTPResponse`、`HTTPClientError`、`Transport` 的既有 public contract 已鎖定；新增 interface 是 additive，除了 `HTTPURLValidationError` exhaustive-switch source impact。
- 60 秒是 client configuration default；沒有 configuration 的 injected transport client 亦使用它。
- 若實作需要修改 ReadOnly targets、擴張 error/URL policy、加入新檔案或改變 BC ownership，停止並回報 Scope Gap，不得自行擴張。
