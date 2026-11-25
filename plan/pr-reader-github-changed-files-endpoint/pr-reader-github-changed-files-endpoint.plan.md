# PR Reader GitHub 變更檔案端點執行計畫

Topic 為 `pr-reader-github-changed-files-endpoint`。核對後的執行基線為 `dev` `47e4b45983df38ee9a5e2784cf7aceb25a75b2f9`。依 `git-branch-naming` 與 repo 的 `<type>/<work-item>` 慣例，分支為 `feat/pr-reader-github-changed-files-endpoint`，在獨立 feature worktree 執行。主工作樹的兩份既有實驗文件留在原處。

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 在既有 `RivetPRReaderGitHub` target 新增 internal endpoint，驗證 PR 識別與頁碼、組裝 URL，並新增離線單元測試。 |
| Out-Of-Scope | 讀取 adapter、REST client 接線、標頭、`Link`、3,000 檔完整性、DTO、`ReaderFile`、Reader failure、清單組裝與 UI。 |
| ReadOnly | 既有 tracked 檔案，含 #84 詳情端點、`Package.swift` 與長期文件。 |
| Written | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestChangedFilesEndpoint.swift`、`Tests/RivetPRReaderGitHubTests/GitHubPullRequestChangedFilesEndpointTests.swift`、`analysis/pr-reader-github-changed-files-endpoint/requirements.md`、`analysis/pr-reader-github-changed-files-endpoint/technical-spec.md` 與本 topic 的 `.plan.md`、`.step.md`。 |
| Deleted | 無。 |
| Modify | 無。 |
| Goal | 同一端點實例持有指定 `ReaderPullRequestID`，每次呼叫依當次頁碼產生 GitHub Changed Files GET URL。 |
| Non-Goal | 取得指定 PR 的變更檔案清單。 |
| TestCase | CF01 同一實例產生不同頁碼的 URL，CF02 驗證失敗，CF03 #84 回歸與專案檢查。 |

## 產品驗收

- **CF01** 以 `Owner-1/Repo.name_2`、PR `42` 建立一個實例並驗證 `.get`。用獨立字面值核對 `makeURL()` 結果為 `https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/files?page=1&per_page=100`，並以同一實例呼叫 `makeURL(page: 2)`，結果為 `https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/files?page=2&per_page=100`。另以參數化測試驗證顯式頁碼 `31` 與 `Int.max`。
- **CF02** 沿用 #84 的無效 owner／repository 樣本覆蓋兩欄位，確認零或負 PR 編號，以及零或負頁碼均拋錯。
- **CF03** 執行 `swift test --filter RivetPRReaderGitHubTests` 涵蓋新端點和 #84，再執行 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`。

## 本機交接與驗證

| 工具 | 執行與證據 |
| --- | --- |
| Graphify 0.9.73 | 實作前僅使用可追溯到受查 revision 的既有 `graphify-out/graph.json` 做限域查詢，並對照來源。查證時缺圖，以 `rg` 和原碼驗證 #84 詳情端點及 `GitHubRESTDestination`。每次 CLI 呼叫均設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。 |
| PR Lens 0.11.0 | 實作後使用核定基線與實際 worktree 的限域 diff，包含未追蹤新增檔。記錄基線 SHA、worktree 來源及檔案範圍。可於 stage 或 commit 前完成。在 repo 外暫存目錄 `validate`、`render` 並核對 manifest 和實際 diff。查證時無 overlay，使用 `--no-config`，有適用的既有 `.github/pr-lens.yml` 才套用。 |
| Archify | 在 worktree 的 ignored `.build/topic-evidence/pr-reader-github-changed-files-endpoint/archify/` 交付繁中 sequence、英文 viewer。呈現 `init(id:)` 固定 PR 識別、同步 `makeURL(page:)` 驗證頁碼、#84 驗證識別與組裝目的地。以 `deliver` 通過 showcase 9/9、零錯誤與零警告，執行 `visual-check --repo-root` 四種桌面尺寸量測，目視核對擷取畫面並記錄相對路徑證據。 |
| Show Me | 以技術規格的預期呼叫樹交接，實作後對照原碼。 |
| Floorplan | 在獨立 worktree 複用現有 ignored `graph.json`、`architecture.json` 及作者描述作 seed。先 refresh，再完成 `NEXT` 指出的資料與關係，將本 topic 放入 Recent work，build 後本機顯示。若預覽受限，驗證靜態 HTML 並記預覽未驗證。產物存於該 worktree 的 ignored `floorplan/`。 |

本機交接以實際產物、來源及未驗證事項交付。CF01–CF03 是產品驗收證據。產物限本機。

## 派遣與交付

Plan-Creator 完成四份 topic 文件後，交獨立 Plan-Reviewer。獨立 Plan-Reviewer 明示 `approved` 後，依序交 Implementer、Tester、獨立 Reviewer。Tester 提供實際 Swift 驗收與本機交接證據，依步驟帳本追蹤。

Human 已授權在通過驗證與獨立審查、無重大問題且 staged diff 只包含本 topic 授權檔案時，依 `git-commit-convention` 核對 staged diff 與 commit 訊息，提交單一 topic commit，推送 feature branch 並開啟以 `dev` 為 base 的 Draft PR。交付後讀回遠端狀態，停在 Human Review。條件不成立時停在提交前，回報具體差異。

[需求](../../analysis/pr-reader-github-changed-files-endpoint/requirements.md) · [技術規格](../../analysis/pr-reader-github-changed-files-endpoint/technical-spec.md) · [步驟帳本](pr-reader-github-changed-files-endpoint.step.md)
