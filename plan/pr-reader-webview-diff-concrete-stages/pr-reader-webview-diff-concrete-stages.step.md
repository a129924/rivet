# pr-reader-webview-diff-concrete-stages — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-concrete-stages`
- Current phase: Historical deviation correction；待新的獨立 Plan-Reviewer 審查
- Ledger rule: status 與 checklist 不構成 approval；只有指定獨立角色的明示 verdict 可通過 gate。

## Goal

在既有 PR Reader WebView diff pipeline 中實作 internal concrete Validator、Parser、Renderer 與 `GitDiffTemplate`，將 `DiffSnapshot` 轉為 opaque internal `RenderPlan`；有 patch 使用 diff2html line-by-line rendering，no-patch 保留 metadata-unavailable entry。

## Non-Goal

不實作 Output、DOM、CSS、UI、HTML safety、Swift bridge、viewed persistence、公開 API／Port／contract／dependency 變更；不實作 side-by-side、file list 或 no-patch skip。

## In-Scope

- Internal structural Validator、immutable per-file VO、unified Git diff template、Parser、Renderer 與 tests。
- concrete stage verified 後，最小 docs truth amendment。
- 本 topic 四份 formal artifacts。

## Out-Of-Scope

- `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public barrel、manifest、lockfile、existing dependency artifacts 的變更。
- patch syntax validation、snapshot mutation、diff2html internals／HTML 對外洩漏，以及非既定 docs truth 的 architecture／BC 修改。

## File Operations

- ReadOnly: `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency artifacts。
- Written: requirements、technical spec、execution plan、此 ledger；`concrete-stages/` 下 internal modules 與 tests。
- Deleted: 無。
- Modify: 僅必要 test harness，及 concrete success 後的 architecture README／PR Reader BC 既定 truth statement。

## TestCase

- Validator structural cases：valid、identity、uniqueness、status、rename、boolean、safe counter、patch type。
- Template／Parser status cases、no-patch metadata、invalid diff／exception `parse-error`。
- Renderer configuration、order／identity、HTML／metadata entries、exception `render-error`。
- Existing UseCase composition 的 success 必須以既有 non-DOM `DiffOutputPort` test double 斷言 renderer 的 RenderPlan 恰被接收一次；三種 stage failure short-circuit 才斷言 Output 未呼叫；不得有 DOM call。
- Implementer 必須依 TypeScript TDD 取得可歸因 red failure、最小 strict TypeScript green 與僅在持續 green 下的 refactor evidence；Tester 獨立執行 frozen install、check、test、coverage、diff check。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立同 slug 四份 formal artifacts，完整記錄 locked scope、file impact、tests、gates 與 human boundary。 | 四份 artifacts 已建立；不構成 Plan-Reviewer approval。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查初版 artifacts。 | 明示 required corrections：success flow 必須以既有 non-DOM Output test double 驗證單次 RenderPlan 接收；補入 TypeScript TDD red-green-refactor 與 evidence gate。 |
| PC-02 | completed | Plan-Creator | 僅更新四份 artifacts，納入 PR-01 required corrections，不變更 locked scope。 | 本次 artifact correction；不構成 Plan-Reviewer approval。 |
| PC-03 | completed | Plan-Creator | Human 已接受 pre-gate historical deviation 後，如實記錄 implementation 在 PR-02 pending 時開始，以及可歸因的歷史 evidence 與 corrective routing。 | 不回溯核准 PR-02；不補造 red／green evidence；保留所有原始 gates。 |
| PR-02 | pending | Plan-Reviewer | 新的獨立 Plan-Reviewer 審查 PC-02 corrections、scope、contract preservation、file impact、TDD evidence gate 與 routing。 | 尚無獨立明示 verdict。 |
| IM-01 | pending | Implementer | 僅於 PR-02 `approved` 後，在 feature worktree 依 TypeScript TDD 實作 internal concrete stages、tests 與允許 truth amendment。 | 尚無 Implementer handoff；必須含 attributable red failure 與 green／refactor evidence。 |
| TE-01 | pending | Tester | IM-01 明示完成後，獨立執行 frozen install、check、test、coverage、diff check，確認 success test 的 non-DOM Output test double 恰收取一次 RenderPlan，且只在三種 stage failure 時未呼叫 Output；DOM 未被觸及。 | 尚無 Tester result。 |
| RV-01 | pending | Reviewer | 獨立審查 implementation scope、locked contracts、docs truth 與 Tester evidence。 | 尚無獨立 Reviewer verdict。 |
| DL-01 | pending | Implementer | 僅於 RV-01 `approved` 後，依 human 已明示授權 commit by topic、push、開 draft PR。 | 尚無 delivery evidence。 |
| HC-01 | pending | Human | draft PR 建立後進行 human review。 | DL-01 後停止自動前進。 |

## Blockers

- Human 已接受 pre-gate historical deviation：implementation 在 PR-02 pending 時開始；此接受不構成 PR-02 approval，也不會回填 IM-01、TE-01 或 RV-01 的 gate status。
- 可歸因的歷史 evidence：Implementer 報告最初 red tests 因 target modules 尚未存在而失敗、後續 rework red tests 與其後 green checks；Tester 獨立報告 frozen install、check、test、coverage、diff check command evidence；technical Reviewer 已提供 implementation review result。這些 evidence 僅供 fresh independent review 檢視，不能取代 gate verdict。
- PC-03 已完成，尚待新的獨立 Plan-Reviewer 對 PR-02 明示 `approved`。其後仍須新的獨立 Reviewer 對 implementation 與本 correction 進行 fresh review；在其明示 `approved` 前不得進入 DL-01。
- 任一需要修改 public contract、dependency、DOM／Swift、HTML safety policy 或既定 BC boundary 的需求，必須標示 `blocked` 或交還 human，不得擴張本 topic。

## Human Check

- `DL-01` 完成後，停止於 `HC-01` human draft-PR review；human 是唯一可決定後續變更或合併的人。

## Last Updated

- Updated by: Plan-Creator
- Update reason: Human 接受 pre-gate historical deviation；如實記錄現有 evidence、保留 PR-02 pending 與 corrective routing。
- Update status: PC-03 completed；PR-02、IM-01、TE-01、RV-01 與 DL-01 維持原狀，status 不構成 approval。
