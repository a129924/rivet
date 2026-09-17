# Auth 子系統責任重定義：需求

## Goal

將 `RivetHTTPClient` 的 authentication subsystem 從目前的 legacy Model A
capability，收斂為已採用、尚未實作的 Model C architecture contract：
`AuthFlow` 只擁有 authentication policy/state transition；`AuthRequester`
獨占 caller 的 original request 並解讀 semantic action；`Requester` 維持
generic `HTTPRequest → HTTPResponse` I/O boundary。

本 topic 是 **documentation-and-diagram architecture topic**。它建立未來
concrete-consumer implementation 所需的責任邊界，並不修改 Swift runtime、
public API 或測試。

## Current Responsibility Analysis

現行 contract 是 legacy Model A：

```swift
public enum ClientAction: Sendable {
  case send(HTTPRequest)
  case finish
}

public protocol Auth: Sendable {
  func makeFlow(for request: HTTPRequest) -> any AuthFlow
}

public protocol AuthFlow: Sendable {
  mutating func start() async -> ClientAction
  mutating func receive(_ response: HTTPResponse) async -> ClientAction
}
```

現行 internal `AuthRequester` 以 caller request 建立 flow，持續執行
`.send(HTTPRequest) → Requester.execute → receive(response)`，直到 `.finish`。
因此型別 contract 允許 flow：讀取 original request、建立任何 URL／method／body
的 request，或要求多次不相關 request。現有實作並未聲稱這些行為是 product
policy，但 capability 已由 `.send(HTTPRequest)` 授予。

`Requester` 目前只將 `HTTPRequest` 轉為 transport I/O 並回傳 raw
`HTTPResponse`；它不認識 auth policy、retry 或 credential lifecycle。現行 Swift
source 沒有 `TokenFetcher` 或 `TokenProvider` runtime contract；本 topic 不可將其
推定為既有元件。

## Adopted Architecture Decision

採用 **Model C — semantic action**。

- `Auth` 是 authentication strategy／independent-flow provider；不持有每次
  execution 的 auth state、original request 或 I/O。其 exact Swift factory
  signature 留待 future concrete-consumer topic。
- `AuthFlow` 是 authentication policy/state machine。它可理解 raw
  `HTTPResponse` 的 authentication semantics（包括 401），擁有 refresh／retry
  是否可進行、可進行幾次與 terminal decision；它不取得 original request、不建構
  original 或 refresh request，也不執行 I/O。
- `AuthRequester` 是 original request 的唯一 owner 與 semantic-action
  interpreter。它把已保留 caller intent 的 request 交給 `Requester`；任何
  decoration representation 及 refresh dispatch interface 尚未鎖定。
- `Requester` 仍是唯一 generic HTTP I/O component，不取得 auth state 或 retry
  policy。

此決定只鎖定責任及 capability boundary；它不預先定義 `AuthAction` case、
header overlay、credential refresher、event type、failure surface 或 async
signature。

## Responsibility Matrix

下表描述 adopted target，而非現行 Swift API。

| Role | Owns auth state | Knows HTTPResponse | Knows original request | Builds original request | Builds refresh request | Performs I/O | Controls retry |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Auth` | 否 | 否 | 否 | 否 | 否 | 否 | 否 |
| `AuthFlow` | 是 | 是，作為 policy input | 否 | 否 | 否 | 否 | 是 |
| `AuthRequester` | 否 | 是，負責轉交 flow | 是，唯一 owner | 是，只保留 caller intent；decoration shape deferred | 否 | 否，委派給 `Requester` | 否 |
| `Requester` | 否 | 是，raw return | 僅接收待執行 instance，不擁有 | 否 | 否 | 是 | 否 |
| `TokenFetcher` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| `TokenProvider` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |

`N/A` 是明確結論：此 topic 不宣稱這兩個 type 已存在、擁有 runtime role，或應被
新增。未來若需要 refresh I/O component，必須以獨立 topic 鎖定它的名稱、依賴和
credential update contract。

## Model Comparison

| Model | Flow capability | 優點 | 代價／決定 |
| --- | --- | --- | --- |
| A — HTTPX-style | `.send(HTTPRequest)`；可任意建構／多送 HTTP request | 彈性高，challenge-response 易表達 | 這是現行 legacy capability；original request、refresh request 與 I/O ownership 容易重疊，未採用為 target。 |
| B — restricted HTTP action | flow 對 original request 發出受限 header／refresh instruction | 可限制 endpoint 改寫 | 仍需先決定 header overlay 與 refresh request builder owner；這些決定尚未被需求支持，故未採用。 |
| C — semantic action | flow 僅決定 send／refresh／finish 等語意結果 | type boundary 直接反映 policy/mechanism 分離，單一 retry owner，易獨立測試 | exact action、decoration、refresh result delivery 與 failure API 必須由 future topic 決定；採用。 |

## In-Scope

- 建立本 topic 的四份 formal planning artifacts，記錄 legacy／target distinction、
  matrix、Model A/B/C 比較、adopted decision、gate 與 human boundary。
- 在 independent Plan Review `approved` 後，回寫長期 architecture document，並更新
  architecture overview、BC directory index、既有 AuthFlow lifecycle artifact 與
  HTTP client package canvas 的 target／legacy wording。
- 在新 diagram namespace 交付繁體中文的 responsibility/dependency canvas、normal
  request sequence、401 refresh/retry boundary sequence、AuthFlow state diagram。

## Out-Of-Scope

- 任何 Swift source、test、package manifest、public API、runtime behavior 或 API
  migration。
- `AuthAction` exact cases、header／decoration representation、failure surface、
  async signature、credential persistence、refresh endpoint、refresh I/O type 或
  event/result shape。
- generic HTTP retry、5xx／network retry、backoff、rate limit、circuit breaker、
  concurrent 401 single-flight、OAuth implementation、GitHub client behavior。
- 改寫 OAuth dual-client lifecycle architecture 或其 diagrams。

## Path Contract

### Written

Phase 1 只建立：

- `analysis/redefine-auth-subsystem-responsibilities/requirements.md`
- `analysis/redefine-auth-subsystem-responsibilities/technical-spec.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md`

Phase 2 僅在 independent Plan Review 明示 `approved` 後建立：

- `docs/architecture/rivet-http-client-auth-responsibilities.md`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/` 內的新 canvas、
  Archify source／generated artifacts 與 validation evidence。

### Modify

Phase 1 無既有檔修改。

Phase 2 僅可修改下列 long-lived paths，且只可將現行 Model A 如實標為 legacy、將
adopted Model C 如實標為尚未實作 target：

- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.html`
- 該 lifecycle 的 artifact-local validation／visual-check evidence
- `docs/architecture/diagrams/http-client-package-structure/scene.js`
- `docs/architecture/diagrams/http-client-package-structure/index.html`
- 該 canvas 的 artifact-local validation／visual evidence

### ReadOnly

所有 Swift source、Swift tests、package manifests、OAuth dual-client lifecycle 文件與
diagram、existing topic artifacts，以及任何不在上述 allowlist 的 repository path。

### Deleted

無刪除、搬移或更名授權。

## Acceptance Criteria

1. 四份 artifacts 使用同一 slug，並一致記錄 Model C 是 adopted target、現行
   `.send(HTTPRequest)` 是 legacy Model A。
2. matrix 對每格給出明確答案，且不將 `TokenFetcher`／`TokenProvider` 誤記為現有
   runtime type。
3. long-lived docs 和 diagrams 只在 independent Plan Review `approved` 後寫入，且
   不聲稱 deferred Swift API 已被實作。
4. component diagram 明確標示 state owner、original request owner、I/O owner，且
   沒有 `AuthFlow → Requester`、`AuthFlow → original request` 或 arbitrary-request
   capability。
5. normal 與 401 diagrams 明確區分 decision owner、I/O owner 和 deferred refresh
   boundary；不虛構 endpoint、credential runtime 或 API。
6. 所有圖表作者內容使用繁體中文，依對應 skill 驗證，且不發布 artifact.cafe。

## Workflow and Delivery Contract

1. PR-03 是唯一 final replacement Plan Review；只有其 `approved` 才授權 IM-01。
2. TE-01 是 historical `needs-rework`，不可作為 delivery gate。TE-02 是其唯一
   independent replacement verification gate：它必須驗證 allowlist、`git diff --check`、
   legacy/target truth、OAuth isolation 與 diagram evidence，並明示 `approved`；此
   `approved` 等價於本 topic 的 verification pass。
3. TE-03 是 IM-02 diagram-localization correction 的 independent re-test；它必須
   明示 `approved`，且不取代 TE-02 的 TE-01 replacement verification truth。
4. AuthFlow state diagram 的 human accepted desktop containment limitation 維持
   non-pass exception；TE-02 `approved` 不得將它重述為 visual-check pass。
5. RV-01 的 `needs-rework` 僅要求 verification/delivery gate wording correction。
   其 planning amendment 必須經 PR-04 independent Plan-Reviewer re-review `approved`
   後，才可進入 RV-02 independent Reviewer re-review。
6. 本 topic 的「無重大問題」只有在 **TE-02 = `approved`、TE-03 = `approved` 且
   RV-02 = `approved`** 時才成立；任何其他 status 或 verdict 均不得進入 delivery。
7. 上述條件成立後，DL-01 由 Implementer 依 topic delivery intent 與
   `git-commit-convention` 執行 topic commit、push、open **draft PR**。
8. draft PR 建立後進入 HC-01 human review。不得自行 merge、release 或處理 review
   comment；future Swift implementation 仍須另開 topic。

## TestCase

- **TC-01 — Phase 1 scope**：changed paths 僅為四份 listed planning artifacts。
- **TC-02 — Legacy truth**：文件與圖表不把現行 Model A 的 arbitrary-request
  capability 描述為 adopted Model C。
- **TC-03 — Matrix consistency**：`AuthFlow` 是唯一 auth state/retry policy owner；
  `AuthRequester` 是唯一 original request owner；`Requester` 是唯一 HTTP I/O owner。
- **TC-04 — Deferred boundary**：無文件聲稱已鎖定 action、decoration、failure、async
  或 refresh-component API；`TokenFetcher`／`TokenProvider` 維持 N/A。
- **TC-05 — Diagram semantics**：component、normal、401、state diagrams 的 owner 和
  legacy/target wording 彼此一致，401 圖僅表達 boundary topology。
- **TC-06 — Diagram validation**：architecture-canvas 與 Archify 分別通過規定
  validate/build/deliver/visual evidence；Archify showcase validate 為 9/9 checks、0
  errors、0 warnings；exact delivered artifact 經人工 light/dark 檢視。
- **TC-07 — ReadOnly isolation**：無 Swift、package、OAuth dual-client lifecycle 或
  historical topic 變更。
