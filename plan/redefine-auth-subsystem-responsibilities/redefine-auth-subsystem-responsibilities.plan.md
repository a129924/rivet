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
- **TC-06**：architecture-canvas validate/build/light-dark inspection，及每份 Archify
  showcase 9/9、0 error、0 warning、deliver、visual-check/exact output inspection 均有
  independent evidence；不得發布 artifact.cafe。
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
  不開新 PR，也不得改變其 status。
- **CH-02 / Implementer**：DL-03 completed 後才可處理 thread。依 supplied evidence
  reply+resolve T06；T01/T02/T03/T05/T07/T08/T09 只在各自 corrected delivery visible 時
  resolve；T04 只在 reproducibility fix visible 時 resolve。此刻沒有任何 thread 可 resolve。
- **HC-02 / Human**：CH-02 完成後停在 human review；不得 merge、release 或進入 Swift
  implementation。

## Branch Naming

建議 branch：`docs/redefine-auth-subsystem-responsibilities`。

此為命名建議，不授權建立、切換、刪除或推送 branch。
