# GitHub 請求標頭技術規格

`GitHubIntegration` 擁有 GitHub-specific 的固定組合與 REST 選擇。Inbox adapter 依目前 Swift package target 依賴方向採用。既有 Endpoint 描述 URL 和方法。兩個 `/user` 呼叫沿用共用 Endpoint 並明示各自的標頭需求。

## 標頭與配置

- `Providers/HeadersProvider.swift` 定義 `package final class HeadersProvider: Sendable`。私有 initializer 保存 `let headers: HTTPHeaders`。三個 production `static let` 分別是 `inboxREST`、`loginAccountREST`、`oauthToken`。REST 建構入口在模組內可供 Factory 根據替代配置建立相同形狀的實例。OAuth 使用固定實例。
- `Composition/GitHubHeadersConfiguration.swift` 定義 internal 不可變結構，保存 `restAccept`、`standardUserAgent`、`loginUserAgent`、`apiVersion`。內建 `.rivet` 使用表列基線。非公開 throwing initializer 拒絕 trim 後為空或包含 CR 或 LF 的任一欄。合法欄位原樣保存，錯誤不含原值。
- Provider 透過既有 typed header API 建構 `HTTPHeaders`，GitHub API 版本欄位用 `HTTPHeaderName.custom`。Inbox REST 包含三欄，登入 REST 保留相同 Accept 和自己的 User-Agent，OAuth 包含 JSON Accept 和 form Content-Type。欄位大小寫及值副本依 `HTTPHeaders` 現有語義。

## REST 組合與接線

`Composition/GitHubHeadersFactory.swift` 定義 package 不可變 `Sendable` struct 與同檔 `package enum GitHubHeaderRequirement: Hashable, Sendable`。兩個 cases 是 `.standardREST` 與 `.loginRuntimeREST`。`GitHubHeadersFactory.standard` 共用兩個 production REST Provider。Internal `init(configuration:)` 一次建出兩組不可變 Provider，供套件內測試注入。

`make(requirements: [GitHubHeaderRequirement]) throws(CompositionError) -> HTTPHeaders` 以封閉需求選擇基線。巢狀 `CompositionError` 是 package typed error。空需求選 standard，單一需求選指定組合，重複選同組，兩種需求共存則回報同一衝突。回傳 `HTTPHeaders` 值副本。原始欄位、Authorization 和合併政策不屬於此入口。

- Inbox 的 `public init(rest:)` 委派給 `package init(rest:headersFactory:)`，預設 `.standard`。Adapter 保存 Factory，在共用 GET 路徑取得 `.standardREST`，把 headers 原樣交給 `GitHubRestClient`。REST 的 classifier 與 BC failure mapping 保留原路徑。
- 登入探查的 internal initializer 接收預設為 `.standard` 的 Factory。Probe 取得 `.loginRuntimeREST`，維持以 `BearerAuth` 套入當次 token 後呼叫通用 `HTTPClient` 的順序。既有 LoginService 可沿用預設探查。
- OAuth code exchange 和 refresh 在原有 POST 組裝讀取 `HeadersProvider.oauthToken.headers`。OAuth 路徑沿用現有 Endpoint、form body、取消及 error mapping。

Public API、依賴清單、transport、REST request override、raw response、401 recovery 與 retry 由各既有契約維持。產品入口、Keychain 和 OAuth app 憑證配置不加入這個組合流程。正式組裝確認後，將 package 內固定組合的採用狀態回寫既有三份長期文件。

## 相關文件

- [需求與四處基線](requirements.md)
- [執行計畫](../../plan/github-request-headers-provider/github-request-headers-provider.plan.md)
