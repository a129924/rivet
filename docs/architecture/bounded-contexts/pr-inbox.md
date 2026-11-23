# PR Inbox

## 責任

提供目前登入帳號自己開的 GitHub.com open PR，供單人開發者在合併前挑選自查。符合條件的 open Draft 也在清單內。

- `RivetPRInbox` 提供 Inbox 值、`SelfReviewSource`、`SelfReviewCandidate` 與既有 refresh-only Facade。組裝端可用 `PRInboxFacade(selfReviewSource:)` 交付自查入口。
- 原直接指派 Port 與 Facade initializer 仍支援既有 caller 與 E019 重現。 [E019 紀錄](../../../experiments/E019/README.md)

## 非責任

- 不讀取單一 PR 的完整背景、討論、checks、檔案或 diff。
- 不擁有目前選取的 PR；那是 Presentation Session 的狀態。
- 不處理 review 寫入、通知、team review request 或 Repository Catalog。
- Core、UseCase 與 Port 不依賴 GitHub REST／GraphQL、GitHub DTO 或任何 transport。

## 核心概念與互動

- 自查候選只包含目前帳號開啟且仍為 open 的 PR。保留來源順序，自查完成狀態與產品排序策略留待後續定義。
- 完整空佇列是成功結果。
- PR Inbox 透過自己擁有的 Port 取得資料；它不直接依賴 PR Reader。
- 對 Presentation 提供穩定的 Inbox Facade；Presentation Session 可在重新整理後保留目前選取狀態。
- Inbox 自有 `RivetPRInboxGitHub` 基礎設施 target 持有 GitHub adapter、endpoint、媒體類型、分頁、DTO 與 failure mapping。它接收既有 GitHub REST client，先讀取 OAuth 登入帳號，再搜尋自己開的 open PR。 [API 規格](../../github-api/rest-inbox-discovery.md)
- non-BC `GitHubIntegration` 提供既有 GitHub REST、GraphQL client 與認證支援。只有 Inbox 基礎設施 target 依賴 GitHub 特定介面。DTO 與技術錯誤在跨過 Port 前轉為 Inbox 語意。
- caller 持有 `GitHubClientScope` 所需的 OAuth provider。Inbox 基礎設施只接收 REST client，憑證生命週期由 `GitHubIntegration` 與 caller 管理。

## Failure Contract

完整空集合為成功。認證、傳輸、DTO 或分頁失敗在跨越 Port 前映射為 `.unavailable`，包含任一頁失敗或搜尋未回傳完整結果。

PR Inbox 只對外表達自身語意，例如待審閱佇列暫時不可取得；其 local Infra GitHub adapter 不得將 GitHub DTO、HTTP status、token 或技術層 failure 洩漏至 Inbox core Port，跨越 Port 前必須映射為 Inbox failure contract。

## 延後能力

team review request、通知、repository 瀏覽、快取與同步不屬於目前 PR Inbox。
