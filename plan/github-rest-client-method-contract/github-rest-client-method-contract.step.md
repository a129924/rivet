# GitHub REST method 契約步驟帳本

- Topic：`github-rest-client-method-contract`
- Phase：已驗收交付／Human Review
- Current step：`H01`
- Current step status：`pending`
- Upstream verdict：Reviewer `approved`
- Branch：`feat/github-rest-client-method-contract`
- Baseline：`79f473b2fc51572b39455b65db010c2a8b55093f`
- 最後更新：2026-10-13
- 更新者角色：Implementer
- 對應：[執行契約](github-rest-client-method-contract.plan.md)、[需求](../../analysis/github-rest-client-method-contract/requirements.md)、[技術規格](../../analysis/github-rest-client-method-contract/technical-spec.md)。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 四份正式 artifacts 在 feature worktree 建立，涵蓋九欄位、locked signatures／behaviors／TC／skills／授權 | 本次已建立 analysis/github-rest-client-method-contract/requirements.md、technical-spec.md，以及 plan/github-rest-client-method-contract/github-rest-client-method-contract.plan.md、github-rest-client-method-contract.step.md；實體檔案存在／可讀。此紀錄不是品質 approval。 |
| P02 | completed | Plan-Reviewer | 獨立審查四份實體 artifacts、scope／contract／workflow，一致後明示 verdict | 獨立 Plan-Reviewer 正式 verdict：approved。四份實體 artifacts scope、八 internal signatures、無 default args／overload、一次 401、errors／cancel、九欄 allowlist、TC01–TC11／skills／sidecars 一致，沒有必要修正；僅 planning readiness，非成果驗證。 |
| I01 | completed | Implementer | 契約、共用 execution、caller／isolation 與必要 tests 完成；遵守精確允許集合 | 八入口 internal 契約、共用 expected-method execution、GET 改名及精確 isolation 已完成。Red：新增契約 tests 編譯報 cannot find type GitHubRestClient；實作後 15 REST tests（61 parameterized cases）green，integration 156 tests／17 suites pass；本次五個 Swift files 的 format lint strict／SwiftLint strict pass。僅局部證據，非成果 approved。 |
| I02 | completed | Implementer | 長期文件／既有圖表同步且完成 skill 驗證 | 長期文件與 canvas／v11 lifecycle 同步。Canvas validate：5 bands／15 boxes／16 edges，0 errors／warnings。Archify showcase validate／deliver 9／9，composition 0 errors／warnings；四桌面 containment pass；人工實看 canvas 三張與 lifecycle light／dark captures，visual_review passed、correction_rounds 0，auto receipt pending 原樣保留。 |
| T01 | completed | Tester | TC01–TC11 與約定命令驗證完成，失敗明確分類 | 獨立 Tester 五項約定 checks exit 0：integration 156 tests／17 suites、full 225 tests／28 suites、consumer 9 tests／2 suites、format clean、SwiftLint 145 files／0 violations。29 files 均在 allowlist，無刪檔、diff check pass；圖表 hashes／四桌面 containment／canonical 與歷史 evidence 一致。 |
| R01 | completed | Reviewer | 獨立成果／證據／scope 審查，明示 verdict | 獨立 Reviewer 正式 verdict：approved，critical none；source／tests／docs／圖／receipts 符合契約。獨立實看四張 lifecycle 與三張 canvas captures passed；未重跑測試。只建議同步 artifacts 過期頁首狀態，本次已整理。PR Lens 待真實 commit 後提供，不作 gate。 |
| H01 | pending | Human | 已授權 topic commit／push／Draft PR 交付後檢視成果 | 成果已驗收；將依本次明確授權執行 topic commit／push／Draft PR。實際 publication evidence 由交付回覆與 PR 記錄；human review pending，不視為 completed。 |

## Blockers

- 目前無已知 scope／技術 blocker。
- P02／R01 已取得獨立 approved，T01 五項 checks 全 pass；目前無交付 blocker。
- PR 尚未建立；root 唯讀確認 graphify 0.9.73（refresh opt-out）／PR Lens 0.11.0 符合 pin。無 graph，source fallback，未建圖；PR Lens 待真實 distinct commit provenance。
- 未來實際 blocker 附具體 evidence／owner／解除條件，不把未執行視為通過。

## Human Check

使用者本次已明確確認計畫，授權「建立 feature worktree → 只在 feature 實作 → 無重大問題直接 topic commit → push → Draft PR → human review」。feature worktree 已由上游建立並驗證；planning、實作、獨立驗證與成果審查已完成。

此明確授權優先於一般 skill 需再確認 commit message 的規則，不新增中途確認；staged diff 仍須依 git-commit-convention 檢查單一 commit 語意邊界並形成合適 message。正式 planning／verification／獨立 review gates 不省略。

R01 approved 且無重大問題後，由後續 Implementer 在 feature branch 執行已授權交付，Draft PR base 為 dev，再到 H01 停止等待 human review。不授權 merge／release；不因 PR Lens local-only 禁止地圖發布而禁止另行授權的 GitHub Draft PR。

## 路由與停止條件

P01 → P02 → I01 → I02 → T01 → R01 → 已授權 commit／push／Draft PR → H01。需要回修時交回對應產出角色；只有獨立審查者明示 verdict 可推進 gate，status／checkbox 不取代 approved。

scope／architecture／path／contract 衝突、超出精確允許集合、重大問題、blocked／human-check 或未授權動作停止回報。其他 topic、dev worktree、global skills／configs 不得修改。Plan-Creator 不做 runtime、測試、Git 或自我 review。

## 更新資訊

2026-10-13，Plan-Creator：依使用者已確認完整修訂稿建立四份正式 artifacts，記錄九欄位、TC01–TC11、branch、指定 skills 限制與本次直接 topic commit／push／Draft PR 授權。P01 completed；P02 pending；formal upstream verdict null。


## Implementer 交接證據（2026-10-13）

所有修改在指定 feature worktree，branch 為 feat/github-rest-client-method-contract；未 commit／push／建立 PR，未修改 dev worktree。無新 public API、provider／GraphQL／generic HTTP／manifest／config 改動。

- Red：`swift test --filter GitHubRestClientTests` 在新增 tests 後因缺少 GitHubRestClient 契約編譯失敗；缺失可歸因需求。
- Green：同命令 15 tests、61 cases 通過；後續 `swift test --filter GitHubIntegrationTests` 156 tests／17 suites 通過。
- Format：只對本次五個 Swift files 執行 `swift format format -i`；其 `swift format lint --strict` 與 `swiftlint lint --strict --quiet` exit 0。
- `git diff --check` exit 0。完整 repository checks 與 consumer script 留待獨立 Tester，不以局部檢查替代。
- TC01：substituteReceivesAllEightEntrypoints／defaultBuildersDispatchExecutionWitness；TC02：methodsPreserveRequestAndRawResponse；TC03：wrongMethodStopsBeforeCredentials／invalidURLStopsBeforeCredentials 加既有 GET destination matrix。
- TC04：firstUnauthorizedReplaysOnlyAuthorization（先取得非零 used version，可抓偽造 snapshot）；TC05：secondUnauthorizedStops；TC06：writeStatusRemainsRaw／writeTransportErrorsDoNotRecover 加既有 GET regression。
- TC07：writeCredentialFailuresPreserveClassification／invalidWriteTokenNeverSendsInvalidBearer 加既有 GET；TC08：兩組 writeCancellation tests 加既有 GET；TC09：concurrentWritesShareOneRecovery／lateStaleUnauthorizedUsesCurrentReplacement，使用 gates 而非 sleep。
- TC10：integration regression 包含 GET／GraphQL／provider／redirect／static isolation；consumer contract 待 Tester。TC11：文件／canonical／歷史 evidence 與受限檔案 diff 交獨立檢查。

圖表 receipts 位於 docs/architecture/diagrams/github-oauth-dual-client-architecture/。v11 spec 在首次 showcase validate pass 後即 freeze，deliver 後未更改 spec 或 HTML。delivery receipt 只將 input／output 正規化為 repository-relative，hash／bytes／validation 不變：

- specification SHA-256：cf640afa61dc235fdd94bcad6c849875ec6e15af286436b2608f7101e7580d7c；6190 bytes。
- artifact SHA-256：c38350e9d22f064b46f2ff66fb223074a9fdde53ce8bce7bace33c83b617b130；711532 bytes。
- 最終重新計算與 delivery receipt 完全相符。visual-check 四 viewport 均無 overflow，light／dark captures 與 contact sheet／JSON 均已產出，auto visualReview pending 保留原值。
- 人工以 image reader 檢視 lifecycle 1440 light 與 2048 dark、canvas overview／top／bottom 三張：新增 REST 四 methods／雙入口文案無 collision；最大 lifecycle viewport 垂直構圖平衡。人工結果另記 canvas-visual-review.md，未寫入 frozen spec 或自動 receipt。
- v10 及歷史 lifecycle evidence、canvas-1440x900.png 未修改。canonical 改為 v11；沒有 preview server、上傳或發布。

I01／I02 completed 僅表示產出角色已交接；T01 pending、R01 pending，無成果 approved 宣稱。


## Final delivery 前紀錄（2026-10-13）

Tester 五項 checks 全部 exit 0，Reviewer approved／critical none，T01／R01 completed。TC01–TC11 的 source／tests／documentation／diagram evidence 已獨立檢查。consumer 的既有 generic JSONSemanticDecodingError.Kind Sendable warning 非本次變更，未修改該檔，保留為 baseline limitation。

已同步 requirements／technical-spec／plan 過期狀態；技術規格的原現況段明示為實作前依據。此整理只更動 topic metadata，不重跑完整 tests。交付前檢查 diff、精確 stage 並依 git-commit-convention 確認單一 topic 語意；採使用者已明確授權直接 commit／push／Draft PR，無再次確認需求。

目前 H01 pending：此紀錄不聲稱尚未發生的 commit／push／Draft PR 已完成。實際 SHA／remote／Draft PR／local PR Lens evidence 將在交付回覆記錄，避免為回填自身 SHA 或 PR URL 再新增循環 commit。Human Review 尚未完成，無 merge／release 授權。
