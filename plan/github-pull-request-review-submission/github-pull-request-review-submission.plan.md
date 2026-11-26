# 送出單一 PR 的整體 Review

規劃及查證基線為 `dev` 的 `a559f7a69f2f`。工作分支 `feat/github-pull-request-review-submission`，整合目標 `dev`。本次寫入限獨立 feature worktree。

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| Goal | 送出指定 PR 和 commit 的整體 Review，回報接受、拒絕或待核對結果。 |
| Non-Goal | 完整審閱工作流及遠端結果自動核對。 |
| In-Scope | 套件內 target、REST 請求與結果、受控測試、依賴驗證、API Catalog 和本機檢閱證據。 |
| Out-Of-Scope | 逐行留言、PENDING、編輯、撤回、合併、產品 UI、PAT 寫入組裝、資料遷移、共用 REST 或 Reader 契約修改、真人遠端驗收。 |
| ReadOnly | 其餘 tracked 路徑，包含共用 REST client、PR Reader 與主工作樹的兩項 experiments 索引修改。 |
| Written | `analysis/github-pull-request-review-submission/requirements.md`<br>`analysis/github-pull-request-review-submission/technical-spec.md`<br>`plan/github-pull-request-review-submission/github-pull-request-review-submission.plan.md`<br>`plan/github-pull-request-review-submission/github-pull-request-review-submission.step.md`<br>`Sources/RivetPRReviewGitHub/GitHubPullRequestReviewSubmission.swift`<br>`Tests/RivetPRReviewGitHubTests/GitHubPullRequestReviewSubmissionTests.swift` |
| Deleted | 無。 |
| Modify | `Package.swift`<br>`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`<br>`docs/github-api/rest-discussion-reviews.md` |
| TestCase | TC01 三種動作與 wire request。TC02 無效輸入與預先取消零呼叫。TC03 收據、拒絕、認證與結果待核對。TC04 401 重送上限。TC05 套件隔離及靜態檢查。 |

執行新 target、`GitHubRestClientTests`、`StaticIsolationTests`、Swift 格式、lint 與 `git diff --check`。檢查每次 adapter 操作呼叫 REST client 零或一次，並保留 adapter 實際取得的 200。依驗證結果更新 API Catalog。

## 本機檢閱證據

- Archify 2.16 製作繁中 sequence，Viewer 使用英文。執行 showcase validate、deliver、四尺寸 visual-check 及目視核對。產物位於 ignored 的 `.build/topic-evidence/github-pull-request-review-submission/archify/`。
- PR Lens 0.11.0 使用實際 topic diff，在 repo 外驗證及渲染，記錄 base、head 與未提交狀態。
- Graphify 0.9.73 只查詢能核對來源的既有 graph。每次使用 `GRAPHIFY_NO_AUTO_REFRESH=1`。若圖缺席或過期，直接核對原始碼。
- Show Me 交接呼叫樹由送出入口經 REST client 到 GitHub，包含本機拒絕、401 復原、收據與待核對。
- Floorplan 僅在 feature worktree 刷新既有 ignored map，保留作者內容，更新本 topic 的卡片、依賴與 Recent work。記錄 build 與預覽結果。

工具證據留在本機。獨立 Plan-Reviewer 核准後，由 Implementer、Tester、Reviewer 依序執行。使用者已授權驗證無重大問題時提交單一 topic commit、推送並開 Draft PR。提交前檢查 staged diff 與 commit message，Draft PR 讀回後停於 Human review。

[需求](../../analysis/github-pull-request-review-submission/requirements.md) · [技術規格](../../analysis/github-pull-request-review-submission/technical-spec.md) · [步驟帳本](github-pull-request-review-submission.step.md)
