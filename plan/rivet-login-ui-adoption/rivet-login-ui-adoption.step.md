# Login UI 元件化執行帳本

> 現行契約：本文件末段「R3：2026-11-18 E011 凍結與驗收歸屬修訂」優先適用於本輪。前文原規劃及 I01／I02 授權、實作與驗收保留為其版本歷史；不得以本輪要求倒推原作業越權，也不得把舊驗收直接套給新 host。

- Topic：`rivet-login-ui-adoption`
- Branch：`feat/rivet-login-ui-adoption`
- 原查核 Base：`1f31b35604adb5bb36326e52f9d6dbcff0cac763`
- 交付整合 Base：`origin/dev`／`ab77391b73291deb1ce3d96cef72f981aeb3104a`
- 最後更新：2026-11-18，Implementer完成I03受限實作／自驗交接；原Human接受與HC01／HC-FINAL completed保留，T06由獨立Tester記錄。
- Current Phase：R3受限source交付；I03／T06完成，R06復審approved，新host/Canvas/native差異尚未驗。
- Current Step：D03，in-progress，owner=Implementer；R06已明示復審approved／required fixes無，RF01／RF02 closed。並行T07 human-check待exact新binary當下確認；HC01 completed歷史保持，HC02 pending，不merge。
- 上游：Planner 規劃準備 approved；Human 已接受對話方案與本 topic 執行授權。這些不替代 P02 的獨立 planning verdict。
- 本帳本的 completed／pending 不是 approval；只依明示 verdict 路由。

## Steps

| ID | status | owner role | 完成條件 | 驗證證據／目前結果 | verdict |
| --- | --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 同slug四份artifacts落盤，保留Human鎖定scope／介面／VO對應／9標籤／工具／授權邊界 | requirements.md、technical-spec.md、rivet-login-ui-adoption.plan.md、本帳本；只落盤規劃，未改產品、未跑test/build | 無；作者不自審 |
| P02 | completed | Plan-Reviewer | 獨立審查四份artifacts的sufficiency、scope／contract／workflow，明示verdict | 獨立 Plan-Reviewer 對話 verdict=approved，required fixes=無；確認四 artifacts 與已接受契約一致（2026-11-17） | approved |
| I01 | completed | Implementer | P02明示approved後，依受限契約完成元件／content／intent／E011／測試／長期docs／adoption record／Archify v2，明示交接 | 元件／content／intent／E011／長期docs／adoption及lifecycle v2-r1完成；evidence/implementation.md記32tests／Demo build／scoped checks與root基線失敗，native互動及Human聲音分列待驗 | 作者不自審；交Tester |
| T01 | incomplete | Tester | 依I01交接獨立執行TC01–TC09可自動或原生驗證部分，回報命令／來源／結果／限制，Human VoiceOver另列 | evidence/testing.md：獨立32tests／7suites pass、Demo build／scoped checks／圖hash／showcase pass；root再現既有編譯失敗；CUA窗口不可讀，probe最後呼叫aborted，TC02／03／05 native未驗及TC06 pending | 無 correctness approval；交R01分類 |
| T02 | completed | Tester | 依使用者再次授權補驗既有native缺口，分開可觀察互動與Human聲音接受 | evidence/native-ui.md：N01–N16、48組呈現／AX、代表性截圖／捲動與焦點；正式source無改，VoiceOver聲音／宣告時序pending | 測試交接，不自審correctness |
| R02 | completed | Reviewer | 沿既有成果審查phase核對T02證據／採用分類，維持Human界線 | evidence/native-review.md：無required fix；正式source零diff，N01–N16／48組AX與代表性視覺界線清楚，LU-A02／04可列已採用限UI、LU-A03部分；VoiceOver及Human接受pending | approved（僅T02補證／既有Draft更新） |
| R01 | completed | Reviewer | 獨立檢查diff、範圍、行為、測試／圖與採用證據，分類required fix／重大問題及明示verdict | evidence/review.md：無 required fix；source／範圍／VO對應與圖面有界審查可Draft，root基線失敗與native TC02／03／05未驗須在PR揭露；不是最終UI接受 | approved（僅D01／D02 Draft） |
| D01 | completed | Implementer | R01允許前進且無重大問題後，依git-commit-convention查staged diff與message，執行僅本topic commit | 實作 commit `d762f935ec2d4e220e7bc2135e6b80daa21bef3e`；staged topic 邊界／diff-check 與全部 hooks 通過；後續同 topic docs-only 交付紀錄不改程式 | 已依既有Human授權執行 |
| D02 | completed | Implementer | D01後push本feature branch，建立target=dev之Draft PR，描述揭露Human／工具pending與限制 | feature branch 已push；[Draft PR #75](https://github.com/a129924/rivet/pull/75)，base=dev；Human checklist及native缺口已揭露，詳見evidence/delivery.md | Draft交付，未merge |
| T03 | completed | Tester | 整理Human實際VoiceOver回報與fixture來源，保留無效嘗試及最終接受界線 | evidence/voiceover-human.md：H01–H08，正常流程與兩組同主窗切態已確認；第二組截圖衝突只改外部host後補驗；無音檔／精確時序，正式source零改 | 證據交接，不自審correctness |
| R03 | completed | Reviewer | 獨立核對T03、採用分類及Human最終接受仍pending，明示verdict | evidence/voiceover-review.md：無required fix；正式來源與T02相同，H01–H08及無效嘗試界線清楚，LU-A03可列已採用限所列受測案例；TC06整體／Human最終接受仍pending | approved（僅T03補證／既有Draft更新） |
| I02 | completed | Implementer | 依 Human 要求提供使用 .standard 的乾淨單窗原生 preview，與原展示host分開；完成差異測試及可用wrapper | evidence/clean-preview-implementation.md：15tests／3suites、正式build及scopedchecks通過；獨立.app已準備未launch，正式核心13檔bytes相同，native差異交T04 | 作者不自審；交Tester |
| T04 | incomplete | Tester | 驗乾淨preview的單窗／正式copy／CLI／必要fake events，僅補差異並保留T02/T03 | evidence/clean-preview-testing.md：獨立15tests／3suites、product build、5files format／lint及diffcheck通過；核心13檔bytes同HEAD；CUA啟動被automatic review拒絕，native未驗／未留開 | 無correctness approval；交R04分類 |
| R04 | completed | Reviewer | 獨立審查I02／T04與正式核心零差異、預覽／展示隔離 | evidence/clean-preview-review.md：18份hash相符、13核心bytes同a7a2fad，無required fix；准source/docs topic交付，native因自動審查拒絕須Human當下確認，不稱新preview已接受 | approved（僅source/docs；native待確認） |
| T05 | completed | Tester | Human當下確認後只補乾淨preview必要native差異，保留T04拒絕及舊結果 | evidence/clean-preview-native.md：CP01–CP09，同SHA已啟動；七畫面變體與必要callbacks／Dark21捲動／Light17錯誤／完成，留開Light13 Welcome；無新source／聲音／Human接受 | 測試交接，不自審correctness |
| R05 | completed | Reviewer | 獨立核對T05實際證據、授權解除與最終接受界線 | evidence/clean-preview-native-review.md：無required fix；CP01–CP09與原生工具回報一致，七變體／代表性視覺有界，verifying-account／完整矩陣／聲音未重做；Human最終接受pending | approved（僅T05補證／Draft更新） |
| HC01 | completed | Human | Draft交付後Human明確確認本topic正式文案與視覺／UI接受 | evidence/human-acceptance.md：Human「接受目前這版正式 Login UI／UX」；對應3c9baf3／同SHA preview，T03聲音及TC06最終Human部分完成 | approved（Human明示UI接受；非merge） |

## Blockers

- 目前沒有已知的不可解除技術 blocker。
- T04啟動被拒及當時未驗保留；之後Human已明確確認SHA4d4cf13f719e…的exact app，T05直接CUA成功啟動並補驗必要差異，原action授權停點已解除。之後Human另行明示接受正式UI，詳見HC01紀錄；不是以啟動許可推定接受。
- P02 獨立 Plan-Reviewer 已明示 approved；I01 自驗交接完成，T01已取得有界結果但 native coverage incomplete；R01已approved僅Draft交付，不冒稱最終通過。
- 舊查核基線 root swift test 的 FakePATSecurity 缺 delete 編譯失敗保留於T01歷史。上游修正後整合至 `ab77391`，root親跑361 tests／46 suites通過，正式Demo build通過，R01補充延續approved；未修改本topic認證來源。
- 原T01 native窗口限制與未驗歷史保留。使用者重新授權後T02已補驗TC02／03及TC05所列48組呈現／AX、鍵盤與代表性視覺；T03再取得所列Human聲音／切態確認；TC06最終Human部分已由本次明示接受補足；原證據及限制不變，仍不放行merge。
- 若發現scope擴到真request／service／認證async／儲存／session、locked contract衝突、required fix／重大問題或權限不足，停止依賴動作並回報對應角色／Human。
- Graphify無可用graph可採source fallback；PR Lens不可用可採直接diff review。這些不自行新增mandatory gate。
- Archify未通過則圖面接受維持未完成；不得將pending／skipped／非零宣稱pass。

## Human Check 與既有授權

| ID | owner | 狀態 | 對交付的影響 |
| --- | --- | --- | --- |
| HC-SCOPE | Human | completed | 已選正式UI元件化，已鎖定本topic非真登入／非session，並接受完整方案 |
| HC-DELIVERY | Human | completed | 已授權無重大問題直接本topic commit→push→Draft PR→Human review；未授權merge／tag／release／發布 |
| HC-VOICEOVER | Human | completed | T03記錄本輪H01–H08實際聆聽確認；僅受測內容／焦點／切態，不代表所有時序或最終UI接受 |
| HC-FINAL | Human | completed | Human已明示接受目前正式Login UI／UX；見evidence/human-acceptance.md，既有受測限制不變，非真認證或merge授權 |

## 更新規則

各owner只依實際產出與證據更新所屬step；Reviewer／Plan-Reviewer保持獨立，不把status或checkbox當gate。遇needs-rework交回對應產出角色；blocked／human-check依既有契約停Human。Human聲音／最終接受pending必須在PR與交付回報明列，不得為追求completed抹去。

## 關聯 artifacts

- [requirements](../../analysis/rivet-login-ui-adoption/requirements.md)
- [technical-spec](../../analysis/rivet-login-ui-adoption/technical-spec.md)
- [plan](rivet-login-ui-adoption.plan.md)


## R3：2026-11-18 E011 凍結與驗收歸屬修訂

Human新要求：E011凍結、正式tests／controlled#Preview優先、必要native驗收改歸tools/acceptance/login-ui；原I01/I02授權與HC01接受保留。Planner preflight=approved只表示資料足夠起草R3，並非P03獨立planning gate。

| ID | status | owner role | 完成條件 | 驗證證據／目前結果 | verdict |
| --- | --- | --- | --- | --- | --- |
| PC03 | completed | Plan-Creator | 同topic四artifacts追加R3、保留歷史，列freeze六項／tool例外／controlledPreview／readonly／差異cases | 2026-11-18只改四規劃文件；沒有code/test/build/launch/commit | 作者不自審 |
| P03 | completed | Plan-Reviewer | 獨立審R3 freeze／scope／新增toolpackage例外／公共API保留／source與新binaryHuman邊界，明示verdict | 獨立Plan-Reviewer對話已明示P03 approved，required fixes無（2026-11-18）；非作者自審 | approved |
| I03 | completed | Implementer | P03approved後依R3六檔回復、controlledPreview／formaltests／最小tool與ownerdocs完成交接；新app僅build不launch | evidence/acceptance-ownership-implementation.md：六項freeze／controlledPreview／tool完成，正式9tests與tool8tests／build／scopedchecks通過，新app/source/hash已備未launch，core/rootreadonly保留 | 作者不自審；交T06 |
| T06 | completed | Tester | 獨立驗R3-TC01–05及07，記actualsource/hashes/cache/gaps；不launch新app | evidence/acceptance-ownership-testing.md：獨立16tests（9formal＋7frozen）／tool8tests／兩product build／format-lint／freeze-core-history／28source及app tree資源hash完成；Canvas與native未驗 | 自動／source完成；交R06 |
| R06 | completed | Reviewer | 獨立審I03/T06／freeze／corebytes／工具歸屬／source/docs及新app準備證據，無requiredfix才可提exactnative當下確認 | evidence/acceptance-ownership-review.md原needs-rework；RF01現況Reset文件及RF02先驗外部run已修，T06非法run無寫入與新版build複驗完成；目前source6c1d5266…／binary9219bd76…／app6be23f92…，詳I03差異附錄及Reviewer明示復審approved | 最新復審approved（source／tests／docs受限交付）；RF01／RF02 closed，required fixes無 |
| T07 | pending | Tester | R06後且Human對exact新binary當下確認後補R3-TC06必要native，記同窗callback/focus/resources及Human聲音待驗 | 目前修後binary9219bd7656c55287ecb6ab1adc6d37f7f9b51e9b9217c15846cb27d8e0460b10已build，source6c1d5266c7f10f2340ed383604fd8a74b3ff7f00a0411c276bd9df86a195921d／app6be23f92067767340b21cd00644943f7ffe72adbba3872de320ab94762c59eb3已由T06核對；未取得當下確認、未launch，無新native結果 | pending |
| R07 | pending | Reviewer | 獨立核對T07實際版本／界線／待驗，明示boundedreviewverdict | 尚未審查；不代替Human聲音或新host接受 | pending |
| HC02 | pending | Human | 依實際新host受影響cases確認VoiceOver／必要差異UI，不重開未變core的舊HC01 | 原HC01completed保持；新host接受／受影響Humancases未驗 | human-check未到達 |
| D03 | in-progress | Implementer | 無重大問題、依原授權完成本topiccommit/push/既有Draft更新，明列新native/Human限制，無merge | 原直接交付授權有效；R06復審approved後檢查單一topic staged diff，執行正常hooks／commit／push；既有Draft更新交主agent，T07／HC02 pending | source交付中；不merge |

### 本輪 Blockers／Human Check

- P03獨立Plan-Reviewer已approved（required fixes無）；I03作者實作／自驗交接完成，T06／R06與新host接受依獨立角色及Human實際結果，不代填pass。
- Root Package.swift/Package.resolved/gitignore/settings唯讀；若工具確需改動，提出精確最小proposal並停止該相依動作，其他獨立工作可繼續。
- E011凍結與formal.standard、無demo mode、HEAD重建舊demo語意不變四條件無法全滿足；採已明示安全範圍：E011只歷史引用、不作本輪正式驗收，無legacy/footer/bundle特判。不是未解除的實作假設。
- 新binary需要原生工具當下確認：先build/R06，再交exactapp/SHA/source/cases。原4d4cf13...啟動許可與HC01接受不套新binary；未獲新確認只暫停native，不阻擋source/tests/docs獨立工作。
- HC02只限本輪受影響HumanVoiceOver／host差異，不能重開或抹去HC01completed。Source/docs可依boundedreview與原授權更新Draft，不能稱新hostHuman接受或merge。
- 本輪I03已code/test/build，未launch新app或Canvas；T06依獨立證據記錄，T07／HC02仍待新binary當下確認及差異補驗，不回填舊結果作新pass。原T01/T04incomplete／拒絕及後續Human解除歷史完整保留。

### 六點最終交接欄位

1. E011 freeze revision/tree、六項逐blob差異與結果。
2. Formal／tool／history diff ownership及rootreadonly/corebytes。
3. 正式tests／controlledPreview實際涵蓋與限制。
4. Native必要性、最小host/menu/resources足跡與無service/DI依賴。
5. 實跑source/binary/hash/results/gaps、當下確認及舊Human接受適用版本。
6. 能力採用程度與產品認證/儲存/session整合分開；Draft狀態／無merge。
