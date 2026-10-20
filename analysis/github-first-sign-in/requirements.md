# GitHub 首次登入與當次 API 使用：需求

- Topic：`github-first-sign-in`。
- 更新：2026-10-20，Plan-Creator；正式 planning 初稿，尚未取得獨立 Plan-Reviewer verdict。
- Branch：`feat/github-first-sign-in`；base／Draft PR target：`dev`。
- 配對：[technical-spec](technical-spec.md)、[plan](../../plan/github-first-sign-in/github-first-sign-in.plan.md)、[step](../../plan/github-first-sign-in/github-first-sign-in.step.md)。

## Goal

單一使用者從正式本機 Rivet.app 輸入個人自有 GitHub.com OAuth App 配置，經系統預設瀏覽器完成授權；取得符合既有模型的完整 credential bundle 後，當次程序使用既有 provider／scope 執行 `GET /user`，呈現實際 `login` 與 `id`，並能再次查詢。

成功不是只收到 callback、取得 token 或本地 prepare 完成。取消、拒絕、逾時及失敗均提供明確結果與重新開始的路徑；過期事件不得完成其他登入嘗試。

## In-Scope

- macOS 15／Swift 6 正式本機 app host、最小登入及 API 結果呈現。
- 個人 OAuth App 的 client ID／secret 程序內配置、loopback callback、state、S256、初次 token exchange。
- 完整六欄 bundle 程序內 store、caller-owned provider、既有 ready scope 與同程序多次唯讀 API 操作。
- 取消／授權拒絕／五分鐘逾時／重複及遲到 callback／交換與 API 失敗處理。
- TC01–TC09 的受控測試、明確分列的 Human 真實驗收、脫敏證據與長期文件／圖。
- 每次 `swift-implementation` bounded step 及完成交接均列九欄；此名稱為階段稱呼，不聲稱有同名 skill。

## Out-Of-Scope／Non-Goal

不新增 BC；不實作 Keychain／SQLite／DPK adapter、跨重啟恢復、資料遷移、多帳號／切換、PAT、Enterprise、device flow、broker、完整登出／remote revoke、PR Inbox／Reader 資料、一般 retry／pagination／rate-limit framework、公開發行或 notarization。

不重做 refresh、rotation、single-flight、snapshot、401 recovery；不新增 provider disposition API。不宣稱 `/user` 成功證明 repository permission、所有 refresh／401 路徑已取得遠端實證，或釋放本地狀態即撤銷遠端 token。

## 已鎖定決策

1. GitHubIntegration 是 non-BC，產品入口與組合屬 Application／Presentation；不改既有 BC 邊界。
2. 個人自有 OAuth App，在 Rivet 內輸入 client ID／secret；secret 與完整 credential 僅程序內，不落盤、不進 logs／證據。不能使用 gh credential 代替產品 OAuth，不自行尋找或讀取 secret。
3. 正式本機 Rivet.app 使用 macOS 15／Swift 6、ad hoc／Sign to Run Locally、首版 non-Sandbox；不要求 Apple Development／profile／DPK。這不是長期發行安全決策。
4. callback 固定 IPv4 loopback、動態 port、`/oauth/callback`；採 S256，單一 active session、五分鐘期限；不改走 ASWebAuthenticationSession、自訂 scheme 或 HTTPS 替代路徑。
5. 只請求 `offline_access`；`/user` 只讀公開身分 login／id，不索取 read:user 或 repo scopes。回應 scope 字串可為空，不以包含 offline_access 字串作為 bundle 驗證要求。
6. 既有 bundle、OAuthCredentialStore、OAuthTokenFetcher、OAuthTokenProvider、GitHubClientScope 與雙 client 契約不變；完整程序內 store 不等於現有單 token store。
7. 兩 Mission 已由 Human 分開：本 topic 獨占首次登入至當次 API；`github-persistent-connection` 負責保存／重啟／儲存採用及未來合流。詳細 ownership amendment 與來源 SHA 見 technical-spec §6，須獨立審查，不能自填通過。
8. 使用者已授權專用 feature worktree 實作，以及無重大問題時 `commit → push → Draft PR → Human review`。受控 tests 與獨立 review 仍為交付前置；需個人 secret／互動的真實 OAuth 與反向 PKCE 留 Human review pending，不阻擋已授權 Draft PR。不能 merge。

## Acceptance Criteria

| ID | 結果 | 證據層級 |
|---|---|---|
| AC01 | 正式 app 可發起授權，只有相符且單次有效 callback 進入交換 | 受控＋Human live |
| AC02 | 完整有效六欄 response 才交付 bundle，交換失敗不交付連線 | 受控＋Human live |
| AC03 | 同程序由同 provider／scope 多次 GET /user，結果含實際 login／id | 受控＋Human live |
| AC04 | 取消、拒絕、逾時與失敗後可重新開始；舊事件不污染新嘗試 | 受控＋適用的 Human 操作 |
| AC05 | 本地 prepare、HTTP／decode 失敗均不冒充遠端成功；失敗可再操作 | 受控 |
| AC06 | 不保存 secret、tokens、bundle、code、verifier、完整 callback 或原始交換 body 至磁碟／logs／證據 | source／transport 設定／受控檢查 |
| AC07 | 完整結束再啟動回到未連線；交付不依賴持久化 adapter 或 E007 | 受控／本機啟動 |
| AC08 | 正向 S256 與獨立新 code 的缺失／錯誤 verifier 反向結果分列，不重用 code 製造假陰性 | Human review pending，不能預填 |

AC01–AC03 的 live 部分與 AC08 未驗證時，Draft PR 明示 pending；不能把它寫成 topic 已完成或宣稱真 GitHub 通過。

## 依據與未知界線

[既有 OAuth 架構](../../docs/architecture/github-oauth-dual-client.md) 與 [scope step](../../plan/github-client-scope-composition/github-client-scope-composition.step.md) 是既有契約依據。E001 證明獨立 loopback callback，E002 正向證明六欄與 /user，反向 PKCE 仍未定；E003 是受限 refresh／rotation 實證，均不取代正式 app 驗收。

GitHub 官方：[OAuth authorization／offline_access／S256／loopback／secret](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)、[/user 與 private response scopes](https://docs.github.com/en/rest/users/users#get-the-authenticated-user)。本 topic 沒有待補造的重大產品決策；個人實際配置與 live 結果仍待 Human。
