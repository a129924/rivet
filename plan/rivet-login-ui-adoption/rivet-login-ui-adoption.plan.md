# Login UI 元件化與選擇性採用計畫

> 現行契約：本文件末段「R3：2026-11-18 E011 凍結與驗收歸屬修訂」優先適用於本輪。前文原規劃及 I01／I02 授權、實作與驗收保留為其版本歷史；不得以本輪要求倒推原作業越權，也不得把舊驗收直接套給新 host。

- Topic：`rivet-login-ui-adoption`
- 日期：2026-11-17
- Branch：`feat/rivet-login-ui-adoption`
- Base：`origin/dev`／`1f31b35604adb5bb36326e52f9d6dbcff0cac763`
- Human 已接受對話方案並授權受限實作、無重大問題時 topic commit／push／Draft PR；本文件尚待獨立 Plan-Reviewer。

## Goal

以既有正式 Login 為基礎，選擇性採用已驗證能力，交付可組合 SwiftUI 元件、呈現模型、局部狀態及 callbacks，移除正式來源展示耦合。文件記錄既有 VO 對應，實際外層協調留後續。規格以 [technical-spec](../../analysis/rivet-login-ui-adoption/technical-spec.md) 的元件表、公開 initializer／content schema、狀態及 VO 對應為受限契約。

## Non-Goal

不重建品牌／布局／七態或登入 VO，不交付真實認證、request 建構、service 呼叫、認證 async／取消管理、production mapper／Adapter、儲存、session／clients、產品 App 整合。不擴 BC、package／target 或整個專案架構盤點。

## In-Scope

- Internal LoginMethodSelection、LoginOAuthSection、LoginPATForm、LoginStatusNotice 與公開 RivetLoginView 組合；不碎片化每個 label／button。
- Parent-owned phase、局部 form／focus state、既有六個 intent 與新增 createPersonalAccessToken；content 模型與相容 initializer。
- E011 同正式元件加 fake inputs／events，相關測試、採用紀錄與長期 UI／入口摘要。
- 文件層 UI／VO 對應與 UI lifecycle v2；Graphify 有界導航及 PR Lens 實際 diff 理解輔助。

## Out-Of-Scope

OAuth／PAT concrete service、真 VO／service runtime 接入、browser／network／Keychain／DPK、session／clients、production mapper／Adapter、E013／E014 搬移、舊 topic 證據改寫、系統架構重畫、merge／release／發布。

## 檔案操作範圍

`Written` 是新增檔案，`Modify` 是修改既有檔，`Deleted` 是整檔刪除。移除重複 View 片段不等於刪檔。

| 標籤 | 受限範圍 |
| --- | --- |
| ReadOnly | Package.swift；設計原則；GitHubIntegration 既有來源／長期契約；原型；舊 rivet-login-ui analysis／plan／驗收；E011 README；E013／E014；舊凍結 lifecycle 圖；既有 graph、工具規範與 PR Lens config |
| Written | Sources/Presentation/Login/ 下的 LoginMethodSelection.swift、LoginOAuthSection.swift、LoginPATForm.swift、LoginStatusNotice.swift、RivetLoginContent.swift 及必要 LoginStyles.swift；Tests/RivetPresentationTests/ 的元件行為測試；本 topic 四 artifacts；docs/feasibility-adoption.md；原 UI 圖目錄下 lifecycle v2 規格／HTML／凍結快照／receipt／視覺 sidecars |
| Modify | RivetLoginView.swift、RivetLoginPresentation.swift；受影響正式 Login 測試；E011 host／model／tests；docs/presentation/login-ui.md；README.md／docs/architecture/README.md 中相關過期摘要；圖面 BUILD.md 及現行文件連結 |
| Deleted | 無 |

不改 Package.swift，不需新 target。E011 README、舊 topic 與舊凍結圖只讀；v2 為後繼版本，不覆寫舊 bytes。PR Lens graph／render 只放 repository 外 topic scratch。計畫允許的證據寫入限本 topic plan 目錄與列明圖目錄；不另設必要 summary／release artifact。

## 採用與實作順序

1. 以 requirements 的有界 audit 為基線，重用正式 phase／intents／PAT helper／字級／品牌／資源；只調整本次必要能力。既有依賴已滿足，不等待認證服務。
2. 先更新長期 UI 契約及相關過期摘要，保留舊來源／限制；按 technical-spec 拆分責任元件與呈現模型，維持40:60穩定布局、七態、表單 identity 與 focus 取消保護。
3. 新增 createPersonalAccessToken intent、content／canCreateToken 預設參數；更新 exhaustive switch 與 E011 消費端。View 不持 URL／開 browser；E011 本地提供 demo content 與 fake events，不呼真 VO／service。
4. 保存新版有界行為證據與圖面 receipts，更新獨立 adoption record；所有程度依實際證據判定，不因計畫已核准標為已採用。
5. 交獨立 Tester、Reviewer；沒有重大問題時由獲授權 Implementer 完成 topic commit／push／Draft PR，停 Human review。

## TestCase

| ID | 驗證情境與接受條件 |
| --- | --- |
| TC01 | 舊 initializer／trailing closure 可編譯，新增 public data 可由一般 consumer 使用；七態與新增 intent 的消費端完整 |
| TC02 | PAT 外圍 trim、保內部空白、空值不送、送出即清／隱藏、Show／Hide、failure 重填、離開／Reset 清除；字級／content 更新不重建 form |
| TC03 | GitHub／PAT 選擇、Back、Cancel／Escape、Retry、Submit 事件正確；create 停用不發事件、啟用只發一次且不清輸入 |
| TC04 | Parent phase 不被 View 自改；E011 fake inputs／events 驗介面，無 GitHubIntegration import、request 建構、service 或 Outcome mapper |
| TC05 | 七態與兩種 failure origin、Light／Dark、780×500、13／17／21 pt 操作可捲動到達；快速切態／離開不發過期焦點／宣告 |
| TC06 | Human VoiceOver 聲音與最終 UI 接受；可 pending 交付 Draft，不能以舊結果或自動檢查冒稱新版通過 |
| TC07 | 正式 Presentation／E011 tests、root Swift tests、Demo build、受影響 Swift format／lint；既有無關 findings 分列，不稱全域通過 |
| TC08 | 文件 VO 對應與實碼一致；Outcome 不被當成完整 phase／session，connected 只表示本次登入完成 |
| TC09 | Archify v2 showcase／deliver／四尺寸 visual-check 證據完整，人工檢視截圖與 pending 狀態分列；PR Lens 如可用須對應真 diff |

保留既有有效測試，新增測試覆蓋行為與接線，不以重複資料欄位斷言代替互動驗證。沒有執行或環境受限的檢查明列，交 Reviewer 判斷是否重大問題；不得自稱通過。

## 工具節點與 fallback

### Graphify

只用 pinned graphifyy 0.9.73；每次 CLI invocation 均有 `GRAPHIFY_NO_AUTO_REFRESH=1`。只對存在且可確認來源 revision 的 graph 執行 bounded query／path／explain，query budget 1500，重要關係再查 source。基線標準 graphify-out/graph.json 不存在，使用 targeted source reads，不建立 graph。Runtime 缺失／不相容、graph 過期或 query 失敗，記具體限制回原始碼；不 install／extract／refresh／provider／upload／hook／config。

### Archify

限現有 UI lifecycle v2，不擴為系統架構，不把文件層 VO 對應畫成已接線 runtime。作者繁中，Viewer UI／HTML lang 英文 fallback，不發布。讀 lifecycle／common schema，作者 JSON 後 showcase validate 全部9checks／0errors／0warnings；deliver 凍結 exact spec bytes 並保存 receipts，再用 repo-root visual-check 四桌面尺寸並人工看截圖。pending／skipped／非零不稱 pass；只修診斷項，連續兩輪未改善則停止圖面接受並回報未解診斷。不得手改已交付 HTML。

### PR Lens

只有實際 base／head 或有界 diff 後才根據 `git diff --find-renames` 做 local change map，記真 SHA 與未commit狀態、不造 head。包含相關 unchanged 鄰居與 file refs。只用 pinned CLI0.11.0 validate／render，產物在 repository 外 topic scratch。存在 .github/pr-lens.yml 時先讀並套用，無適用 config 才 --no-config；基線該檔不存在。不改 repository config／.pr-lens／.gitignore，不上傳、發布或開server。工具／map失敗或增加閱讀負擔時記限制、回直接diff review；map不是correctness review。本輪尚無實作diff，不產假map。

## 採用紀錄與完成判斷

docs/feasibility-adoption.md 各能力記來源版本與來源關係、正式需求、適用條件、選定／排除理由、必要依賴及滿足方式、採用方式、程度、正式位置／實際消費端接入、行為證據、缺口、觀察日期與歷次更新。程度與重用／調整／重寫／不採用分欄；缺tracker不當未採用證據。LU-A04在新版實作、接入與行為證據未齊前維持部分採用；Human聲音／最終UI接受未驗明記pending，不等於實作或UI已全面接受。

## Review、Git 與停點

四 artifacts 落盤後先交獨立 Plan-Reviewer 明示 approved，才可實作；其後 Implementer→Tester→獨立 Reviewer。Plan-Creator 不自審也不實作。

Human 已明確授權：本 topic 沒有重大問題時直接 commit→push→Draft PR→Human review，不重問相同授權。Commit 前仍依 git-commit-convention 從 staged diff 檢查單一 topic 語意邊界與 message，僅納入本 topic；PR target=dev，維持 Draft。Human VoiceOver／最終 UI 接受 pending 本身不阻擋 Draft，但描述必須揭露未驗與證據限制。若有 required fix／重大問題、未解scope或權限邊界，停止相依動作；不merge、tag、release或發布。

- [需求](../../analysis/rivet-login-ui-adoption/requirements.md)
- [技術規格](../../analysis/rivet-login-ui-adoption/technical-spec.md)
- [執行帳本](rivet-login-ui-adoption.step.md)


## I02 補充：乾淨原生預覽入口（2026-11-17）

Human 在既有 UI scope 要求驗收正式 Login 外觀。本次僅新增 E011 app-local 的獨立乾淨 host，保留既有展示 host／Controls／LoginDemoCopy，不擴正式 library 或真登入能力，不重開架構或新增 gate。

- Written：`experiments/E011/Sources/RivetLoginDemoRuntime/LoginPreviewConfiguration.swift`、`LoginPreviewHost.swift`；`experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginPreviewConfigurationTests.swift`；本 topic `evidence/clean-preview-implementation.md`。
- Modify：既有 executable `experiments/E011/Sources/RivetLoginDemo/main.swift` 增加 `--preview` 分流；`Sources/Presentation/Login/RivetLoginView+Previews.swift` 只替換 footer／failure 展示文字；`docs/presentation/login-ui.md`、本 topic technical-spec／plan／step。
- ReadOnly：Package.swift／Package.resolved、正式 View／content／component／intent 實作、既有 Demo host/model/copy、E011 README、T02／T03／H01–H08 歷史與凍結圖。Deleted：無。
- CLI：同一 `RivetLoginDemo` executable；無 `--preview` 維持原展示入口。乾淨入口為 `--preview [--state <state>] [--appearance system|light|dark] [--text-size <13...21>]`，預設 welcome／system／13。state 為 welcome、pat、waiting、verifying-account、verifying-token、browser-failure、token-failure、completed；非有限／超範圍字級、未知／缺值／重複選項在建窗前拒絕，不靜默改成展示模式。
- Host：單一原生主窗，直接組合 `RivetLoginView(content: .standard)`；不建立 Controls、overlay、debug labels、事件計數或測試選單。CLI 只指定啟動畫面／外觀／字級；重新啟動切換，沒有 timer 或自動完成。
- Parent：重用既有 LoginDemoModel 的 fake event 處理，不呼認證服務／VO／儲存／session。初始 failure 由 preview configuration 提供中性可重試文字，不使用模擬 failureMessage。
- `.standard` 不含 footer 或 failure message；host 明確提供中性 footer `Connect your GitHub account to Rivet.` 與 failure copy，不誤稱它們來自 `.standard`。不修改正式 content schema 或空 footer 行為。
- 原生 wrapper：可在 feature `.build` 新增獨立 `RivetLoginPreview.app`，bundle ID `local.rivet.login-ui-preview`，複製同一正式 debug executable／Presentation resource bundle，不覆寫既有 wrapper，不 commit `.app`。此 bundle ID 在同一 executable 入口預設選擇 preview，即使 `open` 未附參數也不會誤開展示 host；外加 state／appearance／text-size 參數仍由相同 parser 處理。本實作階段只準備，不啟動或停止其他 app。
- 差異驗證：配置／八種 phase 選擇、邊界參數拒絕、中性 copy 與 Demo copy 隔離、fake callbacks不自動推進，受影響 tests、正式 executable build、scoped format／lint／diff-check；不因預覽入口重跑不相關完整 suite，也不重產 lifecycle。獨立 Tester T04 驗證單窗／原生外觀／無展示文字及必要事件；R04 獨立審查後回 HC01，既有 T02/T03/H01–H08 結果保留。本次 preview 不宣稱 Human 已接受，HC01 仍 pending／no merge。


## R3：2026-11-18 E011 凍結與驗收歸屬修訂

### 現行 Goal／Non-Goal／In-Scope／Out-Of-Scope

Goal：保留正式Login既有能力與API，以正式tests／controlled#Preview優先、最小native tool補必要差異，從E011抽離本topic驗收依賴。In-Scope：六項E011定點回復／移除、DEBUG Preview wrapper、直接正式consumer tests、工具自有parent/config/host/fixtures/tests、必要owner文件與新證據。

Non-Goal／Out-Of-Scope：正式core/API/child行為重寫、複製View／VO、E011增補、fake Service／DI、認證Task／timer／storage/session/nav、root target/package設定修改、舊證據刪改或merge。原plan及I01／I02授權歷史有效，不倒推越權；現行R3優先。

### E011 freeze 與精確六項操作

本輪起始HEAD=`44ddbeea6235e9b785b41a9f787c92f52aa85eaf`；current PR base/dev=`d2332bfff25510a3f78c1fbc8b0d2d9cf953b223`。7e5f4fd／1f31b35／ab77391／d233的E011 tree皆為`b6a1e6e1196e64999af9591ec32f09211f1936c6`，故pin d233有來源依據。起始HEAD E011 tree為`a1fd3793fecdccf52c192158939629b58ca7c685`。

| 操作 | 路徑 | freeze blob／限制 |
| --- | --- | --- |
| Modify：逐檔回復 | experiments/E011/Sources/RivetLoginDemo/main.swift | 06fc0e261d862c4dcb5c463fbcecfc92124a9e45 |
| Modify：逐檔回復 | experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoHost.swift | 0519ea65b0c922aa3525472460aa3a3c4040dc64 |
| Modify：逐檔回復 | experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift | 87301e4e536143fca9add64a90b327b6a3d5c1c5 |
| Deleted：僅本PR新增檔 | experiments/E011/Sources/RivetLoginDemoRuntime/LoginPreviewConfiguration.swift | 實用配置邏輯改歸新tool，不留E011相依 |
| Deleted：僅本PR新增檔 | experiments/E011/Sources/RivetLoginDemoRuntime/LoginPreviewHost.swift | 新tool自有parent，不保留LoginDemoModel依賴 |
| Deleted：僅本PR新增檔 | experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginPreviewConfigurationTests.swift | 新tool驗自己的config，勿把測試搬成formal行為證明 |

逐項從指定base/blob回復，不整目錄overwrite。LoginDemoModel／E011 README等原未變項不碰；完成後git tree等freeze是驗證。未commit前以對指定base的逐路徑diff加E011未追蹤檔列舉檢查內容，commit後再核對commit:E011 tree；不可把尚未更新的HEAD tree冒稱working tree已凍結，也不為驗證改index或批量覆寫。Frozen host未傳content，語法預期相容但依.standard使用產品copy，不能稱HEAD重建舊demo語義等效；本輪只歷史引用，不重播，不加formalDemoMode／bundle/footer特判。

### 本輪 ReadOnly／Written／Modify／Deleted allowlist

| 標籤 | 確定範圍 |
| --- | --- |
| ReadOnly | 除上表六項回復外整個E011、尤其model／README；正式RivetLoginView.swift／content／presentation intents／四child／helpers/styles/artwork/resources；root Package.swift／Package.resolved／.gitignore及設定；GitHubIntegration／VO；舊topic與本topic既有evidence；凍結圖JSON/HTML/receipts |
| Modify | 本四artifacts；Sources/Presentation/Login/RivetLoginView+Previews.swift；必要RivetLoginPresentationTests.swift／RivetLoginContentTests.swift；上表三restore路徑；docs/presentation/login-ui.md、docs/feasibility-adoption.md、README.md／docs/architecture/README.md的本topic現況／consumer文字 |
| Written | Tests/RivetPresentationTests/RivetLoginConsumerTests.swift；下表工具package明列新檔；本topic evidence/acceptance-ownership-implementation.md、acceptance-ownership-testing.md、acceptance-ownership-review.md及native／Human後續差異證據（只有實際發生才建立） |
| Deleted | 僅上表三個本PR新增的E011 preview/config/tests；不刪任何舊evidence或圖 |

工具package僅在`tools/acceptance/login-ui/`：Package.swift、必要時自身Package.resolved、README.md、scripts/build-app.sh；Sources/RivetLoginAcceptance/main.swift；Sources/RivetLoginAcceptanceSupport/{LoginAcceptanceConfiguration.swift,LoginAcceptanceParent.swift,LoginAcceptanceHost.swift,LoginAcceptanceFixtures.swift}；Tests/RivetLoginAcceptanceSupportTests/{LoginAcceptanceConfigurationTests.swift,LoginAcceptanceParentTests.swift}。不新增其他產品target或服務抽象。

原不新增package/target的文字保留作原契約歷史；這次例外只限獨立acceptance tool（tools6.0／Swift6／macOS15、Support＋executable＋tests），由Human新授權最小host支撐，須經獨立Plan-Reviewer。Root product/package/target不變，rootPackage blob應保持`af69162fa848074fe62c9a4fd8d4056e3e3c6102`。工具path dependency只取rootRivetPresentation product，不importE011／GitHubIntegration、不copy formalView/VO。

### 實作與TestCase

1. I03先完成六項E011回復及直接正式tests／private controlledPreview，再做最小native工具；無需root設定的工作先完成。若rootreadonly確需變更，停相依工作、提出具體最小proposal，不自行改lock或環境。
2. ControlledPreview按technical-spec R3使用@State與有限onIntent回寫／eventkind-count，保留同formidentity的字級/content更新；原fixedphase/ignoreIntent不能當互動pass。
3. Native理由限獨立NSWindow、resource、標準menu/ReturnEscape/focus/HumanVoiceOver。新tool自有parent/config/fixtures，乾淨.standard主畫面；有限控制在wrapper外／toolmenu，無獨立Controls視窗，無自訂截圖3/4/5/6快捷鍵。新binary只build準備，未取得當下確認不得launch。

| TestCase | 本輪新增／差異接受條件 |
| --- | --- |
| R3-TC01 freeze/ownership | 六項結果逐blob吻合、E011整tree等freeze；model/README未改；rootmanifest/lock/settings與正式corebytes不變；不得整目錄restore |
| R3-TC02 formal tests | 直接helper/content/consumer契約與test-privatefixture/spy，不importE011/GitHubIntegration、不重建VO或fakeService；自己呼spy不算View事件 |
| R3-TC03 controlledPreview | 同root連續phase回寫、form tokenEntry↔tokenFailure、13/17/21字級/content更新保值、ShowHide、Reset清除；實際rendered觀察與parser/parentunit分開；未能運行Preview如實列gap |
| R3-TC04 toolconfig/parent | 八啟動state、system/light/dark、有限13...21與錯誤參數拒絕；有限callbacks、eventkind/count且無token保存；無timer/task/service自動完成；tool自己的unit只證tool |
| R3-TC05 build/resource | 工具獨立build/test、必要scopedformat/lint/diffcheck；newapp資源路徑／bundle載入／view圖示不冒用舊cache；記rootlock前後hash，tooltransitiveApollo解析/cache需求明列，無需無關root全suite重跑 |
| R3-TC06 native差異 | 新app經當下確認後，驗單主窗／乾淨copy／stdmenu／ReturnEscape／實際callback及toolmenu同窗切態、字級/content/formidentity/focus/21ptscroll／代表性LightDark與新資源；每case記source/binary，必要Human聲音另停點 |
| R3-TC07 history/capability | 保留HC01/source3c9baf3／preview42e99fa／binary4d4cf13...、I01/I02及T/R歷史；不把舊tests直接套新host，不把新tool完成當產品認證／session整合 |

本輪只補受影響case，不重跑未改core的全部歷史矩陣。可針對root受影響正式測試而不因此重跑無關BC suites；若新改動或failure需擴大驗證，由Tester列原因。

### 圖／工具／獨立review與交付

既有v2-r1圖表達正式七態而未綁E011路徑，本輪無正式lifecycle變更，因此不改凍結圖、不產新圖，只在可寫UI文字標其舊consumer/受測版本與本輪ownership。若實際發現生命週期語義改變，再依既有Archify流程，不為搬位置重畫。Graphify／PRLens原pinned/bounded/local-only與fallback規則延續；PRLens如重作只能基於實際diff/SHAs，不編造map。

P03獨立planning review approved後才I03。T06只先tests/Preview/build不launch，R06獨立審core/freeze/host/source及差異證據後，才可向Human提出exact新binary的必要native當下確認。確認前可完成獨立source/docs工作，舊4d4cf13...許可不可套新binary。T07只在確認後補native，交獨立R07；受影響HumanVoiceOver／新host接受仍是Human停點，原HC01保持completed。

原topiccommit/push/Draft更新授權有效，依stageddiff語意及requiredfix狀態交付，PR#75保持Draft；不merge。六點交付回報：①freeze版本/tree與六項差異；②formal/tool diff ownership及rootreadonly未變；③tests/controlledPreview實際涵蓋；④native必要性與最小足跡；⑤實跑source/binary/hash/results/gaps與當下確認／舊接受界線；⑥能力採用完成程度與產品認證/session整合仍排除。缺證據保持pending，不寫成pass。
