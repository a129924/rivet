# Swift HTTP Client Method Facade：需求

## Goal

在既有 `RivetHTTPClient` internal transport foundation 的 `HTTPClient` 新增 HTTP method facade。呼叫端持有已驗證的 `HTTPURL` 時，可透過 `get`、`post`、`put`、`patch`、`delete`，或一般化的 `request(method:url:headers:body:)` 發送請求，取得 raw `HTTPResponse` 或未改寫的 transport error。

這不是新的 DDD Bounded Context；package 仍是 GitHub Integration 未來可採用的內部 transport foundation。既有 `execute(_:)` 保留為呼叫端已完成建立 `HTTPRequest` 時的 advanced entry。

## In Scope

- `HTTPClient` 的一般 request entry 與五個固定 HTTP verb async entry。
- facade 以既有 `HTTPURL`、`HTTPHeaders`、`Data?` 組成既有 `HTTPRequest`，並只透過 `execute(_:)` 進入既有 `Requester → Transport` 鏈。
- public contract、chain、raw error passthrough 與 `execute(_:)` compatibility 的測試。
- 對現有 HTTP client architecture 文件與既有 package structure canvas 做最小長期回寫，說明 public facade 已存在且不改變既定責任邊界。

## Out of Scope

- Endpoint、Base URL、Path、Query 或任何 URL composition。
- `URLSessionTransport`、其他 concrete transport、真實網路呼叫、session ownership 或 lifecycle API。
- `HEAD`、`OPTIONS`、streaming request／response。
- status validation、retry、decode policy、token refresh 或統一 package error。
- `Requester` 的公開可見性或責任變更。
- root manifest、GitHub adapter、Bounded Context Map 或其他 BC 的修改。

## Success Criteria

- 五個 verb 與一般 request entry 皆建立語意等價的 `HTTPRequest`，並抵達 injected fake `Transport`。
- 任意既有 `HTTPMethod` 可經 `request(...)` 傳遞；verb 固定其對應 method。
- method、URL、headers、body 與呼叫端直接建立 `HTTPRequest` 後使用 `execute(_:)` 的語意一致。
- raw `HTTPResponse` 與原 transport error 原樣傳遞；既有 `execute(_:)` 行為不變。
- `HTTPURL` 仍是唯一 typed-throws validation boundary，且本 topic 不引入新的 validation 或 error mapping。
