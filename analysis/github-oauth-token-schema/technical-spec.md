# GitHub OAuth Token Schema：技術規格

## Boundary

本 topic 的唯一資料流為：GitHub OAuth App token-response JSON → internal `GitHubOAuthTokenResponse` → immutable public `GitHubOAuthCredentialBundle` → future `TokenStore`。DTO 是 wire boundary，不得成為 public API；bundle 是 future persistence／refresh-rotation replacement 的完整 value boundary。refresh runtime 與 store write 尚未實作，但其後的新 bundle 必須完整原子取代舊 bundle。

issuer 僅為 GitHub OAuth App。本 topic 的 bundle 僅代表可 refresh、會過期的 OAuth App credential；不接受 non-expiring response、missing-refresh-token response 或 GHES fallback。

## Public Value Surface

`GitHubAccessToken` 現有 public declaration 已為 `Sendable`，不得修改。新增型別均明示 `Sendable`：

| Type | Visibility | Contract |
| --- | --- | --- |
| `GitHubOAuthRefreshToken` | public | immutable raw-value wrapper；不驗證或 log token format。 |
| `GitHubOAuthTokenType` | public | `String, Decodable, Sendable`；僅 `.bearer`，未知 raw value 用 synthesized `Decodable` failure 拒絕。 |
| `GitHubOAuthCredentialBundle` | public | immutable `Sendable` value；六個 non-optional initializer arguments：access token、refresh token、access-token expiry、refresh-token expiry、token type、`grantedScopes`。 |

bundle 的 scope property 固定命名為 `grantedScopes: String`，保存 OAuth response 原始值，例如 `"repo,gist"`；不建立 scope collection、normalizer、sorter 或 `hasScope(...)`。

## Wire Mapping

`GitHubOAuthTokenResponse` 維持 internal `Decodable`，以 explicit snake-case `CodingKeys` 對應：

| Wire field | Internal value | Bundle value |
| --- | --- | --- |
| `access_token` | `GitHubAccessToken` 或 raw mapping input | access token |
| `token_type` | `GitHubOAuthTokenType` | token type |
| `scope` | `String` | `grantedScopes` |
| `expires_in` | non-optional relative seconds | access-token absolute expiry |
| `refresh_token` | `GitHubOAuthRefreshToken` 或 raw mapping input | refresh token |
| `refresh_token_expires_in` | non-optional relative seconds | refresh-token absolute expiry |

DTO 的 internal `credential(receivedAt:)` 必須接收 caller-supplied `Date`；以該值分別加上兩個 relative seconds，產生 bundle 的兩個 absolute expiry。DTO 與 bundle 都不得將 `receivedAt` 隱式設為現在時間；bundle 不保存 relative seconds。

所有六個 wire fields 皆為 non-optional。缺欄位使用 synthesized `Decodable` failure；unknown `token_type` 同樣使用 `Decodable` failure。不自行補值、轉換為 non-expiring credential、fallback 至 GHES，或以 validation/failure enum 替換 decoding failure。

## Swift Implementation Draft

1. 以 fixed JSON fixture 先建立 decode/mapping red tests；fixture 的 token prefix 分別是 `gho_`、`ghr_`，scope 是 `repo,gist`，relative expiry 為 `28800` 與 `15897600`。
2. 在單一新增 Foundation-only contract source 實作 DTO、public wrappers、token-type enum、bundle 和 `credential(receivedAt:)`。DTO 不得外洩；bundle/public wrappers/enum 均為 `Sendable`。
3. 用固定 receipt time 驗證 exact absolute expiry，並驗證缺少任一必要 field／unknown token type 的 decoding failure。
4. 更新 public consumer fixture 與 static isolation test；consumer 只能編譯 public bundle surface。最後才做最小 architecture writeback，僅記錄已交付 schema/mapping 與 future atomic replacement。

## Forbidden Expansion

不得建立 HTTP request、OAuth fetcher/provider/store、Keychain serialization、refresh or rotation runtime、401 retry、client integration、PAT union、credential migration、async lifecycle 或 error mapping。不得修改 `Package.swift`、現有 access-token store/provider public contract、`RivetHTTPClient`、任何 BC 或 diagram artifact。

## Verification Contract

驗證須涵蓋 focused schema tests、existing static-isolation checks、public consumer fixture、root `swift test` 與 `git diff --check`。測試輸出、assertion message 與文件不得洩漏 fixture token 值。任何需觸及 ReadOnly path 或將 DTO 變為 public 的需求，必須停止並回報 scope gap。
