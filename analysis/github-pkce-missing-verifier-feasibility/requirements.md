# GitHub PKCE missing-verifier 受限補證需求

- Topic：`github-pkce-missing-verifier-feasibility`
- 日期：2026-10-22。
- Branch：`chore/github-pkce-missing-verifier-feasibility`；基線／PR target：`dev`。
- 來源基線：`origin/dev`，`fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`。
- 類型：non-BC `GitHubIntegration` 外部授權協定的受限可行性補證，不新增 BC。

## Goal

維護者要釐清：在目前適用的 GitHub 配置下，帶有效 S256 challenge 的新授權，於 token exchange 省略 verifier 時，當次拒絕是否有足夠證據歸因於 PKCE 驗證要求。交付可追溯的事實、推論、適用條件與決策限制；不以填寫紀錄取代調查與判讀。

## Non-Goal

不交付正式登入 UI、帳號管理、公開 API 或正式 OAuth 行為修改；不重做正常登入、API、wrong-verifier、持續連線、refresh／401、憑證保存及 profile renewal 驗收，不建立通用診斷或翻譯框架。

## In-Scope／Out-Of-Scope

| 標籤 | 邊界 |
| --- | --- |
| In-Scope | 一輪有範圍的文件／原始碼調查、工具適配與安全前提核對、必要性判斷、有限結論及 workflow 圖交付。必要且另獲授權後，才進行一次 missing-verifier 真人操作及獨立語義判讀。 |
| Out-Of-Scope | 正式能力修改、工具修改、正向對照授權、歷史回應重建、舊 code、自動重試、補次、補發授權、下一輪研究。 |

## 已知依據與證據缺口

[README](../../README.md)保留既有歷史：missing 曾遭拒但原因無法判定；X 輪來源 `4dbf3df` 的 wrong-verifier，只支持當次拒絕及 provider 的 mismatch 聲明，不能代替 missing 證據。不追補未保存的原始回應。舊 live 額度及原文同意均不延續。

Observer 已交接本輪官方契約與工具來源的唯讀查證，尚待 M03 正式證據交付；不能將本計畫當成調查紀錄完成。正式 OAuth／credential／provider／scope／lifecycle 決策維持；本 topic 不成為既有登入 UI 的新阻塞條件。

## 驗收條件

1. 先明示主要假設、決策影響及缺口，再決定是否有實驗必要性與可靠資訊增益；文件足夠就不建立實驗。
2. 成功、失敗、無法判定及停止界線在執行前固定，詳[技術設計](technical-spec.md)。
3. 分別記錄遠端是否拒絕、provider 明確聲稱的原因、單次實驗可支持的結論。HTTP 狀態、`invalid_grant`、無 token 或關鍵字均不單獨證明 PKCE。
4. 若執行，確認新授權、新 code、單次交換、S256、client／redirect 關聯及 verifier 確實省略；本機 prepared 證據不冒稱完整遠端 wire。
5. 安全原文傳遞、兩名盲判 Reviewer、token 成功契約與資料界線遵守技術設計；分歧維持無法判定。
6. 舊 planning／evidence 保持原樣；新結論另記來源。實驗四態與本輪任務完成否分開，缺口未解不得因此放行原決策。
7. 交付只在 feature worktree，完成獨立審查後按 topic commit、push、Draft PR，再交 Human review；不能在 dev worktree 實作。

## 授權與完成語意

Human 已接受對話計畫，明確授權 feature worktree、受限離線交付、按 topic commit／push／Draft PR；不包含新 OAuth 或實際 provider 原文揭露。當前真人狀態為「未執行」，新增授權 0，未建立新實驗。

本輪離線調查及可 review 交付可以完成，即使 missing 的歸因仍無法判定。需要 live 才能解答時，列出具體缺口並停 Human boundary；不將缺口說成漏洞或正式採用核准。

相關：[執行契約](../../plan/github-pkce-missing-verifier-feasibility/github-pkce-missing-verifier-feasibility.plan.md)／[狀態帳本](../../plan/github-pkce-missing-verifier-feasibility/github-pkce-missing-verifier-feasibility.step.md)。
