# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 將集中式 diff contract 替換為實體、分層的零依賴 declaration-only pipeline，並固定 `Adapter ↔ Port → UseCase → Facade` 與 `Validator → Parser → Renderer → Output` 的未來實作邊界。

## Non-Goal

不實作任何 parser、renderer、DOM、UI、collapse、syntax highlighting、Swift bridge、GitHub mapping 或 viewed-state 持久化；不新增 package、修改 lockfile，或變更 PR Reader Bounded Context 與架構文件。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、PR Reader BC 文件與既有 WebView toolchain 設定。
- 既有 TypeScript source、tests、package scripts 與 compiler 設定，以確認實際放置位置與 strict typecheck 命令。

## Written

- 同 topic 的四份 planning artifacts。
- `src/diff-rendering/` 下的 declaration-only modules 與依 module 分檔的 type-level tests，限於既有 PR Reader WebView surface。

## Modify

僅可修改本 topic 的四份 artifacts，以及 Implementer 為落實已鎖定 contract 所需的 TypeScript declarations 和 tests。移除既有集中式 `src/diff-rendering.contract.ts` 與其 test，替換為已鎖定的 `src/diff-rendering/` tree。其他現有 repository 檔案不修改。

## Deleted

僅刪除由 module tree 取代的集中式 diff contract source 與 test。

## Implementation Changes

1. 建立 technical spec 指定的 `contracts/`、`adapters/`、`ports/`、`usecases/`、`facades/` 與 `index.ts`；每個 module 只宣告其 layer 的 type／interface，不建立任何 concrete behavior。
2. 將 `DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`、opaque stage inputs 與 stage-specific results 放入對應 contracts modules；保留所有既定 model、viewed 與 outcome contract。
3. 定義 Adapter boundary interfaces、exact Port signatures、internal `DiffRenderUseCase.execute` 與 public `DiffFacade.present`／`requestViewedStateChange`；UseCase 只依賴四個 pipeline Ports，Facade 只依賴 UseCase、Output Port 與 viewed-state Port。Output caller／時機 deferred。
4. 讓 `index.ts` 只匯出 `DiffFacade`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；所有 opaque types、Ports、Adapters、dependency descriptors 與 UseCase 均保持 internal。
5. 建立依 module 分檔的 type-level tests，驗證 contracts、相鄰 stage outputs、Facade API、barrel export surface 與禁止跨層依賴；不以 tests 引入 DOM 或第三方工具。

## Test Cases

- `DiffViewModel` 可表達 added、removed、modified、renamed、optional patch、rename 前路徑、非負增刪計數與 viewed 狀態。
- 四個 stage 只接受前一 stage success value，且只產生各自允許的 error kind；UseCase 與 Facade 的 dependency descriptors 只含既定 keys。
- UseCase 與 Facade 的方法參數、回傳型別與 readonly snapshot contract 完全相符；Facade 的 Output caller／時機未被 declaration-only interface 決定。
- viewed notification 以 `fileId` 與 boolean 送出、回傳 `void`，不產生 acknowledgement 或 snapshot mutation API。
- barrel 僅公開 `DiffFacade`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；core 不得 import Adapter、Swift、WebView 或 Presentation。
- 既有 Bun typecheck、tests 與 coverage gate 通過；若命令或環境不存在，明確分類為 blocker。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立、移除或修改 TypeScript contract declarations 或 tests。
- 若現有 surface 無法定位、strict TypeScript 設定不明，或 contract 與既有公開入口衝突，Implementer 停止並回報具體 blocker；不得自行改寫已鎖定 contract。
- Tester 或 Reviewer 發現 contract、scope 或 workflow drift 時，只由獨立 Implementer 進行最小相符修正並重新驗證。
- Reviewer 明示 `approved` 後，Code-Implementer 可依 human 已授權的本 topic Git 流程 commit、push 更新既有 draft PR #4，然後停止於 human review。
