# PR Inbox 自查 REST Endpoint 執行計畫

分支 `refactor/pr-inbox-rest-endpoints`，PR 目標 `dev`，基線 `b7dac7e`。只在 feature worktree 實作。 [技術契約](../../analysis/pr-inbox-rest-endpoints/technical-spec.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 兩支具名 Endpoint、共用 REST 目的地、對應程式與測試及現有契約文件。 |
| Out-Of-Scope | 公開 API、依賴、GraphQL、OAuth 授權／token／callback、Reader、Xcode hosted、真人與實驗。 |
| ReadOnly | `Package.swift`、`packages/RivetHTTPClient/`、`Sources/BoundedContexts/PRInbox/`、`Sources/BoundedContexts/GitHubIntegration/REST/GitHubRestClient.swift`、`Tests/RivetPRInboxTests/StaticIsolationTests.swift`、`Tests/GitHubIntegrationHostedTests/`、`experiments/E020/`。 |
| Written | 同 slug 四份正式文件、技術契約列明的三支 Swift Sources、下列三支直接測試。 |
| Deleted | 無。 |
| Modify | 限下列既有檔案。 |
| Goal | 登入共用帳號 Endpoint，Inbox 交付完整、按來源排序的 open 自查清單，含 Draft 與空集合，任一步失敗為 `.unavailable`。 |
| Non-Goal | 通用 Endpoint framework、重設 client／分頁、自查完成狀態、資料遷移或部署。 |
| TestCase | 獨立 Endpoint method／URL／query、目的地及取 token 前拒絕、redirect、OAuth／PAT probe 後保存、Facade GET override、完整分頁、空集合和失敗映射。 |

新增測試：

- `Tests/GitHubIntegrationTests/REST/Endpoints/GitHubAuthenticatedUserEndpointTests.swift`
- `Tests/RivetPRInboxGitHubTests/Endpoints/GitHubSelfReviewSearchEndpointTests.swift`
- `Tests/GitHubIntegrationTests/REST/GitHubRESTDestinationTests.swift`

既有修改：

- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginAccountProbe.swift`、`Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClient.swift`、`Sources/PRInboxGitHub/GitHubSelfReviewSource.swift`
- `Tests/GitHubIntegrationTests/GitHubLoginAccountProbeTests.swift`、`Tests/GitHubIntegrationTests/GitHubLoginServiceTests.swift`、`Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift`、`Tests/GitHubIntegrationTests/REST/GitHubHTTPTransportTests.swift`
- `Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift`、`Tests/GitHubIntegrationTests/OAuthLocalSignOutTests.swift`、`Tests/GitHubIntegrationTests/GitHubOAuthStartupRestoreTests.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`、`Tests/RivetPRInboxGitHubTests/GitHubSelfReviewSourceTests.swift`
- `docs/architecture/bounded-contexts/pr-inbox.md`、`docs/architecture/github-dual-login-runtime.md`、`docs/architecture/github-oauth-dual-client.md`

一般請求 fixtures 採具名 Endpoint，獨立契約預期、GitHub Link／DTO、raw REST 與故意錯誤的輸入保留獨立資料。離線驗收為 `swift test --skip KeychainTokenStoreTests`、`scripts/check-github-integration-consumer.sh`、`scripts/check-swift-format.sh`、`swiftlint lint --strict` 與 `git diff --check`。

## 本機交付

- Graphify 使用可追溯的既有索引，缺索引時以限域原碼查找。CLI 一律帶 `GRAPHIFY_NO_AUTO_REFRESH=1`。
- PR Lens 0.11.0 使用實際差異，本機 validate/render，沿用適用 overlay。
- Archify 繪繁中 sequence，本機 showcase 9/9、deliver、四尺寸 visual-check 與目視檢查。Viewer 固定介面為英文。
- Show Me 在交接展示兩支 Endpoint 與共用目的地。
- Floorplan 在 feature worktree 刷新既有地圖，依 NEXT 補原碼卡片與連線、Recent work、build、以 open.mjs 展示並記錄本機 URL。受阻時驗證靜態 HTML 或記展示待驗證。產物位於 ignored `floorplan/`。
