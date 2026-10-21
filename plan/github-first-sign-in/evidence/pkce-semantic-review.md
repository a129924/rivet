# U：Human-only semantic review 離線證據

## U03 Implementer 交接（2026-10-21）

來源為 `9f603f81d77040a2e06ad178062e8cfecc4de468` 與本輪受限 dirty 工具修改。獨立 Plan-Reviewer confirmation approved、無 required fix，僅 offline，由主 agent 明示傳達。本文件不是 Tester／Reviewer approval。

### 實作及模式

- 既有 default CLI 不開 semantic UI。新增 private opt-in parent gate：strict OAuth error／UTF-8／4096-byte 完整描述，已知context的 literal／case／URL／JSON／HTML／Base64 variants、URL／control／bidi／24+ opaque identifier-like 序列命中整段拒絕。這是有限辨識，不是任意秘密或編碼防護。
- 候選在當次context仍可用時gate；run_case先detach observer、clear Attempt／observer／fields／body／code及敏感參照，main清除配置後才可能launch。另有cleanup_completed guard，失敗不launch；這是參照生命週期控制，不是immutable memory／OS physical zero保證。
- helper只經anonymous stdin傳一個bounded protocol record。Swift自訂exact two-key parser拒絕duplicate／escaped duplicate／bool-int混淆，不依Foundation last-wins。stdout<=512bytes有限schema，stderr丟棄；parent watchdog100秒，超限／timeout／nonzero／protocol異常歸未知。
- 私有AppKit helper：先密封30秒，Human明示一次reveal最多60秒；文字不可選取/編輯、自動偵測關閉、無copy/export menu、非restorable/sharingType none。這些目前是實作/source facts，尚未完成synthetic互動或OS留痕實證。
- `provider_semantic_observation`是local_human attestation，與原outcome/proof獨立；強訊號衝突歸conflict/indeterminate，不能提升既有遠端證明。

Human離線單一步驟（只在U05完成、Human明確參與後）：

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review
```

此分支不輸入ID/secret、不呼叫authorize/send_token、不建立socket/browser/HTTP。固定fixture schema/hash由獨立Tester／Reviewer提供，工具只投影description、不讀expected label值；SystemRandom在記憶體打散案例。UI不收ID/case/outcome/label；中途只進度，最後輸出SHA256(id)前16hex opaque correlation_id與safe observations，交獨立Tester對照凍結fixture核分。工具不自行score、不預填9+7 Human結果。

自評score方案曾被自動審核拒絕，理由為Implementer不得讀holdout labels及獨立Tester評分邊界。該動作未執行；後改為不讀答案、只輸出opaque correlation與safe observations的替代方案，已獲自動審核允許，無繞過或待追加授權。

### 受控驗證

實際命令：

```sh
python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p 'test_pkce_negative_probe.py'
```

最終 **54 tests passed，exit 0**；原36項及新增18項。新增涵蓋privacy variants/size/shape/token、strict parent helper output、strong conflict、cleanup未確認不launch、run_case/main/observer/request參照清理、default不開helper、校準分支無網路/配置、schema projection不讀label值、匿名pipe及stderr不forward、513-byte child output kill、parent watchdog fail-closed。Swift6 helper在suite內實際編譯，protocol-check模式測1個valid與10個invalid輸入，不打開UI；涵蓋重複/escaped duplicate keys、bool與小數version、extra/null/trailing/invalidUTF8/description超限/總輸入超限。

過程唯一測試探針失敗為mock wrapper frame未走到main而KeyError；修正測試探針後51、54項先後全部通過。這不是production秘密洩漏或被忽略的failure。

### 凍結工具指紋

| 檔案 | SHA-256 |
|---|---|
| tools/pkce_negative_probe.py | 005fb570a60779a221d039cef52562936b498a820ed012624231129f34cb07cc |
| tools/test_pkce_negative_probe.py | 44e5d00344f63b4296860c9b4c40ca1b2525b06e647e286cd556415cf7dbffb0 |
| tools/pkce_semantic_review.swift | 4a9fac413a1144820ad67798c185d1e1abbcb5e9e7e2a3c52f05baa3ce977430 |
| tools/README.md | 8f53ddae7436afb3aed9facb66cb7c9dc79273137a35f9c3f1632b9b254afe16 |

上述tools前綴為 `apps/GitHubSignInVerification/`。獨立holdout freeze SHA `d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5`由主agent/Reviewer明示；Implementer未開啟該fixture內容或expected labels，只依schema/hash整合。

### 尚未執行及限制

- U04獨立Tester、U05獨立code/privacy review待接手；工具現在凍結，不自稱approved。
- AppKit synthetic互動、30/60秒實際view timeouts、copy/export/restoration／異常關閉的runtime QA尚未執行；parent watchdog僅受控mock fail-closed驗證，不冒稱等待過100秒。
- 16-case Human offline calibration **pending**，9/9 decisive＋7/7 abstain未填結果，全unknown不能pass；未自動開UI或代答。
- 新OAuth **0**；未讀App配置、未取code、未POST、未看live原文。P/Q/R/T歷史及共享R→T1/1用盡不改；正常App/API/canvaspassed不重做。
- 無raw live description證據，因此任何將來local_human attestation無法由agent獨立稽核原句；不保證全盲、任意秘密偵測、OS無留痕或physical zero。

### U03 完成九欄

- In-Scope：private parent privacy/cleanup/protocol/attestation、Swift helper、無網路校準入口與synthetic tests。
- Out-Of-Scope：OAuth/live、正式App/API/lifecycle、他人dirty source/tests、holdout建立或答案核標、自動Human校準。
- ReadOnly：所有正式source/API/傳輸與TTY及loopback政策、舊evidence/圖/其它topic/worktree；holdout內容與labels未讀。
- Written：`apps/GitHubSignInVerification/tools/pkce_semantic_review.swift`、本evidence；未建立holdout。
- Deleted：0。
- Modify：`apps/GitHubSignInVerification/tools/pkce_negative_probe.py`、`apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py`、`apps/GitHubSignInVerification/tools/README.md`。
- Goal：已交付可獨立測試及Human明確啟動的offline工具。
- Non-Goal：不自審、不宣稱Human校準／遠端PKCE通過，不做OS零留痕承諾。
- TestCase：54 controlled tests pass與helper實際編譯/protocol-check；US04 Human16case與上述runtime QA pending，交獨立Tester/Reviewer。

## U04 獨立 Tester（2026-10-21）

來源 `9f603f81d77040a2e06ad178062e8cfecc4de468` + U manifest受限工具diff。已讀四planning現行offline更正與U1–U4；外部Plan-Reviewer明示formal/offline confirmation approved，沒有新OAuth或自動Human校準授權。此節只記Tester自己的受控結果，不代U05核准。

### 獨立holdout建立、核標與凍結

Tester獨立建立唯一 `apps/GitHubSignInVerification/tools/fixtures/semantic-review-cases.json`：16純synthetic、3mismatch/3grant/3config/7abstain；七種abstain覆蓋否定/條件/例子/多候選/矛盾/不完整/未知。未讀取、猜測或重建任何歷史live原文。Implementer只收到schema與hash、不提供內容/labels。獨立Reviewer已明示16labels符合U1/U4、approved並凍結：SHA `d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5`，4058bytes；親查仍一致，不為結果改標。此為holdout核標，不是code/UI/Human校準/live放行。

### 親跑命令與實際結果

| 檢查 | 實際結果 |
|---|---|
| `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py`（允許本機loopback的受控權限） | 初版54tests exit0；helper格式修正後完整54tests再次exit0，OK |
| suite內 `xcrun swiftc -swift-version 6` private helper及`--protocol-check` | 實際compile成功；1valid及10invalid bounded inputs，無GUI；stdout<=512bytes、不echo描述 |
| `swift format lint --strict apps/GitHubSignInVerification/tools/pkce_semantic_review.swift` | 初次exit1：indent/line length；回修後親跑exit0 |
| `swiftlint lint --strict apps/GitHubSignInVerification/tools/pkce_semantic_review.swift` | 初次exit2：5snake_case identifier及1alignment，共6serious；camelCase+CodingKeys及單檔format後親跑exit0，0violations |
| 額外helper分段stdin/EOF/trailing測試（compiled snapshot，僅`--protocol-check`） | 尚未EOF時不提前accept；追加trailing後exit2、安全有限output，無UI |
| default無args/help/noTTY wrong及opt-in noTTY | 依序exit2/0/2/2，stderr均空，無helper/UI/OAuth |
| Python AST／pycache／來源hash | syntax pass、pycache0，所有當前hash如下 |

初次format/lint failure交Implementer，Tester沒有改source。修正只helper命名/explicit wire CodingKeys與format，協定仍exact snake_case JSONkeys；舊helper `4a9fac413a1144820ad67798c185d1e1abbcb5e9e7e2a3c52f05baa3ce977430` 為修正前歷史。當前helper已重凍結 `91d570e9f4e9a4b617105b911f2f847b393c3f974275066c5660bebcd116e148`；CLI `005fb570a60779a221d039cef52562936b498a820ed012624231129f34cb07cc`、test `44e5d00344f63b4296860c9b4c40ca1b2525b06e647e286cd556415cf7dbffb0`、toolsREADME `8f53ddae7436afb3aed9facb66cb7c9dc79273137a35f9c3f1632b9b254afe16` 與U03交接相同。只有scratch logs `rivet-u04-helper-format.log`／`rivet-u04-helper-lint.log` 保存純source診斷，不入repo、不含live資料。

### US01–US05 分層

- US01受控passed：known-context literal/case/URL/JSON/HTML/Base64 forms、URL/control/bidi/opaque、strict pure-error/token/mixed/duplicate/trailing/UTF8/非string/4096-byte上限；命中整段不launch。僅finite測試集合，不保證任意編碼或未知秘密。
- US02受控passed：strict exact input/output keys/types/enum/狀態、16KiB/4096/512bytes界線、escapedduplicate/partial/nonzero、stderr不forward；匿名stdin，原文不進argv/env/file。真frame檢查send_request/response/body、run_case Attempt/observer/fields/context與main配置在helper前清理；cleanup未確認不launch，strongconfig/redirect/auth衝突強制conflict/indeterminate。不是physicalzero。
- US03部分passed／runtime未驗證：defaultnoUI、strict invalidinput不開窗、parentwatchdog mock kill/expired、oversizechildkill受控通過；helper source含30s密封/60s一次reveal與copy/export/restoration限制。未開AppKit校準視窗，實際互動、30/60秒runtime、copy/export/restoration與異常關窗仍pending，不能宣稱技術全面禁止或OS無留痕。
- US04準備passed／Human校準pending：獨立16labels已核標freeze。另直接呼叫實際calibrate_semantic_review但注入只回安全indeterminate的fakehelper；socket/authorize/send_token/getpass/subprocessGUI都設禁止，仍16unique case完成，SystemRandom.shuffle實際呼叫一次。中途只有進度；helper只收description，最後16個opaque correlations可由Tester對frozen IDs一一對應，沒有expected_category或描述原文輸出。程式不讀label值、不自評。
- US04 scoring sanity：對上述fake allunknown報告由Tester獨立試算為decisive0/9、abstain7/7，整體不能pass；這是mock評分負測，不是Human答題、不是校準成績。真正9/9＋7/7仍pending，禁止為結果改label。
- US05受控passed：attestation有local_human有限schema，confirmedindeterminate不改outcome/proof；sentinel/異常無traceback/rawoutput，callback/helper安全failure及cleanup路徑通過。未保存原文意味未來agent不能獨立稽核Human原句。

### Scope、外部dirty與停點

只核對scope與檔名，未讀取、stage/format/還原他人六個App source/hosted-test dirty檔。排除這六個明示外部檔後，其餘diff/untracked全在U9Modify/3Written，正式rootSources/Tests/packages/rootPackage/project/resources/experiments、舊evidence/圖無tracked變更。舊CLI AST變更只send_token/run_case/main的既定清理/opt-in接點；challenge/exchange_fields/authorize/原TTY與傳輸policy未變。

Tester自己的Written只有frozenholdout；Modify只有本evidence/step，沒有修產品或工具。U04沒有剩餘controlled failure；實際GUI/Human校準仍未執行，交U05獨立Reviewer判準備度。新增OAuth0、共享R→T1/1耗盡不改；不進行live、不讀機密、不重做正向/App/canvas、不Git。

### U04 完成九欄

- In-Scope：US01–US05適用離線部分、獨立holdout/schema與freeze、54tests/compile/protocol/strictchecks/mock校準/評分負測。
- Out-Of-Scope：改source/Human自動校準/真GUI或OAuth/讀秘密/App外部dirty/Git。
- ReadOnly：工具source、正式source/App/他人tests/舊evidence/圖、frozenlabels。
- Written：`apps/GitHubSignInVerification/tools/fixtures/semantic-review-cases.json`（獨立建立後已核標freeze）。
- Deleted：0。
- Modify：本新evidence與step自身U04事實。
- Goal：交獨立Reviewer可追溯的離線結果與未驗證能力清單。
- Non-Goal：不代U05approved、不把synthetic/mock技術通過當Human9+7或遠端proof。
- TestCase：初次strictfail→定點回修→strict0/54tests再pass；其餘passed/pending如上。

## U05 P2 stderr required fix：獨立 Tester 重驗與單次synthetic smoke

2026-10-21。收到Implementer凍結交接後，親跑完整57tests exit0、OK；新增真child匿名pipes覆蓋validstdout加任一stderr、無界stderr輸出及idle deadline。stderr只讀1byte存在即static helper_protocol/indeterminate並kill，沒有forward、無界buffer或hang；stdout512上限與parent watchdog保持。helper strictformat exit0、SwiftLint0violations。

當前CLI SHA `9ebee1367ffd3f91d6311debe0457668ae96d1e24af77bf9ec24c61609d742e8`；test SHA `74f641699b77fc0c0142ea1072884584406dee1a7f65bb76251a2dc27081f575`；helper仍 `91d570e9f4e9a4b617105b911f2f847b393c3f974275066c5660bebcd116e148`，holdout仍Reviewer凍結 `d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5`。上文005fb/44e5開頭hash是P2前受控快照，保留歷史。pycache0。

主agent告知Human不要操作後，Tester僅執行一次明示授權的純synthetic密封窗smoke，沒有讀fixture、沒有點選／按鍵／reveal／CUA／截圖／OAuth。用實際parent/helper路徑，只對stderr讀取記presence布林，沒有保存／轉印stderr原文。實際安全結果：elapsed_seconds=30.534、stderr_present=false、review_status=confirmed、reveal_started=true、user_confirmed=true、semantic_category=indeterminate、reason=human_confirmed。helper已退出與清理。

這與預期密封30秒自然逾時的expired/revealfalse不一致，**自然逾時仍未能驗證**。只由安全結果不能判定外部互動或其它UI原因；主agent正在請Human釐清，Reviewer唯讀核對code路徑。未推定bug或人類控制失效，未開第二次視窗。此不是16case Human校準或9+7成績，也不是timeoutpassed；不得把controlled57pass當runtime QA全部通過。

本次只Modify新evidence/step自身結果，Written/Deleted無，ReadOnly工具/holdout/正式App/他人dirtytests；In-Scope=P2受控重驗與唯一syntheticsealed smoke，Out-Of-Scope=第二次GUI/真人校準/live/Git/秘密；Goal=給Reviewer可追溯的實際結果，Non-Goal=不代核准或推定原因；TestCase=57/strictpassed，natural-timeoutpending。新增OAuth0、Human9+7pending。

### 單次synthetic smoke：Human外部事實補充

Human隨後明示曾手動操作該synthetic視窗：看到文字不能複製，便任選一個選項。這能解釋confirmed/reveal_started=true/user_confirmed=true；是否有外部操作不再pending。**本次synthetic smoke受Human操作中止，不是自然timeoutpassed，也不是Human holdout或9+7成績。** 沒有因這筆補充改判code或重測，完整UI／自然timeout行為仍未驗證。主agent已向Human說明不需／不應複製原文，只閱讀後選分類；此紀錄不保存描述原句。

## U06 正式 Human offline calibration：未達資格

Source commit：`f420901a1076537c4f7aa0404fe31509b8bdc889`。沿既有frozen CLI／test／helper／fixture四SHA，未改bytes；外部獨立Tester已核凍結16個唯一映射及fixtureSHA一致，沒有重新抽題或讀live原文。**decisive6/9、abstain2/7；既定門檻9/9＋7/7未達，calibration_threshold_met=false。** 這是外部Tester核分，本文件作者不讀expectedlabels、不自行重算。

Human明示不懂英文：英文方法語言前提未滿足，不是使用者過失。U06 completed-not-qualified、method needs-rework，停Human方法決策。外部獨立Reviewer明示結果處置approved，僅文件記錄與停止；原57controlledtests pass／U05codeapproved仍成立，不能據此放行live、不表示正式OAuthbug或PKCEfailed。

### 安全 Human observations（只有實際選擇）

共同metadata：`reason=human_confirmed`、`reveal_started=true`、`review_source=local_human`、`review_status=confirmed`、`user_confirmed=true`。外部Tester已核16cases／16unique；下表無expectedlabel／description，correlation僅為既定opaque識別。這些是Human選擇，不是provider或PKCE原因證明。

| correlation_id | Human semantic_category |
|---|---|
| `9607720f9f1c07df` | `verifier_mismatch_asserted` |
| `b8c9573532d1cdd0` | `verifier_mismatch_asserted` |
| `97ce842ec69dee17` | `verifier_mismatch_asserted` |
| `64f6ec689229f82b` | `verifier_mismatch_asserted` |
| `6fd1b3e081a50a23` | `grant_or_code_asserted` |
| `95b6504a8bd60df3` | `client_redirect_configuration_asserted` |
| `4d14d5d4f7193b74` | `grant_or_code_asserted` |
| `75af07890985d922` | `verifier_mismatch_asserted` |
| `2f015d970c0be4dd` | `verifier_mismatch_asserted` |
| `29881aad8730c5ab` | `verifier_mismatch_asserted` |
| `a50656c6edf2f06a` | `client_redirect_configuration_asserted` |
| `105a9cef3903c748` | `indeterminate` |
| `2055254ee30aaae1` | `indeterminate` |
| `4c4f62330d76370f` | `indeterminate` |
| `92ec86fa88925dab` | `verifier_mismatch_asserted` |
| `1632c29ecdece3db` | `verifier_mismatch_asserted` |

### 邊界與本slice九欄

此前30.534s／stderrfalse／confirmed-indeterminate smoke已由Human說明手動操作中止，原筆保留，不併入本16case、不當自然timeout。當時pending是執行前歷史；P/Q/R/T unknown／預算、正常App/API/canvaspassed、共享R→T1/1已耗盡不變，本次新OAuth0。禁止改frozenfixture／labels、重跑16、新UI/code或OAuth；新語言方案未決策／未授權，機譯不能proof，新增本機元件讀description須Human確認，沒有實作／安裝／下載。

- In-Scope：安全16筆選擇、已明示外部核分／處置、語言方法不適用與停止。
- Out-Of-Scope：讀fixturelabels／raw／機密、重跑／重判舊案、新code/UI/OAuth、Git／發布。
- ReadOnly：frozen工具／fixture四SHA與本節以前全部既有證據；其他非manifest檔與6份他人Appdirty。
- Written：0。
- Deleted：0。
- Modify：本次plan U06列明的8tracked docs；本evidence只追加本節，不覆寫舊結果。
- Goal：可追溯記錄not-qualified與Human方法決策停點，禁止live。
- Non-Goal：不責怪Human、不代產approval、不把57tests當語義／遠端成功、不宣稱PKCEfailed。
- TestCase：只登錄外部Tester16unique/SHA核對及6/9、2/7；未執行測試／校準／OAuth。

## V 前置：外部唯讀語言資產 inventory

Human最新同意本機繁中方案與offline驗證，允許未來Apple on-device元件讀gate後description；原文／譯文只本機記憶體短暫視窗，agent不看不存，不雲端／不自下載；live未授權、新OAuth0。這不回改U06原16obs或decisive6/9／abstain2/7未達門檻。

外部Tester一次scratch Swift6 compile/run：macOS26.5.2／SDK26.5／Xcode26.6，exit0、stderr_present=false；sourceSHA `ce6e738621fafc8c71b744db13dd7da3383cf90aaf9cc1b2b55e68ba9ed380bf`。僅Translation.LanguageAvailability.status(from:to:)查en→zh-Hant及en→zh-TW，兩者supported非installed，只證所需組合資產未齊，非每個語言都未安裝。未init session／translate／prepareTranslation／下載／UI／OAuth，scratch自清、無repo新檔；這是environmentinventory，不是新工具／experiment或機譯成效驗證。

Apple官方installedSource初始化／canRequestDownloads支援macOS26+同步nonthrowing且不要求下載；on-device內容不入其metrics，並非Safari／系統雲端翻譯。現無實際機譯／中文工具／新holdout，候選尚不可用，Human已同意自行下載，等待完成回報才重查；既有inventory仍supported非installed，本輪未翻譯／下載／新查，不先建Vimplementationplan／fixture。機譯不能proof；原U06結果與先前smoke、四SHA及歷史均保留。本slice仍Modify8／Written0／Deleted0，只文件。

## V04a Implementer：先驗同函式 translator（2026-10-21）

V02 外部獨立 verdict approved／無 required fix，由主 agent 明示；本段只記實作與受控事實，不代 V05a／V06a 核准。

- 新 private `translateForReview`／`installedTranslation` 固定 en→zh-Hant、installed-only session，核 installed、canRequestDownloads=false、isReady；session 只在單一 worker task 建立／使用並 defer cancel，不下載、不 prepareTranslation／translationTask／cloud、不跨 task 共用。20 秒一次性結果 gate 取消 worker 但不 await 其作為 settlement；late 結果不覆蓋終值，技術 timeout 後 runner 停止。完整譯文的非空白／8192 UTF8 bytes／URL/control/bidi/opaque gate 與將來正常 v2 為同一函式，沒有截斷後判讀。
- normal binary 保持既有 v1 入口，尚未接 Chinese UI 或 CLI。`SYNTHETIC_TRANSLATION_VALIDATION` 才包含 synthetic runner；固定新 fixture 路徑、硬編碼最終 frozen SHA、空 stdin、無 args，只 Codable 投影 id/description，不讀或比較 reference_zh／expected_category 值。輸出僅此 frozen 公開 synthetic 的 id、有限 translation_status 及成功的完整中文譯文，供獨立 Reviewer；不接受任意文字／路徑或 language。
- V03 最終 fixture SHA `2be946fe6ce64f5ed29e39aaa8c183e336b5112271e1482f7410f9ee3d387827` 由獨立 Reviewer approved／tinyfixclosed 後主 agent 傳達。Implementer未開啟fixture內容、參考譯文或labels，也未跑真引擎16例。
- 親跑 normal 及 test-only Swift6 compile，均 exit0；58項離線測試全部通過（原57＋Swift stub-operation harness，13個安全布林），涵蓋完整譯文gate、受控成功／失敗、短化deadline、取消及非合作late結果不替換終值。所有 operation 均stub，沒有呼叫真engine。helper strict format／SwiftLint exit0，0 violations。test-only binary對非空stdin及任意args都在讀fixture前exit2，stdout/stderr均空；未執行空stdin真16。
- 凍結helper SHA `ebf1c606a0417aaf9f4592b64938720f499f9735db0fbe042a9576fa9929255d`；test SHA `7cb786a2e4722fd81269394e0e71e40ca7b96b221be8fb6b699037bbb928b812`。CLI、既有v1協定與英文fixture未改。下一步 V05a Tester 執行真引擎16例，各一次／無retry，總360秒外部watchdog；V06a獨立Reviewer逐例16/16 fidelity approved前，不進Chinese UI/CLI。這些gate目前pending，不能以58tests或installed inventory代填。

V04a完成九欄：In-Scope＝同函式installed-only core／compile-time固定synthetic runner及controlled tests；Out-Of-Scope＝Chinese UI/CLI、真人校準、live/OAuth、ref/label與正式App；ReadOnly＝CLI/v1 policy、舊fixture/歷史段落/圖/正式source及6他人App；Written＝0（新fixture由獨立Tester建立）；Deleted＝0；Modify＝helper／test與本evidence追加；Goal＝交獨立真engine與fidelity gate的凍結來源；Non-Goal＝不自評機譯或Human，不保證SDK立即響應取消／全機無網路；TestCase＝58controlledpass＋兩種compile＋strictchecks，真引擎與V06a／Human全pending。未GUI／翻譯／下載／OAuth／Git。

## V05a 獨立 Tester：固定 synthetic 真引擎一次序列（2026-10-21）

來源 `fbbc2fb0ca6960f7f714fd5c85d3b39f9c4215e5` 加 V 受限 dirty diff；helper SHA `ebf1c606a0417aaf9f4592b64938720f499f9735db0fbe042a9576fa9929255d`、test SHA `7cb786a2e4722fd81269394e0e71e40ca7b96b221be8fb6b699037bbb928b812`、新fixture SHA `2be946fe6ce64f5ed29e39aaa8c183e336b5112271e1482f7410f9ee3d387827` 均親查與核准凍結一致。既有 macOS26.5.2／SDK26.5／Xcode26.6 與 installed inventory 前提沿用。

- 親跑 `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py`：58 tests／2.739秒／exit0；全為受控測試。`swift format lint --strict` helper exit0。SwiftLint首次0 violations但因cache寫權限exit1；`swiftlint lint --strict --no-cache`同helper重驗exit0、0 violations，非source修正。無pycache／pyc。
- 在scratch以 `xcrun swiftc -swift-version 6 -module-cache-path <scratch-cache>` 分別編譯正常binary與加 `-D SYNTHETIC_TRANSLATION_VALIDATION` binary，均exit0。正常binary空stdin及不支援dump參數皆exit2、固定v1 unreviewable／indeterminate、reveal/userconfirmed false、stderrfalse，無dump入口；最初檢查錯把正常拒絕應有的安全JSON預期為空，已依既有協定核對，非產品failure。test-only binary額外args／非空stdin皆exit2、stdout/stderr空，未進engine。
- 固定runner空stdin／無args，唯一真engine序列只執行一次：16 records／16 translated，exit0，2.646秒；stderr_present=false、360秒外部watchdog未觸發、stdout未超界、逐筆public-synthetic schema有效。每例呼叫同一20秒deadline函式，未retry。只有新凍結公開synthetic譯文存於外部scratch交獨立Reviewer，無actual provider資料。
- 選定readonly paths（正式Sources／Tests／rootPackage／experiments／既有圖／CLI／舊英文fixture）相對HEAD diff空；他人六份Appdirty未觸碰。舊英文fixture SHA保持 `d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5`。未GUI／下載／OAuth／Human校準／Git，未重跑未變Swiftroot或App。

本次16/16是技術成功數，不是語義忠實度結論；已交V06a獨立Reviewer逐例核對，未自行評分／approved。V04b GUI仍須等該明示verdict。新OAuth0，舊歷史結果／預算不變。

九欄：In-Scope＝V05a core controlled／compile／failclosed及唯一真engine序列；Out-Of-Scope＝code/labels改動、GUI/Human/live/OAuth/Git；ReadOnly＝所有工具/fixture與正式source、六他人Appdirty／歷史證據／圖；Written＝0（本slice）；Deleted＝0；Modify＝本evidence追加與step自身結果；Goal＝提供V06a實際凍結來源及公開synthetic輸出；Non-Goal＝不代語義或Human核准／不以installed與tests當方法成立；TestCase＝58pass、strict0、編譯/拒絕邊界pass、真engine16 translated；fidelity待Reviewer。

V05a輸出交接補註：當次工具回傳已完整保留16筆實際公開synthetic JSONL，並直接轉錄其translated_text予Reviewer。Reviewer讀scratch回No suchfile；Tester先曾讀到原檔3924bytes，後續hash檢查亦回No suchfile。未執行cleanup或重跑，故不提供未量測的原產物SHA，也不聲稱scratch目前可讀；Review使用同次工具回傳轉錄，絕非reference重建。此留存限制不被16translated技術數取代，語義verdict仍由Reviewer決定。

## V06a 實際語義結果、保留範圍與停止

V03新fixture已獨立approved／frozen，V04a只保留synthetic研究core與compile-time固定fixture runner；正常binary無dump，CLI未改，沒有ChineseGUI／ChineseCLI或新Human校準。獨立Reviewer已允許保留此研究範圍。另獨立bounded code Reviewer明示approved、無required fix、不需額外驗證；這只涵蓋研究code，與V06a語義fidelity failed／needs-rework分開。

V05a唯一真引擎序列為16records／16translated、2.646s、exit0、stderr_present=false；58受控tests／normal及test-only compile／strictformat與SwiftLint通過，前文來源／SHA保留。**這個16/16是技術成功數，不是語義通過數。** V06a獨立Reviewer對當次實際synthetic譯文判定至少8處術語／角色失真，16/16 fidelity門檻未達；未提供精確語義通過數，不推算8/16或其它成績，不改ref／label配合。

### 原產物與傳遞限制

原scratch JSONL已無法再讀，沒有量測其原bytes hash。語義review來源僅是Tester當次工具輸出直接轉交Reviewer的實際16筆公開synthetic譯文，不是reference重建；不追補原檔、hash或重跑後冒充原產物。這項留存限制仍在，不因code approved或技術成功消失。

V04b ChineseGUI／CLI、V05b完整後半驗證、原後半V06b與V07 Human calibration均未執行且停止；不宣稱繁中能力已交付。語言資產installed不等於語義passed；V06a失敗不是Human過失、正式OAuthbug或PKCEfailed。Human最新允許規劃AI閱讀經安全檢查的描述，並接受資料可能離Mac／留於對話服務及gate殘餘風險；僅規劃，實際原文揭露／bridge／具體欄位與傳遞方式尚未批准，OAuth0，不擴V實作。U06舊16／6/9＋2/7、P/Q/R/T與R→T1/1耗盡、正常App/API/canvaspassed原樣保留。

### 文件slice完成九欄

In-Scope＝實際技術／語義／code verdict、來源限制與停止；Out-Of-Scope＝code/fixture/CLI/GUI/OAuth/新方法／重跑追補／Git；ReadOnly＝工具/新舊fixture/舊evidence段落/正式App/六他人dirty；Written＝0；Deleted＝0；Modify＝既定8owned docs，僅本evidence追加；Goal＝交實際docdiff獨立review；Non-Goal＝不自產approved或編造語義分數／中文交付；TestCase＝登錄58controlled/compile/strict、唯一engine16translated及外部verdict，本角色未執行驗證。

## W：兩盲 reader 公開 synthetic 核分（2026-10-21）

來源基線469f2b0＋W受限dirtydiff；唯一新fixture `apps/GitHubSignInVerification/tools/fixtures/semantic-review-ai-v1.json`，schema_version1、16筆全新公開synthetic。獨立核標Reviewer明示approved／無requiredfix，凍結SHA `38946829d2181e6a279e34de5ad1ce6221fb67fc53f53efbaf7a67b0c6001245`（4910bytes）；核分時親查未變。作者兼scorer不是blindreader；核標Reviewer不參與兩reader。來源投影只有id/description，未帶expected/ref，compact JSON投影SHA `94bafd68942815d65846fe0f5bb3e983713629a44dba41f07be54072e29e9cfb`。

第一reader root先固定一次答案；第二為全新Reviewer、fork none，明示僅見同一source投影/四enum、未見第一答案或fixturelabels。此盲性依角色明示交接，非測量模型內部或服務留存。兩份各16unique完整對應；獨立Tester依frozenlabels核分：reader1 decisive9/9、abstain7/7；reader2 decisive9/9、abstain7/7；分歧0，按分歧一律indeterminate規則計共識仍9/9＋7/7，達本synthetic固定門檻。沒有調整labels、重作reader回答或修改criteria。

封存safe enum（兩reader相同）：w01 client_redirect_configuration_asserted；w02 indeterminate；w03 verifier_mismatch_asserted；w04 grant_or_code_asserted；w05 indeterminate；w06 indeterminate；w07 client_redirect_configuration_asserted；w08 verifier_mismatch_asserted；w09 indeterminate；w10 grant_or_code_asserted；w11 indeterminate；w12 client_redirect_configuration_asserted；w13 indeterminate；w14 verifier_mismatch_asserted；w15 grant_or_code_asserted；w16 indeterminate。

這是公開synthetic方法校準成績，非code approval／copy UI驗證、非任意provider描述泛化、非live授權、非PKCE或遠端拒絕原因proof。W04工具仍由Implementer進行，W05／W06未因此完成；新增OAuth0，既有正式能力／PQRSTUV歷史與預算不改。不保存或重貼actual provider raw。

本slice九欄：In-Scope＝W03 fixture造作／獨立核標freeze及兩reader封存答案核分；Out-Of-Scope＝工具source/UI/live/OAuth/Git與自代review；ReadOnly＝工具/正式source/六foreign Appdirty/舊fixtures/歷史證據/圖；Written＝唯一 `apps/GitHubSignInVerification/tools/fixtures/semantic-review-ai-v1.json`；Deleted＝0；Modify＝本evidence追加與step自身結果；Goal＝給W校準可核對分數與邊界；Non-Goal＝不代code/live/遠端proof核准；TestCase＝16unique、schema/分布/大小/無舊description精確重用/frozenSHA通過；兩reader及consensus9/9＋7/7，無分歧。

## W05 獨立 Tester：copy-only controlled 驗證（2026-10-21）

來源469f2b0＋W受限dirtydiff，親查三份凍結source SHA一致：CLI `26894482d275636d4e736a648b0366ee6ce6b980e5fafb0683b80b40544ff0b9`；helper `8505134d2130f1f99a1339cb9abbccabe894c2db73575c60d759d542a5a5e405`；test `62d1849c1d1b16351b27b4b6ea1247c75a24a8c6fdf9b3c32908e733c3fde0c5`。

- 親跑 `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py`：67 tests、3.850秒、exit0。包含正常helper Swift6實際編譯、strict v1/v3 protocol-check、同source mock clipboard state harness及既有回歸；未啟動視窗／原生clipboard。新9項涵蓋四status/schema/互斥options、cleanup及candidate先clear、錯誤不echo、stderr/watchdog、安全main、一次明確copy與terminal/late/failure。
- helper `swift format lint --strict` exit0；`swiftlint lint --strict --no-cache` exit0、0 violations；`git diff --check` exit0。另親查AST與CLI noTTY copy opt-in／互斥flags：均exit2、stderrfalse、input_unavailable、indeterminate、proof=false；noTTY copy只回copy_status=unreviewable，未索取配置或啟動helper。
- source核對：protocol3 exact input兩keys／output兩keys、四有限copy status；不加入semantic確認。copy action須在left-mouse事件追蹤中，keyDown／keyEquivalent不可copy、defaultButtonCell=nil；30秒common-mode timer、completed／terminal guard阻late。window只有中文風險文字，不display描述。唯一native寫入點為明確mouse action的注入write；不讀既有clipboard、無自動copy／還原／清除／傳送。以上為source＋mock證據，不宣稱實機AppKit事件或clipboard互動通過。
- run_case finally清observer／attempt／fields／body／context／配置後標cleanup_completed；main先清client/secret才launch；candidate先clear再交單欄、stdin匿名pipe，parent output512bytes／stderr任byte拒絕／100秒watchdog、異常kill，無rawstdoutfile或rawexception。未更改正式outcome/proof。help目前未列新copy旗標，這是可發現性限制，非本契約指定requiredfailure，交Reviewer判定。
- frozen AI fixture SHA維持38946829…6001245；選定正式Sources/Tests/rootPackage/experiments與兩舊fixture相對HEAD diff空，無pycache/pyc，未動六foreign Appdirty。未重跑盲讀，未Swiftroot/App全測、GUI/nativeclipboard/Humanlive／translation/OAuth/Git。

受控層未發現required failure，交W06獨立Reviewer；不代code批准。既有兩reader共識9/9＋7/7只代表synthetic校準，不能替代本次未驗證nativeUI/clipboard，也不等於live或PKCEproof。

本slice九欄：In-Scope＝WC01–02 controlled/schema/cleanup/compile/checks與WC03 source/mock層；Out-Of-Scope＝修改code/labels、nativeclipboard/GUI/translation/live/OAuth/Git；ReadOnly＝所有工具/source/fixtures/六foreignApp/舊歷史與圖；Written＝0；Deleted＝0；Modify＝本evidence追加與step自身事實；Goal＝交獨立codeReviewer實測結果及限制；Non-Goal＝不代review/Human/native或遠端核准；TestCase＝67pass/strict0/diffcheck0/AST/noTTY/readonly/fixturehash通過，nativeUI/clipboard互動未驗證。

## W06 外部最終code verdict與W08待辦

獨立Reviewer已明示W06 codeReview approved、無required fix，僅offline。W05親跑67tests／3.850s／exit0、凍結sourcehash一致、Swift6compile／strictformat／SwiftLint／diffcheck0、mockclipboard及CLI互斥ASTpassed，完整來源保留前節，不重跑或覆寫。W03 final fixture SHA `38946829d2181e6a279e34de5ad1ce6221fb67fc53f53efbaf7a67b0c6001245`不變；W07兩盲reader各9/9＋7/7、分歧0、共識達該set門檻，均由Tester獨立核分，labels未改，不推廣未知描述。

W04 completed、W05 completed、W06 approved、W07 syntheticpassed；W08publication與Humanreviewpending。真nativeUI／clipboard仍未驗；copy不是semantic confirmation／proof，無actual provider raw、OAuth新增0／未放live。help未列copy旗標是discoverability限制、非requiredfix，toolsREADME已明列旗標／互斥／本輪禁止live命令。正常v1、U/V/PQRT與失敗中文route歷史不改。

本文件slice九欄：In-Scope＝8docs外部最終facts與限制；Out-Of-Scope＝code/fixture/labels/foreign/live/OAuth/Git；ReadOnly＝所有凍結工具/fixture與舊evidence段落；Written＝0；Deleted＝0；Modify＝既定8owned docs；Goal＝交最終publicationreview；Non-Goal＝不代nativeUI或live核准、不泛化setpassed；TestCase＝只登錄獨立67與盲9+7結果，沒有本角色新測試。
