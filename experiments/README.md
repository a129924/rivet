# 實驗索引

更新日期：2026-11-03。此索引依已合併的實驗 README 與有限證據整理；各輪前提、歷史結果與授權仍以原紀錄為準。實驗成功、驗證任務完成、PR 合併與正式採用是不同狀態。

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
| [GitHubConnectionVerification](../apps/GitHubConnectionVerification/README.md) | 獨立驗證 App 的登入、保存、重啟、重建、受控到期真刷新、輪替後讀回與 API | PR #62 的受限可行性結果；真 GitHub／儲存、fake-only 測試與受控觸發分開，不等正式產品登入。 |

結果的證據層級、主要缺口與決策限制另見 [驗證總覽](VALIDATION-SUMMARY.md)。本索引不授權執行任何 README 中的重現命令、新 OAuth、重試或秘密清理。

這份導覽以 [PR #62](https://github.com/a129924/rivet/pull/62) 合併點 `aa16de91` 為 E001–E007 與持續連線 App 的來源快照，另補已合併 [PR #61](https://github.com/a129924/rivet/pull/61) 的固定來源 `14d0832f`，以及已合併 [PR #63](https://github.com/a129924/rivet/pull/63) 的固定來源 `fccaf2b6`；新增索引不代表重新實測或正式產品 UI 已交付。本次整合另保留 `613a505025774b3841ab73b4ed3b8774be38274a` 內已合併 PR #65／E008 的後續事實；不以後輪結果回填先前輪次。

## PR #61：正式初次 OAuth 與獨立登入驗證

[正式能力與驗證 App 歸屬](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/docs/architecture/github-first-sign-in.md)及[X 收尾安全證據](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/plan/github-first-sign-in/evidence/pkce-semantic-review.md)固定引用 PR #61 合併點；實際工具來源仍是 `4dbf3df`。`GitHubIntegration` 留下正式初次 OAuth 能力，`GitHubSignInVerification` 收納驗證外殼；該來源當時正式 Rivet 產品登入 UI 尚未交付；目前產品入口依其自身工作線判讀。X 已完成 native 正常 copy／Human 手貼核對及唯一 wrong 單交換：HTTP400 invalid_grant、無 token，兩獨立 AI 對 provider 描述一致判為 verifier mismatch claim。這僅支持該次負向觀察，原自動 indeterminate／proof=false 不改；新 X 1/1 用盡，不再執行授權或研究。與 PR #62 的持續連線 App／refresh 證據分開，E002 及 missing 歷史無法判定不回改。

## PR #63／E009：手動首次登入的受限結果

[PR #63](https://github.com/a129924/rivet/pull/63) 已於 2026-10-22T03:51:18Z 合併，合併點 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`、最後 feature head `fe9af0dbbbbf2cf72befd45fec23488e5ebf55c2`。[E009 保存紀錄](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/experiments/E009/README.md)與[長期結論](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/github-account-login-feasibility.md)固定引用該合併點；它不是 M03 真人執行 build。

M03 的四項判準於 Human 回報層級受限成功：看到登入、完成登入、看到並同意授權、同流程有效帳號。Human 另確認獨立 session 原先未登入、帳號先前未授權，以及同一次新版手動流程、300 秒內、未重啟／再啟動／改用舊網址。Agent 沒有全程 UI 或 network trace；詳見[分層摘要](VALIDATION-SUMMARY.md)。C01 對 L01 的撤回、A07 及反向 PKCE 歷史原樣保留。

M04 已交付同 repository 的驗證 host、必要 runtime／tests 與一次性開發端 launcher；之後兩次同步 dev 的合併只處理相容性與相關 mock／build 核驗，沒有新的真人 OAuth。這些工具與結果不代表正式產品入口、production secret custody、持久化或普遍 PKCE enforcement 已完成。

#63 的收尾已完成：annotated tag `v0.1.57-github-account-login-feasibility` 指向 `fccaf2b6`，原 topic local／remote branch 與 managed worktree 已正常移除，未 force。當時由 Draft PR #64 交付、尚未合併的文字保留為提交前快照；#64 現已合併，實際收尾見下節。未吸收並行 topic 成果。

## E008 交付事實

[PR #65](https://github.com/a129924/rivet/pull/65) 已於 2026-10-22 合併並關閉，目標為 `dev`，merge commit 為 `0276ff3385495ed7fb0444e02b3b6da0757dd17a`。執行來源仍是 `d067c2c6adad7b1bcb19639c3f0ca58fc437e251`，結果提交為 `0644fdda1fb6bd9bb4fe5e4b064d3e97d65b59ad`；合併不改寫原結果。

E008 驗證紀錄任務已完成，但主要假設仍無法判定；單次預算已耗盡，不追加判讀者、OAuth 或研究。正式 OAuth 與歷史證據保持原契約，原始描述未寫入 repo 或檔案。詳細有限資料見 [安全 JSON](E008/safe-result.json) 及[封存語義結果](../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json)。

## PR #64 合併與收尾（2026-11-03）

[PR #64](https://github.com/a129924/rivet/pull/64) 已合併並關閉，GitHub `mergedAt` 為 2026-11-03T06:04:24Z；merge commit `71d395cc9ca3cfe645b13a93ee0e83f22c255edd`，最後 feature head `572e366e03471324cd745a4e4a103d19374e5009`。兩索引已隨該 PR 納入 dev；合併不改寫各實驗原結果。

R64 的來源範圍契約與 E006 措辭兩項回修已交付；獨立 Tester 22／22、Reviewer approved，兩個評論 thread 已由主方讀回 resolved、未解決數0。E006 僅支持「切換至 Rebuilt configuration 真正重建」，不稱 Clean；PR #62 的獨立 App 真正 Clean／Build 證據保留。原 D／R64 的 pending 文字是當時快照，不代表本次交付仍待執行。

Annotated tag `v0.1.59-github-connection-validation-summary` 已推送並核對 peeled commit 為上述 merge，未指向後續維護 commit，亦非產品 release。原 `docs/github-connection-validation-summary` local／remote branch 與本輪 feature worktree 已正常移除，無 force／prune；其他 feature worktree、App、Keychain／Apple 資產未動。完整分層與限制見[驗證總覽](VALIDATION-SUMMARY.md)。
