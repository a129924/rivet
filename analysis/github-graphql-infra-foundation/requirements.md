# GitHub GraphQL Infrastructure Foundation：Requirements

## 目標與基線

本 topic 是 non-BC、GitHub-specific 的 shared integration 內部 foundation，不擁有 Domain business result。讓 `GitHubIntegration` 內部以現有 OAuth lifecycle 執行 authenticated read Query；跨 target GraphQL 使用仍為 deferred。

Human 於 2026-10-07 明確選擇「收斂為 internal foundation」：撤換原 public `execute`／外部直接使用 client 的 Goal、AC 與 consumer evidence。這是既有 topic 的明示契約收斂，不取代 topic 或重開既定 target／ownership。

- 既有 `OAuthTokenProvider` actor 與 `TokenSnapshot`、`snapshot()`、`replacementSnapshot(afterUnauthorized:)` 已存在；provider 擁有 restore、expiry、refresh、stale version、single-flight、rotation 與 persistence。
- 2026-10-05 本次獨立 Reviewer 接受 provider runtime iteration 2，Human 選擇「接受並繼續」。保留其歷史測試 evidence；本次 ledger 更正不表示重新執行測試或倒填 approval。
- Feature branch：`feat/github-graphql-infra-foundation`；base：`a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f`，來自 `dev`，未來 Draft PR base 為 `dev`。
- Apollo 2.1.2 只有 Explorer 的 source-level feasibility evidence；實際 Swift 編譯、assembly、TaskLocal／noncopyable bridge、cancellation 與 integration 尚未驗證。提議的 API／side code 不是 runtime 證據。

## Locked Scope

**In Scope**：既有 `GitHubIntegration` target 中的 internal final client、Query-only `fetch`、Bearer injection、parser 前 HTTP status 分類、401 recovery／一次重送、有限 technical error、取消與必要測試／docs 回寫。本次唯一新增 protocol 是 internal、Apollo-bound 的 execution testing seam。

**Out of Scope**：public client capability、跨 target GraphQL 使用、BC operation／schema／selection／DTO／mapping／Port／failure contract；OAuth concrete adapters、初次 sign-in／PKCE／callback／logout／revoke、多帳號、PAT、Enterprise；REST、Mutation、Subscription／streaming、pagination、rate-limit、一般 retry、可調式 cache policy、offline cache、migration 與 vendor-neutral GraphQL abstraction。

Shared token／credential contracts、provider、stores 與 OAuth definitions 保持原位及原契約。Apollo 不進入 BC Core／UseCase／Port，不新增 production module／target／product 或 REST 目錄。正常 Apollo query／response 只存在於 integration 內部；未來各 BC local Infra 的責任與既定長期架構保持，並未交付該跨 target 能力。

## 可觀察情境

- **成功**：Given provider 可交付有效 snapshot、內部 caller 提供 SingleResponseFormat Query；When `fetch(query:)`；Then 用該 snapshot 的 Bearer 執行固定 GitHub.com endpoint，回傳合法 Apollo response。
- **Recovery**：Given 第一個 execution 使用 snapshot N 後收到 HTTP 401；When 回報完整 N 給 provider；Then 以 replacement snapshot 重送相同 query／variables 一次。第二次 401 終止為 authentication-required。
- **失敗**：missing credential 為 authentication-required；restore／refresh／persist 保留 technical stage；非 401 HTTP status 與 network／parser failure 不 recovery。合法 partial data＋errors 或 errors-only response 不被強制 throw。
- **取消**：caller cancellation 優先於 recovery 與 error mapping；取消 caller 不送 retry、不主動取消 provider shared refresh。provider await 的立即取消返回不在保證範圍。

## Acceptance Criteria

1. Client、constructor、`fetch`、technical error 與 execution seam 均 internal；沒有 public GraphQL capability 或外層 client protocol。
2. 入口僅接受 `GraphQLQuery`，且 `Query.ResponseFormat == SingleResponseFormat`；不提供 generic Operation／Mutation／Subscription placeholder。
3. 初始與 retry 的 snapshot Bearer 正確；並行 fetch 不混用 headers；raw executor 的 accessToken 參數經 TaskLocal 傳至各自 URLRequest value。
4. 在 parser 前辨識 empty／non-JSON HTTP 401；第一次 recovery 使用實際 snapshot，原 query／variables 不變，`maximumAuthenticationRecoveries = 1`，第二次 401 terminal。
5. 每個 fetch 最多兩次 Apollo session/application execution；不宣稱 Foundation redirect／connection／wire request 次數保證。
6. 403、其他 HTTP、provider failure、GraphQL errors、APQ error payload、network 與 parsing failure 不造成額外 recovery／execution。
7. 合法 partial／errors-only response 原樣保留。Provider failure 保留 restore／refresh／persist stage，不全部轉 authentication-required。
8. CancellationError 保留，URLError.cancelled 與 provider stage 包裝的 underlying cancellation 正規化；已取消 caller 不 recovery／retry，shared refresh 仍由 provider 管理。
9. 不交付 token bundle、raw request、secret body、Apollo transport objects 或任意 underlying diagnostics；不形成 shared BC failure contract。
10. exact Apollo 2.1.2、POST、APQ off、retry 0、network-only 且 explicit cache-write disabled 的真 request-chain evidence 通過。
11. Swift 6 generic／TaskLocal／noncopyable bridge、internal visibility、static isolation 與正常 import 的既有 public consumer regression 通過；外部 consumer 不加 Apollo 依賴或以 @testable 冒充產品可用性。

## 導覽與交付限制

僅用 $graphify 查證本 topic 的既有接點與受影響範圍；發現缺漏就回報，不自行擴大 scope、建立 graph 或重開已鎖定決策。

既有 Explorer evidence：graphify runtime 0.9.73；每次 CLI 使用 `GRAPHIFY_NO_AUTO_REFRESH=1`。限定既有位置查找未發現 usable graph，revision／nodes／edges／freshness／query／path／explain 未驗證；最小 source fallback 不等於 graph 查證。缺 graph 是工具證據缺口，不新增 implementation gate；不建 graph、不掃全 home／cache。

Human 已條件式授權：無重大問題且正式 plan review、implementation verification、outcome review 通過後，以 topic commit、push、開 Draft PR，再交 human review。此授權不等於任何 gate approval，不授權 merge／release。Delivery 的 $pr-lens 僅於外部 scratch 為 actual diff 產生本地 review map，不修改 repo `.pr-lens`／config 或 upload。

執行契約見 [Plan](../../plan/github-graphql-infra-foundation/github-graphql-infra-foundation.plan.md)，設計見 [Technical Spec](technical-spec.md)。
