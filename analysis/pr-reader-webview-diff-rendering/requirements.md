# PR Reader WebView Diff Rendering — Requirements

## Goal

定義 Swift 向 PR Reader WebView 提供的 diff snapshot envelope，以及 TypeScript 對其進行後續處理所需的穩定介面契約。此 topic 以實體、分層的 TypeScript module tree 建立 declaration-only pipeline，為零依賴的後續實作切片提供邊界。

## In-Scope

- 定義 `DiffSnapshot` envelope、`DiffViewModel`、檔案狀態、帶 PR／snapshot identity 的 viewed-state 變更與公開結果型別。
- 定義 `Validator → Parser → Renderer → Output` 的 stage-specific result unions 與 opaque 中間資料。
- 建立 contracts、adapters、ports、usecases、facades 與 presentation barrel 的分層 module 結構；每個 module 只宣告自己 layer 的 type／interface。
- 定義 `Adapter ↔ Port → UseCase → Facade` 的 Port、UseCase、Facade 與 dependency descriptor 方法簽名。
- 定義 `viewed` 的 ownership、通知時機與 WebView 本地暫態狀態邊界，並將其 best-effort `void` notification 明定為對一般 `Outcome` 規則的狹義架構例外。
- 對各 module 的 import surface、相鄰 stage output、snapshot input、Facade API、Adapter／Port assignability 與 layer dependency 進行 strict TypeScript type-level tests 與既有檢查。
- 將已確認的 snapshot、render flow 與 viewed notification exception 事實回寫至架構 README 與 PR Reader BC 文件。
- 更新既有 architecture-canvas scene 與 generated index，使其主路徑反映已鎖定的 `DiffSnapshot` flow，並完成 skill 要求的 validate、build 與 evidence capture。
- 修正文檔架構 README 對 baseline、compile-time dependency、Adapter 邊界與 render request runtime flow 的敘述；並為同一份 PR Reader WebView diff 圖加入僅限該 artifact 的 keyboard／screen-reader fallback。

## Out-Of-Scope

- 具體 Adapter、validator、parser、renderer、Output、RenderPlan schema、DOM、UI、collapse、syntax highlighting 或 raw diff 格式解析。
- Swift bridge、Swift target、GitHub REST／GraphQL mapping、viewed-state 持久化或 acknowledgement。
- viewed notification 的 reliable transport、enqueue／serialization failure outcome、acknowledgement、retry、delivery guarantee 或 bridge implementation。
- 新增套件、package manifest 或 lockfile 變更。
- 其他 Bounded Context、產品行為或未來 concrete implementation 的變更。
- TypeScript pipeline、Swift bridge、global `architecture-canvas` template、其他 architecture-canvas 圖與任何套件變更。

## Success Criteria

- Swift 可提供一個帶 `pullRequestId`、`snapshotId` 與完整有序 `readonly DiffViewModel[]` 的 `DiffSnapshot`；TS 以 module tree 呈現完整 pipeline，且公開入口與相鄰 stages 的型別相容性可由 typecheck 驗證。
- Snapshot 可表達檔案路徑、rename、變更類型、可選 patch、增刪計數與 viewed 狀態。
- `present` 僅回傳 success、validation、parse、render 或 output 的既定 outcome；`requestViewedStateChange`／`notify` 是狹義 best-effort `void` exception，不產生 outcome、acknowledgement、optimistic snapshot 更新或可靠傳輸承諾。
- `index.ts` 僅公開 Presentation 所需的 Facade 與 contracts（含 `DiffSnapshot`）；opaque stage types、Ports、Adapters、dependency descriptors 與 UseCase 均非 public surface。
- 介面保持零依賴，核心層不依賴 Swift、WebView 或 Adapter，且不偷渡任何具體 rendering 或 transport 決策。
- architecture README 明確區分 `Presentation → Facade → UseCase → Port` 的 core compile-time dependency、Adapter 對 Port 的符合與 Outside 隔離，以及 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` 的 runtime render request；不改變既定 ownership。
- architecture-canvas 以 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` 呈現 render 主路徑；generated `index.html` 的文件語言與 viewer UI 皆為繁體中文，且有可追溯的 validate／build evidence。
- 該圖提供 diagram-local 可近用性 fallback：stage 可聚焦、僅在 stage 聚焦時處理 viewport keyboard keys、`[`／`]` 可巡覽 scene `BOXES`、選取狀態會以 live readout 宣告，並由 `BOXES`／`EDGES` 動態產生可 Tab 到達的語意節點與關係內容；不使用 `role="application"` 或 window-global keyboard listener。

## Non-Goals

- 不以此 topic 定義 GitHub-like 視覺、紅綠行、檔案 header、錯誤畫面或任何瀏覽器副作用。
- 不將 `viewed` 的 WebView 本地 collapse 偏好當作 Swift snapshot 的一部分。
