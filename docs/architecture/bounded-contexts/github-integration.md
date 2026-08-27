# GitHub Integration

## 責任

GitHub Integration 是 Supporting BC，隔離 GitHub.com 的身分、外部資料、協定與 infrastructure failure，並為 PR Inbox 與 PR Reader 的內部 Port 提供轉換後的資料。

## 非責任

- 不定義 PR Inbox 的待審閱規則或 PR Reader 的閱讀模型。
- 不讓 GitHub DTO、HTTP status、token 或 OAuth 細節進入核心 BC。
- 不因為 OAuth 存在而過早形成獨立 Auth BC。

## 核心概念與互動

- 未來 Inbox 可使用 GitHub GraphQL 取得直接 review request；Reader 可使用 REST 取得單一 PR 閱讀資料。
- OAuth、Keychain、網路與 GitHub API 屬於 Outside；Adapter 在此 BC 邊界轉換外部協定與資料。
- PR Inbox 與 PR Reader 各自經由自己的 Port 取得轉換後資料，彼此不直接相依。

## Failure Contract

Integration 負責在 Adapter 邊界分類與正規化外部失敗；無法安全分類時產生 `InfraUnknownError`。核心 BC 再將其轉譯為各自的 failure contract。

## 延後能力

多帳號、GitHub Enterprise、跨裝置同步、雲端 backend 與公開發布需求均不屬於目前 Integration 範圍。
