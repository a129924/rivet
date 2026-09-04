# PR Reader WebView Diff Concrete Stages — Execution Plan

## Summary

在既有 orchestration 與 opaque stage contract 內，新增 internal concrete Validator、Parser、Renderer、`GitDiffTemplate` 與測試。這個 topic 止於 `RenderPlan` 的建立；沒有 Output、DOM 或公開 surface 變更。

## Goal and Boundaries

- **Goal**：將有效 `DiffSnapshot` 轉為 internal `RenderPlan`，有 patch 的檔案使用 repo-local diff2html 產生逐檔 line-by-line HTML，無 patch 的檔案保留 metadata-unavailable entry。
- **Non-Goal**：不實作 concrete Output 或顯示 HTML；不處理 HTML safety、CSS、UI、syntax highlighting、Swift bridge、viewed persistence、side-by-side 或 file list。
- **In-Scope**：structural validation、per-file immutable VO、unified Git diff template、parse、render、internal opaque representation、tests，以及 concrete-stage verified 後的最小 docs truth amendment。
- **Out-Of-Scope**：公開 API／Port／contract／dependency 變更；Validator 的 patch parsing；修改 snapshot；no-patch failure 或 skip；其他 architecture／BC 結論。

## Implementation Changes

- 建立 `concrete-stages/diff-view-model-validator.ts`，實作既有 Validator Port 的 locked structural checks；成功時建立不可變 branded validated input，失敗時回傳穩定 `invalid-input`。
- 建立 `concrete-stages/git-diff-template.ts`，以 immutable `GitDiffTemplateInput` 根據單一檔案 status 組裝 unified Git diff source；不對外 export VO 或 template。
- 建立 `concrete-stages/diff-parser.ts`，依 input order 對 patch entries 執行 template 與 `diff2html.parse`，對 no-patch entries 保留 metadata-unavailable，並將 template／parse exception 收斂為 `parse-error`。
- 建立 `concrete-stages/diff-renderer.ts`，依 input order 對 parsed entries 執行 `diff2html.html`，固定 line-by-line 且不繪製 file list，建立 opaque `RenderPlan`；render exception 為 `render-error`。
- 在同一 internal folder 建立對應 tests；必要時僅註冊既有 test harness。完成 concrete-stage verification 後，最小更新 architecture README 與 PR Reader BC 的 implementation truth，其他 docs 不動。
- Implementer 必須以 TypeScript TDD 完成每個可觀察 stage 與 integration behavior：先新增可歸因於尚未實作行為的 failing test（red），再以最小 strict TypeScript implementation 使其通過（green），最後只在 tests 持續通過時重構。Implementer handoff 必須逐一提供 red failure 與 green local verification evidence；不得以 `any` 或弱化 strict 設定迴避型別問題。

## File Operations

| Operation | Scope |
| --- | --- |
| ReadOnly | `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency topic artifacts。 |
| Written | 同 slug 四份 artifacts，及 `concrete-stages/` 下四個 internal implementation modules 與其 test modules。 |
| Modify | 僅既有 test harness（如必需）及在 concrete success 後的 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 既定 truth statement。 |
| Deleted | 無。 |

## Test Plan

- Validator：valid snapshot；empty identity；duplicate `fileId`；invalid status；rename metadata mismatch；invalid `viewed`；negative／unsafe counters；non-string patch。
- Template／Parser：added、removed、modified、renamed unified diff；no-patch metadata entry；invalid diff 與 diff2html exception 是 `parse-error`，且訊息不含 patch。
- Renderer：每檔固定 `outputFormat: "line-by-line"` 與 `drawFileList: false`；file identity/order、HTML entry、metadata entry；dependency exception 是 `render-error`。
- Integration：concrete stages 與既有 non-DOM `DiffOutputPort` test double 注入既有 UseCase。success flow 必須斷言 test double 恰接收一次 Renderer 產出的 RenderPlan；只有 `invalid-input`／`parse-error`／`render-error` short-circuit 可斷言 Output 未呼叫；任何情境均不得接觸 DOM。
- Tester 執行 frozen install、check、test、coverage、`git diff --check`；Reviewer 確認 diff 未觸及 read-only surface 或 dependency topic。

## Delivery Gates

- 僅在獨立 Plan-Reviewer 對 PR-02 明示 `approved` 後，Implementer 可進行 bounded implementation；Implementer 必須交接 TypeScript TDD 的可歸因 red 與 green evidence。
- Implementer 明示完成後，Tester 獨立執行 frozen install、check、test、coverage、diff check；Tester 明示結果後，獨立 Reviewer 審查 scope、contract、docs truth 與 TDD／Tester evidence。
- Reviewer 只有明示 `approved` 才可進入 topic commit、push、draft PR；delivery 完成後停止於 human PR review。任何 `needs-rework`、`blocked` 或 `human-check` 均依 ledger 路由，不能自行跨越。

## Accepted Historical Deviation and Corrective Routing

- Human 已接受：本 topic 的 implementation 在 `PR-02` 仍 pending 時開始。此接受僅允許如實保留既有工作結果，不會追溯核准 `PR-02`，也不會補造或重新標示 red／green evidence。
- 可歸因的歷史 evidence：Implementer 報告最初 red tests 因 target modules 尚未存在而失敗、後續 rework red tests，以及其後 green checks；Tester 獨立報告 frozen install、check、test、coverage、diff check command evidence；technical Reviewer 已提供 implementation review result。這些均不是既有 delivery gate 的替代品。
- 本紀錄修正後，先由新的獨立 Plan-Reviewer 審查 `PR-02`；再由新的獨立 Reviewer 審查 implementation、上述歷史 evidence、Tester evidence 與本 corrective record。只有該 fresh review 明示 `approved`，才可進入 `DL-01`。
