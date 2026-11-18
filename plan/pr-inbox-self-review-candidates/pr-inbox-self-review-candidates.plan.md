# PR Inbox 自查候選執行計畫

在既有 PR #78 的 feature worktree 新增自查候選入口、GitHub adapter、受控測試與獨立 E020 驗證。實作前由獨立 Plan-Reviewer 核對四檔，實作後交獨立 Tester 與 Reviewer。

| 欄位 | 規格 |
| --- | --- |
| In-Scope | 自查候選 Core、Facade、Inbox 自有 GitHub 基礎設施、CLI、驗證和有效文件。 |
| Out-Of-Scope | UI、自查完成狀態、產品登入、GitHub 資料寫入、合併或發布。 |
| ReadOnly | E019 與其規劃 artefacts、GitHubIntegration、RivetHTTPClient、PR Reader、Presentation。 |
| Written | 本 topic 四檔、SelfReviewSource 與候選型別、Inbox GitHub target、測試及 E020。 |
| Deleted | 無。 |
| Modify | 既有 Facade 與內部 refresh use case、root manifest 與其 target graph 驗證、必要的產品、架構與 API 文件。 |
| Goal | 同一 Facade 首版能取得目前 OAuth 帳號自己開的 open PR。 |
| Non-Goal | 推斷是否完成自查、引入一般重試、擴張產品責任。 |
| TestCase | Core membership、REST 查詢與分頁、失敗映射、E019 相容性、E020 真實正例。 |

核對單一語意 staged diff 後，將加法式 commit 正常推送至既有分支，更新 Draft PR #78 的摘要與驗證狀態。真實前置若缺失，在 E020 與 PR 明列。停在 Human review。
