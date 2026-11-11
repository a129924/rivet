# Rivet 登入 UI：IM-01 自我驗證

2026-10-22；branch `feat/rivet-login-ui`；base `14d0832f042720889993d769b4cbfb720078e6b1`。所有寫入僅在已授權 feature worktree。IM-01初始尚未commit／push／PR；目前code commit與發布停點以下節為準。本文保留Implementer歷史及獨立Tester／Reviewer交接，不混同各角色verdict。

## RV-06 approved／待topic交付與Human兩入口（目前狀態）

Dispatcher正式交接獨立RV-03 `approved`、required source fix `None`。TE-05已完成partial verification：新版自動檢查、三真入口可觀察互動、13／17／21 pt五畫面及捲動可達性；主對話Tester操作CUA，本Tester獨立實看18份外置raw JPEG，精確來源與padding限制見TE-05。這些不是VoiceOver真朗讀、Human新版大字或rapid departure通過，HC-02三缺口不closed，HC-01／HC-03仍pending；原binary七類Human通過保留其來源。

IM-06已完成source commit `9f8955c40696cee6d77739da6d22d659287cfbc0`（`fix(presentation): 修正登入宣告與大字驗收`），精確13檔、全部hooks passed；正常public push與ls-remote同SHA。IM-09的View現為waiting語義修補working diff，其餘六個Swift檔保持已發布bytes，新debug／release實測SHA見IM-09；四canonical PNG／18份新raw JPEG來源與限制不變。PL-03已獨立完成，Draft PR #66維持target dev；HC-03 PAT兩次未通過；Human另明確回「有，其他項目會朗讀」，不是全系統無聲。PR-04／RV-04限定approved後HC-04唯一診斷case已完成，Human回「讀出驗證中」；34筆實際trace顯示同case post路徑完成、無early return。預算1／1已用，診斷logging不當功能修法；PR-05正式approved後IM-08已外置封存並移除自身探針，正常版經TE-07獨立preflight partial完成，RV-05已正式approved／required None，僅放行HC-05一次Human前景Return；本次Human在明確正常版步驟後回「讀出驗證中」，CUA確認verifyingToken，HC-05 completed-observed有聲、1／1已用。HC-01／HC-03與三缺口不closed，詳文末HC-05。

## IM-05 自驗完成／待獨立補驗（歷史）

Dispatcher正式交接PR-03 `approved`、required fix `None`後，已完成PC-03限定的phase焦點／宣告協調與13／17／21 pt真字級入口；新自動結果見文末IM-05。尚未操作新版原生UI／VoiceOver或取得新Human朗讀／大字結果，HC-02三缺口仍open，HC-01／HC-03 pending；不能將自驗當三缺口closed。HC-02原binary七類Human通過與完整原文限制保留如下。

## Human partial／needs-rework（2026-11-04 HC-02交接歷史）

Human最新完整交接明示「本輪尚未全面通過」，七類通過結果保留；PAT驗證中的自動宣告、等待授權的兩入口自動宣告、大字驗收方法三項仍未解決。HC-01採用決策維持pending，最新上游verdict為Human `needs-rework`；不因既有RV-02 approved、公開授權或Draft PR交付而宣稱全部原生驗收通過。詳細來源、通過範圍與缺口見本文末HC-02。

本輪只回寫Human／主對話Computer Use交接證據，不改source／tests／素材／四PNG／圖面，不操作UI或系統設定，不commit／push／改PR。後續先交Explorer合併檢查兩項宣告的焦點／時序，並查明macOS大字來源及可靠測法；尚未選定修正設計、取得新測試結果或新增approval。既有focused10／root284／debug／release／format／scopedlint／hooks成功限各自舊來源，本輪未重跑；root strict lint仍非零，不列通過。

## Draft PR 交付／Human review（2026-10-22 歷史）

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


## HC-02：Human 實測完整交接（2026-11-04）

**Human partial／needs-rework；尚未全面通過，HC-01 pending。** 2026-11-04是本輪交接與正式證據回寫日期，各項實際操作日期／時刻未另提供，不補造時間。來源為主對話最新Human原文「RivetLoginDemo Human review 完整交接」，由Dispatcher完整轉交；結果來自Human實際回報與主對話Computer Use核對。本Implementer只記錄該來源，未在本輪重新操作或親驗，不把既有AX tree當成Human朗讀證據。

### 受測版本與證據邊界

- Human交接的受測binary SHA-256：`1009d4464106663e8ab554082ef7faea9d79adf80474f9a65c7677845731b873`，與既有TE-04記錄相同；本輪沒有重新build或改source。回寫前feature HEAD為`6dc04b81834eb8008ed59aebb142771e40d0116f`且clean；僅在原feature worktree回寫兩份文件。dev外部已前進`758aca9bb518f2a21f20f47609335fac49043370`，本輪不修改dev。
- 暫存App包曾遺失，已修復並使用相同執行檔重啟後才進行本輪驗收；Human交接明示該側沒有修改程式碼或Git。不把此事件推論為產品或source回歸。
- 舊focused10 tests、root284 tests、debug／release、format、scopedlint及hooks曾通過，保留原版本與執行來源；本輪未重跑。Root strict lint非零，仍不列通過。
- 四份既有native PNG與Archify bytes未更新；本輪Human文字結果不能冒稱新增截圖、錄音或工具log。PL-02仍只對既有source `6fc18b3`，不重算或擴稱本輪證據。

### 七類 Human 通過紀錄

| 類別 | Human實際回報及適用範圍 |
| --- | --- |
| 鍵盤操作 | 主對話先前已確認Tab／Shift＋Tab、Return、Escape與失敗重試通過；保留該Human回報，不外推到未驗控制項或所有系統條件。 |
| Welcome VoiceOver | 主標題、說明、GitHub按鈕、PAT連結與footer可朗讀，角色正確、前後巡覽正常；左側裝飾略過，沒有多餘朗讀。 |
| PAT VoiceOver／Show-Hide | 欄位名稱與安全輸入角色正確；隱藏時沒有朗讀完整內容；Show／Hide保留內容與編輯焦點，能繼續輸入。此通過不包含下列PAT verifying自動宣告缺口。 |
| 其他狀態宣告 | 帳號驗證中與完成提示通過；失敗提示在重跑後由Human確認正確訊息。第一次未確認state的觀察另保留如下，不推定為偶發bug。 |
| 失敗與取消 | Try again與PAT入口角色可讀；VoiceOver啟用時重試能進入等待。Escape返回Welcome並自動朗讀主按鈕。此通過不表示等待狀態的自動宣告通過。 |
| 高對比 | Light／Dark的Welcome、PAT，以及PAT Failure／Connected檢查均清楚；焦點、邊界、停用狀態、文字及圖示可辨識，未回報遮擋或截斷。 |
| Reduce Motion | 等待／返回、PAT編輯、Show／Hide、送出驗證、失敗與Connected展示切換均平穩，操作正常。原生進度圈仍旋轉只列觀察，尚未判為缺陷。 |

### 三項缺口與補驗目標

| ID | 已觀察結果 | 後續目標與目前限制 |
| --- | --- | --- |
| HC-02-G1 | PAT送出確實進入驗證中，自動只聽到`scroll area`；手動進入捲動區後標題可以朗讀。 | 無需手動尋找即可理解正在驗證，焦點符合既有spec。先查焦點與宣告時序，原因及修法尚未判定。 |
| HC-02-G2 | 從Welcome進入等待只讀展示版不能連接GitHub的說明；從失敗重試進入等待只讀通用footer。 | 兩入口都明確告知正在等待授權，並保留Cancel／Escape可操作。與G1合併調查，不把已通過取消操作當宣告通過。 |
| HC-02-G3 | 系統調到13／15點時，Human確認Codex變大，但Demo沒有變大；大字排版未能驗證。 | 先釐清macOS字級來源、大字支援目標與可靠測法，再決定是否及如何實作，以真正放大字級確認表單、footer、捲動與操作可達性。既有`ScaledMetric`不是系統文字大小整合完成的證據。Human提供[Apple Dynamic Type文件](https://developer.apple.com/documentation/swiftui/environmentvalues/dynamictypesize)供Explorer後續查驗，本輪尚未據此作技術結論。 |

### 保留的辨識限制與環境還原

- 失敗宣告第一次未聽到時，尚未確認進入Failure；工具當時讀到Welcome。之後重跑，Human明確確認正確失敗訊息。兩次紀錄均保留，不猜測為偶發產品bug，也不以第二次通過改寫第一次state不明的事實。
- Human使用CapsLock＋方向鍵巡覽，以CapsLock＋Shift＋↓進入捲動區。工具背景送鍵沒有產生朗讀的結果，不作為產品缺陷證據；不混同真Human前景操作。
- 依Human交接，環境已還原：系統文字大小預設；增加對比、減少透明度、Reduce Motion、VoiceOver均關閉。Demo為System／Welcome、模擬失敗關閉、Failure origin為Browser。這是交接狀態，本輪文書工作未更動UI或系統設定。

### 後續 bounded 交接

先交Explorer合併調查G1／G2焦點與宣告時序，並查明G3字級來源／支援目標／可靠驗法，再依既有contract交bounded Implementer處理。完成適當自動檢查後，由獨立Tester補驗三缺口與必要focus回歸，交Reviewer獨立審查；本輪不預填任何修法、執行結果或approval。保留七類Human通過及舊自動／native證據的來源限制；三缺口未補驗完成前HC-01不全面通過。Git交付仍受既有授權與topic流程約束，本次不commit／push／改PR，也沒有merge／release授權。


## IM-05：PC-03 bounded實作與自驗（2026-11-04）

PR-03由獨立Plan-Reviewer正式`approved`／required fix `None`，經Dispatcher明示交接後才實作。改動限既有View／Presentation data／Previews、Demo Host／Model、兩測試檔及登入說明；不增檔、不改七態／intent、manifest、原素材／四nativePNG／凍結Archify或其他BC。Graphify限定重查仍無codegraph，沿source fallback，未刷新或建圖；本輪不產PR Lens，舊PL-02不代表新source。

- View以phase對應accessibility identity與 `.task(id: phase)` 分序處理keyboard focus、AX focus與announcement；每次await後檢查cancel與目前focus phase，Show／Hide task也檢查表單仍有效。保留既有落點、PAT清除、Cancel／Escape與medium通知priority；不用任意sleep或全域鍵盤攔截。source時序候選未冒稱唯一已證root cause，真聲音去重／過期宣告仍待native／Human。
- 新 `bodyPointSize: CGFloat = 13` 位於onIntent前；finite clamp13...21、非finite回13。右側實際font同ratio，移除ScaledMetric／Dynamic Type大字假設；Controls三選一傳真point size、改size不重建form、Reset保留size，Preview同入口。長期說明明示系統文字大小偏好整合未交付。
- TDD red先在兩既有test檔寫行為，真exit1來自缺新Typography／textSize symbols；green後字級正常化、邊界／非finite、model三字級變更保留phase／form identity及Reset保留通過。這不驗證View內PAT實際保值或AX／聲音。首次scoped lint唯一complexity finding以兩個View私有focus映射消除，沒有放寬rule。

| 本輪實跑 | 真結果 | 外置log檔名 |
| --- | --- | --- |
| TDD red | exit1，缺尚未實作symbols | `rivet-login-ui-im05-red.log` |
| Focused＋target graph | exit0，15 tests／4 suites，0.584s | `rivet-login-ui-im05-focused.log` |
| Root tests | exit0，289 tests／37 suites，3.681s | `rivet-login-ui-im05-root.log` |
| Demo debug／release | 均exit0，1.30s／4.49s | `rivet-login-ui-im05-debug.log`／`rivet-login-ui-im05-release.log` |
| Swift format／7檔scoped strict | 均exit0，scoped0 | `rivet-login-ui-im05-format.log`／`rivet-login-ui-im05-scoped-lint.log` |
| Root strict lint JSON | exit2，39＝37未改experiments＋2原樣scaffold，無production／tests finding；非通過 | `rivet-login-ui-im05-root-lint.json`／`rivet-login-ui-im05-root-lint.stderr.log` |

Logs與 `rivet-login-ui-im05-fingerprints.json` 均在repository外的OS暫存根，不入staged diff。新View SHA-256=`89cb23c412b7d9e2b5ecefe0e1b0123731e2b4d96cfafaf366126527afc980a5`；debug binary SHA=`9a2828a1fee54b5dfaeba1bce72f98a675192599a5ebdc61959c072ed11cce87`（2576960bytes），release SHA=`22c098851583db8bfeab3c63f3f9fcf9d8c633c73077eae729550410bf6e4cdf`（1272064bytes）。既有外置wrapper仍存在、binary仍為HC-02的 `1009d4464106663e8ab554082ef7faea9d79adf80474f9a65c7677845731b873`；本輪未改wrapper或啟動UI，Tester啟動新版前須核對並換入新debug binary／既有Presentation resource bundle。

此為Implementer自驗完成交TE-05／RV-03，不宣告其結果或approval。本輪未stage／commit／push／改PR、未跑hooks、未操作全域設定或要求TCC；HEAD仍為`6dc04b81834eb8008ed59aebb142771e40d0116f`而source為受限working diff。Human依HC-03逐項親聽PAT submit、Welcome／Retry進waiting、實看13／17／21 pt及必要focus回歸；每項等待回報，未取得前HC-02三缺口不closed，HC-01不全面通過。


## TE-05：PC-03 修補的獨立驗證（2026-11-04）

PR-03 `approved`／required fix None與IM-05明示完成交接由Dispatcher提供；本節不替代RV-03或HC-03。**TE-05完成partial verification：自動檢查、原生可觀察互動及字級／排版證據通過；三真入口聲音與新版大字Human親驗仍pending，不宣稱三缺口closed。** HC-02七類Human通過仍只限舊binary，三缺口未因source／tests通過而closed，HC-01／HC-03 pending。

### 本Tester親跑：自動檢查及來源

基於feature HEAD `6dc04b81834eb8008ed59aebb142771e40d0116f` 加本次受限working diff，未改source／tests或planning contract。自動logs集中於 `$TOPIC_SCRATCH/tester-te05/`，只在外置暫存保存；沒有重跑或改動凍結Archify、原素材或PR Lens。

| 獨立命令 | 實際結果 | Log |
| --- | --- | --- |
| `swift test --filter 'RivetLoginPresentationTests\|RivetLoginTypographyTests\|LoginDemoModelTests\|packageDeclaresTheLockedTargetGraph'` | exit0；15 tests／4 suites，0.575s；含字級finite／邊界／非finite與model表單identity／Reset保留 | `focused.log` |
| `swift test` | exit0；289 tests／37 suites，3.700s | `root.log` |
| `swift build --product RivetLoginDemo` | exit0；build0.27s | `debug.log` |
| `swift build --product RivetLoginDemo -c release` | exit0；build0.24s | `release.log` |
| `scripts/check-swift-format.sh` | exit0 | `format.log` |
| `swiftlint lint --strict Sources Tests packages/RivetHTTPClient/Sources packages/RivetHTTPClient/Tests` | exit0；136 files，0 violations | `scoped-lint.log` |
| `swiftlint lint --strict` | exit2；224 files，39 serious findings，**不是rootlint pass** | `root-lint.log` |
| `git diff --check` | exit0 | `diff-check.log` |

39項全部為既有experiments37＋原樣封存prototype2，其他0；九個finding files逐檔bytes與目前HEAD完全相等。七份原素材逐檔與HEADbytes一致，沒有修舊finding或原素材。分類與比對保存在 `root-lint-classification.json`，不以scoped0冒稱root0。

親核凍結source `Sources/Presentation/Login/RivetLoginView.swift` SHA `89cb23c412b7d9e2b5ecefe0e1b0123731e2b4d96cfafaf366126527afc980a5`；debug binary SHA `9a2828a1fee54b5dfaeba1bce72f98a675192599a5ebdc61959c072ed11cce87`；release SHA `22c098851583db8bfeab3c63f3f9fcf9d8c633c73077eae729550410bf6e4cdf`，均與IM-05來源相符。

### 本Tester親核：既有wrapper換版

舊bundle為唯一已識別的`local.rivet.login-ui-demo`／PID75968，binary為舊`1009d446…`。主對話Tester用CUA選定該app並點Quit menu，回報`procNotFound`；本Tester另以限定ps親核舊PID已結束後，才把feature debug binary與對應Presentation resources複製到既有外置wrapper，不建立新app、平行instance、簽章或bootstrap。Human先前恢復的資源原位置是`Contents/Resources/Rivet_RivetPresentation.bundle`；依該既有位置更新。Wrapper SHA精確為上述`9a2828a1…`，`GitHubMark.pdf` SHA `37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`與source bundle相等，紀錄`wrapper-copy.json`。本Tester沒有以shell執行UI操作或重用舊AX／CGEvent腳本。

### 主對話Tester CUA觀察＋本Tester獨立實看

子agent本輪未提供CUA工具，UI操作由獨立於Implementer的主對話Tester執行；以下明示其逐條實際工具觀察，本Tester親自檢視18份raw capture，不能冒稱自己親操作。主對話Tester始終只操作本Demo，沒有啟VoiceOver或改全域contrast／motion／字級偏好，未用shell AX／CGEvent代替CUA。

- 三真入口均實際走過：Welcome primary→waiting；PAT Return submit→verifyingToken；真browser failure Try again→waiting。Waiting Cancel落點與單步Escape→Welcome primary可觀察；verifyingToken heading可讀，但VOoff時focusedWindow不能當VoiceOver target或自動朗讀passed。Controls直接show只用於部分純字級視覺格，未替代三入口。
- PAT假輸入Show保值，收回選取後再輸入一字、Hide後14→15字元且secure field保留focus，支持持續編輯；Return真submit後不保留輸入。Token failure欄位為空hidden且focus field；Back→重進、Reset→重進亦空hidden且focus field。
- 字級21→17時PAT仍保留14個假字元與focus，沒有重建／清空form；Reset保留選中21／17字級。原生截圖可直接看見21較17大、17較13大，heading／說明／field／button／error／footer皆隨比例改變，左側裝飾固定；這是Demo局部字級，非系統偏好整合。
- 21pt Welcome、PAT、PAT failure與waiting有內容位於viewport外；主對話Tester實際scroll down後完整到達field／error／CTA或Cancel／footer，不能把top截圖的局部不可見當成全內容同時可見。Connected21的heading／說明／footer可見；未見水平scrollbar、文字重疊或操作被永久截斷。
- 一次CUA批次Escape／Return／Escape的末態仍waiting，後續單步Escape正常回welcome；批次送鍵的時序結果**無法判定**，不宣稱rapid departure passed或產品缺陷。快速離開／stale task仍交Reviewer取消邏輯核對及Human回歸，不能由source或舊binary pass外推。

| 實際字級 | Welcome | PAT | PAT failure | Waiting | Connected |
| --- | --- | --- | --- | --- | --- |
| 13 pt | 明暗／primary可讀 | 空hidden與CTA／footer可達 | error／field／CTA／footer可讀 | 真primary入口、Cancel／footer可讀 | heading／body／footer可讀 |
| 17 pt | Reset保17、真字級可見 | 改字級保值／focus、比21小比13大 | 捲動至error／field／CTA／footer | 真primary入口、Cancel／footer可讀 | 同phase改字級、heading／body／footer可讀 |
| 21 pt | 真放大；捲動至footer | 真放大；捲動至field／CTA／footer | 真submit→failure；捲動至error／field／CTA／footer | 真primary及Retry入口；捲動至box／Cancel／footer | 真流程完成；heading／body／footer可讀 |

矩陣是主對話Tester操作觀察與本Tester截圖實看，並非Human親驗結果。最小主窗780×532 pt frame＝780×500 content＋32pt chrome；所有字級保持40／60，無額外window放大掩蓋排版。

### 原生影像來源與限制

18份外置原生CUA raw images位於 `$TOPIC_SCRATCH/native/te05-*.jpg`。工具原先以`.png` capture名稱保存，檔頭／sips核為JPEG；只改副檔名為`.jpg`，原bytes／SHA不變，**沒有轉碼、裁切或resample**。`tester-te05/native-image-receipts.json`逐一列originalCaptureFilename、新檔名、format、bytes、SHA與尺寸。

所有raw images均1560×1064，實際780×532視窗位於左上，右側／下方為CUA白padding；這是工具輸出限制，不是產品畫面或2×真視窗。大字證據包含`te05-{welcome-21-top,pat-21,pat-21-bottom,pat-17,verifying-token-21,pat-failure-21-bottom,waiting-21-bottom,connected-21,connected-17,welcome-17,waiting-17,pat-failure-17-bottom,pat-failure-13,connected-13}.jpg`。新13pt明暗／waiting／PAT四圖為`te05-{welcome-light-13,welcome-dark-13,waiting-dark-13,token-dark-13}.jpg`，本Tester均實看，default13近舊版四圖；不把raw padding圖冒作canonical四PNG。

Repository原四PNG完全未改、bytes與HEAD相同，仍只證舊binary `1009d446…` 的TE-04來源；新版13pt外置證據另列，是否足以沿用LU-01交獨立Reviewer判定。本Tester沒有覆寫成新provenance，也沒有新增repo圖片path。Source／debug／release／wrapper收尾SHA與本節開頭完全相同，唯一新版Demo PID11544；`freeze-check.json`記原四PNG hash／未變與binary核對。

### 結論與交接

- LU-08獨立自動檢查通過、rootstrict39如實分類；LU-03保值／持續編輯／Back／Reset／submit清除與字級保留的可觀察native回歸通過。
- LU-05三字級×五畫面的真放大及垂直scroll可達性證據通過，Human新版大字親驗仍pending；沒有宣稱macOS系統字級偏好已整合。
- LU-06三真入口已走過、waiting Cancel／Escape可操作、heading角色／內容可讀；**VOoff不證自動聲音、VoiceOver target或每phase只宣告一次**。三真入口朗讀、rapid departure與必要Human回歸仍pending；HC-02七類舊pass保留，HC-01／HC-03及三缺口不closed。
- 執行過的bounded項目未觀察到新required source fix；交獨立RV-03審核source／取消去重／證據限制，不自行給Reviewer approval。最後由主對話Tester還原System／Welcome13pt、simulate failure off、origin Browser、Controls關閉且可⌘0開啟；VO／全域設定沿Human交接off。
- 本Tester只更新verification／step；未改source／tests／planning contract／原四PNG、未stage／commit／push／改PR。IM-05 source與Human公開發布授權均保留，這不是Human成果採用。


## PL-03／新版交付收尾（2026-11-04）

獨立Reviewer以base `613a505025774b3841ab73b4ed3b8774be38274a` → source `9f8955c40696cee6d77739da6d22d659287cfbc0`製作本地map；三點merge-base `14d0832f042720889993d769b4cbfb720078e6b1`，40files、+19023／-88。Pinned CLI0.11.0 validate／render exit0，無overlay時使用`--no-config`；1view／4lanes／12nodes／15edges／6steps，34 exact-head file refs與XML12 labels已核，未raster實看。

- Graph SHA-256：`9364bde15bd80ca2189a7e7002a838cbbd424c5caa47190b6aa31ce07a2cf751`；contentHash=`3fe2699ff22f185d813955fdbd427ced`。
- SVG：22001bytes、1738×700；contentHash=`bec587614a6f68b020ee67b3b797b2bf`。
- 外置 `$TOPIC_SCRATCH/pr-lens/9f8955c/`：`graph.json`、`SOURCE.md`、`rendered/manifest.json`、`rendered/login-change-light-bec587614a6f68b020ee67b3b797b2bf.svg`。無repo改寫／upload／publish；map僅涵蓋source9f8955c，不含本輪後續metadata、不冒稱最終head。

[Draft PR #66](https://github.com/a129924/rivet/pull/66)仍交Human review，不merge／release。HC-01／HC-03 pending：三真入口VoiceOver聲音、真正大字Human實看及rapid回歸尚待逐項回報；HC-02舊binary1009d446七類pass、三缺口與所有取證限制保持。這次只補兩份metadata，source／四PNG／凍結圖未變，不回填自身新commit SHA。


## HC-03-PAT：兩次新版實聽未通過（2026-11-04）

本日為交接／觀察日期，兩次未提供精確時刻。來源是主對話Human原句與root CUA核對，受測source `9f8955c40696cee6d77739da6d22d659287cfbc0`、binary SHA `9a2828a1fee54b5dfaeba1bce72f98a675192599a5ebdc61959c072ed11cce87`；不是HC-02舊binary1009d446，本Implementer只回寫證據。
- Attempt 1：Human回「我按RETURN出去沒有朗讀」；root CUA確認main heading為Simulating token verification，鍵盤focus顯示window，PAT自動宣告未通過。
- Attempt 2：Human說「你再一次」後，root CUA Reset→Welcome→真PAT入口並填好dummy，再交Human前景Return；Human明確回「完全沒聲音」。root CUA再次確認verifyingToken／鍵盤focus顯示window，仍未通過。
- 只在第二次之後，root唯讀getApp系統設定旁白頁，看到`AX_VOICEOVER_ENABLED Value:on`；沒有toggle任何系統設定。此觀察不回填第一次當時已on，也不證明音量、mute或speech channel等其他條件。
等待兩入口、大字Human與rapid尚未在本輪補驗，不判fail／pass；舊自動／TE-05／RV-03 bounded通過保留來源，不能關閉此gap。HC-01／HC-03仍pending、Human needs-rework；下一步EX-02只讀查真正通知發出／AX掛載／VoiceOver scope的新證據，不先指定NSApp錯target、priority或任意delay為修法。本輪未改source／tests、未操作UI、未stage／commit／push。


## IM-07：DEBUG instrumentation-only交接（2026-11-04）

Dispatcher正式交接獨立PR-04 approved／required None後，只在既有View加DEBUG OSLog notice有限追蹤，同檔private extension不新增type／public API／dependency。原onChange更新順序、第一guard與全部判定、focus落點、三次yield、通知API／medium priority均保留；沒有功能修法，也沒有新增鏡像logger測試。初次helper可見性編譯錯誤只以明確private修正。

Trace使用 `local.rivet.login-ui.phase-probe`／`PhaseEntry`：phase-change前後、task UUID／每guard實際返回stage、cancel／phaseMatches、有限entry／focusPhase、keyboard／AX request與binding tag、notification.post前後。第一guard先判再記start／return；未見post不能單獨當返回原因。只記有限tags與App／window／VoiceOver布林，缺值unknown；不記PAT／任意text／failure message／AX label／window title。binding只是SwiftUI值，mainWindow不證own View附窗或AX-ready，post.after只證呼叫返回，不證朗讀；logger本身會改timing，不能回推先前兩次原因。

本輪真focused15／4suites（0.630s）、root289／37suites（4.161s）、debug0.76s／release4.38s、format、唯一View scoped strict0、diffcheck均通過。Logs為OS外置暫存根的 `rivet-login-ui-im07-{focused,root,debug,release,format,scoped-lint}.log` 與 `rivet-login-ui-im07-fingerprints.json`；root strict未重跑，保留既有39非零限制。未啟UI或實際收取trace，不冒稱事件已emit或敏感資料runtime核對已完成。

HEAD仍`9dd80eaf51f0c5f4c7245db092ed3f04b92fe605`，診斷source為working diff；View SHA=`98bb32bd5ff4e014b9e146d42ab8cb7880d9f93793e9c571abadab7b0a6eacd3`。新debug probe SHA=`18c8a3a4b81ed7bf6f335af96ab8aa4ef504a67150406eddb3f31fd250a4d2eb`（2693328bytes），release SHA=`ad9e58408f5d71e758d62d5267cab1d80f37d56f565c5bd423c859c9846b0ab7`；獨特probe subsystem marker僅在debug binary存在、release不存在。既有running wrapper未替換，不能把原9a2828當診斷版；TE-06換版沿既有 `Contents/MacOS/RivetLoginDemo` 與 `Contents/Resources/Rivet_RivetPresentation.bundle`。

收集方式僅供TE-06／主對話後續執行；先核preflight trace與source／binary，再準備最多一次真Human前景PAT Return，HC-04目前0／1、未執行。使用下列精確predicate，只將輸出放既有外置topic scratch；stream於本case結束後停止，show限同一短時間窗，不擴掃其他subsystem。

```sh
/usr/bin/log stream --style json --predicate 'subsystem == "local.rivet.login-ui.phase-probe" AND category == "PhaseEntry"' > "$TOPIC_SCRATCH/native/hc04-phase-probe-stream.jsonl"
/usr/bin/log show --last 5m --style json --predicate 'subsystem == "local.rivet.login-ui.phase-probe" AND category == "PhaseEntry"' > "$TOPIC_SCRATCH/native/hc04-phase-probe-show.json"
```

本輪未stage／commit／push／改PR、未替換wrapper或操作UI／VoiceOver／全域設定；HC-01／HC-03／HC-04 pending。Human兩次無聲與「其他項目會朗讀」並存；等待兩入口／大字Human／rapid仍未新測。runtime結果才可決定後續修法，PC-04不預准換API／priority／delay或attachment橋接。


## TE-06：DEBUG probe獨立preflight（2026-11-04）

**TE-06 preflight完成／partial verification，交獨立RV-04；HC-04主要case仍0／1、未執行。** PR-04 approved／required None及IM-07完成由Dispatcher明示交接。本輪只核logging-only／自動檢查／runtime可讀，沒有選功能修法，沒有聲音pass或舊兩次無聲因果結論。

- 親讀唯一View diff：新增DEBUG OSLog及同檔private helper；callsite只給固定event、有限phase／focus tags、UUID與布林。沒有讀PAT、任意AX label、failure message或window title作log。原第一guard判定、onChange更新順序、focus request／三次yield、NSApp announcementRequested與medium priority未改；private diagnostic ID傳遞與extension分組不形成public API。
- 本Tester親跑：focused15／4suites（0.612s）、root289／37suites（3.800s）、debug（0.29s）／release（0.25s）、format、scoped strict136files0、diffcheck皆exit0。Logs為 `$TOPIC_SCRATCH/phase-probe-runtime/te06-{focused,root,debug,release,format,scoped-lint,diff-check}.log` 與check-results JSON；未寫鏡像logger測試，rootstrict未重跑，既有39非0分類不改。
- Source SHA `98bb32bd5ff4e014b9e146d42ab8cb7880d9f93793e9c571abadab7b0a6eacd3`；debug／wrapper均 `18c8a3a4b81ed7bf6f335af96ab8aa4ef504a67150406eddb3f31fd250a4d2eb`；release `ad9e58408f5d71e758d62d5267cab1d80f37d56f565c5bd423c859c9846b0ab7`。獨特probe subsystem marker親核debug有、release無，收尾再次核相同值，見 `te06-freeze.json`。
- 主對話NativeTester CUA正常Quit舊app後，本Tester以限定process比對確認無running，才更新既有wrapper binary與Contents/Resources下Presentation bundle並逐檔核SHA；沒有新bundle、啟UI、改source或替代UI操作。其後主對話CUA啟新版、真Welcome→PAT entry並填假資料，停在tokenEntry，沒有Return或Controls直切verifying。

### 真runtime可讀與有限schema

本Tester親跑 `/usr/bin/log show --last 5m --style json --predicate 'subsystem == "local.rivet.login-ui.phase-probe" AND category == "PhaseEntry"'`：exit0；只讀此精確subsystem／category，外置保存原JSON／stderr，沒有改logging preferences、VoiceOver或TCC。唯一受測probe PID46623，20筆全屬該PID，時間2026-11-04 15:01:47.699615～15:01:57.593502（Asia/Taipei）。

`te06-preflight-show.json`原bytes SHA `9af8381a2991390a927cf7f1356d1e3cbb37d1b033495102e2f4b6cce21a8525`；另有 `te06-preflight-current-pid.json` 與 `te06-preflight-schema.json`。所有自訂eventMessage payload的15欄符合allowlist；event／phase／focus／detail皆有限tags，correlation為`-`或UUID，布林為true／false／unknown；schema errors0，沒有token／任意text或associated failure message。標準Unified Log metadata只留外置，不能把payload allowlist核對泛稱為任意app log審核。

實際只見welcome→tokenEntry：Welcome與PAT各phase-task UUID、PAT另field-task UUID可追；phase-change.before的focusPhase仍welcome、after變tokenEntry，其後keyboard／accessibility request與binding可讀。沒有guard-return、notification.post或verifyingToken記錄。Welcome／tokenEntry原announce switch不發通知，故此處「未見post」不能當task提前返回，更不能外推PAT submit；沒有記錄到不存在的skip event。

最早多筆appActive／hasMainWindow／hasKeyWindow=false、keyIsMain=unknown、VoiceOver=true；最後一筆為accessibility binding tokenEntry→none，當筆appActive／main／key／keyIsMain均true、VoiceOver=true。這只證當筆logger觀察與SwiftUI binding，不證own View實際附窗／AX-ready或朗讀；logger本身仍可改timing，不能回推先前兩次無聲原因。

HC-04仍待獨立RV-04後，由Human最多一次真正前景PAT Return；本輪preflight不消耗該case。Post前後將來若出現也只代表呼叫／返回，不當出聲passed。HC-01／HC-03、等待兩入口／Human大字／rapid及原有來源限制均保留。本Tester只寫verification／step；未改source／tests／fonts／assets／圖面／其他contract、未stage／commit／push／改PR。


RV-04正式交接：獨立Reviewer `approved`／required None，僅准HC-04一次真Human前景PAT Return診斷；已核logging-only原logic／API／yield／priority不變、有限tags／UUID／bool未讀敏感欄位，PID46623的20筆／15欄schema0 errors，source98bb32／debug-wrapper18c8a3／releasead9e58凍結來源均見TE-06。只有welcome／tokenEntry、無verifying／guard-return／post，不推舊兩次原因或宣稱修復；HC-04仍0／1 pending，HEAD9dd80ea的diagnostic working diff非新commit，PL-03仍限source9f8955c，不產working-tree map。


## HC-04：唯一前景PAT Return診斷結果（2026-11-04）

Human本次明確回「讀出驗證中」；主對話先保存同次精確predicate的24h範圍trace，再CUA確認verifyingToken。**本case completed-observed有聲，1／1已用；未重測。** 本Tester獨立核外置 `phase-probe-runtime/hc04-runtime.json`：34筆全屬PID46623，15欄finite schema0errors，唯一verifyingToken task correlation `90309595-A557-4A70-B879-69DB46879DBB`。原JSON57755bytes、SHA `04dc31510ba19930d1b8c6ded0ee76350f7019da265d9af70bef1eddfa9d0ffd`；詳細核對receipt為 `hc04-independent-receipt.json`。

15:55:03（Asia/Taipei）同case依序task.start→keyboard.request(none)→accessibility.request(tokenStatus)→notification.post.before／after各一次；phaseMatches=true、cancelled=false，無guard.return，當筆appActive／main／key／keyIsMain／VoiceOver皆true。15:55:08 binding none→tokenStatus時appInactive／mainkeyfalse；15:55:10 tokenStatus→none時active／keytrue，只分列當筆，不回填主要case或後續CUA，不證own AX-ready／實際VO cursor，也不判聲音由哪個機制產生。

HEAD仍`9dd80ea`、working View SHA `98bb32bd5ff4e014b9e146d42ab8cb7880d9f93793e9c571abadab7b0a6eacd3`、debug／wrapper `18c8a3a4b81ed7bf6f335af96ab8aa4ef504a67150406eddb3f31fd250a4d2eb`均親核不變。本次可判post路徑完成而非early return；前兩次`9a2828…`無trace且未過仍cause unknown，原`1009d446…`七類Human pass留源，VoiceOver已確on／其他項目有聲補充保留。Instrumentation可能改timing，不能把logging當已修正式PAT，waiting兩入口／新版大字Human／rapid本輪未跑，三缺口及HC-01／HC-03不closed；交獨立Reviewer分類，不自選fix。只寫兩檔metadata，未改source／UI／新case／tests／build／Git發布。


## IM-08：探針封存、單檔還原與正常版自驗（2026-11-04）

Dispatcher正式交接PR-05 `approved`／required None；本步只移除自身logging，不是功能修法。HC-04 Human「讀出驗證中」與後續Human「Yes」依上游交接保留，不擴張為穩定性或採用；原計畫短窗而實際24h精確predicate採集的偏差保留，未重收trace或重用1／1預算。HC-05正常版對照仍0／1 pending。

- 外置雙份封存：`$TOPIC_SCRATCH/normal-compare/archive/`、`$TASK_ARTIFACTS/normal-compare-2026-11-04/archive/`，20件原bytes逐檔SHA一致；relative `manifest.json` SHA `193805105317e081fd4a4bdb19defe6f4b05523f026c4d2002da4df09c93c11f`。含View `98bb32bd5ff4e014b9e146d42ab8cb7880d9f93793e9c571abadab7b0a6eacd3`、debug `18c8a3a4b81ed7bf6f335af96ab8aa4ef504a67150406eddb3f31fd250a4d2eb`、release及34筆trace／receipts；原trace SHA `04dc31510ba19930d1b8c6ded0ee76350f7019da265d9af70bef1eddfa9d0ffd`，source版本為HEAD9dd80ea上的未commit probe working diff。
- 雙重hash guard後只將View寫回HEAD `9dd80eaf51f0c5f4c7245db092ed3f04b92fe605` 原blob，SHA `89cb23c412b7d9e2b5ecefe0e1b0123731e2b4d96cfafaf366126527afc980a5`；七個Swift檔逐bytes等於HEAD及source9f8955c，其餘六檔未寫，五份metadata通過還原前後hash核對。還原／fingerprint receipts在 `$TOPIC_SCRATCH/normal-compare/im08-{restore-receipt,normal-fingerprints}.json`。
- 正常debug新實測SHA `ea297d3d5dc63594cc20fd2a1d79cfda19994d9db7133fa4916b71aeb370f36d`（2576960bytes）；release `fe886ca50f7173e94d6dc65dd57c6f99ac4141f2a527c41a5eec8c3ee454a304`（1272064bytes）；兩者均無probe subsystem marker，不沿用舊9a／22c hash。
- 自驗focused15／4suites（0.642s）、root289／37suites（3.868s）、debug（0.25s）／release（4.07s）、format、scoped136files0／diffcheck皆exit0；完整命令與logs為 `$TOPIC_SCRATCH/normal-compare/im08-check-results.json`、`im08-*.log`。Root strict未重跑，舊39非0不冒pass；沒有新增鏡像測試或重做native。
- 未操作UI／系統設定、未替換running wrapper（仍probe18c8a3）、未stage／commit／push／改PR或圖面；正常版尚無runtime post trace／appActive／VoiceOver內部條件。先交獨立TE-07及RV-05，不以單次A／B推唯一原因或穩定修復；舊9a兩次failed／unknown cause、1009d七類pass留源，waiting兩入口／大字Human／rapid與HC-01／HC-03仍pending。


## TE-07：正常版對照preflight（2026-11-04）

**TE-07 partial完成，交獨立RV-05；HC-05仍0／1未用。** 親核七Swift逐bytes等於HEAD9dd80ea與已發布source9f8955c，Sources／Tests zero diff；View SHA `89cb23c412b7d9e2b5ecefe0e1b0123731e2b4d96cfafaf366126527afc980a5`。雙份archive20件逐檔符合relative manifest與相互SHA，manifest `193805105317e081fd4a4bdb19defe6f4b05523f026c4d2002da4df09c93c11f`；probe98bb／18c與34筆HC-04 trace保持原來源，未覆寫。

親跑focused15／4suites（0.574s）、root289／37suites（3.695s）、debug0.24s／release0.25s、format、scoped strict136files0／diffcheck皆exit0；沒有新測試或rootlint重跑，舊39非0限制保留。Logs／receipts為 `$TOPIC_SCRATCH/normal-compare/te07-*`（含check-results、archive-check、seven-swift-source-check、wrapper-copy與freeze）。

主對話CUA正常Quit probe後，本Tester親核唯一目標無running才換既有wrapper及Presentation resources；正常debug／wrapper SHA `ea297d3d5dc63594cc20fd2a1d79cfda19994d9db7133fa4916b71aeb370f36d`、release `fe886ca50f7173e94d6dc65dd57c6f99ac4141f2a527c41a5eec8c3ee454a304`，兩者及wrapper皆無probe marker，收尾hash相同。不沿用舊9a／22c，也不假稱bit deterministic或正常版有post trace。

主對話NativeTester CUA其後啟正常版，Welcome primary→真PAT link→secure field focus，填14個dummy字元、Connect enabled，仍停tokenEntry；未按Return／切verifying／改全域設定。本Tester沒有UI操作；normal內部active／VoiceOver／通知條件不補造，留Human實際聲音與視窗結果。HC-04 1／1已用、舊兩次9a failed／probe18c有聲及24h採集偏差保留；一次A／B不證logging因果或穩定修復，HC-01／HC-03、三缺口與waiting兩入口／大字Human／rapid仍pending。僅更新verification／step，不改source／tests／PNG／圖面、無stage／commit／push／新map。


## RV-05：正常版成果審查與Human邊界（2026-11-04）

Dispatcher正式交接獨立RV-05 `approved`／required None：Reviewer核112份Sources／Tests逐bytes、雙archive20件／manifest與TE-07證據，僅放行HC-05一次Human前景Return；正常debug／wrapper ea297d3d…、release fe886ca5…及無probe來源不變。HC-04 1／1不重用；HC-05 human-check仍0／1，單次有聲不證穩定修復或logging因果，HC-01／HC-03及三缺口仍pending。

最新Human另回「讀出驗證中」，但主對話唯讀CUA getAXState明確無變化，正常版仍tokenEntry、secure field維持焦點；未見新送出證據，正常版尚未Return。此句暫不歸因HC-05、不耗預算或判通過，也不推定指哪次；HC-04既有相同回報留源。本步僅兩檔metadata回寫，未改code／UI／build／tests或執行Git。


## HC-05：正常版Human對照結果（2026-11-11交接／核對）

最新Human於明確正常版前景PAT Return步驟後回「讀出驗證中」；主對話CUA先以listApps確認既有app running，getApp僅選取該app，讀到`Simulating token\nverification…`與模擬／no requests footer、focusedUIElement0為window，當時沒有按鍵／點擊／改狀態。**HC-05 completed-observed有聲、1／1已用，不再觸發。** 聲音證據來自Human；AX只證畫面，window focus不當實際VoiceOver cursor。日期為本次結果交接／核對日，不補填無法查證的精確操作時刻。

本Tester只讀核對唯一wrapper PID70908／bundleID `local.rivet.login-ui-demo`，wrapper與debug SHA均`ea297d3d5dc63594cc20fd2a1d79cfda19994d9db7133fa4916b71aeb370f36d`（2576960bytes）、無probe marker；View SHA `89cb23c412b7d9e2b5ecefe0e1b0123731e2b4d96cfafaf366126527afc980a5`，七Swift仍等於published9f8955c、HEAD9dd80ea、Sources／Tests zero diff。正常版沒有post trace，不能補造通知／active／VO內部條件。

先前同句但無新送出證據的歷史原樣保留；舊9a兩次無聲原因仍未知、probe18c的HC-04 1／1有聲與原1009d七類pass及來源限制保留。一次正常版有聲不證穩定修復或logging因果；waiting兩入口、Human大字與必要focus／rapid、HC-01／HC-03及三缺口不closed，交獨立Reviewer作結果處置。

結果核對後，主對話CUA僅開Controls讀System13／Browser origin／failure0，Reset回Welcome並關Controls；最新Welcome可讀、Continue with GitHub為focusedUI17。尚未點primary／Return，只是下一項Welcome→waiting的準備，未消耗新waiting case。本Tester未操作UI／build／test／新case，只寫verification／step，沒有source或Git發布變更。


## HC-03：Welcome→waiting Human失敗回報（2026-11-11）

Human依真Welcome→waiting步驟先回「他聚焦在 Cancel sign in」，再明確回答「沒有 直接唸出 Cancel sign in」：本入口**自動等待狀態宣告failed／needs-rework，Cancel焦點符合既定契約**。主對話CUA僅唯讀核畫面為waiting，heading `Finish signing in/on GitHub`、simulated handoff／`Waiting for simulated authorization…`可讀、focus5為Cancel link，沒有其他UI操作；AX不代Human聲音，也不補造正常版post trace或精確操作時刻。

來源沿用最近親核normal EA297d／View89cb、HEAD9dd。前輪獨立Reviewer結果處置approved／required None只放行既有HC-03，不代表本次通過。HC-05正常PAT單次有聲1／1、HC-04／原七類pass／兩次無聲與先前模糊回報歷史均保留；Retry→waiting仍未補驗，Human大字／必要focus與rapid及HC-01／HC-03、三缺口仍pending。交Explorer bounded調查等待宣告缺失，維持Cancel落點，不預選修法。本輪只寫兩metadata，未重測／build／UI／新receipt／Git發布。


## IM-09 waiting Cancel焦點語義修補與自驗（2026-11-11）

Dispatcher正式交接PR-06 `approved`／required fix None後，依PC-06在既有Cancel link加入 `Waiting for simulated authorization. Cancel sign in.` accessibility label，並刪除waiting的獨立announcement分支。Source diff為View +1／-1，既有長期登入說明同步等待狀態的朗讀方式。

- View SHA `cf1f007065af1449c5ca945dafd00fe81fbba1187479e0d501f72d651e51f1a8`（15203bytes），來源為HEAD `9dd80eaf51f0c5f4c7245db092ed3f04b92fe605` 上的PC-06 working diff。其餘六個Swift檔親核等於HEAD，既有五份metadata在自驗前後hash一致。
- Debug SHA `50a30cdc872292f8cd4de5a689b52ae2ab9d6451613067ff8440ba68b384d67f`（2580048bytes），release SHA `25a8136f02e9d974d27c8a644f37304ace8e7cc80ccb007c9c3db56a79dcd9c5`（1274048bytes），兩者probe marker皆缺席。
- 本輪一次自驗focused15／4suites（0.590s）、root289／37suites（3.657s）、debug（0.25s）／release（3.57s）、`scripts/check-swift-format.sh`、scoped strict136files0與diffcheck皆exit0。完整命令／logs及精確指紋保存於 `$TOPIC_SCRATCH/im09/check-results.json`、`fingerprints.json`、各項 `.log`。Root strict保留舊39非零結果，本輪未重跑。
- 現交獨立TE-08核新版native link role／label／focus、Cancel／Escape與來源，再由RV-06 review。兩真waiting入口的聲音、雙讀情況及Human大字／rapid列HC-03待驗，HC-01採用pending。HC-05正常PAT observed有聲1／1、舊兩次無聲／probe與HC-02七類通過均保留原來源。

Running wrapper／UI由主線與Tester接續處理，本輪自驗使用feature build產物。Git交付待RV-06後依既有topic授權處理，當前HEAD仍9dd80ea，PL-03限source9f8955c。


## TE-08：waiting修補獨立驗證（2026-11-11）

**TE-08 completed／partial verification，交獨立RV-06。** 本Tester親讀View +1／-1只加waiting Cancel狀態label、移除該phase獨立post，其餘phase／focus／role／Escape路徑與六Swift／tests未改。親跑focused15／4suites（0.570s）、root289／37suites（3.442s）、debug0.27s／release0.23s、format、scoped strict136files0／diffcheck皆exit0；外置logs為 `$TOPIC_SCRATCH/te08/{check-results.json,*.log}`，rootstrict舊39非pass保留，未新增字串鏡像測試。

View SHA `cf1f007065af1449c5ca945dafd00fe81fbba1187479e0d501f72d651e51f1a8`、debug／既有wrapper `50a30cdc872292f8cd4de5a689b52ae2ab9d6451613067ff8440ba68b384d67f`、release `25a8136f02e9d974d27c8a644f37304ace8e7cc80ccb007c9c3db56a79dcd9c5`收尾親核不變、均無probe marker。主對話CUA退出舊app後，本Tester親核目標process結束才換既有wrapper及正確Resources位置，逐檔相等；沒有新app或平行instance。

主對話NativeTester CUA實際回歸：Welcome真primary→waiting，link role／focused label精確為 `Waiting for simulated authorization. Cancel sign in.`；點該link或另一輪單Escape均回Welcome primary。另真primary→waiting→SimulateReturn→verifyingAccount→Complete→browser failure，Try again focus後點真Try again→同waiting link／label／focus，單Escape回Welcome；沒有Controls直切waiting／Failure。再關simulate failure／Reset，PAT link→空secure field正確label／focus→Back→Welcome primary。CUA以bundleID launch回Invalidapp，改既有app path成功；先前退出工具嘗試不當Cancel pass或產品bug。

以上UI由主對話Tester操作，本Tester只親核source／build／hash，不把AX當聲音、雙讀或Human通過；本輪未輸入／送出PAT、不重用HC-05 1／1、未重做大字／rapid／舊全項矩陣或新增圖片。執行項目未觀察新required fix，不代Reviewer approval；Human兩真waiting入口親聽／雙讀、大字／必要focus與rapid及HC-01／HC-03仍pending，舊failed／HC-05有聲／probe與七類pass留源。最後System／Welcome13、Browser origin、failure off、Controls關閉、primary focus，未改全域VoiceOver或設定。本Tester只寫verification／step，無source或Git發布變更。


## RV-06交付審查（2026-11-11）

Dispatcher正式交接獨立RV-06 `approved`／required fix None，核View兩行反還原精確為89cb原bytes、其餘六Swift相等，並批准TE-08 source／自動與bounded native證據。TE-08 completed／partial，兩waiting入口Human聲音／雙讀、大字Human／rapid及HC-01／HC-03仍pending。

IM-10依既有topic及公開payload授權進行七檔staged語意／message檢查、完整hooks與正常public push，提交／推送結果待執行後另記。凍結View cf1f／debug50a／release25a來源沿IM-09／TE-08，舊Human紀錄與PL-03 source9f範圍留存。
