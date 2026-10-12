# Rivet

Rivet 是一個個人 GitHub PR 工作台。

它的首版目標是集中查看目前等待使用者 review 的 GitHub.com open Pull Request，降低在 GitHub 網站、repository 與 PR 之間切換的成本，並成為日常挑選與開啟 PR 的優先入口。

## 成功標準

連續兩週以上，使用者在挑選及開啟待 review PR 時優先使用 Rivet。

## 文件導覽

- [產品規範](docs/product.md)
- [架構規範](docs/architecture/)
- [設計原則](docs/design-principles.md)
- [開發工具鏈](docs/toolchain.md)
- [GitHub PR API Catalog](docs/github-api/)
- [開發分支流程](docs/development-workflow.md)

## 目前狀態

non-BC `GitHubIntegration` 現另提供 internal-only GitHub GraphQL Query foundation：使用 Apollo 2.1.2 與既有 OAuthTokenProvider，僅在 HTTP 401 回報實際 snapshot 並重送原 Query 一次，保留 cancellation 與合法 partial response。此入口不對其他 target 公開；跨 target GraphQL 使用、各 BC adapters、Keychain credential adapter 與初次 OAuth 授權整合 與產品登入仍延後。

Rivet 目前是可公開的 architecture baseline repository。它保留產品與架構決策、Bounded Context Map，以及 Swift／Node 版本基線；root Swift package 已包含受限的產品實作。

目前已實作 non-BC `RivetPresentation` library target 的原生 SwiftUI `PullRequestRow` leaf、display-ready Presentation input，以及組合 Row 的 `PullRequestList`。List 提供 parent-owned 單選、清單焦點、鍵盤選取與安全的 Open PR intent；完整 Inbox 的初次選取與 stale selection fallback、Reader 導覽及 app menu 仍由未來上層整合。該 target 不依賴任何 Bounded Context，也不包含 Domain／Application mapper；後續仍以一次一個 Bounded Context 或 bounded Presentation slice 的節奏推進，並以 `analysis/`、`plan/` 與 `docs/` 的配對文件保留可追溯決策。

GitHubIntegration 已交付 internal `GitHubOAuthHTTPTokenFetcher`，以 generic HTTPClient 執行固定 refresh POST；public `OAuthTokenFetcher.refresh` 使用 typed `OAuthTokenRefreshError`。只有可信純 error 的憑證拒絕映射為 `.authenticationRequired`；設定錯誤維持 `.refresh` 且可再次嘗試。輪替未知與遠端已接受後的 persistence failure 停止該 provider，保留 store。這些 GitHub-specific 分類屬於 GitHubIntegration；通用 HTTPClient 與各 BC 的業務 failure 邊界維持。[完整契約](docs/architecture/github-oauth-dual-client.md)記錄取消與過期行為。
