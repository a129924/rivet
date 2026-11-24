# PR Inbox 採用 GitHub REST 回應分類器執行計畫

Topic `github-rest-response-classifier-adoption`，分支 `refactor/github-rest-response-classifier-adoption`，基線 `dev` `909c20c7982fe990b50896e857467ea85acdc773`。使用者已確認依核准的 processed-plan 在獨立 feature worktree 執行。 [需求](../../analysis/github-rest-response-classifier-adoption/requirements.md) · [技術規格](../../analysis/github-rest-response-classifier-adoption/technical-spec.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | Phase A 分類器的最小跨 target 可見性、Inbox 帳號查詢與搜尋各頁的接線、Adapter failure mapping、離線回歸測試及驗證後架構回寫。 |
| Out-Of-Scope | PR Reader 接線、分類規則重設、public API 擴充、Endpoint／headers／DTO／分頁重構、transport、OAuth／credential lifecycle、恢復、重送或取消政策變更。 |
| ReadOnly | 除 Written 與 Modify 外的所有 tracked 檔案，包含 `Package.swift`、Phase A 文件與分類測試、REST client、`experiments/README.md` 及 `experiments/VALIDATION-SUMMARY.md`。保留原 worktree 無關的既有變更。 |
| Written | `analysis/github-rest-response-classifier-adoption/requirements.md`、`analysis/github-rest-response-classifier-adoption/technical-spec.md`、`plan/github-rest-response-classifier-adoption/github-rest-response-classifier-adoption.plan.md`、`plan/github-rest-response-classifier-adoption/github-rest-response-classifier-adoption.step.md`。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/GitHubIntegration/REST/GitHubResponseClassifier.swift` 的可見性與顯式初始化、`Sources/PRInboxGitHub/GitHubSelfReviewSource.swift` 的共用拒絕分支、`Tests/RivetPRInboxGitHubTests/GitHubSelfReviewSourceTests.swift` 的相關回歸測試，以及驗證後 `docs/architecture/README.md` 的架構現況。 |
| Goal | GitHubIntegration 解釋遭拒絕的 REST 回應，Inbox Adapter 將技術分類映射到既有 `.unavailable`。 |
| Non-Goal | 新的 Inbox 業務失敗語意、Reader 403 mapping 或供外部 package 使用的分類器介面。 |
| TestCase | `TC01` 成功與 DTO、`TC02` HTTP 語意與映射、`TC03` 停止條件與部分結果、`TC04` execution errors 與 REST 復原、`TC05` 接線與隔離、`TC06` 完整 Swift 回歸。 |

## 驗收

| 測試 | 驗收結果 |
| --- | --- |
| TC01 | HTTP 200 帳號與搜尋 DTO 正常映射，完整空集合成功。HTTP 200 解碼或既有業務驗證失敗維持 `.unavailable`。 |
| TC02 | 沿用現有 REST stub，驗證 raw 401、403 明確拒絕、明確限流或零剩餘額度、原因不明、404、429、5xx、非預期 2xx／3xx 均映射 `.unavailable`。既有 Phase A tests 覆蓋分類與證據優先序。 |
| TC03 | 帳號查詢遭拒時停止搜尋，後續頁遭拒時捨棄已累積候選。用請求順序與次數確認停止條件與 Adapter 無重送。 |
| TC04 | 重驗認證需求、無效請求、傳輸、憑證生命週期及取消的既有 `.unavailable` 路徑，以及正式 REST client 首次 401 復原與第二次 401 終止。 |
| TC05 | 以受限原始碼與精確 diff 確認共用的非 200 分支確實呼叫分類器、mapping 涵蓋所有 case，HTTP error body 與 rate-limit headers 的解釋由 GitHubIntegration 持有。查核單向依賴、存取修飾與完整允許清單。 |
| TC06 | 先跑 Inbox、Phase A classifier 與 REST client focused tests。再執行根目錄 `swift test`、`scripts/check-github-integration-consumer.sh`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`。 |

## 本機審閱

- Show Me 採技術規格內的 200、非 200、拋錯流程與合成 403。驗證後依受測程式碼核對。
- Archify 以受測 checkout 製作繁體中文 workflow，Viewer 使用英文。使用本機未追蹤輸出，記錄 `showcase` 九項檢查、零錯誤與警告，執行 `deliver` 及四個桌面尺寸的 containment 與目視檢查。保留本機圖與驗證收據。
- PR Lens 使用釘選本機 CLI 0.11.0，依實際 base／head SHA 與 Git diff 產圖，在 repo 外暫存、驗證及渲染。取得實際 commit 前先用受限 diff 核對並記錄待定。提交後沿用適用的既有 overlay，由實際輸出與 manifest 核對差異。
- Graphify 0.9.73 若有可用既有圖，按範圍查詢兩個 target 與呼叫路徑。所有 CLI 呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`，以原始碼驗證結果。現有 checkout 缺圖，採定向原始碼查詢。
- Floorplan 以既有本機地圖刷新受測 checkout，保留既有描述與自訂流程，標記本次 topic 的 Recent Work，完成 build 與本機開啟。記錄實際輸出與可預覽狀態。

本機工件維持未追蹤，工具限制與失敗按實際結果回報。Swift 驗收依 `TC01`–`TC06` 及獨立審查。

## 交付

獨立 Plan-Reviewer 對四份正式文件明示 `approved` 後，依序交 Implementer、Tester 及獨立 Reviewer。驗證後回寫架構現況。交付報告列出修改檔案、`package` 可見性、採用前後映射、重複 helper 基線查核、測試結果、本機審閱證據與延後事項。

人類已明確事前授權，在獨立驗證及審查通過、無重大問題時，依 `git-commit-convention` 查核 staged diff 與記錄建議訊息後，執行一個 topic commit、推送 feature branch、開一個以 `dev` 為目標的 Draft PR。遇重大問題、混入無關變更、需要拆分或獨立審查未核准時停於提交／發布前。Draft PR 交付後停在 Human review，合併與 release 另由人類決定。
