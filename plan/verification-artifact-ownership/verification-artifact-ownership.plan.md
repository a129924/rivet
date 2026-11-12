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

## B2 開始交接與搬移前適用基線

來源7e5f4fd44c64a956ed133096939d42f37de4ff2f，feature乾淨、upstream及Draft PR69 head一致，B1獨立approved保留。Human重申五批直接授權，不逐批重問，也不因B2完成自行停止。
沿用已確認可啟動標準SwiftPMsandbox的normalhost、原scratch/cache/module argv與程序GitHTTP/HTTPS拒絕；只將product換RivetPRReaderHarness，test filter換ReaderHarnessTests|BridgeSessionTests|WireContractTests|StaticIsolationTests。
外置證據沿用B1_RUN/logs/B2，以下均實際執行，不採歷史disable-sandbox測試命令。

| 必要檢查 | baseline結果／到達階段 |
|---|---|
| bun run bundle:reader | exit0，reader.js SHA 2ab5fdf0daad9aff9ccefb1f61021b54c1ce57fc8019b85b84a3c2f47abd4cba，與既有bytes相同 |
| Reader product build | exit0／3.079s，使用本次build graph／資源；log SHA 26580cf472a7aaa22ead1fbb1207990c7de85d933d289d263b1c08b6a1fa8a43 |
| Swift指定tests | exit0／7.062s，68tests6suites pass；真WKWebView資源、Viewed往返、failure／timeouts／external拒絕實際執行；log SHA 9a14ef4bad39ac146bb3984e86ac085413b54bbbddcdccd5010987697f52601d |
| TScheck／tests | check exit0；normalhost 99pass0fail，log SHA 55c1372a4be4a4544e7298f3dc95091441ccccac03805b0925e36563004063d9 |
| 主對話原生fixture入口 | 暫存wrapper真顯示六狀態／四patch／兩metadata；首檔Viewed設為已Viewed再取消復原；file URL實際為本次debug resource bundle，非遠端頁面 |

TS tests首次受限context的coverage寫入exit1保留於ts-tests-baseline.log，normalhost重跑成功另存ts-tests-baseline-host.log，不以相同failcount視為pass。原swift-run模式CUA無app識別，改採既有歷史暫存wrapper模式，未改source行為；入口條件與實際資源URL分列，post獨立驗證，不宣稱portable app。

### swift-implementation 九欄（B2）

- Goal：Reader驗收host／Runtime／fixture／resources／專屬測試完整集中E012，既有入口及Viewed往返可用。
- Non-Goal：不改bridge／Core／TS行為、API、簽章／儲存，不開始B3–B5。
- In-Scope：唯一spec的B2七移檔、E012README、B1/B2及各批中B2必要接線；docs架構README只更新現行入口。
- Out-Of-Scope：正式能力／正式測試搬移、圖面重產、新package／抽象／工具、真人API／OAuth／DPK。
- ReadOnly：引用spec B2正式bridge及相關不可寫檔；未列寫入檔一律不可改。
- Written：spec B2七個new檔與E012README，無其他新增。
- Deleted：spec B2七個old檔；集中歸屬所需，反向mapping及原hash可完整回復。
- Modify：spec B2／B1-B2／B2-B3-B4／各批中本批必要列；只三targetpaths、bundle輸出、lint涵蓋、現行導覽與topic證據狀態。
- TestCase：TC-VO-002／004／008／009／010；必要post product、68tests、TScheck99tests、bundle bytes／實際資源URL與Viewed原生入口；補充hash／graph／lint不能替代必要項。

本段是實作前契約，尚待Plan-Reviewer明示approved／required fixes0，不等於post通過。B2通過成果審查後立即續B3；若遇E009 pin等人類邊界才停止，不以單批完成結束topic。

## B2 post 實際驗證交接

七個source／resource／test純搬移bytes相同，接線限spec唯一B2集合；同一正常host、標準SwiftPMsandbox、scratch/cache/modules與GitHTTP/HTTPS拒絕，實際argv存B1_RUN/logs/B2各result.json。

| 必要項 | post真正執行與結果 | log SHA-256 |
|---|---|---|
| product build | exit0／4.413s；新路徑ReaderFixture、ReaderHarness、resource_accessor及main實際編譯、三資源複製與連結 | cca282e3323e6288213b28bdea260089896bf415c71305dd4270a9095db44bc6 |
| Swift指定tests | exit0／6.371s；68tests／6suites，包含真WKWebView與Viewed往返、failure／timeout及external拒絕 | 09b2b871c3efdfb31d9ce53a5cd827871983a1142fb737fd5ee5375373d157ec |
| TScheck／tests | check exit0；99pass0fail，沿相同本機依賴／host條件；原受限coverage失敗仍保留 | check a6d6f8c683e65d0638ff6b37fcf18bf4de11c891ae3d07ef63adb976c94b2413；tests 6aa9142318e98409b8562a3dcf3638db57b0341b2a91a196b06048f82f000091 |
| bundle輸出 | 新路徑bun run bundle:reader exit0；產物bytes與baseline／唯一spec相同 | b7b68b83d58046c07bf80dabd3d09fb666f783ab697b84804f035697ed9a1723 |
| 原生資源與入口 | 主對話CUA親驗六狀態／四patch／兩metadata、Viewed設定後取消；實際file URL為本次debug resource bundle fallback，wrapper Info.plist與baseline bytes相同 | ui-post.json、wrapper-post.json；原生AX／截圖在本輪工具紀錄，沒有宣稱已存repo圖片 |

post binary SHA a0179c6eb6c52f4ff6e4fee9383ae96c7b2c1a0e958d0eef33e5cd45f3fceef3。三resource hashes相符，不在本處另維護逐檔清單。主對話實測不代替獨立Tester／Reviewer；目前待其明示verdict，B3–B5未動。沒有真人API、持久化Viewed或重新完成原topic Human驗收的宣稱。

### B2 獨立 Tester

Chandrasekhar verdict passed、required fixes0；親跑68Swift tests／6suites exit0／6.321s、99TS tests0fail、check／format／lint／shell syntax通過。Swift log SHA 00b67e1d8f586924d5c7b567244e076bfdeb67ce97dfab155b126eed32dd537d。7/7hash、正式graph與bundle外置重現相符；必要項skip／blocked／unknown0。UI由主對話親驗，Tester只核receipt與artifact。詳logs/B2/tests-independent-summary.json及swift／checks／static-result.json；目前成果仍待Reviewer，不由Tester放行。

### B2 最終成果審查

Schrodinger正式approved、required fixes0、unresolved required fixes0；已納Chandrasekhar最終Tester及主對話UI證據，7puremove與允許接線完整、必要post真正執行。Reviewer／Tester未重跑nativeUI，也未另實跑全新空cache的README全流程，不誇大驗證範圍。依既有Human直接commit／push授權提交完整B2，接續B3，不將本批等同topic完成。

## B3 preflight：命令與九欄

B2已獨立approved0，提交d62e0ef；B3沿同一featureworktree，E013／23files／精確兩個reference例外與其他現行導覽允許差異鎖在唯一spec。B3開始前尚未搬source，先重建本主對話正常host基線。B3_RUN表示既有本次暫存根下B3子目錄；logs沿B1_RUN/logs/B3。只複製既有本機SourcePackages（Apollo2.1.2，固定revision38c202227d0f09508e573dcf22f54885cfb0c5d4）至本次scratch，核對checkout與root／project lockfiles；缺少則停止，不抓網路。標準sandbox保留。

```sh
# PROJECT先指向spec的B3 old project；post須改用同表new project。
# SOURCE_PACKAGES指向本次copy，DERIVED_DATA按baseline-host／baseline-final／post-host／post-final分開。
env -u RIVET_VERIFY_GITHUB_CLIENT_ID -u RIVET_VERIFY_GITHUB_CLIENT_SECRET   GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE=1   GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=protocol.https.allow GIT_CONFIG_VALUE_0=never   GIT_CONFIG_KEY_1=protocol.http.allow GIT_CONFIG_VALUE_1=never   xcodebuild -project "$PROJECT" -scheme GitHubSignInVerification     -configuration Debug -destination 'platform=macOS'     -clonedSourcePackagesDirPath "$SOURCE_PACKAGES" -packageCachePath "$B3_RUN/package-cache"     -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile -skipPackageUpdates     -derivedDataPath "$DERIVED_DATA"     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build-for-testing
# 成功後同參數test-without-building（既有scheme guard），final-DD另行build。
# PKCE只跑unittest discover；不執行--case／校準UI／live，helper protocol分支不開GUI。
python3 -B -m unittest discover -s "$PKCE_TOOLS" -p test_pkce_negative_probe.py -v
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors   -module-cache-path "$B3_RUN/modules" experiments/E009/LaunchVerification.swift -o "$B3_RUN/e009-launcher"
"$B3_RUN/e009-launcher" --self-test
"$B3_RUN/e009-launcher" --preflight --app-bundle "$FINAL_APP"
```

實際argv／env／toolchain／source HEAD／logSHA另存本次receipts。unsigned只限既有計畫的build參數，不寫project簽章設定。hosted與PKCE必要測試若未到test body即blocked；baseline與post在不同DD／source paths要明示，不以同failcount等價。現行pin拒絕baseline時保留事實並停，不假設final新binary必然同hash。

- Goal：既有首次登入驗證App與PKCE工具／fixture完整集中E013，維持受控離線build／tests與E009入口契約。
- Non-Goal：不改OAuth、UI、helper行為、API／依賴版本、簽章／storage，不採用驗證工具為正式能力。
- In-Scope：唯一spec B3 locked23列及列明current文件／索引／本topic契約；只兩reference例外與必要路徑文字。
- Out-Of-Scope：其餘批次、正式能力與正式tests搬移、pin更新／弱化、真人OAuth／API、校準、外部副作用及圖面／治理。
- ReadOnly：引用spec B3及其他非寫入列，含E009 launcher／歷史README與所有正式能力；不讀憑證。
- Written：只引用spec B3 new檔，含同表project與tools README的明列內容例外；無額外新增檔案。
- Deleted：只引用spec B3 old檔；若未搬移則零，反向mapping與hash可復原。
- Modify：只引用spec B3適用且留在原位的Modify列；搬移後檔案的允許例外歸Written，不與Modify重疊；不改root graph、schemeguard、資源身分與pin。
- TestCase：TC-VO-002／005／008／009／010／011；必要old／new unsigned source build、guarded hostedtests、PKCE受控cases、fixturebytes、實際finalbundleID／executable／SHA及E009preflight；補充package refs／schemes／README連結與diffhash。必要baseline未到達／失敗即保留未驗與停止，不進下一批。

本節待Plan-Reviewer實作前審查；baseline執行只為取得適用證據，未授權提前搬移。通過後仍須獨立Tester與Reviewer成果gate；失敗可在原範圍內補路徑，超出範圍或pin問題交Human。

## B3 搬移前必要基線失敗：停止

主對話正常host已實際使用上述離線Xcode參數、本次SourcePackages copy、獨立baseline-host-DD、程序限定modulecache與TMPDIR。source HEAD d62e0ef，B3全部source仍是原bytes／原位置。標準package sandbox保留，Apollo固定revision，兩個真配置環境key在子程序移除；既有scheme UNIT_TEST_MODE=1防止App啟動載入live配置。

| 必要項 | 實際結果／到達階段 | log SHA-256 |
|---|---|---|
| baseline build-for-testing | exit0／16.780s，App與hosted test source、資源／plist、test bundle實際編譯連結 | aa486f6cd7854151c19010b3b7239e0415c495e9ba5cf26ca4db596143675415 |
| baseline test-without-building | exit65／19.634s，17tests／5suites真到testbody；16pass、1fail，該case內2issues；不是manifest或權限阻擋 | 1422daa73b0af6d6982704fc05b72ea550d48af1fd6fd6eca863206a49556c89 |
| 既有E009 launcher compile／self-test | compile exit0／4.930s；self-test exit0／0.406s，live_launch_performed=false、credential_input_performed=false | 外置launcher-compile／launcher-self-test-result.json；不等於App入口preflight |

失敗case：GitHubConnectionCoordinatorTests.absentOrPartialConfigurationNeverStartsLiveAuthorization()，原test第252行，canStart實際true而期待false，2issues。其餘16case包括真正loopback傳遞／取消通過，不把XCTest的0tests摘要或通過suite誤當全通過。
source查證鏈：App composition僅檢查兩key存在後交給正式GitHubOAuthAppConfiguration initializer；initializer只檢查非空，故空白字串仍可成為preparedConfiguration；coordinator presentation據此canStart=true。case的兩個空白輸入與這個差異吻合（raw log只定位共同斷言，沒有個別迭代標籤，個別輸入歸因來自source核對）。正式OAuth factory另有trim檢查，於建立authorization session前拒絕；不能由UI斷言失敗推論已發生真OAuth／token exchange。這是搬移前既有行為與test期待衝突，具體需要修改何者須另行決策，不納入本次純搬移。

B3成果狀態blocked；未搬23source，不留下半套接線，B4–B5未開始。baseline-final與所有post source／resource／entry均未驗；E009 App preflight尚未執行，pin相容性維持unknown，既有pin／hash／receipts不改，不能聲稱匹配或失配。PKCE獨立Tester結果待補；任何局部通過不解除hosted必要case失敗。
最小必要下一步：在獨立受限修正授權下決定並修復configuration接受條件與既有test的衝突，完成適用正常host基線與審查，再續既有B3契約。沒有建議更新正式API／storage／signing或弱化test／pin；本topic不自行做行為修正。

### B3 獨立審查結論

Plan-Reviewer Nash最終B3-preimplementation contract approved、required fixes0、unresolved required fixes0，唯一RF-1（Written／Modify互斥）已closed；只是契約足夠，execution仍blocked。獨立Reviewer Jason核對rawlog／receipt SHA、23source原位及原hash、相關正式source未改與具體source因果鏈：B3成果blocked，不放行搬移或後批。對本輪失敗記錄與停止處置明示approved、required fixes0；超出本topic的行為／test衝突保留1個執行阻擋事項，不冒作文件RF已清而執行gate通過。尚待PKCE獨立結果補記；任意局部pass都不解除hostedfail。

### B3 獨立 PKCE baseline 完成

Socrates親跑既定unittest命令一次，source HEAD d62e0ef；normalhost、標準compiler、兩client配置key移除、bytecode停用，TMPDIR與compiler cache僅本次B3子目錄。exit0／8.413s，67pass／0fail／0errors／0skip；loopback兩案、helper真編譯、v1／v3 --protocol-check與受控Swift harness真正到達。23sourcebytes保持，無bytecode新增。這是與前輪受限環境不同條件的新baseline，不比較64舊case總數或把前輪失敗回填成pass。
外置prefix：logs/B3/pkce-baseline-20261112T075035Z-48040，保留raw.log／argv.json／env.json／receipt.json／cases.json（67逐case）；raw SHA f5cff2aa1cf6c38245626f173d2dc846c675d4014afe320a19eae4c415d484a6。Tester局部verdict passed、required fixes0，明示B3整體仍blocked。hosted唯一失敗與2issues未解，baseline-final／所有post／E009 App preflight及pin相容性仍未驗，不以PKCE成功取代。

## Execution Authorized：VO-RB3 受限修正交接

沿原feature與分支，不建worktree。當前ec94bec／upstream／DraftPR69相符且乾淨；B1／B2完成保留，B3–B5未搬。此次Human授權修復空白配置衝突；依既有test與factory規則在App composition最早入口拒絕純空白，正式initializer契約保持。先用直接configuration測試得到可歸因red，再最小guard修正與green，完整hosted／PKCE基線及獨立Tester／Reviewer通過後另提交；B3原移動契約的pin停點仍有效，不能由此次行為授權推導更新pin。

- Goal：驗證App配置缺失／empty／純空白不成為prepared，不可啟動；有效配置原樣保留，解除既有hosted斷言失敗。
- Non-Goal：不改正式API／initializer、OAuth session／factory、UI結構、簽章／storage／pin；不改PKCE工具或fixture。
- In-Scope：只引用spec VO-RB3的兩個old Modify檔及本次必要四文件與現行配置說明；修正後另建搬移基線。
- Out-Of-Scope：搬移、其餘batch、真人OAuth／API／DPK、環境擴修、版本更新、refactor與新工具／抽象。
- ReadOnly：spec VO-RB3全部不可寫內容，正式configuration及OAuthfactory只查證；原歷史log／pin保留。
- Written：空集合；沒有新增repo檔案。
- Deleted：空集合；本階段沒有source搬移。
- Modify：僅spec VO-RB3明列old source／專屬test及必要既有文件；禁止把內容修改藏於後續rename。
- TestCase：TC-VO-012新增直接composition typederror／有效值保留測試先red、最小修正green；既有absentOrPartial與UNIT_TEST_MODE／prepared配置回歸、完整hosted與PKCE受控tests、23sources只有兩個允許hash變化。必要build／test body均真到達；format／lint為補充，不能替代行為驗證。

重用本次B3 sourcepackages copy與相同offline／sandbox／modulecache選項；新輸出在B3/blank-config-repair-DD，red／green分resultBundle，每次記錄argv／env／HEAD／source指紋及rawlogSHA。hosted scheme guard不改；移除兩client配置環境key，不啟動正常真人入口。先完成Plan-Reviewer approved／0fix才動source；修後獨立Tester／Reviewer gate僅解除本次行為阻擋，B3仍須baseline-final／E009preflight與移後必要驗證。

### VO-RB3 Implementer 完成交接

Gauss本次契約approved／required fixes0。依上述九欄與spec兩old檔完成最小guard及直接配置regressiontest，source未搬；其餘正式source／test、rootgraph、project／scheme、tools／fixture及pin不變。修後搬移SHA僅補在spec兩檔原列，原盤點hash仍保留；本次獨立fixcommit完成後在B3接續記錄綁定。

| 檢查 | 真正結果／到達階段 | raw log SHA-256 |
|---|---|---|
| 方法filter首次red嘗試 | exit0／23.170s但0tests；未選到SwiftTesting case，不算red／pass | 20cc9eeaf119bc07dd3b96a4d9433bb0698255b57e7ae39178f7df7b32db47bc |
| 完整hosted red | exit65／15.825s；18tests／5suites，新增case6issues（empty錯誤型別／純空白未拒）、既有case2issues，真到testbody | 7277e72a391d7c011ef5598f9fbb97dfff21d152abdbbf8855ec1a20069f7c0d |
| 最小guard後green | exit0／9.744s；App／test重新編譯，18tests／5suites全pass，新增及原failed case均實際執行 | 018d3d32fa46cd765bbdf6d95676257fec5ac4b3dac0e30427218cc9b6f68178 |

原始argv／env／HEAD／source狀態與logs在B1_RUN/logs/B3/blank-config/{red,red-full,green}-result.json及對應log；DD是本輪blank-config-repair-DD，結果各自獨立xcresult。原17testfailure保留為歷史，沒有用0tests或新舊數量推論通過。待獨立Tester完整hosted／PKCE與Reviewer，尚未解除B3成果gate；baseline-final／E009preflight與post仍未驗。

主對話green後的strictformat發現新增test字典行長／trailingcomma，僅對新增字典換行並補尾逗號，strictformat重驗exit0；canonical同列hash已更新。最終格式快照交Tester重新編譯／測試，不把先前green冒稱精確最後bytes驗證。

### VO-RB3 獨立 Tester 完成

Raman verdict VO-TRB3 passed、required fixes0。正常host親跑最終格式快照hosted18tests／5suites exit0／9.591s，test確實重編；PKCE完整一次67pass exit0／5.002s；兩者0fail／error／skip／blocked／unknown。兩檔strictformat／SwiftLint／diffcheck通過，canonical修後SHA相符，其餘21檔原hash相符、23newpaths不存在；trackedfiles／index／HEAD在測試前後不變。
外置B1_RUN/logs/B3/blank-config/tester-summary.json及tester-*含完整raw／逐case／argv／env／snapshot；hosted raw SHA eebd96c7491f8d0aba196d2c6ffb2290a3e61b310f45f681f9be73a93d933a48，PKCE raw SHA 2452e62101c5ce3f3c22bbf15c55cfbe61b15047552ae301af2bd248f97bab96。
補充xcresult新版summary介面在Tester受限上下文因TestReport cache permission exit64受阻，保留stderr，不用它判主對話權限或測試失敗；legacy讀回exit0，確認18declarations／19參數化invocations成功與無actionissues。沒有修環境或將blocked算pass，必要testbody／rawlog與legacyartifact已到達；此補充介面限制不冒作B3pin或post通過。最終成果仍交Noether，不由Tester自判Reviewer gate。

### VO-RB3 最終成果審查

Noether正式VO-RB3 approved、required fixes0、unresolved0；已納Raman最終18hosted／67PKCE、formatlint／hash與原bytes保持證據，確認bounded diff與四artifacts／現行配置說明符合契約，原期待未弱化。只解除空白配置行為阻擋，不代替B3final／pin／post；先獨立behaviorcommit綁修後基線，再接續既有B3必要檢查。Human既有topic commit／push／DraftPR授權沿用，不自行merge。

## 接續 B3：受限修正後獨立 final 基線及 E009 拒絕

VO-RB3獨立fix commit ccf9d21cda0f41db36bc8b0caf24afc7777ff5b2，hooks全部通過。主對話在乾淨已提交feature tree，使用同一B3 sourcepackages copy／固定Apollo／HTTPHTTPS deny／正常host／標準sandbox與modulecache選項；來源仍在唯一spec的old位置，沒有提前搬移。重用green argv，移除resultBundlePath、action改build、DerivedData改本次repaired-baseline-final-DD；env／build設定不變。完整實際argv／env／HEAD及logSHA在logs/B3/blank-config/baseline-final-build-result.json。

| 必要項 | 真正到達結果 | log SHA-256 |
|---|---|---|
| 獨立baseline-final App build | exit0／15.220s；乾淨修正source與依賴實際編譯連結，不是hosted test artifact | ad6a9c7ff3062fec892474102f6022d2681499f6797eba4fd4ed9d14284f5bfa |
| 當前E009 launcher重新compile | 未改source，Swift6 strict／warnings-as-errors及既有modulecache參數；exit0／0.847s | emptylog SHA e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 |
| 當前launcher --self-test | exit0／0.372s，self_test_passed=true；live_launch／credential_input=false | 5ae135adf013f700ec5e6808de945122707596c7c33136f8bd3d20afd76710fa |
| 原pin --preflight --app-bundle 本次App | exit2／0.019s，App bundle或執行檔指紋拒絕，未launch | aa5df3d2fa75e49bd5ff22957bfb6f20799c4a32f3bfd6eb6f6547a523549a6f |

來源／產物身分與SHA只見spec本輪停點；外置baseline-final-identity.json與launcher-current-{compile,self-test}／baseline-final-preflight-result.json存完整command／sourcehash／launcher binaryhash／exit／logSHA。bundle ID／executable name、檔案存在／可執行核對正常，實際binaryhash與原pin不同；不是以沒有source硬編碼推論相容。launcher與歷史pin／hash／receipts原樣保留，不將unsigned新artifact視為歷史binary重現，也不追認真人驗證。
B3 execution blocked，source尚未搬移，B4–B5未開始；本次已解除空白配置阻擋，但沒有解除pin邊界。移後source／資源／tests／入口與最終pin相容性仍未驗；不可把本次baseline digest當移後final pin。最小必要下一步：由Human決定是否另行授權新版本現行pin的受限契約，列明精確允許差異與最終來源／recipe／artifact綁定，保留舊證據並經獨立審查後再執行；未授權前不改pin、不搬source或進後批。最新證據交獨立Reviewer分類，不由作者放行。

### 接續B3停止證據最終獨立審查

Dewey文件／停止處置approved、required fixes0、unresolved0；B3 execution blocked／BL-E9有效。已獨立核四rawlogSHA、實際App及launcher digest、身分與原pin保持，確認拒絕在配置輸入／launch前；兩修後SHA符合ccf9d21與唯一原列，其他60檔原hash保持，B3–B5共62old仍原位且new不存在。dev乾淨／a554a4f，feature僅三指定文件變更。
僅交付新pin停點證據，不更新pin或宣稱移後final已驗。Human另行pin契約仍需綁最終source／recipe／artifact，本次baseline digest不直接提升final pin；本輪按既有授權提交證據並push同DraftPR69，交Human review，不自行merge。

## VO-PIN3／B3 本輪開始交接

本次Human授權精確更新現行pin；可在同B3內先搬移與驗證、再綁移後final artifact更新pin。所有精確路徑／允許差異／來源投影／rollback只引用唯一spec VO-PIN3與B3列，不維護副本；舊07335a00baseline失配仍保留。固定本次normalhost／標準sandbox／既有B3 SourcePackages，與ccf9d21相同unsigned／offline flags；project改用spec new，post-host-DD跑build-for-testing→test-without-building、post-final-DD只跑build，兩DD與舊產物分開。實際argv及環境存本次logs/B3/pin-current；最終產物不在pin後重建。PKCE改用new tools path，67 cases需真到達；hosted18tests5suites需真執行。

- Goal：完整完成E013搬移與現行E009新產物pin綁定，入口保護與歷史證據保持。
- Non-Goal：不改App行為／正式API／root graph／signing／storage，不做live或新增工具／圖面。
- In-Scope：唯一spec的B3 Written／Deleted列、既有B3適用Modify與VO-PIN3兩項明確例外。
- Out-Of-Scope：B4／B5在本批gate前、Runtime重構、fixture／舊結果改寫、真人流程、依賴更新及merge。
- ReadOnly：未列寫入者，含全部正式能力／正式tests／lock內容／ccf9d21兩檔修後bytes、歷史binary與receipts；launcher其他內容只讀。
- Written：唯一spec B3 new23檔及同列project／README例外；沒有另新增repo檔案。
- Deleted：唯一spec B3 old23檔；集中歸屬所需，反向mapping與批前snapshot可回復。
- Modify：僅spec留原位B3適用列與VO-PIN3的新pin literal／E009追加收據、四正式文件；搬移檔的例外歸Written不重疊。
- TestCase：TC-VO-002／005／008／009／010／011與TC-VO-013（新pin接受final、wrongID及tampered拒絕、source投影與commit tree／artifact綁定）；必要newproject build／hosted18／PKCE67、plist／fixture／操作preflight真正到達；補充hash／link／diff／format不能代替必要項。

實作前交Plan-Reviewer approved／required fixes0；數值尚未量到就標待測，不先填新pin。完成後Tester→Reviewer兩gate，完整B3 topic commit→依唯一spec建立commit-binding.json並核commit tree／artifact→PR明示source commit／binding位置與指紋及核對結果→push同DraftPR69，再續B4／B5既有授權；不逐批重問。若不在精確契約內或驗證未到達則依既定停點停止，不把pin授權擴成真人或安全設定授權。

### B3／VO-PIN3 Implementer完成交接

相同九欄與唯一spec集合，23檔完整搬移及接線／current docs／E009 pin與追加收據已處理。170 build inputs封存，pin取獨立post-final binary，非舊baseline；尚未commit，不捏造source revision。外置prefix B1_RUN/logs/B3/pin-current，所有result含實際argv／env／baseHEAD／sourceProjection／logSHA。

| 必要檢查 | 主對話真正結果 | raw log SHA |
|---|---|---|
| 移後host build | exit0／15.639s，實際source／test compile | 23ef97c54b20e7d5726b2cb4842d582bf14d36f8ec128a2df1d2d2f3d96394e3 |
| hosted body | exit0／6.359s，18tests／5suites真pass | 8d503b44828b6cd8b686c5466755827ecce55fd85728513a98edb2f541f119e1 |
| PKCE | exit0／4.653s，67cases真pass | 8442fa101faecb8dc6be195ac532509e9ee61f39c2c7fae09dbb0f9b8025c751 |
| 獨立final build | exit0／11.925s，non-test App | 68c2ef01222d0a878a393574d4b27bdb175f8cacacf54fa11b151b3a6b8817b3 |
| launcher compile／selftest | exit0／0.911s及0.432s，無launch／配置 | compile空log；selftest 5ae135adf013f700ec5e6808de945122707596c7c33136f8bd3d20afd76710fa |
| fixed App preflight | exit0／0.017s，credential_input_performed=false | 69b98da3097d564adf658ec33d3fc3c2a1494a06f862f497b1c59ea5387be7af |
| wrongID／tampered controls | exit2拒絕／0.008s及0.009s，沒有launch任何副本 | 各aa5df3d2fa75e49bd5ff22957bfb6f20799c4a32f3bfd6eb6f6547a523549a6f |

精確pin／來源投影與artifact hash只見spec／E009 current收據，避免另一套逐檔清單。後續Tester親驗hosted／PKCE／launcher正負檢查與hash／link／format，Reviewer給明示verdict；通過後完整B3commit並真核commitbinding，才可push／進B4。原歷史blocked保持當時定位，不當目前失敗；目前只待獨立與commit gate，未自判approved。

### B3 獨立Tester首輪執行條件修正

Godel首輪hosted18／5suites（19invocations）、launcher compile／selftest及preflight0／2／2、170inputs／hash／links／history／13Swift formatlint均通過，sourceRF0。PKCE誤用受限sandbox：65pass／2error，兩loopback cases在bind被拒，assertions未完成，保留原receipt且不算pass。RF-TPIN3-01為缺正常host獨立PKCE；已在既有授權內要求同argv／env改require_escalated正常host補驗，不改系統權限，不以side限制推論main狀態。新條件另存receipt，待Godel明示RFclosed與完整verdict才放行。

### B3 獨立Tester正常host補驗完成

Godel RF-TPIN3-01 closed，最終Tester passed／required fixes0／unresolved0。正常host明確require_escalated、同argv／env補跑PKCE67pass／0error／skip／blocked、exit0／5.782s，兩個loopback cases均真完成；raw SHA bd79c8961ad5b5d93eef13348c381b8603d64b6d30d8ae1ddb1e2f1cfdbfcb4a，另存tester-pkce-normal-host.{result,argv,env,cases}.json及raw.log，舊65pass2error保留。
獨立hosted18／5suites、19invocations pass（5.953s，raw SHA92e6c6eec95a91c9cada5d208dc0b6e3ca29f203a68b697d44f01963132ce33f），launcher compile／selftest與preflight0／2／2、13Swift formatlint、170source mode/blob/SHA及fixedartifact前後保持均通過；完整tester-summary.json。postcommit-binding仍待，不提前聲稱完成或進B4。

### 完整B3 precommit成果最終審查

Helmholtz最終approved、required fixes0／unresolved0，唯一帳本現況RF1 closed；已納Godel最終passed0與完整23檔／21puremove／refs／README／170inputs／fixedApp／launcher保護。固定Apollo checkout末查tracked乾淨、revision仍38c202227d0f09508e573dcf22f54885cfb0c5d4。現在只准完整B3commit後實核binding，binding未完成前不push／不續B4，不把precommitapproval說成postcommit已驗。

## B4 開始交接與適用基線命令

B3 postcommit已approved0並push0b6c39f；source／binding指紋只引用spec，不重複維護。全程原feature。B4 E014／三十路徑與允許差異已鎖唯一spec，先正常host離線baseline build-for-testing→完整test-without-building→獨立build，source仍old。沿用本次固定B3 SourcePackages、-disableAutomaticPackageResolution／-onlyUsePackageVersionsFromResolvedFile／-skipPackageUpdates與Debug／platform=macOS／CODE_SIGNING_ALLOWED=NO／CODE_SIGNING_REQUIRED=NO／CODE_SIGN_IDENTITY=；project／scheme改為B4唯一表與GitHubConnectionVerification。本批輸出／modulecache／tmp／packagecache分到B4目錄，baseline與post各獨立host-DD及final-DD。
僅程序注入GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE=1；清除GITHUB_CONNECTION_VERIFICATION_MODE／GITHUB_CONNECTION_VERIFICATION_RECEIPT與兩RIVET_VERIFY clientkeys，不dump繼承值；GitHTTPHTTPS拒絕、GIT_TERMINAL_PROMPT=0。完整實際argv／env／HEAD／toolchain／rawlogs存B1_RUN/logs/B4，各case真正到達才pass，完整case集合用baseline與post名稱核對，非比失敗數。

- Goal：持續連線獨立驗證App完整集中E014，維持受控offline build／hosted入口、原資源身分與production獨立性。
- Non-Goal：不改App／DPK／OAuth／取消／儲存行為、簽章／profile、正式API或合併Runtime。
- In-Scope：只引用spec B4三十Written／Deleted與其例外、留原位B4 current導覽及topic證據／狀態。
- Out-Of-Scope：其他批次、真人OAuth／API／DPK、normal LaunchAction、讀真profile或credential、全域環境修復及新圖面／工具。
- ReadOnly：spec不可寫者；production與正式tests／rootgraph、B3 source／pin／fixedartifact／receipt保持。
- Written：spec B4 new30檔，project／README明列例外隨Written；無額外新增。
- Deleted：spec B4 old30檔；完整逆mapping與批前0b6c39f bytes可回復，不覆蓋無關修改。
- Modify：僅spec留原位B4適用列；無RootPackage／lint或test期待變更。
- TestCase：TC-VO-002／006／008／009／010；必要baseline/post App與hosted fullsuite、真guarded hosted launch／isolation／audit、plist／entitlements原bytes與build身分。post獨立SwiftPM scratch實際build五正式targets GitHubIntegration／RivetPRInbox／RivetPRReader／RivetPRReaderWebViewBridge／RivetPresentation，並跑filter packageDeclaresTheLockedTargetGraph|targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports，必須真到兩個正式static test bodies；不要跑會真增刪Keychain的整個GitHubIntegrationTests。補充links／hash／refs／formatlint不代替必要項。

Production recipe沿既有swift offline標準sandbox參數，僅scratch/cache/modules改B4獨立目錄，從既有barecache固定Apollo seed、不更新版本；順序失敗即停。新App hosted suite僅無真I/O的既有受控路徑，不宣稱所有constructorfake；具體邊界見spec。baseline必要項真正完成且Plan-Reviewer approved0才搬移；post Tester／Reviewer approved0後完整commit／push，再續B5；不擴無關修正。

## B4 baseline compiler assertion：停止搬移

主對話以正常host／標準sandbox、既定offline／unsigned與B4 unitguard原source執行baseline-host-build，source HEAD0b6c39f；exit65／16.176s，raw SHA cf4f6e757ea86d24e4e3917c10b3fc5a4a7d872a196641f9f84c4b51bc71ade1，完整argv／env／log在B1_RUN/logs/B4/baseline-host-build-result.json及log。
失敗階段是GitHubConnectionVerificationTests的SwiftCompile，檔案GitHubOAuthAuthorizationSessionTests.swift；Apple Swift6.3.3 frontend內部Assertion failed: (!firstType->hasTypeVariable()), checkRequirementsImpl at Requirement.cpp:289。stack定位authorizationUsesStatePKCEAndNoSecret()第12行method內，第16–17行Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })表達式的type check。這是compiler assertion crash，並非test expectation failure或已查證的權限／manifest／signing阻擋；更底層原因及可行workaround仍unknown，不宣稱有已驗證修法。
App sources已實際編譯／連結，但test bundle未成功完成；完整hosted bodies、isolation／audit／guarded入口、獨立baseline-final及所有B4post／production獨立驗證均未執行，不能以App link或其他檔編譯成功算完整通過。後兩個既定baseline命令未繼續。B4 source尚未搬移／修改；B5未開始，B3固定artifact／pin／binding保留。
既有授權只許搬移／路徑接線／相關斷言；這個型別推斷表達式不屬路徑修改。本輪不改test期待、不skip該case、不加放寬編譯／安全flags、不換版本或重建B3。最小下一步交Human：另行授權限定該test表達式的顯式型別註記候選（例如只將query binding標為[String: String]、保持原表達式與所有expectations），先取得受控red／green證據與獨立審查，再重建B4必要基線；此候選尚未套用／驗證，不保證解crash，不自行實作。

Goodall本次B4契約充分性正式approved／0 required fixes／0 unresolved；不取代baseline，未宣稱hostedbody或final通過。主對話已查明compilerassertion及表達式位置，底層原因仍unknown，交獨立Reviewer核原始證據及停止處置。

### B4 阻擋文件／停止處置最終獨立審查

Ramanujan正式approved（僅文件與停止處置）、required fixes0、unresolved0；B4 execution仍blocked，B5不放行。已核actualargv／rawSHA／exit65／16.176s及Swift6.3.3 compilerassertion階段，未把App link當hosted pass。B4三十與B5九個oldhash相符／new不存在，B3的170source mode/blob/SHA、固定App七檔／binary／tree、launcher pin／recipe／bindingreceipt均保持，無source變更或重建。lowercause／顯式型別候選仍unknown／未驗，不越界修正；按原授權僅交付本輪三文件證據、push同DraftPR69交Human，不宣稱topic完成。

## VO-RB4 本次受限修正交接

以同原feature及3818c7d為起點，先保留／核對原baseline compilerassertion rawSHA與sourcehash，使用同B4 baseline-host-build argv／env正常host離線重現（仍oldsource）；只在契約獨立approved0後套用一行候選。後續同flags／toolchain／cache與unitmode的build-for-testing→full test-without-building→獨立baseline-final build，實際命令／source指紋／HEAD／rawSHA另存B1_RUN/logs/B4/type-annotation，red／green分開；blocked／0tests不算pass。不rebuild B3 fixedApp，不改B3receipt。此為compiler相容驗證，既有test全數真執行，無需新增行為test或refactor。

- Goal：驗證單行型別候選能否解除B4 testcompile assertion並完成原guarded suite基線。
- Non-Goal：不改runtime、test expression／expectations、Swift版本／flags／signing／storage，不新增public能力。
- In-Scope：僅spec VO-RB4 old測試檔一行與四既有文件；相容修正與搬移分開commit。
- Out-Of-Scope：搬移及其他source內容修改、skip／縮小驗收來避crash、真人流程、版本／安全設定／工具圖面工作。
- ReadOnly：引用spec VO-RB4其餘內容，特別B3固定170inputs／App／pin／binding與正式source／tests保持。
- Written：空集合。
- Deleted：空集合。
- Modify：只引用spec VO-RB4一行型別註記與授權／證據／狀態文件；不以搬移例外藏入。
- TestCase：TC-VO-014原compilercrash適用red／一行candidate編譯green／完整hosted實際body與資源／audit／guarded入口、獨立App baseline-final、限定test formatlint／diff、其餘hash及B3綁定保持；候選無效或新超界問題先停。獨立Tester需親跑正常host必要suite，Reviewer approved0才解除BL-B4；完整B4原post／production驗證gate仍保留。

Plan-Reviewer先明示本次contractapproved0才改test；green不自動放行B4，Tester→Reviewer後先獨立修正commit／修後hash綁定，再依原B4契約繼續，不重問已授權的其餘批次。

### VO-RB4 A實測未解／B開始交接

原source本輪red正常host exit65／6.986s，rawSHA3318bcc1ededd9f5892cc6251faf00aa6145cef4441da175ece301e329a2b1fc。Mendel契約approved0後A只加query binding型別，green-host-build仍exit65／5.215s、同assertion／同表達式（rawSHA f58b0ac76ce81390853afa30610fba3a96662afe62f73a6963b724e5f1a866ae）。未跑testbody/final，未算green；A已原bytes還原。source namespace限定查找未發現repo自訂Dictionary，但lowercause仍unknown，不宣稱已知upstream bug。
沿同九欄／TC-VO-014及本次限定型別註記目的，候選B精確差異只引用spec最新段；這次Modify仍只同old test一行與四docs，Written／Deleted空。新Plan-Reviewer先核scope／充分性；通過後才同flags/argv/env套B build-for-testing→完整hosted→獨立baseline-final，logs另存candidate-b前綴、不覆寫A。B失敗或判超界即停，不再擴修改。原B4移後及production必要gate仍保留。

### VO-RB4 B結果／C scope交接

B type annotation編譯仍同assertion，未跑hosted或final，raw log／argv／source指紋在type-annotation/candidate-b-host-build-result.json與log。已還原原檔，B段停止／不續搬移；不是測試通過。現C僅提供Dictionary／map的顯式型別資訊，精確候選以spec新段單一來源為準；仍同九欄與TC-VO-014、四docs＋同old test，先新Plan-Reviewer檢scope再套用，紅綠／完整suite／獨立gate仍必須真到，sourceHash原列保留。若scope不符或需非typeannotation更動則blocked，不用既有approval擴範圍。

### VO-RB4 C 實際結果／停止契約

Hubble 獨立 Plan-Reviewer 對精確 C scope／contract approved，required fixes=0、unresolved=0。main 依同一 B4 recipe／正常 host／標準 sandbox／固定 offline dependency、unitmode 與 unsigned 參數套 C；`candidate-c-host-build-result.json` 留完整 argv／程序 env／HEAD／source SHA，raw log 與同名 receipt 在既有 B1_RUN 的 `logs/B4/type-annotation/`。build-for-testing exit65／6.319s，raw SHA `a65e8a7437844c24863e8d1b88cc366d554a9cf12e4d5f7422f62b2d7310e397`。A／B 及原 red 的失敗與 log 不覆寫。

這次未出現原 assertion；失敗階段為 GitHubConnectionVerificationTests 的 SwiftEmitModule。三處都同時可見 GitHubIntegration public 型別與 GitHubConnectionVerification internal 同名型別，diagnostic 為：

| 原測試位置 | 明確診斷 | 判定 |
|---|---|---|
| GitHubConnectionCoordinatorTests.swift:485 | GitHubOAuthAppConfiguration ambiguous for type lookup | test module emit failed；不是 body expectation failure |
| GitHubOAuthAuthorizationSessionTests.swift:256（C 暫時多兩行；還原後 :254） | GitHubOAuthAuthorizationSession ambiguous for type lookup | 同上；超出原 query 表達式 |
| GitHubOAuthDataProtectionStoresTests.swift:210 | GitHubOAuthDataProtectionStores ambiguous for type lookup | 同上；其他 test 不在本次限定修改集合 |

這三處是已查證的當前編譯阻擋；原 assertion 的底層因果，以及型別消歧後是否還有其他診斷／測試失敗，仍 unknown。沒有完整 test bundle，後續 full guarded hosted bodies、資源／audit／入口、獨立 baseline-final、B4 post 及 production 獨立驗證皆未執行；未跑不是 skipped-pass。不可用診斷改變宣稱無回歸或原問題完全解決。
main 已精確逆轉 C，原 bytes hash 引用 spec 原列；沒有失敗 source 修正 commit，沒有 B4／B5 搬移。只保留四 docs 的授權、獨立 planning verdict、實驗／停止證據。獨立 Tester 重現與 Reviewer 停止處置審查尚待，沒有宣稱 execution gate approved。

最小必要下一步是由 Human 決定是否另准三處限定測試型別消歧（其餘變更集合須由實際 compiler 診斷鎖定，不預先擴為整個測試重構）。若獲授權，先確認原測試意圖與應選模組、建立精確 contract 並獨立 approved0，再作受限 red／green、完整 guarded suite／baseline-final；原 B4 移後／production gate 仍保留。本輪沒有實作消歧、不更新編譯器／依賴／flags／權限或行為；不跑真人流程，B5 不放行。

### VO-RB4 獨立 Tester 重現證據

Parfit 已以 require_escalated 正常 host 真跑精確 C；argv／env overrides 與 main C 相同，候選整檔 SHA 同 spec。獨立 build-for-testing exit65／5.322s，raw SHA `c17e05a51b2497b9911a8872a8796f298fffea568b97f31f4d183365ed17c868`；原檔於 finally 精確還原、mode 保持。`tester-c-classification.json` 明示 verdict blocked：相同三處 test module emit 型別歧義、log assertion marker=0／body success marker=0；hosted／final 沒有執行，不能稱完整通過。
獨立 `tester-c-protection-result.json` 已核 HEAD／branch／index 不變、B4／B5及B3 integrity保持，fixed App modes／hashes及整個pin收據目錄不變，main C log未覆寫、non-Markdown變更空。完整命令／環境／前後snapshot／還原與結果於同 `logs/B4/type-annotation/tester-c-*`；不把保護查核取代必要 suite。停止文件仍交獨立 Reviewer，沒有有效修正或前進 gate。

### VO-RB4 獨立停止處置審查完成

Pascal 最終 verdict approved，required fixes=0、unresolved required fixes=0；僅限本輪四 docs、失敗分類與停止處置。已核必要 receipts／raw SHA、A／B 原 assertion、main／Tester C 三歧義與 exit65、source bytes／mode 還原及無 source diff。Reviewer 明示 execution 仍 blocked：原 compiler 根因未證實解決、完整 hosted／final／post／production 未驗，B4 不搬、B5 不進；三處消歧須 Human 另定精確契約。依原授權只提交本輪四 docs 至同 Draft PR69，交 Human review，不把文件 approved 當作 source 修正完成。
