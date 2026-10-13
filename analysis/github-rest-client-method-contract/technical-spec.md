# GitHub REST method 契約技術規格

- Topic：`github-rest-client-method-contract`
- 需求：[requirements.md](requirements.md)
- 契約：[topic.plan.md](../../plan/github-rest-client-method-contract/github-rest-client-method-contract.plan.md)
- 狀態：實作與獨立驗證已完成；Plan-Reviewer／Reviewer approved，等待已授權交付及 human review。

## 實作前現況依據

既有 `GitHubHTTPClient` 為 internal final Sendable concrete client，只提供 `executeGET`，caller 僅在測試。production 自建拒絕 redirect 的 bare HTTP executor。HTTPRequest／HTTPURL／HTTPHeaders／Data body 可保留並重播。OAuthTokenProvider 已提供 snapshot、replacementSnapshot、version、single-flight 及測試 seam。StaticIsolationTests 使用精確 source／import allowlist。

## Locked interface

新增 `Sources/BoundedContexts/GitHubIntegration/REST/GitHubRestClient.swift`：

```swift
import Foundation
import RivetHTTPClient

internal protocol GitHubRestClient: Sendable {
  func get(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse

  func post(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse

  func put(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse

  func patch(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse
  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse
  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse
}
```

同檔 protocol extension 為四 builder 提供相同 signature 的預設組裝實作，依對應 method 建立 HTTPRequest 並委派 execution requirement。沒有 default arguments 或其他 arity overload；所有 caller 明傳 headers／body。八入口均為 protocol requirements，替身可提供 witness；透過 `any GitHubRestClient` 明傳參數呼叫 builder，須驗證替身 witness 生效。

GitHubHTTPClient 符合此契約，保留 concrete 名稱、既有初始化／測試 seam／transport factories／GitHubHTTPClientError。既有 executeGET 改為 executeGet，調整測試，不加 alias。只接受 HTTPURL，不新增 Foundation URL、relative path 或 endpoint policy；不新增 public API／BC Port／package dependency。

## 共用 execution

四完整 request 入口委派 private helper，傳入 expected method：

1. 同步檢查 request.method 與 expected method 相等，再沿用 GitHub URL guard；不符回 `.invalidRequest`，不取得 credential，不暗改 method。
2. 透過既有 async boundary 取得 `usedSnapshot`。
3. 使用 BearerAuth 對原始 request 套用 request-local Authorization，經既有 HTTPClient.execute 發送。
4. 非 401 response 直接回傳，不改 status／headers／Data body。
5. 首次實際 HTTP 401 透過 async boundary 呼叫 `replacementSnapshot(afterUnauthorized: usedSnapshot)`。
6. 從原始 request 套用 replacement Bearer 後第二次發送；method／URL／body／其他 headers 保留，原始輸入不變。
7. 第二次 401 回 `.authenticationRequired`，其餘 raw response 原樣回傳。

不建立 retry loop；timeout、transport failure、403、429、5xx 不啟動 recovery／replay。recovery failure 與非法 replacement token 不追加 send。

URL guard 保留：scheme HTTPS、host api.github.com，沿用大小寫正規化；無 user／password／fragment；port 缺省或 443。path／query 保留，不新增 endpoint 白名單。GET 仍可保留 Data body。

## Error 與 cancellation

| 來源 | 結果 |
| --- | --- |
| method／URL mismatch | `.invalidRequest` |
| missing credential／provider authentication required／第二 401 | `.authenticationRequired` |
| provider restore／refresh／persist failure | `.credentialLifecycle(stage:)` |
| 非取消 transport／其他 execution failure／非法 Bearer token | `.executionFailed` |
| caller／transport／provider-stage cancellation | `CancellationError` |

不新增 error cases。保留同步 validation 在前、每個既有 async boundary 前後檢查取消的順序及 wrapped cancellation 正規化。取消 caller 後不啟動下一個 recovery／send；不取消 provider shared refresh，不保證 provider await 立即返回。shared refresh 完成後，取消 caller 不 replay。

provider 是唯一 lifecycle owner；同 provider 並發 execution 與 late stale 401 沿用其 snapshot version／single-flight。client 不新增認證協調或 provider abstraction；GraphQL 不經 REST。

## Compatibility、文件與圖表

caller 只有既有測試，故在 topic 內調整 executeGET 名稱。StaticIsolationTests 只精確新增 REST/GitHubRestClient.swift 及該檔必要 RivetHTTPClient import。

長期文件／既有責任 canvas 更新 internal REST 四 methods／雙入口交付文案，不改 ownership，不把跨 target、Adapter、完整 endpoint、登入標成已交付。canvas 依 architecture-canvas 驗證。lifecycle 僅從 canonical v10 衍生 v11；依 archify showcase 9 checks、0 warnings／composition errors，deliver、四桌面 containment 與實際 light／dark visual inspection 後更新 canonical links。v10 與歷史 evidence 不覆寫／刪除。作者繁體中文，固定 Viewer UI／HTML lang English fallback；不自動 preview／publish。

graphify 與 PR Lens 的 pin、唯讀／本機限制、fallback 與 provenance 條件見執行契約，工具不決定 correctness 或 gate。
