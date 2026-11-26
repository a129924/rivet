# 讀取單一 PR 的 Checks 執行計畫

Topic 為 `pr-reader-github-checks-source`。固定基線 `97e3db851348d2dc0305fc371aa792ce84b257ae` 已納入 PR #102，並對應 `v0.1.94-pr-reader-github-review-threads-source`。本題使用獨立工作樹 `../rivet.worktrees/agent-20261126-pr-reader-github-checks-source` 及分支 `feat/pr-reader-github-checks-source`。Human 已核准對話版計畫、獨立 worktree 實作及條件式交付。 [PR #102](https://github.com/a129924/rivet/pull/102) · [需求](../../analysis/pr-reader-github-checks-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-checks-source/technical-spec.md)

## swift-implementation

Implementer 開工前依九欄逐欄核對。獨立 Reviewer 依 Tester 證據審查 tracked 的 staged 與 unstaged diff，以及允許新增的 untracked 檔。

| 欄位 | 執行契約 |
| --- | --- |
| In-Scope | Checks operation、產碼、Reader Infra 來源、CK01–CK04 受控驗收、BC 契約回寫及五項本機輔助審閱。 |
| Out-Of-Scope | `reviewThreads` 行為、整體 review decision、Reader Core、公開 API、共享 client／headers／SDL 基線、REST 來源、快照與 UI、合併判定、重跑及持久化。 |
| ReadOnly | `Written` 與 `Modify` 之外的 tracked 路徑，含共用工具設定。 |
| Written | 同 slug 四份正式規劃檔。在 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/` 新增 `PullRequestChecks.graphql`、`GitHubPullRequestChecksSource.swift` 及 `Generated/` 的必要產碼，於 `Tests/RivetPRReaderGitHubTests/` 新增 `GitHubPullRequestChecksSourceTests.swift`。 |
| Deleted | 無。 |
| Modify | 既有 `apollo-codegen-config.json` 的 operation 清單僅追加新檔。`Package.swift` 僅將新的原始 `.graphql` 納入 exclude。既有生成檔僅納入可重生的 Checks 相關差異。驗收後回寫 `docs/architecture/bounded-contexts/pr-reader.md`。 |
| Goal | 套件 Caller 取得完整有序的 Checks、合法缺席或單一 Reader failure。 |
| Non-Goal | 提供 Check ID、詳情 URL、產品入口或部分結果。 |
| TestCase | CK01 入口與映射、CK02 分頁與歸屬、CK03 失敗與取消、CK04 產碼與回歸。 |

## 產品驗收

- **CK01** 以正常套件入口讀取受控 GraphQL 回應，核對請求變數、單頁、兩種明細、合法缺值、無 rollup 與有狀態的空明細。
- **CK02** 核對多頁 `after`、原序與同名異 ID。涵蓋 head、rollup、state、總數或定位變更、重複 ID、游標缺失／空白／停滯／循環、rollup 續頁消失、空續頁及末頁筆數不符。無效游標須停止發出請求。
- **CK03** 涵蓋無效輸入零請求、定位缺席與明確拒絕、Checks 欄位拒絕、partial／errors-only、無法映射、解碼及傳輸失敗。驗證首請求前、累積明細後及回應晚到時的取消，皆只交付單一失敗。
- **CK04** 先以固定基線的 SDL、Apollo 2.1.2 與既有 `ReviewThreads.graphql` 驗證離線重生。加入 `PullRequestChecks.graphql` 後，以同一清潔輸出程序從同一 SDL 和兩份 `.graphql` 一併離線重生，確認既有 `reviewThreads` operations 保留，生成差異可重現且屬 Checks 範圍。執行 `swift test --filter 'RivetPRReaderGitHubTests|RivetPRReaderTests|GitHubIntegrationTests'`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 和 `git diff --check`。Reviewer 核對 staged、unstaged 及允許新增檔的完整差異。

## 本機輔助審閱

Implementer 產出本機證據。Tester 獨立驗證並在帳本登記基線、工具版本、產物及未驗項。Reviewer 核對證據與實際差異。產品驗收以 CK01–CK04 為準。產物只存於 ignored 路徑或 repo 外暫存目錄，留在本機。

| 工具 | 產物與核對 |
| --- | --- |
| Archify | 在 `.build/topic-evidence/pr-reader-github-checks-source/archify/` 產出繁中 sequence，viewer 採英文。`validate`、`deliver` 須達 showcase 9/9、零 errors／warnings。`visual-check` 核對四種尺寸，另目視最小及最大尺寸的亮暗畫面。 |
| PR Lens | 固定 `0.11.0`，在 repo 外暫存目錄以實際 base 與本題 diff 製圖，納入允許新增及相關的未變更節點。採可用的 repo overlay，查無適用設定時用 `--no-config`。執行 validate 與 light render，核對 manifest 和 SVG。條件式授權下提交後核對實際 base／head。 |
| Graphify | 固定 `0.9.73`，每次設 `GRAPHIFY_NO_AUTO_REFRESH=1`。僅查可追溯至受查版本的既有圖，並覆核原碼。初查未見 repo 預設圖，採 `rg` 與原碼查證，不另建圖。 |
| Show Me | 在帳本記錄簡短 call tree。Tester 核對 `fetchChecks`、定位與逐頁驗證，以及原序完整結果、合法缺席或單一 failure，並對照受控請求。 |
| Floorplan | 將現有 ignored Floorplan 複製至獨立 worktree 再 refresh。保留筆記與自訂 flows，Recent work 只列本題。核對說明覆蓋率 100% 及本機預覽，記錄高嚴重度發現與未覆蓋檢查。 |

工具受限時，帳本記錄原因及替代核對。Archify 以原碼和受控請求核對 sequence，PR Lens 逐檔核對完整 diff，Graphify 以 `rg` 和原碼查證，Floorplan 靜態核對 HTML 與說明覆蓋。視覺或互動項目未驗時另行記錄。

## 交接與停點

獨立 Plan-Reviewer 對實際四檔明示 `approved` 後，依序交 Implementer、Tester、Reviewer。Implementer 在正式產碼與接線前核對固定基線的 SDL、Apollo 2.1.2 及離線重生。若既有 SDL 或產碼流程無法支援 operation，或需調整已確認的契約及 tracked 範圍，停在 Human Check。

產品驗證與獨立成果審查無重大問題，且 staged diff 符合九欄和單一 topic 語意邊界時，Human 已授權依 `git-commit-convention` 先核對 staged diff、提出並記錄訊息，再做單一 commit、推送功能分支及開啟以 `dev` 為目標的 Draft PR。條件未達成時停於提交前。Draft PR 建立並讀回後交還 Human Review。 [步驟帳本](pr-reader-github-checks-source.step.md)
