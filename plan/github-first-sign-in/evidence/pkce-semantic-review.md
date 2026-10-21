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
