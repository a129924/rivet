# GitHub Account Login 可行性技術依據

日期：2026-10-21。對應[需求](requirements.md)與[執行契約](../../plan/github-account-login-feasibility/github-account-login-feasibility.plan.md)。

## 結論與適用條件

開發端準備 App 設定時，終端使用者不必各自註冊 App、輸入 client ID／secret 或貼 token，既有 OAuth 授權、code exchange 與有效帳號確認路線可行。開發端配置責任的拆分是文件／程式結構推論，不是本輪零配置 UX 真人觀察。產品入口尚缺不構成新技術未知，也不授權建立 App。

## 來源與證據分類

官方文件於 2026-10-21 核對；原碼及歷史紀錄固定至 `90646c21bd9e6f0f19644f04efa39ef1c033a139`。下列 GitHub permalink 指向固定版本，並非本 branch 的本機檔案或目前 PR HEAD。

| 分類 | 來源 | 支持內容與限制 |
| --- | --- | --- |
| 官方事實 | [OAuth web application flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#web-application-flow) | authorize 使用 App client ID；token POST 要求 client ID／secret，PKCE 不免除 secret；流程包含 verifier／state 與 token 後的帳號確認。 |
| 官方事實／推論依據 | [REST basic authentication](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api#using-basic-authentication) | App credentials 屬於 App，不是 owner 或 authorizing user；由開發端提供設定符合此模型，但不是零配置 UX 實測。 |
| 原碼事實 | [App configuration](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift#L7) | public init 接受 client ID／secret 並檢核 trim 後非空，未規定由終端 UI 輸入。 |
| 原碼事實 | [OAuth composition](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift#L12) | configuration／redirect URI 建立 session、exchanger 與 state／verifier，支持程式自動 exchange 路線。 |
| 原碼事實 | [Account probe](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift#L20) | GET `https://api.github.com/user`，僅 HTTP 200、正整數 id、trim 後非空 login 為有效帳號；callback 或 token 單獨不足。 |
| 歷史觀察 | [A07 保存紀錄](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/plan/github-first-sign-in/evidence/verification-host-amendment.md#L60) | 記錄 2026-10-21／`e941d88` Human 手填驗證 App 配置後，真人 callback、真實 `/user` 及同 process 再次 `/user` observed pass。此 agent 未重跑或保存憑證值。 |
| 歷史限制 | [既有 topic ledger](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/plan/github-first-sign-in/github-first-sign-in.step.md#L1) | P／Q 各 2／2 反向 PKCE 預算耗盡且 indeterminate；後續 R05 approved／R06 Human review、R 0／1 未用僅屬文件調查，不是本 topic 前置 gate。 |
| 發行限制 | [OAuth App 最佳實務](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app) | native 隨附 secret 不可視為 server secret；公開發行 custody 未在本輪驗證，不提出新方案。 |

歷史 A07 的執行版本是 `e941d88`；`90646c21bd9e6f0f19644f04efa39ef1c033a139` 是本輪讀取其保存紀錄與原碼的來源 pin，兩者不混用。

## 分支與產品狀態限制

本次工作 base 為 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`；[base README](https://github.com/a129924/rivet/blob/16606b89b8e3e6b61523c23aa0be9653c1ea7b44/README.md) 仍將首次 OAuth／產品登入列為 deferred，不能因外部分支存在程式就宣稱 dev 已交付。

前輪 `dev@16606b8`、feature `82489b6`／`21e2542`、PR #61 Draft 未合併只是歷史快照。本 topic 不刷新其現況、不以其 merge 或 Human review 為依賴，也不修改其 artifacts。

## 是否需要實驗

不需要新實驗：官方條件、固定程式結構及歷史正向觀察已足以回答受限路線可行性。這不是宣稱完整產品驗收成功；build／tests／callback 不可單獨替代假設驗證。

`swift-implementation` 為 N/A。只有未來另有具體決策未知，且能說明既有證據不足，才依 feasibility skill 固定假設、區辨操作、成功／失敗／無法判定判準及有限預算，確認未占用 E### 後僅建立必要實驗素材與八段 README。開始前預定完整九欄，完成後依 actual diff／觀察回填；Written／Modify／Deleted 依實際缺口決定。此條件不是本輪新任務授權，不預選編號或虛構 manifest。

## 工具界線

Graphify 未見既有 `graph.json`，已用定向 `rg` fallback，未執行 Graphify CLI／建圖。若日後需要，只用既有圖、pin 0.9.73、每次 CLI 設 `GRAPHIFY_NO_AUTO_REFRESH=1`，重要關係回查 source。

本輪文字足夠，Archify 2.16 不產圖；若未來真需 sequence，先說明排除哪個未知與文字為何不足，遵守 showcase 九 checks、零 error／warning、validate／deliver／visual-check、繁中作者內容、英文 viewer fallback、本機不發布。任何圖均不是 OAuth 實驗證據。

PR Lens 0.11.0 用本 topic 真實五文件 diff，詳執行契約；無 config 時不假設存在，不自動安裝、上傳或改配置。

## L01：2026-10-21 本輪真人正向重驗（新增）

- 觀察紀錄時間：2026-10-21 06:15:08 UTC。這是後續使用者要求的既有工具重驗，不是新產品交付或新的 PKCE 實驗。
- 事前範圍：最多一次新授權，成功必須看到有效帳號與 API 查詢成功；取消、逾時或錯誤即停止，不自動重試。不安排反向 PKCE、refresh／401 或額外再次查詢。
- Human 明示確認：「是，我剛在這輪完成登入授權」。這項確認用來區別本次新授權與先前留下的成功畫面。
- agent 在 Human 確認後以 AX 僅輸出結果布林：`apiSuccess=true`、`busy=false`、`failureVisible=false`、`identityDisplayed=true`。
- 判讀：**本輪既有驗證 App 正向重驗成功**。Human 確認新授權，agent 觀察到有效帳號結果呈現；不是由 callback 或 build 單獨推定。

### 執行物與來源界線

使用既有 GitHubSignInVerification.app，未重新 build；唯讀 process 檢查確認與預期 executable 路徑相符。其 binary SHA-256 為 `648435704a5a335040cb8abc6ad0f1841304500c4b9ab2dd96d79b1af7078a31`。本輪未建立 binary 與目前 source checkout 的一對一 build provenance，因此不把此結果冒稱為 90646c21、e941d88 或其他 source commit 的重驗。

agent 沒有重新觸發授權或操作「再次查詢」。本次沒有擷取 raw HTTP status／response、token POST 或 callback；正常授權依 Human 明示，帳號查詢結果依驗證 App UI 與已查原碼契約判讀，不冒稱獨立 network trace。

沒有確認本輪設定由誰於何時輸入；既有工具仍包含配置欄位。因此此證據不證明終端使用者零配置產品 UX、Production custody 或 PKCE enforcement。P／Q／後續反向驗證的舊結果與耗盡預算不變，不據此追加負向授權。

repository 紀錄不保存 client ID、secret、帳號原值、token、code、state、verifier、callback URL 或 screenshot。結果只保存 Human 確認、上述四布林、時間、binary 指紋與限制。原 A07 與文件階段的歷史事實不改判。
