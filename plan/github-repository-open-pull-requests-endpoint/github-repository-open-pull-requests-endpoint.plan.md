# 指定 repository 的 open PR Endpoint 執行計畫

Topic `github-repository-open-pull-requests-endpoint`。執行分支 `feat/github-repository-open-pull-requests-endpoint`。本機 `dev` 與執行前查證的遠端 `dev` 基線為 `7a283f8dbf1f6c1d84e5b1013c8f7663c5abb500`。整合目標 `dev`。所有寫入限獨立 feature worktree。

## swift-implementation

| 欄位 | 契約 |
|---|---|
| Goal | 在 Swift package 內交付可建立及獨立驗證的 `GET /repos/{owner}/{repo}/pulls` Endpoint。 |
| Non-Goal | 完整 repository PR 清單及產品瀏覽入口。 |
| In-Scope | 專用 SwiftPM target、Endpoint 型別、HTTP method、URL 與輸入驗證、離線測試及 Catalog 更新。 |
| Out-Of-Scope | Headers、Adapter、正式呼叫、REST 發送、Link 分頁、DTO 與清單映射、OAuth、BC 或 UI 擴充、即時 GitHub 驗收。 |
| ReadOnly | 其餘 tracked 路徑，包含並行 Headers 工作線、既有 BC 及主工作樹的 `experiments/README.md`、`experiments/VALIDATION-SUMMARY.md`。 |
| Written | `analysis/github-repository-open-pull-requests-endpoint/requirements.md`<br>`analysis/github-repository-open-pull-requests-endpoint/technical-spec.md`<br>`plan/github-repository-open-pull-requests-endpoint/github-repository-open-pull-requests-endpoint.plan.md`<br>`plan/github-repository-open-pull-requests-endpoint/github-repository-open-pull-requests-endpoint.step.md`<br>`Sources/RivetRepositoryPullRequestsGitHub/GitHubRepositoryOpenPullRequestsEndpoint.swift`<br>`Tests/RivetRepositoryPullRequestsGitHubTests/GitHubRepositoryOpenPullRequestsEndpointTests.swift` |
| Deleted | 無。 |
| Modify | `Package.swift`<br>`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`<br>`docs/github-api/rest-inbox-discovery.md` |
| TestCase | TC01 驗證套件內可見性、GET 與 URL。TC02 驗證無效輸入。TC03 驗證 SwiftPM target graph 及既有 product 集合。TC04 執行 Swift 回歸與 diff 檢查。 |

## 實作與驗收

依技術規格新增正規 target、測試 target 及 Endpoint。擴充 target graph 測試並更新 Catalog 的 Endpoint 記錄。回退 topic 變更即可移除本次交付，沒有資料遷移。

| ID | 驗收條件 |
|---|---|
| TC01 | 使用一般 `import` 從測試 target 建立 Endpoint。以獨立預期值核對 GET、完整 HTTPS URL、大小寫、固定 query、預設第 1 頁以及指定第 2 頁。 |
| TC02 | 對 owner 與 repository 分別覆蓋空值、點段、分隔字元、百分比編碼與空白。頁碼覆蓋 `0`、`-1`。每個無效輸入均拋錯。 |
| TC03 | 更新 `StaticIsolationTests` 的精確 graph，確認正式 target 的兩個直接依賴，測試 target 再依賴被測 target。核對既有 product 集合。 |
| TC04 | 執行下列 SwiftPM、格式、lint 與 diff 檢查，記錄實際輸出與 exit code。 |

```sh
swift test --filter RepositoryOpenPullRequestsEndpointTests
swift test --filter StaticIsolationTests
swift test --skip KeychainTokenStoreTests
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
git diff --check
```

## 本機證據與交接

記錄工具版本、來源基線、實際結果與具體失敗原因。本機產物存於 ignored 或外部暫存路徑。產品驗收以 Swift 測試結果為準。

| 工具 | 交付 |
|---|---|
| Graphify | 沿用 `0.9.73`。只在既有 graph 能證明對應受查 revision 時做小範圍查詢，每次設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。規劃時缺少 `graphify-out/graph.json`，使用限域原始碼查證。 |
| PR Lens | 沿用 `0.11.0`。在 repo 外暫存目錄 validate 與 render 實際受限 diff，記錄 base 與已存在的 head。尚未 commit 時，使用包含新增檔的實際 worktree diff 並記錄未提交狀態。若仍無 `.github/pr-lens.yml`，使用 `--no-config`。 |
| Archify | 使用 `2.16` 產出繁中 sequence、英文 Viewer，呈現 Endpoint 測試建立 `HTTPURL` 及輸入無效時提前拋錯。交付至 `.build/topic-evidence/github-repository-open-pull-requests-endpoint/archify/`，取得 showcase 9/9、零錯誤與警告、deliver、四尺寸 visual-check 和目視核對。使用 `--repo-root` 保持證據中的路徑相對。 |
| Show Me | 以短呼叫樹交接有效輸入與驗證失敗兩條路徑。 |
| Floorplan | 既有 ignored map 有 536 檔、62 節點，來源 `4955cff` 早於基線。若 feature worktree 缺 seed，從主工作樹複製既有 graph、作者內容、自訂流程與 local ignore。只在 feature worktree refresh，依 `NEXT` 補 target、檔案卡片、依賴關係與 Recent work，再 build 並執行 `open.mjs`。若預覽受限，驗證靜態 HTML 並記錄預覽待驗證。 |

```text
RepositoryOpenPullRequestsEndpointTests
└─ makeURL(page:)
   ├─ 有效輸入 → GitHubRESTDestination.makeURL → HTTPURL
   └─ 無效輸入 → 拋出私有驗證錯誤
```

## 審查與交付

四份規劃文件由獨立 Plan-Reviewer 審查。明示 `approved` 後依序交 Implementer、Tester、獨立 Reviewer。範圍或鎖定契約如需改變，停於 Human 決策。

使用者已核准 processed-plan，並授權在上述 feature worktree 落實計畫。若獨立驗證與成果審查無重大問題，且 staged diff 語意單一並符合本 topic，使用者已授權一個 topic commit、push feature branch 與開 Draft PR 至 `dev`。提交前依 git-commit-convention 核對 staged diff 及記錄建議訊息。若條件未滿足，停於提交前交還 Human。Draft PR 建立後讀回遠端狀態，停在 Human Review。

Headers 與 Endpoint 均交付後，再排同一 target 的 Adapter。

- [需求](../../analysis/github-repository-open-pull-requests-endpoint/requirements.md)
- [技術規格](../../analysis/github-repository-open-pull-requests-endpoint/technical-spec.md)
- [步驟帳本](github-repository-open-pull-requests-endpoint.step.md)
