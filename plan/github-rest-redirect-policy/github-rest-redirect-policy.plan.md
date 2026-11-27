# GitHub REST 預設重新導向政策執行計畫

Topic `github-rest-redirect-policy`，分支 `refactor/github-rest-redirect-policy`，獨立 feature worktree 基線 `dev` `3468eaa`。人類已接受對話版並授權受限實作及交付。 [需求](../../analysis/github-rest-redirect-policy/requirements.md) · [技術規格](../../analysis/github-rest-redirect-policy/technical-spec.md) · [執行帳本](github-rest-redirect-policy.step.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | REST 重新導向 policy、拒絕預設與 Foundation delegate 集中於新 Swift 檔，既有 `makeSession` 注入預設，補離線回歸與長期契約。 |
| Out-Of-Scope | GraphQL、OAuth token exchange／refresh、通用 `RivetHTTPClient`、各 Bounded Context 的錯誤映射、其他 topic 及 release。 |
| ReadOnly | 除 Written 與 Modify 外的 tracked 檔案。包括 `Package.swift`、`Sources/BoundedContexts/GitHubIntegration/REST/GitHubResponseClassifier.swift`、`Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginAccountProbe.swift`、`Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift`、`Tests/GitHubIntegrationTests/REST/GitHubResponseClassifierTests.swift` 和既有 experiments 變更。 |
| Written | `analysis/github-rest-redirect-policy/requirements.md`、`analysis/github-rest-redirect-policy/technical-spec.md`、`plan/github-rest-redirect-policy/github-rest-redirect-policy.plan.md`、`plan/github-rest-redirect-policy/github-rest-redirect-policy.step.md`、`Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPRedirectDelegate.swift`。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClient.swift` 注入預設並移除原 blocker 宣告。更新 `Tests/GitHubIntegrationTests/REST/GitHubHTTPTransportTests.swift`。在 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `expectedPaths` 僅加入 `REST/GitHubHTTPRedirectDelegate.swift`，保留集合相等與匯入檢查。回寫 `docs/architecture/github-oauth-dual-client.md` 的既有 REST 段落。 |
| Goal | 明確分開判斷、Foundation 轉譯和預設接線。保留 raw 302、單次發送與既有 401 復原上限。 |
| Non-Goal | 通用重送政策、正式允許重新導向的政策、外部配置、public 或 package 介面變更。 |
| TestCase | TC01 政策決策、TC02 delegate 轉譯、TC03 預設接線、TC04 原始回應、TC05 認證復原、TC06 受限差異和離線 suite。 |

預計新增 5 檔、修改 4 檔、刪除 0 檔，共 9 檔。工作僅在指定 feature worktree 進行。原工作樹的 `experiments/README.md` 與 `experiments/VALIDATION-SUMMARY.md` 既有改動屬其他工作。

## 驗收

| ID | 完成條件 |
| --- | --- |
| TC01 | 直接驗證預設 policy 對同主機 302、跨主機 302 與 307 都回傳 `false`。 |
| TC02 | 以 `true` 和 `false` 的受控 policy 驗證 delegate 交付原 response 與 proposed request，並且以原樣 proposed request 或 `nil` 各回呼恰一次。 |
| TC03 | 直接檢查 production `makeSession()` 的 delegate，使用合成重新導向驗證接線已採拒絕預設。 |
| TC04 | 既有 `URLProtocol` fixture 由共用 REST factory 回傳原始 302、`Location` 及非空合成 body，記錄原 URL 一次發送。 |
| TC05 | 沿用 OAuth REST suite，首次 302 維持原回應、發送一次及零次 refresh。401→200 和 401→401 維持至多一次重送。 |
| TC06 | 執行 `swift test --filter GitHubIntegrationTests`、`git diff --check`，依基線核對檔案與 package/API 影響。靜態隔離測試確認來源清單與實際來源完全相等，並維持既有匯入限制。測試使用離線 fixtures。 |

## 本機審閱

- Show Me 沿用技術規格的呼叫樹，以實際實作核對判斷及 callback 分工。
- Archify 依實際接線製作繁中短序列，在 topic 專屬 repo 外暫存目錄驗證並輸出，按實際結果記錄驗證狀態。
- PR Lens 0.11.0 以實際 base/head 或受限 diff 為來源，在同一 topic 的 repo 外暫存目錄本機 `validate` 與 `render --no-config`，記錄來源與本機結果。
- Graphify 查找與基線相符的既有圖。若存在，以限定結果查原始碼並設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。目前缺圖，實作採 `rg` 核對接線。
- Floorplan 只讀既有忽略的 `floorplan/index.html` 定位。地圖基線 `4955cff`，以實作原始碼核對。

本機輔助工件留在 repo 外，工具結果如實回報。Swift 驗收以 TC01–TC06 和獨立審查為準。

## 交付

四份 planning artifacts 由獨立 Plan-Reviewer 明示 `approved` 後，依序由 Implementer、Tester 與獨立 Reviewer 完成實作、驗證及成果審查。計畫或成果需回修時，由產出角色修正，再交相應的獨立角色復核。

獨立驗證與成果審查通過、無重大問題且 staged diff 是單一 topic 時，人類已授權依 `git-commit-convention` 查核 staged diff、提出並記錄訊息後，直接做一個 topic commit、推送 feature branch，再開一個以 `dev` 為目標的 Draft PR，並讀回交付狀態。遇重大問題、差異混入其他工作或審查未核准，停於提交與發布前。Draft PR 交付後停在 Human Review，由人類決定是否合併。
