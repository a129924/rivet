# OAuth credential storage 真人驗證工具

本目錄只屬於 `github-oauth-credential-persistence`。它是包成 `.app` 的 async CLI，連結 root package 公開 `GitHubIntegration`，不包含登入／OAuth／網路，不抄 credential codec。準備測試及 unsigned build 不表示真 DPK、有效 profile、跨程序或提示已通過。

## 目前驗證狀態（2026-11-05）

[LG81-Cap-R](../../plan/github-oauth-credential-persistence/evidence/live-preparation-review.md)已獨立確認：指定簽章環境的正式 public adapter，以完整假 bundle 完成 A→writer 結束→fresh A→整筆 B→fresh B→同身分真 clean/build／簽章→rebuilt fresh B；五個 runtime Human 全程觀察均 0 提示。完整六欄、fresh instance、不同 binary、原 identity/profile/claims 與同 request/report/ACK/final/operation 鏈均成立，詳[逐段紀錄](../../plan/github-oauth-credential-persistence/evidence/live-validation.md)及[長期契約](../../docs/architecture/github-oauth-credential-persistence.md)。不是 OAuth／產品登入或所有環境保證；configuration item、系統拒絕、斷電 durability 不在本輪 live 證據內。

全部 live 已停止，原窗口／readies／額度不可重用。LC06 cleanup 未做且本輪禁止；Human 視覺與 topic 接受仍 pending。下文依原階段保留工具與候選歷史，舊「待驗／仍停」只描述當時狀態，舊命令不構成新授權或可直接續行的 ready；歷史 unknown 不改成功。本 README 的本次文字修訂不改寫舊 buildsource9／manifest／收據 hash，也不表示曾以此新 doc hash 重跑或建置。

## 歷史準備與操作說明（非目前執行授權）

最初 L02 只準備 pure controls 與 unsigned compile；原準備及真人 setup 歷史留在 topic evidence。先前 L02-Retry1 已完成，後續真Writer仍unknown；本次只D02最小診斷工具準備（詳末節），不是重試A。原候選準備範圍：pure fixtures 與既有 unsigned fake-only binary，不重build不變Swift、不簽章／啟動App／SecItem，也不建立真人 retry directory／policy／ready。先完成獨立Tester／Reviewer，之後才由Human採用新政策並提供當段freshready。以下命令是操作說明，不表示已執行或已授權重試。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py
```

Unsigned compile 可將 project／Sources／Resources 複製到一般編譯暫存（不是 live runroot），把 project 的 local package reference 從 `../..` 換成本 feature worktree，依序執行：

```sh
xcodebuild -project "$RIVET_BUILD_PROJECT" -scheme CredentialStorageProbe \
  -configuration Debug -derivedDataPath "$RIVET_BUILD_DEBUG" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= clean build
xcodebuild -project "$RIVET_BUILD_PROJECT" -scheme CredentialStorageProbeRebuilt \
  -configuration Rebuilt -derivedDataPath "$RIVET_BUILD_REBUILT" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= clean build
```

不要並行對同一 project 做 clean builds。不要執行 unsigned App。最初 L02 的 Swift 部分只有 compile／人工接線檢查。L03 bounded 回修新增同一 Sources/main.swift 內的共用 operation seams；下列測試會以 fakes 執行實際 perform／cleanup 控制路徑，不是另一套平行假流程，也不是真 Security／production adapter 的 live 執行。

## 獨立審查後才可建立 live round

設 `RIVET_VALIDATION_REPO` 為本 feature worktree、`RIVET_VALIDATION_PARENT` 為 repository 外的私有暫存父目錄；runner 只會建立 exclusive `rivet-credential-storage-<UUID>`、0700 的 owned root。

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  prepare --repo "$RIVET_VALIDATION_REPO" --parent "$RIVET_VALIDATION_PARENT"
```

prepare 不簽章或呼叫 Security。UUID／service／source hashes 的 `run.json` immutable。Production adapter／configuration／bundle／package source 及複製的 Swift／Resources 每次重驗；private project 可在 setup 觀察期間由 Human 用 Xcode 選既有 Team／profile，之後 `identity.json` 凍結其 hash，不再允許改動。不得把 raw path／IDs／profiles 複製到 repository 或貼到公開紀錄。

每段的 ready JSON 必須由當次 Human ready 產生，`readyUUID` 為新 lowercase UUIDv4，不能重放：

```json
{"runUUID":"<本輪 UUID>","phase":"setup","ready":true,"readyUUID":"<本段新 UUIDv4>"}
```

setup fresh ready 前不要做簽章／profile 操作。Human 只需操作 Xcode／系統畫面，不需貼 Team、group、certificate 或 profile 私人值：在私有 copied project 選既有 Apple Development identity／profile，將該 project 的 Derived Data 設為 owned root 的 `derived-debug`，只 **Build，勿 Run**。若 Xcode 要新 certificate／安全設定／付費，停止。手動產物的固定位置應為 `derived-debug/Build/Products/Debug/CredentialStorageProbe.app`；Agent 只唯讀檢查這一個 exact App，不 inventory 其他 App／帳號資產。

Agent 使用下列 `stage setup --built-app` 接線：以當段已取得的 ready 記錄唯讀導出該 exact App 的 identity／embedded profile／certificate 至私有 JSON／profile copy；Human 不輸入 identity JSON。私有 source／project hash 隨後凍結，再執行正式 clean build。手動 Build 不當作正式 source/build proof，不能只憑它宣稱 setup 成功。setup 的完整觀察從 Human ready 後的 Xcode／系統操作一直涵蓋到 runner 回 machine SHA，之後才收實際提示數；若中途停止，也以 unknown 收據保留已發生觀察，不將手動子步或正式 clean build 的提示推定為0。

`--identity-file` 僅保留為 Agent 已有私有設定的低階入口，不能要求 Human 提供私人值；`inspect-built` 同樣只是低階 preflight，不是主要 setup 流程。禁止 provisioning updates／device registration／authentication-key權限旗標；runner沒有匯入或建立／刪除Appleassets的命令，不承諾Xcode的所有本機cache零變更。

正式 setup 會對私有 project 以固定既有選擇執行實際 `xcodebuild clean build`，保留 command/source/build proof，檢查 profile、cert、App ID、唯一 keychain group、DR、非 ad-hoc，安裝到同 root 固定 `current/CredentialStorageProbe.app`。沒有足夠 profile 不會因 identity count=1 而放行。

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  stage --root "$RIVET_VALIDATION_ROOT" --phase setup \
  --ready-file "$RIVET_READY_FILE" --built-app "$RIVET_MANUAL_BUILT_APP"
```

## 每段操作與觀察

順序固定：setup → save-a → read-a → replace-b → read-b → rebuild → rebuilt-read-b → cleanup。除 setup 外，`stage` 不帶 identity-file／built-app；每段都帶自己的 ready-file。setup／rebuild 不呼叫 SecItem。Runtime 只能以 `open -W -a <固定 App> --args ...` 啟動，不用 `open -n` 或 raw binary。每次前 PID 已結束且 process UUID 不同。

- save-a：精確 namespace 必須 absent；先持久化 absence，再持久化 write-attempt marker，才 production save A／read六欄。提示 ≤1。
- read-a：fresh read A，提示 0。
- replace-b：先確認 A，再完整 save/read B；記實際提示，不設額外門檻。
- read-b：fresh read B，提示 0。
- rebuild：真正 Rebuilt clean build；same source／certificate／profile／App ID／group／DR／位置且有效，binary 不同。marker 由編譯條件寫進 App receipt；不只靠 hash 不同。
- rebuilt-read-b：fresh read B，提示 0。
- cleanup：另段觀察；只刪有本 run absence＋write-attempt ownership 的 exact DPK service/group/credential account，之後 production adapter load=nil。沒有產品 delete／logout API。

每段完成，runner 印的是安全 public machine bytes 的 SHA。合法 ready 消耗後的 build／inspect／launch／receipt guard 失敗也會提供有限 unknown machine 與 SHA，讓 Human 記錄真正已發生的提示；工具能回收據不表示驗證成功。未知 child／來源或身分不明時不宣稱 fresh／valid，不啟動依賴段。工具無法數提示；Human 需回報完整觀察、count、有限 actions，存 private human JSON：

```json
{"runUUID":"<本輪 UUID>","phase":"save-a","machineSHA256":"<runner SHA>",
 "promptCount":0,"wholeStageObserved":true,"actions":["none"]}
```

actions 僅 none／allow／deny／authenticate／other；count>0 時每提示一個 action，count=0 只准 [] 或 ["none"]。沒有自由敏感文字。未知 count 用 null、觀察不完整 false；不推定 0。

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  observe --root "$RIVET_VALIDATION_ROOT" --phase save-a --human-file "$RIVET_HUMAN_FILE"
```

未答／未知／失敗不前進依賴段。setup/rebuild 簽章提示不能混算 runtime。初輪授權或 availability 不是後續 fresh ready。固定假 A/B 的 tokenType 都是 bearer，其餘六欄比較以預期 bundle 為準；tokens／payload 從不輸出。

## 停止、恢復、公開與清理

任何可能寫過的錯誤／crash都保留 owned root／markers，不能 reset UUID 或用新 root 冒充已清。cleanup 可跳過後續測量但不能跳過 ready／所有 ownership／signed App guards。第一次 cleanup 仍用 stage cleanup；需要再恢復則用：

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  recover-cleanup --root "$RIVET_VALIDATION_ROOT" --ready-file "$RIVET_FRESH_CLEANUP_READY"
```

Recovery 使用同 service／item、獨立 private attempt UUID、一次性 ready。觀察時 `observe --phase cleanup --recovery-id <runner recoveryUUID>`；不覆蓋原 public failure／unknown 收據。必要的恢復結果由 Tester 追加 `live-validation.md`，不偷新增 repository JSON leaf。若 signature／source／ownership 不成立，保留最小恢復交接，不刪猜測項目。

export 只往 plan 精確 `evidence/live/<UUID>` 位置，allowlist 投影去除 PID／paths／group／IDs／payload／任意錯誤；Human SHA 綁的是 export 的原封 public machine bytes，不重綁或改寫：

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  export --root "$RIVET_VALIDATION_ROOT" --destination "$RIVET_EXACT_EVIDENCE_DESTINATION"
```

完成或停止才加 `--final`，exclusive 建 run-summary。未發生階段 notExecuted、未知 prompt=null；final 後不能補答重寫既有歷史，只允許最小 recovery cleanup。只有 cleanup 完整觀察通過、已 final export，才可 `cleanup-files --root ...` 清 manifest 所列 private project／DerivedData／current App：可能寫過時仍要求 exact item read-absent；可證未寫入時依下節 files-only 路徑，不冒稱 item 已刪。保留 private manifests／必要 proof，不刪父目錄或既有 Apple assets。未完整清理就如實留未知／殘留，不承諾已恢復全系統狀態。

## L03 bounded 回修：fake-only Swift operation 與 runner 整合測試

先 unsigned compile，再指定該 App 內 executable 路徑（只存私有 shell variable）：

```sh
PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY="$RIVET_UNSIGNED_PROBE_BINARY" \
  python3 -m unittest discover \
  -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v
```

沒有設定 binary 會明示 skip Swift case，不能當完整準備通過。唯一獲准 raw CLI 執行例外是 exact `--self-test-fakes`；此分支在所有 live validation／SecTask／SecItem／GUI 入口之前，只用 fake store／delete 及 TemporaryDirectory 的真 durable proof，同一個 perform／cleanup 控制流程。真人操作仍只准 LaunchServices sequential open -W。

Swift cases 覆蓋 exists／read error 零save、durable absence→attempt→save、save failure／模擬commit後控制中斷仍保留marker、proof failure零save、未owned／selector mismatch零delete、exact delete查詢／共享success與notFound分類且load=nil，以及delete／nonabsent失敗後同root recovery。模擬中斷不是實際SIGKILL／主機crash實證。

Runner tests 使用真正stage／observe／export入口與fake child，覆蓋historical UUID／PID重用與存活拒絕、不同UUID成功、ready重放、缺Human結果停依賴、machine原bytes SHA綁定、安全projection、final unknown immutable及同namespace cleanup恢復／foreign files保留。只使用一般測試TemporaryDirectory與fake context，沒有建立真人runroot或呼叫真 App／簽章工具；DR fixture 額外使用系統 csreq 純文字 requirement parser，不操作任何簽章資產或 Keychain。


## L04 bounded 回修：DR、失敗觀察及未寫入的 files-only cleanup

DR 只取 raw codesign output 中唯一 designated requirement，再以系統 csreq 文字 parser canonicalize；Executable 路徑／其他 display metadata 不入 hash。缺失、多義、語法無效或真正 DR 不同都拒絕。測試的 App/codesign/profile 全是假 fixtures，只有 csreq 對固定字串做純解析。

setup 失敗或 save-a 在 write 前被拒絕，也必須另取 **cleanup fresh ready**，執行 `stage --phase cleanup`。只有合法同run owned root／manifest／source，沒有 write-attempt marker，所有已嘗試 child 都有同run request／launch-settled／有效 receipt、已終止，且最多只有可證未save的 save-a 拒絕，才會得到 files-only 安全檢查結果。此 machine 用既有 `writeAttempted=false`／owned-root／previousTerminated 等有限欄位，不聲稱 `deleted`／`readAbsent` 或簽章有效。沒有 identity／signed host 的 setup failure不會卡在item cleanup。

Human 仍須實際觀察 cleanup、綁 machine 原bytes SHA並 observe；final export後才 `cleanup-files`。這只刪 manifest owned directories，保留 private proof／必要evidence／foreign files與所有既有Apple assets，完全不launch App或呼叫SecItemDelete。setup 的 unknown／failure歷史不因此變成功。

只要有 write-attempt、可能提交、未知／仍活child、missing receipt、來源ownership不明，就不能走files-only。未知child同樣阻擋item cleanup的新launch；保留原root／markers與恢復交接，不用新UUID掩蓋。失敗後的actual observation可在同ownedroot記錄／export，即使source變動使後續operation禁止，亦不抹掉已發生的提示；不因記錄觀察而重新放行source guard。


## 唯一 setup retry 候選（準備完成仍不等於採用）

本次只為已記錄 unknown/build 的同run提供 `retry-1`，不另建run。原formal全程0次提示已綁原machineSHA；unknown仍是unknown，原manual／formal兩份Human與machine bytes不改。原ready（包含尚未consume的manual輸入）全部不能用於retry。

候選沿immutable identity及frozen privatePBX的App-target Automatic，移除全域CODE_SIGN_STYLE／DEVELOPMENT_TEAM／PRODUCT_BUNDLE_IDENTIFIER／CODE_SIGN_IDENTITY／PROVISIONING_PROFILE_SPECIFIER／RIVET_VALIDATION_GROUP。只用現有cachedassets；無allowProvisioningUpdates／device registration／auth-key flags，缺cache或錯誤就停，不自動登入／下載／換profile／新增cert或再試。原source／exact adopted cert/profile/AppID/group/bootstrapDR／有效期／固定位置guards保留，產物全符才install。未執行cachedAutomatic真build，也不保證所有本機cache／Appleassets零變更；Human須明確接受此文件證據界線，才能進實際段落。

**外部reviewed-version權威**：執行前由Dispatcher／Tester直接將actual runner SHA256與獨立Reviewer最新approved freeze逐字核對，不符就不invoke。不是讓harness自己批准自己，也不接受任意caller SHA／環境變數當approval。Attempt只記actual執行檔SHA供稽核；這個hash本身不證明已review。完成這項外部核對、Human明確採用政策及唯一retry、取得全新setupready後，執行者才exclusive建立同ownedroot兩份0600輸入；準備期不建立它們：

- `private/setup-retry-1-policy.json`：`{"schemaVersion":1,"runUUID":"<同run UUID>","policy":"automaticCachedNoPortalUpdates","attempt":"retry-1","adopted":true}`，必須源於實際Human政策採用。
- `private/setup-retry-1-fresh-ready.json`：沿既有runUUID／phase=setup／ready=true／全新readyUUID，源於本次當段Human ready。

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  retry-setup --root "$RIVET_VALIDATION_ROOT" \
  --ready-file "$RIVET_VALIDATION_ROOT/private/setup-retry-1-fresh-ready.json" \
  --policy-adoption-file "$RIVET_VALIDATION_ROOT/private/setup-retry-1-policy.json"
```

Preflight驗原machine／完整Human SHA與frozen run／identity／PBX／profile、無後續操作或可能寫入，再exclusive mkdir0700 `private/setup-retry-1`。Directory或attempt任一存在就永遠耗用唯一額度，含mkdir後attempt前中斷；不刪除以重試、不fallback initial、不進save-a。整套retry build/inspection/ready/machine/Human/proof只寫該storage；不重新bootstrap／freeze identity。錯誤仍提供unknown publicmachineSHA供當次Human觀察；真正中斷未產收據時summary保持retryunknown／effective=null，留下最小恢復交接。

Retry結束後另取actual count/actions/whole觀察，Human JSON仍phase=setup並綁retry machine原bytes SHA：

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py \
  observe --root "$RIVET_VALIDATION_ROOT" --phase setup \
  --setup-attempt retry-1 --human-file "$RIVET_RETRY_HUMAN_FILE"
```

無selector仍指原setup；selector不能用在其他phase或cleanup recovery。存在retry後，只在retry全部guards／有效buildproof及Human完整觀察成功時解鎖save-a，runtime／rebuild採retry baseline，絕不讀原缺失的setup buildproof或借initial成功。Unknown／missing／partial均停止。

Export新增且僅新增 `setup-retry-1.machine.json`／`setup-retry-1.human.json`（v1／phase=setup）；原setup兩leaf原SHA永留。未建立的run-summary改v2，固定setupAttempts.initial/retry-1與effectiveSetupAttempt，directory-only為retryunknown、effective=null；保守top-level status保留原unknown歷史，即使有效retry與後續成功也不能抹去初次失敗。Final summary仍exclusive，不能重寫。Cleanup／no-write shortcut／unknownchild／recovery全部沿原strict契約，不新增產品delete或擴張Appleassets清理。

新增測試走實際retry／stage／observe／export與CLI dispatch，build/sign/inspect以fixtures替代；另實際中斷retry在mkdir後、attempt前，確認額度與unknown不fallback。這些是工具控制實證，不是cachedAutomatic／簽章／DPK或prompt通過。


## D02：可信bootstrap與獨立有限診斷（僅準備完成）

原run、current binary、manifest／identity／pins及setup/save-a所有machine/Human全唯讀保留；原save-a unknown與全程0次提示不改，未找到歷史精確guard。Developer Tools disabled／無public open waiting-debugger flag路徑維持停止；不改權限。新copy/context結果不能當成原Writer重現或修復。

兩用途只有diagnostic-only與namespace-read-only。Trusted operator在未來D05新host build/sign實際採用／freshready與獨立證據完成後，才可在別的0700 owned scratch `rivet-credential-storage-diagnostic-<UUID>`放固定 `diagnostic.json`、`app/CredentialStorageProbe.app`及四份新source副本；不是新的credential run，不換舊current。Manifest精確schema、legacy hashes及source freeze依technical-spec §5.2，runner／host都核同SHA、ownercanonicalpath／無symlink、fixedApp／binary／四source位置。不得在本準備階段建立真人scratch／manifest／ready或執行以下未來操作。

Host由私有環境RIVET_DIAGNOSTIC_MANIFEST／RIVET_DIAGNOSTIC_SHA256先驗可信bootstrap，才取得固定exclusive0600 output，之後才解析待診斷argv／舊request及早期guards。Bootstrap失敗零落檔；較後args/request/root/source/identity/bundle/entitlement失敗寫有限stage/status/failureKind，沒有rawerror／argv／path／IDs／secret。診斷copy使用其新預期安裝位置與freeze，另外只讀核原fixedApp；不改原安裝契約。diagnostic-only到completed即終止，不建store、不呼叫SecItem或原perform。namespace-read-only另需當次Humanready，才以原UUIDservice/group/credential/clientID最多一次public adapter load；不save/delete。Absent只證現在空，present/error即停；兩用途均不能補原absence/attempt或解除unknownchild／cleanup。

未來D06與D07各別的固定ready格式：`{"diagnosticUUID":"<新診斷UUIDv4>","purpose":"diagnostic-only","ready":true,"readyUUID":"<本段新UUIDv4>"}`；readonly purpose改namespace-read-only。檔名分別diagnostic.ready.json／namespace.ready.json。所有guard通過後、open-W之前exclusive+fsync寫同purpose consumed-ready.json；任何existing／partial／失敗均永久耗用該purpose本次額度，不刪以重試。工具使用exact App的open-W、兩個bootstrap --env與原只讀request args；沒有open-n／rawGUIlaunch。

未來CLI為 `diagnostic-stage --manifest <固定diagnostic.json> --manifest-sha <外部核對hash> --ready-file <固定purpose.ready.json>`；外部Dispatcher/Tester先核新source/binary/signing為獨立Reviewer接受的D05版本並收本段Humanready，工具不自批簽章或approval。Host有效收據後回exact machine bytes SHA，Human另存diagnosticUUID/purpose/machineSHA256/promptCount/wholeStageObserved/actions，再由 `diagnostic-observe --manifest ... --manifest-sha ... --human-file <同owned scratch私有輸入>`exclusive寫固定purpose.human.json。未答／觀察不足unknown，不前進。

若launch失敗或沒有hostreceipt，runner只回有限unknown、保留consumed marker，絕不製造Appreceipt或重用ready；沒有machine bytes可綁時，Tester只在既有live-validation.md如實記當次Human實際觀察與無receipt限制，不捏造Human SHA sidecar。公開只由Tester追加該既有md的有限摘要，不新repoJSON／改舊summary。任何securitypermission、新assets或無安全恢復條件即停，原root/Appleassets不清理。

準備驗證必用修改後同一main的新unsigned fake-only binary，不沿用舊12case binary。普通compile scratch可使用既有自身編譯輸出的GitHubIntegration／RivetHTTPClient／Apollo／ApolloAPI modules/objects，以swiftc編譯main；不xcodebuild、sign、package更新或AppRun。缺依賴即報blocker。新binary只准exact --self-test-diagnostics及--self-test-fakes；前者caseIDs必含bootstrap／schema／UUID／path／symlink／exclusive、早期args/request/root/source/identity/Bundle/entitlement、diagnostic-zero-load、readonly nil/present及finiteerrors，後者保留舊12operationchecks。Python套件同時設定RIVET_DIAGNOSTIC_PROBE_BINARY與RIVET_FAKE_PROBE_BINARY為這個新binary，核source/binaryhash，未設定會skip而不得稱完整準備通過。

本validation檔案因固定單一host邊界與實際共用fake驗證，僅局部豁免file_length；其他SwiftLint與swift-format規則保留，交獨立Reviewer評估。這不是一般production檔案policy變更。


## LG：launcher紀錄缺口（候選準備，未授新App啟動）

D05建置/Human0與D06unknown/Human0歷史保留；D06額度已消耗，不能重跑上面的diagnostic-stage或改其marker。此補修只改runner/tests/README，不改host、signed App、舊manifest/source snapshots、原run或DPK。外部Dispatcher/Tester須先直接核獨立Reviewer最新approved的實際runner SHA；工具只記actual SHA，不自核approval。

未來另獲具體單段Human freshready才可使用以下已實作入口；現在不建立真人ready/attempt或執行：

```text
python3 <own-feature-runner> launcher-amendment
  --manifest <同N/diagnostic.json> --manifest-sha <原完整manifestSHA>
  --ready-uuid <本段新UUIDv4> --ready-confirmed
```

只沿同N新增唯一diagnostic-launch-amendment-1目錄，固定attempt.json、ready.json、consumed-ready.json、launch.stdout、launch.stderr、launcher.machine.json、launcher.human.json、caller-result.json原八leaves，另固定launcher.machine.pending.json、caller-result.pending.json兩個publication pending（合計十個）。目錄或partial存在即耗額，不重試/刪除/新namespace。啟動前須原pins與D05真觀察吻合，當次完整ownUID/exacthost與selected-open既有argv快照無match；無法查核即拒絕，不從ready或單獨無PID推settlement。legacyWorkerSettled欄位僅表示此當次known-open-absent，並非歷史退出/無寫。

Native命令只有open -W -a同App、兩個固定diagnostic --env及--args --launcher-amendment-only。該單一invalid sentinel讓凍結Swift的diagnostic/legacy兩分支均在args guard停止；env遺失也不讀原save-a request或建store。沒有-n/raw App/DPK。Popen.wait最多30秒，不自動kill/terminate；timeout/wait-error保留nativePID與unknown，禁止依賴前進。

launcher.machine是獨立native觀察，不是Appreceipt。它如實記rc/signal/finite exception/timeout及Appreceipt存在/validity；primary寫入或fsync失敗保留partial並嘗試唯一caller-result fallback，兩者都不可寫則只有有限stdout與非零CLI，不能保證磁碟故障仍能留檔。raw logs/argv/PID只private，勿上傳；公開只有既有role evidence的有限摘要。CLI一直unknown/nonzero：一般exit1，任何結果持久失敗exit2。Host沒有attempt nonce，valid新receipt也可能D06遲到；hostConfirmed與appReceiptAttributable固定false，native0不代表host pass。

Human對本段實答後，以真正primary或fallback原bytesSHA觀察（未答不invoke；沒有持久receipt只在原live-validation敘述）：

```text
python3 <own-feature-runner> launcher-amendment-observe
  --manifest <同N/diagnostic.json> --manifest-sha <同SHA>
  --binding-receipt-sha <真原bytesSHA> --prompt-count <非負int或unknown>
  --actions <none或有限action逗號序列> --whole-observed <yes或no>
```

Human leaf exclusive且只綁實際原bytes，不能重用D05/D06的0次。記錄Human不升級hostconfirmed、不解鎖D07/DPK/cleanup。LG-T01–06使用普通temp及實際有限fake child；既有63 regression沿同source的unsigned fake-only binary，不重編Swift，不執行signedhost或open。完整有限schema與Human停點以spec/plan§5.3為準。

RF-LG04-01 publication：只對launcher.machine/caller-result採專用writer，exclusive0600寫固定pending，file fsync與D directory fsync全成功後，最後一步atomic link發布final（不覆寫），pending保留；link後沒有其他fallible read/fsync/cleanup來撤回已發布SHA。沒有跨斷電final目錄entry存活保證。observe只接受final/pending安全同inode/完整bytes/schema/context吻合的published pair；完整pending永不binding。primary發布而caller失敗仍可綁primary；primary失敗而caller發布可綁caller；兩者僅pending必null/noHuman，兩final交叉SHA/選擇矛盾拒絕。原全域writer、其他stage及舊資料不改；錯誤bytes不重寫／清除。CLI寫失敗仍exit2，publication僅launcher觀察，不是hostConfirmed或DPK成功。


### 未來單段純launch的確定輸入（本輪不執行）

沒有待補builder/caller或snapshot輸入檔；snapshot由現有launcher-amendment在spawn前自動取得並核對，無法驗證即停止。trusted operator依序：

1. 在本topic feature worktree使用本檔同目錄scripts/credential_storage_live.py，以actualSHA對獨立Reviewer最新approved freeze；不把工具自算SHA當approval。從既有D05私有caller scratch `rivet-D05-caller-vhxwk2v2/execution.json`安全唯讀取context（不是要求Human貼ID/path）：先核scratch自身UID/0700、全祖先canonical/nosymlink、execution regular/0600；repo須同本feature，callerSHA256須原已採31dd8f62a1ecd2720b78a530350699d0ba296b6560bbb18f9ebfc078bd2f09f2。以其diagnosticRoot欄位接固定diagnostic.json為LG_MANIFEST，不能任選新root；本topic runner為LG_RUNNER。這只準備既有metadata來源，不建立任何新inputs。不可將新runner複製到N/source或改舊manifest/pins。
2. Human另採具體「同N唯一sentinel純launch、無DPK」scope並freshready後，才在記憶體產生新lowercase UUIDv4作LG_READY_UUID。確認本次實答才使用--ready-confirmed；不重用D05/D06 UUID或預建ready檔。唯一執行命令：

```sh
python3 "$LG_RUNNER" launcher-amendment --manifest "$LG_MANIFEST" --manifest-sha 15e4e4fbcc09524cbabdca03b24f98e136f77f7c4ee99ea8351ee6cce06cd02e --ready-uuid "$LG_READY_UUID" --ready-confirmed
```

CLI自行驗完整舊pins/D05 Human、D06原marker/logs與fixed receipt absent、ownUID/current exacthost及known-open argv snapshot，然後才exclusive D/ready/consume及spawn；無需Human準備process資料或後寫私有程式。任何preflight/permission/timeout/不明結果即停，不用同ready反覆試、不kill、不回舊diagnostic-stage。新App/security/資產需求不在此scope。

3. 將此真CLI有限結果和原bytes bindingSHA交Tester；actual提示count/actions/whole由Human事後實答。LG_BINDING_SHA只取CLI實際非null值，null則不呼叫observe，僅既有live-validation記觀察／無可綁收據限制。LG_ACTUAL_COUNT、LG_ACTIONS、LG_WHOLE只取實答有限值（unknown count不猜0、whole僅yes/no）；使用前述launcher-amendment-observe完整argv記錄，不執行其他phase。即使Human全程0次且有published launcher證據，hostConfirmed仍false/unknown，原D06不改、D07/DPK/清理仍停。


### LG10：pre-trusted-D有限guard診斷（候選準備）

同一launcher-amendment命令／輸入／snapshot guards不變。只有trusted D之前失敗的原五key stdout增加guardPoint、apiOutcome、apiReturn、errnoKind；trusted-D後結果、publication/Human/observe schema與其他CLI不加欄位。guardPoint為context/ready/quota/request、snapshot各setup/list/path/args/decode/match、caller-source/output等固定enum，不含PID/path/argv。apiOutcome只notCalled/returned/exception/guard，apiReturn只notAvailable/negative/zero/positive；原生return即時觀測，不新增query或retry。

每次call局部記錄，ctypes use_errno=True、native前清thread-local errno、返回後立即取值；原生失敗但errno不可取得或0必unknown，不猜permission。errnoKind僅none/notFound/permissionDenied/interrupted/unsupported/other/unknown；純require拒絕才none，原生已知errno按spec固定映射。未知exception也只有限拒絕，不印raw error/traceback/環境或argv。舊LG06真stdout SHA b3d71cb085489be348cd23a361040f247b5b2bbc139b8ae8dd9bbf497885db66與Human全程0不回填新字段；這些字段只能說明未來本次guard，不能證歷史worker退出、host/DPK或無寫。

三葉新freeze須獨立Tester/Reviewer後才可能再交Human審具體新段落freshready。這不是重跑LG06／snapshot的許可；不新增flag/privateleaf/namespace/caller或改host，舊ready不能重用。本輪測試只fake ctypes/native結果及普通temp/fake child，沒有真libproc/sysctl/App查詢。


### LG16：正向名稱預篩（non-live候選；真launch仍停）

同一未來CLI在ownUID PID列舉後先單次proc_name：32-byte buffer、return/NUL/strict UTF-8全部可信才分類。只由原固定兩host executable basename及open導出完整／31/15-byte別名與prefix；名稱是排除預篩，不是identity。可信且對全部目標不相容者略過該PID path/args，15或31-byte長度不單獨觸發candidate；compatible prefix／case／encoding／alias歧義仍完整path，只有exact open才讀原argv。name API零／未知／格式失敗仍停止，candidate path的ESRCH/ENOENT照舊拒絕。只加snapshot-name有限guardPoint，沒有新key/flag/privateleaf/caller或snapshot重試。hostConfirmed仍false，LG13與舊unknown不回填。

新增actual CLI/fake ctypes驗證已含無關短名／disjoint 15/31零path/args，known/prefix/alias／非ASCII候選仍path、name零與errno／NUL／編碼／長度未知拒絕，以及public敏感資料不外洩；其餘原99 regression保持。全UID snapshot只有fake provider；本輪未執行真launcher/App或全UID程序查詢。

LG-N07受限可行性觀察：以未修改sys.executable建立普通與偽裝argv0的兩個自有finite-sleep child，只對直接取得PID讀name/path/bounded argv，未列舉其他PID，兩者均正常啟動及自然退出。name有效並可排除固定host/open；但回報path與sys.executable realpath不同，kernel argv0亦不等caller傳入值，故未完成預期的完整path/argv0對照，不能宣稱N07通過或實際launcher可用。原因未查證，不調環境、不copy/sign平台binary或追加probe；交獨立Tester/Reviewer判讀此限制。未來仍先外部核新runner approved freeze，再具體同CLI＋Human freshready；本結果不授新invoke。


### LG22 現行：fullinfo／status／instance（真人／DPK暫停）

取代LG16 proc_name wrapper：公開SDK PROC_PIDTBSDINFO,arg1讀完整proc_bsdinfo，核exact size、PID/UID/status/starttime與有界name/comm。可信zombie正向排除，不推歷史無寫；live noncandidate依原名字規則排除，candidate做兩次完整path／exact-open argv分類，再以A/B instance、status及name/comm一致性核對。觀測到真host/open、metadata未知、permission、reaped、格式錯或任何變動仍停止；沒有errno-only skip、UID membership重讀或exactPID fallback。PID+starttime不是不可偽造token，不保證中間exec/ABA／查核後變化或原子snapshot。

只有launcher-amendment stdout增加有限八欄processEvidence，保留正向zombie/noncandidate、instance與真衝突aggregate；published machine/caller/Human及atomicpublication、sentinel保持。其餘CLI不加欄位。原CLI及輸入仍相同，但真人全停，不能沿用任何ready或重跑LG19；新freeze仍須獨立Tester/Reviewer。Host缺nonce，hostConfirmed仍false。

Non-live：114/114零skip（原104＋10必要case），AST/Ruff通過。SDK header C static_assert核size/alignment/全部offset，僅clang -fsyntax-only，未建立App／簽章或新native binary。單一未修改未複製/bin/sleep child的直接own PID實際觀察running→zombie→reaped：arg1取得zombie、arg0失敗、reaped仍guard，finally自然wait回收，無kill或其他PID／全UID查詢。這驗證所選原語的受限行為，不證LG19根因或真人launcher可用；先前Python mismatch／copied sleep -9未知史保持。


### LG28 現行：path返回失敗的單次後查（真人／DPK仍停）

僅candidate第一／第二proc_pidpath native返回≤0時，以同PID arg1 fullinfo後查一次；不重試path、不讀額外argv或UID列表。原path四欄與即時有限errno另存，不受post的獨立observer覆蓋。只有同PID/UID/starttime的可信zombie可排除；liveSame、identity/classification改變、denied、unavailable/invalid/unknown仍停止，查不到不稱reaped。API exception／其他guard不進此新branch。名字預篩與既有aggregate意義保持。

launcher-amendment stdout新增固定五key pathFailureEvidence：pass、postState、nameMatchKind、pathErrno、pathFailure（原四欄副本）。無event輸出spec defaults；有event綁最近一次實際失敗iteration，first/second由caller提供，name類別依A實際name/comm來源。pathErrno僅實得ENOENT/ESRCH/EPERM/EACCES/zero/other/unknown，不從notFound推定。舊aggregate true不代表本失敗PID已核；nested原path與後續外層guard可分別保留，不公開PID/name/path/argv/error。Published machine/caller/Human及publication不改，無新CLI flag或私有leaf。

Non-live 122/122、零skip，AST/Ruff通過；first/second各post狀態／原errno／來源name分類／defaults-reset／敏感資料與跨PID歸屬皆走actual CLI fake providers。SDK與單known-child既有case只隨正常完整入口執行，未額外probe。原LG25 unknown及Human0 wholetrue保持，不宣稱已知歷史根因、真人可用或hostconfirmed；真人/DPK/cleanup仍停，新freeze待獨立Tester/Reviewer，不重用舊ready。

## LG33：離線 launch-report binding 候選

這是驗證工具的獨立 `launch-report-only` 路徑，不使用 credential store、provider、SecItem 或 entitlement 查詢。Host 接到 `--launch-binding-only` 或任一 `RIVET_LAUNCH_REPORT_REQUEST{,_SHA256}` key，先選入本路徑再驗 argv/input；即使環境遺失也不能回落保存流程。舊入口及歷史收據保留。

本輪只在普通 owned fake scratch 驗證協定，沒有建立正式 diagnostic context。新 Swift 共用 fake 入口為 `--self-test-launch-binding`；與原 `--self-test-fakes`、`--self-test-diagnostics` 相同，只供新編譯的 unsigned CLI 執行，絕不用 raw CLI 執行真人診斷模式。Python tests 的 `RIVET_LAUNCH_BINDING_PROBE_BINARY`、`RIVET_FAKE_PROBE_BINARY`、`RIVET_DIAGNOSTIC_PROBE_BINARY` 均指向此次新 main source 編譯的同一 fake binary；fixture 成功不能當作 signed-host／環境真傳遞／提示 UX 證據。

未來操作候選（本段不是執行授權）：先獨立審查並取得 Human 對新 context 與 signed build 的授權，核已有 profile/certificate 的適用性、有效期與 exact identity，不假設舊免費 profile 仍可用。需要新資產、trust/security 或付費就停。完成 exact build/source/location/signature 驗證並取得最終產物 binary SHA 後，才可建立正式 context；由外部 trusted operator 凍結以下 private 輸入，不能靠 hash 自核 approval：

- `R/context.json`：schemaVersion=1、purpose=launch-report-only、contextUUID、九個固定 validation relative leaves 的 sourceHashes、expectedBinarySHA256、buildProofSHA256、signingProofSHA256。
- `R/source/` 九葉 snapshot；`R/app/CredentialStorageProbe.app` 固定 App；`R/build.machine.json`、`R/signing.machine.json` 是外部已審的 build/signature 原 bytes，hash 與 context 相符。Launcher 對 bytes/hash/位置獨立核對；其內容的 signed-host 來源、身分與有效期仍由操作階段核實，runner 不以 opaque proof 自證簽章。
- R owned0700、metadata regular0600、全祖先 canonical/no symlink。這是新 operational freeze，不修改／恢復／重建舊 N 或原 run，舊額度及 unknown 歷史不變。

只有上述操作階段完成、外部核 actual runner SHA 等於獨立 Reviewer approved freeze，且另取得當段 fresh Human ready，才可呼叫唯一一次：

```sh
python3 validation/github-oauth-credential-persistence/scripts/credential_storage_live.py binding-launch \
  --context "$R/context.json" --context-sha "$CONTEXT_SHA256" \
  --attempt-uuid "$ATTEMPT_UUID" --ready-uuid "$READY_UUID" --ready-confirmed
```

`--ready-confirmed` 由 trusted operator 依實際當段回覆提供，不能由「目前可配合」推定；本輪沒有生成這些實際輸入。`binding-consumed.json` 或 `attempt/` 任何存在（包括 partial）就耗額，不重用、不重試、不刪除。Host/launcher request、report、ACK、final、machine exact schemas 見 technical-spec LG31。各輸出以固定 pending fsync＋directory fsync 後 no-clobber atomic link 發布，同 inode/bytes 才可消費；完整 pending 不等於發布，最後 link 之後不再以 fallible I/O 撤回 SHA，亦不宣稱跨斷電保證。

Launcher 並行等 report，以 ownUID、reported PID 的兩次獨立 kernel start/path 讀取、freshness 窗口和 frozen binary bytes 驗證，再給 ACK；Host 回傳實讀 ACK 的 final，native worker 再 settle。全段 monotonic 上限30秒，不自動 relaunch/kill。Native0、UUID／nonce、新 processUUID 單獨都不是歸屬或 freshness 證明；PID reuse、missing／mismatch／timeout／寫入失敗均不成功。`fake-only` 永遠 `hostAttributed=false`，即使其餘 protocol flags 通過。原 native rc/signal/有限 exception 保留 private machine，公開只有限投影與 bytes SHA，不含 PID／路徑／私 ID／raw error。

這是 trusted-operator／正常本機時鐘前提下的有界交叉觀測，不抵抗同 UID 惡意偽造，也不保證 exec／ABA／postcheck 無競態。未來另審 signed build/readonly signature proof，再另 freshready 單次 purelaunch；host attribution 尚未成立前 DPK 繼續停止。本輪不執行新 context、App、簽章、全 UID scan、DPK 或舊 root 清理。

RF-LG34-01：caller 與 host 在各自 invocation 保存上一個實際 wall-clock 觀測，後續值必須不小於前值（等值可接受）。即使回退後仍高於 request createdAt 也拒絕，不再發布後續 ACK／host.final 或成功；monotonic 30秒上限及已記 native 原值保持。這只用 fake clock 驗證，不修改 OS clock。

## LG38：已採用 profile-free 診斷 variant（2026-11-04）

同一 target 的 `LAUNCH_REPORT_ONLY` 編譯版本只有 LaunchReport 頂層入口；原 fake/legacy argv、legacy/unknown RIVET env、缺失或未知組合皆在讀 credential request／store/provider/SecTask/SecItem 前拒絕。Default compile 保留原入口與 fake regression。正常 binding request 仍必須為 `launch-report-only`；兩個 exact build/sign proof 必須 purpose/variant/mode/source/binary 互綁，live 只接受 signed-host。完整 schema 依 technical-spec LG36，不能沿用舊 opaque/DPK proof。這個 variant 不驗 DPK，empty claim 不改原 registered AppID、BID、CodeIdentifier 或原 certificate Team。

新 runner 在 ACK 前除了原兩次 kernel PID/start/path/binary/time 核對，還驗 **exact reported PID** 的 dynamic code signature／original DER／Team／CodeIdentifier／DR；metadata/binary 與 dynamic code 必須互符。Static preflight 亦驗 frozen source 的 BID、實際 App Info、profile absence、空 entitlements 與原 DER/type/日期/Team。所有 verifier command stdout/stderr 只在 private memory，公開仍沿原 finite schema。Unknown/native failure/deadline不通過，沒有新 retry/kill App 或 security bypass。Verifier短命令本身有 timeout；這不代表 App 或原 worker 已退出。

LG38 已準備的是普通 unsigned **CLI fixtures**，不是可供真人簽署的 `.app`。兩 binary 同 final main source：default 供 `--self-test-*` 純 fake，variant 只供 invalid/env-loss hard-fence CLI 拒絕測試。`RIVET_PROFILE_FREE_PROBE_BINARY` 指 variant；其餘三個 fake-binary環境變數指 default。兩者都不是 signed-host／OSlaunch實證。原146/LG35歷史保留，新受影響範圍另跑 targeted tests；不以舊146認證新variant。

後續LG41 preparer負責實際 unsigned App 與完整操作caller，供獨立審閱後才集中Human窗口，不能要求Human找Team／BID／selector等私有欄位：

1. 先用本topic own package／locked cache準備 private project copy與unsigned App；build argv依spec LG36的Manual、CODE_SIGNING_ALLOWED=NO、CODE_SIGNING_REQUIRED=NO、空CODE_SIGN_ENTITLEMENTS、CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO、DEBUG LAUNCH_REPORT_ONLY。不改五模板／原BID，不帶任何provisioning/device/account flags。若需還原既有lockfile指定公開依賴，只取locked內容，不升級或改lockfile；Apple帳號／profile／SDK／cert取得仍不在routine範圍。
2. Agent由已凍結 PBX 的 PRODUCT_BUNDLE_IDENTIFIER及產物Info取得expected BID/CodeIdentifier；原Team由精確原DER的OU解析，不用CN／member ID猜Team。先核新App來源、owned/canonical位置、無embedded profile／restricted claims／未知nested code；不修改舊App／profile或quarantine。此階段尚不建立新operational context。
3. 以下既有runner helper是**最後已授權Human窗口**的可審接線，現在未執行。`binding_original_certificate(exact_login_keychain)`只向明確既有login keychain查Apple Development公開certificates，在記憶體按原DER SHA256唯一選取，無匹配即停；不查私鑰或其他keychain，不新cert／import/exportkey／trust。此publiccert query仍可能要求auth，因此不提前呼叫。
4. `binding_sign_preparation(original_der, exact_login_keychain, fresh_app, expected_identifier)`先核原DER SHA256、Apple Development OIDs／Code Signing用途／有效期、Team與App Info，再從**同DER**算SHA1，返回private argv。它不執行簽章。固定sign argv為 `/usr/bin/codesign --force --sign <derivedSHA1> --keychain <exactExistingLoginKeychain> --options runtime --identifier <unchangedCodeIdentifier> <freshOwnedApp>`；不帶entitlements、不deep sign、不preserve舊權利。SHA256 pin永遠不是codesign selector。
5. 原key當次授權後才由受審caller執行該argv；可沿 `binding_code_command(sign_argv, bounded_timeout)` private capture，不能print返回private結構或raw error。沒有當次授權選項、取消／denied、缺原identity或需要Always Allow/ACL/partitionlist/trust/newcert就停，不repair。Postverify用 `binding_code_identity(fresh_app)`，再驗Info BID／profile absence／binary，與prepared原certificateSHA256、Team/BID/CodeIdentifier hashes比較，凍結DR/final binary及sign proof。不能預寫成功proof。
6. Build/sign proof及final signed binary確認後，另授新R/context／source snapshots與一次quota，保持原context/歷史不動；最後只一次freshready既有 `binding-launch --context --context-sha --attempt-uuid --ready-uuid --ready-confirmed`，由Human記實際提示/全程觀察。正常OS拒絕就停，不用spctl放寬／xattr移除／trust變更。

Helper只供上述受審caller引用；沒有新增能自動查Keychain／簽章的CLI subcommand，`binding-launch`不呼叫certificate-acquisition或sign-preparation helper。必要public DER查詢、原key使用與LS launch集中最後授權窗口；LG38沒有執行它們，profile取得也不是此候選前提。


## LG46：獨立certificate欄位解析與有限準備證據

LG43仍是unknown/sign-preparation/guard、Human全程0；沒有原decoder輸出，這次修補不回填歷史根因。`binding_certificate_text(der, part, evidence=...)`現在只按固定三種part讀同一已pin DER：subject用`x509 -inform DER -noout -subject -nameopt RFC2253`，dates用`-noout -dates`，class用`-noout -text -nameopt RFC2253`。各10秒有界，stdin／固定C locale與無自訂openssl配置；不查Keychain、不簽章或做trust/network操作。

`binding_certificate_team`只解析獨立subject記錄，RFC2253 escaped comma/plus/hex不形成額外attribute；多OU（含相同值）、重複subject／額外行／非法escape／多值RDN拒絕。完整text中的issuer/subject OU不作Team來源，日期／Code Signing EKU及兩原OID檢查仍各自必要。原static/dynamic postverify也共用這份解析，保留原DER pin／Team/code identity／deadline等標準。

受審caller接線為`evidence = binding_preparation_evidence()`後呼叫`binding_sign_preparation(der, exact_keychain, owned_app, expected_code_identifier, evidence=evidence)`。成功回傳prepared及其preparation快照；拒絕時mutable evidence仍保留實際guardPoint、decoderPart/outcome/returncode、OU count和四項nullable檢查bool，exact欄位依spec LG44 SP02。它不執行回傳signCommand。原nonzero/signal以CalledProcessError保留實際returncode/stdout/stderr，timeout/OSError保留原exception；僅private capture，公開不可print原exception或prepared私有argv，應只投影有限preparation及既有status/hash。未檢查不得推true或補猜原因。

本輪沒有改main／五模板或重建App；新工具三葉freeze與原App/build九source provenance分開。LG49須依spec SP03 exact leaves在同prep root製作唯一amendment-1 caller/config/controller及NoAppdry proof，引用LG43原operation/caller/config/consumed hashes與原buildproof；原bytes/ready/額度不改。外部Reviewer核新caller/config/controller及現repo三葉SHA，原private九source／main及模板仍核原buildfreeze；不得改原sourceHashes假重建。

LG49實際caller的必要phase fixture：sign前副本與原件均核原unsigned tree；fake sign確實改副本binary/tree，再以新signedproof/hash核context/launch，**不可每個phase要求已簽副本仍等於unsigned tree**，原unsigned原件則始終不變。父unknown及子pending/consumed都不能變成重試理由；任何partial耗唯一amendment額度。新成功operation與新signproof才可供後續context producer引用，不能fallback到LG43。這些私有producer留LG49實作／LG50獨立審閱；本輪未建立新caller/config/ready、未query/sign/context/launch。新sign仍需最後集中Human原key當次auth＋freshready及實際觀察；舊兩ready已結束，不carry，DPK/cleanup仍停。

RF-LG47-01：shared static/dynamic postverify在原DER extraction／SHA pin後，三個decoder的實際subprocess皆以同一記憶體DER bytes作`input`，不附`-in`、不重讀certificate檔，也不沿一般command adapter的DEVNULL。固定argv、C locale／OPENSSL_CONF、每call最多10秒與原總deadline保持；rc/signal／timeout／原native exception仍由共同decoder如實保留。底層subprocess fake回歸穿過實際shared wrapper，並驗錯bytes／型別／argv拒絕；不是只檢上層options。這不改LG43 unknown或原App/build。


## LG54：LG51 report-timeout 的離線修補

原LG51 sign/context success與launch unknown、全窗口0次權限申請保持。原compiled Swift使用`URL.path == standardizedFileURL.path`作root條件；在本機Foundation會把`/private`別名標準化，與Python realpath固定路徑不同。保留原raw request/context/proof/source bytes、同URL組裝、真FS與歷史clock的非live replay，於原source line714可決定性重現拒絕；這是固定guard缺口，**不聲稱歷史App首先拒絕於此**（當時argv/env未觀察）。

只LaunchReport改用POSIX realpath相等、逐層lstat no-symlink/owner、root0700/file0600及原size/no-follow條件，接受物理canonical路徑而不放寬symlink或非owned資料；legacy DiagnosticProbe不變。真FS mode/symlink/nonowner負例、真Foundation NSNumber非bool整數與fraction拒絕、ordinary unsigned CLI僅getpid自身SDK metadata均有實際共用入口。新default CLI可跑`--self-test-launch-startup`；LAUNCH_REPORT_ONLY variant仍不允許任何fake入口/legacy/unknown組合，不到store/provider/SecTask/SecItem。

新實際wire：五argv恰`--launch-binding-only --request <request.json> --request-sha <SHA>`，並帶原兩env。完整argv優先，完整env僅診斷fallback；兩channel缺失/partial/不一致或未知RIVET env都不能成功。可信request/output bootstrap才發布同B的`host.entry`，後續guard失敗可發布有限`host.failure`；exact schema／nullable／publication依spec LG52。無可信pair只finite stderr，不亂寫；entry/failure只診斷，從不代host attribution或nonce authentication。完整context/proof/source/selfbinary/兩次liveinstance/dynamic/clock/ACK/final條件保持。

Open仍是-W/-a單一fixedApp、不-n；現在明確`--stdout <attempt/app.stdout> --stderr <attempt/app.stderr>`及上述args，原launch.stdout/stderr仍只native open。Caller每個wait迭代與timeout/finally nonblocking poll原Popen，已知rc/signal/settled即保留，缺report仍unknown，不kill或重試。App streams只≤65536的有界snapshot/hash，oversize只size；不公開raw SDK/error/私ID，不以snapshot宣稱App已退出或output已final。

受影響non-live selectors：LaunchStartupControls、LaunchBindingControls、SwiftLaunchStartupControls、SwiftLaunchBindingOperations、SwiftProfileFreeVariant。沿既有`RIVET_LAUNCH_BINDING_PROBE_BINARY`指final default unsigned CLI、`RIVET_PROFILE_FREE_PROBE_BINARY`指final variant。由agent設定`RIVET_CAPTURED_REPLAY_SOURCE`到原LG51只讀context；Python測試先核原requestSHA297a4d…dfa6，再copy原bytes/App/source到普通owned `rivet-lg54-replay-*` fixture，Swift真核心/FS以歷史clock及fake executable/instance/ACK sink執行，只寫fixture。它不是新正式context或signed-host實證；native-self testcase則真查自身，不拿fake identity替代。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest \
  test_live_protocol.LaunchStartupControls test_live_protocol.LaunchBindingControls \
  test_live_protocol.SwiftLaunchStartupControls test_live_protocol.SwiftLaunchBindingOperations \
  test_live_protocol.SwiftProfileFreeVariant
```

工作目錄validation/Tests，三個私有fixture輸入由agent從交接定位設定，不讓Human排障。原frozen source replay紅證據與新final main雙unsignedCLI/commands/hash均保留普通scratch。LG54只離線code/tests；main已變更，LG57必須準備新unsignedApp、新build/proof/source9及完整actualcaller/config，再LG58獨立審閱。只能用同prep root明確LG51-report-timeout-amendment-1，保全部LG51 bytes/spent/old App；不偷偷重用原signedartifact當新host，不現在建立新context/ready。既有signedApp公開DER的已pin0600副本可供agent備class/date/Team及SHA1，不需先查Keychain或叫Human找資料。真正原key當次sign/auth與單次LS觀察仍最後新Human窗口；不new/revoke cert/profile/trustACL/TeamBID/security/paid/DPK/cleanup。

## LG65 DPK 專用接線（未授真人操作）

`DPK_VALIDATION_ONLY` 與 `LAUNCH_REPORT_ONLY` 互斥；原 report-only 仍不接受 profile、不呼叫 store。DPK purpose 為 `dpk-credential-validation`，只從同 request/context/round 的 report→獨立 liveinstance/binary 核對→ACK→正式 facade operation→含六欄布林結果的 final 前進，不另跑 legacy Probe。初次 save 必 nil→durable absence→durable write-attempt；失敗保留 ownership，不 retry/delete。

只在受審 actual caller／profile／source／signature freeze 及 Human decision/freshready 全齊後執行 `dpk-stage --root ... --phase save-a|read-a|replace-b|read-b|rebuilt-read-b --ready-file ...`；`dpk-observe --root ... --phase ... --human-file ...` 綁當段 machine SHA。Stage 必須核前段完整觀察與 exact previous kernel instance 已退出；PID/UUID 不同或缺 marker 不能代替。Rebuilt 使用新 context/proofs，App 固定位置、同 identity/profile/claims/DR/source、真 binary/marker 改變。

`dpk-prepare --repo ... --parent ... --profile ...` 只在普通 owned preparation scratch 產兩組 unsigned App 與 inputs，無 context／簽章／App launch／DPK。原公 DER 到原 key 的 manual-sign、profile/claims 檢查及 context producer 仍須以 LG70 實際 caller/config/OPERATIONS 交 LG71 審查，不能只憑這些 CLI 文案啟動真人。No Auto/provisioning flags/new certificate/profile update/cleanup/reset/-n/kill/Git。

所有入口固定截止 `2026-11-04T10:06:29Z`，含 Human 等待；build/sign/runtime 分別需540/210/60秒 start reserve，不足不啟動。截止後只 settle/保存既發生事實，不開下一段。首次 save≤1、fresh A/B/rebuilt B=0；replace0及每build/sign原key授權≤1為待Human採用，未採用不執行。工具無法數提示，沉默不是0。

非真人 `--self-test-dpk` 是 unsigned CLI 唯一新增 fake-only入口，使用實際 Swift parser/FS/ACK/Probe.perform 及 fake store，不呼叫 SecTask/SecItem 或簽章；它的成功不是 signed-host／DPK 證據。Python `DPKWire` 僅 ordinary finite child，native/identity最低provider fake，其結果必保持 hostAttributed=false。


### LG75：新窗口資料介面（尚未開窗）

LG73/LG74契約的 exact descriptor/Human/authority schema 由 runner 的 `dpk_window_schema` 驗證；`dpk_open_window(root, descriptor_sha, human_path, asset_expiry=..., sample=...)` 是供受審 caller 使用的內部 factory。`asset_expiry` 必須來自準備階段已驗的原 profile/certificate 有效期較早值，不能由 Human 補欄位或 CLI 任意放寬。外部 Dispatcher/Tester 先核真正 Human 授權及 review freeze；factory 不認證 Human。正式 caller 必須保留舊 revision/ready/quota，只在最後新的 Human 窗口建立固定 `human-window.json`，再以來源固定的 factory 開窗。此文件不是 live ready。

每個 participant 使用明確 `DPKWindow`，不改全域 cutoff 或 clock。可信 boot 來源為 `kern.bootsessionuuid`，雙 clock 使用 UTC 和同 boot `mach_continuous_time` ns；任何不可得、boot 不同、已觀測回退、期限或剩餘 bound 不足都在新 native/store 動作前拒絕。`window.native` 只在開始前核 timeout+保存餘裕；已開始命令原結果/例外保留，逾期不得再開 postverify。DPK round/context/build/sign proof 帶相同 authoritySHA256，request/entry/report/ACK/final 經 contextSHA/roundSHA 接合，B 不加欄位。新 DPK runtime 必走 `dpk_stage` 的 exact 當段 fresh-ready；單靠 binding-launch 的 ready-confirmed 旗標不能通過。Swift 的同 participant window 一路傳入 operation/store wrapper；沒有 window 的舊入口仍走已到期舊 cutoff。

非真人驗證僅由測試 API 注入 synthetic clock/boot 與明確 fake-only 資料；正式 CLI 不提供 fake mode/clock/deadline 選項。新版 `--self-test-dpk` 使用 fake store 穿真 Swift parser/FS/request→ACK→operation→final，並回報 `windowPassed` 的 boot/schema/clock 負例；不簽章、不啟動 App、不碰 DPK。新 source 必另編 unsigned CLI/App 與 buildproof；原 binary/buildsource9 和已核離線15-action結果保持原版本證據。完整新 caller/兩 unsigned App/五phase-Rebuilt NoApp/實際命令仍由 LG78 準備並 LG79 獨立核，不能以局部 source tests 代準備完成。


RF-LG76-01：window-aware identity 驗證的 codesign/csreq 和 subject/dates/class 三個 decoder 共用同一 participant window native guard，decoder 仍將同一 pinned DER bytes 真正傳入 stdin，不回讀檔或改成 DEVNULL。Static/dynamic verifier 與 sign-preparation 必須顯式傳入 window/phase；每個 decoder 前及成功接受前重查 boot/UTC/monotonic，最後 native 回傳後跨 boot/到期仍拒絕。原 native 非零/例外保留，不以後續 clock 錯誤覆蓋；沒有 window 的 legacy/report-only 路由維持原行為。
