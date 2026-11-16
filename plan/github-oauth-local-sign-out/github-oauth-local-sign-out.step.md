# 本地登出與 OAuth 憑證清除：狀態帳本

- Topic：github-oauth-local-sign-out
- Phase：T09 unsigned harness 驗證（系統驗證未完成）
- 基線：2973150b2789d63c10226b57150073ccc793c509
- Branch：feat/github-oauth-local-sign-out
- 最後更新：2026-11-16 Asia/Taipei（T09補充契約，尚待獨立Plan-Reviewer）
- 上游：Planner 已判規劃輸入充分可交 Plan-Creator；不是 planning gate approved。

| ID | Status | Owner role | 完成條件 | 驗證證據／verdict |
| --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 四份同 slug artifacts 落 feature worktree，保留九欄、API、三 tools、feasibility 與邊界 | 本次四份 artifacts；未執行實作／測試，品質由 S02 獨立審查；無自評 approval。 |
| S02 | completed | Plan-Reviewer | 四份均可讀，獨立核對需求／scope／contract／readiness | 獨立 Plan-Reviewer 明示 approved（2026-11-13），無 required fix；已核對四份及 provider／DPK／scope source。 |
| S03 | completed | Implementer | 僅依 S02 approved bounded contract 完成 src/tests/docs/必要實驗入口 | src／focused tests／長期文件完成；root316 tests passed、format exit0、focused GitHubIntegration lint 0。E016僅未執行設計，harness未建立，T09不宣稱完成。 |
| S04 | completed | Tester | 親跑受控／consumer回歸並如實列出 T01–T09 證據限制 | [獨立驗證](evidence/tests.md)：44 focused／316 root／15 consumer通過；回修11 sign-out tests通過，T04/T08補證；T09仍未執行，交Reviewer分類；不是所有驗收通過。 |
| S05 | completed | Reviewer | 獨立核對受限 code/tests 與 required fixes | 2026-11-13 18:16 明示 approved，T04/T08 closed；不包含未建立的 E016 harness／T09。 |
| S06 | pending | Human | 最終 review／必要圖面接受／既有 commit boundary | 未開始。 |

## Blockers

- S02 的原契約已 approved；本次 T09 補充須獨立審查，不以歷史 approval 推定新 harness 放行。
- PR 狀態先前因網路未驗證，不推測。
- 2026-11-16 已由 Explorer 查得且主 session 選定既有 signer/profile；E016 尚無 signed harness／preflight／真實兩程序證據，不宣稱重啟驗收完成。
- Graphify 可用 graph／revision、PR Lens runtime／actual diff 及圖面結果未驗證。

## Human Check

- 已確認：單一 owner／唯一 writer；保留 App configuration；執行已接受的 feature-worktree 計畫。
- 尚待：必要系統提示／圖面視覺接受／最終 review，均依實際執行記錄。
- Human 本輪明確授權按 topic commit、push、開 Draft PR；仍先檢查 staged semantic boundary，由主 agent 執行；最終交 Human review。
- 2026-11-13 18:20 收斂為歷史；11/16續行只補T09，不以時間上限代替完成。

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

## 2026-11-16：T09 continuation

下列是本次補充的待執行 steps；不是過去 approval 的延伸。既有 S01–S05 的歷史 evidence 原樣保留，S06 Human 最終review仍pending。

| ID | Status | Owner role | 完成條件 | 證據／verdict |
| --- | --- | --- | --- | --- |
| T09-P1 | completed | Plan-Creator | 四份artifacts及E016八段README具體化既有資產、獨立host、一次兩程序、safe receipt／停止規則 | 本次補充文件；未自評approved。 |
| T09-P2 | completed | Plan-Reviewer | 獨立審查補充契約，明示verdict | 2026-11-16 獨立Plan-Reviewer approved，無required fix。 |
| T09-I | completed | Implementer | E016 unsigned host／最小runner／fakechecks、實際命令與source freeze | 已建立；7 fakechecks與unsigned build通過，交獨立Tester/Reviewer；未sign/live。 |
| T09-R1 | pending | Reviewer | 獨立審查新harness與fake evidence | [獨立unsigned先驗](evidence/e016-unsigned-tests.md)：7fakechecks／unsignedbuild／format／lint／rootzero-diff通過，helper與整runner覆蓋差異及attestation流程依賴交Reviewer；不沿用S05 approval。 |
| T09-V1 | pending | Tester | 審查後signing preflight、frozen binary/profile及actual launch identity證據 | 尚未執行；不能稱signed ready。 |
| T09-H | pending | Human | 工具具體可檢視後安排兩段完整prompt觀察，attestation綁receipt hash | 未執行；promptcount unknown。 |
| T09-V2 | pending | Tester | 唯一first/fresh序列、判準分類／safe receipt／殘留紀錄 | 實驗未執行。 |
| T09-R2 | pending | Reviewer | 獨立審查系統結果與限制，回原topic | 尚無。 |

本次沒有 production 修改、build/test/sign、Keychain操作或commit。既有資產重用是主session明示決策；資產expiry前提須在實際兩段啟動時重新驗，不把唯讀inventory當preflight成功。

## T09-R1 needs-rework 回修交接

Reviewer要求unsigned→signed provenance鏈及實際launch_phase mock coverage兩項；Implementer已完成E016限定回修，16fakechecks通過，無真簽章／launch／DPK。COMMANDS以sign_prepared專用helper取代手動codesign繞過；preflight/launch必核轉換hash。狀態仍待Tester及Reviewer重新明示verdict，不自評approved。產出文件／review仍可改變dirtymanifest，最後sourcefreeze需最後review後重建，不沿用先前companion。

## 2026-11-16 E016 unsigned 回修審查

獨立Tester親跑16fake checks、format/lint/Python AST/diffcheck通過；production零差異。Reviewer明示approved（unsigned harness／回修），兩項required fixes closed：unsigned→signed來源轉換鏈，actual orchestration mock guards。准凍結後重建／manual signing／preflight，不代表signed ready或T09 passed。最終Human觀察與真DPK兩程序仍pending；不沿用舊build。
