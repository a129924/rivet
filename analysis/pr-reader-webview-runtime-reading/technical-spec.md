# PR Reader WebView 可視化 Runtime 閱讀 — Technical Spec

## 已鎖定的設計

- 本 Mission 位於 Presentation integration；`RivetPRReader` Core 不引入 WebView 責任。資料由本地 `PRContentSnapshot` fixture 提供，Swift 記憶體 authority 擁有 Viewed，WebView 擁有當次 DOM。
- 保留 `DiffSnapshotWire`／`ViewedStateChangeWire` 與 TypeScript 既有 contract，包含 added、removed、modified、renamed、copied、typeChanged 六狀態；render 保留 `invalid-input`、`parse-error`、`render-error`、`output-error`。
- `BridgeSession` 原有 PR、snapshot、file 三重 identity 驗證維持唯一 authority 更新門檻；host 再以頁面世代拒絕重載前事件。Viewed 通知為 best-effort、`void`、無 acknowledgement／retry；WebView 不先改 snapshot。

## Runtime 資料流與完成語意

1. harness 建立 fixture、in-memory authority、`BridgeSession`、`WKWebView` 與打包的本地 HTML／CSS／JS。WebView 資源完成載入且 JavaScript 已註冊 ready 後，host 才呼叫 `publish`。
2. sink 將 Swift wire snapshot 編碼為 JSON，交付目前頁面世代的 JavaScript entry。同步 `receiveSnapshot` 返回只表示 host 接受交付，不表示 TypeScript pipeline 或 DOM 已完成；編碼或交付啟動失敗拋出，讓 bridge 回傳既有 `deliveryFailed`。
3. TypeScript runtime 用既有 callable `DiffSnapshotAdapter.receiveSnapshot` → Facade／UseCase → Validator／Parser／Renderer → 新 DOM Output。Output 以 render plan 來源順序更新 DOM，回報同一頁面世代與 snapshot 的完成或既有 render outcome；host 只接受目前交付的 completion。載入中及未完成前 Viewed 停用。
4. 使用者點選 Viewed 時，TS 透過既有 Facade／Viewed adapter 發出 `ViewedStateChange`；WebView message handler 解碼後先核對頁面世代，再交給 `BridgeSession.receiveViewedChange`。該方法回傳 `void`，不可由其返回值推定更新成功。host-owned in-memory `ViewedStateAuthority.setViewed` 在 bridge 完成 PR／snapshot／file identity 驗證後才被呼叫；它成功寫入記憶體後，以 host-local callback 通知 host。callback 僅排程下一個 main-actor turn 的 fixture `publish`，且再次核對頁面世代，避免在 bridge 呼叫堆疊內 reentrant publish。identity ignore 不會呼叫 `setViewed`／callback；寫入拋錯不呼叫 callback／重新 publish。新 snapshot 的 Viewed 值由 authority 讀取，WebView 不做 optimistic update。
5. WebView 重載時 host 使舊頁面世代失效、停用操作並重新等待 ready；逾時、資源、JavaScript／render 或 WebContent process 失敗進入明確錯誤畫面。完成／失敗只作用於當前頁面及 snapshot，舊 callback 不覆蓋新結果。

## DOM、安全與資源

- Output 使用 `readRenderPlan` 取得 internal entries，依序建立檔案區塊，呈現 filename、status、additions/deletions、Viewed 與 patch。`metadata-unavailable` 顯示明確提示，不能與空白或 delivery failure 混淆。
- 檔名與 metadata 以 `textContent` 放入 DOM；diff2html 的 HTML 在插入前清理，移除 executable markup、事件屬性與不受控 URL。WebView 僅讀取打包本地資源，限制 file read scope 與外部導覽。
- TypeScript bundle 寫入 SwiftPM resources，build script 可重建並比對 committed `reader.js`；執行時不需要 Bun、網路或 GitHub。若 bundle 缺失，build／啟動需顯示明確失敗。
- 失敗畫面不插入原始 patch、第三方 exception 或敏感資料；可辨識 phase 及穩定錯誤種類供診斷。

## 介面與相容性

- 不修改公開 Swift `DiffSnapshotSink`、`BridgeSession`、wire types 或公開 TS snapshot、Viewed、stage Ports。host-local delivery state、ready/completion/error 與頁面世代是 runtime 私有協定。
- `Package.swift` 增加 `RivetPRReaderHarnessRuntime` target、`RivetPRReaderHarness` executable、runtime tests 與 resources；TS package 增加 bundle script。bundle 路徑與 SwiftPM resources 對應，不新增 GitHub／Inbox dependency。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `packageDeclaresTheLockedTargetGraph` 是 exact product／target graph assertion。新增兩個 products（`RivetPRReaderHarnessRuntime` library、`RivetPRReaderHarness` executable）及三個 targets（上述兩者與 `RivetPRReaderHarnessRuntimeTests`）後，僅同步該 assertion 的預期集合；不改現有 GitHubIntegration／bridge path、dependency 或隔離斷言，也不重寫其他 tests。改動必須符合既有 Swift format／lint 限制。
- 舊 bridge 純契約測試、TS pipeline tests 必須持續通過。若發現現有 contract 無法支持非同步呈現，停下提出最小 contract 變更及 human decision，不偷偷重定義公開 sink 語意。

## Gate 與驗證

- `PR-01` 獨立審查明示 `needs-rework`，PC-02 後 `PR-02` 已獨立明示 `approved`。IM-01 開始後，完整 Swift suite 134 tests 中僅上述 graph test 的兩個 exact-set assertions 因新 targets/products 失敗，形成受限 file-scope gap。PC-03 僅授權上述 expected sets 修訂，須交新的獨立 `PR-03`；其明示 `approved` 前 IM-01 維持暫停，不能以 PR-02 追溯核准擴張。
- `IM-01` 的明確基線前提是 feature worktree HEAD 等於 `dev` 已合併基線 `9c61af8`：bridge PR #43 遠端 merge 時間 2026-09-29T03:34:35Z、merge SHA `9c61af8`；concrete-stages PR #13 於 2026-09-09 已 merge。不得將其未合併的 EOF correction 視為本 topic 已取得：原 ledger `RV-17` blocked、`RV-18`／`DL-10` pending，bridge `HC-01` 亦 pending。這些歷史狀態不被本 topic 回填。
- EOF correction 並非本 Mission 的硬依賴：本次可在已合併 pipeline 上驗收 fixture runtime，不要求修改該 correction 的 Parser／Renderer 行為。若 runtime tests 觸發受其影響的 EOF 缺陷，`IM-01` 停止並將問題交回原 concrete-stages topic，不能在本 topic 修改 ReadOnly stages 或宣稱 gate 通過。
- `PR-03 approved` 後，實作按 requirements 的 TC-01 至 TC-04 驗證，包含完整 Swift suite、graph exact-set preservation 與原隔離 assertions；Tester's independent evidence 後交 Reviewer。只有其明示通過與既有 commit 規範允許時，才進入 topic commit、push、Draft PR，最後停在人類 review。
