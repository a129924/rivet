# 實驗索引

更新日期：2026-10-22。此索引依已合併的實驗 README 與有限證據整理；各輪前提、歷史結果與授權仍以原紀錄為準。實驗成功、驗證任務完成、PR 合併與正式採用是不同狀態。

## 既有實驗

| 編號 | 驗證問題 | 目前可支持的結果 |
| --- | --- | --- |
| [E001](E001/README.md) | OAuth App 的瀏覽器／loopback callback | 成功：真實授權取得非空 code、state 相符；未交換 token。 |
| [E002](E002/README.md) | S256 token exchange 與 credential 相容性 | 正向 exchange、六欄 schema 與一次 API 成功；反向 PKCE 及總體無法判定，2/2 授權用盡。 |
| [E003](E003/README.md) | 遠端 refresh 與 rotation | T01–T04 成功：初始 API、新 token pair、相同帳號 API、舊 refresh token 明確遭拒。 |
| [E004](E004/README.md) | GRDB／SQLite 與 provider lifecycle | 本機真磁碟、跨程序、原子輪替與失敗處理成功；fetcher／clock 為 fake，未驗證真 GitHub 或秘密保護。 |
| [E005](E005/README.md) | 免費 legacy Keychain 完整 bundle 與提示 UX | 最後 human-only 輪資料機制成功、候選 UX 失敗：真正重建讀回出現一次提示。 |
| [E006](E006/README.md) | 免費 Personal Team／DPK 與重建 UX | 2026-10-19 受限輪資料機制與 UX 成功；有效 profile、同身分／同機條件限定，使用假 OAuth bundle。 |
| [E007](E007/README.md) | 同身分 profile 更新後 DPK 讀回 | 兩輪無法判定；renewal read 均未執行。Human 接受此未知限制，不升格為驗證成功。 |
| [E008](E008/README.md) | missing-verifier 拒絕的 PKCE 歸因 | 無法判定：HTTP400 拒絕、無 token；provider 要求 enum 一致，當次因果判讀分歧，1/1 用盡。 |
| [E009](E009/README.md) | 手動獨立 browser 的首次登入／同意／帳號結果 | M03 在 Human 回報與來源契約層級受限成功；M04 建置與 mock 檢查不構成另一次真人成功。 |

結果的證據層級、主要缺口與決策限制另見 [驗證總覽](VALIDATION-SUMMARY.md)。本索引不授權執行任何 README 中的重現命令、新 OAuth、重試或秘密清理。

## E008 交付事實

[PR #65](https://github.com/a129924/rivet/pull/65) 已於 2026-10-22 合併並關閉，目標為 `dev`，merge commit 為 `0276ff3385495ed7fb0444e02b3b6da0757dd17a`。執行來源仍是 `d067c2c6adad7b1bcb19639c3f0ca58fc437e251`，結果提交為 `0644fdda1fb6bd9bb4fe5e4b064d3e97d65b59ad`；合併不改寫原結果。

E008 驗證紀錄任務已完成，但主要假設仍無法判定；單次預算已耗盡，不追加判讀者、OAuth 或研究。正式 OAuth 與歷史證據保持原契約，原始描述未寫入 repo 或檔案。詳細有限資料見 [安全 JSON](E008/safe-result.json) 及[封存語義結果](../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json)。
