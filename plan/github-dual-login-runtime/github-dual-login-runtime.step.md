# github-dual-login-runtime 執行帳本

最後更新：2026-11-17，交付組裝端（依獨立角色明示證據回寫）。Branch：`feat/github-dual-login-runtime`；base `1f31b35`。

目前 phase：human-check。Current step：R07，status=pending（HC01；同時等待R09 Draft PR與圖的Human review）。Upstream verdict：approved（獨立 Reviewer `/root/runtime_reviewer`，R05，required fixes 0）；不自行完成TC08或topic。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據／Verdict |
|---|---|---|---|---|
| R01 | completed | Plan-Creator | 同slug四檔落feature，保留已接受Q1–Q3與九欄位 | 本四檔已建立；不宣稱gate通過 |
| R02 | completed | Plan-Reviewer | 獨立核對四檔一致性／scope／契約 | 獨立 Plan-Reviewer `/root/artifact_reviewer` 明示 approved，required fixes 0 |
| R03 | completed | Implementer | 正式service／coordinator／probe／OAuth通道、測試及獨立入口完成 | 正式runtime／tests／獨立入口及docs完成；見[evidence](evidence/implementation.md)，獨立驗證見R04 |
| R04 | completed | Tester | TC01–TC07及受影響檢查親跑，附命令／來源／結果 | root Tester 親跑358 tests／45 suites通過，format／strict lint／consumer／CLI build通過，見[驗證](evidence/verification.md) |
| R05 | completed | Reviewer | 獨立審查產出、取消／提交與證據限制 | 獨立 Reviewer `/root/runtime_reviewer` approved，required fixes 0，見[審查](evidence/review.md) |
| R06 | completed | Implementer | 長期docs／Archifysequence及localPRLens交付，依授權commit／push／DraftPR | Archify與本機PR Lens已驗證；runtime commit `fa93773`已push，Draft [PR74](https://github.com/a129924/rivet/pull/74)已建立，見[交付](evidence/publication.md)；不作Human接受或live證據 |
| R07 | pending | Tester | Human確認當次條件後執行TC08、分別記真OAuth／PAT與fresh讀回 | pending，Human停點；不挪用舊topic額度 |
| R08 | pending | Reviewer | 獨立核對TC08來源／環境／實際結果 | pending；無結果不宣稱live通過 |
| R09 | pending | Human | DraftPR review、圖視覺接受及topic最終接受 | pending，不自行標topic完成 |

## Locked decisions

Q1正式GitHubPATDataProtectionStore、不新增legacy適配／migration／delete；Q2另一方式憑證保留；Q3同目標共享coordinator整次互斥立即拒絕。既有取消／Outcome契約不變，僅feature實作。

## Blockers

- 產品／技術未決：無已知新缺口。
- R02 正式獨立審查 approved；實作遵受限契約，非自評放行。
- TC08不在本次自動執行範圍，須先完成HC01當次條件確認。

## Human Check

| ID | Owner | Status | 條件 |
|---|---|---|---|
| HC01 | Human | pending | TC08前確認配置、有效簽章、host、namespace、exact-owned處置及當次live執行條件；本次不重跑live |
| HC02 | Human | pending | Archify圖的Human視覺接受，與自動containment／Agent檢視分開 |
| HC03 | Human | pending | Draft PR及topic最終接受；不自動merge／release |

原PAT P07 approved只支持5465d3c指定環境storage，原Human pending不回填；合併版不是新live。無真runtime驗收結果，topic不標complete。
