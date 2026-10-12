# Rivet 設計原則

## 產品取捨

- Rivet 是個人 GitHub PR 工作台，不是 GitHub 或 Graphite 的完整替代品。
- 先解決「集中挑選並開啟目前等待我 review 的 open PR」，再考慮擴張功能。
- MVP 以唯讀工作流為優先；寫入 review、通知、團隊協作、多帳號與跨裝置同步均須以獨立 topic 重新評估。

## 架構取捨

- 一次只處理一個 Bounded Context；未經 topic 授權，不因為未來可能需要而預先建立 package、module 或抽象層。
- PR Inbox 與 PR Reader 的責任邊界優先於技術框架或目錄便利性；`GitHubIntegration` 是 BC 外的 shared GitHub-specific integration module，不是 Bounded Context。
- 每個 Domain BC 的 Core、UseCase 與 Port 不依賴 GitHub 外部協定或 transport；該 BC 未來自己的 Infra 負責 GitHub adapter、operation／endpoint、endpoint-specific media type、DTO 與 failure mapping。
- 外部 GitHub DTO、HTTP status、OAuth／Keychain 細節與 infrastructure failure 不得洩漏到核心 BC，也不得形成 BC-to-BC compile-time dependency。
- 每個 BC 擁有自己的 failure contract；即使 `GitHubIntegration` 未來對 raw transport 或 GitHub error 作 technical classification，也只有各 BC Infra 可將它映射為該 BC 語意，絕不形成 shared BC failure contract。
- `GitHubIntegration` 是已實作的 non-BC shared GitHub-specific integration module；目前提供既有可注入、同步、typed-throws 的 access-token store/provider contract，以及 public、`Sendable`、async 的 `GitHubAccessTokenProvider` token-acquisition contract。後者尚無 PAT 或 OAuth conformer，且不處理 lifecycle、request、transport、401 recovery 或 retry。同一 target 另已交付 internal-only GraphQL Query foundation；跨 target GraphQL 使用與各 BC adapters 仍延後。GitHub REST raw transport、Keychain credential adapter 與初次 OAuth 授權整合、共通 request headers／API version、pagination、rate limit、一般 retry 與 shared configuration 仍為 deferred capability；未來只有各 BC Infra 可採用跨 target 的 shared technical capability，它不進入 Core、UseCase 或 Port，也不依賴任何 BC。endpoint-specific media type、DTO translation、BC failure mapping 與 business meaning 留在各 BC Infra。
- `GitHubIntegration` 另已交付 OAuth credential lifecycle runtime：adapter-facing `OAuthCredentialStore`／`OAuthTokenFetcher` ports 與 actor-isolated `OAuthTokenProvider` 負責 restore、expiry-first refresh、rotation persistence、snapshot version 與 single-flight。client 只取得 `TokenSnapshot(accessToken, version)`；已交付的 internal GraphQL Query client 重用此 runtime，HTTP 401 分類與 Query 的最多一次 recovery retry 屬於 client，不屬 provider。Keychain credential adapter、REST client、跨 target GraphQL 使用及各 BC adapters 仍延後。
- Presentation Session 是 UI 狀態，不是假裝成 Bounded Context。
- `GitHubIntegration/GraphQL/` 已實作 internal-only Query foundation：concrete client 與 Apollo-bound executor、request-local Bearer、parser 前 HTTP 分類、401-only 一次 recovery、有限 technical outcomes 與取消正規化。它重用現有 provider，不新增 public capability；跨 target 使用及 BC adapters 仍延後。REST、Keychain credential adapter 與初次 OAuth 授權整合、一般 retry／rate limit policy 仍未交付。

## 工作方法

- `analysis/`、`plan/` 與 `docs/` 各有責任：研究、執行契約、長期真相。三者互相連結，但不可互相取代。
- 每個正式 topic 先鎖定範圍與驗收，再開始實作；scope 改變時先回到 analysis 與 plan。
- 架構圖不是裝飾：全景與責任邊界使用 `architecture-canvas`，流程與狀態變化使用 `archify`。
- 文件、圖與程式碼若不一致，優先修正能代表長期真相的文件與圖，再進行實作調整。
- 對上游來源作本地 skill overlay 時，必須清楚記錄 pin 與本地差異；同步上游時重新評估 overlay，不得將本地規則誤稱為 upstream 原文。
- 僅 `sdd-workflow-contract` 定義或理解 SDD；其他 skill 必須以完成自身工作所需的最小輸入、輸出與安全邊界獨立運作，不假設 topic artifacts、phase、verdict 或其他角色職責存在。

GitHubIntegration 已交付 internal `GitHubOAuthHTTPTokenFetcher`，以 generic HTTPClient 執行固定 refresh POST；public `OAuthTokenFetcher.refresh` 使用 typed `OAuthTokenRefreshError`。只有可信純 error 的憑證拒絕映射為 `.authenticationRequired`；設定錯誤維持 `.refresh` 且可再次嘗試。輪替未知與遠端已接受後的 persistence failure 停止該 provider，保留 store。這些 GitHub-specific 分類屬於 GitHubIntegration；通用 HTTPClient 與各 BC 的業務 failure 邊界維持。[完整契約](architecture/github-oauth-dual-client.md)記錄取消與過期行為。
