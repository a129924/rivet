# GitHub 首次登入：執行帳本

- Topic：`github-first-sign-in`。
- Phase：S07 Draft PR 交付。
- Current step：S07。
- Current status：in-progress；獨立 Reviewer approved，準備 commit／push／Draft PR。
- Upstream verdict：approved；獨立 Plan-Reviewer 已明示 S01／S02 approved（2026-10-20）。
- Branch：feat/github-first-sign-in；base／PR target：dev；基線 16606b89b8e3e6b61523c23aa0be9653c1ea7b44。
- Worktree：使用者指定的本 topic feature worktree；不得在 dev 或平行儲存線實作。
- 最後更新：2026-10-20，主 agent 轉錄獨立 Reviewer approved；S07 進行中。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[plan](github-first-sign-in.plan.md)。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker／verdict |
|---|---|---|---|---|---|
| S01 | completed | Plan-Reviewer | 獨立審四 artifacts、locked decisions、九欄、manifest、TC與交付順序 | 四文件已由 Plan-Creator 建立；主 agent 傳達獨立 Plan-Reviewer 明示結果 | approved（外部 verdict） |
| S02 | completed | Plan-Reviewer | technical-spec §6 Human ownership amendment／source SHA／無DPK前置與無重疊實作 | 2026-10-20平行draft唯讀快照及矩陣；主 agent 傳達獨立結果 | approved（外部 verdict）；不等待儲存adoption |
| S03 | completed | Implementer | W02／W03及必要M01／M02；bounded九欄與明示完成交接 | 已接收 Implementer 明示交接；S05 親跑結果見 evidence/contracts.md | 需S01／S02 approved |
| S04 | completed | Implementer | W04–W06／M03；store、host、UI、API、docs／圖 | 已接收 Implementer 明示交接；圖視覺限制與最終 build/test 見 evidence | 依S03整合，不碰其他worktree |
| S05 | completed | Tester | 受控tests／consumer／build／check、docs／工具證據分列 | evidence/contracts.md、compatibility.md：276 root＋13 consumer＋8 app pass（R1最終），格式/lint pass | coverage 限制經 Reviewer 接受；反向PKCE/canvas視覺Human pending |
| S06 | completed | Reviewer | 獨立code／scope／evidence review，required fixes明示 | evidence/reviewer-verdict.md（外部明示 verdict 轉錄） | approved；R1 required fix 已關閉 |
| S07 | in-progress | Implementer | 無重大問題且上游允許；staged語意檢查後commit→push→Draft PR回dev | 真commit IDs／push／Draft PR URL待補 | user已明示授權，不merge |
| S08 | pending | Human；Tester記錄 | Draft PR後human review，真登入／再次API／新code反向PKCE實際結果 | product-e2e.md：正常授權及再次/user已由Human/主agent觀察；反向PKCE待Human | 不得擅取secret；pending不改寫通過 |

每個 step status／checkbox 均不等於 approval；只有獨立角色明示 verdict 才能路由。各角色只填自身實際事實及已收到的外部 verdict。

## Blockers／待辦界線

- B01（已解除）：依主 agent 明示，獨立 Plan-Reviewer 已對 S01／S02 approved；v2 candidate 與 app lock amendments 亦 approved。
- B02：儲存線四 draft仍有舊重疊，來源與SHA已記technical-spec §6；Human split已決，不重問。S02審本topic amendment即可；儲存線產品實作前須在其流程回修，不要求本topic等E007／DPK。
- B03（現行）：受控 root/consumer/app tests 與 strict checks 親跑通過；contracts.md 明列 coverage gaps，獨立 Reviewer 已接受限制，不將全部 TC 冒稱完整。Canvas 視覺 Human pending，PR Lens 待真 diff。
- B04：真實OAuth／反向PKCE需Human個人配置與互動，記Human review pending；依最新user順序，不作開Draft PR的前置。不是授權agent讀取既有secret或gh credential。

## Human Check 與授權

已確認：個人OAuth App、secret程序內、單帳號GitHub.com、loopback+S256、五分鐘單session、完整bundle程序內、同provider/scope多次/user、local ad hoc host、不帶DPK adoption gate；ownership split見technical-spec §6。

已授權：建立feature worktree並只在其內實作；無重大問題時commit→push→Draft PR→Human review。仍做staged diff語意／message檢查；不重問已授權發佈、不merge。需要具體外部OAuth設定／系統安全變更或出現重大scope gap時，停止受影響動作回Human，不以推論跨越。

未提供／不可推定：個人secret、PKCE反向結果、遠端refresh全路徑成功、儲存採用或Human接受。正常授權及再次/user由Human/主agent明示觀察，見product-e2e.md；其餘保持pending。

## 本輪九欄事實交接（Planning）

- In-Scope：建立本topic四planning artifacts，明示Human split／精確manifest／TC01–TC09／工具策略／交付順序。
- Out-Of-Scope：產品實作、測試、工具生圖、branch mutations、commit／push／PR、其他worktree寫入。
- ReadOnly：README／project指令／架構／既有source、平行儲存draft四檔、skills。
- Written：requirements.md、technical-spec.md、github-first-sign-in.plan.md、github-first-sign-in.step.md（完整相對path見plan W01）；本輪實際建立。
- Deleted：無。
- Modify：無既有repository檔案；不修改平行儲存draft或其verdict。
- Goal：給獨立Plan-Reviewer可讀的完整執行契約與S02 ownership evidence。
- Non-Goal：宣稱planning approved、實作／驗證完成，或替儲存線核准／回修歷史帳本。
- TestCase：TC01–TC09全未執行；本輪只讀source／draft並建立planning檔案。

後續每次swift-implementation開始及完成交接都必須重列九欄與該slice精確paths／實際diff evidence，不能將本Planning事實沿用成產品實作事實。

## S03 開始交接（Implementer）

- In-Scope：W02/W03 授權 configuration、factory、session、exchange 及必要 M02。
- Out-Of-Scope：既有 refresh/provider/scope 政策、持久化、其他 worktree。
- ReadOnly：既有 credential/provider/client contracts 與 runtime；baseline 16606b8。
- Written：plan W02/W03 精確新檔；此刻先新增三份 failing tests。
- Deleted：無。
- Modify：StaticIsolationTests.swift、consumer PublicAPITests.swift；四份 planning 狀態依事實更新。
- Goal：有效 callback 單次取得完整 bundle，無效或遲到結果不得發布。
- Non-Goal：遠端 OAuth/PKCE 已驗證、持久化或 repository 權限。
- TestCase：TC01–TC04/TC06；基線 GitHubIntegration 195 tests passed，新測試 red 待記錄。

## S03／S04 實作交接（Implementer）

- In-Scope：plan W02–W06、核准 v2 candidate 與 app lock；完整初次授權、程序內 app 組合、文件圖。
- Out-Of-Scope：持久化、其他 worktree、既有 lifecycle／BC 政策變更。
- ReadOnly：原 provider/store/scope/client contracts；通用 HTTPClient、root Package.swift／lock。
- Written：W02/W03 source/tests，W04 app/project/lock，W05 Presentation/tests，W06文件與圖；實際逐檔以 feature diff 為準，未把 canvas screenshots 當成已產生。
- Deleted：無。
- Modify：M02 consumer與靜態source allowlist、M03四長期文件、planning狀態；原HTTP refresh fetcher未修改。
- Goal：一次授權交付完整bundle，正式app使用同provider/scope多次呼叫/user。
- Non-Goal：反向PKCE、全部遠端refresh/401、跨重啟採用均未宣稱。
- TestCase：red為目標新型別缺席；green S03三suite 10tests；root 276tests通過，app 7hostedtests通過，最終獨立驗證待Tester。正常live與再次API已觀察，反向PKCE Human pending。

規劃 amendment：獨立 Plan-Reviewer 已核准 v2 candidate；app generated lock精確列入W04後已回查approved。Canvas互動視覺因file URL policy受限，未繞過；Archify四截圖已實看。

## S05 獨立 Tester 完成交接

親跑 root 276 tests、consumer 13 tests、app 最終8 tests 全部通過；root/app strict format與SwiftLint exit0。只寫 evidence/contracts.md、compatibility.md及本帳本；未改產品code，未操作現有live app。精確九欄、source dirty fingerprint、actualpaths、warnings、TC覆蓋及限制見上述兩份 evidence。

S05 測試執行完成不等於 approved；R1補充TC06真provider gatedrefresh/rotation-save settlement，完整app8tests重驗passed；其他coverage限制交獨立Reviewer判定，反向PKCE/canvas視覺保留Human pending。

### S05 R1 bounded 重驗

Reviewer R1 required fix：Implementer僅新增 app coordinator 真provider gatedrefresh取消/settlement測試。Tester親跑完整app build/test 8tests／4suites passed；app strict format/lint exit0。產品source未改，root/consumer結果沿用。最終dirty source指紋見contracts.md。已補TC06證據，交獨立Reviewer複查，不代填approved。
