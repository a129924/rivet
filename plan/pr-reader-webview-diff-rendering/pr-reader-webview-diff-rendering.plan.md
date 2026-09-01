# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 建立 Swift-to-TypeScript diff snapshot 的零依賴介面層，並固定 `Adapter ↔ Port → UseCase → Facade` 與 `Validator → Parser → Renderer → Output` 的未來實作邊界。

## Non-Goal

不實作任何 parser、renderer、DOM、UI、collapse、syntax highlighting、Swift bridge、GitHub mapping 或 viewed-state 持久化；不新增 package、修改 lockfile，或變更 PR Reader Bounded Context 與架構文件。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、PR Reader BC 文件與既有 WebView toolchain 設定。
- 既有 TypeScript source、tests、package scripts 與 compiler 設定，以確認實際放置位置與 strict typecheck 命令。

## Written

- `analysis/pr-reader-webview-diff-rendering/requirements.md`
- `analysis/pr-reader-webview-diff-rendering/technical-spec.md`
- `plan/pr-reader-webview-diff-rendering/pr-reader-webview-diff-rendering.plan.md`
- `plan/pr-reader-webview-diff-rendering/pr-reader-webview-diff-rendering.step.md`
- 實作階段所需的 TypeScript contract declarations 與 type-level tests，限於既有 PR Reader WebView surface。

## Modify

僅可修改本 topic 的四份 artifacts，以及 Implementer 為落實已鎖定 contract 所需的 TypeScript declarations 和 tests。其他現有 repository 檔案不修改。

## Deleted

無。

## Implementation Changes

1. Implementer 依 technical spec 定義 `DiffViewModel`、`DiffFileStatus`、`ViewedStateChange` 與 `DiffRenderOutcome`，不建立任何 bridge 或 rendering 實作。
2. 定義 opaque `ValidatedDiffInput`、`ParsedDiffInput`、`RenderPlan`，以及 Validator、Parser、Renderer、Output 的 stage-specific unions 和 exact Port signatures。
3. 定義 internal `DiffRenderUseCase.execute` 與 public `DiffFacade.present`／`requestViewedStateChange`；Facade 不公開其他操作，viewed notification 不等待 acknowledgement。
4. 建立 type-level tests，僅驗證已鎖定 contract；不以 tests 引入 DOM 或第三方工具。

## Test Cases

- `DiffViewModel` 可表達 added、removed、modified、renamed、optional patch、rename 前路徑、非負增刪計數與 viewed 狀態。
- 四個 stage 只接受前一 stage success value，且只產生各自允許的 error kind。
- UseCase 與 Facade 的方法參數、回傳型別與 readonly snapshot contract 完全相符。
- viewed notification 以 `fileId` 與 boolean 送出、回傳 `void`，不產生 acknowledgement 或 snapshot mutation API。
- 既有 Bun typecheck、tests 與 coverage gate 通過；若命令或環境不存在，明確分類為 blocker。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立或修改 TypeScript contract declarations 或 tests。
- 若現有 surface 無法定位、strict TypeScript 設定不明，或 contract 與既有公開入口衝突，Implementer 停止並回報具體 blocker；不得自行改寫已鎖定 contract。
- Tester 或 Reviewer 發現 contract、scope 或 workflow drift 時，只由獨立 Implementer 進行最小相符修正並重新驗證。
- Reviewer 明示 `approved` 後，交由 human review；human 未明示確認前不得 commit、push 或開 PR。
