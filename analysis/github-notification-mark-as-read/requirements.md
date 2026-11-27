# 將單一 GitHub 通知標記為已讀需求

Topic 為 `github-notification-mark-as-read`。Human 已接受含 internal Endpoint 的對話版計畫，授權在獨立 feature worktree 實作。基線為本機及遠端 `dev` 的 `a559f7a69f2fda6d25c6e50298905f777cd831b4`。

已取得通知的呼叫端可用同一 GitHub 帳號的 thread ID 與 classic PAT，請 GitHub 標記單一 thread 為已讀。GitHub 持有遠端狀態。呼叫端需要分辨確認、未修改、存取遭拒及結果待核對，以免在結果未知時顯示已讀。成功寫入作用於整個 thread，包含送出前可能已進入該 thread 的新通知。 [GitHub 單筆已讀 API](https://docs.github.com/en/rest/activity/notifications#mark-a-thread-as-read)

本次在既有 `GitHubIntegration` target 提供 package 入口。與並行未讀通知能力共用保留 GitHub 字串 ID 的語意，可獨立交付。通知清單與輪詢、整批已讀、標記 done、逐則留言已讀、本機同步、UI、憑證保存及真人驗證均屬範圍外。

## 驗收條件

1. 有效識別對固定 GitHub HTTPS 目的地提交一次無 body、無 query 的 PATCH。無效 ID 或本地準備失敗在提交前回報。
2. 只有 `205` 確認已讀，直接依狀態碼交付。`304` 單獨回報未修改，呼叫端保留原狀態。
3. 存取遭拒、限流、非預期回應及結果待核對可區分。呼叫端保留待核對結果。每次呼叫的自動讀回及自動重送次數為零。
4. Bearer 僅送往固定 GitHub API 目的地並拒絕轉址。回傳及診斷只提供有限分類和必要狀態碼。
5. 驗收使用合成 PAT 和受控傳輸。呼叫端確保提供同帳號 classic PAT，驗收採 `notifications` scope。GitHub 也接受 `repo` scope。 [GitHub 通知認證](https://docs.github.com/en/rest/activity/notifications#about-github-notifications)

[技術規格](technical-spec.md) · [執行計畫](../../plan/github-notification-mark-as-read/github-notification-mark-as-read.plan.md)
