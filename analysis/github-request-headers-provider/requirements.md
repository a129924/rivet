# GitHub 請求標頭需求

Topic `github-request-headers-provider`，調查基線為 `dev` 的 `b3e5428`。依使用者確認的 processed-plan，先驗證標頭核心，再在同一 topic 接入四個現有請求組裝點。

## 問題與範圍

同一組 OAuth token request 標頭在交換和刷新各自定義。兩個 REST 路徑共用 GitHub JSON 媒體類型，但以不同的 User-Agent 或 API 版本表達各自契約。固定標頭集中到一個不可變的 `HeadersProvider` 類別，共有三個 production 實例。套件內的 REST 組合入口可接收替代配置，供離線驗證。

| 基線組裝處 | 現行固定標頭 |
| --- | --- |
| `Sources/PRInboxGitHub/GitHubSelfReviewSource.swift:8`，`/user` 與所有搜尋分頁 | `Accept: application/vnd.github+json`、`User-Agent: Rivet`、`X-GitHub-Api-Version: 2026-03-10` |
| `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginAccountProbe.swift:14`，登入 `/user` | `Accept: application/vnd.github+json`、`User-Agent: RivetLoginRuntime` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthCodeExchanger.swift:47` | `Accept: application/json`、`Content-Type: application/x-www-form-urlencoded` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthHTTPTokenFetcher.swift:75` | 同 OAuth code exchange |

## 驗收

- 現有四條路徑的實際封裝請求攜帶各自既有標頭。Inbox 的所有頁面都使用 Inbox 組合，登入探查以當次 token 產生 Bearer。OAuth 交換與刷新均只套用既有 token 固定組合。
- REST 需求陣列為空時選用 standard 組合，重複需求等同一次。兩種互斥需求同時出現時產生具型別的衝突，結果與順序無關。
- 套件內可注入替代 REST 配置。空白和含 CR 或 LF 的值會被拒絕，其他合法值原樣保存。現有測試 fixtures 與標頭預期值維持獨立。
- 先驗證核心選擇與配置語義，再驗證正式組裝及既有 REST、GraphQL 認證回歸。工具產出有各自的本機驗證證據。

## 延後

待出現實際消費端需求後再決定 conditional headers、representation 選項及疊加優先順序。通用自動標頭政策、public 配置、新 product composition root、API 版本更新和 live GitHub 驗證均留在本 topic 範圍外。既有 `If-None-Match` 型別、Reader catalog 與通用 HTTP defaults 並未提供本次 GitHub REST 組合契約。

## 相關文件

- [技術規格](technical-spec.md)
- [執行計畫](../../plan/github-request-headers-provider/github-request-headers-provider.plan.md)
