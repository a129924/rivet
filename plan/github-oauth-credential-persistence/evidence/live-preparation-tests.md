# L03 Tester：真人驗證工具準備驗證

- 日期：2026-10-21；topic：`github-oauth-credential-persistence`；角色：獨立 Tester。
- Verdict：**needs-rework**。Required fixes：RF-L03-01、RF-L03-02。下一角色是獨立 Implementer；本次不交 L04、不放行 L05/L06。
- 驗證邊界：只讀 L-W01 九檔／本 topic 既有 foundations，僅寫本 evidence 與 step 自己 L03 結果；沒有修改受測工具／測試期望、沒有讀寫他人 worktree／E007，沒有簽章／profile inventory／LaunchServices／SecItem／真人 runroot。

## 獨立執行結果

| 檢查 | 實際結果 |
| --- | --- |
| L02 九檔 frozen SHA-256 | 執行前、寫證據前均 9/9 match；見下表。 |
| `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v` | exit 0；15/15，0.004s。這些是 helper／fixtures，沒有執行 Swift host。 |
| `xcrun swift-format lint --strict validation/github-oauth-credential-persistence/Sources/main.swift` | exit 0，read-only。 |
| `swiftlint lint --strict --quiet --no-cache validation/github-oauth-credential-persistence/Sources/main.swift` | exit 0，read-only。 |
| Debug `CredentialStorageProbe` unsigned clean build | exit 0；一般 private compile scratch 中複製 project/Sources/Resources，local package 指向本 feature worktree。 |
| Rebuilt `CredentialStorageProbeRebuilt` unsigned clean build | exit 0；與 Debug 依序執行，不共用 DerivedData。 |
| Tester 額外 fake-child stage reproduction | 重現 RF-L03-01：historical processUUID 重用被接受，machine.freshProcess 被標為 true；直接呼叫 validate_process 的對照則會拒絕。 |

兩個 unsigned 命令均為 `xcodebuild -project <copied project> -scheme <上述 scheme> -configuration <Debug/Rebuilt> -derivedDataPath <各自 generated scratch> -destination platform=macOS,arch=arm64 -jobs 1 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= clean build`。只使用一般編譯暫存，不呼叫 runner prepare，也沒有建立 live manifest/root。必要 generated build/cache 權限經 escalation 執行。私有編譯 scratch basename 為 `rivet-L03-unsigned-6ew9kdq5`，保留 Debug.log／Rebuilt.log；raw logs 不入 repository。Compile green 不證明有效簽章、profile、runtime compiledMarker 或真重建讀取。

## Required fixes

### RF-L03-01：歷史 process UUID 被排除於驗證

- 位置：`validation/github-oauth-credential-persistence/scripts/credential_storage_live.py:583`–585。
- 現行 stage 在 child 退出後從 existing_processes 建 previous，使用 `item.processUUID != receipt.processUUID` 過濾。這不只排除當次 receipt，亦排除所有重用相同 UUID 的歷史 receipt，使 validate_process 無法檢出 reuse，之後仍寫 freshProcess=true／previousTerminated=true。
- 純 fixture 重現：普通 TemporaryDirectory 下寫 fake run/identity/setup-proof/ready JSON；context、完成階段、inspect、alive 與 child launcher 全以 fake 注入。Historical receipt PID=101，current PID=202，但 processUUID 相同；首次 existing_processes 回 historical，child 後回 historical＋current。Fake child 只寫 read-a.app.json，不執行 open/任何工具。stage 回 awaitingHumanObservation 且 machine.freshProcess=true。相同 current 與 historical 直接傳 validate_process 則正確 Rejected，證明缺口在接線，不是 helper。
- Required fix：保留完整歷史集合進行檢查；只排除精確當次 receipt 檔案，或在 launch 前凍結歷史集合，不依 UUID 值移除歷史。加入 stage-level fake-child regression：歷史同 UUID 必拒絕，正常不同 UUID 可通過，PID reuse／仍存活的歷史程序必拒絕。測試不得靠 source 字串或單測 helper 取代實際 stage 接線。

### RF-L03-02：LT02／LT03 的操作級準備證據缺口

- 位置：`validation/github-oauth-credential-persistence/Tests/test_live_protocol.py:122`–131 僅驗 validate_ownership 字典；169–173 僅驗 launch_command 陣列。Swift `Sources/main.swift:181`–250 直接建立 live adapter、寫 durable proofs 並呼叫 SecItemDelete，沒有可供本輪 pure tests 使用的 store/delete seam。
- 現有 15 tests 沒有執行實際 absence→proof→marker→save 的路徑，也沒有驗 save error/crash 後 marker 保留、exact delete query→adapter load=nil、cleanup failure 後同 root recovery，或真 export/observe 入口的 bytes SHA 綁定及 exclusive 歷史保留。Helper green 與 unsigned compile 不能填補 plan LT02 明訂的 fake Security/child／cleanup seam 要求。
- Required fix：在既有九檔界線內提供可替換的 fake store/delete/child/proof seam，讓與正式 host 共用的控制路徑可測；不得複製一份僅供測試的平行實作、修改 production adapter 或呼叫真 Security。
- 必要驗證：exists／read error 時零 save；持久化 absence 與 write-attempt marker 早於 save；save 拋錯或中斷後 proof 保留；未 owned／selector mismatch 零 delete；delete 僅 exact class/group/service/credential/DPK=true/sync=false，success/notFound 仍須 load=nil；delete/readAbsent 失敗保留恢復材料，同 namespace fresh cleanup ready 可恢復，不清 foreign files；透過實際 stage/observe/export 入口以 fake child 驗證 readyUUID replay 拒絕、未答 unknown 停依賴段、Human SHA 綁輸出 machine 原 bytes、public allowlist 與 final unknown 不覆寫。這些全部維持 pure fixtures，不開真人段。

## LT01–LT04 判讀

- LT01：namespace、exclusive 0600 JSON、0700 root、symlink/path、source drift 的 helper 正反例通過；不把它擴稱完整 live ownership 成功。
- LT02：準備證據不足，依 RF-L03-02 回修。
- LT03：prompt thresholds、unknown、finite projection、SHA、ready schema helpers 通過；stage 的歷史 UUID 接線有 RF-L03-01，操作級 replay/export/cleanup 回歸仍欠缺。
- LT04：兩 schemes unsigned native clean builds 通過；project 的 macOS15/Swift6/local GitHubIntegration product、Rebuilt 編譯條件與 public adapter 接線已讀取。validate_rebuild fixtures 有 profile/buildVerified/marker/binary/validity/source 負例；不冒稱真 source/build/signature/DR/profile/cert/AppID/group/location 已成立。

## 凍結來源

| 檔案 | SHA-256 |
| --- | --- |
| validation/github-oauth-credential-persistence/README.md | `b1c2305b7e0d6505d62d2f01d01fba99bee42559d2c7abe407d7fa2d6517fe6d` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` |
| validation/github-oauth-credential-persistence/Sources/main.swift | `24297250fb5907207bd30e39982a5f52a99e268d9bbce8bc8e0e70b84aa80e11` |
| validation/github-oauth-credential-persistence/Resources/Info.plist | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` |
| validation/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |
| validation/github-oauth-credential-persistence/scripts/credential_storage_live.py | `c0a2307cc5db464356905cc62778fd8f531fa2b423f2148fa29714b287b5e575` |
| validation/github-oauth-credential-persistence/Tests/test_live_protocol.py | `5ff9389509ca914a94af007f6f69e56b6668e68c704e51afe667108acb932665` |

## 下一步與限制

只交 Implementer bounded fixes；修正後重跑相關 pure guards／seams／source hashes與受影響 unsigned checks，再交獨立 Tester／Reviewer。後續修正版 evidence 若需新 leaf，依既有 manifest amendment 先明列，不覆寫本次 needs-rework 歷史。L04／L05／L06、各段 Human fresh ready／提示、簽章與 cleanup 尚未執行，S08 Human 接受仍 pending；沒有任何 live 成功判定。


## L03 bounded recheck r1 — 2026-10-21 03:26:32 UTC

**Verdict：approved；required fixes=[]。** RF-L03-01／RF-L03-02 已在下列凍結版本重驗解除；可交獨立 L04 Reviewer。上方原 needs-rework、重現、原始 hashes及其限制完整保留，沒有改寫歷史。此輪前原 evidence bytes SHA-256：`da812621696c7eacb498de738ebdb88211c7eb526c59628495359a2a2cba3734`。

### 本次實際重驗

- `PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY=<本輪現有 unsigned Debug executable> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v`：exit0，23/23、0 skip，0.146s。包含22個Python helpers／實際runner入口integration及1個實際Swift fake-only binary case。
- unsigned Rebuilt executable 僅帶 exact `--self-test-fakes`：exit0，JSON `mode=fake-only`、`passed=12`、`failures=[]`。Debug binary亦由上述suite實際呼叫相同fake-only入口，沒有走live request入口。
- `xcrun swift-format lint --strict validation/github-oauth-credential-persistence/Sources/main.swift` 與 `swiftlint lint --strict --quiet --no-cache validation/github-oauth-credential-persistence/Sources/main.swift`：各exit0，唯讀。
- 九檔source SHA與最新Implementer凍結值9/9相符。一般compile scratch的project/Sources/main.swift與凍結main.swift一致。獨立核對兩個既有最終unsignedbuild logs有 BUILD SUCCEEDED、重算binary及log hashes；本輪沒有重做兩個build，不將Implementer的compile事件說成Tester重編。
- 將前輪獨立fake-child reproduction用相同歷史UUID/PID101、current PID202重新執行：stage現在拋Rejected，沒有產生成功machine receipt。只在一般TemporaryDirectory的fixture中patch context／inspect／child／alive，不執行LaunchServices或Security。

### Required fixes 解除證據

**RF-L03-01**：runner `stage` 在launch前取得完整existing_processes，child後直接把凍結歷史傳validate_process；不再依current UUID過濾。實際StageIntegration及Tester原重現均拒絕歷史UUID重用；另有PID reuse／歷史仍存活拒絕，正常新UUID透過stage→observe→export成功。這不是僅測helper。

**RF-L03-02**：直接閱讀Swift接線：真人wrapper與fake tests均呼叫同一 `Probe.perform`／`performCleanup`，`ProbeOperations.files`共用durable absence/write-attempt/cleaned file proofs及validateOwnership；只注入store/delete。Live wrapper是唯一SecItemDelete seam，exact fake-only分支在Probe.run／validate／SecTask前返回，沒有複製另一份流程。

12個Swift fake checks執行：exists/readerror零save；durable absence→attempt→save順序；saveerror／模擬commit後中斷保留proof；prooferror零save；unowned/selectormismatch零delete；exact class/group/service/credential/DPK/sync query；success/notFound必須loadnil；delete/readAbsent失敗後同root fresh recovery且proof保留。模擬拋錯不是實際SIGKILL或機器crash證據。

Python實際runner入口另驗：ready replay拒絕且child只執行一次；錯誤Human SHA不寫觀察；未答unknown停止dependent stage；final unknown永久保留；stage/observe/export的public machine原bytes SHA保持且移除private sentinel；cleanup failure後同root recovery使用新ready與processUUID，foreign file/ownership proof及原public failure bytes保留。以上都用fake context/child，沒有建立live root或呼叫真工具。

### 既有unsigned artifacts重算

compile scratch basename：`rivet-storage-L02-build-dz_zpcge`。只讀該已指定scratch，不inventory簽章或其他資產。

| Artifact | SHA-256 |
| --- | --- |
| Debug unsigned executable | `8183280a5273e5a4484e9fda34fde6bc6771411965fd872a200a8f2669d48022` |
| Rebuilt unsigned executable | `17f9a132aa048bfceba19233787d66811da458500444bc7e4ce3d87cfb856170` |
| Debug-RF-L03-final.log | `7564045199b0adb018be042dca5ebf43c61ef59561e55d835157de07cae5d5c3` |
| Rebuilt-RF-L03-final.log | `ed517aa64f8297accd69d2fe0c2add79b0ee5163dca02d7eecb3caf08ccb3cf1` |

### 本次凍結版本

| 檔案 | SHA-256 |
| --- | --- |
| validation/github-oauth-credential-persistence/README.md | `72cc80d38bd487220133e9d5fc32803112172b252ec1e3ba66780d64b607b7f8` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` |
| validation/github-oauth-credential-persistence/Sources/main.swift | `ce775535bc0694b7d67e6cf6aa135aeb450384f2f62c098aadc52401431e9ce8` |
| validation/github-oauth-credential-persistence/Resources/Info.plist | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` |
| validation/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |
| validation/github-oauth-credential-persistence/scripts/credential_storage_live.py | `dabf09ae03f8b09dfe6484c55b8fde60fbea0f1fa65d273a8fbbe302ecae08a8` |
| validation/github-oauth-credential-persistence/Tests/test_live_protocol.py | `72b2ef6d820972cca027fa50ae1d0e5e93a740cf80bdfae8f73b172f0d26f514` |

### 交接與保留限制

下一角色為獨立 L04 Reviewer，僅本次準備回修可前進；不代Human fresh ready或L05/L06。沒有簽章、profileinventory、SecTask、SecItem、LaunchServices、真人runroot、真DPK／跨程序或提示觀察。本輪只追加既有Tester evidence與更新自己L03狀態，不改受測source、測試期望或其他工作線；S08 Human acceptance仍pending。


## L03 runner-only bounded recheck r2 — 2026-10-21 03:42:33 UTC

**Tester verdict：approved；required fixes=[]（本次適用驗證）。** RF-L04-01／02／03及exact-owned-App setup bootstrap的準備測試通過，可交原獨立 L04 Reviewer bounded 回查。此 Tester 結果不改寫或解除 Reviewer 原 needs-rework，亦不放行 Human ready／live。之前 evidence 完整保留；追加前 bytes SHA-256：`4bd9c1a5f52abd262405a921dc9f48fd430c32c88a8999787fac5d58b411b139`。

### 實際命令與範圍

- `PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY=<既有 unsigned Debug executable> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v`：exit0，38/38、0 skip，0.375s。37 Python controls／實際runner入口fixtures，加1個執行既有Swift共用operation fake-only12checks的case。
- 新九檔freeze SHA 9/9相符。Swift main的SHA仍為 `ce775535bc0694b7d67e6cf6aa135aeb450384f2f62c098aadc52401431e9ce8`；現有Debug executable SHA仍為 `8183280a5273e5a4484e9fda34fde6bc6771411965fd872a200a8f2669d48022`。故沿用r1已核對的兩config unsignedbuild／Swiftformatlint事實，這輪沒有重build或重跑未受影響的Swift檢查，也未跑root全套。
- 只讀九validationfiles與本topic既有證據，只追加本Tester evidence／自己step交接；沒有執行raw live request入口、prepare、簽章、profileinventory、SecTask、SecItem、LaunchServices、真人root或其他工作線。DR測試只對fixture固定字串呼叫系統csreq parser，其餘codesign/profile/certificate/App操作皆mock。

### 本輪修正的獨立驗證

**RF-L04-01**：直接核對 `inspect_selected` 從兩個codesign輸出擷取唯一designated requirement，交csreq canonicalize後只hash該canonical expression，不含Executable path。實際inspect fixture分別用derived-debug/current/derived-rebuilt路徑與空白差異得到相同drSHA，validate_rebuild通過；真正requirement改變拒絕。missing／duplicate／invalidsyntax／empty requirement拒絕。沒有用fixture成功宣稱真簽章或DR已成立。

**RF-L04-02**：合法ready消耗後，實際stage入口對setup build、runtime inspect、launch error、missing child receipt及UUID/process guard失敗寫unknown machine與原bytes SHA binding。實際observe記錄fixture當段promptCount=1、finite action、完整觀察，export後仍是unknown、私密sentinel未出現，不把freshProcess或validity猜成true；dependent save-a等仍拒絕。沒有合法ready的拒絕仍不造success。source drift後observe/export採owned結構讀取，不放行source drift後的操作。launch-attempt/settled/child證據不足時保留可能寫入proof且阻止新cleanup child。

**RF-L04-03**：setup無identity或prewrite明確未寫入的fixture，可透過新cleanup ready→files-only machine→實際observe→final export→cleanup-files清理manifest的owneddirectories；cleanup不呼叫child/delete、不宣稱deleted/readAbsent。缺freshready／觀察／final不清；attempt marker、unresolved或存活child、ownership不明拒絕no-write shortcut，foreignfiles／Appleassets／必要privateproof／歷史unknown保留。有write時仍走原strict itemcleanup或留恢復材料。測試是fixtures，不是真刪除或系統恢復證據。

**Exact-owned-App setup bootstrap**：實際stage setup built_app接線只接受ownedroot內固定derived-debug產品；其他App在任何mock codesign呼叫前拒絕並產unknown可觀察machine。fixture核對唯讀exactApp導出私有identity及owned profilecopy後freeze，仍呼叫正式build_selected一次；沒有由manualApp虛構source/build proof。實際profile可用性及Human Xcode選擇都未測。

### 本輪凍結版本

| 檔案 | SHA-256 |
| --- | --- |
| validation/github-oauth-credential-persistence/README.md | `bb6ace4b040073b609b4a14be6bf5028cfaacce46973329cb98b40fe585afeeb` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` |
| validation/github-oauth-credential-persistence/Sources/main.swift | `ce775535bc0694b7d67e6cf6aa135aeb450384f2f62c098aadc52401431e9ce8` |
| validation/github-oauth-credential-persistence/Resources/Info.plist | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` |
| validation/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |
| validation/github-oauth-credential-persistence/scripts/credential_storage_live.py | `1c80a66eae3c56e35620ed31ac56676209bc43bbc1bdbc3111660962fa784017` |
| validation/github-oauth-credential-persistence/Tests/test_live_protocol.py | `ea8ab55eab216210cdbda52a17b2dfd671306eed89e1ffc5b4e69e46b370fa0f` |

### 下一步

只交原獨立Reviewer回查RF-L04-01／02／03與本輪bootstrap的source／fixtures／限制。Reviewer needs-rework歷史與權責完整保留；本Tester不代其給verdict，不代任何Humanready、L05/L06或S08接受。沒有新增repositoryleaf、沒有修改受測工具／測試期望。


## Tester real codesign CLI 窄修重驗 r3 — 2026-10-21 06:10:52 UTC

**Verdict：approved；required fixes=[]（僅本次CLI修正）。** 可交Reviewer窄回查，沒有放行formal setup或解除profile Human boundary。追加前evidence bytes SHA-256：`d1ae23b540504a7dae5d5335abb3a2f2a490c1e93ad378fa6b285af7fac2d505`；前輪needs-rework及r1/r2歷史完整保留。

### 獨立重驗

- `PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY=<既有 unsigned Debug executable> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v`：exit0，38/38，0 skip，0.333s；含現有Swift共用perform/cleanup fake-only12checks。沒有重build／簽章、重跑無關checks或live assets probe。
- 凍結九檔9/9相符：只有runner/tests相對r2改變，其餘七檔保持。兩個正式呼叫（inspect_selected／identity_from_built_app）各只使用一次共用extract_certificate；其argv固定四個元素：codesign、-d、單一equals形式的extract-certificates實參、exact App，不再把prefix當額外code物件。新helper仍拒絕prefix父目錄不符、certificate缺失／symlink／空資料，保留原private command錯誤傳遞。
- 兩個high-level fixtures實際驗argv順序、元素數、equals形式、prefix parent與exact App；測試不只直接呼叫helper或回任意成功值。新實參與Tester前輪對同一exact signed App的真readonly成功語法相同；沿用原private readonly-proof及certificate SHA `5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440`，本次沒有再讀簽章資產。原失敗／成功證據不覆寫。
- 同run原setup ready仍未consume、沒有root identity.json／setup machine；本次只讀受測source/tests與既有private證據，未改privatecopiedproject、scheme、App、manifest、signing settings或其他工作線。

### Staging提案可行性（未執行，非本次授權）

已readonly確認的Xcode scheme變更不涉及BuildAction／buildable／build配置／Swift，因此把同ownedroot的兩copiedschemes恢復原frozen bytes可重新滿足原copiedSources pins，不必改manifest；須先避免Xcode再自動改寫並核對原manifest與四prod／五copied pins。原signed App若保真copy到既有runner expected directproduct bootstrap位置，原App保留且copy後簽章／binary/profile/cert hashes再核對，僅屬私有產物接線修復，不是正式build proof。已修正的certificate CLI可供後續既有stage使用；正式stage仍必須真cleanbuild/source proof及同identity/profile檢查。這是方案評估，不是Tester已restore/copy或批准執行。

仍停Human boundary：profile CreationDate晚於run的採用決定尚未取得，不能把其當run開始前既有profile；原manualSucceeded全程0次只涵蓋manual子步，不延伸formal。無stage／readyconsume／Run／SecTask／SecItem／新資產、trust/security/paid或E007操作。

### 本輪版本

| 檔案 | SHA-256 |
| --- | --- |
| validation/github-oauth-credential-persistence/README.md | `bb6ace4b040073b609b4a14be6bf5028cfaacce46973329cb98b40fe585afeeb` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` |
| validation/github-oauth-credential-persistence/Sources/main.swift | `ce775535bc0694b7d67e6cf6aa135aeb450384f2f62c098aadc52401431e9ce8` |
| validation/github-oauth-credential-persistence/Resources/Info.plist | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` |
| validation/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |
| validation/github-oauth-credential-persistence/scripts/credential_storage_live.py | `25866dff13e96b002956fea1f36002f4c3bc3c2fdedc27009905af2a05695605` |
| validation/github-oauth-credential-persistence/Tests/test_live_protocol.py | `d70e0aa3770436e40b6572b5a0844999f2166bbb5297053f098fc66f95b67f8a` |

下一步只交Reviewer窄回查此CLI修正與相應fixtures；不解除其他未決前提、profile Human決策、formal觀察或S08接受。


## Tester L03-Retry1 候選準備獨立驗證 — 2026-10-21 06:45:33 UTC

**Verdict：approved；required fixes=[]（僅候選準備）。** 可交獨立Reviewer執行L04-Retry1最後code／contract回查。本結果不代Human採用cached Automatic政策、同run唯一retry或freshready，亦不放行真build／sign／Run／DPK。追加前evidence bytes SHA-256：`06d4be82a77602f4bdbe87faae4f1b7178c4a48a7d1844d19b65f81b32187c15`；原needs-rework及全部重驗歷史保留。

### 命令、版本與證據範圍

`PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY=<既有 RF03 unsigned Debug executable> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v`：exit0，55/55、0 skip，0.579s。54個Python純controls／實際entrypoint fixtures，加1個呼叫既有Swift共用perform／delete／proof fake-only12checks的case。Swift main與模板未變，既有Debug executable SHA-256仍為`8183280a5273e5a4484e9fda34fde6bc6771411965fd872a200a8f2669d48022`，沒有重build兩config、重跑無關Swift／root checks或asset probe。固定fixture的DR字串沿既有csreq parser驗證，其餘build／sign／inspect／launch均mock；compile／fixture成功不等於cached Automatic真build或live成功。

九個validationfiles逐檔獨立SHA核對9/9符合Implementer最新freeze。原真人run僅唯讀核原證據SHA及retry leaves不存在：原setup machine SHA-256=`899ed35b0279c730e6c39bb1c4bc927612f7e6c81897b2d3062ff13a5db46d19`；原setup Human SHA-256=`6229797bb5271fa44158be28b63ddf77a46794c154f240bfef2d43e238056154`，兩者bytes保持。真run未建立`private/setup-retry-1/`、`private/setup-retry-1-policy.json`或`private/setup-retry-1-fresh-ready.json`；未建立attempt、consume ready、修改privatePBX／identity／immutablemanifest或他人工作線。

### RT01–RT04 獨立判讀

- **RT01**：共用正式build_selected入口的argv fixture驗六個全域signing／identity overrides均移除，保留既有clean build／owned配置與安全設定；cached build失敗，以及certificate／profile／AppID／group／bootstrap DR／build後frozenPBX漂移均拒絕install。真private_command入口對portal updates、device registration及三個authentication-key flags在subprocess前拒絕。這些是fail-closed工具接線證據，不保證所有本機cache／assets零變更。
- **RT02**：實際retry-setup入口核固定same-run／manifest／identity／PBX／profile／original machine／Human pins；錯policy、舊ready、錯run或identity bytes漂移在build前拒絕。固定leaf與exclusive directory／attempt守住唯一額度；實際入口在mkdir後attempt前注入KeyboardInterrupt，directory-only永久耗用額度，第三次拒絕。attempt記actual runnerSHA供稽核；approval權威明確在外部Dispatcher／Tester比對獨立Reviewer最新approved freeze，不由harness、callerSHA或環境變數自證核准。
- **RT03**：實際observe／export保留initial machine／Human原bytes，retry只新增兩個v1 phase=setup leaves；wrong machineSHA、wholeStageObserved不足、observation replay均拒絕或維持unknown。v2summary固定雙history與effective selector；partial／directory-only／缺receipt使setup unknown、effective=null，不fallback initial；即使retry有效，歷史initial unknown仍使總結果保守unknown。
- **RT04**：新retry出現即取代initial作resolver來源，失敗或partial不解鎖save-a。只有全部guards／buildproof及Human完整觀察SHA綁定成功才允許相依流程；實際stage/runtime與rebuild fixtures採正確retry proof，原setup.build-proof不存在仍不誤讀，rebuild沿原bootstrap DR／identity baseline驗證。原38項legacy／no-write cleanup／unknownchild／ownership／recovery及共用Swift12checks維持通過，未增加清理權。

### 本輪凍結版本

| 檔案 | SHA-256 |
| --- | --- |
| validation/github-oauth-credential-persistence/README.md | `d140677e309b61cb1717e3e1dbab6f6aa14fffa5e84fbe4742f6def9ee13c2bb` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` |
| validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` |
| validation/github-oauth-credential-persistence/Sources/main.swift | `ce775535bc0694b7d67e6cf6aa135aeb450384f2f62c098aadc52401431e9ce8` |
| validation/github-oauth-credential-persistence/Resources/Info.plist | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` |
| validation/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |
| validation/github-oauth-credential-persistence/scripts/credential_storage_live.py | `df542c92dee213ed8f04a9002b1ac467abf4424d96a8b3ac4db746b771052d55` |
| validation/github-oauth-credential-persistence/Tests/test_live_protocol.py | `750201704a87090ca1ded02ff73f565d9fd7da564abf1063a67c62bc869291b5` |

### 下一步與停點

只交L04-Retry1獨立Reviewer審查此freeze；執行前仍須外部核actual runnerSHA等於其最新approved版本。Human尚未採用新cached Automatic政策／唯一retry，也尚未提供retry freshready；本Tester未建立真run新輸入或執行候選，不宣稱cache可用、資產副作用、提示UX、DPK、完整setup或S08接受。原unknown/build與Human本段0次觀察只維持原範圍。


## D03 Tester：§5.2 最小診斷工具候選獨立驗證 — 2026-10-21 07:35:48 UTC

**Verdict：approved；required fixes=[]（僅工具候選準備）。** 交D04獨立Reviewer做source／contract最後審查；不代Human D05新host build/sign scope與ready、D06 diagnostic launch或D07 namespace-read-only ready／actual觀察，不解除舊unknownchild、cleanup或S08停點。追加前evidence bytes SHA-256=`a3d9693aad5ceb6a6b540888a0428c668966572efd203236a7b399c1137074b1`；全部needs-rework／回查／live歷史保留。

### 獨立執行與source／binary綁定

讀technical-spec／plan §5.2、DT01–04、D01及consumed-ready delta獨立approved證據、D02最終命令與freeze，再讀實際Swift bootstrap／validateEarly／execute／hooks／fake assertions，以及Python context／dispatch／marker／observe及其fixtures。四修改葉SHA逐字符合finalfreeze；其餘五個project／schemes／resources亦核對原freeze相符，驗前後九檔皆無變更。沒有讀寫真人run、currentApp或其他工作線，也沒有用舊12-only binary冒充本次診斷。

- D02 `Probe-fake-final` binary SHA=`e602ac7fc350af883b1aec0e0e4420fc0f41a8cadece49fab579a8f12ecf056b`獨立符合；直接執行exact `--self-test-diagnostics` exit0，22個獨立caseIDs、passed22／failures=[]。
- `PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY=<本次D02新binary> RIVET_DIAGNOSTIC_PROBE_BINARY=<同binary> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v`：**63/63、exit0、0 skip，1.013s**。原55regression完整保留；7個新Python實際runner入口cases＋1個新Swift入口case。包含同新binary原共用perform／cleanup fake-only12checks，不是真DPK或刪除。
- 為獨立核source到binary接線，另在普通compile scratch `rivet-diagnostic-D03-e3oiqg0y`，以D02相同已存在四組modules／objects及`xcrun swiftc -swift-version 6 -target arm64-apple-macos15.0`、Security／CryptoKit framework、scratch module-cache編譯目前凍結main.swift；沒有xcodebuild、package更新或簽章命令。Source編前後SHA不變；compiler exit0，stdout／stderr空。Tester binary SHA=`3a6fb9be152b460567555e2d6a54d4a1ac24d72720a0e5f007eb38eaf181bf74`；其自身exact `--self-test-diagnostics` **22/22**及`--self-test-fakes` **12/12**皆exit0、failures=[]。Ordinary scratch保留compile-proof.json與原始compile logs；這是unsigned隔離compile／fake-only證據，不是新signedhost或真人bootstrap結果。
- `xcrun swift-format lint --strict validation/github-oauth-credential-persistence/Sources/main.swift`及`swiftlint lint --strict --quiet --no-cache validation/github-oauth-credential-persistence/Sources/main.swift`各exit0，無輸出。只看到固定single-host檔案附理由的局部file_length豁免；沒有新增全域lint設定或放寬其他規則。

### DT01–DT04判讀及額外bounded fixtures

**DT01**：Swift execute直接使用真正bootstrap／owned／exclusiveJSON。Bootstrap沒有output寫入API，先檢有限schema與型別、manifestSHA、lowercase UUIDv4、固定purpose、canonical0700自身root、逐段無symlink／ownership、exactApp／source／binary與legacy hashes；只有可信結果才選purpose固定output。Actualfake的錯SHA／purpose／expectedApp逸出／schema1.5／UUID／source symlink及preexistingreceipt均拒絕，不落output或覆寫keep bytes，trace零load。不是只讓Python mock回成功。

**DT02**：可信bootstrap後即取得固定safe destination，validateEarly的args／request／root／source／identity／Bundle／entitlement失敗以真正Swift路徑產finite stage／failure收據；fake assertions驗stage/status、0600、無private sentinel／fixturepath。DiagnosticHooks.live只建立closures；store facade的建立與public credentialStore.load唯一呼叫都在loadclosure內，只有namespace-read-only分支會invoke。Diagnostic-only成功或失敗皆不load，不進原perform、不呼叫四SecItem。新版入口不fallback舊Probe.run；bootstrap不可信時無收據，Python missinghost／launcherror保持unknown且不製造App成功收據。

**DT03**：Actualfake readonly nil／present／untypederror及denied／unavailable／corrupt／identityMismatch都走同一execute，trace每次恰為[load]，hooks不提供save/delete介面；diagnostic trace=[]。Nil只輸出現在absent，present/error停。所有fake cases均驗原absence／write-attempt未建立；Python fixture逐byte核legacy JSON保持。原unknownchild／ownership／no-writecleanup／recovery regressions仍通過，沒有把nil、無PID或newcopy的結果回推舊Writer安全未寫或放行cleanup。

**DT04**：七個新Pythoncases走實際main dispatch／stage／observe與同一exclusive_json；mock只攔截App launch。Launch callback先讀已寫consumed marker並核ready bytesSHA，證consume-before-launch。Existing／partial marker、writefailure、launcherror／missingAppreceipt後ready重放皆拒絕。Tester另用普通TemporaryDirectory補兩項獨立exercise：一是在真正exclusive_json的os.fsync注入OSError，驗零launch、marker保留且下一次拒絕；二是namespace實際stage／observe fixture驗固定namespace marker在launch前已存在、wrongpurpose及wrongmachineSHA不觀察成功、正確binding才觀察，diagnostic marker未混用，legacy原bytes及無absence／write-attempt保持。沒有更動repository tests期望、也沒有真人ready／policy／attempt或diagnostic scratch。

Python projection僅有限stages／status／failureKind／hash／booleans／readonlystate，任意private欄位不外洩；Human exactbytesSHA與diagnosticUUID／purpose綁定及exclusive sidecar保持。Consumed marker任何存在即耗用本purpose額度，不作App成功或legacyownership證據；fsync失敗不launch，無收據unknown，不能重放或自動恢復。

### 本次實際Swift診斷case IDs

`bootstrap-sha-zero-output`、`bootstrap-purpose-zero-output`、`bootstrap-path-zero-output`、`exclusive-receipt`、`args-failure`、`request-failure`、`identity-failure`、`bundle-failure`、`entitlement-failure`、`source-failure`、`diagnostic-zero-load`、`readonly-absent`、`readonly-present`、`readonly-error-zero-write`、`bootstrap-schema-zero-output`、`bootstrap-uuid-zero-output`、`bootstrap-symlink-zero-output`、`root-failure`、`readonly-denied`、`readonly-unavailable`、`readonly-corrupt`、`readonly-identityMismatch`。

### 最終修改葉freeze

| 檔案 | SHA-256 |
| --- | --- |
| validation/github-oauth-credential-persistence/Sources/main.swift | `d65f818dfbfe92726cc3e1928b161a8b783b3f84af2b3befceb5897f1223f618` |
| validation/github-oauth-credential-persistence/scripts/credential_storage_live.py | `a2834ede6d9c90b418e20c3723210c54530fe6a18ee5308edf9cb0f9a09c6907` |
| validation/github-oauth-credential-persistence/Tests/test_live_protocol.py | `1e016f12fcfc99f9f18f3ee36eb535d8dca3a902d893da9b3d9941c8cd046f53` |
| validation/github-oauth-credential-persistence/README.md | `8a14aa67d05b6036b3e301ca03b938015814b210a5e80d511b0c3fb22e0f54c8` |

### 交接與限制

D03 completed／approved只限可交獨立Reviewer的工具準備；不保證真Bundle／SecTask／LaunchServices能啟動或重現原早期guard，也不代表DPK、提示UX、原namespace恢復或安全清理完成。未xcodebuild、signedbuild、sign、AppRun、LaunchServices、SecItem、真人root／assets probe或建立真人新inputs；未修改source／舊run／私人manifest與identity／current／別人verdict。D05–07仍須各段明確Human scope／freshready與actual觀察；外部執行者須再核獨立approvedfreeze，不由harness自批。


## LG04 Tester：launcher-only獨立non-live驗證（2026-10-22 02:52:16 UTC）

**Verdict：needs-rework；required fixes=[RF-LG04-01]。** 原repository suite83/83 green不等於本Tester新增反例符合契約；回Implementer做下列單一bounded修正，再交Tester重驗，不前進Reviewer／LG06/07。追加前本evidence bytesSHA=`70df348ee9b597ca29096d707fb86ed7a273ea6d29ba718cdf75ad50c8ab7692`；所有舊needs-rework／成功／unknown及Human歷史保留。

### 獨立結果與範圍

直接讀spec/plan§5.3、LG02兩項回修及current-state delta獨立approved/fixes=[]、LG03freeze，審實際launcher/context/receipt/finally/observe/processsnapshot與20項新增test assertions。三修改葉及另六葉freeze9/9相符；自身branch為feat/github-oauth-credential-persistence。只普通TemporaryDirectory與non-App有限fakechild，不讀寫真人root、current App或其他工作線，也不執行真正libproc/sysctl/PID/argv OSprobe。

- 原完整命令：`PYTHONDONTWRITEBYTECODE=1 RIVET_FAKE_PROBE_BINARY=<既有D02 fake-only binary> RIVET_DIAGNOSTIC_PROBE_BINARY=<同binary> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v` → **83/83、exit0、0 skip、2.253s**（原63＋新20）。包括實際普通Python fakechild rc0／7／自身signal15／timeout後仍活且自行有限退出；timeout不kill。Spawn/wait／disk錯誤為mock注入，沒有呼叫真open或App。
- 既有未變Swift main SHA仍d65f818d…3f618，D02 binary完整SHA=`e602ac7fc350af883b1aec0e0e4420fc0f41a8cadece49fab579a8f12ecf056b`符合；suite實際呼叫既有22診斷＋12operation fakechecks，沒有重編／重簽或冒稱真host／SecTask/DPK成功。
- 兩個changed Python各AST parse/compile記憶體檢查通過。`ruff check --no-cache --select F,E9 --ignore F401 <runner> <tests>` exit0；沿本次既定適用範圍，未改全域lint／原兩個F401或安裝工具。

LG-T01／02／03／05／06的已驗部分：actual入口逐token固定兩env與唯一invalid sentinel，無--request/-n/rawApp；未改Swift兩條count==5 guard，故sentinel的count2在request/store前拒絕，任一env存在走diagnostic、皆遺失也在legacy args guard停，不把sentinel當DPK驗收。Actualfake驗rc/signal/timeout/spawnOS/waitOS及receipt absent/valid-unbound/invalid/unreadable；native0與有效receipt始終unknown、hostConfirmed/appReceiptAttributable固定false。Path/pin/symlink/partial/spent及badSHA/count/exclusive／unknownHuman有覆蓋，原D06/legacy fixtures bytes保持。

Current-state只以fixtures驗matching host/open、incomplete／不可辨識即拒絕與argc/NUL parser；source使用PROC_UID_ONLY、完整兩hostpath，只有exact open executable讀bounded KERN_PROCARGS2，逐token比較固定manifest/request導出的兩個舊command，不讀其他App argv、不保存無關inventory。legacyWorkerSettled只屬本次known-open-absent，不能從ready／CLI0／無PID推歷史settlement、無寫或ownership。這些是non-live接線／靜態核對，不宣稱真OS snapshot已通。

### RF-LG04-01：無可用持久binding仍可observe殘留primary

位置：`scripts/credential_storage_live.py`的launcher_amendment finally約1417–1432行及launcher_amendment_observe約1438–1444行。後者在caller-result.json不存在時，無條件選launcher.machine.json當primary，沒有證明該primary曾持久成功。

**獨立實際入口反例**（未改repository tests／期望）：使用既有LauncherAmendmentControls普通fixture與真有限fakechild／patched current-state。對launcher_write注入：(1) primary呼叫原write留下完整JSON bytes後raise OSError，模擬primary寫／fsync未確認成功；(2) caller-result在write前raise OSError。Actual launcher CLI依契約exit2、primaryReceiptWritten=false、callerResultWritten=false、bindingReceiptSHA256=null，primary partial保留、caller-result不存在。接著以這份殘留primary的actual bytesSHA執行actual observe入口，count=unknown、actions=other、whole=no：**目前仍建立launcher.human.json，bindingKind=primary**，observe雖exit1/unknown，卻把無可用binding升格為可觀察primary。原suite的partial-primary-fsync case只覆fallback成功，both-writes-fail case只在primary完全不存在時驗null，未覆本組合。

契約明定primary失敗且fallback也失敗沒有可用binding；Human只能綁已選定且已確認持久receipt。必要最小修正：observe不可用caller-result缺失作primary成功證據；既有selector證據缺失／partial／不一致時fail closed，保留所有partial，不創Human sidecar、不補寫／重做receipt或新fallback leaf。補上述實際launcher→observe回歸：launcher exit2＋兩written=false＋binding=null；observe拒絕且**launcher.human.json不存在**、不交付殘留primary binding。正常可核primary及fallback成功觀察路徑、未知Human不補0、83既有回歸應保持。只補此精確binding缺口，不引入通用durability framework或擴新scope。

### 凍結版本與停點

| 修改葉 | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `562af43d50c814ed3a6f5ed889cd63ee78e152532aed8f1356def7344ea99505` |
| Tests/test_live_protocol.py | `8df86206a80a4752254a4158fce1867d5db36700e1a59bddcf83f29fdff7a24d` |
| README.md | `0ef158f7048ea84008d2c0297d722d6151f996ed7f08a0e7fba5f9b3ca6d34f1` |

Tester未修source／tests／作者verdict，未新增repo leaf、真人inputs/ready/root、查真PID/OS、App/build/sign/Keychain/DPK或清理；原D05成功與Human0、D06/save-a unknown及Human0／strictownership／S08停點不動。回Implementer單一RF，修後bounded重驗再交獨立Reviewer；LG06/07及D07仍未授。


## LG04 bounded複驗 r1：RF-LG04-01（2026-10-22 02:56:28 UTC）

**Verdict：needs-rework；required fixes=[RF-LG04-01]（同一RF的fallback分支尚未解除）。** 原needs-rework、作者回修及全部歷史保留；追加前evidence bytesSHA=`eb5761d4e768aab0b93ee93f3514462a2f3b3f249e37c421831adff1cdc570d5`。未擴一般power-loss／durability框架。

直接讀LG03最新回修交接及實際source／assertions，核新三葉freeze，不沿用舊SHA：runner=`a42b954390e10940180b18ad5e9c80ff53dae8aa9de5b7b79f28fb42c5c46027`；tests=`d41ee9a35d18da1bc17acfe47833348db783fc0cb75214c73f1aeab3a0089aca`；README=`f5e03f45696c354ef258b963748c8bfcb494a9c4e683f49b1c7ea08a3b10d291`。其餘六葉及既有e602ac7f…56b fake-only binary亦符合。新suite同原LG03命令獨立重跑：**85/85、exit0、0 skip、2.108s**；兩changed Python AST/compile與原適用Ruff F/E9(ignore既有F401)均通過。未重編Swift／建置簽章或執行真人OS/App。

### 原反例已修的部分

同獨立ordinary fixture再次執行actual launcher→observe：primary完整bytes後注入write/fsync失敗，caller-result寫入前失敗。Launcher exit2、兩written=false、bindingSHA=null；observe現在拒絕且**Human不存在**，primary residual bytes保持。新observe要求caller-result存在及精確schema/context，並交叉驗primarySHA／humanBinding，的確解除原missing-caller默認primary分支；既有有效fallback觀察仍在85suite通過。

### 同RF剩餘可證明反例

普通LauncherAmendmentControls fixture中，保留真有限fakechild及mock current-state（無真OSprobe）：(1) primary在write前raise OSError；(2) caller-result呼叫原launcher_write寫成完整JSON bytes後raise OSError，模擬該fallback write/fsync未確認成功。Actual launcher CLI **exit2、primaryReceiptWritten=false、callerResultWritten=false、bindingReceiptSHA256=null**；caller-result完整residual存在，primary不存在。再以此residual的actual bytesSHA執行actual observe入口（promptCount=unknown、actions=other、whole=no），**仍建立launcher.human.json，bindingKind=caller-result**；residual bytes未改。此反例是明確write/fsync失敗接線，不推論主機斷電或任意同UID偽造。

原因：finally的caller_sha在write/fsync例外時保持null，CLI如實宣布無可用binding；但observe只靠殘留caller-result內容的primaryReceiptWritten=false／humanBinding=caller-result／failureKind=receiptWrite便採納它。精確schema/context能排除錯誤選擇，仍不能在這個明確失敗分支證明fallback曾確認持久成功。現行85suite新增的兩項只覆caller-result不存在及selector欄位矛盾，沒有覆fallback完整bytes但失敗這一分支。

**必要最小修正／驗收：** 同RF將fallback write/fsync明確失敗時的residual一併fail closed，不得從完整可解析bytes推可用binding。補上述actual launcher→observe負例：launcher兩written=false且binding=null後，observe必拒絕，**Human sidecar不存在且不回傳此residual為可用binding**；保留partial bytes，不補寫／重做／刪除／新增fallback leaf。正常已確認可用的primary與fallback觀察及85回歸保持。只處理這個既有失敗分支；若現有caller協定不能提供所需辨別證據，先如實回既有bounded planning，不新增durability框架或放寬負例／以操作說明代替拒絕。

只append本Tester evidence及自身LG04複驗row，未改code/tests期望／作者verdict／正式artifacts。沒有真PID/libproc/sysctl/open/App/build/sign/DPK、真人root/inputs/ready或cleanup。回Implementer完成同一RF後再由Tester bounded重驗，不交Reviewer或live；原D05/D06/Human及Keychain／S08停點全保留。


## LG04 bounded複驗 r2：RF-LG04-01 publication修正（2026-10-22 03:05:56 UTC）

**Verdict：approved；required fixes=[]；RF-LG04-01已解除（僅工具non-live候選）。** 原兩輪needs-rework、85green及所有反例／真人歷史完整保留，追加前evidence bytesSHA=`3f3bc388fbb7b6eb3e52c3fefb63b4eda5da27909f6d9196e761ed47e557795b`。交LG05獨立Reviewer，不代LG06/07授權或live、D07/DPK／cleanup／S08。

直接核LG02最新兩pending／publication四態矩陣delta的獨立approved/fixes=[]，再讀LG03最新完整freeze與實際publication／finally／observe／tests assertions及README future CLI，不沿用舊hash。九validation leaves9/9符合（三修改葉如下、其他六含host main保持）；原e602ac7f…56b binary亦核符合，沒有重編或簽章host。

### 獨立重跑

原LG03 full suite命令（兩RIVET fake binary變數指同既有普通unsigned fake-only binary）獨立執行：**94/94、exit0、0 skip、4.344s**；原63及其Swift22＋12 fakechecks均實際執行。適用Ruff `--no-cache --select F,E9 --ignore F401` exit0，兩changed Python AST parse/compile通過。Child僅普通自有有限Python fake，rc／signal／timeout自己退出；process snapshot只fixtures，沒有真open、OS/PIDprobe、App或DPK。

**兩個Tester獨立原反例均通過，沒有改原noHuman期望：**

1. Primary pending寫成完整JSON後，於真os.fsync的該payload fd（以fstat的dev/inode識別）注入OSError；caller pending在write前失敗。
2. Primary pending在write前失敗；caller pending寫成完整JSON後，在真payload fd的os.fsync注入OSError。

兩次都走actual launcher CLI→actual observe；不是在已發布final之後任意raise。結果各為launcher exit2、兩written=false、binding=null，完整pending可解析且bytes保留，兩final皆不存在。即使向observe提供該pending的actual bytesSHA，它仍拒絕、回binding=null且**launcher.human.json不存在**。只在普通fixtures執行，無真人context／ready／input。

### Publication及選擇核對

- 專用launcher_publish先以原exclusive/fsync writer寫固定pending，完成file與D fsync，才no-clobber atomic link發布final；全域exclusive_json／其他legacy writer未變。Source中link後只return已計算SHA，沒有後續fallible讀／fsync／cleanup將已發布結果降成null；pending保持供驗證，未宣稱final directory entry跨斷電存活。
- Suite實際驗primary與caller payload／prepublication directory fsync失敗不發布；existing final及link競爭FileExists不覆寫；pair不同inode、bytes或cross-binding矛盾拒Human。Observe核final/pending安全owned位置、dev/inode／完整bytes／精確schema與context。Pending即使完整不binding，原兩反例皆保留。
- 最新四態：兩者發布且一致選primary；primary發布／caller失敗仍選primary並exit2；primary未發布／caller發布只選caller並exit2；兩者未發布必null/noHuman。正常published primary／fallback及unknownHuman不補0回歸通過；成功publication只代表launcher觀察，hostConfirmed／appReceiptAttributable仍false、整體unknown，不推host成功或原D06歸屬。
- Directory-or-marker partial額度、exclusive0600／fsync、無overwrite／retry／kill／cleanup及固定invalid sentinel保持。Frozen Swift兩條args count==5 guard仍先於request/store；launcher唯一sentinel沒有--request，env遺失也不進legacy保存，沒有改host或允許DPK。
- 未來CLI及輸入已具體：README從既有D05 execution.json安全metadata取同N，外部核approved runnerSHA，Human當段明確freshready後才傳新UUID與--ready-confirmed；现有CLI自身在spawn前執行已實作current-state preflight，不需ready後另寫caller。OwnUID／兩個known完整host paths／selected-open完整舊argv皆由既有manifest/request導出，unknown或match拒絕；本輪只fixture/static核對，不能宣稱真OS snapshot已通或由無PID推出historical無寫／ownership。

### 本輪最新freeze

| 修改葉 | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `689eaeb8d65309ed4a23f20fe6e9889c5e54dca713f0b90e1a0912e3429e4e90` |
| Tests/test_live_protocol.py | `daef8d44659176b95f9016f3cae01be1ff963112db1fb044f574f727fe6f45b3` |
| README.md | `5a82028bf832b8267f37340376b9683dd8c1c642e2260e1a86a07cb5112df3dd` |

本Tester只append原evidence及自己的LG04複驗row，未改實作／tests期望／作者或Reviewer判定。沒有真OSprobe、open/App、build/sign、Keychain/DPK、真人root/inputs/ready、舊資料／namespace覆寫或delete/cleanup。原D05pass/Human0與D06/save-a unknown/Human0／unknownchild與所有strictownership限制保留；此approval只可交LG05獨立code review，不等於future scope／ready或解除live停點。


## LG11 Tester：pre-trusted-D有限stdout獨立驗證（2026-10-22 03:22:55 UTC）

**Verdict：approved；required fixes=[]（僅non-live工具候選）。** 可交LG12獨立Reviewer，不代新Human scope／freshready或任何invoke。原LG06單次pre-attempt unknown／stdoutSHA b3d71cb085489be348cd23a361040f247b5b2bbc139b8ae8dd9bbf497885db66／Human全程0及全部歷史不回填、不改為已知根因。追加前evidence bytesSHA=`ec836d7e9840622d57447541a29d3effca5702ca31d06a237217768a63cff35d`。

### 獨立執行

先讀LG09獨立approved/fixes=[]與spec/plan有限四keys契約、LG10最新freeze及實際guard/API/projection/CLI與五項multi-branch assertions。三修改葉及其他六host葉9/9符合；沒有改host或舊snapshot。原LG03 full suite命令（兩RIVET fake binary變數沿既有普通D02 fake-only binary）獨立重跑：**99/99、exit0、0 skip、2.714s**（94回歸＋5項multi-branch）。原22診斷／12operation fakechecks與publication／Human矩陣保持；未重編Swift、產品或host。兩changed Python AST parse/compile及適用Ruff `--no-cache --select F,E9 --ignore F401`皆通過，未更動lint政策／安裝工具。

所有新API測試是actual main CLI dispatch加fake ctypes CDLL/provider，不呼叫真Darwin libproc/sysctl、launcher/snapshot真人入口或任何App。Native child仍只原regression中普通自有有限fake；沒有真人root/ready/input或OS/PID資料。

### 邊界與負例判讀

- Invocation-local plain dict由amendment/state/snapshot傳遞；每個source point先清前一point的API資料。兩次list、每選定PID path、selected-open兩次sysctl等原call位置／參數／次數及require仍保留；沒有重查／buffer retry或放寬成功條件。ctypes.use_errno、set/get thread-local errno只提供觀測。
- Actual fake API assertions覆context/ready/quota/request/platform/library/list-size/list-read/open-canonical/path/args-size/args-read/decode/match/source/output等point：原返回立即記returned與符號，再執行原guard；native失敗errno0／不可得為unknown，已知errno只有限映射；純require與成功API後buffer-bound拒絕不捏造失敗errno。敏感fixture message/path/argv/environment/PID字串不出stdout。
- Tester另以同ordinary fixture／actual CLI＋全fake ctypes獨立串接：先permissionDenied的path失敗，再下一invocation的args-size負return／errno0，確認後者為negative／unknown；get_errno回None時native0失敗仍unknown；get_errno拋含敏感sentinel的RuntimeError時只有限exception／unknown，不洩raw字串，D與spawn均不存在。這些是當次fake值，沒有把任一正/0返回或舊thread-local errno當作本次確定失敗原因。
- 四keys只加在launcher-amendment尚未trusted D的拒絕stdout；觀測資料或分類本身不可得時維持有限unknown。Trusted-D成功及其native/write失敗輸出仍原五keys，observe／其他legacy schema與例外邊界不加四keys。既有publication十leaf、四態binding／兩原fsync反例、Human exactSHA/unknown不補0及spentquota94回歸全過。
- public欄位只有封閉guardPoint／apiOutcome／apiReturn／errnoKind，不包含raw exception、PID、count、path、argv、ID或buffer。Status仍unknown／nonzero；這些欄位不是Host success、historical settlement／無寫／ownership或清理證據。此次沒有新的真API返回資料，不能藉新code定位LG06歷史原因或保證未來可啟動。

### 最新freeze

| 修改葉 | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `3bb4d411ebc8ef961c29d756fb9f2e613b3e4b571d8d9746230d21ff0c9632a1` |
| Tests/test_live_protocol.py | `13f95da8b1c5b7a80799ee20f5f72246864ded2b195c347eec0486b2141e479a` |
| README.md | `b98fb6aeb5e7cf7a9f2a7f8a72eab81bb984d670dfbc22b2f1f2e3bd66450f5f` |

本Tester只append既有tests evidence及自己LG11 row，保留所有needs-rework／成功／unknown／Human歷史與他人verdict。沒有執行真launcher-amendment／snapshot／OSprobe／PID查詢、open/App、build/sign、DPK/Keychain、真人root/inputs/ready或cleanup；沒有重跑LG06或改舊root/current/manifest/identity。交LG12獨立Review，未授任何新invoke或S08接受。


## LG17 Tester：正向名稱前篩獨立 non-live 驗證（2026-10-22 03:51:08 UTC）

**Verdict：approved；required fixes=[]。** 僅代表本輪工具準備可交LG18獨立Reviewer；不是實際launcher／host／DPK成功，不授新invoke或Human freshready。先讀README/design、LG15最後approved/fixes=[]、LG16交接、spec/plan LG-N01–07及本輪N07原版native等價fixture澄清；原Python path/argv0 mismatch、copied sleep exit-9原因未驗、LG13與全部成功／unknown／Human歷史保持。追加前evidence bytesSHA=`e90598cdaa7a3cc87f364b8890d22b7525d0a67c0d589f25b131b107f05ed6a0`。

### 獨立執行與結果

- `PYTHONDONTWRITEBYTECODE=1 RIVET_DIAGNOSTIC_PROBE_BINARY=<既存D02 fake-only binary> RIVET_FAKE_PROBE_BINARY=<同binary> python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py`：**104/104、exit0、0 skip、2.948s**。包括原99 publication／Human／sentinel／finite fakechild回歸、Swift22診斷與原12operation fakechecks；未重編host。既存fake binary SHA=`e602ac7fc350af883b1aec0e0e4420fc0f41a8cadece49fab579a8f12ecf056b`。
- 兩changed Python的`ast.parse`＋`compile`：2 passed；`ruff check --no-cache --select F,E9 --ignore F401` runner/tests：All checks passed，exit0，未改lint政策或安裝工具。
- Tester另以既有ordinary unittest fixture／actual CLI dispatch和全fake ctypes provider作**3項獨立測試、40子例**，0 failure：30種known22/4的完整／逐長prefix、大小寫及空白／非ASCII歧義名稱，均走candidate path；注入ENOENT仍snapshot-path/notFound拒絕，單次name＋單次path、零args、無D/spawn。另6個可信disjoint長度1/14/15/16/30/31，在fake process-state入口（固定open known-name）均零path／args；4個candidate path ENOENT／ESRCH／EPERM／errno0仍拒絕，沒有把notFound當gone。獨立測試未改repo tests或期望。

### N01–N06 source／assertion 查核

每個同次ownUID listed PID只新增單次proc_name，零初始化32-byte buffer；要求int return 1…31、return位置NUL、此前無NUL與strict UTF-8。API0／notFound／例外／空／壞編碼／長度不符或不可得均停止，沒有略過ESRCH。目標只由原固定host path basename與open導出完整／31/15 aliases及非空prefix；ASCII可信且與全部known不相容才排除，15/31長度本身不是全域candidate。大小寫／編碼／別名不能排除的歧義仍candidate；候選原fullpath及僅exact-open bounded argv接線保留，名字不當identity。

實際assertions核對新增5 multi-branch cases及原99：unrelated/disjoint15/31皆zero path/args；known full／15 alias／prefix／歧義皆candidate；name格式／API錯誤不產D／spawn；candidate path錯誤仍拒絕。snapshot-name僅新增既有有限guardPoint enum，public九key／trusted-D及observe舊schema不擴；每point重設metadata、同次native呼叫前清errno，敏感name／PID／path／argv／rawerror不出stdout。Publication四態矩陣、pending/final及fsync反例、Human exactSHA、quota、invalid sentinel、hostConfirmed/attributable=false均由原回歸保持；不把processCheckComplete推為歷史退出或無寫。

### N07 唯一原機 native 等價 fixture

直接讀回spec/plan新增允許原機未修改且未複製的`/bin/sleep`單一finite child後才執行：Popen executable固定原binary、argv0固定非秘密`CredentialStorageProbe`、參數1秒；只對Popen直接取得的own child PID讀單次proc_name／path和bounded KERN_PROCARGS2（兩次size/read，最多1MiB，僅解析argv並保存必要argv0，不保留environment tail）。沒有UID列舉／其他PID／退出後PID查詢，沒有copy/patch/sign binary、App或安全調查。

實際結果：nativeNameValid／nameMatchesNativeBasename／pathMatchesNativeExecutable／kernelArgv0MatchesSpoof／nameDifferentFromSpoof／positiveExcluded／childExitedNormally／emptyChildLogs均true。核心name為固定原生basename `sleep`，完整path與原binary相符，kernel argv0仍固定spoof且不同於name；自然exit0，沒有kill或重試。此為一個直接native executable的正向對照，**不覆寫原Python path/argv0 mismatch限制，也不宣稱跨API原子快照／一般rename／exec／PID競態保證或真launcher可用**。Raw PID/path與有限native回傳保存在0700 ordinary scratch `rivet-LG17-knownchild-4gpu_upa`的0600 `private-result.json`；bytesSHA=`468bfc5e8870d0437812331ec14a916f5732b89ea527c38c99ecec64c9a48a3a`。

### 獨立核實 freeze（9/9）

| validation相對leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `a2ea02691abe9059300a2af7810fddc128a97c5bc35aba230a28ec381cebfae4` |
| Tests/test_live_protocol.py | `a6a6275ae6d68c045ec0d7503826a62d1b8ec8345b14016a2e9346299d0c0cf7` |
| README.md | `20bca7090ab9182616f19db70e2ec2d7800f162af6c17871e79c9c2d7e0403ba` |
| Sources/main.swift | `d65f818dfbfe92726cc3e1928b161a8b783b3f84af2b3befceb5897f1223f618` |
| CredentialStorageProbe.xcodeproj/project.pbxproj | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` |
| CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` |
| CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` |
| Resources/Info.plist | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` |
| Resources/CredentialStorageProbe.entitlements | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |

本Tester只append原tests evidence與自身LG17 row/交接，未改實作、tests期望或他人verdict。未執行真launcher CLI／全UID snapshot／其他PID／open或App／build/sign／DPK/SecItem／新ready／真人root／舊資料清理；沒有讀寫E007或他人worktree。所有舊context/manifest/identity/host/sourcepins與成功／unknown／Human歷史不改。交LG18獨立成果審查（包含N07等價fixture澄清），仍停在新的具體live scope／freshready邊界。


## LG23 Tester：fullinfo／status／instance獨立 non-live 驗證（2026-10-22 06:54:38 UTC）

**Verdict：approved；required fixes=[]。** 只交LG24獨立Reviewer，不代真人／App／DPK可行或新的freshready。先讀README/design、LG20 spec/plan精確演算法及M01–07、LG21最後approved/fixes=[]、LG22完成交接和實際source/assertions。追加前evidence bytesSHA=`ab9ee3fc5d90594f36bdd20bc6d7f3320b7dffb2a989a54677eff385a4ff2fd7`；全部舊needs-rework、成功／unknown／Human與Python mismatch／copied sleep -9未知史保留。

### 實際獨立執行

- 沿既存D02 fake-only binary設定兩個RIVET變數、`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py -v`：**114/114、exit0、0 skip、4.572s**。原104回歸與新增10 case全過，含publication/pending四態與fsync反例、Human exactSHA、sentinel／有限fakechild、Swift22診斷及12operation共用fake paths。未重編Swift/host；既存binary SHA `e602ac7fc350af883b1aec0e0e4420fc0f41a8cadece49fab579a8f12ecf056b`直接核一致。
- 該suite內M01實際`/usr/bin/clang -std=c11 -fsyntax-only -x c -`以SDK `sys/proc_info.h`核sizeof=136、native alignment、全部22欄offset靜態斷言通過。無native產物／App／簽章，未另外重複compile。
- 該suite內M06只一個原機未修改、未複製`/bin/sleep`1秒Popen child：直接own PID觀察到live sleep，再未wait的SZOMB=5；同instance starttime吻合，arg1可讀完整metadata、arg0回0且errno非0；finally自然wait exit0後arg1仍Rejected／metadataUnavailable。只有這個known child的有界狀態輪詢，沒有proc_listpids或其他PID；未再spawn第二個native lifecycle fixture，沒有kill。這是當次對照，不證LG19原因／本機kernel與公開source exact revision吻合或全UID可用。
- 兩changed Python AST parse/compile：2 passed；Ruff `check --no-cache --select F,E9 --ignore F401` runner/tests：All checks passed、exit0。未安裝工具或改lint政策。

### M01–M05 source／assertion判讀

公開SDK proc_bsdinfo以uint32/int32/uint64與native alignment逐欄定義，arg1 exact-size reply才讀PID/ownUID/status/start sec/usec。0／短／大／錯PID/UID/starttime／未知或未就緒status均拒絕；無errno-only gone、membership重讀或exactPID fallback。可信SZOMB可不依name正向排除；live name/comm皆有界NUL／strict UTF-8，原完整／31/15／prefix正向名字規則保持，未知／格式壞不skip。

Candidate以A為前界，兩次完整path/exact-open bounded argv分類；觀測真host或原exact-open command當下直接衝突停止。兩次結果一致後讀B，完整valid A/B的PID/UID/starttime及status／原raw name/comm均比較；可觀測漂移拒絕，不重新把新instance排除。M03/04 assertions覆name歧義／denied／metadata0／reaped、instance／status／name／path／argv變化與真衝突，未知仍不產D/spawn。

ProcessEvidence只launcher-amendment stdout八個allowlist keys；decision是最後事件、bool aggregates只保留已發生正向事實。metadataUnavailable/Invalid、permission與instance/classification拒絕不被false當全局absence。每次snapshot reset；pre-D／trusted-D stdout可含有限物件，published machine/caller/Human及其他CLI schema／publication與sentinel不改。name/PID/UID/starttime/path/argv/env/rawerror/buffer不公開，projection失敗固定defaults不授launch；hostConfirmed/attributable仍false。

### Tester新增有限風險負例：4 tests／9子例，0 failure（0.093s）

全部沿既有ordinary unittest fixture／actual CLI dispatch＋fake ctypes provider，不調真libproc/listpids／launcher／App。沒有修改repo tests或期望。

1. Candidate A與兩path皆成功，**B native reply**分別0/ESRCH、0/EACCES、135-byte短reply：三者均拒絕且無D/spawn，decision依次metadataUnavailable／permissionDenied／metadataInvalid，instanceChecked/checksFinished皆false；兩metadata＋兩path，零args。
2. **第二次分類才遇真衝突**：先other後exactHost，以及兩次exact-open但第二次argv才等原known command。皆立即targetHost/targetOpen與conflictObserved=true，無B metadata／D/spawn，metadata只有一次、path兩次；open僅四次bounded size/read。真衝突不被「前一次other」或後續instance重新分類掩蓋。
3. 三筆fake PID依序可信zombie、live noncandidate、candidate B start-usec改變：最終instanceChanged拒絕且checksFinished=false，仍保留zombieObserved/zombieExcluded/noncandidateExcluded/instanceChecked/instanceChanged=true，conflictObserved=false；metadata四次、path兩次、零args。驗證aggregate早停不抹掉前面實際排除，也不冒稱全部完成。
4. B raw comm的NUL後bytes改變、B從live變SZOMB，以及A的comm16-byte無NUL但name有效：分別classificationChanged／classificationChanged／metadataInvalid拒絕，checksFinished=false；敏感PRIVATE fixture未進public stdout。Name有效不能遮蔽其他required raw欄位無法驗證。

### Freeze與限制

9/9 source leaves直接核相符；本輪三個新freeze為：

| validation相對leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `c36e0959b35b6f4ed45fd91ec752053a0e308017f5969cafbfda61c7c3618108` |
| Tests/test_live_protocol.py | `d302bef7a93032f1cf13de9f3f1a4c01a43be607a926144054f03aa839b05a62` |
| README.md | `d4deaeeae5207b4c4b55fbd95c9528157631a99baabe4b0c9490132e721ddb9d` |

其餘六host葉（main/PBX/兩scheme/Info/entitlements）逐檔等於LG17已列完整freeze。PID+starttime不是不可偽造／形式唯一token；兩端一致仍有中間exec/ABA與postcheck新process/exec殘餘。UID列表無complete flag，checksFinished/processCheckComplete只代表本次有界契約完成，不是原子完備snapshot、歷史退出／無寫或cleanup權限。**Reaped仍guard**，故不保證下一次真人prelaunch一定可過。

只append本原evidence與自身LG23 row/交接，不改source、tests期望、production、其他六host葉或他人verdict。未讀寫真人context／oldroot/manifest/identity/current/source snapshots／任何歷史收據；未其他worktree/E007、真launcher CLI／全UID scan／App／xcodebuild/sign／DPK/SecItem／新assets/security設定／新ready/namespace或舊root清理。普通fixtures自然收尾；真launch仍停止，先交LG24獨立成果審查，不自動派生下一段invoke。


## LG29 Tester：path返回失敗單次同PID後查獨立驗證（2026-10-22 07:14:17 UTC）

**Verdict：approved；required fixes=[]。** 僅交LG30獨立Reviewer，不代真人／host歸屬或DPK驗收／新freshready。先讀README/design、LG26/P01–05、LG27最後approved/fixes=[]、LG28完成交接及實際runner/tests/README。追加前evidence bytesSHA=`6592e61759f6ad8cf9aa369a358ab5c1ce49b6c8f6784dbea0c591ff1ccbac7f`；全部歷史、LG25原stdout/Human0全程觀察、Python mismatch及copied sleep -9未知限制保留。

### 獨立執行與凍結版本

- 原命令沿兩RIVET fake-binary變數與`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py`：**122/122、exit0、0 skip、6.314s**。原114＋8 case、publication／fsync反例／Human binding／sentinel／quota與Swift22診斷/12operation fake paths保持。既有SDK staticassert與單known native child只隨正常full-suite入口執行一次；本輪派遣明確允許該existing case，未另重做layout／spawn native lifecycle fixture或任何額外native probe。沒有重新編Swift／host。
- 兩changed Python AST parse/compile：2 passed；`ruff check --no-cache --select F,E9 --ignore F401` runner/tests：All checks passed、exit0，未改lint政策或安裝工具。
- 9/9 validation葉直接核SHA一致；既存fake-only binary仍`e602ac7fc350af883b1aec0e0e4420fc0f41a8cadece49fab579a8f12ecf056b`。三修改葉：

| validation相對leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `5a05d52836ccf7c5dadd1968cf69685ec46a5e3af39004ed6fc64c6445e0d8a5` |
| Tests/test_live_protocol.py | `46ef326d66a81fbde7bdc6ebb58bcd1b07d0fa1c49b260f5139e91e28132f898` |
| README.md | `81783d041a47ed6a48866a0c8b29e485536caef7ba78578152b32894244dc459` |

其他六main/PBX/兩scheme/Info/entitlements逐檔等於LG17/LG23完整freeze，沒有改host/production或原context。未讀寫真人root／manifest／identity/current/source snapshots／任何歷史收據。

### P01–P05 source與assertions

只在可信live candidate A後、first/second的原proc_pidpath**完成返回≤0**，同PID進單次既有arg1 fullinfo；API exception／成功後其他guard／真host/open衝突不進branch。Pass由caller明傳，不靠global calls或aggregate推定。無path retry、額外argv、UID重讀、等待或production loop；zombieSame後continue結束該PID，不再讀第二path／normal B。

原path native return後立即將errno放本地collector，再保存原四guard值。Post用另一observer及full-size/time/status可信後的本地identity比較資料；原PID/ownUID驗證仍拒絕不符，未把partial metadata交作permission。只有A/post同PID/UID/start且post可信SZOMB才排除；新instance即使zombie、liveSame／class變動／denied／zero／invalid／unknown仍guard。Post自身errno/guard不覆蓋原path四值或實得finite pathErrno，查不到只稱unavailable。

Actual CLI assertions核first/second各postState、sameinstance zombie才continue、原四path keys/errno、不再normal B與call counts；舊metadata callcount2→3是原兩筆metadata後增加已批准的單次post，`run_native_guard`仍明確assert exit1／D absent／commands空，沒有改成放行或弱化原拒絕。名字predicate與原alias/prefix排除策略不動；nameMatchKind只取A實際使用name/comm欄位及真31/15截斷界線作觀測。

五key pathFailureEvidence固定投影default/reset，在pre-D／trusted-D launcher stdout皆序列化最後一筆path失敗事件；published machine/caller/Human、observe與其他CLI及atomicpublication不擴。跨PID先前processEvidence aggregate與本failure event分開，nested原path與後續外層guard各保真，不曝PID/UID/starttime/name/path/argv/error/env或任意errno數字。原八key aggregate／checksFinished語意保持；舊stdout不補欄位。

### Tester獨立有限負例：4 tests／7子例、0 failure（0.086s）

全沿既有ordinary unittest fixture、actual main CLI dispatch及全fake ctypes providers；沒有真listpids／launcher／App，也未改repo tests／期望。

1. **跨PID最新second-pass負return**：第一筆path ENOENT→same-instance zombie恢復；第二筆first path成功、second path return-1/EACCES，post再0/ESRCH。必guard，最新nested精確為pass=second/postState=unavailable/nameMatchKind=full/pathErrno=EACCES，pathFailure四值為snapshot-path/returned/negative/permissionDenied；外層也保持原path四值，不被post ESRCH覆寫。保留早先zombieExcluded但checksFinished=false；list2/metadata4/path3/args0，D absent、zero spawn。
2. **恢復後遇非path失敗**：第一筆ENOENT後zombieSame，下一PID初始metadata denied。外層snapshot-metadata/permissionDenied，而nested仍保留最近first/zombieSame/ENOENT與原snapshot-path/notFound；list2/metadata3/path1/args0，無新path事件或歸屬混淆。
3. **API exception不是native≤0返回**：first/second各EACCES exception都維持原exception guard，pathFailureEvidence仍defaults、不做post。metadata僅A一次，path恰first或second次、args0、D absent/spawn0。
4. **不同identity的新zombie不得排除**：post分別改PID、UID、start-usec並status=5，三者皆postState=instanceChanged且zombieExcluded/checksFinished=false；list2/metadata2/path1/args0，無D/spawn。不把另一instance的zombie當原candidate已退出。

### 限制與交接

本修補只在單次失敗path之後取得有界正向metadata；reaped/permission/unknown/liveSame等仍可能阻擋，不能保證真人snapshot可用或把LG25歸因特定PID／kernel原因。PID+starttime與端點一致性仍非形式唯一／原子證明，exec/ABA/postcheck殘餘、UID列表無complete、無nonce hostConfirmed/attributable=false及DPK/cleanup/S08停點維持。

本Tester只append原evidence及更新自身LG29 row/交接，不改source/tests期望／作者或Reviewer判定。未真launcher CLI／全UIDscan／額外native probe／App／sign/build／DPK/SecItem／安全資產／新ready/namespace／原context操作或cleanup／其他worktree/E007/Git／新agent。只交LG30獨立成果審查，沒有自動live授權。


## LG34 Tester：離線launch-report binding獨立驗證（2026-11-03 03:48:47 UTC）

**Verdict：needs-rework；required fixes=[RF-LG34-01]。** 本輪驗證已完成；只交LG33 Implementer同contract最小回修，不交LG35或真人／newcontext／signedbuild。原144 green不涵蓋下列獨立失敗反例，不能以suite通過宣布準備完成。追加前evidence bytesSHA=`a63b059a0bf357a23230dc475ce5bf18a1794f90e1613418f9810ecb9f61b744`；所有舊needs-rework／成功／unknown／Human／原roots歷史保留。

### 已完成的必要檢查

直接讀LG31/LB01–06及RF-LG32-01兩private schema、LG32最後approved/fixes=[]、LG33交接及四葉actual source/assertions。9/9 freeze符合（四修改葉＋其餘五模板），新unsigned fake binary與普通scratch `rivet-lg33-fake-66hy5ve1`的build-freeze.json/command.txt/compile-final.log匹配：compileExit0、sourceSHA等final main、binary實讀SHA一致、命令指向本source／現有四target objects／該output，log空。此次reuse該binary，沒有重編、下載依賴或建立App／簽章。

`PYTHONDONTWRITEBYTECODE=1`，三個RIVET fake-binary變數均指上述同新source unsigned CLI，再跑既有`python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py`：**144/144、exit0、0 skip、5.307s**。含122舊regression＋22新case、Swift15 shared launch-binding cases、原22診斷／12operation fake paths；既有SDK／單known child只隨正常suite一次，未額外native query/fixture。AST parse/compile兩Python=2 passed；Ruff `--no-cache --select F,E9 --ignore F401`兩檔All checks passed；`xcrun swift-format lint --strict`及`swiftlint lint --strict --quiet --no-cache` main單檔皆exit0。

### RF-LG34-01：觀測到wall clock逆轉但仍高於created時，錯誤通過freshness

- 契約：technical-spec LG31「遇…觀測到時鐘逆轉皆unknown/拒絕」，LB02明列clock reversal；不只是禁止時鐘小於request createdAt。
- 實際source：runner `binding_launch`的兩次inspect只核`created <= start <= hooks["wall"]()`，wait／settle只核wall>=created，沒有記錄並比較前一次已觀測wall。Swift共用`LaunchReport.execute`也只檢wall>=created／start<=wall；同一契約適用此參與方，不能把高於created的回退當正常。
- 獨立反例沿`Tests/test_live_protocol.py::LaunchBindingControls`、actual main binding-launch dispatch＋全fake hooks，在ordinary unittest scratch執行；沒有App、open、真metadata／PIDquery或正式R。新測試`Counterexample.test_observed_wall_reversal_above_created_still_must_reject`的wall觀測offset實得`[0,10000000,5000000,5000000,5000000]`微秒，T為request createdAt。第二次instance核對的wall已從T+10秒退到T+5秒，但仍高於T及report start。
- **實際錯誤結果**：liveInstanceVerified=true、bindingMatched=true、binaryVerified=true、ACKPublished=true、finalPublished=true、failureKind=none；fake-only hostAttributed仍false（這個fake-only界線有守住，不能拿它掩蓋freshness錯誤）。獨立1 test／1反例於0.042s **FAIL**：`self.assertFalse(result["liveInstanceVerified"])`得到True；未修改期望為成功，也未將counterexample加到或修改受測repo tests。

最小可重現函數（繼承現有ordinary fake fixture並只選此方法，沿既有module載入）：

```python
class Counterexample(LaunchBindingControls):
    def test_observed_wall_reversal_above_created_still_must_reject(self):
        base = 2000000000000000
        samples = iter((base, base + 10000000, base + 5000000))
        self.hooks["wall"] = lambda: next(samples, base + 5000000)
        _, result = self.cli()
        self.assertFalse(result["liveInstanceVerified"])
        self.assertIsNone(result["ackSHA256"])
        self.assertFalse((self.root / "attempt/ack.json").exists())
```

**Required fix（限此單一RF）**：runner與同contract Swift共用host在各自protocol invocation內保存上一個已觀測wall，任何後續wall低於該值即有限fail-closed，保留原clock／monotonic界線與已記native/error，不發布後續ACK／host.final或成功旗標。不改受限trusted-clock／同UID惡意／ABA威脅模型，不建一般clock framework。新增上列「下降但仍在created以上」actual-runner回歸，並在Swift共用fake入口驗對應above-created逆轉不發布host.final；保留現有跌到created以下的case與所有原144 tests，不用放寬期望消除反例。回修後獨立複驗新freeze／所需checks；本Tester不修source或代作者判通過。

### 其餘已查範圍與證據限制

已讀exact request/report/ACK/final及consume/machine keys/types/nullability/native success矩陣、owned canonical/no-follow讀取、固定pending→fsync/directory fsync→no-clobber link、pair inode/bytes與quota partial-spent assertions；新Swift selected入口由sentinel或任一新env先選入，env全失亦不落legacy store。LaunchReportHooks只有檔案／自身binary／processmetadata／clock／ACK等待，沒有store/provider/SecItem/SecTask能力；原入口及publication歷史不改。Suite覆fake完整鏈但始終不attributed、UUID/nonce/native0缺報不成功、兩次獨立fake instance/path、ACK/final錯鏈與timeout、原rc/signal保留及machine publication fail finite unknown等。這些檢查不能抵銷本RF。

Opaque build/signing proof的hash只驗bytes，預期signed-host來源、identity／有效期與external approved runner/context freeze仍由未來trusted operator核實，非工具自算approval。未來proposal已具體列新R/context九source snapshots/fixedApp/build+signproof、原CLI四必要參數與ready-confirmed、signedbuild/signature核實後才freeze finalbinary/context再freshready的順序；**本RF未解除前不能視為可前進**，本輪沒有新正式R／inputs／ready，舊N缺失不阻離線且未補造。真LS env傳遞、signedhost attribution及提示UX均未驗；正常時鐘、trustedoperator／同UID惡意、exec/ABA/postcheck及非原子殘餘仍適用，DPK保持停止。

### Finalfreeze（本輪受測版本，待作者回修）

| validation相對leaf | SHA-256 |
| --- | --- |
| Sources/main.swift | `888f43980394f1a4479ef1546d7e14ad979acaec6e068b4714d52c85abfe6560` |
| scripts/credential_storage_live.py | `4d3047a6892b5b2240644aad64b05d3f2a09c3f830eae41d0fcfb496fd36fca9` |
| Tests/test_live_protocol.py | `94deadb322e59a70164771efd24bcbe9083b4a67c816ba766d6548233c48cd7c` |
| README.md | `1c85cb4f0131f2c6aa1324cd99d51182bc37c583b0d1fc35546c3d64361f48c8` |

Unsignedfake binary SHA=`4ea16475ca154f1eb56643f4591efcb921979ee473642d4bec15d46b19fe13b8`。其他五PBX/兩scheme/Info/entitlements逐檔等於LG30freeze。本Tester只append原evidence及自己的LG34row/交接，未source/tests期望／他人verdict或舊history改動；未新agent／真launcher／全UIDscan／App／signedbuild／DPK/SecItem／安全assets／新formalcontext/ready或舊root cleanup。已停止，不擴新probe或其他反例。


### LG34 RF-LG34-01 bounded獨立複驗（2026-11-03 03:52:33 UTC）

**最新verdict：approved；required fixes=[]，RF-LG34-01解除。** 原LG34 needs-rework與原反例FAIL歷史完整保留，此段只回查同一clock-reversal contract及最終source適用checks；不是撤回原finding或用新期望掩蓋。可交LG35獨立Reviewer，未授新正式R／signedbuild／App或DPK。追加前evidence bytesSHA=`6635d0734b5d7da5cb491c3195ee733cc355222a0e8b10bd058e082830dce89c`。

直接讀LG33最新RF交接與actualsource，runner在每次`binding_launch`內以local last_observed_wall/observe_wall記錄每次壁鐘觀測，type=int且正值，後續須>=前次；Swift `LaunchReport.execute`另有該次local lastObservedWall/observeWall，從request created起核第一觀測後，獨立維持自身序列。兩participant沒有共享clock狀態或改OS clock；等值容許。所有原wall觀測位置改走有界observer，monotonic30秒、正常protocol、quota/publication、native/error保留與零credential入口不變；未增加query/retry/kill或clock framework。

**新編譯證據才是本輪綁定：** 普通scratch `rivet-lg33-fake-66hy5ve1`，只用`build-freeze-rf-lg34-01.json`／`compile-rf-lg34-01.log`與原精確`command.txt`核對：compileExit0、sourceSHA等最終main、binary實讀SHA相符，RF log空且argv指向該source/output。未沿舊build-freeze.json或舊binary當新證據，本輪reuse最新unsigned fake CLI而未重編；不當signed-host證明。

#### 獨立重跑

- 三個RIVET fake-binary變數均用此新binary，`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s validation/github-oauth-credential-persistence/Tests -p test_live_protocol.py`：**146/146、exit0、0 skip、5.310s**。含原144、兩個above-created reversal actual-runner回歸，Swift sharedfake新17cases、舊22 diagnostic／12operation，以及正常suite原SDK/單knownchild一次；沒有額外native probe或重複hostcompile。
- Swift共用fake的`clock-reverse-before-report`樣本為T+10秒→T+5秒；`clock-reverse-before-final`為T→T+10秒→T+5秒。Actual `--self-test-launch-binding`在同full-suite內執行，兩case呼叫正式`LaunchReport.execute`，共用assertions要求execute不完成且host.final不存在；完整constant/equal clock case仍完成。未以Python抄寫host流程代替。
- 原Tester獨立反例**原期望**再跑，wall offsets精確`[0,10000000,5000000]`：現在liveInstanceVerified/bindingMatched/hostAttributed=false、ACK SHA=null、ACK/final均未發布，finite failureKind=instance，沒有繼續取第四次wall。另獨立equal-clock固定T的完整fake鏈：bindingMatched/liveInstanceVerified/binaryVerified/nativeSettled=true，failureKind=none、hostAttributed=false，spawn1/inspect2。**2獨立tests、exit0、0 failure、0.045s**，未改repo測試／期望。
- 兩Python AST parse/compile=2 passed；既有F/E9 Ruff no-cache=All checks passed；main的strict swift-format lint及strict SwiftLint no-cache皆exit0。無新scope／工具安裝／全域設定或額外廣測。

#### Finalfreeze與交接

| validation相對leaf | SHA-256 |
| --- | --- |
| Sources/main.swift | `421648eb28456bb43bdaa0e6082e8dfe09f0a329cd7c10f6fe9892f2fdec042b` |
| scripts/credential_storage_live.py | `bff4d6b609fe9880f92dc081252ad5560b10fe9293e26f08ff972751d8c5c879` |
| Tests/test_live_protocol.py | `47cf4c827bbe6b25555dfb958e9ac28b4c8a6a0e583750f531ff988dd5a0b264` |
| README.md | `21eb46c83978b999b6d03417bdc5499cb599bc3d063f473e81c67f1cc65784b2` |

新unsigned fake binary SHA=`61452d70f3231a2cded3c5ed170690bc9500b067fded9973622102013ba5052a`。其餘五模板逐檔等於LG30原freeze，9/9符合。僅對已觀測wall非遞減作有界檢查，不推未觀測時刻或抗OSclock攻擊；trustedoperator、正常時鐘、sameUID惡意／exec-ABA/postcheck及簽章來源外部凍結限制保留。Fake-only永不hostAttributed，opaque signingProof hash仍不自證approval；真LS環境、signedhost attribution與UX未驗。

本Tester只append原tests evidence及自身LG34row/結果，保留原needs-rework／失敗反例、作者／Reviewer及所有其他歷史；未source/原context/oldrun/history改動，未新agent、App/open／全UIDscan／signedbuild／DPK／新formalcontext/ready／安全assets或cleanup。交LG35獨立成果審查；未執行future proposal，不能將本approval當live授權。


## LG39 Tester：profile-free purpose-only工具獨立驗證（2026-11-04 03:14:18 UTC）

**Verdict：approved；required fixes=[]。** 僅交LG40獨立Reviewer；不是signed App／OS可啟動性／真private-key使用／LS傳遞／hostAttributed或DPK驗收。先讀README/design、LG36/PF01–05、LG37 approved＋Human採用、LG38完成交接及四葉actualsource/assertions。追加前evidence bytesSHA=`61071e4b0a571099ac712d798441d727d23bfdd79870e6e76aa5147a206b036a`，先前所有needs-rework／成功／unknown／Human與原146版本歷史保留。

### Finalsource/binary與實際執行

四修改葉及其他五模板9/9 SHA直接核相符。普通scratch `rivet-lg38-fake-7vq_7wn7`的final-build-freeze.json核sourceSHA等最終main、default/variant兩binary實讀SHA皆等記錄、compileExit均0，兩個compile-final.log皆空；default.command.txt及variant.command.txt指向同source與各自output，variant獨有`-D LAUNCH_REPORT_ONLY`（選項位置在swift-version之前，按實際合法argv核對），default無此flag。未先重編或用舊binary代新模式。

完整必要selector（沒有執行SDK/UID廣測或機械重跑原146）：

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=validation/github-oauth-credential-persistence/Tests \
  RIVET_PROFILE_FREE_PROBE_BINARY="$LG38_FAKE/Probe-variant" \
  RIVET_LAUNCH_BINDING_PROBE_BINARY="$LG38_FAKE/Probe-default" \
  RIVET_DIAGNOSTIC_PROBE_BINARY="$LG38_FAKE/Probe-default" \
  RIVET_FAKE_PROBE_BINARY="$LG38_FAKE/Probe-default" \
  python3 -m unittest test_live_protocol.LaunchBindingControls \
  test_live_protocol.ProfileFreeCodeVerification test_live_protocol.SwiftLaunchBindingOperations \
  test_live_protocol.SwiftProfileFreeVariant test_live_protocol.SwiftDiagnosticOperations \
  test_live_protocol.SwiftSharedOperations
```

**獨立37/37、exit0、0 skip、1.090s**。含新Swift共用22launchbinding cases／原22diagnostic／12operation fakes、variant實際unsigned CLI七類拒絕及proof/verifier與受影響binding/clock/ACK/final/native/publication回歸。所有command/metadata/signature providers皆fake；沒有真codesign/security/Keychain/openssl／真PID或UIDscan。AST parse/compile兩Python=2 passed；F/E9 Ruff no-cache All checks passed；main strict swift-format lint與strict/no-cache SwiftLint皆exit0，未改lint政策或安裝工具。

### PF01–05查核

- **Purpose hard fence**：實際`#if LAUNCH_REPORT_ONLY`頂層直接且只呼叫LaunchReport.run，沒有legacy/default/fake入口fallback；正式共用execute先核唯一sentinel，再拒未知RIVET env，兩新env依exactinput核。Variant七類實際呼叫（無argv／三舊fake入口／legacy request／unknown／envloss sentinel）皆非0且stdout/stderr空。共用22正例／負例測actual proof與dispatch；LaunchReport hooks只具檔案、selfbinary/selfmetadata、clock與ACK，無store/provider/SecItem/SecTask capability。舊credential程式仍存在於source不代表新variant有可達入口；沒有把去掉entitlements本身當purpose fence。
- **Exact proof**：host/runner各驗兩proof exactkeys/types/purpose/profile-free/mode、ordered DEBUG+LAUNCH_REPORT_ONLY、fixedsource九hash、build→signing→context/selfbinary鏈。缺/多/錯型/nullable／非empty claims/profilePresent／wrongDER／模式混用／舊opaque DPK proof及context hash錯綁均拒絕。Fake-only永不attributed，簽署來源／actual external review仍不由proof自填互證。
- **Static/dynamic verifier**：static核固定App no embedded profile、Info/BID與frozen PBX expected BID、原DER/class/date/Team、codeID／DRcanonical hash、empty entitlements。Dynamic每次以**同reported PID數字target**送codesign strict-v／display／entitlements／requirement／DER extraction，不以App路徑代替；再與frozen signing的DER/Team/codeID/DR比對。唯讀本機codesign(1) man確認decimal target表示runningPID dynamic validation、至少-v加fullstatic，並列process entitlements display範例。這只是官方工具契約的本機文件核對，**未執行真codesign，也不聲稱真OS政策通過**。Signature不明／identity mismatch／deadline不通過，既有雙metadata/kernel-start/path/freshness與ACK前deadline核對保留。
- **原certificate selector準備**：fake publiccertificate query只固定login與已選certificate family，DER SHA256先pin、用途OID/EKU/date/Team解析後才導出SHA1。Fake assertion確認準備argv用SHA1（不拿DER SHA256充selector）、不給entitlements、錯DER在decode前拒絕；helper只回private argv，不sign、不用privatekey或改trust/ACL。實際原DER來源／當前trust/sign-use仍未在此核實。
- **保持原協定**：request/report/兩次instance＋dynamic核/ACK/final/native settle及最後原bytes publication，clock lastwall／monotonic、partial quota與fake-only界線不退步；targeted assertions含原rc/signal/finiteerror保留、無回報/timeout或machine寫入失敗不成功。不重跑未變SDK/其他146歷史，不把37稱全repo pass。

### 少量獨立風險負例（全fake）

沿既有LaunchBindingControls ordinary fixture／actual main entrypoint，另**2 tests、exit0、0 failure、0.045s**：

1. 第一次dynamic成功後改fake kernel start-usec，第二次metadata讀回漂移；兩次callback均只reportedPID、各有positive remaining deadline，最終liveInstanceVerified/bindingMatched/hostAttributed=false，ACK SHA=null且未發布ACK。Dynamic有效不能掩蓋instance變化。
2. Dynamic callback在原remaining為正時耗至fake monotonic31秒，即使回傳成功，原ACK前deadline仍拒絕；只一次inspect/dynamic，live/binding/attributed皆false，無ACK。沒有延長deadline、retry或kill。

這些未改受測tests/期望，不調任何真PID、OSclock、App或安全資產。

### Freeze與交接界線

| validation相對leaf | SHA-256 |
| --- | --- |
| Sources/main.swift | `2fd43e08f6c43cd3ee91edbc649ae97a7062aace8315bcfdc19435de2889f766` |
| scripts/credential_storage_live.py | `b12a752362831433c5a9d8210324fd51145f83294dc0f4a40bdc312a1977c902` |
| Tests/test_live_protocol.py | `ae5729a4e8f20b7479c06dd09e640b27476351e364efa08a55744d24143026fc` |
| README.md | `fa9da261ac82fdd5f19790f556b99e731ebc61b6451f14920ac5bd715e435666` |

Default unsigned CLI SHA=`ae26e19127c4f73f996090f09affc0b62ed68a667a4da8a6f73cd1fa336f33da`；variant unsigned CLI SHA=`4432db55463655b159a6d0e63815ed9ddb61afeb605b032804872c1b3d4bd7f2`。其餘五PBX/兩scheme/Info/entitlements逐檔等LG37/LG30freeze。

尚無可簽署unsigned .app／實際sign-verify-context-launch輸入是**正常待LG41 routine preparation**，不是本輪code blocker，也不是現在要求Human操作。先LG40獨立審查，再由受限LG41把owned unsigned產物／exactidentity與caller具體化；實際publiccert/auth/私鑰sign/簽後verify/newcontext/LS仍需既定集中Human窗口與具體授權。FakeCommandProvider及此37tests不是signedApp pass；normalOS政策、既有certificate當前來源/適用性/trust/sign-use／UX未證，sameUID惡意、exec/ABA/postcheck殘餘與DPK停點維持。

本Tester只append原evidence及自身LG39row/交接，不source/tests期望或他人verdict／原history改動。未新agent、Keychain/security／真codesign/openssl／私鑰／sign/資產變更／真UIDscan／App/LS／newformalcontext/ready／DPK／oldroot cleanup／其他worktree或Git；必要fixture收尾僅ordinary fake temp。交LG40，不自批操作階段。


## LG47 Tester：certificate split parser／SP01–05獨立驗證（2026-11-04 04:04:12 UTC）

**Verdict：needs-rework；required fixes=[RF-LG47-01]。** 只回LG46 Implementer同contract最小修補，不自行改parser／契約／受測期望，也不交LG48／query/sign。原41green與下列獨立green保留，但不能抵銷shared postverify的stdin接線契約FAIL。追加前evidence bytesSHA=`7ed52a83eea0edbb9b174b104202cebfb27d494e6cb37af2652ae47e591ac7e4`；LG43仍unknown、原因未確認，原Human0與整個窗口已結束，不回填。

### 已完成獨立必要檢查

先讀README/design、LG44/SP01–05、LG45approved/fixes=[]、LG46交接及實際三工具葉。Source三新＋main/五模板未變的9freeze全符；LG43 parent op/pending同inode/bytes、oldcaller/config/prepfreeze/buildproof/consumed與原private九source hash皆符，兩App完整tree仍`e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614`。未改任何原App/buildsource或父資料，newcontroller與immutable oldbuild provenance分開，沒有假重建。

獨立selector：`PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=validation/github-oauth-credential-persistence/Tests python3 -m unittest test_live_protocol.CertificatePreparationControls test_live_protocol.ProfileFreeCodeVerification test_live_protocol.LaunchBindingControls` → **41/41、exit0、0 skip、0.320s**。AST parse/compile兩Python=2 passed；Ruff既有`--no-cache --select F,E9 --ignore F401`兩檔All checks passed。Main未改，沒有compile/build、重跑不受影響Swift／原146／SDK或任何native query。

41涵蓋actual config key形狀與真sign-preparation helper（只native provider fake）、三argv與stdin/options、RFC2253 escaped comma/plus/hex、duplicate subject／多OU／非法escape／缺日期classEKU/OID／wrongDER與path/BID/profile拒絕、native rc/signal/timeout/exception與有限nullable證據、零codesign以及binding quota/clock/ACK/publication適用回歸。這是fake證據，不是LG43實際decoder或原certificate真實資料。

### 額外3項獨立檢查：0 failure（0.034s）

1. 同一`CertificatePreparationControls` realistic fixture含issuer OU／text Subject OU／獨立subject記錄，載入**immutable原build的實際old controller helper**，以fake DER pin與fake subprocess output執行old `binding_sign_preparation`，取得預期Rejected（old combined argv同時dates/subject/text，一次call）；不mock整個helper。隨即在相同config/temp形狀執行new actual helper，三固定call成功且只採獨立subject Team，無codesign。這重現工具舊缺口，不證LG43歷史原因。
2. Dates/class兩個較晚decoder實際fake return7：通過之前subject/date的flags保留，失敗點為對應Decode、decoderPart正確、decoderOutcome=nonzero/code7，未parse欄仍null；CalledProcessError原returncode/private stderr保持，有限evidence不含PRIVATE。只fake subprocess，不執行回傳sign argv。
3. Ordinary **NoApp proof/data層** fixture：保留unsigned original與原build proof/source bytes不變，fake sign確實改controlled binary bytes，使用新signed proof/binary hash、同原buildproof建立純fake context資料；現有`binding_context(..., mode="fake-only")`與proof互綁接受新binary，原unsigned hash與final hash可不同且original仍不變。這只證source/proof相容性，**不是尚未存在的LG49 actualcaller跨phase測試**；LG49仍須真實NoApp caller fixture驗sign前unsigned、context/launch核新signedhash，不能每phase要求copy仍unsigned。

### 唯一RF-LG47-01：shared postverify未把已pin DER送stdin

**明文契約**：SP01要求subject/dates/class三份固定argv「都只stdin同一已pin DER」，且postverify/dynamic共用同一嚴格解析。新sign-preparation default decoder有遵守；shared `binding_code_identity`亦確實改用三份新parser，**不是退回combined解析**，但其local decode/run接線不符合input契約。

**實際source與入口反例**：`binding_code_identity`的run wrapper先require options["input"]==raw，隨後丟棄此input，改成`command([*arguments, "-in", str(leaf)], ...)`。預設`binding_code_command`的subprocess stdin是DEVNULL；因此真正openssl不讀先前已pin的raw bytes，而是再次按檔案路徑讀取。不能用上層options看似input相等宣稱底層stdin已綁定。

獨立沿`Tests/test_live_protocol.py::ProfileFreeCodeVerification`、actual shared `binding_code_identity`＋fake command provider：三個decoder的`fileInputPresent=[true,true,true]`、combinedOutputFlags=false。`PostverifyInputContract.test_shared_postverify_preserves_fixed_stdin_decoder_contract`要求無file-input代替的assert **FAIL：1test／0.032s**。無任何真openssl／codesign／PID查詢；這是受審helper真接線差異，非環境問題／簽章結果／已發生安全事件。

最小反例方法（繼承既有fake command fixture，只選此方法）：

```python
class PostverifyInputContract(ProfileFreeCodeVerification):
    def test_shared_postverify_preserves_fixed_stdin_decoder_contract(self):
        live.binding_code_identity(4321, command=self.command, timeout=3)
        decoders = [c for c in self.calls if c[0] == "/usr/bin/openssl"]
        self.assertEqual(len(decoders), 3)
        self.assertFalse(any("-in" in c for c in decoders))
```

**Required fix（唯一）**：共享postverify的native wrapper真正把同一已pin DER `input=raw`傳到底層openssl stdin，三個part保持SP01精確argv，不以`-in file`重讀代替；保留bounded remaining/10秒、固定C locale/OpenSSL config、native rc/stdout/stderr/exception handling，不能改成空成功或放寬class/date/subject/DER標準。補回歸須穿過真shared wrapper與native command adapter，僅fake最底層subprocess.run並捕捉實際stdin bytes/argv/options；不能只assert上層options或mock整個wrapper就稱修好。原41與3獨立green保留，反例期望不改。Tester不代修，也不自行解釋降低SP01。

### Freeze與後續界線

| validation相對leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `faff8159a43706c622c9c64d793238493d2a951ec6b839548ec1ce8155ae1905` |
| Tests/test_live_protocol.py | `b464a0ee916b382f7fa6a6205e5a91b777ad7989ba99e7cd296f9c774242cf49` |
| README.md | `88468b62aa2b7d29efccf55ae5f99581bd10be92b1db86633a6311957ae52850` |

Main仍`2fd43e08f6c43cd3ee91edbc649ae97a7062aace8315bcfdc19435de2889f766`與五模板等LG40。Parent LG43 operation SHA=`d123529e216fd44ffdce0bfd4b82343e6851a00996513b9abefc1d37af5edf26`、consumed=`18c0df133b5b7c050909787d52484aed543ef48f3be44ca6e1ddca0e686e8df6`、原caller/config/buildproof/九source及雙App均未改；舊ready不可重用。SP03actual amendment caller/config/controller仍正常LG49待備，不捏造已測actual phase producer；其newreviewedtool freeze／oldAppbuildproof分離及futurecontext只能新成功amendment鏈的契約仍需LG49/50完成。沒有Human欄位或ready需求。

本Tester僅append此原tests evidence與自身LG47 row/交接，未改source/tests期望／他人verdict或原history。未真Keychain/query/openssl/codesign/App/context/DPK/cleanup、buildcompile／資產變更／新agent或Git。全部native只有fake providers，ordinary fixture正常收尾；停止交root→LG46 boundedfix，不擴其他反例或框架。


## LG47 RF-LG47-01 bounded獨立複驗（2026-11-04 04:11:11 UTC）

**最新verdict：approved；required fixes=[]，RF-LG47-01解除。** 原LG47 needs-rework、41green＋3獨立green及stdin反例FAIL全部保留；本段只審最小stdin接線回修，不回填LG43歷史原因。

### 實際重驗結果

- 選擇器：`PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=validation/github-oauth-credential-persistence/Tests python3 -m unittest test_live_protocol.CertificatePreparationControls test_live_protocol.ProfileFreeCodeVerification test_live_protocol.LaunchBindingControls` → **44/44、0 skip、exit0、0.313s**。
- 兩Python AST parse通過；`ruff check --no-cache --select F,E9 --ignore F401`兩檔All checks passed。Main／模板未變，未重編Swift／App或重跑未受影響146。
- 讀實際shared `binding_code_identity`：DER extraction後先read/pin；三part呼叫同parser，其local run核raw bytes與pin、exact argv、input exact bytes，再以原options直送`subprocess.run`。不走general adapter的DEVNULL，不加`-in`重讀；remaining deadline裁切每call最多10秒。rc／signal／timeout／OSError沿共同decoder保留；44包含wrong bytes/type/argv底層未呼叫及原native失敗回歸。一般codesign/csreq adapter未被本修補改寫。
- **原反例獨立重驗：1/1、exit0、0.008s**。沿`ProfileFreeCodeVerification`原fixture／actual shared helper，僅patch最底層`subprocess.run`，分別給fake PID及fake App target；不mock整個wrapper。兩種target皆3 decoder，逐項assert exact `binding_certificate_arguments(subject/dates/class)`、無`-in`、`type(input) is bytes`且等pinned fixture DER、三次同一bytes物件、無stdin key、capture_output=True、固定LC_ALL=C／OPENSSL_CONF=/dev/null、0<timeout<=3。另assert text/universal_newlines不為true、encoding/errors均None；與bytes stdin相容，mock沒有遮住text=True型態錯誤。原反例的無file-input期望保留，觀測點下移真正subprocess邊界以吻合實際adapter。

### 最終freeze與原資料

| validation相對leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `3511c3f4d42e8ee2016cb0c9c28b36691c35d653eb8c77a6f32e0f7ecbd5ebc9` |
| Tests/test_live_protocol.py | `9c6de3cd9bd5f0fdd4f6eaf3252127e91a38ae87ad7d30ef6b7574591ebb6602` |
| README.md | `1ac021d7b3199fb6b6bcf331f9b18569720ec4ec23886d92d7fd5f173d945ea5` |

三新＋main/五模板未變共9葉直接核符。Parent caller/config/prepfreeze/buildproof/operation/consumed六檔exact SHA仍符；operation與pending同inode/bytes。原private source9逐檔等原config；雙App binary仍`ad1e4f4fdb2b9da08603aa969d58a5bc6b6830775922cc67b087bff6871d1a0b`，依原caller完整tree算法唯讀計算兩者仍`e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614`。未import/執行舊caller，也未改原provenance。

SP02九欄有限schema與nullable/native failure語義未擴；README同步寫清stdin接線及原歷史界線。SP03新reviewed三工具／immutable oldbuild九source分離保持，先前NoApp data-layer相容性證據仍適用；這不是LG49尚待製作的actualcaller/config/controller跨phase證據，不能用本approval代替其prepared proof或LG50審閱。

僅交LG48獨立Reviewer；不是query/sign／原privatekey可用／signedApp／context／LS／hostAttributed或DPK驗收。未真Keychain/native certificate/openssl/codesign/PIDquery／App／build／新context/ready／DPK/cleanup、未source或tests期望修改、未新agent或Git；原LG43unknown/Human0及ended readies不變。本Tester只append既有evidence與自己的LG47 row，其他owner verdict保持。


## LG55 Tester：LG52 A–E／F交接邊界獨立驗證（2026-11-04 07:17:14 UTC）

**Status：completed；verdict：approved；required fixes=[]。下一步LG56獨立Reviewer。** 已讀README/design、LG52 spec A–F/RTT01–06與plan九欄、LG53獨立approved/fixes=[]及LG54 actual source/測試/編譯交接。只四既有工具葉受測、原root/收據/history唯讀；本approval是受限offline工具成果，不是LG51根因歷史認定或新signedApp／LS／hostAttributed／DPK通過。F之actual privatecaller/newApp準備仍按LG57/58，不以尚未到該phase當本code blocker。

### 最終來源／binary與實際selector

| validation相對leaf | SHA-256 |
|---|---|
| Sources/main.swift | `d9d3aa68d4f006f2d273e9eb41346446645d89a8df8f1183da7cae04a63f5328` |
| scripts/credential_storage_live.py | `1591468a2de9878cd0d39c6d9c3b4a45c845ee84290d29c882df143c3f553bb1` |
| Tests/test_live_protocol.py | `b1ac37798a44ffad1a5f39cb0a865ee3e067da80ad6c3cd088022f3a548bf2f4` |
| README.md | `8264f2c6cbe8f04a8d17c555958dfe581e428c7dabea38c345eeeffd5d0f5c5e` |

四葉直接hash符合；其餘五PBX/schemes/Info/entitlements仍等原pin，共9/9。Ordinary compile basename `rivet-lg54-compile-i3l4zxd0`的compile-source-sha.txt等finalmain，兩command.json實際source參數均該main、-o各指對應CLI，診斷stderr空，binary實讀SHA核符：default `40ce8e4c9e69660639197af3bfdc32342a8660f0d4a6488a498ce31a2ec64ad5`，variant `3b3206682b7b5626817c99a285ba6afd9704b0197ea42e0369a35471f29e94ce`。Default沒有LAUNCH_REPORT_ONLY，variant有；普通CLI不強套未來App build的DEBUG flags條件。未重編final雙CLI，使用已核來源的實際binary。

從validation/Tests執行README exact五selector：`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest test_live_protocol.LaunchStartupControls test_live_protocol.LaunchBindingControls test_live_protocol.SwiftLaunchStartupControls test_live_protocol.SwiftLaunchBindingOperations test_live_protocol.SwiftProfileFreeVariant`，兩binary env分別指上述final CLI，RIVET_CAPTURED_REPLAY_SOURCE指原LG51context唯讀。**40/40、0 skip、exit0、1.413s**。涵8 startup/28 binding/2 actual startup/1 Swift binding/1 variant；Swift binding實際跑source列明28 cases，不以Python合成host成功替代。既有finite非App Python child自然exit7，真Popen.poll保rc；沒有真App/open／UIDscan。

AST parse兩Python=2通過；Ruff `--no-cache --select F,E9 --ignore F401`兩檔All checks passed；`xcrun swift-format lint --strict`及`swiftlint lint --strict --quiet --no-cache` finalmain皆exit0、無輸出警告。未新增豁免或重跑未影響146/44/37。

### A–B：獨立原core red、rawbytes真FS與self-native

先逐byte核原replay source：去除僅`lg54Trace = <line>`與其宣告後，driver前core完整等原main2fd43至原`#if LAUNCH_REPORT_ONLY`分派前；未改guard條件。另核finalmain在隔離LaunchReport之前的整段legacy prefix與原source逐byte相同。只LaunchReport修canonical/no-symlink語義，未更動legacy DiagnosticProbe。

本Tester**自行重編一次原trace core**（不是重建App）到ordinary basename `rivet-LG55-red-compile-3jyjruw3`，同原xcrun swiftc/object recipe，只換owned source/output/module-cache，compile exit0；新binary SHA=`da5a5be3c501d7062501b9b5680f832532825582e7df2c4aeafc9c4b1d5772f4`。另普通fixture `rivet-lg54-replay-mkg4chfh`原樣copy原source/App與五raw JSON，沒有重serialize原JSON。自己的原core replay exit0但finite passed=false、originalGuardLine=714、privatePrefixAlias=true、derived/directory/requestURLCanonical=false、schemaNSNumberEncoding=q、schemaIsCFBoolean=false。這是固定舊guard決定性拒絕的red證據，不是期待成功測試，也**不能認定LG51歷史首先到此**；歷史argv/env仍未觀察。原rawfiles及原root前後hash未變。自己的scratch保command.json／source／compile與replay stdout/stderr/input-hashes.json，僅ordinary fixtures不屬正式namespace。

新版40 selector中的captured replay使用同五原rawbytes、歷史clock與最低executable/instance/ACK hooks，真Swift bootstrap/schema/digest/FS/proof/context/source到report/ACK/final完成；actual Swift產生entry，不是Python fake report。真Foundation的NSNumber整數／CFBoolean／fraction與字典比較、root/file mode／nonowner／symlink／size／type拒絕均由真API跑。Self-native只getpid自身：原SDK proc_bsdinfo fullreturn、UID/PID/status/start/usec checks通過；不推任何他PID或OS lifecycle因果。

### C–E：實際接線與4項獨立風險負例

實讀新core：exact五argv優先、env完整pair僅bootstrap fallback；兩channel缺/partial/mismatch/unknownRIVET一律不得成功。先可信owned output／rawSHA/schema後exclusive entry，wire/fullcontext/proof/source/binary/instance/clock/ACK失敗才有限failure；無trustedpair只有finite stderr。entry/failure nullable instance僅實取得才填，並非nonce認證；variant compile硬fence只LaunchReport，不到store/provider/SecTask/SecItem。完整原success前提與wall reversal、兩次instance/dynamic、ACK/final/native settle/publication仍必要，新success另需entry非null/failure為null。

Runner真argv保持fixed -W/-a、兩env、App與native streams分開、五hostargs且無-n。App snapshot≤65536才hash，oversize只size；unreadable/null及exact schema受檢。Native每wait與finally非blocking poll，已settled不再poll；已知rc/signal保留，native0不代report或attribution。所有public projection只有有限欄/hash，PRIVATE fixture/rawerrors不外漏。

在ordinary `LaunchBindingControls`沿actual main／binding_launch，最低providers fake，另外只選4個獨立方法，**4/4、0 skip、exit0、0.151s**：

1. Fake spawn保留有效report但移除自己的entry pair：不得ACK、不得inspect、entrySHA=null、hostAttributed=false；新entry確實是必要條件。
2. 發布same-pair但requestSHA錯綁的failure：拒絕於診斷驗證，failureSHA不採信，零inspect／ACK／attribution；不以failure的存在放寬binding。
3. Missing report時poll第一次回0，第二次若呼會OSError：實際只poll一次，原rc0/nativeSettled=true/nativeExceptionKind=null保留，整體仍timeout/unknown。這驗已settled結果不被晚期poll抹掉。
4. 完整fake鏈到native wait，注入TimeoutExpired：finite nativeExceptionKind=timeout/nativeSettled=false/returnCode=null，hostAttributed=false，public輸出無PRIVATE原error。未kill/retry。

這4方法沒有修改repo source/測試期望，也不mock整個validator成功；原40既有native spawn/poll errors、signal、partial publication、clock與wrongproof/identity回歸保持。原shared certificate parser本輪未改，不額外native解碼或重跑其44。

### 原資料與路由限制

收尾再核四新＋五未變source；原LG51 sign/context/launch operations、machine、request、context、signproof共7固定SHA均仍原值，原context private source9與原signed binary=`a8f4502d8df8a637675ab3894e1d80f1296b599573307e0b719c1387c9d24fd6`未變。LG51仍launch unknown/report-timeout/nativeSettledfalse/hostAttributedfalse，Human原文全窗口「全程觀看0次權限申請」保持，不補歷史機器或更動spent。新正式child context尚不存在。

**交LG56 Reviewer；required fixes=[]。** 本輪只有unsigned CLI及ordinary fixtures，並無新unsigned App；LG57須依既定manifest製新main對應App/buildproof/source9／完整actualcaller/config/NoApp跨phase，LG58再獨立審，真正sign/context/LS只最後新Human窗口。不得拿原signedApp充新host；公開DER readonly準備與原key/identity/trustACL停點不變。未sign/Keychain/privatekey/query、LS/App、DPK、cleanup原root、kill/-n/reset/retry、新正式namespace/context/ready或新agent；只append本existingevidence與自身LG55 row，所有needs-rework／unknown與他人結果保留。


## LG63 Tester profile獨立驗真（2026-11-04 08:54:05 UTC）

**Verdict：needs-rework；required fixes=[RF-LG63-01]，只私有copy目錄mode。Profile技術有效性全部true，無profile內容／CMS／信任鏈／device blocker。** 固定七leaves owned0600、取得root0700與rawhash／inputs-before-after-consumed來源核符；pending是原操作前schema，不要求與final同inode。原operation SHA7ef09d84dbbb7cd2eabe99a65b3908252b873f4a7a8eca05439545a5e0d87497／after d9f10f5353208eddd4d7cd44c7e763fd0d772a5815fb921f54025ba46c3b384f／profile88ec674b614b3400203013a0d6b6c79c83bfc8516ec6eac4a49cefb00ae58026保持。原operationunknown不覆寫成success；新獨立驗真結果在ordinary owned0700 basename `rivet-LG63-profile-validation-5oshrbkc/result.json`，SHA4314e75e0461d0d4c409ef4c488cc170a62b354fbe3b52a802b67e8cd55ecf4e。

必要SDK/header與Apple primary policy source核後，純Python ctypes呼原生CMSDecoder：Create/Update/Finalize=0，signerCount1，**CMSDecoderCopySignerStatus(evaluateSecTrust=true)** 配平台macOS provisioning profile用途policy OID1.2.840.113635.100.1.40，OSStatus0、signerStatus=kCMSSignerValid(1)、certVerifyOSStatus0、SecTrustResult=unspecified(4)、chainCount3。此policy核Apple anchor／macOS profile leaf marker1.2.840.113635.100.4.11／WWDR intermediate marker／digital-signature usage與有效期，不以BasicX509或noverify解碼冒充Apple用途。CMSsignatureValid/appleSignerTrusted=true；沒有新增trust或讀私鑰。依SDK定義，只有CopySignerStatus才實際驗signature/cert；Apple來源：[API](https://developer.apple.com/documentation/security/cmsdecodercopysignerstatus%28_%3A_%3A_%3A_%3A_%3A_%3A_%3A%29)、[policy source](https://github.com/apple-oss-distributions/Security/blob/main/OSX/sec/Security/SecPolicy.c#L3019)、[policy identifier](https://github.com/apple-oss-distributions/Security/blob/main/OSX/sec/Security/SecPolicy.list#L46)。

只從同一已驗signature decoder取content。原DER bytes exact inclusion且DeveloperCertificates恰僅原pin5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440，原publiccert strict split class/date/Team核符；Team/AppID與固定BID/codeID、由profile真ApplicationIdentifierPrefix推exact group（不猜prefix=Team）、group授權／平台OSX全部true。creation2026-11-04T08:43:09Z≤驗證時2026-11-04T08:51:14Z<expiration2026-11-11T08:43:09Z。只本機SPHardwareDataType取得唯一Provisioning UDID，對ProvisionedDevices exact匹配true（deviceCount1），不用hardwareUUID替代；raw hardware資料只同scratch私有文件，public只bool/hash。來源：[Apple裝置識別要求](https://developer-mdn.apple.com/help/account/devices/register-a-single-device)。原標準位置profile rawbytes與固定candidate相同；未provision/refresh/build/sign/App/DPK/context/cleanup。Profile中僅原cert不能推全Keychain／遠端無新增或原cert未撤銷。六原source hashes及copy main/Info/entitlements核未變，修改PBX等after記錄。

**RF-LG63-01（唯一）：** LG60明文要求取得紀錄本目錄及子目錄ownUID0700，但owned `profile-acquisition-1/project/`及Xcode自生metadata部分子目錄為0755/0777，共11目錄；本取得root與七固定原資料檔已符。精確相對path／目前mode/dev/inode清單只在上述private scratch `mode-deviations.json`（SHAafc7553f504a585f0e5c602640b81d5663d2ed1f8b6371e5ed9051ca317609ce），不在public洩漏user metadata名稱。交Implementer最小chmod：只清單中的sameowned/no-symlink現存目錄設0700，先lstat/核UID與原scope，不follow symlink、不chown、不動profile／文件bytes或系統資產／Keychain私鑰ACL，不新增 framework或retry取得。保存七leaf及profile/source/原history hashes；修後Tester只重核此RF目錄mode/原bytes，不重跑CMS/Apple/device或取得操作，再交LG64 Reviewer。外層0700存在不抹消此明文偏差，也不推profile無效。

Human assetstage原文「全程觀看 0 次」只綁原LG62 operation：promptCount0、wholeObservedtrue，actions未另報不補none；詳原live-validation LG63追加。這不是DPK提示UX驗收。只append自身evidence/row，未改實作／原收據或資產，不新agent；完成即停交root→Implementer最小RF，不延伸調查。


### LG63 RF-LG63-01 bounded複核（2026-11-04 08:56:24 UTC）

**Status completed；verdict approved；required fixes=[]，RF-LG63-01解除。** 只讀fix-receipt SHA`dec8ded1ccc4da48f8b1afbff2e6d556c7df12815e874c392e223742589e7eed`及原private清單，逐一lstat核11原目錄同dev/inode／ownUID／no-symlink／0700；七固定leaf含profile原SHA全未變。Receipt亦記11/11、no-symlink traversal、未chmod文件或原資產、無provision/build/sign/launch/DPK。原技術結果SHA`4314e75e0461d0d4c409ef4c488cc170a62b354fbe3b52a802b67e8cd55ecf4e`未變且allProfileTechnicalChecks=true；原needs-rework與RF歷史保留。Human原文「全程觀看 0 次」／actions未報範圍保持，不重跑CMS/trust/device或新profile取得。只交LG64獨立Reviewer，不代DPK execution或topic完成；本Tester只追加自身evidence/row讀回後停止。


## LG68 Tester bounded affected驗證（2026-11-04 09:38:13 UTC）

**Verdict needs-rework；required fixes=[RF-LG68-01]。** 已讀README/design、LG65 DK01–06、LG66approved及LG67 actual source/交接。四葉SHA、ordinary `rivet-lg67-compile-33eclkpi/final-freeze.json`與三unsignedCLI binary/source/command/模式flags相符，compile diagnostics空；未重編。作者exact十selector自行重跑**54/54、0skip、exit0、1.374s**（DPKControls/DPKWire/DPKInstanceControls/SwiftDPKChecks/LaunchBindingControls/CertificatePreparationControls/ProfileFreeCodeVerification/SwiftSharedOperations/SwiftLaunchBindingOperations/SwiftProfileFreeVariant），四binary env皆該finalsource新CLI。AST2、Ruff F/E9 no-cache、strictSwiftformat/SwiftLint皆exit0。只ordinaryfixtures／finite nonApp child、DPK共用core fake store與既有guards，無真codesign/App/DPK/context/profile操作或無關146/CMS/純launch重測。54不是LG70五phase／fake sign改copy／Rebuilt actualcaller整鏈驗收。

**唯一RF-LG68-01：前段report沒有綁到前段已驗machine。** `scripts/credential_storage_live.py::dpk_stage`讀前段machine/human後，再讀`binding_published(root,"host.report.json",previous)`只要求存在，未核report SHA等machine.reportSHA256，未依前段machine核report exact schema/同B，即把report交previous_gone後可delegation下一phase。這使『已證退出的是前段實際host instance』失去受驗鏈，與DK04/05 exact previous instance/freshness不符。

獨立actual入口反例 `Counterexample.test_previous_report_must_match_verified_machine_before_process_query`，沿existing DPKWire真ordinaryFS/paired publication/完整fake save-a產生machine後，保machine及綁其SHA的whole Human fixture不變；只將同inode有效report pair內容換成另attemptUUID/PID，使report digest明確不同於machine.reportSHA。再給valid read-a ready，以fake previous_gone避免真PIDquery、末端binding_launch spy避免新spawn：**本應Rejected、observer與downstream皆不得呼叫，實際未Rejected，1test FAIL／0.215s**。原schema/core/readers未mock；僅最低native/hooks及最後下段spy fake，未改受測source/期望，沒有真DPK或他PID query。

重現要點：`machine,machineSHA=binding_published(...,save-a)`；保同inode reportpair但改`pid/attemptUUID`，assert新reportSHA != machine.reportSHA256；valid Human綁machineSHA＋wholetrue；actual `dpk_stage(...,read-a,ready,hooks)`仍前進而未Rejected。**最小fix**：任何previous_gone／下一phase呼叫前，要求前段machine屬當round/預期previous phase；report digest==其非null reportSHA256，且`binding_validate("report",report,前段machine的完整B)`通過（含round/phase/context/request/binary）。錯SHA、錯B或invalid schema須零previous process query／零next launch／不消耗下段。新增穿actual stage/真pair的該反例與有效前段仍通過回歸；不新增framework、不放寬原native/ownership/Human/deadline。

回Implementer普通bounded code fix，非Human停點；本Tester不修source，原54green不解除RF。修後只原RF/適用checks複核，再交LG69 Reviewer。Deadline10:06:29Z含Human等待不變；五phase與Rebuilt完整實作準備仍LG70，任何A→exit→freshA→wholeB→freshB→真rebuild→freshB及逐段Human未完成均整體未通過。只append自身evidence/row，原history/profile/assets不改；停止新cases/live。


### LG68 RF-LG68-01 bounded複核（2026-11-04 09:42:09 UTC）

**Completed／approved；required fixes=[]，本RF解除。** 新runner/test實讀與rf-lg68-01-freeze.json相符；main/README/三binary等原finalfreeze，未重編。Actual stage先核previous machine屬當round/previous phase，要求reportSHA==其非null reportSHA，再以machine完整B驗report exactschema，全部通過才previous_gone/下段delegation。

只重跑DPKWire **1/1、exit0、0.244s**：真ordinary FS/paired predecessor機器＋Human fixture，合法前段可observer/delegate一次；換report同inodepair但不同digest/B則零observer、零delegate、無下一phase目錄。另獨立保留原反例期望，以fixture更新後同actual dpk_stage換PID/attemptUUID：**1/1、exit0、0.227s**，錯SHA確實Rejected且零query/delegation/下一phase目錄。沒有真PIDquery／App／DPK。AST2/Ruff通過；原54green、FAIL及needs-rework歷史保留，不重跑廣測/crypto/舊API或編譯。

只交LG69獨立Reviewer；五phase＋fake sign變副本＋Rebuilt完整actualcaller NoApp與雙App準備仍LG70，不能由此稱整鏈/live已通過。Deadline10:06:29Z不變，Human未授live，無sign/context/profile/Auto/newcert/trustACL/Git/cleanup。只自身evidence/row追加讀回，停止額外測試。


### LG68 static evidence-mode delta複驗（2026-11-04 10:01:51 UTC）

**Approved；required fixes=[]，只source delta。** 實讀兩行接線：`binding_verify_static(...,mode="signed-host")`原default保持，將mode傳既有proof validator；AST逐一核CLI add_argument無fake開關。指定`StaticEvidenceModeControls`＋既有`DPKWire` **2/2、0skip、exit0、0.308s**：真sharedvalidator／僅最低command fake，default拒fake且零native、explicitfake-only通、invalidmode拒且零native；先前合法phase及wrongreport零observer/delegate/nextdir仍通。PublicDER僅既存pin副本讀取／離線解碼，不Keychain或CMS/trust重驗。

新runner/test實讀SHA等noapp-mode-delta-freeze.json（該檔flat leaf schema）；main/README/三CLI另核原finalfreeze均未變。AST2/Ruff通過，無compile/全suite/UI/sign/build/context/LS/DPK。原54/RF FAIL與approved歷史保持；LG70 candidate僅unsigned準備，完整五phase/Rebuilt NoApp尚未通，不當ready或整體完成。Deadline10:06:29Z不延長；只自身evidence/row讀回後停，交獨立Reviewer窄source回查。


## LG70-T Tester：offline NoApp里程碑（2026-11-05 03:07:11 UTC）

**Status completed；verdict approved；required fixes=[]，僅offline里程碑。LG70整體仍pending，非liveReady。** 先讀現行README/design、LG70交接及LG68/69 source approval，實讀97行重跑腳本、202行actualcaller與NoApp Swift driver。Handoff freeze SHA37851765dbcb9b76dbb5f36f67d0148ead1cee378a55dc82918f631f694d6499全部file hashes核符；caller/config/controller等handoff。Compiler proof SHA689d21091f88530e9d350ea1cc890dbfa2960237acc1a889ae99ed081e2fa41f及兩unsignedNoAppCLI command/source/output/模式/空diagnostics核符；NoApp.swift前112361bytes逐byte等凍結production main，prefixSHA2cb335d1cd1a8045cf55476e2774e9d043f4e1799e458091e8af82e2e3c84640。額外只有DPKValidation時鐘primitive alias及testentrypoint，未更改真cutoff或OSclock；controller synthetic dpk_time adapter只在隔離fake-only module。

安全讀碼確認sign/codesign僅最低command fake追加副本bytes，rebuild最低build fake產新binary；nativeidentity/clock hooks fake、store明確FakeProbeStore（不走真SecTask/SecItem/adapterKeychain）。固定open argv/env由spawn hook轉成兩ordinary unsignedCLI、自有finite children自然wait，不執行open/GUI/App。其餘caller/parser/schema/FS/正式Probe.perform/ownership/report→ACK→final／previous-machine-report同B流程實際走；沒有mock整validator。原DER僅公開bytes解碼，無Keychain／CMS重驗。

獨立重跑已pin腳本`lg70-resume-noapp-chain.py`（SHA4182f0429694b91135b9e4b3ee2422cb6500f46c66719249a3201f46bc106ad7）帶原compiler ordinarybasename `rivet-lg70-noapp-compiler-1miqc3p1`：exit0、stderr空，**15actions/5runtime全code0、各operationVerified=true但hostAttributed=false/fake-only**。新ordinary fixture `rivet-dpk-noapp-yixb90rx/operative/result.json` SHA`bbb8b89315f17d7c7d79c9082a6f9efdac70197ef801e6c6cab8c67a49c51505`，records.json保15步。順序sign-debug→context→saveA/observe→freshA/observe→wholeB/observe→freshB/observe→fake clean rebuild→sign-rebuilt→context-rebuilt→rebuiltfreshB/observe；native child逐次自然結束。兩fake sign確實改副本，rebuild確生新binary/context/build+signproof，固定App位置替換前把舊App保留retired-debug，未刪原產物。這是真core對fake存取/身份/時鐘/簽章/建置的離線鏈，不是真DPK／真signedhost／真rebuild驗收。

額外只1項必要獨立once負例：在本人fixture再呼actualcaller的spent runtime save-a（新fakeUUID/typed offlineclock），code1/unknown/guard，零nativecallback，operations所有file hashes完全未變。收尾再核handoff全files未變、原production round仍absent且operative production operations空；原profileAbsent red與原候選／buildsource9/歷史保留。未跑舊expiredlive命令、未重55suite/CMS/profile取得／純launch，未新正式namespace/context/ready、真sign/App/DPK/provision/Auto/trustACL/Git或kill/cleanup。

**交獨立Reviewer只審本offline milestone。** 新live authority/入口/deadline最小契約尚未設計，不當此離線結果RF，也不能由此復活2026-11-04窗口。完整本次真人A→exit→freshA→wholeB→freshB→真rebuild→freshB與各段Human未執行，整體DPK仍未通過。Tester僅追加自身原evidence與附屬LG70-T row，未改Implementer LG70 pending或他人verdict。


## LG76 Tester：NW01–06 affected source驗證（2026-11-05 03:40:47 UTC）

**Verdict needs-rework；required fixes=[RF-LG76-01]。** 已讀README/design、LG73 exact schema/NW01–06、LG74 boot RF approved及LG75 source交接。四葉final-freeze、三unsignedCLI compile-final/command source/output/互斥模式與binary SHA均核符。獨立執行已先靜態讀安全邊界的`lg75-affected-checks.py`：**70/70、0skip、exit0、2.542s**；AST2/Ruff/strictSwiftformat/SwiftLint皆exit0。Ordinary capture basename `rivet-LG76-checks-od445t8y`保存author原generated log/result備份及tester本次log/result，不覆原history/收據。未重編／新profile/真App/簽章/DPK或CMS驗證。

Factory/descriptor/human/authority exactschema、once/partial、synthetic boot/UTC/continuous-mono、legacyexpired及authority→round/context/B/proof wire與舊reportSHA/同B回歸已有70green（Swift實際9DPK＋14window core cases）；這不代表所有native邊界都已受保護。新schema15-action/fullRebuilt actualcaller與雙App仍LG78待備，非本gate已完成/liveReady。UUID/hash/operator聲明不是人類認證／同UID惡意防禦；本輪不建立真人authority/window/ready。

### 唯一RF-LG76-01：shared public decoder繞過window邊界

`binding_verify_process(...,window=...)`只把傳入command（codesign/csreq）包成`window.native`。其實際shared `binding_code_identity`中的三個openssl decoder直接`subprocess.run(arguments, **options)`，沒有傳／核verified window；最後回傳也沒有window成功接受guard。因此最後extract command後若boot/clock已變，即可繼續postverify native且該次verification仍回成功，違NW03每native及成功接受前重核boot/time。不是publicDER解析本身錯誤，也不是可放寬no-new-action原則的理由。

**獨立actual入口反例：** 沿`ProfileFreeCodeVerification`真sharedvalidator與底層fake subprocess，先取一致expected identity，再開`DPKWindowControls` ordinary synthetic window；呼`binding_verify_process`時只有fake extract command返回後將sample.boot改成不同hash，UTC/mono保持合法。觀測：crossBootRejected=false、**postCrossBootDecoderCount=3**，函式未Rejected而返回；`Counterexample.test_cross_boot_after_extract_rejects_before_decoder_native_and_acceptance` **1test FAIL／0.042s**。沒有真native簽章、boot/PID query、Keychain或DPK；只是最低command/native fake，未mock整validator。期望是Reject且0個後續decoder。

**最小required fix：** 將同一已驗window/phase真正傳到shared decoder native邊界並在每個decoder開始前核boot/UTC/mono/remaining；成功接受identity前也重核，涵最後native期間變更。保留SP01同pinned bytes stdin/精確argv/binary flags、原timeout/native rc/例外（不以後guard抹掉已失敗native），report-only及無window舊行為不放寬，CLI不新增fake/clock flag。補穿真shared wrapper/最低subprocess的此反例及合法window仍通回歸；不需新框架或真資產驗證。Fix普通source接線交Implementer，非Human排障；本Tester不修source。

原70green與此FAIL並存，不能以70放行；修後bounded複核再LG77 Reviewer。只有offline gate，LG78 fullcaller/App/NewHuman authority仍待準備受審；舊window/結果/artifacts/readies/spent全部保留。只自身evidence/row追加讀回，停止新cases/live。

LG76已執行反例原樣保存於ordinary私有capture `rivet-LG76-checks-od445t8y/counterexample.py`；selector `Counterexample.test_cross_boot_after_extract_rejects_before_decoder_native_and_acceptance`，PYTHONPATH沿validation/Tests；只保存既有反例、未新增／再執行case。


### LG76 RF-LG76-01 bounded複核（2026-11-05 03:46:07 UTC）

**Completed／approved；required fixes=[]，RF-LG76-01解除。** 實讀shared decoder現在每part都經同window.native provider，保SP01 pinned DER bytes stdin/精確argv/options與剩餘timeout；每part後、identity/static/process成功接受前再核window/boot/clock。Native原失敗先保return/exception，不用後guard抹掉；report-only／無window分支未放寬，CLI AST核無fake/clock開關。

本Tester重跑原保存counterexample.py（含其繼承shared-native回歸）**12/12、0skip、0.055s**；原反例現在crossBootRejected=true／postCrossBootDecoderCount=0。另只指定3個window新回歸＋stdin/native原失敗2項：**5/5、0skip、0.039s**，合法window三decoder、subject後boot變更拒後part、最後class native後expiry拒成功、同一input bytes/timeout與rc17原stderr保真皆符。再獨立1case兩subcases：subject native內boot變更並分別throw TimeoutExpired/OSError，**1/1、0.007s**，捕獲同一原exception物件，只有1decoder。全部最低native fake，未真boot/資產query。

AST2/Ruff通過；rf-lg76-01-freeze.json四葉相符，新runner/test/README實讀等交接，main及三CLI等原compile-final，未重編/全73suite/CMStrust/UI/新asset/DPK/live。原70green、FAIL/needs-rework與所有歷史保留。只交LG77獨立source Reviewer；LG78新schema完整actualcaller/15-action-Rebuilt NoApp及兩App仍待準備，沒有真人authority/window/ready或liveReady。本Tester只自身evidence/row追加讀回，停止額外cases。


## LG81-Cap-T Tester：fixed hardcap amendment（2026-11-05 05:59:37 UTC）

**Completed／approved；required fixes=[]，只離線cap準備。** 實讀parent-linked cap-amendment-1 actualcaller/config/descriptor/OPS及freeze（4528405fd24e13400227f233355f2cca767e119d940500c58af636b9e7364248）精確pin皆符；source/controller/main/App/schema未改。新private `--deadline-cap`只允初次record-ready/sign-debug，須等config pin06:48:07Z；真路徑用kernel sample與actual time_ns，floor(cap-now)整秒，>270且≤3600，兩expiry承接原ready而不隨factory延後，各後續action再核cap。Synthetic clock/sample只fake-only test boundary，無production fakeclock CLI。

獨立重跑`lg78-cap-checks.py` **6/6、0skip、0.781s**：actual CLI/factory fractional floor、delayed open不延end、invalid/expired/too-short/nonUTC/over60、missingcap、nonwindow cap、partial/once及legacy no-cap行為。另1個獨立actual CLI負例：有效日期但不同於config pin的cap，**1/1、0.093s**，拒絕且零human/authority/consume/operations。未mock整validator。AST2/Ruff三私有腳本通過。

`lg78-cap-noapp-chain.py`帶原compiler獨立重跑exit0：**15actions／5runtime均operationVerified=true、hostAttributed=false/fake-only**，actual record-ready/open factory與完整A→freshA→wholeB→freshB→fake rebuild→rebuiltB走通，authorityend≤synthetic cap。新ordinaryfixture `rivet-dpk-noapp-9ezfcqht/operative/result.json` SHA0177150395445a6d8135fdae06b604851c4dfd3cfb855e842339cfc6eb712c13。Lowest native/clock/boot/store/identity全fake，原core/FS/schema/Probe.perform/ACK/final未整體mock；無真codesign/open/App/build/DPK。原failed producer/parent bytes與新freeze皆保留，所有parent hashes收尾仍符；真candidate round/Human/ready/authority/consume absent、operations/phase-ready仍empty。

交獨立Reviewer只審actualcap＋scope，不表示新freshready或真人開窗/sign。原RO段已停止，等待Reviewer後root再取freshsignready；scope/policy grant只在外部05:48:07–06:48:07Z原window，不重算新1小時，過hardstop不開始新操作。只自身evidence/附屬row追加讀回；未source改動、重profileCMS/73suite/資產或新live。


### LG85 獨立文件收尾驗證（2026-11-05）

Verdict：**needs-rework**；required fixes=[RF-LG85-01]。只核 LG82/CD01–05、LG83 approved 與 LG84 實際文件；未執行舊測試、author script（其會覆寫作者結果）、build/sign/App/DPK/cleanup 或 Git mutation。

- 獨立讀取 actual diff／D 六文件與 publication，另以 inline Python Path/urlsplit/hashlib/subprocess 唯讀檢查：7份文件、61個相對 target（含 Markdown heading anchor）均存在；trailing whitespace、本機 absolute path、private-key 區塊及 GitHub token 樣式有限掃描零 finding。`git diff --check` exit0、無診斷。
- 作者 unchanged-before／after 的21 readonly leaves逐一重算 hash全符，包含8 code/template leaves；main=`78eede7ec1132d7dc84d6762d0e61c737d6eac9e51950b623194fda05b680213`、runner=`b4e28abb50c348f93870aadb4ad6256805c275039c7242530cb7fa19c8d40916`、tests=`f0b5f63a15a09b23dd22db15a0d06f67ac28b07d9ab248ff9025413efb7d3b80`，舊圖bytes不變；兩個個人metadata hash與checkpoint相同且排除stage。兩個正式source與adapter tests仍同HEAD；live-validation原SHA `5f4f959b4362f672d3c151450fc7160cd2af015767189de57ae9726410351c27` 未改。Index空。
- 四artifacts現在摘要與LG81-Cap-R／closeout路由一致；原L05/L06 unknown/pending與S08、Human visual、未cleanup及五個未整合conflict均保留。Publication只有本地PR/message草案，明列API差異及不得merge/rebase/remote write；DPK指定環境假bundle與fake-provider停止契約／非真OAuth分開。
- **RF-LG85-01（唯一）：** `docs/architecture/github-oauth-dual-client.md:23` 現行「責任與依賴」組合圖文字仍為 `OAuthCredentialStore adapter（DPK，fake-only verified）`。此處不是後面的實驗歷史章節，與同檔剛更新的指定環境DPK驗證成立矛盾，未滿足CO01/CD02現在式準確。最小修正僅更正文字符號標籤（保留provider/adapter責任、驗證限制與原歷史），不要改source/API／凍結圖。回修後僅核該一行與文件有限checks，不重既有suite/live；未通前不交LG86。


#### LG85 RF-LG85-01 bounded 複驗（2026-11-05）

Verdict：**approved**；required fixes=[]，RF-LG85-01解除，前輪needs-rework及已通檢查歷史保留。實讀現行label已改為「指定環境假憑證 DPK 已驗」，指向同頁正式adapter段，provider rotation／persist-stop另標假backend；與相鄰正文／LG81-Cap-R及原S05/S06界線一致，不擴真OAuth或所有環境。

實際doc SHA=`ed7fe11066eecec9f7d1cacc0378df621aeff8b5cf613c6a5675bf89378a5ee0`。獨立於記憶體將此唯一新label還原舊label，重算恰等原author result快照SHA `14038dc4e4f05e8a30a4cb9149ee6bac2c547ec7b4596d7d8fb928a72a509702`，證明精確一行delta；其餘五D文件與publication逐一hash等原快照，index仍空。未重跑已通checks、suite或任何native/App/DPK/cleanup；未修改受測文件/source，未stage/commit/merge/發布。交LG86獨立Reviewer，只核本次closeout成果，不代Topic完成或Human接受。
