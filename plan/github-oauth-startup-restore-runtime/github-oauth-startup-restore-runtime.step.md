# 執行帳本

## Current phase
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
