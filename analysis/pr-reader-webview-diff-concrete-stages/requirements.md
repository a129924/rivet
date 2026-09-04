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
- Parser 僅接收已驗證的 `ValidatedDiffInput`，以 immutable per-file VO 與 internal `GitDiffTemplate` 建立單檔 unified Git diff source，呼叫 diff2html，並在 Parser 內防禦第三方不完整結果。
- `GitDiffTemplateInput` 不承載 Git blob SHA；template 不得輸出任何 `index ` 行或 placeholder object identity。
- 實作 structural Validator、diff2html Parser 與 line-by-line Renderer，並維持 snapshot 的 file order 與 `fileId`。
- 將 no-patch file 表達為 metadata-unavailable entry；將未預期的 template／dependency exceptions 收斂為既有 stage failure kind，且 error message 不得包含 patch。
- concrete stages 成功後，最小回寫 architecture README 與 PR Reader BC 文件的 implementation truth。

## Out-Of-Scope

- 新增公開 API、factory export、Port、adapter boundary、failure outcome 或 composition API。
- 將 diff2html 型別或資料、HTML、`GitDiffTemplateInput` 或 internal representation 外洩至公開 contract。
- Validator 解析 unified diff syntax、檢查 diff2html 結果，或 Parser／Renderer 修改 snapshot。
- 將 diff2html、unified diff source 或 parsed result shape 移入 UseCase，或將 Parser 的第三方結果防禦誤稱為第二個 Validator。
- 將 no-patch 視為 invalid input、跳過檔案、建立 DOM placeholder，或採用 partial-file skip policy。

## Success Criteria

- `DiffSnapshot → ValidatedDiffInput → ParsedDiffInput → RenderPlan` 僅透過既有 stage Ports 的 opaque values 串接。
- 有 patch 的有效檔案可透過 diff2html 解析並以 `outputFormat: "line-by-line"`、`drawFileList: false` 產生 HTML。
- added、removed、modified、renamed 的 patch 在沒有 `index ` 行時仍可 parse 並 render；非空 malformed patch 必須為不洩漏內容或 dependency message 的穩定 `parse-error`；empty patch 仍是合法且可 render 的 input。
- 缺少 patch 的有效檔案依原順序保留 metadata-unavailable entry。
- `invalid-input`、`parse-error`、`render-error` 均是穩定的既有 outcome，且不洩漏 patch；成功流以既有 non-DOM `DiffOutputPort` test double 接收 RenderPlan 一次，DOM 不被呼叫。

## File Impact

| Category | Paths / policy |
| --- | --- |
| ReadOnly | `contracts/`、`ports/`、`usecases/`、`facades/`、public `index.ts`、`package.json`、`bun.lock`、既有 dependency topic artifacts，以及除明示 truth amendment 外的 architecture／BC 文件。 |
| Written | `analysis/pr-reader-webview-diff-concrete-stages/requirements.md`、`analysis/pr-reader-webview-diff-concrete-stages/technical-spec.md`、`plan/pr-reader-webview-diff-concrete-stages/pr-reader-webview-diff-concrete-stages.plan.md`、`plan/pr-reader-webview-diff-concrete-stages/pr-reader-webview-diff-concrete-stages.step.md`，以及 internal concrete-stage、template 與 test modules。 |
| Deleted | 無。 |
| Modify | 僅新增 internal TypeScript implementation/test modules；必要時最小修改既有 test harness 以註冊新 test module；concrete stage 成功後僅修改 architecture README 與 PR Reader BC 文件的 truth statement。 |

## TestCase

- Validator：有效 snapshot、空 identity、重複 `fileId`、非法 status、rename metadata 不一致、非布林 `viewed`、負數或非安全整數 counters、非字串 patch。
- Template／Parser：added、removed、modified、renamed patch 皆不輸出 `index ` 行且仍可 parse/render；no-patch metadata entry；empty patch 成功；非空 malformed patch 與 dependency exception 為不洩漏 patch 或 dependency message 的穩定 `parse-error`；以內部 `isCompleteDiff2HtmlParseResult` 檢查第三方結果完整性，而非重驗 `DiffSnapshot`。
- Renderer：line-by-line config、`drawFileList: false`、identity 與順序保留、HTML entry、metadata entry，以及 dependency exception 為 `render-error`。
- Integration：以 concrete stages 與既有 non-DOM `DiffOutputPort` test double 注入既有 UseCase；成功流須斷言 test double 恰收取一次 renderer 產出的 RenderPlan。僅 `invalid-input`／`parse-error`／`render-error` short-circuit 可斷言 Output 不呼叫；所有情境皆不得接觸 DOM。
- Implementer 依 TypeScript TDD 的 red-green-refactor：先新增可歸因於目標行為的 failing test，再以最小 strict TypeScript implementation 轉綠，最後僅在 tests 持續通過下重構；handoff 必須保留 red 與 green evidence。
- Tester 執行 `bun install --frozen-lockfile`、`bun run check`、`bun test`、`bun run test:coverage` 與 `git diff --check`。
