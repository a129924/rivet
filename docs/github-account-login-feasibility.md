# GitHub Account Login 可行性結論

日期：2026-10-21；Topic：`github-account-login-feasibility`。

## 問題與結論

當 Rivet 開發端準備有效的 GitHub.com OAuth App 設定時，終端使用者能否只經 GitHub 登入與授權，由程式交換 token、確認帳號，而不用自行註冊 App、輸入 client ID／secret 或貼 token？

**這條技術路線可行；本次不需要新實驗。** 此結論適用於有效 App 設定、既定 callback 與允許存取帳號資料的授權條件，不代表正式零配置登入畫面已交付或經本輪真人驗證。

終端使用者免配置與 OAuth 完全不使用 App 憑證是不同命題。本結論只支持前者的技術可行性。

## 官方契約與配置責任

2026-10-21 查閱的 [GitHub OAuth web flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#web-application-flow) 以 App client ID 發起授權，使用 client ID／secret 與 authorization code 交換 token，再以 token 呼叫 `/user` 確認身分。PKCE 不免除 web flow 的 secret 要求；單純瀏覽器返回不構成帳號確認。

[GitHub REST 認證文件](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api#using-basic-authentication) 區分 App credentials 與授權使用者。由開發端準備 App 設定、使用者只處理 GitHub 登入與同意，符合該配置模型；這是文件與程式結構推論，不能寫成零配置產品 UX 的真人觀察。

## 原碼與歷史證據

本輪讀取固定來源 `90646c21bd9e6f0f19644f04efa39ef1c033a139`。這些來源屬既有實作 lineage，不在本 topic 的 dev 基線；此文件沒有將其程式碼帶入 dev。

| 證據 | 支持範圍 |
| --- | --- |
| [App configuration](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift#L7) | caller 可提供配置；initializer 不要求設定來自終端使用者畫面。 |
| [OAuth composition](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift#L12) | 配置進入正式 session 與 code exchange 路徑，token 可由程式取得。 |
| [Account probe](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift#L20) | GET `/user` 必須 HTTP 200、正整數 id、非空 login，才判定有效帳號。 |
| [A07 保存紀錄](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/plan/github-first-sign-in/evidence/verification-host-amendment.md#L60) | 記錄執行版本 `e941d88` 的真人授權、真實 `/user` 及同程序再次查詢成功；當時 Human 手填驗證 App 配置。 |

`90646c21…` 是保存紀錄及本輪原碼的來源 pin，`e941d88` 是 A07 的執行版本。兩者不可混用，也不能把歷史觀察當成目前版本的重驗。

本 topic 基線為 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`；[該版 README](https://github.com/a129924/rivet/blob/16606b89b8e3e6b61523c23aa0be9653c1ea7b44/README.md) 仍將首次 OAuth／產品登入列為 deferred。既有分支已具授權能力，不等於本基線已有正式產品入口。

## 證據限制與決策影響

- 已有正向證據支持授權、token exchange 與有效帳號查詢；完整零配置 UX 未經本輪真人驗證。
- [原 topic 帳本](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/plan/github-first-sign-in/github-first-sign-in.step.md#L1) 的 P／Q 反向 PKCE 各 2／2 預算耗盡且 indeterminate，保留原判讀與 Human-review 限制。本 topic 不重跑或宣稱解除。
- PR #61 僅為既有實作與歷史證據來源，不是本次分支、合併或審查的前置依賴。
- 公開發行的 native secret custody、持久化、多帳號、完整 refresh／401 與 repository permissions 未由本輪證明。[OAuth App 最佳實務](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app) 相關限制不因本結論解除。
- 曾提出的 `apps/Rivet` 產品 slice、launcher、UI、composition、產品測試及 S01–S06 已撤回，不是待執行工作。

## 為何不建立實驗

官方契約、caller-owned configuration 與歷史正向紀錄足以回答本次受限技術問題。沒有發現必須透過執行才能排除、且會改變技術選擇的新未知；產品入口尚缺屬交付缺口，不能作為建立 App 或新實驗的理由。

本輪沒有新增 Swift、實驗目錄、真人授權或產品測試。Build、測試通過、callback、圖表與文件驗證均不能單獨代替主要假設的證據。

未來只有先說清楚「要排除哪個決策未知」及「現有證據為何不足」，才重新依 feasibility-validation 設定假設、區辨操作、成功／失敗／無法判定條件及有限投入上限。最小實驗只能使用確認未占用的 `experiments/E###/`，本輪不預留編號。

## 追溯

- [需求與撤回紀錄](../analysis/github-account-login-feasibility/requirements.md)
- [固定來源與技術依據](../analysis/github-account-login-feasibility/technical-spec.md)
- [執行契約](../plan/github-account-login-feasibility/github-account-login-feasibility.plan.md)
- [狀態帳本](../plan/github-account-login-feasibility/github-account-login-feasibility.step.md)

## 後續本輪真人證據（2026-10-21 新增）

> **2026-10-21 更正（以此為準）：使用者隨後明確表示沒有遇到 GitHub 登入畫面，也沒有進行 GitHub 登入授權。L01「本輪新授權／正向重驗成功」判定撤回，狀態改為「無法判定」。以下原判讀只保留為已被更正的歷史，不是有效成功證據。**

文件交付後，使用者要求以既有驗證 App 進行正向真人重驗，並確認剛在本輪完成登入授權。agent 隨後只觀察結果布林：`apiSuccess=true`、`busy=false`、`failureVisible=false`、`identityDisplayed=true`。**此次既有工具的正常授權與帳號結果呈現重驗成功。**

執行 binary SHA-256 為 `648435704a5a335040cb8abc6ad0f1841304500c4b9ab2dd96d79b1af7078a31`，未重新 build，process 路徑比對相符；未建立與 source commit 的 build provenance。沒有抓取 raw HTTP／callback 或重發授權，因此 Human 新授權確認、UI 結果與原碼契約推論必須分開。

此補充不覆寫歷史 A07，也不把原文件階段的「未真人重驗」改寫成當時已完成。零配置產品 UX、公開發行與 PKCE enforcement 仍未獲證；PR review 亦未因登入成功而自動通過。詳見[本輪 L01 來源與限制](../analysis/github-account-login-feasibility/technical-spec.md#l012026-10-21-本輪真人正向重驗新增)。

### C01 更正與目前結論

使用者明確否認本輪有看到 GitHub 登入畫面或進行授權，故撤回上述 L01 成功判定。本輪狀態為**無法判定**，真人新授權路徑未完成驗證。UI 曾呈現成功與帳號結果的觀察保留，但沒有本輪流程關聯，不能證明新授權或新的帳號查詢，也不能推定畫面來源。技術路線的原文件／歷史依據仍僅在原條件內成立。詳見[判讀更正](../analysis/github-account-login-feasibility/technical-spec.md#c01l01-判讀更正2026-10-21)。

## M03：後續手動首次登入／授權的受限 Human 證據

使用者回報以工具提供的本次網址手動開啟，親眼看見登入頁並完成登入、看見授權頁並親自同意、到達 callback 提示，返回工具後看見 API 成功及帳號結果。另逐項明示確認：使用不共用登入狀態且原先未登入的獨立／無痕 session，測試帳號操作前未授權此 App，且是同一次 E009 新版手動啟動、300 秒內、未重啟／再啟動／改用舊網址。

**E009 判讀為受限成功**，依據是上述 Human 回報與補充確認，配合已查原碼的同一 session／callback／exchange／有效帳號契約。Agent 只獨立核對目前程序路徑、binary／source 指紋，沒有全程 UI 觀察或 network trace；目前正確 binary 不單獨證明整段歷史操作。精確起訖、互動 launcher 真實供給、啟動前主對話 ready 收據及 2FA 提示未獨立確認。

這是 C01 之後的新證據；C01 對 L01 的撤回與原 A07 保留。結果只支持本次被 Human 確認的首次登入／同意／帳號路徑，不代表完整零配置產品 UX、產品 readiness、production custody 或 PKCE enforcement；Human PR review 仍待決。完整分層、九欄與缺口見[本輪 E009 紀錄](../experiments/E009/README.md#m03-本輪手動真人驗證結果2026-10-21現行)。

## M04 可重現驗證工具交付現況（2026-10-21）

Human 後續明示將驗證程式碼加入同一 PR #63；前輪文件-only 限制在 M04 精確範圍內放寬，產品 B 仍撤回。此 PR 已搬入既有初次 OAuth 五檔、必要測試與完整驗證 host；六份手動入口／配置 snapshot 經 SHA 核對，另納入 E009 一次性 launcher，無需另取 PR #61 的 working tree 或等待其合併。長期契約見[初次登入與驗證工具](architecture/github-first-sign-in.md)，本 PR build／操作見[E009 M04](../experiments/E009/README.md#m04-同一-pr-的重現與建置2026-10-21)。

本次只做重建、mock 與 synthetic 檢查，未啟動真人 OAuth；M03 Human 證據及原 binary 指紋不被新 build 覆寫。正式產品入口、持久化、production custody 與 PKCE 限制保持；獨立 Tester／Reviewer、同 PR Git 交付與 Human review 仍待實際完成，不預填 gate。

#### M04 獨立檢查結論與交付範圍

Tester 的最終 hosted mock 為 17 definitions／18 executions、0 failures，binary 重新凍結 RF01 已解除。獨立 Reviewer 在 architecture overview 的現況句修正後明示 approved、required fixes=[]；只審本 38 paths，不代表產品採用或新真人成功。M04 準備按既有授權提交／推送原分支、交同 PR #63；PR metadata 待主方更新與讀回，尚不宣稱已更新 PR。M03／C01／PKCE 與 production 限制保留，Human review 不自動通過。

#### M04 同分支交付收據（2026-10-21）

驗證工具與既有依賴已以 `7cc4f35b90d07a2dc0160c7354a1c636cc414d18` 提交並 push 原分支，交同一 PR #63；精確 38 paths，六 commit hooks 全 pass。獨立 Tester 已解除最終 binary 重凍結 RF01，Reviewer 修正架構總覽後 approved、無 required fixes。PR metadata／實際 Draft 與 head 讀回待主方完成；本筆不聲稱已更新 PR 說明或 Human 已接受，不 merge。M03 Human 層級受限成功及產品／PKCE／custody 限制維持。
