# Implementer 交接

## 範圍與 TDD

僅在 feat/github-oauth-credential-persistence feature worktree實作；未修改 dev、其他topic或E007。九欄與精確leaves依 plan W02／W03／M01／M02；無repo刪檔、無live Security或簽章操作。

- 基線：既有 OAuthTokenProviderTests 19 tests 通過。
- Red：新增 fake Security 契約測試後 `swift test --filter GitHubOAuthDataProtectionStoresTests` exit1，缺 GitHubOAuthDataProtectionStores／GitHubOAuthSecurityClient，確認缺少新實作。
- Green：同命令 exit0，13 tests，包含25個corrupt payloads、7個access statuses、3個write failures。沒有改既有provider期望。
- Full non-live regression：`swift test --skip KeychainTokenStoreTests` exit0，269 tests／31 suites。明確跳過既有legacy Keychain live suite，沒有宣稱其本輪通過。
- 本次Swift source／test strict SwiftLint通過；跨targetconsumer及全repo format／lint交獨立Tester重驗。

## 行為

完整兩items、strict version1 codec、clientID read-check-write保護、explicit DPK query／protection、update-add-duplicate單次retry及finite errors已交付；shared actor在同步Security calls間無suspension。測試包含完整替換、configuration-first partial save、並行views及provider persist-stop。Readonly provider／ports／clients／Package.swift不改。

Static isolation初次回歸只因舊檔案/import allowlist有2 issues；已經Plan-Creator＋獨立Plan-Reviewer核准精確amendment，再只補兩個檔案與新adapter的Security例外，其他限制維持。機械修正後269 tests通過。

## 文件與圖

長期文件、單張storage sequence已完成；Archify最終9/9 showcase、0errors／warnings，四尺寸containment及四lightdark截圖通過，Agent已實際看圖。Human visual acceptance pending。PR Lens待真commit後完成；Graphify無圖採source fallback。

## 獨立驗證交接

請Tester獨立執行適用T01–T08，核fake-only/publicconsumer/strictformatlint與圖receipt；之後交獨立Reviewer。真DPK、跨程序、簽章、prompts、GitHub登入未驗證，不依賴別人E007，不宣稱Mission整套完成。

## Tester 回修

獨立 Tester 發現 StaticIsolationTests 新 OR 條件的 opening_brace lint；Implementer 改為相同兩個 paths 的 Set.contains，未變更期望或放寬範圍。指定檔重新 format，交 Tester 只重驗必要 lint／format 與 static case。


## LG41：實際 unsigned App／最後窗口 caller 準備（2026-11-04）

依LG40 approved/fixes=[]與Human routine授權完成，未改LG40四葉code或五模板。普通owned scratch basename `rivet-lg41-preparation-3rjw9k7l`，root0700／直接private files0600；不是新diagnostic context，future-context/sign-consumed/launch-consumed/signingproof皆不存在。精確私有定位交Dispatcher工具訊息，不公開abs/私人ID或raw errors。

實際CredentialStorageProbe/Debug同target Xcode build成功exit0。命令為spec LG36的signingAllowed/Required=NO、Manual、空entitlements/no base、LAUNCH_REPORT_ONLY/no debugdylib，無provisioning/auth/deviceflags；指定macOS/arm64、使用own既有Apollo2.1.2 locked barecache。第一次sandbox/DNS公開套件解析失敗exit74，config／build命令／stdout/stderr與結果保留；第二次必要工具權限和own cache後成功，不是App診斷重試，不涉舊quota。Root Package.resolved／package inputs與九source SHA前後相符。無CodeSign步驟／帳號auth要求／SDK或profile取得。

實際App Info BID符合原target，no embedded profile、empty claims、0 nested MachO；arm64 linker自動ad-hoc seal，未憑證簽署或使用私鑰。工作產物另以ditto保留metadata為unsigned-artifact原件及to-be-signed副本；完整relative filetree/content/modes hash一致。Unsigned linker temporary CodeIdentifier不等最終expected，未修改seal或OSpolicy；最終仍須原DER憑證手動--identifier原值後postverify，不能把此暫態當正式identity。BID/最終CodeIdentifier expected hash均b812208351271046f0c7f97b66cf5e0e1580dd87a9bdbd1ba22a16cdc16836a3。

完整private caller.py／config-final.json／OPERATIONS.md與source snapshots、build inputs／精確command、完整noauth compile logs及proof已備。Caller外部approved SHA/config核對＋ownsource/runner/package/privatePBX/unsignedtree guards；explicit armed phases各自sign/context/launch，無隱式下一段。Sign marker先於可能auth的publiccert query；原DER pin→class/date/Team→SHA1selector，原key只簽受控副本；staticpostverify後才發布paired signedproof/artifact/operation。Context producer只在該成功proof後exclusive新R/source/App/proofs，再staticverify；partial即耗額。Launch另freshready且拒重用sign ready，只invoke frozen binding-launch一次，unknown不retry/kill。私有新caller不是新repo工具或framework；尚未執行任何certquery/sign/context/LS。

NoApp實際dry-check exit0，只有sourceGuard/preparationOnly及privateKeyAccess/contextCreated/appLaunched=false；錯callerSHA exit2有限拒絕。普通fake fixtures中**7/7 drytests、0skip、0.040s**：unarmed零query/marker、queryfail已消耗不sign／不重試、fake sign/context完整鏈且unsigned原件不動、partialcontext不reuse/delete、oldready noLaunch／unknown只一次、fsyncfail pending不受信、publication不覆寫；所有query/sign/copy/static/launch helpers皆mock，fake成功不冒充真簽。AST caller/tests2/2及Ruff F/E9通過。沒有額外root測試或重新跑37/146。

| 證據 | SHA256 |
|---|---|
| 實際unsigned binary（原件與簽署副本相同） | ad1e4f4fdb2b9da08603aa969d58a5bc6b6830775922cc67b087bff6871d1a0b |
| App完整tree（兩副本相同） | e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614 |
| caller.py | fa37d3ae267865dc0c2546f1c3806c588501ad4802f0dba851009a03788df5dd |
| config-final.json | f850bcfa2421a17f9c442048a12c3eddeb6a3455a92d383722a7a8128b213be3 |
| build.machine.json（只unsigned build成功） | 9746cf38165eaddbb6fa2cf0ace9942e236c6e7b758e200f3a7b00fe145f7e1f |
| unsigned-artifact.json | 8eac01d4877e9d58cc5c557aa016d7c86d08fc031ae3e3858c4ab1334f60cbaa |
| OPERATIONS.md | 248267f7b6419a4e64cd034913f2103cf23c0924c65056f62670b1b7a0870fb8 |
| preparation-freeze.json | 03c9ab921c7addd91c70552f874be3b25c8c30a47003fc7b8e6deeca21677bba |

後續只交LG42獨立審caller/config/產物/proof/dry evidence。真正Human窗口仍未發ready：publiccert query若需auth、原key當次sign、成功postverify後新context授權與freshready單次LS／全程prompt觀察。原DER來源/class/trust/key-use於窗口由已審caller精確處理，不要求Human找欄位；query30秒／decode10秒／sign180秒／各identity verify30秒／binding窗口30秒，cancel/denied/timeout/缺原identity/expired/未知nested code/需newcert/profile/ACL/AlwaysAllow/trust/paid/OS拒絕皆停，不修資產。Oldroots/history/assets/quota未操作，DPK/cleanup不解鎖；作者未自批。


## LG46 Implementer：certificate解析受限修補（2026-11-04）

依LG45 approved/fixes=[]，只既有runner/tests/README＋自身row/evidence。首個actual default helper fixture用原config exact key形狀、fake owned App/keychain及同一fake DER，模擬舊combined x509輸出中的issuer OU／text Subject OU／subject記錄。舊source確實在len(units)==1拋Rejected：1 test red；不是原LG43 decoder輸出，也不認定其歷史根因。改為三份精確argv後green。

DER pin仍先於一切decode/SHA1；subject只收一記錄，RFC2253 escaped separators/hex解碼後恰一OU，禁止重複subject／多OU／multi-valued RDN／非法escape／UTF8／額外行；issuer/text不參與Team。日期兩唯一欄位與UTC有效期、Code Signing EKU及兩OID仍必要。Static/dynamic code identity共用新解析，三個decoder各10秒並受原總deadline約束，原DER／Team／codeID／claims／DR條件維持。Preparation新nullable finite evidence按spec九keys，每invocation重置；實際native return/signal/timeout/exception及parse bool保留，nonzero的CalledProcessError保留原private stdout/stderr，沒有raw錯誤投影。Helper只產private sign argv，不execute。

局部13/13通過(0.061s)後，最終source適用selector **41/41，0skip，exit0，0.327s**：CertificatePreparationControls(8)、ProfileFreeCodeVerification(5)、LaunchBindingControls(28)。有完整default argv/options assertions、config形狀helper實入口、escaped injection／duplicate／class/date／wrongpin與path/info/profile拒絕、零codesign、native原例外保留、有限schema/privacy，以及原binding quota／clock／ACK／publication等選擇性回歸。全部commands為fake providers、普通fixture scratch；不真openssl/Keychain/codesign/processquery/App。沒有改main，因此未compile/build或機械重跑原Swift／146。

```sh
python3 -m unittest test_live_protocol.CertificatePreparationControls \
  test_live_protocol.ProfileFreeCodeVerification test_live_protocol.LaunchBindingControls
ruff check --no-cache --select F,E9 --ignore F401 \
  validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  validation/github-oauth-credential-persistence/Tests/test_live_protocol.py
```

測試命令工作目錄為本topic validation/Tests；Ruff工作目錄為feature repo。兩Python AST2/2及上述Ruff通過。Final三葉SHA256：

| validation相對leaf | SHA256 |
|---|---|
| scripts/credential_storage_live.py | faff8159a43706c622c9c64d793238493d2a951ec6b839548ec1ce8155ae1905 |
| Tests/test_live_protocol.py | b464a0ee916b382f7fa6a6205e5a91b777ad7989ba99e7cd296f9c774242cf49 |
| README.md | 88468b62aa2b7d29efccf55ae5f99581bd10be92b1db86633a6311957ae52850 |

Main原SHA2fd43e08f6c43cd3ee91edbc649ae97a7062aace8315bcfdc19435de2889f766及五模板6/6等LG40；兩App tree均e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614。原caller/config/buildproof／LG43 operation/consumed hashesreadback全等SP03原pins。這次只讀這些private父資料，沒有改snapshot／原App／ready／quota／history。

界線／handoff：實際amendment-1私有caller/config/controller／phase producer尚未建立，按既定LG49再準備，LG50實讀審查，並以真正改變副本tree的fake sign證明sign前核unsigned、context/launch後核新signedproof；原件始終immutable。README已精確列此契約及外部新controller freeze對原build provenance分離，不能讓新caller沿舊guard要求現repo三工具leaf等於舊buildsource、不能假App重建。LG43 unknown、原兩ready結束與DPK停點維持。LG46 source完成只交LG47獨立Tester，不自評approved；未query/sign/context/launch/newready／私有amendment或delegate。


### LG46 RF-LG47-01 bounded回修（2026-11-04）

承接LG47 needs-rework唯一RF，不改Tester verdict。新回歸穿過default `binding_code_identity`、實際shared wrapper及native adapter，僅fake底層subprocess.run：舊source三個argv都含-in，在精確argv斷言確實red（1test FAIL）。修補只把shared decoder從`command(... -in leaf)`接線改為真正`subprocess.run(arguments, input=raw, ...)`，固定三argv、原已pin bytes、每call10秒及原總deadline保持；不重讀file／不經DEVNULL。Wrapper拒絕錯input bytes/type或額外file argv；共同decoder原rc/signal／stdout/stderr／timeout/OSError保留，不降低parse／class／日期／身分條件。

Regression成功時以相等bytes並斷言三個input為同一已讀DER物件；它不要求fixture原始寫入bytes物件與read_bytes產物具有Python物件身分。必要負例透過actual wrapper修改上游input/type/argv後，皆在底層openssl前拒絕；native失敗則依原return/exception停止。沒有mock整個wrapper來替代主回歸，沒有真openssl/codesign/Keychain/PID或App操作。

Final適用selector與前次相同三classes，新增3 methods後 **44/44、exit0、0skip、0.476s**。包含原41與本RF底層stdin／錯input/argv／native failures；原41及LG47三額外green仍歷史保留。最終兩Python AST2/2、Ruff `--no-cache --select F,E9 --ignore F401`通過；README僅追加本RF接線說明。沒有main／五模板／App/build／父資料修改，未compile/build/query/sign/context/launch/newready／新私有amendment，LG43unknown保留。

| validation相對leaf | 本次final SHA256 |
|---|---|
| scripts/credential_storage_live.py | 3511c3f4d42e8ee2016cb0c9c28b36691c35d653eb8c77a6f32e0f7ecbd5ebc9 |
| Tests/test_live_protocol.py | 9c6de3cd9bd5f0fdd4f6eaf3252127e91a38ae87ad7d30ef6b7574591ebb6602 |
| README.md | 1ac021d7b3199fb6b6bcf331f9b18569720ec4ec23886d92d7fd5f173d945ea5 |

自身回修完成只交原LG47 bounded複驗；不自行解除RF或宣稱approved，不直接交LG48。LG49 actual privatecaller/config及跨phase NoApp驗收仍依既定路由，原成功build source/proof不換成新controller歷史。


## LG49：同prep root唯一amendment私有準備（2026-11-04）

依LG48 approved/fixes=[]及六leaf澄清獨立approved，只做私有工具準備／NoApp，未改LG48受審三葉。原owned準備root basename `rivet-lg41-preparation-3rjw9k7l`新增四個exclusive0600檔，root0700／canonical／全祖先no symlink；write/flush/fsync及root fsync，readback一致。沒有建立任何新的consumed/operation/proof/context/ready，未query/codesign/LS或原資產清理。

| 私有fixed leaf | SHA256 |
|---|---|
| caller-sign-amendment-1.py | 4b3be2ed3d4238826679d46d13da0d8ed77bb39038bf0a25300ce5b1105d0d2f |
| config-sign-amendment-1.json | 463ba3c0622568053b4c59cdde3b74cbb34662ab869a5614d5b9220e27fe7a68 |
| credential-storage-controller-amendment-1.py | 3511c3f4d42e8ee2016cb0c9c28b36691c35d653eb8c77a6f32e0f7ecbd5ebc9 |
| preparation-freeze-amendment-1.json | 12724d99d156d5ef0a442dbbb4e2269919e900739fa3d62fd83dc22e6580f4d7 |

Caller有真正dry-check/sign/context/launch入口，phase前核parent operation同inode/pendingbytes、原caller/config/consumed固定SHA與unknown/sign-preparation，原source九葉/buildproof/unsigned原件不變。新config只append amendment；現repo新工具三葉與新controller獨立核reviewed freeze，main/五模板仍核oldsource，不改舊buildsource。Sign前核副本unsigned/context absent和一次額度，context/launch驗child成功operation／exact signingproof/artifact及signed tree；consumed/operation任一partial存在耗額。新markers及全部操作均專名，只用當段freshready、與原/child前段UUID不同，不carry舊Human條件ready。先consume再query/copy/launch，原parent永不覆寫。

Sign實用reviewed helper的原DER pin→split subject/date/class→SHA1 sign argv、原identity postverify與finite preparation evidence；拒絕仍可持久記原decoder return/outcome／guardPoint/nullable檢查結果，無rawsubject/私ID/error投影。Context producer保原build/source九葉bytes並copy新的signproof，exact LG31 context綁final binary；launch仍跑actual binding_launch/雙metadata+dynamic/ACK/final/clock/native/publication，無重試或kill。外部operator必須先比LG50最新approved freeze與實際bytes，flags/hash不自核approval。

**NoApp dry**：ordinary fixture testscript basename `lg49-test-caller.py` SHA264a24e49d59ae244277ba99301c4e8160fba51b1b1f01cdcda7dfbc2278f279，candidate bytes逐hash等actual caller。**7/7、0skip、exit0、0.374s**；actual main入口及actual reviewed helpers，不mock sign-preparation/code identity/context/binding核心。只fake最底層subprocess及既有binding hooks；fixture自己的golden parent hashes／fake DER pin在隔離module memory對應合成inputs，production caller/config/controller pins一律未改，未執行fake signed來源作真人證據。

唯一happy chain先dry zero-native→sign→context→launch；fake sign真的追加副本binary bytes使tree不同，actual postverify真split parser、context/static與binding協定仍通，原unsigned原件及原build/source bytes逐一相同。Fixture的signed-host欄位只用於走真schema/分支，所有OS／PID／codesign／cert結果都是fake，不能當signedhost實證。其他六tests：duplicate subject拒絕zero sign並記subjectParse、dates decoder rc7/原checked bool保存、parent/source/currenttool hash拒絕於query前、partial/spent/context存在拒絕、old/child ready重用拒絕、parent pair同bytes不同inode拒絕。原LG41七項mockhelper dry不是這次證據替代。

私有candidate與NoApp test AST2/2、Ruff既有F/E9規則通過。真prep root只執行`dry-check` exit0：sourceGuard=true/privateKeyAccess=false/contextCreated=false/appLaunched=false；程式此分支不native。所有14個future操作paths（新三phase consumed、五種proof/operation pending-final及future-context）仍absent。父LG43 operation d123529e216fd44ffdce0bfd4b82343e6851a00996513b9abefc1d37af5edf26、consumed18c0df133b5b7c050909787d52484aed543ef48f3be44ca6e1ddca0e686e8df6、oldcaller/config/build hashesreadback未變；兩App皆仍原e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614，由actual dry guard核通。未重build或改main／Appbytes。

**未執行的未來命令**：LG50確認actual freeze後，operator從私有已知root定位，不要求Human提供Team/BID/DER檔。以下LG49_ROOT由agent映射原owned root；NEW_*_READY只於Human真實當段authority後生成canonical v4，不預建。每段獨立執行／觀察／停止，不串成自動流程；sign若失敗整輪停，不以新UUID重試。

```sh
python3 "$LG49_ROOT/caller-sign-amendment-1.py" sign \
  --config-sha 463ba3c0622568053b4c59cdde3b74cbb34662ab869a5614d5b9220e27fe7a68 \
  --caller-sha 4b3be2ed3d4238826679d46d13da0d8ed77bb39038bf0a25300ce5b1105d0d2f \
  --ready-uuid "$NEW_SIGN_READY" --ready-confirmed
python3 "$LG49_ROOT/caller-sign-amendment-1.py" context \
  --config-sha 463ba3c0622568053b4c59cdde3b74cbb34662ab869a5614d5b9220e27fe7a68 \
  --caller-sha 4b3be2ed3d4238826679d46d13da0d8ed77bb39038bf0a25300ce5b1105d0d2f \
  --ready-uuid "$NEW_CONTEXT_READY" --ready-confirmed
python3 "$LG49_ROOT/caller-sign-amendment-1.py" launch \
  --config-sha 463ba3c0622568053b4c59cdde3b74cbb34662ab869a5614d5b9220e27fe7a68 \
  --caller-sha 4b3be2ed3d4238826679d46d13da0d8ed77bb39038bf0a25300ce5b1105d0d2f \
  --ready-uuid "$NEW_LAUNCH_READY" --ready-confirmed
```

尚需Human真正動作集中最後窗口：原publiccert query若auth、原key當次sign及全程提示觀察；code/caller準備由agent完成，不請Human排障。Query30秒／各decode10秒／sign180秒／identity30秒／copy60秒／binding30秒為既有上限。取消／缺原key／class-date-identity不符、需newcert/profile/trust/ACL/AlwaysAllow/paid或OS拒絕即停。Context/launch另當段authority與實際觀察，舊兩ready已結束；不DPK、不清理。LG43 unknown保留，本LG49準備非approved，交LG50獨立實讀四檔／NoApp／父資料。


## LG54 Implementer：真Swift replay與entry/native接線（2026-11-04）

依LG53 approved/fixes=[]，只四既有工具葉＋自身evidence/row。原compiled main2fd43核心在ordinary fixture讀原captured request/context/proof/source/App rawbytes，不由Python重編JSON；歷史clock、executable/instance/ACK sink為最低fake，schema/digest/FS/guard為原真Swift。只加原line trace的非live driver（核心條件未改）決定性先拒原source line714：URL.path與standardizedFileURL.path不等，Foundation標準化去掉/private alias，而Python realpath產生物理canonical路徑。Host相同requestURL→attempt→root組裝已重現；schema NSNumber為q且非CFBoolean。**這證固定路徑對原guard必拒，不證LG51歷史首先到哪個guard或argv/env已正確到達。**

只LaunchReport換POSIX realpath相等＋逐層lstat/no-symlink/ownUID/root0700/file0600及原O_NOFOLLOW/size guard，legacy DiagnosticProbe不變；不是解析後接受任意symlink alias。原guard red→新同核心在原bytes真FS／固定歷史clock完整到report/ACK/final green，input原bytes/hash未變，寫sink全在ordinary fixture。真FS mode/symlink/nonowner/type/filemode/size負例與Foundation integer/CFBoolean/fraction走真API；ordinary unsigned CLI live metadata accessor僅getpid自身，SDK fullcount/PID/UID/status/start/usec原checks均通，不查他PID/UIDscan。Native不可得fake hook另驗只產instance有限failure/null fields，不假填instance。

新五argv／兩env與ownedbootstrap後entry/failure exactschema實作；雙channel缺/partial/duplicate/unknown/mismatch仍不能成功，無trustedpair只finite stderr，從不fallback credential path。Entry/failure包含同B及實際wire/nullable self欄位；完整原proof/source/binary/instance/clock/ACK/final條件保持。原core 22 cases加6必要wire/entry/metadata unavailable cases皆由實際Swift execute跑（28cases）；variant不允fake/legacy入口。Entry/failure不是attribution或nonce authentication。

Runner exact App stdout/stderr redirect與native stream分開，bounded65536 snapshot/oversize只size。Report missing native rc0/signal／wire原source三tests先red；新nonblocking poll每wait/timeout/finally保原Popen已知return/signal/settled，pollerror不抹結果、native0不補host成功。實際finite Python非App child自然exit7被真Popen.poll觀察；其餘native錯誤／signal／timeout用最低provider，無production kill/retry/-n。新machine/finite projection exact追加兩diagnosticSHA與appOutput，嚴核schema/binding/nullable/privacy。

Final **40/40、0skip、exit0、2.382s**：LaunchStartupControls(8)、LaunchBindingControls(28)、SwiftLaunchStartupControls(2)、SwiftLaunchBindingOperations(1)、SwiftProfileFreeVariant(1)。Actual Swift rawbytes入口不是Python fake report替代；真self/FS與28cases在新default binary執行；variant actual subprocess驗fake/legacy/env-loss拒絕與有限stderr。只受影響selectors，未機械重跑原146/44/37或無關SDK／產品tests。最終AST2/2、Ruff F/E9 no-cache、strict swift-format lint及strict/no-cache SwiftLint皆通過；未新增lint豁免（原單檔file_length保留）。必要private helpers分割只是滿足既有lint，無新framework/target。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest \
  test_live_protocol.LaunchStartupControls test_live_protocol.LaunchBindingControls \
  test_live_protocol.SwiftLaunchStartupControls test_live_protocol.SwiftLaunchBindingOperations \
  test_live_protocol.SwiftProfileFreeVariant
```

工作目錄validation/Tests；RIVET_LAUNCH_BINDING_PROBE_BINARY/default、RIVET_PROFILE_FREE_PROBE_BINARY/variant及RIVET_CAPTURED_REPLAY_SOURCE由agent私有tool交接，不讓Human找值。Captured source是原LG51 context只讀；測試核原request SHA297a4dd546bb28f262cf4c7f00f437e95ad238e21867827867dbb7e316ffdfa6，再copy rawfiles及source/App到ownedordinary prefix fixture，原root不寫。

| validation相對leaf | final SHA256 |
|---|---|
| Sources/main.swift | d9d3aa68d4f006f2d273e9eb41346446645d89a8df8f1183da7cae04a63f5328 |
| scripts/credential_storage_live.py | 1591468a2de9878cd0d39c6d9c3b4a45c845ee84290d29c882df143c3f553bb1 |
| Tests/test_live_protocol.py | b1ac37798a44ffad1a5f39cb0a865ee3e067da80ad6c3cd088022f3a548bf2f4 |
| README.md | 8264f2c6cbe8f04a8d17c555958dfe581e428c7dabea38c345eeeffd5d0f5c5e |

Final ordinary compile basename `rivet-lg54-compile-i3l4zxd0`：default/variant.command.json及stdout/stderr，compile-source-sha.txt等finalmain，兩swiftc exit0且diagnostic空。Default binary SHA40ce8e4c9e69660639197af3bfdc32342a8660f0d4a6488a498ce31a2ec64ad5；variant3b3206682b7b5626817c99a285ba6afd9704b0197ea42e0369a35471f29e94ce。原frozen-core red ordinary basename`rivet-lg54-replay-n4q5uekr`留main.swift/Replay/replay.stdout/captured-input-hashes.json，有限結果originalGuardLine714/privatePrefixAlias=true；非已安裝App。Repro scripts basename`lg54-prepare-replay.py` SHA0cba9ae91dbd0dee104f5ca3c58ab22836c764168892fb9c8bb17fc800a16cc4、`lg54-compile.py` SHA6150d9ab20696bf768afe453c3670a8ea2b6c2588b87adbe772fde46ad37504d，完整command與工具私有定位已交Dispatcher供LG55重跑。

Readback原LG51 launch operation9e3d7a44…266cd5、machine3aeee262…f6da37、request297a4d…dfa6、context24fb6e…c7d7、signproof38b7cf…fe285皆仍原SHA。沒有修改原App/五模板／source snapshots／build／receipts／quota/ready、未Keychain query/sign/LS/DPK/cleanup或新正式context；普通fixture只自然收尾。**本階段只有unsigned CLI，沒有新unsigned .app**，LG57按既定路由再備actual新App與精確privatecaller/config/proofs，原signedartifact不能冒充新main；LG58後才最後Human原key當次auth及單次LS觀察。LG54只作者完成，交LG55獨立Tester，不自批。


## LG57：新unsigned App與actual私有caller準備（2026-11-04）

LG56 approved/fixes=[]後只新私有準備／自身evidence-row；四reviewed工具葉與五模板不改。新main經真正Xcode same target/Debug、DEBUG LAUNCH_REPORT_ONLY、CODE_SIGNING_ALLOWED/REQUIRED=NO、Manual／空entitlements／無base injection/no provisioning flags／locked public cache build成功exit0。首輪sandbox cache拒絕exit74的root固定stdout/stderr保留；同argv必要escalated unsigned成功log於新derived目錄`build-authorized.stdout/stderr`，不是App重試／quotareset。成功stdoutSHA95db2b01d1b087ea4a83ddd800a102fc4e9b54f577e0b676adb3fe8caabe8bf0、stderr空；原lock不升級不覆寫，沒有Apple帳號／Keychain／私鑰操作。

新source/project各九輸入葉與new privatePBX pin分開；新project另保留**原locked Package.resolved副本**於Xcode標準workspace swiftpm位置，及Xcode自生workspace資料，均在新project prefix內，作standard build輸入/輸出供LG58核，不是新工具／schema／root lock變更。Derived內cache/logs僅新owned build資料；原project/source/App/parents均不改。

純檔案Mach-O preflight（不真codesign）：同原Info BID/executable、no embedded profile、無XML/DER entitlement blobs、無CMS、linker-ad-hoc暫態、0 nested MachO。兩新copy tree均d51713c80af7bfa08f1464c0496b5c7ced6a67bb7ed0dcd4201004f31a8b216e，binary b4be9446130371c2ab33b800410f093103ec71b58e1d24e5f0621d1860efb51d。暫態seal不作certificate identity；未來只簽新to-be-signed copy。New build proof40202feeebcd3e9ce09a318707071478b1d362e3d969715b6ff536b9b6a86a99綁新source9/command/unsignedbinary，pending-final同link；原buildproof歷史不改。

| 同prep root fixed leaf | SHA256 |
|---|---|
| caller-report-timeout-amendment-1.py | a437302534e2f538d52e6ed22ab4f8f7da599f0452c8f607ce8ef3a3b6d83861 |
| config-report-timeout-amendment-1.json | 541587eff1e965c45a6a615b144c0d80519cf0377ce2d5d635716deda5b04504 |
| controller-report-timeout-amendment-1.py | 1591468a2de9878cd0d39c6d9c3b4a45c845ee84290d29c882df143c3f553bb1 |
| preparation-freeze-report-timeout-amendment-1.json | 5d6732ab358467fd086d9813ff16ff36f0bb27538845ad53d1cfb25f282b8d3d |

Actual新caller/config/controller/freeze exclusive0600／root0700落地並readback；actual `dry-check` exit0、zero-native/privateKeyAccess=false/contextCreated=false/appLaunched=false。原LG51 sign/context成功、launch/machine unknown與全部pins/pairs由common guard以frozen舊validator核，原source/build/unsigned/signed/oldcontext/ready/spent不動；新source9/四工具及新buildproof獨立核，舊machine不餵新schema。Public DER只讀已pin普通副本，無security find-certificate／新cert／Keychain query。新三phase markers/operations/signproof/context均未建立，ready未consume。

**NoApp：7/7、0skip、exit0、1.381s**，實際新caller main→reviewed helper→context/static/binding完整schema；只fake最底層native／既有identity/host hooks，不mock整個核心。Fixture沿用原parent actual rawbytes/pins與公開DER，不改production pin；真helper的必要login路徑FS metadata check不讀Keychain內容／不呼叫Keychain API。Split decoder fixture為同public DER的真LibreSSL三份格式，內存處理不公開CN/Team/serial。Fake sign確改新副本binary/tree，context/launch依新signedproof/finalbinary，原件及parent bytes不變。涵蓋bad subject／decoder rc7有限準備證據、parent/source/pair/spent/context-existing/ready重用拒絕於native前、new bound failure/appOutput不產false success。Fixture signed-host欄只用於走真分支，所有identity/host結果fake，非OS/sign/App證據。

普通private testcase basename`lg57-test-caller.py` SHA76b57d93a1f6f2d61c3ff2837883818597b0c9c96797e007f17ace6efbb0adfa；candidate=actual caller bytes，ordinary scripts/inputs0600。Caller/test AST及Ruff F/E9 no-cache皆通過，不重跑LG55 source全測／compile舊CLI。完整工具定位已交Dispatcher供LG58實讀與重跑。

**Exact三phase命令／deadlines／輸入／停止與Human觀察**已成普通0600 `lg57-OPERATIONS.md`，SHAe785db0d198ab45f78441f328cceb0c726126c1ffe03f443f7287dd6e700c117：皆實際新caller path＋configSHA541587…4504/callerSHAa43730…3861，sign/context/launch各獨立新ready UUID／--ready-confirmed，不串自動流程。原公開DER pin→class/date/Team→deriveSHA1→原key一次sign，不再先查Keychain或要Human找欄位；sign180s／decoder各10s／identity30s、context copy60s、LS binding30s。只有簽後新proof/finalbinary才建固定新childcontext，runtime新五argv／兩env／App+native streams／entryfailure與全attribution成功標準保持；-n/kill/retry/cleanup/DPK禁止。

尚需LG58獨立Review actual files後最後集中Human真正原key當次auth與各段實際觀察；本準備不發ready、不sign/LS/新formalcontext，不替代Human、不自評approved。LG57 completed僅準備交接。


### LG62 profile acquisition 實際交接（2026-11-04）

LG61 approved 後，在本 topic 隔離六檔副本的 Debug target 啟用 Automatic，選既有原 Personal Team。既有帳號會話可用，Xcode 顯示 Managed Profile；未 Build/Run/App sign/LS/DPK，未按 Manage Certificates/Fix Issue，未執行 revoke/trustACL/付費/換身分。UI 操作結果只作流程證據，不代 profile pass。Private PBX 的 Team 與已 pin 原 DER Team 相等；原 source／LG59 project/App/caller/receipts/spent 未被本操作改寫。

已取得並保真保存 profile SHA256 `88ec674b614b3400203013a0d6b6c79c83bfc8516ec6eac4a49cefb00ae58026`；creation 2026-11-04T08:43:09Z，expiration 2026-11-11T08:43:09Z。原 cert exact inclusion／Team／AppID／exact group 授權／日期初核全 true；DeveloperCertificates 僅原 pin，newCertificateObserved=false 只指此公開 profile 所見，不能推全部 Keychain 無新增。未讀私鑰或收 password/2FA；CMS 目前僅 noverify/nosigs 解碼，未宣稱簽章或 Apple chain 真實性；deviceMatch/CMSsignature/AppleSignerTrusted 均 null，交 LG63 獨立純讀核實。

Spec 固定 profile-acquisition-1 七 leaves 均 exclusive0600（root0700），before direct-profile count=0，after=1；原 raw bytes 相等。inputs `35ffe2084122de85d31e27083b43dc4c9ce727fa8e9d7098560f7c88191c4a92`、before `4774ccefdfe940ee61afeb7bb3d147368f18daa7e75ed0e5a4ed490cc977119f`、after `d9f10f5353208eddd4d7cd44c7e763fd0d772a5815fb921f54025ba46c3b384f`、operation `7ef09d84dbbb7cd2eabe99a65b3908252b873f4a7a8eca05439545a5e0d87497`。Operation 為 unknown/profile-validation/unknown，保留驗證未完成，不把 candidate 當完整可用結論。Human count/whole/actions 未報均不補造；後續觀察由 Tester 綁本 operation SHA。單次 consumed/pending 保存，不重試、不建立 DPK context，不清理。LG62 completed 僅取得與初核交接，交 LG63 Tester；非 approved 或 DPK ready。


### LG62 RF-LG63-01 最小回修（2026-11-04）

只依已 pin deviation-list SHA afc7553f504a585f0e5c602640b81d5663d2ed1f8b6371e5ed9051ca317609ce，逐層 O_NOFOLLOW/O_DIRECTORY、root boundary、ownUID、dev/inode及原 mode 核對後，fchmod 清單內11個隔離 project/metadata 目錄為0700；未改檔案 mode／原資產／KeychainACL，未follow symlink。七固定 leaves/hash（包含profile/inputs/before/after/operation/consumed/pending）前後完全相同。Owned ordinary fix receipt SHA dec8ded1ccc4da48f8b1afbff2e6d556c7df12815e874c392e223742589e7eed，精確私有定位已交 root；只本 RF 交 LG63 純讀複核。未重provision/profile/CMS/trust檢查或tests/build/sign/launch/DPK/context/cleanup；保留 LG63 已驗 profile 結果，不自批。


### LG67 DPK 接線作者交接（2026-11-04；未live）

完成四葉bounded delta：互斥DPK purpose/profile-aware verifier、phase/round binding、同次report→liveinstance核對→ACK後正式facade/Probe.perform→六欄operationResult final、once/ownership、deadline與unsigned prepare入口；原report-only仍拒profile/零DPK。無production/API/五模板/原profile/歷史變更。4個真正red→green；final affected **54/54、0skip、2.806s**，包含Python actual DPK wire/publication＋ordinary finite child、Swift新DPK 6共用parser/FS/ACK/operation fake cases及原binding/cert/profilefree/shared-operation適用回歸。AST2/2、Ruff F/E9 no-cache、strict swift-format與SwiftLint均過；final main重編default/DPK/report-only普通unsignedCLI皆exit0，編譯diagnostics空。未建真正DPK App／sign／LS／SecItem／真round/context，也未provision或掃UID。

Final四葉與三binary完整SHA／commands/logs在已tool交接的ordinary basename `rivet-lg67-compile-33eclkpi`之final-freeze.json及各模式.command.json/stdout/stderr、source-sha.txt；精確私有位置已交Dispatcher供LG68。Main ba3103c43f8163b9d6a19a52659813fab28547f8bbf70553799af59706478932；runner b11adfe16b442b43cbfd32f35df3047216a296d9d308aba159ea444db373fb50；tests ab36b2618726aeeace0289a57b3ccdbc292673effa1f845fba083e94f36fcdc4；README 0160601a9a865e2665c4e8fca2df03693797c387f68293a5996dc9d2487a9158。

重跑命令：PYTHONPATH指定validation的Tests，以python3 -B -m unittest依序選DPKControls/DPKWire/DPKInstanceControls/SwiftDPKChecks/LaunchBindingControls/CertificatePreparationControls/ProfileFreeCodeVerification/SwiftSharedOperations/SwiftLaunchBindingOperations/SwiftProfileFreeVariant。RIVET_DPK_PROBE_BINARY指新Probe-dpk、RIVET_LAUNCH_BINDING_PROBE_BINARY與RIVET_FAKE_PROBE_BINARY指新Probe-default、RIVET_PROFILE_FREE_PROBE_BINARY指新Probe-report-only。不得用舊binary冒finalsource。

**限制／下一階段：** Python新NoApp只save-a單段；五phase＋fake sign真改副本＋Rebuilt context完整actualcaller NoApp鏈、真正unsigned兩config App/manualsign caller/config/OPERATIONS尚待LG70，不能以54green代整鏈通過或準備完成。LG68獨立核source/phaseguards與真核心，LG69再review；不自批。絕對deadline10:06:29Z不變，不足start reserve即停；真人未授，提示門檻提案待集中Human。


### LG67 RF-LG68-01 bounded 回修（2026-11-04）

Actual DPKWire 真ordinaryFS/pairs＋前machine/whole Human fixture新增同inode report替換：red 1 FAIL/0.234s（應Rejected卻前進）。最小fix只dpk_stage：先核前machine屬當round/previousphase，再要求report digest等其非null reportSHA256，並以該前machine完整B核report exactschema；全部在previous_gone/PIDquery/下段delegate/consume前。有效前段控制仍可前進；錯pair要求零observer／零delegate／無nextphase目錄。Green affected54/54、0skip、1.152s；AST2/Ruff F,E9 no-cache過。Main/README及三unsignedCLI原SHA不變，未重編或改contract，未live。Runner a546f98c4fe68aca32c8d43007ea80d022e4bd500c6fe9334ba029e0e8db1757；tests ec566bace9ba3016f7da0f4093c73ff2c96b1a11e6cd3c264fd60046a77c833e；完整rf-lg68-01-freeze.json位於原LG67 ordinarycompile scratch，精確私有定位tool交接。交原LG68只RF複核，不自批；deadline不延長。


### LG70 unsigned產物／候選準備與 NoApp seam delta（2026-11-04；未完成）

實際Debug/Rebuilt兩config unsigned App均已xcodebuild成功，stderr空；固定Manual/no-sign/no-provisioning/DPK flag，原App/資產未變。最初sandbox cache寫入失敗logs保留，之後在已授require_escalated範圍成功，非DPK launch retry。普通準備basename `rivet-dpk-preparation-mle5sxmg`保存實際command/rawlogs/preparation.json、兩unsigned原件、profile嵌入但未sign的Debug副本、原buildsource9快照及候選caller/config/controller/freeze/OPERATIONS。完整私有定位已tool交接。Debug binary45e411ad0405d1f5dd9e532c31d77ef158598899219b2cbeb26bfed17296964a；Rebuilt d7fc2eb3487dfe6f64bff4619d08f188b224ff1a85ae9c89542d3c250a2cf130。預備Rebuilt不是正式rebuild；正式流程仍須read-b及Human成功後重新clean/build，caller候選保此命令及rawlog/時點紀錄，不能拷預備產物冒充。

**準備未完成／不可live：** actualcaller候選與privateinputs已落地，AST可解析，但五phase＋Rebuilt完整NoApp尚未通，未有LG71 approval。candidate-state明示NoAppComplete=false/futureRoundAbsent=true/operationsEmpty=true，不建真context/ready/round、不sign/LS/DPK、不provision/cleanup。Caller候選SHA0c11394d7634f4c4ad21d57d0ee4f3f08e6b901b276a77b3a087d722d49d64a8；config c58d60ad080d1434583b6cc734f063e67016a1022cbfd282da2042fa01b71ff3；candidate-freeze35c89563c88f61102ec6cb1f0a3eba1e699a6d87e89af58f722f50ba6a6cae83；OPERATIONS f2ca5e00b10ad40ad2aff07e0dee369e4eba643519ffd70f745a8818d709af0a。候選仍引用原受審controller，沒有偷偷改既有buildsource9或整鏈假pass。

發現NoApp真static驗證固定signed-host而fake-only鏈不能進；root明授最小source seam修補。只binding_verify_static新增內部mode參數預設signed-host，將同一真proof validator的mode改用此參數；無CLI fake旗標、production預設不變，未省略profile/claims/native identity核對。StaticEvidenceModeControls在原frozen controller真red 1ERROR/0.068s（不支援explicitfake mode），新source驗default拒fake且零native、explicitfake走真validator綠、invalidmode拒且零native；mode與certificate/publicDER皆實際解析、不mock整validator。連既有54適用checks final55/55、0skip、1.364s；AST2/Ruff過，main未變不重build。Runner f2b52c9eafea0a0ea4af0aedea905a3cd74ed624bea1d7c66f48afbea6ca3c47／tests9d078c8b68e3c31c641c56f2a74d599dc1c7a051f028086e888b833ae018f603；freeze在原LG67 ordinarycompile的noapp-mode-delta-freeze.json，精確selector/env已tool交LG68複驗，須LG69獨立回查。本角色未自批；source/operativecontroller已停改待獨立確認。

10:02:23Z快照剩餘不足正式rebuild的540秒start reserve，不能本窗口補跑全live；10:06:29Z hardstop不延長。整套DPK驗收仍未通過，LG70未完成，不能拿工具成稿或profile成功替代。


### LG70 限時收尾：pending／incomplete（2026-11-04）

依Dispatcher明示停止新增操作，只保存既有結果。本輪窗口09:06:29Z–10:06:29Z含Human等候，未延長。兩個真unsigned App、candidate caller/config/原controller、原buildsource9與freeze/OPERATIONS已保存，前述SHA與歷史不改。最小NoApp test-mode source seam已由LG68/LG69獨立approved（依各角色既有evidence/row，不是本人自批）；但未接operativecontroller，完整五phase＋Rebuilt actualcaller NoApp仍未完成。故LG70 pending/incomplete，LG71未審、LG72未開；真正首阻礙是NoApp test-mode整合準備未完成，繼而review/live未到。有效profile已由LG64交付且仍在既知有效期，不是阻礙。

七步實際live狀態全未執行：①假A正式保存，②該writer結束的確認，③fresh reader A，④整筆替換B，⑤fresh reader B，⑥同identity真rebuild，⑦rebuilt fresh reader B。預備Rebuilt產物不當⑥；source/fake測試不當①–⑦。未取得本輪Human freshready，舊ready不reuse；依最後已得candidate-state，futureRoundAbsent=true、operationsEmpty=true、realSign=false、AppLaunch=false、DPK=false，未建立真context或更新profile。截止前剩餘已不足540秒正式rebuild start reserve，不start任何live、不以沉默或時間提案宣稱通過。整套DPK驗收未通過。

已知工具session：sandbox首敗unsignedbuild已exit1、escalated兩config build已exit0、三CLI compile及最後55 tests均已完成；無已知仍在執行的本角色command。不為此另掃process，不任意kill／cleanup；Xcode可仍開既有隔離profile專案，本角色未啟Build/Run或後續資產操作。自此不再source/operative修訂、NoApp新cycle、test/build/sign/App/DPK/context/provision/Git操作，只保存既有結果。


### LG70 續作：offline NoApp milestone complete（2026-11-05；非liveReady）

Human「可以繼續了」授權同PR60離線operative整合／NoApp／獨立測審；原2026-11-04窗口已關閉，不延長／重設、不推新一小時或live。RO快核四source、profile／公DER、原candidate/caller/config/controller/freeze/OPS、雙unsigned binary均原SHA，profile按當前日期仍有效；不重CMS、取得、純啟動或未受影響測試。原正式round仍absent，production operations空。

Operative-resume-1保原candidate及原buildsource9，另列operational controller freeze，顯式fake-only static verifier與scoped fakeclock adapter呼叫既有真dpk_time(now=synthetic)，原guard/cutoff不改、CLI無fakeclock。首個actualcaller sign-debug red定位原helper profileAbsent：過早embed profile，未真sign。保留red fixture/finite-trace，operative-resume-2只調順序：unsigned原DER/helper核→同once操作embed固定profile→manualsign native boundary→DPK postverify；不弱化原source guard。

**Actual NoApp完整15 actions／5 runtime綠：** sign-debug/context、save-a+observe、read-a+observe、replace-b+observe、read-b+observe、rebuild/sign-rebuilt/context-rebuilt、rebuilt-read-b+observe。每個runtime均operationVerified=true、hostAttributed=false；真Swift parser/FS/Probe.perform/六欄/ownership/report-ACK-final穿實際caller資料，fake store A/B跨子程序保留，own finite child均自然wait。Fake sign真改副本，最低native build fake在read-b後產新binary與新context，不把預備copy冒充真建置；NoApp actualCleanBuild=false。合成observe記錄只fixture輸入，不是Human零提示證據。

Fake participant由原frozen main前112361 bytes逐byte相同核心編譯，prefixSHA2cb335d1cd1a8045cf55476e2774e9d043f4e1799e458091e8af82e2e3c84640；只追加DPKValidation scoped Date primitive alias＋test entrypoint/最低identity/native fake，原判斷不改。Debug/Rebuilt普通CLI均compile exit0；fake-only context才可用、root必ordinary NoApp前綴、supplied fake store且mode假分支零SecTask/SecItem；非signed-host grade。NoApp完整腳本、compiler source/commands/proof、成功result/records及old red全部已tool交Dispatcher供獨立Tester。AST／Ruff F,E9 no-cache通過，不改repo source／原unsigned buildsource9或重build App。

Freeze：operative-resume-2 caller da64b4e7a874b0c48609be0fa91e1c02d91e458c6a9bb10c17c4db0a10e92e64；config598d672b9bb2b9f7c88edb7bfb900f3cbade76e914e7afead0a0678e5a486033；offline-handoff-freeze37851765dbcb9b76dbb5f36f67d0148ead1cee378a55dc82918f631f694d6499。NoApp script4182f0429694b91135b9e4b3ee2422cb6500f46c66719249a3201f46bc106ad7／resultfdca256c204ade6f8759c8cc056d4fcaeac5aeef955b8aa387029908eb9bf75c。精確私有定位及重跑command僅tool交接，公開不印本機路徑/IDs。

Offline里程碑已完成交獨立Tester；LG70整體仍pending：新live authority/deadline實際入口尚未定義，舊live預設仍expired拒絕，不能宣稱liveReady或索ready。下一步先獨立重跑本bounded產物，再將新live窗口必要source/契約delta交獨立PlanReview；未新cert/revoke/trustACL/TeamAppID/pay/Auto/profile更新、未真sign/App/DPK/context/cleanup/Git。原歷史、候選、spent/readies全部保持。


### LG75（2026-11-05）：新window source／affected nonlive完成，待獨立Tester

Status：completed（作者實作交接，不是approval或liveReady）。依LG73/LG74：exact descriptor/Human/authority factory＋exclusive consumed/pending發布、kernel boot canonical hash、UTC/mach-continuous clock及每participant已觀測回退；verified window顯式傳Python phase/native與Swift同participant operation/store。新round/context/build/sign proof帶同authoritySHA，既有B經contextSHA/roundSHA接合；report-only exactschema/profile deny不變，無authority仍舊expired。新DPK direct binding入口缺exact當段ready先拒，ready-confirmed不能繞過。到期已開始native保原rc/例外，禁止後續postverify/native/store，有限deadline結果保持unknown。

TDD red：4個window API缺少之局部tests；另native前時間guard測試缺method先red。Green：final affected **70/70、0skip**，包括Python真FS/factory/once/boot/clock/ready/資產到期邊界與request→context/proof→report/ACK/final真wire、direct入口無ready零spawn；新Swift selftest真parser/FS/sharedoperation的9個DPK cases及14個window checks，跨boot但兩clock表面合法仍零store。原rc=17的同一exception物件保留；過期後第二native不啟動。保受影響report-only/normal/privatecertificate-helper回歸，不重production全面suite/CMS/profile取得/已過真人純launch。

Finalsource三個普通unsignedCLI均compile exit0（default/DPK/report-only）；Swift strict format＋SwiftLint、Python AST＋Ruff E9/F63/F7/F82均通過。Compile/result/freeze/可重跑腳本已精確tool交Dispatcher；未公開本機abs/私ID/rawerr。四葉freeze：main `78eede7ec1132d7dc84d6762d0e61c737d6eac9e51950b623194fda05b680213`；runner `ba6ed95fa2fc15c4746bc4aa5e854fe71d6825084aaa8ead1b7e3db03117fa68`；tests `3f366e0fee9580f475a82ea14f5833c8d03c6a389c80df6da97874127ee81e09`；README `22738d75b2e069db08f24d1e2fff55511b2160186ff72848972c186841464490`。

本輪只ordinary synthetic fixtures／fake-only unsignedCLI，不建立真人authority/window/context/ready或操作真sign/App/DPK，不動原history/App/buildsource9/profile/assets/已核舊15-action鏈。新schema的完整actualcaller五phase/Rebuilt NoApp、兩真unsignedApp與新descriptor/operation commands仍由LG78準備、LG79獨立核，不能以本source checks當已完成準備；≤60min與兩提示提案仍待最後Human採用。無已知本角色runningcommand（本次compile/tests均返回）；未scan/kill/cleanup/Git。交LG76獨立Tester，再LG77Reviewer。


#### LG75 RF-LG76-01 最小修訂（2026-11-05）

Status：completed（作者修訂，交原LG76複驗）。原反例先red：cross-boot未拒且後續decoder=3。修後原actual binding_verify_process selector green：cross-boot拒絕、後續decoder=0。Shared identity把三個decoder同codesign/csreq送同explicit window native guard，保同一pinned DER實際stdin/剩餘timeout；static/dynamic/sign-preparation成功接受前重核boot/UTC/mono，最後成功native之後跨boot/到期也拒，原非零/exception保留。No-window legacy/report-only原路徑保持。

新增3個窄回歸穿真sharedhelper＋最低subprocess fake：extract後跨boot零decoder；正常三decoder stdin/timeout、subject後跨boot與class最後返回後到期；decoder rc17/error bytes仍原物件/內容，不因clock變覆蓋。Final affected73/73、0skip及AST/Ruff通過，原Tester反例獨立腳本也green；未sign/query/App/DPK/context/window/資產。Main仍原LG75 freeze，不重編、不改Appbuild9/歷史。新runner `b4e28abb50c348f93870aadb4ad6256805c275039c7242530cb7fa19c8d40916`、tests `f0b5f63a15a09b23dd22db15a0d06f67ac28b07d9ab248ff9025413efb7d3b80`、README `2650c6b9980bd43f5d4c71f22f32d381d9ca6ccb121071716710555c40fdee38`；RF freeze/再現腳本/logs已私有tool交Dispatcher，原LG76 needs-rework歷史不改。


### LG78（2026-11-05）：actual準備完成，交LG79

Status：completed（作者準備，不是liveReady）。LG77四葉未改；新Debug/Rebuilt真Xcode clean/build均exit0，Manual/no-sign/no-base-injection/noProvisionUpdates、原BID。兩App binary不同，owned originals與簽署副本分離；profile absence、empty claims、BID/Info對照通過，linker ad-hoc不是憑證身分。原profile/DER只quick pin/日期沿LG64，公DER bytes離線無trust/Keychain解析備妥原Team/class/date/SHA1selector，不要求Human找欄位；無資產新增/更新/簽章。

Actual caller/config/controller/descriptor/OPERATIONS及新source9/buildproof/private freeze已落地，顯式parent連原candidate/LG59/LG64/已核offlinefreeze，原App/窗口/ready/quota/history不改。Descriptor先凍結unsigned provenance；真Human record及window factory只有最後實答後才可執行，簽後proof再接真binary/context，不預填未知signed SHA。每後段freshready exact phase/authority/clock，270s sign／120s context-runtime／540s rebuild minRemaining；正式rebuild必read-b＋Human觀察後實際clean/build，預備Rebuilt不代替。期限內已啟命令只自然settle，禁止到期新postverify/phase，不kill/cleanup/retry。

新版actualcaller NoApp（最終caller bytes）**15 protocol actions／5runtime全綠**：由actual record-ready→factory建立synthetic authority，再完整sign/context/A-save/freshA/wholeB/freshB/read-b後fake-native cleanbuild/sign/context-rebuilt/freshB與5observe；每runtime operationVerified=true、hostAttributed=false。Fake sign真改copy，fake rebuild產不同binary/context；真Swift core prefix逐byte相同，只最低clock/boot/OS/store test-entrypoint fake，兩unsigned fake participant編譯exit0。ActualCleanBuild=false，synthetic Human輸入不是真人零提示證據；NoApp沒有執行真open/codesign/Xcode/DPK。AST/Ruff通過；不重原source全面tests/原15-action里程碑/CMS/純launch。

Freeze：caller `95f1ca8e563a8536687d2a1e137b5fd68ac6b9e0f2cc7afde5d8eb8489d80575`、config `6412f32e9862016f14bb97f94c636e7dccfe133f155787df41bb19605e8c382f`、controller `b4e28abb50c348f93870aadb4ad6256805c275039c7242530cb7fa19c8d40916`、descriptor `9d212a073e3586f078a0691eca479158ee74d51cf25fd18f62ec5086c2fec4f6`、OPERATIONS `0921682c375c6c1d91af5593f8c936ab77c1e3a5ddeb5cecc4f7d73c59e71d97`；preparation-freeze `750fe76370e26e1226183a46e4fe5a244182859470e0d188a32332feb302a7ac`。NoApp final result `0177150395445a6d8135fdae06b604851c4dfd3cfb855e842339cfc6eb712c13`／compile-proof `292c699422ecc870b3f4fb1e8dd2b59a3ea1bd7249e11fe187f3d84ab726edef`。完整私有定位/重跑命令已tool交Dispatcher/LG79；不公開abs/原始身分。

Human/authority/window-open-consumed/pending/phase-ready/round/context全未建、operations空；新≤60min與replacement0/build-sign keyauth≤1仍提案，首次save≤1、freshA/B/rebuilt0保持。只有LG79獨立實讀通過後才集中請Human採用窗口/判準及真正freshready，之後各段實答觀察；現在不操作任何私鑰/真sign/App/DPK/context/provision/Git。已知本角色build/compile/NoApp command均返回，未為此掃process或kill。

新unsigned binary SHA：Debug `7cabe2dc3a4cce3f5f1880f2998d32a5f1d82d28abf6702a5fac90b6cdbcf2b4`；Rebuilt `f0f64681c0dbce8bdc303a6529613d70d86608bf0b35fb66bbdd42300cf96fab`。


#### LG78：LG81 stopped-preflight cap amendment（2026-11-05）

Status：completed（作者窄修，待獨立Tester/Reviewer）。原record-ready synthetic反例先red：硬寫3600導致end超外部cap。只新增parent-linked private cap-amendment-1，不改原caller/config/descriptor/freeze/OPS/LG81停止史；controller/main/App/buildsource9及正式Human/authority schema不變、不重build。固定本輪STOP=2026-11-05T06:48:07Z，既有整套grant/政策持續，不延長或重開一小時；第一段已停止，新sign freshready仍待審後Human。

初始record-ready必帶與config逐值相同的UTC --deadline-cap，以真kernel雙clock捕捉及actual UTC nanoseconds算floor(cap-now)，必>270且≤3600，既有windowSeconds承接；factory不移起點，各action還核authority end≤cap。非法/非UTC/過期/太短/>60/缺cap以及非window action帶cap均拒；原無caplegacy資料保原語義。新子Rebuilt command使用新DerivedData/project副本，live proof記實際command hash，原建置歷史不改。

窄actualCLI/factory **6/6**：fractional floor、延後mint不延cap、非法/expired/too-small/nonUTC/>60、缺cap、新舊無cap區分、非window誤用與partial/exclusive拒絕；全部普通synthetic fixture。最終新caller完整NoApp **15actions/5runtime綠**、hostAttributed=false，真record-ready/factory及shared核心/假signed copy/重建context仍穿，無真sign/App/DPK。AST/Ruff通過。Actual root/freeze/OPS/重跑scripts已tool交Dispatcher供獨立實讀，原6測試與NoApplogs保存。

新freeze `4528405fd24e13400227f233355f2cca767e119d940500c58af636b9e7364248`；caller `7f1ce81998170b5c13141e86b685ea0f2e84d378b8db00d2d4dad4cd6be519ad`、config `88c0410c382b33d2079724a8de29deae5b7ad4e2013611af828311cc6f728d38`、descriptor `f55a28e067259b95026d8a3bf007f72a540923c0ffed4519c69c5915368a5fae`、OPS `3dadc558b49ae84021b95ff5be6bc67f295923d133f6e86ad14a3dcbab86cc49`。真Human/authority/pending/consumed/ready/round/context未建、operations空；沒有query/sign/provision/cleanup/Git。交root路由Tester/Reviewer，不自批、不續用已停止ready。


### LG84（2026-11-05）：受限 docs closeout 完成，交 LG85

Status：completed（作者，非approval）。依LG83／LG82 D六葉，只修能力／驗證／導覽文字：README、design-principles、architecture README／dual-client／credential-persistence、validation README。現在式明示LG81-Cap-R限定假bundle／指定環境的完整跨程序與真同身分重建、五runtime Human0；不擴張首sign的permission-only觀察，也不宣稱configuration item、真OAuth／API／登入、denial、斷電或所有環境。Cleanup LC06、圖Human visual／S08與PR整合仍未完成，舊unknown／候選章節原語境保留。

Publication既有leaf追加本地PR title/body、五conflict／configuration公開契約差異及後續consumer核對、exact-stage／commit-message暫擬；未更新遠端PR或整合dev。舊sequence只在文字標初始adapter snapshot，圖及技術QA bytes不改，沒有新圖／工具／summary artifact。Validation README純doc新hash不覆舊buildsource9／manifest／proof，未以新hash重測／重建。

有限author checks完成：D六葉relative file links缺失0、whitespace0、有限secret／本機abs findings0；git diff --check對D＋publication通過。修改前後21個已捕捉Readonly檔hash同（V八code/template葉、圖檔及一個個人metadata）；另只讀定位兩個個人.swiftpm metadata並保存目前雙檔checkpoint，供LG87 stage前後核對／精確排除，不清理／改寫。私人重跑腳本、before/after/hash及result已tool交Dispatcher/LG85，無公開abs或身分資料。沒有執行tests/build/sign/App/DPK/CMS/cleanup、stage/commit/push/merge/rebase或PR write。

D六葉SHA：README `186a6d7f4c0cb1131340552a5cadfb0e9607eb0c091e7813476f0c0ba75f78b3`；design `55dd9363d404fe6ad57bda2ef5dbd0a88a3d05f3db2a6c16c91fc57f2a6afb05`；architecture README `6adca78703aa133fb883bcdef88c75a254eb668ccb4085d9f065f8d45d6893eb`；dual-client `14038dc4e4f05e8a30a4cb9149ee6bac2c547ec7b4596d7d8fb928a72a509702`；credential-persistence `a9407854474aaa70c8257160a97cc6f0520ceec89d6411ee338ebf9c5c2447ab`；validation README `0290d1d81a9e40e820914feaba69aa0114c454b75ed2ce2044dfbd508ba5d698`。Publication `4f26c3994f87ea65ddf11079629a52fa84f75f70732b2158d9cc7f044573086c`。交LG85有限docs驗證，再LG86獨立Reviewer；LG87 stage及message提案尚未執行，Human未答不提交。


#### LG84 RF-LG85-01 一行修訂（2026-11-05）

Status：completed（作者修訂）。只將dual-client現行composition中的「DPK，fake-only verified」改為指定環境假憑證DPK已驗、指向同頁正式adapter驗證範圍，並明確provider rotation／persist-stop仍是獨立假backend驗證。該doc新SHA `ed7fe11066eecec9f7d1cacc0378df621aeff8b5cf613c6a5675bf89378a5ee0`；其餘文件/code/圖/歷史/API不改，未重做已通檢查或tests/live，不stage/Git發布/cleanup。交原LG85 bounded複驗，不改Tester needs-rework歷史或自批。


### LG87 exact-stage前置交接（2026-11-05）

已唯讀核index無staged變更，LG86 completed／approved／required fixes=[]。按LG82 D/P/E/V 26個exact允許leaf準備stage實際變更；兩個個人.swiftpm metadata hash與LG84 checkpoint同，保留原bytes，不納allowlist。只此作者記錄及自身ledger在stage前追加，之後不改已stage內容。本段僅記前置完成，不宣稱尚未發生的git add／staged checks已成功；真正staged path/count/stat/diffSHA與skill語意判定，於操作後由tool/private receipt交root及Human，不寫回staged檔以免自指。

既有工具／證據／docs經LG86確認屬單一topic語意；仍須只讀真正staged diff依git-commit-convention決定message，不自批commit。若index/path混雜或staged需調整，停Human、不自拆／reset。LG88為下一Human停點；未commit/push/merge/rebase/tag/PR write，也不執行tests/build/sign/App/DPK/provision/cleanup。LC06、Human visual/S08與五conflict整合仍尚缺。


## LG91（2026-11-10）：dev 非提交整合與 configuration 邊界

上游 LG90 approved／required fixes=[]。依 Human 採用，在原 feature `fbd4434a` 準備 `git merge --no-commit --no-ff 758aca9bb518f2a21f20f47609335fac49043370`；HEAD 未變，MERGE_HEAD 精確為該 dev tip。事前 index 空，五個 dirty planning／review 葉與 incoming paths 無交集，private copies／hashes 保護後完成 merge，恰有五個預期 conflicts。

五葉已解並 exact-stage：configuration 完整保留 feature 原 bytes；四 Markdown 保留兩邊有效內容，將首次授權與正式 DPK 的現況對齊，獨立驗證工作線的 freeze／成功／unknown／失敗留原歸屬。dual-client 新短節明列 typed constructor、兩 factories guard 與 App blank-only 前置狀態限制；未改其他工作線檔案或圖。公開 init 仍 typed／public fields／不 trim；兩個原一般 throwing factory 只增共用 private blank-validation、在建立依賴前拋 AuthorizationError。這是 Human 採用的直接 constructor 錯誤型別變更，不稱 dev 所有直接呼叫端零回歸。

### 實際 TDD／受影響檢查

| 邊界 | 結果 |
|---|---|
| RED：新兩 factory blank ID／secret 反例，production guard 尚未加入 | 3 tests／1 suite、8 issues、exit 1；各空白值仍成功建立 fetcher／session，可歸因缺 admission guard，非 compile／環境失敗；原始 fake diagnostics 僅私有保存 |
| GREEN：同一 suite 加最小 guard | 3 tests／1 suite、exit 0 |
| 受影響整合：DPK fake store／provider／factories／authorization session／code exchange／static isolation | 74 tests／6 suites、exit 0 |
| 獨立 public consumer：typed init function reference／未 trim public fields／兩空值 typed error／既有 public surfaces | 11 tests／1 suite、exit 0 |
| 四個受影響 Swift 檔 strict swift-format／SwiftLint | 均 exit 0 |
| 四份衝突 Markdown | 102 個相對 links 含 heading anchors、conflict markers／有限 secret 及本機 abs patterns 零 findings；diff --check 與 cached --check 均 exit 0 |

命令（root package 執行；consumer 明列 package path，raw logs 僅私有）：
- `swift test --skip-update --filter GitHubOAuthFactoryTests` → 1。
- `swift test --skip-update --filter GitHubOAuthFactoryTests` → 0。
- `swift test --skip-update --filter GitHubOAuthDataProtectionStoresTests|GitHubOAuthFactoryTests|GitHubOAuthAuthorizationSessionTests|GitHubOAuthCodeExchangerTests|OAuthTokenProviderTests|GitHubIntegrationTests.StaticIsolationTests` → 0。
- `swift test --package-path Tests/GitHubIntegrationConsumer --skip-update --filter PublicAPITests` → 0。
- `xcrun swift-format lint --strict Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` → 0。
- `swiftlint lint --strict --quiet --no-cache Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` → 0。

### 來源／stage 與限制

Merge 後、手動修復前保存完整 auto-index stages；resolution 後核 1,328 個非手動 auto entries 的 mode/blob 完全相同，零額外 delta；全部 unmerged stages 已清。手動 stage 僅五 conflicts＋factory／FactoryTests／PublicAPITests 八葉；dev 自動帶入的其他檔案保留來源，不是本輪手寫變更。四 planning 與 Reviewer planning evidence 在 merge 中原 bytes 保留；自己的本交接及 step 變更另列。兩個個人 metadata 原 bytes 未變且未 stage。

| 手動 source／test | SHA-256 |
|---|---|
| `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift` | `570bfc17cc8d3c5d4701b47a74043c1294196c52cec95ff8c9831a9761b60e95` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift` | `6075c4b2127df0a73cd2bd6d9f1342345c19cc417b3e9b0215c82c0ee493ff40` |
| `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift` | `ef5f11eb9f381488f99b13c78a9364ccab478a5b7c3f4c8a9a3428fe2229a833` |
| `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` | `f168355968e2e2fecfcd56ed1c7fda6ac024e2cbb3d63caf60bfe8e15b796276` |

正式 stores adapter 及 configuration source bytes 與原 feature 完全相同；原 LG81-Cap-R 證據仍只涵蓋其原來源／假 bundle／指定環境，不證明新 merged binary 已真人驗收。未啟 App／DPK、未 xcodebuild／codesign／修改資產或清理，未重其他 topic／完整 live suites。尚未 commit／push／更新 PR，也未代 LG92／LG93 approval；遠端 conflict 要待必要審查及新 Human commit 核准後才可能解除。私有 baseline／auto-index／resolution／doc-checks／每次命令 stdout/stderr 與 JSON 位置已工具交接，無私有路徑寫入本文件。交 LG92 獨立 Tester。


### LG91 最終 exact-stage 前置（2026-11-10）

LG93 approved 後，已核原八個手動 resolution 與 1,328 個非手動 auto entries 及個人 metadata 未變，剩餘 unstaged 僅四 planning 與四 owner evidence 的已審內容。依同一雙親整合語意，只將這八個精確 leaves 加入既有 merge index；publication 未修改。本段寫入時實際 stage／stat／diff SHA／commit-convention 檢查尚待後續工具，不預填成功。真正 staged 結果私有保存並交 root／Human，不在 stage 後追加 tracked 文件；未獲新 message 確認前不 commit／push／更新 PR。


### RF-LG94-LINT 作者修復交接（2026-11-10）

上游 bounded planning review approved／required fixes=[] 後，只套用已審候選：StaticIsolationTests 的 expectedPaths 前兩字串併同一行。原 source SHA `14a5aedc7f7553acd534e0a1e3348310fd300fae6408c1af6310a62f852a4508` → candidate／repo SHA `1640e25df6e28dc610757e702513875dfbeb3e3f6b6d74e9ce335d95fdc1484d`；non-whitespace bytes 完全相同，801→800，不改 allowlist／保護或 lint 規則。

真 repo 單檔 `xcrun swift-format lint --strict Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 與 `swiftlint lint --strict --quiet --no-cache Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 均 exit0。`swift test --skip-update --filter GitHubIntegrationTests.StaticIsolationTests` 未用 skip-build，實際 compile 該新檔／Build complete，29 tests／1 suite 通過（wall174.046s，suite36.359s），非零命中、自然完成，未 timeout／kill。原174秒包含 build／工具等待，不能冒稱 suite 同耗時。原74／11／live不重跑。

八個已審 resolution source／docs hashes、兩個 metadata bytes 與原 staged index 保持；只工作檔一行修復、四 planning 與 owner evidence 可見變更。第一次 normal hooks commit exit1 的原 receipt／raw logs 私有保留，不改為成功；本輪未 stage 或 retry commit／push／PR write。source patch／不變式、compile 與三個 check 收據已工具交 Tester，交獨立 bounded 驗證／成果審查，不自批。
