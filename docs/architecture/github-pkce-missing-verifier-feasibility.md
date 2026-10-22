# GitHub PKCE missing-verifier 補證與證據界線

`GitHubIntegration` 是 non-BC shared integration。本文件記錄外部授權協定的補證界線，不新增產品能力或修改正式 OAuth／credential／provider／scope／refresh／401 契約。

## 契約與觀察分開

GitHub 公開契約要求送出 challenge 的交換附上原 verifier，且支援 S256，見 [OAuth Apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)／[GitHub Apps](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app)。[RFC 7636 §4.5–4.6](https://www.rfc-editor.org/rfc/rfc7636.html#section-4.5)說明 verifier／challenge 驗證；[RFC 6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2)亦允許 invalid_grant 表示其他 grant 問題。

因此應分開保存「GitHub 是否拒絕」、「provider 聲稱的原因」與「當次條件能支持的結論」。HTTP 狀態、錯誤碼、無 token、關鍵字及本機 prepared 一致性，均不足以單獨證明遠端 PKCE 原因。

## 本輪有限結論

2026-10-22，來源 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4` 的文件／原始碼調查，確認既有 missing 工具會省略 verifier，工具 SHA 與 X 凍結來源一致；未查得必須修改工具的缺口。詳細依據見[新 topic 調查](../../plan/github-pkce-missing-verifier-feasibility/evidence/document-source-investigation.md)。

本輪新真人實驗為**未執行**，OAuth／code／exchange 均 0。歷史 missing 的當次拒絕歸因仍無法判定；wrong 的單次 mismatch 聲明不移作 missing 證明。真 client 類型及目前配置適用性未確認，沒有新 provider 原文或遠端結果。

現有 CLI 的 token_present 只表示鍵存在，不能冒充完整成功契約。provider 若說 mismatch，只能如此記錄，不能改寫為明言缺少 verifier；獨立語義結果不得覆寫 CLI 原始分類。這些限制不構成正式 OAuth bug，也不增加既有登入 UI 的阻塞條件。

## 受限工作流與後續邊界

[互動流程圖](diagrams/github-pkce-missing-verifier-feasibility/missing-verifier.html)表達文件優先、另行真人／原文授權、單次交換、雙盲判讀及停止界線；圖是操作契約，不是本輪真人操作已發生的證據。作者內容為繁體中文，固定 Viewer UI 與 HTML lang 使用英文 fallback。

[新 topic 計畫](../../plan/github-pkce-missing-verifier-feasibility/github-pkce-missing-verifier-feasibility.plan.md)及[帳本](../../plan/github-pkce-missing-verifier-feasibility/github-pkce-missing-verifier-feasibility.step.md)獨立保存本輪交付，不改寫舊 topic planning／evidence。

未來如需真實補證，須另確認配置與資訊增益，並明確取得一次新授權／一個新 code／單 exchange 及完整單欄原文的可見性／手動傳遞授權；不沿用舊額度或同意，不補次。任何 token 鍵存在立即停止，不使用或保存 token。可信反例或工具修改需求交原變更流程，不自動擴張。
