# Rivet 架構規範

本文件記錄未來實作必須遵守的架構不變量。Rivet 目前是 architecture baseline；PR Reader WebView diff 的 Facade／UseCase orchestration、Validator、Parser、Renderer internal concrete stages 與 `RivetHTTPClient` 的最小 HTTP 介面切片已有實作；Output、DOM、Swift bridge 與 viewed-state persistence 仍未實作。除其單一架構圖的 artifact-local viewer 可近用性補強外，不建立其他產品功能。

## 架構方向

Rivet 未來採用 monorepo 與輕量 DDD。

核心的 compile-time dependency 方向如下：

```text
Presentation → Facade → UseCase → Port
```

Adapter 符合 Port，並隔離 Outside；Adapter 不加入核心的 compile-time dependency 方向。PR Reader WebView diff 的 runtime render request 則是：

```text
Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output
```

## Layer Responsibilities

- **Outside**：GitHub API、OAuth、Keychain、網路、WebView runtime 等外部世界。
- **Adapter**：符合 Port，隔離外部協定、資料與錯誤的轉換邊界。
- **Port**：由內部擁有的依賴契約。
- **UseCase**：應用與業務流程。
- **Facade**：提供 Presentation 使用的穩定入口。
- **Presentation**：原生 UI 與 WebView renderer。

## Outcome 與 Failure Contract

- 所有正式 layer 與 Bounded Context 邊界使用 `Outcome` 作為成功／失敗契約。
- 每個 Bounded Context 擁有自己的 failure contract；不得洩漏、重用或混入其他 Bounded Context 的 failure contract。
- `InfraUnknownError` 用於各 BC Adapter 無法安全分類外部 failure 時的 local normalization。
- `InfraUnknownError` 應在該 BC 的 Adapter 邊界產生或正規化；其他層只能傳遞，或補充自身語意。未來 `GithubIntegration` 對 raw transport 或 GitHub error 的 technical classification 不得形成 shared BC failure contract；只有 consuming BC local Infra 可將它映射為自己的 failure contract。
- 純資料轉換與保證不失敗的 private helper，未來不強制使用 `Outcome`。

## 已確認的 Bounded Context Map

- **PR Inbox**：定義目前明確要求使用者 review 的 open PR 與其排序；不負責單一 PR 的閱讀資料或 UI selection。
- **PR Reader**：提供單一 PR 的背景、討論、checks、檔案與 diff 閱讀資料；不決定 Inbox membership。
- **Presentation Session**：擁有目前選取的 PR 與切換狀態；它屬於 Presentation，不屬於任何 Bounded Context。
- PR Inbox 與 PR Reader 不直接依賴彼此，也不建立 BC-to-BC compile-time dependency。各 BC 的 Core、UseCase 與 Port 不依賴 GitHub protocol 或 transport；未來各自的 Infra 隔離 GitHub adapter、operation／endpoint、endpoint-specific media type、DTO 與 failure mapping。
- `GitHubIntegration` 是位於 BC 外的 shared GitHub-specific integration module，不是 Supporting BC 或集中 adapter 邊界。目前 root Swift package target 只提供可注入、同步、typed-throws 的 access-token store/provider contract：未保存 token 映射為 missing credential，store load failure 保留為 token-store error；它不實作 persistence 或 authorization。未來只有各 BC Infra 可依賴其 raw transport、authentication mechanism、共通 request headers／API version、pagination、rate limit、retry、GitHub error technical classification 與 shared configuration；上述均為 deferred mechanism，並非已實作 policy。它不依賴任何 BC，也不產生 shared BC failure contract。各 BC Infra 仍各自擁有 DTO translation、technical classification 到其 failure contract 的 mapping 與 business meaning。
- 此 boundary 決定 supersede `github-integration-auth-boundary`／PR #17 的 Supporting BC 敘述；該舊決定僅保留為歷史 traceability。

## PR Reader WebView Diff Pipeline

PR Reader 的 WebView diff rendering 中，Facade／UseCase orchestration 已有 runtime 實作。render 主路徑為 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；UseCase 擁有四個 stage Port 的協調責任，也是 Output Port 唯一 caller。Adapter 僅宣告 Swift／WebView 的輸入與通知邊界，不加入或反向轉送 render 主路徑。

公開 render outcome 區分 `invalid-input`、`parse-error`、`render-error` 與 `output-error`。`viewed` 的持久化權威仍是 Swift：WebView 只發送包含 PR、snapshot 與 snapshot-local file identity 的 best-effort `void` 單向 notification，不等待 acknowledgement、不 retry、不承諾可靠傳輸，也不修改 snapshot。Validator、Parser 與 Renderer 已有 internal concrete implementation；Output、DOM、Swift bridge 與 viewed-state persistence 尚未實作。

- [PR Reader WebView Diff Pipeline](diagrams/pr-reader-webview-diff-rendering/index.html)：Swift／WebView 邊界、編譯期依賴、宣告的 Ports 與 ownership；此 canvas 不表達 runtime render dataflow。其 [重建與失敗回復規則](diagrams/pr-reader-webview-diff-rendering/BUILD.md) 明確區分兩次單檔 atomic rename 與可驗證的 backup/restore policy，不宣稱雙檔原子交付。
- [PR Reader WebView Diff Dataflow](diagrams/pr-reader-webview-diff-rendering/diff-render-flow.html)：以同一組既定契約表達 runtime render dataflow；不新增 concrete implementation 或資料契約。

## 文件導覽

- [設計原則](../design-principles.md)：Rivet 的產品取捨與工作方法。
- [Bounded Context](bounded-contexts/)：每個 BC 的長期責任與邊界。
- [Bounded Context Map](diagrams/bounded-context-map/index.html)：BC、Presentation Session 與外部邊界的互動式全景圖。
- [HTTP Client package 結構](diagrams/http-client-package-structure/index.html)：`HTTPClient` 已提供 `request(...)` 與常見 HTTP method facade，並經 `execute → Requester → Transport` 形成 `HTTPURL → HTTPRequest → HTTPResponse` 的最小介面鏈；包含 `URLSessionTransport`、caller-owned JSON convenience 與 header convenience，但不包含 Endpoint 組裝。
- [Repository Knowledge Map](diagrams/repository-knowledge-map/index.html)：公開讀者與 agent 如何從入口、文件、analysis、plan 走向下一個 BC 切片。
- [Topic Lifecycle](diagrams/topic-lifecycle/index.html)：正式 topic 從分析、計畫、受限實作到回寫與 human review 的可互動流程圖。

## 尚未定義的項目

Rivet 仍是 architecture baseline。`RivetHTTPClient` 是 generic、GitHub-unaware 的 technical HTTP foundation，可由各 consuming Domain BC 的 local Infra 採用；它具備 Swift product、target、最小 HTTP 介面與 package-owned `URLSessionTransport`。`HTTPHeaders` 提供 case-insensitive lookup 與 typed read/write convenience，`HTTPResponse` 保留 canonical raw `Data` response，並提供由呼叫端傳入 `JSONDecoder` 的 opt-in `json(_:decoder:)` 與 `jsonSemantic(_:decoder:)` conveniences。兩個 API 的 decoded payload 都必須符合 `Decodable & Sendable`；這是 public source-breaking contract。前者直接傳遞 decoder 的原始 error；後者只將 decode failure 分類為有限 semantic kind，並保留完整 underlying error。它以 `HTTPClientError` 表達 cancellation、network failure、non-HTTP response 與無法分類的 underlying failure，並將所有 HTTP status 與 raw response data 原樣保留給呼叫端。package 不擁有 decoder configuration；它不是 `GitHubIntegration` 的實作，也不提供 Endpoint、Base URL、Path 或 Query 的 URL 組裝 API，且不實作 status 或 `Content-Type` validation、retry、token refresh、default/shared JSON decoder 或其他 response decode policy；`jsonSemantic(_:decoder:)` 僅是 caller-invoked decode-failure classification，不改變 raw response dataflow。GitHub endpoint、endpoint-specific media type、DTO 與 technical classification 至 Domain failure contract 的 mapping 都屬 consuming Domain BC local Infra。`GitHubIntegration` 是已實作的 non-BC shared GitHub-specific integration module，但目前只交付 access-token store/provider contract；GitHub REST／GraphQL raw request execution、authentication mechanism、共通 request headers／API version、rate limit、retry、pagination、GitHub error technical classification 與 shared configuration 仍為 deferred capability。它不依賴任何 BC，且不承擔 BC 的 DTO translation、failure mapping 或 business meaning，也不產生 shared BC failure contract。除這個受限切片與既定 PR Reader WebView diff pipeline contract 外，本階段不定義 `Outcome` 的程式碼型別、泛型、case 名稱、payload schema，也不定義其餘 module、package 或產品實作細節。這些決策將隨著一次一個 Bounded Context 的實作 topic 處理。
