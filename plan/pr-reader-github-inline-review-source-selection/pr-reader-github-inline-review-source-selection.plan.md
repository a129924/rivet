# PR Reader 行內留言來源選擇執行計畫

Topic 為 `pr-reader-github-inline-review-source-selection`。獨立工作樹 `../rivet.worktrees/agent-20261126-pr-reader-github-inline-review-source-selection`，分支 `feat/pr-reader-github-inline-review-source-selection` 採既有 Reader 命名。執行基線為 `10610d0be88c1d2bce37d5418fa5bae3171f8526`。Human 已確認對話版計畫並授權本工作樹實作及條件式 Draft PR 交付。 [需求](../../analysis/pr-reader-github-inline-review-source-selection/requirements.md) · [技術規格](../../analysis/pr-reader-github-inline-review-source-selection/technical-spec.md)

## swift-implementation

Implementer 開工前逐欄核對。獨立 Reviewer 對驗收證據及實際完整差異核對九欄，涵蓋已暫存、未暫存及允許的未追蹤新增檔。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 套件內入口、兩種結果型別、既有 GraphQL／REST 接線、取消與失敗、離線驗收、BC 文件回寫與五項本機補充審閱。 |
| Out-Of-Scope | Reader Core、公開 API、`PRContentSource`、快照組裝、Checks 與其他來源、Facade／UI／App、真實 GitHub 驗收、GitHub 寫入及本機持久化。 |
| ReadOnly | Written 與 Modify 之外的既有 tracked 路徑，包含來源及原有測試、端點、schema／產碼、`Package.swift`、`GitHubIntegration`、實驗文件及工具設定。 |
| Written | `Sources/BoundedContexts/PRReader/Infra/GitHub/GitHubInlineReviewContentSource.swift`、`Tests/RivetPRReaderGitHubTests/GitHubInlineReviewContentSourceTests.swift`，及同 slug 的四份規劃文件。本機審閱產物留在 ignored 路徑或儲存庫外暫存目錄。 |
| Deleted | 無。 |
| Modify | 驗收後在 `docs/architecture/bounded-contexts/pr-reader.md` 新增來源選擇段落。 |
| Goal | 交付同一 PR 的一份完整可辨識來源的行內留言，或單一 Reader 失敗。 |
| Non-Goal | 重建 REST threads、推導 thread 狀態、跨來源合併或去重、決定快照呈現方式。 |
| TestCase | IS01 GraphQL 優先、IS02 REST 保真、IS03 單一來源、IS04 失敗、IS05 取消、IS06 回歸及差異。 |

## 產品驗收

以一般 `import RivetPRReaderGitHub` 從測試 target 呼叫新入口，受控回應由兩個既有來源讀取。

- **IS01**｜GraphQL 非空多頁及完整空清單直接成功。核對分組、兩層原序、狀態、查詢與 PR 識別。兩案 REST 零請求。
- **IS02**｜GraphQL 回 `.unavailable` 後，REST 多頁保留序列、識別、定位、回覆及缺值，完整空清單同樣成功。REST case 無 thread 狀態。核對 PR 與請求順序。
- **IS03**｜兩來源有重疊留言。GraphQL 成功只交付 GraphQL。GraphQL 累積資料後在續頁回 `.unavailable`，只交付完整 REST，無 GraphQL 前頁累積的獨有留言。
- **IS04**｜GraphQL 的 `.notReadable` 與 `.contentNotRepresentable` 原樣返回，REST 零請求。切換後三種 REST 失敗原樣返回，至少一案在已累積一頁後失敗。
- **IS05**｜開始前取消，兩來源零請求。在任一來源的可控制暫停點取消，晚到成功或失敗均回 `.unavailable`，且無後續切換或續頁。
- **IS06**｜執行 `swift test --filter 'RivetPRReaderGitHubTests|RivetPRReaderTests'`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check`，並按九欄核對完整差異。

## 本機補充審閱

- **Archify**｜在 `.build/topic-evidence/pr-reader-github-inline-review-source-selection/archify/` 產出繁中靜態 sequence。Viewer 介面為英文。用 showcase `validate`、`deliver` 確認 9/9、零錯誤警告。以 `visual-check --repo-root` 驗四尺寸及目視兩極尺寸亮暗畫面，留收據。
- **PR Lens**｜固定版 0.11.0 以真實基線、差異和直接相鄰元件在儲存庫外暫存目錄產圖。適用既有 overlay 時採用，無則 `--no-config`。驗證、淺色渲染並檢查 graph、SVG 及 manifest。提交後依實際 base／head 重驗。工具受限時逐檔核對原始差異。
- **Graphify**｜固定版 0.9.73 每次執行設 `GRAPHIFY_NO_AUTO_REFRESH=1`。只查可追溯版本的既有圖並覆核原碼。圖缺席或不適用時，以 `rg` 和原碼留證。
- **Show Me**｜將實際入口、GraphQL、REST、取消停點記為短呼叫樹，以原碼和受控請求核對。
- **Floorplan**｜將既有 ignored 地圖複製到獨立工作樹，再 refresh 並保留使用者筆記、自訂 flows。依 NEXT 補說明，Recent work 限本題，確認說明覆蓋率 100% 並本機預覽。預覽受限時靜態核對 HTML，記錄未驗互動。

Tester 在帳本記錄工具版本、基線、收據及限制。產品驗收以 IS01–IS06 為準。

## 交接與人類邊界

獨立 Plan-Reviewer 對四份實際文件明示 `approved` 後，由 Implementer 實作，交 Tester 執行驗收，再由獨立 Reviewer 核對結果。既有來源行為、公開契約或九欄之外的路徑需調整時，停在 Human Check。

Human 已授權在驗收及獨立審查無重大問題且 staged diff 符合 topic 時，依 `git-commit-convention` 核對並記錄訊息，做單一 commit、推送及開啟以 `dev` 為目標的 Draft PR。讀回 Draft PR 後交 Human Review。 [步驟帳本](pr-reader-github-inline-review-source-selection.step.md)
