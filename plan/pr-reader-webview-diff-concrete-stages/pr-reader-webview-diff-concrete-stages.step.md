# pr-reader-webview-diff-concrete-stages — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-concrete-stages`
- Current phase: Responsibility-boundary correction planning；待新的獨立 Plan-Reviewer 審查
- Ledger rule: status 與 checklist 不構成 approval；只有指定獨立角色的明示 verdict 可通過 gate。

## Goal

在既有 PR Reader WebView diff pipeline 中實作 internal concrete Validator、Parser、Renderer 與 `GitDiffTemplate`，將 `DiffSnapshot` 轉為 opaque internal `RenderPlan`；有 patch 使用 diff2html line-by-line rendering，no-patch 保留 metadata-unavailable entry。

## Non-Goal

不實作 Output、DOM、CSS、UI、HTML safety、Swift bridge、viewed persistence、公開 API／Port／contract／dependency 變更；不實作 side-by-side、file list 或 no-patch skip。

## In-Scope

- Internal structural Validator、immutable per-file VO、unified Git diff template、Parser、Renderer 與 tests；Validator 只驗 raw `DiffSnapshot`，Parser 只接收 validated input 並處理 diff2html third-party-result defense。
- concrete stage verified 後，最小 docs truth amendment。
- 本 topic 四份 formal artifacts。

## Out-Of-Scope

- `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public barrel、manifest、lockfile、existing dependency artifacts 的變更。
- patch syntax validation、snapshot mutation、diff2html internals／HTML 對外洩漏，以及非既定 docs truth 的 architecture／BC 修改；UseCase 對 diff2html、unified diff 或 parsed shape 的認知；以 placeholder SHA 或任何 `index ` 行偽造 Git object identity。

## File Operations

- ReadOnly: `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency artifacts。
- Written: requirements、technical spec、execution plan、此 ledger；`concrete-stages/` 下 internal modules 與 tests。
- Deleted: 無。
- Modify: 僅必要 test harness，及 concrete success 後的 architecture README／PR Reader BC 既定 truth statement。

## TestCase

- Validator structural cases：valid、identity、uniqueness、status、rename、boolean、safe counter、patch type。
- Template／Parser：four-status source 沒有 `index ` 行且仍可 parse/render；no-patch metadata；empty patch success；nonempty malformed patch、incomplete diff2html result／exception 為穩定且不洩漏的 `parse-error`。第三方結果 helper 命名為 `isCompleteDiff2HtmlParseResult`，不作 raw snapshot 重驗。
- Renderer configuration、order／identity、HTML／metadata entries、exception `render-error`。
- Existing UseCase composition 的 success 必須以既有 non-DOM `DiffOutputPort` test double 斷言 renderer 的 RenderPlan 恰被接收一次；三種 stage failure short-circuit 才斷言 Output 未呼叫；不得有 DOM call。
- Implementer 必須依 TypeScript TDD 取得可歸因 red failure、最小 strict TypeScript green 與僅在持續 green 下的 refactor evidence；Tester 獨立執行 frozen install、check、test、coverage、diff check。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立同 slug 四份 formal artifacts，完整記錄 locked scope、file impact、tests、gates 與 human boundary。 | 四份 artifacts 已建立；不構成 Plan-Reviewer approval。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查初版 artifacts。 | 明示 required corrections：success flow 必須以既有 non-DOM Output test double 驗證單次 RenderPlan 接收；補入 TypeScript TDD red-green-refactor 與 evidence gate。 |
| PC-02 | completed | Plan-Creator | 僅更新四份 artifacts，納入 PR-01 required corrections，不變更 locked scope。 | 本次 artifact correction；不構成 Plan-Reviewer approval。 |
| PC-03 | completed | Plan-Creator | Human 已接受 pre-gate historical deviation 後，如實記錄 implementation 在 PR-02 pending 時開始，以及可歸因的歷史 evidence 與 corrective routing。 | 不回溯核准 PR-02；不補造 red／green evidence；legacy steps 保持 historical pending，並建立後續 corrective route。 |
| PC-04 | completed | Plan-Creator | Historical artifact-writing fact：僅更新四份 formal artifacts，記錄本次責任邊界 correction、無 SHA/no-index template policy、Parser third-party-result defense 與新的 TDD acceptance。 | 不改 TS、docs、dependencies 或 Git；不回填任何舊 step status；不是 correction gate 或 prerequisite。 |
| PR-02 | pending | Plan-Reviewer | Permanently pending historical-deviation entry；不再執行或產生後續 routing。 | 不構成任何 correction delivery prerequisite。 |
| IM-01 | pending | Implementer | Permanently pending historical-deviation entry；不再執行或產生後續 routing。 | 不構成任何 correction delivery prerequisite。 |
| TE-01 | pending | Tester | Permanently pending historical-deviation entry；不再執行或產生後續 routing。 | 不構成任何 correction delivery prerequisite。 |
| RV-01 | pending | Reviewer | Permanently pending historical-deviation entry；不再執行或產生後續 routing。 | 不構成任何 correction delivery prerequisite。 |
| DL-01 | pending | Implementer | Permanently pending historical-deviation entry；既有 draft PR 的建立不由本 step 重新執行。 | 不構成任何 correction delivery prerequisite。 |
| HC-01 | pending | Human | Permanently pending historical-deviation entry；不產生後續 routing。 | 不構成任何 correction human-review prerequisite。 |
| PR-03 | pending | Plan-Reviewer | 獨立審查 locked responsibility-boundary correction：確認 Validator／UseCase／Parser 責任分離，template 無 blob SHA 或 `index ` 行，及 correction TDD acceptance 與 routing。 | 尚無獨立明示 verdict。 |
| IM-02 | pending | Implementer | 僅於 PR-03 `approved` 後，以新的可歸因 TDD cycle 實作 bounded correction：新增 failing tests 後，修正 internal Validator／Parser／template 邊界與 no-index behavior。 | 必須含 four-status no-index parse/render、nonempty malformed stable/no-leak `parse-error`、empty-patch success 的 red 與 green evidence；不得觸及 ReadOnly surface。 |
| TE-02 | pending | Tester | IM-02 明示完成後，獨立執行 frozen install、check、test、coverage、diff check。 | 必須驗證 correction test cases 與既有 checks；尚無 Tester result。 |
| RV-02 | pending | Reviewer | TE-02 明示完成後，獨立審查 correction scope、責任邊界、ReadOnly preservation、TDD evidence 與 Tester evidence。 | 尚無獨立 Reviewer verdict。 |
| DL-02 | pending | Implementer | 僅於 RV-02 `approved` 後，依既有 human delivery authorization 將 correction 以 topic commit 推送至既有 draft PR branch。 | 尚無 delivery evidence；不得另開 PR。 |
| HC-02 | pending | Human | DL-02 後，人類重新審查既有 draft PR 的 correction。 | DL-02 後停止自動前進。 |

## Blockers

- Human 已接受 pre-gate historical deviation：implementation 在 PR-02 pending 時開始；此接受不構成 PR-02 approval，也不會回填 IM-01、TE-01 或 RV-01 的 gate status。PR-02、IM-01、TE-01、RV-01、DL-01 與 HC-01 永久維持 pending historical entries，不得作為 correction delivery prerequisite。
- 可歸因的歷史 evidence：Implementer 報告最初 red tests 因 target modules 尚未存在而失敗、後續 rework red tests 與其後 green checks；Tester 獨立報告 frozen install、check、test、coverage、diff check command evidence；technical Reviewer 已提供 implementation review result。這些 evidence 僅供 fresh independent review 檢視，不能取代 gate verdict。
- `PC-03 → PR-03 approved → IM-02 → TE-02 → RV-02 approved → DL-02 → HC-02` 是唯一 authoritative path。
- PC-04 僅為 historical artifact-writing fact，不是 PR-03 的 target 或 prerequisite。尚待新的獨立 Plan-Reviewer 對 PR-03 明示 `approved`；在 PR-03、IM-02、TE-02 與 RV-02 完成各自明示 gate 前，不得執行 DL-02。
- 任一需要修改 public contract、dependency、DOM／Swift、HTML safety policy 或既定 BC boundary 的需求，必須標示 `blocked` 或交還 human，不得擴張本 topic。

## Human Check

- `DL-02` 完成後，停止於 `HC-02` human re-review；human 是唯一可決定 correction 是否接受或合併的人。`HC-01` 是 historical entry，不參與此路徑。

## Last Updated

- Updated by: Plan-Creator
- Update reason: PC-04 artifact correction 與 final routing correction；消除 legacy route 與 correction route 的 delivery contradiction，鎖定既有 draft PR 的唯一 authoritative correction path。
- Update status: PC-04 completed；legacy steps 永久維持 pending historical entries；PR-03、IM-02、TE-02、RV-02、DL-02 與 HC-02 為唯一 pending correction routing，status 不構成 approval。
