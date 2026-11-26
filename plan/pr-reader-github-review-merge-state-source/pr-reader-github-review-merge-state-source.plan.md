# 單一 PR 審閱與合併狀態執行計畫

Topic `pr-reader-github-review-merge-state-source`，分支 `feat/pr-reader-github-review-merge-state-source`。基線為 `dev` 的 `10610d0be88c1d2bce37d5418fa5bae3171f8526`。使用獨立 worktree `../rivet.worktrees/agent-20261126-pr-reader-github-review-merge-state-source`。 [需求](../../analysis/pr-reader-github-review-merge-state-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-review-merge-state-source/technical-spec.md)

## swift-implementation

`GraphQL/` 代表 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/`。Implementer 開工前核對九欄，Reviewer 核對 staged、unstaged 與允許新增的 untracked 檔。

| 欄位 | 執行契約 |
| --- | --- |
| In-Scope | 新 query、必要產碼、套件入口與結果型別、RM01–RM04、PR Reader 契約回寫與五項本機輔助審閱。 |
| Out-Of-Scope | 審閱與合併寫入、Checks 與 reviewThreads 改造、Reader Core 與公開 API 變更、共用 client／headers／SDL 更新、REST 來源、快照組裝、UI 與持久化。 |
| ReadOnly | `Written` 與 `Modify` 之外的 tracked 路徑，含其他 topic 文件、共用工具設定與既有 GraphQL operations。 |
| Written | 同 slug 的 requirements、technical-spec、plan、step 四份文件。在 `GraphQL/` 新增 `PullRequestReviewMergeState.graphql`、`GitHubPullRequestReviewMergeStateSource.swift`、`ReaderPullRequestReviewMergeState.swift` 及必要 `Generated/` 檔。在 `Tests/RivetPRReaderGitHubTests/` 新增 `GitHubPullRequestReviewMergeStateSourceTests.swift`。 |
| Deleted | 無。 |
| Modify | `GraphQL/apollo-codegen-config.json` 的 `operationSearchPaths` 與 `Package.swift` 對應 target 的 `exclude` 各追加新 query。既有生成檔只收錄本題必要且可重生的差異。驗收後回寫 PR Reader 的長期契約與重生命令，在本題步驟帳本更新後續證據。 |
| Goal | 呼叫端取得同一筆經核對 PR 的五項狀態，保留合法缺值及兩種 `UNKNOWN`，或收到單一 Reader failure。 |
| Non-Goal | 推導是否可合併、交付部分結果、接入畫面。 |
| TestCase | RM01 入口與狀態映射、RM02 PR 歸屬與失敗分類、RM03 解碼與取消、RM04 產碼與回歸。 |

## 產品驗收

- **RM01**。走套件入口與受控 Apollo JSON，核對變數、正常情況單次請求、五項回傳值、各自的 `UNKNOWN`、詳細狀態 `DRAFT` 與獨立的 `isDraft`。
- **RM02**。核對三項歸屬比對、無效輸入零請求、定位缺席與拒絕、混合與欄位層級錯誤、無法確認完整、裸 403、限流、傳輸、未知 enum 及空白必要值。
- **RM03**。正式 Apollo 解析區分顯式 null、欄位遺漏與錯型。核對事前取消與回應晚到，以及晚到認證錯誤。
- **RM04**。Apollo 2.1.2 以固定 SDL 先清潔離線重生兩份操作文件的三個 operations，再含新 query 重生四個 operations。比較兩組輸出。執行 `swift test --filter 'RivetPRReaderGitHubTests|RivetPRReaderTests|GitHubIntegrationTests'`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`，記錄 Checks 與 Review Threads 回歸。

## 本機輔助審閱

| 工具 | 執行與核對 |
| --- | --- |
| Archify | 在 `.build/topic-evidence/<topic>/archify/` 製作繁中 sequence，Viewer 採英文。執行 showcase validate、deliver 與四尺寸 visual-check，達 9/9、零 errors／warnings。目視最小與最大尺寸的亮暗畫面。 |
| PR Lens | 固定 0.11.0，以實際 base 與本題 diff 在 repo 外暫存目錄製圖，涵蓋允許新增檔與其直接鄰居。先執行 validate，再用適用的既有 overlay 執行 light render。無 overlay 時以 `--no-config` render，並讀回 manifest 與 SVG。交付時對照實際 base、head。 |
| Graphify | 固定 0.9.73，每次設 `GRAPHIFY_NO_AUTO_REFRESH=1`。有受查版本的既有圖才限量查詢並覆核原碼。缺圖時用 `rg` 和原碼核對。 |
| Show Me | 在帳本記錄入口、輸入驗證、查詢、歸屬比對、五項狀態或單一 failure 的 call tree。 |
| Floorplan | 將既有 ignored map 複製至 feature worktree 後 refresh，保留筆記與自訂 flows。Recent work 只顯示本題，核對說明覆蓋、預覽、高嚴重度 Health 項目與未覆蓋檢查。 |

Implementer 產出證據，Tester 獨立驗證，Reviewer 核對差異與證據。工具產物留在 ignored 或 repo 外暫存目錄。工具受限時記錄原因、來源替代核對與未驗項，產品驗收依 RM01–RM04。

## 交接與停點

獨立 Plan-Reviewer 讀回四檔並明示 `approved` 後依序交 Implementer、Tester 與獨立 Reviewer。固定 SDL 或 codegen 無法支援、或需改動已核准契約與 tracked 範圍時，交 Human 決定。

Human 明示授權本題在實作、驗證與獨立審查無重大問題時，依 `git-commit-convention` 核對 staged diff 並提出訊息後，進行單一 topic commit、push 與以 `dev` 為目標的 Draft PR。讀回遠端狀態後停在 Human Review。 [步驟帳本](pr-reader-github-review-merge-state-source.step.md)
