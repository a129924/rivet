# 正式 OAuth 能力與獨立驗證 App：執行帳本

- Topic：`github-first-sign-in`。
- Phase／Current step：P08 提交與原Draft PR更新。
- Current status：Tester evidence-check completed，待P07獨立Reviewer；兩case均indeterminate，總2/2預算已用完。
- Upstream verdict：P02 approved，獨立Plan-Reviewer明示無required fix。
- Branch：`feat/github-first-sign-in`；base `dev`；[原 Draft PR #61](https://github.com/a129924/rivet/pull/61)。
- 回修基線：`e63eeb21b4774adafc5f8a822ac474df7e0bdc22`；沿用原 feature worktree，不在 dev／其他worktree實作，不建新PR／worktree、不merge。
- 最後更新：2026-10-21，Tester；P07安全報告／分類／來源／readonly／manifest複核完成，交獨立Reviewer；沒有live或新預算。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[plan](github-first-sign-in.plan.md)。

## P 輪現行 ledger（優先於以下 A/S 歷史）

- 本輪來源d11f343；原feature/branch/PR61、不新建不merge。正常e941d88授權＋再次查詢保留，不重做。遠端refresh/401本輪不做。
- Human已驗收d11f343 index-v2.html內容/流程/責任、拖曳、縮放可讀、聚焦說明、明暗可讀。此為Human明示事實；agent仍不繞過file-URL policy。以下A/S的canvas pending只代表歷史當時狀態。
- missing/wrong反向PKCE均已執行且indeterminate；E002判準不能沿用。每case新process、新code、單次POST，總最多兩次授權，不positive/API/retry。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker／verdict |
|---|---|---|---|---|---|
| P01 | completed | Plan-Creator | 四planning精確追加manifest/判準/九欄 | 本輪四文件；官方兩來源已讀；只讀基線 | 未自審 |
| P02 | completed | Plan-Reviewer | 獨立planning判準/安全界線審查 | 獨立Plan-Reviewer明示approved、無required fix | approved |
| P03a/P03b | completed | Implementer | approved後CLI/tests/README及允許文件，各slice九欄 | P03a/P03b九欄及精確diff；工具21tests，R1關閉 | P02approved |
| P04 | completed | Tester | fake-only PK01–PK06/必要checks/readonly確認 | pkce-negative-verification.md：最終21tests exit0（含R1）；help/noTTY/syntax/readonly/frozen23/hash/manifest通過 | 不live，不代P05核准 |
| P05 | completed | Reviewer | 獨立review/required fixes完成 | 獨立Reviewer approved；R1已關閉，21tests通過 | approved |
| P06 | completed | Human | 一次一步missing/wrong各fresh授權單POST | missing/wrong各1/1；兩者HTTP400 unknown_error/unknown、無token，均indeterminate | 總2/2用完，不retry或改判 |
| P07 | completed | Tester → Reviewer | 記錄安全結果並獨立複核分類/來源/限制 | Tester已完成安全報告/來源/分類/預算/readonly核對，見pkce-negative-verification.md | 待獨立Reviewer；兩case indeterminate，不passed |
| P08 | in-progress | Implementer → Human | review後commit/push/更新原DraftPR61/local真diffmap→humanreview | 待真SHA/URL/map | user已授權，不merge |

### P 輪 Blockers／Human Check

P02已獨立approved，無required fix；不沿用歷史A02。Canvas現行Human視覺已通過但browser policy限制未解除。反向兩case只有P05核可後交Human本機terminal以getpass自行輸入，逐步等待；秘密不進對話。未知error、generic bad_verification_code、timeout/expired/config不算passed；有token即failed並丟棄，不使用、不增加第三次授權。遠端refresh/401、跨重啟及完整PR human review仍未驗證／完成，不自動升級。

### P01 九欄完成交接

- In-Scope：四planning追加反向PKCE工具受限manifest與判準、記canvasHuman已驗收來源。
- Out-Of-Scope：實作/測試/live/Git操作、正式SwiftApp及OAuth/實驗改動。
- ReadOnly：既有文件/四planning、d11f343來源、官方授權及token錯誤文件。
- Written：無新repository檔案。
- Deleted：無。
- Modify：analysis/github-first-sign-in/requirements.md；analysis/github-first-sign-in/technical-spec.md；plan/github-first-sign-in/github-first-sign-in.plan.md；plan/github-first-sign-in/github-first-sign-in.step.md。
- Goal：給獨立Plan-Reviewer完整最小追加契約。
- Non-Goal：不宣稱工具/反向驗證完成或planning approved；不重做正常login/remote refresh。
- TestCase：未執行；PK01–PK06交Tester、遠端missing/wrong保持pending。

---

## A 輪歷史 amendment ledger

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

## P03a 開始九欄（Implementer）

- In-Scope：獨立stdlib negative CLI、fake tests及README。
- Out-Of-Scope：Swift／正式能力／實驗／正常login/API/refresh/401、新module。
- ReadOnly：d11f343的全部既有code、圖、experiments及工具設定。
- Written：apps/GitHubSignInVerification/tools/pkce_negative_probe.py；同目錄test_pkce_negative_probe.py、README.md。
- Deleted：無。
- Modify：step本次狀態；不改任何既有source。
- Goal：missing/wrong各fresh單POST、安全TTY輸入與failclosed分類。
- Non-Goal：不把mock pass當遠端PKCE通過；兩case live仍pending。
- TestCase：PK01–PK06；先新增代表性red，再完整受控green，交獨立Tester。

## P03b 開始九欄（Implementer）

- In-Scope：現行canvas Human五項passed紀錄、工具命令/安全判準與來源。
- Out-Of-Scope：改frozen圖、重做live/API、記機密或代Human未做結果。
- ReadOnly：所有圖與既有歷史結果。
- Written：plan/github-first-sign-in/evidence/pkce-negative-verification.md。
- Deleted：無。
- Modify：P manifest指定四planning、docs/architecture/github-first-sign-in.md、diagrams/github-first-sign-in的visual-review.md/BUILD.md/tool-evidence.md、evidence/verification-host-amendment.md；入口四docs僅實際結果/限制同步。
- Goal：canvasHuman來源d11f343與helper受控/遠端層級分明。
- Non-Goal：尚未執行negative，不預填passed；remoteRefresh/401保持pending。
- TestCase：PK06 source/manifest/證據核對；圖不重生。

## P03a 完成九欄（Implementer）

- In-Scope：獨立CLI、fixturetests與README實作完成。
- Out-Of-Scope：未改正式Swift/GitHubIntegration/experiments，未live/positive/API/refresh/401。
- ReadOnly：d11f343既有source/project/tests/frozen圖/設定。
- Written：tools/pkce_negative_probe.py、test_pkce_negative_probe.py、README.md三個精確manifest新檔。
- Deleted：無。
- Modify：只有step進度，無舊產品source diff。
- Goal：missing真的omit；wrong43字元且challenge不同；獨立fresh/singlePOST、TTYhidden、boundedcallback/HTTP與failclosedreport已受控驗證。
- Non-Goal：受控green不代表GitHub遠端通過。
- TestCase：20tests green，red為新module未存在；中間fixture問題與最終sourceSHA見pkce-negative-verification.md。交獨立Tester。

## P03b 完成九欄（Implementer）

- In-Scope：canvasHuman結果及CLI說明/限制/來源。
- Out-Of-Scope：未改圖、未讀秘密或代填遠端結果。
- ReadOnly：所有frozen圖與先前evidence結果。
- Written：evidence/pkce-negative-verification.md。
- Deleted：無。
- Modify：docs/architecture/github-first-sign-in.md；圖目錄visual-review.md/BUILD.md/tool-evidence.md；evidence/verification-host-amendment.md；四planning依自身與外部事實更新。
- Goal：Human canvas五項passed來源d11f343，舊pending保留為歷史；helper/遠端/完整Humanreview分層。
- Non-Goal：missing/wrong live仍pending，完整遠端refresh/401本輪不做。
- TestCase：PK06差異/manifest/source核對待Tester；圖無生成或修改。

## P04 獨立 Tester 完成九欄

- In-Scope：PK01–PK06受控測試、CLIhelp/noTTY、syntax、hash、manifest／readonly／no-pycache。
- Out-Of-Scope：真OAuth/live App/秘密/遠端refresh401/Git/其他worktree。
- ReadOnly：工具source與全部正式source/tests/project/experiments/frozen圖。
- Written：無；-B無bytecode。
- Deleted：無。
- Modify：evidence/pkce-negative-verification.md與本step自身結果。
- Goal：獨立可核對的受控與範圍證據交P05。
- Non-Goal：不核准自己的產出、不代Human執行或判missing/wrong通過。
- TestCase：20tests exit0；help0、無TTY兩case2且有限安全輸出/無stderr；syntax／readonly／23frozen／manifest通過，pycache0。正式Swift未變沿用275/13/9歷史，未跑hooks。CLI SHA與P03交接一致，詳見evidence。

P06 missing/wrong各0/1仍pending；完整遠端refresh401本輪不做。受控結果不等於P05approved或遠端GitHub通過。

## P03a R1 原slice回修九欄（Implementer）

- In-Scope：P05唯一required fix：阻止getpass echo失敗降級明文，first/second prompt fixture驗證。
- Out-Of-Scope：新需求、正式能力或任何live操作。
- ReadOnly：全部既有Swift/圖/experiments，原manifest不變。
- Written：無額外新檔。
- Deleted：無。
- Modify：tools/pkce_negative_probe.py及test_pkce_negative_probe.py；本帳本與pkce-negative-verification.md自身事實。
- Goal：getpass warning立即中止，不開瀏覽器或授權、不echo/traceback。
- Non-Goal：不宣稱Reviewer已複核或真人PKCE通過。
- TestCase：root21tests green；新SHA與原因見evidence，交獨立Tester定點重驗再P05複核。兩Human預算尚未使用。

### P04/P05 R1 getpass fallback 獨立重驗

Tester親跑完整21tests exit0（含first/second getpass fallback warning不可進run_case）；無TTY missing/wrong各exit2、安全JSON、stderr空；ASTsyntaxpass、pycache0。CLI最終SHA659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699，工具指紋與來源分層見pkce-negative-verification.md；修前20tests/hash保留歷史。

只Modify該evidence與本step，ReadOnly工具與正式source，Written/Deleted無；Goal是R1獨立證據交P05，Non-Goal是不代核准或真OAuth。沒有live、Git或Human預算消耗，兩case各0/1仍pending。其餘未變範圍不擴測。

## P05 外部核准／P06 起點

獨立Reviewer明示approved，R1已關閉。兩次getpass禁止明文fallback，first/second warning tests與Tester21tests/noTTY安全退出通過。可逐步交Human執行；helper SHA659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699固定，不在兩case間改判準。此刻missing/wrong皆0/1，啟動等待TTY不等於已授權；必須收到Human實際結果後記錄，不預填通過。

## P06 missing 已執行

2026-10-21，Human安全JSON：fresh/callback_claimed/single_exchange/omitted皆true，HTTP400、remote_rejected=true、token_present=false、unknown_error/unknown。按固定判準indeterminate，不當成PKCE通過。helper SHA未變。missing預算1/1已用盡，不重跑、不重用code；wrong預算0/1，下一步獨立新process。完整結果待P07 Tester／Reviewer複核。

## P06 wrong／Human執行結束

2026-10-21，Human安全JSON：fresh/callback_claimed/single_exchange/wrong_challenge_differs皆true、omitted=false，HTTP400、remote_rejected=true、token_present=false、unknown_error/unknown。按既定判準indeterminate；missing/wrong各1/1，總2/2預算用盡，停止新授權，不重用code、不增加第三次。Helper SHA659809be...1699未改，兩case之間沒有改程式或allowlist。原因無法從安全unknown分類追補，不索取raw body或機密；後續若需診斷另定契約/預算。本輪執行與紀錄可交付，不等於PKCE結論已通過，完整遠端refresh/401與全部Human review仍pending。

## P07 Tester 脫敏複核完成

In-Scope：兩safeJSON與既定分類/來源/預算/manifest最小核對；Out-Of-Scope：live/全測試/App秘密/Git/工具改動；ReadOnly：工具與正式source及docs；Written/Deleted：無；Modify：pkce-negative-verification.md與本step；Goal：交P07Reviewer可核對證據；Non-Goal：不代核准、不歸因unknown；TestCase：轉錄與safeJSON一致，最終SHA與P05一致，readonlydiff空/manifest內/pycache0。missing及wrong皆HTTP400 unknown_error/unknown、無token，均indeterminate；各1/1總2/2用完，不再授權或重試。詳見evidence；獨立Reviewer尚待明示結果。

## P07 外部最終 verdict／P08 開始

獨立Reviewer明示approved、無required fix：兩safe report依事前固定判準均indeterminate，未將HTTP400/remoteRejected當PKCE通過；來源/歸因/各1/1總2/2預算與未知原因限制一致，無機密，舊結果未改。只允許按既有授權提交紀錄與更新原DraftPR61；不再授權/重試/擴判準，不merge，停Humanreview。
