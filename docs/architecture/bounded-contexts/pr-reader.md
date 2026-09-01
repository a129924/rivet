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

## WebView Diff Rendering Boundary

- Swift 對 WebView 提供完整且有序的 `DiffViewModel[]` snapshot；每個檔案包含 snapshot-local `fileId`、檔案變更 metadata、可選 patch、增刪計數與 viewed 狀態。
- WebView diff pipeline 只鎖定 declarations：Validator、Parser、Renderer、Output 四個 Ports 由 `DiffRenderUseCase` 協調；`DiffFacade` 是 Presentation 的 render 入口，且不依賴 Output Port。
- Output 是獨立 stage，公開 outcome 區分 `invalid-input`、`parse-error`、`render-error` 與 `output-error`。
- Swift 是 viewed 狀態唯一持久化權威。WebView 僅以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 `viewed` 發送單向通知；Swift 可忽略過期事件。
- 此邊界不定義 concrete Adapter、parser、renderer、Output、DOM、UI、collapse、Swift bridge 或 viewed-state persistence。

## Failure Contract

PR Reader 僅表達「PR 無法閱讀／無權存取」或「內容暫時不可取得」等閱讀語意；GitHub 外部失敗由 Integration 邊界隔離。

## 延後能力

commits tab、巨大 diff 分段、review 寫入與離線快取均不在目前範圍。
