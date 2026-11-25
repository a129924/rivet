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

- 背景切片可單獨供應選取 PR 的背景資料。完整閱讀快照仍由完整內容來源契約定義，組裝及大型 PR 延遲載入另行決定。
- 對 Presentation 提供穩定的 Reader Facade。
- 透過自己擁有的 PR Content Source Port 取得資料；不直接依賴 PR Inbox。
- Presentation 可用目前選取的 PR 向 Reader 請求閱讀快照。
- PR Reader 自己的 Infra 擁有 GitHub adapter、operation／endpoint、endpoint-specific media type、DTO 與 failure mapping；現有 GraphQL SDL 僅是未驗證的 candidate／暫存 asset，本文件不將它定義為正式 BC-local ownership，也不據此搬移 schema、指定 target 或改變任何 API／實作。
- non-BC `GitHubIntegration` 已實作為 shared GitHub-specific integration module，目前提供既有可注入、同步、typed-throws 的 access-token store/provider contract，以及沒有 conformer 的 public、`Sendable` async `GitHubAccessTokenProvider` token-acquisition contract；後者不處理 PAT／OAuth lifecycle、request、transport、401 recovery 或 retry。另已交付 public、process-local、non-persistent 的 `InMemoryGitHubTokenStore`，僅在單一 store instance 的生命週期保存一個 token，以及 public `KeychainTokenStore`：後者以 legacy macOS Keychain 為目前使用者保存單一 GitHub access token，並可跨 process 讀回；兩者均不實作 authorization。另已交付 `OAuthTokenProvider` actor 與 `OAuthCredentialStore`／`OAuthTokenFetcher` ports；它只交付 `TokenSnapshot(accessToken, version)`，不將 credential bundle 或 provider failure 帶入 Reader。Reader Infra 可採用 `GitHubIntegration` 的 REST client、固定標頭組合與技術回應分類；`GitHubIntegration` 不依賴任何 BC。GitHub DTO／GraphQL node translation、technical classification 到 Reader failure contract 的 mapping 與 Reader business meaning 仍只留在此 Infra；它們不會進入 Core、UseCase 或 Port，且不形成 shared BC failure contract。

## Core Content Source Contract

`GitHubIntegration` 已提供 internal-only GraphQL Query／Mutation foundation；Reader 的 GraphQL 接線仍延後。候選 SDL 不屬於Query／Mutation 或測試來源，Reader Core／UseCase／Port 不新增 Apollo、OAuth 或 transport 依賴。

- `PRContentSource` 是 Reader-owned、`Sendable` 的 Domain Port；它以 `ReaderPullRequestID(owner, repository, number)` 非同步回傳 target-local `Outcome<PRContentSnapshot, PRReaderFailure>`。
- `PRContentSnapshot` 保留背景、有序 conversation、reviews、inline threads、files，以及可缺的 review decision 與 check rollup。成功 producer 必須回傳與 request 相同的 PR identity、同一 snapshot 內唯一的 `ReaderFileReference`，並保留來源檔案順序；Core 不另設 validator。
- 檔案變更語意包含 added、removed、modified、renamed、copied 與 type changed。每檔保留 path、可缺 previous path、增刪計數與可缺 patch；缺 patch 的 metadata-only 檔案仍是合法成功內容。Core snapshot 沒有頂層 unified diff。
- check rollup 缺席與存在但 checks 為空是不同狀態；run 與 commit status 保留各自的 Reader 語意與來源順序。Core 不含 check ID 或 URL。
- Core 不含 WebView 的 `snapshotId`、snapshot-local `fileId` 或 `viewed`；兩側 identity 映射、viewed 來源與事件回查由獨立的 `RivetPRReaderWebViewBridge` presentation integration target 處理，Core 不依賴它。

## GitHub REST 背景讀取

- 套件內的 `RivetPRReaderGitHub` target 接收已認證的 `GitHubRestClient` 和 `ReaderPullRequestID`。Reader Infra 驗證識別後向 `api.github.com` 取得指定 PR 的 JSON 詳情，將 `200` 投影為 `ReaderBackground`。描述或作者缺席保留缺值。
- Reader Infra 選用共用 `.standardREST` 標頭，並以 `get` 委派請求。REST client 負責執行與 `401` 復原。Reader 與 Inbox 將所有非 `200` 回應交給同一個 `GitHubResponseClassifier`。Reader Infra 將共用技術分類映射為 `PRReaderFailure`，權限拒絕及原因未明的 `403` 回 `.notReadable`，限流回 `.unavailable`。
- 背景 adapter 實作 Reader Core 的 `PRBackgroundSource`，由 `PRReaderBackgroundFacade` 透過單次讀取 UseCase 消費。完整快照仍由 `PRContentSource` 定義。

### 背景資料呈現工作階段

- 套件內組裝入口 `makePRReaderBackgroundSession(rest:)` 使用 caller 提供的已就緒 REST client，組合 Reader adapter、Facade 與新 Session。組裝層持有技術依賴，`RivetPRReaderPresentation` 僅依賴 Reader Core。正式元件整合由受控 REST 驗收，產品 App Owner 與導覽接入另行交付。
- `PRReaderBackgroundSession` 在 MainActor 管理選取、顯示狀態與當前 Task。切換 PR 清除上一筆背景，同 PR 重新選取維持狀態。顯式刷新保留最後一次成功值，刷新失敗顯示錯誤並保留資料。
- Session 先撤銷過期請求的提交資格再取消 Task。有效結果依當前請求識別、選取及原 Task 取消旗標，在同一同步區段提交並清理。狀態及當前 Task 更新後才通知觀察者，讓同步回呼可安全操作 Session。呼叫端離開時使 Session 永久失效，重開時組裝新實例。

## GitHub REST 變更檔案讀取

- `RivetPRReaderGitHub` 的套件內 `GitHubPullRequestChangedFilesSource` 接收已認證的 REST client 與指定 PR 識別，回傳有序、識別唯一的 `ReaderFile` 清單。檔案識別採來源路徑，保留逐檔增刪數、可取得的原路徑與 patch。合法空清單為成功。此入口供後續快照組裝使用。
- 續頁必須能核對到原 PR，實際請求由 Changed Files 端點重建。首次收到有效的數字 repository ID 續頁時，用原 PR 詳情核對其歸屬。當次讀取以 GitHub 提供的分頁序列為準。無法確認完整性或達 3,000 檔時回 `.unavailable`。
- Reader Infra 將認證與存取拒絕映為 `.notReadable`，將限流、傳輸、取消與分頁失敗映為 `.unavailable`。必要資料、狀態或檔案識別無法保真表達時回 `.contentNotRepresentable`。任一失敗只回 Reader failure。

## GitHub REST raw unified diff

套件內的 `GitHubPullRequestUnifiedDiffSource.fetchUnifiedDiff(for:)` 接收 `ReaderPullRequestID`，透過已授權的 `GitHubRestClient` 讀取該 PR 的整份 diff。Reader Infra 沿用背景讀取的 PR 詳情 GET 路徑，選擇 `.pullRequestUnifiedDiffREST` 取得 `Accept: application/vnd.github.diff`。

HTTP `200` 交付 `Outcome<Data, PRReaderFailure>` 的原始 response body。Reader Infra 沿用背景讀取的技術分類與失敗映射。權限拒絕或無效識別回 `.notReadable`，`406`、限流、執行失敗或取消回 `.unavailable`。取消優先於晚到的回應或 client 失敗。 [Rivet API Catalog](../../github-api/rest-pr-reader.md#unified-diff)

## GitHub REST 一般討論留言讀取

- 套件內 `GitHubConversationCommentsSource.fetchConversationComments(for:)` 使用已認證的 REST client 與已確認的 PR 識別，透過 `GitHubConversationCommentsEndpoint` 讀取指定 PR 的一般留言。請求從第 1 頁開始，每頁請求 100 筆。成功結果保留來源頁次、頁內順序、留言 ID、原始 Markdown 與可用作者。合法缺作者仍保留留言，完整空清單回成功。此入口可供後續快照組裝。 [GitHub 留言端點](https://docs.github.com/en/rest/issues/comments#list-issue-comments)
- Reader Infra 驗證 `Link` 的續頁仍屬原 PR，再重建具名請求。首次遇到有效數字 repository ID 續頁時，讀取原 PR 詳情，以與 Changed Files 共用的解碼及身分核對確認 PR 編號、repo 名稱與 ID。已確認 ID 只在本次讀取內重用。各頁可能反映讀取期間不同時間點。 [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api#using-link-headers)
- 留言請求的認證或存取拒絕、找不到或已移除的資源及無效起始識別回 `.notReadable`。取消、限流、傳輸、續頁或 PR 詳情查核失敗回 `.unavailable`。必要留言資料無法保真映入 Reader 模型時回 `.contentNotRepresentable`。整次讀取只交付完整清單或單一失敗。

## WebView Diff Rendering Boundary

- Swift 對 WebView 提供完整且有序的 `DiffSnapshot`；它帶有 `pullRequestId`、`snapshotId` 與 `readonly DiffViewModel[] files`，每個檔案包含 snapshot-local `fileId`、檔案變更 metadata、可選 patch、增刪計數與 viewed 狀態。
- WebView diff pipeline 的 Facade／UseCase orchestration 已有 runtime 實作。render 主路徑為 `Swift bridge snapshot → WKWebView live transport → DiffSnapshotAdapter.receiveSnapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → DOM Output`；四個 Ports 由 `DiffRenderUseCase` 協調，且它是 Output Port 唯一 caller。`DiffFacade` 是 Presentation 的 render 入口，且不依賴 Output Port；`DiffSnapshotAdapter.receiveSnapshot` 是 callable 邊界，呼叫 Facade 一次並回傳既有 render outcome。Swift sink 的同步返回只代表 host 接受交付；host 另行追蹤頁面世代、快照 DOM 完成、失敗與逾時。
- Output 是獨立 stage，公開 outcome 區分 `invalid-input`、`parse-error`、`render-error` 與 `output-error`。
- Swift-owned viewed authority 是此 bridge 的讀取與更新邊界；永久儲存機制尚未決定。WebView 僅以 `pullRequestId`、`snapshotId`、snapshot-local `fileId` 與 `viewed` 發送 best-effort `void` 單向通知；Swift 可忽略過期事件。此狹義例外不等待 acknowledgement、不 retry、不承諾可靠傳輸，且 WebView 不做 optimistic snapshot 更新。
- Validator、Parser 與 Renderer 已有 internal concrete implementation，支援 added、removed、modified、renamed、copied、typeChanged 六狀態。`RivetPRReaderWebViewBridge` 以無碰撞 PR encoding、session snapshot ID 與 snapshot-local file registry 完整交付 Reader files；viewed event 須符合 PR、snapshot、file 三重 identity 才送往 Swift authority。fixture harness 提供具體 Output／DOM、WKWebView host 與雙向 live transport；Viewed 只存於該 harness 的記憶體，永久儲存尚未實作。host 先驗證頁面世代，bridge 再驗證三重 identity；authority 成功寫入後，host 在下一 main-actor turn 發布新快照，WebView 不做 optimistic update。
- 長期圖表以責任分工保持一致：architecture-canvas 表達 ownership、編譯期依賴與 Swift／WebView boundary；同資料夾的 Archify `dataflow` 表達 fixture runtime render flow。兩者均不宣稱 GitHub source 或完整產品 Reader UI 已交付。

## Failure Contract

PR Reader Core 以 `.notReadable` 表達 PR 無法閱讀或無權存取，以 `.unavailable` 表達內容暫時不可取得；`.contentNotRepresentable` 表達來源無法將必要集合元素或必要資料保真映入完整 Core 模型。合法的 optional review decision、check rollup、author、conclusion 或 patch 缺席不屬於 `.contentNotRepresentable`。Reader local Infra GitHub adapter 不得將 GitHub DTO、HTTP status、token 或技術層 failure 洩漏至 Reader core Port，跨越 Port 前必須映射為 Reader failure contract。

## 延後能力

commits tab、巨大 diff 分段、review 寫入與離線快取均不在目前範圍。
