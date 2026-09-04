# PR Reader WebView Diff Concrete Stages — Technical Spec

## Locked Decisions

- 本 topic 屬 PR Reader，遵守既定 runtime flow：`Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；只實作前三個 concrete stage。
- `DiffSnapshot`、`DiffViewModel`、Ports、stage result、opaque brands、UseCase、Facade 與 public `index.ts` 全部維持不變。concrete factories、VO 與 representations 僅為 internal module exports，不從 public barrel 匯出。
- Validator 只對原始 runtime `DiffSnapshot` 做結構驗證：`pullRequestId`／`snapshotId`／`fileId`／filename 為非空字串；`fileId` 在 snapshot-local files 中唯一；status 是 `added | removed | modified | renamed`；`viewed` 為 boolean；additions／deletions 為非負安全整數；patch 若存在則為字串。`renamed` 必須有非空 `previousFilename`，其餘 status 不得有 `previousFilename`。它不解析 patch syntax、不產生 unified diff，且不檢查 diff2html 或 parsed result。
- Validator success 建立 internal branded `ValidatedDiffInput`，不可變且保留 snapshot order、identity、metadata 與 optional patch。任何不合格資料回傳既有、不含 patch 的 `invalid-input`。
- `GitDiffTemplateInput` 是 immutable per-file internal VO，承載 `fileId`、filename、status、rename metadata 與 patch，且沒有 old/new Git blob SHA。`GitDiffTemplate` 依 added／removed／modified／renamed 建立單檔 unified Git diff source：保留 `diff --git`、必要 file header、`---`／`+++` path、rename metadata 與 patch，但完全省略所有 `index ` 行；它不屬公開 contract。
- Parser 只按 `ValidatedDiffInput` 的原始順序處理。有 patch 時以 template source 呼叫 `diff2html.parse`；no-patch 時建立 metadata-unavailable parsed entry。Parser 的 internal `isCompleteDiff2HtmlParseResult` 僅防禦第三方結果：要求輸入所產生的單一 Git diff 對應一個完整 git-diff result；非空 patch 必須包含完整且格式正確的 hunk blocks，empty patch 可為零 blocks。此 helper 不重驗 `DiffSnapshot`。template、`diff2html.parse` throw 或該完整性檢查失敗時，回傳既有、不含 patch 或 dependency message 的穩定 `parse-error`。diff2html parsed data 維持 internal，UseCase 不認識其型別、source 或檢查規則。
- Renderer 按 parsed entry order 處理。它對 parsed diff 呼叫 `diff2html.html`，固定 `outputFormat: "line-by-line"`、`drawFileList: false`；對 metadata-unavailable entry 保留其 identity 與狀態。render throw 時回傳既有、不含 patch 的 `render-error`。HTML 與 `RenderPlan` internals 不公開，也不在此 topic 輸出至 DOM。
- concrete stage 完成且驗證成功後，architecture README 與 PR Reader BC 文件只可將「Validator、Parser、Renderer 已有 internal concrete implementation」回寫為長期 truth，並繼續明示 Output、DOM、Swift bridge、viewed-state persistence 尚未實作。

## Internal Module Boundary

新增 `surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/`，其中包含 validator、parser、renderer、`git-diff-template` 與各自 tests。此資料夾是唯一可存取 opaque brands 的 internal implementation boundary；它以 type assertion 建立既有 branded values，並以 private shapes 消費它們。既有 contracts 不新增 production schema。

## File Impact Contract

| Operation | Scope |
| --- | --- |
| ReadOnly | `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、package manifest、lockfile、existing dependency topic artifacts。 |
| Written | 同 slug 四份 formal artifacts；`concrete-stages/` 下 validator、parser、renderer、`git-diff-template` 及對應 tests。 |
| Modify | 只在 test harness 需要註冊新增 module 時修改該 harness；concrete-stage verification 成功後，最小修改 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` 的既定 truth statement。 |
| Deleted | 無。 |

## Verification Contract

- 不以 patch payload 或 raw dependency error 作為 public failure message；只使用既有 error kinds 與穩定 stage-specific message。
- 成功流必須保留每個 file 的 `fileId` 及 snapshot order；no-patch 是成功 input 的 metadata-unavailable representation，不是 error 或省略。
- Template 不得以 `0000000`、`1111111`、`2222222` 或其他 placeholder 偽造 Git object identity；four-status fixture 必須確認 source 沒有 `index ` 行且仍可 parse/render。nonempty malformed patch 必須穩定地是 `parse-error`，empty patch 必須維持成功可 render。
- `diff2html@3.4.56` 必須由 repo-local package resolution 提供；本 topic 不修改 manifest 或 lockfile。
- Output 不實作 concrete stage，亦不接觸 DOM；integration success test 必須以既有 non-DOM `DiffOutputPort` test double 注入 UseCase，並斷言它恰接收一次 Renderer 所產出的 RenderPlan。僅前三種 stage failure short-circuit 可斷言 Output 未呼叫。
- Implementer 必須採 TypeScript TDD：每個可觀察 stage／integration behavior 先建立可歸因的 failing test（red），以最小 strict TypeScript implementation 使其通過（green），只在 green 持續時重構；交接必須含 red failure 與 green local verification evidence。Tester 仍獨立執行 frozen install、check、test、coverage、diff check。
- 實作進入前須取得獨立 Plan-Reviewer 明示 `approved`；任何 public contract、dependency、DOM／Swift、HTML safety policy 或 scope 變更需求均為 `blocked`／human boundary。

## Historical Deviation Record

- Human 已接受一次 historical deviation：實作在 `PR-02` 仍為 pending 時開始。這項接受不回溯將 `PR-02` 視為 approved，也不將既有 red／green 或 technical review evidence 轉為 gate approval。
- 可歸因的歷史 evidence 僅供後續獨立審查使用：Implementer 報告最初 red test 因 target modules 尚未存在而失敗，並另報告後續 rework red tests；其後報告 green checks。Tester 獨立報告 frozen install、check、test、coverage 與 diff check command evidence；technical Reviewer 報告 implementation review result。
- `PR-02`、`IM-01`、`TE-01`、`RV-01`、`DL-01` 與 `HC-01` 永久保留為 historical-deviation ledger entries，status 維持 pending，但不再是任何實作、delivery 或 human review 的 prerequisite。Human 對 `PC-03` 的接受建立 corrective route，唯一可交付路徑由 `PR-03` 起始。

## Boundary Correction Record

- 此 correction 不重開既定 pipeline、public contract、Port、UseCase orchestration、dependency version 或 file-impact boundary。`DiffRenderUseCase` 只以既定順序協調 Validator → Parser → Renderer → Output，並套用既定 failure short-circuit；它不得知道 diff2html、unified diff 或 parsed result shape。
- correction implementation 必須採新的可歸因 TDD cycle：先新增 four-status no-index parse/render、nonempty malformed stable/no-leak `parse-error`、empty-patch success 的 failing tests，再以最小 internal implementation 轉綠。這是新的 correction evidence，不回填或取代 historical-deviation record 的舊 evidence。
- correction 的唯一 authoritative route 為：`PC-03 → PR-03 approved → IM-02 → TE-02 → RV-02 approved → DL-02 → HC-02`。`DL-02` 將 correction commit push 至既有 draft PR；舊 steps 的 status 僅維持歷史紀錄，不得作為此路徑的 prerequisite。
