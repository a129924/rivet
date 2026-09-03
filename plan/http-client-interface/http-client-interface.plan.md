# HTTP Client interface

## Goal

實作 `HTTPURL → HTTPRequest → HTTPClient → Requester → injected Transport → HTTPResponse` 最小且可測的 public interface chain。

## Non-Goal

不實作 Endpoint／URL composition、`URLSessionTransport`、實際網路、status validation、retry、token refresh、decode policy、統一 package error model，或 root package dependency。

## In-Scope

- standalone `RivetHTTPClient` library product、source target、test target。
- typed-throwing `HTTPURL` validation，以及不 throws 的 `HTTPRequest` construction。
- `HTTPMethod`、`HTTPHeaders`、raw `HTTPResponse`、`HTTPClient`、`Requester`、injected `Transport`。
- Foundation `URLRequest` mapping、Swift Testing、長期架構文件與兩張既有 HTTP Client canvas。

## Out-Of-Scope

- Endpoint、Base URL、Path、Query 與呼叫端 domain API 設計。
- OAuth、Keychain、TokenProvider、GitHub DTO／failure mapping、PR Inbox、PR Reader、WebView diff pipeline、BC Map。
- Canvas publication、merge、release 與 tag。

## ReadOnly

- 根 `Package.swift`。
- `analysis/http-client-package-baseline/` 與 `plan/http-client-package-baseline/` 的既有歷史 artifacts。
- 其他 Bounded Context、全域 BC Map，以及 architecture-canvas template／scripts。

## Written

- `analysis/http-client-interface/requirements.md`
- `analysis/http-client-interface/technical-spec.md`
- `plan/http-client-interface/http-client-interface.plan.md`
- `plan/http-client-interface/http-client-interface.step.md`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/{URL,Request,Response,Execution}/`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/{URL,Request,Response,Execution}/`

## Modify

- `packages/RivetHTTPClient/Package.swift`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/github-integration.md`
- 兩張既有 HTTP Client architecture-canvas 的 `scene.js`、`BUILD.md`、generated `index.html`。

## Deleted

- `packages/RivetHTTPClient/Sources/.gitkeep`
- `packages/RivetHTTPClient/Tests/.gitkeep`

## Implementation

1. 建立 package product、source target 與 test target，但不將 package 接入 root manifest。
2. 只在 `HTTPURL` initializer 使用 typed throws；Requester 信任已驗證的 URL。
3. 由 Requester 把 HTTPRequest 映射為 URLRequest，再委派 injected Transport；成功 response 與 error 均原樣傳遞。
4. 更新 docs／canvas，明確將 Endpoint composition 留在 caller／domain layer，並標示沒有 concrete URLSession transport。
5. source 與 tests 都依 URL、Request、Response、Execution folder 分組；此重排不得改變 public API 或行為。

## TestCase

- TC-01：HTTPURL 接受 http 與 https URL。
- TC-02：HTTPURL 以 `unsupportedScheme` 拒絕非 http／https scheme。
- TC-03：HTTPURL 以 `missingHost` 拒絕缺少 host 的 URL。
- TC-04：Requester 將 method、headers、body 與 `HTTPURL.value` 映射為 URLRequest。
- TC-05：fake Transport 驗證 HTTPClient 到 Requester 到 Transport 的呼叫鏈，並回傳 raw HTTPResponse。
- TC-06：Transport error 維持原始型別向上傳遞。
- TC-07：SwiftPM manifest、Swift tests、canvas validate／build／accessibility verifier 與 pre-commit 通過。
- TC-08：HTTPHeaders dictionary literal 的重複 name 不會 crash，且後者覆蓋前者。
