# 驗證導覽

本目錄保存可行性實驗與其版本化證據。這份導覽以 [PR #62](https://github.com/a129924/rivet/pull/62) 合併點 `aa16de91` 為來源快照；新增索引不代表重新實測或正式產品採用。

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
| [GitHubConnectionVerification](../apps/GitHubConnectionVerification/README.md) | 獨立驗證 App 的登入、保存、重啟、重建、受控到期真刷新、輪替後讀回與 API |

最後一項沿用既有實驗結論完成整條流程驗證，沒有新增實驗編號。它的 source、UI、adapters、控制與測試屬於驗證 App；Rivet 正式產品登入仍未交付。各來源的真 GitHub、真儲存、fake-only 測試與受控觸發必須分開閱讀；沒有觀察即保留未驗證。
