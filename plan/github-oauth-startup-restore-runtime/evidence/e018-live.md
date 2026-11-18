# E018：正式啟動還原 live 結果（2026-11-18）

## 結果
主session依獨立核准的exact controller命令執行first一次、fresh一次，兩段machine passed。Human各實答「全程觀察，0次」，各以獨立attestation綁原machine SHA；public projection promptObservation仍pending，machine promptCount未回填。兩個slots已使用完，停止額外launch／refresh／DPK操作。

| 段 | 實際結果 | Human |
| --- | --- | --- |
| first | 載入已到期credential；正式owner ready；prepare真refresh attempted1／accepted1、save1；API後完整readback一致；configuration保持；GET/user有效帳號；程序退出 | 全程、0次 |
| fresh | 相同binary的新process；初始完整credential tag等於first final；ready、同帳號、完整readback一致；refresh0、save0；程序退出 | 全程、0次 |

Prepare及API後final counts分列；本次API沒有額外401 recovery。整毫秒canonical HMAC覆蓋完整六欄，不宣稱原DPK JSON bytes相同。Fresh為不同實際PID／starttime；exact executable samefile、hello/authorize、exit證明及private source/build/signing鏈保存於同owner-only runroot，公開projection不含路徑／identity／token／secret／帳號原文。

## 固定來源與簽章
正式runtime來源e31a75a，本輪E018在建置時為未提交工具來源，以source manifest逐檔hash凍結；不冒稱工具由e31a75a編譯。
- Source aggregate：`e94cb1450324708de61e3b89f35475c9314f3b8970caf71445fa71c93d94448b`
- Signed binary：`8ff15af45b8cf45c5e975e4231fdc6ec1d7f20c00243630826703201db7f0823`
- Embedded profile：`6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`
現有有效profile至2026-11-23T06:19:04Z；各phase前均實際重驗。新host AppID不同於舊E014，profile的group pattern允許舊exactgroup；實際entitlement只給該exactgroup，certificate leaf與舊App一致。沒有新certificate、更新Apple cache、重簽／啟動舊App或讀舊實驗private controls。

## Goal / Non-Goal
Goal為正式既存連線真OAuth／DPK冷啟動還原；Non-Goal為初次授權、產品登入UI、profile延續性與普遍遠端權限保證。

## In-Scope / Out-Of-Scope
本輪只first／fresh與有限readback/API；未新登入、強制到期、clear／signOut／migration、重跑E014或其他已耗額度。真refresh由已存credential自然到期觸發，不改OS或provider clock。

## ReadOnly / Written / Modify / Deleted
Production Sources／root manifests維持零diff；Written為E018 host/project/resources/controller/tests與safe projections；Modify為本topic artifacts及必要長期狀態文件。Deleted無既有檔案；私有App／control／Keychain items保留，不cleanup或rollback已接受rotation。

## TestCase與審查
L01–L03：獨立Tester親跑16mock、unsignedbuild、fake self-test liveOperations0、host strictformat/lint及diffcheck均通過。準備時HTTP typed header、receipt schema／一致性、自然expiry與final-only401判準皆先出現可歸因red再修正；舊unsigned準備保留未sign／未live。
PlanReviewer E018追加計畫approved；獨立Reviewer工具／協定approved，最終pins與first命令bounded approved。L04／L05 runtime由主session依核准controller執行；不冒稱獨立Tester親跑live。獨立Tester已只讀核對兩段safe receipts／原machine SHA／Human綁定／repo copies、當前source及actual binary/profile hashes、不同actual process與退出證明，全數吻合；沒有重跑live或重新驗證簽章。獨立Reviewer已對本次有限live結果與文件明示approved，無required finding；不等同Human最終topic接受。

## 證據與限制
[e018-first.json](e018-first.json)、[first Human](e018-first-human.json)、[e018-fresh.json](e018-fresh.json)、[fresh Human](e018-fresh-human.json)。原machine／private provenance未改寫。
只支持當次同機／GUI user／原certificate／有效profile與唯一writer下的既存連線還原、自然到期真刷新及新程序完整讀回。不支持舊AppID profile renewal、自然長週期多次refresh、跨機／跨user／並行writer、斷電durability或所有環境。原E014/E015/E016/E017及PKCE歷史、額度與unknown不變。Human最終topic與圖接受仍pending。
