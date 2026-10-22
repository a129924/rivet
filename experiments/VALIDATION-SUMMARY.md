# 實驗驗證總覽

更新日期：2026-10-22。本頁整理既有紀錄，不新增執行、重判或採用核准；完整時序、來源版本與不可變收據請由[實驗索引](README.md)進入各 README。

## 證據與限制

| 實驗 | 觀察與來源 | 未由此證明的事項 |
| --- | --- | --- |
| [E001](E001/README.md) | 2026-10-07 真實 OAuth callback、非空 code、state 相符、exit 0。 | token exchange、refresh、儲存或正式產品登入。 |
| [E002](E002/README.md) | 真實正向 token、六欄 bundle、GET /user 成功；反向歸因不足。總體無法判定。 | PKCE enforcement；不將後續 X 或 E008 補成此輪成功。 |
| [E003](E003/README.md) | 2026-10-08 T01–T04 遠端測量成功，舊 refresh token 重用回 bad_refresh_token。 | 自然到期、provider 自動刷新、401 recovery、持久化或所有遠端配置。 |
| [E004](E004/README.md) | 2026-10-14 T01–T06、真 SQLite／跨程序／rollback 成功；fake refresh 與受控失敗。 | 加密、真遠端 rotation、sandbox、斷電 durability 或正式 adapter 採用。 |
| [E005](E005/README.md) | 最後 human-only 輪六欄保存與同身分重建讀回成功；Human 提示數首次／fresh／重建為 0／0／1，候選 UX 失敗。 | 所有免費 Keychain 路徑失敗、DPK 不可用或必須付費。早期 unknown 與 machine receipt 原值保留。 |
| [E006](E006/README.md) | 2026-10-19 假 bundle，首次／fresh／真重建讀回完整且 Human 均零提示，受限成功。 | profile 更新／過期恢復、certificate rotation、真 OAuth、公開分發。2026-10-16 controlled-stop／逾時歷史保留。 |
| [E007](E007/README.md) | 兩輪 renewal 前提未成立，renewal read 均未執行，結果無法判定；Human 已接受該未知限制。 | 不同 profile 的讀回成功；新版 export-clean 的受控檢查不代替原真人輪或新增真人驗收。 |
| [E008](E008/README.md) | 2026-10-22 單次安全 JSON 與兩名獨立先封存 enum；依固定判準無法判定。 | 普遍 PKCE enforcement、OAuth 漏洞、完整 wire 或正式安全決策變更。 |
| [E009](E009/README.md) | M03：Human 確認獨立未登入 session、未授權帳號、同輪登入／同意／300 秒內有效帳號；來源契約支持。 | agent 直接見證歷史 UI／network、2FA、完整零配置 UX、產品 readiness 或 PKCE。後續 build 不回填真人來源。 |

## E008：三層結果

1. **交換觀察**：Human 手動提供的 [CLI 安全 JSON](E008/safe-result.json) 回報 HTTP400、invalid_grant、remote_rejected=true、token_present=false；新嘗試、單次 exchange、本機一致性與 verifier 欄位省略均有有限欄位紀錄。本機 prepared inputs 不等於完整遠端 wire 證明。
2. **Provider 聲明**：[封存結果](../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json) 中，A／B 的 provider_claim 同為 verifier_required；A 的 pkce_causality=not_asserted，B=asserted。原始描述不保存，不重建原句或追加第三人重判。
3. **主要假設**：因當次因果判讀分歧，依執行前固定判準維持**無法判定**。CLI 的 outcome=indeterminate、pkce_rejection_proven=false 原樣保留；HTTP、錯誤碼、關鍵字及要求 enum 不能單獨取代因果共識。

執行來源 `d067c2c6adad7b1bcb19639c3f0ca58fc437e251`；工具凍結未改。[獨立 Tester](../plan/github-pkce-missing-verifier-feasibility/evidence/live-verification.md) 與 Reviewer 接受的是有限證據的如實整合，required fixes=0；不是 missing-verifier 假設成功。任務完成、1/1 額度用盡，不補次；未使用 token 呼叫 API，也未執行 revoke。

[PR #65](https://github.com/a129924/rivet/pull/65) 已於 2026-10-22 合併並關閉，merge commit 為 `0276ff3385495ed7fb0444e02b3b6da0757dd17a`。PR 合併只更新交付狀態，不解除因果缺口；E008 README 與 step 中的 Draft／待 review 文字保留為當時交付快照。

## 決策邊界

各實驗的成功只適用其來源版本、前提與觀察層級；測試／build 通過、文件審查通過、驗證任務完成或 PR 合併均不能代替主要假設的證據。E002 反向／舊 missing 未知、E005 候選 UX 失敗、E007 renewal 未驗證與 E008 無法判定分別保留；既有 X wrong 的單次支持性證據不代替 missing。

正式登入 UI 依自身工作線推進。後續正式 adapter、安全決策、憑證 lifecycle 或產品採用仍依各自既有流程，不由本總覽自動核准。
