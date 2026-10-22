# Rivet 登入 UI：IM-01 自我驗證

2026-10-22；branch `feat/rivet-login-ui`；base `14d0832f042720889993d769b4cbfb720078e6b1`。所有寫入僅在已授權 feature worktree。IM-01初始尚未commit／push／PR；目前code commit與發布停點以下節為準。本文保留Implementer歷史及獨立Tester／Reviewer交接，不混同各角色verdict。

## Draft PR 交付／Human review（目前狀態）

RV-02正式`approved`／required fix `None`，Show／Hide focus defect closed；TE-04最終source的Show／Hide四次＋rapid4、Back／Reset／submit departure與canonical Return／Escape，以及新版四份真native圖已獨立通過bounded驗證。完整Tab／Shift-Tab traversal、VoiceOver實際朗讀／announcement、大字、IncreaseContrast與ReduceMotion啟用條件仍pending Human。公開payload授權與成果採用分開；Human尚未決定採用。

IM-04已完成commit `6fc18b3c040997155d84ca85abba48abc1a61d6c`（`fix(presentation): 保留 PAT 顯示切換後的輸入焦點`），精確7檔，完整hooks全passed。Human明確同意將程式／測試／原始素材／文件圖面公開到`a129924/rivet`後，正常非force push成功，`ls-remote`精確feature branch SHA與該commit一致；舊兩次自動拒絕保留為歷史，不再是blocker。

GH-01由Dispatcher透過connector建立並attach [Draft PR #66](https://github.com/a129924/rivet/pull/66)：draft=true、base=`dev`（建立時API SHA `613a505025774b3841ab73b4ed3b8774be38274a`）、source head=`6fc18b3c040997155d84ca85abba48abc1a61d6c`。目前交HC-01 Human review，沒有merge／release；本輪只補兩份metadata，不再改source、tests、四張native PNG或凍結Archify。後續metadata commit不在自身文件預填SHA。

### PL-02：實際 PR source 變更圖

獨立Reviewer依真PR base `613a505025774b3841ab73b4ed3b8774be38274a` → source head `6fc18b3c040997155d84ca85abba48abc1a61d6c` 完成本地map；三點diff merge-base=`14d0832f042720889993d769b4cbfb720078e6b1`，共40files。Pinned CLI0.11.0 validate／render均exit0；1view／4lanes／10nodes／12edges／6steps，23個file refs已對exact source head核對。只核source／manifest與SVG XML labels，沒有raster實看，map不取代correctness review。

- Graph SHA-256：`188661884b6a923cfaae627816d16931c1bf8f19485d64433799fb55f45ee1cb`；contentHash=`ada650d6d967b53c01374cd8dc692432`。
- SVG：18851bytes、1708×596；contentHash=`c4f3346b5587256a984bf8c43a58a932`。
- 外置位置：`$TOPIC_SCRATCH/pr-lens/6fc18b3/graph.json`、`SOURCE.md`、`rendered/manifest.json`、`rendered/login-ui-change-light-c4f3346b5587256a984bf8c43a58a932.svg`。未上傳或發布map。
- 此map明確bounded於source `6fc18b3`，不包含本輪後續兩份metadata變更，不能冒稱最終metadata head map；不為metadata自參照重產圖。

## RV-02 後交付準備（歷史）

Dispatcher交接獨立RV-02正式`approved`、required fix `None`：TE-03 Show／Hide焦點缺陷已closed。TE-04已獨立親驗最終source／debug與wrapper binary SHA一致、Show／Hide四次＋rapid4保值／focus、Back／Reset／submit departure與canonical Return／Escape；新版四份1×原生PNG及IM-03／TE-04 logs已核對。Public API／七態／PAT清除不變。完整traversal、VoiceOver實際朗讀、大字、IncreaseContrast／ReduceMotion啟用條件仍pending Human，不把bounded通過當全部原生驗收或UI採用。

Human直接明確回答公開範圍與目的地：同意將`feat/rivet-login-ui`的程式、測試、原始素材及文件／圖面公開推送至public `a129924/rivet`，並以`dev`建立Draft PR。下方兩次auto-review拒絕只屬先前歷史，這次具有新增明確公開payload授權，依原`commit by topic → push → Draft PR → Human review`執行，不重問已回答事項。

本輪只準備一個focus修正topic commit：精確stage View、兩份交付紀錄及四份真nativePNG共7檔，message為`fix(presentation): 保留 PAT 顯示切換後的輸入焦點`；完整hooks保留。七份原始素材、frozen圖面與resources均未改。發布前feature仍為`feat/rivet-login-ui`／HEAD`3a5a87bffc099ffd5e5f80c5ef0f8cc4073ca52f`；dev worktree仍`dev`且clean，外部已前進至`613a505025774b3841ab73b4ed3b8774be38274a`，本topic不rebase／merge或修改dev。此段不預填新commit／push／PR成功；push結果交正式發布步驟，PR由Dispatcher後續建立。舊PL-01 map僅含`98f0573`，新head map待獨立更新，不能冒稱最終head provenance。

## 前輪本地交付與發布停點（歷史）

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


## TE-03：真原生畫面與有限互動驗收（2026-10-22）

**Verdict：needs-rework；required fix 為 PAT Show／Hide 失去編輯焦點。** 本輪完成四張真原生 PNG、七態假流程與 PAT 主要操作；沒有宣稱全部 native／accessibility passed。前輪工具限制是當時歷史，不能套用成目前無權限；本輪 evidence 也不回寫成先前已通過。

### 環境、來源與取證方式

- 沿用 code `98f057324419d33926850d926483080c3f3ca633`、交付紀錄 HEAD `3a5a87bffc099ffd5e5f80c5ef0f8cc4073ca52f` 的既有外置 Demo wrapper，沒有重建、重啟或修改 production／tests。既有 PID75501，主窗175379、controls175380。
- 單次唯讀 preflight：`CGPreflightScreenCaptureAccess()=true`、`AXIsProcessTrusted()=true`；`AXWindows` status0，可讀兩個正確標題。未 request TCC、修改全域設定或讀取其他 app。
- 使用外置 Swift AX helper，僅作用上述 PID；AXPress／AXValue／AXFocused／AXMain 與 target-PID CGEvent keyboard。Helper 的兩秒 messaging timeout、driver 八秒 subprocess timeout 保持有限操作。假輸入不寫入 log，tree 只輸出字數與 secure flag；不使用 clipboard、真 PAT、LLDB、產品測試 API、ImageRenderer 或 placeholder。
- 四圖使用 `screencapture -l 175379 -o -x <approved-output>`，只取 Demo 主窗、無 shadow，沒有桌面或其他 app。外置操作紀錄為 `$TOPIC_SCRATCH/native/te03-actions.jsonl`；額外 System／resize 真圖亦只留外置暫存，不是 repository 交付。

### 真畫面、尺寸與對照

四圖均已實看、與對應四份 PNG 並列。1560×1064 px 是 2× backing 的780×532 pt原生 frame，包含32 pt native chrome；參考為1560×1000 px，沒有把真圖縮放／裁切冒充同尺寸。最小窗40／60雙欄、品牌／dots／diff、GitHub mark、完整主文／按鈕／footer均可讀，未見遮擋或水平捲動。Light圖顯示原生focus ring；dark圖含inactive traffic lights，仍可讀。

差異如實保留：系統字體／行距及原生chrome使右側標題、CTA、footer垂直位置與參考不同；Welcome dark操作區比該參考較深，waiting／PAT使用同一深色palette；footer改為明示simulation、不存憑證，PAT建立連結disabled，waiting模擬返回移至controls。這是可審查的原生近似，不宣稱pixel-perfect或Human已採用。

| PNG | Pixels | SHA-256 |
| --- | --- | --- |
| `welcome-light.png` | 1560×1064 | `cd578abb3edd5e3edc6c4ed13c13142d840d5a2d14ced1c500c357584d2f3863` |
| `welcome-dark.png` | 1560×1064 | `c6e4eff6aa71ce13ee014a32552c8fa66c1b4d19d46782461213c5d03eb3b061` |
| `waiting-dark.png` | 1560×1064 | `f6e015d5bd2f71488186e5534913394de784150b8552d342913becf31d20b663` |
| `token-dark.png` | 1560×1064 | `ca911b852b2fc85ad99a417a7d757653be570f168ec748a1027453178e338f9b` |

### 已觀察的互動結果

- Browser：真AXPress primary→waiting；Cancel→welcome且無error；controls模擬return→verifyingAccount→complete→connected。Simulate failure後可達browser failure，Try again→waiting，Cancel／Reset可回welcome。Connected顯示模擬完成而停留，非真account連線。
- PAT：空字串與全空白時Connect disabled；帶外圍空白的非prefix假字串使Connect enabled並進verifyingToken。精確trim仍由既有value-state test支持，native不觀測intent payload；不把UI eligibility當trim內容證明。
- PAT failure：submit後欄位清空／回hidden，complete failure仍保留可重填表單、錯誤訊息及disabled空白CTA；重填後直接verifyingToken，再完成success。Back→welcome→重進與Reset→重進均為空白hidden。沒有傳送或保存憑證。
- Show／Hide字數保持，secure flag true→false→true；**編輯focus未保留，required fix如下**。
- Controls：System／Light／Dark均可選；System radio value1、對應當前dark系統；明暗真圖已取。非適用狀態的return／complete顯示disabled；native不再強送無法由使用者觸發的disabled action，stale／duplicate由既有model tests支持。
- AX：正確heading／button／link／secure text field label與disabled unavailable help可讀；decorative品牌／diff不出現在main tree。這只證明AX結構，不代表VoiceOver實際朗讀／announcement去重已驗證。
- Resize：AXSize設定1000×680 pt成功，真圖2000×1360px已實看，布局延展、footer可讀無clip／水平捲動；要求700×400時被限制為780×532frame，真圖1560×1064px。最後恢復780×532並Reset，app保留執行。

### Required fix：Show／Hide focus

精確復現：主窗設AXMain、app `active=true`、focusedWindow=`Rivet Login Demo`；先聚焦並輸入假PAT，`focusedRole=AXTextField`／field `AXFocused=true`。AXPress Show後字數保持19、secure=false，但focusedRole變成AXWindow、field AXFocused=false；Hide後字數仍19／secure=true，focus仍AXWindow。首次操作與一次明確主窗復核一致。

對應 `Sources/Presentation/Login/RivetLoginView.swift` 的tokenField（line125–143，切換與focus assignment在138–140）；可能是SecureField／TextField替換而FocusState維持相同值，這是待Implementer確認的原因推論，不是已測內部因果。需在既有View內bounded修正並由Tester重驗真focus；不增加全域keyboard攔截或產品測試API。本Tester未改production。

### 鍵盤觀察與剩餘條件

- 唯讀系統條件：AppleKeyboardUIMode=0、IncreaseContrast=false、ReduceMotion=false。沒有切換全域Keyboard Navigation／高對比／減少動態效果，故這些啟用條件及大字仍pending。
- 明確app active／main window下，target-PID Return成功welcome→waiting；target-PID Escape兩次均未離開waiting，而AXPress Cancel正常回welcome。這是**需調查的鍵盤觀察**，不是已鎖定的普遍硬體Escape缺陷；需按既有cancel語意確認，不自行擴張scope。
- PAT進入時一輪focusedRole為AXGroup；手動聚焦欄位後首個Tab仍為AXTextField，後續因app active變false而停止判讀，Shift-Tab同樣不宣稱通過。Mode0下不強推所有button可Tab為契約；完整traversal／自動落點仍pending。
- 沒有啟動VoiceOver；真朗讀、announcement、IncreaseContrast=true、ReduceMotion=true、大字條件仍pending。不得以AX tree、build或既有model tests代替。

### LU-01～06 本輪狀態與交接

| ID | TE-03 結果 | 缺口／下一步 |
| --- | --- | --- |
| LU-01 | 四份真native圖已取、實看與對照completed | 尺寸／palette／字階差異如上；交獨立Reviewer／Human判讀，不宣稱pixel-perfect。 |
| LU-02 | 七態／browser與PAT成功失敗／AXCancel／Retry／Reset native pass | Target keyboard Escape觀察待確認；stale／duplicate沿用model tests。 |
| LU-03 | eligibility／nonprefix／保值／清空／failure重填pass；focus needs-rework | Show／Hide焦點required fix；exact trim沿用value-state tests。 |
| LU-04 | System／明暗與inactive真圖可讀 | IncreaseContrast=true pending。 |
| LU-05 | resize／min constraint真圖pass | 大字／ReduceMotion=true pending。 |
| LU-06 | AX roles／labels／decorativehidden已核 | Show／Hide required fix；Escape觀察、完整traversal、自動落點／VoiceOver仍待驗。 |

LU-07～11沿用既有獨立證據，本輪不重跑Swift／Archify／Graphify／PR Lens。Human公開push授權已明確，但不等於UI成果採用；先交獨立Implementer焦點修正與Tester回歸，再交Reviewer。四圖只證本輪上述來源，不能冒稱後續fix的新版圖。


## IM-03：Show／Hide bounded focus 修正與自驗（2026-10-22）

TE-03 的真原生 red 保留。僅修改既有 `RivetLoginView.swift`：SecureField／TextField 各用不同私有 focus identity，切換後的 `.task(id: token.showsToken)` 先 `await Task.yield()` 讓舊 control 完成 resign，再於未取消時將 focus 交新欄位。不新增 public API／檔案／測試 harness／全域 keyboard 攔截，PAT value／clear／intent 與七態不變。Cancel 原本已有 `.keyboardShortcut(.cancelAction)`；本輪不因尚未釐清的 Escape 觀察改動 Host 或其他 keyboard routing。

- 有界 attempt 1：不同 identity＋立即 task assignment 的自驗仍 red；active=true，Show／Hide 後 focusedRole=AXWindow，值長19保持。保留外置 `native/im03-focus-attempt1.json`。
- 有界 attempt 2：加入一次 `Task.yield()` 與 cancellation guard 後，自驗 secure→visible→secure 三階段均 active=true、focusedRole=AXTextField、field AXFocused=true，secure true→false→true、valueLength均19。外置 `native/im03-focus-attempt2.json` 只記字數與 AX status，不含假輸入文字。這是一輪 Implementer 自驗，不取代 Tester 獨立回歸或完整 accessibility 驗收。
- Demo 沿用既有外置 wrapper；核對唯一 executable 後停止舊程序再重啟，僅換 Demo binary／必要 Presentation resources，沒有平行新 instance／TCC／全域設定操作。最後 PID=36729，主窗已返回 Welcome。
- 修正 source SHA-256：`4a1100d712eb15beb97b7eef824e043e3874e6ef5f55f6aea8d1b0c1d5e11cfb`（12820 bytes）；自驗 wrapper binary SHA-256：`1009d4464106663e8ab554082ef7faea9d79adf80474f9a65c7677845731b873`（2471344 bytes）。

| 最終 source 自驗命令／項目 | 真結果 | 外置 log |
| --- | --- | --- |
| `swift test --filter 'RivetLoginPresentationTests\|LoginDemoModelTests\|packageDeclaresTheLockedTargetGraph'` | exit0，10 tests／3 suites，0.563s | `native/im03-focused.log` |
| `swift test` | exit0，284 tests／36 suites，3.543s | `native/im03-root.log` |
| `swift build --product RivetLoginDemo` | exit0 | `native/im03-debug.log` |
| `swift build -c release --product RivetLoginDemo` | exit0 | `native/im03-release.log` |
| `scripts/check-swift-format.sh` | exit0 | `native/im03-format.log` |
| `swiftlint lint --strict Sources/Presentation/Login/RivetLoginView.swift` | exit0 | `native/im03-lint.log` |

上述 paths 均相對於既有 topic scratch；不加入 repository。Root strict lint 未重跑，沿用既有 baseline findings 分類，沒有宣稱全局0。四份 TE-03 PNG 是修正前畫面，需 Tester 對最終 source 回歸 focus 與必要新 capture；Escape／完整 traversal／VoiceOver／大字／對比與 motion 啟用條件仍依 TE-03 缺口處理。本輪未 commit／push／建立 PR，不宣告 Reviewer approved 或 Human 採用。Lifecycle 狀態／intent 沒有改變，不重畫圖。


## TE-04：最終 focus 修正獨立原生回歸（2026-10-22）

**TE-04 bounded regression passed；交獨立 Reviewer 判定 required fix close。** 本輪只親驗最終修正焦點／departure、canonical Return／Escape與新版四圖；TE-03其他passed項目保留，不宣稱完整accessibility或Human採用。沒有重跑Swift／Archify／PR Lens，也不把IM-03自驗冒作本輪親跑。

- 實際PID36729，新主窗176692／controls176694；最終source SHA `4a1100d712eb15beb97b7eef824e043e3874e6ef5f55f6aea8d1b0c1d5e11cfb`。親核wrapper與debug binary均SHA `1009d4464106663e8ab554082ef7faea9d79adf80474f9a65c7677845731b873`，沒有重建或改產品。
- 明確active=true、focusedWindow=主窗、假輸入字數19；Show→Hide→Show→Hide四次均focusedRole=AXTextField、AXFocused=true。Visible值精確相等；Secure AXValue是遮蔽值，只以字數19及下一次visible精確相等共同驗保值，不把secure的`matchesExpected=false`誤當值遺失。
- 再有界rapid4切換，末態hidden／AXFocused=true／字數19；回visible後精確相等。切換緊接Back、Reset及submit後，分別仍welcome、welcome、verifyingToken且無textfield，不被已離開的task拉回；Back／Reset重進為空白hidden、欄位AXFocused=true。Departure部分status出現app inactive，因此只據實判無殘留欄位／狀態回跳，不推論inactive下所有自動落點。
- Canonical鍵盤helper使用private CGEventSource、flags0、keyCode36／Unicode13（Return）、keyCode53／Unicode27（Escape），明記down／up字元並target PID。兩組Return→waiting、Escape→welcome均成功；第一組全程active=true，第二組Escape前active=true、結果welcome後active=false。TE-03舊Escape觀察保留為先前合成事件語義不足，不能反推舊產品keyboardbug；本輪無keyboard routing改動。
- 外置紀錄為 `$TOPIC_SCRATCH/native/te04-actions.jsonl`；僅儲存AX布林／字數與公開文案，不存輸入。最後Reset welcome、原窗尺寸，Demo仍執行；沒有操作其他app、TCC、clipboard或全域設定。

四份正式PNG已以新主窗原生`-l 176692 -o -x`重取，並與四份來源圖逐一實看；PAT為空白hidden，沒有真token。當前螢幕backing為1×，**780×532 px = 780×500 content加32pt原生chrome**，沒有resample／放大／裁切補成前輪2×尺寸。四檔現bytes代表TE-04；TE-03表中hash只屬修正前歷史。新版Welcome CTA與PAT欄位可見focus ring，其餘雙欄／字階／配色／品牌／完整footer無新增遮擋；與參考的palette、原生字體／垂直位置、simulation文案差異沿用TE-03，仍非pixel-perfect或Human採用。

| 新版 PNG | Pixels | SHA-256 |
| --- | --- | --- |
| `welcome-light.png` | 780×532 | `c0c50d6fc814fa404f8614f9caa1c69295885de61f58e37aea12b38e0c2eaf47` |
| `welcome-dark.png` | 780×532 | `62cea3f7a37f16da9f08e397ace5d1316c5aa6e13e00a2d3ed5eade44042dac0` |
| `waiting-dark.png` | 780×532 | `a51e20940eb79db918274ea69eae647fb817da60f3fd6dae24ab296210a62b29` |
| `token-dark.png` | 780×532 | `607a0b522e965c160639e649aa1540718c1c72a3a14321ec9ccd07151f55bfdb` |

LU-03 Show／Hide焦點required fix的**Tester回歸已passed**，等待Reviewer close；LU-02 canonical Return／Escape passed。LU-01新版四圖取證／實看completed；LU-04／05／06特殊條件仍分項pending：KeyboardUIMode0、IncreaseContrast=false、ReduceMotion=false未改，完整Tab／Shift-Tab traversal、VoiceOver真朗讀／announcement、大字與對比／motion啟用條件沒有冒稱通過。IM-03自驗focused10／root284／build／format／scoped0沿用其來源；本輪不預填Reviewer或push／PR結果。

Human本輪已明示「可以開始原生驗收」，並明確同意將本topic程式、測試、原始素材及文件／圖面公開推送至`a129924/rivet`、以`dev`建立Draft PR；原auto-review拒絕是保留歷史，公開payload問題已回答。成果採用仍交Human review。
