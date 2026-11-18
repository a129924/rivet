# R07：新版 host 原生差異與資源封裝審查

- 日期：2026-11-18；owner=獨立 Reviewer。
- 依據：T07 `acceptance-ownership-native.md`、實際 generated resource accessor、tool 包裝腳本與目前 app 路徑；binary `9219bd7656c55287ecb6ab1adc6d37f7f9b51e9b9217c15846cb27d8e0460b10`、source manifest `6c1d5266c7f10f2340ed383604fd8a74b3ff7f00a0411c276bd9df86a195921d`。
- **verdict: needs-rework；required fixes：一項 P2（RF03）。** 不重開正式 UI／API／架構；R06 的原 source/test/docs approved 與 pre-fix 證據保留，不回填改判。

## RF03：資源 bundle 未放在實際 accessor 的首選位置

`tools/acceptance/login-ui/scripts/build-app.sh:98` 將正式 bundle 複製至 app 的 `Contents/Resources`。但本次 generated accessor 第一候選為 `Bundle.main.bundleURL.appendingPathComponent("Rivet_RivetPresentation.bundle")`，即 app 根目錄；失敗後才使用當次 SwiftPM 的絕對 buildPath。正式 `LoginStyles` 由 `Bundle.module` 取得 GitHubMark.pdf。

Reviewer 只讀核對：app 根目錄 bundle 不存在，Contents/Resources bundle 存在，buildPath fallback bundle 仍存在；accessor SHA-256 為 `16d842c97847a3cc72627970af60d7769beba57332c5a92c9c7d8792e3b84fa5`。Binary 與28項 source 仍符合上述 receipt。這確認獨立包裝路徑缺口；T07 可見圖示與使用 build cache fallback 相容，不能據此稱 app 內資源已獨立載入。沒有 debugger/runtime path trace，不冒稱已觀測到實際 fallback 呼叫。

最小修正：只改 tool script，將同一正式 resource bundle 放入當前 accessor 期待的 app 根目錄，更新 packaged resource path、source/app receipt 與新 artifact SHA。正式 API／View／資源 bytes、root 設定及 E011 不動。不能僅改文件把缺口稱為已通過。

驗證限受影響項：核新包裝及 accessor 一致、source/app provenance，然後於 exact 新 artifact 取得當下確認後，以 fresh process 並受控排除其 buildPath fallback，觀察實際圖示。Fresh process 是必要條件，不能用已初始化 Bundle.module／快取圖示的舊 PID 補證。排除 fallback 限該次外部 run 的可逆安排，不刪改 source／global cache。無需重跑未變 UI 全矩陣或新增 host menu／產品設定。

## Native 證據與未驗分類

- T07 記錄 Human 已明示允許本次 exact9219 binary，CUA 成功啟動，Dark13／17／21、八 states AX、有限 receipt、同窗 copy／字級／PAT-failure identity、Reset、Return／Escape、focus／直接輸入均有 Tester 直接觀察。接受為該受測版本與所列案例的證據，不外推全組合、所有 race 或聲音；Reviewer沒有親看未轉交的三張主對話截圖，不稱獨立視覺接受。
- Light 未驗：CUA 沒有 app args API，取得 Terminal 被工具安全限制拒絕，未進入／執行命令，也未繞過。這是工具入口／授權限制，不是 Light 元件 failure。若要用既有 CLI 的 shell 標準 open 帶 args，需 Human 明示該工具方式，可在新 artifact 修正並審查後與 exact 啟動確認一併提出；不提前執行，不為此擴 host menu 或系統設定。
- T07 最後回到 Dark13／Standard Welcome、Continue focus；PID42461／binary／source 核對由 Tester 回報。這不是本 Reviewer 再次操作 GUI 的結果。
- 新 host Human VoiceOver 尚無回報；AX focus 不等於聲音通過。HC02、Light、Canvas 及獨立資源 runtime 證據保持 pending。原 HC01／H01–H08／舊接受保留，不套到新 host，也不回撤已接受的正式能力。

## 路由

交 Implementer 只修 RF03，補工具 source／app receipt 與有界檢查；其後可先做 source-only 差異復審，通過才提出 exact 新 app/source/binary 及 Light 工具方式的當下確認。Native 補驗仍須實際結果，再交 Reviewer；不 launch／merge、不擴新 topic。此輪 Reviewer未改作者程式／契約、未 build／test／GUI，只新增本證據。

`current_step: R07 needs-rework`；`next_step: RF03 tool packaging bounded fix`；`status: COMPLETE`（有界 review）；`verdict: needs-rework`。


## RF03 source-only 差異復審：2026-11-18

原 R07 needs-rework、9219 binary 的 Dark N01–N12 與資源 fallback 缺口保留。本次只復核腳本目的位置／receipt、新來源包裝證據及作者附錄，未操作 GUI、未 launch、未移動 fallback，也未重跑未改 Swift 的 unit／正式 UI 測試。

**最新 verdict: approved，僅限 source／docs／artifact 準備交付及提出 exact 新 app 當下確認；無新增 source required fix。RF03 的程式修正已確認，fresh-process 排除 fallback 的 runtime 條件仍未完成。**

- Script 現將同一正式 bundle 複製至 app 根目錄，resource receipt 從該位置產生；沒有另複製到 Contents/Resources。README／I03 附錄與 T07 差異段明列此修正與 runtime 限制。
- Reviewer獨立核對28份 current source bytes／canonical manifest，和修前6c1d清單相比只有 build-app.sh 改變；Swift／root readonly／E011 未因此改動。Script SHA為 `9a88a9b2d2b0a90a0e19c3bd3059d5cc28a538d644f0c3c337c9683cda1059c1`。
- 新 generated accessor 仍優先找 appRoot 的 Rivet_RivetPresentation.bundle。實際首選位置存在、舊 Contents/Resources 位置不存在；PDF仍1812 bytes、SHA `37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`。
- 新 app 各 entry 的 bytes／mode／type 與 canonical tree digest符合 receipt，root readonly 前後相同。Tester親跑 script／plist／bash syntax／diff-check結果保留；Reviewer沒有再 build/test。讀取純 Foundation probe log確認 packaged Bundle(path:)／url(forResource:)可讀 PDF；**此非 GUI 或 fresh app 的 Bundle.module runtime 證據**。

### 目前待確認的新 artifact

外部 run 別名 `$R3_RESOURCE_FIX_RUN`；app 為 `native/RivetLoginAcceptance.app`，ID `local.rivet.login-ui-acceptance`：

- Source manifest SHA-256：`3e748de3a3b19225e1a03160d90318037a0be8430b13b911ec2e958b34bdd988`。
- Binary SHA-256：`6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1`。
- App tree SHA-256：`ccfbbd965a9a8b40e4b3df22562f7542d02b2dc28a93f9a3b4a6df2988877cae`。
- `nativeLaunch: not-run`；fallback未動，無新 PID／AX／截圖／聲音。原9219確認不套此6a binary。

### Remaining conditions／路由

可依原 topic 授權 commit／push／更新既有 Draft，明列 source-only 及 runtime 未驗；不 merge。下一步對 exact 新 app/source/binary 及有限流程提出 Human 當下確認：只操作已核對的舊 instance，對新 run 的 fallback 作精確可逆排除，以 fresh process驗 Welcome／GitHub圖示；不得沿用舊PID內已初始化的 Bundle.module。Light若使用 shell標準open帶既有CLI appearance args，須先由Human明示該工具方式，不擴Host menu、不改系統設定或繞過Terminal限制。

T07整體仍INCOMPLETE；Light、新artifact runtime／resources、Canvas及新hostHuman聲音／HC02 pending。原Dark N01–N12與舊HC01各保留原version，不因source-only批准外推新native或Human接受。實際補驗後再交R07，不能將此附錄當最終runtime關閉。

`current_step: R07 source-only approved`；`next_step: 受限交付與exact新artifact／工具方式當下確認；其後T07 runtime補證`；`status: COMPLETE`（本輪有界source-only復審）；`verdict: approved`（受限範圍）。

## RF03 修後 runtime 有界復審：2026-11-18

**verdict: approved（F01–F06 代理 runtime／來源證據範圍）；required fixes: 無。RF03 在本次受控環境的 source 與 fresh-process runtime 條件已完成，關閉此項。Human 最終接受仍為 human-check。** 原 needs-rework、source-only 復審及舊版結果保留，不回填改判。

依據為 T07 的 F01–F06、[runtime receipt](acceptance-ownership-runtime-receipt.json) 與 external run 原始 machine receipt。Reviewer 獨立核對兩份 JSON，僅 fallback 路徑轉為 run-relative，其餘內容完全一致；沒有 PAT payload 或本機絕對路徑寫入此 receipt。新來源 HEAD 為 `9d14a3f6bf878a215de0d39d4fb05ec05970ec80`。

- 紀錄表明舊 instance 退出並查無 process 後，精確、可逆移走該 run 的 non-symlink fallback；Light PID71178 與 Dark PID72574 是不同的 exact 新 binary process。Light 結束後才啟動 Dark，兩次 open exit0；fallback 在兩次啟動與圖示觀察期間均缺席。
- Tester 直接 CUA 觀察 Light13／Dark13 Welcome 與 GitHub 圖示、有限鍵盤／PAT互動與 Light21 failure 底部操作。這與 appRoot 首選資源路徑及缺席的 build fallback 共同支持此次獨立資源 runtime 條件；並非 debugger 路徑 trace，也不外推其他 SwiftPM／分發環境。Reviewer 未操作 GUI、未親看未轉交的主對話圖片，不稱獨立視覺接受。
- Reviewer 只讀重核28份 source bytes 符合 manifest `3e748de3a3b19225e1a03160d90318037a0be8430b13b911ec2e958b34bdd988`；binary SHA為 `6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1`；整 app entries 的 bytes／mode／type 與 canonical tree `ccfbbd965a9a8b40e4b3df22562f7542d02b2dc28a93f9a3b4a6df2988877cae` 全符。沒有 rebuild 或 app 變更，root readonly 前後相同。
- 核對 fallback 已還原為非 symlink 目錄、held 路徑不存在，PDF SHA仍為 `37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`，與 packaged PDF／receipt 相同。可逆操作已收尾，不留下資源移位。

此次 Human 已明示 exact 修正版、受控 fallback 排除／還原及 shell 標準 open 的 Light／Dark 工具方式；沒有操作先前被拒的 Terminal UI 或改系統設定。Reviewer 本輪未 launch／移動 fallback／重跑測試，也未改作者程式。

範圍仍限 F01–F06；9219 的 N01–N12 保持原版本，不宣稱6a重跑完整矩陣。Human「我做不出來」是操作引導／驗證未完成，不能據此判元件 failure 或 pass；AX／直接輸入的代理觀察不等於 Human 聲音確認。HC02、聲音與 Canvas 仍 pending，原 HC01 接受保留原版本。

可依既有授權據實更新 docs／既有 Draft；繼續由主流程引導 Human 聲音與最終接受並保留實際回覆，不能代替 Human 或 merge PR。無新增 source blocker、架構／consumer 測試或圖重產要求。

`current_step: R07 runtime bounded approved`；`next_step: Human 聲音／HC02 驗證與據實交付更新`；`status: COMPLETE`（本輪有界審查）；`verdict: approved`（代理 runtime／來源證據）；`human_boundary: human-check`。

## V01／V02 Human 聲音證據有界審查：2026-11-18

**verdict: approved（Human 聲音 attestation 紀錄與界線）；required fixes: 無。HC02 最終差異接受仍為 human-check。** F01–F06／RF03 已核定結果不變，不以本輪 case 結果代簽 Human 最終接受。

本輪只讀 [Human 聲音證據](acceptance-ownership-voiceover-human.md) 與 T07 末段，兩者對版本、方法、實際回報及限制一致。沿用先前已核 source HEAD `9d14a3f`、manifest `3e748de3…`、binary `6a7867b5…`、app tree `ccfbbd96…`；未重核28份 source／app、未操作 GUI 或重跑測試。沒有新 source 變更的主張與此次聲音驗證方法相容，不產生新 artifact 接受。

- Human 明示已開旁白；最初「我做不出來」、重啟要求、單獨「有讀到」及跨 App 焦點干擾保留為未完成嘗試，不判 failure／pass，也不推定唯一干擾來源。
- 無問答卡、Tester 切態後停止操作的最後回合，Human 普通訊息明示：V01 讀到 Continue with GitHub、沒有晚到帳號驗證語音；V02 讀到 PAT 區塊、可不點欄位直接輸入、沒有晚到舊驗證語音。可採為這兩次有界序列的 Human 聲音／直接輸入回報。
- 紀錄未把 AX keyboard focus 當 VoiceOver cursor 或音訊 trace；沒有完整音檔／最後一句逐字稿、全部快速 race／漏讀矩陣保證，也未保存 Human 輸入。收尾回同 app 乾淨 Welcome 是 Tester 的 AX／畫面觀察，不是 Reviewer 再操作或 Human 最終接受。

沒有可由本證據定位的新元件缺陷或 required source fix；不要求新架構、全矩陣重測或重畫。Canvas 未驗、舊 HC01／H01–H08 與9219 N案例各保留原版本；HC02 的驗收支援分離／封裝修正／新 host 差異最終接受仍須 Human 明示。可依原授權據實更新 source／docs 交付與既有 Draft，不 merge。

`current_step: R07 Human聲音證據 bounded approved`；`next_step: HC02 最終Human差異接受`；`status: COMPLETE`（本輪證據審查）；`verdict: approved`（聲音 attestation 紀錄）；`human_boundary: human-check`。
