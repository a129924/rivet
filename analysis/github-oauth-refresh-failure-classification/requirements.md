# GitHub OAuth refresh 失敗分類需求

## Goal

基於已合併 PR #48／E003，補上 OAuthTokenProviderError.refresh(underlying:) 無法可靠區分憑證失效與技術失敗的缺口。由 GitHubIntegration 的 internal HTTP refresh adapter 提供 public typed failure，provider 管理 lifecycle，既有 internal GraphQL client 映射 technical outcome。

## Human 決策與授權

- 2026-10-08：接受 OAuthTokenFetcher typed throws 的 source-breaking migration。
- Rotation 狀態未知時停止此 provider、保留 store，回傳技術失敗；恢復限外部重新授權、保存新 bundle、建立新 provider。
- 只在 feature worktree 實現；branch 為 feat/github-oauth-refresh-failure-classification，不修改 dev worktree。
- Human 最新明確要求「請直接 commit by topic -> push -> open Draft PR -> human review」。本 topic 視為 commit／push／Draft PR 的直接授權；仍先依 staged diff 檢查語意邊界並提出 message，不另要求相同動作的確認。不得 merge。

## In-Scope

Typed refresh contract、internal HTTP adapter、provider／GraphQL mapping、conformer migration、離線測試、長期文件、責任 canvas／lifecycle v7，以及本機 PR Lens review artifact。

## Out-Of-Scope／Non-Goal

REST GET、產品登入、初次 token exchange、Keychain credential adapter、device flow、secret 部署、credential reconciliation、一般 retry／rate limit policy、其他 BC／Presentation、generic HTTP package source、真實 OAuth 請求與發布圖表。

## 保留決策

Access-expiry-first、single-flight、snapshot version／stale recovery、accepted rotation 先 persist 再 publish、persist failure terminal、HTTP 401-only 最多重送一次。不預檢 refreshTokenExpiresAt。既有兩次成功 rotation／persist 後仍過期的 exhaustion 保留為 nonterminal technical failure。

## 證據與限制

PR #48／E003 曾觀察 HTTP 200 body bad_refresh_token；不能只用 status 分類。E003 沒有實測等待真實到期或撤銷。GitHub refresh 成功會使舊 token pair 失效，response 遺失可能使 rotation 狀態未知。

- [PR #48](https://github.com/a129924/rivet/pull/48)
- [GitHub OAuth refresh 文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#refreshing-an-access-token-with-a-refresh-token)
- experiments/E003/README.md

## 成功條件

technical-spec 的 failure／state／cancellation 契約、plan 的 exact allowlist 與 TC01–TC12 均交付；獨立驗證與審查完成後提交同 topic、push、建立以 dev 為 base 的 Draft PR，停在 human review。
