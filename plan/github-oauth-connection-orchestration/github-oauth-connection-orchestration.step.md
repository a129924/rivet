# OAuth 啟動／重連：執行帳本

- Topic：`github-oauth-connection-orchestration`
- Base：`ab77391b73291deb1ce3d96cef72f981aeb3104a`
- Branch：`docs/github-oauth-connection-orchestration`
- Current phase：獨立成果審查 approved，待受限交付。
- Current step：RV01 completed；next DL01 pending。
- 最後更新：2026-11-17，Reviewer（RV01）。
- [requirements](../../analysis/github-oauth-connection-orchestration/requirements.md)／[technical-spec](../../analysis/github-oauth-connection-orchestration/technical-spec.md)／[plan](github-oauth-connection-orchestration.plan.md)

## Steps

| ID | Status | Owner role | 完成條件 | Evidence／verdict |
| --- | --- | --- | --- | --- |
| PC01 | completed | Plan-Creator | 在指定 worktree 保存四份同 slug artifacts，納入 Human 已鎖定 scope／工具／9欄／驗收及交付授權。 | 四份文件已建立；依本輪檔案讀回確認保存。僅作者交付完成，不是 approval。 |
| PR01 | completed | Plan-Reviewer | 獨立審查四份 artifacts 的 sufficiency、scope、contract、角色與 allowlist，明示 verdict。 | [獨立 planning review](evidence/plan-review.md)：approved，required fixes 無，只適用本題規劃。 |
| IM01 | completed | Implementer | PR01 approved 後完成 bounded 原碼證據／盤點／採用方案／Floorplan 現況及兩 Archify 圖；必要實驗依條件處理，維持 production zero diff。 | [IM01 交接](evidence/implementation.md)、source-audit／adoption-audit／採用方案、兩圖收據與本機 Floorplan 已交付；無新實驗或 production。 |
| TE01 | completed | Tester | 依完成交接獨立核對 TC01–TC10，記實際檢查／親跑／skipped／限制及使用者內容無損。 | [TE01 獨立驗證](evidence/verification.md)：完成；首輪 broken link 由 Implementer 修正後閉合，來源／圖面／map 檢查通過；未執行 Swift runtime／live。 |
| RV01 | completed | Reviewer | 獨立審查證據、圖面、需求追溯、範圍及驗證結果，明示 verdict／required fixes。 | [獨立成果審查](evidence/review.md)：approved，required fixes 無；僅限本題交付，不代表正式 orchestration／live／Human 接受。 |
| DL01 | in-progress | Implementer | Staged convention／範圍檢查後，依 Human 已授權 direct topic commit／push／Draft PR；actual bounded diff 後完成必要本機 PR Lens 或記真實限制。 | 待 commit IDs／命令／Draft PR URL／publication evidence；不得 merge。 |
| HC01 | pending | Human | 最終 topic／圖面／Draft PR review；確認結論限制及後續正式實作仍需獨立契約。 | 未接受；不得由 agent 宣告通過。 |

## Blockers

目前沒有已確認不可解除 blocker；PR01 已獨立 approved，IM01 已交接 TE01。Source audit 不需新實驗；本機 Floorplan 新建與兩圖完成，待 TE01／RV01 獨立核對。重大 scope／contract 歧義或需超出 allowlist 時停止相關動作，不把未驗證標成功。

## Human Check

Human 已鎖定 OAuth-only、只區分啟動／重連儲存錯誤、暫時錯誤 retry 原 provider、重新授權前退休／清除且不復活、交付終點是方案／證據／現況圖，非 production orchestration。最新已明示隔離 worktree → 實現本 topic → direct topic commit → push → Draft PR → Human review；staged 語意檢查仍需做，不新增重複確認。HC01、Archify Human 視覺接受均 pending；不承接其他 topic 的 Human approval。

## 狀態與證據規則

步驟完成、四狀態實驗結果、五分類採用程度、review verdict 與 Human 接受分開。各角色只更新自己的實際結果及相對 evidence 位置；獨立 Reviewer 不審查自己產出。圖面／runtime／tests 沒執行不得記通過。必要回修保留歷史與 required fixes，不覆寫已知失敗／無法判定；不可因新 skill 新增 gate。
