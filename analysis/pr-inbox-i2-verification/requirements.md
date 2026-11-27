# PR Inbox I2 · 需求

Topic 為 `pr-inbox-i2-verification`。讓單人開發者在 macOS 原生 Inbox 看見目前 GitHub.com OAuth 帳號自己建立且仍開啟的 PR，並在更新時保留仍存在的選取。I2 要補上 E020 的真人查詢結果進入 E024 所採用的 Variant B 原生工作區的證據。 [E020](../../experiments/E020/README.md) · [Variant B 採用](../../docs/presentation/pr-inbox-visual-adoption.md)

## 範圍

- 用既有 OAuth 授權驗收一筆真實 open PR，由 GitHub PR 詳情獨立核對作者、open 狀態與四欄，再比對原生清單的 owner、repository、number、title。
- 用受控 REST 資料驗收同帳號的 open Draft 入列、他人建立與已關閉的 PR 排除，以及完整空清單、查詢失敗、跨頁失敗和更新選取。由既有 PR Inbox 決定候選與順序。 [PR Inbox 契約](../../docs/architecture/bounded-contexts/pr-inbox.md)
- 原生列顯示標題、`owner/repo` 和 `#number`。驗收涵蓋寬版，畫面省略作者、時間、Draft 徽章與孤立分隔點。
- 四欄原生清單與資料接線限於 `experiments/`。正式 App 登入與接線、Reader 或 repository 導覽、篩選規則與 Draft 徽章延後。

## 完成判定

受控案例全部通過，且同一 OAuth 帳號的一筆獨立核對正例在原生 Inbox 四欄吻合，I2 才完成。既有 OAuth 工作階段無法使用時，照常交付受控結果，將真人項記為「未執行」，I2 整體維持未完成。驗收保留受測版本、相關畫面、四欄比對與選取變化。 [執行計畫](../../plan/pr-inbox-i2-verification/pr-inbox-i2-verification.plan.md)
