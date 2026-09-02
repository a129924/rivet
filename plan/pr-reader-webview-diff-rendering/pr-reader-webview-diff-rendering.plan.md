# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 將集中式 diff contract 替換為實體、分層的零依賴 declaration-only pipeline，並固定以 `DiffSnapshot` 為 input 的 `Adapter ↔ Port → UseCase → Facade` 與 `Validator → Parser → Renderer → Output` 未來實作邊界；PC-07 另將同一份 diff canvas 收斂為 ownership／boundary map，使用同 topic Archify `dataflow` 表達既定 runtime flow，並補齊可重建、可見的 keyboard／screen-reader fallback 與 opaque type brand 邊界。

## Non-Goal

不實作任何 TypeScript parser、renderer、DOM、UI、collapse、syntax highlighting、Swift bridge、GitHub mapping 或 viewed-state 持久化；不新增 package 或修改 lockfile。`viewed` notification 不新增 outcome、reliable transport、acknowledgement、retry 或 bridge implementation。不修改 global `architecture-canvas` template、其他圖或 PR Reader BC 的既定 pipeline 事實。僅在既有 diff canvas folder 增加 artifact-local build／a11y 行為與一份重述既定 flow 的 Archify `dataflow`，不重開或變更 PR Reader BC 邊界。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、PR Reader BC 文件、既有 architecture-canvas scene／index 與 WebView toolchain 設定。
- 既有 TypeScript source、tests、package scripts 與 compiler 設定，以確認實際放置位置與 strict typecheck 命令。

## Written

- 同 topic 的四份 planning artifacts。
- `src/diff-rendering/` 下的 declaration-only modules 與依 module 分檔的 type-level tests，限於既有 PR Reader WebView surface。
- `docs/architecture/README.md` 中 baseline 例外、compile-time dependency／Adapter boundary／runtime render request 的精確 wording；PR Reader BC 僅在長期事實實際改變時才更新。
- `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 下的 ownership-only canvas scene／generated index、其唯一 diagram-local reproducible build entry、accessibility enhancer／verifier，以及同 topic 的 Archify `dataflow` specification／generated HTML；包含兩個 skill 的 validation／build evidence。

## Modify

僅可修改本 topic 的四份 artifacts，以及 Implementer 為落實已鎖定 contract 所需的 TypeScript declarations、tests、`docs/architecture/README.md`、PR Reader BC 文件與既有 PR Reader WebView diff diagram folder。本輪只允許在該 folder 新增冪等 single build entry、post-build accessibility enhancer／verifier 與 Archify `dataflow` artifacts；不得修改 global template、其他 diagrams 或套件。移除既有集中式 `src/diff-rendering.contract.ts` 與其 test，替換為已鎖定的 `src/diff-rendering/` tree。除已確認的架構 writeback、canvas responsibility alignment、`dataflow` render-flow representation 與 diagram-local accessibility 外，其他現有 repository 檔案不修改。

## Deleted

僅刪除由 module tree 取代的集中式 diff contract source 與 test。

## Implementation Changes

1. 建立 technical spec 指定的 `contracts/`、`adapters/`、`ports/`、`usecases/`、`facades/` 與 `index.ts`；每個 module 只宣告其 layer 的 type／interface，不建立任何 concrete behavior。
2. 新增 public `DiffSnapshot` contract，固定 `readonly pullRequestId`、`snapshotId` 與 `files: readonly DiffViewModel[]`；既有 `DiffViewModel` 不變。將它與 `DiffFileStatus`、帶 PR／snapshot identity 的 `ViewedStateChange`、含 `output-error` 的 `DiffRenderOutcome`、opaque stage inputs 與 stage-specific results 放入對應 contracts modules。
3. 定義 `DiffSnapshotAdapter.receiveSnapshot(snapshot): void`、exact Port signatures、internal `DiffRenderUseCase.execute(snapshot)` 與 public `DiffFacade.present(snapshot)`／`requestViewedStateChange`；Validator、UseCase 與 Facade 都只接受 `DiffSnapshot`。UseCase 是四個 pipeline Ports（含 Output）的唯一協調者與 Output caller，Facade 只依賴 UseCase 與 viewed-state Port。
4. 定義 `ViewedStateChangeAdapter` 直接 extends `ViewedStateChangePort`，不得新增 wrapper 或第二個 notification method。`index.ts` 只匯出 `DiffFacade`、`DiffSnapshot`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；所有 opaque types、Ports、Adapters、dependency descriptors 與 UseCase 均保持 internal。
5. 保持 `ViewedStateChangePort.notify` 與 `DiffFacade.requestViewedStateChange` 為 best-effort `void`；在 type-level tests、架構文件與圖中明確限定其為 Swift snapshot-reconciliation 模型下的 viewed notification exception。不得新增 notification outcome、acknowledgement、transport、delivery guarantee、retry 或 optimistic state。
6. 建立或調整依 module 分檔的 type-level tests，驗證 snapshot contract、未變更的 file model、相鄰 stage outputs、`output-error`、viewed notification identity、精確 `void` signatures、Adapter-to-Port assignability、UseCase／Facade dependency ownership、barrel export surface 與禁止跨層依賴；不以 tests 引入 DOM 或第三方工具。
7. 僅將已確認的 snapshot、render flow 與 viewed notification exception 事實回寫 `docs/architecture/README.md` 與 PR Reader BC 文件。
8. 以 `architecture-canvas` 更新 scene 與 generated index：它只表達 declaration-only pipeline 的 ownership 與 Swift／WebView boundary，不得以 edge、標題、strapline、fallback prose 或其他 visual language 表達 runtime render sequence；作者內容使用繁體中文，canvas `index.html` 使用 `lang="zh-Hant"`。Archify 的 global generated viewer chrome 與文件語言只支援英文／簡體中文，且本 PR 不修改 global template，因此 Archify generated HTML 保留英文 chrome 與 `lang="en"`；不得宣稱整個 viewer 已完成繁中化，visibility／readability 留待 HC-06。完成 skill validate 與 build evidence；不得發布 artifact.cafe。
9. 修正 `docs/architecture/README.md`：baseline 的「不建立程式碼、抽象層或產品功能」只排除已鎖定的 declaration-only modules 與這份圖 artifact-local accessibility；分別呈現 core compile-time dependency `Presentation → Facade → UseCase → Port`、Adapter 符合 Port 並隔離 Outside，及既定 runtime render request。不得將 Adapter 放回主 render path 或變更 Output ownership。
10. 為 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 建立唯一、diagram-local、冪等的 reproducible build entry：validate `scene.js`、產生與 committed `index.html` 同 filesystem 的 temporary canvas build、執行 enhancer 與 verifier，並執行 Archify validate，將 `deliver dataflow` 寫入與 committed `dataflow` HTML 同 filesystem 的 temporary target。只有兩個 temporary HTML 都成功、通過 hash／consistency check 後，才以 atomic rename 分別更新兩個 committed outputs。重跑必須 byte-identical；任何步驟失敗均不得改寫任一 committed output，必須清理全部 temporary outputs 並以非零結束。不得修改 global template、其他圖、套件，或手動修改生成 HTML。
11. enhancer 必須讓 `BOXES`／`EDGES` 維持唯一資料真相，僅在 generated canvas index 補上繁中 artifact-local UI、focusable `#stage` region／description、`aria-hidden` canvas、stage-scoped viewport keys、`[`／`]` box traversal、live readout 與動態生成的 native semantic fallback controls／relationships。fallback 必須位於正常文件流並使用可發現的語意 control（例如 `details`／`summary`）；buttons 不得 visually clipped，且需有 `:focus-visible` 與 fallback container `:focus-within`。所有 selection input 共用既有行為，無第二套 selection state；不得用 `role="application"` 或 window-global listener。
12. 以 Archify 在同一 diagram folder 建立 `dataflow` specification／generated HTML，唯一表達既定 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` runtime render flow。`dataflow` 只能重述已鎖定的 stage failure 與 Output ownership，不能新增 concrete behavior 或架構事實；必須執行 `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json`，再以 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json` 交付至同 filesystem temporary target；不得發布。
13. 將 opaque stage inputs 的 phantom brand 改為 module-private `declare const ...: unique symbol` 與 required `never` brand property。不得 export brand value 或建立 runtime `Symbol`；opaque interfaces 仍 internal 且不可由一般結構物件建構。

## Test Cases

- `DiffSnapshot` 以 readonly PR identity、snapshot identity 與完整有序 `readonly DiffViewModel[]` 表達 render input；`DiffViewModel` 繼續表達 added、removed、modified、renamed、optional patch、rename 前路徑、非負增刪計數與 viewed 狀態。
- 四個 stage 只接受前一 stage success value，且只產生各自允許的 error kind；Output 失敗只使用 `output-error`；UseCase 與 Facade 的 dependency descriptors 只含既定 keys。
- `DiffSnapshotAdapter.receiveSnapshot`、Validator、UseCase 與 Facade 的方法參數、回傳型別與 readonly snapshot envelope contract 完全相符；UseCase 是 Output Port 唯一 caller，Facade 不依賴 Output Port。
- viewed notification 以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 boolean 送出；`notify` 與 `requestViewedStateChange` 是唯一的 best-effort `void` exception，不產生 outcome、acknowledgement、delivery guarantee、retry 或 snapshot mutation API。
- `ViewedStateChangeAdapter` 可結構性指派為 `ViewedStateChangePort`，且不包含 wrapper 或第二個 notification method。
- barrel 僅公開 `DiffFacade`、`DiffSnapshot`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；core 不得 import Adapter、Swift、WebView 或 Presentation。
- 架構 README 與 PR Reader BC 文件只陳述已確認的 snapshot、主 render flow 與 viewed notification exception；不將 deferred bridge／transport behavior 寫成既定架構。
- architecture-canvas scene／generated index 只呈現 ownership／boundary，且不以任何 visual text／edge 重複 runtime render sequence；作者內容為繁體中文、canvas `index.html` 為 `lang="zh-Hant"`，且附帶 skill validate／build evidence。Archify `dataflow` artifact 精確表達既定 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`，並通過 `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json` 與寫至 same-filesystem temporary target 的 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json`；Archify global chrome／`lang="en"` 不屬本 PR 的本地化承諾，HC-06 必須人工確認其 visibility／readability。
- README baseline、compile-time dependency、Adapter boundary 與 runtime render request 各自精確，且沒有把已鎖定 declaration-only pipeline 或 Output ownership 說成產品實作。
- single build entry 可重跑且通過：scene validate、canvas temp build、enhance、verify、Archify validate 與 same-filesystem temporary deliver 全數成功，並通過兩個 temporary outputs 的 hash／consistency check，才 atomic rename 更新 committed canvas index 與 `dataflow` HTML；兩次成功輸出 byte-identical，注入 failure 不可改寫任一舊 output 或遺留 temporary artifact。
- canvas fallback：stage 是中文命名的 focusable region 並描述操作、canvas `aria-hidden`、無 `role="application"`／window-global keydown、viewport keys 僅在 stage focus、`[`／`]` 依 `BOXES` 巡覽並更新 aria-live readout，且 fallback 從 `BOXES`／`EDGES` 產生原生可 Tab node controls 與中文 relationship list。fallback 在正常 flow、可發現且具 `:focus-visible`／`:focus-within`；不可 visually clip buttons，且所有 input 共用 selection 行為。
- opaque stage input 的 brands 是 non-exported `declare const ...: unique symbol`，無 runtime `Symbol` 或 value export；ordinary structural object 不可指派為 opaque input，而既有相鄰 stage 型別相容性不變。
- 既有 Bun typecheck、tests 與 coverage gate 通過；若命令或環境不存在，明確分類為 blocker。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立、移除或修改 TypeScript contract declarations、tests、架構 README、PR Reader BC 文件或 architecture-canvas 圖。
- 若現有 surface 無法定位、strict TypeScript 設定不明，或 contract 與既有公開入口衝突，Implementer 停止並回報具體 blocker；不得自行改寫已鎖定 contract。
- Tester 或 Reviewer 發現 contract、scope 或 workflow drift 時，只由獨立 Implementer 進行最小相符修正並重新驗證。
- Reviewer 明示 `approved` 後，Code-Implementer 才可依 human 已授權的本 topic Git 流程 commit、push 更新既有 PR #4，回覆並 resolve 本輪已修正 threads；GitHub handoff 完成後停止於 human review。
- PC-07、PR-07、IM-07、TE-07、RV-07 與 GH-07 必須依序完成；PR-07 未 approved 前不得實作。若 canvas 無法只表達 ownership／boundary、Archify `dataflow` 需要新增架構資料、single build entry 無法保證兩個 generated artifacts 的 same-filesystem temporary delivery、hash／consistency check、atomic rename、clean failure／idempotence、fallback 需要 visually clipped controls／第二套 selection state，或 opaque brand 修正影響公開 contract，即停止並回報 blocker。任何新架構資料、contract 或 scope violation 都必須交還 human；GH-07 完成後停止於 HC-06，runtime browser／screen-reader 驗證與 Archify 英文 chrome／`lang="en"` 的可讀性維持 human check。
