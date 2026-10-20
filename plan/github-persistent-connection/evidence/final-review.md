# GitHub 持續連線：獨立成果審查紀錄

## S06b Integration 審查（2026-10-20 UTC 07:50）

- 角色：獨立 Reviewer；不是 S05 Implementer 或 S06a Tester。
- Branch：`feat/github-persistent-connection`；只在指定 feature worktree 審查及寫入本收據與自身帳本狀態。
- Verdict：`approved`；requiredFixes：`[]`。只放行既定 S07 W04／W05；不是全 topic final approval、真儲存、真 GitHub 或產品驗收通過。
- 上游：S06a Tester 明示 approved；Human 唯一接受 profile 更新後讀回未驗證的限制，其他產品驗收維持。E007 兩輪仍無法判定且 phase 2 未執行，不重跑或改寫原收據。

### 審查範圍與方法

依 README、設計原則、架構 README／OAuth 雙 client 長期邊界、四份 formal artifacts 與 SDD 角色契約，逐行核對四個新增 source、三個新增 tests，以及 provider／provider tests／正常 import consumer／StaticIsolation 的 additive diff。查閱既有 bundle DTO、refresh construction、generic URLSession transport，確認沒有改寫其責任或 policy。這是 source／bounded diff 與外部驗證收據審查，不重跑已 green 的全 suite，不以作者自驗代替獨立 Tester。

核對 S06a [contracts](contracts.md) SHA-256 `924cf673f38a63b91399ddb337040ff906117c31620ec5907fbe81bd45b3dc8e` 與 [compatibility](compatibility.md) SHA-256 `9f7c72304d3d528b9f9c46b4ac9d0c215401d86aa1553eb5fe8d67220daa96d8`；兩份所列五個 production、六個 tests 的目前 SHA 全部相符。唯讀 `git diff --check` exit 0；branch 相符。沒有 source／tests／工具設定修改、真 Keychain credential operations、GitHub requests 或 Git mutation。

### 結果

| 項目 | 獨立審查結論 |
|---|---|
| Public configuration／factories | 非空 configuration、Sendable、description／debug／reflection 脫敏；refresh factory 重用既有 internal fetcher。新 public surfaces additive，concrete transports／Security 不公開。正常 import consumer 只 construction／cancel，不假稱連線成功 |
| 初次授權 V02 | state／verifier 各自 32-byte OS crypto RNG、base64url／S256、offline_access、URL 不含 secret。actor 在首個 await 前一次消耗；exact callback scheme／host／port／encoded path、userinfo／fragment／duplicate params／state／code-error 排他檢查先於 exchange；取消等待、拒絕、過期、consumed 分類明確 |
| Exchange V02 | 固定 HTTPS endpoint、五欄 form escaping、30 秒 ephemeral、無 cookie／cache、redirect delegate 拒絕 redirect、無應用 retry。只有可信 2xx 完整六欄／bearer／正數 integral lifetimes／有限 receipt 及到期日期可交付 bundle；scope 空字串合法、mixed／null error 及缺欄拒絕；錯誤不攜帶原始 payload／callback／underlying error |
| DPK V03 | 同一 backend actor 的同步 Security calls 不在 update／add／duplicate recovery 間 suspend；每個操作共用 exact DPK=true、non-sync、group／service／account selector。新增 AfterFirstUnlockThisDeviceOnly；整筆 update-first、missing 才 add、duplicate 僅一次 update；denied 不落入 add 或 missing |
| Codec／ID V03 | config 與 credential 各 schema 1；必要欄位完整 decode、非空 ID／tokens、bearer、有限 milliseconds；expired dates 允許。inspect 與 bound load 同 codec，corrupt 不撈部分 ID、mismatch 擋使用；不新增 bundle Codable，不聲稱兩 item transaction。產品 configuration-first／repair table 仍待 S07 協調 |
| Milliseconds oracle | 實際 Date→milliseconds 與完整六欄／Date roundtrip 共同驗證，沒有用放寬 production codec 迎合十進位硬常數；仍可偵測秒／毫秒尺度錯誤 |
| Provider V05／相容性 V08 | baseline diff 僅有限 disposition enum／從原 unavailableError 推導的純觀測；不動 snapshot、single-flight、refresh、persist、401 policy。既有 tests 只 additive。ports／scope／REST／GraphQL／Package／generic HTTP auth 無變更 |
| StaticIsolation | 四個 exact paths、factory／session HTTPClient、factory／store Security 精確例外符合外部批准 amendment；legacy 精確 import 集合、其他禁止規則及 parser 保留，沒有 session Security 例外 |

S06a 已獨立執行 integration **211 tests／22 suites**（明確 skip 真 KeychainTokenStoreTests）、正常 import consumer **13 tests／3 suites**、精確 11 Swift 檔 strict format／SwiftLint **0 violations**；此處接受其明示結果，沒有冒充 Reviewer 重跑。Consumer fresh build 既有未改 generic HTTP dependency 的 Sendable warning 仍列於 compatibility，不宣稱整個 build 零 warning，也不越界修它。

### 剩餘邊界與路由

本 slice 的 fake-only 契約與 source compatibility 足以進入既定 S07，未發現需作者回修的 correctness／ownership／workflow drift。S07 必須落實單一 tracked operation settlement、全部 reauth 退休舊 provider、configuration-first／可信 ID repair、GET /user 與 test-mode 零 live calls，再交 S08 獨立 Tester／Reviewer。

V04 產品 overlap、V05 產品 retry／reauth、V06 真 DPK／fresh process／真正重建／輪替後 fresh process／提示、V07 真授權／API／真遠端 refresh、V08 signed host／hosted tests 及 V09 圖與工具仍未通過。本收據不替後續 S08／S10 或 Human 填 approval；不解除其他驗收，不以 E007 或 fake green 冒充端到端完成。


## S08b Product 審查（2026-10-20）

- 角色：獨立 Reviewer；不是 W04／W05 或 RF-P01／RF-P02 作者，也不是 S08a Tester。
- Verdict：`approved`；requiredFixes：`[]`。只放行既定 S09 文件／圖／工具工作；不是 S10b 最終成果批准或 S11 Human 接受，不批准 merge。
- 範圍：W04 十個 App source／project／resource／test leaves、W05 兩個 Presentation leaves，RF-P01 既有三檔受控驗收修正、RF-P02 Debug 單欄修正，及 V04–V08 對應證據。未重開 E007、已接受的 DPK 決策或其他 ownership。

### 方法與來源核對

已讀 README／設計原則、架構 README／OAuth 雙 client 邊界、四份 formal artifacts 與既有 S06b；逐行核對本產品 slice 及 tests，並核對 S08a 獨立驗證結果。兩個先前 required fixes 的歷史與後續解除分列，未以先前 checkbox 代替明示 approval。

本次讀取的四份 S08a 累積收據 SHA-256：

| 檔案 | SHA-256 |
|---|---|
| `contracts.md` | `f1fa103f555817ebd45f866bf4d99c99c5a8ab642c70939cb0222112a993798b` |
| `compatibility.md` | `d6912e6e72e56b6559a7dc3356fa128da42741d37307a6b2896ef7cf7c2efc42` |
| `storage-live.md` | `817b91e7beb78777dc1a452247f14da28fdb7544bce7d10edfc3e9074b07e133` |
| `product-e2e.md` | `3be1dbe2bfa4c861cbb92b666be628bf9c5fbfe8f69c6eb5c3e58396f533c851` |

目前十二個產品 leaves 與受測 hashes 相符；三個 RF-P01 最終 hashes 取其後續重驗段，project 最終 hash 為 `ddf42ca3511f297456cb82c30b8c1a74413da785c103a4409ebc6fff058df62f`，移除唯一新增的 Debug `ONLY_ACTIVE_ARCH = YES` 可精確還原原受測 hash。歷史 table 的舊 hash 因該已記錄修正不同，不視為不明 source drift。Private project 的九個 source／scheme／resource／test copies 與目前 feature 完全相符；59 個 linked package source／manifest hashes 亦全相符。

唯讀核對 private manifest 指向的四份實際程序 receipt：SHA 全符、leaf 0600、parent 目前 user 所有且 0700，receipt PID 與各段 manifest 新 PID 相符且不同於前程序；source 的 UUID 只代表 observation，不拿它冒充 fresh-process。核對兩份實際 GUI activity logs 的 SHA、compile／link／codesign、Swift 6 與無 x86_64 override；真正 rebuild 有先 Clean 後舊 GUI product 不存在的當輪有限紀錄，binary bytes 確實不同。

另唯讀核對目前固定安裝 App 的 strict code signature、重建 binary hash、embedded profile hash／有效時間、macOS 15、debug dylib 不存在、non-Sandbox；Info／entitlements 的精確 private group 一致，profile 的 Apple group wildcard 正確授權該 group、App identifier 精確且不含 wildcard，目前 Mac provisioning UDID 在 profile 內，原 certificate fingerprint 在 profile 內。沒有啟動／退出 App、操作 Keychain credential、開 browser 或改 Apple assets。Sandbox 內 CMS 解碼未成功輸出 plist，改在同一受限 readonly host 檢查後成功，未用該環境失敗推論簽章不成立。

### Source correctness 與 ownership

| 契約 | 審查結論 |
|---|---|
| V04 settlement | MainActor admission gate 在第一個 await 前保存唯一 unstructured operation Task；caller cancellation 不釋放 handle。所有 connect／repair／reauth／prepare／probe 重試經同 gate，實際 task.value 結束後才清 handle。Latches 分別暫停 old refresh 與 old save，檢查取消後仍拒絕新設定／grant，沒有 sleep 推定 |
| V03／V05 repair、retry、retirement | 完整可信 credential ID 優先；損毀不撈 ID，無可信 ID 需明確原 App confirmation；configuration save 成功才開授權，denied／unavailable 保留資料只 explicit retry。全部 reauth／secret repair 在 settled 後退休原 provider／scope 並清帳號，取消／grant／save 失敗不復活；新 grant 保存成功才建新 provider。暫時 prepare 同 provider retry，stopped／authenticationRequired 不藉 retry 重建 |
| Authorization／relay | 僅 IPv4 loopback 系統 port，listener ready 後開 browser；GET origin-form／exact encoded path、8 KiB／5 秒 connection／5 分鐘等待，callback 交原 session 做 OAuth 驗證；結果或取消路徑都關 relay／session。Exchange 階段 UI 無取消入口，browser 只回靜態 return-to-app 文字，不宣稱該文字代表產品連線成功 |
| Probe／Presentation | account probe 經 scope.rest 的固定 GET /user／GitHub JSON Accept／Rivet User-Agent，只接受 200／正 ID／非空 login；非 401 不新增刷新或一般 retry。重新授權先清舊 account，Presentation 只 display-ready values／intents，SecureField secret 提交後清除，不含 OAuth／Security 或 PR BC 依賴 |
| Host safety | shared TestAction 明確 RIVET_UNIT_TEST_MODE=1；App entry 在 live construction／validation／restore tasks 前回 fake root，實際 hosted audit 三類 counts 零。正常 defaults 不啟動 validation；沒有把 unsigned hosted tests 說成 signed hosted tests |
| RF-P01 | 明確環境 opt-in，只對可信同 ID 初次 restore 將原 provider clock 暫放舊 access expiry，依 credential state 一次 arm，不依 now 呼叫次數推進；原 fetcher response receipt 仍真時鐘，OS clock／bundle dates 不改。原 store 成功保存 accepted 完整新 bundle 後才解除控制，保存失敗保留原停止契約；reauth retirement 結束控制。有限 receipt 僅 hashes／counts／booleans／mode，exclusive 0600，不輸出 token／secret／code／callback／raw response，正常 UI 不露驗收開關 |
| RF-P02 | project 共用 Debug 僅加 native active arch，符合最小修正，沒有 architecture／signing／runtime／package 變更。正常 GUI Build 及 Clean→Build 實際成功，不再靠 CLI override 假裝預設 GUI 可用 |

S08a 的獨立 fake-only root **226 tests／25 suites**、RF-P01 後 hosted **29 passed／0 failed／0 skipped**（新版全 suite，不能與先前 23 相加）、精確 Swift strict format／lint 及 plist／diff checks 結果可接受；本 Reviewer 沒有重跑已 green suite，另唯讀 `git diff --check` exit 0。既有 generic HTTP Sendable warning 與 unsigned XCTest support warnings 如實保留，不宣稱 build 全程零 warning。

### 真路徑與證據界線

- 首次正式設定→真 browser OAuth→完整 credential 保存→GET /user 有效帳號，由凍結 source 先後與當輪有限 UI 確認；Human 完整段 0 提示。Normal 初程序未啟用 validation，因此 initial digest 未測，沒有補造。
- 同 binary 完整退出／真新 PID 與同身分真正 GUI rebuild／真新 PID 均在同固定位置，observe 的 strict restore=provider load 六欄 digest 均為 `4c4da8d8ad3e49fdc706d2c5dca5732938045c278fbad77eee695984dd704f61`，forced=false、refresh／save=0、accountConfirmed=true；兩段 Human 各 0。Rebuild 新 binary `8693fbc21152cb7413cd4529934370beb3b9631b0f95ce5102bd4af5f61c14bf` 不同於舊 binary；profile bytes 相同，不能算 renewal。
- 受控 expiry 的真新程序：forced=true、原 production refresh attempt=1／accepted=1、原 DPK save=1、clock 回 real、accountConfirmed=true；accepted=persisted 六欄 digest 為 `893b2c89ad4b58f66f0a9b15d9bb3f27d6961436c31518e4040e9b92d409bc6d`，不同舊 bundle，aggregate tokenPairChanged=true。這是真 GitHub refresh／真 DPK 保存，由受控 provider clock 觸發，非自然等待八小時；沒有個別 token hashes，不主張兩者個別改變已各自測得。Human 完整段 0。
- 輪替後再完整退出／真新 PID，observe forced=false、refresh／save=0，strict restore=provider load=前 accepted/persisted 新 digest、accountConfirmed=true；Human 完整段 0，最後回覆接收 UTC08:58:02。四份私有原 receipts 的 SHA 與對應公開記錄全相符，沒有把 fake coordinator UUID 當真程序證據。

取消／拒絕／invalid callback／暫時失敗／accepted-save failure／terminal／overlap 以獨立 fake 契約證明，沒有宣稱真人破壞產品憑證測得。E007 兩輪 unknown、profile 更新後讀回未驗證、Personal Team 七日到期與過期不可用、過期恢復／certificate rotation／公開發行／Intel host 未驗證全部保留。

### 路由與剩餘工作

沒有未解 required fix，S08b `approved`、`requiredFixes=[]`；交既定 S09 文件／圖／工具工作，依其受限 manifest 執行。長期 docs 尚未回寫產品現況，V09 工具圖／視覺 QA、S10 最終核對與 S11 Human 整體接受仍待後續，不因本產品 slice 通過略過。保留目前可用 installed App／live credential 及審查 private evidence；本 Reviewer 未執行清理、Git mutation 或發布。


## S10b 最終技術審查：第一輪（2026-10-20）

- 角色：獨立 Reviewer，非 S09 作者或 S10a Tester；此為成果／scope／workflow 審查，未重跑已通過的 Swift 或真產品流程。
- Verdict：`needs-rework`；requiredFixes：`[RF-D02]`。只交原文件 Implementer 作下列文字修正，不重開 source、圖或已接受決策；S11 Human 圖表／整體接受保持未執行。

### 唯一 required fix：RF-D02

`docs/architecture/README.md` 的「尚未定義的項目」仍有兩段以現在式否定已交付功能：

1. 第 85 行整段末句仍列「Keychain OAuth credential adapter」及「產品登入」為延後。
2. 第 87 行長段末端的 deferred capability 清單仍列「Keychain credential adapter 與初次 OAuth 授權整合」。

這與同檔第 48 行 DPK／初次 authorization 已交付、末尾產品組合段、README 及正式產品 source／S08 真驗收結論矛盾，會讓長期架構讀者誤判本 Mission 尚未交付。請只修這兩段的現況清單：將本次已交付的 DPK 完整 credential adapter、初次 OAuth 與最小產品登入由 deferred 移出，可簡短連到既有正式產品段；保留完整 REST endpoint、各 BC adapters、一般 retry／rate limit 等真正延後能力與既有 non-BC／generic HTTP 邊界。不要修改歷史實驗段、source 或圖，不新增需求或 gate。

### 其餘審查結果保留

- 已讀四份 M03 文件與 W07 作者資料、BUILD／visual-review／tool-evidence，對照先前 S06b／S08b source review 與最新 S10a 明示 approved／requiredFixes=[]。S10a 原 RF-D01 的 source／幾何 finding 與獨立解除有完整歷史，沒有把工具零錯誤當成責任正確的替代。
- RF-D01 新 scene SHA `187bba542b1e1f2b17e960a74863b39b5e0a2633d4655bfb2d638f27ceff95d3`、canvas HTML SHA `61a8f9b558407ae9d1d04c63b56221325d2d666cd660fa110ef80cd4763e69ae` 與 pointer 相符；Reviewer 已親看 hash 驗證後的最新 Canvas 真截圖，Coordinator 左側經 gutter 進 stores 的完整保存邊正確，無 session→stores 或重複該邊。三張 Archify 的授權、restore／refresh／settlement／reauth、lifecycle 重要語意與 source 邊界相符。
- 直接核三組 native delivery／visual receipts：JSON／HTML SHA 全符、showcase 9/9／0 errors／0 warnings、四尺寸 containment 皆 pass、每圖四張 PNG 存在且 visualReview=pending 保留。32 個 W07 leaves 符合受限 manifest。另抽看最小 light 授權 sequence、最大 dark lifecycle 與最新 Canvas，未見裁切／新增遮擋；不冒稱 Reviewer 重看全部 12 PNG，採 S10a 已獨立逐張檢視及 scratch 重建結果。
- S10a contracts SHA `2edcea41264a41846e77ab2e6045671e394c752d932633272a727f9b3614f66d`、compatibility SHA `c71373dad80437fa89ecc21219ab4afe6da6f726ab65597f1fd1002e12dbaa1c` 的實際收據可讀；69 source hashes、四 live receipts／完整六欄 digest 鏈、五段 Human0、79 links 及 source 未改的獨立核對結果明載。沿用已批准的 signed GUI live／unsigned hosted29／root226／consumer13 分列，不重跑或相加舊23。
- E007 兩輪 unknown／phase2未執行與 Human 唯一例外、有效免費 profile／七日到期／過期不可用、同 Mac／GUI user／AppID／group／certificate／固定位置前提，以及 certificate rotation／公開分發／Intel 未驗證保持。受控 expiry 仍明示非自然八小時，但走真 GitHub／DPK；normal 初 digest 未測、aggregate tokenPairChanged 非個別 token hash 保持。
- PR Lens 尚無真 code commit，文件沒有捏造 map／base-head 或宣稱 validate/render；S12 真 code commit 後 bounded map→後 docs evidence commit→push／Draft PR 的已批准時序維持。Graphify 無既有 graph 的 source fallback、pinned versions、無 install／config／graph build／upload／發布不擴張。沒有新增工具 gate、代 S11 接受或批准 merge。

本輪只因 RF-D02 兩段現況矛盾需回修；其餘已完成審查保留。文字修正後可作獨立 bounded recheck，不需重跑圖／Swift／live 或新增 phase。Reviewer 只寫本收據與自身 S10b 狀態，未修受審文件、未執行 Git、啟動 App 或讀寫 credential。


## S10b RF-D02 bounded recheck 與最終技術 verdict（2026-10-20）

- Verdict：`approved`；requiredFixes：`[]`；RF-D02 已由本獨立 Reviewer 解除。只接受技術成果可交既定 S11 Human 圖表／整體接受，不代 Human 決策、發布或 merge。
- 直接回讀作者唯一受審文件 `docs/architecture/README.md`，SHA-256=`1511b192194679c95cd95df1b614c29833e9f8a95c5c4a39ed0bd16baeca8956`，與交接相符。第85行不再列已交付的 Keychain OAuth credential adapter／產品登入為延後；第87行不再將 credential adapter／初次 OAuth 整合列 deferred。與同檔已交付 DPK／初次授權、產品 composition 段及已批准 source／真驗收一致。
- 真正 deferred 的完整 REST endpoint、各 BC adapters、共通 headers／API version、rate limit、一般 retry、pagination／shared configuration 仍在；generic HTTP／non-BC／provider ownership、歷史實驗、有效 profile／Human renewal unknown 例外未因這兩段刪除而改變。相關 Markdown local links 皆存在，無 trailing whitespace／使用者本機絕對路徑。
- 本輪僅文字 bounded recheck；前輪其他 source／native receipts／RF-D01 Canvas／三 Archify／32 leaves／S10a 已獨立 source 與 live 證據、已記錄限制及工具時序審查結果保留。沒有 source／圖修改或重跑 Swift／真人／圖表測量，沒有新增 phase／gate／Tester loop，也未 Git、啟動 App 或讀 credential。

S10b 最終技術審查完成且無未解 required fix；S11 Human 視覺與整體接受保持 pending，S12 真 code commit 後 PR Lens bounded map／後 docs evidence commit／push／Draft PR 尚未執行。整個 topic 與發布未宣告完成。Reviewer 只追加本段與自身帳本結果，此刻停止寫入。
