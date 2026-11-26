# 按需讀取 GitHub 未讀通知｜需求

Topic 為 `github-unread-notifications-source`。查證基線為 `d47354ef66dff4e3b1562a974aaabc486c246c6a`，執行基線為 `dev` 的 `fa3329bfe78be069633d8e08a74ecc4389ab386c`。執行基線包含已合入的 Files Viewed。 [查證基線](https://github.com/a129924/rivet/commit/d47354ef66dff4e3b1562a974aaabc486c246c6a) · [執行基線](https://github.com/a129924/rivet/commit/fa3329bfe78be069633d8e08a74ecc4389ab386c)

## 呼叫端需要的能力

套件呼叫端每次提供一個具 `notifications` 或 `repo` scope 的 classic PAT，取得該憑證所屬帳號的 GitHub.com 通知。以 `all=false` 讀取 GitHub 的未讀範圍，省略 `is_done`，維持 GitHub 回傳的順序與狀態。`notifications` 為較窄的驗收 scope。 [GitHub 通知 API](https://docs.github.com/en/rest/activity/notifications#list-notifications-for-the-authenticated-user)

- 完整讀取可驗證的分頁後才交付清單，完整零筆回傳成功空陣列。完整性以該次 GitHub 回應的分頁鏈為準。
- 每筆保留 thread 識別、原始 `unread`（含 `false`）、更新與最後已讀時間、主旨標題與原始類型、可缺的主旨與最新留言連結，以及 repository 識別。
- 呼叫端可區分存取拒絕、分頁未完成、必要資料無法映射、其他首頁失敗及取消。任何失敗都只交付分類。憑證、回應原文、底層錯誤與部分清單不得出現在輸出或診斷。
- 所有頁面維持同一 PAT 和固定查詢範圍。Bearer 只送往經核對的 GitHub.com 通知 endpoint。主旨連結只作為資料回傳。

## 工作邊界

本題在 GitHubIntegration 內提供套件級唯讀入口。排除新增 Bounded Context 或 target、產品登入與憑證保存、通知 UI、系統通知、背景輪詢與快取、標記已讀、讀取主旨資源，以及 comment-level last-seen。實作與驗證僅使用受控 REST 回應及合成 PAT。

Human 已核准對話版 processed-plan 和獨立工作樹實作。若驗證及獨立成果審查無重大問題，並確認 staged diff 是單一 topic，Human 已授權一次 commit、push 和開啟以 `dev` 為目標的 Draft PR。交付後交回 Human Review。 [技術規格](technical-spec.md) · [執行計畫](../../plan/github-unread-notifications-source/github-unread-notifications-source.plan.md)
