# Swift HTTPClient AuthFlow Send Runtime：技術規格

## Goal

以新的 `HTTPClient.execute(_:auth:)` 驅動 generic `AuthFlow` 的 `.send → raw response → receive` loop，直到 `.finish` 回傳最後成功 `HTTPResponse`；direct finish 則以 typed error 表達無 response 終態。

## Non-Goal

不變更 AuthFlow public contract，或新增 credential、token、OAuth、GitHub behavior、static header auth、status／Content-Type policy、retry／backoff、flow cap、URL／endpoint 組裝或另一個 driver。

## In-Scope

- 原 `execute(_:)` 保持不變，新增唯一 auth opt-in overload 與 `authFlowFinishedWithoutResponse` error case。
- flow 僅建立一次、`start()` 僅呼叫一次；每個 successful `.send` response 只回灌一次 `receive(_:)`。
- transport errors 原樣立即傳遞；所有 HTTP status 保持 raw response 並交由 flow。
- 修改 locked file boundary 中的 Swift、tests、architecture prose 與 lifecycle／package-structure diagrams，以及 package-structure existing generated-viewer/accessibility delivery support 的 narrow initial-fit fix。

## Out-Of-Scope

- `Auth`、`AuthFlow`、`ClientAction`、`Requester`、`Transport`、`URLSessionTransport`、`HTTPRequest`、`HTTPResponse`、manifest、request／verb facades 的修改。
- GitHubIntegration、其他 BC、bounded-context map 與 `swift-http-client-auth-flow-contract` 的 analysis／plan artifacts 修改。
- 除「unshared 未互動 initial view resize refit；share hash 或任何 pan／zoom preserve transform」外的 Canvas viewer interaction、share format、pan／zoom semantics 或 accessibility redesign。

## Locked Public API

既有 API 不變：

```swift
public func execute(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse
```

新增唯一 auth opt-in API：

```swift
public func execute(
  _ request: HTTPRequest,
  auth: any Auth
) async throws(HTTPClientError) -> HTTPResponse
```

`HTTPClientError` 新增無 associated value 的 case：

```swift
case authFlowFinishedWithoutResponse
```

`Auth`、`AuthFlow`、`ClientAction` 維持既有 public declaration，不新增 overload、case 或 default behavior。

## Driver Semantics

1. 建立一個 mutable existential flow：`auth.makeFlow(for: request)`；不可重建 flow。
2. 對該 flow 呼叫一次 `await start()`，取得第一個 action。
3. `.send(nextRequest)` 時，只由 `Requester.execute(nextRequest)` 發送；成功取得的 exact `HTTPResponse` 成為最後 response，然後只呼叫一次 `await flow.receive(response)` 以取得下一 action。
4. `.finish` 時，若已有最後 response，回傳它；若尚無 response（即 `start()` 直接 finish），丟出 `.authFlowFinishedWithoutResponse`。
5. `Requester.execute` throw 時立刻傳遞同一 `HTTPClientError`，不呼叫 `receive`、不產生下一 action、不 retry。

driver 不檢查 status、headers、body、action request 是否等於原 request，或 flow 的認證意圖；4xx／5xx 也依第 3 步當成 raw response 回灌。沒有 loop cap。

## Documentation and Diagram Contract

- `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/README.md` 將舊的 declarations-only／non-driver 描述改為：RivetHTTPClient 是 GitHub-unaware generic technical foundation，`HTTPClient` 在 auth overload 驅動 `AuthFlow`，而 flow 保有認證決策。
- `auth-flow-lifecycle.json`／generated HTML 將 lifecycle 改為 `makeFlow → start → .send → HTTPClient/Requester send → raw response → receive → .send | .finish`，並標示 direct `.finish` 是無 response 的 typed error，receive 後 `.finish` 回傳最後 response。圖不得表示 retry policy 或解析認證狀態。
- `http-client-package-structure/scene.js`／generated HTML 加入 `Auth`／`AuthFlow` 與 auth `execute` driver relationship；保留 `Requester → Transport`、raw HTTP status 與 GitHub-unaware boundary。
- `http-client-package-structure/BUILD.md` 與 `enhance-accessibility.js` 僅調整 existing delivery support：initial untouched、unshared view 在 resize refit；任何 share hash 或 pan／zoom 發生後，resize 保留既有 transform。不得改變其他 Canvas interaction、share format 或 accessibility behavior。

## File Contract

### Written（本 planning phase）

- `analysis/swift-http-client-auth-flow-send-runtime/requirements.md`
- `analysis/swift-http-client-auth-flow-send-runtime/technical-spec.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.plan.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.step.md`

### Modify（Swift implementation phase）

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClientError.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`（僅為 deterministic recording／sequence transport test support）
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.html`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.visual-check.*`
- `docs/architecture/diagrams/http-client-package-structure/scene.js`
- `docs/architecture/diagrams/http-client-package-structure/index.html`
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`
- `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`

### Written（Swift implementation phase）

- 無新增 Swift public type、test target、package target 或 runtime source file。
- Archify deliver 與 visual-check 會重寫上述既有 generated HTML／evidence；Canvas build／enhance 會重寫既有 `index.html`。不得新增其他 committed artifact。
- `BUILD.md` 與 `enhance-accessibility.js` 是既有 generated-viewer/accessibility delivery support；可在 narrow initial-fit contract 內修改，不新增 viewer 或 accessibility artifact。
- implementation delivery 可寫入既有 `docs/architecture/diagrams/http-client-package-structure/BUILD.md` 與 `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`，只承載 locked initial-fit support。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/URLSessionTransport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`
- `packages/RivetHTTPClient/Package.swift`、所有 request／verb facade source、`AuthTests.swift`
- `analysis/swift-http-client-auth-flow-contract/`、`plan/swift-http-client-auth-flow-contract/`、GitHubIntegration、其他 BC 與 bounded-context map。

### Deleted

無。不得刪除、搬移或更名 source、test、public API、既有 topic artifact 或 diagram artifact。

## Required Verification

- focused `HTTPClientTests` 與 complete SwiftPM tests；`git diff --check`。
- AuthFlow lifecycle 依 Archify 的 `validate lifecycle ... --quality showcase --json`（9/9 checks、0 errors、0 warnings）→ `deliver` → `visual-check --repo-root . --json`。人工檢視 exact delivered light/dark screenshots（1440×900、2048×1320），記錄 verdict 與 correction rounds；`visualReview: pending` 不可視為 acceptance。
- Canvas 依其 `BUILD.md`：validate → build 至 temporary raw output → accessibility enhance 至 `index.html` → accessibility verify；再以 browser screenshot 人工檢查 light/dark desktop 的可讀性、無 overlap／overflow，並在 ledger 記錄 verdict。驗證 initial untouched、unshared view 在 resize refit；驗證 share hash 或任何 pan／zoom 後 resize 保留 transform。不得發布 artifact.cafe。

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
