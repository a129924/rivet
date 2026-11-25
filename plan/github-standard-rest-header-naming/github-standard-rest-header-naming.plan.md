# 標準 REST 標頭命名執行計畫

Topic `github-standard-rest-header-naming`。獨立分支 `refactor/github-standard-rest-header-naming`，基線 `dev` `7a283f8dbf1f6c1d84e5b1013c8f7663c5abb500`，已核對遠端 `dev` 同一 SHA。 [需求](../../analysis/github-standard-rest-header-naming/requirements.md) · [技術規格](../../analysis/github-standard-rest-header-naming/technical-spec.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | Provider 與 Factory 的標準組合成員、tuple label、區域值、私有欄位、初始化標籤和相關引用對齊 `standardREST`，執行既有離線驗收並回寫固定標頭文件。 |
| Out-Of-Scope | PR 清單 Endpoint、adapter、專用標頭、API 版本升級、OAuth 授權流程、替代媒體型別、條件式標頭與 304 處理。 |
| ReadOnly | 其餘既有 tracked 檔案，包括呼叫端、配置、測試、舊 topic 文件及 `dev` 工作樹的既有實驗變更。 |
| Written | `analysis/github-standard-rest-header-naming/requirements.md`、`analysis/github-standard-rest-header-naming/technical-spec.md`、`plan/github-standard-rest-header-naming/github-standard-rest-header-naming.plan.md`、`plan/github-standard-rest-header-naming/github-standard-rest-header-naming.step.md`。 |
| Deleted | 無檔案刪除。 |
| Modify | `Sources/BoundedContexts/GitHubIntegration/Providers/HeadersProvider.swift`、`Sources/BoundedContexts/GitHubIntegration/Composition/GitHubHeadersFactory.swift`、`docs/architecture/github-oauth-dual-client.md` 的「固定請求標頭」一節。 |
| Goal | 透過既有 `GitHubHeadersFactory.standard` 與 `GitHubHeaderRequirement.standardREST` 取得等價標頭，三組輸出與錯誤契約均通過驗收。 |
| Non-Goal | 新增套件介面、資料遷移、真人 OAuth 或 GitHub live 驗收。 |
| TestCase | TC01–TC03 依下列既有測試在基線與 topic 驗證。 |

## 驗收

- TC01。Inbox 與 Reader 的標準組合含 `Accept: application/vnd.github+json`、`User-Agent: Rivet`、`X-GitHub-Api-Version: 2026-03-10`。Factory 亦驗證空清單、重複需求、注入配置、回傳副本隔離與 `conflictingRESTRequirements`。
- TC02。登入專用 REST 含相同 Accept 與 `User-Agent: RivetLoginRuntime`，省略 API 版本。登入探查沿用 Bearer。
- TC03。OAuth 交換與刷新均有 `Accept: application/json` 及 `Content-Type: application/x-www-form-urlencoded`，兩條請求皆無 Bearer 與 REST API 版本。

獨立 Tester 先在乾淨基線 checkout，再於 topic worktree 執行相同 Swift 指令，另在 topic 執行 `git diff --check`。記錄兩邊的 SHA、指令和結果，依證據區分基線、環境問題及 topic 回歸。原 `dev` worktree 無須切換。

```sh
swift test --filter 'GitHubHeadersFactoryTests|GitHubSelfReviewSourceTests|GitHubPullRequestBackgroundSourceTests|GitHubLoginAccountProbeTests|GitHubOAuthCodeExchangerTests|GitHubOAuthHTTPTokenFetcherTests'
git diff --check
```

## 本機審閱證據

| 工具 | 交付 |
| --- | --- |
| Show Me | 對話計畫已呈現預期名稱差異。N03 核對兩檔實際引用。 |
| Graphify `0.9.73` | N03 以限定 `rg` 查證。執行時若已有可追溯的 graph，以 `GRAPHIFY_NO_AUTO_REFRESH=1` 及 1500 查詢預算檢視，再核對來源。 |
| Archify | N03 在 repo 外 topic 暫存目錄畫既有 REST 選擇及互斥錯誤的繁中 sequence，檢視器採英文。N04 記錄 showcase 9/9、零錯誤與警告、`deliver` receipt、四尺寸 `visual-check` 與最小、最大尺寸的明暗截圖目視。以暫存根作 `--repo-root`，尺寸採 1440×900、1600×1000、1920×1080、2048×1320。 |
| PR Lens `0.11.0` | N05 直接審查限定 diff。具備符合 schema 的真實相異 base／head SHA 且 runtime 可用時，在 repo 外 topic 暫存目錄執行 validate／render。有 overlay 時沿用，缺少 overlay 時使用 `--no-config`。N06 使用正常交付流程形成的 topic commit。缺少有效 provenance 或 runtime 時記 pending。 |
| Floorplan | N03 複製既有 ignored map 至 topic worktree 的 ignored `floorplan/`，保留原圖與既有 custom flows。於副本依 refresh、NEXT、topic recent、build 更新，透過靜態頁或合規本機 viewer 核對。 |

工具狀態和缺口分別記錄。工具產物限本機暫存或 ignored 副本，Swift 驗收及獨立審查依既有流程。

## 派遣與交付

正式四檔由獨立 Plan-Reviewer 審查，明示 `approved` 後交 Implementer，再交獨立 Tester 與 Reviewer。Reviewer 審查通過且無重大問題才進入 N06。提交前依 `git-commit-convention` 檢查實際 staged diff，記錄範圍、單一語意邊界與建議訊息。符合人類預先確認的單一 topic 和驗收條件時，以一次 commit 推送 feature branch 並開一個以 `dev` 為目標的 Draft PR，讀回狀態，停在 Human review。範圍混入其他工作、驗收阻塞、重大問題或需拆分時，停在提交前交還 Human。 [步驟帳本](github-standard-rest-header-naming.step.md)
