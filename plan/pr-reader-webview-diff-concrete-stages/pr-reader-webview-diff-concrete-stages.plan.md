# PR Reader WebView Diff Concrete Stages — Execution Plan

## Summary

在既有 orchestration 與 opaque stage contract 內，新增 internal concrete Validator、Parser、Renderer、`GitDiffTemplate` 與測試。這個 topic 止於 `RenderPlan` 的建立；沒有 Output、DOM 或公開 surface 變更。

## Goal and Boundaries

- **Goal**：將有效 `DiffSnapshot` 轉為 internal `RenderPlan`，有 patch 的檔案使用 repo-local diff2html 產生逐檔 line-by-line HTML，無 patch 的檔案保留 metadata-unavailable entry。
- **Non-Goal**：不實作 concrete Output 或顯示 HTML；不處理 HTML safety、CSS、UI、syntax highlighting、Swift bridge、viewed persistence、side-by-side 或 file list。
- **In-Scope**：structural validation、per-file immutable VO、unified Git diff template、parse、render、internal opaque representation、tests，以及 concrete-stage verified 後的最小 docs truth amendment。Validator 只處理 raw `DiffSnapshot` runtime structure/invariants；Parser 才負責 template、diff2html parse 與第三方結果完整性防禦。第六個 PR thread #1 的本輪 correction 僅補強 Parser 對 multi-hunk source 被靜默截斷的防禦。
- **Out-Of-Scope**：公開 API／Port／contract／dependency 變更；Validator 的 patch parsing 或 diff2html result checking；UseCase 對 diff2html、unified diff 或 parsed shape 的認知；修改 snapshot；no-patch failure 或 skip；其他 architecture／BC 結論。

## Implementation Changes

- 建立 `concrete-stages/diff-view-model-validator.ts`，實作既有 Validator Port 的 locked structural checks；成功時建立不可變 branded validated input，失敗時回傳穩定 `invalid-input`。
- 讓 `concrete-stages/diff-view-model-validator.ts` 只驗證 raw `DiffSnapshot` runtime structure/invariants；它不得產生 unified source、呼叫 diff2html 或檢查 parsed result。
- 建立 `concrete-stages/git-diff-template.ts`，以沒有 blob SHA 的 immutable `GitDiffTemplateInput` 根據單一檔案 status 組裝 unified Git diff source；保留必要 header/path/rename metadata/patch，完全省略 `index ` 與所有 fake mode metadata（含 `100644`）；不對外 export VO 或 template。非 `/dev/null` path 先加入 `a/`／`b/` side prefix，再以 deterministic Git C-style serializer 輸出：safe ASCII `[A-Za-z0-9._/+\-]` unquoted；否則雙引號包覆、quote/backslash/named controls C-escape，其餘 control、DEL 與 UTF-8 bytes 為零補三位八進位 escape。
- 建立 `concrete-stages/diff-parser.ts`，只接收 `ValidatedDiffInput`，依 input order 對 patch entries 執行 template 與 `diff2html.parse`，對 no-patch entries 保留 metadata-unavailable。以 internal `isCompleteDiff2HtmlParseResult` 確認第三方回傳代表一份完整的單檔 Git diff：由 template source 讀取 nonempty patch 的 ordered hunk header tuples（old/new start/count），要求 parsed blocks 數量相同、逐一同位置 header tuple 相同，且每個 block old/new line-array counts 等於同位置來源 count；再由同一 source hunk body 逐行推導 context／delete／insert marker-plus-body `DiffLine.content` expectation，精確比較 parsed content、type、old/new number。只可略過 trailing LF split 的 terminal empty segment；actual blank context 的 single-space marker 必須保留。unknown source prefix 或任何 line-level mismatch 一律不完整。empty patch 的 source expectation 與 parsed blocks 均為 zero。此 helper 不得重驗 raw snapshot。template／parse exception 或完整性失敗一律收斂為不洩漏內容的穩定 `parse-error`。
- 建立 `concrete-stages/diff-renderer.ts`，依 input order 對 parsed entries 執行 `diff2html.html`，固定 line-by-line 且不繪製 file list，建立 opaque `RenderPlan`；render exception 為 `render-error`。
- 在同一 internal folder 建立對應 tests；必要時僅註冊既有 test harness。完成 concrete-stage verification 後，最小更新 architecture README 與 PR Reader BC 的 implementation truth；本輪 docs remediation 只校正 architecture README 首段，其他 docs 不動。
- Implementer 必須以 TypeScript TDD 完成每個可觀察 stage 與 integration behavior：先新增可歸因於尚未實作行為的 failing test（red），再以最小 strict TypeScript implementation 使其通過（green），最後只在 tests 持續通過時重構。Implementer handoff 必須逐一提供 red failure 與 green local verification evidence；不得以 `any` 或弱化 strict 設定迴避型別問題。

## File Operations

| Operation | Scope |
| --- | --- |
| ReadOnly | `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency topic artifacts。 |
| Written | 同 slug 四份 artifacts，及 `concrete-stages/` 下四個 internal implementation modules 與其 test modules。 |
| Modify | 僅既有 test harness（如必需）及在 concrete success 後的 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 既定 truth statement；本輪 PR remediation 的 docs edit 只限 architecture README 首段。 |
| Deleted | 無。 |

## Test Plan

- Validator：valid snapshot；empty identity；duplicate `fileId`；invalid status；non-renamed `previousFilename`、empty `previousFilename`；renamed missing `previousFilename` remains valid；invalid `viewed`；negative／unsafe counters；non-string patch。
- Template／Parser：added、removed、modified、renamed unified diff 均沒有 `index ` 或 fake mode metadata 且仍可 parse/render；nonempty patch 的 template source hunk header tuples 與 parsed blocks 必須一對一、依序相符，且 parsed old/new line-array counts 等於來源 header counts；每個 hunk 的 source context／delete／insert marker-plus-body 必須與 parsed `DiffLine.content` 精確相符，type 與 old/new number 另行比較，unknown prefix 或任一 mismatch 都是 stable `parse-error`；只可略過 trailing LF split 的 terminal empty segment，actual blank context 的 single-space marker 必須保留；empty patch 的 source expectation 與 parsed blocks 都是 zero 且成功可 render；no-patch metadata entry；path fixture 鎖定 `a/`／`b/` prefixes 與 Git C-style quote、backslash、named control、octal UTF-8 escapes；nonempty malformed patch、incomplete third-party parse result、兩個來源 hunk 被靜默截斷為僅第一個完整 block，以及 diff2html exception 是穩定 `parse-error`，且訊息不含 patch 或 dependency message；TDD 使用明確 source content 的 injected content/type/number mismatch red regressions，與實際 Parser parsed trailing-LF normal control green regression。
- Renderer：每檔固定 `outputFormat: "line-by-line"` 與 `drawFileList: false`；file identity/order、HTML entry、metadata entry；dependency exception 是 `render-error`。
- Integration：concrete stages 與既有 non-DOM `DiffOutputPort` test double 注入既有 UseCase。success flow 必須斷言 test double 恰接收一次 Renderer 產出的 RenderPlan；只有 `invalid-input`／`parse-error`／`render-error` short-circuit 可斷言 Output 未呼叫；任何情境均不得接觸 DOM。
- Tester 執行 frozen install、check、test、coverage、`git diff --check`；Reviewer 確認 diff 未觸及 read-only surface 或 dependency topic，且五個 selected PR threads 均有對應 evidence。

## Delivery Gates

- Legacy `PR-02`、`IM-01`、`TE-01`、`RV-01`、`DL-01` 與 `HC-01` 永久保留 pending historical-deviation entries；它們不構成 correction 的實作、delivery 或 human-review prerequisite。
- Human 對 `PC-03` 的接受曾建立 correction route：`PC-03 → PR-03 approved → IM-02 → TE-02 → RV-02 approved → DL-02 → HC-02`；此 route 與其 status 保留為歷史紀錄。
- `DL-02` 對既有 draft PR branch 的 delivery record 保留為歷史；任何 `needs-rework`、`blocked` 或 `human-check` 仍依目前 ledger 停止或回修。

## PR Comment Review Correction Gates

- `PC-05` 只記錄五個 selected PR thread remediations；不改寫 PC-01 至 PC-04 或既有 PR／IM／TE／RV／DL／HC statuses。
- `PR-04` 已由獨立 Plan-Reviewer 明示 `approved`；因此 `IM-03` 可開始新的 TDD correction。IM-03 已提供 red／green evidence，TE-03 已提供獨立 Tester `pass` evidence；兩者均保留為歷史事實，不取代 Reviewer verdict。
- `RV-03` 已明示 `needs-rework`，不得視為 approval。Plan-Creator 的本次 ledger-evidence correction 不新增未被要求的 implementation 或 Tester gate；後續唯一 route 為 `PC-06 → RV-04 fresh independent review approved → DL-03 → HC-03`。RV-04 必須是獨立於 IM-03 Implementer 與 TE-03 Tester 的 fresh Reviewer，並審查更正後 ledger、RV-03 verdict 與既有 factual evidence/statuses。
- 僅 RV-04 明示 `approved` 後，DL-03 才可建立 correction commit、push 至既有 PR branch，並只 resolve 五個已驗證處理的 threads；不得 commit/push/resolve 其他 thread。DL-03 後停止於 HC-03 human review。

## Sixth PR Thread #1 Correction Gates

- `PC-07` 只更新四份 formal artifacts：鎖定 Parser 以 template source 的 ordered hunk header tuples 對照 diff2html parsed blocks，empty patch 必須為 zero blocks，並記錄 multi-hunk silent-truncation TDD case；不改 TS、architecture／BC docs、dependencies 或 Git。
- `PR-05` 必須由獨立 Plan-Reviewer 明示 `approved`，才可開始 `IM-04`。`IM-04` 先新增兩個有效來源 hunk、dependency 只回傳第一個完整 block 的 failing test，斷言 stable/no-leak `parse-error`，再以最小 internal Parser 修正轉綠；同時保留完整 multi-hunk parse/render success。
- `TE-04` 的獨立 Tester 已回報 frozen install、check、test、coverage、diff check evidence。`RV-05` 審查後的明示 verdict 為 `needs-rework`，因此 `DL-04`／`HC-04` 不得前進；所有 prior routes/statuses（包括 `PC-05 → PR-04 → IM-03 → TE-03 → RV-03 → PC-06 → RV-04 → DL-03 → HC-03`）均只保留為歷史，且不被回填或改寫。

## Sixth PR Thread #1 Reviewer Rework Gates

- `PR-05` 已由獨立 Plan-Reviewer `approved`；`IM-04` 的 TDD evidence 包含 injected parse result 對有效 two-hunk source 的靜默截斷 red case 與 green correction；`TE-04` 已完成獨立 verification。它們均為事實記錄，不將 RV-05 的 `needs-rework` 轉為 approval。
- `PC-08` 只更新四份 formal artifacts，鎖定 correction：Parser 對每個 patch 恰建立一次 `GitDiffTemplate` unified source，並將同一 source 同時傳給 parse 與 `isCompleteDiff2HtmlParseResult`。source hunk headers 與 parsed block headers 都正規化為 `{ old: { start, count }, new: { start, count } }`，依序比較 tuples 和 parsed old/new line-array counts。
- `PR-06` 必須由新的獨立 Plan-Reviewer 明示 `approved`，才可開始 `IM-05`。`IM-05` 先新增可歸因 failing test，再以最小 internal Parser/test change 實作 single-source、structured-tuple comparison；保留 injected silent-truncation `parse-error`，並新增真實有效 two-hunk Parser→Renderer green regression。不得改 Validator、UseCase、public contract、Port、docs、dependencies 或 Git。
- `TE-05` 獨立執行 frozen install、check、test、coverage、diff check。`RV-06` 獨立確認 Parser-only scope、ReadOnly preservation、red/green、two-hunk Parser→Renderer regression 與 Tester evidence。只有 `RV-06` 明示 `approved`，`DL-05` 才可 commit、push 至既有 PR branch，並只 resolve thread #1；之後停在 `HC-05` human review。
- 固定 corrective route：`PC-08 → PR-06 approved → IM-05 → TE-05 → RV-06 approved → DL-05 → HC-05`。PC-08／PR-06 前不得修改程式、docs、dependencies 或 Git。

## Sixth PR Thread #1 Pre-Gate Historical Deviation

- Human 接受本次 historical deviation：`IM-05` 已有可歸因 red／green TDD evidence，`TE-05` 已有獨立 Tester `pass` evidence，但兩者發生時 `PR-06` 仍為 pending，沒有 Plan-Reviewer approval。這些是歷史 evidence，不是 gate completion。
- `PR-06` 保持 pending，絕不回填為 approved。`RV-06` 的歷史結果是 `human-check`／`blocked`，不是 approval；因此既有 `DL-05` 不得執行。
- 本次 Plan-Creator 記錄後，唯一可前進路徑為 fresh independent Reviewer 審查 historical-deviation record、locked scope、IM-05／TE-05 evidence 與 RV-06 non-approval result。僅該 Reviewer 的明示 `approved` 可解鎖既有 `DL-05`；不得補造 `PR-06` approval 或改寫既有 route/status。

## Seventh PR Thread #1 Source-Line Completeness Gates

- `PC-10` 只更新同 topic 四份 formal artifacts，鎖定 Parser-local source-line completeness correction；不改 TypeScript、docs、dependencies 或 Git，且不回填或改寫任何 prior status/evidence。
- `PR-07` 必須由獨立 Plan-Reviewer 明示 `approved`，才可開始 `IM-06`。`IM-06` 必須先加入 injected parsed-line mismatch 的 failing test；source expectation 需涵蓋 context、delete、insert 的精確 type/body/old-new mapping，unknown source prefix 或 body/type/number mismatch 皆須 stable/no-leak `parse-error`。再以最小 Parser/test change 轉綠，並保留真正由 Parser 解析的正常 control green test。
- `TE-06` 獨立執行 frozen install、check、test、coverage、diff check。`RV-08` 獨立確認 Parser-only scope、ReadOnly preservation、red/green evidence、line-level exact mapping 與 Tester evidence。只有 `RV-08` 明示 `approved`，`DL-06` 才可 commit、push 至既有 PR branch，並只 resolve thread #1；之後停在 `HC-06` human review。
- 固定 route：`PC-10 → PR-07 approved → IM-06 → TE-06 → RV-08 approved → DL-06 → HC-06`。`PR-07` 前不得修改程式、docs、dependencies 或 Git。

## Eighth PR Thread #1 Source-Marker Content Gates

- `PR-07` 已明示 `needs-rework`：PC-10 所記 body-only comparison 不符合 `DiffLine.content` contract。`PC-11` 只更新同 topic 四份 artifacts，鎖定 marker-plus-body exact comparison、type/numbers 獨立 checks 與 trailing-LF split handling；不改 TypeScript、docs、dependencies 或 Git，且不回填或改寫 prior status/evidence。
- `PR-08` 必須由獨立 Plan-Reviewer 明示 `approved`，才可開始 `IM-07`。`IM-07` 必須先以明確 source content 建立 injected content、type、number mismatch 的 failing tests，再以最小 Parser/test change 轉綠；保留由實際 Parser 解析、帶 trailing LF、涵蓋 context/delete/insert 的 valid control。unknown prefix 與所有 mismatch 都必須 stable/no-leak `parse-error`。
- `TE-07` 獨立執行 frozen install、check、test、coverage、diff check。`RV-09` 獨立確認 Parser-only scope、ReadOnly preservation、red/green evidence、exact `DiffLine.content` mapping、trailing-LF rule 與 Tester evidence。只有 `RV-09` 明示 `approved`，`DL-07` 才可 commit、push 至既有 PR branch，並只 resolve thread #1；之後停在 `HC-07` human review。
- 固定 route：`PC-11 → PR-08 approved → IM-07 → TE-07 → RV-09 approved → DL-07 → HC-07`。`PR-08` 前不得修改程式、docs、dependencies 或 Git。

## Eighth PR Thread #1 PR-08 Pre-Gate Historical Deviation Gates

- Human 接受本次 historical deviation：`IM-07` 的 red／green TDD evidence 與 `TE-07` 的獨立 Tester `pass` 已在 `PR-08` pending、沒有獨立 Plan-Reviewer approval 時發生。它們保留為 factual evidence；`PR-08`、`IM-07`、`TE-07` 永久保持 `pending`，不構成 gate completion。
- `RV-09` 的 historical result 為 `blocked`，不是 approval；既有 `PC-11 → PR-08 → IM-07 → TE-07 → RV-09 → DL-07` route 只保留為歷史，不能據以 delivery。
- `PC-12` 只更新四份 formal artifacts，如實記錄上述 evidence/status；不改 TypeScript、docs、dependencies 或 Git，也不新增 nonblocking type-only mismatch test 或任何其他實作／測試工作。
- 唯一可前進 route 是 `PC-12 → RV-10 fresh independent review approved → DL-07 → HC-07`。`RV-10` 必須獨立審查 locked scope、PR-08 pending、IM-07 red／green、TE-07 `pass` 與 RV-09 `blocked`；僅其明示 `approved` 可解鎖既有 `DL-07`，以 commit、push 並只 resolve thread #1。

## Ninth PR Comment Correction Gates — EOF Marker and CRLF

- `PC-13` 只更新同 topic 四份 artifacts，鎖定兩個 selected threads：合法 `\ No newline at end of file` source metadata marker 與 CRLF hunk content completeness comparison。不改 TypeScript、docs、dependencies 或 Git，且不回填或改寫任何 prior route/status/evidence。
- Parser-local `isCompleteDiff2HtmlParseResult` 必須將精確 EOF marker 視為 metadata；它不建立 expected parsed line、不消耗 old/new count，也不視為 unknown prefix。此例外不適用於其他反斜線-prefixed hunk body；其他 unknown prefix 必須繼續回傳 stable/no-leak `parse-error`。
- Parser 只在 private completeness-comparison representation canonicalize source expectation 與 diff2html parsed line 的 line-ending／marker-removal difference。template source 本身、傳入 `diff2html.parse` 的 input、raw snapshot 與既有 Validator/UseCase flow 均不得改動；parse input 必須保持同一份 original template source。
- `IM-08` 先加入 exact EOF-marker failing regression，再以最小 Parser/test correction 轉 green，並保留 actual Parser→Renderer success。CRLF 測試必須先記錄 actual Parser/diff2html behavior：若已 green，保留 truthful green characterization，不能捏造 red；若初始為 red，才保留可歸因 red/green evidence。未知 prefix 與 malformed patch 的 strict stable/no-leak `parse-error` controls 必須持續通過。
- `TE-08` 獨立執行 frozen install、check、test、coverage、diff check。`RV-11` 獨立確認 Parser-only scope、同一未改寫 source 的 parse input、EOF metadata exclusion、CRLF canonical comparison、TDD evidence 與 ReadOnly preservation。只有 `RV-11` 明示 `approved`，`DL-08` 才可 commit、push 並只 resolve 此兩個 selected threads；之後停在 `HC-08` human review。
- 固定 route：`PC-13 → PR-09 approved → IM-08 → TE-08 → RV-11 approved → DL-08 → HC-08`。`PR-09` 前不得修改程式、docs、dependencies 或 Git。

## Tenth PR Comment Correction Gates — Nonexact Backslash EOF Marker

- 已發生 evidence 如實保留：`PR-09` 為 independent Plan-Reviewer `approved`，`IM-08` 有 exact EOF-marker／CRLF TDD evidence，`TE-08` 為 independent Tester `pass`；`RV-11` 的明示 verdict 是 `needs-rework`，不得進入 `DL-08`。
- `PC-14` 只更新四份 artifacts，鎖定 metadata exception 的 exactness regression。test fixture 必須在 otherwise-valid hunk 放入 `\ No newline at end of file `（尾端一個空白）；它不同於唯一允許的 exact marker，故 Parser 必須回傳 stable/no-leak `parse-error`，不得把它視為 metadata 或略過。
- Existing independent Plan-Reviewer 已對 `PR-10` 明示 `approved`；`IM-09` 僅新增上述 single negative test，並保留 production Parser、其他 TypeScript、Validator、UseCase、template、public surface、docs、dependencies 與 Git 不變的 factual evidence。
- Existing independent Tester 的 `TE-09` evidence 已涵蓋 frozen install、check、test、coverage、diff check，以及 nonexact marker 與既有 EOF／CRLF／unknown-prefix controls。`RV-12` 的既有 verdict 為 `blocked`，因當時 ledger 漏記 PR-10 approval；它不是 delivery approval，且不得改寫為 `approved`。
- `PC-15` 只如實補記上述 evidence 與 RV-12 blocked，保留所有既有 status/history。唯一可前進 route：`PC-15 → RV-13 fresh independent review approved → DL-08 → HC-08`。RV-13 必須重審 test-only scope、stable/no-leak result、exact EOF／CRLF coverage、ReadOnly preservation 與 RV-12 blocked 原因；只有其明示 `approved` 可解鎖 DL-08。

## Eleventh PR Comment Correction — Preamble, Identity, and Rename Metadata

- **Scope**：只修正 Parser 對第一個 hunk 前非 template preamble 的 nonempty garbage 拒絕、internal Parser→Renderer 的 PR／snapshot identity 保留，以及 renamed 無 `previousFilename` 時的 metadata-unavailable fallback。缺少舊路徑不是 Validator error；provided empty old path 仍是 `invalid-input`，non-renamed 仍不得帶 old path。
- **Implementation**：Validator 的 validated input 保留既有 immutable envelope。Parser 僅接受 template-generated preamble；其他第一個 hunk 前非空 source line 一律是 stable/no-leak `parse-error`。Parser 對缺少 `previousFilename` 的 renamed 檔案直接建立 metadata entry，完全不建立 template 或呼叫 parse；Renderer 原樣保留其 identity／metadata，完全不呼叫 render dependency。對可解析 entries，Parser 將 `pullRequestId`／`snapshotId` 與 `fileId` 放入 internal parsed envelope，Renderer 原值轉入 opaque RenderPlan；不調整 public type 或 UseCase。
- **TDD and verification**：先建立 generated-preamble green control 與 pre-hunk garbage red regression；建立兩組不同 PR／snapshot 的 Parser→Renderer identity regression；建立 missing-rename Validator-success、Parser／Renderer metadata result 與 Template／parse／render zero-call regression；保留有 `previousFilename` renamed parse/render control。獨立 Tester 執行 frozen install、check、test、coverage、diff check；Reviewer 檢查 public/read-only surface、stable no-leak failures、identity propagation 與三個 thread 對應。
- **Delivery**：`PC-16 → PR-11 approved → IM-10 → TE-10 → RV-14 approved → DL-09 → HC-09`。PR-11 前不改程式；DL-09 只可依已授權流程 commit、push、更新既有 PR，並 resolve 精確三個 selected threads。任何非 approved verdict、需改公開 contract／Port／UseCase／依賴，或 metadata entry 無法保存既有 internal fields，均停止並交還 human。

## Eleventh Correction Historical-Deviation Route

- Human 已接受 `IM-10` TDD 與 `TE-10` Tester pass 在 `PR-11` approval 前發生的 deviation。`PR-11`、`IM-10`、`TE-10` 永久保持 `pending`，只保留其 factual evidence；不得補造 Plan-Reviewer approval。
- `RV-14` 的既有 verdict 是 `blocked`，不能 delivery。`PC-17` 只更新四份 artifacts，如實記錄上述 evidence/status；不改實作、tests、docs、dependencies 或 Git。
- 唯一 delivery route 改為 `PC-17 → RV-15 fresh independent review approved → DL-09 → HC-09`。RV-15 必須審查 locked scope、歷史 evidence 與 ReadOnly preservation；DL-09 僅可 commit、push 至既有 branch 並 resolve 三個 selected threads。

## Accepted Historical Deviation and Corrective Routing

- Human 已接受：本 topic 的 implementation 在 `PR-02` 仍 pending 時開始。此接受僅允許如實保留既有工作結果，不會追溯核准 `PR-02`，也不會補造或重新標示 red／green evidence。
- 可歸因的歷史 evidence：Implementer 報告最初 red tests 因 target modules 尚未存在而失敗、後續 rework red tests，以及其後 green checks；Tester 獨立報告 frozen install、check、test、coverage、diff check command evidence；technical Reviewer 已提供 implementation review result。這些均不是既有 delivery gate 的替代品。
- 舊 gates 不回填、不審核為 delivery prerequisite。Human 對 `PC-03` 的接受將既有 evidence 保留為歷史脈絡，並由新增 correction gates 處理後續實作與審查。

## Responsibility-Boundary Correction Gates

- 此 correction 保持 `DiffRenderUseCase` 為既定的 orchestration-only caller：只協調 Validator → Parser → Renderer → Output 與既定 failure short-circuit；不得新增 diff2html、unified diff 或 parsed-shape logic。
- `PC-04` 只記錄本次 bounded correction；舊 `PR-02`、`IM-01`、`TE-01`、`RV-01`、`DL-01` 與 `HC-01` 的 status 與 historical-deviation record 均不回填，且不參與 correction routing。
- `PR-03` 至 `HC-02` 保留當時 correction routing 的歷史內容，不改寫其 step status；它們不 gate PC-05 及其後的 PR-comment remediation route。
