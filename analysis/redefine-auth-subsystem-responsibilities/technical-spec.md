# Auth 子系統責任重定義：技術規格

## Decision Status

本文件鎖定 architecture decision，而非 Swift implementation specification。
adopted target 是 Model C；現行 source 的 Model A 仍是 legacy runtime，直到 future
concrete-consumer topic 取得獨立 implementation approval 為止。

## Locked Architecture Contract

```text
caller
  │ original HTTPRequest（所有權保留）
  ▼
AuthRequester ──要求新 flow──────► Auth（factory／strategy provider）
  │                                  │
  │◄── per-execution AuthFlow（新建）─┘
  │
  ├── response input ───────────────► AuthFlow（policy/state）
  │◄── semantic decision ────────────┤  response semantics／retry decision
  │                                  │  no request construction／no I/O
  │                                  │
  ├── retained original request ────► Requester（generic HTTP I/O）
  │◄── raw HTTPResponse ─────────────┤
  │
  └── deferred refresh dispatch ────► deferred refresh I/O boundary
                                        （未命名、未鎖定；不由 AuthFlow 直接呼叫）
```

- `Auth` 的 contract 是在每個 `AuthRequester` execution 開始時建立並回傳一個獨立
  `AuthFlow` 的 factory／authentication strategy，不是 credential store、HTTP decorator
  或 I/O component。它不取得 caller original request 的 ownership。
- `AuthFlow` 擁有 per-execution authentication state、response-to-next-decision
  transition、refresh eligibility、retry limit 和 terminal decision。它可以讀取
  `HTTPResponse`，包括 401 semantics；這不是 request construction 或 I/O authority。
- `AuthRequester` 擁有 original request 的 lifetime 和 semantic action
  interpretation。它不得重訂 retry policy，也不得把 caller request ownership
  交給 flow；它只保有 caller original request，**不建構**該 request。selected／decorated
  representation 的 owner／API 維持 deferred；它以 `Requester` 執行該 retained request。
- `Requester` 唯一負責 generic HTTP I/O：接收已選定 `HTTPRequest`，交 transport，
  回傳 raw `HTTPResponse`。它不認識 auth flow、credential refresh 或 retry policy。

## Capability Boundary

Model C 的 type contract 必須最終能表達下列限制：

| Capability | `AuthFlow` target | Owner |
| --- | --- | --- |
| 讀取 401／其他 raw response semantics | 允許 | `AuthFlow` 作為 policy input |
| 決定是否 refresh、retry、finish | 允許 | `AuthFlow`，唯一 policy owner |
| 保有／讀取 original URL、method、query、body | 禁止 | `AuthRequester` 只保有 caller original request |
| 建構或修改 arbitrary `HTTPRequest` | 禁止 | 不授予 `AuthFlow`；exact decoration owner deferred |
| 建構 refresh endpoint request | 禁止 | future refresh I/O component，尚未定義 |
| 執行 transport／`Requester`／`URLSession` I/O | 禁止 | `Requester` 或 future dedicated I/O component |
| 持久化／更新 credential | 禁止 | future credential lifecycle boundary，尚未定義 |

這些 capability 是 future API review 的 acceptance boundary；本 topic 不從中推導
`AuthAction` enum、protocol methods 或 value type。

## Responsibility Matrix

| Role | Owns auth state | Knows HTTPResponse | Knows original request | Builds original request | Builds refresh request | Performs I/O | Controls retry |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Auth` | 否 | 否 | 否 | 否 | 否 | 否 | 否 |
| `AuthFlow` | 是 | 是 | 否 | 否 | 否 | 否 | 是 |
| `AuthRequester` | 否 | 是，轉交給 flow | 是，唯一 owner | 否；只保有 caller original request，selected／decorated representation deferred | 否 | 否，僅委派 | 否 |
| `Requester` | 否 | 是，raw return | 僅取得待執行 instance | 否 | 否 | 是 | 否 |
| `TokenFetcher` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| `TokenProvider` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |

## Legacy and Target Distinction

| Dimension | Legacy Model A | Adopted Model C target |
| --- | --- | --- |
| Flow input | `Auth.makeFlow(for: HTTPRequest)` 授予 original request | exact factory input deferred；flow 不取得 original request capability |
| Flow output | `.send(HTTPRequest)`，可指向任意／多個 request | semantic decision；exact action type deferred |
| `AuthRequester` | generic loop driver | semantic interpreter + sole original request owner |
| Refresh HTTP request | contract 允許 flow 建構 | future dedicated I/O owner，未定義 |
| Retry policy | flow 可透過任意 action 實現，但 type boundary 不限制 work | flow 的明確 state transition responsibility |
| Runtime status | 已實作 | 已採用、尚未實作 |

Model B（restricted HTTP action）未採用，因為它要求現在先選擇 header overlay 與
request-decoration ownership。Model C 保留最小責任決定，延後尚無 concrete consumer
佐證的 representation。

## Flow Topology to Document

### Normal Request

1. caller 將 original request 交給 `AuthRequester`；它是唯一 owner。
2. `AuthRequester` 向 `Auth` factory 要求新 flow；`Auth` 為這個 execution 建立並回傳
   一個 independent `AuthFlow`，之後才開始與 flow 的 semantic send decision exchange；
   factory interface 尚未鎖定。
3. `AuthRequester` 只轉交 retained caller original request 以供執行；它不建構
   original request，selected／decorated representation 尚未鎖定。
4. `Requester` 執行 HTTP I/O，回傳 raw `HTTPResponse`。
5. `AuthRequester` 把 response 交給 `AuthFlow`；flow 作 terminal policy decision。
6. `AuthRequester` 回傳 terminal response；它不自行產生 retry count policy。

### 401 Refresh and Retry

1. caller 先把 original request 交給 `AuthRequester`，作為本次 original execution entry；
   `AuthRequester` 保有它，但不建構它，也不把它交給 `AuthFlow`。
2. initial semantic send 前，`AuthRequester` 向 `Auth` factory 要求 per-execution flow；
   `Auth` 建立並回傳一個 independent `AuthFlow` 給 `AuthRequester`。factory request／return
   不帶 original request，之後的 `AuthRequester ↔ AuthFlow` exchange 才開始，且只傳遞
   response／semantic decision，不帶 request payload。
3. `Requester` 回傳 401 raw response；`AuthRequester` 將它交給 `AuthFlow`。只有具
   refresh capability 且該 state eligible 的 flow 可在第一次 401 發出 semantic refresh
   decision；不具資格的 flow 可以 terminal，仍由 flow 單一擁有 decision/state。
4. `AuthRequester` 只解讀 semantic refresh decision，交給 **deferred credential-refresh
   I/O boundary**；這份文件不命名 type、不定義 endpoint、payload、credential update
   API 或 refresh-result type。
5. deferred boundary 完成其 I/O 與 credential update responsibility後，將 refresh result
   經 `AuthRequester` 的 deferred result boundary 傳回 flow；沒有 receive→retry shortcut。
6. **只有 refresh-success** result 使 flow 可發出 semantic retry permission **transition／event**；
   它進入 waiting-for-retry-response policy state，而非成為獨立 lifecycle node。該 state 收到
   retry response 後，才由 response policy 分支 normal-success terminal 或 second-401 terminal；不得由
   retry permission
   直接到任一終態。refresh failure、ineligible flow 與第二次 401 都 terminal。
   `AuthRequester` 仍只可重送其 retained original work，且不自行決定 retry。

401 diagram 不得將上述 topology 畫成 existing runtime，亦不得以圖表建立新的
`TokenFetcher`、`TokenProvider`、`CredentialRefresher` 或 `AuthEvent` public contract。

## Long-Lived Documentation Contract

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

僅 final replacement Plan Review gate **PR-03** 明示 `approved` 後，獨立 Implementer
可只在以下 paths materialize decision。PR-03 的 `approved` 是此 topic 唯一滿足
「Plan Review approved」條件的 verdict；PR-01 與 PR-02 均為 historical
`needs-rework`，不授權 IM-01。

- 新增 `docs/architecture/rivet-http-client-auth-responsibilities.md`，含 matrix、
  legacy/target distinction、Model A/B/C comparison、recommendation 與 trade-off。
- 更新 `docs/architecture/README.md` 和 `docs/architecture/bounded-contexts/README.md`
  的索引／boundary wording。
- 修訂既有 AuthFlow lifecycle artifact 和 HTTP client package canvas，使其標示 legacy
  runtime 與 adopted target 的差異，而不把 target 說成已交付。
- 在 `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/` 新增一份
  architecture-canvas component/dependency diagram，以及三份 Archify diagrams：normal
  request sequence、401 refresh/retry sequence、AuthFlow state diagram。

Canvas 只表達 component responsibility/dependency，不表達 runtime sequence。三份
Archify artifacts 只表達 adopted target；所有作者內容為繁體中文。不得發布
artifact.cafe。

## PR #37 Comment-Fix Materialization Contract

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

此 comment-fix 不改變 Model C。獨立 Implementer 只可在既有 allowlist 內完成下列
修正，並使 source、generated output 與 evidence 一致：

1. canonical responsibility document 的 matrix 改為 `AuthRequester` 不建構 original
   request，只保有 caller original request；selected／decorated representation 仍 deferred，
   不新增 decoration API 或 runtime role。
2. lifecycle、401 sequence、state diagram 由 `Auth` factory 在 initial semantic send 前
   建立 one per-execution flow，並將 `AuthRequester ↔ AuthFlow` 標為無 request-payload 的
   response／semantic exchange；不得畫成 `AuthRequester` 向預先存在的 flow 取得 instance。
3. 401／state 明示 eligible refresh-capable flow 才可在 first 401 request refresh，
   refresh result 經 deferred boundary 回 flow，只有 refresh-success retry；ineligible、
   refresh-failure 及 second-401 terminal。
4. `http-client-package-structure/BUILD.md` 僅可調整固定 build kicker／subtitle 的作者
   arguments，使既有 pipeline 可重現已交付繁中 HTML；enhancement script 和其他 build
   semantics 均為 ReadOnly。
5. lifecycle、401、state 的所有說明性文案必須使用繁體中文：以「request 資料」、「資格」、
   「延後確定」、「更新成功」分別取代 payload、eligibility、deferred、refresh-success
   的解釋；只有 type、protocol、state、檔名等 identifier 可保留英文。
6. current PR #37 comment preflight 的四個必要 correction 僅限：(a) 401 diagram 在無
   request-payload semantic exchange 前表達 caller entry 及 `AuthRequester → Auth → AuthRequester`
   的 per-execution-flow factory round-trip；(b) state diagram 將 retry permission 表示為進入
   waiting-for-retry-response state 的 transition／event（非 lifecycle node），再由 response policy
   分支 normal success 或 second 401；
   (c) package canvas 不得將 selected／decorated request preparation 指派給 `AuthRequester`；
   (d) ledger 如實回復 delivered head 的 RV-04 = approved、DL-03 = active，並為 current
   preflight = needs-rework 定義新的 gated route。以上不決定 preparation owner、representation
   或任何新的 runtime API。

## Human-Authorized State Delivery-Recovery Redesign

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

human 現明確授權只擴張 `auth-flow-state.json` 的 topology/layout presentation scope，目的僅為
消除 Archify showcase composition crossing `[850,307]`、恢復 normal standard delivery。PC-10／
PR-10／IM-08 alternate-materialization route（public validate／deliver／render 都失敗，preview 無
source-matched output）保留為 historical failed recovery evidence，現由 PC-11 route supersede。PC-13
進一步 supersede IM-09 的 prior state-node formulation；此為 expression revision，非 retry policy change，
也不恢復 alternate HTML materialization path。

IM-11 可將 retry permission 表達為進入 waiting-for-retry-response 的 transition／event（不是
distinct lifecycle node），並調整相連 state presentation、labels、areas 與 transitions，卻必須保持
下列 locked semantics：first 401 的 ineligible／non-refresh-capable flow terminal；eligible path refresh；
refresh outcome 回到 Flow policy；只有 refresh success grants exactly one retry；waiting state 將 retry
response 交給 response policy 分支 normal success／second-401 terminal；沒有 receive→retry shortcut。
這不重開 Model C、original-request ownership、
deferred preparation owner/representation、401/canvas contract 或任何 runtime API。

state redesign 的 acceptance 是 standard Archify showcase validate 9/9、0 errors、0 warnings、
successful standard `deliver` 的 source-matched HTML／receipt，以及 exact-delivered visual evidence
與 manual light/dark inspection；不得將未消除的 `[850,307]` 稱為 accepted non-pass 或 delivery。
兩次 focused repair、一次 independent overall-layout attempt、all-attempts-restored 與 IM-08 failure
只保留為歷史。既有 desktop containment accepted non-pass 完全分離且不變：1440×900 scrollHeight
1035、1600×1000／1920×1080 1109、2048×1320 pass；它仍不得稱 visual-check pass。401 sequence
仍須完整 standard 9/9、normal `deliver`、visual pass；package canvas 維持 validate/build/
reproducibility/accessibility；其他 diagram、scope、ReadOnly、diff、PR status 或 thread gates
一概不被豁免。

PC-12 明確分離 source modification 與 output materialization；PC-13 使 IM-11 成為唯一可修改 state
expression／presentation 的 step。IM-10 在其後獨立執行，且 **source ReadOnly**。實際現況只記錄下列
unproven pairs：401 JSON SHA-256
`edf7864d859bede17f9572d1a24dff31452ce8a4f0ec80ec14874c818cc5c798`、existing 401 HTML SHA-256
`f4e4d9f546a7f772127b008a7e64f7e01b47bc0d7fb3b142155992d4697c73ca`；package scene SHA-256
`017bdfe15961912f24c6e479938fff17f6a85b6bc7069eeeaa9aefb2c336bc3f`、existing index SHA-256
`ca7b3773ab24971f8f41172ad1489df29015b1a85f1abfb900115483f9aa03d2`。沒有 receipt 將各 pair 證明為
source-matched；不得從現有 hash 推定 output validity。IM-10 必須重新建立可追溯的 delivery／build
relation，而 `BUILD.md` 與 enhancement script 維持 ReadOnly。

## Human 授權的 401 參與者脈絡表述調整

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

human 授權 PC-15／PR-15／IM-13 只將 `401-refresh-retry` 的參與者副標籤表述從參與者標頭移至
圖外脈絡／說明區。這只 supersede IM-12 的「所有副標籤置於標頭」表述限制，並不是 visual exception、
retry-policy change、component identity change 或 ownership change。

每個移出的副標籤必須在圖外脈絡／說明區以可對照的說明文字保留既有解釋意義；不得 invent ownership、
capability、runtime behavior 或 architecture decision。IM-13 只可修改 `401-refresh-retry.json`、其 generated
HTML 和 artifact-local validation／delivery／visual evidence；`auth-flow-state`、package canvas、lifecycle、normal
sequence、Swift、OAuth 和所有其他 paths 皆為 ReadOnly。必須保留 17 則 sequence messages、caller →
AuthRequester 的 entry、AuthRequester → Auth → AuthRequester 的 per-execution flow factory round-trip、
request-less exchange、Flow 無 original-request access、ineligible／eligible policy、refresh result 回 policy、
refresh-success-only exactly-one retry、waiting-for-retry-response → response-policy split 和 no
receive→retry shortcut。

IM-13 的交付仍是 standard Archify showcase validate 9/9、0 errors、0 warnings、source-matched `deliver`、
1440×900／1600×1000／1920×1080／2048×1320 全數 visual-check pass 與 exact-delivered manual light/dark
inspection。package passed materialization evidence 維持、不重做。route 固定為 PC-15 → PR-15 → IM-13 →
TE-11 → RV-11；TE-11 只驗證、不產生 output/evidence。RV-11 `needs-rework` 已取代原本未開始的
DL-09 → CH-08 → HC-08 downstream route。

## RV-11 Canvas Ownership／Ledger Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

RV-11 = `needs-rework` 的範圍只有兩項：component-dependency canvas 不得將
selected／decorated request 的準備責任交給 `AuthRequester`；該角色只保有 caller original request
並解讀 semantic action，準備者與 representation 的 exact owner 維持 deferred。step ledger 也必須以
RV-11 = `needs-rework` 為 current rework truth，不得將 IM-14 receipt regeneration 或已 supersede
的 DL-03 誤述為 current gate。

這不重開 Model C、original request ownership、retry policy、401 sequence、state topology、
participant-context presentation 或 deferred API。這是直接交回 IM-15 的最小回修，不建立新的 planning cycle。
TE-12 initial 已 `needs-rework`；IM-15 rework 已完成同一個 bounded canvas finding 的回修，且 TE-12 re-test 已
`approved`；下列是 PC-18 前的 historical snapshot：TE-14 已 `approved`，當時 gate 為 RV-14。IM-15 的
實作範圍只可更新
`component-dependency/scene.js`、其 generated `index.html`、artifact-local validation／visual evidence 與
actual-step ledger evidence；`BUILD.md`、enhancement script、401、state、lifecycle、normal sequence、
canonical document、Swift、OAuth 與其他 path 均為 ReadOnly。當時 historical route：
TE-14（approved）→ RV-14（approved）→ DL-12（completed）→ CH-11（completed）→ HC-11（needs-rework）。

## Post-Merge Four-Thread Correction Contract

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

`f277ac4` 的 canonical-containment delivery 與 `d2cefd4` 的 `dev` merge-conflict
resolution 都已可見於同一 feature branch。`DL-12`、`CH-11` 因而是 completed historical
steps；`HC-11` 收到四個穩定 review finding 後為 `needs-rework`。這一 current-state sync
supersede 本文件所有較早的「RV-14 current」或「DL-12 active」敘述；它們只保留為歷史。

以下是 PC-19 前的 PC-18 historical route：

```text
PC-18 (completed) → PR-18 → IM-18 → TE-15 → RV-15 → DL-13 → CH-12 → HC-12
```

PR-18 是獨立 Plan Review，現已 `approved` 並授權且完成 IM-18。它只確認下列已鎖定 contract
內的 correction；不重新決定 architecture。TE-15／RV-15 均已 `approved`，DL-13 已 completed；CH-12
已 completed（四個 thread 已 resolved、無未分類 feedback）。HC-12 隨後收到兩項 P2 feedback，當時為
`needs-rework`；四個已 resolved thread 維持 historical。

1. **formal state**：四份 artifacts 一致敘述 `f277ac4`／`d2cefd4`、DL-12／CH-11 completed、
   HC-11 `needs-rework` 與上述 route；PR #37 保持 OPEN、ready for review。
2. **state standard delivery**：`auth-flow-state.json` 是 ReadOnly。IM-18 只能透過既有
   canonical-containment producer，由 repository root 以 repository-relative input／output 執行
   standard `deliver`，寫入 `auth-flow-state.html`、新
   `auth-flow-state.delivery.json` 與必要 visual evidence。receipt 必須 producer-generated，記錄
   source／HTML SHA-256、showcase 9/9、0 errors、0 warnings，以及只含 repository-relative POSIX
   path 的 artifact/input/output/provenance metadata；不得 postprocess 或修改 producer。state visual
   check 仍精確記錄 1440×900 = 1035、1600×1000／1920×1080 = 1109、2048×1320 pass，為 accepted
   non-pass 而非 pass。
3. **component legacy dependency**：`component-dependency/scene.js` 可恢復
   `AuthRequester → HTTPRequest`，但 edge 與對應說明必須明確限定為 legacy Model A 的編譯期
   request-type dependency。它不可描述成 adopted Model C target request preparation、request
   construction、ownership/dataflow transfer 或 I/O delegation；Model C 的 original-request ownership
   和 selected／decorated preparation owner／representation deferred 都維持原判。canvas 必須重新
   validate、build、檢驗 temporary rebuild byte-identical 與既有 accessibility baseline。
4. **401 terminal response**：`401-refresh-retry.json` 可增加唯一的
   `AuthRequester → caller` terminal final-response message，以及與該 response 相符的 caller
   activation。實作須把 message count 從 17 記為 18，並證明此是唯一新增 message；其他
   factory prefix、no-request-payload semantic exchange、Flow 無 original request、eligible-only
   refresh、refresh result 回 policy、success-only exactly-one retry、waiting-to-response-policy terminal
   split 和 no receive→retry shortcut 一律 ReadOnly semantics。401 仍須 standard `validate`／`deliver`、
   source-match、showcase 9/9、0 errors、0 warnings、四個 desktop viewport visual pass 與 exact
   delivered manual light/dark inspection。

IM-18 只可寫入四份 planning artifacts 的 actual-step evidence、state generated delivery output／receipt／
visual evidence、component source/generated output/evidence、401 source/generated output/evidence。Swift、
OAuth dual-client lifecycle、receipt producer／tests、package canvas、canonical architecture document、
lifecycle、normal sequence 與其他 repository paths 均為 ReadOnly；無刪除、rename 或 move 授權。

TE-15 只驗證這些產出、hash/provenance、message delta、canvas semantics/reproducibility/accessibility、
visual facts、scope、`git diff --check` 與 dev clean，不產生 output。RV-15 只在 TE-15 `approved` 後
獨立判斷四個 finding 與所有 locked contract 是否無 drift。TE-15／RV-15 `approved` 後，DL-13 已完成
commit/push；CH-12 已在 delivery visible 後完成四個 thread 的 resolve，且重新取得結果沒有未分類 feedback。
PC-18 route 已在 HC-12 的兩項 P2 feedback 後結束為 `needs-rework`，不 merge、不 release。

### PC-19 — Post-HC-12 Two-P2 Diagram Expression Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

human 已明示授權此 formal rework cycle。PC-19 是既有 architecture contract 內的最小 post-HC-12 rework，
已 `completed`，PR-19／TE-16／RV-16 verdict 為 `approved`，DL-14 已 completed；CH-13 = `needs-rework`、
HC-13 = `pending`，故 PC-19 為 PC-20 前 historical route。不重新決定 Model C、retry policy、state topology、
original-request ownership、deferred preparation owner 或 OAuth boundary。

HC-12 當時 `needs-rework` 的兩項 precise P2 feedback 為：

1. **P2-01**（`PRRT_kwDOUFu0Cc6knaR9`）：`http-client-package-structure` canvas 必須新增或明示
   `AuthRequester → HTTPRequest` 只屬 legacy Model A 的編譯期 request-type dependency。它必須與
   component-dependency canvas 的既有 edge 一致；不得被標示或解讀為 Model C target request preparation、
   construction、ownership、dataflow transfer 或 I/O。component-dependency canvas 維持 ReadOnly。
2. **P2-02**（`PRRT_kwDOUFu0Cc6knaSA`）：`auth-flow-state` 的 retry-response transition 與
   normal-terminal edge 只可透過 layout／route 分離，消除假雙向箭頭的視覺讀法。不得新增、移除或改變
   retry policy、state topology、transition／terminal semantics、message contract 或 runtime behavior。

PC-19 的 P2-01／P2-02 已由 DL-14 completed delivery 處理；它們只保留為 historical evidence。

### PC-20 — Final PR Comment Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

human 已直接授權 PC-20；其 initial formal planning write 與 PR-20 `needs-rework` 的最小 amendment 均已
`completed`／historical，獨立 PR-20 re-review 亦已 `approved`／`completed`，IM-20 已 `completed`，TE-17／RV-17 已 `approved`／`completed`，DL-15 已於 `3abbc71` completed，CH-14 = `needs-rework`、HC-14 = `pending`，故 PC-20 為 historical。它是最後的
bounded comment-rework route，只處理下列 exact feedback，不改 API、owner、retry policy、state topology、Swift、OAuth 或 long-lived architecture docs：

1. **P3-01** `PRRT_kwDOUFu0Cc6knhr9`：normal-request sequence 清楚維持 selected／decorated request
   representation 與 preparer deferred，未指派給 `AuthRequester` 或新 role。
2. **P3-02** `PRRT_kwDOUFu0Cc6knhsB`：auth-flow lifecycle 的 refresh-failure terminal 只採 neutral／generic
   style，不能暗示 success；terminal semantics 不變，且不得新增 node、payload 或 API。
3. **P3-03** `PRRT_kwDOUFu0Cc6knhsF`：401 只拆分 Requester initial/retry activation；固定 18 messages，
   不改 factory/no-payload/retry semantics。
4. **P3-04** `PRRT_kwDOUFu0Cc6knaSA`：auth-flow-state 只 revalidate current source/output，無 source change。
5. **P3-05** `PRRT_kwDOUFu0Cc6knaR9`：package canvas 只 revalidate current source/output，無 source change；
   在 delivery visible 後 reply／resolve。

README／bounded-contexts additive base conflict 是 comment closure，而非 document rewrite。actual additive resolution
必須同時保留既有 OAuth runtime description 與 Model C auth canonical conclusion，兩者共存且不構成 long-lived-doc
architecture change：`docs/architecture/README.md`、bounded-contexts 與其他 canonical architecture docs 均 ReadOnly。

PC-20 historical route 是：

```text
PC-20 amendment → PR-20 re-review → IM-20 → TE-17 → RV-17 → DL-15 (`3abbc71` completed) → CH-14 (needs-rework) → HC-14 (pending)
```

PR-20 是獨立 Plan Review gate。PR-20 `approved` 後，IM-20 的 Written allowlist 僅為四份 planning
artifacts 的 actual-step evidence、normal-request source／HTML／artifact-local evidence、auth-flow-lifecycle
source／HTML／artifact-local evidence、401 source／HTML／receipt／artifact-local evidence及必要 generated
delivery evidence。package/state source、component canvas、Swift、OAuth、receipt producer／tests、long-lived docs、
canonical README與所有其餘 path 一律 ReadOnly；不得 delete、rename、move、merge 或 release。

IM-20 completion 必須確認 lifecycle 僅為 neutral／generic terminal presentation，未新增 node、payload 或 API。
TE-17 必須獨立驗證 normal/lifecycle/401 presentation correction、401 18-message invariant、P3-02
no-node／no-payload／no-API assertion、package/state no-source revalidation，以及 README／bounded-contexts actual
additive resolution 同時保留 OAuth runtime description 與 Model C auth canonical conclusion、沒有 long-lived-doc
architecture change；並驗證 scope、source-output-delivery evidence與 state exact non-pass truth。RV-17 只在 TE-17
`approved` 後獨立審查上述 P3-02 與 conflict criteria。RV-17 `approved` 後才可 DL-15；delivery visible 後 CH-14 只在
確認兩項 README／bounded-contexts conclusion 共存、無 long-lived-doc architecture change 時，處理五項 P3、
README base-conflict reply／resolve及新取得已分類 feedback。DL-15 已於 `3abbc71` completed；CH-14 因新的 P2 receipt
finding 為 `needs-rework`、HC-14 = `pending`，故 PC-20 route 為 PC-21 前 historical。

### PC-21 — Receipt-Only Final Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-21 是 historical receipt-only snapshot：DL-16 已以 `bccc183` completed／visible，CH-15 因 P5 feedback 為
`needs-rework`，HC-15 是 pending historical human boundary。**P4-01** `PRRT_kwDOUFu0Cc6koqlS` 只收斂 normal-request 與 auth-flow-lifecycle 的
standard producer-generated `.delivery.json` receipts；artifact/source semantics 不變。以下 PC-21 route 是 historical snapshot，非 current route：

```text
PC-21／PR-21／IM-21／TE-18／RV-18 (completed／approved／historical) → DL-16 (`bccc183` completed／visible) → CH-15 (needs-rework) → HC-15 (pending historical)
```

PR-21 `approved` 後，IM-21 只可用 repository-relative input／output 和 `--repo-root` 重跑 standard `deliver`，
生成兩份 receipt 與必要 artifact-local receipt/visual evidence。receipt 必須驗證並記錄 source／HTML hashes、9/9、
0 errors、0 warnings 與無絕對路徑的 provenance；normal-request／auth-flow-lifecycle source、HTML、artifact semantics
必須 byte-identical。四 viewport visual evidence 僅在 delivery 所需時 revalidate。

TE-18 獨立驗證 producer invocation、relative metadata、hash continuity、9/9／0／0、absolute-path absence、
byte-identical source/HTML與必要 visual evidence；RV-18 審查 P4-01/no-drift。僅 RV-18 `approved` 後，DL-16 才可依本
direct human execution authorization 將 receipt-only diff commit，並 normal push 至既有 PR #37 branch。只有 pushed commit
在既有 PR branch 可見且 P4-01 receipt evidence 已 verified 後，CH-15 才可 reply／resolve P4-01；其 closure 後的 P5 feedback 由 PC-22 承接。所有其他 diagrams/source/HTML、README/merge candidates、Swift、OAuth、
producer/tests、state/package/401、long-lived docs及未列 path ReadOnly；不新增 contract/API/policy/topology/role/test implementation。

### PC-22 — P5 Current-State and 401 Terminal-Decision Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

human authorization 與 independent Planner ready verdict 已足夠建立 PC-22；不需新 design choice。DL-16 `bccc183`
completed／visible，CH-15=`needs-rework`、HC-15=`pending` 均為 historical。PC-22 已 completed／historical、PR-22 completed／approved／historical、IM-22 completed／historical、TE-19 completed／approved／historical、RV-19 completed／approved／historical，DL-17 `cc15069` completed／visible／historical；其後 DL-18 `51ae037` completed／visible。CH-16 因 `PRRT_kwDOUFu0Cc6k_x2f` 為 `needs-rework`、HC-16 pending，均為 PC-23 前 historical state。以下為 PC-22 historical route：

```text
PC-22 (completed／historical) → PR-22 (completed／approved／historical) → IM-22 (completed／historical) → TE-19 (completed／approved／historical) → RV-19 (completed／approved／historical) → DL-17 (`cc15069` completed／visible／historical) → DL-18 (`51ae037` completed／visible／historical) → CH-16 (needs-rework historical) → HC-16 (pending historical)
```

**P5-01** `PRRT_kwDOUFu0Cc6kqRi3` 僅修正 stale current claim/gate/route，令其符合上述 actual state；dated
historical snapshot、completed evidence 與 locked architecture 必須原樣保留。**P5-02**
`PRRT_kwDOUFu0Cc6kqRi9` 僅修改 `401-refresh-retry` source/output/receipt/visual evidence：原有 18 message
IDs/semantics 完全不變，總數恰為 20，且只新增兩則 guarded `AuthFlow → AuthRequester` terminal decision：
ineligible terminal/no refresh、refresh-failure terminal/no retry。兩則位於互斥 segments；不新增 caller failure return、
payload、API、state node/transition、policy、ownership 或 runtime behavior，並保留 caller final response、factory／
no-payload／retry semantics。

下列六個 fixed closure threads 維持 resolved/historical、不得 reopen/reply/change：
`PRRT_kwDOUFu0Cc6knhr9`、`PRRT_kwDOUFu0Cc6knhsB`、`PRRT_kwDOUFu0Cc6knhsF`、
`PRRT_kwDOUFu0Cc6knaSA`、`PRRT_kwDOUFu0Cc6knaR9`、`PRRT_kwDOUFu0Cc6koqlS`。

P5 allowlist 是四份 planning artifacts 與唯一 401 artifact set（JSON、generated HTML、delivery receipt、artifact-local
visual evidence）；P5-01 只寫 planning，P5-02 才寫 401 set。其餘 diagrams/source/HTML/receipt/visual、README/merge,
Swift/OAuth、producer/tests、state/package/normal/lifecycle、long-lived docs 及未列 path ReadOnly。PR-22 獨立審查；
TE-19 必須驗證 P5-01 historical preservation、六 fixed closures、standard 401 validation/delivery/provenance/9/9/0/0/
four-viewports、20 total、18 original IDs/semantics unchanged、兩 guarded mutually exclusive terminals與所有 prohibited
capabilities absent；RV-19 獨立 no-drift。TE-19/RV-19 approved 後，DL-17 可依 human authorization single-topic
commit/normal-push existing PR branch；pushed commit/evidence visible 後 CH-16 才可 resolve P5-01/P5-02、重抓 threads，
確認 six closures still resolved/no unclassified feedback，停在 HC-16；不 merge/release。

### PC-23 — P6 Component Canvas Raw-Response Route-Only Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

exact thread `PRRT_kwDOUFu0Cc6lAdHo` 只授權 component-dependency canvas raw `HTTPResponse` edge 的 route geometry
修正；既有 direct progression authority 僅在此 bounded scope 內適用。DL-18 `51ae037` completed／visible、CH-16=
`needs-rework`、HC-16=`pending` 均為 historical。PC-23／PR-23／IM-23／TE-20／RV-20／DL-19 已 completed／historical，PR-23／TE-20／RV-20 verdict=`approved`，DL-19=`6127b29` completed／visible；CH-17 因 exact ledger-only thread `PRRT_kwDOUFu0Cc6lAh5g` 為 `needs-rework`，HC-17=`pending`。下列為 PC-24 前 historical P6 closure lineage，非 current route：

```text
PC-23 (completed／historical) → PR-23 (completed／approved／historical) → IM-23 (completed／historical) → TE-20 (completed／approved／historical) → RV-20 (completed／approved／historical) → DL-19 (`6127b29` completed／visible／historical) → CH-17 (needs-rework) → HC-17 (pending)
```

P6-01 必須使 raw-response edge 視覺上明確終止於 `AuthRequester` box，而非 legacy `HTTPRequest` box；不得改變
endpoint semantics、label 或 locked architecture contract。所有 boxes、ownership statement、legacy Model A
`AuthRequester → HTTPRequest` compile-time request-type dependency 均 ReadOnly，且不得重新解釋為 Model C preparation、
construction、ownership、dataflow 或 I/O。

IM-23 的唯一 artifact allowlist 為 component canvas 的 `scene.js`、generated `index.html` 與其 validation、build、enhance、
accessibility、temporary-rebuild reproducibility、visual evidence；四份 planning artifacts 僅可用於 state/route traceability。
所有其他 diagram/document/source、README、Swift、OAuth、producer、tests、receipts、package、401、normal、lifecycle、state、
Git/GitHub 與未列 path ReadOnly。禁止新增、移除或改寫 API、role、owner、policy、topology、payload、message、contract、box
或 legacy edge，亦不得 delete、rename、move、merge/release。

PR-23 只審查 exact edge-route、allowlist 與 ReadOnly locks。TE-20 獨立驗證 edge 的 visible endpoint、endpoint
semantics/label/contract unchanged、boxes/ownership/legacy edge no-drift，以及 source/output 與 validate/build/enhance/a11y/
repro/visual evidence consistency；RV-20 只在 TE-20 `approved` 後獨立 no-drift review。TE-20/RV-20 approved 後，DL-19
才可依 existing authority commit/normal-push 至既有 PR branch。只有 pushed commit/evidence visible 後，CH-17 才可 reply/
resolve 全部十個 fixed threads：`PRRT_kwDOUFu0Cc6knhr9`、`PRRT_kwDOUFu0Cc6knhsB`、
`PRRT_kwDOUFu0Cc6knhsF`、`PRRT_kwDOUFu0Cc6knaSA`、`PRRT_kwDOUFu0Cc6knaR9`、
`PRRT_kwDOUFu0Cc6koqlS`、`PRRT_kwDOUFu0Cc6kqRi3`、`PRRT_kwDOUFu0Cc6kqRi9`、
`PRRT_kwDOUFu0Cc6k_x2f`、`PRRT_kwDOUFu0Cc6lAdHo`。重抓 feedback 確認全數 resolved、無未分類 feedback後，
停於 HC-17 human review；不 merge/release。

### PC-24 — Lifecycle Policy-Return Projection + Component Edge Route Separation

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

DL-19 `6127b29` completed／visible、CH-17=`needs-rework`、HC-17=`pending` 僅為 PC-24 前 historical P6 closure
state。先前 PC-24 amendment／layout amendment 與其 completed／approved review 均為 historical；PC-24 transition-count
amendment 已 completed／historical，PR-24 獨立 re-review 已 completed／approved／historical，IM-24 已 completed／historical，TE-21 已 completed／approved／historical，RV-21 已 completed／approved／historical，DL-20 `67695b5` 已 completed／visible／historical，CH-18 的 preflight feedback 已由 PC-25 承接，HC-18 為 historical human boundary。下列為 PC-25 前 historical route，不是 current route：

```text
PC-24 transition-count amendment (completed／historical) → PR-24 re-review (completed／approved／historical) → IM-24 (completed／historical) → TE-21 (completed／approved／historical) → RV-21 (completed／approved／historical) → DL-20 (`67695b5` completed／visible／historical) → CH-18 (needs-rework／historical) → HC-18 (pending／historical)
```

BDat `PRRT_kwDOUFu0Cc6lBDat` 的既有 planning amendment、layout-only expansion 與其 completed／approved review 均為
historical；PC-24 transition-count amendment 與 PR-24 re-review 均已 completed／approved／historical，IM-24 completed／historical，TE-21 completed／approved／historical，RV-21 completed／approved／historical，DL-20 `67695b5` completed／visible／historical，CH-18 needs-rework／historical，HC-18 pending／historical。
finding 已由 source 唯一對應為 11 states／11 transitions 的 bounded
projection correction。`refresh-success-result` 保留 ID 與 `from: start-finish`，只將 `to` 由 `resend` 改為
既有 `receive`，label 由 `成功結果回到流程` 改為精確 `更新結果經 AuthRequester 回到流程`。`refresh-failure-terminal`
保留 ID，只將 `from/to` 由 `start-finish → receive-finish` 改為既有 `receive → resend`，並設定精確 label
`更新成功：允許一次重試`；它不再是 external→terminal edge。這使 external update-results 只返回既有
`AuthFlow receive` policy input，且僅既有 policy 導向既有 terminal 或 one-time retry。

僅三個 state text field 可變：`start-finish.sublabel` `更新失敗時終態` → `更新結果待回傳流程`；
`receive.sublabel` `正常／首次 401 的資格判斷` → `正常回應／首次 401／更新結果`（既有 `label: 回應策略` 與
`tag: 僅限 AuthFlow` 保留）；`receive-finish.tag` `正常／不具資格／第二次 401` →
`正常／不具資格／第二次 401／更新失敗`。`terminal-decision` 必須保留 ID、既有 `receive → receive-finish` 端點
及所有現有設定。除兩個列名 edge 與三個列名 fields，所有 lifecycle edge identity/from/to/label、state ID/count、
policy、event、API、payload、ownership、retry-policy capability 必須 byte-identical；禁止 add/remove state 或 edge。

此次唯一新增 geometry/layout allowlist 為 `receive-finish.width` `110 → 140`；
`refresh-success-result.toSide` `right → top`、`via` 精確為 `[[220,479],[220,220],[556,220]]`、`labelAt`
精確為 `[430,210]`；`refresh-failure-terminal.toSide` `right → top`、移除 `via` 而 route straight、`labelAt`
精確為 `[556,380]`。不改既有 11 state IDs／11 transition IDs、edge semantics／`from/to`／labels，或 state policy、
API、payload、ownership、retry invariants。驗收必須是 9/9、0 errors、0 warnings、`properCrossings`、
`ambiguousCorridors` 與 label issues 均為 0、minimum clearance 至少 16.1px，並標準 deliver／visual；component candidate
維持不動。

BDaw `PRRT_kwDOUFu0Cc6lBDaw` 僅允許 component raw-response last route points 從
`[972,610] → [972,509] → [960,509]` 變為 `[972,610] → [972,540] → [954,540]`。edge semantic label/endpoints、
boxes、ownership 與 legacy Model A edge 均 byte-identical。

IM-24 allowlist 僅為四份 formal artifacts；lifecycle JSON、existing sibling generated HTML、standard producer receipt
與 existing artifact-local visual evidence sidecars（先 discover exact current sibling names，不 invent name）；component
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/scene.js`、其 `index.html` 與
existing local evidence。其餘 diagrams/docs/Swift/OAuth/producer/tests/未列 path ReadOnly。
TE-21 必須獨立驗證 lifecycle validate/deliver 9/9、0／0、repository-relative receipt source/HTML hash、four viewport/
light-dark pass；component validate/build/enhance/a11y/temporary rebuild/visual、exact route 與 no-drift。RV-21 只在
TE-21 approved 後審查。DL-20 只在 TE-21／RV-21 approved 後 single-topic commit + normal push existing PR branch；visible
後 CH-18 只處理 exact 12 IDs：`PRRT_kwDOUFu0Cc6knaR9`、`PRRT_kwDOUFu0Cc6knaSA`、
`PRRT_kwDOUFu0Cc6knhr9`、`PRRT_kwDOUFu0Cc6knhsB`、`PRRT_kwDOUFu0Cc6knhsF`、`PRRT_kwDOUFu0Cc6koqlS`、
`PRRT_kwDOUFu0Cc6kqRi3`、`PRRT_kwDOUFu0Cc6kqRi9`、`PRRT_kwDOUFu0Cc6k_x2f`、`PRRT_kwDOUFu0Cc6lAdHo`、BDat、BDaw。
BDat／BDaw direct resolve；`PRRT_kwDOUFu0Cc6knaR9` comment then resolve；其餘 9 fixed IDs direct resolve。重抓未知 feedback
即停 HC-18；不 merge/release。

### PC-25 — Planning-State Historicality Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

這是 human 授權、只寫四份 formal planning artifacts 的三項 state-sync rework。它只把 TC-12 的 P6／PC-24
current-route 誤述、HC-12 的過期 human-boundary 表述，以及 ledger 的 CH-17／HC-17 historicality 與 current gate
收斂為同一歷史鏈；不改 architecture contract 或任何圖表／runtime contract。

唯一 current route 為：

```text
PC-25 (completed／historical) → PR-25 (completed／approved／historical) → IM-25 (completed／historical) → TE-22 (completed／approved／historical) → RV-22 (completed／approved／historical) → DL-21 (`df18404` completed／visible／historical) → CH-19 (active) → HC-19 (pending／human boundary)
```

HC-12 只保留為 PC-19 前 historical snapshot；CH-17／HC-17、CH-18／HC-18 與 PC-24 亦只保留為
historical lineage。PR-25 已 completed／approved／historical。IM-25 已 completed／historical，並確認三項
historicality/current-gate scope 不需要額外 artifact 變更。TE-22／RV-22 均已 completed／approved／historical；DL-21 `df18404` 已 completed／visible／historical；CH-19／HC-19 已由 PC-26 承接為 historical。

### PC-26 — Refresh Policy-Return and Raw-Response Projection Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-26 是 human 授權的三個 source、最小表達回修，並取代本文件所有較早的 PC-25
「current route」snapshot。它只讓圖表直接反映已採用的 Model C：
`AuthFlow` 只作 policy/state decision、`AuthRequester` 解讀並派送 semantic action、`Requester` 維持 raw
HTTP I/O。不得改變 retry policy、original-request ownership、deferred representation/API、payload、failure
surface 或任何 product Swift contract。

| Finding | Source-only semantic allowlist | Fixed invariant |
| --- | --- | --- |
| LC-26 lifecycle | 11 states 不變；11→12 transitions。`refresh-decision: receive → initial-send`，label `首次 401：具資格才可更新（交回 AuthRequester）`；新增唯一 `refresh-dispatch: initial-send → start-finish`，label `派送至延後確定的憑證更新 I/O 邊界`；`refresh-success-result: start-finish → receive` 與 `更新結果經 AuthRequester 回到流程` 不變。 | `AuthRequester` 只派送、不執行/不擁有 refresh I/O；其他 state/edge IDs、fields、semantics、policy、ownership、retry 不變。 |
| ST-26 state | 11 states 不變；11→12 transitions。`response-policy.sublabel = 初始／重試 HTTPResponse／更新結果的流程狀態判斷`；新增唯一 `refresh-result: refresh-boundary → response-policy`，label `更新結果交回 AuthFlow 策略`；`refresh-success: response-policy → waiting-for-retry-response` 保留 `更新成功：一次重試許可`；`refresh-failure: response-policy → refresh-failed`，label `更新失敗：終態`。 | refresh outcome 先回 `AuthFlow` policy 才分支；no receive→retry shortcut、first-401/ineligible/second-401 topology 與 exactly-one retry 不變。 |
| NR-26 normal | 僅 `response-policy-input.label: 轉交回應語意 → 轉交原始 HTTPResponse`；保留 ID、`auth-requester → auth-flow`、`y: 478`、variant。 | 12 messages、participants、activations、其他 message fields及 caller terminal return 不變。 |

layout-only fields 只可在 lifecycle 的 `refresh-decision`、`refresh-dispatch`、`refresh-success-result`，以及 state 的
`refresh-result`、`refresh-success`、`refresh-failure` 上變更：`route`、`fromSide`、`toSide`、`via`、`labelAt`。
所有非表列 state／transition/message fields 均 ReadOnly。

### PC-26 Layout Amendment — Exact Presentation Allowlist

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-26 semantic contract 不變。本 amendment 只允許 state presentation geometry；所有 endpoints、labels、
variant 與 semantic fields locked，仍保留 11 個 state ID、12 個 transition ID、policy/ownership/API/payload/retry
invariants。Implementer 只可套用以下 exact values：

- states：`response-policy.width=190`、`response-policy.yOffset=74`、`first-401.yOffset=82`、
  `refresh-boundary.yOffset=82`、`waiting-for-retry-response.yOffset=82`。
- `receive-response`：`fromSide: bottom`、`toSide: left`、`via: [[402,210],[440,210],[440,231]]`。
- `first-401-decision`：`fromSide: left`、`toSide: top`、`via: [[440,231],[440,320],[402,320]]`、
  `labelAt: [420,340]`。
- `dispatch-refresh`：`fromSide: bottom`、`toSide: bottom`、`via: [[402,434],[556,434]]`、
  `labelAt: [540,446]`。
- `ineligible-terminal`：維持 `route: straight`、`labelAt: [250,440]`。
- `refresh-result`：維持 `route: straight`、`fromSide: top`、`toSide: bottom`、`labelAt: [365,290]`。
- `refresh-failure`：`fromSide: left`、`toSide: left`、
  `via: [[440,231],[440,300],[320,300],[320,542],[480,542],[480,479]]`、`labelAt: [250,410]`、
  `route = unset/auto`（不是 `bottom-channel`）。
- `refresh-success`：`fromSide: right`、`toSide: right`、`via: [[790,231],[790,389]]`、
  `labelAt: [820,290]`。
- `retry-response-policy`：`fromSide: left`、`toSide: top`、`via: [[630,389],[630,170],[556,170]]`。
- `second-401-terminal`：`fromSide: bottom`、`toSide: right`、`via: [[556,320],[850,320],[850,479]]`。

Planner read-only diagnostics: showcase 9/9、0 errors、0 warnings、0 crossings、0 ambiguous corridors、minimum
label clearance 5px. These diagnostics do not replace the independently gated implementation/test/review evidence.

### PC-26 Route Clarification — `refresh-failure.route`

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

TE-23 read-only 發現的唯一 ambiguity 是：HEAD baseline 使用 `refresh-failure.route = bottom-channel`，但已驗證
9/9 candidate 與 current source 使用 `unset/auto`。本 clarification 只將
`refresh-failure.route = unset/auto`（不是 `bottom-channel`）寫成 explicit lock；其餘 exact geometry、endpoints、
labels、policy、ownership、API、retry、11 states 與 12 transitions 完全不變。這是重現 validated candidate 所需的
presentation field，非 topology 或 semantic change。

PC-26 route clarification 與 PR-26 re-review 均已 completed／approved／historical，且只確認 planning
contract，不修改 diagram/source/output/evidence、Git 或 GitHub。IM-26 no-op resume、TE-23 re-test 與 RV-23
independent review 均已 completed／approved／historical；DL-22 `6372a2a` 已 completed／visible／historical，CH-20
為唯一 active gate。

**Written/Modify**：四份 formal artifacts，以及三份 listed Archify source 的 existing sibling generated HTML、
standard producer receipt、artifact-local visual evidence；不新增 path。**ReadOnly/Out-of-Scope**：401 sequence、
component/package canvas、long-lived docs、Swift/tests/OAuth/producer、all other diagrams and evidence、Git/GitHub、
merge/release。**Deleted**：無。

TE-23 需獨立驗證 exact allowlist（包括 `refresh-failure.route = unset/auto`）、兩個 lifecycle/state 11-state/12-transition count、normal 12-message count、
no-drift、showcase 9/9/0/0、standard source-matched/repository-relative receipt、四個 desktop visual pass與 manual
light/dark inspection。state 既有 1035／1109／1109、2048 pass exact desktop-containment non-pass 不得被改寫為 pass。

下列為 PC-29 initial planning／initial review 後、已被 layout amendment supersede 的 historical snapshot，不是 current route：

```text
PC-26 route clarification (completed／historical) → PR-26 re-review (completed／approved／historical) → IM-26 (completed／historical) → TE-23 (completed／approved／historical) → RV-23 (completed／approved／historical) → DL-22 (`6372a2a` completed／visible／historical) → CH-20 (active) → HC-20 (pending／human boundary)
```

PC-25 route、CH-19=`needs-rework`、HC-19=`pending` 都是 historical。PC-26 route clarification、PR-26 re-review、
IM-26、TE-23 與 RV-23 均 completed／approved／historical；DL-22 `6372a2a` 已 completed／visible／historical，
CH-20 active。

### PC-27 — Lifecycle Dispatch Exclusivity and Transport Terminal Rework

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-27 只 materialize 已授權的 lifecycle projection；不重開 Model C、retry policy、`AuthFlow` policy ownership、
original-request ownership、deferred refresh boundary、API、payload 或 failure contract。它選擇**互斥條件**，不新增
專用 `AuthRequester` state 或 runtime role：`initial-send` 仍為既有 state ID，僅能依當前 semantic action 擇一送出
retained original request 或派送 refresh I/O。

| Item | Exact allowed source mutation | Invariant |
| --- | --- | --- |
| `initial-send` | `width: 150`；`sublabel: 保有原始請求；依語意擇一派送`；`tag: 目標所有者／互斥派送` | 11 states 不變；不建構 request、不執行 I/O；同次 decision 僅能走 `client-sends-initial-request`／`refresh-dispatch` 其一。 |
| `refresh-dispatch` | 保留 `initial-send → start-finish`、security variant 與既有 `fromSide`／`toSide`／`via`；label=`更新語意：派送至延後確定的憑證更新 I/O 邊界`，`labelAt: [130,300]` | `refresh-decision` 仍為 `receive → initial-send`；dispatch 不送 original request，不執行 refresh I/O。 |
| `requester-failure` | 保留 state ID/type/lane/col/step/`yOffset`；`width: 150`、label=`HTTPClientError 終態`、sublabel=`Requester 傳輸失敗；非 AuthFlow 策略`、tag=`既有 Model A 失敗路徑` | 不增加 failure surface；legacy node 可達，但不成為 AuthFlow policy 或 retry path。 |
| `transport-http-client-error` | 新增唯一 `client-send → requester-failure` transition：label=`傳輸 HTTPClientError`、`fromSide: top`、`toSide: right`、`via: [[710,100],[850,100],[850,339]]`、`labelAt: [850,220]` | 12→13 transitions；`requester-failure` exactly one inbound/zero outbound，transport error 不回流至 flow。 |

除了上表，lifecycle 的 11 state IDs、既有 12 transition IDs 及全部未列 fields 一律 ReadOnly；特別是
`refresh-success-result`、`refresh-failure-terminal`、`terminal-decision`、`client-sends-retry`、`receive-finish`
terminal semantics 與 exactly-one retry 不得漂移。所有 state/transition label、endpoints、geometry 與 count 由
TE-24 依 exact source 驗證。

### PC-27 Layout Amendment

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

此 amendment 只覆寫上表中的 layout values，不覆寫其 semantics。精確 allowlist 為
`meta.viewBox: [1040,640] → [1000,640]`、`start.width: 115 → 94`、`client-send.width: 118 → 94`、
`requester-failure.yOffset: -140 → -100`、`refresh-dispatch.labelAt: [130,300] → [340,300]`、
`transport-http-client-error.via: [[710,100],[850,100],[850,339]] → [[710,100],[850,100],[850,379]]`、
`transport-http-client-error.labelAt: [850,220] → [920,220]`。`initial-send.width`、`requester-failure.width`
均固定為 `150`。11 states、13 transitions、所有 IDs、endpoints、semantic labels、ownership、retry、API、payload
及其餘 nonlisted fields 維持不變。

Planner 的 read-only candidate diagnostic 為 showcase 9/9、0 errors、0 warnings、0 crossings、0 collisions，
minimum label clearance = 7.3。temporary visual command 的 SIGABRT 並未產生 delivery evidence；故這不是 visual
pass，也不放寬 IM-27 的正式 deliver／receipt／四 viewport visual evidence requirement。PC-27 layout amendment 與
PR-27 re-review 均 completed／approved／historical；IM-27、TE-24、RV-24 均已 completed／approved／historical；DL-23 已以
`fc37f04` completed／visible／historical，CH-21 是唯一 active gate，HC-21 維持 pending human boundary。

**Written/Modify**：四份 formal planning artifacts；lifecycle JSON、其 existing sibling HTML、standard
producer-generated receipt 與 artifact-local visual sidecars。**ReadOnly/Out-of-Scope**：normal/state/401/component/
package artifacts、long-lived docs、Swift/tests、OAuth、producer、Git/GitHub、merge/release 與未列 path。
**Deleted**：無，且不得 rename/move。normal/state 僅作 evidence verification，不重建或寫入。

**TE-24 TestCase**：lifecycle standard validate/deliver 為 showcase 9/9、0 errors、0 warnings，receipt source-match
且所有 metadata repository-relative、無絕對路徑；lifecycle 1440×900、1600×1000、1920×1080、2048×1320 containment
均 pass，並 manual inspect light/dark。normal 的四 viewport 亦均 pass、manual light/dark；state 的四個 exact result
為 1440=1035、1600=1109、1920=1109 containment non-pass 與 2048 pass，這是既有 accepted limitation，不得改寫為 pass。

本節 supersede 上方所有將 CH-20 稱為 current/active 的歷史 snapshot。PC-26 至 DL-22 `6372a2a` 是 historical；
CH-20=`needs-rework`、HC-20=`pending` 亦 historical。唯一 current route：

```text
PC-27 original contract (completed／historical) → PC-27 layout amendment (completed／historical) → PR-27 re-review (completed／approved／historical) → IM-27 (completed／historical) → TE-24 (completed／approved／historical) → RV-24 (completed／approved／historical) → DL-23 (`fc37f04` completed／visible／historical) → CH-21 (active) → HC-21 (pending／human boundary)
```

DL-22 已依已完成的 IM-26／TE-23／RV-23 approval 建立並 push bounded topic commit；CH-20 現在重新取得
thread state，未知 feedback 停止並交還 human。不得 merge/release。

## Validation and Gate Contract

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

1. Plan-Creator 完成四份 artifacts 後，必須交由獨立 Plan-Reviewer；Plan-Creator
   不得自判 `approved`。
2. PR-03 是 PR-01／PR-02 rework 後的 final replacement approval gate。只有 PR-03
   明示 `approved` 才滿足本 topic 的「Plan Review approved」條件，並授權 IM-01
   寫入 long-lived allowlist。
3. architecture-canvas artifact 必須依 skill 執行 validate、build，並人工檢閱 exact
   light/dark output。
4. 每份 Archify artifact（包含重新設計後的 state）必須先以 showcase quality validate（完整
   9/9 checks、0 errors、0 warnings），再 standard `deliver`；delivery 會 freeze exact source/output。
   之後須以 repository-root visual-check 取得 evidence，並人工檢閱 exact delivered light/dark
   output。state 只保留既有 desktop containment exact non-pass，不存在 alternate-materialization
   delivery path。
5. TE-01 是 historical `needs-rework`，不是 delivery entry condition。其唯一
   independent replacement verification gate 為 TE-02：獨立 Tester 必須驗證
   changed-path allowlist、`git diff --check`、legacy/target wording、OAuth isolation、
   diagram receipts 與 exact delivered visual evidence，並明示 TE-02 = `approved`。
   此 `approved` 等價於本 topic 的 verification pass。
6. TE-03 是 IM-02 diagram-localization correction 的 independent re-test，必須明示
   TE-03 = `approved`；它不取代 TE-02 作為 TE-01 的唯一 replacement verification
   gate。
7. TE-02／TE-03 `approved` 不改變 AuthFlow state diagram human accepted desktop containment
   limitation 的 non-pass truth；它不得被描述為 visual-check pass。RV-01 的
   `needs-rework` 只回交 verification/delivery wording；Plan-Creator correction 後，
   PR-04 independent Plan-Reviewer re-review 必須 `approved`，才可進入 RV-02。
8. RV-02 的獨立 Reviewer 必須判定 scope／contract／workflow drift，並明示
   RV-02 = `approved`。本 topic 的「無重大問題」只定義為 TE-02 = `approved`、
   TE-03 = `approved` **且** RV-02 = `approved`；不得以單一 check 或未解決 finding
   取代此 gate。
9. 只有上述「無重大問題」條件成立，DL-01 才可依 user-authorized topic workflow 與
   `git-commit-convention` 完成 topic commit、push 至 PR #37；該 PR 現為 OPEN、ready for
   review，這是已完成的 historical delivery gate。
10. PR #37 是 **OPEN、ready for review** 的既有 PR，planning contract 不得改變其 status。
    RV-03 `needs-rework` 的 replacement workflow 是 PC-07 Plan-Creator amendment → PR-07
    independent Plan Review → IM-04 Implementer → TE-05 independent Tester → RV-04
    independent Reviewer → DL-03 topic commit/push to the existing ready-for-review PR →
    CH-02 reply/resolve → HC-02 human review。CH-02 僅可在 TE-05/RV-04 approved 與
    DL-03 completed 後執行：T06 依 supplied evidence
    reply+resolve；T01/T02/T03/T05/T07/T08/T09 要等 corrected delivery visible；T04 要等
    reproducibility fix visible。這是 PC-08 前的 historical route；delivered head 只記錄
    DL-03 = `active`，不得現在 resolve，且不得 merge、release 或開始 Swift implementation。
11. delivered head 的 workflow ledger 只記錄 RV-04 = `approved`、DL-03 = `active`；它不
    把 push、thread closure 或 HC-02 寫成已完成。PC-08／PR-08 是 historical correction lineage；
    PC-09／PR-09／IM-07 blocked 是 standard-delivery limitation 的歷史 evidence，不得回寫為
    pass 或 delivery approval。
12. PC-10／PR-10／IM-08 blocked 是 historical failed alternate-materialization route，不得被回寫為
    delivery pass；其 downstream TE-07 至 HC-04 未前進，現由 PC-11 replacement route supersede。
13. PC-12／PR-12 與 IM-09 blocked 是 historical source/output-separation route。PC-13 只可將 retry
    permission 從 node 改為進入 waiting-for-retry-response 的 transition／event，並 supersede
    alternate HTML materialization 與 prior state-node formulation；不得改變任何 policy semantics。PR-13
    必須由 independent Plan-Reviewer 審查 IM-11 state-only、IM-10 source-ReadOnly、TE-09
    verification-only、unproven checksum observations與 all-existing gates；`approved` 才可依序進入
    IM-11、IM-10。
14. IM-11 只可修改 `auth-flow-state` source/HTML/standard receipt/visual evidence，並將 retry
    permission 表達為進入 waiting-for-retry-response 的 transition／event（非 node），以及必要的
    topology/layout presentation 調整以消除 `[850,307]`。它必須保留 locked semantics，並取得 normal
    standard validation/delivery evidence。IM-10 在 IM-11 completed 後，
    不得修改 source：401 必須 standard validate → deliver → visual-check，取得 source-match/
    9-of-9/0-error/visual-pass evidence；package 必須 validate → temporary build → enhance → verify
    materialize `index.html`，取得 reproducibility/accessibility/source-output consistency；BUILD.md／
    enhancement script ReadOnly。任一項不能完成即 `blocked` 交還 human。
15. 只有 IM-11 **及** IM-10 completed 且 state/401/package evidence 齊備，TE-09 才可開始，且只可
    verify、不得生成 output/evidence。其後 route 固定為 TE-09 → RV-09 → DL-07 → CH-06 → HC-06；
    DL-07 只在 TE-09/RV-09 `approved` 後 commit/push，CH-06 只在 corrected delivery visible 後
    重新取得並處理 thread，PR status 不變。
16. IM-10 的 package materialization 已通過（5 bands／15 boxes／22 edges、0 errors、0 warnings、
    build→enhance→verify、byte-identical output），保留為有效 evidence，不得重做。401 source ReadOnly
    delivery雖為 9/9、0 errors、0 warnings、source-matched，fresh visual-check 的 1440×900 = 1001、
    1600×1000 = 1073 卻失敗，且不屬於 state exception；IM-10 因此是 historical blocked route。
17. PC-14 只可建立 bounded `401-refresh-retry` layout/source repair contract，且明定這不是 new exception。
    PR-14 必須獨立確認只有 IM-12 可 supersede IM-10 的 **401 source ReadOnly** 限制；package passed
    evidence、BUILD.md、enhancement script與其他 ReadOnly boundary不變。`approved` 才可進入 IM-12。
18. IM-12 只可修改 401 diagram source/layout及其 required delivery evidence；必須保留 caller →
    AuthRequester entry、AuthRequester → Auth per-execution flow request、Auth → AuthRequester flow return
    後才開始 request-less exchange，且 original request 不提供給 Flow。first-401 ineligible terminal、
    eligible refresh、refresh result 回 policy、refresh-success-only exactly-one retry、waiting → response-
    policy normal-success／second-401 split及 no receive→retry shortcut均不得變動。IM-12 必須 standard
    validate 9/9、0 errors、0 warnings、deliver/source-match、1440×900／1600×1000／1920×1080／2048×1320
    全數 visual pass、manual light/dark。route 為 PC-14 → PR-14 → IM-12 → TE-10 → RV-10 → DL-08 →
    CH-07 → HC-07；TE-10 只 verify，絕不生成 output/evidence。
19. PC-15 狹義 supersede IM-12 的「所有副標籤置於標頭」表述限制：參與者副標籤表述只可移至
    圖外脈絡／說明區，並非 new visual exception。PR-15 必須確認 17 sequence messages、flow contract、
    retry policy、participant/component identities 與 package passed evidence 不變；`approved` 才可進入 IM-13。
20. IM-13 只可修改 `401-refresh-retry` 的參與者標頭／圖外脈絡表述及 required delivery evidence。
    每個移出標頭的副標籤必須於圖外脈絡／說明區保留可對照的說明意義，且不得 invent ownership、
    capability、runtime behavior或 architecture decision。caller → AuthRequester、AuthRequester → Auth、
    Auth → AuthRequester prefix、request-less exchange及 Flow 無 original-request access不變；first-401
    ineligible terminal、eligible refresh、refresh result→policy、success-only retry、waiting→response-policy
    split及 no receive→retry shortcut不變。IM-13 必須 standard validate 9/9、0 errors、0 warnings、
    deliver/source-match、1440／1600／1920／2048 visual pass及 manual light/dark。route 為 PC-15 → PR-15 →
    IM-13 → TE-11 → RV-11；TE-11 只 verify。RV-11 `needs-rework` 後，不得前進至原本未開始的
    DL-09 → CH-08 → HC-08。
21. RV-11 `needs-rework` 僅要求：component-dependency canvas 不得將 selected／decorated request
    preparation 指派給 `AuthRequester`，以及 ledger 必須把 RV-11 `needs-rework` 視為 current rework
    truth。這是直接交回 IM-15 的最小回修，不建立新的 planning cycle。TE-12 initial 已 `needs-rework`，
    IM-15 rework 已完成、TE-12 re-test 已 `approved`；以下為 PC-18 前 historical snapshot：TE-14 已 `approved`，當時 gate 為 RV-14；IM-15 只可修改 canvas `scene.js`、generated `index.html`、artifact-local validation／
    visual evidence 和 actual-step ledger evidence；其後 route 固定為 IM-15 rework → TE-12 re-test（approved）→
    TE-14（approved）→ RV-14（approved）→ DL-12（completed）→ CH-11（completed）→ HC-11（needs-rework）。DL-12 只在 RV-14 approved 後 commit/push；CH-11 只在 corrected delivery visible 後重新取得
    exact thread evidence，必要事項修正後 resolve，非必要事項留言後 resolve；PR status 不變。

## TestCase

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

- **TC-01**：future implementation 的 flow unit test 證明 normal response terminal、
  eligible refresh-capable flow 的 first 401 requests refresh、refresh success permits
  original retry、second 401 stops、ineligible flow／refresh failure terminal；本 topic 不新增
  此 Swift test。
- **TC-02**：future compile/API test 證明 `AuthFlow` 無 arbitrary endpoint/request
  construction authority；若未來不採納此限制，必須另開 topic 明確重啟 architecture
  decision。
- **TC-03**：documentation test 檢查 matrix、sequence 和 state diagram 對 decision、
  I/O、state、original request ownership 一致。
- **TC-04**：changed-path／ReadOnly test 檢查無 Swift、package、OAuth dual-client
  lifecycle 或 historical topic 變更。
- **TC-05**：diagram validation/visual evidence 滿足本文件的 skill gate，且 no
  artifact.cafe publication。
- **TC-06**：canonical matrix、lifecycle、401 與 state 的 source/generated evidence
  一致表達 `Auth` factory 先建立 per-execution flow、沒有 request-payload flow exchange
  或 receive→retry shortcut。
- **TC-07**：`BUILD.md` 固定作者參數可重現 package canvas 的已交付繁中 HTML；enhancement
  script 與其他 build semantics 不變。
- **TC-08**：lifecycle、401、state 說明性文案為繁體中文，以「request 資料」、「資格」、
  「延後確定」、「更新成功」取代 payload、eligibility、deferred、refresh-success 的解釋；
  英文限於 identifier。
- **TC-09**：PR #37 維持 OPEN、ready for review；PR-07 至 CH-02 是 historical route，
  不得以其 DL-03／CH-02 status 略過 current PC-08 replacement route。
- **TC-10**：401 sequence 的 factory prefix 從 caller original-execution entry 開始，依序
  要求並回傳 per-execution flow，之後才進行無 request payload 的 semantic exchange；這不授予
  `AuthFlow` original-request access。
- **TC-11**：state diagram 的 retry permission 是進入 waiting-for-retry-response 的
  transition／event、不是 lifecycle node；waiting state 將 retry response 交給 response policy，
  再區分 normal-success 與 second-401 terminal，沒有 shortcut。
- **TC-12**：package canvas 只保留 `AuthRequester` 的 original-request ownership／semantic
  interpretation，不指派 selected／decorated preparation；其 owner／representation 未決。
- **TC-13**：current comment preflight = `needs-rework`、RV-04 approved／DL-03 active 的
  historical ledger、PC-10／PR-10／IM-08 blocked alternate history與 IM-09 blocked history均如實保留；
  它們均非 current route，thread 只在 CH-11 重新取得 evidence。
- **TC-14**：state redesign 只可將 retry permission 改為進入 waiting state 的 transition／event並調整
  相連 presentation，卻同時保留 first-401
  ineligible terminal、eligible refresh、outcome 回 Flow policy、refresh-success-only exactly-one retry、
  retry waiting state/responsive-policy terminal split，且無 receive→retry shortcut。
- **TC-15**：`[850,307]` 必須被消除；state 以 normal standard validate 9/9、0 errors、0 warnings、
  deliver/source-matched receipt、visual evidence/manual inspection 證明，不再以 alternate receipt
  或 crossing accepted non-pass 交付。
- **TC-16**：desktop containment 1035／1109／1109、2048 pass 維持 exact distinct non-pass，不稱
  visual pass，也不放寬其他 diagram/canvas、scope、diff、delivery、PR status 或 thread gates。
- **TC-17**：401 sequence 仍為 standard showcase 9/9、normal deliver、visual pass；package canvas
  仍為 validate/build/reproducibility/accessibility。任何其他 failure 均不得以 state scope expansion
  豁免。
- **TC-18**：IM-10 source ReadOnly；401 的 current JSON／HTML hashes 和 package scene／index hashes
  僅是 unproven observations，重新 materialize 後必須以 receipt/build evidence 證明 source-output
  relation。TE-09 只驗證，不得重新 build、deliver 或寫 evidence。
- **TC-19**：PC-14／PR-14 只授權 IM-12 的 401 layout/source repair，不是 new exception；IM-10 的
  package passed evidence 維持有效且不重做，所有其他 ReadOnly boundary 不變。
- **TC-20**：IM-12 的 401 source/output/evidence 保留 caller/AuthRequester/Auth factory prefix、
  request-less exchange與 Flow 無 original-request access，並保留 ineligible/eligible、refresh-result
  policy return、success-only retry/waiting-response-policy/no-shortcut semantics。
- **TC-21**：IM-12 standard source-matched delivery 為 showcase 9/9、0 errors、0 warnings，且
  1440×900、1600×1000、1920×1080、2048×1320 全數 visual pass、manual light/dark；
  PC-14 → PR-14 → IM-12 → TE-10 → RV-10 → DL-08 → CH-07 → HC-07 是 historical route，不是 current route。
- **TC-22**：IM-13 只把參與者副標籤表述從標頭移至圖外脈絡／說明區；17 messages、factory prefix、
  request-less exchange、Flow original-request boundary、retry policy 和 component identities 均不變。
- **TC-23**：每個移出的副標籤在圖外脈絡／說明區保留可對照的說明意義，不 invent ownership、capability、
  runtime behavior 或 architecture decision；此為 presentation change，不是 exception。
- **TC-24**：IM-13 standard source-matched delivery 為 9/9、0 errors、0 warnings，1440×900、1600×1000、
  1920×1080、2048×1320 全數 visual pass、manual light/dark；RV-11 `needs-rework` 後，未開始的
  DL-09 → CH-08 → HC-08 不再是 current route。
- **PM-01**：formal artifacts 的 current status 是 DL-12／CH-11 completed、HC-11
  `needs-rework`、PC-18／PR-18／IM-18／TE-15／RV-15／DL-13 completed、CH-12 completed（四個 thread 已
  resolved、無未分類 feedback）、HC-12 `needs-rework` historical snapshot；`f277ac4` 與 `d2cefd4` 僅為已交付歷史，
  PC-19 至 DL-14 已 completed、CH-13 = `needs-rework`、HC-13 = `pending` 亦為 historical；PC-20 至
  CH-14=`needs-rework`、HC-14=`pending`，PC-21 至 DL-16 `bccc183` completed／visible、CH-15=`needs-rework`、
  HC-15=`pending` 均為 historical。DL-18 `51ae037` completed／visible、CH-16 needs-rework、HC-16 pending 亦為 historical。PC-24／CH-18 route 亦已由 PC-25 承接為 historical。唯一 current route 為 PC-25（completed／historical）→ PR-25（completed／approved／historical）→ IM-25（completed／historical）→ TE-22（completed／approved／historical）→ RV-22（completed／approved／historical）→ DL-21（`df18404` completed／visible／historical）→ CH-19（active）→ HC-19（pending／human boundary）。
- **PM-02**：state receipt 僅能由 canonical-containment producer 以 repository-relative
  arguments 標準產生；source／HTML SHA-256、9/9、0 errors、0 warnings 與 repository-relative
  metadata 都匹配，exact 1035／1109／1109、2048 pass 維持 non-pass truth。
- **PM-03**：component canvas 的 `AuthRequester → HTTPRequest` edge 明示 legacy Model A
  編譯期 type dependency，並不表示 Model C request preparation、construction、ownership transfer 或 I/O。
  canvas source/output/rebuild/accessibility evidence 必須一致。
- **PM-04**：401 唯一新增 message 是 terminal `AuthRequester → caller` final response；caller
  activation 覆蓋 return，message count 由 17 變 18，其他 locked semantics、source-match、9/9 與四 viewport
  visual pass 維持。
- **PM-05**：PR-18／TE-15／RV-15 已 `approved`；DL-13／CH-12 已 completed，四個 thread 均已
  resolved、無未分類 feedback。HC-12 當時因 P2-01／P2-02 為 `needs-rework`，PC-18 route 為 historical；
  PC-19 route 已在 CH-13 = `needs-rework`、HC-13 = `pending` 停止；PC-20 已在 DL-15 completed、CH-14
  needs-rework、HC-14 pending 後 historical；DL-16 `bccc183` completed／visible、CH-15 needs-rework、HC-15 pending
  亦為 historical；DL-18 `51ae037` completed／visible、CH-16 needs-rework、HC-16 pending 亦為 historical；PC-24／CH-18 route 亦已由 PC-25 承接為 historical；PC-25（completed／historical）→ PR-25（completed／approved／historical）→ IM-25（completed／historical）→ TE-22（completed／approved／historical）→ RV-22（completed／approved／historical）→ DL-21（`df18404` completed／visible／historical）→ CH-19（active）→ HC-19（pending／human boundary） 是唯一 current route。
- **P2-01**：`PRRT_kwDOUFu0Cc6knaR9` 要求 package canvas 的 `AuthRequester → HTTPRequest` edge
  明示 legacy Model A compile-time request-type dependency，非 Model C preparation／construction／ownership／
  dataflow／I/O。
- **P2-02**：`PRRT_kwDOUFu0Cc6knaSA` 要求 state retry-response transition 與 normal-terminal edge
  只作 layout／route separation，避免假雙向箭頭，且 retry policy、state topology、contract 不變。
- **P3-01**：`PRRT_kwDOUFu0Cc6knhr9` 限定 normal selected／decorated representation 與 preparer 為
  deferred；`AuthRequester` 或新 role 均不得被指派。
- **P3-02**：`PRRT_kwDOUFu0Cc6knhsB` 限定 lifecycle refresh-failure terminal 為 neutral／generic、
  non-success-styled presentation，semantics 不變，且不得新增 node、payload 或 API。
- **P3-03**：`PRRT_kwDOUFu0Cc6knhsF` 限定 401 Requester initial／retry activation presentation split，
  18 messages 與 factory／no-payload／retry semantics 不變。
- **P3-04／P3-05**：state `PRRT_kwDOUFu0Cc6knaSA`、package `PRRT_kwDOUFu0Cc6knaR9` 僅 revalidate
  current source/output；不改 source，delivery visible 後才 reply／resolve；README／bounded-contexts conflict
  只作 comment disposition，並須確認 OAuth runtime description 與 Model C auth canonical conclusion 共存、沒有
  long-lived-doc architecture change。
- **P4-01**：`PRRT_kwDOUFu0Cc6koqlS` 僅 normal-request／auth-flow-lifecycle receipts 可重建；relative
  `--repo-root` standard deliver 必須保留 source/HTML byte identity，receipt 證明 hash、9/9、0／0與無 absolute path；DL-16
  必須 commit 並 normal push 至既有 PR branch，CH-15 只在 pushed commit 可見且 receipt evidence verified 後 reply／resolve。
- **P5-01**：`PRRT_kwDOUFu0Cc6kqRi3` 只修正 stale current claim/gate/route；保留 DL-16 `bccc183`、
  CH-15 needs-rework、HC-15 pending 的 dated historical evidence/closure。
- **P5-02**：`PRRT_kwDOUFu0Cc6kqRi9` 只允許 401 set 由 18 至 20 messages；18 existing IDs/semantics
  不變，只有兩則 mutually-exclusive guarded `AuthFlow → AuthRequester` terminals（ineligible/no refresh、
  refresh-failure/no retry），並禁止 caller failure return/payload/API/state node/transition/policy/ownership。

### PC-27 Historical-Route Supersession

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

本 technical spec 的 PC-27 exact lifecycle contract、artifact mapping 與 TE-24 TestCase 以本檔較前的
PC-27 section 為唯一準據。本節 supersede 本檔任何較早的 CH-20 active/current route snapshot：PC-26 至 DL-22
`6372a2a`、CH-20=`needs-rework` 與 HC-20=`pending` 全為 historical。唯一 current route：

```text
PC-27 original contract (completed／historical) → PC-27 layout amendment (completed／historical) → PR-27 re-review (completed／approved／historical) → IM-27 (completed／historical) → TE-24 (completed／approved／historical) → RV-24 (completed／approved／historical) → DL-23 (`fc37f04` completed／visible／historical) → CH-21 (active) → HC-21 (pending／human boundary)
```

### PC-28 — Shared Terminal Neutral Deferred Outcome

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-28 選擇最小的 neutral deferred terminal outcome，不新增 response terminal 或 deferred-failure
surface。IM-28 的唯一 lifecycle source mutation 為
`states[id=receive-finish].label: 終態回應 → 待定終態結果`。

`receive-finish` 的 ID、`type: neutral`、lane、col、`width: 140`、既有 `yOffset`（含 absent/default
表達）、sublabel 與 tag 均 locked。11 states、13 transitions、所有 transition ID/endpoints/labels/geometry
均 locked；尤其 `refresh-success-result: start-finish → receive`、
`terminal-decision: receive → receive-finish` 與
`transport-http-client-error: client-send → requester-failure` 均不可改動。這只中性化既有 shared terminal
presentation；不改 retry、policy owner、ownership、deferred I/O、API、payload、failure surface 或 transport terminal
semantics。

**Written/Modify**：四份 formal planning artifacts；existing lifecycle JSON、existing sibling generated HTML、
standard producer receipt、artifact-local visual sidecars。**ReadOnly/Out-of-Scope**：所有其他 diagrams/docs、
Swift/tests、OAuth、producer、Git/GitHub、commit/push、merge/release 與未列 paths。**Deleted**：無，不得
delete/rename/move。

**TE-25 TestCase**：diff 只能有該 label field；11/13 count 與所有 locked fields 必須相同。standard
`validate → deliver` 必須 showcase 9/9、0 errors、0 warnings，receipt source-matched、hash-consistent 且 metadata
全為 repository-relative、無本機 absolute path。lifecycle 1440×900、1600×1000、1920×1080、2048×1320 visual
check 均 pass，並 manual inspect exact delivered light/dark。任何 label visual issue 均 fail-closed，不得手改 HTML、
建立例外或擴張 scope。

本節 supersede 本檔所有較早將 CH-21 稱為 current/active 的 snapshot。PC-27 route 全為 historical：
CH-21=`needs-rework`、HC-21=`pending`。下列為 DL-24 visible 後的 PC-28 historical snapshot，已由 PC-29 承接並
supersede，不是 current route：

```text
PC-28 (completed／historical) → PR-28 (completed／approved／historical) → IM-28 (completed／historical) → TE-25 (completed／approved／historical) → RV-25 (completed／approved／historical) → DL-24 (`ac43495` completed／visible／historical) → CH-22 (當時 active／historical) → HC-22 (當時 pending／human boundary／historical)
```

### PC-29 — 401 互斥條件分支與原始回應轉交

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-29 只允許 `401-refresh-retry` 在既有 20-message sequence 內修正 control-flow projection 與 raw-response naming。PC-28 route（含 DL-24 `ac43495`）已 completed／historical；CH-22=`needs-rework`、HC-22=`pending` 亦為 historical。這不改 adopted Model C：`AuthFlow` 是唯一 policy/state/retry owner，`AuthRequester` 只解讀 semantic action 並轉交 raw response。

**Goal**：讓 `ineligible-terminal` 與 `refresh-failure-terminal` 成為明確停止的互斥 guard branches，而非垂直主線的前一步；首次／重試 response 以 raw `HTTPResponse` handoff 交給 `AuthFlow`。

**Non-Goal**：不增刪／重排 participants、messages、activations、states 或 transitions；不改 factory prefix、deferred boundary、original request ownership、caller return、retry policy、API/payload/failure surface、Swift/OAuth/producer/Git/GitHub。

**Written/Modify**：四份 formal planning artifacts；existing `401-refresh-retry.json`、existing sibling generated HTML、standard producer receipt、existing artifact-local visual sidecars。**ReadOnly/Out-of-Scope**：所有其他 paths。**Deleted**：無。

IM-29 只可保留 6 participant IDs、7 activation records、20 existing message IDs、5 segment records、`meta.viewBox: [1250,780]`，以及所有 endpoints/`y`/variants。lifecycle 11 states／13 transitions、state 11 states／12 transitions、normal 12 messages 均無 count impact 且 ReadOnly。

| Allowed field | Exact value |
| --- | --- |
| `messages[first-401].label` | `原始 HTTPResponse（首次 401）` |
| `messages[flow-receives-401].label` | `轉交原始 HTTPResponse（首次 401）` |
| `messages[refresh-decision].label` | `首次 401 的資格分流：具資格才可更新` |
| `messages[ineligible-terminal].label` | `〔不具資格〕終態；不派送更新` |
| `messages[dispatch-refresh].label` | `〔具資格〕派送待定的憑證更新` |
| `messages[refresh-failure-terminal].label` | `〔更新失敗〕終態；不取得重試許可` |
| `messages[retry-permission].label` | `〔更新成功〕一次重試許可` |
| `messages[retry-response].label` | `原始 HTTPResponse（重試結果）` |
| `messages[terminal-input].label` | `轉交原始 HTTPResponse（重試結果）` |
| `segments[0...4]` | geometry `[150,240]`、`[246,426]`、`[432,510]`、`[516,538]`、`[544,710]`；labels 依序為 `呼叫端入口與每次執行的流程建立`、`首次 401：〔不具資格〕終態／〔具資格〕更新（互斥）`、`〔具資格〕更新支線：派送與結果回傳`、`〔更新失敗〕終態支線（不重試）`、`〔更新成功〕一次重試支線與終態回傳` |
| `cards` | 僅新增兩張：`首次 401 的互斥 guard`，items 為 `〔不具資格〕只走 ineligible-terminal，於此終態。`、`〔具資格〕才可走 refresh-decision → dispatch-refresh；兩支不得連續發生。`；`更新結果的互斥 guard`，items 為 `〔更新失敗〕只走 refresh-failure-terminal，於此終態。`、`〔更新成功〕才可走 retry-permission → retry-original；只授予一次。`。 |

`flow-receives-401` 固定為 `auth-requester → auth-flow`、`y:356`、`security`；`terminal-input` 固定為同 endpoint、`y:636`、`security`。`ineligible-terminal`／`dispatch-refresh` 與 `refresh-failure-terminal`／`retry-permission` 的 endpoints、y、variants 保持 requirements PC-29 table 的 exact values。cards/segments/labels 只表達已鎖定 guard，不可創造新 runtime branch。任何 showcase 或 visual failure 都 fail-closed；不可自行改 geometry、count、HTML 或 receipt。

TE-26 必須依上述 exact values、20-message no-add/no-delete/no-reorder、two-card-only addition、raw-response handoff、guard terminal mutual exclusivity、source/output receipt/provenance 與 four viewport/manual light-dark 檢查。RV-26 only reviews no-drift after TE-26 approved. DL-25 is one bounded topic commit/push only after RV-26 approved. CH-23 re-fetches feedback only after delivery visible; unknown/unclassified feedback stops at HC-23, with no merge/release.

下列為 PC-29 initial planning／initial review 後、已被 layout amendment supersede 的 historical snapshot，不是 current route：

```text
PC-29 (completed／historical) → PR-29 (completed／approved／historical) → IM-29 (當時 active／historical) → TE-26 (當時 pending／historical) → RV-26 → DL-25 → CH-23 → HC-23
```

### PC-29 Layout Amendment

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

本 amendment 的唯一 source allowlist 是
`meta.viewBox: [1250,780] → [1337,780]`。它只 supersede PC-29 initial source contract 對
`meta.viewBox` 的 `[1250,780]` 固定值；不重開任何 guard、response handoff 或 retry decision。

Planner 的 read-only candidate diagnostics：`[1336,780]` 有 1440×900 `scrollHeight: 901`，故失敗；
`[1337,780]` 為 showcase 9/9、0 errors、0 warnings，1440×900、1600×1000、1920×1080、2048×1320 的
exact `scrollHeight` 分別為 900、1000、1080、1320，minimum text size = 7.651。candidate diagnostics
不是 visual evidence 或 delivery receipt，IM-29 不得以它們取代標準 validate、deliver、receipt 與 visual gate。

6 participant IDs、7 activation records、5 segment records、20 message IDs/count，以及每一 message 的
`from`、`to`、`y`、`variant`、label 均為 ReadOnly。兩張 renderer-owned guard cards、互斥 branch
projection、raw `HTTPResponse` handoff、`AuthFlow` sole policy owner、retry permission 只一次，以及所有
Non-Goal／ReadOnly boundary 全部不變。除了 source `meta.viewBox` 外，不允許任何其他 JSON field mutation；
existing HTML、receipt 與 visual evidence 只能由標準 delivery 從該 source 重新產生，不得手改。

PR-29 initial、PR-29 re-review 均已 completed／approved／historical。PC-29 layout amendment 已 completed／historical；
PR-29 re-review 已確認唯一 `meta.viewBox` allowlist 與所有既有 PC-29 locks。IM-29 與 TE-26 已
completed／historical，TE-26 verdict 為 `approved`；RV-26 initial review 僅因 PC-28 historicality 記述未對齊而
`needs-rework`，RV-26 re-review 已 completed／approved／historical。下列保留 PC-30 前的 historical
snapshot，不是 current route：DL-25 `9aad10e` 已 completed／visible／historical；CH-23 當時為 active，HC-23
當時為 pending human boundary：

```text
PC-29 layout amendment (completed／historical) → PR-29 re-review (completed／approved／historical) → IM-29 (completed／historical) → TE-26 (completed／approved／historical) → RV-26 initial review (needs-rework／historical) → RV-26 re-review (completed／approved／historical) → DL-25 (`9aad10e` completed／visible／historical) → CH-23 (當時 active／historical) → HC-23 (當時 pending／human boundary／historical)
```

### PC-30 — Ledger 可見狀態與 Component 文件語言

> Historical snapshot：本節的 workflow route、gate 與執行狀態只記錄各步驟當時的情況，非目前 route／gate，也不因這個標示新增 approval 或 thread closure。既有技術契約與 factual evidence 保持原義。

PC-30 是兩項 finding 的表述回修。不改變已採用的 Model C contract、任何 retry／ownership decision 或 component
canvas topology。DL-25 `9aad10e` 是 completed／visible／historical；其後的已分類 feedback 使
CH-23=`needs-rework`／historical、HC-23=`pending`／historical。新 route 開始前，四份 formal artifact 都必須
可見這三項事實，並如實保留其前一個 historical snapshot：
`DL-25 completed／visible → CH-23 active → HC-23 pending`；此 snapshot 不代表已完成 thread closure。

**Non-Goal**：不改 canvas component／edge／content、keyboard、VoiceOver fallback、ARIA、contrast behavior 或 shared
architecture-canvas template／producer；不改其他 diagram、Swift/tests、Git/GitHub、merge 或 release。

`component-dependency/scene.js` 是不可變的 authored scene，且沒有 document-language field。raw build 的
`<html lang="en">` 是由 shared architecture-canvas template 輸出，不是 scene metadata；它必須 ReadOnly。
因此 final artifact contract 固定為：

```text
scene.js (unchanged)
  → architecture-canvas validate + temporary raw build
  → artifact-local enhance-document-language.js (one root-language replacement only)
  → component-dependency/index.html (generated delivery)
  → verify-document-language.js
```

raw build arguments 固定為 title／kicker `RivetHTTPClient — 認證責任目標`、subtitle
`<b>AuthRequester</b> 持有原始請求 → <b>AuthFlow</b> 擁有策略／狀態 → <b>Requester</b> 執行通用輸入／輸出`，
以及 slug `redefine-auth-subsystem-responsibilities-component-dependency`。

raw input 沒有恰好一個預期的 `<html lang="en">` 時，`enhance-document-language.js` 必須 fail-closed；它只能將
它替換為 `<html lang="zh-Hant">`。不得改變 stage behavior、keyboard handling、ARIA、styles、canvas pixels、
`BOXES`／`EDGES`／`TEXTS`、labels、dependencies 或任何 visible content。`verify-document-language.js` 必須只
assert delivered root-language invariant。`BUILD.md` 記錄精確的 validate → raw build → enhance → verify
procedure，以及第二次完整 temporary run 的 final HTML byte-identical。不得改 shared template/producer，也不得
direct edit final HTML。

**Written/Modify**：四份 formal planning artifacts；`component-dependency/index.html` 作 deterministic generated
output；只新增 artifact-local `BUILD.md`、`enhance-document-language.js`、`verify-document-language.js`。
**ReadOnly/Out-of-Scope**：`scene.js`、所有 canvas semantics/content、global architecture-canvas template/scripts、
其他 diagrams/docs、Swift/tests、OAuth、Git/GitHub、merge 與 release。**Deleted**：無。

**TE-27 TestCase**：四份 formal artifact 對 DL-25／CH-23／HC-23 historical truth 與唯一 current route 一致；
canvas validation 維持 5 bands／10 boxes／12 edges／0 errors／0 warnings；scene byte-identical；raw-to-final delta
只能是 root `lang` value；verifier 確認恰有一個 `zh-Hant` document root、沒有 `en` root；重跑完整 pipeline
產生 byte-identical final HTML；temporary raw outputs 不得納入 Git。delivered canvas 在
1440×900、1600×1000、1920×1080、2048×1320 都無 visual drift，並 manual inspect 1440／2048 light/dark。
language verifier 是唯一新增的 a11y assertion；keyboard、fallback 與其他 ARIA behavior 明確不改。

**Route**：PC-30 completed／historical → PR-30 completed／approved／historical → IM-30 completed／historical → TE-27 initial verification needs-rework／historical → PC-30 ledger-only correction completed／historical → TE-27 re-test completed／approved／historical → RV-27 completed／approved／historical → DL-26 當時 active／historical → CH-24 當時 pending／historical → HC-24 當時 pending／human boundary／historical。
PR-30 已在 implementation 前獨立 approve 此 mapping；IM-30 已依已核准 mapping materialize。對應 downstream gate
前，不得 commit、push、thread resolution、merge 或 release。

## PC-31 — DL-26／CH-24／HC-24 可見交付狀態回修（Historical Snapshot）

### Goal 與當時的範圍

PC-31 只將已發生的 DL-26 completed／visible、CH-24 當時 active、HC-24 當時 pending 狀態納入四份
formal planning artifacts 的可見交付，回應 `PRRT_kwDOUFu0Cc6m85u0`。這是 ledger historicality／delivery
traceability 回修；Model C、retry policy、original-request ownership 與 deferred boundary 均保持 locked。

### PC-31 前 Historical Snapshot

`40f439c` 已 push 且對既有 PR #37 visible。下列只記錄 PC-31 開始前的事實，非 current route，
也不表示 CH-24 closure completed 或 HC-24 human approval：

```text
DL-26 (`40f439c` completed／visible／historical) → CH-24 (當時 active／historical) → HC-24 (當時 pending／human boundary／historical)
```

### In-Scope／Written／Modify 與 Non-Goal

當時只可寫四份 formal planning artifacts 的 snapshot、phase／role status、route 與 delivery-traceability
文字。所有 diagram/source/HTML/receipt/visual evidence、component canvas／language tools、Swift/tests、OAuth、
producer、long-lived docs、Git/GitHub、merge、release 及未列 path 均為 ReadOnly／Out-of-Scope。
Deleted：無；不得 delete、rename 或 move。PC-31 不處理或 resolve thread。

### TestCase 與執行結果（Historical Snapshot）

TE-28／RV-28 只檢查四份 planning artifacts 的一致性、scope 與 no-contract-drift；不生成、重建或驗證
diagram/canvas，不新增 product test。驗收要求四份 artifacts 保留上述 snapshot，且不得把 CH-24／HC-24
誤列 current gate、completed closure 或 human approval。

PC-31 planning 與 snapshot-status amendment 均 completed；PR-31 已由獨立 Plan-Reviewer
completed／approved；IM-31 no-op re-test completed；TE-28 re-test completed／approved。
RV-28 的 needs-rework 僅指出早期 route/gate 文字仍可能被誤讀為現況，由 PC-32 承接。
下列是 PC-32 前 historical route，不構成新的 approval：

```text
PC-31 (completed／historical) → PR-31 (completed／approved／historical) → IM-31 (completed／no-op re-test／historical) → TE-28 (completed／approved／historical) → RV-28 (needs-rework／historical) → DL-27／CH-25／HC-25 (未進入的 historical downstream route)
```

## PC-32 — Early Route/Gate Historicality 與受限文本重建

### Goal

統一四份 formal planning artifacts 早期無時間限定的 current-route／active-gate 宣告，讓每個 workflow
單元在自己的段落或小節明確呈現 historical snapshot，並維持唯一 current route。只修正 planning wording，
不重開 architecture、path、contract、Model C、retry policy、ownership、deferred representation 或 API。

### 已發生的 Review／Implementation History

PC-32 completed；PR-32 initial review 的 needs-rework 是 historical；其 re-review 已依獨立
Plan-Reviewer verdict completed／approved。IM-32 已 completed／no-op。
TE-29 initial verification 為 needs-rework／historical，指出機械 historical marker 造成斷句與過度標示；
independent integrity review likewise needs-rework。Human 於 2026-09-30 明確授權四份 artifacts 的受限重建。
這些歷史 verdict 不構成重建後的 approval。TE-29 re-test 與 RV-29 的新 approved verdict 分別引用獨立 Tester 與 Reviewer evidence。

### In-Scope／Written／Modify

- 僅本 topic 的 requirements、technical spec、plan 與 step ledger 四份 formal planning artifacts。
- 以 HEAD `40f439c` 原文逐文件恢復受損歷史文本，保留 PC-31／PC-32 的 scope、事實、review evidence 與 route。
- 只限定 workflow route/gate 單元；可用明確的局部 historical section 表達語境，不對每個 active、pending、
  test 或 evidence 機械追加 marker。Historical 標示不改寫原有 date、hash、status 或 approval evidence。
- 重建前保存四份現況、HEAD 原文與完整 diff，保留可恢復性；不新增 cycle。

### Non-Goal／Out-of-Scope／ReadOnly／Deleted

所有 production、Swift/tests、OAuth、diagram/source/HTML/receipt/visual evidence、canvas language tools、producer、
long-lived docs 與未列 path 均 ReadOnly／Out-of-Scope。此 planning write 不操作 Git/GitHub，不 commit、push、
resolve thread、merge 或 release。Deleted：無；不 delete、rename 或 move repository files。

### TestCase

- TE-29 re-test 逐段驗證可讀性、Markdown 結構與 factual preservation；舊 workflow 單元須有清楚的局部
  historical 語境，沒有競爭的裸 current-route／active-gate 宣告，不靠單一全域免責語掩蓋落差。
- 比較 HEAD 與備份，確認 architecture/evidence 未刪失；PC-31 snapshot 仍是 DL-26 `40f439c`
  completed／visible／historical、CH-24 當時 active、HC-24 當時 pending human boundary。
- 只驗證四份 formal artifacts 的 consistency／scope／no-contract-drift；不新增 product test 或生成 diagram。
- PR-32 approved 只引用既有獨立 review；TE-29 re-test approved 只引用本次獨立 Tester evidence，後續 pending gate 不是 historical。

### PC-33 前 Historical Route／Delivery Snapshot

本小節及下方 CH-26 新 Feedback 只保存 PC-33 授權前的 historical snapshot；非 current route，未新增 approval 或 thread closure。2026-09-30 human 已授權 PC-33 最小圖表回修；當時 CH-26 needs-rework／HC-26 pending 的 scope 決定停點由 PC-33 承接。

TE-29 re-test 已 completed／approved，依獨立 Tester evidence：四檔 diff scope、diff check、UTF-8、Markdown fences／table、hash／date／content preservation 均通過，dev clean、備份完整。
TE-29／RV-29 啟動時 active／尚無 approved verdict 的記述已為 historical snapshot。
RV-29 已 completed／approved，依獨立 Reviewer evidence：只有四份 formal artifacts 變更，facts／backup／schema、historicality／唯一 current route 正確，dev clean／diff check 通過。DL-28 已以 `738366c` completed／visible，local／origin／PR #37 head 一致，PR 維持 OPEN、ready。
Delivery-before snapshot（historical）：當時 DL-28 active／尚未 completed／visible，CH-26 當時 pending，HC-26 當時 pending human boundary；此記述非 current route。
Delivery-after snapshot（historical）：DL-28 `738366c` completed／visible → CH-26 當時 active → HC-26 當時 pending human boundary；此記述非 current route。
四份 artifacts 當時唯一 current route（PC-33 前 historical snapshot）為：

```text
TE-29 re-test (completed／approved／historical) → RV-29 (completed／approved／historical) → DL-28 (`738366c` completed／visible／historical) → CH-26 (needs-rework) → HC-26 (pending／human boundary：新 scope 決定)
```

CH-26 的獨立 Reviewer verdict 為 needs-rework → human-check：Codex 對 head 的 review 已於 2026-09-30T02:54:15Z 完成（COMMENTED），新增四條 P2 feedback；其中 diagram findings 超出 PC-32 scope。原 28 條 known-fixed classifications 保留，現有 32 條 thread 仍 unresolved，未執行 resolve。
當時只同步 delivery／review facts；HC-26 當時 pending human boundary，等待新 scope 決定；當時尚未建立 PC-33。此 historical snapshot 保留 DL-28／CH-26 未提交 fact sync 的原始事實，不宣稱 closure 或 human final approval。

### CH-26 新 Feedback（PC-33 前 Historical Snapshot）

- `PRRT_kwDOUFu0Cc6nXmhX`：normal／401／state Archify HTML 的 root 與 SVG language 仍為 en；要求由標準 producer regeneration 改為 zh-Hant，尚未實作。
- `PRRT_kwDOUFu0Cc6nXmhd`：DL-28 visible delivery 與 CH-26 route 的 ledger sync；此四檔 fact sync 記錄已查證狀態，尚未提交／push，thread 仍 unresolved。
- `PRRT_kwDOUFu0Cc6nXmhf`：lifecycle 缺少 initial semantic finish outcome；target failure surface 仍 deferred，中性的 initial terminal topology 需新 human scope，尚未實作。
- `PRRT_kwDOUFu0Cc6nXmhh`：state 的 initial waiting label 提及 retry，但 retry 已有獨立 waiting state；要求 initial-only label，尚未實作。

## PC-33 — 最小圖表語言／初始終態回修契約

> 本節為 PC-34 前 historical snapshot；其中 current route／gate／待同步狀態只描述當時情況，已由 PC-34 新 cycle supersede。保留 CH-27 needs-rework、HC-27 pending 與全部原始證據，不代表 closure 或新增 approval。

### Goal／Human Authorization

2026-09-30 human 明確授權：三份 Archify HTML／inline SVG 設為 `zh-Hant` 並重新產生 receipts；
lifecycle 明確表達 initial semantic terminal outcome，failure surface 保持 deferred；
state initial waiting label 僅描述首次回應。PC-33 承接 CH-26 的四條 P2 與未提交 DL-28／CH-26 fact sync，
不重開已採用 Model C、retry policy、ownership 或任何 deferred API。

### In-Scope／Modify

1. normal／401／state 三份 source 僅新增獨立 `meta.document_language: "zh-Hant"`；
   `meta.locale` 的既有 absent／en／zh-CN 行為保持不變。normal／401 messages、participants、
   activations、guards、geometry 均保持不變。
2. state 僅將 `waiting-response.label` 改為首次回應語意；既有 11 states／12 transitions、
   state IDs、edges、retry waiting state、policy、geometry 保持不變。
3. lifecycle 在 `start` 的初始語意決策加入真正互斥 alternative：
   semantic send → 原有 `initial-send`；semantic terminal → 原有中性 `receive-finish`。
   initial terminal path 不經 Requester／transport／HTTPResponse／receive policy，亦不暗示憑空回傳 response、
   concrete error API 或既有 `HTTPClientError.authFlowFinishedWithoutResponse` 就是 target failure surface。
   最小 node/edge wording 或 context 可明示「初始終態；結果／failure surface 延後確定」；
   既有 response／refresh terminal、refresh decision → AuthRequester → deferred I/O、
   transport HTTPClientError 與 legacy failure node 可達性保持不變。
4. lifecycle 首選復用中性終態（11 states／新增 1 transition，合計 14 transitions）。
   僅修正被診斷的相連 label／route；兩輪 focused repair 後仍未通過 showcase 時，
   先交獨立 Reviewer 分類。若仍屬同一 initial terminal 表達問題，才可改用專用中性 initial terminal
   （12 states／14 transitions），由 Reviewer 明示此 bounded fallback 可前進後實作並重驗；
   不允許任意重排其他 nodes、改 retry policy 或將 target failure surface concrete 化。

   IM-33 實際 focused repair diagnostics 為 10 → 6 → 4，有改善但兩輪後仍未通過 showcase；
   剩餘四個 diagnostics 的 subject 均為 initial terminal，相交於 initial-send／refresh-dispatch／
   receives-response／client-sends-retry。獨立 Reviewer（agent name：
   `im33_initial_terminal_fallback_review`）已分類並明示 approved：可採用本契約既有專用中性
   initial terminal fallback（12 states／14 transitions），屬原 scope，不改 gate。
   此證據只准許 bounded fallback，不表示 IM-33 completed、fresh delivery 或 TE-30 pass。
5. 由 repository-tracked、pinned、pre-generation producer overlay 產生語言正確的新 HTML 與 receipts；
   不修改全域 Archify installation，也不對已生成 HTML／JSON 做字串後處理。

### Written — 精確檔案 Allowlist

四份 formal planning artifacts：

- `analysis/redefine-auth-subsystem-responsibilities/requirements.md`
- `analysis/redefine-auth-subsystem-responsibilities/technical-spec.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md`

下表的 directory + basename 定義四個且僅四個 artifact stem；不授權整個 directory：

| Directory | Basename |
| --- | --- |
| `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities` | `normal-request` |
| `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities` | `401-refresh-retry` |
| `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities` | `auth-flow-state` |
| `docs/architecture/diagrams/http-client-auth-flow-contract` | `auth-flow-lifecycle` |

每個 stem 僅允許既有九種 suffix：
`.json`、`.html`、`.delivery.json`、`.visual-check.json`、`.visual-check.html`、
`.visual-check.1440x900.light.png`、`.visual-check.1440x900.dark.png`、
`.visual-check.2048x1320.light.png`、`.visual-check.2048x1320.dark.png`。
HTML 中的 inline SVG 是語言驗證對象；不新增 standalone SVG 或其他 viewport／alternate artifact。

Producer 新檔僅允許下列五個，集中於
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/`：

- `run.mjs`：pinned temporary runtime copy、pre-generation patch、canonical containment 與標準 CLI 委派。
- `document-language.patch`：下方五個 upstream files 的最小 patch。
- `upstream-pin.json`：producer-relative filenames／SHA-256 與 baseline provenance；不得存安裝位置。
- `BUILD.md`：重建／測試命令、pin check、overlay 差異、receipt capture 與 failure policy。
- `producer.test.mjs`：語言、schema/generated validator、pins、containment、stdout receipt 驗證。

目前 Plan-Creator 只寫四份 formal artifacts；上述 diagram／producer 檔案必須等 PR-33 approved 後由獨立 Implementer 處理。

### Technical Producer Contract

Planner 查證的 patch targets 僅為：
`schemas/sequence.schema.json`、`schemas/lifecycle.schema.json`、
`renderers/shared/generated-validators.mjs`、
`renderers/shared/cli.mjs`、`renderers/shared/utils.mjs`。
兩個 typed schema 的 optional `meta.document_language` 僅接受 const `"zh-Hant"`；
absence 保持現有 resolved locale 的 document language。不得為此增加 Viewer locale 或改 common locale enum。
generated validators 必須從 generator 重新產生，不手改 generated validator。
`writeDiagram` 傳遞 document language 至 root SVG attrs；`applyTemplate` 只覆寫 HTML root lang，
i18n 仍由 resolved Viewer locale 決定。common schema、i18n、template、generator、package 與 CLI entry 是 ReadOnly。

Planner 提供的已查證 baseline（package `2.16.0-dev.0`／skill `2.16`）；只作 upstream-relative pin，不記錄 installation path：

| Upstream relative file | SHA-256 | Overlay scope |
| --- | --- | --- |
| `schemas/sequence.schema.json` | `1184b00d4847811cae6829affa1815ef4b42546cadc60c7a0cc2019315f3f7ea` | optional document_language const zh-Hant |
| `schemas/lifecycle.schema.json` | `f0dbe72f612449b4dd5326a1cfd0057a6d2fa68e66c132da387ff2d427516088` | optional document_language const zh-Hant |
| `renderers/shared/generated-validators.mjs` | `b7db8e42033c8357d4be47b3cd536e43a6e53d4572502a22537b5da0c8e9133f` | generator output only |
| `renderers/shared/cli.mjs` | `a36a3e028b976454272c2aadcef777aa9343d07f118994005d850689213ac6a8` | writeDiagram document language／SVG attrs |
| `renderers/shared/utils.mjs` | `20124265300eb286db184a053561005cc32b6128dc1bc1b3f9520ffa8d43a241` | root HTML lang only；i18n resolved locale unchanged |
| `package.json` | `48c15b6102adea1882421544d3a3f0dad3aa8e355a3f535c48de13da5e6b6121` | ReadOnly |
| `schemas/common.schema.json` | `ba6f6023450034a1f52f474fe887be23633f819d12570a0dc0f27a4743724d1a` | ReadOnly |
| `scripts/generate-validators.mjs` | `a5f5f67d3cd4675b16fa620043a5463f3c15aad89afb1b0c7cf42cf35e883f9a` | ReadOnly |
| `bin/archify.mjs` | `a73a0beac5eb023821ba4136daea1a9aa4125dde437941050762950c12e037d6` | ReadOnly |



Manifest 必須記錄 Planner 已驗證的 upstream-relative baseline hashes，涵蓋五個 touched files 及
package/common/generator/bin 的 ReadOnly pins；Implementer 在任何 copy／patch 前補齊實際載入 runtime
dependency 的完整 relative-path/hash manifest，獨立 Reviewer 核對覆蓋。僅五個 touched-file hashes
不得宣稱完整 reproducibility。每個 pin mismatch 在寫任何 artifact／receipt 前 fail-closed。
Runtime 可在暫存處完整複製所需 Archify tree；repository 只追蹤上述五個 overlay files，
不 vendor 整套工具。Patch 在 validate／deliver 前套用；BUILD 記錄 upstream version、patch scope 與 pin
來源，不把本地 overlay 冒稱為 upstream support，也不將本機安裝路徑寫入產物／manifest／log。

所有 input／output 以 repository-relative 參數在 feature repository root 執行。
`--repo-root` 的 root/input/output 先做 canonical／realpath 解析；
canonical input/output 必須位於 canonical root 內，明確 repo 外路徑或 repo 內 symlink 指向外部
均須在任何 artifact／receipt write 前拒絕。這些現有安全 boundary 不因語言 overlay 改變。

Final source 經 showcase validate 通過後 freeze，標準 deliver 直接產生 HTML；
stdout JSON 同時以原始 bytes capture 到同一 receipt directory 暫存檔，驗證後 atomic rename 成
`.delivery.json`。不手寫、替換或後處理 receipt bytes。Receipt 的 input/output/artifact.path／
provenance/command metadata（若存在）只能使用 repository-relative 位置；
hash 與 bytes 必須對應實際 final source/HTML。Visual evidence 由 final HTML 重新取得，不 rerender trusted HTML。

### Non-Goal／Out-Of-Scope／ReadOnly／Deleted

ReadOnly：所有 Swift／product tests／package manifest、OAuth、canonical architecture docs／indexes／BC、
兩份 canvas 及其 scene/build/language tools、其餘 diagram/topic、全域 Archify installation 與未列檔案。
本次不設計新 action/event/factory/failure API，不改 refresh/retry policy、credential boundary、
request preparation owner，亦不把 deferred interface 寫成已實作。
不發布 artifact.cafe、不 merge、不 release；不得清理 ignored／untracked 資料。
Deleted：無；不得 delete／rename／move repository files。Producer runtime temporary files 只作隔離執行，
不包含 repo 資料清理。規劃編寫不執行 Git/GitHub、測試或實作。

### TestCase／Acceptance Evidence

- **TC-33-01 Language**：三份 final HTML root 與 inline SVG language 為 `zh-Hant`；
  authored 繁體中文保持不變；Viewer UI absence／en／zh-CN 行為維持原樣。
  explicit document_language=zh-Hant + existing locale 組合可產生正確 root；
  absence/default en、explicit en／zh-CN locale 的舊輸出語言與 Viewer strings 不回歸。
- **TC-33-02 Producer**：無效 document_language（含 en／zh-CN／任意其他值）與 pin mismatch
  fail-closed/no artifact or receipt output；sequence/lifecycle typed schema 與 generator 產生的 validator 一致。
  完整 pins＋patch＋命令可重現 source/output language；不以 postprocessing 通過。
- **TC-33-03 Semantics**：四 source 各通過 showcase 9/9、0 composition errors／warnings。
  initial lifecycle terminal 為真 alternative、無 transport/HTTPResponse predecessor、failure surface deferred；
  legacy transport failure 仍可達。normal/401 topology 與 state 11/12 unchanged，
  state initial waiting 不提 retry；locked policy／ownership／raw response handoff 無漂移。
- **TC-33-04 Provenance**：四 fresh deliver receipts 的 stdout bytes capture、source／HTML SHA-256／bytes
  正確；canonical root containment 與兩種 repo 外路徑／symlink 拒絕案例通過；
  metadata、全部待提交 diff／HTML／evidence 不含本機絕對位置、用户名、home 或 worktree 名稱。
- **TC-33-05 Visual**：normal／401／lifecycle 在 1440×900、1600×1000、1920×1080、2048×1320
  containment/capture pass；最小與最大 viewport light/dark manual inspection。
  state 的既有 1440=1035、1600/1920=1109 containment non-pass 與 2048 pass 必須如實記錄，
  readability/chrome/captures 不回歸，不宣稱全 pass、不新增例外。不得以 clipping/overflow hidden/縮字造假。
- **TC-33-06 Scope/Workflow**：exact allowlist、dev clean、四份 artifacts facts／current route 一致；
  DL-28 `738366c` completed/visible 與原 28 known-fixed＋32 unresolved 的當時分類保留為 historical evidence，
  不提前宣稱本次 delivery、thread closure、human approval 或尚未執行的測試 pass。

### IM-33 — Fresh Delivery 與人工視覺回修證據

以下為上游 Implementer／獨立 Reviewer 的交接事實；不是 Plan-Creator 自行驗證或 gate approval。
producer 五檔已建立，完整 manifest 為 743 pins；五個 upstream targets 的 patch 為 836320 bytes。
上游回報 producer tests 7/7、fresh hashes 與 generated-validator check 通過。
四 source 的 fresh validate／deliver 各為 showcase 9/9、composition errors／warnings = 0；
raw stdout receipt 與 source／HTML hashes 已由上游核對。這些結果不取代 TE-30 的獨立驗證。

Composition history 完整保留：shared terminal 原 candidate diagnostics 10 → 6 → 4，兩輪 focused repair
仍失敗，經 `im33_initial_terminal_fallback_review` 明示 approved 後採用既有
12 states／14 transitions 專用中性 initial terminal fallback。Fallback candidate 的 pre-delivery
composition diagnostics 為 5 → 2 → 0，經兩輪修正後四 source 9/9。既有 lifecycle 11 nodes／13 edges
及其 locked semantics 保留；只依原契約新增 initial terminal node／edge，不改 retry／refresh policy
或 deferred failure surface。這兩組 composition rounds 不等同 post-delivery perceptual repair rounds。

Normal／401／lifecycle 的四 viewport automated containment 均通過；
state 保留 1440×900 height 1035、1600×1000／1920×1080 height 1109 containment non-pass，
2048×1320 pass，不能宣稱 state visual 全 pass。
獨立 Reviewer `im33_visual_terminal_overlap_review` 親自檢閱 exact-delivered
2048 light、1440 dark 與 SVG，原始 FINAL verdict 為 needs-rework，並 approved bounded fix：
lifecycle `initial-finish` rectangle [34,236,120,62] 遮住 response heading [72,252]，
response rail y=264；首次人工 visual inspection failed。當時尚未進行 post-delivery perceptual repair
（0 輪），不能以 automated containment pass 宣稱 manual visual pass 或 IM-33 completed。

Reviewer 當時已直接交接 Implementer，核准第一個 post-delivery visual candidate 僅將
`initial-finish.yOffset` 110 → 144，未預判成功。第一輪 fresh image 顯示 node 遮擋改善，
但新的 initial-terminal edge x=94 垂直段仍穿過 heading，manual inspection failed。
第二個且最後 visual round 僅修改新 initial-terminal route，
`via = [[402,200],[58,200],[58,260],[94,260]]`；node yOffset 保持 144。
Implementer `im33_diagram_implementation` 明示 completed handoff：第二輪 final exact-delivered
最小／最大 viewport light/dark 共四張 manual inspection 通過，lifecycle 四 viewport automated checks 均 pass。
既有 lifecycle 11 nodes／13 edges 與 HEAD deep-equal；其餘三 source／producer 自首次 delivery 後未再修改。
不改 retry／refresh policy、failure surface deferred、其他既有 geometry、scope 或 pins；
首次 inspection failed、第一輪 failed 與第二輪 pass 均保留，未超過兩輪上限。
每次 source visual edit 後皆須 fresh validate → deliver、原始 receipt bytes capture／hash 核對、
fresh visual-check 與 exact-delivered manual light/dark inspection。
Post-delivery visual repair 最多兩輪；第二輪仍 failed，或需要改既有其他 geometry／scope／pins，
即停止交獨立 Reviewer 分類。這是原 IM-33 的已核准 bounded handoff，未新增 cycle 或 contract design。

Final lifecycle source SHA-256 為 `124582f618975eb3e15925f8b792f96dc4ff8d8a67e3b7993ef1d9638f7dd5c8`，6516 bytes；
HTML SHA-256 為 `d06e2aba55fa3825a2700254318fd42e7ddc51e04a2d90584ee373ceab12bdf8`，712909 bytes。
Implementer 回報完整 producer tests 7/7、四 source validate／deliver 9/9、hash／byte integrity、
pins、scope 與當時 dev clean 回報通過；最新獨立 Tester 將 dev 狀態限於 tracked／staged clean，另有未追蹤 `.vscode/`。State 1035／1109 containment non-pass 與 2048 pass 維持既有例外。
這些是 implementation completion evidence，不是獨立 test／result-review approval。

IM-33 completed handoff 時的 historical snapshot：TE-30 當時 active，RV-30／DL-29／CH-27／HC-27 當時 pending。
當時尚無 TE-30 verdict；最新獨立 test verdict 與 current route 見下節。

### TE-30 — 獨立 Tester 完成交接

獨立 Tester `te30_diagram_independent_validation` 的原始 FINAL verdict 為
TE-30 completed／approved、required fix 無，RV-30 eligible；本節只引用該 evidence，不由 Plan-Creator 自核准。
Tester 實際驗證 producer tests 7/7、四 source showcase validate 9/9、source／HTML hash 與 bytes、
visual evidence 綁定、HTML root／inline SVG language、既有 nodes／edges 與 HEAD deep-equal、
locked policy、current route、exact allowlist、diff 無本機絕對位置及 diff check 均通過。

Sandbox Chrome 首次 SIGABRT 沒有產生有效 fresh visual evidence；之後獲准 escalation，
以 exact HTML 在暫存位置重新執行 visual-check。Normal／401／lifecycle exit 0，
四 viewport automated checks 均 pass；state exit 1，保留 1440 height 1035、
1600／1920 height 1109 containment non-pass 與 2048 pass，readability／chrome／captures 通過。
Tester 親自檢閱 16 張 repository captures 及 fresh 401 dark，未見 regression，manual inspection passed。
Automated evidence 的 visualReview pending 原值保留，未將 manual inspection 結果改寫成該欄位 approval。

Dev tracked／staged diff 為空，但 porcelain 有 `?? .vscode/`；只可稱 tracked／staged clean，
不能宣稱 full worktree clean。不推測來源、不清理未追蹤資料。
IM-33 completed 與全部 composition／visual repair history 保留。TE-30 完成交接時的 historical snapshot：
TE-30 completed／approved，RV-30 當時 active，DL-29／CH-27／HC-27 當時 pending；當時尚無 RV-30 verdict。
最新獨立 result-review verdict 與 current route 見下節，未宣稱 delivery visible 或 thread closure。

### RV-30 — 獨立 Reviewer Gate 完成交接

獨立 Reviewer `rv30_final_diagram_review` 原始 FINAL verdict 為 RV-30 approved、
required fixes 無，可依既定契約前進 DL-29；Reviewer 未修改 ledger。本節只引用其獨立 verdict。

Reviewer 以 HEAD `738366c` 核對 36 tracked paths＋5 producer files 符合 exact allowlist、
staged empty／diff check 通過；獨立 producer tests 7/7、743 完整 pins／五 patch targets、
generated-validator check、canonical containment 與 symlink fail-closed 通過。
四 source validate 為 showcase 9/9、0 errors／warnings；source／HTML／receipt SHA-256 與 bytes 綁定、
tracked metadata 無本機路徑；三 HTML root／inline SVG 為 zh-Hant，Viewer locale 原樣，
lifecycle 既有 en 屬授權外，保持不變。

既有 lifecycle 11 nodes／13 edges 逐項與 HEAD 一致，新中性 initial terminal 為互斥直達，
不經 I/O／response policy，failure surface deferred；normal／401／state contract 無漂移。
Reviewer 親閱 16 張 current captures，未見新增缺陷；normal／401／lifecycle 四 viewport pass，
state 既有 1035／1109 三 containment non-pass 與 2048 pass、automated visualReview pending 保留。
四 formal artifacts 的 contract／history／route 一致；dev tracked／staged clean，
未追蹤 .vscode/ 保留，不宣稱 full clean。

RV-30 完成交接時的 historical snapshot：依其明示 verdict 同步 RV-30 completed／approved、DL-29 當時 active；
CH-27／HC-27 當時 pending，當時尚無 DL-29 completed／visible evidence，未宣稱 thread closure 或 human final approval。

### DL-29 Delivery／CH-27 Post-Delivery Snapshot

Delivery 原始 FINAL 明示 DL-29 completed／visible，commit
`175965784597b224781e31600a8352f8e6dd75de`，message：
`docs(auth): 修正圖表語言與初始終態並同步驗證紀錄`。
該次 non-force push exit 0；local／origin／remote branch／PR #37 SHA 一致，
PR OPEN／ready、CLEAN／MERGEABLE、checks []，41 paths；feature clean，
dev 的未追蹤 .vscode/ 保留。Human 已直接授權此 commit 的 known SwiftLint
`--no-verify` exception，未改 Swift；此紀錄不是後續 commit 的概括 exception。

CH-27 獨立 Reviewer 原始 FINAL 為 needs-rework，必要 scope 僅四 formal artifacts 的
post-delivery fact sync；本次依此修正 stale delivery 狀態，尚待獨立 Reviewer 審查同步 diff，
未新增 PC cycle，未自核准。CH-27 未完成／needs-rework，HC-27 pending。

GitHub 最後提供的 snapshot 為 50 threads／32 unresolved、無新 feedback；
bot 對 1759657 為 Running，since `2026-09-30T07:33:51.914333Z`，
summary updated `2026-09-30T07:33:54Z`；該 snapshot 最新 submitted review 仍為 738366c。
這些只描述當時 snapshot，不能當作目前 live state 或宣稱 latest bot review 完成。
三條新 threads nXmhX／nXmhf／nXmhh 已分類 visible-fixed；
nXmhd 的 DL-28 已 historical／visible-fixed、待 supersession comment，但當時最新 DL-29 ledger 尚未同步；
其餘 28 threads 本輪 closure 未驗。未宣稱 closure pass、thread resolved 或新增 approval。

### Historical Route／Dispatch Contract — PC-33

PC-33 planning 編寫 completed。規劃交接時 PR-33 active／尚未 approval 已為 historical snapshot。

Human 已直接確認：`確認 PR-33 approved/completed，授權將 IM-33 設為 active。這是 human 對本次 gate 狀態同步的直接確認。` 本次依 human 確認同步 status；獨立 Plan-Reviewer 原始 verdict 為 approved、Required fix 無，IM-33 具備 planning eligibility。此同步不表示 implementation／test／result review 已通過。

PR-33 completed／approved、IM-33 completed handoff、TE-30／RV-30 completed／approved 保留；依 Delivery 原始 FINAL，DL-29 `175965784597b224781e31600a8352f8e6dd75de` completed／visible。CH-27 獨立 Reviewer 原始 FINAL needs-rework，當時四檔 fact sync 尚待獨立 review；HC-27 pending。以下為 PC-34 前 historical route：

```text
PC-33 (completed／historical) → PR-33 (completed／approved／historical) → IM-33 (completed／handoff) → TE-30 (completed／approved) → RV-30 (completed／approved) → DL-29 (`1759657` completed／visible) → CH-27 (needs-rework／未完成) → HC-27 (pending／human boundary)
```

未進入的後續 steps 是 pending future route，不標為 historical。
PR-33 必須由獨立 Plan-Reviewer 審查 scope、exact allowlist、minimal producer、pins、topology/fallback、
tests 與 receipt contract，approved 後才進入獨立 Implementer。
TE-30 由獨立 Tester 驗證全部 TestCase；RV-30 由獨立 Reviewer 核對 evidence、contract/ownership
與 scope drift，approved 後才進入 DL-29。Plan-Creator 只同步有上游 evidence 的 status，不能自核准。
DL-29 依 staged diff 提出單一 topic commit message，取得 human 明確確認後才 commit/push 至既有 feature
branch；保留既有 PR #37 ready。Hook 例外只依已明確授權且仍適用的受限 exception，其他 failure 停止。
Push visible 後 CH-27 重新取得 threads，只對已分類、證據可見的 known-fixed finding closure；
非必要項目以說明留言後 resolve；unknown/unclassified feedback 停在 human boundary。
HC-27 保持 pending human review；不 merge/release，不自動採用新 architecture 或擴張 scope。

## PC-38 — Receipt 防護與 Enhancer 診斷最小回修（Current Contract）

### Goal

Human 已授權三項最小 scope：receipt 冒號前綴 traversal 防護、receipt schema／type 驗證，
及 component enhancer diagnostic sanitizer。Planner receipt_diagnostics_schema_preflight
正式 approved sufficiency、無 missing，只放行 creation，不是 PR-38 planning approval。
不改 diagram／ownership／layout，恢復可信 receipt 與不洩漏本機路徑的 fail-closed 診斷。

### In-Scope

1. Receipt 遞迴 metadata tokens：冒號 prefix 後 ../ 或 ..\\ 必拒，含 nested prefix、
   internal traversal、keys／values／arrays／command quoted／backtick／option=value framing。
2. Receipt schemaVersion strict numeric 1，type 與 actual contained source.diagram_type
   相同且為有效 sequence／lifecycle；actual invocation 與 schema-validated source 不能不一致。
3. Enhancer diagnostic boundary 涵蓋 read／output catch 與 VM failure stack，
   只安全遮蔽 diagnostic，不改成功 artifact bytes／atomic output 契約。
4. 四 formal scope／tests／route／historicality／visible vs local 同步。

### Out-Of-Scope

不修改 CLI、global skill、producer runtime pin／patch／dependency 或新增 schema dependency；
不修改 generated diagram／HTML／receipt／canvas scene／layout／CSS／ownership、verifier／BUILD。
不修改 Swift／Tests／Package.swift、lint／800 限制／hooks；不改 retry／deferred architecture。
不手動 postprocess JSON／HTML、不重生 repository index／viewport evidence、不增 tracked 檔案。
不得用 --no-verify／hooksPath override，不 merge／release。

### ReadOnly

所有 Archify source／HTML／receipts／visual、所有 canvas scene／index／verifier／BUILD／其他 canvas；
global skills、producer BUILD、743 pins／五 targets／manifest／patch、canonical prose／其他 topics、
Swift／Tests／Package.swift／lint／hooks 保持。成功 enhancer HTML／semantics／CSS／ownership／
layout／atomic normal contract 不改；既有 state 三 containment non-pass／visualReview pending 保留。
原生 VoiceOver／Increase Contrast／inactive 待驗、Arrow viewer pan 不提升。
Implementer 建立 protected baseline，驗證區間與四 formal 合法 state sync 分開；
dev 不改檔，未追蹤 .vscode/、temp／使用者檔案保留。

### Written

Literal seven-file allowlist；四 formal 僅 Plan-Creator，後三檔僅 Implementer，不新增 tracked files：

- analysis/redefine-auth-subsystem-responsibilities/requirements.md
- analysis/redefine-auth-subsystem-responsibilities/technical-spec.md
- plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md
- plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/run.mjs
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/producer.test.mjs
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/enhance-document-language.js

### Deleted

無。

### Modify

Receipt 保留 absolute POSIX／Windows drive／UNC／rooted、backtick／原 containment／symlink 防護，
unsafe nested-prefix 或 internal-traversal tokens fail-closed；合法 cwd:docs/relative.json、
status:ready、time:12:30、urn:synthetic:record 保持可接受，不 blanket 禁冒號。
成功 receipt Buffer／raw stdout bytes 不改、不後處理 JSON；unsafe run 不 publish receipt，
保留舊 receipt bytes／temporary cleanup。上游 HTML 可能已寫入：不虛稱 HTML／receipt 雙檔交易原子性。

Receipt envelope schemaVersion 僅 strict numeric 1，依 pinned CLI successful deliver envelope；
source.schema_version 是另一欄位，不可混同。Receipt type 必須等於 actual contained source 的
有效 diagram_type（sequence／lifecycle），並核對 actual invocation；不得從 receipt 自推
expected type、從 filename 猜測，source parse failure／missing 或 invalid discriminator fail-closed。
以既有 runtime／schema contract 為依據，不改 schema dependency／pins／CLI。

Enhancer read／output errors 與 VM failure stack 的 diagnostic sanitizer，不依本機 prefix blacklist，
涵蓋任意 POSIX／Windows drive／UNC／rooted、quoted spaces／multiline paths。
真 CLI read／output failure 與 synthetic diagnostic 都 nonzero、不洩漏路徑、
舊 output 不覆寫；保留 safe relative diagnostic 的可讀文字，不執行 metadata／diagnostic 字串。
成功 temp raw → enhance → ReadOnly verifier 可驗證與既有 index byte-equal，
不生成 repository index 或其他 artifacts。

### Non-Goal

不重開任何已鎖定 architecture／retry policy／ownership／representation decision。
不以 sanitize 後字串修補 receipt provenance，不以 receipt 自身 type 證明正確，
不刪 coverage／降低 validation。沒有新的 artifact exception、native accessibility pass 或 thread closure。
本輪只有 bounded diagnostic／receipt producer fixes，不延伸至一般 renderer 重構。

### TestCase

| ID | 必須驗證的證據 |
| --- | --- |
| TC-38-01 | Colon-prefix traversal matrix 覆蓋 ../／..\\、nested prefixes／internal traversal、keys／values／nested arrays／quoted／backtick／option=value command framing，全拒絕；relative／colon-nonpath positives 接受且 Buffer byte-equal。 |
| TC-38-02 | 有效 sequence／lifecycle envelope 接受、raw bytes unchanged；cross type、missing／invalid type、schemaVersion 999／string／null／missing 拒絕。Expected type 取 actual contained source／invocation，不由 receipt 或 filename 猜；source parse／discriminator 不合法 fail-closed。 |
| TC-38-03 | Actual run stdout injection 驗證新增 unsafe 類別 nonzero、不 publish receipt／舊 bytes 不變／temp cleanup；如 upstream HTML 已寫入須真實記錄，非雙檔 transaction。 |
| TC-38-04 | Real enhancer CLI read／output errors 與 synthetic VM／multiline diagnostic，stdout／stderr 無 absolute paths、nonzero、舊 output unchanged；安全 relative 文字保留，不執行字串。 |
| TC-38-05 | Valid temp raw → final byte-equal existing index，ReadOnly verifier pass；repository index 不重生，無新 viewport／tracked artifact。 |
| TC-38-06 | 全 producer tests regressions，保留 pins／runtime／absolute／backtick／document-language hashes／containment／symlink contract。 |
| TC-38-07 | Exact seven-path allowlist／protected others／dev／user data，四 formal history／唯一 route／visible vs local 一致；Human 新 exact message 後正常完整 delivery hooks，不 bypass。 |

### Current Route／Gates

```text
PC-38 completed → PR-38 completed／approved → IM-38 completed → TE-35 completed／approved → RV-35 completed／approved → DL-34 active → CH-32 pending → HC-32 pending
```

Creation completed 不等於 planning approval；PC-38 completed → PR-38 active 為 historical snapshot。
現依 Dispatcher 傳遞獨立 pr38_receipt_diagnostics_review approved／no-fix，完整 611-line diff／current contract
已審查：PR-38 completed／approved → IM-38 active 是前次 planning handoff historical snapshot。
IM-38 completed → TE-35 active 為前次 implementation handoff historical snapshot；self-verification 不是 test approval。
TE-35 completed／approved → RV-35 active 為前次 test handoff historical snapshot。
現引用 Dispatcher 獨立 rv35_receipt_diag_review approved／no-fix：RV-35 completed／approved → DL-34 active；
actual delivery full hooks／新 exact message／closure 仍 pending。獨立 Tester TE-35
及 Reviewer RV-35 後才 delivery。Normal hooks 必須通過，新完整 staged semantic check／exact
message 仍需 Human 明示確認；舊 confirmation／exception 不沿用，不逐 gate 問 Human。
Fresh matching-head review／thread classification 後才 CH-32 evidence-backed reply／resolve，
re-fetch threads；新 unknown／超 scope feedback 停止回報，不假稱 closure。最後停 HC-32。

### Sources／Historical Snapshot／Visibility

Dispatcher 提供 published HEAD c86effb（四 formal factsync 已 commit／push），不得仍宣稱該版
factsync local。DL-33 62462476 completed／visible、normal 六 hooks Passed 事實保留；
CH-31 新 necessary scope 後為 historical human-check，HC-31 historical pending，
由本次 Human scope 授權承接，不將 CH-31 寫成 completed 或 threads closed。
舊 submitted review 對應 62462476、65 threads／47 unresolved 只為 Reviewer snapshot，
不是本 Plan-Creator live 查詢；temp locator os.tmpdir() 下 rivet-ch31-final-review-20261005。
Pinned CLI successful deliver envelope numeric schemaVersion 1 已由 Planner 核對 global SHA／manifest，
不是新增 pin／自行放寬 schema。下方 PC-37／更早所有 route、active gate、local／pending 字句
均為有限時 historical snapshot；PC-38 新四 formal creation 仍 local，未再 commit／push。

### Blockers／Human Check／Last Updated

2026-10-05 — 引用獨立 pr38_receipt_diagnostics_review approved／no-fix，只同步
RV-35 completed／approved → DL-34 active，CH-32／HC-32 pending；依獨立 rv35_receipt_diag_review approved／no-fix，
不是 Plan-Creator approval；actual delivery full hooks／新 exact message／closure 仍 pending。
本次只四 formal state sync，未自審、實作、
測試、stage／Git／remote。若缺必要輸入、需改 ReadOnly／新增 path／contract 或 source-type
驗證無法可信完成即停止，交獨立角色分類；審批拒絕即停寫入、回報原始理由，不繞過。
New exact message／normal hooks failure／scope drift／final HC-32 boundaries 保持。

### IM-38 — Completed Handoff／Self-Verification Evidence

Dispatcher 傳遞 IM-38 正式 completed：只三 implementation files，未 stage／commit／push／resolve。
RED 14 tests：11 pass／3 fail（traversal、schemaVersion 999、enhancer read leak）；
final GREEN 15/15，syntax／diff check pass。210 unsafe placements 拒絕、70 relative／colon-nonpath
positives 接受且 Buffer unchanged；5 actual deliver stdout injections fail-closed、old receipt bytes
preserved／capture cleanup。HTML 可能上游已寫，不宣稱兩檔 transaction。
Enhancer real read／output errors 加 21 synthetic cases、三 diagnostic boundaries 均 nonzero，
舊 output preserved／無 absolute leak／safe relative readable。Temp raw → final canvas 與 existing
index exact byte-equal，ReadOnly verifier pass，未重生 repository index／viewport。
550 tracked baseline 中 547 untouched byte-equal，含當時四 formal；本次合法 factsync 不受此區間
限制，不假稱永遠 immutable。Index empty、dev 未追蹤 .vscode/ 保留。
Temp evidence locator：os.tmpdir() 下 rivet-im38-0fdJwV 的 baseline／protected／RED／GREEN、
raw sources／receipt exact stdout／canvas verifier；不新增 tracked evidence。
全部是 Implementer self-verification，非 TE-35／RV-35 approval；當時交 TE-35 active 為 historical snapshot，
最新獨立 Tester verdict 見下節。
新 exact message Human confirmation／normal full hooks／no bypass 保持，原 native 待驗、
state non-pass／automated visualReview pending 不提升；尚未新 delivery visible／threads closure。

### TE-35 — Independent Verification Evidence

現引用 Dispatcher 傳遞獨立 te35_receipt_diag_verify 正式 approved／no-fix：
TE-35 completed／approved，當時交 RV-35 active 為 historical snapshot；最新 result-review verdict 見下節。
Tester actual producer suite 15/15；224 unsafe cases 全拒絕、140 positives 接受且 Buffer unchanged，
30 envelope negatives／6 source-type probes 通過。7 actual stdout injections 拒絕，
old receipt preserved／capture cleanup；HTML 可能 upstream 已寫，不宣稱兩檔 transaction。
4 actual source CLI cases：parse failure／missing 或 invalid discriminator／missing source 均 nonzero，
舊 HTML／receipt preserved。Enhancer actual read／output errors 加 27 synthetic cases／三 boundaries
均 nonzero、無 absolute path leak、old output preserved／safe relative readable。
Temp canvas exact byte-equal existing index、ReadOnly verifier pass，無 repository regeneration。
543 protected baseline files HEAD byte-equal；七檔 allowlist、syntax／diff check pass、index empty，
dev 未追蹤 .vscode/ 保留。此驗證區間 baseline 不禁止本次合法四 formal factsync。
Evidence locator：os.tmpdir() 下 rivet-te35-CL5Xxl 的 producer-tests.log／producer-tests-result.json、
independent.mjs／result、source-cli.mjs／result 及 raw temp；未新增 tracked evidence。
上述為獨立 Tester 證據，Plan-Creator 未重跑或自行核准；actual delivery full hooks 仍 pending，
須 Human 新 exact message 確認後正常執行，不使用 no-verify／hooksPath override。
Native VoiceOver／Increase Contrast／inactive、Arrow viewer pan、state non-pass／visualReview pending
保持；沒有新 delivery visible／thread closure。

### RV-35 — Independent Result Review Evidence

現引用 Dispatcher 傳遞獨立 rv35_receipt_diag_review approved／no-fix：
RV-35 completed／approved，允許 DL-34 exact staging／new message preparation。
Reviewer own producer suite 15/15 exit 0、diff check pass、543 HEAD-protected files byte-equal。
TE-35 logs／helpers／results 經 Reviewer 確認可信，carry-forward 224 unsafe／140 positive／
30 envelope negatives／6 source-type／7 stdout／4 source CLI／27 diagnostic probes 證據，
不假稱 Reviewer 重跑全部 probes。Trusted source schema／type、成功 raw Buffer 不後處理、
diagnostic 安全／normal output byte-equal index 等 contract 一致，無 required fix。
此 approval 僅放行 delivery preparation，不代表 message Human confirmed、actual full hooks pass、
commit／push visible 或 thread closure。上述仍 pending，正常 hooks／新 exact message boundary
及 no-verify／hooksPath override 禁止保持。Readonly／native 待驗／既有 visual non-pass 不升級，
four formal factsync 仍 local；Plan-Creator 不實作／測試／自審／操作 Git 或 remote。

## PC-37 — StaticIsolationTests 最小責任拆分（Historical Snapshot）

> 本節所有 current route／active gate／local factsync／pending／未交付文字只記錄 PC-38 前的 historical snapshot。
> Published c86effb 已交付先前四 formal factsync；CH-31 新 scope 停 human-check、HC-31 pending，由 PC-38 承接，未完成 thread closure。

### Goal

Human 已授權最小 StaticIsolationTests 冗餘／責任拆分以恢復正常 commit hooks，不提高
SwiftLint 800 行限制、不降低 isolation coverage。Explorer 未確證可安全刪除的冗餘，
因此採原封移動單一既有 Keychain 測試；不虛造需要新增行為測試的 RED。
Planner static_isolation_split_preflight 正式 approved 只表示 sufficiency，不是 PR-37 approval。

### In-Scope

1. 將 keychainAdapterUsesTheCommonLegacyBaseQueryForEveryOperation 原封移到同 directory
   的 StaticIsolationTests+Keychain.swift，仍是 extension StaticIsolationTests 的同一 @Test。
2. 原檔只移除該完整 @Test 區塊；新檔只加入 Foundation／Testing imports、該 extension，
   及與原檔一致的 file-private repositoryRoot，以 #filePath 連續三次 deletingLastPathComponent。
3. 四 formal 記錄受限 scope、測試／normal-hook 驗收、歷史／local visibility 與新 route。
   PC-36 六 implementation files 不再修改，只保留已獨立 approved 的既有 bytes 供後續交付。

### Out-Of-Scope

不修改 production Swift、Package.swift／target graph、scanner／其他 helper 或其 visibility、
dependency、SwiftLint configuration／800 上限、format／lint／Git hooks configuration。
不得刪除測試／assertion／snippet、改測試 identity、重新命名 suite 或變更 isolation 能力。
不修改 ownership／retry policy／deferred contract、任何 diagram／receipt／layout；
不使用 --no-verify 或 hooksPath override，不 merge／release。

### ReadOnly

既有六 PC-36 implementation files bytes 保護；component scene、四 Archify source／HTML／receipts／
visual、其他 canvas、canonical architecture prose、global skills／patch／pin／dependencies 均不改。
原 StaticIsolationTests 除移出單一 @Test 外，其他 code／scanner／helper bytes 保持；其他 tests 不改。
dev 不實作／改檔，未追蹤 .vscode/、temp evidence 與使用者資料保留。
原十檔已 staged snapshot 保留，不 reset／unstage；Dispatcher 提供 staged diff SHA-256：
64d22be4843a09f25eebff5c03cb4093b7f89eef41d48de5ae3fc0c6d7859686。
此 hash 是 PC-37 前 snapshot，不假稱 formal 新同步後 index／worktree 永遠不變。

### Written

本輪 Plan-Creator 只四 formal；Implementer 只兩 tests。待 delivery union 為 literal twelve paths：
既有 PC-36 十檔與本次兩檔，非允許再次修改六 PC-36 implementation files。

- analysis/redefine-auth-subsystem-responsibilities/requirements.md
- analysis/redefine-auth-subsystem-responsibilities/technical-spec.md
- plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md
- plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/run.mjs
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/producer.test.mjs
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/enhance-document-language.js
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/verify-document-language.js
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/BUILD.md
- docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/index.html
- Tests/GitHubIntegrationTests/StaticIsolationTests.swift
- Tests/GitHubIntegrationTests/StaticIsolationTests+Keychain.swift

### Deleted

無；新增一份同 directory 測試 extension，不刪檔。

### Modify

僅在 PR-37 獨立 approved 後，於既有 feature worktree 進行兩檔純 refactor。
移動 @Test 的 name／signature／throws／body／required snippets／forbidden markers／全部 #expect
原封保持；不可改 helper visibility 或 import scanner。新 file-private repositoryRoot 與原檔
使用相同 #filePath 三次 deletingLastPathComponent，兩檔同 directory，必須解析到同 repository root。
先保存完整移動區塊與 29 個 qualified discovery identities baseline，再原封移動及驗證；
既有 pre-refactor normal hook failure 是 pre-RED，不虛造新行為 RED。

RV-34 approved 後，Delivery Implementer 才明確整理原 staged／新 unstaged formal 與兩 tests 差異，
依 git-commit-convention 重新審查完整 staged diff 語意邊界、提出新的 exact message，
Human 確認後才正常 commit／non-force push。舊 PC-36 message confirmation 不套用新 scope。
若建議拆成兩個 commits，各自需語意審查與 Human message 確認，不由 Dispatcher 自行決定。
正常完整 hooks 必須通過；再次失敗須停止及分類，不以 --no-verify／hooksPath override 繞過。

### Non-Goal

不追求一般測試重構、刪除尚未證明冗餘或改 lint policy。PC-36 既有 implementation／
TE-33／RV-33 approvals 保持；native VoiceOver／Increase Contrast／inactive 待驗、
Arrow keys 既有 viewer pan、state containment non-pass／automated visualReview pending 不提升。
沒有新 delivery visible 或 thread closure；beyond-scope／unknown feedback 仍交 human boundary。

### TestCase

| ID | 必須驗證的證據 |
| --- | --- |
| TC-37-01 | 前後完整 29 qualified StaticIsolationTests discovery identity set 相同且不重複，不只比較 count；不能以其他 target 同名 suite 代替。 |
| TC-37-02 | 移動 @Test name／signature／throws／body／snippets／assertions 與保存 baseline exact；原檔只去該完整區塊，新檔 repositoryRoot 三次 deleting 與原同 root。 |
| TC-37-03 | 執行 qualified GitHubIntegrationTests.StaticIsolationTests suite，全部 29 tests pass；保留 runner identity／結果證據，避免其他 target 同名 tests。 |
| TC-37-04 | GitHubIntegrationTests target regression pass，不擴張至無關產品修改。 |
| TC-37-05 | 既有 scripts format／lint pass；兩檔都低於 800 行，lint／800／hooks configuration 不變。 |
| TC-37-06 | 六 PC-36 implementation bytes 保持，十二檔 delivery union／protected others／dev／user files 保護；四 formal 唯一 route／history／local vs visible 正確。 |
| TC-37-07 | Human 新 exact message 確認後正常完整 commit hooks 全通過；任何再次 failure 停止分類，不使用 --no-verify 或 hooksPath override。 |

### Current Route／Gates

```text
PC-37 completed → PR-37 completed／approved → IM-37 completed → TE-34 completed／approved → RV-34 completed／approved → DL-33 completed／visible → CH-31 active → HC-31 pending
```

PC-37 completed → PR-37 active 是 creation historical snapshot。
現引用 Dispatcher 傳遞獨立 pr37_test_split_review 正式 approved／no-fix；
PR-37 completed／approved → IM-37 active 為前次 planning handoff historical snapshot。
IM-37 completed → TE-34 active 為前次 implementation handoff historical snapshot；self-verification 不是 TE-34 approval。
TE-34 completed／approved → RV-34 active 為前次 test handoff historical snapshot。
RV-34 completed／approved → DL-33 active 為前次 review handoff historical snapshot。
現依 Dispatcher actual delivery：DL-33 62462476 completed／visible → CH-31 active → HC-31 pending；
已確認 29 identities／TC-37-01～07／十二檔 delivery union／正常 hooks 禁止 no-verify 與歷史區隔。
TC-37-01～06 獨立 pass，RV-34 approved；TC-37-07 現依 actual normal commit 六完整 hooks Passed。
Human 新 exact message 已確認、正常 commit／push exit 0，未使用 no-verify／-c／hooksPath override。
尚無 fresh matching-head review／closure verdict，pending／checkbox 不構成 approval。
本次新四 formal factsync 仍 local、未再 commit／push，不冒充遠端可見狀態。
獨立 PR-37 approved 才 IM-37；獨立 TE-34 result 後交 RV-34；RV-34 approved 後才 DL-33。
不逐 gate 重問 Human，但新 exact staged message confirmation／normal hook stop／final HC-31
仍是明確 boundary。Push visible 後 fresh matching-head review／classification 才 evidence-backed
CH-31 reply／resolve，re-fetch 全 threads，不假稱 closure；最後停 HC-31，不 merge／release。

### Sources／Historical Delivery Boundary

Dispatcher 提供：HEAD ba6422c8dbc1a74e56a0573573fdd1bf47177ae8 保持 visible；
DL-32 正常 commit exit 1、SwiftLint exit 2，唯一已知 failure 是
Tests/GitHubIntegrationTests/StaticIsolationTests.swift 801 行超過 800，其餘五項 checks pass。
尚未 commit／push；原十檔 staged snapshot 與 PC-36 implementation 保留，
formal factsync 仍 local，未以新文字冒充遠端可見。Human 最新授權本次最小責任拆分，不准提高 800。
DL-32 的正常 hook blocker／未 completed／未 visible 是 superseded historical snapshot，
由 PC-37 承接；CH-30／HC-30 仍 historical pending，未偽造 thread closure／Human approval。
下方 PC-36 契約／approvals／所有 route、active-gate 與未交付文字只記錄其當時 historical snapshot，
非 current route；其 technical facts 與 native pending 保留。

### Blockers／Human Check／Last Updated

2026-10-05 — PC-37 completed；引用獨立 pr37_test_split_review approved／no-fix，
依 Dispatcher actual delivery evidence，只同步 DL-33 62462476 completed／visible → CH-31 active → HC-31 pending。
TC-37-01～06 pass，TC-37-07 actual 完整正常 hooks Passed；fresh review／threads closure 尚待後續。
本次四 formal 新 factsync 仍 local、未再 commit／push。Plan-Creator 只寫四 formal，
未實作、測試、stage、commit／push、remote action 或自審。
若需改 helper visibility／scanner／production／manifest／其他 path、discovery identities 或 coverage
弱化／repositoryRoot 不同即停；測試環境 failure 交 Tester 分類，不以推論 pass。
審批拒絕即停止該寫入、回報原始拒絕理由，不繞過。
Human 新 message confirmation 與 HC-31 boundaries 保持；沒有本輪 hook-bypass 授權。

### IM-37 — Completed Handoff／Self-Verification Evidence

> Delivery-before historical snapshot：本節 pending hooks／未 commit／push／visible 等措辭只描述當時。
> 目前 DL-33 已 completed／visible、完整 normal hooks actual pass；最新事實見 DL-33 小節，原 evidence 不重寫。

Dispatcher 傳遞 IM-37 正式 completed：只改兩 test files，original 801→750 行、new 60 行。
完整 29 qualified identities 前後相同且無 duplicates；original 只去移動區塊，new @Test
body／markers／assertions 與 baseline exact，兩份 repositoryRoot 同根。
Implementer self-verification：focused suite 29 pass；target 76 tests／8 suites pass，
format／lint／consumer checks exit 0，consumer 8 pass。此證據不是 TE-34 approval。
548 other tracked files implementation-before／after byte-equal，包含當時四 formal、六 PC-36
implementation files、configs／hooks／production；factsync 合法改四 formal，不假稱永遠 immutable。
原 staged snapshot SHA-256 64d22be4843a09f25eebff5c03cb4093b7f89eef41d48de5ae3fc0c6d7859686
保持；dev 未追蹤 .vscode/ 保留。Evidence locator：os.tmpdir() 下 rivet-im37-zlHvyP 的
baseline before／after、discovery、after-result／checks logs，未新增 tracked evidence。
此 handoff 當時交 TE-34 active，為 historical snapshot；最新獨立 verdict 見下節。
TC-37-07 正常完整 commit hooks 尚待 delivery 與 Human 新 message
確認，不能將 self-verification scripts pass 宣稱為完整 hooks 已通過。未新 commit／push／resolve。

### TE-34 — Independent Verification Evidence

> Delivery-before historical snapshot：本節 pending hooks／未 commit／push／visible 等措辭只描述當時。
> 目前 DL-33 已 completed／visible、完整 normal hooks actual pass；最新事實見 DL-33 小節，原 evidence 不重寫。

現引用 Dispatcher 傳遞獨立 Tester 正式 approved／no-fix：TE-34 completed／approved，
TC-37-01～06 pass；TC-37-07 仍 pending actual normal delivery hooks，不宣稱完整 hooks 已通過。
完整 29 qualified identities exact、無 duplicate；只移動完整 @Test 區塊，
original 750／new 60 行；body／markers／assertions 保持，repositoryRoot canonical 相同。
Tester actual focused suite 29 tests／1 suite pass，target 76 tests／8 suites pass；
scripts format／lint／consumer exit 0，lint 68 files／0 violations，consumer 8 pass。
544 protected baseline files Tester-before／after byte-equal；原 staged snapshot
64d22be4843a09f25eebff5c03cb4093b7f89eef41d48de5ae3fc0c6d7859686 保持，
dev 未追蹤 .vscode/ 保留，無 core.hooksPath 設定。
以上是獨立 Tester evidence，不是 Plan-Creator verdict；本次授權 factsync 合法改四 formal，
不把 protected baseline 宣稱為永遠 immutable。此 handoff 當時交 RV-34 active，為 historical snapshot；最新 review verdict 見下節。
Native VoiceOver／Increase Contrast／inactive、Arrow viewer pan 與舊 state non-pass／visual pending
保持；尚未新 commit／push／thread closure。正常完整 hooks 待 Human 新 message 確認後 delivery，
不得使用 --no-verify／hooksPath override。

### RV-34 — Independent Result Review Evidence

> Delivery-before historical snapshot：本節 pending hooks／未 commit／push／visible 等措辭只描述當時。
> 目前 DL-33 已 completed／visible、完整 normal hooks actual pass；最新事實見 DL-33 小節，原 evidence 不重寫。

引用 Dispatcher 傳遞獨立 Reviewer 正式 approved／no-fix：RV-34 completed／approved，
允許 DL-33 exact staging／new message 準備。Reviewer own checks：原封完整 @Test move，
750／60 行、repositoryRoot 同根；544 protected files／六 PC-36 implementation bytes／index 不變。
Reviewer 核對 TE-34 actual transcript（a4929a、session 85031 exit 0）：29 identities 無 duplicates、
suite 29／1、target 76／8、scripts exit 0；採該獨立 Tester 證據 carry-forward。
TE-34 未落盤 logs 明確保持 unavailable，不以 IM-37 self-verification logs 冒充 TE-34 logs。
Reviewer 自行 discovery attempt 因環境／sandbox 失敗，不宣稱 reviewer 重跑 pass；
此限制與可信 TE-34 transcript carry-forward 由獨立 Reviewer 明示，Plan-Creator 未自行判定。

TC-37-07 actual 完整正常 commit hooks 仍 pending，須新 full staged semantic check／exact message
Human 確認後才執行；不得使用 --no-verify／hooksPath override，任何再次 failure 停止分類。
DL-33 active 僅 stage／message preparation，未新 commit／push／visible／threads closure。
CH-31／HC-31 pending；native 待驗、Arrow viewer pan、舊 state non-pass／visual pending 保持。
本次四 formal state sync 合法更新 baseline 中的文件，不宣稱 protected bytes 永遠 immutable。

### DL-33 — Completed／Visible Delivery Facts

Dispatcher 傳遞 actual delivery completed／visible：commit
62462476efe2ea2a31a019a6d7776f8637bd0fbd，parent
ba6422c8dbc1a74e56a0573573fdd1bf47177ae8。已獲 Human 確認的 exact message：

```text
fix(auth-diagrams): 強化收據驗證與圖表可及性並拆分隔離測試
```

Normal git commit／non-force push exit 0；六項完整 hooks 全 Passed：
trim、EOF、swiftformat、consumer、SwiftLint、renderer。
TC-37-07 actual pass；沒有 --no-verify、-c 或 hooksPath override。
Literal twelve-path delivery union 為唯一 changes；local HEAD／tracking／actual remote ref／
PR #37 head 均一致。Delivery snapshot：PR OPEN／ready、MERGEABLE／CLEAN、checks []。
此 snapshot 不代表 fresh matching-head review completed，亦不是 CH-31 approval／thread closure。

Delivery 後 feature clean／index empty；538 non-union tracked files 對 parent byte-equal，
544 IM-baseline protected files、既有六 PC-36 implementation bytes 保持，generated index SHA-256
2bd759c3366fcdb3033ebd0c213bf1c21ad79df6a8f7b13df6183d2b3b30c81e 保持。
dev tracked clean、未追蹤 .vscode/ 保留。上述均為 Dispatcher 傳遞的 delivery evidence，
不是 Plan-Creator 新 Git／GitHub 查詢，baseline 僅對該驗證區間有效。

Current gate CH-31 active，HC-31 pending；fresh matching-head review／thread classification
與 evidence-backed reply／resolve 尚待後續，沒有新 threads closure。
本次四 formal delivery-after factsync 仍 local、未再 commit／push，不能當作遠端可見狀態文字；
62462476 內已交付的 planning／implementation bytes visible 與本次新增 factsync 必須區分。
Native VoiceOver／Increase Contrast／inactive 待驗、Arrow viewer pan、既有 state non-pass／
automated visualReview pending 保持。不 merge／release。

## PC-36 — Receipt 冒號前綴驗證／Component Canvas 等價可及性（Historical Snapshot）

> 本節所有 route／active-gate／status wording 僅記錄 PC-37 前 historical snapshot，非 current gate。
> DL-32 normal hooks failure 未 completed／visible；由上方 PC-37 最小 split 承接，原 PC-36 技術證據／native pending 保持。


### Goal

Human 已授權最小新增 scope：receipt colon-prefix validation／相關 tests 與 component canvas
等價 accessibility；不改 ownership 或 layout。依 Planner receipt_canvas_minimal_preflight
approved sufficiency 建立 PC-36；該 verdict 只放行 creation，不是 PR-36 approved。
Receipt 不得以冒號前綴繞過本機路徑防護；canvas 不依 mouse 才能取得完整既有架構語意。

### In-Scope

1. Producer 只修 verifyReceipt 的 metadata 路徑識別與既有 producer regression tests。
2. Component artifact 的既有 enhancer／verifier／BUILD 契約與生成 index.html，提供
   完整、靜態、可見且 accessible 的 scene-equivalent semantic DOM。
3. 四 formal 同步受限 scope／TC／route／historicality／local-versus-visible；既有 local factsync 保留。
   CH-29 的新增 necessary findings 由本 cycle 承接，CH-29 historical human-check，
   HC-29 historical pending；不宣稱 completed／threads closure。

### Out-Of-Scope

不改 ownership／retry policy／deferred contract、scene geometry／文字／edge route、viewer runtime
或 global template。不得 deliver／重生 Archify outputs、手改 index.html 或 receipt、
新增 tracked screenshots／receipts／viewports／檔案、patch／pin／dependency。
不是 Swift implementation，不修改上游 Swift；不建立新的 artifact exception。

### ReadOnly

component scene.js 全 byte-equal：5 bands／10 boxes／12 edges、W／H、geometry、全部文字、
ownership 與 routes 不變。其他 canvas、四份 Archify source／HTML／receipts／visual
均 ReadOnly；state 已接受 containment non-pass／automated visualReview pending 保留。
Producer BUILD、743 pins／五 targets／patch、upstream-pin.json、document-language.patch、
global Archify／architecture-canvas、Swift／Tests／Package.swift、canonical prose、其他 topic
以及 allowlist 外既有檔案均 ReadOnly。dev 不實作／改檔，未追蹤 .vscode/ 與使用者資料保留。
Implementation 前建立 protected baseline；factsync 與 implementation 變更區間分開記錄。

### Written

Literal ten-file allowlist；不新增 tracked files：

- `analysis/redefine-auth-subsystem-responsibilities/requirements.md`
- `analysis/redefine-auth-subsystem-responsibilities/technical-spec.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/run.mjs`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/producer.test.mjs`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/enhance-document-language.js`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/verify-document-language.js`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/BUILD.md`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/index.html`

### Deleted

無。

### Modify

Plan-Creator 只改前四 formal；獨立 PR-36 approved 後，Implementer 只於既有 feature worktree
修改後六檔。index.html 僅由既有 validate → raw build → artifact enhancer → verifier pipeline
生成，不手改；temp evidence 可保存於 temp，不加入 Git。

Receipt：識別例如 cwd:/outside/synthetic 的冒號前綴 POSIX，及 Windows drive／UNC／rooted
路徑；遞迴涵蓋任意 metadata keys／values／nested arrays／command tokens。保留既有
recursive path 防護、合法 relative 與 colon-nonpath positives；不得 blanket 禁冒號。
Unsafe receipt fail-closed、nonzero，保留舊 receipt；raw stdout bytes 不 postprocess，
PC-35 diagnostic sanitizer 不回退，不改 runtime／exports／其他 contract。

Canvas：artifact-local enhancer 從 raw 完整 generated scene 產生 static semantic DOM，
涵蓋所有 10 nodes 的 name／responsibility／about／既有可見 text、12 directed edges 的
source／target／existing label，以及 context／caveats：legacy type、deferred decoration、
Model C 已採用尚未實作。無 label 的 edge 不造 ownership 或新語意。
只允許 static DOM／必要 artifact-local a11y attributes 與不破壞原 canvas 的 CSS；
不改 scene／viewer runtime／global template。等價內容須可見、可由鍵盤及 AX tree 讀取，
不得 hidden／display:none／aria-hidden 隱藏該等價內容。
Verifier 獨立驗證完整性與 escape 安全；移除嚴格允許的 a11y／root-lang delta 後，
raw／final byte-equal，scene bytes 不變。保留 duplicate／missing marker fail-closed、
同目錄 temporary file／atomic rename 與兩次完整 fresh build byte-identical。

### Non-Goal

不將 AuthRequester 指派為 selected／decorated preparation owner、不添加 auth interface、
不改 retry／refresh ownership 或 lifecycle topology、不重開 Model C contract。
Browser AX／keyboard evidence 不等於 native VoiceOver pass；無原生證據時 VoiceOver 待驗，
不得記通過。四 viewport 新 canvas evidence 不提升既有 state non-pass／visual pending。

### TestCase

| ID | 必須驗證的證據 |
| --- | --- |
| TC-36-01 | 冒號前綴 POSIX 在任意 key／nested object／array／command metadata 拒絕，不依固定 key 或本機前綴。 |
| TC-36-02 | Windows drive／UNC／rooted、既有 traversal／backtick 與 PC-35 diagnostic regressions 均保持。 |
| TC-36-03 | 合法 relative／colon-nonpath 接受，receipt Buffer bytes unchanged；unsafe nonzero／fail-closed、舊 receipt preserved。 |
| TC-36-04 | Canvas 等價 DOM 完整 10 nodes／12 directed edges／context caveats、HTML escape safe；duplicate／missing markers fail-closed；鍵盤／AX tree 不需 mouse 可讀，無 native VoiceOver 證據則待驗。 |
| TC-36-05 | validate 0 errors／0 warnings → raw build → enhance → verify，兩次 fresh build byte-identical；除 allowed a11y／root-lang delta 外 raw／final 及 scene bytes 相同。 |
| TC-36-06 | 1440×900、1600×1000、1920×1080、2048×1320 驗證；1440／2048 light／dark 人工確認無 layout／ownership drift、互動保持，screenshots／evidence 僅 temp。 |
| TC-36-07 | Literal ten-file allowlist、protected baseline、四 formal 唯一 current route／歷史／visible vs local／human boundaries 一致。 |

### Current Route／Gates

```text
PC-36 completed → PR-36 completed／approved → IM-36 completed → TE-33 completed／approved → RV-33 completed／approved → DL-32 active → CH-30 pending → HC-30 pending
```

PC-36 creation completed；當時 PR-36 active／未 approved 為 creation historical snapshot。
現引用獨立 pr36_receipt_canvas_review 明示 approved、required fix 無，完整四 formal／diff review 已完成，
PR-36 completed／approved → IM-36 active 為前次 planning handoff historical snapshot。
IM-36 completed → TE-33 active 為前次 implementation handoff historical snapshot；
Implementer self-verification 不是 TE-33／RV-33 approval。
現依 Dispatcher 傳遞獨立 te33_recovery_verify 正式 approved／completed、required fix 無，
TE-33 completed／approved → RV-33 active 為前次 test handoff historical snapshot。
現引用 Dispatcher 傳遞獨立 rv33_receipt_canvas_review 正式 approved／completed、required fix 無，
RV-33 completed／approved → DL-32 active；delivery／closure 尚未 completed。
不逐 gate 再詢問 Human；新 staged exact diff／git-commit-convention message 仍需新的
Human 明示確認才 commit／non-force push。正常 hooks 先跑；舊 no-verify exception 不沿用，
新增本次 exception 需 Human 明示。禁止 hooksPath override，不修改上游 Swift。
Push visible／fresh matching-head review／classification 後才 CH-30 evidence-backed reply／resolve，
重新抓取所有 threads；新未分類／超 scope finding 回報，不假稱 closure。HC-30 final human review，
不 merge／release。Pending future steps 不是 approval。

### Sources／Historical Human-Check

Dispatcher 傳遞 Reviewer snapshot：actual head ba6422c8dbc1a74e56a0573573fdd1bf47177ae8
已 visible；59 threads／41 unresolved、matching review Completed，submitted
2026-10-05T04:19:45Z。這只是獨立 Reviewer 最後 snapshot，非 Plan-Creator 新 live 查詢。
兩條新增 findings 為 PRRT_kwDOUFu0Cc6o51NR／PRRT_kwDOUFu0Cc6o51NT，
涉及 receipt colon-prefix 防護與 component canvas 等價可及性，由本次 authorized scope 承接。
CH-29 historical human-check／HC-29 historical pending 保留，不改 completed。
DL-31、DL-30 已交付與本輪／歷史 hook exception 的原事實保留；沒有 new reply／resolve evidence。
既有 DL-31 delivery factsync 與本次 PC-36 四 formal 都仍 local、未新 commit／push，
不得宣稱這些文字已遠端可見或新 findings 已閉合。

### Blockers／Human Check／Last Updated

2026-10-05 creation snapshot：PC-36 completed，當時 PR-36 active，後續 pending。
前次 planning handoff snapshot：pr36_receipt_canvas_review approved／required fix 無，當時 IM-36 active。
2026-10-05 最新引用 Dispatcher 傳遞獨立 rv33_receipt_canvas_review 正式 approved／completed、required fix 無，
只同步四 formal：RV-33 completed／approved → DL-32 active，CH-30／HC-30 pending。
PR-36／TE-33 approved、十檔 allowlist、local factsync／history 保持；VoiceOver／Increase Contrast／inactive
原生待驗保留。result-review approval 來自獨立 Reviewer，不是 Plan-Creator 判定；尚無 delivery／closure approval。

### IM-36 — Completed Handoff／Self-Verification Evidence

2026-10-05 Dispatcher 傳遞 Implementer 正式 completed：只六 implementation files 變更，
四 formal 在 implementation-before／after 區間未動；549 tracked baseline 中其餘 543 byte-equal。
此區間包括當時四 formal，本次授權 factsync 會合法改四 formal，不能誤稱永遠 immutable。
Producer colon metadata／unsafe stdout 舊 receipt protection 兩項 RED failures → GREEN 11/11。
Canvas static semantic DOM source-derived 10 nodes／12 edges／全部 context，HTML escaped；
獨立 verifier 不 import enhancer，檢查 strict projection／CSS／markers，移除 allowed delta 後 raw bytes 相同。
6 tamper rejects、4 bad-marker cases 既有 output preserved、escape fixture pass；
兩次 fresh build validate 0 errors／0 warnings、byte-identical，generated index SHA-256：
2bd759c3366fcdb3033ebd0c213bf1c21ad79df6a8f7b13df6183d2b3b30c81e。
四 viewport no overflow；1440／2048 dark／light 人工檢查無 drift／obstruction。
AX full content、Tab focus、PageDown scroll 0→96、PageUp→0、End→2342、Home→0，canvas hash unchanged。
Arrow keys 由原 viewer pan 接管，不能宣稱 arrow-scroll pass；native VoiceOver／Increase Contrast／
inactive 待驗，browser AX 不代 native pass。全部數據是 Implementer self-verification，不是 TE-33 approval。
Temp evidence locator：os.tmpdir() 下 rivet-im36-WDXJii 的 baseline／protected／raw repeat／screens／
.playwright-cli／harness；不記本機絕對路徑或新增 tracked evidence。Plan-Creator 未重跑驗證。
此 self-verification handoff 當時交 TE-33 active，為 historical snapshot；最新獨立 verdict 見下節。
未新 commit／push／resolve，state 舊 non-pass／visual pending 保留。
Scope／locked decision／path 不明、需改 ReadOnly 或新增 tracked artifact 即停。
審批拒絕即停該寫入並回報原始 action／reason，不繞過。VoiceOver native 待驗保持，
新 commit message／特定 no-verify exception／final Human Check boundaries 維持。
Plan-Creator 未實作、跑測試、審查自己產出或操作 Git／GitHub。

### TE-33 — Server Recovery／Independent Verification Evidence

Server restart 中斷舊 Tester；當時僅有 producer 11/11 的片段，未落盤的舊 temp 為空，
不能冒充正式 gate approval。現引用 Dispatcher 傳遞新獨立 te33_recovery_verify 正式 verdict：
TE-33 approved／completed、required fix 無；Plan-Creator 只記錄交接，不重跑驗證或產生 verdict。
獨立 temp evidence locator：os.tmpdir() 下 rivet-te33-independent-QfOIXh，未新增 tracked evidence。

獨立驗證 TC-36-01～07：actual producer suite 11/11；90 unsafe metadata cases 全拒絕，
42 relative／colon-nonpath positives 全接受且 raw bytes unchanged；suite 的 unsafe stdout
nonzero／舊 receipt preservation 與 PC-35 diagnostic regressions 通過。
兩次 fresh canvas validate 均 0 errors／0 warnings，build → enhance → verify byte-identical，
index SHA-256：
2bd759c3366fcdb3033ebd0c213bf1c21ad79df6a8f7b13df6183d2b3b30c81e。
等價 DOM 完整 10 nodes／12 directed edges／context，6 tamper rejects、4 bad-marker cases、
escape fixture 與既有 output preservation 通過；strict allowed delta／scene bytes 不變。
Browser AX 包含完整等價內容、Tab focus、PageDown 0→96、PageUp→0、End→2342、Home→0，
canvas hash unchanged；Arrow keys 僅既有 viewer pan，不宣稱 arrow-scroll pass。
四 viewport no overflow；1440／2048 dark／light 由獨立 Tester 親自 view，無 drift／obstruction。

Tester-before／after 區間全部 549 tracked files byte-equal；539 與 HEAD byte-equal，
十檔 allowlist 符合、index empty、dev tracked clean／未追蹤 .vscode/ 保留。
該區間包含當時四 formal，本次 factsync 合法改四 formal，不把 baseline 宣稱為永遠 immutable。
VoiceOver／Increase Contrast／inactive 仍待原生驗證；browser evidence 不代 native pass。
TE-33 approval 當時只放行 RV-33 active，為 test handoff historical snapshot；最新 review verdict 見下節。
當時尚無 result-review approval；目前仍未新 delivery visible 或 thread closure。

### RV-33 — Independent Result Review Evidence

2026-10-05 引用 Dispatcher 傳遞獨立 rv33_receipt_canvas_review 正式 verdict：
RV-33 approved／completed、required fix 無。Plan-Creator 只同步已明示 verdict，不自行放行。
Reviewer actual producer suite 11/11；另獨立 24 unsafe metadata cases 全拒絕，
20 relative／colon-nonpath positives 全接受且 Buffer bytes unchanged。
Reviewer 自行 raw → final verifier pass；generated index 與 TE-33 兩次 fresh output byte-equal，
SHA-256：2bd759c3366fcdb3033ebd0c213bf1c21ad79df6a8f7b13df6183d2b3b30c81e。
Reviewer 已核對 Tester logs／browser AX／keyboard evidence，並親自 view 1440 dark、2048 light：
無 layout／ownership drift；其餘 exact-byte evidence carry-forward，不假稱全部視窗重新驗證。
539 tracked files HEAD byte-equal，僅十檔 allowlist changed、index empty、diff check pass；
dev 未追蹤 .vscode/ 保留。scope／native pending／history／local-versus-visible 無漂移。

RV-33 approval 只放行 DL-32 active 的 exact staging／message 準備。
新 commit message 仍須 Human 明示確認；本輪尚無 no-verify exception，禁止 hooksPath override，
不修改上游 Swift。四 formal 同步及六 implementation files 仍 local，未新 commit／push／resolve。
CH-30／HC-30 pending；native VoiceOver／Increase Contrast／inactive 與既有 state non-pass／
visual pending 不提升，Arrow keys 僅既有 viewer pan。未宣稱 delivery visible 或 thread closure。

## PC-35 — Diagnostic Sanitizer 最小回修（Historical Snapshot）

> 本節 route／active gate／狀態措辭只記錄 PC-36 前 historical snapshot，非 current route／gate。
> CH-29 新 finding 後停於 human-check、HC-29 pending，由上方 PC-36 授權 cycle 承接；不宣稱 closure。
> DL-31 ba6422c visible、已查證交付／hook exception／歷史限制與未提交 factsync 原事實保留。

### Goal

Wrapper 的現有失敗診斷中，任意位置的本機 POSIX／Windows 絕對路徑不得經輸出洩漏；
保留非零失敗退出與安全、可辨識的診斷。Human 最新明示：
「請授權最小新增範圍——僅修正 diagnostic sanitizer 與相關測試」。
依 Dispatcher 傳遞的 Planner approved bounded 契約建立本 cycle；planning sufficiency
只放行 creation，不是 PR-35 或後續實作／驗證的 approval。

### In-Scope

- 只修 wrapper 現有失敗 diagnostic sanitizer 與相關 regression tests。
- 將四份 formal 的 current route／歷史／local-versus-visible 事實對齊。
- 保留既有未提交的 DL-30／Human 接受單次偏離 factsync，不倒改執行當時授權。
- CH-28 的新增 necessary finding 由本 cycle 承接；舊 CH-28 是 historical human-check，
  不是 completed／approved／threads closed。

### Out-Of-Scope

不修改 receipt verification、BUILD.md、global Archify、diagram／HTML／SVG／receipt／visual、
pin／patch、Swift、其他 topic、architecture／retry policy；不 deliver、不後處理 generated outputs。
不擴充 generic producer 行為或新 API／dependency；不可用實作猜測擴大本契約。

### ReadOnly

除下列六檔外的既有 repository 檔案均 ReadOnly。全部 diagram source／HTML／SVG／receipt／
visual evidence、pins／patch、Swift 與其他保護檔，以本 cycle implementation 前 baseline
逐 byte 保持，不以重新生成證明 unchanged。dev worktree 不得實作或改任一檔；
未追蹤 `.vscode/` 與其他使用者資料保留。

### Written

Literal six-file allowlist（不得新增檔案）：

- `analysis/redefine-auth-subsystem-responsibilities/requirements.md`
- `analysis/redefine-auth-subsystem-responsibilities/technical-spec.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/run.mjs`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/producer.test.mjs`

### Deleted

無。

### Modify

Plan-Creator 只寫前四份 formal；獨立 PR-35 approved 後，Implementer 只在既有
feature worktree 修後兩份 producer files 的 diagnostic sanitizer／相關測試。
Formal 後續同步只依 specialist 明示 evidence；不得把 self-verification 或 status 當 approval。
Implementation 前保留 baseline，與既有未提交四檔 factsync 分開界定變更區間。

### Non-Goal

不重新設計 retry policy／failure surface／request ownership；不重跑全部圖表交付、
不改任何 diagram bytes、不建立新的長期 artifact exception。DL-30 `b830bb4` visible
與 Human 已接受的一次 hook deviation 不需再次取得相同接受；既有 state containment
non-pass／automated visualReview pending／歷史 evidence 照實保留，不能提升為 pass。

### TestCase

| ID | 必須驗證的證據 |
| --- | --- |
| TC-35-01 | 任意 POSIX 根路徑不依既有四個前綴也能安全遮蔽；涵蓋診斷任意位置、合成引號／空白案例。 |
| TC-35-02 | Windows drive／UNC／rooted 絕對路徑的失敗診斷不洩漏本機位置。 |
| TC-35-03 | 實際 CLI catch 輸出 safe stderr 且 nonzero exit；schema-validation 仍保留安全可辨識診斷。 |
| TC-35-04 | 全部既有 producer regressions 通過；receipt validation／raw stdout bytes contract 不變。 |
| TC-35-05 | 全部 diagram／HTML／SVG／receipt／visual／pins／patch／Swift 與其他保護檔和 baseline byte-equal，變更限 literal 六檔。 |
| TC-35-06 | 四 formal 唯一 current route、historical snapshots、local-versus-visible 與 human boundaries 一致。 |

### Current Route／Gates

```text
PC-35 completed → PR-35 completed／approved → IM-35 completed → TE-32 completed／approved → RV-32 completed／approved → DL-31 completed／visible → CH-29 active → HC-29 pending
```

PC-35 creation completed；creation 時 PR-35 active／未 approved 為 historical snapshot。
依獨立 pr35_diagnostic_sanitizer_review 明示 approved、required fix 無，PR-35 completed／approved，
PR-35 approved → IM-35 active 為前次 gate-sync historical snapshot。
IM-35 completed → TE-32 active 為前次 implementation handoff historical snapshot；
Implementer self-verification 不構成獨立 test／result-review approval。
TE-32 completed／approved → RV-32 active 為前次 test handoff historical snapshot。
RV-32 completed／approved → DL-31 active 為 pre-delivery historical snapshot。
現依 Dispatcher 已查證交付，DL-31 ba6422c8dbc1a74e56a0573573fdd1bf47177ae8 completed／visible，
交 CH-29 active → HC-29 pending；未宣稱新 head review／threads closure 完成。
獨立 Tester TE-32 approved 後才 RV-32；獨立 Reviewer RV-32 approved 後才 DL-31。
DL-31 依新 staged diff／git-commit-convention 提出新的 exact message，取得 Human 明示
確認後才 commit／non-force push。舊 no-verify 授權不沿用；正常 hooks 先跑，新增 exception
須對本次特定 commit 明示授權。絕不自行加入 hooksPath override，不修改上游 Swift。
四檔 factsync／planning 當時 local 未 commit／push 為 pre-delivery historical snapshot；
已由 DL-31 交付的六檔版本 visible。本次 2026-10-05 新四 formal factsync 仍 local、未新 commit／push，
不能當作遠端可見證據；Human 本輪 no-verify 單次授權不覆蓋未來新 commit。
Push visible 與 fresh matching-head review／thread classification 後才處理 CH-29：
必要事項有 visible evidence 才 resolve；非必要項目留言說明後 resolve；重新抓取確認，
新未分類／超 scope finding 回報 Dispatcher／human boundary，不假稱 closure。
HC-29 是 final human review；不 merge／release。

### CH-28 Historical Human-Check／Sources

Dispatcher 傳遞 CH-28 獨立 review 的四 formal factsync approved／no required planning fix；
新增 diagnostic sanitizer finding 為 necessary 且超前次 factsync scope，停於 human-check。
本次 Human 已授權上述最小新增 scope，僅解除該 scope 決定停點，不宣稱 CH-28 completed。
獨立 ch28_accepted_delivery_review 最後 snapshot（不是本次新 live 查詢）：
head b830bb481d43ba552548859ecae9ae60511f783e，PR OPEN／ready、base dev、CLEAN／checks []；
matching review PRR_kwDOUFu0Cc8AAAABQHvrZg 於 2026-10-01T08:30:41Z submitted COMMENTED，
bot Completed；57 threads／39 unresolved，不能當作永遠 fresh 或 closure evidence。
Necessary finding PRRT_kwDOUFu0Cc6n3RbR 指向 run.mjs:180 的四個 Unix prefix
sanitizer；Reviewer 的任意 Unix／Windows 三個合成案例仍洩漏診斷路徑。
Current-route feedback PRRT_kwDOUFu0Cc6n3RbX 當時 local 修正／pending-visible 為 CH-28 historical snapshot；
原修正已納入 DL-31 交付版本；本次 delivery factsync 則仍 local，未完成 reply／resolve。
PRRT_kwDOUFu0Cc6n3Rbe 對 state guards 的 feedback 為 nonessential，Reviewer 指出
state L21／L28／L36 guards 與 spec L117–120 一致；後續證據 reply／resolve，尚未執行。
DL-30 已推送與接受偏離事實保留於下方 PC-34 historical section，不能以新 route 抹除。
本次 scope 授權只解除 sanitizer 新 scope boundary，不宣稱 thread resolved／final human pass。

### Blockers／Human Check／Last Updated

2026-10-01 creation snapshot：PC-35 completed，當時 PR-35 active、其餘 pending。
前次 gate-sync snapshot：依獨立 pr35_diagnostic_sanitizer_review approved／required fix 無，
當時 PR-35 completed／approved → IM-35 active，其餘 pending；Plan-Creator 未執行實作／tests／Git／GitHub。
前次 implementation handoff snapshot：Dispatcher 傳遞 IM-35 completed，當時 TE-32 active、
RV-32／DL-31／CH-29／HC-29 pending，未新增 test approval／delivery-visible 宣稱。
前次 test handoff snapshot：獨立 Tester TE-32 completed／approved、required fix 無，當時 RV-32 active、
DL-31／CH-29／HC-29 pending，未新增 result-review approval／delivery-visible 宣稱。
前次 result-review handoff snapshot：RV-32 completed／approved、required fix 無，當時 DL-31 active、
CH-29／HC-29 pending，未新增 delivery-visible／closure 宣稱。
2026-10-05 最新依 Dispatcher 已查證交付，只同步四 formal：DL-31 completed／visible → CH-29 active → HC-29 pending。
PR-35 approved／IM-35 completed／TE-32 approved／RV-32 approved 保持；未新增 matching-head review completed／threads closure。

### IM-35 — Completed Handoff／Self-Verification Evidence

2026-10-01 Dispatcher 傳遞獨立 Implementer completed：只改 run.mjs diagnostic sanitizer／
producer.test.mjs，real CLI 合成 /outside/local 診斷未遮蔽為 RED，修正後 GREEN、11/11 exit 0；
新增 72 個合成 POSIX／Windows／quote／whitespace／position 與 safe-relative／schema controls。
verifyReceipt／run runtime／raw stdout contract 未改，無新 exports／dependency。
Implementation-before baseline 549 tracked files，其餘 547 在該 implementation-before／after 區間
逐 byte-equal，包含當時四 formal；baseline 證據位置為 temp rivet-im35-XfySpd/baseline.json。
此區間 baseline 不限制後續授權 formal factsync，亦非新獨立 test approval。
Implementer 回報 diff check／node check pass、index 未動、dev tracked clean、.vscode/ 保留；
這些均為交接時 self-verification snapshot，Plan-Creator 未重跑驗證，不是 TE-32 approved。
當時交 TE-32 active 為 implementation handoff historical snapshot；未 commit／push／resolve。

### TE-32 — Independent Test Approved／RV-32 Handoff

2026-10-01 引用 Dispatcher 傳遞獨立 Tester 明示 approved／completed、required fix 無：
120 個真 CLI negative cases 全部路徑遮蔽、stdout empty、exit 1；6 個 safe-relative controls
保持原文及安全 schema 診斷；producer 11/11、exit 0。run／receipt verification 既有 bytes 不變。
Allowlist 外 543 tracked files 與 implementation baseline 及 HEAD byte-equal，涵蓋 diagrams／
receipts／visual／pins／patch／Swift／BUILD；此集合與 IM-35 的 547（含當時四 formal）不同，
不得混稱同一集合。syntax／diff check pass、index empty、dev clean 為 Tester 交接 snapshot。
本次只是引用獨立證據同步四 formal，不重跑 tests／圖表或提升 visual evidence：state containment
non-pass／automated visualReview pending 及全部歷史限制保留。現交 RV-32 active，DL-31／CH-29／
HC-29 pending；當時尚未 result-review approved、未 commit／push／resolve，為 test handoff historical snapshot。

### RV-32 — Independent Review Approved／DL-31 Preparation Handoff

2026-10-01 引用 Dispatcher 傳遞獨立 Reviewer 明示 approved／completed、required fix 無：
Reviewer 自身 producer 11/11；48 真 CLI negative cases 全部遮蔽、stdout empty、exit 1；
6 safe-relative controls 與安全 schema 診斷保持。pre-CLI 既有實作與 HEAD byte-equal，
無 verifyReceipt／runtime／raw stdout／exports／dependencies 變更；六檔 scope、allowlist 外
543 protected tracked files 與 baseline 及 HEAD byte-equal；dev clean／index empty 為 review snapshot。
Reviewer evidence 不替代 delivery visible 或 Human final；state containment non-pass、automated
visualReview pending 與全部歷史限制保留，不重新生成圖表或宣稱新的 visual pass。
當時交 DL-31 active，僅 staging／exact message preparation；當時新 exact message 仍需 Human 確認，
舊 no-verify 不沿用，禁止 hooksPath override，不修改上游 Swift。
當時 CH-29／HC-29 pending、未新 commit／push／resolve，為 pre-delivery historical snapshot。

### DL-31 — Published Delivery／CH-29 Handoff

2026-10-05 引用 Dispatcher 已查證 Implementer delivery：
commit ba6422c8dbc1a74e56a0573573fdd1bf47177ae8，parent b830bb481d43ba552548859ecae9ae60511f783e；
exact message「fix(archify-producer): 遮蔽診斷中的本機路徑」，六檔確認版均在 literal allowlist。
Human 本輪明示單次 no-verify 授權後，實際 command（僅記錄，不執行）為：
~~~text
git commit --no-verify -m 'fix(archify-producer): 遮蔽診斷中的本機路徑'
~~~
無 -c／hooksPath override；前次正常 hook 因既有 SwiftLint 801 > 800 失敗，其他五項 Passed，
不修改上游 Swift。此例外僅此 commit，不能沿用至本次新 factsync 或任何未來 commit。
Normal non-force push 至 origin 的 docs/redefine-auth-subsystem-responsibilities，exit 0；
local／tracking／actual remote／PR #37 head 一致。PR OPEN／ready、CLEAN／checks [] 為交付 snapshot，
feature 當時 clean，543 protected files 與 implementation baseline byte-equal；dev tracked／index clean，
未追蹤 .vscode/ 保留。Plan-Creator 未重跑 Git／tests／GitHub，僅引用已查證證據。
DL-31 completed／visible → CH-29 active → HC-29 pending；matching 新 head review 是否 completed 尚未查證，
沒有 threads closure 證據，不宣稱 replied／resolved。State non-pass／automated visualReview pending 保留。
本次新四 formal delivery factsync 仍 local、未新 commit／push，不能當作遠端已 visible。
不 merge／release；需要新增 commit 時重新 staged-diff／exact message Human 確認，no-verify 不沿用。
Scope、locked contract 或 evidence 不明、需動 ReadOnly／generated artifact 或超六檔即停。
自動審批拒絕即停止該寫入並回報原始 action／拒絕理由，不繞過。
未執行實作／tests／Git／GitHub；新 commit message 確認及 final Human Check 保持。

## PC-34 — 最小 Rework 技術契約（Historical Snapshot）

> 本節全部 route／active gate／狀態措辭只記錄 PC-35 前 historical snapshot；非目前 route／gate。
> CH-28 新 finding 後停於 human-check，由上方 PC-35 授權 cycle 承接；不宣稱 completed 或 closure。
> 原技術契約、DL-30 visible、Human 接受單次偏離與歷史 unknowns 保留；唯一 current route 見 PC-35。

### Goal／In-Scope／Modify

`PRRT_kwDOUFu0Cc6ncU5E` 的 lifecycle JSON 僅新增 meta.document_language=zh-Hant。
移除此新增屬性後，整份 source 必須與 PC-34 baseline HEAD deep-equal；
existing locale、meta、nodes／edges、geometry、policy 皆保持。使用既有 pinned pre-generation overlay，
由標準 deliver 產生 root HTML／main SVG language 與 fresh receipts，不能修改 generated HTML／JSON。

`PRRT_kwDOUFu0Cc6ncU5K` 的 state 在 initial-decision 表達真互斥 send／neutral initial terminal；
initial terminal 直達、無 waiting-response、transport、HTTPResponse 或 response-policy predecessor，
failure surface 仍 deferred。只准必要 wording、neutral node／transition 及相連 presentation，
不鎖定新增 exact action／error／factory API 或座標。舊 11／12 限制僅於此分支 supersede；
既有 refresh eligible、refresh result 經 AuthRequester 回 flow、refresh-success 才授權一次
retained-original retry、refresh failure／ineligible／second401 terminal 及其他 geometry 不任意改。

`PRRT_kwDOUFu0Cc6ncU5P` 的 verifyReceipt 必須完整走訪 metadata 的任意深度 object／array，
含非 path key、array string、provenance.cwd／root／temp／command 等 path-bearing values。
驗收涵蓋任意 POSIX absolute、Windows drive／UNC／rooted 與兩種 separator 的 `..` traversal；
不得只查 path-key regex 或機器前綴黑名單。具體演算法與內部 representation
由 IM-34 在受限 producer 內選擇；規劃不擴 schema／API／全域 renderer。
有效 relative metadata 與原 receipt 保持可接受；檢查只驗證、不得改寫 receipt bytes。

### Non-Goal／Out-Of-Scope／ReadOnly／Written／Deleted

Written 與 ReadOnly 以 execution plan PC-34 exact allowlist 為準；本次只寫四 formal。
既有 `document-language.patch`／`upstream-pin.json` bytes、
743 pins／五 targets、typed schema／generated validator consistency 與 upstream
package/common/generator/CLI entry/i18n/template boundary 全部維持。
不改 normal／401、所有 canvas、canonical architecture／BC、Swift product／tests、
OAuth、其他 topic 或全域 Archify；不具體化 deferred interfaces。Deleted：無。

### TestCase／Delivery 與 bounded repair

兩 sources 每次 edit 後驗證，final showcase 9/9、0 errors／warnings 後 freeze，
再標準 deliver、捕捉原始 stdout 作 sidecar，核對 source／HTML SHA-256／bytes 與 relative metadata，
接續對 exact final HTML fresh visual-check；禁止手改 generated JSON／HTML／receipt。
Receipt 驗證失敗 exit nonzero 且保留舊 receipt；HTML 可能已完成 upstream commit，
必須停止核查，不能聲稱 HTML／receipt 雙檔 transaction。
Regression 包含 existing 七 tests、canonical containment／symlink fail-closed、
pin mismatch 寫入前拒絕、generator check／runtime 743 pins 與五 targets。
新增 metadata fixtures 必須建立於有效原 receipt，分別加入各 unsafe path 類別、
deep object／array string／非 path key，並有有效 relative／原 receipt byte-unchanged 正例。

沿用既有 Archify contract：focused composition correction 在最佳 errors count 持續改善時前進，
連續兩輪無改善則停並如實交 diagnostics；post-delivery perceptual correction 最多兩輪，
每輪都需 fresh validate／deliver／receipt／visual evidence，仍 failed 或需超 scope 時交獨立 Reviewer。
不自行增加輪次或創設 fallback。Lifecycle 四 viewport containment pass；
state 1440 scrollHeight=1035、1600／1920=1109 non-pass 與 2048 pass 保留，
readability／chrome 不回歸，最小／最大 light/dark 人工 inspection，不將 automated visualReview pending 改為 pass。

### 已查證輸入與來源

以下均引用 Dispatcher 的 human 授權與 `pc34_minimal_rework_preflight` Planner FINAL snapshot（2026-09-30），並非 Plan-Creator 重新執行 Git/GitHub 或測試：
human 最新明示「授權上述最小 rework 範圍」，完整對應三條 finding；
Planner verdict 為 approved sufficiency、無 missing inputs／required fix，僅允許 creation，不是 PR-34 approval。
Feature branch `docs/redefine-auth-subsystem-responsibilities` 的 local／origin／PR #37 head 同為
`22ff1e039ea7c22c701cc21319303e78a4ec0664`；feature clean，PR OPEN／ready／CLEAN、checks []。
Review `PRR_kwDOUFu0Cc8AAAABP68FTg` 已 completed（08:12:18Z），54 threads／36 unresolved；
原 33 known-fixed 仍未 closed，三新 finding 已分類、未 resolve。Dev 只為 tracked／staged clean，
未追蹤 `.vscode/` 保留。這些是具來源的時間點事實，後續須 fresh 查證，不能推論 closure。
Producer PC-34 baseline：743 pins、既有五 patch targets 不變；
`document-language.patch` 為 835272 bytes、SHA-256
`13fdd35be8205a0c0c3f8baa86a7ed1a2eb2caff84d0948193bb6208208098e5`；
`upstream-pin.json` SHA-256
`24057319e7e9bec052ff68f3efb0ddc2395dae4bff92a8edc545995ac1cfdd43`。
IM-33 原始 836320-byte historical report 保留原文，不倒改為本次真值。

### Current Route／Dispatch Contract — PC-34

```text
PC-34 completed → PR-34 completed／approved → IM-34 rework completed → TE-31 initial needs-rework（保留）／re-test completed／approved → RV-31 completed／approved → DL-30 completed／visible（Human 接受單次偏離）→ CH-28 active → HC-28 pending
```

PC-34 creation 交接時 PR-34 active／尚無獨立 verdict 為當時 snapshot。
2026-10-01 Human 直接確認：「確認 PR-34 approved／completed，授權同步 IM-34 active。」
獨立 `pr34_minimal_rework_plan_review` 原始 FINAL approved／required fix 無；
scope／allowlist／TC-34-01 至 TC-34-06／route／history／boundaries 一致，PC-34 足以受限 IM-34。
依 Human 確認同步 PR-34 completed／approved、IM-34 active 為當時 gate snapshot。
IM-34 completed handoff → TE-31 active 為當時 implementation 交接 snapshot。
現引用獨立 `te31_bounded_diagram_receipt_validation` 原始 FINAL needs-rework／required fix 1：
TC-34-03 command tokenizer 未拒絕 backtick 包覆的 unsafe path。
IM-34 rework active／TE-31 re-test pending 為 Tester 初次交接 snapshot。
當時引用 im34_bounded_diagram_receipt_fix 原始 FINAL rework completed handoff（historical snapshot）：
IM-34 rework completed、TE-31 initial needs-rework 保留／re-test active；PR-34 approved 保持，
不開新 cycle、不改契約，RV-31 及後續 pending。回修限既有 producer tokenizer／regression，
兩 sources／HTML／delivery receipts／visual evidence bytes 保留，re-test 以相關 producer fix 與其他 bytes unchanged 為主。
當時引用獨立 te31_recovery_focused_retest 原始 FINAL（historical handoff snapshot）：TE-31 re-test completed／approved、required fix 無，
交 RV-31 active；IM-34 rework completed、PR-34 approved 保持，DL-30／CH-28／HC-28 pending。
TE-31 initial needs-rework 與此前 re-test active 為 historical snapshots；核准來源為獨立 Tester，非 Human 新確認。
當時引用獨立 rv31_bounded_final_review 原始 FINAL（pre-delivery historical snapshot）：RV-31 completed／approved、required fix 無，
交 DL-30 active，限 exact staged diff／message preparation；PR-34 approved、IM-34 rework completed、TE-31 re-test approved 保持。
CH-28／HC-28 pending；DL-30 尚未 completed／visible、尚無本次 delivery SHA，未宣稱 thread closure。
Reviewer approval 來源為獨立 Reviewer，非 Human 新確認；新的 message confirmation 與 no-verify boundary 保持。
現依 Dispatcher 已查證交付與 Human 最新原文：「接受此單次偏離與已推送 commit，並授權受限事實／ledger 同步後續行 CH-28。」
DL-30 b830bb481d43ba552548859ecae9ae60511f783e completed／visible（Human 接受這次 workflow deviation），
交 CH-28 active → HC-28 pending；TE-31／RV-31 approved 與 initial needs-rework／歷史 exceptions 保留。
執行當時自行加入 hooksPath override 未另獲 Human 授權，獨立 Reviewer needs-rework／human boundary 保留；本次接受非追溯授權。
不得自行加入未來 hooksPath override；本次接受不授權 future override／no-verify／new commit message。
RV-31 approved 後才交 DL-30。Pending future steps 不是 approval 或執行 evidence。
DL-30 必須依 staged exact diff 與 git-commit-convention 提出具體單一 topic message，
取得新的 human 明確確認後才 commit／non-force push；DL-29 的 no-verify exception 不覆蓋新 commit。
Push visible 後 CH-28 才 fresh review／threads closure；只能處理已分類且可見證據支持的 findings，
unknown feedback 交 Dispatcher 分類／human boundary。HC-28 等 human final，不 merge／release。
CH-27 needs-rework／HC-27 pending 已由本 cycle 承接、標為 historical；沒有將其改為 completed 或 approved。

### IM-34 — Implementer 技術證據（非獨立 Gate）

以下引用 `im34_bounded_diagram_receipt_fix` 原始 FINAL；不是 Plan-Creator 自驗或 TE-31 approval。
Lifecycle 只加 document_language=zh-Hant，移除此欄位後與 HEAD deep-equal。
State final 為 12 states／13 transitions；新 neutral terminal 唯一 inbound 為 initial-decision、
無 outbound／I/O／waiting-response／response-policy，移除新 branch 並還原 initial wording 後 source 與 HEAD deep-equal。
Producer 遞迴檢查 keys／strings、objects／arrays／command tokens，拒絕 POSIX absolute、
Windows drive／UNC／rooted 與 slash／backslash traversal；raw receipt bytes preserved。
Metadata red：有效 receipt 加 provenance.cwd=/outside/local 原先未拒絕；green：70 unsafe 拒絕、
21 relative 通過。Final producer 9/9，含原七項、metadata 與真 run unsafe stdout 保留舊 receipt；
不是 HTML／receipt 雙檔 transaction。TE-31 特別獨立驗證 metadata command coverage 與 state 互斥。
兩 source final validate／deliver 均 9/9、0 errors／warnings，stdout／sidecar byte-equal；
743 pins／五 targets／patch／manifest baseline 不變。524 ReadOnly files combined SHA-256：
`7db96ab65189c458d4dc28ac091158c37370097be79d9abcb6418f9a14984dad`。
詳細 final hash／bytes、composition／manual repair 歷史與八張 captures 見 execution plan。
以上是 Implementer completion evidence；當時 TE-31 active 為 historical snapshot，initial needs-rework 與最新獨立 re-test 見下節。

### TE-31 — TC-34-03 Required Fix（既有契約）

引用獨立 te31_bounded_diagram_receipt_validation 原始 FINAL needs-rework／required fix 1：
archify-producer/run.mjs:88 tokenizer 不分 backtick。有效 lifecycle receipt 注入
commandMetadata.command 的三字串，verifyReceipt 接受但應 throw：
~~~text
node tool.mjs --arg=`/outside/local`
node tool.mjs --arg=`C:\outside\local`
node tool.mjs --arg=`../outside`
~~~
Tester 僅驗證字串，未執行這些 commands；雙引號／$() controls 已拒絕。
獨立80 unsafe／24 relative fixtures 通過且 bytes preserved，但 backtick finding 未修，
所以當時 TE-31 整體 needs-rework、不記 approved，為 initial finding snapshot。修正只限既有 tokenizer／regression，
兩 sources／HTML／delivery receipts／visual bytes 保留；re-test metadata command coverage
與相關 producer regression／其餘 bytes unchanged，原 IM-34 技術與 repair 歷史保留。

### IM-34 — Backtick Bounded Rework Evidence

2026-10-01 引用 im34_bounded_diagram_receipt_fix 原始 FINAL rework completed：
僅 run.mjs 新增 backtick delimiter、producer.test.mjs 新增 lifecycle fixture regression。
三 unsafe backtick POSIX／Windows／parent-traversal 字串原先被接受（red），回修後全拒絕（green）；
三 valid relative framing 仍接受、raw receipt bytes preserved。Producer tests10/10＝原9 groups＋新 regression。
無 shell execution、prefix blacklist 或 blanket backtick ban；不改 schema／API／其他契約。
這是 Implementer self-verification；當時 TE-31 initial needs-rework 保留／re-test active、未 test approved，為 historical snapshot。

### TE-31 — 獨立 Focused Re-test Evidence

2026-10-01 引用獨立 te31_recovery_focused_retest 原始 FINAL：TE-31 re-test completed／approved、required fix 無。
Tester 實際 producer 10/10、exit 0；獨立 matrix 110 unsafe 全拒絕、33 relative 全接受，
包含 backtick、Windows／POSIX／traversal、unknown key、deep object／array、quote／$() controls。
所有 buffer bytes preserved，未執行 command。18 份兩圖 artifacts 與 initial Tester fixture 逐 byte-equal，
TC-34-01／02／05 因 exact bytes unchanged 承接初驗；無新重生成、全 viewport rerun 或人工重閱宣稱。
524 ReadOnly 與 HEAD byte-equal；25-path allowlist 中實際 23 changed paths；743 pins、五 targets、
patch／manifest SHA-256 保持；Tester 當時確認四 route 一致、index empty、feature 無 untracked、diff check pass，
dev tracked／index clean，但未追蹤 .vscode/ 保留。回修只兩 producer files 的區間結論承接 Implementer
before／after 證據；本次獨立確認 current tokenizer／regression 與其他 ReadOnly bytes。
IM-34 rework completed、PR-34 approved 保持；TE-31 initial needs-rework 保留，當時交 RV-31 active（historical handoff snapshot），
DL-30／CH-28／HC-28 pending。State containment non-pass、automated visualReview pending 與全部歷史限制保留。

### RV-31 — 獨立 Bounded Final Review Evidence

2026-10-01 引用獨立 rv31_bounded_final_review 原始 FINAL：RV-31 completed／approved、required fix 無。
Reviewer 獨立 producer 10/10、exit 0；metadata／command backtick、fail-closed 與 raw bytes preservation 符合 PC-34。
Lifecycle 移除 document_language 後與 HEAD deep-equal；state 12／13，僅新增 neutral initial terminal branch，
移除新 branch／還原 initial wording 後與 HEAD deep-equal，policy／geometry 無漂移。
兩 source／HTML／receipt hashes 與 document_language=zh-Hant 一致；18 artifacts 與初驗 fixture byte-equal。
25-path allowlist／23 changed paths；其餘 526 tracked paths 與 HEAD byte-equal，包含兩份未變的 contact sheets，
與 Tester 的 524 ReadOnly 為不同分組，不能混稱同一集合。743 pins／五 targets／patch manifest 不變，
index empty、diff check pass，dev 未追蹤 .vscode/ 保留；Reviewer 當時確認四 route 一致與 rework historical truth。
Reviewer 親視 state 最大 light 與 lifecycle 最小 dark，未見新增遮擋；其他 visual 因 bytes unchanged 承接初驗，
未重生成或重跑全 viewport。State 三 containment non-pass、automated visualReview pending 與歷史限制保留。
當時交 DL-30 active，CH-28／HC-28 pending（pre-delivery historical snapshot）；尚未 delivery visible、thread closure 或 human final，未知 SHA 不填造。

### DL-30 — Delivery／Hook Deviation／Human Acceptance Facts

2026-10-01 本節引用 Dispatcher 已查證交付與獨立 dl30_hook_deviation_independent_review 最後 snapshot；Plan-Creator 未重跑 Git／tests／GitHub。
Commit b830bb481d43ba552548859ecae9ae60511f783e，parent 22ff1e039ea7c22c701cc21319303e78a4ec0664；
message 為「fix(auth-diagrams): 修正圖表語言、初始終態與收據路徑驗證」。23 files 均在 literal 25-path allowlist，
non-force push 後 local／origin tracking／actual remote ref／PR #37 head 一致，feature clean；
dev tracked／index clean、未追蹤 .vscode/ 保留，Sources／Tests／Package.swift bytes 不變。
正常 hook 五項 Passed，只有 SwiftLint 因 StaticIsolationTests.swift 801 行 > 800 失敗；post-hook scope／index／work bytes 不變。
實際重試 command（僅紀錄，不執行）：
~~~text
git -c core.hooksPath=/dev/null commit --no-verify -m 'fix(auth-diagrams): 修正圖表語言、初始終態與收據路徑驗證'
~~~
Implementer 承認多餘 -c 自行加入、未另獲 Human 授權；未先試單獨 --no-verify，也無額外 failure／審批拒絕原因。
獨立 Reviewer 因此 needs-rework／human boundary，該停點與偏離保留。-c 為單次 command override、非持久 config 寫入；
現在 feature／dev 無 core.hooksPath 設定、default 只有 active pre-commit，其餘 .sample。
缺少歷史 pre-commit config snapshot，不能證明 commit 當時不存在其他 active hooks。
Human 最新原文：「接受此單次偏離與已推送 commit，並授權受限事實／ledger 同步後續行 CH-28。」
這是現在接受該一次偏離與 published commit，不是執行當時 -c 已授權，亦不抹除 Reviewer finding。
今後禁止自行加 hooksPath override；本次接受不授權 future override／no-verify／new commit message。
Reviewer 最後 snapshot：PR OPEN／ready、base dev、CLEAN／checks []、54 threads／36 unresolved；
matching b830 review 尚未 submitted，latest review 是舊 22ff head 的 COMMENTED。這些非本次同步的 live claim，不能推論 review／closure 完成。
DL-30 completed／visible（Human 接受此次偏離）→ CH-28 active → HC-28 pending；initial needs-rework、TE-31／RV-31 approved、
state 三 non-pass／automated visualReview pending 保留。本次只四 formal local factsync，尚未新 commit／push。
