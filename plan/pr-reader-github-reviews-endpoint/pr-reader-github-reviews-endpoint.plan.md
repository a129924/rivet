# PR Reader 審閱紀錄端點執行計畫

Topic 為 `pr-reader-github-reviews-endpoint`，分支為 `feat/pr-reader-github-reviews-endpoint`。對話查證基線為 `b0ad6974a33cc53112083eefad60504462593d66`。執行基線為 `dev` 與本機 `origin/dev` 共同指向的 `587f7bb91fbe9f056cf72214a9992a1325ffce72`。#94 已合併，所依賴的詳情識別驗證、URL builder 與 target 配置相同。所有檔案修改在獨立 feature worktree 進行。

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | Internal Reviews GET 端點、PR 識別與頁碼驗證、同步 URL 建構、離線測試、BC 契約回寫與五項本機審閱交付。 |
| Out-Of-Scope | Source／Adapter、HTTP 執行、標頭接線、Link 解析、repository 歸屬查核、分頁讀取、DTO、Reader failure、快照組裝、UI、GitHub 寫入與遷移。 |
| ReadOnly | Written 與 Modify 以外的 tracked 檔案，含 Package.swift、既有端點與來源、Reader Core／Port、GitHubIntegration 與 dev worktree 兩份既有實驗文件。 |
| Written | `analysis/pr-reader-github-reviews-endpoint/requirements.md`、`analysis/pr-reader-github-reviews-endpoint/technical-spec.md`、`plan/pr-reader-github-reviews-endpoint/pr-reader-github-reviews-endpoint.plan.md`、`plan/pr-reader-github-reviews-endpoint/pr-reader-github-reviews-endpoint.step.md`、`Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestReviewsEndpoint.swift`、`Tests/RivetPRReaderGitHubTests/GitHubPullRequestReviewsEndpointTests.swift`。 |
| Deleted | 無。 |
| Modify | `docs/architecture/bounded-contexts/pr-reader.md`，驗收後新增端點小節。 |
| Goal | 同一 PR 識別可依當次頁碼產生 GitHub.com Reviews GET URL。無效輸入拋錯。 |
| Non-Goal | 取得審閱紀錄清單或整體審閱結論。 |
| TestCase | RE01 方法、URL 及正頁碼。RE02 無效 PR 識別與非正數頁碼。RE03 Reader REST 回歸、格式與範圍。 |

## 產品驗收

- RE01 以 `Owner-1/Repo.name_2` 的 PR 42 核對 GET 與同一實例的首頁、第 2 頁完整 URL。驗證顯式第 31 頁與 `Int.max`。
- RE02 對 owner 與 repository 分別套用既有詳情端點的無效樣本，涵蓋空值、點路徑、路徑與 URL 分隔字元、百分比編碼、空白、換行及非 ASCII。PR 編號和頁碼各核對零及負數。
- RE03 執行 `swift test --filter RivetPRReaderGitHubTests`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`，並核對包含未追蹤新增檔的差異範圍與空白。

## 本機審閱

- Graphify 0.9.73 每次呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。可追溯圖才使用，缺圖回到 `rg` 和原碼查核。
- Show Me 以技術規格同步呼叫樹對照實際程式碼和測試。
- Archify 交付繁中 sequence、英文 viewer。於 ignored `.build/topic-evidence/pr-reader-github-reviews-endpoint/archify/` 驗證並交付 showcase 9/9、零錯誤及零警告。量測四種桌面尺寸，並目視檢查最小與最大尺寸的亮暗畫面。若環境受限，記錄可得回執與未驗項。
- PR Lens 0.11.0 依實際 feature diff 建圖，含未追蹤新增檔。記錄基線與檔案範圍。於 repo 外暫存目錄 validate、以 light theme render，核對 graph、SVG 與 manifest。僅使用適用的既有 overlay，否則用 `--no-config`。提交後以實際 base/head 核對交付圖。
- Floorplan 以主 worktree 的 ignored 地圖作 seed，僅在 feature worktree refresh。保留筆記與自訂 flows，依 NEXT 補齊描述，將 Recent work 限於本 topic，再 build 與本機預覽。預覽受限時核對靜態 HTML，保留限制說明。

## 派遣與停點

先建立四份規劃文件並取得獨立 Plan-Reviewer 明示 `approved`，之後進行實作、獨立驗證及獨立成果審查。人類已授權在無重大問題且 staged diff 符合九欄範圍時，依 git-commit-convention 提出訊息，執行一個 topic commit，推送 feature branch 並開啟以 `dev` 為 base 的 Draft PR。讀回遠端狀態後交還 Human Review。圖與本機證據限本機。

[需求](../../analysis/pr-reader-github-reviews-endpoint/requirements.md) · [技術規格](../../analysis/pr-reader-github-reviews-endpoint/technical-spec.md) · [步驟帳本](pr-reader-github-reviews-endpoint.step.md)
