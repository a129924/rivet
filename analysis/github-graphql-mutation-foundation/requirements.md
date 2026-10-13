# GitHub GraphQL Mutation Foundation：需求

## 意圖與責任

Topic：`github-graphql-mutation-foundation`。在既定 non-BC `GitHubIntegration` 提供 internal、可驗證的 authenticated GraphQL Mutation execution。同 target 呼叫端提供 typed Mutation 與 variables，取得單次 GraphQL response 或既有 technical failure。這是技術能力切片，不新增 BC 或產品寫入功能。

## In Scope

- Internal Mutation 入口、既有 Apollo executor seam 的必要擴充。
- Request-local Bearer、parser 前 HTTP status 分類、401-only 一次 recovery、原操作保真。
- 合法 partial／errors-only response、technical errors、取消、provider single-flight 與 snapshot version。
- Mutation 不讀寫 cache、不使用 APQ、不引入隱藏 retry。
- Query／REST／provider／隔離／consumer regression，以及長期文件與既有圖表交付文案同步。

## Out of Scope

Public API、跨 target 使用、composition root、BC Adapter、產品 operation／DTO、codegen pipeline、Files Viewed／resolve thread／review submission／merge、UI、Subscription／streaming／incremental response、pagination、rate limit、一般 retry／backoff、新 credential lifecycle／PAT／Keychain／初次 OAuth 授權整合、Apollo 升級、新 dependency、通用 GraphQL abstraction、業務 idempotency／補償／遠端結果 reconciliation。

## Acceptance Criteria

1. 同 target 呼叫端可執行符合 SingleResponseFormat 的 typed Mutation 並取得 GraphQLResponse。
2. 每次發送使用當次 snapshot 的 request-local Bearer。
3. 首次實際 HTTP 401 將完整 used snapshot 交給 provider。
4. Replacement 成功後重送原 operation／variables，只替換認證；每次 execution 最多兩次發送。
5. 第二次 401 回報 authenticationRequired，無第三次發送。
6. Provider failure 保留 restore／refresh／persist technical stage；非法 initial／replacement token 沿用既有分類，不再發送。
7. Empty／non-JSON 401 在 parser 前辨識；其他非成功 HTTP status 沿用既有分類且不 recovery。
8. 合法 partial／errors-only response 保留，不以 payload error 啟動 recovery。
9. Timeout、transport／parse failure 不重送。
10. 各 await 前後保留取消 checkpoints 與正規化；觀察到取消後不開始後續 recovery／發送。
11. Caller 取消不取消 provider shared refresh，不承諾 provider await 立即返回。
12. Query／Mutation 共用 provider 保留 single-flight、snapshot version 與 late stale 401。
13. 真 Apollo chain 驗證零 cache read／write、無 APQ fallback 或額外 retry。
14. Query／REST／provider／隔離／consumer regression 維持；不擴張 public API、BC behavior／契約／依賴或產品寫入能力。

## 限制、文件與交付

取消或 transport failure 不保證遠端未執行寫入，也不提供 rollback。合法 partial response 可能已含寫入結果；client 不自動 replay 或宣稱交易原子性。不要求真實 GitHub 寫入作為驗收。

長期文件只同步實際技術交付狀態，包含兩份 BC 文件的 integration 狀態句；工具只提供限定探索、圖表驗證與審查支援，不新增產品能力。

使用者已授權 feature worktree 內實作，無重大問題時直接依 topic commit、push、建立 Draft PR，最後 Human review；仍須先完成正式 planning、測試與獨立審查 gates。若需要越過 locked scope／path／contract，回報具體 gap，不自動擴張。
