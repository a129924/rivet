# Swift HTTPClient AuthFlow Send Runtime：需求

## Goal

讓 `RivetHTTPClient.HTTPClient` 在 caller 明確提供 `any Auth` 時，以 HTTPX 式通用 driver 執行既有 `AuthFlow`：發送 `.send(HTTPRequest)`、將 raw `HTTPResponse` 精確回灌一次，並在 `.finish` 回傳最後成功 response。此 topic 明確取代前一 topic「HTTPClient 不驅動或解讀 AuthFlow」的歷史 runtime 決策；仍不引入 GitHub 認知或認證 policy。

## Decision Source

2026-09-12 human locked contract：auth 僅由新 overload opt-in，`AuthFlow` 仍擁有 action／認證決策；`HTTPClient` 只做 generic action dispatch。已鎖定 contract 不得重開。

## In-Scope

- 保留原有 `execute(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse` 完全不變，新增 `execute(_ request: HTTPRequest, auth: any Auth) async throws(HTTPClientError) -> HTTPResponse`。
- auth overload 只呼叫一次 `auth.makeFlow(for:)` 與一次 `start()`；重複處理 `.send(request) → Requester.execute → flow.receive(response)`，直到 `.finish`。
- 每個成功 response 先保留為最後 response，再精確呼叫一次 `receive(_:)`；最後 `.finish` 回傳該 response。
- 若 `start()` 直接產出 `.finish`，拋出 `HTTPClientError.authFlowFinishedWithoutResponse`，不執行 transport 或 `receive(_:)`。
- transport 丟出的既有 `HTTPClientError` 原樣、立即傳遞；不回灌、不取下一 action、不 retry。所有 HTTP status 仍是 raw `HTTPResponse`，交由 flow。
- 最小 long-term writeback：architecture overview、BC directory README、既有 AuthFlow lifecycle artifact 與 HTTP client package-structure canvas；後者包含既有 generated-viewer/accessibility delivery support 的 narrow initial-fit 修正。

## Out-Of-Scope

- `Auth`、`AuthFlow`、`ClientAction` 的 signature、case 或 ownership 變更。
- credential、token、OAuth、GitHub behavior、static header auth、status／Content-Type policy、retry／backoff、flow cap、URL／endpoint 組裝或另一個 driver。
- `Requester`、`Transport`、`URLSessionTransport`、`HTTPRequest`、`HTTPResponse`、package manifest、`request(...)` 或 verb facades 的變更。
- GitHubIntegration、其他 BC、bounded-context map、舊 topic 的 `analysis/`／`plan/` artifacts。
- 除指定 initial-fit 行為外的 Canvas viewer interaction、share format、pan／zoom semantics 或 accessibility redesign。

## Non-Goal

不提供任何 concrete authentication behavior 或 policy；本 topic 不將 `AuthFlow` 擴張為 credential lifecycle、retry runtime、GitHub integration 或 endpoint abstraction。

## Written

- `analysis/swift-http-client-auth-flow-send-runtime/requirements.md`
- `analysis/swift-http-client-auth-flow-send-runtime/technical-spec.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.plan.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.step.md`
- Swift implementation 不新增 Swift source／test file；diagram delivery 僅重寫既有 generated HTML 與 visual-check evidence。
- `BUILD.md` 與 `enhance-accessibility.js` 是既有 delivery support，僅允許下列已存在檔案修改；不新增 viewer 或 accessibility artifact。
- implementation delivery 可寫入既有 `docs/architecture/diagrams/http-client-package-structure/BUILD.md` 與 `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`，僅為 locked initial-fit support。

## Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClientError.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`、`auth-flow-lifecycle.html`、`auth-flow-lifecycle.visual-check.*`
- `docs/architecture/diagrams/http-client-package-structure/scene.js`、`index.html`
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`
- `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`

## ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`
- `packages/RivetHTTPClient/Package.swift`、`packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/AuthTests.swift`、request／verb facade source
- `analysis/swift-http-client-auth-flow-contract/`、`plan/swift-http-client-auth-flow-contract/`、GitHubIntegration、其他 BC、bounded-context map。

## Deleted

無。不得刪除、搬移或更名任何既有 source、test、public API、topic artifact 或 diagram artifact。

## TestCase

| ID | Scenario | Expected result |
| --- | --- | --- |
| TC-01 | 無 auth 的 `execute(_:)` 與 facades | 原 direct dispatch、raw response、error behavior 不變；facades 無 auth overload。 |
| TC-02 | 單輪 flow：start `.send`、receive `.finish` | make-flow/start 各一次，request 已送出，response 僅 receive 一次並回傳。 |
| TC-03 | 多輪 flow | requests/responses 依 action 順序，回傳最後 successful response。 |
| TC-04 | start direct `.finish` | 拋 `.authFlowFinishedWithoutResponse`；零 transport、零 receive。 |
| TC-05 | 首輪／後續 transport failure | 同一 `HTTPClientError` 立即傳遞；無 receive、下一 action 或 retry。 |
| TC-06 | 4xx／5xx response | exact raw response 仍交給 flow，HTTPClient 不分類。 |
| TC-07 | Auth contract regression | `any AuthFlow` mutable transition conformance 維持。 |
| TC-08 | diagram delivery 與 Canvas initial-fit | Archify 9/9 clean validate、deliver、visual-check 與人工 screenshot review；Canvas validate/build/enhance/verify 與人工 screenshot review 均有 evidence。未互動且未帶 share hash 的 initial view resize 時重新 fit；有 share hash 或任何 pan／zoom 後，resize 保持既有 transform。 |

## Success Criteria

- 無 auth 的 HTTP execution 與 method facades 保持既有行為。
- auth overload 的 request／response ordering、single flow creation、single `start()`、response-once receive、multi-send completion 與 direct-finish typed error 均有可重現測試。
- architecture prose 與兩張圖如實表達 `HTTPClient` 已驅動 generic flow，且不新增認證或 GitHub policy。
- package tests、diff whitespace、Archify showcase delivery／人工 visual review，以及 Canvas validate／build／accessibility／人工 visual review 都由獨立 Tester 驗證；Canvas initial-fit test 必須驗證未互動 unshared resize refit 與 share hash／pan-zoom transform preservation。
