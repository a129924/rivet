# 執行帳本

## Current phase
人類審查交付；N04／N05 completed、N06獨立有限結果approved，N07 commit／push／Draft PR交付completed；H01／M06 Human最終接受pending。最後更新：2026-11-18 Asia/Taipei。
兩段正常CLI機器結果皆passed／exit3待Human，各原生1案passed、不同actual程序且退出；fresh sameCredential／sameAccount通過。Human本輪first實答「0 次提示 全程觀看」、fresh新實答「全程觀看 / 0 次」，兩次正常attest皆exit0並各綁原machine SHA。兩段credential均未到期，refresh／save均0，本輪未涵蓋真refresh。First／fresh各1/1已用盡，停止額外phase／重試；舊失敗roots、machine／safe pending欄位與歷史保持。

## NR12 準備摘要（歷史）
NR12獨立完整Offline通過27 mocks、正向2案與預期原生負向2案；唯一preflight-insideout build／inside-out sign／逐code strict verify／host deep strict／測試列舉均通過。當時未bind／無journal／正式run-root不存在、first／fresh各使用0/1；該準備不是正式first結果。原N03／NR02 blocked及失敗roots不改。

## NR02 停止摘要（歷史）
N-R 修後驗證停止；NR01 completed、NR02 blocked，待 NR03 獨立 Reviewer 分類。原 N03 blocked 保留，N02r planning approved。最後更新：2026-11-18 Asia/Taipei。
NR02獨立完整Offline已通過21 mocks、正向2案與預期原生負向2案；唯一修後preflight build及nested bundle／host簽章完成，但host deep strict驗證在Contents/Frameworks/Testing.framework回報sealed resource missing or invalid而停止，未列舉。無補簽／策略擴張／preflight retry；唯一N context不變、未bind／無journal／正式run-root不存在，first／fresh各使用0/1。原L／M／N03失敗歷史及H01／M06保持。

## N03 停止摘要（歷史）
正式 hosted 有限 Live 準備停止；N01／N02 completed，N03 blocked。最後更新：2026-11-18 Asia/Taipei。
Human 已明確授權 N first／fresh 各最多一次及受限純 build-only preflight；N03 Offline通過、Live純build成功，但既有runner的test bundle簽章目標路徑不存在而停止，未完成sign／驗證／列舉。未bind／attempt／authorize／讀DPK fixture／呼GitHub；first／fresh各0/1已用，N04–N07 pending。原H01／M06及L／M歷史保持，不重試或暗修。

## M 交付摘要（歷史）
人類審查交付；M01–M05 completed，M06 pending。最後更新：2026-11-18 Asia/Taipei。
本輪 Human 已明示 Implement the plan；M02 獨立 Plan-Reviewer 已明示 approved、無 required finding；M03 已完成實作；獨立 Tester 已完成 M04 離線／mock 與回歸驗證；M05 獨立 Reviewer 已明示 approved、無 required finding。原 H01 pending、原 P／I／T／R／L 完成歷史保持；L first／fresh 各 1/1 已耗盡，沒有新增 live 授權。

## 原階段摘要（歷史）
人類審查交付。最後更新：2026-11-17 18:04 Asia/Taipei。
以下原輪次內容至 M 修訂節之前均保留為歷史記錄；其未執行 live／截止時間等敘述不是目前 M phase 的現況。

| ID | status | owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 四份 artifacts 對齊 Human 計畫 | requirements／technical-spec／plan／本帳本 |
| P02 | completed | Plan-Reviewer | 獨立 approved | 首輪 preparationFailed 回修後 approved；StaticIsolation 必要登記範圍補正亦 approved |
| I01 | completed | Implementer | bounded runtime、測試、文件與圖 | 新 actor/outcome、root/consumer tests；長期契約與圖 BUILD.md |
| T01 | completed | Tester | 測試及驗證實證 | 獨立親跑 root375／consumer22；format0；owned159Swift strictlint0；diffcheck0 |
| R01 | completed | Reviewer | 獨立成果 verdict | 獨立 Reviewer 整體 approved，無 required finding |
| H01 | pending | Human | Draft PR 最終 review | 待交付 |

## Goal / Non-Goal
正式既存連線還原；不宣稱遠端身分／權限與產品登入體驗。

## In-Scope / Out-Of-Scope
執行範圍依 requirements／plan；未做初次登入、清除、PAT、UI、跨程序或live。

## ReadOnly / Written / Modify / Deleted
既有production Sources與manifests zero diff。Written為新actor/outcome、root/consumer tests、四artifacts與必要文件圖；本機Floorplan ignored不commit。Modify四份既有導覽文件及StaticIsolation的兩路徑登記。Deleted無既有專案檔。

## TestCase
TC01–TC11：獨立Tester確認17個owner tests、3個consumer tests（另含參數case）及既有回歸涵蓋，無重要gap。TC12：Floorplan先4planned-files藍圖，後13files bounded原碼map，13/13描述、0unassigned、0routes；僅本機靜態交付。

## Evidence
Root375tests／46suites、consumer22tests／6suites、strictformat通過。原lint script掃入consumer .build第三方檔案失敗；改用相同roots的159個專案Swift明確清單strictlint，0violations，未改script／vendor。正式consumer hook清理fixture build後，原canonical lint重跑159檔亦0violations；renderer初次缺biome，已依frozen lockfile補本機依賴，無來源／lockfile變更。
責任canvas 0errors／warnings；lifecycle最終v3 9/9showcase、0errors／warnings，四桌面containment通過，agent實際看圖passed；Human接受pending。原始receipt的自動visualReview保持pending。
Graphify固定0.9.73，無graph依skill用source fallback；未建新圖或semantic。PR Lens於真實commit後生成本機diff圖，實際base/head於交接回報。

## Blockers
無已確認功能blocker。gh default auth無效；git傳輸與GitHub connector可用，push／Draft PR結果於交接回報。

## Human Check
Human已採納設計並直接授權topic commit／push／Draft PR；最終成果、圖視覺接受與Human review pending。18:20前收斂，不把未完成證據當passed。

## Verdict
Planning approved；Tester驗證完成；Reviewer整體 approved，無 required finding。以上不等同Human接受。

## L phase：2026-11-18
| ID | status | owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| L01 | completed | Plan-Creator | 固定新live範圍與有限判準 | E018 README與topic附錄 |
| L02 | completed | Plan-Reviewer | 獨立追加範圍review | E018追加計畫與API後oracle補正approved |
| L03 | completed | Implementer | 新host／controller／offline tests | 獨立Tester 16mock／unsignedbuild／fake selftest／strictformat與lint通過 |
| L04 | completed | Reviewer | 工具與exact操作review | 工具協定approved；最終source/binary/profile pins與first命令bounded approved |
| L05 | completed | Tester | first＋Human觀察、fresh＋Human觀察 | 主session依核准controller執行兩段passed；Human各全程0，獨立Tester只讀closeout核對全數吻合 |
| L06 | completed | Reviewer | 有限live結果review | 獨立Reviewer最終有限結果approved，無required finding；Human最終topic接受pending |
原Human最終成果接受pending不變；本次User已明確授權開始live。每段需Human在場觀察。

### L當前結果
2026-11-18 first/fresh各1/1已用完。主session依核准controller執行：first自然到期真refresh/save各1，fresh refresh/save各0；兩段ready／完整readback／API成功，same account，兩actual process已退出。同binary/profile/source，Human各全程0提示並綁receipt SHA。離線16mock／unsignedbuild／fake selftest／strictformat/lint均由獨立Tester親跑通過；live結果由獨立Reviewer approved，不冒稱Tester親跑live。停止額外live，不cleanup憑證。

## M：正式 hosted integration 測試設施修訂

### M steps

| ID | status | owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| M01 | completed | Plan-Creator | 原四 artifacts 原位追加目前修訂、保留原歷史與 evidence | requirements／technical-spec／plan／本帳本的 M 節；僅計畫文件完成，未宣稱獨立 approved |
| M02 | completed | Plan-Reviewer | 獨立審查四 artifacts 範圍、target／CLI、結果與歷史不可變性 | 獨立 Plan-Reviewer：approved，四 artifacts 與最終手動 Live 版一致，無 required finding |
| M03 | completed | Implementer | 正式兩 targets、Offline／手動 Live runner、必要能力遷移與 active E018 退役 | 兩 targets／schemes、正式 runner 與17 mock tests；完整 Offline first／fresh 及兩隔離原生負向 passed；strict format／lint0；active E018九 tracked files退役；不得將自驗當獨立 Tester通過 |
| M04 | completed | Tester | Offline、mock 協定／失敗案例、回歸及歷史完整性實證 | 獨立親跑17 mocks、正向2案、預期原生負向2案、純mock timeout／missing receipt；root375／46與consumer22／6、strictformat／lint／diffcheck0；5份歷史evidence SHA一致；未執行 Live |
| M05 | completed | Reviewer | 獨立確認結果語義、秘密不輸出、一般流程不觸 Live 及證據限制 | 獨立 Reviewer：approved，無 required finding；受審 source SHA 與 M04 相同，核准限離線／mock 實證，不含新增 Live 或產品 E2E |
| M06 | pending | Human | 原 PR 最終接受 | 待成果交付；不代表新增 Live 授權，原 H01 pending 保持 |

### M Goal / Non-Goal / In-Scope / Out-Of-Scope

Goal 為正式 hosted integration 測試設施及 active E018 退役。In-Scope 是兩 targets、Offline／Live configurations 與 shared schemes、測試組裝／斷言、runner 與必要文件；Non-Goal／Out-Of-Scope 是改正式 runtime／public API／manifests、產品 App／UI E2E、新登入／seed／clear／強制到期與本輪新增 live。詳見 requirements／plan 的 M 節。

### M ReadOnly / Written / Modify / Deleted

ReadOnly：原正式 Sources、manifests、受控／consumer 測試與原證據。Written：正式 hosted 設施及 runner／driver tests。Modify：四 artifacts 及 plan 明列之導覽／長期測試文件。Deleted：必要能力遷出後刪 active E018 九 tracked files，不刪私有 App／Keychain／歷史。M03 已新增正式 hosted project／測試／runner、更新必要導覽並退役 active E018；原 evidence 不變。

### M TestCase / Evidence

TC-H01–TC-H07 已完成 M04 離線／mock 獨立實證。Implementer 自驗（保留）：`python3 -B scripts/check-github-integration-hosted-tests.py --offline` 通過17 mocks，正向first／fresh各1案、不同實際host程序且退出，assert／throw隔離負向各1案原生failed被正確辨識；strict format／SwiftLint exit0。初輪runner缺檔red後mocksgreen；原生執行曾因Xcode單次repetition旗標被拒，修正為無重複／retry旗標與案例數核對後通過。未執行 Live build／簽章／DPK／OAuth；原L結果不轉記新設施。

### M04 獨立 Tester 證據（2026-11-18）

- 親跑 `python3 -B scripts/check-github-integration-hosted-tests.py --offline` exit0；17 driver mocks 通過。正向 first／fresh 各1個 Swift Testing 案例 passed；actual PID 40024／40042、starttime不同、兩程序均退出。First fake refresh／save各1，fresh各0；完整安全tag一致、liveOperations=0。
- 同一 Offline 入口另跑 assertion／throw 兩隔離原生負向，各1案由 `.xcresult` 記為 Failed、零skip、程序退出；runner 正確辨識預期失敗。另以純mock測 `execute_phase` timeout 回 Failure(exit1)、missing machine receipt被拒；未啟動真子程序或Live命令。
- 親跑 root `swift test`：375 tests／46 suites、exit0；`bash scripts/check-github-integration-consumer.sh`：22 tests／6 suites、exit0。新增3個Swift檔 strict format與strict SwiftLint各exit0；`git diff --check` exit0。
- 對 `0debe0b`，正式Sources／manifests／既有root與consumer tests零diff；5份歷史evidence逐檔SHA吻合；E018九trackedfiles全部不存在，新設施程式與project無E018／E014執行依賴。
- 獨立來源SHA：`aeccff8efb1a07288efe082238ce2a4f69c4c0116d85f39d89a6abf5aaf0017f`；獨立重建artifact SHA：`05d132d8427c952f42f3613a03035ab2714b1a5141b9ee1909ea972ca7bc5fc0`。First／fresh共用全部BuildProducts、testbundle、固定xctestrun／control／selected-tests及來源pins，執行後仍吻合；不要求不同build間artifact bytes相同。
- 證據保存在TMPDIR之 `rivet-hosted-offline-5h718pix/`；root／consumer完整logs分別在 `rivet-hosted-tester-root-qvt17831/`、`rivet-hosted-tester-consumer-bhjpc9_n/`。僅離線與mock，不執行Live build／簽章／DPK／OAuth，不代表新設施Live或產品E2E已通過。

### M Blockers

M02 planning approved；M03／M04 完成；M05 獨立成果審查 approved，無 required finding。不把未取得的實證當作通過。若跨出 plan M 明列邊界，停止並回報 Scope Gap。

### M Human Check

Human 已批准 Implement the plan，僅在 feature worktree 執行受限修訂；一般測試／CI 離線。未來 Live 具體值與新預算須明確授權，本輪不簽發／執行 context；新的 run-root 不重設舊額度。原成果及圖視覺最終接受仍 pending。

### M Verdict

M01 completed；M02 獨立 planning review approved；M03／M04 completed；M05 獨立 Reviewer approved，無 required finding；M06 pending。審查僅涵蓋本輪離線／mock、正式測試設施與退役界線，不等同 Human 接受、新設施 Live 通過或新增 Live 授權。

### 交付同步：外部 dev 文件更新

交付時遠端 dev 由 `d2332bf` 推進至 `0a71be9`，內容為 PR #68 的 E010 結案與 Git 收尾文件。Feature 以正常 merge 整合，僅處理 `experiments/README.md` 檔尾追加衝突，保留 dev E010 收尾與本 topic E018 歷史／正式測試指向；`experiments/VALIDATION-SUMMARY.md` 保持遠端原樣。程式來源與原測試證據不變，未重跑 full tests 或 Live；獨立 bounded Reviewer 已明示 approved、無 required finding：兩方 README 內容完整保留、summary 與遠端 bytes 一致，無 conflict markers，程式／測試／歷史 evidence 零差異。此核准僅涵蓋文件同步，不擴大原 M05 的實證範圍。未改 dev worktree／分支，M06／H01 pending。

## N：正式 hosted 有限 Live 驗收

### N steps

| ID | status | owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| N01 | completed | Plan-Creator | 四 artifacts 追加新 Human 有限授權、preflight 例外及停止條件，保留既有歷史 | requirements／technical-spec／plan／本帳本 N 節；僅文件完成，不代表獨立 approved |
| N02 | completed | Plan-Reviewer | 獨立審查 N 範圍、純 build-only 例外、phase／Human 與 evidence 契約 | 獨立 Plan-Reviewer approved，無 required finding；僅planning核准 |
| N03 | blocked | Tester | Canonical Offline、資產／source／writer 核對及獨立純 build-only Live build／sign／驗證／測試列舉 | Offline通過；Live純build成功，sign-test因runner預期外置xctest但實際nested於host而No such file or directory，停止；無bind／attempt／authorize／fixture／API |
| N04 | completed | Tester | 本輪 Human ready 後 first 一次；機器結果及 actual process 退出；取得實際 Human 觀察並 SHA attest | 正常first機器passed／native1案passed／actual process退出；Human本輪「0 次提示 全程觀看」，正常attest exit0綁原machine SHA、first_ready=true；prepare／final refresh save0 |
| N05 | completed | Tester | first machine passed／退出／Human 全程且 0 提示後，fresh 一次、新程序 continuity，再重新詢問並 attest | 唯一fresh機器passed／native1案passed／新程序退出、samecredential／account皆true；Human新實答「全程觀看 / 0 次」，正常attest exit0綁原fresh machine SHA；兩slots1/1用盡 |
| N06 | completed | Reviewer | 獨立新結果／coverage／safe evidence／provenance／Human SHA／歷史不變審查 | 獨立Reviewer approved、無required finding；4份safe bytes／Human SHA、原生各1pass／0skip、退出／continuity、source／artifact／profile／context pins及coverage／歷史不變均吻合，僅本次有限結果 |
| N07 | completed | Implementer | 依 N06 結果完成安全 evidence／必要長期結論、topic commit／push、更新既有 Draft PR #77 並交 Human review | 安全4檔exact-bytes與hosted-live.md已由N06有限結果審查approved；f68c386正常topic commit及9fee6781正常baseline merge已push，既有PR #77讀回Open Draft、head／base吻合及mergeable；H01／M06仍pending |

### N Goal / Non-Goal / In-Scope / Out-Of-Scope

Goal 為正式 hosted restore／API／完整 readback／跨程序 continuity 的有限 Live。In-Scope 為先 Offline 與環境、純 build-only preflight、first／fresh 各最多一次及每段 Human 實答／SHA；Non-Goal／Out-Of-Scope 是改 source／contracts／tools、login／seed／clear／forced expiry、新 Apple 資產、UI／產品 E2E 或任何 automatic phase retry。

### N ReadOnly / Written / Modify / Deleted

ReadOnly 為所有 source／tests／scripts／project／manifests、Apple 舊資產、舊 evidence／pins／Human 與私有 controls／keys／assets／logs。Written 限新 owner-only context／key／journal／build／machine／Human 及 plan 明列的新 safe receipts；Modify 為四 artifacts 與審查後必需驗收結論文件；Deleted 無，不 cleanup fixture。N01建立文件時只改四 artifacts；目前N04／N05已取得正式run與Human證據，N07僅整理明示safe allowlist及必要文件，不動raw controls／machine／placeholder。

### N TestCase / Evidence

TC-N01的Offline及資格檢查、原兩輪工具缺陷回歸／NR12新preflight分開保留；原N03／NR02 blocked不改成通過。N04／N05各執行正常CLI一次，native各1案passed、0skip，ready／API／完整readback／configuration保持，fresh同完整credential及帳號、不同actual程序且退出；兩段Human本輪重新實答全程、0提示，分別綁原machine SHA。TC-N03–TC-N06已有上游實際證據，N06獨立有限結果審查已明示approved；TC-N07已完成N07發布與Draft PR讀回，Human最終接受仍pending。
兩段credential有效未到期，prepare及final的refresh／save全0，沒有本輪真refresh或rotation-save coverage。兩slots各1/1已用盡，停止再run／preflight／sign／DPK／API；有效credential結果不沿用舊E018自然到期refresh覆蓋。4份safe／Human exact-bytes及[本輪有限結果](evidence/hosted-live.md)分列source／artifact／machine SHA；公開無rawtoken／secret／clientID／account／identity／profilePath／控制key／私有路徑，原machine／既有safe pending欄位不回填。原L／M／old5evidence／所有舊pins保持。

### N03 獨立 Tester 準備證據（2026-11-18）

- Canonical Offline親跑exit0：17 mocks、first／fresh正向各1案、assert／throw預期原生負向各1案；不同actual PID／starttime、程序退出、固定provenance、liveOperations=0。證據於TMPDIR的 `rivet-hosted-offline-m3m18whr/`；artifact SHA `1a2ac540b7cac01f75219e849186d05b804c4b5ebdefb25b2f3e2aa3c33be8f2`。
- Source SHA仍為 `aeccff8efb1a07288efe082238ce2a4f69c4c0116d85f39d89a6abf5aaf0017f`。重驗唯一匹配profile SHA `6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`、有效至2026-11-23T06:19:04Z；matching available identity1、device允許、related writers0。Exact fixture group／service按repo公式及current profile prefix核對，未讀installed舊App或舊private資料。
- 新owner-only N context與獨立preflight root位於TMPDIR `rivet-hosted-live-n-20261118-m2mhtqhu/`；context只記新授權／既存環境，不含token或client secret。只呼現有 `root_control(...,'live',ctx)`、`build(...,'live',ctx)`；沒有bind_context、main --live、execute_phase或authorize。
- 純Live build-for-testing成功；`sign_products`嘗試的 `Build/Products/Live/GitHubIntegrationHostedTests.xctest` 不存在，實際產物為 `Build/Products/Live/GitHubIntegrationTestHost.app/Contents/PlugIns/GitHubIntegrationHostedTests.xctest`。本次新sign-test.log僅為No such file or directory；sign-host與enumeration未執行。依N停止，未暗修／手動補簽／重試；不宣稱host／testbundle signature或hosted runtime資格已通過。
- Preflight無hello／attempt／authorize／machine／Human等phase證據；context journal與正式run-root均不存在。未讀fixture、未呼OAuth／GitHub，first／fresh剩餘額度各1；準備中的OS提示次數未觀察、不填0。即使後續解除阻擋，first前仍需本輪Human ready，不能把preflight作first結果。
- 對df801f6，source／tests／scripts／project／manifests無修改；5份原evidence逐檔SHA保持。僅此帳本新增N03實際證據；新private `n03-safe.json`記錄失敗分類，不含raw身份／路徑／fixture。

### N Blockers / Stop

原N03／NR02 blocked歷史保持；兩個明示受限修正與NR12／NR13準備審查後，N04／N05已完成有限機器與Human結果。N06獨立有限結果審查approved、無required finding；N07已交付，現待Human最終接受；兩phase額度各1/1已用盡，不再執行phase／preflight／簽章／DPK／API。缺任何必要資格、工具問題、runtime 失敗、timeout、非唯一 writer 或 Human gate 不滿足即停止，不能自動 retry 或暗修。正式 --live first 會先消耗 attempt，嚴禁用它作 preflight；unexpected hello 不 authorize。New root 不重設已耗 phase。

### N Human Check

Human 已授權 `human-2026-11-18-hosted-live-first-fresh` 的新 N 有限範圍；主 session 必須先在 N03 準備完成後通知，待本輪明確可全程觀察回覆才 first。每段退出後重新詢問全程觀察／actual prompt count，不預設 0。只有 first machine passed＋退出＋Human 全程且 0 提示才 fresh；最終 topic 接受仍 pending。

### N Verdict

N01／N02 completed；原N03 blocked保留；NR13準備審查approved；N04／N05 completed；N06獨立有限結果approved、無required finding；N07 completed。核准只涵蓋本次已完成情境，不代替Human最終接受；舊M05／L不代替本輪結果。

## N-R：nested test bundle 簽章路徑受限修正

### N-R steps

| ID | status | owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| N01r | completed | Plan-Creator | 四 artifacts 明示兩檔 bounded fix 與修後驗證／來源／Human 邊界 | 本 N-R 節及 requirements／technical-spec／plan 對應節；僅文件完成 |
| N02r | completed | Plan-Reviewer | 獨立審查 ReadOnly 例外、nested target／順序、TDD、同一 context／原失敗 immutable | 獨立 Plan-Reviewer 明示 approved，無 required finding；核准僅涵蓋 N-R 受限契約 |
| NR01 | completed | Implementer | 只修 sign_products 與 test_driver.py 純 mock／temp fixture TDD 回歸 | 純 mock／temp fixture red：21 tests，新增3 failures＋1 error；最小 nested path／缺產物 guard 修正後21 tests green，diffcheck0；未執行真 signing／Security／Live helper或phase |
| NR02 | blocked | Tester | 新回歸／完整 Offline；另一獨立 helper-only preflight 固定修後 source／pins | 獨立Offline21 mocks／正向2／預期負向2通過；修後helper build與簽章到位，host deep strict在Testing.framework sealed resource驗證失敗，停止；無bind／authorize／DPK／API |
| NR03 | completed | Reviewer | 獨立審查修後 source／pins、TC-NR01–04 與原 context／budget／歷史保持 | 獨立Reviewer完成分類needs-rework，要求App內embedded code inside-out修正；不等於NR02 preflight或Live通過 |

### N-R ReadOnly 例外 / Goal / TestCase

唯一 source 修改例外是 scripts/check-github-integration-hosted-tests.py 的 sign_products 及 Tests/GitHubIntegrationHostedTests/test_driver.py 的純 mock／暫存 fixture TDD。目標固定為預期 nested xctest、先簽 test bundle 再 host，缺產物 fail-closed；TC-NR01–TC-NR04 依 plan N-R。除此 source／tests／project／Swift 正式 Sources／manifests／contracts／CLI／context schema／budget／Apple 資產／old receipts 仍 ReadOnly。新功能、fallback 搜尋、fixture provisioning／登入／清除均不在範圍。

### N-R Evidence / Blockers / Stop

原 N03 blocked 與失敗 preflight／safe proof 保持 immutable；獨立 Reviewer 已指出 needs-rework，本次將最小修正公開列明，不是暗修。N01r／N02r／NR01完成；NR02完整Offline通過，但唯一修後preflight在host deep strict的Testing.framework sealed resource驗證失敗而blocked，NR03待獨立分類；不得以mock或nested bundle自身簽章通過取代整體preflight。
同一私有 parent `TMPDIR/rivet-hosted-live-n-20261118-m2mhtqhu/`、唯一 N context 及 authorizationRef 不變；未 bind／無 journal／正式 run-root 不存在。本輪 first／fresh 各使用 0/1、剩餘各1；舊 L 額度不動。另立 `preflight-fixed` 只作修後純 build／sign／驗證／列舉，記新 source／pins，不是 Live phase retry，不能 reset phase。
若再次工具／環境失敗停止回報，不擴修、自動 retry 或換 context。NR03 approved 後仍須主 session 通知並等 Human 可全程觀察回覆才正常 first；每段實際提示次數不預設。原 N04–N07／H01／M06 的 Human 與結果邊界不變。

### N-R Verdict

N01r completed；N02r planning approved；NR01 completed；NR02 blocked、NR03 completed／needs-rework。此為第二次準備失敗的歷史分類；其後N-R2另行修正與審查，原N03／NR02 blocked及失敗pins不覆寫。

### NR01 Implementer 證據

`python3 -B -m unittest discover -s Tests/GitHubIntegrationHostedTests -p test_driver.py`：先新增 nested target／bundle→host 順序、缺 host、缺 nested 及外置 decoy 不得替代等4個回歸，red 為21 tests／3 failures＋1 error；僅在 `sign_products` 改固定 nested 路徑並於資產／簽章操作前檢查兩預期目錄後，21 tests green（exit0）。所有 command／live_assets／verify_signing 均 mock，profile／bundle 僅為暫存合成 fixture；沒有真 codesign／Security／Live build／DPK／OAuth。`git diff --check` exit0。修後 source SHA為 `ac2e0418d352acf1d218f48be6bc38703534ab78bd785cf2a2a0b94c4707c772`，與原 `aeccff…` 分列，不反寫舊 pins。未操作唯一 N context、原失敗 preflight 或任何 phase root；交 NR02 獨立驗證。

### NR02 獨立 Tester 證據（2026-11-18）

- 親跑canonical `python3 -B scripts/check-github-integration-hosted-tests.py --offline` exit0：21 mocks、first／fresh正向各1原生案、assert／throw預期原生負向各1案；distinct actual PID／starttime、前程序退出、固定provenance、liveOperations=0。證據位於TMPDIR `rivet-hosted-offline-rfiu6gg2/`；artifact SHA `6e082f66a73a8cf6df394e81af51ed7f6a713723e0243c2fa29a9e06a4e26498`。
- 修後source SHA `ac2e0418d352acf1d218f48be6bc38703534ab78bd785cf2a2a0b94c4707c772`；git差異只有四artifacts及明示兩個py。3Swift／project／正式Sources／manifests／既有root及consumer tests保持；5份原evidence逐檔SHA保持。未無必要重跑root375／consumer22。
- 重新核對同一N context、既有profile SHA／expiry／可用identity／device／exact group資格及related writers0；沒有產生新context或Apple資產、沒有修改get-task-allow。Fixture仍未知。
- 只於同parent新 `preflight-fixed` 呼現有root_control／build一次；Live build-for-testing成功，sign-test／sign-host均正常完成。Nested test bundle的read-only strict verify exit0；host `codesign --verify --deep --strict` exit1，訊息a sealed resource is missing or invalid，subcomponent相對位置 `Contents/Frameworks/Testing.framework`。因此helper verify_signing未完成、enumeration未執行，不能宣稱host／profile／testbundle完整資格已通過。
- 再次問題後停止；只做read-only驗證以分類，沒有重build、再sign、修framework、變更策略或呼phase。新 `nr02-preflight-failure-safe.json`、`nr02-diagnostic-safe.json` 保存安全分類；原preflight／N03 proof與aeccff來源pin保持，修後source另凍結於preflight-fixed，不合併來源。
- 仍使用TMPDIR `rivet-hosted-live-n-20261118-m2mhtqhu/` 同一context，owner-only、未bind／無journal／正式run-root不存在。兩個preflight roots均無hello／attempt／authorize／machine／Human等phase證據；未讀fixture／呼API，first／fresh各使用0/1、剩餘各1。準備期間OS提示未觀察，不填0。待獨立Reviewer分類；即使後續解除阻擋仍需本輪Human ready才first。

## N-R2：App 內嵌程式碼 inside-out signing 受限修正

| ID | status | owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| N01s | completed | Plan-Creator | 四 artifacts 明列最小 inside-out signing 例外、禁止降格與同一預算 | 本 N-R2 四節；只文件完成，非獨立 approval |
| N02s | completed | Plan-Reviewer | 獨立審查兩檔受限 scope、App 邊界／順序／entitlements、停止與來源契約 | 獨立 Plan-Reviewer 明示 approved，無 required finding；僅 planning 核准 |
| NR11 | completed | Implementer | runner sign_products／bounded helper＋純 mock／temp fixture TDD | 新增6個純mock／合成fixture回歸：red 27tests／4failures＋1error，green27／27；App-bound canonical executable discovery、inside-out與host-only entitlements；其餘ReadOnly |
| NR12 | completed | Tester | 新增回歸＋full Offline 後，單次 preflight-insideout helper-only build／sign／deep strict verify／列舉 | 獨立27 mocks／正向2／預期負向2通過；11code targets逐一strict與host deep strict、profile／certificate／exactgroup及列舉通過；同一context未bind，無phase／authorize／fixture／API |
| NR13 | completed | Reviewer | 獨立審查修後 source／pins／scope／資格與原失敗不可變性 | 獨立Reviewer approved，無required finding；source／profile／context／artifact pins及11code／IDs吻合，僅準備資格核准，不代替N04與Human |

NR03 的獨立分類現已明示 needs-rework；原 N-R 表中 pending 為分類前歷史，不表示 approved。已知原因是 unsigned build 的 embedded framework 複本缺 sealed files 而仍帶 SDK seal，漏簽 embedded code；不能推論 profile／get-task-allow 無效。原 N03 blocked、NR02 blocked、兩個失敗 preflight roots／safe proof／pins全部保留。
唯一 ReadOnly 例外仍為 runner sign_products／內部 App-bound helper與test_driver.py純mock／temp fixture；不改 project／Swift／CLI／schema／budget／正式 runtime／contracts／profile／identity／group，不新增 Apple 資產。只對 App 內 resolved executable code inside-out 簽章，再 test bundle、host 最後；同一 identity，host-only DPK entitlements，resource-only bundle skip；禁止刪 seal、降格 verify 或 --deep --force。TC-NR2-01–04 依 plan。
同一私有 parent `TMPDIR/rivet-hosted-live-n-20261118-m2mhtqhu/` 與 context保持，未 bind、無 journal／attempt／authorize／hello／正式 run-root；first／fresh 各使用0/1。新 preflight-insideout 只一次修後純建置，不是 phase retry／額度重設；原 roots 不覆寫。再次失敗即停止回報，不擴 scope／自動重試；NR13 approved 後仍由主 session 等 Human ready 才 first。
N01s completed；N02s planning approved；NR11／NR12 completed；NR13獨立準備審查approved。修後完整Offline與純preflight通過只證準備資格；後續N04／N05實際機器及Human結果另列，不能由本準備結果推論。原 N04–N07、H01／M06 及所有 Human／歷史證據邊界保持。

### NR11 Implementer 證據

`python3 -B -m unittest discover -s Tests/GitHubIntegrationHostedTests -p test_driver.py`：先以6個新增純 mock／暫存合成 Mach-O／bundle fixtures產生 red（27 tests，4 failures＋1 error），證明漏簽embedded code／未擋App外alias等缺陷；限定 App 內 CFBundleExecutable 與 Mach-O runtime file types、canonical alias去重、inside-out signing後27 tests green（exit0）。涵蓋多framework與dylib、nested子層先簽、同identity且只有host使用既定entitlements、外部framework／executable symlink停止、內層失敗不簽父層、resource-only bundle／MH_OBJECT／普通資料跳過。程式依Apple TN2206、Bundle Programming Guide與Apple Mach-O loader.h／fat.h；不把SDK路徑當目標，不刪seal、不降格既有deep strict verify。所有signing／live_assets／verify均mock；沒有真codesign、build、SDK修改、N privateparent或phase操作。兩py AST parse及diffcheck通過。新source SHA `7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131` 與原兩輪失敗pins分列；交NR12獨立full Offline／唯一新preflight驗證。

### NR12 獨立 Tester 證據（2026-11-18）

- 親跑canonical `python3 -B scripts/check-github-integration-hosted-tests.py --offline` exit0：27 mocks、first／fresh正向各1原生案及assert／throw預期原生負向各1案，實際程序分離並退出、固定provenance、liveOperations=0。證據於TMPDIR `rivet-hosted-offline-y84_z0mm/`；artifact SHA `f1a2be360f13f138403d551ab0b3f67ed53e80a873153d83fe126008fc08895a`。
- 修後source SHA `7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`；只有明示兩py及四artifacts變更。3Swift／project／正式Sources／manifests／既有root及consumer tests未變，5份歷史evidence SHA保持；未無必要重跑root375／consumer22。
- 同一N context及parent保持，重驗現profile SHA／expiry／identity／device／exactgroup與related writers0。只在唯一新 `preflight-insideout` 呼現有root_control／build；未bind／呼main --live／execute_phase／authorize。原 `preflight`、`preflight-fixed` 與safe proofs逐檔hash前後一致，原aeccff／ac2e來源pins保持，不合併來源。
- Live build／inside-out signing／原deep strict verify／測試列舉全部完成。9個App內embedded targets（7 frameworks、2 dylibs）、nested test bundle及host共11個code targets，獨立逐一strict verify通過；host deep strict通過，實際paths全在App內，沒有簽SDK。11個targets同一選定既有certificate，只有host有DPK group entitlements，AppID／exactgroup／embedded profile皆符合現context；profile與host均無get-task-allow，此結果只證靜態簽章與列舉，不證debugger／runtime已可執行。
- 新preflight artifact SHA `0311950c8d7005854c9785e9cbebb9a8ba8a26e2d9c2c893b294075c35a0473d`；host binary SHA `76651b892ee3e4b47d9860bccd326412d014547dcbbfe9c1df58d5053f7cab57`；test binary SHA `5e09adfef598678f82d620b6605f4845047d1eb62dae0c7f50f7451ecba50a7b`。Profile SHA `6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`、expiry2026-11-23T06:19:04Z；certificate leaf SHA256 `5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440`。
- 固定test identifiers為 `GitHubIntegrationHostedTests/OAuthStartupHostedTests/first()`、`GitHubIntegrationHostedTests/OAuthStartupHostedTests/fresh()`。安全測量保存在同parent `nr12-safe.json`；context bytes SHA `c759c7a4af83920588cd6ef0eff79022c63aa8c6e6ba3af322a516f39c5ebf1d`，不公開raw identity／group／profilePath／credential。
- `preflight`、`preflight-fixed`、`preflight-insideout`三roots保留；同一context未改、未bind，journal與正式run-root不存在，無attempt／authorize／hello／machine／Human等Livephase檔，fixture未讀／未呼API，first／fresh各使用0/1、剩餘各1。準備期間OS提示未觀察，不填0；待NR13及本輪Human ready才可正常first。此preflight不是first結果，正式first仍正常CLI另建run-root並freeze自己產物。

### N04 正式 first 與 Human attestation（2026-11-18）

- NR13獨立approved後，主session重新詢問Human ready並取得「可以，現在開始」（questionItem `call_8c5a3267161e4c6b9800e9419546d88e`）；User觀察涵蓋正式build／sign至結束。只執行一次正常 `--live --context PRIVATE_CONTEXT --run-root RUN_ROOT --phase first`，未用preflight產物代替，CLI exit3／pending-human。
- 原生Swift Testing 1案passed、0skip；正式restore ready、API authenticated、完整credential readback一致、configuration保持，failureKind none。Actual PID99645、starttime2026-11-18 16:29:36，程序已退出、xcode exit0；握手授權與來源核對通過。Credential當時未到期；prepare及final均configurationLoads1／credentialLoads1，refreshAttempts／accepted／saveAttempts／saves均0，naturalRefreshObserved=false。本輪支持既存有效連線還原，不宣稱真refresh覆蓋。
- 正式run source SHA `7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`；artifact SHA `bc78a4ab7c3bf85b7dbf179acef35e21bdff222e9148d6c55b0c4541da1afc9d`；host binary SHA `703ed35ecaca63891d974062ff4389c92284da10826b05ba800445281bee3500`；test binary SHA `600377cddd9c93aa6b8a36f3c678f091dd5ea2e7101ea9f353d3791429a8a367`；embedded profile SHA仍 `6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`。正式run與preflight各自freeze，不把不同產物hash合併。
- 主session結束後新問題取得Human實答「0 次提示 全程觀看」（questionItem `call_a576877642f94c7a9178f82c2744f3c0`），不是舊E018答覆。正常 `--attest --phase first --fully-observed --prompt-count 0` exit0，`first_ready`通過。Human檔綁原machine SHA `58eeaecadb679ff501f01694a98f407ac4e217412bbad77157f958e98f562441`；Human檔SHA `55204cf81e84209ac17016c6ea45aa68765a5954875a394da53dd0835cdb351f`。
- 原machine bytes／SHA及新safe projection的human pending欄位不回填，Human另檔保存。Attestation只metadata，新增native tests／DPK／API呼叫均0；source／artifact／profile／context保持，context SHA仍 `c759c7a4af83920588cd6ef0eff79022c63aa8c6e6ba3af322a516f39c5ebf1d`。First已用1/1、fresh0/1未開始；本次沒有attest後自動fresh。原L／M與兩失敗preflight roots／pins不變。
- 安全first projection保存在同private parent的 `n04-first-safe.json`；canonical原machine／result／process／exit／xcresult及Human檔位於正式 `run/`，不含公開raw clientID／account／token／secret。N05仍須主session明確開始通知後另行一次正常CLI；N06結果審查及Human最終接受未由本段取代。

### N05 fresh 機器結果（2026-11-18，Human pending）

- First機器與Human gate通過後，主session已明確宣布fresh觀察開始；只執行一次正常 `--live --context PRIVATE_CONTEXT --run-root RUN_ROOT --phase fresh`，同context／run及受測產物，沒有rebuild／preflight／換root／改source。正常CLI exit3／pending-human，未執行fresh attest。
- Fresh native1案passed、0skip、xcode exit0；actual PID2898／starttime2026-11-18 16:33:08，與first PID99645／starttime不同，程序退出。Restore ready、API authenticated、完整readback、configuration保持、sameCredential及sameAccount均true，failureKind none。
- Credential未到期；prepare與final均configurationLoads1／credentialLoads1，refreshAttempts／accepted／saveAttempts／saves均0；naturalRefreshObserved=false。本輪支持有效credential的新程序restore與continuity，不宣稱自然到期真refresh覆蓋。
- Fresh原machine SHA `89fc51a9b65d122bac3b27226781ad887edc4f1d456f52b61caf66ff81998bf7`；source仍 `7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`、artifact仍 `bc78a4ab7c3bf85b7dbf179acef35e21bdff222e9148d6c55b0c4541da1afc9d`、profile仍 `6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`；context及first machine／Human SHA保持。Safe projection在同parent `n05-fresh-safe.json`，Human欄位保持pending，canonical fresh.human不存在。
- First／fresh各使用1/1，兩額度已耗盡，不重試、無額外phase／登入／seed／clear／強制expiry。現在只等本段Human是否全程與actual prompt count的新實答，不能用first／舊E018回覆代用，不能預設0；N06／N07及Human最終接受仍pending。

### N05 fresh Human attestation 與 Tester 最終交接（2026-11-18）

- 主session對fresh結束重新詢問，Human新實答「全程觀看 / 0 次」（questionItem `call_441c7a4e49814aa3b6f27e595a807cf7`），不是first或舊E018答覆。只執行正常 `--attest --phase fresh --fully-observed --prompt-count 0`，exit0／passed；未新增phase、native測試、DPK／API、build／簽章或source改動。
- Fresh Human檔SHA `47aa84ce5f09ba17f82a1d14e63f736b24d2256a4bcf4648bb0b7df83fc9bdf4`，綁原fresh machine SHA `89fc51a9b65d122bac3b27226781ad887edc4f1d456f52b61caf66ff81998bf7`。First machine仍 `58eeaecadb679ff501f01694a98f407ac4e217412bbad77157f958e98f562441`、first Human仍 `55204cf81e84209ac17016c6ea45aa68765a5954875a394da53dd0835cdb351f`；兩段原machine bytes及原n04／n05 safe projection的Human pending欄位未回填，Human另檔保存。
- Source／artifact／profile／context pins保持N04／N05測量值；兩段皆未到期、prepare及final的refresh／save全0。這是本次既存有效連線restore／API／完整readback／新程序continuity的有限結果，不涵蓋本輪真refresh或產品E2E。適用當次同機／GUI user／既有certificate／有效profile／exact group及唯一writer；沒有新Apple資產、登入／seed／clear／forced expiry。First／fresh各1/1已用盡，不再執行任何phase。
- 同一owner-only private parent已生成explicit allowlist的可複製新safe projections，沒有raw token／secret／clientID／account／profilePath／identity原文／控制key／使用者家目錄；不改舊repo evidence。`hosted-live-first.json` SHA `3b1f275972596aec1355990a117d28691d011a83fd510cb1fddd07bae2ddc88c`；`hosted-live-fresh.json` SHA `c62b2ca56d86023b7f69491cbe24a85739112ea3fb02a86be6abbba20380a2a9`。兩檔保存原machine SHA與source／artifact／profile pins、counts／booleans／native結果／退出；fresh附sameCredential／sameAccount／distinctProcesses，未公開不透明credential／account tags。
- `hosted-live-first-human.json`／`hosted-live-fresh-human.json`分別為canonical `run/first.human.json`／`run/fresh.human.json`的exact bytes副本，SHA同上，不添加推測Human欄位。兩projection共用獨立runIDHash `2e6152f268a8b0af396a976503aae327396196b89f7b5adac0ad905a4d44bf86`，不公開原runID。
- 交N06／N07：私有parent保留 `nr12-safe.json`、`n04-first-safe.json`、`n05-fresh-safe.json`及上述4份safe可複製檔；正式run內保存first／fresh的原machine、result、process、exit、xcresult及Human。兩失敗preflight proofs、27mock／Offline測量及舊L／M／5份repo evidence未被本段修改。N06獨立結果審查及N07必要文件／證據交付仍pending；Tester不代替Reviewer或Human最終接受。

### N07 受審證據／文件準備

Implementer只讀Tester explicit allowlist四份safe／Human檔、核對無秘密與私有路徑後，將原bytes複製至本topic evidence，並新增hosted-live.md及必要長期說明。Safe SHA依序為first `3b1f275972596aec1355990a117d28691d011a83fd510cb1fddd07bae2ddc88c`、first Human `55204cf81e84209ac17016c6ea45aa68765a5954875a394da53dd0835cdb351f`、fresh `c62b2ca56d86023b7f69491cbe24a85739112ea3fb02a86be6abbba20380a2a9`、fresh Human `47aa84ce5f09ba17f82a1d14e63f736b24d2256a4bcf4648bb0b7df83fc9bdf4`。Human分別綁原machine SHA，沒有回填機器pending／未觀察欄位。
凍結source仍`7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`；本次沒有改code／tests／project、重run／sign／preflight／DPK／API或讀raw private control／key／credential／log。原5份evidence及兩failedprep history保持。N06現已明示有限結果approved、無required finding；N07 commit／push／PR更新尚未完成，H01／M06最終Human接受pending。

### N06 獨立有限結果審查

Reviewer已明示approved、無required finding：4份repo safe／Human bytes與私有allowlist SHA相同，Human正確綁兩段原machine；原生各1案passed／0skip、不同actual程序退出、完整credential／account continuity；actual source／host與test binaries／profile／context／artifact pins吻合且preflight分列。兩段未到期、refresh／save全0，沒有假稱真refresh coverage；正式Sources／舊tests／原5份evidence保持，兩failedpreflight及原pins不改。此為當次有限integration結果核准，不是產品E2E、所有環境或Human最終接受；兩slots已用盡，停止額外Live操作。N07仍交付中。

### N07 交付 baseline 同步（獨立 bounded review approved）

遠端dev新baseline `e7a4b84`為已接受的PR #75 Login UI採用，包含Presentation／驗收工具及文件。Feature以正常merge整合，三份共享導覽README／architecture README／feasibility-adoption均自動合併、無conflict；保留外部UI採用與本topic N有限hosted結果，不把UI Human接受當成產品E2E或OAuth證據。外部UI檔案保留遠端原blob，不手工改UI／測UI。
完整受測source-manifest字典及SHA保持`7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`；外部差異與GitHubIntegration／HTTPClient／root manifests／hosted source及actualtarget依賴輸入交集為空。N06有限結果核准不重開，兩Live slots已耗盡，不重跑Live；獨立bounded Reviewer已明示approved、無required finding：72檔受測字典及SHA相同、protected source／evidence零差異、58個非共享外部blobs等於e7、三共享文件正確且無conflict markers。N07in-progress、H01／M06pending。本工作未寫dev worktree／branch；遠端追蹤ref以實際metadata讀回為準，不推論其更新者。


### N07 實際發布完成（2026-11-18）

正式簽章工具修正與受審有限結果以 `f68c386614951222d39b3418fe44b9cdc93bd07b` 正常提交；外部登入UI採用基線以 `9fee6781ba02d2410c09b5aef7450b91433e277e` 正常merge提交，parents為f68c386及e7a4b842。兩次正常commit hooks全通過、未skip；正常push後遠端feature與9fee6781一致。

既有 [Draft PR #77](https://github.com/a129924/rivet/pull/77) 已更新本輪有限結果、固定來源及safe evidence連結，讀回head為9fee6781、base為e7a4b842、Open Draft及mergeable均true，body吻合。N07 completed；本段後續僅以文件commit記錄已發生的交付事實，PR head將隨該commit前進。source-manifest 72檔及SHA仍為`7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`；未改正式runtime／受測工具／tests／project／evidence，未新增Live操作。H01／M06 Human最終topic review仍pending，未ready／merge。
