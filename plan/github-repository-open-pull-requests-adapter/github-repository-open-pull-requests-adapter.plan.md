# 指定 repository 的完整 open PR 清單執行計畫

Topic `github-repository-open-pull-requests-adapter`，執行分支 `feat/github-repository-open-pull-requests-adapter`，整合目標 `dev`。執行前已確認本機和 GitHub `dev` 均為 `d8e2ffed24c64da728cfb394da8d5a521b03642d`，其中 #89 為獨立的 PR Reader Endpoint。所有 tracked 寫入限獨立 feature worktree。 [需求](../../analysis/github-repository-open-pull-requests-adapter/requirements.md) · [技術規格](../../analysis/github-repository-open-pull-requests-adapter/technical-spec.md) · [步驟帳本](github-repository-open-pull-requests-adapter.step.md)

## swift-implementation

| 欄位 | 契約 |
|---|---|
| Goal | 套件內呼叫端以 owner、repository 和已配置的 REST client，一次取得憑證可讀的完整 open PR 摘要，或收到可辨識的整次失敗。 |
| Non-Goal | 提供產品層的 repository 選擇、瀏覽入口或 PR 工作流整合。 |
| In-Scope | 既有 `RivetRepositoryPullRequestsGitHub` 的唯讀查詢、Endpoint 和標頭接線、Link 分頁、摘要與階段式失敗、離線驗收、Catalog 更新及本機工具交接。 |
| Out-Of-Scope | 套件外 API、BC 責任變更、PR Inbox／Reader 或產品 UI 接線、跨 repository 搜尋、closed／merged PR、額外篩選與排序、快取、GitHub 資料寫入、OAuth 變更、即時 GitHub 驗收。 |
| ReadOnly | 其餘 tracked 路徑，包含既有 Endpoint、`Package.swift`、BC、REST client 和標頭程式、`experiments/README.md` 及 `experiments/VALIDATION-SUMMARY.md`。 |
| Written | `analysis/github-repository-open-pull-requests-adapter/requirements.md`<br>`analysis/github-repository-open-pull-requests-adapter/technical-spec.md`<br>`plan/github-repository-open-pull-requests-adapter/github-repository-open-pull-requests-adapter.plan.md`<br>`plan/github-repository-open-pull-requests-adapter/github-repository-open-pull-requests-adapter.step.md`<br>`Sources/RivetRepositoryPullRequestsGitHub/GitHubRepositoryOpenPullRequestsQuery.swift`<br>`Tests/RivetRepositoryPullRequestsGitHubTests/RepositoryOpenPullRequestsQueryTests.swift` |
| Deleted | 無。 |
| Modify | `docs/github-api/rest-inbox-discovery.md` 的 Repository Pull Request List 段落，記錄套件內查詢契約與後續唯讀的產品狀態。 |
| TestCase | TC01 正式入口與 GET。TC02 清單與順序。TC03 分頁範圍。TC04 階段式失敗及取消。TC05 回歸與 diff。 |

## 驗收

| ID | 驗收條件 |
|---|---|
| TC01 | 既有測試 target 以一般 `import` 呼叫正式入口。注入可記錄 `executeGet` 的 actor 替身，核對每頁 GET、HTTPS URL、固定查詢參數、`.standardREST`、無 body 及實際請求數。 |
| TC02 | 受控測試覆蓋有效單頁、空陣列、多頁 Draft 與其他作者、跨頁及頁內順序，以及有效 `Link` 無 `next` 時結束。 |
| TC03 | 同名 Link 和可證明的數字別名成功。實際請求從原 Endpoint 重建。涵蓋錯誤目的地或查詢、重複或跳頁、破損 `Link`、大小寫與關係清單中的 `next`、別名 ID 不符、缺少與衝突證據。核對失敗分類和未送出下一頁。 |
| TC04 | 無效識別回 `.invalidRepository` 且零請求。前頁成功後遇到 HTTP 或解碼失敗，只收到對應的整次失敗。受控請求已取消但回應晚到時，回 `.cancelled` 且不再請求。 |
| TC05 | 執行下列 SwiftPM、格式、lint 與 diff 檢查，記錄基線、工具版本、實際結果與 exit code。 |

```sh
swift test --filter RepositoryOpenPullRequests
swift test --filter StaticIsolationTests
swift test --skip KeychainTokenStoreTests
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
git diff --check
```

回退以 topic 的新增檔與 Catalog 差異為單位。此查詢無資料遷移。

## 本機工具交接

| 工具 | 交付 |
|---|---|
| Archify | 使用 `2.16` 生成繁中 sequence、英文 Viewer，呈現正式入口、同 Endpoint 分頁、尾頁成功與整次失敗。產物放在 ignored 的 `.build/topic-evidence/github-repository-open-pull-requests-adapter/archify/`。記錄 showcase 9/9、零錯誤與警告、`deliver` 和以 `--repo-root` 執行的四尺寸 `visual-check`。另行目視核對，分別記錄自動檢查與目視結果。 |
| PR Lens | 使用 `0.11.0`，在 repo 外暫存目錄 validate 和 render。未提交變更採 `kind: graph`，記錄真實 base 與現有 worktree `HEAD`，兩者可相同。記錄 worktree 的 dirty 狀態與含未追蹤新增檔的實際受限 diff。僅在查證存在兩個不同真實 commit 時採 `kind: patch`。來源無法查證時標為待驗。若有 `.github/pr-lens.yml`，以 `--config` 唯讀使用，否則用 `--no-config`。由發布步驟執行已授權的單一 topic commit。 |
| Graphify | 使用 `0.9.73`，每次指定 `GRAPHIFY_NO_AUTO_REFRESH=1`。只對能證明與受查 revision 相符的既有 graph 做限定唯讀查詢，並回到原始碼核對。規劃時缺少 `graphify-out/graph.json`，以 `rg` 查證。不建立 graph。 |
| Show Me | 以對話的短呼叫樹交接正式入口、GET、next、尾頁和整次失敗。 |
| Floorplan | 現有 ignored map 為 536 檔、62 節點，來源 `4955cff`。若 feature worktree 缺 seed，從主 worktree 複製既有本機 ignored map，保留作者內容、自訂流程和 local ignore。只在 feature worktree refresh，依 `NEXT` 補本 topic target、檔案卡片、依賴說明及 Recent work，build 後以 `open.mjs` 本機預覽。若預覽受限，查核靜態 HTML 並記錄預覽待驗證。 |

```text
fetch(owner:repository:)
├─ Endpoint 拒絕識別 → .invalidRepository
└─ 依 Endpoint 和 .standardREST 送出 GET
   ├─ 請求、回應、分頁或取消失敗 → 回傳整次失敗
   └─ 驗證頁面、累加摘要與檢查 Link
      ├─ 有效 next → 以原 Endpoint 重建下一頁 GET
      └─ 尾頁 → 回傳全部摘要
```

## 審查與發布停點

由獨立 Plan-Reviewer 讀回四件正式文件並明示 `approved`，再依序交 Implementer、Tester 和獨立 Reviewer。規劃與成果有必要修正時，交原產出角色回修並由審查者複核。範圍或鎖定契約需要改變時，停止並交 Human 決策。

Human 已確認本計畫並授權在獨立 feature worktree 實現。驗證與成果審查無重大問題，且 staged diff 符合 topic 語意與範圍時，授權直接提交單一 topic commit、推送 feature branch 並開以 `dev` 為目標的 Draft PR。提交前依 `git-commit-convention` 核對 staged diff 並記錄 commit message。發布條件未滿足時停於提交前。Draft PR 建立後讀回遠端狀態並停止於 Human Review。
