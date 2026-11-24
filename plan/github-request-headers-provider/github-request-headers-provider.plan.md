# GitHub 請求標頭執行計畫

Topic `github-request-headers-provider`，分支 `feat/github-request-headers-provider`，基線 `dev` `b3e5428`。所有寫入限 feature worktree 及下列範圍。先驗證 REST 標頭核心，再在同一 topic 接入 Inbox、登入探查和 OAuth 兩個 token request。

## swift-implementation

`G` 為 `Sources/BoundedContexts/GitHubIntegration`，`T` 為 `Tests/GitHubIntegrationTests`，`S` 為 topic slug。路徑範圍以 topic 基線分類。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 不可變 Provider 與三個 production 實例、REST Factory 與套件內替代配置、四處既有 request 組裝接線、離線驗證與長期架構回寫。 |
| Out-Of-Scope | Conditional headers、representation、GraphQL/Apollo 組裝、loopback response、REST response classifier、API 版本升級、fixture 遷移、live GitHub 驗證。 |
| ReadOnly | 其餘 tracked files，含 `Package.swift`、Endpoints、`RivetHTTPClient`、OAuth 憑證設定、`GitHubClientScope`、BC Core／Port、GraphQL、fixture 本體、skills、hooks、config 與 dev worktree 的兩份既有 experiment 文件。 |
| Written | `analysis/S/requirements.md`、`analysis/S/technical-spec.md`、`plan/S/S.plan.md`、`plan/S/S.step.md`、`G/Providers/HeadersProvider.swift`、`G/Composition/GitHubHeadersConfiguration.swift`、`G/Composition/GitHubHeadersFactory.swift`、`T/GitHubHeadersFactoryTests.swift`。 |
| Deleted | 無。四處組裝點移除原有 header 組合字面值。 |
| Modify | `Sources/PRInboxGitHub/GitHubSelfReviewSource.swift`、`G/Login/GitHubLoginAccountProbe.swift`、`G/OAuth/GitHubOAuthCodeExchanger.swift`、`G/OAuth/GitHubOAuthHTTPTokenFetcher.swift`、`Tests/RivetPRInboxGitHubTests/GitHubSelfReviewSourceTests.swift`、`T/GitHubLoginAccountProbeTests.swift`、`T/GitHubOAuthCodeExchangerTests.swift`、`T/GitHubOAuthHTTPTokenFetcherTests.swift`、`T/StaticIsolationTests.swift`、`docs/architecture/github-oauth-dual-client.md`、`docs/architecture/README.md`、`docs/design-principles.md`。 |
| Goal | 四條請求路徑保有獨立可驗證的現行標頭。REST 可注入替代配置，需求選擇與衝突結果可重現。 |
| Non-Goal | 公開配置、新產品 composition root、通用合併引擎、Endpoint／client／Scope 的全域自動套用。 |
| TestCase | TC01–TC05，結果記錄於 step，預期值獨立於 production Provider。 |

## 執行及驗證

| ID | 驗收條件 |
| --- | --- |
| TC01 | 接線前完成 `GitHubHeadersFactoryTests`。驗證 production 與替代配置、各欄空白／CR／LF 拒絕、合法值原樣保留。 |
| TC02 | 驗證空、單一、重複需求、兩種排列的 typed 衝突、回傳副本獨立、無 Authorization，以及登入組合無 API 版本。 |
| TC03 | 驗證 Inbox `/user` 與所有搜尋頁共用三欄，登入探查沿用原 Accept、User-Agent 和動態 Bearer，且沒有 API 版本。兩條路徑透過各自的測試注入入口證明替代配置生效。 |
| TC04 | OAuth 交換與刷新分別擷取實際 request，驗證 JSON Accept、form Content-Type、無 Bearer 與 REST API 版本。沿用 fixture。 |
| TC05 | 既有 REST、GraphQL 認證與 LoginService 回歸，精確檔案範圍及靜態隔離。靜態 `expectedPaths` 加入三個 production 檔，既有 `RivetHTTPClient` allowlist 只加入 Provider 與 Factory。 |

先用 `swift test --filter GitHubHeadersFactoryTests` 驗證核心。接線後離線執行下列過濾範圍與 `git diff --check`。完成驗證後回寫三份長期文件，記錄三組固定值的 package 採用狀態。通用自動標頭政策維持 deferred。

```sh
swift test --filter 'GitHubHeadersFactoryTests|GitHubSelfReviewSourceTests|GitHubLoginAccountProbeTests|GitHubLoginServiceTests|GitHubOAuthCodeExchangerTests|GitHubOAuthHTTPTokenFetcherTests|GitHubRestClientTests|GitHubGraphQLAuthorizationTests|StaticIsolationTests'
git diff --check
```

## 本機審閱產出

- **Show Me**。對話內以 call tree 呈現 Inbox 選 standard REST，登入選 login REST 再套用 Bearer，OAuth 交換與刷新共用固定 token 組合。
- **Archify**。Swift 驗證後在 repo 外暫存目錄產出繁中 sequence。依 skill 完成 showcase 9/9、零 errors／warnings、deliver、visual-check 和目視核對。固定檢視器英文。產出留在本機。
- **Graphify**。沿用 pin `0.9.73`。目前無標準 `graphify-out/graph.json`，以限定 `rg` 查證。後續環境若已有版本可核的 graph，每次關閉自動刷新，以 1500 查詢預算檢視 topic，再查原始碼。環境可個別跳過。
- **PR Lens**。沿用 pin `0.11.0` 和可用的既有 overlay。以真實且不同的 base／head 檢視 topic diff，在 repo 外 topic 暫存目錄驗證和渲染。缺少可比較 commits 時直接審查限定 diff，PR Lens 記為 pending。圖面不要求額外 commit 或 PR。
- **Floorplan**。在 feature worktree 用現有 Swift 地圖的副本刷新，保留原圖及 custom flows，依 `NEXT` 和近期卡片建置本機 HTML。本機預覽可用時確認顯示。寫入限 ignored `floorplan/`。工具產出不變更 tracked 檔、hooks 或 config，也不發布。

工具證據分別記錄。Swift 驗收依 TC01–TC05。

## 審閱與交付

四檔由獨立 Plan-Reviewer 審查。經明示核准再交 Implementer，依序交接 Tester 與獨立 Reviewer。使用者已確認實作無重大問題時直接依 topic 提交、推送並開 Draft PR 至 `dev`。提交前仍依 git-commit-convention 核對完整 staged diff 的單一語意邊界並記錄建議 message。若 staged diff 混入其他工作、需要拆分或有重大問題，則事前確認條件不成立，交由 Human 決定。條件成立時完成一個 topic commit、推送及 Draft PR，停在 Human review。

- [技術規格](../../analysis/github-request-headers-provider/technical-spec.md)
- [步驟帳本](github-request-headers-provider.step.md)
