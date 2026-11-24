# GitHub OAuth Endpoint 實例化執行計畫

Topic `github-oauth-endpoint-instances`，規劃基線為本地 `dev` 的 `c389454`。使用 `refactor/github-oauth-endpoint-instances` 分支與獨立 feature worktree。分支符合 `git-branch-naming` 的 `<type>/<work-item>` 慣例，Git ref 格式已核對。原 worktree 的 `experiments/README.md` 與 `experiments/VALIDATION-SUMMARY.md` 既有修改留在原處。

使用者已確認 Endpoint 只提供固定 URL。依技術規格定義兩個模組內不可變實例並接入三處。授權 session 讀取授權實例，交換與刷新共用 token 實例。沿用現有 OAuth API、GET／POST、標頭、表單、結果和安全行為。

[需求](../../analysis/github-oauth-endpoint-instances/requirements.md) · [技術規格](../../analysis/github-oauth-endpoint-instances/technical-spec.md) · [步驟帳本](github-oauth-endpoint-instances.step.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 兩個固定 GitHub.com OAuth 目的地、三個正式呼叫點、離線請求與結果回歸、Endpoint 歸屬回寫及本機審閱證據。 |
| Out-Of-Scope | 新增 HeadersProvider 需求、PR Reader diff 標頭、登入 UI、憑證儲存與輪替策略、重試與傳輸政策、GitHub live 驗收。 |
| ReadOnly | 除 `Written`、`Modify` 外所有 tracked 路徑，含既有歷史 topic、`HeadersProvider`、`Package.swift`、靜態隔離測試及原 worktree 的兩份實驗文件。 |
| Written | `analysis/github-oauth-endpoint-instances/requirements.md`、`analysis/github-oauth-endpoint-instances/technical-spec.md`、`plan/github-oauth-endpoint-instances/github-oauth-endpoint-instances.plan.md`、`plan/github-oauth-endpoint-instances/github-oauth-endpoint-instances.step.md`。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/GitHubIntegration/OAuth/` 下的 `GitHubOAuthEndpoints.swift`、`GitHubOAuthAuthorizationSession.swift`、`GitHubOAuthCodeExchanger.swift`、`GitHubOAuthHTTPTokenFetcher.swift`。另含 `Tests/GitHubIntegrationTests/` 下的 `GitHubOAuthEndpointsTests.swift`、`GitHubOAuthAuthorizationSessionTests.swift`、`GitHubOAuthCodeExchangerTests.swift`，以及 `docs/architecture/github-first-sign-in.md` 的「責任與契約」段落。 |
| Goal | 三個正式呼叫點從兩個 Endpoint 實例取得目的地，通過離線相容性驗收。 |
| Non-Goal | 公開 Endpoint API、通用 Endpoint 抽象、自訂 OAuth host。 |
| TestCase | TC1 至 TC5。用獨立預期值和合成 fixture，將命令與結果記入 step 帳本。 |

## 離線驗收

| ID | 驗收條件 |
| --- | --- |
| TC1 | `GitHubOAuthEndpointsTests` 比對兩個實例的 `url` 與獨立寫明的固定 HTTPS URL。審查三個正式使用點，確認兩個 token 呼叫點均讀取同一個 `GitHubOAuthEndpoint.token`。 |
| TC2 | `GitHubOAuthAuthorizationSessionTests` 核對完整授權目的地與精確六個 query 項目 `client_id`、`redirect_uri`、`scope=offline_access`、`state`、S256 `code_challenge`、`code_challenge_method=S256`。無效 callback 當下零交換，其後有效 callback 只交換一次。既有拒絕、取消、到期和並行案例須通過。`GitHubLoginOAuthFlowTests` 以替代瀏覽器與 loopback callback 驗證交接。 |
| TC3 | `GitHubOAuthCodeExchangerTests` 透過測試 transport 擷取實際單次 POST，核對完整 token URL、`Accept: application/json`、`Content-Type: application/x-www-form-urlencoded`、無 `Authorization` 與 `X-GitHub-Api-Version`、完整百分比編碼的 `client_id`、`client_secret`、`code`、`redirect_uri`、`code_verifier` 及成功憑證。非 2xx 與帶 OAuth error 的 200 均回 `.exchangeRejected`，畸形成功回應回 `.invalidTokenResponse`。送出前取消回 `.cancelled` 且傳輸零次。 |
| TC4 | 沿用 `GitHubOAuthHTTPTokenFetcherTests` 與 `OAuthClassifiedProviderTests`，核對相同 token URL、單次 POST、同組標頭、完整編碼的 `client_id`、`client_secret`、`grant_type=refresh_token`、`refresh_token` 表單、成功輪替、遠端拒絕分類、送出前取消零次及送出後取消一次。 |
| TC5 | 執行 OAuth 工廠、靜態隔離、格式及 lint 檢查。核對限定差異、既有套件依賴與 import 規則。 |

```sh
swift test --filter 'GitHubOAuthEndpointsTests|GitHubOAuthAuthorizationSessionTests|GitHubLoginOAuthFlowTests|GitHubOAuthCodeExchangerTests|GitHubOAuthHTTPTokenFetcherTests|OAuthClassifiedProviderTests|GitHubOAuthFactoryTests|StaticIsolationTests'
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
git diff --check
```

## 本機審閱證據

| 工具 | 操作與證據 |
| --- | --- |
| Show Me | 對話內的規劃 call tree 已呈現瀏覽器 GET 經授權實例組出 URL，交換與刷新各自用 POST 並共用 token 實例，兩組表單各自組裝，標頭共用 `HeadersProvider.oauthToken.headers`。 |
| Archify | 受限 Swift 測試通過後，依實際接線產出繁中 sequence，呈現三條請求路徑、token 目的地共用及結果與取消分支。固定 Viewer 採英文。使用 showcase 9/9、零錯誤與警告、`deliver` 收據、使用 `--repo-root` 的四尺寸 `visual-check` 及明暗目視。成果留在 feature worktree 的 ignored `.build/topic-evidence/github-oauth-endpoint-instances/archify/`。 |
| PR Lens | 沿用 `0.11.0`。執行時查核 `.github/pr-lens.yml`，有則使用既有 overlay，無則用 `--no-config`。有真實且不同、可對應本題的 base／head 時，在 repo 外本題暫存目錄依實際差異與來源連結驗證和渲染。尚未提交時直接審閱含新增檔的限定差異，待有可比對的 revision 再製圖。 |
| Graphify | 沿用 `0.9.73`，只查與受查 revision 相符的既有圖。每次執行設 `GRAPHIFY_NO_AUTO_REFRESH=1`，查詢 budget 1500，並核實原始碼。規劃時無可用圖，執行時若仍無相符圖，以限定 `rg` 查證。 |
| Floorplan | 從既有 ignored map 建立 feature worktree 的 ignored `floorplan/` 副本。規劃時 seed 為 536 檔、62 節點，revision 較舊。保留原圖、自訂流程與既有配置。依 `refresh`、`NEXT` 和 spec 更新描述，Recent work 只標本題，完成 `build` 與 `open`。若預覽受限，驗證靜態 HTML 並記錄預覽待驗。 |

工具與預覽結果分別記錄。程式驗收依 TC1 至 TC5，受限的工具項目列為待驗。本機產物留在上述忽略目錄或 repo 外暫存目錄，版本控管範圍以九欄表為準。PR Lens 在本題單一 commit 形成真實 head 後可補充，證據記入交付回報。

## 審查與交付

獨立 Plan-Reviewer 審查正式四檔並明示 `approved` 後交 Implementer。接著由獨立 Tester 驗證、Reviewer 審查程式、文件與驗收證據。對話版審閱與正式四檔審查各自記錄。若需要變更 OAuth 安全行為、公開 API、標頭契約或約定路徑，帶具體差異停在 Human Check。

使用者已確認在獨立驗證與審查無重大問題、staged diff 範圍相符且為單一語意 topic 時，可以執行一個 commit、推送 feature branch，並開立目標分支為 `dev` 的 Draft PR。提交前依 `git-commit-convention` 核對完整 staged diff 及記錄建議訊息，依該條件使用既有確認。若語意需拆分、差異超出 allowlist 或有重大問題，在提交前交由 Human 決定。條件成立時完成交付並讀回 Draft PR 狀態，停在 Human review。
