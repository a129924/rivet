# 驗證導覽

本目錄保存可行性實驗與其版本化證據。這份導覽以 [PR #62](https://github.com/a129924/rivet/pull/62) 合併點 `aa16de91` 為 E001–E007 與持續連線 App 的來源快照，另補已合併 [PR #61](https://github.com/a129924/rivet/pull/61) 的固定來源 `14d0832f`，以及已合併 [PR #63](https://github.com/a129924/rivet/pull/63) 的固定來源 `fccaf2b6`；新增索引不代表重新實測或正式產品 UI 已交付。

先讀[驗證結果摘要](VALIDATION-SUMMARY.md)，再依下表查原始判準、機器收據、Human 觀察及限制。原 README 內的 pending／歷史停點應依其日期與版本閱讀，不能覆寫後續或其他實驗的結論。

| 來源 | 驗證主題 |
|---|---|
| [E001](E001/README.md) | 系統瀏覽器授權與 loopback callback 的 code／state |
| [E002](E002/README.md) | 初次 token exchange、六欄相容性與反向 PKCE |
| [E003](E003/README.md) | 單次真 refresh、rotation 與舊 refresh token 拒絕 |
| [E004](E004/README.md) | SQLite 完整 bundle、跨程序與 provider 失敗契約 |
| [E005](E005/README.md) | Legacy Keychain 假 bundle、跨程序／重建與提示 UX |
| [E006](E006/README.md) | 有效同 profile 下真 DPK、假 bundle 與零提示讀回 |
| [E007](E007/README.md) | 同身分 profile 更新後讀回；兩輪均無法判定 |
| [E009](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/experiments/E009/README.md) | 開發端配置、獨立未登入 session 的手動首次登入／同意／帳號確認；M03 為受限 Human 證據 |
| [GitHubConnectionVerification](../apps/GitHubConnectionVerification/README.md) | 獨立驗證 App 的登入、保存、重啟、重建、受控到期真刷新、輪替後讀回與 API |

最後一項沿用既有實驗結論完成整條流程驗證，沒有新增實驗編號。它的 source、UI、adapters、控制與測試屬於驗證 App；Rivet 正式產品登入仍未交付。各來源的真 GitHub、真儲存、fake-only 測試與受控觸發必須分開閱讀；沒有觀察即保留未驗證。

## PR #61：正式初次 OAuth 與獨立登入驗證

[正式能力與驗證 App 歸屬](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/docs/architecture/github-first-sign-in.md)及[X 收尾安全證據](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/plan/github-first-sign-in/evidence/pkce-semantic-review.md)固定引用 PR #61 合併點；實際工具來源仍是 `4dbf3df`。`GitHubIntegration` 留下正式初次 OAuth 能力，`GitHubSignInVerification` 收納驗證外殼；正式 Rivet 產品登入 UI 尚未交付。X 已完成 native 正常 copy／Human 手貼核對及唯一 wrong 單交換：HTTP400 invalid_grant、無 token，兩獨立 AI 對 provider 描述一致判為 verifier mismatch claim。這僅支持該次負向觀察，原自動 indeterminate／proof=false 不改；新 X 1/1 用盡，不再執行授權或研究。與 PR #62 的持續連線 App／refresh 證據分開，E002 及 missing 歷史無法判定不回改。

## PR #63／E009：手動首次登入的受限結果

[PR #63](https://github.com/a129924/rivet/pull/63) 已於 2026-10-22T03:51:18Z 合併，合併點 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`、最後 feature head `fe9af0dbbbbf2cf72befd45fec23488e5ebf55c2`。[E009 保存紀錄](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/experiments/E009/README.md)與[長期結論](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/github-account-login-feasibility.md)固定引用該合併點；它不是 M03 真人執行 build。

M03 的四項判準於 Human 回報層級受限成功：看到登入、完成登入、看到並同意授權、同流程有效帳號。Human 另確認獨立 session 原先未登入、帳號先前未授權，以及同一次新版手動流程、300 秒內、未重啟／再啟動／改用舊網址。Agent 沒有全程 UI 或 network trace；詳見[分層摘要](VALIDATION-SUMMARY.md)。C01 對 L01 的撤回、A07 及反向 PKCE 歷史原樣保留。

M04 已交付同 repository 的驗證 host、必要 runtime／tests 與一次性開發端 launcher；之後兩次同步 dev 的合併只處理相容性與相關 mock／build 核驗，沒有新的真人 OAuth。這些工具與結果不代表正式產品入口、production secret custody、持久化或普遍 PKCE enforcement 已完成。

#63 的收尾已完成：annotated tag `v0.1.57-github-account-login-feasibility` 指向 `fccaf2b6`，原 topic local／remote branch 與 managed worktree 已正常移除，未 force。這兩份索引仍由 Draft PR #64 交付；本次修訂未合併至 dev，不吸收並行 topic 成果。
