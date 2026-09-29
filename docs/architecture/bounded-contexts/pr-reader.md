# PR Reader

## 責任

提供閱讀單一 Pull Request 所需的背景、一般討論、review 摘要、inline comment、checks、檔案與逐檔可選 diff patch。

- Core 已實作於 `RivetPRReader` library target；target 僅編譯 `Sources/BoundedContexts/PRReader/Core/`，不納入 Reader Infra 或候選 GraphQL SDL。

## 非責任

- 不決定 PR 是否屬於待審閱佇列，也不排序 Inbox。
- 不擁有 UI 的選取與切換狀態。
- 不執行 review、comment、approve、merge 或任何 GitHub 寫入操作。
- Core、UseCase 與 Port 不依賴 GitHub REST／GraphQL、GitHub DTO 或任何 transport。

## 核心概念與互動

- 第一個切片以一份完整閱讀快照供應資料；大型 PR 的延遲載入是後續獨立決策。
- 對 Presentation 提供穩定的 Reader Facade。
- 透過自己擁有的 PR Content Source Port 取得資料；不直接依賴 PR Inbox。
- Presentation 可用目前選取的 PR 向 Reader 請求閱讀快照。
- 未來若需 GitHub 資料，僅 PR Reader 自己的 Infra 可擁有 GitHub adapter、operation／endpoint、endpoint-specific media type、DTO 與 failure mapping；現有 GraphQL SDL 僅是未驗證的 candidate／暫存 asset，本文件不將它定義為正式 BC-local ownership，也不據此搬移 schema、指定 target 或改變任何 API／實作。
- non-BC `GitHubIntegration` 已實作為 shared GitHub-specific integration module，目前提供既有可注入、同步、typed-throws 的 access-token store/provider contract，以及沒有 conformer 的 public、`Sendable` async `GitHubAccessTokenProvider` token-acquisition contract；後者不處理 PAT／OAuth lifecycle、request、transport、401 recovery 或 retry。另已交付 public、process-local、non-persistent 的 `InMemoryGitHubTokenStore`，僅在單一 store instance 的生命週期保存一個 token，以及 public `KeychainTokenStore`：後者以 legacy macOS Keychain 為目前使用者保存單一 GitHub access token，並可跨 process 讀回；兩者均不實作 authorization。另已交付 `OAuthTokenProvider` actor 與 `OAuthCredentialStore`／`OAuthTokenFetcher` ports；它只交付 `TokenSnapshot(accessToken, version)`，不將 credential bundle 或 provider failure 帶入 Reader。authorizer、GitHub REST／GraphQL raw transport、共通 request headers／API version、pagination、rate-limit、retry、GitHub error technical classification、shared configuration、OAuth adapters 與 client integration 仍為 deferred。只有此 Infra 可依賴 `GitHubIntegration` 與上述 deferred capability；`GitHubIntegration` 不依賴任何 BC。GitHub DTO／GraphQL node translation、technical classification 到 Reader failure contract 的 mapping 與 Reader business meaning 仍只留在此 Infra；它們不會進入 Core、UseCase 或 Port，且不形成 shared BC failure contract。

## Core Content Source Contract

- `PRContentSource` 是 Reader-owned、`Sendable` 的 Domain Port；它以 `ReaderPullRequestID(owner, repository, number)` 非同步回傳 target-local `Outcome<PRContentSnapshot, PRReaderFailure>`。
- `PRContentSnapshot` 保留背景、有序 conversation、reviews、inline threads、files，以及可缺的 review decision 與 check rollup。成功 producer 必須回傳與 request 相同的 PR identity、同一 snapshot 內唯一的 `ReaderFileReference`，並保留來源檔案順序；Core 不另設 validator。
- 檔案變更語意包含 added、removed、modified、renamed、copied 與 type changed。每檔保留 path、可缺 previous path、增刪計數與可缺 patch；缺 patch 的 metadata-only 檔案仍是合法成功內容。Core snapshot 沒有頂層 unified diff。
- check rollup 缺席與存在但 checks 為空是不同狀態；run 與 commit status 保留各自的 Reader 語意與來源順序。Core 不含 check ID 或 URL。
- Core 不含 WebView 的 `snapshotId`、snapshot-local `fileId` 或 `viewed`；兩側 identity 映射、viewed 來源與事件回查由獨立的 `RivetPRReaderWebViewBridge` presentation integration target 處理，Core 不依賴它。

## WebView Diff Rendering Boundary

- Swift 對 WebView 提供完整且有序的 `DiffSnapshot`；它帶有 `pullRequestId`、`snapshotId` 與 `readonly DiffViewModel[] files`，每個檔案包含 snapshot-local `fileId`、檔案變更 metadata、可選 patch、增刪計數與 viewed 狀態。
- WebView diff pipeline 的 Facade／UseCase orchestration 已有 runtime 實作。render 主路徑為 `Swift bridge snapshot → DiffSnapshotAdapter.receiveSnapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；四個 Ports 由 `DiffRenderUseCase` 協調，且它是 Output Port 唯一 caller。`DiffFacade` 是 Presentation 的 render 入口，且不依賴 Output Port；`DiffSnapshotAdapter.receiveSnapshot` 是 callable 邊界，呼叫 Facade 一次並回傳既有 render outcome；Swift sink 與 adapter 之間尚無 live transport。
- Output 是獨立 stage，公開 outcome 區分 `invalid-input`、`parse-error`、`render-error` 與 `output-error`。
- Swift-owned viewed authority 是此 bridge 的讀取與更新邊界；永久儲存機制尚未決定。WebView 僅以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 `viewed` 發送 best-effort `void` 單向通知；Swift 可忽略過期事件。此狹義例外不等待 acknowledgement、不 retry、不承諾可靠傳輸，且 WebView 不做 optimistic snapshot 更新。
- Validator、Parser 與 Renderer 已有 internal concrete implementation，支援 added、removed、modified、renamed、copied、typeChanged 六狀態。`RivetPRReaderWebViewBridge` 以無碰撞 PR encoding、session snapshot ID 與 snapshot-local file registry 完整交付 Reader files；viewed event 須符合 PR、snapshot、file 三重 identity 才送往 Swift authority。Output、DOM、WKWebView host／live transport 與 viewed-state persistence 尚未實作。
- 長期圖表以責任分工保持一致：architecture-canvas 只表達 ownership、編譯期依賴與 Swift／WebView boundary；同資料夾的 Archify `dataflow` 才表達既定 runtime render flow。兩者均不定義 concrete implementation。

## Failure Contract

PR Reader Core 以 `.notReadable` 表達 PR 無法閱讀或無權存取，以 `.unavailable` 表達內容暫時不可取得；`.contentNotRepresentable` 表達未來 mapper 無法將必要集合元素或必要資料保真映入完整 Core 模型。合法的 optional review decision、check rollup、author、conclusion 或 patch 缺席不屬於 `.contentNotRepresentable`。Reader local Infra GitHub adapter 不得將 GitHub DTO、HTTP status、token 或技術層 failure 洩漏至 Reader core Port，跨越 Port 前必須映射為 Reader failure contract。

## 延後能力

commits tab、巨大 diff 分段、review 寫入與離線快取均不在目前範圍。
