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
export declare const validatedDiffInputBrand: unique symbol
export declare const parsedDiffInputBrand: unique symbol
export declare const renderPlanBrand: unique symbol

export interface ValidatedDiffInput {
  readonly [validatedDiffInputBrand]: true
}

export interface ParsedDiffInput {
  readonly [parsedDiffInputBrand]: true
}

export interface RenderPlan {
  readonly [renderPlanBrand]: true
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

- `ValidatedDiffInput`、`ParsedDiffInput` 與 `RenderPlan` 必須維持 opaque；其 schema 在各自後續實作 topic 才能定義。
- Validator、Parser、Renderer 與 Output 各自只回傳所屬 stage 的 success／failure union；相鄰 stage 只能消費前一 stage 的 success value。
- `DiffRenderUseCase.execute` 依序協調 Validator、Parser、Renderer 與 Output，並將各 stage failure 映射為對應 `DiffRenderOutcome` kind；UseCase 是 `DiffOutputPort` 的唯一 caller。UseCase、Validator 與 Facade 均以 `DiffSnapshot` 接收 render input。
- `ViewedStateChangeAdapter` 直接符合 `ViewedStateChangePort`；`DiffSnapshotAdapter` 只定義 Swift 的 inbound snapshot boundary。UseCase 只依賴四個 pipeline Ports，Facade 是 Presentation 的唯一 render 入口。Facade 僅宣告對 UseCase 與 Viewed-state Port 的 dependency descriptor；此處不定義 adapter、use case 或 facade 的建構／組裝方式。
- `requestViewedStateChange` 透過 `ViewedStateChangePort` 發送通知，回傳 best-effort `void`，不等待 Swift acknowledgement，且不做 optimistic snapshot 更新。`void` 不表示 delivery、enqueue 或 serialization 成功，也不建立 retry、failure mapping 或 transport guarantee；這些行為與任何 bridge contract 均留待獨立實作 topic。此例外不得用來削弱 `execute` 的四個 stage outcome mapping，或擴張為其他 layer／Port 的通用規則。

## Architecture Writeback

- IM-05 必須只將已確認的 `DiffSnapshot` input envelope、render 主路徑與 viewed notification 的狹義 `void` exception 回寫至 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md`；不得將 deferred concrete behavior 寫成長期事實。
- IM-05 必須更新 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/scene.js` 與其 generated `index.html`。scene 的 render 主路徑必須精確表達 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；Adapter 僅保留為 Swift／viewed 邊界宣告，不得插入或反向主 render flow。所有圖作者內容採繁體中文，generated index 的 `<html lang>` 必須是 `zh-Hant`。
- 依 `architecture-canvas` skill 對 scene 執行 validate，使用相同 scene build 產生 index，並保存 validate 與 build 的 command／receipt evidence；不得自行發布 artifact.cafe。

## PC-06 Documentation and Diagram-local Accessibility Revision

- 本輪只修正 `docs/architecture/README.md` wording 與既有 PR Reader WebView diff architecture-canvas artifact；不改 TypeScript pipeline、Swift bridge、套件、global `architecture-canvas` template 或其他圖。這是既有 topic 的可近用性與文件收斂，不重開 `DiffViewModel`、Swift snapshot authority、viewed best-effort `void`、零依賴或 declaration-only pipeline 決策。
- README 必須把 baseline 限定為「除已鎖定的 PR Reader WebView diff declaration-only modules 與該圖 artifact-local viewer accessibility 外」，仍不建立產品功能。它必須分開陳述：(1) core 的 compile-time dependency 為 `Presentation → Facade → UseCase → Port`；(2) Adapter 符合 Port 並隔離 Outside；(3) runtime render request 為 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`。三項皆不得改變既定 Output ownership 或 Adapter 非主路徑的決策。
- `scene.js` 的 `BOXES`／`EDGES` 是圖資料唯一真相。既有圖的 generated `index.html` 必須透過**該圖資料夾內**的 post-build enhancer／verifier 建立可近用性補強；重跑必須冪等。不得修改 skill 的 global template、將手抄的 node／edge 資料另存為第二份真相，或影響其他 diagrams。
- viewer UI、hint、toolbar 與 fallback 文字皆使用繁體中文；`<html lang="zh-Hant">`。`#stage` 必須是帶中文 label 的可聚焦 `role="region"`，以 `aria-describedby` 指向操作說明；canvas 必須 `aria-hidden="true"`。不得使用 `role="application"`。
- viewport keyboard keys 只可在 `#stage` 具有 focus 時處理，且不得註冊 window-global keydown listener。`[` 與 `]` 依 `BOXES` 順序巡覽；選取 node 必須更新既有 readout，且 readout 為 `aria-live` status。鍵盤巡覽、fallback focus 與 fallback click 必須呼叫同一個既有 node-selection 行為，不得導入第二套選取狀態。
- fallback 必須由 runtime `BOXES`／`EDGES` 動態產生：以語意 section／list 描述 pipeline，為每個 node 提供原生、可 Tab 到達的中文 `button`，並以關係清單呈現 edge。它的目的是讓 screen reader 與純鍵盤使用者取得與圖相等的 node／relationship 資訊，不宣稱 canvas 視覺本身可被讀取。
- IM-06 只可在 PR-06 approval 後進行；完成時同步 README wording 與這份圖。PR Reader BC 的 pipeline 長期事實沒有改變，故本輪不改寫 BC 文件。

## Validation

- 以依 module 分檔的 strict TypeScript type-level tests 驗證所有 literal unions、`DiffSnapshot` 的 required／readonly fields、未變更的 `DiffViewModel`、exact method signatures 與 public barrel export surface。
- 驗證每個 stage failure 只能使用對應 kind，`OutputResult` 只可使用 `output-error`，前後 stage input／output 僅在 success branch 相容，並驗證 UseCase／Facade dependency descriptor keys。
- 驗證 `DiffSnapshotAdapter.receiveSnapshot`、UseCase 與 Facade 都只接受 `DiffSnapshot`，且 barrel 公開 `DiffSnapshot`；Facade 只公開 `present` 與 `requestViewedStateChange`，後者回傳 `void`；核心 modules 不得 import Adapter、Swift、WebView 或 Presentation。
- 驗證 `ViewedStateChangeAdapter` 可指派為 `ViewedStateChangePort` 且不聲明 wrapper 或第二個 notification method；並驗證 `ViewedStateChange` 的 PR／snapshot identity 與 snapshot-local `fileId` contract，以及 UseCase 是 Output Port 唯一 caller、Facade 不依賴 Output Port。
- 驗證 `ViewedStateChangePort.notify` 與 `DiffFacade.requestViewedStateChange` 精確回傳 `void`，並以文件與圖證明此為僅限 viewed notification 的 best-effort exception；不得新增 notification outcome、bridge、transport 或可靠性主張。
- 驗證 architecture-canvas scene 與 generated index 的主路徑、繁體中文作者內容與 `lang="zh-Hant"`，並交付 skill validate／build evidence；不發布 artifact.cafe。
- 對 PC-06 diagram-local enhancer／verifier 驗證：`zh-Hant`、全繁中 UI、`#stage` 的 tabindex／region／description、canvas `aria-hidden`、沒有 `role="application"` 或 window-global keydown、僅 stage-focused 的 viewport key handling、`[`／`]` traversal、live readout、由 `BOXES`／`EDGES` 動態產生的 fallback、原生可 Tab node controls 與中文 relationships。先對 scene validate／temp build，再執行 enhancer／verifier；不得以手動改動生成圖取代該流程。
- 執行既有 Bun typecheck、test 與 coverage gate；若現況尚無可執行 test，Tester 必須回報明確環境或設定 blocker，不以臆測替代。
