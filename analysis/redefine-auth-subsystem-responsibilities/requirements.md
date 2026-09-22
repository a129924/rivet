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

### Current PR #37 Rework Amendment

目前 PR #37 的新 comment preflight 為 `needs-rework`。此 amendment 只處理四個必要
thread 的既有 contract 表述，不重開 Model C、OAuth ReadOnly、original request ownership，
也不提前決定 deferred 的 API 或 representation：

1. 401 sequence 必須先清楚畫出 `caller → AuthRequester` 的 original execution entry，
   再畫出 `AuthRequester → Auth` 要求 per-execution flow 與 `Auth → AuthRequester` 回傳
   flow；只有其後才可開始無 request payload 的 `AuthRequester ↔ AuthFlow` semantic
   exchange。這個 factory round-trip 不得把 original request 交給 `AuthFlow`。
2. state diagram 的 retry permission 是**進入**「等待 retry response」policy state 的 transition／event，
   而非獨立 lifecycle node；該 state 收到 retry response 後，才由 response policy 分支為 normal-success terminal
   或 second-401 terminal。不得存在 retry permission 直接到 success 或 second-401 的 shortcut。
3. HTTP client package component canvas 不得把 selected／decorated request preparation
   指派給 `AuthRequester`。它仍只保有 caller original request 並解讀 semantic decision；
   preparation 的 exact owner 與 representation 維持 deferred，且不得藉此新增 runtime role。
4. step ledger 必須如實保留 delivered head 的歷史：`RV-04 = approved`、`DL-03 = active`；
   新 comment preflight 本身為 `needs-rework`，不得把尚未完成的 delivery、push 或 thread
   resolution 寫成既成事實。

此四項只使用 planning aliases 追蹤，不取代 GitHub thread identifier；實際回覆／resolve
前必須由後續 comment-resolution step 重新取得當時仍未解決的 thread 狀態。

### Human-Authorized State Delivery-Recovery Redesign

human 明確授權只擴張 `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/`
`auth-flow-state.json` 的 **topology/layout presentation scope**，唯一目的為消除 Archify showcase
composition crossing diagnostic `[850,307]`，恢復 normal standard `validate`／`deliver` delivery。
PC-10／PR-10／IM-08 alternate-materialization route 與其 `unavailable`／`non-pass` evidence 是
historical failed recovery evidence，現由 PC-11 replacement route supersede；不得再將它當作當前
delivery path。PC-13 進一步 supersede IM-09 的 prior state-node formulation：這是 presentation
expression revision，不是 retry policy change，也不恢復 alternate HTML materialization path。

IM-11 可在 state diagram 內將 retry permission 表達為進入 waiting-for-retry-response 的
transition／event（不得畫成 distinct lifecycle node），並為此調整相連的 presentation states、labels、
areas 與 transitions；它只能保留、不能重開以下 locked semantics：

1. first 401 的 ineligible／non-refresh-capable flow terminal；
2. eligible flow request refresh，refresh outcome 回到 Flow policy；
3. 只有 refresh success 授予**恰好一次** retry；
4. 只有 refresh success 觸發的 retry permission transition／event 進入
   waiting-for-retry-response；該 waiting state 將 retry response 交給 response policy，再分支
   normal success 或 second-401 terminal；
5. 不得出現 receive→retry shortcut。

此 scope expansion 不改變 Model C、original-request ownership、deferred preparation owner／
representation、401/canvas contract、production API 或任何其他 diagram。兩次 focused repair、一次
independent overall-layout attempt、all-attempts-restored 與 IM-08 的 validate／deliver／render
failure均保留為歷史；新 topology/layout redesign 必須真正消除 `[850,307]`，不可把 crossing
重新標為 accepted non-pass。

state 必須恢復 normal standard Archify showcase validate 9/9、0 errors、0 warnings，並 successful
standard `deliver` 產生 source-matched HTML／receipt、visual evidence 與 exact-delivered manual
light/dark inspection。既有 desktop containment accepted non-pass 不變：1440×900 = 1035、
1600×1000／1920×1080 = 1109、2048×1320 pass；它仍不得稱 visual-check pass。401 sequence 仍必須
standard 9/9、normal `deliver`、visual pass；package canvas 仍必須 validate/build/reproducibility/
accessibility。沒有任何其他 gate、scope／ReadOnly、diff、PR delivery 或 thread-resolution truthfulness
被豁免。

PC-12 將 source change 與 output materialization 分離；PC-13 使 IM-11 成為唯一可改 state expression／
presentation 的 step。後續
獨立 IM-10 **不得修改任何 source**，只 materialize 已修改的 401 與 package source。此刻的實際
checksum observation 是 401 source `edf7864d859bede17f9572d1a24dff31452ce8a4f0ec80ec14874c818cc5c798`
與 existing HTML `f4e4d9f546a7f772127b008a7e64f7e01b47bc0d7fb3b142155992d4697c73ca`；package scene
`017bdfe15961912f24c6e479938fff17f6a85b6bc7069eeeaa9aefb2c336bc3f` 與 existing index
`ca7b3773ab24971f8f41172ad1489df29015b1a85f1abfb900115483f9aa03d2`。這些是各檔案的現況 hashes，
不是 source-matched proof；current artifacts 沒有可將這些 source/output pairs 關聯的 delivery
receipt。IM-10 必須建立新的 source-output consistency evidence，不得從 hash 值推論既有輸出有效。

### Human-Authorized 401 Visual-Pass Repair

IM-10 已如實證明 package materialization 完整通過（5 bands／15 boxes／22 edges、0 errors、0 warnings、
build→enhance→verify 與 byte-identical output），該 evidence 保留且不重做。其 401 source ReadOnly standard
delivery 雖為 showcase 9/9、0 errors、0 warnings、source-matched，fresh visual-check 卻在 1440×900
scrollHeight 1001、1600×1000 scrollHeight 1073 失敗；這不屬於 state desktop containment exception。

human 授權 PC-14／PR-14／IM-12 **僅**為 `401-refresh-retry` 圖表的 layout/source adjustment 恢復所有
desktop visual-check pass，而非新增 exception。此授權只 supersede IM-10 的 401 source-ReadOnly 限制，
不影響 package materialization 已通過 evidence，亦不放寬 `BUILD.md`、enhancement script、package、state、
Swift、OAuth、runtime API 或其他 diagram 的 ReadOnly／scope。

IM-12 必須完整保留 401 flow contract：`caller → AuthRequester` original execution entry，
`AuthRequester → Auth` per-execution flow request，`Auth → AuthRequester` flow return 在無 request-payload
semantic exchange 前完成；original request 不得暴露給 `AuthFlow`。它也必須保留 first-401
ineligible/non-refresh-capable terminal、eligible refresh、refresh result 回 Flow policy、refresh-success-only
exactly-one retry、waiting-for-retry-response → response-policy 的 normal-success／second-401 terminal 分流，
以及無 receive→retry shortcut。

IM-12 的交付要求為 standard Archify showcase validate 9/9、0 errors、0 warnings、standard `deliver`
source-matched receipt、所有 desktop viewport（含 1440×900、1600×1000、1920×1080、2048×1320）visual-check pass，
以及 exact-delivered manual light/dark inspection。route 固定為 PC-14 → PR-14 → IM-12 → TE-10 → RV-10 →
DL-08 → CH-07 → HC-07；TE-10 只驗證，不得生成 output/evidence。

### Human 授權的 401 參與者脈絡表述調整

human 選擇 IM-12 renderer geometry blocker 的 bounded scope change：參與者副標籤的表述必須從
參與者標頭移到圖外脈絡／說明區。這只 supersede IM-12 的「所有副標籤置於標頭」表述限制，
**不是** new visual exception，也不是 sequence contract、retry policy、component identity 或 ownership 的變更。

PC-15／PR-15／IM-13 必須保留全部 **17** sequence messages、caller → AuthRequester original-execution entry、
AuthRequester → Auth per-execution flow request、Auth → AuthRequester flow return 在 request-less exchange 前完成，
以及 Flow 不取得 original request。first-401 ineligible terminal、eligible refresh、refresh result 回 policy、
refresh-success-only exactly-one retry、waiting-for-retry-response → response-policy normal-success／second-401
terminal 分流與無 receive→retry shortcut 均不得改動；participant/component identities 也不得改名、合併或創造
new owner。

每個移出的副標籤必須在圖外脈絡／說明區以可對照的說明文字保留原本解釋意義；不得 invent ownership、
capability、runtime behavior 或 architecture decision。IM-13 只可改 `401-refresh-retry` 的參與者標頭／
圖外脈絡表述與 artifact-local delivery evidence，並仍須
standard showcase validate 9/9、0 errors、0 warnings、source-matched `deliver`、四個 desktop viewport full
visual pass、exact-delivered manual light/dark inspection。package passed evidence 維持，不得重做。

route：PC-15 → PR-15 → IM-13 → TE-11 → RV-11；TE-11 只驗證。RV-11 的
`needs-rework` 已取代原本未開始的 DL-09 → CH-08 → HC-08 downstream route；其既有契約內
回修直接交回 IM-15，不建立新的 planning cycle。

### RV-11 Canvas Ownership／Ledger Rework

RV-11 = `needs-rework` 僅確認兩項 bounded finding，不重開 Model C、original request ownership、
retry policy、401 sequence、state topology、participant-context presentation 或 deferred API。

1. component-dependency canvas 不得稱 selected／decorated request 由 `AuthRequester` 準備。
   `AuthRequester` 仍只保有 caller original request 並解讀 semantic action；selected／decorated
   representation 的準備者與 representation 均維持 deferred，不得因此新增 role、API、capability
   或 runtime behavior。
2. step ledger 必須把 RV-11 = `needs-rework` 列為 current rework truth；不得將 IM-14 receipt
   regeneration 或已被 replacement route supersede 的 DL-03 誤述為 current gate。

此為已鎖定 contract 內的最小回修，不建立新的 Plan-Creator／Plan-Reviewer cycle。TE-12 initial 已
`needs-rework`；**IM-15 rework 已完成**同一個 bounded canvas finding 的回修，且 **TE-12 re-test 已
`approved`**。TE-14 已 `approved`；目前 gate 為 **RV-14**。IM-15 的
實作範圍只可更新
`component-dependency/scene.js`、其 generated `index.html`、artifact-local validation／visual evidence
與 actual-step ledger evidence。`BUILD.md`、enhancement script、401、state、lifecycle、normal sequence、
canonical document、Swift、OAuth 與其他 path 均維持 ReadOnly。current route：
**TE-14（approved）→ RV-14（current）→ DL-12 → CH-11 → HC-11**。

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
- 在 current PR #37 comment preflight = `needs-rework` 後，依新的 independent Plan Review
  僅修正 401 sequence 的 factory prefix、AuthFlow state retry-response topology，以及 package
  canvas 對 selected／decorated preparation 的錯誤責任指派；不改變 deferred owner／representation
  的未決狀態。
- 記錄 human-authorized state delivery-recovery topology/layout redesign 與 PC-13 expression revision；它只可由
  PC-13／PR-13／IM-11 在 locked semantics 與 normal standard delivery gate 下修正 crossing，不得
  放寬其他 artifacts、gates 或 architecture boundary。
- human 授權的 PC-15 participant-context presentation change：只將 401 sequence 的參與者副標籤表述
  移至圖外脈絡／說明區；保留 17 則訊息、所有 component identity、caller/factory/no-payload contract
  與 retry policy，並維持完整 normal delivery／visual-pass gate。
- RV-11 的 bounded canvas ownership／ledger rework：只移除 component-dependency canvas 對
  `AuthRequester` 準備 selected／decorated request 的錯誤指派，並讓 ledger 反映 RV-11
  `needs-rework` 與 replacement route；exact preparation owner／representation 維持 deferred。

## Out-Of-Scope

- 任何 Swift source、test、package manifest、public API、runtime behavior 或 API
  migration。
- `AuthAction` exact cases、header／decoration representation、failure surface、
  async signature、credential persistence、refresh endpoint、refresh I/O type 或
  event/result shape。
- generic HTTP retry、5xx／network retry、backoff、rate limit、circuit breaker、
  concurrent 401 single-flight、OAuth implementation、GitHub client behavior。
- 改寫 OAuth dual-client lifecycle architecture 或其 diagrams。
- 變更 401 sequence 的訊息數量、參與者／component identity、流程語意、ownership 或 retry policy；
  也不為 401 新增 visual exception。

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

本次 current-comment amendment 的 Implementer allowlist 更限縮為：

- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.json`
  與其 generated HTML、artifact-local validation／visual-check evidence；
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/auth-flow-state.json`
  與其 generated HTML、artifact-local validation／visual-check evidence；
- `docs/architecture/diagrams/http-client-package-structure/scene.js`、`index.html` 與其
  artifact-local validation／visual evidence。

不得修改 package canvas 的 `BUILD.md`、enhancement script 或其他 build semantics；也不得
修改 lifecycle、normal sequence、canonical document、Swift、OAuth 或其他 repository path。

以上是 **IM-07 的 historical standard-deliver limitation**：當時此例外不增加 allowlist，且只允許
標準 Archify `deliver` 寫入 state HTML／receipt；`[850,307]` 令該 command non-zero，故 IM-07
如實 blocked。它不是 current unconditional rule。

IM-08 alternate-materialization path 已是 historical blocked evidence，不是 current contract。
human 現僅允許 IM-11 在 `auth-flow-state` 將 retry permission 重述為進入 waiting-for-retry-response
的 transition／event（不是 node），並依此調整 topology/layout presentation，以消除 `[850,307]` 並恢復
normal Archify delivery。它必須保留 locked state
semantics，並標準 validate 9/9、0 errors、0 warnings、successful `deliver` source-matched receipt、
visual evidence與 manual light/dark inspection；不得改 401、package canvas、其他 diagram 或任何
runtime/deferred boundary。desktop containment exception與其他 gates 均未放寬。

PC-15／IM-13 的 historical allowlist 再限縮為
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.json` 與其
generated HTML、artifact-local validation／delivery／visual evidence。它只允許把參與者副標籤表述移至
圖外脈絡／說明區；package canvas、`auth-flow-state`、lifecycle、normal sequence、Swift、OAuth 與
所有其他 paths 均為 ReadOnly。

IM-15 的最小回修可修改
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/scene.js`
及其 generated `index.html`、artifact-local validation／visual evidence 與 actual-step ledger evidence。
`BUILD.md`、enhancement script、401、state、lifecycle、normal sequence、canonical document、Swift、OAuth
與其他 paths 均為 ReadOnly。

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
7. current-comment amendment 的 401 sequence 在 semantic exchange 前完整表達 caller entry、
   `AuthRequester → Auth` factory request、`Auth → AuthRequester` per-execution flow return，
   且 `AuthFlow` 不取得 original request。
8. current-comment amendment 的 state diagram 以等待 retry response state 及其 response
   policy 表達 retry 後的 normal-success／second-401 terminal 分支；package canvas 不指派
   selected／decorated request preparation 給 `AuthRequester`，其 exact owner 維持 deferred。
9. `auth-flow-state.json` 的 `[850,307]` 是 historical recovery diagnostic，兩次 focused repair、
   一次 independent overall-layout attempt 及 all-attempts-restored truth 必須保留；IM-11 必須以
   state-only transition/event expression 與 topology/layout redesign 消除它，不得把它當作 current accepted non-pass。
10. state output／receipt 必須來自 normal standard `deliver` 且可證明 source-match；state 需 validate
    9/9、0 errors、0 warnings及 visual evidence/manual light-dark inspection。重構只可 restructure、
    merge 或 reposition presentation，且必須保持 locked semantics；不得以例外跳過 401、package
    canvas、其他 diagram、diff、scope 或 delivery truthfulness gates。desktop containment exception
    仍是唯一 exact non-pass，不得稱 visual pass。
11. IM-13 只將 401 sequence 的參與者副標籤表述移至圖外脈絡／說明區；每一副標籤的說明意義皆可
    對照保留，17 則訊息、component identity、caller/factory/no-payload contract 與 retry policy 不變，
    且四個 desktop viewport 全數 visual-check pass。

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
   PR、merge、release 或開始 Swift implementation。此段是 PC-08 前的 historical lineage；
   delivered head 只記錄 DL-03 = `active`，不得把它當作 current delivery authorization。
8. 作為 historical CH-02 resolution condition，DL-03 delivery 完成後，Implementer 才可由
   CH-02 依已提供 evidence 回覆並 resolve T06；T01、T02、
   T03、T05、T07、T08、T09 只在對應 corrected delivery 已可見時 resolve；T04 只在
   reproducibility fix 已可見時 resolve。此刻不得以此 historical condition resolve 任一 thread。
9. historical CH-02 thread handling 完成後，HC-02 才交還 human review 既有 ready-for-review PR；不得
   自行 merge、release 或開始 future Swift implementation。
10. delivered head 的 ledger 歷史為 RV-04 = `approved`、DL-03 = `active`；PC-08／PR-08 是
    current PR #37 comment preflight = `needs-rework` 的 historical correction lineage。此
    predecessor route 不改變 PR status，也不得以 DL-03、CH-02 或 PR-08 越過 PC-09／PR-09
    的 current exception contract。
11. TE-06／RV-06／DL-04／CH-03／HC-03 是 IM-07 standard-delivery blocker 的 superseded
    downstream route；它們未前進，也不得處理 thread、commit/push 或改變 PR status。
12. PC-10／PR-10／IM-08 blocked 是 alternate-materialization recovery 的歷史：public
    validate／deliver／render 無法在 `[850,307]` 下產生 source-matched output，故不構成 delivery
    path；TE-07 至 HC-04 未前進，且由本次 replacement route supersede。
13. PC-09／PR-09 與 IM-07 blocked 是 historical proof：accepted crossing 不是 standard
    `deliver` success，且在沒有 alternate contract 時不得開始 downstream gate。它們不被回寫為
    pass 或 delivery approval。
14. PC-11／PR-11、PC-12／PR-12 與 blocked IM-09 是已核准或如實記錄的 historical route。PC-13 只可
    將 retry permission 從 lifecycle node 改為進入 waiting-for-retry-response 的 transition／event，並
    supersede alternate HTML materialization 與 prior state-node formulation；不得改 Model C、deferred
    decision、state acceptance、401/package gates 或 scope。PR-13 必須獨立審查這是 expression revision、
    不是 policy change，且 IM-11 state-only、IM-10 source-ReadOnly materialization-only、TE-09
    verification-only boundary與 evidence truth 一致；`approved` 才可依序進入 IM-11、IM-10。
15. IM-11 只可在 `auth-flow-state` 將 retry permission 表達為進入 waiting-for-retry-response 的
    transition／event（非 node），並調整其 topology/layout presentation 以消除 `[850,307]`；必須保留
    五項 locked semantics，並產生 state standard validate 9/9、0 errors、0 warnings、successful
    `deliver` source-matched receipt、visual evidence/manual light-dark inspection。IM-10 僅在 IM-11
    completed 後執行；不得修改 source，只能：(a) 對已修改的 401 source 標準
    validate → deliver → visual-check，取得 source-match/9-of-9/0-error/visual-pass evidence；(b) 對
    已修改 package scene 依 validate → temporary build → enhance → verify materialize `index.html`，
    證明 reproducibility/accessibility/source-output consistency。`BUILD.md` 與 enhancement script ReadOnly。
16. 只有 IM-11 與 IM-10 都 completed 且 state/401/package evidence 齊備，TE-09 才可**只驗證**，
    不得生成或更新 output/evidence。其後 route 固定為 TE-09 → RV-09 → DL-07 → CH-06 → HC-06；
    DL-07 僅在 TE-09/RV-09 approved 後才可 commit/push；CH-06 只在 corrected delivery visible 後
    重新取得 thread state，再依必要／非必要 thread policy處理。PR status 不變。
17. IM-10 的 401 visual-check blocked 與其 source-ReadOnly restriction 是 historical materialization
    boundary；package passed evidence 維持有效且不得重做。PC-14 僅將 401 layout/source repair 寫入四份
    planning artifacts；PR-14 必須獨立確認它不是 new exception、僅放寬 IM-12 的 401 source、且所有
    flow contract/semantics 未變。`approved` 才可進入 IM-12。
18. IM-12 僅可修正 `401-refresh-retry` layout/source 以取得所有 desktop visual-check pass；必須 standard
    validate 9/9、0 errors、0 warnings、deliver/source-match、1440／1600／1920／2048 visual pass、manual
    light/dark inspection。TE-10 只有 IM-12 completed 與 package passed evidence 齊備才可只驗證；其後
    route 固定為 TE-10 → RV-10 → DL-08 → CH-07 → HC-07。不得新增 exception、重做 package 或改動
    401 contract／state semantics。
19. IM-12 blocked 的「所有副標籤置於標頭」表述限制由 PC-15 狹義 supersede：PR-15 必須獨立確認參與者
    副標籤表述只會移至圖外脈絡／說明區、不是 exception，且 17 messages、flow contract、retry policy、
    component identities 與 package passed evidence 不變；`approved` 才可進入 IM-13。
20. IM-13 只可修改 `401-refresh-retry` 的參與者標頭／圖外脈絡表述及 required delivery evidence。
    每個移出的副標籤必須保留說明意義，但不得 invent ownership。它必須 standard validate 9/9、
    0 errors、0 warnings、deliver/source-match、1440／1600／1920／2048 visual pass、manual light/dark。
    TE-11 只在 IM-13 completed 後只驗證；其後進入 RV-11。RV-11 `needs-rework` 已停止原本未開始的
    DL-09 → CH-08 → HC-08 downstream route。
21. RV-11 = `needs-rework` 的 replacement scope 僅為 component-dependency canvas 不得把
    selected／decorated request preparation 指派給 `AuthRequester`，以及 ledger 必須如實將
    RV-11 `needs-rework` 作為 current rework truth。這是直接交回 IM-15 的最小回修，不建立新的
    planning cycle。TE-12 initial 已 `needs-rework`；IM-15 rework 已完成，TE-12 re-test 已
    `approved`。TE-14 已 `approved`，目前 gate 為 RV-14。IM-15 只可修正 canvas `scene.js`、generated
    `index.html` 與 artifact-local validation／visual evidence；其後 route 固定為 IM-15 rework →
    TE-14（approved）→ RV-14（current）→ DL-12 → CH-11 → HC-11。DL-12 僅在 RV-14 approved 後 commit/push；CH-11 僅在
    corrected delivery visible 後重新取得 exact thread evidence，必要事項修正後 resolve，非必要事項
    留言後 resolve；PR status 不變。

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
- **TC-06 — Diagram validation**：architecture-canvas 與每份 Archify artifact（含 redesigned state）
  分別通過規定 validate/build/deliver/visual evidence；Archify showcase validate 為 9/9 checks、0
  errors、0 warnings；exact delivered artifact 經人工 light/dark 檢視。state 只有 desktop containment
  的 exact non-pass，沒有較寬鬆的 delivery/pass claim。
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
- **TC-12 — Historical PR boundary**：PR #37 維持 OPEN、ready for review；PC-07 至 CH-02
  的 historical route 不得改變其 status。current route 以 step ledger 的 TE-14（approved）→
  RV-14（current）→ DL-12 → CH-11 → HC-11 為準，不得以 DL-03、CH-02、superseded
  CH-03 或 CH-04 提前回覆／resolve。
- **TC-13 — Current 401 factory prefix**：401 source/output/evidence 依序表達 caller entry、
  `AuthRequester → Auth` flow request、`Auth → AuthRequester` flow return、再開始不帶 request
  payload 的 semantic exchange；flow 沒有 original-request capability。
- **TC-14 — Retry-response policy topology**：retry permission 必須是進入
  waiting-for-retry-response 的 transition／event，而非 lifecycle node；state source/output/evidence
  沒有其直接到 success／second-401 的 shortcut，retry response 必經 waiting state 和 response policy。
- **TC-15 — Deferred preparation ownership**：package canvas 不把 selected／decorated request
  preparation 指派給 `AuthRequester` 或任何新 role，並維持 exact owner／representation deferred。
- **TC-16 — Materialization-separated history**：ledger 如實記錄 delivered head 的 RV-04 approved／
  DL-03 active、PC-10／PR-10／IM-08 blocked alternate-materialization history、IM-09 blocked history；
  這些均非 current gate。
- **TC-17 — Locked topology semantics**：state redesign 只可將 retry permission 表達為進入 waiting state
  的 transition／event並調整相連 presentation，
  但必須同時保留 first-401 ineligible terminal、eligible refresh、refresh outcome 回 Flow policy、
  refresh-success-only exactly-one retry、waiting-for-retry-response → response-policy 的
  normal-success／second-401 terminal 分支，且沒有 receive→retry shortcut。
- **TC-18 — Normal state delivery and unchanged gates**：state 必須消除 `[850,307]` 並 standard
  validate 9/9、0 errors、0 warnings、successful deliver/source-matched receipt、visual evidence/manual
  light-dark inspection；desktop containment 1035／1109／1109、2048 pass 維持 distinct non-pass。
  401 仍為 normal 9/9/deliver/visual pass，package canvas 仍為 validate/build/reproducibility/
  accessibility；任何一項不符均不得前進。
- **TC-19 — Output materialization evidence**：IM-10 不改 source；401 以 standard
  validate → deliver → visual-check 重新建立 source-match/9-of-9/0-error/visual-pass evidence，
  package 以 validate → temporary build → enhance → verify 重新 materialize `index.html` 並證明
  reproducibility/accessibility/source-output consistency。TE-09 只驗證兩個 Implementer 產出，
  不得生成 output/evidence。
- **TC-20 — 401 repair allowlist**：IM-12 僅可調整 `401-refresh-retry` layout/source；必須保留 caller
  entry、per-execution Auth factory round-trip、無 original-request flow access、ineligible/eligible policy、
  refresh-result policy return、success-only retry 與 no-shortcut semantics，且 package passed evidence 不重做。
- **TC-21 — 401 visual restoration**：IM-12 的 standard source-matched delivery 必須 9/9、0 errors、0
  warnings；1440×900、1600×1000、1920×1080、2048×1320 均 visual-check pass，並完成 manual light/dark。
  不得將這次 repair 記為 exception；PC-14 → PR-14 → IM-12 → TE-10 → RV-10 → DL-08 →
  CH-07 → HC-07 是 historical route，不是 current route。
- **TC-22 — Participant-context expression**：IM-13 保留 17 sequence messages、caller/factory/no-payload
  contract、Flow 無 original-request access、retry policy與 component identities；只把 participant sublabel
  expression 移到 external context/explanation area。
- **TC-23 — Context-copy truth**：每個移出的 sublabel 都在 external area 保留可對照的 explanatory meaning，
  且不 invent ownership、capability、runtime behavior 或 architecture decision；這不是 visual exception。
- **TC-24 — 401 presentation delivery**：IM-13 的 standard source-matched delivery 必須 9/9、0 errors、0
  warnings，1440×900、1600×1000、1920×1080、2048×1320 全數 visual-check pass並 manual light/dark；
  RV-11 `needs-rework` 後，DL-09 → CH-08 → HC-08 不再是 current route。
- **TC-25 — RV-11 canvas／ledger rework**：component-dependency canvas 不稱 `AuthRequester` 準備
  selected／decorated request，exact preparation owner／representation 維持 deferred；TE-12 initial =
  `needs-rework`、re-test = `approved` 後，TE-14 已 `approved`，ledger current route 是
  RV-14（current）→ DL-12 → CH-11 → HC-11，不得將 IM-14 或 superseded DL-03 當作 current gate，也不得建立新的 planning cycle。
