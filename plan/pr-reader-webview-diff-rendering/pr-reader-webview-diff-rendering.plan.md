# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 將集中式 diff contract 替換為實體、分層的零依賴 declaration-only pipeline，並固定以 `DiffSnapshot` 為 input 的 `Adapter ↔ Port → UseCase → Facade` 與 `Validator → Parser → Renderer → Output` 未來實作邊界；本輪另收斂架構 README wording，並為同一份 diff architecture-canvas 圖加入 diagram-local keyboard／screen-reader fallback。

## Non-Goal

不實作任何 TypeScript parser、renderer、DOM、UI、collapse、syntax highlighting、Swift bridge、GitHub mapping 或 viewed-state 持久化；不新增 package 或修改 lockfile。`viewed` notification 不新增 outcome、reliable transport、acknowledgement、retry 或 bridge implementation。不修改 global `architecture-canvas` template、其他圖或 PR Reader BC 的既定 pipeline 事實。僅為既有 diff architecture-canvas artifact 實作資料導向的 viewer fallback，不重開或變更 PR Reader BC 邊界。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、PR Reader BC 文件、既有 architecture-canvas scene／index 與 WebView toolchain 設定。
- 既有 TypeScript source、tests、package scripts 與 compiler 設定，以確認實際放置位置與 strict typecheck 命令。

## Written

- 同 topic 的四份 planning artifacts。
- `src/diff-rendering/` 下的 declaration-only modules 與依 module 分檔的 type-level tests，限於既有 PR Reader WebView surface。
- `docs/architecture/README.md` 中 baseline 例外、compile-time dependency／Adapter boundary／runtime render request 的精確 wording；PR Reader BC 僅在長期事實實際改變時才更新。
- `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 下的 scene、generated index 與該資料夾限定的 post-build accessibility enhancer／verifier；包含 architecture-canvas validate／temp build 與 enhancer／verifier evidence。

## Modify

僅可修改本 topic 的四份 artifacts，以及 Implementer 為落實已鎖定 contract 所需的 TypeScript declarations、tests、`docs/architecture/README.md`、PR Reader BC 文件與既有 PR Reader WebView diff architecture-canvas scene／generated index。本輪只允許在該 diagram 資料夾新增冪等 post-build accessibility enhancer／verifier；不得修改 global template 或其他圖。移除既有集中式 `src/diff-rendering.contract.ts` 與其 test，替換為已鎖定的 `src/diff-rendering/` tree。除已確認的架構 writeback、canvas alignment 與 diagram-local accessibility 外，其他現有 repository 檔案不修改。

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
8. 以 `architecture-canvas` 更新 scene 與 generated index：主 render flow 固定為 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`，Adapter 不得位於該主路徑；作者內容使用繁體中文，`index.html` 使用 `lang="zh-Hant"`。完成 skill validate、從 scene build index，並保存 command／receipt evidence；不得發布 artifact.cafe。
9. 修正 `docs/architecture/README.md`：baseline 的「不建立程式碼、抽象層或產品功能」只排除已鎖定的 declaration-only modules 與這份圖 artifact-local accessibility；分別呈現 core compile-time dependency `Presentation → Facade → UseCase → Port`、Adapter 符合 Port 並隔離 Outside，及既定 runtime render request。不得將 Adapter 放回主 render path 或變更 Output ownership。
10. 為 `docs/architecture/diagrams/pr-reader-webview-diff-rendering/` 建立 diagram-local、冪等的 post-build accessibility enhancer／verifier。scene 的 `BOXES`／`EDGES` 是唯一資料真相；enhancer 只在生成 index 補上全繁中 viewer UI、focusable `#stage` region／description、`aria-hidden` canvas、stage-scoped viewport keys、`[`／`]` box traversal、live readout 與由 `BOXES`／`EDGES` 動態產生的 native semantic fallback controls／relationships。不得用 `role="application"`、window-global listener、手抄資料或第二套選取狀態。

## Test Cases

- `DiffSnapshot` 以 readonly PR identity、snapshot identity 與完整有序 `readonly DiffViewModel[]` 表達 render input；`DiffViewModel` 繼續表達 added、removed、modified、renamed、optional patch、rename 前路徑、非負增刪計數與 viewed 狀態。
- 四個 stage 只接受前一 stage success value，且只產生各自允許的 error kind；Output 失敗只使用 `output-error`；UseCase 與 Facade 的 dependency descriptors 只含既定 keys。
- `DiffSnapshotAdapter.receiveSnapshot`、Validator、UseCase 與 Facade 的方法參數、回傳型別與 readonly snapshot envelope contract 完全相符；UseCase 是 Output Port 唯一 caller，Facade 不依賴 Output Port。
- viewed notification 以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 boolean 送出；`notify` 與 `requestViewedStateChange` 是唯一的 best-effort `void` exception，不產生 outcome、acknowledgement、delivery guarantee、retry 或 snapshot mutation API。
- `ViewedStateChangeAdapter` 可結構性指派為 `ViewedStateChangePort`，且不包含 wrapper 或第二個 notification method。
- barrel 僅公開 `DiffFacade`、`DiffSnapshot`、`DiffViewModel`、`DiffFileStatus`、`ViewedStateChange`、`DiffRenderOutcome`；core 不得 import Adapter、Swift、WebView 或 Presentation。
- 架構 README 與 PR Reader BC 文件只陳述已確認的 snapshot、主 render flow 與 viewed notification exception；不將 deferred bridge／transport behavior 寫成既定架構。
- architecture-canvas scene／generated index 的主 render flow 精確為 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；作者內容為繁體中文、`index.html` 為 `lang="zh-Hant"`，且附帶 skill validate／build evidence。
- README baseline、compile-time dependency、Adapter boundary 與 runtime render request 各自精確，且沒有把已鎖定 declaration-only pipeline 或 Output ownership 說成產品實作。
- canvas temp build 後的 diagram-local enhancer／verifier 可重跑且通過：stage 是中文命名的 focusable region 並描述操作、canvas `aria-hidden`、無 `role="application"`／window-global keydown、viewport keys 僅在 stage focus、`[`／`]` 依 `BOXES` 巡覽並更新 aria-live readout，且 fallback 從 `BOXES`／`EDGES` 產生原生可 Tab node controls 與中文 relationship list。
- 既有 Bun typecheck、tests 與 coverage gate 通過；若命令或環境不存在，明確分類為 blocker。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立、移除或修改 TypeScript contract declarations、tests、架構 README、PR Reader BC 文件或 architecture-canvas 圖。
- 若現有 surface 無法定位、strict TypeScript 設定不明，或 contract 與既有公開入口衝突，Implementer 停止並回報具體 blocker；不得自行改寫已鎖定 contract。
- Tester 或 Reviewer 發現 contract、scope 或 workflow drift 時，只由獨立 Implementer 進行最小相符修正並重新驗證。
- Reviewer 明示 `approved` 後，Code-Implementer 才可依 human 已授權的本 topic Git 流程 commit、push 更新既有 PR #4，回覆並 resolve 本輪已修正 threads；GitHub handoff 完成後停止於 human review。
- PC-06、PR-06、IM-06、TE-06、RV-06 與 GH-06 必須依序完成；若 scene runtime 無法在不改 global template／其他圖的前提下衍生語意 fallback，或 enhancement 需手抄／複製圖資料、改變既定 pipeline、引入 window-global key handling，即停止並回報 blocker。GH-06 完成後停止於 HC-05 human review。
