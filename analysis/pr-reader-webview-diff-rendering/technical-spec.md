# PR Reader WebView Diff Rendering — Technical Spec

## Locked Decisions

- 實作只新增 TypeScript type／interface declarations 與 type-level tests，並維持零新增依賴；不得修改 package manifest 或 lockfile。
- 本 topic 不實作 validator、parser、renderer、Output、DOM、UI、collapse、syntax highlighting、Swift bridge 或具體 raw diff／RenderPlan schema。
- `DiffSnapshot` 是 Swift 每次提供的完整、有序 snapshot envelope，帶 `pullRequestId`、`snapshotId` 與 `readonly DiffViewModel[]`；`DiffViewModel` 本身不變，Swift 是 `viewed` 的唯一持久化權威。
- WebView 的 collapse 僅可在未來作為本地暫態狀態，不能寫入或改變 snapshot contract。
- `Output` 是獨立 pipeline stage；其 failure contract 為公開的 `output-error`。
- `ViewedStateChange` 以 `pullRequestId`、`snapshotId` 與 snapshot-local `fileId` 識別通知所屬資料，Swift 可安全忽略過期 notification。
- `ViewedStateChangePort.notify` 與 `DiffFacade.requestViewedStateChange` 是對一般正式 layer／BC 邊界 `Outcome` 規則的狹義例外：兩者固定回傳 best-effort `void`。這是因為 Swift 是 snapshot 與 `viewed` 的權威、TS 不做 optimistic update，且本 topic 尚無可靠 bridge／transport implementation；此例外不延伸至 render pipeline 或其他 Port。
- `DiffRenderUseCase` 是 `Validator → Parser → Renderer → Output` 的唯一協調者與 `DiffOutputPort` 唯一 caller；`DiffFacade` 只依賴 UseCase 與 Viewed-state Port。

## Module Structure

移除集中式 `src/diff-rendering.contract.ts`，改以以下 production module tree 表達 pipeline：

```text
src/diff-rendering/
  contracts/
    diff-snapshot.ts
    diff-view-model.ts
    viewed-state-change.ts
    stage-results.ts
    opaque-stage-inputs.ts
  adapters/
    diff-snapshot-adapter.ts
    viewed-state-change-adapter.ts
  ports/
    diff-view-model-validator-port.ts
    diff-parser-port.ts
    diff-renderer-port.ts
    diff-output-port.ts
    viewed-state-change-port.ts
  usecases/
    diff-render-use-case.ts
  facades/
    diff-facade.ts
  index.ts
```

- 每個 production module 僅含該 layer 的 type／interface declarations；不得提供 concrete Adapter、Validator、Parser、Renderer、Output、DOM 或 Swift bridge 實作。
- Adapter modules 只定義 Swift snapshot input 與 viewed notification 的邊界介面；`DiffSnapshotAdapter.receiveSnapshot` 接收 `DiffSnapshot`，而 `ViewedStateChangeAdapter` 直接 extends `ViewedStateChangePort`，不得另定 wrapper 或第二個 notification method contract。核心 contracts、Ports、UseCase 與 Facade 不得依賴 Adapter、Swift 或 WebView。
- `DiffRenderUseCase` 的 dependency descriptor 只含 Validator、Parser、Renderer、Output 四個 pipeline Ports，並由 UseCase 依序協調全部 stages。
- `DiffFacade` 的 dependency descriptor 只含 UseCase 與 Viewed-state Port；Facade 不依賴或呼叫 Output Port。

## Public Contract

```ts
export type DiffFileStatus = "added" | "removed" | "modified" | "renamed"

export interface DiffViewModel {
  readonly fileId: string
  readonly filename: string
  readonly previousFilename?: string
  readonly status: DiffFileStatus
  readonly patch?: string
  readonly additions: number
  readonly deletions: number
  readonly viewed: boolean
}

export interface DiffSnapshot {
  readonly pullRequestId: string
  readonly snapshotId: string
  readonly files: readonly DiffViewModel[]
}

export interface ViewedStateChange {
  readonly pullRequestId: string
  readonly snapshotId: string
  readonly fileId: string
  readonly viewed: boolean
}

export type DiffRenderOutcome =
  | { readonly type: "success" }
  | {
      readonly type: "error"
      readonly kind: "invalid-input" | "parse-error" | "render-error" | "output-error"
      readonly message: string
    }
```

- `DiffSnapshot` 是 Presentation render input 的唯一 snapshot envelope；`pullRequestId` 與 `snapshotId` 識別其所屬 PR 與版本，`files` 是完整且有序的檔案集合。
- `fileId` 僅須在同一份 `DiffSnapshot` 中唯一；它不是跨 snapshot 的全域識別子。
- `ViewedStateChange` 必須帶 `pullRequestId`、`snapshotId`、`fileId` 與 `viewed`，讓 Swift 能辨識 notification 的 PR 與 snapshot，並安全忽略過期事件。
- `filename` 是目前檔案路徑；`previousFilename` 僅於 `status: "renamed"` 時可提供，並表示先前路徑。
- `status` 是檔案層級的 added、removed、modified 或 renamed 語意；它不決定 diff 行的新增、刪除或 context。
- `patch` 可對任何 `status` 缺席，表示內容不可取得；其格式與任何 fallback 不在本 topic 定義。
- `additions` 與 `deletions` 是非負整數，`0` 合法，且值由 Swift 提供。

`src/diff-rendering/index.ts` 是唯一 public barrel，且只匯出：

```ts
export type {
  DiffFileStatus,
  DiffRenderOutcome,
  DiffSnapshot,
  DiffViewModel,
  ViewedStateChange,
}
export type { DiffFacade }
```

`ValidatedDiffInput`、`ParsedDiffInput`、`RenderPlan`、stage results、Ports、Adapters、dependency descriptors 與 `DiffRenderUseCase` 均為 internal，禁止由 barrel 匯出。

## Internal Stage and Layer Contract

```ts
declare const validatedDiffInputBrand: unique symbol
declare const parsedDiffInputBrand: unique symbol
declare const renderPlanBrand: unique symbol

export interface ValidatedDiffInput {
  readonly [validatedDiffInputBrand]: never
}

export interface ParsedDiffInput {
  readonly [parsedDiffInputBrand]: never
}

export interface RenderPlan {
  readonly [renderPlanBrand]: never
}

export type ValidationResult =
  | { readonly type: "success"; readonly value: ValidatedDiffInput }
  | { readonly type: "error"; readonly kind: "invalid-input"; readonly message: string }

export type ParseResult =
  | { readonly type: "success"; readonly value: ParsedDiffInput }
  | { readonly type: "error"; readonly kind: "parse-error"; readonly message: string }

export type RenderPlanResult =
  | { readonly type: "success"; readonly value: RenderPlan }
  | { readonly type: "error"; readonly kind: "render-error"; readonly message: string }

export type OutputResult =
  | { readonly type: "success" }
  | { readonly type: "error"; readonly kind: "output-error"; readonly message: string }

export interface DiffViewModelValidatorPort {
  validate(snapshot: DiffSnapshot): ValidationResult
}

export interface DiffParserPort {
  parse(input: ValidatedDiffInput): ParseResult
}

export interface DiffRendererPort {
  createRenderPlan(input: ParsedDiffInput): RenderPlanResult
}

export interface DiffOutputPort {
  output(plan: RenderPlan): OutputResult
}

export interface ViewedStateChangePort {
  notify(change: ViewedStateChange): void
}

export interface DiffRenderUseCase {
  execute(snapshot: DiffSnapshot): DiffRenderOutcome
}

export interface DiffFacade {
  present(snapshot: DiffSnapshot): DiffRenderOutcome
  requestViewedStateChange(change: ViewedStateChange): void
}

export interface DiffSnapshotAdapter {
  receiveSnapshot(snapshot: DiffSnapshot): void
}

export interface ViewedStateChangeAdapter extends ViewedStateChangePort {}
```

- `ValidatedDiffInput`、`ParsedDiffInput` 與 `RenderPlan` 必須維持 opaque；其 phantom brand 是同一 module 的非匯出 `declare const ...: unique symbol`，只存在型別層，不得是 exported value 或 runtime `Symbol`。required `never` brand 令一般 consumer 無法用結構物件建構這些型別；其 schema 仍在各自後續實作 topic 才能定義。
- Validator、Parser、Renderer 與 Output 各自只回傳所屬 stage 的 success／failure union；相鄰 stage 只能消費前一 stage 的 success value。
- `DiffRenderUseCase.execute` 依序協調 Validator、Parser、Renderer 與 Output，並將各 stage failure 映射為對應 `DiffRenderOutcome` kind；UseCase 是 `DiffOutputPort` 的唯一 caller。UseCase、Validator 與 Facade 均以 `DiffSnapshot` 接收 render input。
- `ViewedStateChangeAdapter` 直接符合 `ViewedStateChangePort`；`DiffSnapshotAdapter` 只定義 Swift 的 inbound snapshot boundary。UseCase 只依賴四個 pipeline Ports，Facade 是 Presentation 的唯一 render 入口。Facade 僅宣告對 UseCase 與 Viewed-state Port 的 dependency descriptor；此處不定義 adapter、use case 或 facade 的建構／組裝方式。
- `requestViewedStateChange` 透過 `ViewedStateChangePort` 發送通知，回傳 best-effort `void`，不等待 Swift acknowledgement，且不做 optimistic snapshot 更新。`void` 不表示 delivery、enqueue 或 serialization 成功，也不建立 retry、failure mapping 或 transport guarantee；這些行為與任何 bridge contract 均留待獨立實作 topic。此例外不得用來削弱 `execute` 的四個 stage outcome mapping，或擴張為其他 layer／Port 的通用規則。

## Architecture Writeback

- IM-05 必須只將已確認的 `DiffSnapshot` input envelope、render 主路徑與 viewed notification 的狹義 `void` exception 回寫至 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md`；不得將 deferred concrete behavior 寫成長期事實。
- PC-07 必須更新 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/scene.js` 與其 generated `index.html`，使 architecture-canvas scene 只表達 ownership／boundary；Adapter 僅保留為 Swift／viewed 邊界宣告。既定 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` runtime flow 由同 folder 的 Archify `dataflow` artifact／specification 表達。所有圖作者內容採繁體中文，canvas generated index 的 `<html lang>` 必須是 `zh-Hant`；Archify global generated viewer chrome 與文件語言受限於英文／簡體中文，因本 PR 禁改 global template，Archify generated HTML 保留英文 chrome 與 `lang="en"`。
- 依 `architecture-canvas` skill 對 scene 執行 validate，並以 PC-07 single build entry 從同 scene build canvas index；Archify `dataflow` 必須以 `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json` 驗證，並以寫至同 filesystem temporary target 的 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json` 交付；兩個 generated artifacts 僅在 hash／consistency check 後才 atomic rename，保存兩者 evidence；不得自行發布 artifact.cafe。

## PC-06 Documentation and Diagram-local Accessibility Revision

- 本輪只修正 `docs/architecture/README.md` wording 與既有 PR Reader WebView diff architecture-canvas artifact；不改 TypeScript pipeline、Swift bridge、套件、global `architecture-canvas` template 或其他圖。這是既有 topic 的可近用性與文件收斂，不重開 `DiffViewModel`、Swift snapshot authority、viewed best-effort `void`、零依賴或 declaration-only pipeline 決策。
- README 必須把 baseline 限定為「除已鎖定的 PR Reader WebView diff declaration-only modules 與該圖 artifact-local viewer accessibility 外」，仍不建立產品功能。它必須分開陳述：(1) core 的 compile-time dependency 為 `Presentation → Facade → UseCase → Port`；(2) Adapter 符合 Port 並隔離 Outside；(3) runtime render request 為 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`。三項皆不得改變既定 Output ownership 或 Adapter 非主路徑的決策。
- `scene.js` 的 `BOXES`／`EDGES` 是圖資料唯一真相。既有圖的 generated `index.html` 必須透過**該圖資料夾內**的 post-build enhancer／verifier 建立可近用性補強；重跑必須冪等。不得修改 skill 的 global template、將手抄的 node／edge 資料另存為第二份真相，或影響其他 diagrams。
- canvas 的 artifact-local UI、hint、toolbar 與 fallback 作者文字皆使用繁體中文，且 `<html lang="zh-Hant">`；`#stage` 必須是帶中文 label 的可聚焦 `role="region"`，以 `aria-describedby` 指向操作說明；canvas 必須 `aria-hidden="true"`。不得使用 `role="application"`。Archify 的 global generated viewer chrome 不在此本地化承諾內。
- viewport keyboard keys 只可在 `#stage` 具有 focus 時處理，且不得註冊 window-global keydown listener。`[` 與 `]` 依 `BOXES` 順序巡覽；選取 node 必須更新既有 readout，且 readout 為 `aria-live` status。鍵盤巡覽、fallback focus 與 fallback click 必須呼叫同一個既有 node-selection 行為，不得導入第二套選取狀態。
- fallback 必須由 runtime `BOXES`／`EDGES` 動態產生：以語意 section／list 描述 ownership／boundary map，為每個 node 提供原生、可 Tab 到達的中文 `button`，並以關係清單呈現 edge。它的目的是讓 screen reader 與純鍵盤使用者取得與圖相等的 node／relationship 資訊，不宣稱 canvas 視覺本身可被讀取，且不得藉此重述 runtime sequence。
- IM-06 只可在 PR-06 approval 後進行；完成時同步 README wording 與這份圖。PR Reader BC 的 pipeline 長期事實沒有改變，故本輪不改寫 BC 文件。

## PC-07 Diagram Responsibility, Reproducibility, and Accessibility Revision

- 本輪是既有 topic 的 R5 PR comment review-and-fix。它只調整已存在 canvas artifact 的責任、其 diagram-local build／a11y scripts、同資料夾新增的 Archify `dataflow` artifact，以及 opaque stage input 的 declaration-only 細節；不重開 `DiffViewModel`、Swift snapshot authority、viewed best-effort `void`、零依賴、declaration-only pipeline 或 Output ownership。
- `architecture-canvas` scene 與 generated canvas 只負責表達 layer ownership 與 Swift／WebView boundary。它不得以 edge、title、subtitle、strapline、readout 或 fallback prose 呈現 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` 的 runtime sequence。既定 runtime render flow 改由同 topic、同 diagram folder 的 Archify `dataflow` specification 與 generated HTML 表達；`dataflow` 只能重述既有 flow、stage failure／ownership facts，不得新增實作、資料契約或架構決策。它必須使用 `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json`，再以 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json` 交付至與 committed `dataflow` HTML 同一 filesystem 的 temporary target；Archify global generated viewer chrome 與 `lang="en"` 保留不變。
- 在 canvas diagram folder 建立唯一可執行、diagram-local 的 reproducible build entry。它必須依序：(1) validate `scene.js`；(2) 將 canvas build 寫到與 committed `index.html` 同一 filesystem 的 temporary output；(3) 對 temporary canvas output 執行 a11y enhancer；(4) 執行 a11y verifier；(5) 執行 Archify `dataflow` validate，並以 deliver 寫到與 committed `dataflow` HTML 同一 filesystem 的 temporary output；(6) 僅在兩個 temporary outputs 都成功後，執行 hash／consistency check；(7) 才以 atomic rename 分別更新 committed `index.html` 與 committed `dataflow` HTML。entry 必須明確檢查重跑冪等；任一步失敗必須保留兩個 committed outputs、不留下 temporary artifact，並以非零結果停止。不得修改 global template、其他 diagram、套件或在 workflow 外手動編輯 generated HTML。
- fallback 的 section／list／native buttons 不得以 `sr-only`、clipping、off-screen 或其他長期視覺隱藏方式承載。它必須留在正常文件流，使用可發現的語意控制（例如原生 `details`／`summary`）與 native button；keyboard focus 必須由 `:focus-visible` 顯示，含焦點的 fallback container 必須由 `:focus-within` 顯示狀態。按鈕的 focus／click、`[`／`]` 與 pointer selection 都必須呼叫同一 node-selection 行為，不得另存 selected id 或導入第二套 state。
- 這輪僅修正 declaration-only opaque stage brands：各 brand 是 opaque-stage-inputs module-private 的 `declare const ...: unique symbol`，且 required brand property 的 type 為 `never`。不得匯出 brand identifier 作為 module／barrel value、不得寫 `Symbol()`、不得產生 runtime brand；opaque interface 可供 internal module 型別引用，但 consumer 不得以普通物件建構。
- IM-07 僅可在 PR-07 approval 後進行。runtime browser 與 screen-reader 的實際互動仍是 human check，不得由靜態 verifier 宣稱完成。

## PC-08 PR Comment Review-and-Fix Revision

- 本輪僅回修 PR #4 四個 finding：fallback 展開時的可捲動性、雙產物 publish 遭 `SIGINT`／`SIGTERM` 中斷時的 rollback、screen-reader 關係文字的方向性，以及 Archify `dataflow` 的 failure edge。它不重開 `DiffViewModel`、Swift snapshot authority、viewed best-effort `void`、零依賴、declaration-only pipeline、Output ownership 或既定 failure kinds。
- fallback 展開後，正常文件流中的 node controls 與 relationship list 必須保持可見、可由鍵盤與 screen reader 到達並可捲動閱讀；不得以 document／page `overflow: hidden` 或等效樣式使展開內容不可捲動。此要求不指定 scrolling container 的具體實作，只要求 keyboard 與 assistive technology 的可到達性。
- screen-reader relationship fallback 必須繼續唯一由 runtime `EDGES` 產生；每項必須呈現來源 node、`→`、目標 node 與 edge label，格式可為「來源 → 目標：標籤」。不得只提供 label、手抄第二份 edge 資料，或將 runtime render sequence 偷渡回 ownership canvas。
- single build entry 必須在 publish 前保留可驗證的兩份 committed-output backup／journal。若 `SIGINT` 或 `SIGTERM` 在第一個 atomic rename 後、第二個 atomic rename 前到達，trap／recovery 必須將兩個 committed outputs 回復為同一組先前內容、清理 temporary 與 backup／journal，並以非零結束；不得將兩次 rename 說成雙檔 atomic。受控測試必須可在該精確 interleaving 注入中斷，並以 pre-interrupt hashes 證明兩舊 outputs 都保留。
- Archify `dataflow` 的下一 stage 僅消費前一 stage 的 success value：Validator success 才進 Parser、Parser success 才進 Renderer、Renderer success 才進 Output。`invalid-input`、`parse-error`、`render-error` 與 `output-error` 各自終止於產生 stage 所映射的 Facade outcome，絕不可繪製為進入下游 stage。這是對已鎖定 stage-result contract 的圖表回修，不是新 contract。
- IM-08 僅可在 PR-08 approval 後進行；實體 browser、VoiceOver／screen-reader 與 Archify 英文 chrome 的實際可讀性仍保留 human check，靜態驗證不得取代。

## Validation

- 以依 module 分檔的 strict TypeScript type-level tests 驗證所有 literal unions、`DiffSnapshot` 的 required／readonly fields、未變更的 `DiffViewModel`、exact method signatures 與 public barrel export surface。
- 驗證每個 stage failure 只能使用對應 kind，`OutputResult` 只可使用 `output-error`，前後 stage input／output 僅在 success branch 相容，並驗證 UseCase／Facade dependency descriptor keys。
- 驗證 `DiffSnapshotAdapter.receiveSnapshot`、UseCase 與 Facade 都只接受 `DiffSnapshot`，且 barrel 公開 `DiffSnapshot`；Facade 只公開 `present` 與 `requestViewedStateChange`，後者回傳 `void`；核心 modules 不得 import Adapter、Swift、WebView 或 Presentation。
- 驗證 `ViewedStateChangeAdapter` 可指派為 `ViewedStateChangePort` 且不聲明 wrapper 或第二個 notification method；並驗證 `ViewedStateChange` 的 PR／snapshot identity 與 snapshot-local `fileId` contract，以及 UseCase 是 Output Port 唯一 caller、Facade 不依賴 Output Port。
- 驗證 `ViewedStateChangePort.notify` 與 `DiffFacade.requestViewedStateChange` 精確回傳 `void`，並以文件與圖證明此為僅限 viewed notification 的 best-effort exception；不得新增 notification outcome、bridge、transport 或可靠性主張。
- 驗證 architecture-canvas scene／generated index 只呈現 ownership／boundary、繁體中文作者內容與 `lang="zh-Hant"`，並交付 skill validate／build evidence；不發布 artifact.cafe。以 Archify `dataflow` specification／HTML 獨立驗證既定 runtime render flow，明確執行 `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json` 與交付至同一 filesystem temporary target 的 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json`，且不新增架構事實。Archify global viewer chrome 與 `lang="en"` 是本 PR 不修改 global template 的已知限制；其 visibility／readability 只能列 HC-07 human check，不得當作已完成繁中化。
- 對 PC-07 diagram-local single build entry 驗證：它依序完成 scene validate、canvas temp build、enhance、verify、Archify validate 與同 filesystem temporary deliver，且在兩個 temporary HTML 通過 hash／consistency check 後才 atomic rename 更新兩個 committed outputs；連續兩次成功輸出 byte-identical。任一注入失敗必須保留兩個原 outputs 且無 temporary residue。不得以手動改動生成圖取代此流程。
- 對 PC-07 canvas fallback 驗證：`zh-Hant`、繁中 artifact-local UI、`#stage` 的 tabindex／region／description、canvas `aria-hidden`、沒有 `role="application"` 或 window-global keydown、僅 stage-focused 的 viewport key handling、`[`／`]` traversal、live readout、由 `BOXES`／`EDGES` 動態產生的 fallback、原生可 Tab node controls 與中文 relationships。fallback controls 必須在正常文件流中可見，並具備 `:focus-visible` 與 container `:focus-within`；不得以 visually clipped 內容替代。
- 對 PC-08 fallback 驗證：展開 fallback 時，document／page 不得以 `overflow: hidden` 或等效樣式封鎖正常文件流內容的 keyboard／screen-reader 捲動；node controls 與 relationship list 必須仍可到達。每個由 `EDGES` 產生的 relationship 項目都必須含來源、`→`、目標與 label，而非僅含 label。
- 對 PC-08 build transaction 執行受控 `SIGINT` 與 `SIGTERM` 注入：在第一個 committed output atomic rename 後、第二個前中斷，驗證兩個 committed outputs 均還原為 pre-run hashes、temporary／backup／journal 無 residue、命令非零結束；成功路徑仍須兩次 byte-identical 並維持既有 hash／consistency check。
- 驗證 Archify `dataflow`：每個 stage 到下一 stage 的 edge 僅代表 success value；四類 failure edge／outcome 不得指向任何下游 stage，且只終止為對應 Facade outcome。
- type-level tests 必須驗證 opaque interfaces 的 brand identifier 不是 exported value、source 不含 runtime `Symbol`、ordinary structural object 不能指派為 opaque input，且既有 internal stage compatibility 仍成立。
- 執行既有 Bun typecheck、test 與 coverage gate；若現況尚無可執行 test，Tester 必須回報明確環境或設定 blocker，不以臆測替代。
