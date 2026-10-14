# GitHub Client Scope Composition — Requirements

- Topic：`github-client-scope-composition`
- 狀態：已承接人類鎖定範圍，待獨立 Plan-Reviewer 審查。
- 來源：本次明示授權、既有 GitHub OAuth 雙 Client 長期契約。
- 執行契約：[plan](../../plan/github-client-scope-composition/github-client-scope-composition.plan.md)。
- 設計：[technical-spec](technical-spec.md)。

## 意圖

讓 caller composition root 使用一般 `import GitHubIntegration` 建立可跨 target 使用的雙 client scope。
Caller 建立並保留 `OAuthTokenProvider`，以 `prepare(provider:)` 明確完成本地 readiness。
Scope 支援多個 request 的生命週期；不代表 Unit of Work 或交易。
Scope 不負責建立 provider，也不取代 provider 的 restore、refresh、persist 與 terminal state。
此切片屬 non-BC `GitHubIntegration`；不實作任何 consuming BC adapter。

## 成功條件

1. 一般 import 可見 REST／GraphQL contracts，不需 `@testable`。
2. 消費端可注入 offline fakes，無須遠端 GitHub 或真實 credential。
3. 未完成 readiness 前不得交付部分 scope 或任一 client。
4. Prepare 依 snapshot 路徑完成 restore、expiry-first refresh、persist 與本地 Bearer 驗證。
5. 缺 credential、需重新授權、restore／refresh／persist、非法 Bearer 與取消可安全觀察。
6. 兩 client 使用同一 provider，跨 REST／GraphQL 共用 single-flight 與 snapshot version。
7. 每個 request 不重建 provider。
8. 每次 execution 取得當下 snapshot，不把 prepare snapshot 當永久 credential。
9. Prepare 不探測 resource API、帳號或 repository permission。
10. 已觀察取消不交付 scope，且不撤銷已接受 rotation／persist。
11. 不自動重建 provider 或重新 prepare 來繞過 terminal／rotation-indeterminate state。
12. 保留 REST 四 methods、GraphQL Query／Mutation、401-only 一次 retry、response／errors／取消／transport 行為。
13. BC Core、UseCase、Port 不引入 GitHub、OAuth 或 Apollo。
14. 文件明示 ready 不保證未來 request、遠端 authentication 或 repository permission 成功。

## 範圍

公開既有 REST protocol、四個 default builders 與有限 technical errors。
新增 public GraphQL serving protocol，既有 internal concrete conform。
新增 public scope 與 sanitized preparation errors。
增加受控 internal client factory seam，供真實雙 client 的離線組合驗證。
更新 consumer fixture、精確 isolation allowlist、長期文字與既有圖。
保留既有 provider、ports、fetcher、generic HTTP 與 transport policy。

## 非目標

不新增 BC adapter、endpoint、DTO、domain mapping、Port、產品 Facade 或 App／UI。
不交付登入、Keychain OAuth adapter、logout、多帳號或初次 authorization。
不新增 HTTP methods、retry policy、pagination、rate limit、cache、DI container 或 singleton。
不增加 UoW、close／dispose，亦不重構 OAuth、Apollo 或 generic HTTP。
不公開 transport injection、不替 caller 管理 provider 失敗後的生命週期。
不以真實 token、API probe 或網路成功作為本次驗收。

## 取消與安全

取消獨立為 `CancellationError`，不包裝為 preparation technical error。
Task 取消、URLError.cancelled、provider underlying 與 typed refresh cancellation 必須正規化。
取消 caller 不取消 shared refresh；不承諾 provider await 立即返回。
失敗 envelope 不含 credential、raw underlying error 或 response body。
合法 raw HTTP response 與 Apollo partial／errors-only data 保持原契約。
Caller 在 prepare 失敗或取消後仍持有原 provider。

## 驗收證據

新 scope tests 與 normal-import consumer fixture 對應上述 14 項成功條件。
跨 client recovery 必須使用真實 REST／GraphQL clients 配受控 transport。
包含 concurrent single-flight、version advance 與 late 401，不只測兩個 fake client。
執行 consumer script、完整 Swift regression、format、strict lint 與 coverage ≥90%。
圖的 lifecycle v12 與責任 canvas 各自依對應 skill 驗證；保留 v11 歷史。
所有 evidence 僅記錄實際執行結果；目前未宣稱任何 gate 已通過。

## 待確認狀態

無待重新決定的 scope／API／path；獨立 Plan-Reviewer verdict 尚未取得。
如實作發現無法在 allowlist 達成契約，先回報 required fix，不自行擴張範圍。
最後更新：2026-10-14，Plan-Creator。

AC01–AC14 的 canonical 驗收情境、預定檔／command 與 pending evidence 見 [Plan 驗收映射](../../plan/github-client-scope-composition/github-client-scope-composition.plan.md#ac-verification-mapping)。
