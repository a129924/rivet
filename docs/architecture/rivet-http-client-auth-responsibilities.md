# RivetHTTPClient Auth 子系統責任

## Decision

`RivetHTTPClient` 的 authentication subsystem 採用 **Model C — semantic action** 作為目標 architecture。此決定只鎖定責任與 capability boundary；它是 **已採用、尚未實作** 的 target，不改變目前 Swift runtime。

- `Auth` 提供 authentication strategy 與 independent flow；不擁有每次執行的 auth state、caller original request 或 I/O。
- `AuthFlow` 是 authentication policy/state machine。它讀取 raw `HTTPResponse` 的 authentication semantics（例如 401），單獨決定 refresh、retry 次數與終態；它不取得 original request、不建構 request，也不執行 I/O。
- `AuthRequester` 是 caller original request 的唯一 owner，也是 semantic decision interpreter；它只保有該 caller request，**不建構** original request，且不得重新制定 retry policy。
- `Requester` 是 generic `HTTPRequest → HTTPResponse` I/O boundary；不認識 auth policy、refresh lifecycle 或 retry。

## 現行 baseline 與採用 target

現行 runtime 是 **legacy Model A**：`Auth.makeFlow(for: HTTPRequest)` 將 original request 交給 flow，`ClientAction.send(HTTPRequest)` 允許 flow 建構並要求送出任意／多個 request。這是現行 source 的如實描述，不是採用 target，也不表示現行實作已有 refresh/retry product policy。

Model C 的 target 只允許 flow 產出 semantic decision。`AuthRequester` 只保有 caller original request 並解讀該 decision；selected／decorated representation 的 owner 與 API 維持 deferred，必要的 generic HTTP I/O 仍委派給 `Requester`。exact factory signature、semantic action case、request decoration representation、failure surface、async boundary，以及 refresh result delivery 都尚未鎖定。

| Dimension | Legacy Model A（現行） | Model B（未採用） | Model C（採用 target） |
| --- | --- | --- | --- |
| Flow output | `.send(HTTPRequest)` | 受限 HTTP instruction | semantic decision |
| Flow request capability | 可任意建構／多送 request | 限制 endpoint，但仍須先決定 decoration owner | 不取得 original 或 refresh request construction capability |
| `AuthRequester` | generic loop driver | interpreter | original request sole owner + semantic interpreter |
| Refresh request owner | contract 可由 flow 建構 | 尚須指定 | future dedicated I/O boundary，未定義 |
| 狀態 | 已實作 baseline | 未採用 | 已採用、尚未實作 |

Model B 沒有被採用，因為它會在缺乏 concrete consumer 的情況下，過早鎖定 header overlay 或 refresh request builder 的 owner。Model C 以最小 boundary 將 policy 和 mechanism 分離。

## Responsibility Matrix

下表只描述 adopted target。`N/A` 表示本 topic 不宣稱 type 已存在、也不授權新增 runtime role。

| Role | Owns auth state | Knows HTTPResponse | Knows original request | Builds original request | Builds refresh request | Performs I/O | Controls retry |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Auth` | 否 | 否 | 否 | 否 | 否 | 否 | 否 |
| `AuthFlow` | 是 | 是，作為 policy input | 否 | 否 | 否 | 否 | 是 |
| `AuthRequester` | 否 | 是，轉交給 flow | 是，唯一 owner | 否；只保有 caller original request，selected／decorated representation deferred | 否 | 否，委派給 `Requester` | 否 |
| `Requester` | 否 | 是，raw return | 僅接收 selected instance | 否 | 否 | 是 | 否 |
| `TokenFetcher` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| `TokenProvider` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |

## Flow contract

在 normal request 中，caller 把 original request 交給 `AuthRequester`。每次 execution 都在 initial semantic send 前取得 independent flow；`AuthRequester ↔ AuthFlow` 的 exchange 只交付 response 或 semantic decision，沒有 request payload。`AuthRequester` 只保有 caller original request、解讀 flow 的 semantic send decision，並讓 `Requester` 執行該 retained request。raw response 經 `AuthRequester` 交給 `AuthFlow`；flow 做 terminal policy decision，然後由 `AuthRequester` 回傳 response。

在 first 401 中，唯一的 refresh/retry policy owner 是 `AuthFlow`。只有具 refresh capability 且在該 state eligible 的 flow，才可發出 semantic refresh decision；不具資格的 flow 直接作 terminal decision。`AuthRequester` 只解讀 refresh decision，將它交給 **deferred refresh I/O boundary**。該 boundary 的名稱、endpoint、payload、credential persistence 和 result API 都未定義；它完成後的 refresh result 必須經 `AuthRequester` 的 deferred result boundary 回到 flow，沒有 receive→retry shortcut。只有 refresh-success 使 flow 可授權一次 retained-original retry；refresh failure、ineligible flow 或 second 401 都必須由 flow 導向終態。這是 target topology，不是既有 runtime 行為。

對應圖表：

- [責任與依賴 canvas](diagrams/redefine-auth-subsystem-responsibilities/component-dependency/index.html)
- [Normal request sequence](diagrams/redefine-auth-subsystem-responsibilities/normal-request.html)
- [401 refresh + retry sequence](diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.html)
- [AuthFlow state diagram](diagrams/redefine-auth-subsystem-responsibilities/auth-flow-state.html)

## Trade-offs 與後續 boundary

Model C 的收益是 type contract 可直接限制 flow 不應持有的 capability，retry policy 有唯一 owner，且 flow 可獨立以 response-driven state transition 測試。代價是 future concrete-consumer topic 必須依真實 authentication scheme 決定 semantic action、decoration 與 refresh-result interface；本文件不能替它們命名或定義 API。

後續 Swift implementation 必須先以獨立 topic 鎖定上述 deferred interface，並驗證：normal response terminal、eligible refresh-capable flow 的 first 401 requests refresh、refresh-success permits exactly one retained-original retry、ineligible flow／second 401 terminal，以及 refresh failure terminal。它也必須以 type/API evidence 證明 `AuthFlow` 無 arbitrary endpoint/request construction 或 I/O capability。除非另開 topic 重新檢討，本 decision 不處理 generic retry、5xx/network retry、backoff、rate limit、single-flight refresh、OAuth lifecycle 或 credential storage。

## Supersession history

本文件 supersede 對 HTTP client auth flow 的「`.send(HTTPRequest)` 是目標 contract」解讀；該 contract 仍保留為 legacy runtime baseline 的 traceability。它不 supersede OAuth dual-client lifecycle，也不將 `TokenFetcher`、`TokenProvider` 或任何 credential component 寫成已存在的 `RivetHTTPClient` API。
