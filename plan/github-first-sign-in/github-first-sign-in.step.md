# 正式 OAuth 能力與獨立驗證 App：執行帳本

- Topic：`github-first-sign-in`。
- Phase／Current step：Human review（T08主提交交付完成）。
- Current status：human-check；T07approved，主提交已push/原DraftPR更新；共享R→T1/1用盡，wrong indeterminate。
- Upstream verdict：T07 approved，無required fix；T05code review及T04驗證已通過。
- Branch：`feat/github-first-sign-in`；base `dev`；[原 Draft PR #61](https://github.com/a129924/rivet/pull/61)。
- 回修基線：`e63eeb21b4774adafc5f8a822ac474df7e0bdc22`；沿用原 feature worktree，不在 dev／其他worktree實作，不建新PR／worktree、不merge。
- 最後更新：2026-10-21，Implementer；主提交/hooks/push/原PR讀回/localmap完成，收尾帳本隨後同步。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[plan](github-first-sign-in.plan.md)。

## U：現行 planning ledger（優先於上方 T08 標頭與以下歷史執行授權）

- 更新：2026-10-21，Plan-Creator；來源 `9f603f81d77040a2e06ad178062e8cfecc4de468`，同 feature／branch／Draft PR61。
- Current phase：Human boundary；Current step：U02 completed → Human；Current status：human-check。
- U formal planning verdict：approved，無 required fix；來源為獨立 Plan-Reviewer 明示外部 verdict，只核准四檔 planning。U02 completed 不等於 implementation approval；整體停 Human。
- Human 已接受原文可見性殘餘風險，僅准進入規劃；U02 後必停 Human。未來工具實作／Tester holdout／Reviewer核標／offline Human校準／任何live皆未授權。

| ID | Status | Owner role | 完成條件 | Evidence／verdict |
|---|---|---|---|---|
| U01 | completed | Plan-Creator | 僅四planning新增U節，完整候選技術契約／九欄／未來manifest／限制 | 本次四文件新增文字；不是品質核准，未跑測試／工具 |
| U02 | completed | Plan-Reviewer | 獨立formal planning回查Human-only gate/cleanup/helper/分類/校準/證據軸及零新預算 | 外部獨立 Plan-Reviewer 明示 approved、無 required fix；只 planning，下一步 Human boundary／human-check |

### U Blockers／Human Check

- Formal U02 已由外部獨立 Plan-Reviewer 明示 approved、無 required fix；U02 completed，整體停 Human／human-check。未來 9 Modify／3 Written 仍 NOT AUTHORIZED；不得實作／fixtures／校準／發布／OAuth，新預算 0，無自動 implementation／testing phase。
- AppKit copy/export/restoration、privacy gates、protocol與timeouts／cleanup皆尚未實作或synthetic驗證；holdout與Human離線校準尚未建立／執行，不能預填通過。後續技術能力不保證任意編碼／未知秘密偵測、OS留痕消失或immutable string物理zero。
- P/Q各2/2、R調查與T歷史／既有pkce_rejection_proven與outcome不回改；共享R→T1/1已耗盡，本輪新OAuth=0。e941d88正常App/API再次查詢與canvaspassed保留、不重做。
- Agent／Reviewer／CUA不能看live原文；無原文保存，未來新觀測僅local_human attestation，agent無法獨立稽核原句。若另授權live，推薦wrong但須另定case／次數，不保證一次判定。

### U01 完成九欄（本輪實際）

- In-Scope：四planning新增U節，方案為gate→清理→private helper→獨立語義觀測軸；交U02。
- Out-Of-Scope：任何實作／fixture／test／校準／工具／Git／commit/push/PR或新OAuth。
- ReadOnly：所有code/tests/source/API/experiments/frozen圖/歷史evidence/其餘docs與topics；原T/P/Q/R內容保留。
- Written：無。
- Deleted：無。
- Modify：本topic requirements.md、technical-spec.md、github-first-sign-in.plan.md、github-first-sign-in.step.md；完整paths見plan U當前九欄，僅新增U節。
- Goal：給formal Plan-Reviewer可審查的具體方法與Human停點。
- Non-Goal：不代approved、不把attestation當proof、不回推舊原文、不放行未來工具／live。
- TestCase：US01–US05為planned/not-authorized、全未執行；未建立任何synthetic fixture或helper。

### U 最新授權／狀態更正：啟動離線工具流程

本段是現行 state，優先於上方 U02→Human／未授權 offline 實作的舊停點，舊內容保留為歷史。依原同topic必要回修／實作授權、Human對「工具修改與離線測試」的續行要求及 U02已approved，移除主agent額外增加的offline再批准停點。技術／privacy／manifest／判準完全不變。

- Current phase：bounded offline implementation 準備；Current step：U03；Current status：pending（本記錄凍結供原 Plan-Reviewer 確認後交 Implementer）。
- Upstream technical verdict：U02 approved、無 required fix；不把本次授權記錄當作 source／tests 已完成。
- 現授權：既定 9 Modify／3 Written 內的 U03實作→U04獨立Tester→U05獨立Reviewer及synthetic Human calibration準備；plan各slice九欄必列。
- 停點：U06 Human offline calibration，不自動執行或代填結果。任何live仍須另次明確授權，新OAuth=0，R→T1/1耗盡不變。

| ID | Status | Owner role | 完成條件／證據 |
|---|---|---|---|
| U03 | completed | Implementer | 工具已完成凍結，限既定離線範圍 |
| U04 | completed | Tester | P2selectors/stderr回修後獨立親跑57tests、strict format／SwiftLint exit0；不代Human校準 |
| U05 | completed | Reviewer | 外部獨立最終verdict approved，P2closed／無其他required fix；限工具交付與Human正式offline校準 |
| U06 | pending | Human；Tester記錄 | human-check停點；Human明確參與後才可記9+7校準結果，目前未開始 |

本次實際只Modify四planning的U授權／狀態文字，Written／Deleted無，無Git／tests／工具／OAuth。兩份他人dirty Swift hosted tests不讀、不寫、不暫存、不還原。未來發布沿原topic授權，但本輪先交付可測工具；P/Q/R/T與正常App/API/canvaspassed均保留。

### U 最新執行狀態紀錄

- 外部來源：獨立 Plan-Reviewer 最新 offline confirmation 明示 approved、無 required fix；只離線，OAuth 0、U06 Human 停點不變。
- Current phase：工具交付 → U06 Human offline calibration；Current step：U06；Current status：human-pending，優先於此前 U03 in-progress／pending。U03／U04 completed，U05 外部 verdict approved。
- 外部實際結果：P2 selectors/stderr 回修後，獨立 Tester 親跑 57tests passed、strict format／SwiftLint exit0；獨立 Reviewer 最終 U05 approved、P2 closed／無其他 required fix。U06 正式 Human holdout 校準未開始，完整 UI／clipboard／restoration／timeout 實證仍 pending；不得預填9+7／遠端。原topic發布授權有效，交Implementer完成既定12file commit／push／原DraftPR61更新後停U06，不另造發布批准停點。

#### U03 Implementer 開始九欄（已收到的開始交接，非完成證據）

- In-Scope：parent gate／cleanup、helper protocol／AppKit、單一命令 offline 入口。
- Out-Of-Scope：OAuth／live、他人 App／tests、holdout labels、正式 proof／outcome 改動。
- ReadOnly：正式 source、傳輸／TTY／loopback、歷史 evidence／圖；他人 dirty hosted tests 不讀寫／暫存／還原。
- Written：planned helper 及新 pkce-semantic-review.md evidence，僅指開始交接的允許範圍，不宣稱已建立。
- Deleted：0。
- Modify：pkce_negative_probe.py、test_pkce_negative_probe.py、tools/README.md，精確相對路徑沿既定 manifest。
- Goal：可測 no-network 工具。
- Non-Goal：不預填 9+7／遠端，不保證任意秘密偵測或 OS／記憶體 zero。
- TestCase：US01–US03／US05 synthetic，US04 只接獨立 Tester 定義的 schema，不自行建立 expected labels；實際結果待補。

本次 Plan-Creator 僅四 planning 的 U 狀態事實登錄，不改工具／evidence／他人 App，不執行 Git／tests；已停止編輯。

單次 smoke 紀錄為 30.534s／stderr=false／confirmed＋indeterminate。Human 回報看到文字、當時不能複製並隨意選取，可解釋人工觸發；不據此判自然 timeout、技術性全面禁複製或 Human holdout passed。完整 UI／timeout 等與正式 9+7 校準仍 pending，沒有新增 OAuth。


### U06 最新正式校準結果與停止（優先於此前pending）

- Source commit：`f420901a1076537c4f7aa0404fe31509b8bdc889`；原feature／DraftPR61不變，工具／test／helper／fixture四SHA不變。
- Current phase：Human 方法決策；Current step：U06；Current status：completed-not-qualified；method disposition：needs-rework／human-check。
- 外部Tester已核凍結16唯一映射與fixtureSHA一致：decisive6/9、abstain2/7，未達9/9＋7/7，calibration_threshold_met=false。
- 外部獨立Reviewer結果處置approved，只准文件記錄與停止，不放行live或新方案。原U03/U04 completed、57controlledpassed與U05codeapproved維持，不推論OAuthbug／PKCEfailed。
- Human明示不懂英文，英文方法前提未滿足，不是使用者過失。先前smoke受手動操作中止，與本16case分開，不作自然timeout或holdoutpass。
- P/Q/R/T、正常App/API/canvaspassed、R→T1/1已耗盡與本次新OAuth0保留；禁止改fixture／重跑16／新UI／OAuth／code。新語言方案未授權，停Human。

本slice九欄：In-Scope＝安全結果／外部核分／語言前提／停止；Out-Of-Scope＝fixture/label改動、重跑、code/UI/OAuth/安裝下載/Git；ReadOnly＝工具/四SHA/fixture/歷史/其他檔及6他人Appdirty；Written＝0；Deleted＝0；Modify＝plan最新U06列明8tracked docs；Goal＝記錄not-qualified並停Human；Non-Goal＝不代核准、不責怪Human、不宣稱PKCEfailed；TestCase＝僅登錄獨立16unique/SHA與6/9、2/7，無新測試。

### 最新 Human 繁中決策與 V 前置停點

- Human已同意本機繁中方案與offline驗證／新增Apple on-device元件讀gate後description；原文／譯文只本機記憶體短暫視窗、agent不看不存，不雲端／不自下載，live未授權、OAuth0。
- 外部Tester一次唯讀environmentinventory：macOS26.5.2／SDK26.5／Xcode26.6，Swift6 compile/run exit0、stderrfalse；en→zh-Hant與en→zh-TW均supported非installed，僅證組合資產未齊，不能說各語言皆未裝。未session／translate／prepareTranslation／下載／UI／OAuth，scratch自清無新檔。
- Current phase：等待Human自行下載完成回報；Current status：human-check。Human已明示「願意，我自行下載後回報」，尚未回報完成；完成回報後才重查。既有inventory仍supported非installed，本輪未翻譯／下載／新查，尚無Vimplementationplan／中文工具／新holdout或方法成立證據。
- U06仍completed-not-qualified、6/9＋2/7及16obs保留，57controlled/U05codeapproval與App/canvas/PQRT歷史不改。此筆只Modify既定8docs、Written/Deleted0，不Git／test或新元件工作。

外部獨立Reviewer已明示本次actual8docs approved、無required fix，可依原授權交publisher docs commit／push／更新DraftPR61；本角色僅登錄，不執行Git。Docs交付九欄：In-Scope＝U06結果／inventory／最新Human下載意願；Out-Of-Scope＝Vcode/fixture/翻譯下載重查/OAuth；ReadOnly＝非manifest全部及他人Appdirty／frozen歷史；Written＝0；Deleted＝0；Modify＝既定8tracked docs；Goal＝凍結交publisher並停Human完成回報；Non-Goal＝不宣稱下載完成／installed／方法通過；TestCase＝僅登錄外部actualdocdiff approved，無新測試／查詢。


## T 輪現行ledger（優先於R停止及以下Q/P/A/S歷史）

來源90646c2，原feature/branch/PR61不變。T已授權私有診斷version3實作，不能因遠端結論可能unknown只停止。**共享R→T唯一預算現1/1用盡**；R當時未用，T沿用同1次，無新增額度。T06僅wrong新code單POST一次，無positive/API/refresh401/第二次。P/Q indeterminate、R調查、e941d88正常login及canvaspass保留。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker/verdict |
|---|---|---|---|---|---|
| T01 | completed | Plan-Creator | 四planning固定§11診斷/manifest/九欄/共享預算 | 本輪四planning | 未自審 |
| T02 | completed | Plan-Reviewer | 獨立planning明示verdict | 獨立Plan-Reviewer明示approved，無required fix | approved |
| T03a/T03b | completed | Implementer | bounded code/tests/docs及九欄 | 精確diff及36tests green，見v3 evidence | T02approved |
| T04 | completed | Tester | fake RD01–RD05/Readonly/既有回歸 | v3 evidence：36tests exit0、額外10bool與safeout/AST/hash/readonly全pass | 不live、不代T05核准 |
| T05 | completed | Reviewer | 獨立code/scope/evidence/requiredfixesclosed | 獨立Reviewer明示approved、無required fix | approved |
| T06 | completed | Human | freezeSHA後wrong一次，safeversion3JSON | 共享R→T1/1；local consistent、HTTP400 invalid_grant/無token、完整grammar none | indeterminate，停止新授權 |
| T07 | completed | Tester → Reviewer | safe結果/來源/判準/預算複核 | Tester核對一致，Reviewer明示approved、無required fix | 仍indeterminate，不回改PQR |
| T08 | human-check | Implementer → Human | topiccommit/push/原PR61更新/localmap→humanreview | 主提交403287a已push、原PR讀回OPEN/Draft、localmap完成；本筆收尾隨後同步 | 不merge、共享1/1用盡 |

### T Blockers/Human Check

T02已獨立approved、無required fix；T04親跑36tests及安全/readonly核對通過，T05已明示approved、無required fix。實作/Tester/Reviewer/requiredfixclosed及freezeSHA後才用共享唯一1次，不能T前偷偷live。prepared觀測不是遠端wire/grant/code發行時間證明；grammar是事前支持句法非GitHub保證，結果可unknown仍如實記。無機密/URL/body/description輸出或保存、live後不擴表。正式OAuth未確認bug；正常pass不重做、remote refresh401不做，完整PR Humanreview仍pending。

### T01 九欄完成交接

- In-Scope：四planning追加最小version3私有診斷/固定grammar/prepared觀測/共享預算。
- Out-Of-Scope：code/tests/live/Git、自審、改正式OAuth/傳輸安全策略。
- ReadOnly：README/design/SDD及現行planning、CLI必要私有觀測接點，舊evidence/正式source。
- Written：無新repository檔案。
- Deleted：無。
- Modify：analysis/github-first-sign-in/requirements.md；analysis/github-first-sign-in/technical-spec.md；plan/github-first-sign-in/github-first-sign-in.plan.md；plan/github-first-sign-in/github-first-sign-in.step.md。
- Goal：交獨立Plan-Reviewer可實作的T受限契約，不再只收斂停止。
- Non-Goal：不宣稱planningapproved/新診斷或PKCE遠端通過，不擴預算。
- TestCase：RD01–RD05未執行；T06wrong共享0/1尚未使用。

---

## R 輪現行ledger（優先於Q/P/A/S歷史）

來源HEAD21e2542；原feature/branch/PR61不變、不dev實作、不建新worktree/PR、不merge。本輪僅docs調查收斂，無工具更動/新live；R新額度 **0/1未使用**，未選case，不可當已執行或passed。P2/2 unknown與Q2/2 code_problem/unknown-description皆indeterminate歷史保留；正常e941d88與canvasHumanpassed不重做。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker/verdict |
|---|---|---|---|---|---|
| R01 | completed | Plan-Creator | 四planning最小追加fact/inference/noevidence/停止與精確manifest | 本輪四planning | 未自審 |
| R02 | completed | Plan-Reviewer | 獨立planning審查明示結果 | 獨立Plan-Reviewer明示approved，無required fix | approved |
| R03 | completed | Implementer | 允許docs/唯一new evidence，各九欄 | 調查matrix/來源/停止提示已完成 | R02approved |
| R04 | completed | Tester | 最小source/來源/hash/manifest/readonly驗證，可重跑11bool | investigation evidence：親跑11/11true；CLI/testbytes/manifest/readonly/links核對通過 | 不live、不重跑25/Swift、不代R05核准 |
| R05 | completed | Reviewer | 獨立docs/scope/evidence review與required fixes | Reviewer明示approved、無required fix | approved |
| R06 | human-check | Implementer → Human | commit/push/更新原DraftPR/localmap必要同步→humanreview | 主提交d8ad344已push、原PR61讀回OPEN/Draft、localmap驗證完成；本筆收尾隨後同步 | 停Humanreview，不merge，R0/1 |

### R Blockers／Human Check

R02已獨立approved，無required fix。未找到可靠的新遠端歸因資訊增益方案，本輪依Human限制停止CLI/live而交付文件，不把未使用預算視為blocker或自動執行授權。上游11bool是無網路受控事實，不是live證明；真client配置/服務端狀態/rawdescription語義仍noevidence。PKCE enforcement保持indeterminate，正式OAuth未確認bug。完整PR Humanreview及遠端refresh/401仍pending／本輪不做。

### R01 九欄完成交接

- In-Scope：四planning追加docs-only manifest、分層調查/停止、R0/1未用與獨立流程。
- Out-Of-Scope：code/tests/工具修改、live/選case/Git、讀取配置/rawdescription或重判P/Q。
- ReadOnly：README/design/SDDskills、四planning當前狀態與呼叫端source調查結果/官方依據。
- Written：無新repository檔案。
- Deleted：無。
- Modify：analysis/github-first-sign-in/requirements.md；analysis/github-first-sign-in/technical-spec.md；plan/github-first-sign-in/github-first-sign-in.plan.md；plan/github-first-sign-in/github-first-sign-in.step.md。
- Goal：交獨立Plan-Reviewer受限docs-only契約。
- Non-Goal：不自審、不宣稱工具/live/獨立驗證完成，不擴預算。
- TestCase：RI01–RI03本角色未執行；上游11bool只記來源，交Tester獨立核對。

---

## Q 輪現行 ledger（優先於以下P/A/S歷史）

本輪來源82489b68ff21e955611bde1e9028fff21dc68e74，原feature/branch/PR61不變。P兩case已2/2用完，unknown/indeterminate不能補原body或重判；Q新missing/wrong各fresh單POST一次、總2次。CanvasHumanpassed、e941d88正常login保留；本輪不重做positive/API/remote refresh/401。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker/verdict |
|---|---|---|---|---|---|
| Q01 | completed | Plan-Creator | 四planning精確manifest/固定描述matrix/九欄 | 本輪四planning | 未自審 |
| Q02 | completed | Plan-Reviewer | 獨立planning審查明示verdict | 獨立Plan-Reviewer明示approved、無required fix | approved |
| Q03a/Q03b | completed | Implementer | 分類/test/README及新evidence，slice九欄 | Q03及R1完成，25tests green | Q02approved |
| Q04 | completed | Tester | fakeQD01–QD05/舊回歸/readonly | 新evidence：25tests exit0，help/noTTY/AST/hash/19模板/readonly/manifest通過 | Q05唯一R1已獨立重驗/關閉 |
| Q05 | completed | Reviewer | 獨立code/scope/evidence/required fixes | Reviewer approved、唯一R1closed | approved |
| Q06 | completed | Human | 一次一步missing/wrong各fresh單次，總2次 | version2兩case HTTP400 invalid_grant/code_problem、無token、unknown description | 均indeterminate，2/2用盡 |
| Q07 | completed | Tester → Reviewer | 記錄/複核來源分類及限制 | Tester已核對兩safeJSON/§9/來源/預算/readonly/五docs與三planning摘要，見新evidence | Reviewer明示approved、無required fix，不重判舊P |
| Q08 | human-check | Implementer → Human | commit/push/update同PR/local真diffmap→humanreview | 主提交acdbcb8已push；原DraftPR61讀回OPEN/Draft，local真diffmap驗證完成；本筆收尾帳本隨後同步 | 停Humanreview，不merge |

### Q Blockers/Human Check

Q02已獨立approved，無required fix。Q05approved/R1closed後已完成兩case，均indeterminate，各1/1總2/2用盡。停止新授權；generic/unknown/conflict/原因不符不算pass；不追rawtext/機密、不擴表、不加第三次授權。正式能力不是已確認bug，remote refresh/401與完整PR humanreview仍未完成。

### Q01 九欄完成交接

- In-Scope：四planning追加診斷version2、預先固定模板/matrix、精確manifest與新兩次Human額度。
- Out-Of-Scope：實作/測試/live/Git；修改transport/TTY/loopback/生成及正式Swift能力。
- ReadOnly：既有四planning/CLI分類來源與呼叫端已查官方依據，舊P結果。
- Written：無新repository檔案。
- Deleted：無。
- Modify：analysis/github-first-sign-in/requirements.md；analysis/github-first-sign-in/technical-spec.md；plan/github-first-sign-in/github-first-sign-in.plan.md；plan/github-first-sign-in/github-first-sign-in.step.md。
- Goal：給獨立Plan-Reviewer最小可執行Q契約。
- Non-Goal：不自審、不宣稱新diagnostics或PKCE已通過；不重判P。
- TestCase：QD01–QD05未執行；Human新missing/wrong皆pending。

---

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
| P08 | completed | Implementer → Human | review後commit/push/更新原DraftPR61/local真diffmap→humanreview | 工具/證據799cc8cddeecb5fc2e297e7335d7711440c1cf2a已push，原PR61結果已更新；finalhead localmap隨交付提供 | 停Humanreview，不merge |

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

## P08 實際交付與停止點

- 工具/測試/脫敏證據commit `799cc8cddeecb5fc2e297e7335d7711440c1cf2a` 已push原 `feat/github-first-sign-in`；[原Draft PR61](https://github.com/a129924/rivet/pull/61)已更新canvas passed、missing/wrong indeterminate、remote refresh/401 pending。
- 全部pre-commit hooks通過。提交後default sandbox重查fixture時loopback綁定遭拒，屬環境限制；相同source以既有授權升權重跑21tests全pass。未因此改碼/改判準/重做遠端授權。
- 本筆收尾只更新帳本/evidence，正式source及helper SHA保持相同；最終head的local PRLens map另在外部scratch validate/render，結果隨PR及交付回報，不上傳。
- 總2/2新授權用完，停止新授權/重試；原body未保存，unknown不能追補。Canvas Human已passed，PKCE enforcement仍未獲證；remote refresh/401本輪未執行、pending。完整PR Human review仍待，不merge、不新建/移除worktree或PR。

## Q03a／Q03b 開始九欄

- In-Scope：§9分類/report version2、fixturetests/README與新診斷證據及指定長期docs。
- Out-Of-Scope：正式Swift、transport/TTY/loopback/隨機生成、live操作與舊P重判。
- ReadOnly：全部正式source、舊P證據、frozen圖與CLI授權/交換傳輸。
- Written：plan/github-first-sign-in/evidence/pkce-diagnostics-v2.md。
- Deleted：無。
- Modify：Q精確manifest的3tools、4planning與5長期docs。
- Goal：固定有限完整模板與case/conflict判準，安全區分拒絕與PKCE證明。
- Non-Goal：不把受控通過當遠端通過，不修改live後判準。
- TestCase：QD01–QD05，先受控red→green，再獨立Tester及Reviewer。

## Q03a／Q03b 完成九欄與交接

- In-Scope：version2有限分類/report、25fixtures、README與指定docs/新evidence。
- Out-Of-Scope：未live、未改正式Swift/傳輸/TTY/loopback/隨機生成或舊P結果。
- ReadOnly：舊P證據、全部正式source/tests/project/experiments/frozen圖。
- Written：evidence/pkce-diagnostics-v2.md。
- Deleted：無。
- Modify：Q manifest指定3tools、4planning、5長期docs。
- Goal：完成既定19模板/case/conflict與安全診斷，交獨立Tester。
- Non-Goal：不自審、不把受控green當GitHub遠端結論。
- TestCase：red25tests中5error/1failure；green25tests exit0，詳新evidence。Human各0/1，總0/2。

## Q04 獨立 Tester 完成九欄

In-Scope：QD01–QD05；Out-Of-Scope：live/秘密/Git/code修改；ReadOnly：工具/正式source/TTY/傳輸/loopback/生成/P歷史/圖；Written/Deleted：無；Modify：pkce-diagnostics-v2.md與本step自身事實；Goal：實跑及契約疑點交Q05；Non-Goal：不代核准/不預填遠端；TestCase：25tests pass、help0、noTTY各2版本2安全輸出/stderr空、AST/19模板精確比對/readonly/manifest pass、pycache0。CLI504b4a...6484與交接一致。

非string error_description實際被report為description_present=false/absent，與原欄存在語義不符，已回報主agent，交獨立Reviewer判定required fix；不會誤報PKCEpass，但不能隱藏。Human新0/2未使用。

## Q03a R1 原 slice 回修九欄

- In-Scope：Q05唯一required fix，非string description的presence metadata。
- Out-Of-Scope：passed判準/模板/transport/TTY/loopback/正式能力/live。
- ReadOnly：Q manifest readonly及舊P歷史，19模板與case判準。
- Written：無額外新檔。
- Deleted：無。
- Modify：CLI/test兩檔及step/新evidence自身證據。
- Goal：可解析欄位存在即present=true，不合格式仍unknown/json/indeterminate。
- Non-Goal：不把metadata改動當新判準或真人通過。
- TestCase：null/number/object/array presence與sentinel；red為presence false，待green/獨立重驗。

### Q04/Q05 R1 metadata 獨立重驗

Tester親跑完整25tests exit0，另null/number/object/array四fixture均presence=true/classunknown/json/indeterminate/provenfalse。最終CLI SHA0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51，tools指紋6e01680d63e2f0647ab33c38aaa71306d27270d0950e39ac52fb2c199178d073；舊hash與疑點保留歷史。readonlydiff空/ASTpass/既有readonlyfunction未變/pycache0。

只Modify新evidence與本step自身R1；In-Scope為定點重驗，Out-Of-Scope為live/Git/code修改，ReadOnly工具/正式source，Written/Deleted無；Goal交Q05，Non-Goal不代核准，TestCase如上。Q Human0/2未動，交獨立Reviewer關閉required fix。

## Q05 外部核准／Q06 開始

獨立Reviewer approved、唯一R1closed，可交Q06；Tester獨立25tests及null/number/object/array metadata/sentinel重驗通過。live前固定CLI SHA `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`、tools指紋 `6e01680d63e2f0647ab33c38aaa71306d27270d0950e39ac52fb2c199178d073`，基線82489b6+Qdirtydiff。19模板/case/conflict/passed規則不再改。Human新missing/wrong各0/1，總0/2；先missing，再另process wrong，逐步安全JSON收集；未live前不填結果。

## Q06 missing 已執行

Human安全version2 JSON：HTTP400 invalid_grant/code_problem、generic_code_rejection，remote_rejected=true、token_present=false；description存在、unknown、mentions_verifier=true但非證據，signals_conflict=false、pkce_rejection_proven=false。fresh/callback/singleexchange/omit皆true。依固定§9為indeterminate，不擴模板/不追原文。來源82489b6+Qdirtydiff及凍結CLI SHA未變，詳新evidence。missing1/1已用盡、wrong0/1，總1/2；下一步只允許獨立新process/code的wrong一次。

## Q06 wrong 完成／Q07 交接

Human安全version2 JSON：HTTP400 invalid_grant/code_problem/generic_code_rejection、remote_rejected=true、無token、description_present及mentions_verifier=true但class unknown；conflict=false/proven=false，fresh/callback/single_exchange/wrong_challenge_differs皆true、omitted=false。凍結CLI hash兩case之間未改；按事前§9為indeterminate。與missing一樣無法可靠專指PKCE，詳新evidence。Q兩case各1/1總2/2用盡，P舊2/2另保留，不追rawbody/不擴模板/不重用code/不第三次。正式能力非已確認bug，不重做正常login/API，remote refresh/401 pending。交Q07，不代外部核准。

## Q07 Tester 脫敏複核完成

In-Scope＝safeJSON/§9/來源預算/readonly/docs核對；Out-Of-Scope＝live/全測試/秘密/Git/code變更；ReadOnly＝工具/正式source/舊P/圖；Written/Deleted＝無；Modify＝新evidence與本step；Goal＝給獨立Reviewer來源一致結果；Non-Goal＝不代核准或推論PKCE成敗；TestCase＝兩報告逐欄一致、CLI0d1d912...1a51/tools6e01680...d073不變、readonlydiff空/pycache0、五docs與三planning最新摘要一致。

兩case均invalid_grant/code_problem、description unknown但提及verifier，依事前固定§9保持indeterminate，proven=false；各1/1總2/2用盡、停止授權/重試/重用。P舊2/2保留，refresh401與完整PRHumanreview仍pending。沒有重跑25tests或live，交Q07獨立Reviewer。

## Q07 外部最終 verdict／Q08 開始九欄

獨立Reviewer明示approved、無required fix，可Q08；兩案invalid_grant+unknown description只能indeterminate，hint不是PKCE證明。來源/歸因/限制/Q2/2及P歷史一致，不merge，停Humanreview。

- In-Scope：staged語意檢查、同topic commit/push、原DraftPR61描述與local真diffmap更新。
- Out-Of-Scope：live/重試/擴模板/merge/新worktree或PR。
- ReadOnly：凍結CLI、正式能力與全部Qreadonly/P歷史圖。
- Written：無額外repo檔案；localmap只在scratch。
- Deleted：無。
- Modify：Qmanifest指定docs/step/新evidence自身交付事實，原PR描述。
- Goal：可追溯交付並停Humanreview。
- Non-Goal：不把PR或工具交付當PKCEenforcement通過。
- TestCase：staged/diffcheck/必要hooks、map validate/render、remoteSHA/PRstate。

## Q08 實際交付與完成九欄

- In-Scope：同topic交付已完成，收尾帳本/evidence同步。
- Out-Of-Scope：未新增授權/retry/擴模板/merge/新worktree或PR。
- ReadOnly：正式能力/凍結CLI及舊P證據/全部圖。
- Written：無額外repository檔案；localmap在外部scratch。
- Deleted：無。
- Modify：本step及pkce-diagnostics-v2.md自身交付紀錄；原DraftPR描述已更新。
- Goal：主提交 `acdbcb80b857bf3caedd231e0e1cc3b65c07f4ec` 已push至原branch；原PR61讀回OPEN/isDraft=true/相同HEAD。
- Non-Goal：工具與PR交付不代表PKCEenforcement獲證；不merge，停止新授權。
- TestCase：staged單topic13檔/diffcheck通過；所有既有precommit hooks passed；localPRLens真base16606b8→acdbcb8 validate/render通過，4lanes/15nodes/21edges/4walkthrough，manifest已讀。Graphify仍無可用圖/sourcefallback、無build/upload，frozen圖未改。

本筆僅收尾文件，隨後commit/push並按最終HEAD重新同步localmap及原PR；不再跑未變source的已通過tests。Q兩case各1/1總2/2用盡，均indeterminate；P歷史原樣保留。完整遠端refresh/401繼續pending，正式Rivet產品登入UI未交付，完整PR Humanreview待完成。

## R03 文件 slice 開始九欄

- In-Scope：調查候選原因/事實/推論/缺口、新evidence與現行R停止提示。
- Out-Of-Scope：工具code/判準/測試code/正式能力/圖/live或重判歷史。
- ReadOnly：21e2542所有code/tests/正式契約、P/Q全部舊evidence與圖、非manifestdocs。
- Written：plan/github-first-sign-in/evidence/pkce-diagnostic-investigation.md。
- Deleted：無。
- Modify：七個manifest文件，四planning已由R01追加；本slice同步step、README、OAuth長期doc與toolsREADME。
- Goal：記錄有依據的調查及不浪費R唯一一次額度的停止決策。
- Non-Goal：不產生新遠端語義結論、不將未用預算當測試通過。
- TestCase：RI01–03，主agent11bool已通過，交獨立Tester確認來源/readonly/manifest。

## R03 文件 slice 完成九欄

- In-Scope：來源/候選原因分層/唯一new調查evidence與現行停止提示。
- Out-Of-Scope：未改工具code/tests/判準/正式能力/圖；無live、無重判舊結果。
- ReadOnly：所有code/tests/正式契約、P/Q所有舊evidence與圖、其餘docs/topics/worktrees。
- Written：evidence/pkce-diagnostic-investigation.md。
- Deleted：無。
- Modify：本step、README、docs/architecture/github-first-sign-in.md、tools/README.md；四planning R01屬同精確manifest。
- Goal：完成具證據邊界的docs-only調查；R0/1未用、不選case，交Tester。
- Non-Goal：沒有新遠端診斷資訊、不宣稱PKCEpassed/failed或未來方案不可能。
- TestCase：11bool上游exit0，RI01–03待獨立Tester核對來源/hash/manifest/readonly。

## R04 獨立 Tester 完成九欄

In-Scope：RI01–RI03來源/11bool/hash/manifest/readonly/links/分層；Out-Of-Scope：code/tests/live/選case/Git/秘密；ReadOnly：工具及正式source/舊evidence/圖；Written/Deleted：無；Modify：新investigation evidence與本step自身事實；Goal：交R05獨立有限驗證；Non-Goal：不代核准或證明遠端PKCE；TestCase：11/11true、CLI/testbytes不變、manifest與readonly核對通過、pycache0、相對targets存在。tools README更新後指紋efa508498f0c274b16e30f635228f118f1b8e8ed3fb88a55dffa0ab4bf1b7c94，不能沿用R前指紋。

R0/1未用、未選case；P/Q各2/2與indeterminate保留、正向e941/canvaspass沿用。無required驗證失敗，交R05；未重跑25/Swift或OAuth。詳見investigation evidence。

## R05 外部核准／R06 開始九欄

獨立Reviewer明示approved、無required fix：11bool/來源與synthetic邊界一致，未重判P/Q或宣稱PKCE，停止理由只限現有材料，R0/1未使用/未選case，正向與canvas保留。可提交文件/push/更新原DraftPR61，停Humanreview，不merge或新增授權。

- In-Scope：staged單topic語意檢查、文件commit/push、原PR及local真diffmap必要同步。
- Out-Of-Scope：live/code變更/改判準/新worktree或PR/merge。
- ReadOnly：全部code/tests/正式契約/舊evidence/frozen圖/其它topic。
- Written：無額外repo檔案；map只在scratch。
- Deleted：無。
- Modify：R精確manifest之step/新evidence自身交付事實、原PR描述。
- Goal：交付具來源的調查結果並停Humanreview。
- Non-Goal：不把docs交付當PKCE證明或R已執行。
- TestCase：staged/必要hooks/remoteSHA/原PR讀回及localmap validate/render；R0/1不動。

## R06 實際交付與完成九欄

- In-Scope：同topic調查文件交付與收尾紀錄。
- Out-Of-Scope：無工具/判準/live/新case/新worktree或PR/merge。
- ReadOnly：全部code/tests/正式能力/PQ舊證據/frozen圖。
- Written：無額外repo檔案；localmap在scratch。
- Deleted：無。
- Modify：本step與新investigation evidence自身交付事實，原PR描述已更新。
- Goal：`d8ad344d8eeb9586414620cd0ed9265ab0f9d25f` 已push原branch，原PR61讀回OPEN/isDraft=true/相同HEAD；R0/1未用。
- Non-Goal：docs/受控結果不構成遠端PKCE通過或失敗，正常App/canvaspassed不重做。
- TestCase：staged單topic8文件/diffcheck/all既有hooks passed；localPRLens真base16606b8→d8ad344 validate/render通過（4lanes/15nodes/21edges/4walkthrough），manifest已核對。Graphify受限sourcefallback，無build/upload；圖未改。

本筆只收尾兩文件，隨後commit/push及最終head map/原PR同步；不改工具或消耗R額度，不重跑已pass且未變的tests。P/Q各2/2及indeterminate歷史保留，R0/1未使用/未選case；完整遠端refresh/401與整體Humanreview仍pending，停Humanreview不merge。

## T03a／T03b 開始九欄

- In-Scope：version3被動prepared觀測、有限fullmatch grammar/hints、fixturetests及指定docs/新evidence。
- Out-Of-Scope：正式能力/API、交換算法/endpoint/timeout/retry、TTY/loopback安全策略、任何live。
- ReadOnly：所有正式source/tests、experiments/frozen圖/PQR舊evidence/其它topic。
- Written：evidence/pkce-diagnostics-v3.md。
- Deleted：無。
- Modify：T精確9Modify；先CLI/test，再README/docs/evidence自身結果。
- Goal：增加真實prepared input及安全語彙/關係資訊；通過必須觀測一致。
- Non-Goal：不保證遠端詞句命中，不把fixture當PKCE證明，不擴共享唯一額度。
- TestCase：RD01–RD05，先red→green，再獨立Tester/Reviewer；Human0/1。

## T03a／T03b 完成九欄

- In-Scope：version3 prepared觀測/有限grammar/hints/local gate、36fixtures、指定docs/新evidence。
- Out-Of-Scope：未改正式source/API/算法/endpoint/timeout/retry/TTY/loopback安全政策、未live。
- ReadOnly：正式source/tests/實驗/frozen圖/PQR歷史與其它topics。
- Written：evidence/pkce-diagnostics-v3.md。
- Deleted：無。
- Modify：9manifest文件；CLI/test/README、四planning及指定README/長期doc。
- Goal：完成可受控證明的安全資訊增益，交獨立Tester/Reviewer。
- Non-Goal：不自審/不保證遠端詞句命中/不以fixture冒充PKCE通過。
- TestCase：red34中5failure/7error→green34，補關鍵identity/cleanup後最終36tests exit0；Human共享0/1未用。

## T04 獨立 Tester 完成九欄

In-Scope：RD01–05/36tests/help/noTTY/AST/hash/schema/sentinel/scope；Out-Of-Scope：live/機密/Git/code修改/未變Swift；ReadOnly：工具與核心傳輸/TTY/loopback/交換/正式source/舊PQR圖證據；Written/Deleted：無；Modify：v3evidence與本step自身T04；Goal：獨立實跑交T05；Non-Goal：不代核准或當遠端PKCE證明；TestCase：36tests、實際URL四mutation/非有限clock三種/schema與output三項額外共10bool及safeCLI/sourcechecks全pass。

CLI a72072c752baf4594704ecede984553db295303ca70141ef30a7280aa0324ba0、test1e93c9ab39209ba858751a3e46db95ffaf3e5cf1471747f95d8c1753dd16d43e與交接一致；無required test failure。共享R→T0/1未用。T02舊pending/null佔位已回報主agent依外部明示approved修正；Tester不代判。詳見新v3 evidence，交T05。

## T05 外部核准／T06 起點

獨立Reviewer approved、無required fix，可交T06；T04獨立36tests/額外10bool及安全輸出/readonly通過。CLI SHA `a72072c752baf4594704ecede984553db295303ca70141ef30a7280aa0324ba0`、test SHA `1e93c9ab39209ba858751a3e46db95ffaf3e5cf1471747f95d8c1753dd16d43e`，tools指紋bd446be3a71b7af6e0b17bcd8cfaa03084d6906f68cda68e74dfeedd5626bd3b，來源90646c2+T受限dirtydiff。live前已核對凍結，不再修改grammar/判準。共享R→T唯一0/1尚未用，Human只wrong一次/newcode/單POST，只收安全version3JSON，完成即停；不重試或新增positive。

## T06 完成／T07 交接

Human安全version3 JSON已記錄：本機actualprepared shape/bindings/code/negative均一致，local consistent/valid_different/under_5s；HTTP400 invalid_grant、無token、完整描述unknown/none，verifier/challenge/mismatch hints true但非proof，依§11 indeterminate/provenfalse。CLI/test與T05凍結相同，未改grammar/判準。共享R→T唯一1/1用盡，停止任何新授權/重試/第二次，不重用code或索取rawbody。只做允許文件結果更新（README變動使tools指紋變，CLI/test保持），PQR歷史/正式能力/frozen圖不動，交獨立Tester/Reviewer，不代核准。

## T07 Tester 安全結果複核完成

In-Scope：safeJSON/§11/hash/預算/文件/readonly；Out-Of-Scope：live/36tests/秘密/Git/工具變更；ReadOnly：CLI/tests/正式source/舊PQR及圖；Written/Deleted：無；Modify：v3evidence與本step自身T07；Goal：交獨立Reviewer；Non-Goal：不代核准或從hint重建句子；TestCase：全欄轉錄一致、CLI/testhash凍結、readonly/manifest/pycache0/最新文件核對通過。結果為localconsistent但完整grammar none、一般invalidgrant，依§11維持indeterminate，不是PKCEproof。

共享R→T1/1已用盡（同R原額度），不得第二次或retry。README更新後tools指紋ae1dad2d8a1e9fb813fd8c23be88d4d57497a4b264328144f2f06bd51d1febbe，live前bd446開頭指紋保留歷史；CLI/test仍T05凍結版。無新requiredfix，交T07Reviewer，不改舊PQR結果。

## T07 外部核准／T08 開始九欄

獨立Reviewer明示approved、無required fix：safe report/凍結§11/文件一致，本機prepared gate通過但完整語義未命中，仍indeterminate；未以hint/falsehint/timebucket推定遠端原因。共享R→T1/1用盡，舊證據與readonly保留。可commit/push/更新原DraftPR61，停止任何新授權/重試，停Humanreview不merge。

- In-Scope：staged單topic檢查、commit/push、原PR及local真diffmap同步。
- Out-Of-Scope：新授權/重試/改grammar或判準/merge/新worktree或PR。
- ReadOnly：凍結CLI/test及正式能力/圖/PQR舊evidence。
- Written：無額外repo檔案；localmap只在scratch。
- Deleted：無。
- Modify：Tmanifest內step/新evidence自身交付事實、原PR描述。
- Goal：將已驗證的工具/安全結果交付並停Humanreview。
- Non-Goal：不把工具/本機gate交付當遠端PKCEpassed。
- TestCase：staged/diffcheck/既有hooks、remoteSHA/PR讀回、map validate/render。

## T08 實際交付與完成九欄

- In-Scope：同topic v3交付與收尾帳本。
- Out-Of-Scope：新授權/重試/修改凍結判準/merge/新worktree或PR。
- ReadOnly：凍結CLI/test/正式能力/所有舊evidence/frozen圖。
- Written：無額外repo檔案；localmap在scratch。
- Deleted：無。
- Modify：本step與v3 evidence交付事實；原DraftPR描述已更新。
- Goal：`403287a2c4d9abd081fb841ba56369a250c415a7` 已push原branch，原PR61讀回OPEN/isDraft=true/相同HEAD，工具bytes與真人來源一致。
- Non-Goal：本機gate及工具交付不代表遠端PKCE因果獲證；唯一額度1/1已用盡，不再執行。
- TestCase：staged精確10檔/diffcheck/all既有hooks passed；localPRLens真base16606b8→403287a validate/render通過（4lanes/15nodes/21edges/4steps）且manifest正確。Graphify受限sourcefallback，無build/upload；frozen圖未改。

本筆只收尾兩文件，隨後commit/push並同步最終HEAD localmap及原PR；不改工具或重跑未變且已通過tests。wrong indeterminate、localconsistent為本次實際新增資訊；共享R→T唯一1/1用盡，P/Q/R歷史保留，正常App/canvaspassed不重做。完整遠端refresh401及完整Humanreview仍pending，正式產品登入UI未交付，停Humanreview不merge。

## U04 最新獨立Tester完成紀錄（優先於先前U03 in-progress）

U03已收到明示完成交接；U04獨立離線驗證完成，Current phase=U05獨立Reviewer待審，U06 Human calibration仍pending、新OAuth0。

親跑54tests與真Swift6helper compile/strictprotocol noUI passed；初次helperformat/lint fail交Implementer定點修後，Tester再跑strictformat exit0、SwiftLint0violations及全54tests exit0。最終helper SHA91d570e9f4e9a4b617105b911f2f847b393c3f974275066c5660bebcd116e148；CLI/test/READMEhash同U03，初版helperhash與failure保留歷史，詳pkce-semantic-review.md。

獨立16fixture已由Reviewer核標freeze SHA d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5；mock實際校準分支禁止network/config/UI仍16unique打散，只有進度與finalopaquecorrelation，沒有答案/描述洩漏；Tester獨立allunknown sanity為0/9decisive＋7/7abstain，不能pass，不是Human成績。

九欄：In-Scope=US01–05適用offline/holdout/compile/protocol/checks；Out-Of-Scope=code改動/Human自動校準/GUIlive/OAuth/秘密/Git/外部App；ReadOnly=工具及正式source/他人dirtytests/舊evidence/圖/frozenlabels；Written=唯一semantic-review-cases.json；Deleted=0；Modify=新semantic evidence與本step；Goal=交U05獨立結果/限制；Non-Goal=不代核准/不預填9+7；TestCase=54/strict/protocol/mock準備passed，AppKitruntime與Humancalibrationpending。

其它人六個App dirty檔只列名排除、不讀內容/不碰；不全量App/Swift測試或掃format。不宣稱OS無留痕或physicalzero。Tester已停止寫入，交U05獨立Reviewer。

### U05 P2 獨立Tester定點重驗／synthetic smoke待釐清

P2 stderrfix親跑57tests exit0、helperstrictformat0/SwiftLint0violations，CLI9ebee1367ffd3f91d6311debe0457668ae96d1e24af77bf9ec24c61609d742e8／test74f641699b77fc0c0142ea1072884584406dee1a7f65bb76251a2dc27081f575／helper91d570...e148，holdoutfrozen不變、pycache0。

已協調的一次純synthetic密封窗smoke：30.534s、stderrfalse，卻輸出confirmed/revealtrue/userconfirmedtrue/categoryindeterminate；Tester無點選/按鍵/reveal/CUA/截圖，已退出清理。自然30s逾時未能驗證，原因待Human釐清及Reviewer唯讀查路徑；不推定bug、不重跑、不算Humanholdout/9+7或timeoutpassed。

只修改semantic新evidence與本step自身事實，無source/Git/秘密/OAuth。P2受控passed與runtimepending分列，待外部明示後再路由，不代核准。

#### Synthetic smoke Human外部確認（取代是否操作pending）

Human已明示手動操作：看到文字不能複製，便任選選項，足以解釋confirmed/revealtrue。故本次為受Human操作中止的synthetic smoke，不是自然timeoutpassed、不是16case holdout/9+7成績；完整UI/timeout仍未驗證。未重測/改code，僅補外部事實後凍結；不存原句、不要求複製。
