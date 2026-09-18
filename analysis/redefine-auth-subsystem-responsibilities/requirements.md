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
  interpreter。它只保有 caller 傳入的 original request，**不建構**該 request；任何
  selected／decorated representation、decoration API 與 refresh dispatch interface 尚未鎖定。
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
| `AuthRequester` | 否 | 是，負責轉交 flow | 是，唯一 owner | 否；只保有 caller original request，selected／decorated representation deferred | 否 | 否，委派給 `Requester` | 否 |
| `Requester` | 否 | 是，raw return | 僅接收待執行 instance，不擁有 | 否 | 否 | 是 | 否 |
| `TokenFetcher` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| `TokenProvider` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |

`N/A` 是明確結論：此 topic 不宣稱這兩個 type 已存在、擁有 runtime role，或應被
新增。未來若需要 refresh I/O component，必須以獨立 topic 鎖定它的名稱、依賴和
credential update contract。

## PR #37 Comment-Fix Contract

此 amendment 只收斂已採用的 Model C 文件／圖表表述，不重開 architecture decision。

- canonical responsibility document、requirements 與 technical spec 的 matrix 都必須將
  `AuthRequester` 的「Builds original request」記為「否」：它只保有 caller original
  request；selected／decorated representation 維持 deferred。不得因此新增 decoration
  API 或 runtime role。
- 只有具 refresh capability 且在該 state 下 eligible 的 `AuthFlow`，才可在第一次 401
  發出 semantic refresh decision；不具資格的 flow 可以 terminal。Model C 的 policy
  owner 不變。
- `Auth` factory 必須在每次 execution 的 initial semantic send 前建立一個
  per-execution `AuthFlow`，再由 `AuthRequester ↔ AuthFlow` 進行 semantic exchange；不得
  將 `AuthRequester` 畫成向預先存在的 flow 取得 instance。
- lifecycle、401 sequence 與 state 的 Archify source／generated evidence 必須共同表達：
  `AuthRequester ↔ AuthFlow` 的 semantic exchange 沒有 request payload；refresh 經
  deferred boundary 執行並把 result 傳回 flow；只有 refresh-success 才允許 retry；不得
  存在 receive→retry shortcut，ineligible 與 refresh failure 都 terminal。圖表所有說明性
  文案必須是繁體中文：以「request 資料」、「資格」、「延後確定」、「更新成功」分別說明
  payload、eligibility、deferred、refresh-success；只有 type、protocol、state 或檔名等
  identifier 可保留英文。

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
- 在新的獨立 Plan Review 核准後，對 PR #37 九個 comment thread 所涵蓋的 matrix、
  canonical document、lifecycle／401／state Archify artifacts 與其 evidence 做上述
  limited correction；不新增 runtime contract。
- 在 RV-03 `needs-rework` 後，限定修正 Auth factory 的 per-execution-flow lifecycle、
  圖表繁體中文說明文案與 PR #37 delivery wording；不變更 PR 狀態或 runtime contract。

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

PR #37 comment-fix 只可校正已由本 Phase 2 Written allowlist materialize 的 canonical
responsibility document 與新 diagram namespace 內 lifecycle／401／state 的 source、
generated output 和 artifact-local evidence；這不是新的 path allowance，也不授權新 API。

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
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`：**僅**固定 build
  kicker／subtitle 的作者參數，使現有 pipeline 可重現已交付的繁體中文 HTML；enhancement
  script 與其餘 build semantics 維持 ReadOnly。

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
7. 前述是已完成 DL-01 的 historical delivery gate。PR #37 目前是 **OPEN、ready for
   review** 的既有 PR；這是 human 已執行的 delivery decision，planning artifact 不得改變
   PR status。RV-03 `needs-rework` 後，PC-07／PR-07／IM-04／TE-05／RV-04 必須完成，
   Implementer 才可由 DL-03 作 topic commit／push 到該既有 ready-for-review PR；不得開新
   PR、merge、release 或開始 Swift implementation。
8. DL-03 commit／push 後，Implementer 才可由 CH-02 依已提供 evidence 回覆並 resolve T06；T01、T02、
   T03、T05、T07、T08、T09 只在對應 corrected delivery 已可見時 resolve；T04 只在
   reproducibility fix 已可見時 resolve。此刻不得 resolve 任一 thread。
9. CH-02 thread handling 完成後，HC-02 交還 human review 既有 ready-for-review PR；不得
   自行 merge、release 或開始 future Swift implementation。

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
- **TC-08 — Comment-fix matrix**：三份 planning matrix 與 canonical document 都將
  `AuthRequester` 的 original-request construction 記為「否」，且未引入 decoration API
  或新的 runtime role。
- **TC-09 — Eligible refresh topology**：lifecycle、401、state source/output/evidence
  共同證明 `Auth` factory 在 semantic exchange 前建立 per-execution flow、無
  request-payload semantic exchange、refresh result 回 flow、
  只有 refresh-success retry，以及 ineligible／refresh-failure terminal。
- **TC-10 — Reproducibility**：package canvas 既有 pipeline 以 `BUILD.md` 的固定
  kicker／subtitle 作者參數重現已交付繁體中文 HTML，且 enhancement script/build semantics
  沒有超出該作者參數的改動。
- **TC-11 — Diagram language**：lifecycle、401、state 的所有說明性文案均為繁體中文；
  「request 資料」、「資格」、「延後確定」、「更新成功」分別取代 payload、eligibility、
  deferred、refresh-success 的解釋，僅 identifier 可保留英文。
- **TC-12 — Existing PR boundary**：PR #37 維持 OPEN、ready for review；PC-07 至 CH-02
  不得改變其 status，僅在 DL-03 後依可見 corrected delivery 回覆／resolve，最後交 HC-02。
