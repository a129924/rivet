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
已 completed（四個 thread 已 resolved、無未分類 feedback）。HC-12 隨後收到兩項 P2 feedback，現為
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

human 已明示授權此 formal rework cycle。PC-19 是既有 architecture contract 內的最小 post-HC-12 rework，
已 `completed`，PR-19／TE-16／RV-16 verdict 為 `approved`，DL-14 已 completed；CH-13 = `needs-rework`、
HC-13 = `pending`，故 PC-19 為 PC-20 前 historical route。不重新決定 Model C、retry policy、state topology、
original-request ownership、deferred preparation owner 或 OAuth boundary。

HC-12 = `needs-rework` 的兩項 precise P2 feedback 為：

1. **P2-01**（`PRRT_kwDOUFu0Cc6knaR9`）：`http-client-package-structure` canvas 必須新增或明示
   `AuthRequester → HTTPRequest` 只屬 legacy Model A 的編譯期 request-type dependency。它必須與
   component-dependency canvas 的既有 edge 一致；不得被標示或解讀為 Model C target request preparation、
   construction、ownership、dataflow transfer 或 I/O。component-dependency canvas 維持 ReadOnly。
2. **P2-02**（`PRRT_kwDOUFu0Cc6knaSA`）：`auth-flow-state` 的 retry-response transition 與
   normal-terminal edge 只可透過 layout／route 分離，消除假雙向箭頭的視覺讀法。不得新增、移除或改變
   retry policy、state topology、transition／terminal semantics、message contract 或 runtime behavior。

PC-19 的 P2-01／P2-02 已由 DL-14 completed delivery 處理；它們只保留為 historical evidence。

### PC-20 — Final PR Comment Rework

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

human authorization 與 independent Planner ready verdict 已足夠建立 PC-22；不需新 design choice。DL-16 `bccc183`
completed／visible，CH-15=`needs-rework`、HC-15=`pending` 均為 historical。PC-22 已 completed／historical、PR-22 completed／approved／historical、IM-22 completed／historical、TE-19 completed／approved／historical、RV-19 completed／approved／historical，DL-17 active。唯一 current route：

```text
PC-22 (completed／historical) → PR-22 (completed／approved／historical) → IM-22 (completed／historical) → TE-19 (completed／approved／historical) → RV-19 (completed／approved／historical) → DL-17 (active) → CH-16 → HC-16
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

## Validation and Gate Contract

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
  resolved、無未分類 feedback）、HC-12 `needs-rework`；`f277ac4` 與 `d2cefd4` 僅為已交付歷史，
  PC-19 至 DL-14 已 completed、CH-13 = `needs-rework`、HC-13 = `pending` 亦為 historical；PC-20 至
  CH-14=`needs-rework`、HC-14=`pending`，PC-21 至 DL-16 `bccc183` completed／visible、CH-15=`needs-rework`、
  HC-15=`pending` 均為 historical。唯一 current route 為 PC-22（completed／historical）→ PR-22（completed／approved／historical）→
  IM-22（completed／historical）→ TE-19（completed／approved／historical）→ RV-19（completed／approved／historical）→ DL-17（active）→ CH-16 → HC-16。
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
  resolved、無未分類 feedback。HC-12 因 P2-01／P2-02 為 `needs-rework`，PC-18 route 為 historical；
  PC-19 route 已在 CH-13 = `needs-rework`、HC-13 = `pending` 停止；PC-20 已在 DL-15 completed、CH-14
  needs-rework、HC-14 pending 後 historical；DL-16 `bccc183` completed／visible、CH-15 needs-rework、HC-15 pending
  亦為 historical；PC-22（completed／historical）→ PR-22（completed／approved／historical）→ IM-22（completed／historical）→ TE-19（completed／approved／historical）→ RV-19（completed／approved／historical）→ DL-17（active）→ CH-16 → HC-16 是唯一 current route。
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
