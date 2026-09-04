# GitHub Integration

## 責任

GitHub Integration 是 Supporting BC，隔離 GitHub.com 的身分、外部資料、協定與 infrastructure failure，並為 PR Inbox 與 PR Reader 的內部 Port 提供轉換後的資料。

- 暫定 source location：`Sources/BoundedContexts/GitHubIntegration/`；此位置不代表 target、module、dependency 或 contract。
## 非責任

- 不定義 PR Inbox 的待審閱規則或 PR Reader 的閱讀模型。
- 不讓 GitHub DTO、HTTP status、token 或 OAuth 細節進入核心 BC。
- 不因為 OAuth 存在而過早形成獨立 Auth BC。

## 核心概念與互動

- GitHub 對外 API 的具體選型屬於延後決策；本階段只定義各核心 BC 經由自己擁有的 Port 取得轉換後資料。
- OAuth、Keychain、網路與 GitHub API 屬於 Outside；Adapter 在此 BC 邊界轉換外部協定與資料。
- PR Inbox 與 PR Reader 各自經由自己的 Port 取得轉換後資料，彼此不直接相依。
- `packages/RivetHTTPClient/` 是此 Adapter 可採用的內部 transport foundation，不是新的 Bounded Context；其已驗證 public surface 包含 `HTTPURL`、`HTTPRequest`、`HTTPHeaders`、raw `HTTPResponse` 與 `HTTPClient → Requester → injected Transport` 的最小鏈。`HTTPHeaders` 提供 `HTTPHeaderName` 的九個 lower-case constants（`accept`、`authorization`、`contentType`、`userAgent`、`etag`、`ifNoneMatch`、`location`、`link`、`retryAfter`）、case-insensitive `value(for:)` 與九個對應的 read-only getters；`HTTPResponse` 保留 raw body，並提供顯式 `text(encoding:)` helper。這些便利 API 不使 HTTP、token 或 infrastructure failure 跨越核心 BC Port。
- Endpoint、Base URL、Path 與 Query 的 API domain 組裝責任留在呼叫端或其 domain layer，不由 `RivetHTTPClient` 提供。package 也不提供 concrete transport（包括 `URLSessionTransport`）、實際網路呼叫、retry、token refresh、status validation 或 response decode policy。

## Failure Contract

Integration 負責在 Adapter 邊界分類與正規化外部失敗；無法安全分類時產生 `InfraUnknownError`。實作核心 BC 所擁有 Port 的 Adapter 必須在跨越 Port 前，將外部失敗映射為該 BC 自己的 failure contract；`InfraUnknownError` 不得進入核心 BC。

## 延後能力

多帳號、GitHub Enterprise、跨裝置同步、雲端 backend 與公開發布需求均不屬於目前 Integration 範圍。
