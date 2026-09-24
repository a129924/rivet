# Plan：Auth 子系統責任重定義

## Goal

以 documentation-and-diagram architecture topic 將 HTTP client auth subsystem 的
責任鎖定為 Model C：`AuthFlow` 只負責 authentication policy/state transition；
`AuthRequester` 獨占 original request 並解讀 semantic decision；`Requester` 維持
generic HTTP I/O。交付 long-lived architecture contract，為未來獨立的
concrete-consumer Swift implementation topic 建立可驗收的 capability boundary。

## Non-Goal

- 不實作或修改 Swift runtime、test、package manifest、public API 或 API migration。
- 不鎖定 `AuthAction`、header／decoration representation、failure surface、async
  signature、refresh endpoint、credential persistence、refresh component 或 result/event
  contract。
- 不處理 5xx/network retry、backoff、rate limit、circuit breaker、concurrent 401
  single-flight、OAuth runtime、GitHub consumer behavior。
- 不修改 OAuth dual-client lifecycle 文件／diagram，或任何既有 topic artifact。

## In-Scope

- Phase 1：建立四份 same-slug planning artifacts，固化現行 legacy Model A、adopted
  Model C、責任矩陣、Model A/B/C comparison、diagram/gate contract 與 human boundary。
- Phase 2：在 independent Plan Review `approved` 後，寫入 long-lived architecture
  document，修正 existing architecture index／legacy wording，並交付四張 adopted-target
  diagrams。
- diagrams 必須表達 component/dependency、normal request、401 refresh/retry boundary、
  AuthFlow state；401 圖只表達 topology，不能新增未鎖定的 credential runtime。
- PR #37 comment-fix：在獨立 Plan Review 後，最小修正 matrix/canonical document、
  lifecycle／401／state Archify source/generated evidence 與 package canvas build
  reproducibility；不重開 Model C 或定義 decoration/runtime API。
- RV-03 rework：由 `Auth` factory 在 initial semantic send 前建立 per-execution
  `AuthFlow`，使 `AuthRequester ↔ AuthFlow` semantic exchange 不再暗示取得預先存在的
  flow；lifecycle／401／state 的所有說明性圖文使用繁體中文，僅 identifier 可保留英文。
- 依已執行的 human delivery decision，PR #37 維持 **OPEN、ready for review**；只規劃
  後續 commit/push、thread resolution 與 human review，不改變 PR status。
- current PR #37 comment preflight = `needs-rework`：僅修正 401 sequence 的 caller entry 與
  `AuthRequester → Auth → AuthRequester` factory round-trip、state retry permission 作為進入
  waiting-for-retry-response 的 transition／event（而非 node）後再作 response policy 分支，以及 package canvas 對
  selected／decorated request preparation 的錯誤指派。exact preparation owner／representation
  仍 deferred，不新增 runtime role。
- RV-11 `needs-rework` 的 replacement 只允許移除 component-dependency canvas 將
  selected／decorated request preparation 指派給 `AuthRequester` 的錯誤表述；exact preparation
  owner／representation 維持 deferred。ledger 必須以 RV-11 `needs-rework` 為 current rework truth，
  不得將 IM-14 receipt regeneration 或 historical DL-03 當作 current gate。
- human-authorized state delivery-recovery redesign：只擴張 `auth-flow-state` topology/layout
  presentation，以消除 `[850,307]` 並恢復 normal standard delivery。PC-13／IM-11 將 retry permission
  表達為進入 waiting-for-retry-response 的 transition／event（非 lifecycle node），並只調整相連的
  state／transition presentation；保留 first-401 ineligible terminal、eligible refresh、
  refresh outcome 回 Flow policy、refresh-success-only exactly-one retry、waiting-for-retry-response →
  response-policy normal-success／second-401 terminal，且沒有
  receive→retry shortcut。PC-10／PR-10／IM-08 alternate-materialization failure為 historical evidence；
  不再是 current delivery path。state 必須 standard validate 9/9、0 errors／warnings、successful
  deliver/source-matched receipt；desktop containment 1035／1109／1109、2048 pass 維持 distinct
  non-pass。401/package、diff、scope、delivery 或 thread gates 均不放寬。
- post-merge four-thread correction：同步 `f277ac4`／`d2cefd4` 之後的 delivery/thread truth；以標準
  producer 交付 state receipt；將 component canvas 的 `AuthRequester → HTTPRequest` 限縮為 legacy
  Model A 編譯期 type dependency；並補 401 的唯一 terminal response／caller activation。這些是既有
  contract 的 evidence／expression 回修，不改 Model C 或 retry policy。

## Out-Of-Scope

- production `Auth`／`AuthFlow`／`AuthRequester`／`Requester` code、tests 或 manifest。
- 任意 auth scheme、header mutation、token refresh execution、credential update、error
  model、HTTP transport redesign。
- 將 `TokenFetcher`／`TokenProvider` 宣稱為既有 runtime 或新增兩者；matrix 的 N/A
  是目前唯一允許的表述。

## Swift Implementation Handoff

### Goal

future concrete-consumer topic 應依 adopted Model C，使 type contract 實際禁止
`AuthFlow` 持有 original request、建構 arbitrary/multiple `HTTPRequest` 或執行 I/O。
它必須使 flow 成為唯一 auth state/retry policy owner，並維持 `AuthRequester` 的
original request ownership 與 `Requester` 的 generic I/O boundary。

### Non-Goal

本 topic **沒有 Swift implementation**。它不選擇 exact action、factory API、
decoration、refresh use case、credential provider、failure 或 async surface；未來
implementer 不可從本 plan 推定這些 API。

### In-Scope

- 建立可供 future Swift implementation 採用的 responsibility/capability contract 和
  architecture evidence。
- 定義 future implementation 應能驗證的 policy invariant：normal terminal、first
  401 refresh request、refresh-success original retry、second 401 stop、refresh failure
  terminal。

### Out-Of-Scope

- 對任何 `Sources/`、`Tests/`、`Package.swift` 或 public declaration 的寫入。
- `AuthAction` case、HTTP header overlay、credential refresher、`AuthEvent`、token
  lifecycle type 或 mock/test-double design。

### ReadOnly

- 所有 Swift source、Swift tests、package manifests、existing `Auth`／`AuthFlow`／
  `AuthRequester`／`Requester` contracts。
- OAuth dual-client lifecycle document、canvas、lifecycle diagrams 與 evidence。
- 所有 existing topic artifacts，以及本 plan 未列出的 repository paths。

### Written

**Phase 1（現在）**只建立：

- `analysis/redefine-auth-subsystem-responsibilities/requirements.md`
- `analysis/redefine-auth-subsystem-responsibilities/technical-spec.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.plan.md`
- `plan/redefine-auth-subsystem-responsibilities/redefine-auth-subsystem-responsibilities.step.md`

**Phase 2（僅 final replacement gate PR-03 approved 後）**只新增：

- `docs/architecture/rivet-http-client-auth-responsibilities.md`
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/` 的 canvas、三份
  Archify source/generated artifacts 與其 validation/visual evidence。

### Modify

**Phase 1**：無既有檔修改。

**Phase 2（僅 final replacement gate PR-03 approved 後）**：

- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.html`
- 該 lifecycle 的 artifact-local validation／visual evidence
- `docs/architecture/diagrams/http-client-package-structure/scene.js`
- `docs/architecture/diagrams/http-client-package-structure/index.html`
- 該 canvas 的 artifact-local validation／visual evidence
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`，且僅限固定 build
  kicker／subtitle 的作者 arguments，以重現已交付繁體中文 HTML；enhancement script 與其餘
  build semantics 維持 ReadOnly。

所有修改只可澄清「現行 Model A 是 legacy runtime；Model C 是 adopted but
unimplemented target」，不得虛構新的 API 或 runtime。PR #37 comment-fix 可修正已由
Phase 2 Written allowlist materialize 的 canonical responsibility document，以及新 diagram
namespace 內 lifecycle／401／state 的 source、generated output、artifact-local evidence；
這不增加其他 Modify path。

current-comment rework 只允許修改：

- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.json`
  與其 generated HTML、artifact-local validation／visual-check evidence；
- `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/auth-flow-state.json`
  與其 generated HTML、artifact-local validation／visual-check evidence；
- `docs/architecture/diagrams/http-client-package-structure/scene.js`、`index.html` 與其
  artifact-local validation／visual evidence。

`BUILD.md`、enhancement script、lifecycle、normal sequence、canonical document、Swift、OAuth
及其他 paths 都維持 ReadOnly。

IM-15 的最小回修可修改
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/scene.js`、其
generated `index.html`、artifact-local validation／visual evidence 與 actual-step ledger evidence。
`BUILD.md`、enhancement script、401、state、lifecycle、normal sequence、canonical document、Swift、OAuth
與其他 path 均為 ReadOnly。

PC-18／IM-18 的 current override：新寫入僅限
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/auth-flow-state.delivery.json`。
可修改四份 planning artifacts 的 actual state／step evidence、`auth-flow-state.html` 及其 visual evidence、
`component-dependency/scene.js`／`index.html` 及其 evidence，以及 `401-refresh-retry.json`／HTML／receipt／
visual evidence。`auth-flow-state.json`、receipt producer 和其 tests 必須 ReadOnly；所有 state receipt
只能由 producer 標準產生。package canvas、canonical document、lifecycle、normal sequence、Swift、OAuth 與
未列出的 path 皆為 ReadOnly。

PC-10／PR-10／IM-08 alternate-materialization route 是 historical blocked evidence：public Archify
validate／deliver／render 都在 `[850,307]` proper-crossing 失敗，preview 沒有 source-matched output；
它不再是 current delivery path。

human 現明確授權僅 `auth-flow-state` 的 topology/layout presentation redesign。PC-13 將 IM-09
prior state-node formulation 以 IM-11 replacement 表達為 retry permission transition／event 進入
waiting-for-retry-response（非 lifecycle node）；IM-11 可只為此 restructure、merge 或 reposition
state／labels／areas／transitions，但不得改動下列 semantics：
first-401 ineligible/non-refresh-capable terminal、eligible refresh、refresh result 回 Flow policy、
refresh-success-only exactly-one retry、retry permission transition/event → waiting-for-retry-response →
response-policy normal-success／second-401 terminal，且沒有 receive→retry shortcut。不得擴張到 401、package canvas、
其他 diagrams、runtime API 或任何 deferred ownership。

state 的交付只能是 normal Archify showcase validate 9/9、0 errors、0 warnings、standard `deliver`
產生 source-matched HTML／receipt、visual evidence與 exact-delivered manual light/dark inspection；
`[850,307]` 必須消除。既有 desktop containment exception 維持 1035／1109／1109、2048 pass 的
distinct non-pass，不能稱 visual pass。401-refresh-retry 仍必須 standard 9/9、normal `deliver` 及
visual pass；package canvas 仍必須 validate/build/reproducibility/accessibility。

PC-12 分離 source modification 與 output materialization；PC-13 使 IM-11 保持 state-expression-only；
其後獨立 IM-10
source ReadOnly，只 materialize already-modified 401/package source。實際 current hashes 是 401 JSON
`edf7864d859bede17f9572d1a24dff31452ce8a4f0ec80ec14874c818cc5c798`／existing HTML
`f4e4d9f546a7f772127b008a7e64f7e01b47bc0d7fb3b142155992d4697c73ca`，package scene
`017bdfe15961912f24c6e479938fff17f6a85b6bc7069eeeaa9aefb2c336bc3f`／existing index
`ca7b3773ab24971f8f41172ad1489df29015b1a85f1abfb900115483f9aa03d2`；這些沒有 receipt/build relation
證明，不可推定為 source-matched。IM-10 必須以 401 validate → deliver → visual-check 和 package
validate → temporary build → enhance → verify 建立新 evidence，且不得修改 source、`BUILD.md` 或
enhancement script。TE-09 只驗證，絕不生成 output/evidence。

### PC-14 — 401 Visual-Pass Layout Repair

IM-10 的 package materialization 已通過（5 bands／15 boxes／22 edges、0 errors、0 warnings、
build→enhance→verify、byte-identical output），是既有有效 evidence，無須重做。401 source ReadOnly
delivery雖為 showcase 9/9、0 errors、0 warnings、source-matched，fresh visual-check 於 1440×900 = 1001、
1600×1000 = 1073 失敗；此非 state desktop containment exception。

human 授權 PC-14／PR-14／IM-12 只修改 `401-refresh-retry` diagram layout/source 以恢復所有 desktop
visual-check pass，**不是**新增 exception。此授權只 supersede IM-10 的 401 source-ReadOnly restriction；
package passed evidence、`BUILD.md`、enhancement script、state、Swift、OAuth、runtime API與其他 diagrams
仍為既定 scope／ReadOnly。

IM-12 不能改動 flow contract：caller→AuthRequester entry，AuthRequester→Auth per-execution flow request，
Auth→AuthRequester flow return 必須先於 request-less semantic exchange；Flow 不取得 original request。
同時保留 first-401 ineligible terminal、eligible refresh、refresh result 回 policy、refresh-success-only
exactly-one retry、waiting-for-retry-response→response-policy 的 normal-success／second-401 split與 no
receive→retry shortcut。交付要求為 standard showcase validate 9/9、0 errors、0 warnings、source-matched
`deliver`、1440×900／1600×1000／1920×1080／2048×1320 全數 visual pass、manual light/dark inspection。
route：PC-14 → PR-14 → IM-12 → TE-10 → RV-10 → DL-08 → CH-07 → HC-07；TE-10 只 verify。

### PC-15 — 401 Participant-Context Presentation Repair

human 授權將 participant sublabel expression 從 participant headers 移至 external context/explanation area，
只 supersede IM-12 的 all-sublabel-in-header presentation constraint。這不是 new exception，也不改 sequence
contract、retry policy、component identities 或 ownership。

IM-13 必須保留全部 17 sequence messages、caller→AuthRequester entry、AuthRequester→Auth per-execution
flow request、Auth→AuthRequester flow return 在 request-less exchange 前完成，且 Flow 無 original request
access。ineligible／eligible policy、refresh result 回 policy、success-only retry、waiting-for-retry-response →
response-policy normal-success／second-401 split及 no receive→retry shortcut均不變。每一 moved sublabel 的
external explanatory copy 必須保留原有意義，且不得 invent ownership、capability、runtime behavior 或
architecture decision。

IM-13 只可變更 `401-refresh-retry` participant/header/context presentation與 artifact-local delivery evidence；
仍須 standard showcase validate 9/9、0 errors、0 warnings、source-matched `deliver`、1440／1600／1920／2048
full visual pass、manual light/dark。package passed materialization evidence 維持且不重做。route：PC-15 → PR-15 →
IM-13 → TE-11 → RV-11；TE-11 只 verify。RV-11 `needs-rework` 已停止原本未開始的
DL-09 → CH-08 → HC-08 downstream route。

### IM-15 — Canvas Ownership／Ledger Minimal Rework

RV-11 `needs-rework` 只回交兩個 finding：component-dependency canvas 不得把
selected／decorated request preparation 指派給 `AuthRequester`；該角色只保有 caller original request
並解讀 semantic action，exact preparation owner／representation 保持 deferred。ledger 也必須如實將
RV-11 `needs-rework` 列為 current rework truth，不能將 IM-14 receipt regeneration 或 historical
DL-03 宣稱為 current gate。

這是已鎖定 contract 內的直接回修，不建立新的 Plan-Creator／Plan-Reviewer cycle。TE-12 initial 已
`needs-rework`；IM-15 rework 已完成同一個 bounded canvas finding 的回修，且 TE-12 re-test 已
`approved`。下列是 PC-18 前的 historical snapshot：TE-14 已 `approved`；當時 gate 為 RV-14。IM-15 的實作範圍
只可更新
`component-dependency/scene.js`、其 generated `index.html`、artifact-local validation／visual evidence
與 actual-step ledger evidence；`BUILD.md`、enhancement script、401、state、lifecycle、normal sequence、
canonical document、Swift、OAuth 與所有其他 paths 均為 ReadOnly。當時 historical route 為
TE-14（approved）→ RV-14（approved）→ DL-12（completed）→ CH-11（completed）→ HC-11（needs-rework）。

### PC-18 — Post-Merge Four-Thread Correction

此 section 是 PC-19 前的 historical workflow override。`f277ac4` 的 receipt correction 與 `d2cefd4`
的 conflict resolution 已交付；`DL-12`／`CH-11` completed，`HC-11` = `needs-rework`。任何本 plan
較早的 RV-14／DL-12／CH-11 current-route 表述僅是歷史 snapshot，不可作為 gate。

以下為 PC-18 當時的 current route，現為 historical snapshot：

```text
PC-18 (completed) → PR-18 → IM-18 → TE-15 → RV-15 → DL-13 → CH-12 → HC-12
```

PR-18 已由與 Plan-Creator 獨立的 Plan-Reviewer `approved`，確認本次只有四個 bounded findings；
IM-18／TE-15／RV-15／DL-13 已完成；TE-15／RV-15 verdict 均為 `approved`。CH-12 已完成，四個 thread
均已 resolved 且無未分類 feedback；HC-12 隨後收到兩項 P2 feedback，現為 `needs-rework`：

1. 四份 formal artifacts 如實同步上述 commit、delivery/thread history、current gate 與 PR #37
   OPEN／ready status；不預告 merge 或 release。
2. `auth-flow-state.json` 維持 ReadOnly，由既有 canonical-containment producer 以
   repository-relative parameters standard `deliver` 重建 HTML／新 receipt。receipt 必須包含 source／HTML
   SHA-256、showcase 9/9、0 errors、0 warnings 與完全 repository-relative metadata；state visual fact
   仍只可記錄 1035／1109／1109、2048 pass 的 accepted non-pass。
3. component canvas 的 `AuthRequester → HTTPRequest` edge 只可標示 legacy Model A 編譯期
   request-type dependency；不得暗示 adopted Model C request preparation、construction、ownership／dataflow
   transfer 或 I/O。canvas 仍須 validate、build、temporary rebuild byte-identical 與既有 accessibility baseline。
4. 401 sequence 只新增一則 terminal `AuthRequester → caller` final response 及對應 caller activation；
   message count 從 17 變為 18，新增 terminal response 為唯一 delta。factory prefix、no-payload
   exchange、Flow boundary、eligible refresh、result-to-policy、success-only retry、waiting-to-policy terminal
   split 與 no shortcut 不得變動，並重做 normal standard delivery／four-viewport visual pass。

PR-18 `approved` 後的 IM-18 allowlist 僅為：四份 planning artifacts 的 actual-step evidence；
`auth-flow-state.html`、新的 `auth-flow-state.delivery.json` 與 artifact-local visual evidence（state JSON
ReadOnly）；`component-dependency/scene.js`、其 `index.html` 與 artifact-local evidence；
`401-refresh-retry.json`、HTML、receipt、artifact-local visual evidence。receipt producer／tests、Swift、OAuth
dual-client lifecycle、package canvas、canonical document、lifecycle、normal sequence與其他 paths ReadOnly。
不得 delete、rename、move、手改 receipt 或改變 PR status。

TE-15 僅驗證 producer provenance/hash、state exact non-pass、canvas legacy boundary及 rebuild/accessibility、
401 one-message delta／caller activation／locked semantics／delivery/visual、scope、`git diff --check` 與 dev
clean；不得產生 output。RV-15 獨立確認四個 finding 已消除且無 drift。TE-15／RV-15 `approved` 後，DL-13 已依
既有授權完成 commit/push；CH-12 已完成四個 thread 的 resolve，重新取得結果無未分類 feedback。現在一律停在
HC-12 `needs-rework`，不 merge、不 release。

### PC-19 — Post-HC-12 Two-P2 Diagram Expression Rework

此 section 是 PC-20 前的 historical workflow override。human 已明示授權此 formal rework cycle。HC-12 final GitHub
verification 的兩項 P2 feedback 只要求已鎖定 contract 內的圖表 expression／layout 回修；它們不重新決定
Model C、retry policy、state topology、original-request ownership、deferred preparation owner 或 OAuth boundary。
PC-18 的 DL-13／CH-12 completed 與四個 resolved threads 均為 historical，不得重開或重新處理。

historical route 固定為：

```text
PC-19 (completed) → PR-19 (completed／approved) → IM-19 (completed) → TE-16 (completed／approved) → RV-16 (completed／approved) → DL-14 (completed) → CH-13 (needs-rework) → HC-13 (pending)
```

1. **P2-01 — package legacy type dependency**（`PRRT_kwDOUFu0Cc6knaR9`）：
   `http-client-package-structure` canvas 必須明示 `AuthRequester → HTTPRequest` 是 legacy Model A 的
   compile-time request-type dependency，並與 component-dependency canvas 一致。不得暗示 Model C target
   request preparation、construction、ownership、dataflow transfer 或 I/O；component canvas 是 ReadOnly。
2. **P2-02 — state route separation**（`PRRT_kwDOUFu0Cc6knaSA`）：`auth-flow-state` 的 retry-response
   transition 與 normal-terminal edge 必須只以 layout／route 分離，以消除假雙向箭頭。不得改變 retry policy、
   state topology、transition／terminal semantics、message contract 或 runtime behavior。

PC-19 已 completed；PR-19 已獨立審查並 `approved`，IM-19／TE-16／RV-16／DL-14 已 completed，TE-16／RV-16 verdict 為 `approved`，CH-13 為 `needs-rework`、HC-13 為 `pending`。這是 PC-20 前 historical route。IM-19 的 Written allowlist 僅為
四份 planning artifacts 的 actual-step evidence、
`http-client-package-structure/scene.js`／generated `index.html`／artifact-local evidence、以及
`auth-flow-state.json`／HTML／delivery receipt／artifact-local evidence。component-dependency canvas、401、
receipt producer／tests、Swift、OAuth、canonical docs、lifecycle、normal sequence 及所有其他 paths 是 ReadOnly；
不 delete、rename、move、merge 或 release。

TE-16 只驗證 package edge 的 legacy-only semantics／component consistency、state route separation 沒有假雙向
箭頭、policy/topology/contract no-drift、正常 validation／deliver、source-output-receipt provenance、state exact
non-pass truth、rebuild/accessibility 與 scope。RV-16 只在 TE-16 `approved` 後獨立審查。RV-16 `approved` 後
才可 DL-14；delivery visible 後 CH-13 處理兩項 P2 threads，並因後續 final feedback 為 `needs-rework`。

### PC-20 — Final PR Comment Rework

此 section 是 PC-20 的 historical workflow snapshot，不是 current override。human 已明示授權 PC-20 作為本 topic 最後一次 PR
comment rework。它只收斂既有圖表表達、validation evidence、delivery reply／resolve 與 README／bounded-
contexts additive base-conflict disposition；不新增 API、owner、retry policy、state topology、Swift 或 OAuth
behavior，也不重開 Model C contract。

HC-13 = `pending`，CH-13 = `needs-rework`。PR-20 的 `needs-rework` 已由 PC-20 最小 planning amendment
修正，PR-20 re-review 已 `approved`／`completed` 並成為 historical；IM-20 已 `completed`，TE-17／RV-17 已 `approved`／`completed`，DL-15 已於 `3abbc71` completed，CH-14 = `needs-rework`、HC-14 = `pending`，PC-20 route 為 historical：

```text
PC-20 amendment → PR-20 re-review → IM-20 → TE-17 → RV-17 → DL-15 (`3abbc71` completed) → CH-14 (needs-rework) → HC-14 (pending)
```

1. **P3-01**（`PRRT_kwDOUFu0Cc6knhr9`）：normal-request sequence 只補明 selected／decorated request
   representation 與 preparer deferred；不得新增 preparation owner、representation type、API 或 runtime behavior。
2. **P3-02**（`PRRT_kwDOUFu0Cc6knhsB`）：auth-flow lifecycle 的 refresh-failure terminal 只改為
   neutral／generic、非 success-styled presentation；terminal semantics、policy 與 topology 不變，且不得新增
   node、payload 或 API。
3. **P3-03**（`PRRT_kwDOUFu0Cc6knhsF`）：401 sequence 只分開 `Requester` initial／retry activation
   presentation；18 messages 固定，factory prefix、no-payload exchange、Flow boundary、retry policy與 message
   semantics 不變。
4. **P3-04**（`PRRT_kwDOUFu0Cc6knaSA`）：auth-flow-state 僅 revalidate existing source/output；不改 source、
   state topology、retry policy、contract 或 visual non-pass truth。
5. **P3-05**（`PRRT_kwDOUFu0Cc6knaR9`）：package canvas 僅 revalidate existing source/output；不改 source；
   delivery visible 後由 CH-14 reply／resolve。

README／bounded-contexts additive base conflict 只在 CH-14 留下 bounded disposition reply 後 resolve；actual additive
resolution 必須同時保留既有 OAuth runtime description 與 Model C auth canonical conclusion，兩者共存且不構成
long-lived-doc architecture change。`docs/architecture/README.md`、bounded-contexts、其他 canonical architecture docs
與所有 long-lived docs 均為 ReadOnly。

PR-20 是獨立 Plan-Reviewer gate。PR-20 `approved` 後，IM-20 的 Written allowlist 僅為四份 planning
artifacts 的 actual-step evidence、`normal-request.json`／HTML／artifact-local evidence、
`auth-flow-lifecycle.json`／HTML／artifact-local evidence、`401-refresh-retry.json`／HTML／receipt／artifact-local
evidence及必要 generated delivery evidence。`http-client-package-structure`／`auth-flow-state` source 僅可
revalidate，不可修改。component canvas、Swift、OAuth、receipt producer／tests、long-lived docs、canonical
README、其他 diagrams與所有未列 path 均為 ReadOnly；不得 delete、rename、move、merge 或 release。

IM-20 completion 必須確認 lifecycle 只作既有 terminal 的 neutral／generic presentation，未新增 node、payload 或 API。
TE-17 只驗證 normal／lifecycle／401 的 bounded presentation correction、401 18-message invariant、P3-02
no-node／no-payload／no-API assertion、package/state no-source revalidation，以及 README／bounded-contexts actual additive
resolution 同時保留 OAuth runtime description 與 Model C auth canonical conclusion、沒有 long-lived-doc architecture
change；並驗證 scope、source-output-delivery evidence與 state exact non-pass truth。RV-17 只在 TE-17 `approved` 後獨立審查
上述 P3-02 與 conflict criteria。僅 RV-17 `approved` 後才可 DL-15 commit/push；delivery visible 後 CH-14 只在確認
兩項 README／bounded-contexts conclusion 共存、無 long-lived-doc architecture change 時處理五項 P3、README base-conflict
reply／resolve與新取得已分類 feedback。DL-15 已於 `3abbc71` completed；CH-14 因新的 P2 receipt finding 為
`needs-rework`、HC-14 = `pending`，PC-20 route 為 PC-21 前 historical。

### PC-21 — Receipt-Only Final Rework

PC-21 是 historical receipt-only snapshot：DL-16 已以 `bccc183` completed／visible，CH-15 因 P5 feedback 為
`needs-rework`，HC-15 是 pending historical human boundary。唯一 **P4-01** `PRRT_kwDOUFu0Cc6koqlS` 只允許 normal-request／
auth-flow-lifecycle 的 standard producer-generated `.delivery.json` receipts 重新產生；不改 artifacts/source semantics。
以下 PC-21 route 是 historical snapshot，非 current route：

```text
PC-21／PR-21／IM-21／TE-18／RV-18 (completed／approved／historical) → DL-16 (`bccc183` completed／visible) → CH-15 (needs-rework) → HC-15 (pending historical)
```

PR-21 `approved` 後，IM-21 以 repository-relative input／output 和 `--repo-root` 重跑 standard `deliver`；Written
allowlist 只有兩份 receipt、四份 planning artifacts actual-step evidence及必要 artifact-local receipt/visual evidence。
每份 receipt 必須記錄並驗證 source／HTML hashes、9/9、0 errors、0 warnings與 provenance 無絕對路徑；normal-request／
auth-flow-lifecycle source、HTML、artifact semantics 均 byte-identical。四 viewport visual evidence 僅可 revalidate。

TE-18 只驗證 invocation、relative metadata、hash continuity、9/9／0／0、absolute-path absence、byte identity與必要
visual evidence；RV-18 只審查 P4-01/no-drift。僅 RV-18 `approved` 後，DL-16 才可依本 direct human execution authorization 將
receipt-only diff commit，並 normal push 至既有 PR #37 branch。只有 pushed commit 在既有 PR branch 可見且 P4-01 receipt evidence
已 verified 後，CH-15 才可 reply／resolve P4-01；其 closure 後的 P5 feedback 由 PC-22 承接。其他 diagrams/source/HTML、README/merge candidates、Swift、OAuth、producer/tests、state/package/401、
long-lived docs與未列 path ReadOnly；不得新增 contract/API/policy/topology/role/test implementation，也不得 delete、rename、move、merge 或 release。

### PC-22 — P5 Current-State and 401 Terminal-Decision Rework

human 已授權兩項 P5 thread 且 independent Planner verdict = ready。DL-16 `bccc183` completed／visible、CH-15=
`needs-rework`、HC-15=`pending` 為 historical；PC-22 completed／historical、PR-22 completed／approved／historical、IM-22 completed／historical、TE-19 completed／approved／historical、RV-19 completed／approved／historical，DL-17 `cc15069` completed／visible／historical；其後 DL-18 `51ae037` completed／visible。CH-16 因 `PRRT_kwDOUFu0Cc6k_x2f` 為 `needs-rework`、HC-16 pending，均為 PC-23 前 historical state。以下為 PC-22 historical route：

```text
PC-22 (completed／historical) → PR-22 (completed／approved／historical) → IM-22 (completed／historical) → TE-19 (completed／approved／historical) → RV-19 (completed／approved／historical) → DL-17 (`cc15069` completed／visible／historical) → DL-18 (`51ae037` completed／visible／historical) → CH-16 (needs-rework historical) → HC-16 (pending historical)
```

1. **P5-01** `PRRT_kwDOUFu0Cc6kqRi3`：只同步 stale current claim、current gate、current route 至 actual state；
   date-stamped historical snapshot、evidence、completed steps/closures 與 locked architecture 必須保留。
2. **P5-02** `PRRT_kwDOUFu0Cc6kqRi9`：唯一 artifact change 在 `401-refresh-retry`。18 existing message IDs/
   semantics 必須 byte-for-byte semantic equivalent；total 只能為 20。僅加兩則 mutually exclusive guarded
   `AuthFlow → AuthRequester` terminal decision：ineligible terminal/no refresh 及 refresh-failure terminal/no retry。
   禁止 caller failure return、payload、API、new state node/transition、policy、ownership 或 runtime behavior；保留
   original caller final response、factory/no-payload/retry semantics。

六個 fixed closure threads `PRRT_kwDOUFu0Cc6knhr9`、`PRRT_kwDOUFu0Cc6knhsB`、
`PRRT_kwDOUFu0Cc6knhsF`、`PRRT_kwDOUFu0Cc6knaSA`、`PRRT_kwDOUFu0Cc6knaR9`、
`PRRT_kwDOUFu0Cc6koqlS` 保持 resolved/historical、不得 reopen/reply/change。

Written/Modify allowlist 只有四份 planning artifacts 與
`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.{json,html,delivery.json,visual-check.*}`；
P5-01 只可變更 planning，P5-02 才可變更 401 set。其餘 diagrams/source/HTML/receipts/visual、README/merge、Swift/OAuth、
producer/tests、state/package/normal/lifecycle、long-lived docs及未列 path ReadOnly。PR-22 須獨立審查範圍；TE-19 須獨立驗證
stale-current historical preservation、六 closures、401 validate/deliver/receipt provenance/9/9/0/0/four-viewports、20 total、
18 exact old messages unchanged、only-two mutual-exclusive guarded terminals、及禁項 absent；RV-19 獨立 no-drift。TE-19/RV-19
approved 後 DL-17 依 direct authorization single-topic commit/normal-push existing PR branch；pushed commit/evidence visible
後 CH-16 回覆/resolve P5 threads、重抓確認 six closures resolved/no unclassified feedback，HC-16 human review；不 merge/release。

### PC-23 — P6 Component Canvas Raw-Response Route-Only Rework

human 對 exact thread `PRRT_kwDOUFu0Cc6lAdHo` 的 authorization 只涵蓋 component-dependency canvas raw `HTTPResponse`
edge route geometry，且 direct progression authority 只在此 scope 內適用。DL-18 `51ae037` completed／visible、CH-16=
`needs-rework`、HC-16=`pending` 均為 historical；PC-23／PR-23／IM-23／TE-20／RV-20／DL-19 已 completed／historical，PR-23／TE-20／RV-20 verdict=`approved`，DL-19=`6127b29` completed／visible；CH-17 因 exact ledger-only thread `PRRT_kwDOUFu0Cc6lAh5g` 為 `needs-rework`，HC-17=`pending`。下列為 PC-24 前 historical P6 closure lineage，非 current route：

```text
PC-23 (completed／historical) → PR-23 (completed／approved／historical) → IM-23 (completed／historical) → TE-20 (completed／approved／historical) → RV-20 (completed／approved／historical) → DL-19 (`6127b29` completed／visible／historical) → CH-17 (needs-rework) → HC-17 (pending)
```

1. **P6-01** `PRRT_kwDOUFu0Cc6lAdHo`：唯一 visual/source modification 是 component canvas raw-response edge 的 route
   geometry，使其可見終點在 `AuthRequester` box、非 legacy `HTTPRequest` box。endpoint semantics、label、contract、
   boxes、ownership 與 legacy Model A `AuthRequester → HTTPRequest` compile-time type dependency 全部不變，且絕不表示
   Model C preparation、construction、ownership、dataflow 或 I/O。
2. **Written/Modify**：只有四份 planning artifacts、component-dependency `scene.js`、generated `index.html` 與該
   canvas validation/build/enhance/a11y/temporary-rebuild reproducibility/visual evidence。**ReadOnly**：其餘 diagram/
   document/source、README、Swift、OAuth、producer、tests、receipts、package、401、normal、lifecycle、state、Git/GitHub
   與未列 path。**Deleted**：無；不得 delete、rename、move、merge 或 release。
3. **TestCase**：TE-20 必須獨立證明 raw-response edge 的 visible termination=`AuthRequester`，而 endpoint
   semantics/label/contract、boxes/ownership/legacy edge 不變；並驗證 source/output/evidence consistency 與
   validation/build/enhance/a11y/repro/visual pipeline。不得新增 product test 或改動任何其他 artifact。

PR-23 僅審查 P6-01 edge-route / ReadOnly boundary；`approved` 才授權 IM-23。RV-20 僅在 TE-20 `approved` 後審查
no-drift；TE-20/RV-20 approved 後，DL-19 才可依 direct progression authority 建立單一 topic commit、normal push 至既有
PR branch。pushed commit/evidence visible 後 CH-17 才可 reply/resolve 全部十個 fixed threads：
`PRRT_kwDOUFu0Cc6knhr9`、`PRRT_kwDOUFu0Cc6knhsB`、`PRRT_kwDOUFu0Cc6knhsF`、
`PRRT_kwDOUFu0Cc6knaSA`、`PRRT_kwDOUFu0Cc6knaR9`、`PRRT_kwDOUFu0Cc6koqlS`、
`PRRT_kwDOUFu0Cc6kqRi3`、`PRRT_kwDOUFu0Cc6kqRi9`、`PRRT_kwDOUFu0Cc6k_x2f`、
`PRRT_kwDOUFu0Cc6lAdHo`。重抓 feedback 確認十個皆 resolved、無未分類 feedback後停在 HC-17 human review；不 merge/release。

### Deleted

無。不得刪除、搬移或更名 source、test、manifest、docs、diagram 或 topic artifact。

### TestCase

- **TC-01**：Phase 1 changed paths 僅含四份 listed artifacts。
- **TC-02**：四份 artifacts 對 matrix 的每格、legacy/target distinction 和
  `TokenFetcher`／`TokenProvider` N/A 結論一致。
- **TC-03**：future Swift implementation 可證明 flow 的 normal terminal、first 401
  refresh（僅 eligible refresh-capable flow）、refresh-success original retry、second 401
  stop、ineligible／refresh failure terminal；
  本 topic 不新增或執行此等 Swift test。
- **TC-04**：future type/API test 可證明 `AuthFlow` 不可 arbitrary request/endpoint
  construction 或 I/O；若無法證明，implementation 不可聲稱完成 Model C。
- **TC-05**：長期文件和四圖只在 Plan Review approved 後建立；圖表 owner 一致，401
  圖不虛構 refresh runtime。
- **TC-06**：architecture-canvas validate/build/light-dark inspection，及每份 Archify（含 redesigned
  state）的 showcase 9/9、0 error、0 warning、deliver、visual-check/exact output inspection 均有
  independent evidence；state desktop containment 是唯一保留的 exact non-pass，永不得稱 visual pass。
  不得發布 artifact.cafe。
- **TC-07**：source/tests/manifests、OAuth dual-client lifecycle 與歷史 topics 維持
  ReadOnly。
- **TC-08**：`AuthRequester` 在 requirements、technical spec 與 canonical document 的
  「Builds original request」均為「否」；只保有 caller original request，selected／decorated
  representation deferred，未新增 API/runtime role。
- **TC-09**：lifecycle、401、state 的 source/output/evidence 表達 one per-execution flow、
  `Auth` factory 先建立 flow、無 request-payload semantic exchange、refresh result 回 flow、
  只有 refresh-success retry 與 ineligible／refresh-failure terminal。
- **TC-10**：只由 `BUILD.md` 的固定 kicker／subtitle 作者 arguments 使 package canvas
  pipeline 重現已交付繁中 HTML；enhancement script/build semantics 無其他變更。
- **TC-11**：lifecycle、401、state 的所有說明性文案均為繁體中文，以「request 資料」、
  「資格」、「延後確定」、「更新成功」取代 payload、eligibility、deferred、refresh-success
  的解釋；英文僅作 identifier。
- **TC-12**：PR #37 維持 OPEN、ready for review；PR-07 至 CH-02 不改變 PR status，
  DL-03 後才可 resolve thread，最終由 HC-02 human review。
- **TC-13**：401 sequence 在 semantic exchange 前依序表達 caller original-execution entry、
  `AuthRequester → Auth` per-execution-flow request、`Auth → AuthRequester` flow return；
  flow 不取得 original request。
- **TC-14**：state retry permission 是進入 waiting-for-retry-response 的 transition／event，並非
  lifecycle node；該 waiting state 的 response policy 才分支 normal-success 或 second-401 terminal，
  沒有直接 shortcut。
- **TC-15**：package canvas 不將 selected／decorated request preparation 指派給
  `AuthRequester` 或新 role，並明確維持其 exact owner／representation deferred。
- **TC-16**：delivered head 歷史為 RV-04 approved、DL-03 active；PC-10／PR-10／IM-08 blocked 是
  alternate-materialization history，IM-09 blocked 是 prior state-node/layout history；current preflight
  `needs-rework` 必須走 PC-13 → PR-13 → IM-11 → IM-10 → TE-09 → RV-09 → DL-07 → CH-06 → HC-06。
  CH-06 重新取得 thread state 後，必要項依修正
  resolve，非必要項留言後 resolve。
- **TC-17**：state presentation 可 restructure／merge／reposition，但同時保留 first-401 ineligible
  terminal、eligible refresh、result 回 Flow policy、refresh-success-only exactly-one retry、retry
  waiting state後的 response-policy normal-success／second-401 terminal，且沒有 receive→retry shortcut。
- **TC-18**：`[850,307]` 必須消除；state 必須 normal validate 9/9、0 errors/warnings、standard
  deliver/source-matched receipt、visual evidence與 manual light/dark inspection。desktop containment
  1035／1109／1109、2048 pass 維持 distinct non-pass、不可稱 visual pass。
- **TC-19**：401 sequence 仍為 standard 9/9、normal deliver、visual pass；package canvas 維持
  validate/build/reproducibility/accessibility；其他 diagram/canvas、`git diff --check`、scope、
  source-output matching、delivery 或 thread gate 一律未獲豁免。
- **TC-20**：IM-10 僅 materialize 已修改 401/package source，401 必須 validate → deliver →
  visual-check，package 必須 validate → temporary build → enhance → verify；`BUILD.md`／enhancement
  script/source 全部 ReadOnly。TE-09 只驗證 IM-11/IM-10 的 evidence，不生成任何 output/evidence。
- **TC-21**：IM-12 是唯一可改 401 layout/source 的 step，不是 new exception；保留 caller entry、
  per-execution Auth factory round-trip、Flow 無 original request access，及 ineligible/eligible、
  refresh-result policy、success-only retry/waiting-response-policy/no-shortcut semantics。
- **TC-22**：IM-12 必須 standard validate/deliver 9/9、0 errors、0 warnings、source-match，1440×900、
  1600×1000、1920×1080、2048×1320 全數 visual pass並 manual light/dark；package passed materialization
  evidence 不重做。PC-14 → PR-14 → IM-12 → TE-10 → RV-10 → DL-08 → CH-07 → HC-07 是 historical route，
  不是 current route。
- **TC-23**：IM-13 只將 participant sublabel expression 移到 external context/explanation area；17 messages、
  caller/factory/no-payload contract、Flow 無 original request access、retry policy和 component identities不變。
- **TC-24**：每個 moved sublabel 在 external copy 中保留原有 explanatory meaning，且不 invent ownership、
  capability、runtime behavior 或 architecture decision；這不是 exception。
- **TC-25**：IM-13 standard source-matched delivery 為 9/9、0 errors、0 warnings，1440×900、1600×1000、
  1920×1080、2048×1320 全數 visual pass並 manual light/dark；package evidence不重做。PC-15 → PR-15 →
  IM-13 → TE-11 → RV-11 是 historical route；RV-11 `needs-rework` 後，未開始的 DL-09 → CH-08 → HC-08
  不是 current route。
- **TC-26**：RV-11 `needs-rework` 只允許修正 canvas 對 selected／decorated request preparation 的
  `AuthRequester` 錯誤指派，exact owner／representation 仍 deferred；TE-12 initial = `needs-rework`、
  re-test = `approved` 後，IM-15 rework → TE-12 re-test（approved）→ TE-14（approved）→
  RV-14（approved）→ DL-12（completed）→ CH-11（completed）→ HC-11（needs-rework）是 historical snapshot。不得建立新的
  planning cycle，且在 RV-14 approved 前不得 commit/push、reply 或 resolve thread。
- **PM-01**：PC-18 是 PC-19 前 historical override；`f277ac4`／`d2cefd4`、DL-12／CH-11 completed、
  HC-11 `needs-rework`、DL-13／CH-12 completed 與 HC-12 `needs-rework` 在四份 artifacts 一致。PC-20 →
  PR-20 → IM-20 → TE-17 → RV-17 → DL-15 → CH-14 → HC-14 是 historical snapshot，不是 current route；
  PC-19 至 DL-14 已 completed、CH-13 = `needs-rework`、HC-13 = `pending` 亦為 historical。DL-18 `51ae037` completed／visible、CH-16 needs-rework、HC-16 pending 亦為 historical；唯一 current route 為 PC-24 transition-count amendment（completed／historical）→ PR-24 re-review（completed／approved／historical）→ IM-24（completed／historical）→ TE-21（completed／approved／historical）→ RV-21（completed／approved／historical）→ DL-20（active）→ CH-18 → HC-18。
- **PM-02**：state JSON ReadOnly；canonical-containment producer 以 repository-relative parameters
  產生 state receipt，receipt hash／9/9／0 errors／0 warnings／relative metadata 一致，state 1035／1109／1109、
  2048 pass 維持 exact non-pass。
- **PM-03**：component canvas 中 `AuthRequester → HTTPRequest` 是 legacy Model A 編譯期
  request-type dependency，絕非 Model C preparation、construction、ownership/dataflow transfer 或 I/O；
  source/output/rebuild/accessibility evidence 一致。
- **PM-04**：401 由 17 增至 18 messages，唯一新增的是 terminal
  `AuthRequester → caller` final response 與其 caller activation；factory/no-payload/retry-policy contract、
  source-matched 9/9 與四 viewport visual pass 不變。
- **PM-05**：PR-18／TE-15／RV-15 已 `approved`；DL-13／CH-12 已 completed，四個 thread 均已
  resolved、無未分類 feedback；HC-12 因 P2-01／P2-02 為 `needs-rework`。四個 resolved threads 保持
  historical，不得重開。PC-19 route 已在 CH-13 = `needs-rework`、HC-13 = `pending` 停止；PC-20 至
  DL-15=`3abbc71` completed、CH-14=`needs-rework`、HC-14=`pending` 均為 historical。DL-18 `51ae037` completed／visible、CH-16 needs-rework、HC-16 pending 亦為 historical；唯一 current route 為 PC-24 transition-count amendment（completed／historical）→ PR-24 re-review（completed／approved／historical）→ IM-24（completed／historical）→ TE-21（completed／approved／historical）→ RV-21（completed／approved／historical）→ DL-20（active）→ CH-18 → HC-18。
- **P2-01**：`PRRT_kwDOUFu0Cc6knaR9` 要求 package canvas 也明示 `AuthRequester → HTTPRequest` 僅為
  legacy Model A compile-time request-type dependency，並與 component canvas 一致，非 Model C
  preparation／construction／ownership／dataflow／I/O。
- **P2-02**：`PRRT_kwDOUFu0Cc6knaSA` 要求 state retry-response transition 與 normal-terminal edge
  只作 layout／route separation，避免假雙向箭頭，不改 retry policy、state topology 或 contract。
- **P3-01**：`PRRT_kwDOUFu0Cc6knhr9` 只補 normal-request selected／decorated representation 與 preparer
  deferred 的明示；不指派 `AuthRequester` 或新 role。
- **P3-02**：`PRRT_kwDOUFu0Cc6knhsB` 只將 lifecycle refresh-failure terminal 表達為 neutral／generic、
  non-success-styled；semantics、policy 與 topology 不變，且不得新增 node、payload 或 API。
- **P3-03**：`PRRT_kwDOUFu0Cc6knhsF` 只拆分 401 Requester initial／retry activation presentation；18 messages、
  factory／no-payload／retry semantics 不變。
- **P3-04／P3-05**：state `PRRT_kwDOUFu0Cc6knaSA`、package `PRRT_kwDOUFu0Cc6knaR9` 只 revalidate
  existing source/output；不改 source。delivery visible 後才 reply／resolve；README／bounded-contexts additive
  base conflict 只作 comment disposition，並須確認 OAuth runtime description 與 Model C auth canonical conclusion
  共存、沒有 long-lived-doc architecture change。
- **P4-01**：`PRRT_kwDOUFu0Cc6koqlS` 僅重建 normal-request／auth-flow-lifecycle producer-generated receipts；
  repository-relative `--repo-root` deliver 必須證明 source/HTML hash、9/9、0／0、provenance 無 absolute path與 byte identity；
  DL-16 必須 commit 並 normal push 至既有 PR branch，只有 pushed commit 可見且 receipt evidence verified 後 CH-15 才可 reply／resolve。
- **P5-01**：`PRRT_kwDOUFu0Cc6kqRi3` 只校正 stale current claim/gate/route，保留 DL-16 `bccc183` completed／visible、
  CH-15 needs-rework、HC-15 pending historical 及所有 dated evidence/closure。
- **P5-02**：`PRRT_kwDOUFu0Cc6kqRi9` 只修改 401 artifact set：18 existing message IDs/semantics 不變、total=20，
  僅兩則 mutually-exclusive guarded `AuthFlow → AuthRequester` terminal（ineligible/no refresh、refresh-failure/no retry）；
  無 caller failure return/payload/API/state node/transition/policy/ownership。

## Implementation Phases and Gates

### Phase 1 — Planning Artifacts

- **Owner**：Plan-Creator。
- **Action**：只建立四份 listed artifacts；不得寫入 long-lived docs、diagrams 或
  production code。
- **Exit**：PC-01 completed 後交獨立 Plan-Reviewer；Plan-Creator 不判定 approval。

### Plan Review Lineage and Final Replacement Gate

- **Historical review**：PR-01 與 PR-02 均為 `needs-rework`，分別修正 ASCII
  dependency/data-flow topology 與 approval-gate ID consistency；兩者都不是 IM-01
  的 entry gate。
- **Final gate**：PR-03 是 PR-01／PR-02 rework 後的唯一 replacement Plan Review。
  Owner 是獨立 Plan-Reviewer，且不得是 Plan-Creator。只有 PR-03 的明示
  `approved` 才滿足本 plan 的「Plan Review approved」條件並授權 IM-01。
- **Pass criteria**：Model C 未被重開；matrix、legacy/target truth、allowlist、
  deferred API、OAuth isolation、diagram validation 與 human boundary 一致。
- **Triage**：`needs-rework` 只交回 Plan-Creator；`blocked`／`human-check` 停止並
  交還 human。PR-03 以外的任何 verdict 均不授權 implementation。

### Phase 2 — Documentation and Diagrams

- **Owner**：independent Implementer；僅 PR-03 `approved` 後。
- **Action**：寫入允許的 long-lived docs/diagrams；architecture-canvas 用於
  responsibility/dependency，Archify 用於 sequence/state，作者內容使用繁體中文。
- **Exit**：完成 validation/evidence，交獨立 Tester；不執行 Swift implementation。

### Verification, Delivery and Human Boundary

- **TE-01 history / TE-02 replacement**：TE-01 的 `needs-rework` 保留為歷史，不能
  作為 delivery gate。TE-02 是唯一 independent replacement verification gate；其
  `approved` 等價本 topic verification pass，證明 allowlist、`git diff --check`、
  legacy/target truth、OAuth isolation、diagram evidence 已被獨立驗證。
- **TE-03 re-test / state exception**：TE-03 是 IM-02 diagram-localization correction
  的 independent re-test，必須 `approved`，但不取代 TE-02 的 replacement truth。
  TE-02／TE-03 `approved` 不將 AuthFlow state diagram 的 human accepted
  desktop containment limitation 改寫為 visual-check pass；它維持 non-pass exception。
- **RV-01 → PR-04 → RV-02**：RV-01 `needs-rework` 只回交 verification/delivery
  gate wording。Plan-Creator 修正後，PR-04 必須由 independent Plan-Reviewer
  re-review；只有 PR-04 `approved` 才可進入 RV-02 independent Reviewer re-review。
- **RV-02 / Reviewer**：獨立判定 scope、contract、workflow drift；發現 drift 時
  `needs-rework` 優先保守收斂，無 drift 才可明示 `approved`。
- **No-major-issue gate**：只有 **TE-02 = `approved`、TE-03 = `approved` 且 RV-02 =
  `approved`** 才定義為「無重大問題」並授權 historical DL-01；任何其他 status 或 verdict
  不得交付。
- **RV-03 rework workflow**：RV-03 = `needs-rework` 後，PC-07 Plan-Creator amendment
  必先經 PR-07 independent Plan Review；其 approved 才可進入 IM-04 bounded correction。
  IM-04 後必經 TE-05 independent Tester 與 RV-04 independent Reviewer。兩者 approved 後，
  DL-03 才可依 topic delivery contract commit/push 到既有 **OPEN、ready-for-review** PR #37；
  不開新 PR，也不得改變其 status。此為 PC-08 前的 historical workflow；delivered head 只記錄
  DL-03 = `active`，不構成 current delivery authorization。
- **CH-02 / Implementer**：historical DL-03 delivery 完成後才可處理 thread。依 supplied evidence
  reply+resolve T06；T01/T02/T03/T05/T07/T08/T09 只在各自 corrected delivery visible 時
  resolve；T04 只在 reproducibility fix visible 時 resolve。此刻不得以此 historical route
  處理任何 current thread。
- **HC-02 / Human**：historical CH-02 完成後停在 human review；不得 merge、release 或進入 Swift
  implementation。
- **Current comment-rework workflow**：delivered head 僅保留 RV-04 = `approved`、DL-03 =
  `active` 的歷史；PC-08／PR-08 是 current preflight `needs-rework` 的 historical correction
  lineage，PC-09／PR-09／IM-07 blocked 與 PC-10／PR-10／IM-08 blocked 均為 historical recovery
  evidence。它們都不得改變 PR status 或越過 current state-redesign contract。
- **Human-authorized state-recovery amendment**：PC-11 僅將 state topology/layout redesign 寫入四份
  planning artifacts。PR-11 的 independent Plan Review 必須確認 scope 只限 state presentation、
  locked semantics、`[850,307]` 必須消除、state normal 9/9/0-error/0-warning/deliver/source-match、
  desktop exception unchanged 與 all-other-gates preservation；`approved` 才可進入 IM-09。
- **PC-13 / Plan-Creator → PR-13 / Independent Plan-Reviewer**：PC-13 將 retry permission 的
  state-node formulation 改為進入 waiting-for-retry-response 的 transition／event，不改 retry policy；
  並 supersede alternate HTML materialization path。PR-13 必須確認 no-policy-change、locked semantics、
  normal state delivery、desktop exception與 IM-10 boundary；只有 `approved` 可進入 IM-11。
- **IM-11 / Implementer**：只在 `auth-flow-state` 將 retry permission 改為 transition／event，並為此
  restructure／merge／reposition presentation states、labels、areas／transitions；維持 locked semantics。
  必須完成 standard Archify validate 9/9、0 errors／warnings、standard deliver/source-matched receipt、
  visual evidence與 manual light/dark inspection；不得重用 alternate-materialization path。無法同時滿足時
  停止並交還 human。
- **IM-10 / Independent Implementer**：在 IM-11 完成後，不修改 source，只 materialize already-
  modified artifacts：401 按 standard validate → deliver → visual-check 建立 source-match/9-of-9/
  0-error/visual-pass evidence；package canvas 按 validate → temporary build → enhance → verify
  materialize `index.html` 並證明 reproducibility/accessibility/source-output consistency。`BUILD.md`/
  enhancement script 維持 ReadOnly。
- **TE-09 / Independent Tester**：只有 IM-11/IM-10 都完成才可開始，只驗證 source/output/evidence、
  locked semantics、scope 與 gates；不得 generate、build、deliver 或更新任何 output/evidence。
- **CH-06 / Implementer**：DL-07 corrected delivery visible 後，重新取得當時仍未解決的 threads。
  四個必要 findings 只有修正可見時 resolve；非必要 findings 必須先留下說明再 resolve。不得在
  DL-07 前 reply/resolve，且不得以歷史 DL-03／CH-02 越過此 gate。
- **HC-06 / Human**：CH-06 完成後停在 human review；不得 merge、release 或進入 Swift
  implementation。
- **PC-14 / Plan-Creator → PR-14 / Independent Plan-Reviewer**：PC-14 只建立 401 visual-pass
  layout/source repair，不是 new exception。PR-14 必須確認它只 supersede IM-10 的 401 source-ReadOnly
  restriction、package evidence保留、flow semantics/other scope不變；`approved` 才可進入 IM-12。
- **IM-12 / Implementer**：只調整 `401-refresh-retry` layout/source及其 delivery evidence，完整保留
  flow contract與 policy semantics；必須 9/9、0 errors/warnings、source-matched deliver、四個 desktop
  viewport visual pass與 manual light/dark。不得改 package、state、Swift、OAuth或其他 diagrams。
- **TE-10 → RV-10 → DL-08 → CH-07 → HC-07**：TE-10 只驗證 IM-12與既有 package evidence；RV-10
  independent review 後才能 DL-08 delivery；corrected delivery visible 後 CH-07 才重新取得／處理 threads，
  最後停在 HC-07 human boundary。
- **PC-15 / Plan-Creator → PR-15 / Independent Plan-Reviewer**：PC-15 只將 participant sublabel expression
  移至 external context/explanation area。PR-15 必須確認這不是 exception、17 messages/contract/policy/component
  identities與 package evidence不變；`approved` 才可進入 IM-13。
- **IM-13 / Implementer**：只變更 `401-refresh-retry` participant/header/context presentation及 artifact-local
  delivery evidence。每個 moved sublabel 保留 explanatory meaning、不 invent ownership；必須達成 9/9、0 errors/
  warnings、source-matched deliver、四個 viewport full pass與 manual light/dark。
- **TE-11 → RV-11**：TE-11 只驗證 IM-13和既有 package evidence；RV-11 `needs-rework` 已停止原本未開始的
  DL-09 → CH-08 → HC-08 downstream route。
- **RV-11 → IM-15 rework → TE-12 re-test**：RV-11 的兩項 finding 均未改變 locked contract，故直接由
  IM-15 回修 canvas ownership wording／edge 與 ledger current-gate truth，不建立新的 planning cycle。TE-12 initial
  `needs-rework` 後，IM-15 rework 已完成；TE-12 re-test 已 `approved`。
- **Historical TE-14 → RV-14 → DL-12 → CH-11 → HC-11**：RV-14 approved 後才可 DL-12 delivery；
  DL-12／CH-11 已 completed，HC-11 = needs-rework。這是 PC-18 前歷史，並不構成 current route。
- **Historical PC-18 route**：PC-18 → PR-18 → IM-18 → TE-15 → RV-15 → DL-13 → CH-12 → HC-12 是
  `f277ac4`／`d2cefd4` delivered 後四個 stable review finding 的 historical route。PR-18 已獨立審查
  formal-state sync、state producer receipt、legacy type edge 與 401 terminal return 的 bounded contract，並
  `approved`；IM-18、TE-15、RV-15、DL-13、CH-12 已依序完成，TE-15／RV-15 均 `approved`，四個 thread
  均已 resolved、無未分類 feedback；HC-12 因兩項 P2 feedback 為 `needs-rework`。
- **Historical PC-19 route**：PC-19／PR-19／IM-19／TE-16／RV-16／DL-14 均已 completed，PR-19／TE-16／RV-16
  已 `approved`；CH-13 = `needs-rework`、HC-13 = `pending`。P2-01 的 package legacy Model A type dependency
  與 P2-02 的 state layout route separation 均保持 historical，不改 Model C、retry policy、state topology、Swift 或 OAuth。
- **PC-20 historical route**：PC-20 amendment → PR-20 re-review → IM-20 → TE-17 → RV-17 → DL-15
  (`3abbc71` completed) → CH-14 (needs-rework) → HC-14 (pending)。DL-16 `bccc183` completed／visible、CH-15 needs-rework、
  HC-15 pending 均為 historical；DL-18 `51ae037` completed／visible、CH-16 needs-rework、HC-16 pending 亦為 historical；PC-24 transition-count amendment（completed／historical）→ PR-24 re-review（completed／approved／historical）→ IM-24（completed／historical）→ TE-21（completed／approved／historical）→ RV-21（completed／approved／historical）→ DL-20（active）→ CH-18 → HC-18 是唯一 current route。
  P5-01 只更正 stale current state；P5-02 只寫 401 source/output/receipt/visual、18 existing IDs/semantics unchanged、
  total=20/two guarded terminals。所有其他 diagrams/source/HTML、README/merge candidates、Swift、OAuth、producer/tests、
  state/package/normal/lifecycle 與 long-lived docs ReadOnly。

### PC-24 — Lifecycle Policy-Return Projection + Component Edge Route Separation

DL-19 `6127b29` completed／visible、CH-17=`needs-rework`、HC-17=`pending` 是 historical P6 closure state；
PC-24 不重開 architecture。transition-count amendment 與 PR-24 re-review 均已 completed／approved／historical；IM-24 completed／historical，TE-21 completed／approved／historical，RV-21 completed／approved／historical，DL-20 active。唯一 current route：

```text
PC-24 transition-count amendment (completed／historical) → PR-24 re-review (completed／approved／historical) → IM-24 (completed／historical) → TE-21 (completed／approved／historical) → RV-21 (completed／approved／historical) → DL-20 (active) → CH-18 → HC-18
```

1. **BDat／PR-24 re-review completed／approved／historical；IM-24 completed／historical；TE-21 completed／approved／historical；RV-21 completed／approved／historical；DL-20 active** `PRRT_kwDOUFu0Cc6lBDat`：既有 planning amendment、layout-only expansion 與
   completed／approved review 均為 historical；PC-24 transition-count amendment 與 PR-24 re-review 均
   completed／approved／historical，IM-24 completed／historical，TE-21 completed／approved／historical，RV-21 completed／approved／historical，DL-20 active。source 唯一識別
   11 state IDs／11 transition IDs。
   exhaustive allowlist 僅有：`refresh-success-result` 保留 ID／`from: start-finish`，`to: resend` → `to: receive`，
   label `成功結果回到流程` → `更新結果經 AuthRequester 回到流程`；`refresh-failure-terminal` 保留 ID，
   `from/to: start-finish → receive-finish` → `receive → resend`，新增 label `更新成功：允許一次重試`。前者使
   external update-results 返回既有 `AuthFlow receive` policy input，後者是既有 receive→resend one-time-retry edge，
   不再有 external→terminal failure edge。

   唯一 state text changes：`start-finish.sublabel` `更新失敗時終態` → `更新結果待回傳流程`；
   `receive.sublabel` `正常／首次 401 的資格判斷` → `正常回應／首次 401／更新結果`（既有 `label: 回應策略`／
   `tag: 僅限 AuthFlow` 不變）；`receive-finish.tag` `正常／不具資格／第二次 401` →
   `正常／不具資格／第二次 401／更新失敗`。`terminal-decision` 的 ID、`receive → receive-finish` 端點與
   所有既有設定必須保留。其他所有 edge ID/from/to/label、state ID/count、policy、event、API、payload、ownership、
   retry-policy capability byte-identical；不得新增／移除 state 或 edge。

   layout-only added allowlist：`receive-finish.width` `110 → 140`；`refresh-success-result.toSide`
   `right → top`、`via=[[220,479],[220,220],[556,220]]`、`labelAt=[430,210]`；
   `refresh-failure-terminal.toSide` `right → top`、移除 `via` 以 straight route、`labelAt=[556,380]`。
   僅 geometry/layout 可變；11 state IDs／11 transition IDs、既定 edge semantics／from/to／labels、state policy、API、
   payload、ownership、retry invariants 必須不變。TE-21 必須確認 9/9、0 errors／0 warnings、`properCrossings`、
   `ambiguousCorridors`、label issues=0、minimum clearance ≥16.1px，然後標準 deliver／visual；component candidate 不可動。
2. **BDaw** `PRRT_kwDOUFu0Cc6lBDaw`：只將 component raw-response last route points
   `[972,610] → [972,509] → [960,509]` 變為 `[972,610] → [972,540] → [954,540]`；semantic label/endpoints、boxes/
   ownership、legacy edge byte-identical。
3. **Written/Modify**：四份 formal artifacts；`docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`、
   existing sibling generated HTML、standard producer receipt、existing artifact-local visual evidence sidecars（discover exact
   existing sibling names only）；`docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency/scene.js`、
   其 `index.html` 與 existing local evidence。**ReadOnly**：其餘 diagrams/docs/Swift/OAuth/producer/tests/未列 paths。
   **Deleted**：無。
4. **TestCase**：TE-21 獨立驗證 lifecycle validate/deliver=9/9、0 errors、0 warnings、repo-relative receipt
   source/HTML hash、four viewport/light-dark pass；component validate/build/enhance/a11y/temp rebuild/visual、route
   coordinates 與 no-drift。不得新增 product tests。
5. **Delivery／closure**：PR-24 approved 才 IM-24；TE-21／RV-21 approved 才 DL-20 single-topic commit + normal push
   existing PR branch。visible 後 CH-18 exact closure set 為 `PRRT_kwDOUFu0Cc6knaR9`、`PRRT_kwDOUFu0Cc6knaSA`、
   `PRRT_kwDOUFu0Cc6knhr9`、`PRRT_kwDOUFu0Cc6knhsB`、`PRRT_kwDOUFu0Cc6knhsF`、`PRRT_kwDOUFu0Cc6koqlS`、
   `PRRT_kwDOUFu0Cc6kqRi3`、`PRRT_kwDOUFu0Cc6kqRi9`、`PRRT_kwDOUFu0Cc6k_x2f`、`PRRT_kwDOUFu0Cc6lAdHo`、BDat、BDaw；
   BDat／BDaw direct resolve；`PRRT_kwDOUFu0Cc6knaR9` comment + resolve；其餘 9 fixed IDs direct resolve。重抓 feedback
   有未知 ID 即停 HC-18；不 merge/release。

## Branch Naming

建議 branch：`docs/redefine-auth-subsystem-responsibilities`。

此為命名建議，不授權建立、切換、刪除或推送 branch。
