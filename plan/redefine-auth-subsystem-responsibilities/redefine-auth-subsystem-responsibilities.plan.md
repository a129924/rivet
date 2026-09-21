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
`approved`。目前 gate 為 RV-12。IM-15 的實作範圍
只可更新
`component-dependency/scene.js`、其 generated `index.html`、artifact-local validation／visual evidence
與 actual-step ledger evidence；`BUILD.md`、enhancement script、401、state、lifecycle、normal sequence、
canonical document、Swift、OAuth 與所有其他 paths 均為 ReadOnly。current route 固定為
IM-15 rework → TE-12 re-test（approved）→ RV-12（current）→ DL-10 → CH-09 → HC-09。

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
  re-test = `approved` 後，ledger 的 current route 必須是 IM-15 rework → TE-12 re-test（approved）→
  RV-12（current）→ DL-10 → CH-09 → HC-09。不得建立新的
  planning cycle，且在 TE-12/RV-12 approved 前不得 commit/push、reply 或 resolve thread。

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
- **IM-15 rework → TE-12 re-test（approved）→ RV-12（current）→ DL-10 → CH-09 → HC-09**：IM-15 只修正 component-dependency canvas
  及其 evidence；RV-12 approved 後才可 DL-10 delivery。corrected delivery visible 後，CH-09 重新取得
  exact thread evidence：必要事項修正後 resolve，非必要事項留言後 resolve，最後停在 HC-09 human boundary。

## Branch Naming

建議 branch：`docs/redefine-auth-subsystem-responsibilities`。

此為命名建議，不授權建立、切換、刪除或推送 branch。
