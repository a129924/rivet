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

所有修改只可澄清「現行 Model A 是 legacy runtime；Model C 是 adopted but
unimplemented target」，不得虛構新的 API 或 runtime。

### Deleted

無。不得刪除、搬移或更名 source、test、manifest、docs、diagram 或 topic artifact。

### TestCase

- **TC-01**：Phase 1 changed paths 僅含四份 listed artifacts。
- **TC-02**：四份 artifacts 對 matrix 的每格、legacy/target distinction 和
  `TokenFetcher`／`TokenProvider` N/A 結論一致。
- **TC-03**：future Swift implementation 可證明 flow 的 normal terminal、first 401
  refresh、refresh-success original retry、second 401 stop、refresh failure terminal；
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
  `approved`** 才定義為「無重大問題」並授權 DL-01；任何其他 status 或 verdict
  不得交付。
- **DL-01 / Implementer**：只在 no-major-issue gate 後，依 user-authorized topic
  delivery intent 與 `git-commit-convention`，取得 human-confirmed message 後
  commit by topic、push、open **draft PR**。
- **HC-01 / Human**：draft PR 建立後立刻停在 human review；不得 merge、release、
  處理未授權 review comment 或進入 Swift implementation。

## Branch Naming

建議 branch：`docs/redefine-auth-subsystem-responsibilities`。

此為命名建議，不授權建立、切換、刪除或推送 branch。
