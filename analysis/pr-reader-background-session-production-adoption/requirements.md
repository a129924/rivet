# PR Reader 背景工作階段需求

Topic `pr-reader-background-session-production-adoption`。查核日期 2026-11-25，基線 `dev` `b0ad6974a33cc53112083eefad60504462593d66`。執行分支 `feat/pr-reader-background-session-production-adoption`。

## 使用情境與交付

選取 PR 後安全載入背景資料。同 PR 顯式刷新時保留最近一次成功資料，晚到的成功、失敗或 Task 清理都不能干擾當前請求。已有的 Reader failure 語意仍適用於有效請求。

交付正式 Swift package 元件及套件內組裝入口。呼叫端提供已就緒的 `GitHubRestClient`，持有每次開啟所建立的 Session，並在離開時使其失效。以正式組裝及 adapter 的受控 REST 測試驗收。產品 App Owner、導覽、登入及真 GitHub 驗收另行交付。

## 採用盤點

| 能力 | 基線證據 | 本輪採用 |
| --- | --- | --- |
| Transport／REST 取消、OAuth 共享 Task 及 nonthrowing Outcome | PR #83 合併 `24e3025e`。E021 本機 HTTP/1.1 與 E022 受控 Inbox REST 在 `386af9e` 各完成一組成功配對。證據限各自受測層級。 | 沿用正式依賴與契約。 |
| Reader 背景資料與注入 | PR #84 交付 `GitHubPullRequestBackgroundSource`，可注入 REST client 並回傳 Reader Outcome，既有測試涵蓋資料與失敗映射。 | 部分具備。補 Reader Port conformance、Session 組裝及實際消費證據。 |
| Task ownership、request identity、原 Task 取消、原子提交／清理、失效 | PR #86 合併 `3919313c`。E023 在 `c3894545` 基線以單一 MainActor owner 與合成來源完成 17 案、167 事件、351 檢查。 | 正式 Reader 尚未採用。按正式元件設計採用行為。實驗 owner、harness、trace 及控制留在原來源。 |
| 同 PR 選取去重、刷新保留資料及失敗後重試 | 使用者確認的顯示政策。 | 由本輪正式元件驗收。 |

[E021](../../experiments/E021/README.md) · [E022](../../experiments/E022/README.md) · [E023](../../experiments/E023/README.md) · [Reader BC](../../docs/architecture/bounded-contexts/pr-reader.md)

## 成功條件

- 選取不同 PR 時立即清除前一個 PR 的資料。同 PR 選取保持原請求與顯示狀態。
- 最新請求具有唯一提交資格。刷新保留成功資料，刷新失敗保留資料並顯示最近失敗，重試清除前次錯誤顯示。
- 取消可繼續使用原 Session。失效永久禁止請求及提交，重開建立新 Session。Task 不延長已失效且由呼叫端釋放的 Session 生命。
- 靠正式 Port、Facade、adapter 和組裝取得資料。GitHub 技術型別留在 Infra 及組裝邊界。
- P01–P17、正式組裝及既有回歸通過，由獨立 Reviewer 檢查範圍、契約與證據後交 Human Review。

完整 Snapshot、WebView、Viewed 持久化、跨 PR cache、通用 Task 管理、HTTP／OAuth redesign 及 E011／E012 驗收接線均列範圍外。
