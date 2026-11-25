# PR Reader 行內審閱留言端點執行計畫

Topic 為 `pr-reader-github-inline-review-comments-endpoint`，分支為 `feat/pr-reader-github-inline-review-comments-endpoint`，沿用近期 Reader 的 `feat/<work-item>` 慣例。執行基線為本機 `origin/dev` 快照 `c9c9f17a0d7732574d25a652ce088c65dcefea06`，包含 #96 與 #98。所有修改在已建立的獨立 feature worktree 進行。 [執行基線](https://github.com/a129924/rivet/commit/c9c9f17a0d7732574d25a652ce088c65dcefea06) · [PR #98](https://github.com/a129924/rivet/pull/98)

## swift-implementation

Implementer 開工前依下列九欄核對工項與檔案。獨立 Reviewer 以實際差異逐欄核對，包含尚未追蹤的新增檔。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | `RivetPRReaderGitHub` 內部 GET 端點、PR 識別與頁碼驗證、同步 URL 建構、離線驗收與 BC 契約回寫。 |
| Out-Of-Scope | REST client 與標頭接線、HTTP 執行、`Link` 與續頁歸屬查核、DTO 與 `PRReaderFailure` 映射、GraphQL 備援、快照、UI、GitHub 寫入及資料遷移。 |
| ReadOnly | `Written` 與 `Modify` 以外的 tracked 檔案，包含 `Package.swift`、既有端點與來源、Reader Core／Port、`GitHubIntegration` 及主工作樹既有變更。 |
| Written | `analysis/pr-reader-github-inline-review-comments-endpoint/requirements.md`、`analysis/pr-reader-github-inline-review-comments-endpoint/technical-spec.md`、`plan/pr-reader-github-inline-review-comments-endpoint/pr-reader-github-inline-review-comments-endpoint.plan.md`、`plan/pr-reader-github-inline-review-comments-endpoint/pr-reader-github-inline-review-comments-endpoint.step.md`、`Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubInlineReviewCommentsEndpoint.swift`、`Tests/RivetPRReaderGitHubTests/GitHubInlineReviewCommentsEndpointTests.swift`。 |
| Deleted | 無。 |
| Modify | 離線驗收後，於 `docs/architecture/bounded-contexts/pr-reader.md` 新增端點與 URL 建構契約。 |
| Goal | 同一端點實例依指定頁碼建構該 PR 的 GitHub.com GET URL。無效識別或非正數頁碼拋出驗證錯誤。 |
| Non-Goal | 完整行內留言清單交由後續 Adapter 里程碑。 |
| TestCase | IC01 方法與分頁 URL。IC02 無效輸入。IC03 Reader 回歸、格式與差異範圍。 |

五項工具產物與證據限本機，使用 feature worktree 的 ignored 目錄或 repo 外暫存目錄。PR 與 commit 的路徑範圍以九欄為準。產品驗收依 IC01–IC03 判定。

## 離線驗收

- **IC01** 以 `Owner-1/Repo.name_2` 的 PR `42` 核對 `.get` 和同一實例的完整首頁 URL `https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=1&per_page=100`、第 2 頁 URL `https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=2&per_page=100`。另驗證第 31 頁和 `Int.max`。
- **IC02** 對 owner 和 repository 分別套用詳情端點的既有無效樣本，涵蓋空值、點路徑、路徑與 URL 分隔字元、百分比編碼、空白、換行和非 ASCII。PR 編號與頁碼各測 `0`、`-1`，均須拋錯。
- **IC03** 執行 `swift test --filter RivetPRReaderGitHubTests`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 和 `git diff --check`。另對尚未追蹤的新增檔核對空白，並確認完整差異符合九欄。

## 五項本機審閱

| 工具 | 輸入、操作和證據 |
| --- | --- |
| Graphify | 使用 `0.9.73`，每次呼叫均設 `GRAPHIFY_NO_AUTO_REFRESH=1`，包含版本核對。只查可追溯到受查版本的既有圖，核對端點及共用 builder 並以原碼覆核，記錄圖的來源版本與結果。若缺圖、版本不符或工具不可用，以 `rg` 與原碼核對並記錄回退結果。 |
| Show Me | 以技術規格的同步呼叫樹對照實際程式碼及 IC01、IC02，記錄頁碼驗證、PR 識別驗證與 URL 建構的順序，以及符合項與差異。 |
| Archify | 以呼叫樹及程式碼製作靜態繁中 sequence，viewer 使用英文，產物放在 ignored `.build/topic-evidence/pr-reader-github-inline-review-comments-endpoint/archify/`。執行 `validate`、`deliver`，記錄 showcase `9/9`、零錯誤與零警告的結果。以 `visual-check --repo-root` 量測四種桌面尺寸，並目視核對最小與最大尺寸的亮暗畫面。環境受限時記錄可得回執及未驗項。 |
| PR Lens | 使用 `0.11.0`，以實際基線及 feature worktree 差異為輸入，涵蓋尚未追蹤的新增檔及有助審閱的相鄰未變節點。只使用適用的既有 overlay，否則用 `--no-config`。在 repo 外暫存目錄執行 `validate`，用亮色主題渲染並核對 graph、SVG 與 manifest。記錄基線與檔案範圍，提交後以實際 base/head 核對本機交付圖。工具受限時逐檔核對實際差異，記錄未產出的證據。 |
| Floorplan | 以主工作樹的既有 ignored map 作 seed，只在 feature worktree 執行 refresh。保留筆記與自訂 flows，依 `NEXT` 補齊相關節點描述，將 Recent work 限於本 topic。Build 後在本機預覽，核對端點、共用驗證與 URL builder 的關係。預覽受限時檢查靜態 HTML，記錄未驗的互動項。 |

Tester 在帳本記錄產品驗收結果及五項工具證據，以 repo 相對路徑記錄 repo 內產物，repo 外產物以名稱及核對結果辨識。記錄任何未驗項。

## 派遣與停點

Plan-Creator 建立四檔後，由獨立 Plan-Reviewer 審查實際文件。取得明示 `approved` 後交 Implementer，依序交獨立 Tester 與獨立 Reviewer。依帳本記錄各步驟的證據與 verdict。

Human 已授權在驗收與獨立成果審查通過、無重大問題且 staged diff 符合九欄時，依 `git-commit-convention` 核對 staged diff 與 commit message，再執行一個 topic commit、推送 feature branch 及開啟以 `dev` 為 base 的 Draft PR。條件不符時停在提交前交還 Human。開啟 Draft PR 後讀回遠端狀態，停在 Human Review。

[需求](../../analysis/pr-reader-github-inline-review-comments-endpoint/requirements.md) · [技術規格](../../analysis/pr-reader-github-inline-review-comments-endpoint/technical-spec.md) · [步驟帳本](pr-reader-github-inline-review-comments-endpoint.step.md)
