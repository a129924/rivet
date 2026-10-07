# E002：PKCE token exchange 與 credential 相容性驗證 — Requirements

- Topic：`github-oauth-pkce-token-exchange-feasibility`
- 狀態：使用者已批准對話計畫；四檔正式 Plan-Reviewer gate approved（Dispatcher 轉交獨立 review，2026-10-07）。
- 日期：2026-10-07。
- 配對文件：[technical-spec](technical-spec.md)、[plan](../../plan/github-oauth-pkce-token-exchange-feasibility/github-oauth-pkce-token-exchange-feasibility.plan.md)、[step](../../plan/github-oauth-pkce-token-exchange-feasibility/github-oauth-pkce-token-exchange-feasibility.step.md)。

## 問題、目的與研究依據

沿用 E001 的 GitHub.com OAuth App 與 IPv4 loopback callback，加入 PKCE S256，確認初次交換能否取得符合既有 `GitHubOAuthCredentialBundle` 的 credential，完成一次 `GET /user`，並以另一組新 code 測量錯誤 verifier 是否被拒絕。

[E001](../../experiments/E001/README.md) 只證明一次 redirect／code／state 流程成功，未交換 token。既有產品 schema 要求六欄 refreshable、expiring response。GitHub.com 支援單次登入要求 `offline_access`，無須修改全域 App 設定；該值不作一般 granted scope 判準。PKCE 支援 S256，但 code exchange 仍須 client_secret。[官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)

文件描述支援條件；E002 必須區分真實環境測量與局部 mock，不能從 mock 推論真實 App 的 token／PKCE 行為。現未提供 client ID／secret，App 設定與真實結果未驗證。

## 目標與邊界

In-Scope：E002 獨立 Swift runner、S256／state、code exchange、本地 DTO 建立真正 public bundle、一次 `/user`、局部測試、遮蔽紀錄、一張 E002 sequence，以及受限 Graphify／PR Lens 使用。

Out-Of-Scope：refresh rotation、Keychain、正式登入 UI、REST／GraphQL client 整合、secret 部署決策、放寬 schema、產品 OAuth adapter、Graphify 建圖／provider、發布或 merge。

成功只支持本次 token exchange、schema、API 與 PKCE 測量；不支持正式產品採用或 secret 配送。runner 的資料邊界不涵蓋瀏覽器與 OS 留痕，後兩者未驗證。

## 成功、失敗與無法判定

四軸分開記錄：正向 exchange、schema、API，以及反向 PKCE。各軸使用成功／失敗／無法判定與理由。

- 總體成功：正向取得 token、六欄嚴格相容且建成 public bundle、一次 `/user` 回 200 且有效 JSON user shape；另一組新 code 的錯誤 verifier 被拒絕，且受控條件排除其他原因。
- 總體失敗：前置條件正確且有效測量證明任一軸失敗。未完成的其他軸仍各自保留無法判定。
- 無法判定：沒有有效 failure，但 App／credentials／人工授權／網路／timeout 等阻止完成測量，或反向拒絕原因無法歸因。

反向收到任何非空 access／refresh token 均為 PKCE 失敗。不能以 HTTP status 單獨判斷，也不預設未經文件或實證確認的 OAuth error 是 PKCE 專屬訊號；`bad_verification_code` 必須受控排除 App／secret／redirect／state／過期或已消耗 code 等混淆。[官方錯誤說明](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)

## 使用者授權、交付與 Human Check

使用者已批准完整計畫及「先 create-feature-worktree，只在 feature 實現，不得 dev 任何檔；無重大問題直接 commit by topic → push → human review」。工作只在 feature worktree，branch 為 `chore/github-oauth-pkce-token-exchange-feasibility`，基底 dev／origin/dev 為 `a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f`。

交付已局部測試與獨立審查的實驗 runner、README、sequence 證據及正式 artifacts。HC-LIVE 可 pending，不阻擋 runner 的 commit／push／human review；不得冒稱實驗成功或擅自觸發真實瀏覽器。真實測量須另安排使用者 TTY／瀏覽器互動，secret 不經聊天，不讀取既存 secret。

未真實測量時不修改 OAuth 長期文件。只有實證與獨立成果審查完成後，才允許附加仍成立的受限結論，不改既有架構。

## A001：追加圖修復預算

2026-10-07 — 使用者明確批准「追加最多兩輪圖修復，維持原驗收標準（建議）」。此為限定的預算追加，不延期或豁免 mandatory 圖驗收、不改 OAuth scope。原兩輪失敗與既有證據缺口保留；原預算 2／2 已用盡，追加預算使用 1／2（原 2／2、累計 3／4），總計最多四輪。

A001 獨立 Plan-Reviewer approved／無 required fix；A05 獨立 Reviewer 已對 runner＋v3 完整交付明示 approved，四 captures 實看可讀平衡、語意正確，HC-DIAGRAM 已解除。v1／v2 失敗與 provenance 缺口保留為歷史，不阻 v3 matching 來源交付。真實授權仍 0／2，HC-LIVE pending；既有 commit／push 授權有效；S06 commit 819184f6ddebe05090608a11da602a67e247b5df 已完成／六 hooks 通過、S07 PR Lens approved。當前為 S08 metadata 收尾 commit 前／push 前 snapshot，S09 final coverage 與 S10 push pending，未預寫新 SHA。
