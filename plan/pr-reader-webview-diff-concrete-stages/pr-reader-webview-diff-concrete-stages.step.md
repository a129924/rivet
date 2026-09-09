# pr-reader-webview-diff-concrete-stages — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-concrete-stages`
- Current phase: PC-17 已記錄 Human 接受的 PR-11 pre-gate historical deviation；待 `RV-15` fresh independent review
- Ledger rule: status 與 checklist 不構成 approval；只有指定獨立角色的明示 verdict 可通過 gate。

## Goal

在既有 PR Reader WebView diff pipeline 中實作 internal concrete Validator、Parser、Renderer 與 `GitDiffTemplate`，將 `DiffSnapshot` 轉為 opaque internal `RenderPlan`；有 patch 使用 diff2html line-by-line rendering，no-patch 保留 metadata-unavailable entry。

## Non-Goal

不實作 Output、DOM、CSS、UI、HTML safety、Swift bridge、viewed persistence、公開 API／Port／contract／dependency 變更；不實作 side-by-side、file list 或 no-patch skip。

## In-Scope

- Internal structural Validator、immutable per-file VO、unified Git diff template、Parser、Renderer 與 tests；Validator 只驗 raw `DiffSnapshot`，Parser 只接收 validated input 並處理 diff2html third-party-result defense。本輪第六個 PR thread #1 僅補強 Parser 將 template source 的 ordered hunk header tuples／marker-plus-body source-line expectations 與 parsed blocks／`DiffLine.content` 逐一比較。
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
- Template／Parser：four-status source 沒有 `index ` 或 fake mode metadata 且仍可 parse/render；nonempty patch 的 template source hunk header tuples（old/new start/count）必須與 parsed blocks 一對一、依序相符，且 block old/new line-array counts 等於同位置來源 count；每個 source context／delete／insert marker-plus-body 必須與 parsed `DiffLine.content` 精確相符，type、old/new number 獨立比較，unknown prefix 或任一 mismatch 均為 stable/no-leak `parse-error`；只可略過 trailing LF split 的 terminal empty segment，actual blank context 的 single-space marker 必須保留；empty patch 的 source expectation 與 parsed blocks 都是 zero 且成功；no-patch metadata；path fixture 鎖定 old/new `a/`／`b/` prefixes 與 deterministic Git C-style quote、backslash、named control、octal UTF-8 escapes；nonempty malformed patch、incomplete diff2html result／exception，以及 two-hunk source 被靜默截斷為一個完整 block 均為穩定且不洩漏的 `parse-error`。第三方結果 helper 命名為 `isCompleteDiff2HtmlParseResult`，不作 raw snapshot 重驗。
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
| PC-07 | completed | Plan-Creator | 僅更新同 topic 四份 formal artifacts，記錄第六個 PR thread #1 的 Parser-local multi-hunk completeness correction：template source 的 hunk header tuples 與 parsed blocks 按順序一對一相符，empty patch 為 zero blocks，並鎖定可歸因的 TDD red case。 | 不改 TS、architecture／BC docs、dependencies 或 Git；不回填、改寫或重開任何 prior route/status；不是 Plan-Reviewer approval。 |
| PR-05 | approved | Plan-Reviewer | 獨立審查 PC-07：確認 source-header-to-parsed-block comparison、empty-patch zero-block rule、Parser-only boundary、TDD case、file impact 與只 resolve #1 的 route 均完整。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-04 | completed | Implementer | 僅於 PR-05 `approved` 後，以新 TDD cycle 在 internal Parser 與其 tests 實作 multi-hunk completeness correction。 | Implementer 提供：兩個有效來源 hunks、injected parse result 僅含第一個完整 block 的 stable/no-leak `parse-error` red／green evidence；不得視為 delivery approval。 |
| TE-04 | completed | Tester | IM-04 明示完成後，獨立執行 frozen install、check、test、coverage、diff check。 | Independent Tester 已回報 frozen install、check、test、coverage、diff check evidence；此結果不取代 Reviewer approval。 |
| RV-05 | needs-rework | Reviewer | TE-04 明示完成後，獨立審查 IM-04 scope、Parser-only 責任邊界、ReadOnly preservation、TDD／Tester evidence 與 thread #1 對應。 | Independent Reviewer 明示 verdict：`needs-rework`。Required fix：同一 GitDiffTemplate source 供 parse／完整性使用；source／parsed headers structured tuples 的 ordered comparison 與 valid two-hunk Parser→Renderer green regression。 |
| DL-04 | pending | Implementer | 僅於 RV-05 `approved` 後，建立 correction commit、push 至既有 PR branch，並只 resolve 第六個 PR thread #1。 | 尚無 delivery evidence；不得開新 PR，或處理、resolve、重開其他 thread。 |
| HC-04 | pending | Human | DL-04 後，人類審閱既有 PR 的第六個 thread #1 correction。 | DL-04 後停止自動前進。 |
| PC-08 | completed | Plan-Creator | 只更新四份 artifacts，如實記錄 PR-05／IM-04／TE-04 evidence 與 RV-05 needs-rework，並鎖定 single-source、structured tuple 與 two-hunk green regression correction。 | 不改 TS、docs、dependencies 或 Git；不回填 RV-05 approval；不是 Plan-Reviewer approval。 |
| PR-06 | pending | Plan-Reviewer | Permanently pending pre-gate historical-deviation entry；沒有且不得補造獨立 approval。 | 不構成 IM-05、TE-05 或 fresh review 的 retrospective prerequisite。 |
| IM-05 | pending | Implementer | Permanently pending pre-gate historical-deviation entry；implementation 已發生但不回填 status。 | 可歸因歷史 evidence：Parser/tests 的 red／green TDD 結果；不構成 gate completion 或 delivery approval。 |
| TE-05 | pending | Tester | Permanently pending pre-gate historical-deviation entry；verification 已發生但不回填 status。 | 可歸因歷史 evidence：獨立 Tester `pass`；不構成 Reviewer 或 delivery approval。 |
| RV-06 | human-check | Reviewer | 已發生的 historical non-approval review result。 | 明示結果為 `human-check`／`blocked`，不是 `approved`；不得進入 DL-05。 |
| PC-09 | completed | Plan-Creator | Human 接受本次 pre-gate historical deviation 後，只更新四份 artifacts，如實記錄 PR-06 pending、IM-05／TE-05 factual evidence 與 RV-06 non-approval result。 | 不改 TS、docs、dependencies 或 Git；不補造 PR-06 approval、不回填 IM-05／TE-05 status；不是 Reviewer approval。 |
| RV-07 | pending | Reviewer | PC-09 後，由 fresh independent Reviewer 審查 locked scope、PR-06 pending、IM-05 red／green evidence、TE-05 `pass` evidence、RV-06 human-check／blocked result 與 DL-05 eligibility。 | 尚無獨立 Reviewer verdict；只有明示 `approved` 才可進入 DL-05。 |
| DL-05 | pending | Implementer | 僅於 RV-07 `approved` 後，建立 correction commit、push 至既有 PR branch，並只 resolve 第六個 PR thread #1。 | 尚無 delivery evidence；不得開新 PR，或處理、resolve、重開其他 thread。 |
| HC-05 | pending | Human | DL-05 後，人類審閱既有 PR 的第六個 thread #1 correction。 | DL-05 後停止自動前進。 |
| PC-10 | completed | Plan-Creator | 僅更新同 topic 四份 artifacts，鎖定第六個 PR thread #1 的 source-line completeness correction：同一 template source 的 context／delete／insert line expectation 與 parsed line type/body/old-new numbers 精確比較。 | 不改 TS、docs、dependencies 或 Git；不回填或改寫 prior route/status/evidence；不是 Plan-Reviewer approval。 |
| PR-07 | pending | Plan-Reviewer | 獨立審查 PC-10：確認 per-line source expectation、unknown prefix／body/type/number mismatch `parse-error`、Parser-only boundary、TDD red/green 與只 resolve #1 的 route 完整。 | 尚無獨立明示 verdict；只有 `approved` 才可開始 IM-06。 |
| IM-06 | pending | Implementer | 僅於 PR-07 `approved` 後，以新 TDD cycle 實作 internal Parser/tests 的 source-line completeness correction。 | 先有 injected parsed-line mismatch red evidence，再以最小 Parser/test change 轉綠；保留實際 Parser parsed normal control；不得觸及 ReadOnly surface。 |
| TE-06 | pending | Tester | IM-06 明示完成後，獨立執行 frozen install、check、test、coverage、diff check。 | 必須驗證 line-level regression 與既有 checks；尚無 Tester result。 |
| RV-08 | pending | Reviewer | TE-06 明示完成後，獨立審查 IM-06 scope、Parser-only boundary、ReadOnly preservation、TDD／Tester evidence 與 thread #1 對應。 | 尚無獨立 Reviewer verdict；只有明示 `approved` 才可進入 DL-06。 |
| DL-06 | pending | Implementer | 僅於 RV-08 `approved` 後，建立 correction commit、push 至既有 PR branch，並只 resolve 第六個 PR thread #1。 | 尚無 delivery evidence；不得開新 PR，或處理、resolve、重開其他 thread。 |
| HC-06 | pending | Human | DL-06 後，人類審閱既有 PR 的第六個 thread #1 source-line correction。 | DL-06 後停止自動前進。 |
| PC-11 | completed | Plan-Creator | 僅更新同 topic 四份 artifacts，納入 PR-07 `needs-rework`：source marker-plus-body 必須精確比對 `DiffLine.content`，type/numbers 獨立檢查，並鎖定 trailing-LF split rule。 | 不改 TS、docs、dependencies 或 Git；不回填或改寫 prior route/status/evidence；不是 Plan-Reviewer approval。 |
| PR-08 | pending | Plan-Reviewer | Permanently pending pre-gate historical-deviation entry；沒有且不得補造獨立 approval。 | 不構成 IM-07、TE-07、RV-09 或 fresh review 的 retrospective prerequisite。 |
| IM-07 | pending | Implementer | Permanently pending pre-gate historical-deviation entry；implementation 已發生但不回填 status。 | 可歸因歷史 evidence：source-marker correction 的 red／green TDD 結果；不構成 gate completion 或 delivery approval。 |
| TE-07 | pending | Tester | Permanently pending pre-gate historical-deviation entry；verification 已發生但不回填 status。 | 可歸因歷史 evidence：獨立 Tester `pass`；不構成 Reviewer 或 delivery approval。 |
| RV-09 | blocked | Reviewer | 已發生的 historical non-approval review result。 | 明示結果為 `blocked`，不是 `approved`；不得進入 DL-07。 |
| DL-07 | pending | Implementer | 既有 RV-09 route 已 blocked；僅於 `PC-12` 後 `RV-10` 明示 `approved`，才可建立 correction commit、push 至既有 PR branch，並只 resolve 第六個 PR thread #1。 | 尚無 delivery evidence；不得開新 PR，或處理、resolve、重開其他 thread。 |
| HC-07 | pending | Human | DL-07 後，人類審閱既有 PR 的第六個 thread #1 source-marker correction。 | DL-07 後停止自動前進。 |
| PC-12 | completed | Plan-Creator | Human 接受 PR-08 pre-gate historical deviation 後，只更新四份 formal artifacts，如實記錄 PR-08 pending、IM-07 red／green、TE-07 `pass` 與 RV-09 `blocked`。 | 不改 TS、docs、dependencies 或 Git；不補造 PR-08 approval、不回填 IM-07／TE-07 status，且不新增 nonblocking type-only test work；不是 Reviewer approval。 |
| RV-10 | pending | Reviewer | PC-12 後，由 fresh independent Reviewer 審查 locked scope、PR-08 pending、IM-07 red／green evidence、TE-07 `pass` evidence、RV-09 `blocked` result 與 DL-07 eligibility。 | 尚無獨立 Reviewer verdict；只有明示 `approved` 才可進入 DL-07。 |
| PC-13 | completed | Plan-Creator | 僅更新四份 formal artifacts，鎖定兩個 selected PR threads：合法 EOF metadata marker 不建立 completeness expectation/count，與 CRLF hunk content 的 Parser-private canonical comparison。 | 不改 TS、docs、dependencies 或 Git；不回填或改寫任何 prior route/status/evidence；不是 Plan-Reviewer approval。 |
| PR-09 | approved | Plan-Reviewer | 獨立審查 PC-13：確認精確 EOF marker metadata exclusion、strict unknown-prefix preservation、同一未改寫 template source 供 parse/comparison、CRLF truthful-test rule、TDD 與只 resolve 兩個 threads 的 route。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-08 | completed | Implementer | 僅於 PR-09 `approved` 後，以新 TDD cycle 修正 internal Parser/tests 的 EOF marker／CRLF completeness comparison。 | exact EOF-marker red／green evidence 已完成；CRLF behavior 已如實 characterization；不構成 delivery approval。 |
| TE-08 | completed | Tester | IM-08 明示完成後，獨立執行 frozen install、check、test、coverage、diff check。 | Independent Tester 明示 verdict：`pass`；涵蓋 EOF metadata、CRLF comparison 與 strict unknown-prefix/malformed controls。 |
| RV-11 | needs-rework | Reviewer | TE-08 明示完成後，獨立審查 IM-08 的 Parser-only scope、same-source parse input、EOF metadata/count exclusion、CRLF canonical comparison、TDD／Tester evidence 與 ReadOnly preservation。 | Independent Reviewer 明示 verdict：`needs-rework`。Required rework 僅為 nonexact backslash EOF-marker negative regression，證明唯一 exact marker exception 不接受近似值。 |
| PC-14 | completed | Plan-Creator | 僅更新四份 formal artifacts，如實記錄 PR-09／IM-08／TE-08 evidence 與 RV-11 needs-rework，並鎖定 single nonexact-marker negative regression 的 test-only route。 | 不改 TS、docs、dependencies 或 Git；不回填或改寫 prior status/evidence；不是 Plan-Reviewer approval。 |
| PR-10 | approved | Plan-Reviewer | 獨立審查 PC-14：確認 fixture 非精確、exact metadata exception 仍受限、stable/no-leak `parse-error`、test-only file impact、scope-expanding blocker 與 delivery route。 | Existing independent Plan-Reviewer 明示 verdict：`approved`；此既有事實授權後續 IM-09。 |
| IM-09 | completed | Implementer | 僅於 PR-10 `approved` 後，在 internal Parser test module 新增一個 nonexact `\ No newline at end of file ` negative regression。 | Existing factual evidence：僅新增該 regression，斷言 stable/no-leak `parse-error`；production code 與 ReadOnly surface 未變。 |
| TE-09 | completed | Tester | IM-09 明示完成後，獨立執行 frozen install、check、test、coverage、diff check。 | Existing independent Tester factual evidence：新 regression 與既有 EOF／CRLF／unknown-prefix controls 通過指定驗證。 |
| RV-12 | blocked | Reviewer | TE-09 明示完成後，審查 test-only diff、stable/no-leak `parse-error`、existing coverage preservation 與 ReadOnly preservation。 | Existing Reviewer verdict：`blocked`，原因是當時 ledger 漏記既有 PR-10 approval；這不是 `approved`，不得進入 DL-08。 |
| PC-15 | completed | Plan-Creator | 只更新四份 formal artifacts，如實補記既有 PR-10 approved、IM-09／TE-09 factual evidence 與 RV-12 blocked，保留全部既有 status/history。 | 不改 TS、docs、dependencies 或 Git；不將 RV-12 重寫為 approval，且不構成 Reviewer delivery approval。 |
| RV-13 | pending | Reviewer | PC-15 後，由 fresh independent Reviewer 重新審查 test-only diff、PR-10／IM-09／TE-09 factual evidence、RV-12 blocked 原因、stable/no-leak `parse-error`、coverage 與 ReadOnly preservation。 | 尚無 fresh independent Reviewer verdict；只有明示 `approved` 才可進入 DL-08。 |
| DL-08 | pending | Implementer | 僅於 RV-13 `approved` 後，建立 correction commit、push 至既有 PR branch，並只 resolve 此兩個 selected PR threads。 | 尚無 delivery evidence；不得開新 PR、處理、resolve 或重開其他 thread。 |
| HC-08 | pending | Human | DL-08 後，人類審閱既有 PR 的 EOF marker／CRLF correction。 | DL-08 後停止自動前進。 |
| PC-16 | completed | Plan-Creator | 僅更新同 topic 四份 artifacts，鎖定三個 selected threads：template preamble 以外的 first-hunk-before nonempty garbage 必須 `parse-error`、internal Parsed／Render envelopes 保留 PR／snapshot identity、renamed 缺少 optional `previousFilename` 走 metadata-unavailable 且不呼叫 Template／diff2html。 | 不改 TypeScript、docs、dependencies 或 Git；不回填、改寫或解除任何 prior route/status/evidence；不是 Plan-Reviewer approval。 |
| PR-11 | pending | Plan-Reviewer | Permanently pending pre-gate historical-deviation entry；沒有且不得補造 independent approval。 | 不構成 IM-10、TE-10、RV-14 或 fresh review 的 retrospective prerequisite。 |
| IM-10 | pending | Implementer | Permanently pending pre-gate historical-deviation entry；implementation 已發生但不回填 status。 | 可歸因歷史 evidence：三個 selected-thread correction 的 TDD red／green；不構成 gate completion 或 delivery approval。 |
| TE-10 | pending | Tester | Permanently pending pre-gate historical-deviation entry；verification 已發生但不回填 status。 | 可歸因歷史 evidence：independent Tester `pass`；不構成 Reviewer 或 delivery approval。 |
| RV-14 | blocked | Reviewer | 已發生的 historical non-approval review result。 | 明示結果為 `blocked`，不是 `approved`；不得進入 DL-09。 |
| PC-17 | completed | Plan-Creator | Human 接受 PR-11 pre-gate historical deviation 後，只更新四份 formal artifacts，如實記錄 PR-11 pending、IM-10 TDD、TE-10 `pass` 與 RV-14 `blocked`。 | 不改 TS、tests、docs、dependencies 或 Git；不補造 PR-11 approval、不回填 IM-10／TE-10 status；不是 Reviewer approval。 |
| RV-15 | pending | Reviewer | PC-17 後，由 fresh independent Reviewer 審查 locked scope、PR-11 pending、IM-10 red／green evidence、TE-10 `pass` evidence、RV-14 `blocked` 與 DL-09 eligibility。 | 尚無 fresh independent Reviewer verdict；只有明示 `approved` 才可進入 DL-09。 |
| DL-09 | pending | Implementer | 僅於 RV-15 `approved` 後，依已授權流程建立 correction commit、push 更新既有 PR branch，並只 resolve 此三個 selected threads。 | 尚無 delivery evidence；不得開新 PR、處理、resolve 或重開其他 thread。 |
| HC-09 | pending | Human | DL-09 後，人類審閱此三個 selected-thread correction。 | DL-09 後停止自動前進。 |

## Blockers

- Human 已接受 pre-gate historical deviation：implementation 在 PR-02 pending 時開始；此接受不構成 PR-02 approval，也不會回填 IM-01、TE-01 或 RV-01 的 gate status。PR-02、IM-01、TE-01、RV-01、DL-01 與 HC-01 永久維持 pending historical entries，不得作為 correction delivery prerequisite。
- 可歸因的歷史 evidence：Implementer 報告最初 red tests 因 target modules 尚未存在而失敗、後續 rework red tests 與其後 green checks；Tester 獨立報告 frozen install、check、test、coverage、diff check command evidence；technical Reviewer 已提供 implementation review result。這些 evidence 僅供 fresh independent review 檢視，不能取代 gate verdict。
- `PC-03 → PR-03 approved → IM-02 → TE-02 → RV-02 approved → DL-02 → HC-02` 是先前 correction route，保留其完整 history 與 statuses，但不作為 PC-05 route 的 prerequisite。
- PC-04 僅為 historical artifact-writing fact，不是 PR-03 的 target 或 prerequisite；PR-03 至 HC-02 均維持原 status，且不 gate PC-05 route。
- 任一需要修改 public contract、dependency、DOM／Swift、HTML safety policy 或既定 BC boundary 的需求，必須標示 `blocked` 或交還 human，不得擴張本 topic。
- 既有 PC-03／PC-04 route 與其 step statuses 保留為歷史紀錄；本輪的 PR-04 approved、IM-03 red／green evidence 與 TE-03 Tester `pass` evidence 已如實記錄。RV-03 的明示 verdict 是 `needs-rework`，不回填為 approved。
- PC-06 只更正 ledger evidence／routing，不新增未被 Reviewer required fixes 證實的 implementation 或 Tester gate。唯一可前進 route 是 `PC-06 → RV-04 fresh independent review approved → DL-03 → HC-03`。RV-04 前不得 commit、push 或 resolve threads。
- DL-03 只可 resolve 五個 selected PR threads；任何額外 thread、未被 Reviewer 驗證的 remediation 或 scope change 都是 human boundary。
- PR-05 `approved`、IM-04 completed 與 TE-04 completed 是已發生 factual records；RV-05 的明示 verdict 是 `needs-rework`，因此 DL-04／HC-04 不得前進，也不得將任何 status 回填成 approval。
- PC-08 只新增第六個 PR thread #1 的 corrective route：`PC-08 → PR-06 approved → IM-05 → TE-05 → RV-06 approved → DL-05 → HC-05`。PR-06 前不得修改 TS、docs、dependencies 或 Git。
- IM-05 僅可補強 Parser-local third-party-result defense：同一 GitDiffTemplate source 供 parse／complete check，source／parsed header structured tuple 與 line count comparison，以及 valid two-hunk Parser→Renderer green regression。任何 Validator、UseCase、公開 contract、Port、dependency、architecture／BC docs 或其他 thread 變動均為 human boundary。
- DL-05 只可 resolve 第六個 PR thread #1；任何其他 thread 的處理、resolve 或重開都是 human boundary。
- Human 已接受本次新的 pre-gate historical deviation：`PR-06` 仍為 pending、沒有 approval；`IM-05` 的 red／green 與 `TE-05` 的 Tester `pass` 僅是可歸因歷史 evidence。它們不可回填 step status、不能取代 gate，也不授權 delivery。
- `RV-06` 的歷史結果是 `human-check`／`blocked`，不是 approval。既有 `PC-08 → PR-06 → IM-05 → TE-05 → RV-06 → DL-05` route 保留為歷史，不能依其前進。
- `PC-09 → RV-07 → DL-05 → HC-05` 保留為 prior historical-deviation corrective route；其 statuses 不被回填或改寫。新的 source-line review comment 已建立獨立後續 route，只有 `PC-10 → PR-07 approved → IM-06 → TE-06 → RV-08 approved → DL-06 → HC-06` 可處理並 resolve thread #1。PR-07 前不得修改程式、docs、dependencies 或 Git。
- `PR-07` 的明示 verdict 是 `needs-rework`：body-only comparison 不符合 `DiffLine.content`。`PC-10 → PR-07 → IM-06 → TE-06 → RV-08 → DL-06 → HC-06` 保留為歷史，不得依它前進。唯一新的 route 是 `PC-11 → PR-08 approved → IM-07 → TE-07 → RV-09 approved → DL-07 → HC-07`；PR-08 前不得修改程式、docs、dependencies 或 Git。
- Human 已接受本次 PR-08 pre-gate historical deviation：`PR-08` 仍為 pending、沒有 approval；`IM-07` 的 red／green 與 `TE-07` 的 Tester `pass` 僅為可歸因 historical evidence。它們不可回填 step status、不能取代 gate，也不授權 delivery。
- `RV-09` 的歷史結果是 `blocked`，不是 approval。既有 `PC-11 → PR-08 → IM-07 → TE-07 → RV-09 → DL-07` route 保留為歷史，不能依其前進；本次不新增 nonblocking type-only mismatch test 或其他 implementation/test scope。
- 唯一可前進 route 是 `PC-12 → RV-10 fresh independent review approved → DL-07 → HC-07`。RV-10 前不得 commit、push 或 resolve thread #1，且不得補造 PR-08 approval。
- `PC-13` 只新增兩個 selected PR threads 的 route：合法精確 `\ No newline at end of file` 是 metadata，不建立 expectation/count；CRLF canonicalization 僅限 Parser-private completeness comparison。它不得改 template source、parse input、raw snapshot、Validator、UseCase、公開 contract、docs、dependencies 或 Git。
- strict unknown-prefix behavior 維持：除精確 EOF marker 外，所有未知 hunk-body prefix 都是 stable/no-leak `parse-error`。IM-08 的 exact EOF case 必須先有 failing evidence；CRLF 若 initial characterization 已 green，必須如實保留而非補造 red evidence。
- 唯一可前進 route 是 `PC-13 → PR-09 approved → IM-08 → TE-08 → RV-11 approved → DL-08 → HC-08`。PR-09 前不得改程式、docs、dependencies 或 Git；DL-08 只可 resolve 這兩個 selected threads。
- `PR-09` 的 `approved`、IM-08 TDD evidence 與 TE-08 independent `pass` 均為已發生的 factual record；`RV-11` 明示 `needs-rework`，故不得進入 DL-08。
- `PC-14` 的唯一 rework 是 nonexact backslash EOF-marker negative regression：只有精確 `\ No newline at end of file` 可作 metadata；fixture `\ No newline at end of file ` 必須仍為 strict unknown prefix 並回傳 stable/no-leak `parse-error`。不得修改 production code；若 test 不 green，屬 scope-expanding blocker，交還 human。
- `PR-10` 的 independent `approved`、IM-09 test-only factual evidence 與 TE-09 independent Tester evidence 均已發生；`RV-12` 的明示 verdict 是 `blocked`，因 ledger 當時漏記 PR-10 approval。此 blocked verdict 不得重寫為 approval，也不得進入 DL-08。
- 唯一可前進 route 是 `PC-15 → RV-13 fresh independent review approved → DL-08 → HC-08`。RV-13 前不得 commit、push 或 resolve threads。
- 本輪三個 selected threads 的唯一新 route 是 `PC-16 → PR-11 approved → IM-10 → TE-10 → RV-14 approved → DL-09 → HC-09`。PR-11 前不得修改 TypeScript、docs、dependencies 或 Git；DL-09 只可 resolve 這三個 threads。任何要求修改 public contract、Port、UseCase orchestration、package manifest／lockfile 或將 metadata-unavailable 改為偽造 renamed path 的需求均是 human boundary。
- Human 已接受本次 PR-11 pre-gate historical deviation：`PR-11` 維持 pending、沒有 approval；`IM-10` 的 TDD red／green 與 `TE-10` 的 independent Tester `pass` 僅為可歸因 historical evidence，不能回填 status、取代 gate 或授權 delivery。
- `RV-14` 的既有結果是 `blocked`，不是 approval。既有 `PC-16 → PR-11 → IM-10 → TE-10 → RV-14 → DL-09` route 保留為歷史，不能依其前進。
- 唯一可前進 route 是 `PC-17 → RV-15 fresh independent review approved → DL-09 → HC-09`。RV-15 前不得 commit、push 或 resolve；DL-09 仍只可 resolve 三個 selected threads。

## Human Check

- `DL-03` 完成後，停止於 `HC-03` human review；human 是唯一可決定五項 remediation 是否接受或合併的人。RV-03 `needs-rework` 後，必須先完成 PC-06 並取得 fresh independent RV-04 approval；既有 HC-01／HC-02 均為 prior route entries，不參與此路徑。
- `DL-04` 完成後，停止於 `HC-04` human review；human 是唯一可決定第六個 PR thread #1 correction 是否接受或合併的人。
- `DL-05` 完成後，停止於 `HC-05` human review；human 是唯一可決定 RV-05 corrective implementation 是否接受或合併的人。
- `RV-06` 的 `human-check`／`blocked` 是本次 deviation 的 human boundary；Human 已僅授權 Plan-Creator 如實記錄 evidence。`RV-07` 的 fresh independent review 尚未完成前，不得進入 DL-05。
- `PR-07` 只審查 source-line completeness correction；不得以它回填、取代或重新審查 PR-06、IM-05、TE-05、RV-06、PC-09 或 RV-07 的 historical evidence/status。PR-07 或 RV-08 任何非 `approved` verdict 均不得進入 DL-06。
- `PR-08` 只審查 source-marker content correction；不得以它回填、取代或重新審查任何 prior route/status。PR-08 或 RV-09 任何非 `approved` verdict 均不得進入 DL-07。
- `RV-09` 的 `blocked` 是本次 deviation 的 human boundary；Human 已僅授權 Plan-Creator 如實記錄 evidence。`RV-10` 的 fresh independent review 尚未明示 `approved` 前，不得進入 DL-07。
- `PR-09` 只審查 EOF metadata／CRLF completeness-comparison correction；不得以它回填、取代或重新審查任何 prior route/status。PR-09 或 RV-11 任何非 `approved` verdict 均不得進入 DL-08。
- `RV-11` 的 `needs-rework` 是本輪 test-only correction 的 boundary；既有 `PR-10` approved 後才新增 nonexact marker regression。`RV-12` 已明示 `blocked`，不得進入 DL-08；只有 `RV-13` fresh independent review 明示 `approved` 才可 delivery。
- `DL-08` 完成後停止於 `HC-08` human review；human 是唯一可決定此兩個 selected threads correction 是否接受或合併的人。
- `PR-11` 只審查 preamble、internal identity 與 missing-rename metadata fallback；不得回填、取代或重新審查既有 route/status。PR-11 或 RV-14 的任何非 `approved` verdict 均不得進入 DL-09；DL-09 完成後停止於 HC-09 human review。
- `RV-14` 的 `blocked` 是本次 deviation 的 human boundary；Human 已僅授權 Plan-Creator 如實記錄 evidence。只有 `RV-15` fresh independent review 明示 `approved` 才可進入 DL-09；DL-09 後停止於 HC-09 human review。

## Last Updated

- Updated by: Plan-Creator
- Update reason: Human 接受 PR-11 pre-gate historical deviation 後，如實記錄既有 evidence、RV-14 blocked 與 fresh review route；不改寫任何 prior status/history。
- Update status: PC-17 completed；待 RV-15 fresh independent Reviewer review。唯一新 route 為 RV-15 approved → DL-09 → HC-09；prior routes/statuses 保留不變。
