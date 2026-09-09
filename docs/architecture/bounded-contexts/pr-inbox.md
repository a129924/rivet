# PR Inbox

## 責任

定義目前明確要求使用者 review 的 GitHub.com open Pull Request，並提供列表、排序與重新整理所需的語意資料。

- `RivetPRInbox` root library target 使用 `Sources/BoundedContexts/PRInbox/`，只提供 target-local `Outcome`、Inbox identity、review-request candidate、`ReviewRequestSource` Port 與 refresh-only Facade；尚未實作外部 GitHub Adapter。
## 非責任

- 不讀取單一 PR 的完整背景、討論、checks、檔案或 diff。
- 不擁有目前選取的 PR；那是 Presentation Session 的狀態。
- 不處理 review 寫入、通知、team review request 或 Repository Catalog。
- Core、UseCase 與 Port 不依賴 GitHub REST／GraphQL、GitHub DTO 或任何 transport。

## 核心概念與互動

- 核心集合是「open 且明確要求目前使用者 review」的 PR；具體排序策略留待正式產品 topic 分析後定義。
- 空佇列是成功結果，不是 failure。
- PR Inbox 透過自己擁有的 Port 取得資料；它不直接依賴 PR Reader。
- 對 Presentation 提供穩定的 Inbox Facade；Presentation Session 可在重新整理後保留目前選取狀態。
- 未來若需 GitHub 資料，GitHub Integration 在其 Supporting BC 邊界隔離外部協定、身分、DTO 與 infrastructure failure，並為 Inbox 自己擁有的 Port 提供轉換後資料；PR Inbox 不直接依賴 PR Reader 或 GitHub 外部協定。

## Failure Contract

PR Inbox 只對外表達自身語意，例如待審閱佇列暫時不可取得；GitHub Integration 不得將 GitHub DTO、HTTP status 或技術層 failure 洩漏至 Inbox core Port，跨越 Port 前必須映射為 Inbox failure contract。

## 延後能力

team review request、通知、repository 瀏覽、快取與同步不屬於目前 PR Inbox。
