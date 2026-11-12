# 驗證產物歸屬修正：受限計畫

## 契約與授權

Topic：verification-artifact-ownership。分支：chore/verification-artifact-ownership；起點／PR 目標 dev。
需求見 [requirements](../../analysis/verification-artifact-ownership/requirements.md)，所有逐檔清單只見 [technical-spec](../../analysis/verification-artifact-ownership/technical-spec.md#唯一逐檔清單)，本文件不維護副本。
Human 已接受分類、集中原則與五批方向，已授權四份正式文件落地與獨立審查。本輪另明示 feature worktree 實作、按 topic commit、push、Draft PR 與 human review；這是獨立直接授權，不從規劃 approved 推導。
重大問題／必要驗證未到達則停止批次；不增加系統權限、環境修復、真人流程或 pin 更新授權。僅文件交付可作 WIP Draft PR，不能宣稱五批搬移完成。dev 工作樹不得寫入。
正式規劃 gate：四實體可讀、獨立 Plan-Reviewer approved、零未處理 required fixes；先前對話 approval 不挪用。

## 五批執行與檢查

每批先鎖定 spec 單一清單，完成必要驗證後經 Tester／獨立 Reviewer 才能下一批。

| 批次 | 必須完成的驗證 | 補充檢查（不替代必要驗證） |
|---|---|---|
| B1 Login Demo | 新路徑的 product 實際編譯、LoginDemoModelTests 實際執行、受影響 Presentation 測試、以新產物驗 wrapper／bundle 資源與離線原生入口 | target graph、format／lint、hash／diff、現行連結 |
| B2 Reader Harness | 新路徑 product 實際編譯、ReaderHarnessTests／bridge 受影響測試、TS check／tests、bundle 生成與新 Harness 實際載入 fixture／資源 | target graph、hash、format／lint、輸出路徑查核 |
| B3 首次登入 App＋tools | 新 project unsigned build、受影響 hosted／offline tests、PKCE 受控 cases 實際到達、fixture hash、最終 binary 的 E009 pin／身分 preflight | schemes／package refs 靜態核對、文件連結 |
| B4 持續連線 App | 新 project unsigned build、fake-only tests 實際執行、production 獨立建置／受影響測試且無反向依賴 | 資源／scheme／package refs 靜態核對 |
| B5 DPK runner | copied-project unsigned Debug／Rebuilt build、路徑變更相關受控 tests 實際執行、模板與兩處精確替換使用新位置、正式 source manifest 身分核對 | schema／CLI 入口靜態查核、文件連結；與搬移無關的可選 fixture cases 保留 skip |

所有必要驗證需列每個 case／入口的 command、revision、環境、到達階段（manifest／compile／test body／資源載入／入口 preflight）、預期、實際結果、失敗位置、原因、證據與 pass／fail／blocked／skipped／unknown。
同樣 manifest、權限或 helper 編譯失敗，只證明同一前置受阻；沒有到達本批 source、資源或操作入口時，不能推論無回歸、不能完整驗收、不能進下一批。
不只比較 failures／errors 數；逐 case 比較失敗位置與原因，未確認原因維持 unknown。補充靜態／hash 檢查不能替代必要 runtime／build 證據。
必要項未驗即保留未驗證，待原限制內可用環境補證或交人類，不以全局修復換通過。可選檢查與本批必要檢查的判定須在實作前完成，不能失敗後降級為補充。

## 搬移前基線及命令

既有 Tester 交接 revision：a554a4fee772d3976d5ca2c9331865a604e901e2，tracked files 前後無變更。本輪文件建立不是重跑測試。

| 入口 | 既有結果／到達範圍 |
|---|---|
| swift build --skip-update --disable-automatic-resolution --disable-keychain --disable-netrc --product RivetLoginDemo | exit 1，Clang ModuleCache 寫入權限阻擋 manifest；未編譯本批 product，不構成 source／資源驗證 |
| python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py | Ran 64，3 failures、3 errors；2 loopback bind 遭 Operation not permitted；3 failures＋1 setUpClass 涉 helper 編譯失敗，compiler stderr 未揭露，根因 unknown |
| PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py | exit 0；195 cases：187 pass、8 skip；缺少可選 binary／captured replay／DER，skip 不算通過 |
| Reader TS 的 bun run check | exit 0，format／lint 各45檔、typecheck 通過，未改檔 |
| Reader TS 的 bun test --coverage-dir 指定外置暫存目錄 | 99 pass、0 fail；未驗新 Harness bundle 載入 |

舊 PKCE 交接未保留每個失敗 case 的完整定位與 compiler stderr；不可只憑數量與未來結果建立等價結論。重驗時需補逐 case 證據，不追補未保存原始證據。
DPK 比較保持可選輸入未設定：RIVET_DIAGNOSTIC_PROBE_BINARY、RIVET_FAKE_PROBE_BINARY、RIVET_LAUNCH_BINDING_PROBE_BINARY、RIVET_PROFILE_FREE_PROBE_BINARY、RIVET_DPK_PROBE_BINARY、RIVET_CAPTURED_REPLAY_SOURCE、RIVET_DPK_PUBLIC_DER。
Reader Swift build／filtered tests、GUI WKWebView、兩個 Xcode App build／tests、DPK copied-project build 未驗。GUI／可寫 cache／既有離線依賴等解除條件不構成自動環境修復授權。
後續 unsigned build 指定 CODE_SIGNING_ALLOWED=NO、CODE_SIGNING_REQUIRED=NO、CODE_SIGN_IDENTITY=，使用獨立 DerivedData，不沿用歷史 ad-hoc signing。Hosted tests 先確認既有 UNIT_TEST_MODE=1 guard；不啟動正常 App／真人流程。

## 主對話 B1 局部建置路徑重現（2026-11-12）

本次依 Human 新授權，由主對話自己的 exec 環境重現，不把 side chat 權限檢查當成主環境事實。
新測試 revision：`2103e5624ec7597aca2c7eefac879b6c330aa4b6`。Swift 6.3.3、arm64，使用既有 Xcode toolchain／macOS26.5 SDK；未改版本、全域設定、簽章、安全限制或依賴。
Human 允許本次以標準參數重定向 scratch／輸出／cache；此為有限的新授權，不改先前歷史限制，也不授權停用 sandbox 或擴大環境修復。

### 原命令及新條件

主對話先直接執行本文件原 Login Demo 離線 build 命令：exit 1。錯誤明列預設 Clang ModuleCache 寫入 Operation not permitted、worktree .build/repositories 寫入被拒，並有使用者層 SwiftPM cache 不可寫警告。這是本主環境觀測，不代表系統檔案權限本身故障；更底層政策原因未調查。

接著建立獨立暫存根，逐目錄建立／移除 write-probe，確認 scratch、cache、modules、logs 可寫。以下 B1_RUN 表示該實際暫存根；外置紀錄可用 basename `rivet-ownership-b1-99s8ewap` 識別。本文件不保存本機絕對路徑。
SwiftPM --help-hidden 確認支援 -Xbuild-tools-swiftc；不使用已棄用的 -Xmanifest。以下是實際參數的符號路徑表示，變數僅限此建置，不寫入全域環境：

```sh
# B1_RUN 指向本次已確認可寫的獨立暫存根。
swift build --skip-update --disable-automatic-resolution \
  --disable-keychain --disable-netrc \
  --scratch-path "$B1_RUN/scratch" --cache-path "$B1_RUN/cache" \
  --manifest-cache local \
  -Xbuild-tools-swiftc -module-cache-path \
  -Xbuild-tools-swiftc "$B1_RUN/modules" \
  -Xswiftc -module-cache-path -Xswiftc "$B1_RUN/modules" \
  -Xcc "-fmodules-cache-path=$B1_RUN/modules" \
  --product RivetLoginDemo
```

先以相同 scratch/cache/manifest-cache/build-tools 參數跑 `swift package ... dump-package` 隔離 manifest；不解析／更新依賴、不啟動產品。之後才跑上列完整 build。
沒有傳入 --disable-sandbox、沒有修改 HOME／全域設定、沒有 sudo／chmod，沒有對 build 指令要求超出原執行限制的權限，也沒有啟動真人流程。

### 新條件的實測結果（不能與舊條件直接視為等價）

| 操作 | 實際到達／結果 | 未到達 |
|---|---|---|
| 原離線 build | exit 1；預設 ModuleCache／.build 寫入受拒 | B1 source、tests、資源、入口 |
| 指定可寫目錄的 dump-package | exit 1；錯誤改為 sandbox-exec: sandbox_apply: Operation not permitted | manifest 成功執行／package graph、產品與測試 |
| 上列指定可寫目錄的完整 build | exit 1；1.113s，manifest 標準 sandbox 啟動被拒；無原 ModuleCache／repositories 寫入錯誤 | B1 product source、tests、resource 載入、操作入口 |

新 modules 目錄有10個 cache 檔，包含 Swift、PackageDescription、SwiftOnoneSupport 與 SwiftShims；scratch 有 manifest.db／ManifestLoading。這證明路徑重定向實際生效，不等於 product source 已編譯或 manifest 已成功執行。
SwiftPM configuration／security 使用者層不可寫警告仍在；未變更這些設定。當前阻擋的明確錯誤是標準 sandbox_apply 呼叫遭拒，拒絕背後的主機／執行政策原因維持 unknown，不臆測為原始碼或依賴錯誤。
主對話外置原始紀錄：logs/manifest-command.json、logs/manifest.log、logs/build-relocated.log、logs/build-relocated-result.json；均位於上述 B1_RUN。
完整 build log SHA-256：`b4fc5aa8f2480623d41769b4610fa07dda2b7345193168d7296a2d7d7d0ec181`；結果時間 UTC 2026-11-12T06:52:18。紀錄包含完整 argv、revision、exit、耗時與到達階段，不追補先前未保存的原始輸出。

### 停點與最小下一步

B1 必要 source／測試／新版 wrapper、bundle 資源與入口仍未驗，B1–B5 不開始搬移。既有唯一逐檔清單、候選編號、分類、五批範圍與集中原則不變。
單純再換可寫目錄沒有證據可解決 sandbox_apply；不以停用 sandbox、改系統權限、要求繞過執行限制、換引擎規避檢查或直接執行 manifest 作為 fallback。
最小下一步是在允許 SwiftPM 標準 sandbox 啟動的正常本機執行環境，保持 sandbox 開啟、固定來源及依賴，以同一組可寫目錄參數重新取得適用基線。若需由 Human 調整執行政策或另提供環境，先交 Human，不能自行做。
即使 dump-package／manifest 成功，仍必須實際完成 B1 product build、必要測試、新版 wrapper／資源與入口，經獨立審查後才能繼續；blocked／skipped／unknown 不算通過。

## swift-implementation 交接

每批開始與完成皆列 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify、TestCase。
Goal 為單一可驗收結果，Non-Goal／Out-Of-Scope 保留既有契約與未授權工作。四個檔案集合引用 spec 的精確列且互斥，不用 glob／整目錄，無則 None。
Written 是該批 baseline 不存在的新檔，Modify 是原位修改，Deleted 是舊檔並附必要性／可回復性，ReadOnly 禁改。搬移 old Deleted／new Written 附一對一 mapping，pure move bytes 相同；例外差異須事先鎖定。
完成交接核對 bounded diff，不事後擴張白名單；TestCase 包含穩定 ID、情境、可觀察預期、證據方法與需求追溯。

## 失敗與回復

失敗先停下一批。本批已允許的漏接路徑／路徑斷言可補齊並重驗，不因單一路徑疏漏立即撤回全部。
超出清單、需行為變更、外部副作用或無法安全完成才停止回報，必要時依 spec 一對一 mapping 撤回本批，核對原入口恢復；不覆蓋無關修改、不清理憑證、不改歷史。
相同環境下已存在的問題與本批新增回歸分列；未到達必要驗證的狀態不得交給下一批。第一批前置仍 blocked 時先不搬檔，交付文件 WIP 而非半套新來源。

## TestCase

| ID | 情境／預期與證據 | 追溯 |
|---|---|---|
| TC-VO-001 | 三種同意界線及歷史保留，文件 diff 核對 | R8／歷史澄清 |
| TC-VO-002 | 配號、逐檔 mapping／四集合互斥，pure bytes hash 相同 | R1–R3 |
| TC-VO-003 | B1 build／tests／新版 wrapper 與資源實際執行 | R2–R5 |
| TC-VO-004 | B2 bundle、fixture、Harness／bridge 實際執行 | R2–R5 |
| TC-VO-005 | B3 App／tools、fixture pin 與分輪結果保留 | R2–R5 |
| TC-VO-006 | B4 新路徑 build／fake tests、正式 graph 不變 | R1–R5 |
| TC-VO-007 | B5 模板與兩處替換、正式 manifest、新路徑受控 tests | R2–R5 |
| TC-VO-008 | 批內補路徑重驗；超界停點／安全回復紀錄 | R6 |
| TC-VO-009 | 正式 approved＋零 required fixes 與執行授權分離 | R8 |
| TC-VO-010 | manifest／helper／權限先阻擋時標未到達、不放行；逐 case 原因 unknown 不捏造 | R4–R5 |
| TC-VO-011 | 最終 binary E009 身分／SHA／preflight 實測；失配停，不改歷史 pin | R7 |

## 輔助工具

Graphify：既有五工作樹標準位置未見可用 graph，已用限定 rg/source 回查，不建圖、不安裝。若未來有可用圖，固定0.9.73，每次 CLI GRAPHIFY_NO_AUTO_REFRESH=1，bounded query／path／explain 並核對 revision，重要關係驗 source。
PR Lens：實際 bounded diff 後以真實 base／head，固定本機0.11.0，讀既有 overlay（若有），於 repository 外 validate／render。保留 unchanged neighbors／file refs；不改設定、不建立 repo .pr-lens、不上傳或發布。
Archify 僅在既定 workflow 說明確有必要時使用，不把圖當新治理或 gate 必備；若交付則依技能 showcase／deliver／visual-check。此輪不新增圖面工作。
工具不取代測試或獨立審查；工具缺失記限制，不擴大安裝、整合或 provider 操作。

## Execution Authorized 後的新基線與 B1 契約（2026-11-12）

Human 明確授權提供可啟動標準 SwiftPM sandbox 的執行環境。主對話以正常本機執行上下文重跑既有 argv（本次輸出／cache/module 路徑不變），未加 --disable-sandbox，未改系統權限／全域設定／簽章／安全政策。這是不同於前輪受限上下文的新基線，不改寫先前 sandbox_apply 失敗。
來源為 feature HEAD 0fdb01c46df9a3633806745b59a85f8bd26acd97，工作樹無程式變更。Apollo 2.1.2／38c202227d0f09508e573dcf22f54885cfb0c5d4 由既有本機 bare cache 複製到本次 cache；lockfile 不變，程序限定 Git HTTP/HTTPS transport=never，離線 build 明示 fetched from cache。

| 本次基線 | 實際結果 | log SHA-256 |
|---|---|---|
| 同參數 dump-package（標準 sandbox 開啟） | exit0，1.319s；manifest／graph 真正執行 | 79f7542623558dfc38d5712bbeecf40acec23ca9c224f9474abfac69e3902545 |
| 既定 B1 product build | exit0，10.633s；Presentation、LoginDemoModel、LoginDemoHost、main 真正編譯、連結；GitHubMark.pdf 複製 | 039072e5e4d20198c3d285aacdb6ce244d82ba2f84751601089708f8bb052870 |
| 同選項 swift test，filter LoginDemoModelTests\|RivetLoginPresentationTests\|StaticIsolationTests | exit0，16.302s；62 tests／6 suites 真正執行通過，非 XCTest 的0tests摘要 | 46f297602666233f760e3c76c7f7cb6a4e904f48aca8d0f2de4c5de2ce305d8a |
| baseline 新 wrapper／入口 | binary SHA 43030844dd2d5b3e17323ddee26881120f1beb92b9190a75bf78dc71389e5d08；主對話 CUA 親見 Welcome／PDF圖示／無網路footer、Continue→模擬waiting→Cancel、PAT本地表單；歷史 wrapper 未改 | 外置 logs/wrapper-baseline.json、ui-baseline.json；CUA 原生畫面與AX於本輪工具紀錄 |

所有外置 receipts 沿用前節 B1_RUN，檔名為 manifest-standard-context-result.json、dependency-seed.json、build-standard-context-result.json、tests-baseline-result.json 與對應 logs。沒有修改 dev 工作樹。
本次只鎖定／實作 B1，B2–B5 未開始；baseline 通過不等於搬移後通過。E011 與逐檔允許差異以唯一 spec 為準，B1 四個移檔 bytes 不變，root products／targets／dependencies 不變。

### swift-implementation：B1 開始交接

- Goal：僅將 Login 驗收展示完整集中 E011，維持 build／tests／資源與既有離線操作入口。
- Non-Goal：不改正式 UI／API／行為／簽章／儲存，不新增 package／工具，不處理 B2–B5。
- In-Scope：唯一 spec 的 B1 移檔列、B1／B1-B2／各批的必要接線與明列新增 README；只作本批需要的列。
- Out-Of-Scope：其餘批次、正式能力／正式測試搬移、歷史來源與 frozen wrappers／pins 改寫、真人流程。
- ReadOnly：引用唯一 spec 的 B1 及相關 ReadOnly 列，未列入寫入集合的檔案不可改。
- Written：引用唯一 spec B1 的四個 new 路徑與 E011 README，沒有其他新增檔案。
- Deleted：引用唯一 spec B1 四個 old 路徑；原因僅集中收納；回復時反向映射且保留原 bytes。
- Modify：引用唯一 spec 的 B1／B1-B2／各批中本批必要列；僅三 target 路徑、lint涵蓋、現行導覽與本 topic 契約／證據／狀態。
- TestCase：TC-VO-002／003／008／009／010；同一參數與正常本機執行條件重驗 post build、上述62tests、hash、正式PDF與bundle、新wrapper原生UI／控制入口；不得只以artifact存在或baseline通過放行。

新增 E011 README 僅補既有操作的可重現步驟；所有逐檔路徑仍只在 spec 維護。B1 契約須先經獨立 Plan-Reviewer approved／required fixes0，再搬檔；搬移後由獨立 Tester／Reviewer 驗證，不把本節當成果approval。

## swift-implementation：B1 完成交接（待成果 Reviewer）

本節承接 B1 開始交接的相同 Goal／Non-Goal／In-Scope／Out-Of-Scope 與 spec 唯一 Written／Deleted／Modify／ReadOnly 集合；沒有事後新增 scope。四個移檔均 bytes 相同，正式UI／正式測試／lockfiles／root products、targets、dependencies、resources不變。
下列為搬移後相同正常host、標準sandbox、同scratch/cache/module argv、固定本機依賴及程序GitHTTP/HTTPS禁用條件；不是前輪受限上下文的等價推論。

| TestCase／必要或補充 | 真正執行與結果 | 原始證據 |
|---|---|---|
| TC-VO-003 必要source build | exit0，4.531s；新E011 Host／Model／main重新編譯及連結；非只manifest | build-post.log SHA 9564d13c757d9bef4a26245abbdc126c3151af5ed1fdc19f9f563d2c73b2e8d6 |
| TC-VO-003 主對話必要tests | exit0，3.712s；相同62tests／6suites通過 | tests-post.log SHA 24d04aaf4f2de60fb79a19ad43ddf1f6cd2aaaf5f2a829bb0293854694b37d22 |
| TC-VO-003 獨立Tester必要tests | Kepler 親跑原argv，exit0，3.877s；62pass／0fail／0skip，6suites；案例集合與baseline相同 | tester-post.log SHA 0617d1688eda08465aeb9285f2c3e87073f5f2c0c3abc2c4ff6153cbb60245c6 |
| TC-VO-003 必要資源／操作入口 | 主對話親驗post wrapper：Welcome、PDF圖示、no-network footer、Continue→模擬waiting→Cancel、PAT範例輸入／Show／submit→verifying、Window→DemoControls→Complete→Connected；關控制窗後主窗顯示simulation完成 | ui-post.json；原生CUA AX／截圖為本輪工具紀錄。Tester只讀證據與核artifact，不聲稱親驗UI |
| TC-VO-002 補充hash／graph | 4/4移檔SHA符合唯一表；舊path消失；build graph／source lists三target均指E011；正式來源／測試與lockfiles未改 | tester-static-post-result.json；不是另一份受維護清單 |
| TC-VO-002 補充format／lint／入口語法 | format exit0；SwiftLint正常host exit0，138files／0violations；兩script與README兩shellblocks bash-n均exit0 | Tester保留最初受限上下文SwiftLint cache寫入exit1與正常hostexit0的不同紀錄，不混算 |

post debug／wrapper binary SHA：1aeff9ea17fd45c909dc351ded6c7423d60a7fbb3c39e56fb302d0052de6d870；與本次build產物一致。PDF SHA：37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1，與正式Presentation資源相同；Info.plist bytes與歷史wrapper相同，歷史wrapper未改。
全部外置證據沿用 B1_RUN/logs，另含wrapper-post.json、ui-post.json、tester-post-result.json、tester-summary-post.json。未提交原生截圖檔，不將工具畫面誤稱repoPNG artifact；不宣稱重做原topic完整Human／VoiceOver驗收。
目前 B1 post 必要項均已實際到達，Tester已交接；成果仍待獨立Reviewer明示verdict。B2–B5維持未開始；本輪只交付B1，不將五批一併宣稱完成。

### B1 最終審查補記

Meitner 成果最終 approved／required fixes0。唯一RF為README空cache準備缺口，已補既有barecache與lockfile revision檢查，主對話實跑文件流程exit0／25.972s、source編譯與62tests6suites通過；log SHA ed058de529a63e85d3ff07ca50c6d756d0e8105d183d3dad314063e78e091788，外置readme-offline-workflow-result.json／log。只補原有操作說明，沒有變更scope或source bytes。前節待Reviewer文字為交接當時快照，本節為最新獨立結果；不宣稱B2–B5通過。
