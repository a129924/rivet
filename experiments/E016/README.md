# E016：本地 OAuth 登出精確刪除與新程序讀回

## 驗證什麼

- 原設計2026-11-13；2026-11-16補具體harness契約並完成修正版bb6752a唯一first/fresh有限驗證。ff672c7較早停點仍為無法判定。
- E016於11/13確認未占用後建立，現延用本實驗，不覆寫其他編號或歷史。
- 唯一問題：正式 provider.signOut 經DPK exact clear後，fresh process是否credential absent，且configuration／相鄰sentinel完整保持？
- 假設：有效既有簽章、同機同GUI使用者、同namespace唯一writer下成立。in-flight refresh競態沿正式受控tests，不由本實驗重驗。

## 為什麼

決策位置為github-oauth-local-sign-out T09。起始來源2973150；11/13已完成受限code/tests審查，不能代替真DPK fresh-process證據。Apple SecItemDelete支持selector，但不證此signed host的提示或跨程序absence。E015保存還原結果不證刪除。

參照E015 public GitHubIntegration連結的macOS app target／單group entitlements／non-sandbox與ENABLE_DEBUG_DYLIB=NO形狀；不重用其ready、runroot、sourcefreeze、namespace、stage額度或收據，不更動E010/E015。完整簽章資產pin及協定見[technical-spec](../../analysis/github-oauth-local-sign-out/technical-spec.md)。

## 成功與失敗判準

執行前固定（11/13判準，11/16具體化可觀察證據）：

- 成功：seed absence/readback成立，正式signOut成功，first與fresh兩程序credential absent且configuration/sentinel逐欄相符；來源／signed binary／profile一致，actual程序歸屬與前程序退出證明及Human完整觀察齊備。
- 失敗：在前提可判定時credential仍在／恢復，或configuration/sentinel被誤改。
- 無法判定：簽章、profile、程序歸屬／終止、receipts或完整觀察不足；不能把環境阻礙記成假設失敗。任意操作失敗先停止，不以新run補救。
- 投入：每次Human明確授權的一個新UUID、一次first→fresh序列；first啟動即消耗，不自動retry、換namespace重來、refresh/network或補cleanup。ff672c7 first中斷後已停留；Human另行明確批准修正版bb6752a新準備與新增一次first/fresh額度，本次兩段均已用完，不恢復舊額度。

## 環境與前置條件

- 11/16 Explorer inventory顯示既有E010 identity/profile可選，主session已選較晚expiry組。exact AppID/group、identity/profile pins見technical-spec；profile expiry 2026-11-17T07:28:08Z，每段實際啟動前仍需有效。inventory不等於E016簽章成功。
- 無新資產／automatic provisioning／trust或ACL修改，不修改舊bundle/profile/items。新E016專屬private build/output/DerivedData，root public GitHubIntegration source由feature worktree建置；不重開production API。
- 正式DPK為真依賴；configuration/完整credential/sentinel全固定synthetic。假fetcher被呼叫即fail，不建立網路client。
- source manifest凍結當前commit、dirty逐檔hash、root package/resolution／實際編譯source與E016host/project/resources/runner；signedbinary/embeddedprofile/cert/toolversion/signature receipt再凍結。fresh不得rebuild/resign。
- 同namespace唯一writer是獨立前提；相關舊app已退出、actual PID/starttime/path與binary hash須核對。無法判定不kill未知程序。

## 重現步驟

下列為受審操作流程，不是重跑授權。bb6752a signed preflight與first/fresh已實際完成；命令形狀見[COMMANDS.md](COMMANDS.md)，本次實際觀察與凍結hash見[獨立live證據](../../plan/github-oauth-local-sign-out/evidence/e016-live.md)：

1. `E016LogoutProbe.xcodeproj` shared scheme `E016LogoutProbe`、`Sources/main.swift`、`Resources/Info.plist`、`Resources/E016LogoutProbe.entitlements`；最小` scripts/e016_live.py`（實際路徑不含前導空白）僅preflight/first/fresh；`Tests/test_e016_protocol.py`。
2. unsigned build命令形狀：`xcodebuild -project experiments/E016/E016LogoutProbe.xcodeproj -scheme E016LogoutProbe -configuration Debug -derivedDataPath <E016-private-derived-data> CODE_SIGNING_ALLOWED=NO build`。fakechecks：`python3 -m unittest discover -s experiments/E016/Tests -p 'test_*.py'`。unsigned與fakechecks已由Implementer／Tester先驗；harness與簽章前提經獨立Reviewer審查，最新離線20checks與共用Foundation path checks保留獨立證據。fake/mock不取代真DPK兩程序結果。
3. 獨立harness審查後，manual signing指定已選資產與完整bundle；preflight核AppID/exactgroup/embeddedprofile/cert/signature/expiry/source-binary hashes，僅讀環境不seed/delete。將實際完整命令凍結於private provenance，公開只記hash。
4. 工具與命令可檢視後，主session安排Human完整觀察。run生成一個UUID：主service=`local.rivet.experiment.e016.logout.<UUID>`；sentinelservice=主service+`.sentinel`。first經完整App path bundle launch，不能bundleID lookup、open -n或raw GUI binary。runner核actual PID/starttime/executable path/binary hash；App在DPK前自核frozenidentity/phase/run。
5. first：主configuration/credential及sentinel credential先讀均absent，否則停止不覆寫；正式stores seed固定fixtures並讀回逐欄相符；建立正式provider僅signOut；同程序驗主credential absent/configuration/sentinel intact；write receipt並正常exit。
6. 核實first exact process已退出，再由相同App/signedbinary/profile/run launch fresh一次：只讀三項，相同absence/intact判準。fresh不得任何save/delete/seed。runner命令形狀為`python3 experiments/E016/scripts/e016_live.py <preflight|first|fresh> --app <E016-private-app> --run-root <private-run-root>`；實際private inputs由review凍結，不能臨場換app或run。
7. private runroot owner-only，保存actual paths/PID/starttime及identity/group/profile provenance，公開projection只allowlisted booleans/enums/SHA-256，包含phase/outcome/failureKind、run/process/provenance hashes、seed_absent/seed_readback/write_attempted/signout_returned/same_process_absent/configuration_intact/sentinel_intact/fresh_read_verified/previous_process_terminated/launch_identity_verified、source/binary/profile hashes。禁止payload／任意錯誤原文／raw本機路徑或identity。
8. bb6752a兩段Human完整觀察各綁其原public receipt SHA，private attestation保留實際數字，公開只記prompt_count_class=zero／observation_complete=true及attestation hash。原public的Human unknown／false不覆寫，由獨立成功projection補充；較早ff672c7因無public，Human只綁machine SHA，兩者不能混用。configuration/sentinel留下，不順手清除。

## 是否成功

- 執行日期：2026-11-16。
- 實驗狀態：成功（bb6752a修正版、Human另授權的新first/fresh有限序列）。
- 本輪驗證任務完成：是。seed absence/readback、正式signOut、兩程序absence及configuration/sentinel完整保持、同source/binary/profile、actual exact process退出與兩段Human全程觀察均有證據；獨立Reviewer已對本次有限結果明示approved。
- Human最終topic接受仍pending；此狀態不推翻ff672c7的indeterminate歷史。

## 結果與證據

受測來源固定`bb6752aa483a68043174723a6b3ff2653abe79ce`，Xcode26.6／17F113、Swift6.3.3、Python3.14.0。first seed完整synthetic資料並逐欄讀回，正式provider.signOut成功後credential absent，configuration/sentinel保持。fresh為不同actual exact process，只讀確認同樣absence/intact，write_attempted=false；兩段exact process均已退出。同一signed binary／profile／source保持，啟動前有效性各自重驗。

兩段Human皆確認完整觀察、公開prompt class=zero；各自attestation綁原public receipt SHA。原public之Humanunknown不改寫。安全[success-summary projection](evidence/success-summary.json)採獨立schema，不冒充原協定receipt；完整安全hash、實際commands及限制見[獨立live證據](../../plan/github-oauth-local-sign-out/evidence/e016-live.md)。

較早ff672c7 first仍為無法判定：machine write_attempted=false，無hello/authorize/public/private或exact process證據，fresh未執行；[舊停點projection](evidence/first-stop-summary.json)與舊App／marker／receipts保留，不回填成功。

## 結論與限制

T09在本次受限環境通過，獨立Reviewer已approved有限結果；準備、舊停點、回修及新額度來源分開保留。新first/fresh兩段額度皆已消耗，不自動追加。隔離configuration與sentinel保留，沒有cleanup或額外Keychain讀寫。

只支持當次同機、同GUI使用者、有效既有signer/profile與唯一writer；不外推其他signer／profile更新／跨程序writer／自然到期refresh／斷電durability／正式產品UI或真OAuth。晚到refresh競態沿11/13正式受控tests，本次live沒有refresh/network。後文為各階段歷史，若與本節時間不同，以本節最新有限結果為準；沒有改寫當時的未執行／停止結果。

## 11/16 Implementer unsigned 交接

獨立 E016 host 只 import public GitHubIntegration。7個fakechecks（absence、fresh policy、redaction、不可重試、process/provenance mismatch、prompt unknown）通過；初次red因runner尚不存在失敗。unsigned xcodebuild曾遇局部型別／命名compile錯誤，修正後通過；這些是工具開發歷史，不是系統實驗失敗。正式source沒有變更。

sourcefreeze helper在建置前後比較commit／dirty狀態／實際package與host逐檔hash，保存build-source companion、unsignedbinary／buildlog hash。signed preflight另核固定profileSHA256、profileUUID／expiry、actual leafcert、exact entitlement／AppID與來源，沒有簽章／trust修改。Runner first/fresh需actual PID/starttime/path/hash握手，App在授權前不碰DPK；實際receipt與Human attestation仍未取得。unsigned建置可能執行Xcode正常LaunchServices registration，沒有啟動App／seed／delete。

此處記錄的是Implementer先驗，不是獨立Tester／Reviewer approval，更不是T09成功。最終待驗source hash與實際建置命令由COMMANDS／private build-source companion可重現；本機絕對路徑、profile實際路徑及identity資料不寫公開收據。

## 11/16 harness Reviewer 回修

獨立Reviewer要求的兩項缺口已回修，尚待獨立重驗：

- 新增E016專用sign_prepared準備helper：簽前驗實際unsignedbinary與build-source/source一致，簽後記錄唯一轉換的signedbinary／bundle／profilehash；preflight與launch核該鏈。COMMANDS改用helper，未執行真簽章。
- 以mock實際launch_phase的測試取代未接流程的policy toy helpers：檢查launch前consume、啟動中斷後不可再Popen、source/binary/actualprocess不符不得authorize、fresh缺first通過／termination／provenance不得launch。另mock signing轉換檢查替換unsignedbuild不codesign，以及preflight拒絕缺鏈。

回修後16個fakechecks通過，全部使用暫存fixture與mock subprocess，沒有launch/sign/DPK。原7個先驗數字保留歷史，不能當本輪最新覆蓋。最終sourcefreeze須待最後文件／review完成後重建；先前unsigned companion不能代表後續回修來源。

## 014bab2 準備停止與 bounded command bugfix

2026-11-16，在乾淨014bab2來源及全新私有輸出執行sourcefreeze unsigned build後，唯一sign_prepared嘗試實際完成codesign，但後續signed_info在公開certificate擷取的optional argument語法停止。signing-attempt marker／stopped receipt／已signed App保持原狀；沒有完整signing.json，未進preflight，未執行first／fresh、App launch或DPK。這是工具準備失敗，不是T09假設失敗，實驗仍未執行。

唯讀診斷：codesign signature verify通過、exact AppID／group相符；原split參數`--extract-certificates <prefix>`在此codesign版本將prefix當輸入path而exit1。唯讀改用`--extract-certificates=<prefix>`擷取成功，實際leaf certificate SHA-256與既定pin相符。診斷只抽出公開certificate到暫存，沒有第二次簽章或資產修改。

本次限定修正signed_info的一行參數，新增走完整signed_info且模擬真CLI optional-argument解析／產生certificate檔的regression；舊split形狀先得到可歸因red，修正後17fakechecks green。測試固定clock，避免既定profile到期污染純commandshape判準。未更改一次停止規則、未補造舊transition、未重build／re-sign；新的準備嘗試須在fix獨立審查後由主session向Human交代並確認，不自行換root繞過marker。

## 唯一 first 停點與 path identity 回修（2026-11-16）

Reviewer將本次T09分類為「無法判定」，不是production OAuth failure。first額度已消耗，fresh未執行。machine receipt為indeterminate／operation_or_prerequisite／write_attempted=false；沒有hello、authorize、write-attempted marker，亦沒有原協定first-public／first-private receipt。只能依原始碼ordering推論停在DPK前，沒有成功seed／signOut／fresh-read證據。pgrep同名程序不存在不能代替exact PID/starttime／退出證明。

Human回覆全程觀察，公開表示為prompt_count_class=zero／observation_complete=true；原私有觀察綁machineSHA，不是不存在的publicreceipt。新[停點摘要projection](evidence/first-stop-summary.json)保留此限制，沒有補造原協定receipt、raw count／路徑／identity或payload。

唯讀診斷確認Python frozen與Foundation runtime路徑正規化策略不一致，兩種tmp alias指同物件；原host只正規化一側且runner後續有raw path比較。這是可確認的工具策略bug，但當次沒有hello／runtime path，因此不能宣稱它是唯一實際根因，也不能回填當次程序身分。舊App／receipts／consumed marker完全保留。

本輪限定工具回修：新增實際由host使用的純Foundation path helper，雙側同樣normalize並核device/inode，hello也輸出同策略路徑；runner以samefile比對hello及actual executable，不用字串prefix替換，PID／starttime／binary／profile／source guards維持。純Swift離線程式直接呼叫共用helper，驗tmp alias及不同App／同內容不同物件；完整mock握手驗alias可authorize，different object不得authorize。20個Python checks與純Foundation checks通過，不是主App或DPK驗證。

本輪沒有build主App、sign、launch、DPK或新run。任何新的準備／run都待Human續行，不恢復舊額度或清理殘留；最後仍須獨立Tester／Reviewer核對回修。
