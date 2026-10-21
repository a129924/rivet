# GitHub 初次登入與驗證工具契約

日期：2026-10-21；本文件保存 PR #63／M04 原樣重用的既有能力，不新增架構決策。非 BC 的 GitHubIntegration 邊界不變；既有 credential 的 refresh／401 lifecycle 見[雙 Client 契約](github-oauth-dual-client.md)。

## 已納入本 PR 的初次授權

`GitHubOAuthAppConfiguration` 接受 caller 提供的非空 client ID／secret，description／mirror 不暴露原值；它不規定終端使用者輸入。`GitHubOAuth.makeAuthorizationSession(configuration:redirectURI:)` 建立隨機 state／verifier 與 exchanger，session actor 擁有一次 attempt，只允許一次 code exchange。`makeTokenFetcher(configuration:)` 串接既有 refresh fetcher，未改 provider ownership。

Session 使用 S256、既定 offline_access scope、300 秒期限，以及 http／固定 IPv4 127.0.0.1／動態 port／固定 `/oauth/callback` 路徑。callback 的 redirect／state／code 條件、denial、取消、逾時及重複完成維持既有檢核；exchange 經 GitHub token endpoint，有限錯誤不暴露原始 token 或 response。這是既有 runtime 搬入，不表示 GitHub 反向 PKCE enforcement 已證明。

## 驗證 host 的 app-local 責任

`apps/GitHubSignInVerification` 為獨立 macOS 15／Swift 6／ad hoc／非 sandbox 驗證 host，並非 Rivet 正式產品入口。host 組合 loopback relay、session、記憶體 credential store、既有 provider／scope 及 account probe；成功須 GET `/user` HTTP 200、正整數 id、trim 後非空 login，不能只以 callback、token 或 prepare 完成判定。

保留自動預設瀏覽器路徑，另有 M01 app-local 手動路徑：同 attempt 的授權網址僅記憶體供 Human 複製，在獨立 browser session 完成登入與授權。300 秒後及取消／失敗依既有清理契約終止；不建立額外協定或持久化。

M02 composition 只讀 `RIVET_VERIFY_GITHUB_CLIENT_ID`／`RIVET_VERIFY_GITHUB_CLIENT_SECRET`，配置完整才建立 live dependencies，畫面隱藏憑證輸入。缺設定或 unit-test mode 使用 disabled dependencies；scheme 的 `GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE=1` 供 hosted mock tests，不啟動真人 OAuth。

[一次性 launcher](../../experiments/E009/LaunchVerification.swift)只由開發端管理者在未錄製 TTY 隱藏輸入設定，經 launch environment 供給，無秘密 args／檔案／log。它核對 bundle／binary SHA、拒絕既有同 bundle App、核對新程序身分；不讀舊 process 設定，不自動終止 App。launcher 的編譯、驗證與本 PR build 命令見[E009 M04](../../experiments/E009/README.md#m04-同一-pr-的重現與建置2026-10-21)。

## 來源、驗證與限制

M04 精確清單見[本 topic 契約](../../plan/github-account-login-feasibility/github-account-login-feasibility.plan.md#m04-將驗證程式碼交付到同一-pr-632026-10-21-增補)：20 檔原樣取固定 `9f603f81d77040a2e06ad178062e8cfecc4de468`，另 6 檔使用 hash 核對的 M02 snapshot。未搬入原 source worktree 的 PKCE tools、fixtures 或 planning，更不依賴 PR #61 合併。

[A07 與 E009 的證據分層](../github-account-login-feasibility.md)維持：E009 M03 僅為 Human 證據層級的受限成功，沒有 agent 全程 UI 或 network trace。M04 重建／mock／launcher synthetic 檢查不是新真人重驗；M03 原 binary `990917ac…` 不被本次新 build 取代。

正式產品入口、OAuth credential 持久化、production secret custody、其他 BC 整合與完整 PKCE gate 均未交付；不新增任何真人授權或解除 Human review。
