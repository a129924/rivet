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
- 更新既有 architecture-canvas scene 與 generated index，使其只表達已鎖定的 ownership／boundary；以同 topic 的 Archify `dataflow` artifact／specification 表達既定 `DiffSnapshot` runtime render flow，並以 `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json` 驗證及寫入 same-filesystem temporary target 的 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json` 交付，保存兩個 skill 的 evidence。
- 修正文檔架構 README 對 baseline、compile-time dependency、Adapter 邊界與 render request runtime flow 的敘述；為同一份 PR Reader WebView diff canvas 加入僅限該 artifact、可見且可操作的 keyboard／screen-reader fallback，以及單一可重建 build entry。
- 將 opaque stage inputs 的 phantom brand 限為 module-private `declare const ...: unique symbol`，不匯出品牌 value、不建立 runtime `Symbol`，且維持 opaque types 不可由一般 consumer 建構。
- 修正同一 canvas fallback 展開後的文件可捲動性、由 `EDGES` 動態產生且含來源至目標方向與標籤的關係語意，以及 build entry 在 `SIGINT`／`SIGTERM` 介入兩個產物交付之間時的可驗證 rollback。
- 修正 Archify `dataflow`，使只有成功值可進入下一 stage；各 stage failure 必須終止於該 stage／Facade outcome，而非指向下游 stage。

## Out-Of-Scope

- 具體 Adapter、validator、parser、renderer、Output、RenderPlan schema、DOM、UI、collapse、syntax highlighting 或 raw diff 格式解析。
- Swift bridge、Swift target、GitHub REST／GraphQL mapping、viewed-state 持久化或 acknowledgement。
- viewed notification 的 reliable transport、enqueue／serialization failure outcome、acknowledgement、retry、delivery guarantee 或 bridge implementation。
- 新增套件、package manifest 或 lockfile 變更。
- 其他 Bounded Context、產品行為或未來 concrete implementation 的變更。
- TypeScript pipeline 以外的 concrete rendering、Swift bridge、global `architecture-canvas` template、其他 architecture-canvas 圖、其他 Archify 圖與任何套件變更。
- 改變既定 stage failure contract、`DiffRenderOutcome` kinds、Output ownership，或以 accessibility／build 修正為由重開既定決策的理由。

## Success Criteria

- Swift 可提供一個帶 `pullRequestId`、`snapshotId` 與完整有序 `readonly DiffViewModel[]` 的 `DiffSnapshot`；TS 以 module tree 呈現完整 pipeline，且公開入口與相鄰 stages 的型別相容性可由 typecheck 驗證。
- Snapshot 可表達檔案路徑、rename、變更類型、可選 patch、增刪計數與 viewed 狀態。
- `present` 僅回傳 success、validation、parse、render 或 output 的既定 outcome；`requestViewedStateChange`／`notify` 是狹義 best-effort `void` exception，不產生 outcome、acknowledgement、optimistic snapshot 更新或可靠傳輸承諾。
- `index.ts` 僅公開 Presentation 所需的 Facade 與 contracts（含 `DiffSnapshot`）；opaque stage types、Ports、Adapters、dependency descriptors 與 UseCase 均非 public surface。
- 介面保持零依賴，核心層不依賴 Swift、WebView 或 Adapter，且不偷渡任何具體 rendering 或 transport 決策。
- architecture README 明確區分 `Presentation → Facade → UseCase → Port` 的 core compile-time dependency、Adapter 對 Port 的符合與 Outside 隔離，以及 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` 的 runtime render request；不改變既定 ownership。
- architecture-canvas 只呈現 declaration-only pipeline 的 ownership／boundary，不以箭頭、標題或文字暗示 runtime render sequence；同一資料夾的 Archify `dataflow` artifact／specification 以既定 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output` 表達 runtime flow，且不新增架構事實；它必須以指定的 `validate dataflow` 與 `deliver dataflow` showcase JSON commands 驗證與交付。
- 所有 canvas 與 Archify specification 的作者內容皆為繁體中文；canvas generated `index.html` 維持 `lang="zh-Hant"`。Archify 的 global generated viewer chrome 與文件語言只支援英文／簡體中文，且本 PR 不修改 global template，因此其 generated HTML 保留英文 chrome 與 `lang="en"`；不得宣稱整個 viewer 已完成繁中化，實際可見性與可讀性留在 HC-07 人工確認。
- diagram-local 單一 build entry 必須將 canvas `index.html` 與 Archify `dataflow` HTML 視為同一交付組：先在各自 committed target 同一 filesystem 的 temporary target 完成 canvas validate／build／a11y enhancement／verification，以及 Archify validate／deliver；兩者皆成功後，對 temporary outputs 執行 hash／consistency check，才以 atomic rename 分別更新兩個 committed HTML。任一步失敗不得變更任一 committed output，且必須清除 temporary outputs；重跑成功輸出必須相同。
- 該 canvas 提供 diagram-local 可近用性 fallback：stage 可聚焦、僅在 stage 聚焦時處理 viewport keyboard keys、`[`／`]` 可巡覽 scene `BOXES`、選取狀態會以 live readout 宣告，並由 `BOXES`／`EDGES` 動態產生可 Tab 到達的語意節點與關係內容；fallback controls 在正常文件流中可見且有 focus-within／focus-visible 樣式，不使用 `role="application"` 或 window-global keyboard listener，且不另建 selection state。
- fallback 展開時，其內容仍可由鍵盤與 screen reader 捲動／閱讀；不得以 page `overflow: hidden` 或等效限制使正常文件流中的 controls／relationship content 不可到達。每一項動態關係須以 `來源 → 目標：標籤` 呈現，且三者皆衍生自 `EDGES`。
- single build entry 在成功時維持兩產物的一致交付，在 `SIGINT`／`SIGTERM` 於第一個 publish 後、第二個 publish 前介入時，必須以既有 backup／journal 恢復兩個 committed outputs；不得宣稱雙檔 atomic rename。受控中斷驗證必須證明舊兩檔 hash 均保留且無 temporary／backup residue。
- Archify `dataflow` 的 success edge 才可連至下一 stage；`invalid-input`、`parse-error`、`render-error` 與 `output-error` 必須止於產生它的 stage 所映射的 Facade outcome，不得繪製至下游 stage。
- opaque stage inputs 的 module-private phantom brands 不可由 barrel 或 module value surface 匯出，也不得產生 runtime `Symbol`；type-level tests 證明一般 consumer 不能以結構物件建構它們。

## Non-Goals

- 不以此 topic 定義 GitHub-like 視覺、紅綠行、檔案 header、錯誤畫面或任何瀏覽器副作用。
- 不將 `viewed` 的 WebView 本地 collapse 偏好當作 Swift snapshot 的一部分。
