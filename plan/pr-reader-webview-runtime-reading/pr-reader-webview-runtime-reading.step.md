# pr-reader-webview-runtime-reading — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-runtime-reading`
- Current phase: PR-03 獨立審查已 `approved`；IM-01 已完成本地實作，TE-01 回修後獨立 `approved`；RV-01 重新獨立審查 `approved`，待 DL-01。
- Ledger rule: step status、checkbox、測試結果均不等同 gate approval；僅指定獨立角色的明示 verdict 可前進。

## Goal / Non-Goal

Goal：建立 fixture 驅動、可啟動的真實 WKWebView Reader runtime，讓多檔 diff 與 Viewed Swift authority 往返可見。Non-Goal：真實 GitHub PR、永久 Viewed、完整 Reader UI 或公開 bridge／TS contract 變更。

## In-Scope / Out-Of-Scope

In-Scope：harness、bundled assets、live transport、DOM Output、可見失敗、identity 防護、runtime 與人工驗證、長期架構更新。Out-Of-Scope：GitHub source／write、Inbox、comments／reviews、大型 diff 分段、cache、retry、可靠傳輸。

## File Operations

- ReadOnly：`Sources/BoundedContexts/PRReader/Core/`、`Sources/PRReaderWebViewBridge/{BridgeSession.swift,WireContracts.swift}`、`surfaces/pr-reader-webview/src/diff-rendering/{contracts,ports,adapters,facades,usecases,concrete-stages}/`、下述單一 graph assertion 以外的既有 tests／fixture、其他 topic artifacts。
- Written：本 topic 四份正式 artifacts；`Sources/RivetPRReaderHarness/main.swift`、`Sources/RivetPRReaderHarnessRuntime/{ReaderHarness.swift,ReaderFixture.swift,Resources/index.html,Resources/reader.css,Resources/reader.js}`、`Tests/RivetPRReaderHarnessRuntimeTests/ReaderHarnessTests.swift`、`surfaces/pr-reader-webview/src/diff-rendering/output/{dom-diff-output.ts,dom-diff-output.test.ts}`、`surfaces/pr-reader-webview/src/runtime/{webview-runtime.ts,webview-runtime.test.ts}`。
- Deleted：無。
- Modify：`Package.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 僅改 `packageDeclaresTheLockedTargetGraph` 的 exact product／target expected sets，加入 `RivetPRReaderHarnessRuntime` library product／target、`RivetPRReaderHarness` executable product／target 與 `RivetPRReaderHarnessRuntimeTests` target，保留既有 GitHubIntegration／bridge isolation assertions 及 format／lint 限制；`surfaces/pr-reader-webview/package.json`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/diagrams/pr-reader-webview-diff-rendering/{scene.js,diff-render-flow.dataflow.json,index.html,diff-render-flow.html}`。

## TestCase

- TC-01：真實 WKWebView fixture → Swift bridge → TypeScript pipeline → DOM；多檔、六狀態、patch 與 metadata-only。
- TC-02：Viewed 雙向切換只更新 Swift 目標檔案；authority 成功寫入 callback 下一個 main-actor turn 才刷新，identity ignore／authority throw 不呼叫 callback 或刷新。
- TC-03：啟動／資源／交付／render／逾時／process 失敗可見，惡意 diff 不執行。
- TC-04：完整 Swift／TS 回歸；package graph exact 集合只加入兩個 products／三個 targets，原 GitHubIntegration／bridge 隔離斷言維持；format／lint、browser bundle 重建比對、圖表驗證與人工啟動操作。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 依已核准對話計畫建立同 slug 四份正式 artifacts，列明受限路徑與驗收。 | 四份文件已起草；不構成 Plan-Reviewer approval。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查 initial 四份 artifacts 的 scope、contracts、檔案邊界、上游 gate 與實作 readiness。 | 明示 `needs-rework`：Viewed 的 `void` 返回值無法表示 authority 成功；上游 correction pending 與本 topic implementation precondition 尚未分清。不構成 implementation approval。 |
| PC-02 | completed | Plan-Creator | 明定 host-owned authority 成功 callback、下一 main-actor turn 刷新與 failure／ignore tests；界定合併基線及未合併 correction 的依賴。 | 四份 artifacts 的受限修訂；保留 PR-01 歷史 verdict，不自我核准。 |
| PR-02 | approved | Plan-Reviewer | 新的獨立審查 PC-02 修訂、`IM-01` 基線前提與 TC-02，明示 verdict。 | 獨立 Plan-Reviewer 明示 `approved`，無 findings；確認 Viewed 成功 callback／延後刷新、merged baseline 與 EOF correction 的非硬依賴已足以進入受限 IM-01。不回填 PR-01 verdict 或上游 topic gate。 |
| IM-01 | completed | Implementer | PR-02 `approved` 後以已合併 `dev` 基線 `9c61af8` 在 feature worktree 完成受限 runtime、測試與 docs／圖 source 更新；graph test 修訂經 PR-03 `approved` 才恢復；若測試觸發未合併 EOF correction 缺陷，停止並路由原 topic。 | 保留曾因 exact graph test 暫停的歷史；PR-03 後僅擴充該 test 的預期集合。`swift test --disable-sandbox --scratch-path <scratch>` 136／136 通過，含真實 WKWebView 六狀態、Viewed 往返、過期事件、惡意 markup 與 render／process 失敗。`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`bun run check`、`bun test`（98／98，coverage gate）、browser IIFE bundle 雙次 SHA-256 一致、canvas 0 errors／warnings、Archify showcase 9／9 checks、圖表交易式重建通過。未作獨立 TE-01／RV-01，亦未 commit／push／開 PR。 |
| PC-03 | completed | Plan-Creator | 僅將上述單一既有 graph test 的 expected product／target sets 納入 Modify，補充 TC-04 與 fresh gate；保留所有其他 assertions。 | 本次四份 topic artifacts 的受限修訂；不變更產品程式或測試，不追溯擴張 PR-02 approval。 |
| PR-03 | approved | Plan-Reviewer | 獨立審查 PC-03 的 test-only allowlist、exact graph 集合、既有 isolation assertions 保留及 IM-01 恢復條件，明示 verdict。 | 新的獨立 Plan-Reviewer 明示 `approved`，無 required fixes；受限的 graph expected-set 更新可交由 Implementer 接續 IM-01。不回填 PR-02 的 scope 或改寫 IM-01 暫停事實。 |
| TE-01 | approved | Tester | IM-01 完成後獨立驗證 TC-01 至 TC-04、資產、圖表與 changed-path scope，明示結果。 | 初次 Tester verdict `needs-rework`：TC-03 缺資源載入、交付、逾時及外部導覽的可執行證據。Implementer 僅在已核准的 harness/runtime 與對應 test 檔補測；再次獨立驗證後 Tester verdict `approved`。`swift test --disable-sandbox --scratch-path <scratch> --quiet` 140／140 通過，`--filter ReaderHarnessTests` 9／9 通過，四項 TC-03 均在真實 WKWebView 執行；`bun test --only-failures` 98／98 通過，coverage 100% functions／99.08% lines；`bun run check`、Swift format／lint、`git diff --check` 通過。browser bundle 暫存重建與打包檔位元相同；canvas 0 errors／warnings、Archify showcase 9／9，兩份圖 HTML 暫存重建與既有產物相同。測試用資源 URL、逾時設定及拒絕導覽計數只具 internal 存取，未擴充公開 API；外部導覽仍由 fixture URL 與 main-frame 檢查拒絕。初次 `swift run RivetPRReaderHarness` 啟動並持續執行至 Tester 主動停止，但系統拒絕 Accessibility 查詢（-25211），當時未宣稱目視完成。2026-09-30 使用 Computer Use 檢視同一 feature build 的暫時本地 app bundle：AX 依序顯示 added、removed、modified、renamed、copied、typeChanged 六檔，前四檔有 patch，後兩檔有明確 metadata-only 提示；畫面截圖也確認 patch 色塊與 metadata-only 提示可視區分。點選首檔 Viewed 後 AX 按鈕由「標記 Viewed」變為「已 Viewed · 取消」，再次點選恢復，其他五檔按鈕未變。此為回修前的 fixture 目視補充證據，並非 HC-01 人類審查。RV-01 `needs-rework` 後的 bounded ready-deadline／message-handler 回修再由 Tester 獨立驗證為 `approved`：`swift test --disable-sandbox --scratch-path <scratch> --quiet` 142／142、`--filter ReaderHarnessTests` 11／11、`bun test --only-failures` 99／99（coverage 100% functions／99.09% lines）皆通過；`bun run check`、Swift format／lint、`git diff --check` 通過，browser bundle 暫存重建與打包檔 SHA-256 相同。真實 WKWebView tests 確認 provisional navigation 起算 ready deadline、逾時後 late ready 不復活、舊世代 timer 不使新頁失敗；TS test 確認缺 WebKit handler 時 startup throw，另以 `bun -e` 檢查 Viewed post throw 仍被 best-effort 吞下。本輪未重新目視回修後的 app；待新的獨立 RV-01 verdict。 |
| RV-01 | approved | Reviewer | TE-01 後獨立審查程式、契約、安全、scope、文件／圖表及驗證證據，明示 verdict。 | 首次明示 `needs-rework`：ready 階段缺 timeout，缺 handler 可靜默遺失 ready。受限回修及獨立 Tester 再驗證後重新審查明示 `approved`：provisional navigation 即啟動 15 秒 ready deadline；目前世代 ready 取消 deadline；terminal failure 清除 `awaitingReady`，晚到 ready 無法復活；新 navigation 取消舊 timer，世代及取消檢查避免舊 timer 誤傷。TS 缺 WebKit handler 時 throw，Viewed best-effort 通知仍吞下 post failure。真實 WKWebView 增加逾時／late-ready 與舊 timer／新世代兩項測試；Tester 回報 Swift 142／142、focused 11／11、TS 99／99，format／lint、bundle byte comparison 皆通過。本輪核對 changed-path scope、既有 identity／authority／DOM／資源／圖表及 graph assertion，無未解阻擋發現；可交 DL-01，不代表 human check 完成。 |
| DL-01 | pending | Implementer | 僅於 RV-01 明示通過且無重大問題後，依 commit 規範與使用者授權在 feature worktree topic commit、push、開 base `dev` Draft PR。 | 尚無 commit、push 或 PR evidence。 |
| HC-01 | pending | Human | 檢查 Draft PR 的 runtime 效果、範圍與驗證證據，決定後續處置。 | 尚未開 Draft PR；不宣稱人類驗收。 |

## Blockers

- PR-01 的 `needs-rework`、PC-02 與 PR-02 的獨立 `approved` 均保留歷史。IM-01 曾因 exact graph test scope gap 暫停；PC-03 修訂取得 fresh PR-03 `approved` 後，僅在其限定的單一 expected-set 修改範圍內恢復並完成。PR-02 不追溯放行該修訂。
- concrete-stages PR #13 與 bridge PR #43 的 merged baseline 已在 `dev` HEAD `9c61af8`；原 concrete-stages ledger 的 `RV-17 blocked`、`RV-18`／`DL-10` pending 屬未合併 EOF correction route，並非本 topic 硬依賴。本 topic 不改其歷史、不使用該 correction；測試如觸發相關 EOF 缺陷，停止並路由原 topic。bridge `HC-01` ledger pending 亦不回填。
- 若現有同步 sink 無法在不改公開契約下提供已接受／已呈現語意、若 HTML 無法安全清理，或需要超出已列檔案／外部權限，先停止並回規劃或 human decision。
- TE-01 初次 `needs-rework` 的 TC-03 證據缺口已由受限補測與再次獨立驗證解除；該歷史 verdict 保留於 TE-01 evidence，不視為初次通過。
- RV-01 初次 `needs-rework` 的 ready timeout／missing-handler 缺口已經受限回修、Tester 再驗證與 Reviewer 重新審查 `approved` 解除；歷史 verdict 保留，不視為初次通過。

## Human Check

- 使用者已同意對話計畫，並授權無重大問題時在 feature worktree commit by topic → push → Draft PR → human review；此授權不替代獨立 planning、testing 或 review gate。
- 不在 dev worktree 實作任何檔案；`HC-01` 為 Draft PR 建立後的人類審查停點，不預先宣稱通過。

## Last Updated

- 2026-09-30；PR-03 `approved` 後 IM-01 完成受限實作；TE-01 初次 `needs-rework` 後受限補測，再次獨立 `approved`；RV-01 初次 `needs-rework` 的 ready timeout 缺口已受限回修，Tester 再驗證及 Reviewer 重新審查明示 `approved`。DL-01、Draft PR 與 human review 仍 pending。
