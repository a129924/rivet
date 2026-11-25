# PR Reader 背景工作階段技術規格

本規格採 Swift 6 與現有 macOS 15 package 基線。Topic 為 `pr-reader-background-session-production-adoption`。

## 正式依賴

- `RivetPRReader` Core 新增 `package protocol PRBackgroundSource: Sendable`，以 `fetchBackground(for: ReaderPullRequestID) async -> Outcome<ReaderBackground, PRReaderFailure>` 讀取背景。沿用現有 Reader 型別、Outcome 與完整 `PRContentSource`。現有 `GitHubPullRequestBackgroundSource` 只新增 conformance。
- `package struct PRReaderBackgroundFacade: Sendable` 持有私有 `Sendable` 單次讀取 UseCase。兩者直接 await 同一 Port 呼叫，不建立額外 Task。沿用 `Presentation → Facade → UseCase → Port`。
- 新增 `RivetPRReaderPresentation` target，直接依賴僅為 `RivetPRReader`。提供 `package` 的 `@MainActor @Observable` `PRReaderBackgroundSession`，以 Facade 初始化，提供 `select(_:)`、`refresh()`、`cancelLoading()`、`invalidate()` 與唯讀觀察 `state`。Task、token、當前 slot 與失效旗標維持 private。
- 新增 `RivetPRReaderComposition` target，直接依賴 `RivetPRReaderPresentation`、`RivetPRReader`、`RivetPRReaderGitHub` 和 `GitHubIntegration`。唯一組裝入口 `@MainActor package func makePRReaderBackgroundSession(rest: any GitHubRestClient) -> PRReaderBackgroundSession` 建立正式 adapter、Facade 及新 Session。正式 caller 可傳 `scope.rest`。兩個 target 供套件內使用。維持既有 library products 與通用 `RivetPresentation` 的零 BC 依賴，HTTP fixture 僅在組裝測試 target 直接宣告。

## 狀態轉移

`ReaderBackgroundState` 採 `.idle`、`.selected(id)`、`.loading(id)`、`.loaded(id, background)`、`.refreshing(id, previous:)`、`.refreshFailed(id, previous:, failure:)`、`.failed(id, failure)`。

| 事件 | 顯示與執行效果 |
| --- | --- |
| 首次選取或切換 PR | 依既有 Reader ID 相等性判斷。切換為新 PR 的 loading，舊資料立即離開顯示狀態。撤銷舊資格並取消舊 Task。 |
| 選取同一 PR | 狀態與請求都維持原樣。 |
| 刷新 | 無選取時無動作。每次有效刷新建立唯一 token，最近一次成功資料成為 previous 進 refreshing。尚無成功資料時進 loading。從 refreshFailed 重試會清除舊錯誤顯示。 |
| 有效結果 | 成功進 loaded。如果失敗，有 previous 時進 refreshFailed 並保留資料，否則進 failed。有效且未取消的 unavailable 按一般失敗處理。 |
| 取消 | 先撤銷並清除當前 slot，再發出取消。首次載入回 selected，刷新回 loaded 並保留 previous。無當前請求時無動作。 |
| 失效 | 清除選取與背景資料並顯示 idle，撤銷當前資格並取消 Task，私有旗標永久禁止後續操作。重複失效無副作用。重開建立新實例。 |

## 請求 ownership

每次開始建立 private 物件 identity token，當前 slot 持有 token、PR ID 及 Task。替換先讓舊 token 失去資格，再發出取消。等待 Facade 時 Task 弱持有 Session。原 Task 返回後執行同步 MainActor finish。在同一隔離區段檢查 Session 尚未失效、token 為當前、PR ID 與選取相同及原 Task 的取消旗標，再提交有效結果與清理 slot。過期或失效的完成沒有副作用。若原 Task 已取消但仍具當前 token，只清自身 slot 並依載入型態回 selected 或 loaded(previous)。

驗收用唯讀 `internal` 完成等待 closure 僅捕獲該次 Task 以等待 `.value`，供測試在舊工作實際結束後檢查狀態與 handle。正式入口不公開執行狀態。P10 在 Source 屏障仍關閉時驗證釋放 Session，P12 在舊 Task 完成後以正式取消入口驗證新 Task handle 並另有成功對照。具體證據契約見相同 topic 的 plan。

## 長期說明

Reader BC 同步正式背景讀取、組裝及完整快照後續範圍。既有 bounded-context-map 的 Reader 背景切片以 Session → Reader Facade → Reader UseCase → Reader-owned Port 表達編譯期依賴，標明 Session 與 adapter 的各自責任。
