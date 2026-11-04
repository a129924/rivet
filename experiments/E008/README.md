# E008：GitHub PKCE missing-verifier 單次真人補證

## 驗證什麼

- 實驗編號 E008；設計與執行日期：2026-10-22。
- 建立前已確認目錄與全部 refs 歷史沒有占用；E001–E007／E009 保留。
- 一個問題：帶有效 S256 challenge 的新授權，交換省略 verifier，當次拒絕是否有足夠證據歸因於 PKCE？
- 主要假設：前提成立時，當次拒絕源於 verifier 要求或 verifier／challenge 驗證。

## 為什麼

GitHub 公開契約與 RFC 7636 要求送 challenge 後使用對應 verifier；RFC 6749 的 invalid_grant 亦可能源於其他問題，不能追認歷史 missing 原因。見[文件／來源調查](../../plan/github-pkce-missing-verifier-feasibility/evidence/document-source-investigation.md)。

本輪以新的安全操作結果及兩名先封存的語義結果，補足當次資訊；支持結果也只能增加特定配置的受限信心。反例交原安全變更流程，仍不明則保留缺口，不改正式 OAuth 或阻塞登入 UI。

## 成功與失敗判準

以下在執行前固定，沿用[技術設計](../../analysis/github-pkce-missing-verifier-feasibility/technical-spec.md)，沒有依結果變更：

- 成功：前提成立、verifier 確實省略、交換拒絕且無成功 token 回應；完整描述清楚歸因當次 verifier 要求或 verifier／challenge 驗證，兩名獨立判讀者一致。
- 失敗：前提成立，省略 verifier 仍收到符合既有成功回應契約的 token 回應。
- 無法判定：已嘗試，但配置、網路、格式、一般 grant、描述不足、安全拒絕、成功契約證據不足或判讀分歧妨礙判定。
- 未執行：尚未進行真人操作，包括未授權或前提不成立。
- 任一 token 鍵即停止，不使用／保存／revoke；CLI failed 只代表鍵存在，不能冒充成功契約已成立。
- provider 若聲稱 mismatch，只記 mismatch，不改稱明言缺少；CLI 原始 outcome／proof 不覆寫。
- 上限一次新授權、一個新 code、單 exchange；開始授權即消耗唯一機會，取消、逾時、失敗或無法判讀均不補次。CLI 300 秒授權／交換期限、POST 最多 30 秒且受剩餘期限限制；helper 100 秒總 watchdog、30 秒點擊期限，不另加等待或重試。

## 環境與前置條件

- Runtime commit：`d067c2c6adad7b1bcb19639c3f0ca58fc437e251`；工具凍結未改。
- 執行前已確認 macOS 26.5.2、Python 3.14.0、Apple Swift 6.3.3，arm64 macOS。
- Human 本輪明示一次新 OAuth，另允許安全 gate 後完整單欄手動 copy／AI 閱讀，接受剪貼簿／同步與 AI 服務留存風險。
- Human 確認 OAuth App 沿用 X 輪同一 client／secret 與 callback；這是 Human attestation，沒有向 agent 提供秘密，不是獨立遠端配置證明。
- 執行前獨立 Tester 唯讀核對 E008、planning diff、來源及 getpass／callback／deadline，required issues=0，可交 Human 唯一操作。沒有額外 case／compile／tests／校準。
- 使用 Human 本機互動終端、getpass 隱藏輸入；agent 沒有擷取 Terminal 文字／UI、callback 或配置。不是 agent exec TTY 承接秘密。

## 重現步驟

以下僅記本次已消耗的唯一操作，不授權重跑：

1. Terminal 交付一次既有命令：`python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case missing --copy-description-for-ai`。Human 完成唯一操作，沒有第二次 CLI／OAuth。
2. Human 隱藏輸入同一配置、完成瀏覽器授權；不複製 URL／callback，不 tee／log／截圖。
3. 沿用純 error、完整 UTF-8 ≤4096 bytes 及既有有限 privacy gate；cleanup 後 native helper 才允許一次明確滑鼠 copy。Human 手動提供單欄描述，沒有自動傳送。
4. 兩名全新、獨立 Reviewer 只收到相同完整單欄與固定判準，沒有 case、安全 JSON、歷史結果或彼此答案；各自封存有限 enum 後才整合。兩者未使用工具／讀檔。
5. Human 另提供 CLI 最後有限安全 JSON，原值保存於 [safe-result.json](safe-result.json)。Tester 只閱讀此安全輸出及先封存 enum，沒有接觸原文、第三次判讀或挑選結果。
6. 僅保存有限 enum／布林、HTTP、版本、次數及限制；不保存原句、引文、可重建原句的理由、callback、code、state、secret、verifier、token 或完整 response。

固定判讀只問完整描述是否明確聲稱當次拒絕源於 verifier 要求或 verifier／challenge 驗證；否定、條件、假設、例子、多候選、矛盾、不完整或含糊不算明確因果。每名 reader 只回 `pkce_causality=asserted|not_asserted|indeterminate` 與 `provider_claim=verifier_required|verifier_mismatch|grant_or_code|configuration|indeterminate`。這是人工有限記錄，不修改 CLI 句型或分類。

## 是否成功

- 執行日期：2026-10-22。
- 實驗四態：**無法判定**，不是成功或失敗。
- 理由：兩名獨立 reader 的 provider 要求 enum 一致，但當次 PKCE 因果判讀分歧，未滿足事前成功判準。
- 真人補證任務完成：**是**。單次投入已結束、有限證據已整合，原因、缺口及決策限制已交代；獨立 Reviewer 已核准結果紀錄（approved、required fixes=0），只支持如實整合與交付，不因此解除原未知。
- 額度：**1/1 已使用並用盡**。本輪一次新授權、一個新 code、單 exchange，根據 Human 操作回報與 CLI fresh／callback／single 欄位；不是 agent 直接監看終端／wire 的計數。
- 啟動前的未執行／0/1 是當時歷史快照，已被本次實際結果更新，不回寫舊輪次。

## 結果與證據

以下觀察來源為 Human 手動提供的 CLI 安全 JSON，不是 provider 原始 response 或 agent 直接擷取終端：

| 層次 | 當次有限結果 |
| --- | --- |
| GitHub 是否拒絕 | HTTP400、remote_error=invalid_grant、remote_rejected=true、token_present=false。 |
| Provider 聲明 | 兩 reader 的 provider_claim 都是 verifier_required；A 的 pkce_causality=not_asserted，B=asserted。只保存封存 enum，不重建原文。 |
| 實驗支持範圍 | 新授權／callback／single=true，local_consistency=consistent、submitted_verifier=omitted、各 shape／binding=true；支持本機 prepared 與當次拒絕的有限紀錄。因因果判讀分歧，主要假設仍無法判定。 |

原 CLI 保持 `outcome=indeterminate`、`pkce_rejection_proven=false`、`diagnostic_class=code_problem`、`reason=generic_code_rejection`、`description_class=unknown`、`description_match_source=none`、`signals_conflict=false`。`copy_status=copied` 只支持回報的正常 copy 操作，不是語義或普遍安全證明。其餘布林及 null 原值均保留，未以人工 enum 覆寫。

三工具 SHA 再核對仍 frozen：

| 工具 | SHA-256 |
| --- | --- |
| `pkce_negative_probe.py` | `26894482d275636d4e736a648b0366ee6ce6b980e5fafb0683b80b40544ff0b9` |
| `pkce_semantic_review.swift` | `8505134d2130f1f99a1339cb9abbccabe894c2db73575c60d759d542a5a5e405` |
| `test_pkce_negative_probe.py` | `62d1849c1d1b16351b27b4b6ea1247c75a24a8c6fdf9b3c32908e733c3fde0c5` |

[封存語義記錄](../../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json)／[獨立 Tester 整合](../../plan/github-pkce-missing-verifier-feasibility/evidence/live-verification.md)。未重跑 67 tests／synthetic／正常登入／wrong，沒有追加 reader 或 OAuth。

## 結論與限制

本輪確認有限安全輸出回報拒絕，兩個 provider 要求 enum 一致；但當次因果判讀分歧，missing-verifier 的 PKCE 歸因缺口仍在。不能用 HTTP、invalid_grant、關鍵字、要求 enum 或本機 prepared 一致性替代共識，不能挑 B 覆蓋 A。

沒有成功 token 契約、普遍 PKCE enforcement、OAuth 漏洞或正式採用的新增結論。prepared 不是 wire，配置是 Human attestation，JSON 是 Human 回報；copy 不推論 timeout／cancel／OS 清除，privacy gate 不保證識別任意秘密或完全清除。沒有 token／API／revoke 操作。

本輪結束，不重判、不補次、不追加研究。P/Q/R/T/X 及舊 topic 結果與額度保持原樣，正式程式唯讀；本次 10-path 結果 diff 已經獨立 Reviewer approved、required fixes=0；其未接觸原文或重新判讀，只核對有限證據符合固定規則。後續依原授權同 topic commit／push 更新 Draft PR #65，交 Human review，不自動解除原決策限制。
