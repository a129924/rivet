# 讀取單一 PR GraphQL 審閱對話執行計畫

Topic 為 `pr-reader-github-review-threads-source`。獨立工作樹為 `../rivet.worktrees/agent-20261126-pr-reader-github-review-threads-source`，分支 `feat/pr-reader-github-review-threads-source` 沿用 Reader 的 `feat/<work-item>` 慣例。基線為本機 `dev` 的 `1fcdb2c274e2d0fde5c88e4225e20942650167c3`，已納入 PR #100。Human 已核准對話版完整計畫和獨立工作樹實作。 [需求](../../analysis/pr-reader-github-review-threads-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-review-threads-source/technical-spec.md)

## swift-implementation

Implementer 開工前逐欄核對。獨立 Reviewer 依 Tester 證據核對已暫存、未暫存及範圍內未追蹤的完整差異。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | Reader Infra 讀取入口、保真結果、兩層查詢與分頁、官方 schema 採用、離線驗收、BC 文件回寫及五項本機補充審閱。 |
| Out-Of-Scope | 公開 API、Reader Core、`PRContentSource`、共享 GraphQL client 與既有 REST 來源的行為變更。 |
| ReadOnly | Written 與 Modify 之外的 tracked 路徑，包含舊 schema topic 帳本、工具設定及現有實驗文件。 |
| Written | 同 slug 的四份正式規劃文件。於 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/` 新增 `GitHubReviewThreadsSource.swift`、`ReaderReviewThread.swift`、`ReviewThreads.graphql`、`apollo-codegen-config.json` 及 `Generated/` 內的 Apollo 生成 Swift。新增 `Tests/RivetPRReaderGitHubTests/GitHubReviewThreadsSourceTests.swift`。本機證據放在 ignored 路徑或 repo 外暫存目錄。 |
| Deleted | 無。 |
| Modify | `Package.swift` 調整 Reader Infra 與測試 target 依賴和範圍。於 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `packageDeclaresTheLockedTargetGraph` 僅更新 `RivetPRReaderGitHub` 的來源路徑，以及該 target 與 `RivetPRReaderGitHubTests` 的 Apollo／ApolloAPI 依賴預期。以官方快照替換 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls`。驗收後在 `docs/architecture/bounded-contexts/pr-reader.md` 回寫 Reader GraphQL 契約與 schema 來源。 |
| Goal | 交付指定 PR 的完整分組、狀態與原序。完整空清單回成功，失敗只回單一 `PRReaderFailure`。 |
| Non-Goal | 快照組裝、REST fallback／去重、Facade／UI 接線、寫入、持久化及 live 驗收。 |
| TestCase | RT01 欄位保真與套件入口、RT02 兩層分頁、RT03 失敗與取消、RT04 產碼與回歸。 |

## 產品驗收

- **RT01**｜以一般 `import RivetPRReaderGitHub` 呼叫套件內入口，使用測試專用 client、真 Apollo 解碼及受控傳輸核對查詢。驗證 thread 與留言識別、`FILE`／`LINE`、已知行號與合法缺值、原始 Markdown、作者與回覆指向、兩種狀態獨立及完整空結果。
- **RT02**｜外層兩頁且至少兩個 thread 各有留言續頁。核對請求次序、變數及游標歸屬、原序、分組與識別。核對終頁允許空游標。
- **RT03**｜覆蓋無效輸入零請求、錯 PR／thread、游標停滯與循環、重複 ID、null 集合或元素、GraphQL 部分與只有錯誤的回應、明確拒絕、裸 403、限流、傳輸、解碼及取消。各層後頁失敗只回單一 failure，取消優先於晚到成功或錯誤。
- **RT04**｜核對官方快照雜湊和離線重生差異。執行 `swift test --filter 'RivetPRReaderGitHubTests|RivetPRReaderTests|GitHubIntegrationTests'`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 和 `git diff --check`。核對套件隔離測試只隨新 Reader GitHub 來源路徑和這一對 target 的 Apollo／ApolloAPI 依賴調整預期，並核對允許的新增檔與完整差異。

## 本機補充審閱

Implementer 產出或更新本機證據。Tester 獨立核對並在帳本登記來源、工具版本、產物、收據、未通過或未驗項目。獨立 Reviewer 依實際差異與證據審查。RT01–RT04 決定產品驗收。工具受限時採下列備援，所有產物留於本機。

| 工具 | 產物與查核 |
| --- | --- |
| Archify | 於 `.build/topic-evidence/pr-reader-github-review-threads-source/archify/` 交付繁中靜態 sequence，viewer 為英文。`validate`、`deliver` 的 showcase 須 9/9、零錯誤警告。`visual-check --repo-root` 核對四尺寸，目視最小與最大尺寸亮暗畫面。受限或未通過時據實記錄，依原碼與受控測試核對流程。 |
| PR Lens | 固定版 0.11.0 於 repo 外暫存目錄依實際基線與 bounded diff 製圖，納入允許的未追蹤檔及未變相鄰節點。執行 validate 與 light render，核對 graph、SVG、manifest 及差異。查無適用 overlay 時用 `--no-config`。有授權且產生 commit 後，以實際 base／head 重驗。受限時逐檔核對。 |
| Graphify | 固定版 0.9.73，每次設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。只讀查詢可追溯至受查版本的既有本機圖，並回看原碼。目前預設位置無可用圖，使用 `rg` 與原碼追查並於帳本留證。 |
| Show Me | 在帳本記錄短 call tree。Tester 依原碼與受控請求核對入口 → 外層頁 → 逐 thread 驗證與讀完留言續頁 → 外層次頁或完整成功，以及任一層失敗或取消 → 單一 failure。 |
| Floorplan | 複製整份既有 ignored `floorplan/` 至獨立工作樹再 refresh，避免取代原工作樹的地圖。保留筆記、自訂 flows，依 NEXT 補說明，Recent work 限本 topic。查核說明覆蓋率 100%，以 `open.mjs` 本機預覽。受限時靜態核對 HTML 並記錄未驗互動。 |

## 交接與停點

獨立 Plan-Reviewer 對實際四檔明示 `approved` 後，依序交 Implementer、Tester 及獨立 Reviewer。若 schema 來源或查詢相容性無法驗證、產碼無法重現，或需要變更公開契約、共享 client、完整性條件或 tracked 路徑，停在 Human Check。

Human 已授權在產品驗證及獨立成果審查無重大問題、staged diff 符合九欄語意邊界時，做單一 topic commit、推送功能分支並開啟以 `dev` 為目標的 Draft PR。提交前依 `git-commit-convention` 核對 staged diff、提出並記錄 commit message。以上條件未成立時停在提交前。Draft PR 建立並讀回後停在 Human Review。 [步驟帳本](pr-reader-github-review-threads-source.step.md)
