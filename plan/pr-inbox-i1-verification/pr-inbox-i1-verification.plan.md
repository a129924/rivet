# PR Inbox I1 執行計畫

Topic `pr-inbox-i1-verification`，分支 `chore/pr-inbox-i1-verification`，`dev` 基線 `e0cab03`，實驗 E024。

| 欄位 | 契約 |
| --- | --- |
| Goal | 驗證可操作的原生 Inbox 與完整 PR 識別的單次 Open。 |
| Non-Goal | 正式產品接線、真網路及重試、跨環境保證與採用。 |
| In-Scope | SwiftPM App、原生元件組合、合成資料、情境、選取、焦點與事件證據。 |
| Out-Of-Scope | I2、R1、可操作 repository 導覽、篩選、重試及正式元件 API 變更。 |
| ReadOnly | 四份規劃文件於 Swift 實作階段、正式 Swift／WebView、根套件及 lockfile、正式測試、原型、既有契約、實驗與索引。 |
| Written | E024 套件、README、必要的 Sources、Tests、scripts 與可追溯證據。 |
| Deleted | 無。 |
| Modify | 僅修正本輪新建的 E024 檔案。 |
| TestCase | I1-01 至 I1-08。 |

## TestCase

| ID | 判準 |
| --- | --- |
| I1-01 | 初始選取並聚焦 A。選 B，再由 [A,B,C] 重排為 [B,A,C]，保留 B。移除 B 回退並聚焦 A。更新的 Open 增量為 0。 |
| I1-02 | 單擊、方向鍵、Home、End 只改選取。清單有焦點時 Enter 記當前安全 PR 一筆，失焦增量為 0。從 A 雙擊 B 選取並記錄 B 一筆。 |
| I1-03 | 不可開啟、未知與過期請求增量均為 0。移除 B 後注入 B 保持 A；下一個原生 Enter 記 A 一筆。注入涵蓋 Session。 |
| I1-04 | 載入保留版面與識別，停用列及 Open。保持有效焦點，否則聚焦載入標題。 |
| I1-05 | 成功空清單聚焦標題，停用列及 Open。 |
| I1-06 | 可讀錯誤保留清單、選取及有效焦點，標示可能非最新。無有效焦點時聚焦錯誤標題。不可讀或可用性未知時隱藏列、聚焦錯誤標題及停用 Open。復原停用。 |
| I1-07 | 已知離線且可讀時保留舊列及有效選取，標示離線及可能非最新。無可讀資料時聚焦離線標題並停用 Open。復原停用。 |
| I1-08 | 明暗與 Login 並排，察看鍵盤焦點及失焦選取，實際聆聽 VoiceOver 對列識別、標題、選取與局部狀態的宣告。 |

以一輪完整驗收為主。可補跑一次已定位的環境或取證問題。依法保留實際版本、命令、畫面、聆聽及逐步事件。全部符合才判成功。有效證據確認違例判失敗，已嘗試而證據不足判無法判定。

Graphify 查既有圖後回源碼。Archify 呈現受測流程，PR Lens 使用真實 diff，Floorplan 於隔離環境刷新，show-me 呈現手勢到事件紀錄。輔助圖留本機。
