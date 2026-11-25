# 單一 PR 的變更檔案清單

Topic `pr-reader-github-changed-files-source`。基線為含 #89 的 `dev` `d8e2ffe`。

合併前自查時，持有 `ReaderPullRequestID` 與可讀取該 PR 的 GitHub REST client 的呼叫端，可一次取得所有已確認頁面、保留來源順序且識別唯一的檔案及增刪統計。來源提供原路徑或 patch 時保留其值，合法缺席保留為空值。合法空清單為成功。讀取失敗回單一 Reader failure。

完整性以 GitHub 對該 PR 提供的分頁序列為準。達 3,000 檔時，連同恰好 3,000 檔的情況一律回 `.unavailable`。已確認支援數字 repository ID 的續頁，首次出現時額外讀取一次原 PR 詳情以核對歸屬。

範圍限 Reader Infra 唯讀能力及受控測試。完整快照、公開 Port 擴充、UI、raw diff、逐檔補抓 patch、部分結果、固定 PR 版本、Inbox、OAuth、通用分頁及持久化另行規劃。

[技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-changed-files-source/pr-reader-github-changed-files-source.plan.md)
