# 正式 OAuth 能力與獨立驗證 App：執行帳本

- Topic：`github-first-sign-in`。
- Phase／Current step：A07 Human review。
- Current status：A07 human-check；新host正向live與再次API已觀察通過，其餘Human review／反向PKCE／canvas互動仍pending。
- Upstream verdict：approved；獨立 Plan-Reviewer 明示 A02 approved，無 required fix（2026-10-20）。
- Branch：`feat/github-first-sign-in`；base `dev`；[原 Draft PR #61](https://github.com/a129924/rivet/pull/61)。
- 回修基線：`e63eeb21b4774adafc5f8a822ac474df7e0bdc22`；沿用原 feature worktree，不在 dev／其他worktree實作，不建新PR／worktree、不merge。
- 最後更新：2026-10-21，Tester；依Human協助與主agent實際UI觀察記錄A07新host正向驗收，見 verification-host-amendment.md。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[plan](github-first-sign-in.plan.md)。

## 現行 amendment ledger

Human 已確認「正式 OAuth 實作能力＋獨立 GitHubSignInVerification App」；正式 Rivet 產品登入 UI 尚未交付。舊host命名與產品交付說法由此決策取代，以下歷史區保留作來源，不構成現行執行契約。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker／verdict |
|---|---|---|---|---|---|
| A01 | completed | Plan-Creator | 四planning一致，16rename/Delete與新增圖精確manifest先列 | 本次四planning內容；只讀基線source/文件 | 未自審 |
| A02 | completed | Plan-Reviewer | 獨立planning範圍/manifest/九欄/驗證審查 | 獨立 Plan-Reviewer 明示 A02 approved | approved |
| A03a | completed | Implementer | approved後App/project/UI/test bounded搬移 | A03a完成九欄；16rename與精確diff已由Tester／Reviewer核對 | 需A02 approved |
| A03b | completed | Implementer | 長期docs/修訂圖/來源聲明與工具驗證 | A03b完成九欄；v3／canvas v2收據與來源聲明 | 依A02契約 |
| A04 | completed | Tester | root/consumer/app/format/lint/隔離/圖驗證 | verification-host-amendment.md：275 root／13 consumer／9 app passed；strict checks及圖validate/hash通過 | A04當時新host live pending；2026-10-21正向另見A07；canvas互動/反向PKCE仍pending |
| A05 | completed | Reviewer | 獨立review及requiredfixes關閉 | 獨立 Reviewer 明示 approved，無 required fix；見 amendment evidence | approved |
| A06 | completed | Implementer | staged語意→commit→push→更新原DraftPR61與local真diffPRLens | 回修commit `81fe01f3377abbf7e7382d2c77fc756034c4fffc` 已push；原PR61標題/描述已更新；local真diff map於交付產生 | user已授權，需A05approved |
| A07 | human-check | Human；Tester記錄 | 原PRhumanreview、新hostlive適用項目 | e941d88新host正常授權及真/user、同程序再次查詢observed passed；反向PKCE與全部Human review仍pending | 不讀取或保存機密 |

## 現行 Blockers／Human Check

- 無新增重大scope決策缺口；A02獨立Plan-Reviewer明示approved（無required fix），Tester已完成，獨立code Reviewer明示approved，無required fix。
- 2026-10-21 Human自行配置並授權；主agent觀察e941d88新驗證App正常授權→真/user及再次查詢通過。既有VerificationHostDerivedData測試後build、正常模式、未重建；身分有效但不存值。反向PKCE、canvas互動視覺、全部遠端refresh/401及跨重啟仍未通過，全部Human review尚未完成。
- 舊canvas的file-URL policy限制沿用，不改其他路徑繞過。圖若必要驗證受限則如實記pending，不宣稱完整視覺通過。
- user已授權本topic回修/commit/push/更新原DraftPR，無重大問題不重問；不得新worktree/PR或merge。重大contract/scope或外部系統設定變更才停受影響動作回Human。

## A01 九欄完成交接

- In-Scope：四planning現行契約amendment、HumanDecision、先列16rename/delete、修訂圖與獨立gate。
- Out-Of-Scope：code/docs圖實作、測試、Git與PR操作、其他topic/worktree。
- ReadOnly：README/design-principles/architecture、原四planning、基線host/UI/圖檔名、plan-creator及SDD契約。
- Written：無新repository檔案。
- Deleted：無（只規劃後續16rename來源）。
- Modify：analysis/github-first-sign-in/requirements.md；analysis/github-first-sign-in/technical-spec.md；plan/github-first-sign-in/github-first-sign-in.plan.md；plan/github-first-sign-in/github-first-sign-in.step.md。
- Goal：獨立Plan-Reviewer可讀的受限現行契約。
- Non-Goal：不宣稱本次planning approved、搬移或驗證已完成。
- TestCase：本輪未執行；AT01–AT05與TC01–TC09適用regression交Tester。

後續每個implementation slice開始與完成均記同九欄及actualdiff，不沿用本planning事實作完成證據。

---

## 歷史交付 Steps（基線 e63eeb2）

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker／verdict |
|---|---|---|---|---|---|
| S01 | completed | Plan-Reviewer | 獨立審四 artifacts、locked decisions、九欄、manifest、TC與交付順序 | 四文件已由 Plan-Creator 建立；主 agent 傳達獨立 Plan-Reviewer 明示結果 | approved（外部 verdict） |
| S02 | completed | Plan-Reviewer | technical-spec §6 Human ownership amendment／source SHA／無DPK前置與無重疊實作 | 2026-10-20平行draft唯讀快照及矩陣；主 agent 傳達獨立結果 | approved（外部 verdict）；不等待儲存adoption |
| S03 | completed | Implementer | W02／W03及必要M01／M02；bounded九欄與明示完成交接 | 已接收 Implementer 明示交接；S05 親跑結果見 evidence/contracts.md | 需S01／S02 approved |
| S04 | completed | Implementer | W04–W06／M03；store、host、UI、API、docs／圖 | 已接收 Implementer 明示交接；圖視覺限制與最終 build/test 見 evidence | 依S03整合，不碰其他worktree |
| S05 | completed | Tester | 受控tests／consumer／build／check、docs／工具證據分列 | evidence/contracts.md、compatibility.md：276 root＋13 consumer＋8 app pass（R1最終），格式/lint pass | coverage 限制經 Reviewer 接受；反向PKCE/canvas視覺Human pending |
| S06 | completed | Reviewer | 獨立code／scope／evidence review，required fixes明示 | evidence/reviewer-verdict.md（外部明示 verdict 轉錄） | approved；R1 required fix 已關閉 |
| S07 | completed | Implementer | 無重大問題且上游允許；staged語意檢查後commit→push→Draft PR回dev | 實作 commit `46b48730c68580cc51cd5b44898a85aff7f79118` 已 push；[Draft PR #61](https://github.com/a129924/rivet/pull/61) | user已明示授權，不merge |
| S08 | human-check | Human；Tester記錄 | Draft PR後human review，真登入／再次API／新code反向PKCE實際結果 | product-e2e.md：正常授權及再次/user已由Human/主agent觀察；反向PKCE待Human | 不得擅取secret；pending不改寫通過 |

每個 step status／checkbox 均不等於 approval；只有獨立角色明示 verdict 才能路由。各角色只填自身實際事實及已收到的外部 verdict。

## Blockers／待辦界線

- B01（已解除）：依主 agent 明示，獨立 Plan-Reviewer 已對 S01／S02 approved；v2 candidate 與 app lock amendments 亦 approved。
- B02：儲存線四 draft仍有舊重疊，來源與SHA已記technical-spec §6；Human split已決，不重問。S02審本topic amendment即可；儲存線產品實作前須在其流程回修，不要求本topic等E007／DPK。
- B03（現行）：受控 root/consumer/app tests 與 strict checks 親跑通過；contracts.md 明列 coverage gaps，獨立 Reviewer 已接受限制，不將全部 TC 冒稱完整。Canvas 視覺 Human pending，PR Lens 對真實 commit diff 於本機產生；不寫 repository .pr-lens 或上傳。
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

## S07 交付記錄

- 實作：`46b48730c68580cc51cd5b44898a85aff7f79118`；topic message 經 staged 語意檢查，全部 pre-commit hooks 通過。
- 已 push：`origin/feat/github-first-sign-in`；[Draft PR #61](https://github.com/a129924/rivet/pull/61)，base `dev`。
- 本次記錄提交只更新交付帳本，不改產品 source 或已核准契約。
- 停點：S08 Human review；不 merge、不釋放 worktree，不將 Human pending 改寫為通過。

## A03a 開始交接（Implementer）

- In-Scope：plan §2 全16筆rename與搬後必要host/UI/test識別修改。
- Out-Of-Scope：正式產品登入、帳號業務、新module及OAuth政策。
- ReadOnly：GitHubIntegration全source/tests、PR Inbox、rootPackage；基線e63eeb2。
- Written：plan rename表16筆目的（完整逐檔路徑為本slice精確allowlist）。
- Deleted：同表16筆來源；無其他刪除。
- Modify：搬後project/scheme/entry/module/bundle/testkey、app-local UI存取、驗證提示與references。
- Goal：獨立驗證App包含真OAuth/API組合，移除共用Presentation驗證UI。
- Non-Goal：正式Rivet登入UI與新host真登入驗收。
- TestCase：AT01–AT04；搬後build/test與隔離檢查待執行。

## A03b 開始交接（Implementer）

- In-Scope：plan §2 明列長期docs、圖修訂與歷史證據來源註記。
- Out-Of-Scope：其他topic、改寫歷史結果、工具設定或發布圖。
- ReadOnly：舊frozen v1/v2與生成物、experiments、其他worktree。
- Written：plan新圖精確11檔與evidence/verification-host-amendment.md；實際生成再記。
- Deleted：無。
- Modify：plan列明5長期docs、3工具紀錄、4歷史evidence；四planning依實際更新。
- Goal：清楚區分正式OAuth能力、獨立驗證host與尚未交付產品UI。
- Non-Goal：不把舊正向live或pending變成新host已通過。
- TestCase：AT05／TC09；新圖showcase與視覺證據待執行，Graphify已確認0.9.73無圖採source fallback。

## A03a 完成交接（Implementer）

- In-Scope：已完成plan §2的16筆精確rename；app/test product、scheme、entry、bundle/module、hosted key及references同步。
- Out-Of-Scope：未新增產品登入、帳號抽象或共用module；未改其他topic/worktree。
- ReadOnly：正式OAuth/lifecycle、PR Inbox、rootPackage；與e63eeb2比較指紋無變。
- Written：rename表全部16個目的實際存在；App Sources7、Tests5、Info及project3檔。
- Deleted：rename表16個來源實際移除，無其他刪除。
- Modify：搬後必要識別及UI public移除；project移除RivetPresentation產品與兩target引用；callback/queue/User-Agent改驗證App識別。
- Goal：驗證App明示用途，真OAuth/API組合保留；共用Presentation無驗證UI。
- Non-Goal：不宣稱已build/test、新host真登入或產品UI交付。
- TestCase：swift format僅處理新App source/tests；AT01–AT04實際執行交Tester。

## A03b 完成交接（Implementer）

- In-Scope：五份長期docs與現行圖連結、三工具紀錄、四歷史evidence來源聲明；四planning記實際進度。
- Out-Of-Scope：未改歷史實驗/測試/live結果，未發布圖或修改工具設定。
- ReadOnly：舊frozen specs／HTML／receipts指紋均相同；正式OAuth全部source相同。
- Written：scene-v2.js、index-v2.html；authorization-sequence-v3.json/html/delivery.json/visual-check.json/visual-check.html及1440x900/2048x1320的light/dark四PNG；verification-host-amendment.md。
- Deleted：無。
- Modify：plan §2列明5長期docs、3工具紀錄、4舊evidence與四planning；僅本topic允許範圍。
- Goal：正式能力／驗證host／未交付產品UI有一致文字與圖；舊證據標e63eeb2來源。
- Non-Goal：canvas互動、新hostlive、反向PKCE及全部遠端refresh/401保持pending。
- TestCase：Archify v3九checks零errors/warnings、四viewport通過，四截圖已實看可讀無遮擋；canvas v2 validate/build 5bands/18boxes/17edges零errors/warnings，互動視覺pending；Graphify 0.9.73無圖採source fallback。PRLens待真commit diff。

## A04 獨立 Tester 完成交接

In-Scope：AT01–AT05；Out-Of-Scope：code/Git/live/其他worktree；ReadOnly：planning/source/diagram；Written：無新repository檔案（build及scratch不入版控）；Deleted：無；Modify：verification-host-amendment.md及本step；Goal：獨立驗證實際回修；Non-Goal：不代Reviewer/Human核准；TestCase：root275/consumer13/app9，strict checks與Archify9checks均pass，正式OAuth/PRInbox/rootPackage與lock不變。完整命令、指紋、限制見該evidence；交A05獨立Reviewer。

## A05 外部 verdict 與 A06 開始

2026-10-20，主 agent 轉錄獨立 Reviewer 明示 **approved，無 required fix**。Reviewer逐一比較16搬移檔與e63eeb2，變動限於App識別、app-local存取、引用／依賴與核准文字；正式OAuth/lifecycle/PRInbox未變。文件／新圖與歷史來源一致，Tester275/13/9結果符合搬移範圍。Reviewer只讀未改檔或跑tests。

依使用者授權進行staged語意檢查、同topic commit/push、更新原DraftPR61。新hostlive／反向PKCE／canvas互動與既有coverage限制不改寫為通過；不merge。

## A06 實際交付

- 回修commit `81fe01f3377abbf7e7382d2c77fc756034c4fffc`，message `refactor(github-first-sign-in): 將登入外殼分離為獨立驗證 App`；staged語意與全部pre-commit hooks通過。
- 已push原 `origin/feat/github-first-sign-in`，並更新[原Draft PR #61](https://github.com/a129924/rivet/pull/61)標題與描述：正式OAuth能力＋獨立驗證App，正式產品登入UI尚未交付。
- 本筆交付記錄commit只改帳本/evidence，不改受驗source。最終head的local PRLens map於外部topic scratch validate/render，實際SHA/結果隨PR及交付回報提供，無上傳。
- A07停點：Human review。新host真登入、反向PKCE、canvas互動及既有未驗證路徑pending；不merge、不建立/移除worktree。

## A07：2026-10-21 真人協助正向驗收記錄

Human自行輸入配置與完成OAuth；主agent以CUA觀察獨立GitHubSignInVerification初次真/user成功且身分欄位有效，並操作再次查詢，AX確認apiSuccess=true、busy=false、knownFailure=false，未重新授權。來源e941d88；既有VerificationHostDerivedData測試後build的產品source與該版本一致，正常模式，非重建新build。詳見amendment evidence的A07。

Tester本輪只記錄明示結果，不跑測試、不操作live app、不改code或Git；只修改本step與verification-host-amendment.md，不保存任何身分或機密值。新host正向與再次查詢observed passed；反向PKCE／遠端refresh與401／canvas互動／全部Human review維持pending，不代Reviewer核准。
