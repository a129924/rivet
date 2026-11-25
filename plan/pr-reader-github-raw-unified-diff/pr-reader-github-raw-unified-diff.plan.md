# PR Reader 單一 PR raw unified diff 執行計畫

Topic 為 `pr-reader-github-raw-unified-diff`。對話查證基線 `d8e2ffed24c64da728cfb394da8d5a521b03642d`，執行基線為 `dev` 的 `612b97ed2ec1344b6bc39eb3b69ff7e245a83742`。依 `git-branch-naming` 及專案的 `<type>/<work-item>` 慣例，使用 `feat/pr-reader-github-raw-unified-diff`，在獨立 feature worktree 執行。兩份既有實驗文件變更留在主工作樹。

標頭屬於 Rivet API Catalog 的 **REST PR Reader → Unified Diff**，對應 GitHub REST **Pull requests → Get a pull request**。 [Rivet API Catalog](../../docs/github-api/rest-pr-reader.md#unified-diff) · [GitHub REST 文件](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 先準備並離線驗證固定 diff 標頭，再在 `RivetPRReaderGitHub` 接入獨立 package Adapter，交付原始 body 或既有 Reader failure。涵蓋受控回歸、長期契約回寫及五項本機審閱交付。 |
| Out-Of-Scope | Diff 解析與渲染、逐檔 patch 補抓、快照與 UI 接線、大型 diff 分段、通用媒體型別框架、live GitHub 驗收與資料遷移。 |
| ReadOnly | `Modify` 以外的既有 tracked 檔案，包含 PR 詳情端點、背景 JSON 來源、Reader Core 與 `PRContentSource`、REST client、共用分類器、`Package.swift` 及主工作樹既有實驗文件。 |
| Written | `analysis/pr-reader-github-raw-unified-diff/requirements.md`、`analysis/pr-reader-github-raw-unified-diff/technical-spec.md`、`plan/pr-reader-github-raw-unified-diff/pr-reader-github-raw-unified-diff.plan.md`、`plan/pr-reader-github-raw-unified-diff/pr-reader-github-raw-unified-diff.step.md`、`Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestUnifiedDiffSource.swift`、`Tests/RivetPRReaderGitHubTests/GitHubPullRequestUnifiedDiffSourceTests.swift`。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/GitHubIntegration/Providers/HeadersProvider.swift`、`Sources/BoundedContexts/GitHubIntegration/Composition/GitHubHeadersFactory.swift`、`Tests/GitHubIntegrationTests/GitHubHeadersFactoryTests.swift`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/github-oauth-dual-client.md` 的固定請求標頭節。 |
| Goal | 給定 `ReaderPullRequestID` 與已授權的 `GitHubRestClient`，套件呼叫端取得指定 PR 的 raw unified diff，成功值與 `HTTPResponse.body` 逐位元組相同，失敗時交付 `PRReaderFailure`。 |
| Non-Goal | 交付完整閱讀快照、diff 檢視或大型 diff 的分段與替代讀取。 |
| TestCase | RD01 標頭組合先行驗證，RD02 同一 PR 的 JSON、diff 與 body 保真，RD03 失敗與取消，RD04 既有行為回歸與專案檢查。 |

## 實作與產品驗收

1. **RD01 先準備並驗證 Headers。** 新增 `.pullRequestUnifiedDiffREST` 並沿用標準 REST 的 User-Agent 與 API 版本。以 `swift test --filter GitHubHeadersFactoryTests` 驗證兩種組合的唯一 `Accept`、標準標頭值、空需求、重複需求及不同組合間衝突。取得並記錄通過證據後才接 Adapter。
2. **RD02 接入獨立 Adapter。** 依 [技術規格](../../analysis/pr-reader-github-raw-unified-diff/technical-spec.md) 使用現有 target、詳情 URL 和 REST client。以受控 client 呼叫同一 PR 的背景與 diff 套件入口，核對相同 GET URL、`nil` body、各自唯一的 `Accept` 及正常背景 JSON 解碼。比對 HTTP `200` 的原始 bytes，包含空 `Data` 與非 UTF-8 位元組。
3. **RD03 驗證 Reader failure。** 以受控回應覆蓋 `406`、權限拒絕、限流、無效識別與取消。無效識別及送出前取消各為零次 GET，等待中取消須捨棄晚到成功回應。依技術規格映射結果。
4. **RD04 回歸與回寫。** 重跑 `RivetPRReaderGitHubTests`、`GitHubHeadersFactoryTests`、`GitHubRestClientTests`，執行 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check`。在兩份長期契約回寫套件入口、媒體型別與 failure 語意，保留 PR #91 與其他相鄰切片的紀錄。

## 本機審閱交付

接線前以 Graphify 或原碼查核依賴。接線及受控驗收後，依序核對 Show Me、交付 Archify、建立 PR Lens、刷新 Floorplan。帳本記錄各項來源版本、產物、驗證證據與實際 fallback。RD01–RD04 為產品驗收，工具產物保留於本機並排除於 tracked 檔案範圍。

| 工具 | 執行、產物與證據 |
| --- | --- |
| Graphify 0.9.73 | 每次 CLI 呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。僅使用可追溯至受查 revision 的 `graphify-out/graph.json` 做限域查詢，並以原碼核對端點、標頭工廠與 REST client。規劃查證時缺圖，採 `rg` 與原碼，記錄 revision、檔案及實際關係。 |
| Show Me | 依實際原碼核對技術規格中的預期呼叫樹。若有出入，以實際呼叫鏈更新本機文字交接，標明對應符號與未驗證分支。 |
| Archify | 在 ignored `.build/topic-evidence/pr-reader-github-raw-unified-diff/archify/` 交付繁中 sequence 及英文 viewer，呈現識別、標頭、GET、`200` bytes、失敗映射與取消。先以 `validate --quality showcase` 檢查候選，再以 `deliver` 取得 showcase 9/9、零錯誤與零警告的回執，以 `visual-check --repo-root` 驗證四種桌面尺寸並目視核對擷取畫面。視覺驗證環境不可用時，保留可取得的 HTML、回執與文字呼叫樹，記錄未驗證項。 |
| PR Lens 0.11.0 | 使用核定基線至實際 worktree 的限域 topic diff，納入新增未追蹤檔。記錄基線 SHA、worktree 來源及檔案範圍，排除主工作樹既有改動。在 repo 外暫存目錄 `validate`、`render --theme light`，逐一核對 graph、SVG、manifest 與實際 diff。只有適用的既有 `.github/pr-lens.yml` 才套用，否則使用 `--no-config`。CLI 無法完成或圖仍有偏差時，保留直接 diff 核對與錯誤紀錄。 |
| Floorplan | 在 feature worktree 的 ignored `floorplan/` 複用既有 `graph.json`、`architecture.json`、作者描述及本機 ignore 設定作為 seed，保留使用者筆記與自訂 flows。seed 基線為 `4955cff`，先執行 `refresh.mjs`，依 `NEXT` 補新來源與標頭關係。以 `recent.mjs` 盤點，Recent work 只記錄本 topic。執行 `build.mjs` 再用 `open.mjs` 預覽。預覽受限時核對靜態 HTML 與 Recent work，記錄互動預覽未驗證。 |

## 派遣與交付

Plan-Creator 建立四份規劃文件，交獨立 Plan-Reviewer。四份檔案取得明示 `approved` 後，由 Implementer 依順序完成實作，Tester 驗證 RD01–RD04 與實際本機證據，再交獨立 Reviewer 審查。

Human 已授權建立並實作本 topic。驗收與獨立審查通過、無重大問題且 staged diff 僅包含核定範圍時，依 `git-commit-convention` 核對單一語意與建議訊息，執行單一 commit、推送 feature branch 並開以 `dev` 為 base 的 Draft PR。條件不成立時停在提交前回報。Draft PR 建立後讀回遠端狀態，停在 Human Review。

[需求](../../analysis/pr-reader-github-raw-unified-diff/requirements.md) · [技術規格](../../analysis/pr-reader-github-raw-unified-diff/technical-spec.md) · [步驟帳本](pr-reader-github-raw-unified-diff.step.md)
