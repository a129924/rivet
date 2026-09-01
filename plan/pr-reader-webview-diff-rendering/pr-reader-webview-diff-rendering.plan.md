# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 將集中式 diff contract 替換為實體、分層的零依賴 declaration-only pipeline，並固定 `Adapter ↔ Port → UseCase → Facade` 與 `Validator → Parser → Renderer → Output` 的未來實作邊界。

## Non-Goal

不實作任何 parser、renderer、DOM、UI、collapse、syntax highlighting、Swift bridge、GitHub mapping 或 viewed-state 持久化；不新增 package 或修改 lockfile。僅回寫本 topic 已鎖定的 PR Reader WebView diff pipeline 長期責任與其 architecture-canvas 圖，不重開或變更 PR Reader BC 邊界。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、PR Reader BC 文件與既有 WebView toolchain 設定。
- 既有 TypeScript source、tests、package scripts 與 compiler 設定，以確認實際放置位置與 strict typecheck 命令。

## Written

- 同 topic 的四份 planning artifacts。
- `src/diff-rendering/` 下的 declaration-only modules 與依 module 分檔的 type-level tests，限於既有 PR Reader WebView surface。
- PR Reader BC 文件與 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 內經 `architecture-canvas` 驗證的 WebView diff pipeline 責任邊界圖。

## Modify

僅可修改本 topic 的四份 artifacts，以及 Implementer 為落實已鎖定 contract 所需的 TypeScript declarations、tests、PR Reader BC 文件與 architecture-canvas 圖。移除既有集中式 `src/diff-rendering.contract.ts` 與其 test，替換為已鎖定的 `src/diff-rendering/` tree。除上述 architecture writeback 外，其他現有 repository 檔案不修改。

## Deleted

僅刪除由 module tree 取代的集中式 diff contract source 與 test。

## Implementation Changes

1. 建立 technical spec 指定的 `contracts/`、`adapters/`、`ports/`、`usecases/`、`facades/` 與 `index.ts`；每個 module 只宣告其 layer 的 type／interface，不建立任何 concrete behavior。
2. 將 `DiffViewModel`、`DiffFileStatus`、帶 `pullRequestId`／`snapshotId`／snapshot-local `fileId` 的 `ViewedStateChange`、含 `output-error` 的 `DiffRenderOutcome`、opaque stage inputs 與 stage-specific results 放入對應 contracts modules；保留所有既定 model、viewed 與 outcome contract。
3. 定義 Adapter boundary interfaces、exact Port signatures、internal `DiffRenderUseCase.execute` 與 public `DiffFacade.present`／`requestViewedStateChange`；UseCase 是四個 pipeline Ports（含 Output）的唯一協調者與 Output caller，Facade 只依賴 UseCase 與 viewed-state Port。
4. 讓 `index.ts` 只匯出 `DiffFacade`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；所有 opaque types、Ports、Adapters、dependency descriptors 與 UseCase 均保持 internal。
5. 建立依 module 分檔的 type-level tests，驗證 contracts、相鄰 stage outputs、`output-error`、viewed notification identity、UseCase／Facade dependency ownership、barrel export surface 與禁止跨層依賴；不以 tests 引入 DOM 或第三方工具。
6. 回寫 PR Reader BC 文件，並以 `architecture-canvas` 在 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 建立 `scene.js` 與 `index.html`，完成 scene validation、artifact build 與視覺檢查；圖以繁體中文呈現，且不發布 artifact.cafe。

## Test Cases

- `DiffViewModel` 可表達 added、removed、modified、renamed、optional patch、rename 前路徑、非負增刪計數與 viewed 狀態。
- 四個 stage 只接受前一 stage success value，且只產生各自允許的 error kind；Output 失敗只使用 `output-error`；UseCase 與 Facade 的 dependency descriptors 只含既定 keys。
- UseCase 與 Facade 的方法參數、回傳型別與 readonly snapshot contract 完全相符；UseCase 是 Output Port 唯一 caller，Facade 不依賴 Output Port。
- viewed notification 以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 boolean 送出、回傳 `void`，不產生 acknowledgement 或 snapshot mutation API。
- barrel 僅公開 `DiffFacade`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；core 不得 import Adapter、Swift、WebView 或 Presentation。
- PR Reader BC 文件與 architecture-canvas 圖只陳述已鎖定 boundary，圖以繁體中文通過 skill 驗證且未發布。
- 既有 Bun typecheck、tests 與 coverage gate 通過；若命令或環境不存在，明確分類為 blocker。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立、移除或修改 TypeScript contract declarations、tests、PR Reader BC 文件或 architecture-canvas 圖。
- 若現有 surface 無法定位、strict TypeScript 設定不明，或 contract 與既有公開入口衝突，Implementer 停止並回報具體 blocker；不得自行改寫已鎖定 contract。
- Tester 或 Reviewer 發現 contract、scope 或 workflow drift 時，只由獨立 Implementer 進行最小相符修正並重新驗證。
- Reviewer 明示 `approved` 後，Code-Implementer 可依 human 已授權的本 topic Git 流程 commit、push 更新既有 PR #4，然後才可進入 GitHub handoff；GitHub handoff 完成後停止於 human review。
