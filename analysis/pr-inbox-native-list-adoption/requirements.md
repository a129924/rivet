# I2 正式採用原生 Inbox 清單需求

開發者可以在 Variant B 工作區的原生 Inbox 掃讀 PR 標題、owner、repository 與編號，也能辨識首次載入、成功零筆、讀取失敗或資料可能非最新。此 topic 以 E025 接入正式畫面後的受控原生結果為採用證據。

## 使用情境

- 在 940 pt 與 420 pt 視窗辨識標題及 `owner/repo #編號`。缺作者或時間時自然省略，既有完整欄位呼叫端沿用目前畫面及 VoiceOver 行為。
- 選取兩筆不同 repository、同編號 PR 的其中一筆。重排或改名後維持同一筆，移除後回到第一個可選列，完整更新至零筆時清除選取。
- 首次等待有進度提示。完整零筆時呈現成功空狀態。首次失敗時呈現錯誤，沒有可操作列。更新失敗時保留可讀的完整舊列及有效選取，並明示資料可能非最新。
- 第二頁等待或失敗時，僅顯示適用的狀態及仍可讀的完整舊列。既有呼叫端的原生鍵盤選取、焦點與安全 Open intent 須通過回歸。

## 採用依據與範圍

查證基線為 `3468eaa`。E025 的 I2-01～07 已獲接受，受控案例與一筆真 PR 上屏各有紀錄。正式 `InboxWorkspace`、PR Inbox Facade 與來源已接入 E025。E025 的四欄列、清單綁定與狀態提示仍為本地實作。正式 List 已透過 E024 驗證既有原生行為，本 topic 採用同一正式 List，並補齊欄位缺值及正式狀態呈現。 [Variant B 視覺採用](../../docs/presentation/pr-inbox-visual-adoption.md) · [E025 受控驗收](../../experiments/E025/evidence/acceptance.md) · [I2-07 真人驗收](../../experiments/E025/evidence/i2-07-live.md)

PR Inbox 決定候選、來源順序及查詢完整性。E025 呼叫端提供可直接呈現的資料與狀態，持有選取、焦點、OAuth 工作階段及實驗情境。本次交付正式列與共用呈現，正式 App 接線、登入與 OAuth 變更、Reader 與 repository 導覽、App menu、離線與復原策略、I3 欄位及篩選規則均排除。真人上屏沿用已接受的 I2-07。 [PR Inbox 契約](../../docs/architecture/bounded-contexts/pr-inbox.md)

## 成功條件

NLA-01～06、E025 受控回歸及正式 Presentation 回歸有對應證據，並經獨立成果審查。Human 授權在獨立 feature worktree 實作。實作及驗收無重大問題時，以單一 topic commit 推送，開以 `dev` 為目標的 Draft PR，交 Human Review。 [執行計畫](../../plan/pr-inbox-native-list-adoption/pr-inbox-native-list-adoption.plan.md)
