# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 將集中式 diff contract 替換為實體、分層的零依賴 declaration-only pipeline，並固定以 `DiffSnapshot` 為 input 的 `Adapter ↔ Port → UseCase → Facade` 與 `Validator → Parser → Renderer → Output` 未來實作邊界。

## Non-Goal

不實作任何 parser、renderer、DOM、UI、collapse、syntax highlighting、Swift bridge、GitHub mapping 或 viewed-state 持久化；不新增 package 或修改 lockfile。僅回寫本 topic 已鎖定的 PR Reader WebView diff pipeline 長期責任，不重開或變更 PR Reader BC 邊界；本次 revision 不修改既有 architecture-canvas 圖。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、PR Reader BC 文件與既有 WebView toolchain 設定。
- 既有 TypeScript source、tests、package scripts 與 compiler 設定，以確認實際放置位置與 strict typecheck 命令。

## Written

- 同 topic 的四份 planning artifacts。
- `src/diff-rendering/` 下的 declaration-only modules 與依 module 分檔的 type-level tests，限於既有 PR Reader WebView surface。
- PR Reader BC 文件中已確認的 `DiffSnapshot` input envelope 事實；既有 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 圖僅供 read-only 查證，本次 revision 不修改它。

## Modify

僅可修改本 topic 的四份 artifacts，以及 Implementer 為落實已鎖定 contract 所需的 TypeScript declarations、tests 與 PR Reader BC 文件。移除既有集中式 `src/diff-rendering.contract.ts` 與其 test，替換為已鎖定的 `src/diff-rendering/` tree。除已確認的 PR Reader BC input envelope writeback 外，其他現有 repository 檔案不修改；本次 revision 不修改 architecture-canvas 圖。

## Deleted

僅刪除由 module tree 取代的集中式 diff contract source 與 test。

## Implementation Changes

1. 建立 technical spec 指定的 `contracts/`、`adapters/`、`ports/`、`usecases/`、`facades/` 與 `index.ts`；每個 module 只宣告其 layer 的 type／interface，不建立任何 concrete behavior。
2. 新增 public `DiffSnapshot` contract，固定 `readonly pullRequestId`、`snapshotId` 與 `files: readonly DiffViewModel[]`；既有 `DiffViewModel` 不變。將它與 `DiffFileStatus`、帶 PR／snapshot identity 的 `ViewedStateChange`、含 `output-error` 的 `DiffRenderOutcome`、opaque stage inputs 與 stage-specific results 放入對應 contracts modules。
3. 定義 `DiffSnapshotAdapter.receiveSnapshot(snapshot): void`、exact Port signatures、internal `DiffRenderUseCase.execute(snapshot)` 與 public `DiffFacade.present(snapshot)`／`requestViewedStateChange`；Validator、UseCase 與 Facade 都只接受 `DiffSnapshot`。UseCase 是四個 pipeline Ports（含 Output）的唯一協調者與 Output caller，Facade 只依賴 UseCase 與 viewed-state Port。
4. 定義 `ViewedStateChangeAdapter` 直接 extends `ViewedStateChangePort`，不得新增 wrapper 或第二個 notification method。`index.ts` 只匯出 `DiffFacade`、`DiffSnapshot`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；所有 opaque types、Ports、Adapters、dependency descriptors 與 UseCase 均保持 internal。
5. 建立依 module 分檔的 type-level tests，驗證 snapshot contract、未變更的 file model、相鄰 stage outputs、`output-error`、viewed notification identity、Adapter-to-Port assignability、UseCase／Facade dependency ownership、barrel export surface 與禁止跨層依賴；不以 tests 引入 DOM 或第三方工具。
6. 僅將已確認的 `DiffSnapshot` input envelope 事實回寫 PR Reader BC 文件；既有 architecture-canvas 圖不修改、不重建或發布。

## Test Cases

- `DiffSnapshot` 以 readonly PR identity、snapshot identity 與完整有序 `readonly DiffViewModel[]` 表達 render input；`DiffViewModel` 繼續表達 added、removed、modified、renamed、optional patch、rename 前路徑、非負增刪計數與 viewed 狀態。
- 四個 stage 只接受前一 stage success value，且只產生各自允許的 error kind；Output 失敗只使用 `output-error`；UseCase 與 Facade 的 dependency descriptors 只含既定 keys。
- `DiffSnapshotAdapter.receiveSnapshot`、Validator、UseCase 與 Facade 的方法參數、回傳型別與 readonly snapshot envelope contract 完全相符；UseCase 是 Output Port 唯一 caller，Facade 不依賴 Output Port。
- viewed notification 以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 boolean 送出、回傳 `void`，不產生 acknowledgement 或 snapshot mutation API。
- `ViewedStateChangeAdapter` 可結構性指派為 `ViewedStateChangePort`，且不包含 wrapper 或第二個 notification method。
- barrel 僅公開 `DiffFacade`、`DiffSnapshot`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；core 不得 import Adapter、Swift、WebView 或 Presentation。
- PR Reader BC 文件只陳述已確認的 snapshot envelope input boundary；本次 revision 不修改既有 architecture-canvas 圖。
- 既有 Bun typecheck、tests 與 coverage gate 通過；若命令或環境不存在，明確分類為 blocker。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立、移除或修改 TypeScript contract declarations、tests、PR Reader BC 文件或 architecture-canvas 圖。
- 若現有 surface 無法定位、strict TypeScript 設定不明，或 contract 與既有公開入口衝突，Implementer 停止並回報具體 blocker；不得自行改寫已鎖定 contract。
- Tester 或 Reviewer 發現 contract、scope 或 workflow drift 時，只由獨立 Implementer 進行最小相符修正並重新驗證。
- Reviewer 明示 `approved` 後，Code-Implementer 可依 human 已授權的本 topic Git 流程 commit、push 更新既有 PR #4，然後才可進入 GitHub handoff；GitHub handoff 完成後停止於 human review。
