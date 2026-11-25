# PR Reader GitHub 一般討論留言端點執行計畫

Topic 為 `pr-reader-github-conversation-comments-endpoint`。執行基線為 `dev` 的 `d8e2ffed24c64da728cfb394da8d5a521b03642d`，核對時本地 `origin/dev` 同值且包含 Changed Files #89。依 `git-branch-naming` 與 #84／#89 的 `feat/<work-item>` 慣例，分支為 `feat/pr-reader-github-conversation-comments-endpoint`。在獨立 feature worktree 執行。 [執行基線](https://github.com/a129924/rivet/commit/d8e2ffed24c64da728cfb394da8d5a521b03642d)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 既有 `RivetPRReaderGitHub` target 的 internal GET 端點、Reader Infra 內部共用識別驗證、URL 建構、離線單元測試與 BC 端點能力記錄。 |
| Out-Of-Scope | 讀取 Adapter、HTTP 執行、標頭、`Link`、repository metadata 查核、DTO、Reader failure、快照組裝、UI、寫入與遷移。已確認的數字 repository ID 按需查核屬後續 Adapter。 |
| ReadOnly | 其餘既有 tracked 檔案，包括 `Package.swift`、Reader Core／`PRContentSource`、Background Source、Changed Files、共用 GitHubIntegration／HTTP transport。主工作樹兩份既有實驗文件及 Repository Open Pull Requests Adapter worktree 保留原狀。 |
| Written | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubConversationCommentsEndpoint.swift`、`Tests/RivetPRReaderGitHubTests/GitHubConversationCommentsEndpointTests.swift`，以及本 topic 的 `requirements.md`、`technical-spec.md`、`.plan.md`、`.step.md`。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestDetailEndpoint.swift` 僅提取共用識別檢查，保留既有 URL 和錯誤行為。`docs/architecture/bounded-contexts/pr-reader.md` 記錄 Reader Infra 所擁有的留言端點與 URL 建構能力。 |
| Goal | 同一實例持有一筆 `ReaderPullRequestID`，依當次頁碼同步產生 GitHub.com 一般討論留言 GET URL。 |
| Non-Goal | 取得指定 PR 的一般討論留言清單。 |
| TestCase | CC01 URL 與頁碼，CC02 無效輸入，CC03 既有 Reader 端點回歸與專案檢查。 |

## 產品驗收

- **CC01** 以 `Owner-1/Repo.name_2`、PR `42` 驗證 `.get`。預設首頁用獨立字面值核對 `https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=1&per_page=100`，同一實例第 2 頁核對 `https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=2&per_page=100`。另測顯式第 31 頁及 `Int.max`。
- **CC02** Owner 與 repository 分別套用詳情端點既有無效樣本，涵蓋空值、`.`、`..`、路徑或 URL 分隔字元及百分比編碼。PR 編號或頁碼為零或負數均拋錯。
- **CC03** 執行 `swift test --filter RivetPRReaderGitHubTests`，涵蓋新端點、詳情及 Changed Files，再跑 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`。對未追蹤新增檔補做等效的空白檢查，並核對完整變更符合九欄契約。

## 本機交接與驗證

| 工具 | 執行與證據 |
| --- | --- |
| Graphify `0.9.73` | 每次呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。只查可對應受查版本的既有圖並以原碼覆核。無可用圖時，以 `rg` 和原碼查驗端點及目的地 builder。 |
| Archify | 僅呈現同步 URL 建構的繁中 sequence，viewer 使用英文。以 `deliver` 達成 showcase 9/9、零錯誤與警告，再執行 `visual-check --repo-root` 四種桌面尺寸並目視核對，證據放在 ignored `.build/topic-evidence/pr-reader-github-conversation-comments-endpoint/archify/`。 |
| PR Lens `0.11.0` | 以鎖定基線及實際 worktree 差異呈現限域變更，納入未追蹤新增檔，並核對詳情、Changed Files 與共用 builder 的相鄰行為。以實際 worktree 標示未提交來源。在 repo 外本機暫存目錄 `validate`、`render`，並核對 manifest 和實際 diff。沒有適用 overlay 時使用 `--no-config`。 |
| Show Me | 以技術規格的預期呼叫樹交接，實作後對照原碼，確認同步呼叫與驗證順序。 |
| Floorplan | 以 `4955cff` 的 ignored map（536 檔／62 節點）作 seed，在實作 worktree refresh。依 `NEXT` 補齊描述與關係，將本 topic 放入 Recent work，build 後確認描述完整，以 `open.mjs` 本機顯示。若預覽受限，驗證靜態 HTML 並記錄互動預覽待驗。 |

五項工具的產物與驗證證據限本機交接，產品驗收依 CC01–CC03 的實際結果。

## 派遣與交付

Plan-Creator 建立四份同 slug 文件後，由獨立 Plan-Reviewer 審查實際文件。須取得獨立 Plan-Reviewer 明示 `approved` 才可實作。後續依序交 Implementer、Tester 與獨立 Reviewer，並依[步驟帳本](pr-reader-github-conversation-comments-endpoint.step.md)記錄證據。

Human 已授權在驗證與獨立審查通過、無重大問題且 staged diff 只包含本 topic 授權檔案時，依 `git-commit-convention` 核對 staged diff 的語意邊界並評估 commit message，執行一個 topic commit、推送 feature branch、開啟以 `dev` 為 base 的 Draft PR。條件未達成時停於提交前並回報差異。Draft PR 建立後讀回遠端狀態，停在 Human Review。

[需求](../../analysis/pr-reader-github-conversation-comments-endpoint/requirements.md) · [技術規格](../../analysis/pr-reader-github-conversation-comments-endpoint/technical-spec.md)
