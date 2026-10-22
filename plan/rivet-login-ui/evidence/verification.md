# Rivet 登入 UI：IM-01 自我驗證

2026-10-22；branch `feat/rivet-login-ui`；base `14d0832f042720889993d769b4cbfb720078e6b1`。所有寫入僅在已授權 feature worktree。IM-01初始尚未commit／push／PR；目前code commit與發布停點以下節為準。本文保留Implementer歷史及獨立Tester／Reviewer交接，不混同各角色verdict。

## 本地交付與發布停點（目前狀態）

Code commit已完成：`98f057324419d33926850d926483080c3f3ca633`，message `feat(presentation): 新增原生登入畫面與假資料展示`，36檔（實際32 Written＋4 Modify）。完整staged diff單一topic／原件bytes／凍結圖SHA核對完成；pre-commit trim、EOF、Swiftformat、GitHubIntegration consumer、SwiftLint與renderer-check全部passed。第一次renderer工具缺依賴的失敗及其frozen-lock補齊已在下方保留，沒有SKIP／no-verify。

使用者原已明示「commit by topic → push → open Draft PR → Human review」，這份授權保留。實際兩次正常非force `git push -u origin feat/rivet-login-ui` 都在工具執行前被自動approval review拒絕，並未推送；唯讀ls-remote確認遠端feature branch不存在。沒有第三次retry、改transport、用connector送objects或其他繞過動作，沒有建立PR。

目的地已驗證為既有 `https://github.com/a129924/rivet.git`，GitHub repository `a129924/rivet`、public、owner `a129924`、目前帳號ADMIN／push權限。第二次自動拒絕仍認為原先「push」授權未明確包含將此payload公開至具體目的地，要求Human明確確認「將本topic的程式、測試、使用者原始素材、文件與圖面公開推送到此repository」。這是自動審核額外要求的公開發布確認，不改寫成Human從未授權push；目前等候該明確確認，未假稱已同意或已成功發布。

PL-01已由獨立Reviewer完成本地change map，Dispatcher正式交接：真base `14d0832f042720889993d769b4cbfb720078e6b1` → code head `98f057324419d33926850d926483080c3f3ca633`；pinned CLI validate／render均exit0。1 view、4 lanes、9 nodes、11 edges、4 walkthrough steps；包含必要unchanged neighbors與file refs。Graph contentHash `19c75381ffa577574cd8fc8f3ece66b3`；SVG 17311 bytes、1708×596。Reviewer已核source／manifest／SVG XML labels，沒有raster visual review，不宣稱圖像實看。

外置成果採symbolic位置：`$TOPIC_SCRATCH/pr-lens/98f0573/graph.json`、`rendered/manifest.json`、`rendered/login-ui-change-light-b14b12a647503ffbc6daf5bfc15d66e9.svg`。此map只對上述code commit，不含之後兩檔本地交付紀錄的metadata commit，不冒稱final-head map；未上傳、未發布或附到PR。

TE-01親跑focused10／root284／debug／release／format／scoped0及baseline比較、第2輪Archify新證據獨立核對與RV-01 approved／P2 closed均保留。Root strict lint仍39＝37舊experiment逐條baseline一致＋2原樣封存scaffold，production／tests scoped0。Native四份PNG、實際互動／Keyboard／VoiceOver等AX仍pending；Bounded source／evidence approval供Draft交付，不代表完整原生驗收或Human最終UI採用。GH-01未建立，等待公開push確認後的正式發布動作；HC-01採用決策仍pending。

本節為本地metadata收尾；不在自身內容回填尚未成立的metadata commit SHA，不重新執行Swift／產圖／PR Lens，也不進行任何remote操作。

## PR-02 後 bounded fix：目前狀態

Dispatcher 明示正式 PR-02 approved、無required fix後，已最小同步 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` product／target expected sets：diff僅新增2行，equality與其餘隔離assertions原樣保留。focused10tests／3suites pass（0.621s）；root284tests／36suites全pass（3.711s），修復先前本topic manifest引入的兩個issues。

本輪scoped SwiftLint仍0 violations／136files、format exit0；root strict實際39findings＝37項未修改的既有experiments＋2項原樣歸檔scaffold，production0。前輪44總數保留；先前將其分組為36／2／6是口頭估算錯誤，以本輪精確37／2／0為準，不宣稱rootstrict零。

Archify第1輪perceptual修正後，重新9/9validate／deliver／SHA copy／visual-check，四尺寸containment全pass；四圖已實看 `visual_review: passed`，自動receipt仍pending。新hash及過程見BUILD。

Native完成CUA reset→getState→fresh binding後仍cgWindowNotFound；明確以withExtendedLifetime保留host／delegate到AppKit run-loop結束，debug build1.85s成功；未宣稱它是已證實root cause。只更新外置wrapper的Demo binary與Presentation bundle，最後一次重啟後fresh CUA仍同錯，停止重試交Tester。首次Welcome截圖僅工具對話顯示，未存檔；四份指定native PNG仍缺，不用舊圖或placeholder補造。最新release build結果由外置fix-release log記錄。

外置wrapper相對topic scratch位置：`native/RivetLoginDemo.app`；bundle ID `local.rivet.login-ui-demo`；launch命令 `open "$TOPIC_SCRATCH/native/RivetLoginDemo.app"`。最後重啟前PID70452已停止，未查新PID，避免把舊PID當目前。Raw swift-run PID65297早已停止。進一步native驗證由獨立Tester接續。

下方自動表格與第一次GUI紀錄保留為初輪歷史；目前以本節及下方最新矩陣為準。

## 自動驗證

| 操作 | 實際結果 |
| --- | --- |
| TDD red：focused tests，在新行為未實作時執行 | exit 非0；缺 `RivetLoginTokenInput`／`LoginDemoModel` 等新 symbols，非環境失敗。 |
| `swift test --filter 'RivetLoginPresentationTests|LoginDemoModelTests'` | exit0；9 tests／2 suites pass。 |
| `swift test` | 非0；284 tests／36 suites，`GitHubIntegration static isolation / packageDeclaresTheLockedTargetGraph()` 一個 test 記兩個 issues。`StaticIsolationTests.swift:12,17` exact products／targets sets 未包含本次已授權新 Demo 三 targets，直接由本次 manifest 變更造成，不標環境。等待該檔 exact Modify allowlist 與 Plan-Reviewer 後最小更新，不擴既有 production。 |
| `swift build --product RivetLoginDemo` | exit0；debug build 3.06s。 |
| `swift build --product RivetLoginDemo -c release` | exit0；7.93s。 |
| `scripts/check-swift-format.sh` | exit0。 |
| `swiftlint lint --strict Sources Tests packages/RivetHTTPClient/Sources packages/RivetHTTPClient/Tests` | exit0；0 violations in136 files。 |
| `swiftlint lint --strict` | 非0；首輪44 findings曾有本次production問題，均已修且scoped0；分組以PR-02後精確記錄為準。保留七原件不為lint改寫 scaffold、不改config或既有experiments。原樣 scaffold 2項（identifier_name／line_length），既有 experiments37項（最新精確結果）。root strict仍未達零，不宣稱root pass。 |

完整 logs 存於 repository 外 topic scratch／暫存，非交付原始碼；上述數量來自實際執行。最後 production 修改僅 Preview callback 格式，不改模型行為。

## 原生 GUI

按計畫 `swift run RivetLoginDemo` 啟動成功，無錯誤輸出；CUA 無法選 raw executable。Dispatcher 已允許外置最小 `.app` wrapper，使用同 `.build/debug/RivetLoginDemo` 與 SwiftPM resource bundle，不新增 repo 路徑、不 signing／profile／auth。

首次 CUA 可讀 Welcome AX 與真截圖：heading、Continue button、PAT link、mock footer 可見；左側 branch／dots／diff 已呈現。實看發現 titlebar safe area 多32pt及PDF named loader無mark，已改 `.ignoresSafeArea()`／contentMinSize及file URL NSImage template loader並debug build成功。更新外置wrapper後process存在，CUA以bundle ID及完整app路徑重選均回 `cgWindowNotFound`。不以首次圖當最新修正通過，不以 ImageRenderer 補造原生證據。

四份 `welcome-light.png`／`welcome-dark.png`／`waiting-dark.png`／`token-dark.png` 尚未保存，不建 placeholder。最新 native app、PAT focus／Show-Hide、七態操作、高對比、System/Light/Dark、resize／大字／Reduce Motion、Keyboard Navigation／VoiceOver 均交 Tester 驗證。沒有改全域設定、TCC或使用其他 app 的憑證／資料。

## 工具

- Graphify：`GRAPHIFY_NO_AUTO_REFRESH=1` + pinned CLI `--version` 回 `graphify 0.9.73`。限定 feature tree 沒有 codegraph，未 query／extract／refresh／寫 stamp；以 manifest、既有 harness entrypoint、InboxHeader 及其 tests targeted reads 核實 source 邊界。
- Archify：deterministic validate＋deliver 9/9、0 errors/warnings；same-byte copy／SHA 相符。四張明暗 sidecars 已實看，visual-check 三尺寸垂直 overflow，初輪LU-10 needs-rework；現版已由第1輪修正通過自驗。詳細 receipts、commands、hash與未用 perceptual budget 見 [BUILD](../../../docs/presentation/diagrams/rivet-login-ui/BUILD.md)。
- PR Lens：尚未 commit，map pending；不使用假 SHA。由獨立 Reviewer 依真 bounded diff 先審，正式 commit 後才產外置 map。

## 驗收矩陣與下一步

| ID | 本輪狀態 |
| --- | --- |
| LU-01 | pending：四份最新原生截圖缺。 |
| LU-02 | 模型自我tests pass，native pending。 |
| LU-03 | PAT value-state自我tests pass，focus／Show-Hide native pending。 |
| LU-04／05／06 | pending：尚無完整native／AX條件證據。 |
| LU-07 | imports／model無network／credential storage，自我核對；獨立review pending。 |
| LU-08 | focused、debug／release、format／scopedlint pass；root target-set test已修並root284pass；rootlint39 baseline findings如上，production0。 |
| LU-09 | fallback completed，獨立核對pending。 |
| LU-10 | 第1輪後deterministic／四尺寸containment／四圖實看自驗pass，獨立核對pending。 |
| LU-11 | 真 head前 map pending。 |

IM-01 為 bounded implementation handoff，未滿全部 completion condition：root-test exact path planning與最小test修正、圖面第1輪修正均已完成；剩native evidence交獨立Tester。不以此文件宣稱 agent gate 通過或 Human 採用。


## TE-01：獨立 Tester 實際驗證（2026-10-22）

本節為目前獨立驗證結果，前述 Implementer 自我證據保留為歷史。Tester 只更新此 evidence／step，未修改 production、tests、原素材或凍結圖。環境為 macOS 26.5.2（25F84）、arm64、Apple Swift 6.3.3。feature branch 為 `feat/rivet-login-ui`，固定 baseline `14d0832f042720889993d769b4cbfb720078e6b1`。

**結論：partial verification，沒有全項 passed verdict。** 自動驗證與圖面證據可供 Reviewer 使用；最新原生 UI 四圖、互動與 accessibility 仍 pending，具體阻礙為 CUA 選窗阻塞及 shell screen-capture 權限不足，不是已證實的 source bug。未索取 TCC、未改全域設定，未用 ImageRenderer／placeholder 補圖。Reviewer 與 Human 的 verdict 仍各自待處理。

### 親跑命令與結果

完整外置 logs 位於 `$TOPIC_SCRATCH/tester/`，不屬 repository 交付；`results.json` 記命令 exit 與末段 stdout。

| 命令 | 結果 | Log |
| --- | --- | --- |
| `swift test --filter 'RivetLoginPresentationTests\|LoginDemoModelTests\|packageDeclaresTheLockedTargetGraph'` | exit0；10 tests／3 suites，0.963s | `focused.log` |
| `swift test` | exit0；284 tests／36 suites，4.353s | `root.log` |
| `swift build --product RivetLoginDemo` | exit0；0.29s | `debug.log` |
| `swift build --product RivetLoginDemo -c release` | exit0；0.27s | `release.log` |
| `scripts/check-swift-format.sh` | exit0 | `format.log` |
| `swiftlint lint --strict Sources Tests packages/RivetHTTPClient/Sources packages/RivetHTTPClient/Tests` | exit0；136 files，0 violations | `scoped-lint.log` |
| `swiftlint lint --strict` | exit2；224 files，39 serious findings；不是 root lint pass | `root-lint.log` |
| 固定 baseline 外置副本 `swiftlint lint --strict` | exit2；37 findings。逐條與 current 的 experiments 37 完全相等，沒有舊檔 lint 回歸 | `baseline-lint.log`／`baseline-comparison.json` |
| `git diff --check` | exit0 | Tester 命令結果 |
| `node "$ARCHIFY/bin/archify.mjs" validate lifecycle docs/presentation/diagrams/rivet-login-ui/login-lifecycle.json --quality showcase --json` | exit0；9/9 checks、composition errors0／warnings0 | Tester 命令結果 |

Current 新增的2項 lint 僅為原樣封存 `prototypes/rivet-login-ui/RivetLoginView.swift`：line202 `line_length`、line449 `identifier_name`。七份封存素材逐一與 Human 提供的原件比較 bytes／SHA-256，全部一致；production／test scoped0。既有 `StaticIsolationTests.swift` diff 確認只增加兩行 expected-set entries，保留 equality 與其他隔離 assertions。

### 原生視窗與工具限制

- 實際程序 PID75501，限定本 topic 的外置 `.app` wrapper；NSRunningApplication 回 active=false、hidden=false、terminated=false。
- CGWindowList 實際主窗 ID175379：layer0、onScreen=true、alpha1，bounds x366／y127／width780／height532；controls ID175380：layer0、onScreen=true，x1162／y205／width310／height422。可見窗口存在，不能因 CUA 問題宣稱 host 沒有窗口。
- CUA `getState` 列本 app running；`getApp` 沒有回應達271秒後被中斷。未再反覆重啟或重試長選窗。
- `CGPreflightScreenCaptureAccess()` 回 false，只查詢、沒有 request。限定主窗 `screencapture -l 175379 -x ...` exit1：`could not create image from window`。
- 因此最新 `welcome-light.png`、`welcome-dark.png`、`waiting-dark.png`、`token-dark.png` 尚未取得；PAT Show／Hide focus、blank／Back cleanup、Cancel／Retry、controls、System／Light／Dark、Keyboard Navigation、resize／大字、Increase Contrast、Reduce Motion、VoiceOver 均無本輪實際操作通過證據。App 未被本輪關閉或重啟，其他使用者 app 未操作。

### 工具證據核對

- Graphify：限定 feature tree 搜尋沒有可用 code graph；以 `Package.swift`、Presentation input／View、Demo model／host 及 tests 的 targeted source reads 核實。未 build／extract／refresh／stamp／config／hooks；本輪無需新 CLI 呼叫。
- Archify：spec SHA `0dfd2300540111a32f8c540001509d48d8c81ee019ad94886412a9ba6f24427f`；HTML SHA `ff981c88f6ae8f92ca7cecae008a53ef27cf473ff3b1f21b05f40d7df85cb439`，與 BUILD／visual receipt 一致。重新 validate pass；凍結 HTML 未改、未無故重 deliver。核對既有四尺寸 containment receipt 全pass；獨立實看1440×900／2048×1320明暗四圖，無clipping／opaque-node crossing／文字遮擋，最大尺寸可讀。自動 `visualReview: pending` 原樣保留；此處記獨立人工實看。圖是七態假流程的概念摘要：PAT failure 重新填寫仍使用 `.failure(.token)` 表單，並非 model 自動轉 `.tokenEntry`；此抽象限制交 Reviewer 核對，不擴張成真登入。
- PR Lens：沒有真實 head commit，目前仍 pending；Tester 不捏造 SHA 或產 speculative map。由 Reviewer 先做 direct bounded diff review，再以真 commit 製作外置 change map。

### LU-01～11 矩陣

| ID | 本輪獨立結果 | 尚缺證據／責任 |
| --- | --- | --- |
| LU-01 | pending／tool-permission blocked | 四份最新真 native PNG 與參考對照。 |
| LU-02 | model tests pass，native pending | 七態真操作、Cancel／Retry／Reset。 |
| LU-03 | value-state tests pass，native pending | focus／Show-Hide、表單清除與failure重填實際操作。 |
| LU-04 | pending | System／明暗、inactive、高對比真檢查。 |
| LU-05 | pending | 真 resize／大字／Reduce Motion 與無水平捲動。 |
| LU-06 | pending | Keyboard Navigation 設定、真focus／AX／VoiceOver。 |
| LU-07 | source／dependency初查無真auth／network／storage新增 | 完整 exact-path／boundary review交獨立Reviewer。 |
| LU-08 | 自動項pass；rootlint baseline comparison符合契約；native驗收獨立pending | 不稱 rootlint0 或 GUIpassed。 |
| LU-09 | 無圖 source fallback已核實 | Reviewer核對導覽範圍。 |
| LU-10 | validate／hash／既有四尺寸receipt／獨立四圖實看pass | 概念抽象限制如上，Reviewer最終核對；未重跑capture。 |
| LU-11 | pending | 真實 base／head commit 後的 PR Lens，非 correctness approval。 |


## RV-01 P2 回修：第2輪圖面 handoff

Dispatcher交接獨立Reviewer verdict `needs-rework`，唯一required fix是PAT failure送出邊；production／tests沒有required fix。本輪只修 `token-retry` 為 `failed→checking`（failure內重填並送出直接verifyingToken），label `token：重填後送出`；七態與其他edge語義不變。為新edge的automatic port／label診斷設定其獨立下方corridor，submit限定straight避7px micro-segment，沒有source／產品flow改動。

重新validate／外置deliver 9/9、0errors／warnings；核對新spec／HTML SHA並samebytes copy，再對exact repository HTML執行visual-check exit0。四尺寸containment／readability／captures全pass；新版四張最小／最大尺寸明暗圖均已實看，`visual_review: passed`；`correction_rounds: 2`，額度已用完。當前hash／bytes及每次修正證據見BUILD；TE-01前節第1輪hash只屬舊版，不用來宣稱新版通過。

未重跑Swift，沿用獨立Tester已親跑的focused10／root284／debug／release／format／scoped0／baseline比較。Native四份screenshots、操作與accessibility仍pending；本輪沒有CUA／TCC操作。請交Tester只核新圖證據，再由Reviewerclose；本文件不冒造其approved或全部產品驗收通過。


## TE-02：新版 lifecycle 獨立複核（2026-10-22）

**TE-02 passed，僅限 RV-01 P2 的新版圖證據。** 本輪未修改 Swift／tests／凍結圖、未重跑 Swift、未呼叫 CUA、未 deliver 或重新 capture。TE-01 的自動驗證與 native pending 原樣保留。

- 直接核對 JSON `token-retry`：`from: failed`、`to: checking`、label `token：重填後送出`。這對應 `LoginDemoModel.handle` 在 token failure 表單送出後直接進入 `.verifyingToken`，不再誤畫 `.tokenEntry`；七態不變。
- 親跑 `node "$ARCHIFY/bin/archify.mjs" validate lifecycle docs/presentation/diagrams/rivet-login-ui/login-lifecycle.json --quality showcase --json`：exit0，9/9 checks，showcase errors0／warnings0。
- 新版 spec SHA-256 `769f2cbb3b249f9629a00397822a4b0d1dd505d7f26f39d9b5e234b5910c0701`；HTML SHA-256 `fe912937713f6f42286801317072d8774cae43d69b39e64f9644e021cf64ef4b`，與 BUILD／新版 visual receipt 一致；先前 TE-01 hash 僅屬歷史。
- 核對新版 receipt：四尺寸1440×900／1600×1000／1920×1080／2048×1320 containment、readability、captures 均pass；`visualReview: pending` 原樣保留，未冒充自動人工判定。
- 獨立實看新版1440×900／2048×1320 light／dark四張sidecars：重填送出邊進入 verifyingToken，label 清楚，沒有 clipping、opaque-node crossing 或文字遮擋；最大尺寸可讀，無額外下方空白帶。
- `correction_rounds: 2` 依 BUILD 為已用盡；本輪沒有追加修圖。此為 Tester 複核結果，Reviewer 的 P2 close／整體 verdict 仍待獨立處理；native 四圖與互動並未因此通過。


## RV-01 close／IM-02 交付準備

Dispatcher正式交接RV-01 `approved`、唯一P2 closed、沒有其他required fix。Bounded source／tests及第2輪圖契約／receipts可供Draft PR交付；Native四PNG、實際互動與AX驗收仍pending，不能因此推導Human採用。TE-01親跑focused10／root284／debug／release／format／scoped0及baseline lint比較、後續新圖獨立核對結果保留。

IM-02開始前確認feature branch正確、dev worktree仍dev且clean，32個Written與4個Modify共36實際檔符合exact allowlist；四PNG缺項如實保留，不stage外置scratch。依Human直接授權準備topic commit／push；本節寫入時尚未執行，不預填成功或SHA。


Staged whitespace檢查補充：Git將無binary marker的合法向量PDF辨識為文字，標準`git diff --cached --check`只對PDF xref表5行必要fixed-width padding報trailing whitespace；PDF bytes沒有改寫。以外置attributes只將該精確PDF路徑標binary，單次`git -c core.attributesFile="$TOPIC_SCRATCH/pdf-binary.attributes" diff --cached --check`檢查其餘完整staged diff；不寫repo／global attributes或config。BUILD EOF空白已最小修正。


第一次commit嘗試尚未產生commit：pre-commit的trim／EOF／Swiftformat／GitHubIntegration consumer／SwiftLint通過，renderer-check因featureworktree未安裝既有依賴、`biome: command not found` exit127停止。依既有frozen bun.lock在feature renderer執行 `bun install --frozen-lockfile --ignore-scripts` exit0，僅補node_modules（Biome2.5.10／TypeScript6.0.3／diff2html3.4.56）；manifest／lock／hook tracked bytes未變。沒有SKIP／no-verify、沒有安裝或改動Graphify／PR Lens runtime。之後重新完整commit hooks，不將失敗嘗試記成成功。
