# 單一 PR 的 REST 行內審閱留言執行計畫

Topic `pr-reader-github-inline-review-comments-source`，獨立工作樹 `../rivet.worktrees/agent-20261126-pr-reader-github-inline-review-comments-source`。分支 `feat/pr-reader-github-inline-review-comments-source` 採 Reader 的 `feat/<work-item>` 慣例。基線 `2764e64a77732902693b7890b346b2f3fa3f487d` 已與遠端 `dev` 核對，包含 PR #99。Human 已核准對話計畫及獨立工作樹實作。 [需求](../../analysis/pr-reader-github-inline-review-comments-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-inline-review-comments-source/technical-spec.md)

## swift-implementation

Implementer 開工前逐欄核對。獨立 Reviewer 核對 Tester 證據及實際完整差異，涵蓋已暫存、未暫存及未追蹤新增檔。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | REST 來源、分頁與歸屬核對、欄位映射、Reader 失敗、離線驗收、BC 文件回寫及五項本機審閱。 |
| Out-Of-Scope | 一般討論留言及審閱紀錄行為變更、GraphQL、來源切換、thread 分組、快照及 UI 接線、GitHub 寫入及本機持久化。 |
| ReadOnly | Written 與 Modify 之外的 tracked 路徑，含端點、相鄰來源、Core、`PRContentSource`、`GitHubIntegration`、`Package.swift`、工具設定及既有實驗文件。 |
| Written | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubInlineReviewCommentsSource.swift`、`Tests/RivetPRReaderGitHubTests/GitHubInlineReviewCommentsSourceTests.swift` 及同 slug 四份規劃文件。本機產物放在 ignored 路徑或 repo 外暫存目錄。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestPageLinks.swift` 僅新增路由。驗收後更新 `docs/architecture/bounded-contexts/pr-reader.md` 的行內留言段落。 |
| Goal | 套件內呼叫端取得完整有序的 REST 行內留言清單或單一 `PRReaderFailure`。 |
| Non-Goal | 推導 `isResolved` 或 `isOutdated`、組裝快照、接入產品入口。 |
| TestCase | IC01 請求與保真、IC02 分頁、IC03 失敗與取消、IC04 回歸與差異。 |

## 產品驗收

- **IC01**｜一般 `import RivetPRReaderGitHub` 跨 target 呼叫並讀取結果欄位。核對 GET、首續頁 URL、三個標準標頭與 `nil` body。涵蓋兩頁原序、頁次、重複、超過 `2^53` 的 ID、Markdown、檔案層級、缺欄、`null` 及空清單。
- **IC02**｜驗證具名與數字續頁、末頁只有數字 `last`、詳情順序及重用。涵蓋錯目的地、repo、PR、路徑、query、跳頁、循環、矛盾 Link、詳情失敗和 ID 不符。查請求紀錄確認無無效續頁。
- **IC03**｜無效起始識別零請求。涵蓋首頁與後頁權限拒絕、`404`／`410`、限流、傳輸、壞資料、讀取前取消及累積資料後的晚到成功與錯誤。每案只交付單一失敗。
- **IC04**｜執行 `swift test --filter RivetPRReaderGitHubTests`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 及 `git diff --check`，核對相鄰回歸及完整差異，含未追蹤檔。工具入口受限時記錄實際使用的等效檢查。

## 本機審閱

| 工具 | 交付 |
| --- | --- |
| Archify | 在 `.build/topic-evidence/pr-reader-github-inline-review-comments-source/archify/` 交付繁中靜態 sequence，viewer 為英文。 `validate`、`deliver` 要求 showcase 9/9、零錯誤警告。 `visual-check --repo-root` 核對四尺寸，目視核對最小及最大尺寸亮暗畫面。 |
| PR Lens | 固定版 0.11.0 於 repo 外暫存目錄依實際基線與 bounded diff 製圖，納入允許的未追蹤檔與未變相鄰節點。驗證並用 light theme 渲染，核對 graph、SVG、manifest 及差異。適用 overlay 則採用，無則 `--no-config`。提交後核對實際 base／head。受限時逐檔核對。 |
| Graphify | 固定版 0.9.73，每次設 `GRAPHIFY_NO_AUTO_REFRESH=1`。只查可追溯版本的既有本機圖並覆核原碼。圖或 runtime 不適用時用 `rg` 及原碼並留證。 |
| Show Me | Tester 核對入口 → GET → 映射 → Link → 若需要則查核 PR 詳情 → 續頁 → 完整清單或單一失敗，記錄符合或差異。 |
| Floorplan | 複製既有 ignored 地圖至獨立工作樹再 refresh，保留筆記、自訂 flows。依 NEXT 補說明，Recent work 限本 topic。確認說明覆蓋率 100%，由 `open.mjs` 本機預覽。環境受限時靜態核對 HTML 並記錄未驗互動。 |

Tester 在步驟帳本記錄基線、收據、原碼核對、替代檢查及未驗項。IC01–IC04 決定產品驗收。

## 交接與停點

獨立 Plan-Reviewer 對四檔明示 `approved` 後，依序交 Implementer、Tester 及獨立 Reviewer。Core、公開契約、續頁信任範圍、完整交付語意或 tracked 範圍需調整時，停在 Human Check。

Human 已授權在驗證與獨立成果審查無重大問題且 staged diff 符合九欄時直接做單一 topic commit、推送並開啟以 `dev` 為目標的 Draft PR。依 `git-commit-convention` 核對差異及訊息。Draft PR 建立並讀回後交還 Human Review。 [步驟帳本](pr-reader-github-inline-review-comments-source.step.md)
