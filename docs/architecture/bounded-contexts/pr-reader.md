# PR Reader

## 責任

提供閱讀單一 Pull Request 所需的背景、一般討論、review 摘要、inline comment、checks、檔案與 unified diff 資料。

## 非責任

- 不決定 PR 是否屬於待審閱佇列，也不排序 Inbox。
- 不擁有 UI 的選取與切換狀態。
- 不執行 review、comment、approve、merge 或任何 GitHub 寫入操作。

## 核心概念與互動

- 第一個切片以一份完整閱讀快照供應資料；大型 PR 的延遲載入是後續獨立決策。
- 對 Presentation 提供穩定的 Reader Facade。
- 透過自己擁有的 PR Content Source Port 取得資料；不直接依賴 PR Inbox。
- Presentation 可用目前選取的 PR 向 Reader 請求閱讀快照。

## Failure Contract

PR Reader 僅表達「PR 無法閱讀／無權存取」或「內容暫時不可取得」等閱讀語意；GitHub 外部失敗由 Integration 邊界隔離。

## 延後能力

commits tab、巨大 diff 分段、review 寫入與離線快取均不在目前範圍。
