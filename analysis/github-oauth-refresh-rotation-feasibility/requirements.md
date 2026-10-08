# E003：GitHub OAuth refresh exchange 與 rotation 相容性驗證 — Requirements

- Topic：`github-oauth-refresh-rotation-feasibility`；實驗 ID：`E003`。
- 狀態：原 E003 計畫與 PR #48 thread 3 的 bounded amendment 均已獲獨立 Plan-Reviewer `approved`；R03 唯一 docs append 已完成，R04 Tester 尚待。PR #48 目前 Ready，人類審查仍 pending。
- 日期：2026-10-08。
- 配對文件：[technical-spec](technical-spec.md)、[plan](../../plan/github-oauth-refresh-rotation-feasibility/github-oauth-refresh-rotation-feasibility.plan.md)、[step](../../plan/github-oauth-refresh-rotation-feasibility/github-oauth-refresh-rotation-feasibility.step.md)。

## Goal 與研究依據

以 GitHub.com OAuth App 的一組新授權 credential，測量一次 refresh exchange 能否產生符合既有 public `GitHubOAuthCredentialBundle` 的新 token pair；確認新 access token 對應同一使用者，且 rotation 後重用舊 refresh token 得到明確拒絕。這是 BC 外共用整合模組 `GitHubIntegration` 的受限可行性實驗，不新增 BC Mission。

[E002](../../experiments/E002/README.md) 已有正向 code exchange、六欄 bundle 相容與一次 `/user` 成功的遮蔽證據；其反向 PKCE 與總體「無法判定」保持獨立。E002 token 僅在當次程序記憶體，E003 必須新授權。GitHub 文件描述 refresh 產生新 token pair，舊 pair 隨後失效；真實 App 行為仍由本次測量判定。[GitHub 官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#refreshing-an-access-token-with-a-refresh-token)

## In-Scope 與 Out-Of-Scope

**In-Scope**：一次要求 `offline_access` 的新授權與初始 credential；初始 access token 一次 `GET /user`；一次正向 refresh；六欄與 public bundle 相容性；新 access token 一次 `/user`；正向成功後一次舊 refresh token 重用；遮蔽後的分項結果、限制、局部測試與一張 sequence 圖。

**Out-Of-Scope**：產品自動刷新、`OAuthTokenProvider` 整合、Keychain／持久化／跨程序還原、並行／single-flight、REST／GraphQL client、401 recovery／retry、舊 access token 驗證、等待真實到期、六個月失效、logout／revoke、多帳號與 E002 PKCE 反向補測。

**Non-Goal**：不宣稱正式 credential lifecycle、遠端 credential 撤銷、產品採用、E002 整體成功或 secret 配送方案已驗證。

## TestCase 與結論判準

| ID | Given／When | Then |
| --- | --- | --- |
| T01 | 新授權成功，以初始 access token 呼叫 `/user`。 | HTTP 200 且取得有效 user ID；ID 只留記憶體。 |
| T02 | 初始 refresh token 有效，執行唯一一次正向 refresh。 | 新 access／refresh token 均非空且各自異於舊值；六欄有效、兩期限為正、`token_type=bearer`，可建立 public bundle。 |
| T03 | 以刷新後 access token 呼叫 `/user`。 | HTTP 200，user ID 與 T01 相同。 |
| T04 | T02 成功後，唯一一次重用舊 refresh token。 | 可解析 `error=bad_refresh_token`，且未取得新 token；單憑 HTTP status 不算證據。 |

六欄為 `access_token`、`refresh_token`、`expires_in`、`refresh_token_expires_in`、`token_type`、`scope`。以回應接收時間加有效秒數建立到期 Date；refresh 前後 `scope` 依逗號分隔集合比較，bundle 保留原始 scope 字串。`offline_access` 是授權請求值，不要求出現在一般 granted scope。

四項皆符合才記總體「成功」。有效前置與可判讀回應下任一條件違反，記分項與總體「失敗」；設定、credentials、人工授權、網路或回應證據不足時，未能歸因的項目記「無法判定」，不得以泛用 HTTP／網路錯誤當作 T04 拒絕。局部 mock、build、圖或 PR map 均不替代真實測量。

## 人類邊界與交付

使用者明示先建立 feature worktree，僅在該 worktree 實作，不改 dev worktree；無重大問題時依 topic commit、push、開指向 dev 的 Draft PR，停止於 human review。實測仍需操作者本機隱藏輸入 secret、人工瀏覽器授權及 App／callback 環境確認；尚無這些前置證據時 HC-LIVE 維持 pending，不冒稱成功，也不阻已驗證 runner 的 Draft PR 交付。

2026-10-08 單次實測的 T01–T04 與 overall 均成功，遮蔽證據及限制見 [E003 README](../../experiments/E003/README.md)。此結果只支持本次 App／帳號的 refresh exchange、public bundle 相容、同一 user ID 與舊 refresh token 明確拒絕，不代表產品自動刷新、遠端撤銷或 E002 反向 PKCE 已驗證。

PR #48 thread 3 指出完成後仍成立的受限結論未回寫長期文件。此次 bounded amendment 經獨立 Plan-Reviewer 最終 `approved`、required fixes 無；R03 已只在 `docs/architecture/github-oauth-dual-client.md` 附加 E003 受限依據一小節並連結 README，原文件 bytes 保留，未改既有責任邊界、產品架構決策或 diagrams。R04 獨立驗證及後續成果審查 pending；既有 S09／HC-REVIEW 人類審查仍 pending。

此 docs gate 的 R03 變更清單只含四份 topic planning artifacts 與上述唯一 docs append；E003 README 是證據連結目標，不是 R03 可修改檔。PR #48 其他 threads 對既有 E003 source／tests／README／diagram receipts 的修正仍依原 E003 Written／Modify 契約分別驗證與審查，不藉本 amendment 擴大 docs gate。
