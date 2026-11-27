# PR Inbox I2 · 在原生 Inbox 看見自己的 GitHub PR

Topic `pr-inbox-i2-verification`。規劃查證基線為本機 `dev` `0623246`。驗證 App 路徑採 `experiments/E025`，開始實作前複核當時的 `dev` 及實驗編號。 [需求](../../analysis/pr-inbox-i2-verification/requirements.md) · [技術規格](../../analysis/pr-inbox-i2-verification/technical-spec.md) · [步驟帳本](pr-inbox-i2-verification.step.md)

**建議分支** `chore/pr-inbox-i2-verification`。沿用 I1 獨立驗證工作的 `chore/<work-item>`，以 `dev` 為整合基線。進入實作前確認分支可用性。 [I1 分支前例](../pr-inbox-i1-verification/pr-inbox-i1-verification.plan.md) · [開發分支流程](../../docs/development-workflow.md)

## swift-implementation 執行契約

| 欄位 | 契約 |
| --- | --- |
| Goal | 在 Variant B 原生 Inbox 看見目前 GitHub.com OAuth 帳號自己建立且仍 open 的 PR。核對一筆真人正例上屏，並以受控資料驗證合格 Draft、更新選取與查詢失敗。 |
| Non-Goal | I2 交付獨立原生驗收與證據。正式產品接線、授權能力與 PR 閱讀屬後續 topic。 |
| In-Scope | E025 驗證 App 重用既有 OAuth REST、`GitHubSelfReviewSource`、`PRInboxFacade.refresh()` 與 Variant B `InboxWorkspace`。受控與真人入口共用四欄原生列與選取狀態，候選、來源順序、完整成功與失敗語意由既有 PR Inbox 提供。執行 I2-01～07 並保留版本、畫面與比對。 |
| Out-Of-Scope | 正式 App 登入或接線、互動授權、增加 OAuth scope、PAT、憑證匯入、正式公開 API 變更、Reader 與 repository 導覽、篩選規則及 Draft 徽章。 |
| ReadOnly | `Sources/`、`Tests/`、根目錄 `Package.swift` 與 `Package.resolved`、`experiments/E020/`、`experiments/E024/`、`experiments/README.md`、`experiments/VALIDATION-SUMMARY.md`、既有 OAuth／PR Inbox 契約，以及本 topic 的需求、技術規格與執行計畫。既有工具設定及共享圖譜供參考。 |
| Written | 版本庫內新增限於 `experiments/E025/`。包含獨立 SwiftPM 套件檔、`Sources/`、`Tests/`、必要建置入口、`README.md` 和 `evidence/` 下的驗收證據。輔助工具的產物留在本機隔離目錄。 |
| Deleted | 無既有版本庫檔案刪除。 |
| Modify | 本 topic 的 `.step.md` 記錄進度。驗收通過且成果獲接受後，僅補 `docs/presentation/pr-inbox-visual-adoption.md` 的已驗收範圍及證據連結。 |
| TestCase | I2-01～06 為受控與原生案例，I2-07 為既有 OAuth 的真人原生上屏。逐案判準見下表。 |

## TestCase

| ID | 情境與可觀察結果 |
| --- | --- |
| I2-01 | 受控 REST 回應含同帳號的 open 一般 PR 與 Draft、他人的 open PR、同帳號 closed PR。從原生畫面核對只有前兩類入列，保留來源順序。 |
| I2-02 | 初始順序 A、B、C，其中 A、B 為不同 repo 的同號 PR。選 B，更新成 A、C、B 並改 B 的標題。仍選第三列的 B。再移除 B，選取回退至第一列 A。 |
| I2-03 | 完整成功但零筆時顯示空清單且無選取。由已有選取的清單更新至空時同樣清除選取。 |
| I2-04 | 首次查詢失敗顯示「無法取得 Pull Request」，無可操作列。已有可讀資料後更新失敗，顯示可能非最新並保留最後一次完整清單及有效選取。 |
| I2-05 | 受控第一頁成功且含當次查詢獨有的 PR。觀測 fake REST 確實進到第二頁並先暫停，核對等待中未發布第一頁獨有列。解除暫停並回傳失敗後再核對一次。無舊列與有舊列各走一次，依 I2-04 顯示錯誤或保留舊清單。 |
| I2-06 | 在 Variant B 原生視窗的寬版與窄版核對標題、`owner/repo`、`#number`。作者、時間、Draft 徽章與孤立分隔點均省略。保存代表截圖與實際視窗寬度。 |
| I2-07 | 使用既有 OAuth 工作階段。獨立確認 GitHub PR 詳情的作者是本次 `/user` 帳號且 PR 仍 open，再核對原生列的 owner、repository、number、title，保留驗收畫面與逐欄比對。 |

## 實作與審查工具

工具產物留在本機 topic 專用目錄。各工具依其 skill 驗證產物，並記錄來源版本、產物或遇到的限制。I2 完成判定依 I2-01～07 的結果。

| 工具 | 使用時機與產物 |
| --- | --- |
| Graphify | 實作前先對既有本機圖做有界查詢，核對圖的來源版本，再回讀 Inbox 來源、Facade、`InboxWorkspace` 與 OAuth 組裝原碼。若圖不可用、過時或未涵蓋所需關係，直接查相關原碼。 |
| Archify | 接線完成後，依實作繪製繁中 sequence，呈現受控與真人共用的查詢、完整結果發布、第二頁失敗與舊清單保留。依 `showcase` 驗證與交付 HTML，保留驗證收據及視覺檢查結果。固定 Viewer UI 採英文 fallback。 |
| PR Lens | 成果審查前以實際 base/head 或含 E025 新增檔的有界 diff 製作本機變更圖。記錄實際來源，保留未變動的直接鄰接元件，使用已固定的 CLI 驗證與渲染。 |
| show-me | 重用規劃期合成資料示意，依實作補上必要的選取與空清單／失敗畫面。審閱時展示重排保留、移除回退及失敗保留舊清單。 |
| Floorplan | 以隔離副本描繪 E025 App、Session、受控與真人接線及直接依賴。實作後用同一受測來源建立或刷新 `floorplan/index.html`，驗證相關檔案與連線，記錄掃描未涵蓋處。輸出保存在隔離副本內。 |

## 執行順序與停止點

1. 獨立 Plan Review 後，由 Human 審閱完整計畫並明示執行授權。確認 `dev`、分支及 E025 路徑後，在隔離工作樹依上述執行契約進入 `swift-implementation`。
2. 用 Graphify 導覽並回讀原碼。實作受控 REST、共用資料呈現及原生狀態，再接上既有 OAuth scope。Tester 先跑 E025 自動化及相關 Inbox 回歸，核對 I2-01～06 原生情境，保存版本、命令、畫面、選取及狀態變化。
3. 在可用既有 OAuth 工作階段上執行 I2-07。前置不足記「未執行」，有執行而證據不足記「無法判定」，有效證據顯示違反判準記「失敗」。受控通過不能補足真人證據。Reviewer 獨立核對兩種結果及範圍後交 Human Review。

任何需新增 OAuth 授權或 scope、修改正式 API、擴大產品接線的情況交 Human Check。I2-01～07 全部通過才記 I2 驗收完成。
