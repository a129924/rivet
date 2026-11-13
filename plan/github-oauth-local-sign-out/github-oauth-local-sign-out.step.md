# 本地登出與 OAuth 憑證清除：狀態帳本

- Topic：github-oauth-local-sign-out
- Phase：驗證
- 基線：2973150b2789d63c10226b57150073ccc793c509
- Branch：feat/github-oauth-local-sign-out
- 最後更新：2026-11-13 18:11 Asia/Taipei（Implementer交Tester）
- 上游：Planner 已判規劃輸入充分可交 Plan-Creator；不是 planning gate approved。

| ID | Status | Owner role | 完成條件 | 驗證證據／verdict |
| --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 四份同 slug artifacts 落 feature worktree，保留九欄、API、三 tools、feasibility 與邊界 | 本次四份 artifacts；未執行實作／測試，品質由 S02 獨立審查；無自評 approval。 |
| S02 | completed | Plan-Reviewer | 四份均可讀，獨立核對需求／scope／contract／readiness | 獨立 Plan-Reviewer 明示 approved（2026-11-13），無 required fix；已核對四份及 provider／DPK／scope source。 |
| S03 | completed | Implementer | 僅依 S02 approved bounded contract 完成 src/tests/docs/必要實驗入口 | src／focused tests／長期文件完成；root316 tests passed、format exit0、focused GitHubIntegration lint 0。E016僅未執行設計，harness未建立，T09不宣稱完成。 |
| S04 | completed | Tester | 親跑受控／consumer回歸並如實列出 T01–T09 證據限制 | [獨立驗證](evidence/tests.md)：44 focused／316 root／15 consumer通過；回修11 sign-out tests通過，T04/T08補證；T09仍未執行，交Reviewer分類；不是所有驗收通過。 |
| S05 | pending | Reviewer | 獨立核對成果／證據／scope drift，明示 verdict | 未開始。 |
| S06 | pending | Human | 最終 review／必要圖面接受／既有 commit boundary | 未開始。 |

## Blockers

- S02 已獨立 approved；S03 依核准契約執行。
- PR 狀態先前因網路未驗證，不推測。
- T09 簽章前提及系統證據未驗證；若不足，不宣稱重啟驗收完成。
- Graphify 可用 graph／revision、PR Lens runtime／actual diff 及圖面結果未驗證。

## Human Check

- 已確認：單一 owner／唯一 writer；保留 App configuration；執行已接受的 feature-worktree 計畫。
- 尚待：必要系統提示／圖面視覺接受／最終 review，均依實際執行記錄。
- Human 本輪明確授權按 topic commit、push、開 Draft PR；仍先檢查 staged semantic boundary，由主 agent 執行；最終交 Human review。
- 18:20 Asia/Taipei 收斂時如實報進度與停點，不以時間上限代替完成。

## Locked decisions

API／retirement／pending-write／error／cancellation／retry 依 technical-spec；不重開。不把其他 topic 或歷史 experiments 併入此 topic。

## Artifacts

- ../../analysis/github-oauth-local-sign-out/requirements.md
- ../../analysis/github-oauth-local-sign-out/technical-spec.md
- github-oauth-local-sign-out.plan.md
- github-oauth-local-sign-out.step.md

## Implementer 交接證據

Red：新測試首次編譯因缺 OAuthCredentialClearingStore／signOut 失敗（安全暫存 log rivet-signout-red）。Green：9 sign-out tests 通過；provider／DPK 前一輪41tests通過；最後 root316tests／39suites通過。靜態allowlist已增加兩個新contract。scripts/check-swift-format.sh exit0；focused swiftlint GitHubIntegration Sources/Tests 60files 0violations；git diff --check exit0。全repo swiftlint 掃入歷史experiments有既有大量違規，不擴張回修；本次3項lint已修。

T01–T07有新增受控測試（T04/T05的原需求task可先於退休完成，驗收核心為save→clear-start→clear事件順序及後續signedOut）。T08精確selector／binding／corrupt／delete failure及scope prepare mapping已測；已持有REST／GraphQL scope的新工作與401 recovery尚無專屬新增案例，交Tester判斷必要性。T09未執行，E016缺harness及簽章前提證據；不得宣稱重啟實證。

## Reviewer required fixes 回修（2026-11-13 18:14）

T04兩個pending-save案例已在gate關閉時以snapshot回覆signedOut確認退休，並斷言clear尚未開始，再release save。握手有1秒超時開gate及失敗判準，避免測試死鎖；無production hook。T08新增真實已prepare scope的REST／GraphQL後續工作不送出，以及兩者401 response gate中登出、晚到401不refresh/retry。11個本地登出測試通過（安全暫存rivet-signout-rework.log），交Tester獨立重驗。此回修覆蓋前段T04/T08缺口，T09仍未執行。

## 最終受限成果審查（18:16）

Reviewer 明示 approved（受限 code/tests）：T04、T08 required fixes closed，無其他 required fix。Tester 最後獨立11tests/1suite與diffcheck通過。Timeout child只返回false；parent鎖定結果後才清理gate，取代前段timeout描述。S05受限審查完成，S06 Human review pending。T09/E016缺signed harness及真DPK fresh-process證據，topic完整驗收未完成。Human已明確授權本topic commit/push/Draft PR；不以此代表完整驗收或Human最終接受。
