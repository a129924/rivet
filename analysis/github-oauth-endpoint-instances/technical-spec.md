# GitHub OAuth Endpoint 實例化技術規格

## 型別與接線

在現有 `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthEndpoints.swift` 定義模組內值型別 `struct GitHubOAuthEndpoint: Sendable`。以私有 initializer 設定不可變的 `let url: URL`，只 import Foundation。由兩個 `static let` 提供固定實例，移除舊的靜態 URL 屬性。兩個 URL 使用 HTTPS 與 `github.com`，基底本身沒有 query 或 fragment。

| 實例 | 固定 URL | 正式使用點 |
| --- | --- | --- |
| `GitHubOAuthEndpoint.authorization` | `https://github.com/login/oauth/authorize` | `GitHubOAuthAuthorizationSession` 以實例的 `url` 為基底組裝既有 query，瀏覽器沿用 GET。 |
| `GitHubOAuthEndpoint.token` | `https://github.com/login/oauth/access_token` | `GitHubOAuthCodeExchanger` 與 `GitHubOAuthHTTPTokenFetcher` 取同一實例的 `url`，各自在現有位置轉為 `HTTPURL`，交由 `httpClient.post`。 |

Endpoint 的唯一資料為固定目的地。公開 OAuth API 與現有呼叫方式沿用基線，既有檔案路徑、SwiftPM graph 與 import 規則是相容性約束。

## 請求與結果契約

- 授權 query 沿用 `client_id`、`redirect_uri`、`scope=offline_access`、`state`、S256 `code_challenge` 及 `code_challenge_method=S256`。Session 負責 state、verifier、callback、單次交換及取消、到期與晚到結果。瀏覽器接收 session 組出的 URL。
- 交換與刷新沿用 `HeadersProvider.oauthToken.headers`，以 JSON Accept 與 form Content-Type 送出，沒有 Authorization 或 GitHub REST API 版本標頭。交換保有五欄 form `client_id`、`client_secret`、`code`、`redirect_uri`、`code_verifier`，刷新保有四欄 form `client_id`、`client_secret`、`grant_type=refresh_token`、`refresh_token`，沿用各自的現行編碼。
- `HTTPURL` 驗證留在原捕捉範圍。交換在建構失敗時先判斷 task 是否取消，已取消回 `.cancelled`，其餘回 `.transport`。刷新建構失敗回 `.knownTechnicalFailure`。兩路徑保留自己的回應解析、取消時點和遠端錯誤分類。交換及刷新各自每次最多傳輸一次，既有 provider 保有輪替責任。

## 長期回寫與回退

在正式 OAuth 文件「責任與契約」段落記錄 BC 外的 `GitHubIntegration` 持有兩個固定 Endpoint，以及交換與刷新共用 token Endpoint。程式、受影響測試與此回寫可隨本題差異一併回退，無資料遷移。

[正式 OAuth 契約](../../docs/architecture/github-first-sign-in.md) · [刷新與取消契約](../../docs/architecture/github-oauth-dual-client.md#更新失敗與取消契約) · [執行計畫](../../plan/github-oauth-endpoint-instances/github-oauth-endpoint-instances.plan.md)
