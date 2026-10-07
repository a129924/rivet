# GitHub GraphQL Infrastructure Foundation：Step Ledger

## Current State

- Topic：`github-graphql-infra-foundation`
- Branch：`feat/github-graphql-infra-foundation`
- Feature worktree：`../rivet.worktrees/agent-20261007-github-graphql-infra-foundation`
- Base：`a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f`，來自dev；DraftPR base：dev。
- Current phase：`delivery`
- Current step：`delivery`／`in-progress`
- Upstream verdict：`approved`
- Current verdict：`approved`
- Last updated：2026-10-07 — 限定修復獨立 Tester pass、Reviewer approved／無 required fix；產品及圖 approval 保留，依 Human 既有條件式授權恢復 delivery。先核對 staged semantic／message 與 634 檔 hash；本輪尚未執行 true commit hook，不提前宣告 commit／push／PR。

## Steps

| ID | Status | Owner role | Completion condition | Verification evidence |
| --- | --- | --- | --- | --- |
| planning-artifacts | completed | Plan-Creator | 四份同slug文件在feature存在且可讀，記錄internal API／九欄／allowlist／AC／gates；最小provider ledger correction落地。 | 本次apply_patch成功建立四份文件並更正provider ledger；rg列出四份artifacts，readback／status確認只有這五份planning檔案；未實作／測試／Gitdelivery，不產生approval。 |
| plan-review | completed | Plan-Reviewer | 讀取四份formal artifacts，獨立審查並明示standardverdict。 | 2026-10-07 獨立正式 Plan-Reviewer `approved`，Dispatcher handoff 明示實際四份 artifacts、無 required fix。 |
| swift-implementation | completed | Implementer | formalplan-review approved後，只在allowlist完成internalQueryfoundation與明示handoff。 | exact Apollo 2.1.2 resolved，Swift 6.3.3 compile 真 transport／TaskLocal／noncopyable；meaningful red 為 401 未 recovery 及 finite／cancel mapping 8 failures，green focused 69 tests／6 suites；最後 root swift test 163 tests／21 suites、consumer 8 tests、format strict／SwiftLint strict 0 violations、git diff check 通過。所有產品檔只在 feature GraphQL/。 |
| docs-writeback | completed | Implementer | 按boundedallowlist回寫internal交付狀態；canonicaldiagrams依skill驗證，deferred能力不誤標已交付。 | 六份 docs 及 canonical canvas／lifecycle 狀態同步。Canvas 0 errors／warnings；Archify 9/9 showcase 0 errors／warnings，4 desktop containment pass、light／dark captures 成功；Implementer 實際檢視紀錄於 canvas-visual-review.md。v1–v5 unchanged，不 publish。 |
| verification | completed | Tester | 接收Implementerhandoff，獨立完成測試矩陣／consumer／isolation／rootchecks／diagram驗證。 | 修正前獨立 pass 保留：root 163／21、focused 69／6、consumer 8／1、format／lint 0、diagram validate pass。P2 fix 後 Dispatcher 傳回獨立 Tester recheck pass：新增 2 tests、focused 71／6、root 165／21、consumer 8／1、format 0、lint 96 files／0 violations、diff 0、dev clean。 限定修復獨立 Tester pass：normal／polluted consumer 8／1、15 local variables unset、archive 解開 634 files hash match、normal／polluted true feature index hash 不變、manual consumer hook 8／1、root 165／21、format／lint 96 files 0、bash -n／diff 0。manual hook 正常 index refresh 只改 bytes，logical 634 paths／40 staged／634 content match。 |
| outcome-review | completed | Reviewer | 依Testerevidence獨立審查scope／contract／取消／retry／concurrency／docs並明示verdict。 | 保留歷史 `needs-rework`：唯一 P2 非 HTTP URLResponse crash。private session adapter 與真 chain regression 後，2026-10-07 Dispatcher 傳回 Reviewer recheck `approved`：P2 解除、無新 finding，normal chunks／errors／cancellation 保留。非自審通過。 限定修復獨立 Reviewer 正式 approved／無 required fix，可恢復 delivery；原 GraphQL code／diagram approval 保留。 |
| delivery | in-progress | Implementer | plan／test／outcomegates完成且無重大blocker；依預先conditionalauthorization檢查stagedtopicsemantic與message、commit／push／DraftPR；pr-lens僅external-scratchlocalmap。 | 歷史首次 Staged 39 files，單一 topic／原 allowlist；message：feat(github-integration): 建立內部 GitHub GraphQL Query 基礎。兩次 commit 被 consumer hook Apollo revision 38c202227d0f09508e573dcf22f54885cfb0c5d4 的 unable to read tree 阻擋；無 commit。format／SwiftLint hooks pass，renderer feature frozen dependency setup 後 hook pass。相同 consumer wrapper standalone 8／1 pass；不將它當成 hook pass，不刪 shared cache、不 skip hooks、不修改 scripts／config。PR Lens 0.11.0 已確認但 final-head map 尚未產生；Graphify 0.9.73 bounded查找仍無 usable graph，不 build。 限定修復獨立 approved 後現為 exact 40 files，恢復已授權 delivery；true commit hooks 尚未執行。 |
| human-review | pending | Human | 接收DraftPR與actualevidence作最終review；不自動merge／release。 | pending；PR未建立。 |

## Locked Decisions與既有Evidence

- P2 bounded fix evidence：`swift test --filter sessionValidatesResponseBeforeEnteringApollo` 安全 red 1 test／2 issues（缺 private session guard；不執行會 crash 的舊 chain）。修正後 nonHTTP／guard focused 2 tests／2 suites green；GraphQL／isolation focused 71 tests／6 suites、root 165 tests／21 suites green。private session adapter 原傳 chunks／errors／cancel，非 HTTP response 在 Apollo cast 前轉既定 executionFailed；真 chain regression 驗證 1 request／0 refresh／不 crash。format strict、SwiftLint strict 0 violations、git diff check pass；docs／diagrams 未再變動。以上為 Implementer evidence，待獨立 gate 重驗。
- Human已授權Apollo位於既有GitHubIntegrationtarget的boundeddependency／isolation更新。
- 2026-10-07 Human明選internalfoundation：internalfinalclient／fetch、唯一internalApolloGraphQLExecuting，跨target使用deferred；不是publicexecute能力。
- concreteOAuthTokenProvider與TokenSnapshot／typederrors既有契約保持；restore／expiry／staleversion／refresh／rotation／persist／single-flight屬provider。
- maximumAuthenticationRecoveries固定1；HTTP401fixedsemantics／sameQueryvariables／second401terminal；不新增policy／classifier／mapperprotocol。
- privateasync-boundaryhelper優先取消，含URLError及typedproviderstagewrappedcancel；不cancelsharedrefresh或承諾promptawait。
- exactApollo2.1.2／固定POST／APQoff／retry0／networkOnly＋explicitnoCacheWrite；GraphQL四source／所有新tests固定GraphQL子目錄。
- 2026-10-05 provideriteration2本次獨立Reviewerapproved／Humanaccepted來自Dispatcherhandoff；本次只保存record，沒有新跑provider測試。
- source-level Apollo feasibility 來自 Explorer；本次 Implementer 已取得 assembly／generic／TaskLocal／noncopyable／取消與 concurrency 的新 compile／integration evidence，仍待獨立 Tester 重驗。
- graphify0.9.73歷史限定查找沒有usablegraph；revision／freshness／query未驗證，sourcefallback不等於graphcheck。每CLI使用GRAPHIFY_NO_AUTO_REFRESH=1，不buildgraph，不增gate。
- Human最新授權featurewrite及無重大問題時conditionaltopiccommit／push／DraftPR，最後humanreview；不是gateapproval。pr-lens僅delivery時external-scratchlocalmap，無repo設定／upload。

## Blockers

- 正式 Plan-Reviewer 已 approved；無 planning blocker。
- Delivery：原 hook／後續 index 污染的 Human 限定修復已經獨立 Tester／Reviewer 通過，無 required fix；尚須 true commit hooks 實際通過，未執行前不當作完成。
- Reviewer P2 已由獨立 recheck `approved` 解除；歷史 `needs-rework` 保留，不以 Implementer tests 代替 verdict。
- 沒有已知新增scopegap；graph缺漏僅工具evidencegap，不作架構blocker或新前置gate。

## 限定 Delivery 修復與診斷因果

- 2026-10-07 Human 明示授權：先備份受損 exact feature index 與 working contents，再從 feature HEAD 重建 index，不還原／刪除工作檔；唯一追加 Modify 為 scripts/check-github-integration-consumer.sh 的 SwiftPM subshell local Git variable sanitation。產品 scope、architecture、API／provider／target 及其他 locked decisions 不變。
- 兩次原 commit hook checkout failure 後 feature index 仍正常；Implementer 後續診斷將真 feature GIT_INDEX_FILE 傳入 nested SwiftPM，極可能覆寫 index 為 Apollo tree。此診斷不是唯讀，不把後續污染全歸咎於原 hook；沒有產生 commit。
- 可恢復備份位於 external temporary scratch `github-graphql-infra-foundation-repair.FJBY6g/`：damaged-feature.index、working-content.tar.gz、README.md、working-files.before.sha256／working-files.after-index.sha256。壞 index SHA256 為 9219d6855be64d878c47721d38add2a624f99c8630cfba53a9c44abb9abc8925；archive SHA256 為 03639f08f6548f4ba2ed88a6887ecb18c2c1555422a3b7cea21ab1db34d7545f；before manifest SHA256 為 cd7713fb20069402ec222ae0fd4e6ee6c93ffee9987efce421c52a1945cf48f4。634 非 generated 工作檔備份檢查通過，index-only read-tree 前後所有 hash 完全相同。
- 只用 feature HEAD a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f 重建 exact feature index，無 -u／checkout／reset／工作檔刪除。重建後 index 等於 HEAD、git status 可用。dev clean／HEAD 不變；未修 shared cache／object database。
- sanitation 只有既有 subshell 三行：列出 local Git variables 並逐一 unset。沒有改測試、cleanup、hooks、config、gates 或 lint policy。safe mock normal env pass；polluted disposable fixture/index 在修正前 exit91（GIT_DIR 到達 SwiftPM）、修正後 pass。真 SwiftPM normal／polluted env 均 8 tests／1 suite pass；disposable index 與重建 feature index 在測試前後 SHA256 均維持 8abd0396cb04c1f86c586deaca77592bd454971b46f0aaec48137e806f8a378a。
- 本次為 Implementer evidence，待 Tester／Reviewer 獨立重驗；沒有執行 commit hook 重試或 commit／push／PR。此前 approved、needs-rework 歷史保留，不倒填新 approval。

## Human Check

- 保留2026-10-05provideracceptance與2026-10-07internalcontractnarrowing，不重新開已鎖decision。
- feature之外repository寫入不在scope，尤其dev不得改檔；只允許已授權external scratch存工具evidence。
- 已預先conditionalauthorize topiccommit／push／DraftPR；角色須完成formalplanreview／test／outcomereview與stagedsemantic／message檢查後才執行。
- blocked／human-check或需改scope／固定版本／APIboundary時附實際evidence停止；DraftPR完成後交HumanReview，不自動merge／release。

## Handoff

```json
{
  "topic": "github-graphql-infra-foundation",
  "phase": "delivery",
  "artifacts": [
    {"path": "analysis/github-graphql-infra-foundation/requirements.md", "status": "present"},
    {"path": "analysis/github-graphql-infra-foundation/technical-spec.md", "status": "present"},
    {"path": "plan/github-graphql-infra-foundation/github-graphql-infra-foundation.plan.md", "status": "present"},
    {"path": "plan/github-graphql-infra-foundation/github-graphql-infra-foundation.step.md", "status": "present"}
  ],
  "current_step": {"id": "delivery", "status": "in-progress"},
  "locked_decisions": [
    "internal foundation，同一GitHubIntegration target，跨targetGraphQL使用deferred",
    "internalfetchQuery/SingleResponseFormat，唯一internalApolloGraphQLExecuting，現有concreteprovider",
    "exactApollo2.1.2、GraphQL子目錄、401only/max1、finiteerror、privatecancellationhelper與原allowlist",
    "featureonlywrite；已授權conditionaltopiccommit/push/DraftPR，須先完成各formal gate"
  ],
  "upstream_verdict": "approved",
  "blockers": [],
  "assigned_role": "Implementer",
  "next_objective": "依 Human 既有授權完成 topic commit／完整 true hooks／push／Draft PR，PR Lens final-head local map；實際 PR 回寫 ledger 後交 Human Review 停止"
}
```
