# PR Reader WebView Diff Rendering — Technical Spec

## Locked Decisions

- 實作只新增 TypeScript type／interface declarations 與 type-level tests，並維持零新增依賴；不得修改 package manifest 或 lockfile。
- 本 topic 不實作 validator、parser、renderer、Output、DOM、UI、collapse、syntax highlighting、Swift bridge 或具體 raw diff／RenderPlan schema。
- `DiffViewModel` 是 Swift 每次提供的完整、有序 snapshot；Swift 是 `viewed` 的唯一持久化權威。
- WebView 的 collapse 僅可在未來作為本地暫態狀態，不能寫入或改變 snapshot contract。

## Module Structure

移除集中式 `src/diff-rendering.contract.ts`，改以以下 production module tree 表達 pipeline：

```text
src/diff-rendering/
  contracts/
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
- Adapter modules 只定義 Swift snapshot input 與 viewed notification 的邊界介面；核心 contracts、Ports、UseCase 與 Facade 不得依賴 Adapter、Swift 或 WebView。
- `DiffRenderUseCase` 的 dependency descriptor 只含 Validator、Parser、Renderer、Output 四個 pipeline Ports。
- `DiffFacade` 的 dependency descriptor 只含 UseCase、Output Port、Viewed-state Port。Output 的 caller 與時機維持 deferred，不得由 declaration-only contract 推導 runtime responsibility。

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

export interface ViewedStateChange {
  readonly fileId: string
  readonly viewed: boolean
}

export type DiffRenderOutcome =
  | { readonly type: "success" }
  | {
      readonly type: "error"
      readonly kind: "invalid-input" | "parse-error" | "render-error"
      readonly message: string
    }
```

- `fileId` 在同一份 snapshot 中唯一，並是 viewed-state notification 的唯一識別子。
- `filename` 是目前檔案路徑；`previousFilename` 僅於 `status: "renamed"` 時可提供，並表示先前路徑。
- `status` 是檔案層級的 added、removed、modified 或 renamed 語意；它不決定 diff 行的新增、刪除或 context。
- `patch` 可對任何 `status` 缺席，表示內容不可取得；其格式與任何 fallback 不在本 topic 定義。
- `additions` 與 `deletions` 是非負整數，`0` 合法，且值由 Swift 提供。

`src/diff-rendering/index.ts` 是唯一 public barrel，且只匯出：

```ts
export type {
  DiffFileStatus,
  DiffRenderOutcome,
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
  | { readonly type: "error"; readonly kind: "render-error"; readonly message: string }

export interface DiffViewModelValidatorPort {
  validate(files: readonly DiffViewModel[]): ValidationResult
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
  execute(files: readonly DiffViewModel[]): DiffRenderOutcome
}

export interface DiffFacade {
  present(files: readonly DiffViewModel[]): DiffRenderOutcome
  requestViewedStateChange(change: ViewedStateChange): void
}
```

- `ValidatedDiffInput`、`ParsedDiffInput` 與 `RenderPlan` 必須維持 opaque；其 schema 在各自後續實作 topic 才能定義。
- Validator、Parser、Renderer 與 Output 各自只回傳所屬 stage 的 success／failure union；相鄰 stage 只能消費前一 stage 的 success value。
- `DiffRenderUseCase.execute` 的 contract 保留四個 pipeline Ports 的依賴關係與 `DiffRenderOutcome`；pipeline 的具體協調與 Output caller／時機均 deferred。Facade 的 `present` 不定義 runtime delegation 或 output responsibility。
- Adapter 實作 Port，UseCase 只依賴四個 pipeline Ports，Facade 是 Presentation 的唯一 render 入口。Facade 僅宣告對 UseCase、Output Port 與 Viewed-state Port 的 dependency descriptor；此處不定義 adapter、use case 或 facade 的建構／組裝方式。
- `requestViewedStateChange` 透過 `ViewedStateChangePort` 發送通知，回傳 `void`，不等待 Swift acknowledgement，且不做 optimistic snapshot 更新。

## Validation

- 以依 module 分檔的 strict TypeScript type-level tests 驗證所有 literal unions、required／optional／readonly 欄位、exact method signatures 與 public barrel export surface。
- 驗證每個 stage failure 只能使用對應 kind，前後 stage input／output 僅在 success branch 相容，並驗證 UseCase／Facade dependency descriptor keys。
- 驗證 Facade 只公開 `present` 與 `requestViewedStateChange`，後者回傳 `void`；核心 modules 不得 import Adapter、Swift、WebView 或 Presentation。
- 執行既有 Bun typecheck、test 與 coverage gate；若現況尚無可執行 test，Tester 必須回報明確環境或設定 blocker，不以臆測替代。
