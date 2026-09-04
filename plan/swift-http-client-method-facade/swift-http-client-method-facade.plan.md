# Swift HTTP Client Method Facade

## Summary

在 `RivetHTTPClient` 的既有 `HTTPClient` 加入常見 HTTP method facade 與一般 `request(...)` entry。facade 只負責將已驗證的輸入形成既有 `HTTPRequest`，再委派 `execute(_:)`；raw response、transport error、Requester responsibility 與 URL validation 邊界均不變。

## Implementation Changes

- 新增 `request(method:url:headers:body:)` 與 `get`、`post`、`put`、`patch`、`delete` public async APIs；所有入口回傳 `HTTPResponse`，維持一般 `throws`。
- `request(...)` 以任意 `HTTPMethod` 建立 `HTTPRequest`；各 verb 以對應固定 method 呼叫同一 contract。headers 預設空值、body 預設 `nil`。
- 所有 facade 統一委派 `execute(_:)`，不變更 Requester 可見性或實作、不重複 transport mapping，也不引入新的 error／validation／response policy。
- 加入 contract、chain、raw error passthrough 與 `execute(_:)` regression tests，使用 injected fake transport 驗證捕捉到的 method、URL、headers、body 與 raw response。
- 對現有 HTTP client architecture 文件與 package structure canvas 做最小回寫，表達 public facade 在既有 chain 前的角色；canvas 變更必須依 `architecture-canvas` workflow rebuild 與 validate，但不可發布 artifact.cafe。

## Swift Implementation Handoff

### Goal

在既有 `HTTPClient` 提供可由已驗證 `HTTPURL` 呼叫的 method facade，同時維持既有 `execute(_:)`、raw `HTTPResponse`、原始 transport error 與 `Requester → Transport` chain 的契約。

### Non-Goal

- 不建立或修改 URL composition、Endpoint、Base URL、Path、Query、concrete transport、session lifecycle、status validation、retry、decode policy、token refresh、unified error、`HEAD`、`OPTIONS` 或 streaming。
- 不修改 `Requester`、`Transport`、`HTTPURL`、`HTTPMethod`、`HTTPHeaders`、`HTTPRequest`、`HTTPResponse`、package manifest、GitHub adapter、Bounded Context Map 或任何其他 BC。

### In-Scope

- 在既有 `HTTPClient` 加入已鎖定的 `request(method:url:headers:body:)` 與 `get`、`post`、`put`、`patch`、`delete` public async APIs；全部僅經 `execute(_:)` 形成既有 chain。
- 擴充既有 `HTTPClient` tests，重述本 plan 的 contract、chain、raw response、error passthrough 與 regression 驗證。
- 最小回寫現有 HTTP client architecture 說明與 package structure canvas，僅記錄 facade 已存在及其對既有 chain 的委派關係。

### Out-Of-Scope

- `Requester` 可見性或責任、`Transport` contract、URL／Foundation mapping、任何 root manifest、GitHub Integration adapter、BC Map 與其他 Bounded Context 文件。
- 本 topic 已排除的 URL composition、concrete transport、session lifecycle、response policy、錯誤正規化、額外 HTTP methods 與 streaming 能力。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/URL/HTTPURL.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPMethod.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`：既有 contract 與 execution boundary，僅供理解及驗證，不是本 topic 寫入目標。
- `docs/architecture/bounded-contexts/github-integration.md`、`docs/architecture/diagrams/http-client-package-structure/BUILD.md`：既有 ownership 與 canvas workflow 依據，僅供理解及驗證，不是本 topic 寫入目標。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`：新增已鎖定的 facade API，且只建立 `HTTPRequest` 後委派 `execute(_:)`。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`：新增或調整本 topic 的 contract、chain、error 與 regression tests；可沿用既有 test doubles，不擴張其 contract。
- `docs/architecture/README.md`、`docs/architecture/diagrams/http-client-package-structure/scene.js`：最小 architecture writeback，僅記錄 public facade 與既有 chain 的關係。

### Written

- 僅當 package structure canvas 的 source 變更時，依既有 workflow 產生並寫入 `docs/architecture/diagrams/http-client-package-structure/index.html`；不得發布 artifact.cafe。
- 不新增其他 source、test、manifest、adapter、BC 或 canvas surface；若既有 test surface 無法涵蓋，先回報 Scope Gap，不自行建立額外 surface。

### Deleted

- 無。不得刪除、搬移或更名任何檔案、API、test 或 architecture artifact。

### TestCase

- 五個 verb 分別固定 `.get`、`.post`、`.put`、`.patch`、`.delete`，並保留 URL、headers、body。
- `request(...)` 可傳遞任意既有 `HTTPMethod`，且 method、URL、headers、body 與等價 `HTTPRequest` 經 `execute(_:)` 的語意一致。
- 各新入口皆抵達 injected fake transport、回傳同一 raw `HTTPResponse`，並保留 fake transport 原始 error 的型別與值。
- `execute(_:)` 的既有成功與 transport-error passthrough regression tests 持續通過。
- 執行適用的 standalone `RivetHTTPClient` package checks；若 canvas 變更，執行既定 architecture-canvas rebuild、validation 與 accessibility verification。

## Test Plan

- 五個 verb 各自形成正確固定 method，並保留 URL、headers、body。
- `request(...)` 接受任意 `HTTPMethod`，且與直接 `HTTPRequest` 加 `execute(_:)` 的 request semantics 等價。
- 每個新 entry 可抵達 fake transport、回傳相同 raw `HTTPResponse`，且 fake transport error 保留原始型別／值。
- 既有 `execute(_:)` 的成功與 transport error regression tests 持續通過。
- 執行 standalone `RivetHTTPClient` 的既有 Swift test／package checks；若 canvas 有變更，執行其既定 architecture-canvas rebuild、validation 與 accessibility verification。

## Assumptions

- `HTTPURL`、`HTTPHeaders`、`Data?`、`HTTPRequest`、`HTTPMethod`、`HTTPResponse` 與 injected `Transport` 的既有 public contract 已鎖定且可直接使用。
- 不修改 root manifest、GitHub adapter、Bounded Context Map，亦不擴張至 URL composition、concrete transport、session lifecycle、HEAD／OPTIONS／streaming、status validation、retry、decode、token refresh 或 unified errors。
- 若實作需要改變 `execute(_:)` public semantics、Requester visibility，或納入上述排除能力，停止並回報 Scope Gap，不得自行擴張。
