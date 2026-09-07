# PR Reader WebView Diff Concrete Stages — Requirements

## Goal

為既有 PR Reader WebView diff pipeline 提供 internal concrete Validator、Parser、Renderer 與 `GitDiffTemplate`，使既有 `DiffRenderUseCase` 可將一份 `DiffSnapshot` 轉換為 opaque internal `RenderPlan`。有 patch 的檔案使用 repo-local `diff2html@3.4.56` 產出逐檔 line-by-line HTML；無 patch 的有效檔案保留為 metadata-unavailable entry。

## Non-Goal

- 不實作 `DiffOutputPort`、DOM 插入、HTML safety policy、CSS、WebView UI、syntax highlighting、side-by-side rendering 或 file list。
- 不修改 Swift bridge、viewed persistence、公開 barrel、Port、stage result、failure kind、`DiffSnapshot` 或 `DiffViewModel` contract。
- 不變更 `package.json`、`bun.lock` 或 diff2html version，亦不修改既有 dependency topic artifacts。

## In-Scope

- 建立同 slug 的四份正式 SDD artifacts。
- Validator 僅驗證原始 `DiffSnapshot` 的 runtime 結構與不變量；它不認識 unified diff、diff2html 或任何 parsed result shape。
- Parser 僅接收已驗證的 `ValidatedDiffInput`，以 immutable per-file VO 與 internal `GitDiffTemplate` 建立單檔 unified Git diff source，呼叫 diff2html，並在 Parser 內以來源 hunk header/count 序列對照 parsed blocks 序列，防禦第三方靜默遺漏結果。
- `GitDiffTemplateInput` 不承載 Git blob SHA；template 不得輸出任何 `index ` 行、`new file mode`／`deleted file mode`／`old mode`／`new mode` 行或 placeholder object identity。
- `GitDiffTemplate` 對非 `/dev/null` path 在加上 `a/`／`b/` prefix 後，使用 deterministic Git C-style serializer：僅由 `[A-Za-z0-9._/+\-]` 組成的 token 維持未加引號；其餘 token 以雙引號包覆，`"`、`\\` 與 C named controls 分別輸出 `\"`、`\\`、`\a`／`\b`／`\f`／`\n`／`\r`／`\t`／`\v`，其他 control、DEL 與 non-ASCII UTF-8 bytes 輸出零補三位八進位 escape。added 的 old path 與 removed 的 new path 維持 `/dev/null`，不加 prefix 或引號。
- 實作 structural Validator、diff2html Parser 與 line-by-line Renderer，並維持 snapshot 的 file order 與 `fileId`。
- 將 no-patch file 表達為 metadata-unavailable entry；將未預期的 template／dependency exceptions 收斂為既有 stage failure kind，且 error message 不得包含 patch。
- concrete stages 成功後，最小回寫 architecture README 與 PR Reader BC 文件的 implementation truth；本輪 PR remediation 僅校正 architecture README 首段，使其不再與既有 concrete-stage implementation truth 矛盾。

## Out-Of-Scope

- 新增公開 API、factory export、Port、adapter boundary、failure outcome 或 composition API。
- 將 diff2html 型別或資料、HTML、`GitDiffTemplateInput` 或 internal representation 外洩至公開 contract。
- Validator 解析 unified diff syntax、檢查 diff2html 結果，或 Parser／Renderer 修改 snapshot。
- 將 diff2html、unified diff source 或 parsed result shape 移入 UseCase，或將 Parser 的第三方結果防禦誤稱為第二個 Validator。
- 將 no-patch 視為 invalid input、跳過檔案、建立 DOM placeholder，或採用 partial-file skip policy。

## Success Criteria

- `DiffSnapshot → ValidatedDiffInput → ParsedDiffInput → RenderPlan` 僅透過既有 stage Ports 的 opaque values 串接。
- 有 patch 的有效檔案可透過 diff2html 解析並以 `outputFormat: "line-by-line"`、`drawFileList: false` 產生 HTML。
- added、removed、modified、renamed 的 patch 在沒有 `index ` 或 mode metadata 行時仍可 parse 並 render；Git C-style-quoted path 維持正確 old/new side prefix 與 escape；非空 malformed patch 必須為不洩漏內容或 dependency message 的穩定 `parse-error`；empty patch 仍是合法且可 render 的 input。
- 缺少 patch 的有效檔案依原順序保留 metadata-unavailable entry。
- `invalid-input`、`parse-error`、`render-error` 均是穩定的既有 outcome，且不洩漏 patch；成功流以既有 non-DOM `DiffOutputPort` test double 接收 RenderPlan 一次，DOM 不被呼叫。

## File Impact

| Category | Paths / policy |
| --- | --- |
| ReadOnly | `contracts/`、`ports/`、`usecases/`、`facades/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency topic artifacts，以及除明示 truth amendment 外的 architecture／BC 文件。 |
| Written | `analysis/pr-reader-webview-diff-concrete-stages/requirements.md`、`analysis/pr-reader-webview-diff-concrete-stages/technical-spec.md`、`plan/pr-reader-webview-diff-concrete-stages/pr-reader-webview-diff-concrete-stages.plan.md`、`plan/pr-reader-webview-diff-concrete-stages/pr-reader-webview-diff-concrete-stages.step.md`，以及 internal concrete-stage、template 與 test modules。 |
| Deleted | 無。 |
| Modify | 僅新增或修正 internal TypeScript implementation/test modules；必要時最小修改既有 test harness 以註冊新 test module；concrete stage 成功後僅修改 architecture README 與 PR Reader BC 文件的 truth statement。本輪 PR remediation 的 docs 改動限於 architecture README 首段 truth correction。 |

## TestCase

- Validator：有效 snapshot、空 identity、重複 `fileId`、非法 status、rename metadata 不一致、非布林 `viewed`、負數或非安全整數 counters、非字串 patch。
- Template／Parser：added、removed、modified、renamed patch 皆不輸出 `index ` 或 fake mode metadata 且仍可 parse/render；四種 status 的 nonempty patch 必須從 template source 讀取一個以上有效 hunk header，並使每個來源 hunk 的 old/new start/count 與 parsed block header 在相同順序逐一相等，且 parsed old/new line counts 等於該來源 count；empty patch 必須為 zero parsed blocks；no-patch metadata entry；Git C-style path 的 prefix、quote、backslash、named control 與 octal UTF-8 escapes；非空 malformed patch、multi-hunk source 被第三方靜默截斷為僅第一個完整 block，以及 dependency exception 均為不洩漏 patch 或 dependency message 的穩定 `parse-error`；以內部 `isCompleteDiff2HtmlParseResult` 檢查第三方結果完整性，而非重驗 `DiffSnapshot`。
- Renderer：line-by-line config、`drawFileList: false`、identity 與順序保留、HTML entry、metadata entry，以及 dependency exception 為 `render-error`。
- Integration：以 concrete stages 與既有 non-DOM `DiffOutputPort` test double 注入既有 UseCase；成功流須斷言 test double 恰收取一次 renderer 產出的 RenderPlan。僅 `invalid-input`／`parse-error`／`render-error` short-circuit 可斷言 Output 不呼叫；所有情境皆不得接觸 DOM。
- Implementer 依 TypeScript TDD 的 red-green-refactor：先新增可歸因於目標行為的 failing test，再以最小 strict TypeScript implementation 轉綠，最後僅在 tests 持續通過下重構；handoff 必須保留 red 與 green evidence。
- Tester 執行 `bun install --frozen-lockfile`、`bun run check`、`bun test`、`bun run test:coverage` 與 `git diff --check`。

## PR Comment Remediation Boundary

- 本輪只處理已選定的五個 PR threads：ledger corrective route、parsed hunk line-count completeness、Git C-style path quoting／escaping、architecture README 首段 truth 與 fake `100644` mode metadata removal。
- `PR-04` 已由獨立 Plan-Reviewer 明示 `approved`；`IM-03` 已交付可歸因於五項 remediation 的 red／green evidence；`TE-03` 已由獨立 Tester 明示 `pass`。這些 evidence 不取代成果審查。
- `RV-03` 的現行明示 verdict 為 `needs-rework`，不是 approval。此次 Plan-Creator ledger-evidence correction 完成後，必須直接交由新的獨立 Reviewer 審查已更正 ledger 與既有 factual evidence/statuses；只有該 fresh review 明示 `approved`，才可進入 `DL-03`。
- Implementer 的 TDD、Tester verification、Reviewer scope check 與 delivery 只可將這五個已驗證處理的 threads resolve；不得順帶處理其他 thread 或擴張 scope。

## Sixth PR Thread #1 Correction Boundary

- 此 route 僅處理第六個、目前未解決的 PR thread #1：多 hunk patch 的 diff2html 結果若靜默遺漏後續 block，Parser 必須回傳既有穩定 `parse-error`。它不重開或改寫前五個 thread 的 remediation、route、evidence 或 status。
- Parser 必須從 `GitDiffTemplate` 產生的 source 讀取每個 hunk header 的 old/new start/count，按來源順序與唯一 parsed git-diff file 的 blocks 一對一比較；每個 block header 與其 old/new line counts 都必須對應同一位置的來源 header/count。非空 patch 沒有有效來源 hunk header、block 數不同、header 不同或 line count 不同皆為 `parse-error`。empty patch 的 source expectation 與 parsed blocks 都必須為 zero。
- 此為 Parser-local third-party-result defense，不重新驗證 `DiffSnapshot`，不修改 Validator、UseCase、公開 contract、Port、dependency、architecture／BC docs 或 Git metadata。
- Implementer 必須先加入可歸因的 red test：以兩個有效來源 hunks 和一個僅回傳第一個完整 block 的 injected `parseDiff` 結果，斷言穩定且不洩漏的 `parse-error`；再以最小 internal Parser 修正轉綠。有效 multi-hunk source 仍須可 parse/render。
- `PC-07 → PR-05 approved → IM-04 → TE-04 → RV-05 needs-rework` 是第六個 thread 的已發生 route；`DL-04`／`HC-04` 未取得 gate，不得執行。此 route 的 evidence/status 保留為歷史，不得回填為 approval。

## Sixth PR Thread #1 Reviewer Rework Boundary

- `PR-05` 已由獨立 Plan-Reviewer 明示 `approved`；`IM-04` 已交付兩個有效來源 hunk 被 injected third-party result 靜默截斷為第一個完整 block 的 TDD red／green evidence；`TE-04` 已由獨立 Tester 回報 frozen install、check、test、coverage 與 diff check 的驗證 evidence。這些 factual records 不取代 `RV-05` verdict，且不授權 delivery。
- `RV-05` 的明示 verdict 為 `needs-rework`：Parser 必須為每個有 patch 的檔案只建立一次 `GitDiffTemplate` unified source，並將同一 source 同時交給 diff2html parse 與完整性檢查；不得為完整性檢查另行產生或重建 source。
- Parser 的 source hunk headers 與 parsed blocks 都必須正規化為 internal structured tuples：`old { start, count }`、`new { start, count }`。完整性檢查必須按順序比較 tuple 數量與每個 old/new start/count，並比較對應 parsed block 的 old/new line-array counts；任何差異仍收斂為既有 stable、no-leak `parse-error`。此工作仍是 `isCompleteDiff2HtmlParseResult` 的 Parser-local third-party-result defense，不是第二個 Validator。
- 下一輪必須新增自動化 green regression：以有效、實際由 Parser 解析的 two-hunk patch 交給 Renderer，驗證 Parser→Renderer 成功；它與 injected silent-truncation red case 都必須保留。
- 只有新的 corrective route `PC-08 → PR-06 approved → IM-05 → TE-05 → RV-06 approved → DL-05 → HC-05` 可前進。`PC-08` 只改四份 artifacts；PR-06 前不得改程式、docs、dependencies 或 Git。DL-05 只可 resolve thread #1。

## Sixth PR Thread #1 Pre-Gate Historical Deviation

- Human 已接受本次 deviation：`IM-05` 與 `TE-05` 的工作在 `PR-06` 尚未取得獨立 Plan-Reviewer approval 時已發生。此接受不回溯核准 `PR-06`；其 ledger status 永久維持 `pending`，不構成或取代任何 implementation gate。
- `IM-05` 的可歸因歷史 evidence 是本輪 Parser/tests 的 red／green TDD 結果；`TE-05` 的可歸因歷史 evidence 是獨立 Tester 的 `pass`。兩者僅供新的獨立審查檢視，不改寫既有 route，也不構成 `RV-06` 或 delivery approval。
- `RV-06` 的歷史結果為 `human-check`／`blocked`，明確不是 `approved`。不得由此結果進入 `DL-05`、commit、push 或 resolve thread #1。
- 唯一可前進的 corrective route 是：本次 Plan-Creator evidence record 完成後，交由 fresh independent Reviewer 審查既有 artifacts、`PR-06` pending 狀態、IM-05／TE-05 factual evidence 與 RV-06 的 non-approval result；只有該 Reviewer 明示 `approved`，才可進入既有 `DL-05`。不補造 `PR-06` approval，也不回填 prior status。
