# GitHub Account Login 可行性需求

- Topic：`github-account-login-feasibility`
- 日期：2026-10-21
- 性質：可行性證據保存與文件交付，不是產品登入實作。
- [技術依據](technical-spec.md)；[執行契約](../../plan/github-account-login-feasibility/github-account-login-feasibility.plan.md)；[狀態帳本](../../plan/github-account-login-feasibility/github-account-login-feasibility.step.md)。

## 目標與使用情境

開發端可準備必要 GitHub App 設定。終端使用者只點登入、完成 GitHub 登入與授權、返回 Rivet 並確認有效帳號，不自行註冊 App、不填 client ID／secret、不貼 token。這不是要求 OAuth 協定完全不使用 App 憑證。

本 topic 回答此技術路線是否可行、既有程式已實現到哪裡，以及證據支持範圍。使用者已要求將認可的 feasibility-only 計畫落檔、保存長期結論，依 topic commit／push／建立 Draft PR，停於 Human review；不恢復產品實作。

## 範圍與成功條件

- 以官方文件、固定原碼及歷史正向證據，分開陳述事實、推論、觀察與限制。
- 明確說明開發端配置與自動 token exchange 的路線可行，但完整零配置產品 UX 未交付、未經本輪真人驗證。
- 保存五份文件：本 topic 四份 planning artifacts，以及待 Implementer 建立的 `docs/github-account-login-feasibility.md`。
- 檢核來源 pin、文件連結、五檔範圍、無秘密／本機絕對路徑及撤回界線；獨立審查後交付 Draft PR，不 merge。
- 不以 build、tests 或 callback 單獨替代主要問題的證據，不宣稱 PR #61 gate 通過。

## 非目標

不新增 Swift、App、launcher、UI、產品測試、實驗、架構圖或 public API；不設計 production secret custody、持久化、多帳號、新協定或遠端 refresh；不重跑負向 PKCE、不修改其他 topic／BC，不依賴 PR #61 的 branch、merge 或 Human gate。

## 變更紀錄

| 日期 | 決策 |
| --- | --- |
| 2026-10-21 | 保留原 A 五節可行性計畫及來源限制。曾提出的 B 產品 slice（含 `apps/Rivet`、launcher、composition、UI、產品測試、Human host 驗收及 S01–S06）已明確撤回，不是待執行工作。 |
| 2026-10-21 | 原對話階段 Written／Modify／Deleted 均為無，計畫未落檔。本輪依明示保存與交付指示，Written 更新為五份新文件；Modify／Deleted 仍為無。 |
| 2026-10-21 | 本輪額外固定來源至 `90646c21bd9e6f0f19644f04efa39ef1c033a139`，提高原碼及歷史紀錄可追溯性；不構成真人重驗，也不表示 base dev 已有該 runtime。 |

## 未驗證事項

完整零配置產品 UX、公開發行 custody 與長期持久化均未驗證，屬範圍外，不是本輪 pending implementation。沒有尚須執行才能排除、且影響本次技術選擇的新未知，因此不新增實驗。

## 後續 Human 正向重驗（2026-10-21 新增）

> **2026-10-21 更正（以此為準）：使用者隨後明確表示沒有遇到 GitHub 登入畫面，也沒有進行 GitHub 登入授權。L01「本輪新授權／正向重驗成功」判定撤回，狀態改為「無法判定」。以下原判讀只保留為已被更正的歷史，不是有效成功證據。**

使用者於文件交付後另行要求真人實證，並明示剛在本輪完成登入授權。本次只重驗既有 GitHubSignInVerification 的正常授權與帳號結果；不恢復產品 B、不新增 Swift／實驗程式、不重跑反向 PKCE。原文件交付階段「無真人重驗」保留為當時事實；本次觀察另記 L01，不覆寫 A07。

### C01 本次更正

本輪真人新授權驗證未完成，L01 改為「無法判定」；不以舊畫面或前一則肯定回覆代替本次登入授權。原可行性問題、歷史 A07 與產品撤回範圍不變。本次僅修正文義與證據資格，不新增實驗或產品工作。
