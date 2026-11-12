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
