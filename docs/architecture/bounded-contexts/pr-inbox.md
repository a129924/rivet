# PR Inbox

## 責任

定義目前明確要求使用者 review 的 GitHub.com open Pull Request，並提供列表、排序與重新整理所需的語意資料。

- 暫定 source location：`Sources/BoundedContexts/PRInbox/`；此位置不代表 target、module、dependency 或 contract。
## 非責任

- 不讀取單一 PR 的完整背景、討論、checks、檔案或 diff。
- 不擁有目前選取的 PR；那是 Presentation Session 的狀態。
- 不處理 review 寫入、通知、team review request、Repository Catalog 或 GitHub 外部協定細節。

## 核心概念與互動

- 核心集合是「open 且明確要求目前使用者 review」的 PR；具體排序策略留待正式產品 topic 分析後定義。
- 空佇列是成功結果，不是 failure。
- PR Inbox 透過自己擁有的 Port 取得資料；它不直接依賴 PR Reader。
- 對 Presentation 提供穩定的 Inbox Facade；Presentation Session 可在重新整理後保留目前選取狀態。

## Failure Contract

PR Inbox 只對外表達自身語意，例如待審閱佇列暫時不可取得；不得洩漏 GitHub DTO、HTTP status 或 `InfraUnknownError`。

## 延後能力

team review request、通知、repository 瀏覽、快取與同步不屬於目前 PR Inbox。
