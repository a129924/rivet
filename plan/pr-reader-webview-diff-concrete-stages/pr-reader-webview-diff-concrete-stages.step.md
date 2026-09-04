# pr-reader-webview-diff-concrete-stages — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-concrete-stages`
- Current phase: Ledger-evidence correction；待 fresh independent Reviewer 審查更正後 ledger、RV-03 verdict 與既有 factual evidence/statuses
- Ledger rule: status 與 checklist 不構成 approval；只有指定獨立角色的明示 verdict 可通過 gate。

## Goal

在既有 PR Reader WebView diff pipeline 中實作 internal concrete Validator、Parser、Renderer 與 `GitDiffTemplate`，將 `DiffSnapshot` 轉為 opaque internal `RenderPlan`；有 patch 使用 diff2html line-by-line rendering，no-patch 保留 metadata-unavailable entry。

## Non-Goal

不實作 Output、DOM、CSS、UI、HTML safety、Swift bridge、viewed persistence、公開 API／Port／contract／dependency 變更；不實作 side-by-side、file list 或 no-patch skip。

## In-Scope

- Internal structural Validator、immutable per-file VO、unified Git diff template、Parser、Renderer 與 tests；Validator 只驗 raw `DiffSnapshot`，Parser 只接收 validated input 並處理 diff2html third-party-result defense。
- concrete stage verified 後，最小 docs truth amendment；本輪只校正 architecture README 首段 implementation truth。
- 本 topic 四份 formal artifacts。

## Out-Of-Scope

- `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public barrel、manifest、lockfile、existing dependency artifacts 的變更。
- patch syntax validation、snapshot mutation、diff2html internals／HTML 對外洩漏，以及非既定 docs truth 的 architecture／BC 修改；UseCase 對 diff2html、unified diff 或 parsed shape 的認知；以 placeholder SHA、`index ` 行或 fake `100644` mode metadata 偽造 Git object identity。

## File Operations

- ReadOnly: `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency artifacts。
- Written: requirements、technical spec、execution plan、此 ledger；`concrete-stages/` 下 internal modules 與 tests。
- Deleted: 無。
- Modify: 僅必要 test harness，及 concrete success 後的 architecture README／PR Reader BC 既定 truth statement；本輪 docs edit 只限 architecture README 首段 truth correction。

## TestCase

- Validator structural cases：valid、identity、uniqueness、status、rename、boolean、safe counter、patch type。
- Template／Parser：four-status source 沒有 `index ` 或 fake mode metadata 且仍可 parse/render；nonempty patch 的每個 parsed hunk old/new line-array counts 與 header counts 等價；empty patch 為 zero blocks 且成功；no-patch metadata；path fixture 鎖定 old/new `a/`／`b/` prefixes 與 deterministic Git C-style quote、backslash、named control、octal UTF-8 escapes；nonempty malformed patch、incomplete diff2html result／exception 為穩定且不洩漏的 `parse-error`。第三方結果 helper 命名為 `isCompleteDiff2HtmlParseResult`，不作 raw snapshot 重驗。
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
| PC-05 | completed | Plan-Creator | 僅更新四份 formal artifacts，記錄五個已選 PR comment remediations：ledger route、parsed-hunk count completeness、Git C-style path serialization、README 首段 truth、fake mode removal。 | 不改 TS、docs、dependencies 或 Git；不回填任何既有 step status；不是 approval。 |
| PR-04 | approved | Plan-Reviewer | 獨立審查 PC-05 artifacts：五個 remediations 是否受限、責任邊界／file impact／TDD／thread-resolution 規則是否完整，且不改寫 prior history。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-03 | completed | Implementer | 僅於 PR-04 `approved` 後，以新的可歸因 TDD cycle 實作五個 selected PR thread remediations。 | Implementer 已提供可歸因於 parsed-hunk count、path serializer、no index/mode 與 README truth 的 red／green evidence；只處理 selected threads。 |
| TE-03 | completed | Tester | IM-03 明示完成後，獨立執行 frozen install、check、test、coverage、diff check，並核對五項 remediation test evidence。 | Independent Tester 明示 verdict：`pass`；已執行 frozen install、check、test、coverage 與 diff check。此結果不取代 Reviewer approval。 |
| RV-03 | needs-rework | Reviewer | TE-03 明示完成後，獨立審查 IM-03 scope、責任邊界、ReadOnly preservation、TDD／Tester evidence 與五個 thread 對應。 | Independent Reviewer 明示 verdict：`needs-rework`；不得以此 status 視為 delivery approval。完成本次 ledger-evidence correction 後必須交 fresh independent Reviewer。 |
| PC-06 | completed | Plan-Creator | 僅更正同 topic 四份 artifacts 的 ledger evidence／routing：移除未被 RV-03 required fixes 證實的 IM-04／TE-04 gate，保留所有 prior factual evidence/statuses 與 RV-03 needs-rework。 | 本次 Plan-Creator artifact correction；不改 TS、docs、dependencies 或 Git，不是 Reviewer approval。 |
| RV-04 | pending | Reviewer | PC-06 完成後，由 fresh independent Reviewer 審查更正後 ledger、RV-03 verdict、PR-04／IM-03／TE-03 的既有 factual evidence/statuses 與 DL-03 eligibility。 | 尚無獨立 Reviewer verdict；必須明示 `approved` 才可進入 DL-03。 |
| DL-03 | pending | Implementer | 僅於 RV-04 `approved` 後，建立 correction commit、push 至既有 PR branch，並只 resolve 五個經驗證處理的 threads。 | 尚無 delivery evidence；不得開新 PR、處理或 resolve 其他 thread。 |
| HC-03 | pending | Human | DL-03 後，人類審閱既有 PR 的五項 remediation。 | DL-03 後停止自動前進。 |

## Blockers

- Human 已接受 pre-gate historical deviation：implementation 在 PR-02 pending 時開始；此接受不構成 PR-02 approval，也不會回填 IM-01、TE-01 或 RV-01 的 gate status。PR-02、IM-01、TE-01、RV-01、DL-01 與 HC-01 永久維持 pending historical entries，不得作為 correction delivery prerequisite。
- 可歸因的歷史 evidence：Implementer 報告最初 red tests 因 target modules 尚未存在而失敗、後續 rework red tests 與其後 green checks；Tester 獨立報告 frozen install、check、test、coverage、diff check command evidence；technical Reviewer 已提供 implementation review result。這些 evidence 僅供 fresh independent review 檢視，不能取代 gate verdict。
- `PC-03 → PR-03 approved → IM-02 → TE-02 → RV-02 approved → DL-02 → HC-02` 是先前 correction route，保留其完整 history 與 statuses，但不作為 PC-05 route 的 prerequisite。
- PC-04 僅為 historical artifact-writing fact，不是 PR-03 的 target 或 prerequisite；PR-03 至 HC-02 均維持原 status，且不 gate PC-05 route。
- 任一需要修改 public contract、dependency、DOM／Swift、HTML safety policy 或既定 BC boundary 的需求，必須標示 `blocked` 或交還 human，不得擴張本 topic。
- 既有 PC-03／PC-04 route 與其 step statuses 保留為歷史紀錄；本輪的 PR-04 approved、IM-03 red／green evidence 與 TE-03 Tester `pass` evidence 已如實記錄。RV-03 的明示 verdict 是 `needs-rework`，不回填為 approved。
- PC-06 只更正 ledger evidence／routing，不新增未被 Reviewer required fixes 證實的 implementation 或 Tester gate。唯一可前進 route 是 `PC-06 → RV-04 fresh independent review approved → DL-03 → HC-03`。RV-04 前不得 commit、push 或 resolve threads。
- DL-03 只可 resolve 五個 selected PR threads；任何額外 thread、未被 Reviewer 驗證的 remediation 或 scope change 都是 human boundary。

## Human Check

- `DL-03` 完成後，停止於 `HC-03` human review；human 是唯一可決定五項 remediation 是否接受或合併的人。RV-03 `needs-rework` 後，必須先完成 PC-06 並取得 fresh independent RV-04 approval；既有 HC-01／HC-02 均為 prior route entries，不參與此路徑。

## Last Updated

- Updated by: Plan-Creator
- Update reason: Plan review needs-rework correction：移除未被 RV-03 required fixes 證實的 IM-04／TE-04 gate，保留 PR-04 approved、IM-03 red／green、TE-03 Tester `pass` 與 RV-03 `needs-rework` 的 factual record。
- Update status: PC-06 completed；PR-04 approved、IM-03／TE-03 completed、RV-03 needs-rework；唯一可前進 route 為 fresh independent RV-04 → DL-03 → HC-03，status 不構成 approval。
