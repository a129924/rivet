# PR Reader WebView Diff Concrete Stages — Technical Spec

## Locked Decisions

- 本 topic 屬 PR Reader，遵守既定 runtime flow：`Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；只實作前三個 concrete stage。
- `DiffSnapshot`、`DiffViewModel`、Ports、stage result、opaque brands、UseCase、Facade 與 public `index.ts` 全部維持不變。concrete factories、VO 與 representations 僅為 internal module exports，不從 public barrel 匯出。
- Validator 只對原始 runtime `DiffSnapshot` 做結構驗證：`pullRequestId`／`snapshotId`／`fileId`／filename 為非空字串；`fileId` 在 snapshot-local files 中唯一；status 是 `added | removed | modified | renamed`；`viewed` 為 boolean；additions／deletions 為非負安全整數；patch 若存在則為字串。`renamed` 必須有非空 `previousFilename`，其餘 status 不得有 `previousFilename`。它不解析 patch syntax、不產生 unified diff，且不檢查 diff2html 或 parsed result。
- Validator success 建立 internal branded `ValidatedDiffInput`，不可變且保留 snapshot order、identity、metadata 與 optional patch。任何不合格資料回傳既有、不含 patch 的 `invalid-input`。
- `GitDiffTemplateInput` 是 immutable per-file internal VO，承載 `fileId`、filename、status、rename metadata 與 patch，且沒有 old/new Git blob SHA。`GitDiffTemplate` 依 added／removed／modified／renamed 建立單檔 unified Git diff source：保留 `diff --git`、必要 file header、`---`／`+++` path、rename metadata 與 patch，但完全省略所有 `index ` 及 `new file mode`／`deleted file mode`／`old mode`／`new mode` 行；它不屬公開 contract。
- Template 對每一個非 `/dev/null` path 先依 side 加入 `a/` 或 `b/`，再套用 deterministic Git C-style serializer。完整 token 僅含 `[A-Za-z0-9._/+\-]` 時保持 unquoted；否則以雙引號包覆，並將 quote、backslash、C named controls 轉為 `\"`、`\\`、`\a`／`\b`／`\f`／`\n`／`\r`／`\t`／`\v`，其餘 control、DEL 與每個 non-ASCII UTF-8 byte 轉為零補三位八進位 escape。added 的 old path 與 removed 的 new path 是 literal `/dev/null`。這個 serializer 僅是 internal template behavior，不改變 Validator 對 raw filename 的責任。
- Parser 只按 `ValidatedDiffInput` 的原始順序處理。有 patch 時以 template source 呼叫 `diff2html.parse`；no-patch 時建立 metadata-unavailable parsed entry。Parser 的 internal `isCompleteDiff2HtmlParseResult` 僅防禦第三方結果：從 template source 擷取每個有效 hunk header 的 old/new start/count，要求輸入所產生的單一 Git diff 對應一個完整 git-diff result，並按相同順序使來源 hunk headers 與 parsed blocks 一對一相等；每個 block 的 old/new line arrays 亦必須等於同位置來源 header 的 old/new counts。nonempty patch 必須有至少一個有效來源 hunk header；empty patch 的來源 expectation 與 parsed blocks 都必須為 zero。此 helper 不重驗 `DiffSnapshot`。template、`diff2html.parse` throw 或該完整性檢查失敗時，回傳既有、不含 patch 或 dependency message 的穩定 `parse-error`。diff2html parsed data 維持 internal，UseCase 不認識其型別、source 或檢查規則。
- Renderer 按 parsed entry order 處理。它對 parsed diff 呼叫 `diff2html.html`，固定 `outputFormat: "line-by-line"`、`drawFileList: false`；對 metadata-unavailable entry 保留其 identity 與狀態。render throw 時回傳既有、不含 patch 的 `render-error`。HTML 與 `RenderPlan` internals 不公開，也不在此 topic 輸出至 DOM。
- concrete stage 完成且驗證成功後，architecture README 與 PR Reader BC 文件只可將「Validator、Parser、Renderer 已有 internal concrete implementation」回寫為長期 truth，並繼續明示 Output、DOM、Swift bridge、viewed-state persistence 尚未實作。本輪只修正 architecture README 首段與該 truth 一致；不重寫其餘 README 或 BC 文本。

## Internal Module Boundary

新增 `surfaces/pr-reader-webview/src/diff-rendering/concrete-stages/`，其中包含 validator、parser、renderer、`git-diff-template` 與各自 tests。此資料夾是唯一可存取 opaque brands 的 internal implementation boundary；它以 type assertion 建立既有 branded values，並以 private shapes 消費它們。既有 contracts 不新增 production schema。

## File Impact Contract

| Operation | Scope |
| --- | --- |
| ReadOnly | `contracts/`、`ports/`、`usecases/`、`facades/`、`adapters/`、public `index.ts`、package manifest、lockfile、existing dependency topic artifacts。 |
| Written | 同 slug 四份 formal artifacts；`concrete-stages/` 下 validator、parser、renderer、`git-diff-template` 及對應 tests。 |
| Modify | 只在 test harness 需要註冊新增 module 時修改該 harness；concrete-stage verification 成功後，最小修改 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` 的既定 truth statement；本輪 remediation 的 docs 變更只限 README 首段 truth correction。 |
| Deleted | 無。 |

## Verification Contract

- 不以 patch payload 或 raw dependency error 作為 public failure message；只使用既有 error kinds 與穩定 stage-specific message。
- 成功流必須保留每個 file 的 `fileId` 及 snapshot order；no-patch 是成功 input 的 metadata-unavailable representation，不是 error 或省略。
- Template 不得以 `0000000`、`1111111`、`2222222` 或其他 placeholder 偽造 Git object identity，亦不得輸出 fake `100644` 或其他 mode metadata；four-status fixture 必須確認 source 沒有 `index `／mode 行且仍可 parse/render。path fixtures 必須鎖定 old/new `a/`／`b/` prefix 與 deterministic Git C-style quoting／escaping。nonempty malformed patch 必須穩定地是 `parse-error`；empty patch 必須維持成功可 render。
- `isCompleteDiff2HtmlParseResult` 對 template source 的 nonempty patch 擷取 ordered hunk header tuples（old/new start/count），並要求 parsed blocks 數量相同、同位置 header tuple 相同，且 parsed old/new line arrays 等於該來源 count；任一來源 header 缺失、數量、順序、header 或 line count 不等價即為 stable `parse-error`。empty patch 僅允許 zero source expectations 與 zero blocks。
- `diff2html@3.4.56` 必須由 repo-local package resolution 提供；本 topic 不修改 manifest 或 lockfile。
- Output 不實作 concrete stage，亦不接觸 DOM；integration success test 必須以既有 non-DOM `DiffOutputPort` test double 注入 UseCase，並斷言它恰接收一次 Renderer 所產出的 RenderPlan。僅前三種 stage failure short-circuit 可斷言 Output 未呼叫。
- Implementer 必須採 TypeScript TDD：每個可觀察 stage／integration behavior 先建立可歸因的 failing test（red），以最小 strict TypeScript implementation 使其通過（green），只在 green 持續時重構；交接必須含 red failure 與 green local verification evidence。Tester 仍獨立執行 frozen install、check、test、coverage、diff check。
- 實作進入前須取得獨立 Plan-Reviewer 明示 `approved`；任何 public contract、dependency、DOM／Swift、HTML safety policy 或 scope 變更需求均為 `blocked`／human boundary。

## PR Comment Remediation Record

- 本輪只處理五個已選 PR threads：(1) ledger corrective route、(2) Parser parsed-hunk old/new count completeness、(3) Git C-style path prefix／quoting／escaping、(4) architecture README 首段 implementation truth、(5) fake `100644` mode metadata removal。
- `PR-04` 的獨立 Plan-Reviewer verdict 為 `approved`。`IM-03` 已提供先 red、後 green 的可歸因 TDD evidence；`TE-03` 已提供獨立 Tester `pass` evidence。這些既有結果如實保留，均不等同 `RV-03` approval。
- `RV-03` 的現行獨立 Reviewer verdict 為 `needs-rework`。本次 Plan-Creator 僅更正 ledger evidence，不新增未被要求的 implementation 或 Tester gate；唯一可前進的 route 是 `PC-06 → RV-04 fresh independent review approved → DL-03 → HC-03`。`RV-04` 必須獨立於前次 IM-03 Implementer 與 TE-03 Tester，並審查更正後 ledger、RV-03 verdict 與既有 factual evidence/statuses。它不回填、取代或改寫任何既有 step status 或 historical-deviation record。
- `DL-03` 僅可 commit、push 至既有 PR branch，並 resolve 這五個經 `RV-04` 驗證已處理的 threads，不得處理其他 thread。

## Sixth PR Thread #1 Correction Record

- 第六個、目前未解決的 PR thread #1 要求補強 Parser 對 multi-hunk source 的第三方結果防禦；它是新的 bounded correction，不改寫前五個 thread 或其歷史 route/status/evidence。
- 新 TDD red case 必須以兩個有效來源 hunk 與 injected `parseDiff` 的單一完整第一 block 模擬靜默截斷，預期既有穩定且不洩漏 patch／dependency message 的 `parse-error`；green case 必須確認完整 multi-hunk parse/render 繼續成功。
- 此 route 不新增 Validator、UseCase、公開 contract、Port、dependency 或 docs work。`PC-07` 只修正四份 formal artifacts；僅在 `PR-05` 明示 `approved` 後，`IM-04` 才可對 internal Parser 與其 tests 做最小 TDD 修正。
- `PC-07 → PR-05 approved → IM-04 → TE-04 → RV-05 needs-rework` 是已發生 route；`DL-04` 與 `HC-04` 未獲 gate，保持 pending，不得執行。這不回填或重寫 prior route/status/evidence。

## Sixth PR Thread #1 Reviewer Rework Record

- `PR-05` 有獨立 Plan-Reviewer 的 `approved` verdict；`IM-04` 有兩個有效來源 hunk、injected parse result 僅有第一個完整 block 的 TDD red／green evidence；`TE-04` 有獨立 Tester 的 frozen install、check、test、coverage 與 diff check evidence。`RV-05` 明示 `needs-rework`，上述 evidence 均不構成 delivery approval。
- Parser 對每一個有 patch 的檔案只建立一份 `GitDiffTemplate` unified source；同一 immutable source 必須同時作為 `parseDiff` input 與 `isCompleteDiff2HtmlParseResult` 的 source input。不得重新呼叫 template、從 raw patch 重組，或對 source 使用第二種生成路徑。
- source hunk header 與 parsed block header 都要轉為 internal structured tuple：`{ old: { start, count }, new: { start, count } }`。完整性檢查依序比較 source／parsed tuple 個數及每個 old/new start/count，並比較該 parsed block old/new line-array counts 與同位置 source count。任何不符、缺失或非空 source 沒有有效 tuple 都回傳既有 stable、no-leak `parse-error`；empty patch 仍只接受 zero tuples／zero blocks。
- 除 injected silent-truncation red case 外，internal tests 必須有一個實際有效 two-hunk patch 的 Parser→Renderer green regression，證明同一 template source 的 parse 與完整性檢查不會拒絕可 render 的 multi-hunk result。
- 本 correction 只改 internal Parser/tests；不改 Validator、UseCase、公開 contract、Port、docs、dependencies 或 Git。新 route 為 `PC-08 → PR-06 approved → IM-05 → TE-05 → RV-06 approved → DL-05 → HC-05`；只有 RV-06 `approved` 才可進入 DL-05 並只 resolve thread #1。

## Sixth PR Thread #1 Pre-Gate Historical Deviation Record

- Human 已接受本次 deviation：`IM-05` 的可歸因 red／green TDD evidence 與 `TE-05` 的獨立 Tester `pass`，在 `PR-06` 仍 pending、未取得 Plan-Reviewer approval 時已發生。它們是歷史事實，僅供 fresh independent review；不構成 retroactive implementation gate。
- `PR-06` 永久保留 `pending`，不得標為或推論為 `approved`。`RV-06` 的歷史 non-approval result 為 `human-check`／`blocked`，不得被重寫為 `approved`，且不授權 `DL-05`。
- 本次記錄完成後，新的獨立 Reviewer 必須審查此 historical-deviation record、既有 locked boundary、IM-05／TE-05 factual evidence 與 RV-06 non-approval result。只有 fresh Reviewer 的明示 `approved` verdict 才可進入既有 `DL-05`；不新增或補造 `PR-06` approval。

## Historical Deviation Record

- Human 已接受一次 historical deviation：實作在 `PR-02` 仍為 pending 時開始。這項接受不回溯將 `PR-02` 視為 approved，也不將既有 red／green 或 technical review evidence 轉為 gate approval。
- 可歸因的歷史 evidence 僅供後續獨立審查使用：Implementer 報告最初 red test 因 target modules 尚未存在而失敗，並另報告後續 rework red tests；其後報告 green checks。Tester 獨立報告 frozen install、check、test、coverage 與 diff check command evidence；technical Reviewer 報告 implementation review result。
- `PR-02`、`IM-01`、`TE-01`、`RV-01`、`DL-01` 與 `HC-01` 永久保留為 historical-deviation ledger entries，status 維持 pending，但不再是任何實作、delivery 或 human review 的 prerequisite。Human 對 `PC-03` 的接受建立當時的 corrective route，由 `PR-03` 起始；其 status 與 history 仍保留。

## Boundary Correction Record

- 此 correction 不重開既定 pipeline、public contract、Port、UseCase orchestration、dependency version 或 file-impact boundary。`DiffRenderUseCase` 只以既定順序協調 Validator → Parser → Renderer → Output，並套用既定 failure short-circuit；它不得知道 diff2html、unified diff 或 parsed result shape。
- correction implementation 必須採新的可歸因 TDD cycle：先新增 four-status no-index parse/render、nonempty malformed stable/no-leak `parse-error`、empty-patch success 的 failing tests，再以最小 internal implementation 轉綠。這是新的 correction evidence，不回填或取代 historical-deviation record 的舊 evidence。
- 當時 correction route 為：`PC-03 → PR-03 approved → IM-02 → TE-02 → RV-02 approved → DL-02 → HC-02`。它與 `DL-02` 對既有 draft PR 的 delivery record 均保留為歷史；舊 steps 的 status 不得作為 PC-05 route 的 prerequisite。

## Supersession Note

- 上述 PC-03／PC-04 correction route 與其全部 step status 保留為歷史紀錄。本次 PC-05 不回填其中任何 gate；它只為五個已選 PR comment remediations 新增後續 route。
