# L04 Reviewer：真人驗證工具準備審查

- 日期：2026-10-21；Role：獨立 Reviewer。
- Verdict：**needs-rework**。
- Required fixes：RF-L04-01、RF-L04-02。
- 範圍：L-W01 九檔、technical-spec／plan §5、當前 step 與 L03 r1 準備證據；沒有讀寫他人 E007、修改受審 source／test 或執行 live。

## 已確認的準備範圍

九份 L-W01 檔案的實際 SHA-256 與 Tester r1 凍結表 9/9 相符。L03 r1 的 approved／23 tests／12 個 Swift fake checks／unsigned artifacts 核對保持其原始角色與限制；本 reviewer 未重跑測試、簽章、profile inventory、LaunchServices、SecTask、SecItem，未建立真人 runroot。

已直接閱讀公用 adapter 接線及共用 operation seams：live／fake 路徑共用 Probe.perform／performCleanup／durable file proofs，只注入 store／delete。精確 UUID namespace、absence→write-attempt→save、未 owned 零 delete、exact class/group/service/credential/DPK/sync、刪後 adapter load=nil、一次性 ready、historical UUID/PID、有限 public projection 及原 public bytes SHA 的接線均可追溯。RF-L03-01／02 的既有修正未被重開。

仍有以下必經路徑缺口，不能交 L05。

## RF-L04-01：DR hash 混入 App 位置，必經 runtime／rebuild 比對會誤拒絕

- 位置：`validation/github-oauth-credential-persistence/scripts/credential_storage_live.py:505`、`:523`，及 `:566` 的 runtime identity 比對、validate_rebuild。
- `codesign -d -r-` 的完整 stderr 不只有 designated requirement，亦包含 `Executable=...` 等 display metadata。現行 drSHA256=digest(dr) 將 App 路徑納入 DR 身分。
- Setup proof 在 derived-debug 的 candidate App 上計算；其後實際 runtime 在固定 current App 上重驗。兩路徑不同，即使真正 designated requirement 完全相同，drSHA256 仍會不同。Rebuilt candidate 又位於 derived-rebuilt，會同樣觸發誤拒絕。現有 tests 只使用已人工相同的 synthetic drSHA256，沒有覆蓋此 extraction 接線。
- Required fix：在既有 runner 中只擷取並正規化唯一、有效的真正 designated requirement 作 identity hash，排除 executable 路徑、警告及其他 display metadata；缺少或多義時 fail closed。保留相同 DR 的必要 guard，不刪除 DR 檢查或用整個輸出忽略比較。
- 必要準備驗證：以 fixture/mock 的原始 codesign 輸出經實際 extraction／inspect 路徑，驗 derived-debug、固定 current、derived-rebuilt 的不同路徑但同 DR 得相同 hash並能通過相關 guard；真正 requirement 改變仍拒絕；missing／duplicate 或無效 requirement 拒絕。不需要簽章或檢查任何真 App。

## RF-L04-02：ready 後失敗的段落沒有 machine binding，實際提示無法記錄

- 位置：同 runner `:527`–594（stage），`:601`–610（observe）。
- Stage 在消耗 ready 及開始可能顯示提示的 build／inspect／launch 後，只有整條路徑完全走完才建立 machine.json／public-machine.json。xcodebuild 失敗、child 結束但沒有 receipt、receipt／process guard 拒絕等例外會直接退出；observe 隨後要求 machine 與 binding 已存在，沒有入口記錄該段實際已發生的提示／actions。
- Export 最多將該段標 unknown，不能補回必要的 Human actual observation 與 exact bytes SHA。這不只是未觀察成功的情況：setup 簽章失敗或 App 寫入後中斷也可能先有提示／殘留，必須保留可觀察與 cleanup 的證據鏈。
- Required fix：ready 已合法消耗後，對嘗試過但中途失敗的段落也建立 exclusive、有限分類的 machine receipt 與 public binding，保留既有 private logs／absence／write-attempt proof，並回傳可供 Human 綁定的 machine SHA。不能填入未證實的 sameIdentity／validity／freshProcess／readAbsent 或 success；資料不足保持 unknown。沒有合法 ready 的前置拒絕仍不得產生成功嘗試證據。
- observe 必須能記錄該 failed／unknown attempt 的實際 count／actions／wholeStageObserved；依賴段繼續停止，同 root cleanup／recovery 仍另取 fresh ready且維持所有 ownership guards。既有 exclusive public 歷史不可覆寫。
- 必要準備驗證：以真正 stage／observe／export 入口配合 fake build／child，驗 setup build error、launch error／缺 child receipt、post-child guard failure 皆有可綁定的有限 machine bytes並能記 actual observation；不宣稱成功、不解鎖 dependent phase、不外露錯誤內容。可能寫入後的中斷保留 markers；cleanup recovery 與 final unknown immutable 的既有測試仍應成立。維持純 fixtures，不執行簽章、App 或 Security。

## 判讀與交接

除此兩項，本 bounded review 未發現需要擴張 topic 或重新決定儲存方案的 blocker。Signed build 入口採 Human 指定既有 identity／profile、Manual signing 且不使用 allowProvisioningUpdates；setup 分支沒有呼叫 App／SecItem。真實既有 profile 是否可用仍須到當次 Human ready 後核對，未以 count 或 unsigned compile 假定成立。

只交獨立 Implementer 在既有 L-W01 中回修，再由獨立 Tester 重驗受影響的 runner／projection／negative guards及必要準備 checks，回 L04 bounded 回查。不得以本 review 或 L03 r1 approval 代填 fresh ready、提示、live／cleanup 結果或 S08 Human 接受。


## 同輪 bounded 補充：RF-L04-03（未嘗試寫入的 file-only cleanup）

- 本輪完整 Verdict：**needs-rework**。
- 本輪完整 Required fixes：[RF-L04-01, RF-L04-02, RF-L04-03]。上方初始兩項記錄保留；本節補足同輪審查中的 setup／pre-write failure cleanup 入口。
- 位置：`validation/github-oauth-credential-persistence/scripts/credential_storage_live.py:670` 的 cleanup_files，以及 stage 的 cleanup ownership／build-proof 前置。
- cleanup_files 只在 cleanup／recovery machine＋Human 被分類 success 後才移除私有 owned directories。但 setup build／profile 前提失敗時沒有可用 signed App／build proof；尚未進入 save 或 absence 失敗時亦沒有 write-attempt marker。Stage cleanup 必須先取得 identity／build proof／write-attempt，故此類本來不應做任何 SecItemDelete 的路徑無法取得 success，也就沒有入口清理本輪 project／DerivedData／current files。
- Required fix：在既有 runner 的 files cleanup 控制中，增加受限 no-write 路徑。必須有合法同 run immutable manifest／0700 ownership、無仍存活或未解決的 child，並可證明沒有 write-attempt／可能已寫入；完成必要停止／final evidence 後，只刪 manifest 登記的本輪 owned files，完全不呼叫 App 或 SecItemDelete。尚未凍結 identity／沒有 signed host 不應阻止這個純檔案分支。
- 一旦存在 write-attempt、可能已提交或 proof 不足，就不能以 no-write 分支宣稱 item 已清；維持 exact owned item cleanup／fresh ready 或保留 marker、root 與最小恢復交接。原始 Apple assets、foreign files及必要 evidence／proof 必須保留，不能掃刪父目錄。
- 必要準備驗證：以一般 TemporaryDirectory fixtures 驗 setup build 失敗／未建立 identity、首次 save 前被拒絕且零 write-attempt 的 file-only cleanup，確保零 child／delete 呼叫且只清 manifest directories；有 attempt marker、仍存活／未解決 child 或來源 ownership 不明時拒絕此捷徑。已寫入後的 exact cleanup／recovery 測試繼續成立。不執行任何 live 或建立真人 runroot。


## L04 bounded recheck：RF-L04-01／02／03（Tester r2，2026-10-21）

- Role：獨立 Reviewer。
- Verdict：**approved**。
- Required fixes：[]。
- 上方原 needs-rework、RF-L04-01／02／03 及當時判讀全部保留；本節僅記本輪回修的獨立 bounded 回查。追加前 evidence SHA-256：`e45e674392297f59a8ba92650c189586b77977065c469ca39165e31b0e5149c9`。

### 回查證據

目前 L-W01 九檔實際 SHA-256 與 `live-preparation-tests.md` 的 r2 凍結表 9/9 相符。只直接閱讀受影響 runner／README／tests 及原共用操作，沒有修改受審 source／test，沒有重跑測試或兩 schemes build。Swift source SHA 未變，沿用 L03 r1 已核對的 unsigned artifacts；獨立 Tester r2 的 38/38、零 skip、既有 Swift 共用 fake checks 12/12 保持為 Tester 的實際證據，不冒稱 Reviewer 再執行。

- **RF-L04-01 已解除**：inspect_selected 從 codesign 的兩個輸出擷取唯一非空 designated requirement，以 csreq 解析成 canonical expression 後才 hash；Executable 路徑與其他 metadata 不入 identity。實際 inspection fixtures 包含 derived-debug／current／derived-rebuilt 路徑、空白差異、真正 requirement 改變，以及 missing／duplicate／無效語法；沒有刪除 DR guard。
- **RF-L04-02 已解除**：stage 合法消耗 ready 後的 build／inspect／launch／receipt／process 失敗皆形成有限 unknown machine 與原 public bytes SHA，可由 observe／export 記錄實際提示；未證實的 validity／freshness／identity 不填 true，dependent phase 不放行。Observation／export 的 owned-structure 讀取不會因 source drift 抹除已發生觀察，也不解鎖後續操作的 source guard。Launch-attempt／settled／child proof 不足時保留可能寫入材料，不啟動新的 cleanup child。
- **RF-L04-03 已解除**：cleanup 有 fresh ready 下的 files-only 分支，只在合法 owned root／manifest、無 write-attempt 且所有已嘗試 child 可證 settled、最多為 save 前拒絕時通過。此分支不需要 identity／signed host、不 launch／delete、不宣稱 item deleted／readAbsent；仍須實際 Human observation 與 final export，之後才精確清 manifest owned directories。Marker、unknown／活 child、ownership 不明均拒絕捷徑，必要 proof、foreign files／Apple assets保留；已寫入仍走原 exact item cleanup 或保留恢復交接。
- **Exact-owned-App bootstrap 符合範圍**：setup --built-app 只接受同 root 固定 derived-debug 產品；唯讀導出 identity 與 embedded profile 的私有 copy，原始值不要求 Human 貼出。凍結後仍呼叫正式 build_selected clean build並核查簽章／profile／來源，不將 manual App 當正式 source/build proof。其他 App 在工具檢查前被拒絕，setup失敗仍可記 actual observation。

### 停點與限制

此 approval 只接受準備回修，可交當次 **Human setup fresh ready**；不能視為 ready 已提供、profile／certificate 可用、簽章或 DPK／跨程序／真正重建／提示／cleanup 已通過。後續仍依八段順序各別取得 fresh ready 與事後實際 count／actions／whole-stage observation／machine SHA；未知不推零、不前進依賴段。S08 Human acceptance 維持 pending。

Reviewer 未執行 prepare、profile inventory、簽章、LaunchServices、SecTask、SecItem，未建立真人 runroot或讀寫他人工作線。準備審查於此停止，未跨 Human boundary。


## L04 窄回查：certificate CLI 與最小 private staging 提案（Tester r3，2026-10-21）

- Role：獨立 Reviewer。
- Verdict：**approved（僅本次工具修正與 staging 提案可審查性）**。
- Required fixes：[]。
- Formal setup 停點：仍待 Human 明確採用目前 profile及當段 fresh ready；本 verdict 不取代該決定。
- 原 review／needs-rework／回查歷史完整保留；追加前 evidence SHA-256：`08d7ef10fd3dbe051c8e3cea3d228f3c4ecb483a6346e6966523a927b01ea1d9`。

### 工具修正核對

直接閱讀 extract_certificate、inspect_selected／identity_from_built_app 兩處接線與其 high-level regression fixtures。共用 helper 的 argv 為四個元素：codesign、-d、單一 --extract-certificates=<prefix>、exact App；不再將 prefix 誤作另一個 code object。Prefix parent 必須是指定 private directory，輸出 leaf certificate 須存在、非 symlink且非空；原命令錯誤仍傳回拒絕。兩 fixtures 分別核對真正 high-level 呼叫的實參、順序、equals 形式與 exact App，未只以任意成功值替代接線。

本次九份 validation source SHA 與 Tester r3 凍結表 9/9 相符：runner=`25866dff13e96b002956fea1f36002f4c3bc3c2fdedc27009905af2a05695605`，tests=`d70e0aa3770436e40b6572b5a0844999f2166bbb5297053f098fc66f95b67f8a`；其他七檔維持 r2。Tester r3 的 38/38、無 skip 及沿用 exact signed App readonly CLI 證據保持為 Tester 來源，不說成 Reviewer 再執行。

由 SOURCE_FILES／PROJECT_FILES／prepare 的 manifest 建立程式可確認：runner 不在本輪 run.json 的 sources／copiedSources pins；這次 runner修正的版本由九檔 freeze／獨立 Tester／本 review 綁定，不能冒稱它早已凍結在原 run manifest。本回查不更改 manifest、source hashes或正式 adapter。

### 最小 staging 提案的受限判讀（尚未執行）

- 只關閉本輪 owned copied project 的 Xcode window，避免再次自動改寫；不關閉或變更其他 project／使用者資產。
- 只將兩份 copied shared schemes 恢復為原 manifest 所綁定的 frozen bytes；先核對原始來源 hash，後重驗原 production/package及 copied-source pins。不改 manifest、正式 source 或 Human 選定的 project signing 設定，也不以重新計算 manifest 掩蓋 drift。
- 只將同 root、已指定的 signed App 保真複製到 runner 固定 direct Debug product bootstrap 位置；來源與目的須均為本輪 owned、位置明確且不得覆寫陌生檔案。保留原 App，複製後再核對 signature／binary／profile／certificate hashes。這是 identity bootstrap 的私有產物接線修復，不是正式 source/build proof。
- 之後 formal build_selected 仍須真 clean build、source／簽章／有效 profile／certificate／AppID／group／DR／固定位置校驗。其命令明定 Manual、exact certificate／profile、無 allowProvisioningUpdates；不需要由 Agent 擅改 Human project 的 Automatic 設定，也不能將 runner Manual 改寫成 Human 先前一直使用 Manual。

上述只表示在 ownership／frozen bytes／無陌生覆寫條件下，提案符合原 private staging／source guards。Reviewer 沒有執行關閉 window、scheme restore、App copy、private staging、profile inventory或任何 live 工具。

### Human boundary 與觀察限制

依呼叫端提供的當輪 readonly facts，profile CreationDate 晚於 run；它不能被記為 run 開始前既有 profile，屬實際採用前提變更。正式 setup 前仍必須取得 Human 對此 profile 的明確採用決定及當段 ready，依真實時序保存決定，不修改 CreationDate或原 manifest、不以本 review推定已同意。後續若需要放寬原 scope／profile 前提，須由 Human 明示後按原 planning contract 記錄最小必要修訂，不能由 Reviewer 自行放寬 guard。

Human 已回報 manual 子步全程 0 次提示，僅能如實保留該觀察範圍；formal clean build／runtime／rebuild／cleanup 的提示與結果均尚不能由此推定。沒有消耗 ready、沒有正式 setup machine或 production adapter live 操作的成功判定；S08 仍 pending。

本 reviewer 未重跑測試／build、執行 stage、簽章、Run、LaunchServices、SecTask／SecItem、profile inventory或讀寫其他工作線。於 Human profile adoption／fresh-ready boundary 停止。


## L04-Retry1：Automatic cached 唯一候選準備成果審查（2026-10-21）

- Role：獨立 Reviewer。
- Verdict：**approved（僅候選工具準備）**。
- Required fixes：[]。
- 前 review／needs-rework／修訂／live unknown 歷史保留；追加前 evidence SHA-256：`ffe08f90660f22897a67c9737e0571be00a95f4c13fa5c3f804a1ab7a6b92aad`。

### 受審版本與來源

核對最新 technical-spec／plan §5.1、RT01–RT04、runner／README／fixtures及 Tester L03-Retry1 approved證據。九個 validationfiles實際 SHA-256 與 Tester freeze 9/9相符。本 reviewer接收的候選 freeze為：

- runner：`df542c92dee213ed8f04a9002b1ac467abf4424d96a8b3ac4db746b771052d55`
- tests：`750201704a87090ca1ded02ff73f565d9fd7da564abf1063a67c62bc869291b5`
- README：`d140677e309b61cb1717e3e1dbab6f6aa14fffa5e84fbe4742f6def9ee13c2bb`

其餘六檔含Swift／templates維持前版，Reviewer未重build或重跑測試。Tester的55/55、零skip、既有Swift共用fake-only12checks，保持為其獨立執行證據，不描述成本reviewer再執行。

### Code／contract 判讀

- 正式build_selected移除六個全域signing／identity overrides，沒有改加全域Automatic；沿frozen PBX的target設定。private_command在subprocess前拒絕portal/device及三個authentication-key權限flags。Cached錯誤沒有fallback／UI retry；沒有把不帶flags說成全部本機cache或assets零變更保證。
- 建置前保持frozen run／identity／PBX／profile pins、有效profile與certificate membership；產物signing檢查後，install前重驗sources／PBX及exact adopted certificate、profile、AppID、group、既有bootstrap canonical DR、source、固定location。真正rebuild再核effective setup baseline、不同binary及compiled marker。相關實際build入口fixture包括cache及各項drift拒絕install，沒有擴權或放寬guard。
- retry-setup只接受固定same-run與精確私有輸入，核原unknown/build machine及已完整觀察Human的exact SHA、無setup成功proof/current/write-attempt／後續phase／未settled child／finalized。原private direct JSON中的原ready UUID（含尚未consume的manual輸入）及已consume UUID均拒絕重用；policy schema／值／adopted為有限、明確的新政策，不能以profile採用代替。
- Exclusive0700 directory與attempt永久佔用唯一額度；directory-or-attempt共用presence控制quota／resolver／summary。Directory-only／partial／缺receipt維持retryunknown、effective=null、依賴blocked，不fallback initial、不刪除重試、不第三次。Attempt綁原failure／Human、manifest／identity／PBX／baseline DR、policy bytes、新ready及actual runner SHA。
- 新build helper的storage參數把整套retry logs／proof／machine／binding／Human留在獨立storage，原setup與manual bytes不覆寫。合法ready消耗後的失敗仍能actual-observe unknown；Human觀察不足不補0、不解鎖。
- Effective setup resolver必須retry全部guard／buildproof有效且Human whole-stage觀察綁SHA分類成功，才讓save-a／runtime／rebuild讀retryproof；不再讀缺失原proof。v1兩個新public leaves仍phase=setup；v2summary保留initialunknown與固定attempts/effective，top-level保守聚合不以retry成功抹除原unknown。
- Legacy staged controls、exact cleanup／no-write files-only／unknownchild／source guards未被本候選放寬；同rootcleanup與必要恢復proof保留。Swift共用operation／production public adapter未修改，沒有新增產品delete、OAuth、E007或其他topic。
- README清楚將reviewed-version權威留在外部獨立角色：執行者在invoke前將actual runner SHA與本次approved freeze逐字核對。Attempt內actual hash僅供稽核，harness不自證review approval，caller hash／環境值不取代外部權威。原runmanifest未pin runner的事實不改寫；沒有自我雜湊或簽章認證框架。

### 真run既存資料的有限唯讀相容性回查

只使用呼叫端明確指定的既存ownedroot，先核0700／currentUID／非symlink／解析位置一致；未跨其他root或inventoryassets。僅讀現有JSON／已指定bootstrap receipt／pins，不執行retry、preflight helper、build／signing／App或任何asset command，不產新inputs／attempt。

- 真run／identity JSON包含目前retry所需keys；manifest、identity、privatePBX、採用profile的SHA均符合程式RETRY_PINS，identity.projectSHA256存在且一致。四個production/package pins與五個copied input pins均相符。
- 原setup私有／public machine是unknown/build，Human wholeStageObserved=true、實際count=0且綁原machine SHA；原machine／Human兩個固定SHA相符。未將0提示解讀成build成功。
- 原bootstrap canonical-DR receipt實際存在，strip後SHA符合固定baseline；不依賴合成fixtures才有的bootstrapDR JSON欄位。程式以明列baseline pin比對產物，沒有要求真identity／原失敗machine具備不存在的新欄位。
- 原manual ready private輸入為可讀取的JSON、具有readyUUID，位於既有拒絕掃描範圍；原consume紀錄保留。無retry directory／兩份新inputs、原setup成功buildproof／currentApp／write-attempt／finalized或後續phase／runtimechild artifacts；不在準備期補建它們。

此有限相容性檢查不表示採用profile目前仍有效、cache可用或cached Automatic真build能成功；那些仍須在Human明確採用並給新ready後，由真正執行階段依法核對。

### 停點

候選工具已可交Human審閱：必須明確採用Automatic cached／不授portal provisioning更新但不保證所有本機cache零變更的證據界線、同run唯一retry，並提供全新當段setupready，執行者再核actual runner等於上述approved freeze後才能建立新私有輸入／invoke。Reviewer沒有代填任何policy、ready、實際retry／prompt／DPK／cleanup結果或S08接受。

本 reviewer未改受審source／tests、privatePBX／identity／manifest，未build／sign／Run／LaunchServices／SecTask／SecItem或讀寫他人工作線。於Human execution boundary停止。


## D04：最小診斷工具候選成果獨立審查（2026-10-21）

- Role：獨立 Reviewer。
- Verdict：**approved（僅 §5.2 工具候選準備）**。
- Required fixes：[]。
- 追加前 evidence SHA-256：`0a300b9542f0a2af083e2198ee2b53179af78f3dd18bba26f6c1e203555f4a93`；既有 needs-rework／修訂／真人 unknown 與觀察歷史全部保留。

### 範圍、版本與證據

讀四份 topic artifacts 的 §5.2／DT01–04／D 系列、D02 實作交接及 D03 獨立 Tester 最新結果，直接審查既有四個 validation leaves 的實際程式／README，並逐檔讀取九葉 SHA。Validation 為尚未 tracked 的目錄，未以空 tracked diff 代替 source review。九葉均符合 D03 freeze：

| 修改葉 | SHA-256 |
| --- | --- |
| Sources/main.swift | `d65f818dfbfe92726cc3e1928b161a8b783b3f84af2b3befceb5897f1223f618` |
| scripts/credential_storage_live.py | `a2834ede6d9c90b418e20c3723210c54530fe6a18ee5308edf9cb0f9a09c6907` |
| Tests/test_live_protocol.py | `1e016f12fcfc99f9f18f3ee36eb535d8dca3a902d893da9b3d9941c8cd046f53` |
| README.md | `8a14aa67d05b6036b3e301ca03b938015814b210a5e80d511b0c3fb22e0f54c8` |

另外五個 project／schemes／resources 仍符合既有 freeze。Reviewer 沒有重跑測試、編譯或用自己的 planning approval 當 code 證據；D03 的63/63、零 skip、新 Swift22診斷＋原12checks、另編最終source unsigned fake-only 22＋12及strict format/lint，僅引用為 Tester 的獨立執行結果。

### Code／contract 判讀

- Swift bootstrap 先核精確 schema／型別／UUID／purpose／manifest SHA、canonical0700自身UID root、無 symlink 的固定 App／來源位置，以及原 manifest／identity／machine／Human bytes hashes；成功後才取得 purpose 固定的 output。未通 bootstrap 不寫收據，不能藉任意 output path 落檔。既有 receipt／dangling symlink 拒絕，真正寫入採 exclusive0600 及 fsync。
- validateEarly 在可信 output context 下依 args／request／root／source／identity／bundle／entitlement 保留有限 stage；catch 只有有限 failureKind／hash／布林，沒有 raw error、路徑、argv、ID 或秘密。新 copy 依新 expectedApp／freeze 驗證，原 root 與 fixedApp 僅唯讀對照，不冒稱原 Writer 相同 binary/context 的失敗重現。
- DiagnosticHooks.live 只建立 closures；public store facade 的建構及 load 都在唯讀 closure 內。Diagnostic-only 成功與失敗皆不呼叫它，也不進原 perform 或四個 SecItem 入口。Namespace 分支由原 UUID service／group／credential／fake clientID guards 後至多呼叫一次 public credential store load，沒有 configuration／save／delete 接線。Nil 僅當下 absent；present／finite error 停止，沒有補原 absence／write-attempt 或解除 unknownchild／cleanup。
- Runner 的兩 purpose 各有固定 ready／consumed-ready／machine／Human leaves；ready purpose／UUID、manifest／binary／來源先檢，exclusive0600＋fsync consumed-ready 在 LaunchServices 前完成。Existing／partial marker 拒絕 launch，write／fsync 失敗不 launch；launch 失敗或無 App receipt 保留 unknown 及已耗 marker，無自動重放。Marker 不作成功、歷史未寫或 ownership 證據。
- Host entry 只要有任一 diagnostic bootstrap environment 值就走診斷分支，無效 bootstrap 不 fallback 原 writer。Runner projection 有限且 Human observation 綁 purpose／diagnosticUUID／exact machine bytes SHA；未答或不完整觀察不補0。舊 run/current／manifest／identity／pins／歷史 bytes 沒有新增寫入接線，原 perform／cleanup 控制保持。
- Fake cases直接使用新的 Swift bootstrap／execute／finite receipt／load hooks及 Python實際 dispatch／exclusive marker／observe；原55 regression 保留。局部 file_length 豁免有固定 single-host 與共用 fake 驗證的理由，限此 rule，沒有全域 lint config 或 production policy 變更。

### D05 準備程度與 Human 停點

**D05 尚未具體準備，不能視為 ready。** 現有文件只定義未來新 host build/sign 的 scope／固定位置與 freeze 前提，並提供 D06–07 diagnostic-stage／observe 的 CLI 範本；沒有已選定且可獨立 review 的 D05 prepare/build-sign 完整命令、確定輸入／source copy／產物及簽章 binding。既有 legacy setup／retry helper 不是已接受的新診斷 host 建置方案；不得直接重用而改寫舊 run。

後續須先把受限 D05 方案具體化供 Human 審閱：只建置／簽章新的隔離診斷 App，使用既有已採用 identity／profile，固定新來源與產物 freeze，保留原 current／run，無啟動、LaunchServices 或 DPK；任何新 assets、安全／信任設定或付費需要立即停。取得當段明確範圍採用與 fresh ready 後才能執行；D06 診斷 launch、D07 namespace readonly 各需另一段 fresh ready／actual 提示觀察。此 review 不是這些授權、D05 build 可成功保證、DPK／UX通過或 S08 接受。

本 Reviewer 未改受審 code／tests／作者計畫，未操作真人 root／App／profiles／Apple assets，未 build／sign／launch／SecTask／SecItem、consume ready 或讀他人 E007；僅追加自身 evidence 與 D04 角色結果，於 Human execution boundary 停止。


## D06 後 Reviewer：既有證據與停止邊界（2026-10-21）

- Role：獨立 Reviewer。
- Verdict：human-check，停止自動前進。
- Required fixes：[]；本輪只分類，不提出新repair或執行方案。
- 追加前evidence SHA-256：`8f09fb1383ee23c8125b49f8cb43e14953bda9ea6756a53ed957c5e6d3277f55`；原Tester結果及全部歷史保留。

僅核既有live-validation最新D06、Tester交接、step及spec§5.2，未probe真人root／App。D05已有有效build.machine／Human綁定，建置及該段實際全程0次觀察完成。D06只完成freshready後單次attempt及Human本段全程0次敘述；prelaunch guards、consume/fsync與進入private launch helper有證據，D06驗收仍unknown。已耗marker原bytesSHA為cbdb03661df37a634a97ba6e973377ea87a220f0891cd70c44a82fa297991a31，只是attempt bookkeeping，不是Appmachine／成功／ownership。額度不得重放或刪marker。

兩個空launch logs及有限runner結果無法區分Popen/open失敗或返回後missing Appreceipt；native returncode／有限exception step未持久化。沒有Appmachine，不能判定App已啟動/結束、早期guard、真runtime零DPK或歷史安全未寫。Human全程0次只如實綁本attempt敘述，不造Humanleaf、AppmachineSHA或執行observe。

若日後另有已審工作，最小尚缺證據為可區分native invocation前／return／有限exception及Appreceipt存在性的可信execution紀錄；要判App內部結果仍需有效App有限收據及exact bytes binding。這些新證據不能事後補造本次原attempt的return/App結果。此處僅列證據缺口，不新增repair計畫、probe、PID查詢或重試授權。

原save-a unknownchild仍無有效App/process與strictownership／安全settlement證據；absence/write-attempt不存在不能證未寫，原items刪除及files-onlycleanup皆未放行。D05成功、新copy、D06零提示或未來namespace nil均不能解除舊條件；nil只證當下空。本補修無新delete/cleanup授權。依§5.2無可信輸出維持unknown、spent purpose不可重放及不能安全恢復停交Human，當前分類human-check。D07、retry、新context、cleanup及S08不前進，原root／markers／logs／machine/Human歷史保留。

本Reviewer未改Tester結果／source／作者計畫，未測試、build/sign/launch、App/DPK/system/security/assetprobe或PID查詢；只append自身兩個既有紀錄。


## LG05：launcher amendment 成果與未來單段可審程度（2026-10-22）

- Role：獨立 Reviewer。
- Verdict：**approved（僅受限launcher工具候選，可交Human審具體scope／freshready）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`2f8801f3c885fed7e14f4c2f3fb0adc758b300eaf681a5680513e7241ff8acd3`；原LG04兩次needs-rework、反例與全部真人歷史保留。

### 直接source與freeze

核spec/plan§5.3及已採delta、LG03實作交接、LG04 r2獨立approved/fixes=[]，直接讀runner新publication／snapshot／context／native／receipt／observe／CLI路徑、tests的實際assertions與README未來操作。三leaf仍為既有untracked validation內容，沒有把空tracked diff當source證據。九validation葉逐檔SHA皆與r2 freeze相符；不以本Reviewer先前planningapproval當code證據。

| 修改葉 | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `689eaeb8d65309ed4a23f20fe6e9889c5e54dca713f0b90e1a0912e3429e4e90` |
| Tests/test_live_protocol.py | `daef8d44659176b95f9016f3cae01be1ff963112db1fb044f574f727fe6f45b3` |
| README.md | `5a82028bf832b8267f37340376b9683dd8c1c642e2260e1a86a07cb5112df3dd` |

其餘六葉含Swift host保持既有freeze。LG04 r2的94/94零skip、AST/Ruff、原22＋12 fakechecks及兩個獨立prepublication fsync反例只引用為Tester的執行證據；Reviewer未重跑。

### Code／contract判讀

- launcher_context先核原manifest／binary／sources／legacy bindings與D05成功機器／Human、D06 marker／兩logs的固定SHA；同N唯一D／現有或partial拒絕，實際新ready與consume在spawn前exclusive0600、file／parent fsync。只新增十個已列private leaves，無原context／source snapshot寫入或新namespace／cleanup接線。
- launcher_spawn只Popen固定open -W -a、兩env及唯一invalid sentinel，無--request／-n／raw App。Frozen Swift的兩條args count==5 guard均先於request/store；任一env進diagnostic、env皆遺失進legacy時count2都先拒絕，不改host或重新編譯。
- native wait最多30秒，回傳int／signal、spawnOS／waitOS／subprocess／interrupted／timeout等有限欄位如實保存，無return時null，只有真wait返回才settled；沒有timeout kill／terminate或自動重試。finally採固定App receipt snapshot，absent／invalid／unreadable／valid-but-unbound與hostConfirmed=false／attributable=false均分開；native0／新valid receipt仍unknown，不冒稱host成功或D06歸屬。Public CLI僅五個有限結果欄位，raw argv／PID／errors不輸出，機密資料未新增進receipt。
- 專用writer先完整pending／file fsync／D fsync，再以no-clobber atomic link作最後fallible I/O；全域exclusive_json與legacy helper未變。Observe核安全final/pending同dev/inode與bytes/schema/context；pending永不binding，兩final交叉SHA／selector矛盾拒絕。四態符合最新契約：primary已發布即保留；primary失敗只合法published caller可bind；兩者未發布必null/noHuman。新增actual入口測試與Tester真pending fd fsync反例未降低原期望，不宣稱final entry斷電存活。
- Human只綁CLI真非nullbinding SHA，驗finite count/actions/whole並exclusive sidecar，不把Human0變hostpass。未答／無binding不造SHA或重用D05/D06觀察。
- Current-state preflight只列本UID PID／完整knownhost paths；唯有精確open executable才讀bounded argc/NUL argv，逐token比兩個既有manifest/request導出的命令，其他資料不保留。匹配或任一辨識／權限／parse不完整均拒絕，零match不作historical settlement／無寫／ownership。Reviewer僅唯讀SDK現有headers核PROC_UID_ONLY=4及KERN_PROCARGS2=49，沒有呼叫libproc/sysctl或查任何PID。

### 未來單段是否具體

**已具體可供Human審閱，沒有待補builder、私有caller或未定義CLI。** README明列同topic既有D05 execution.json作metadata來源、UID/mode/canonical檢查、固定repo與原callerSHA，取同N而非新root；外部執行者核上述獨立approved runner freeze後，Human明確採同N唯一sentinel純launch scope及freshready才產新UUID／傳--ready-confirmed。現有launcher-amendment自行完成已實作的preflight與一次attempt；observe完整argv及有限實答來源已明列，不須ready後臨場補程式或要求Human提供PID資料。

這表示方案可審，不證實當下OS snapshot／permission或未來launch一定可行：任一前提無法驗證即停止。此review不執行metadata讀取、PID/OSprobe或真App；沒有替Human採用scope／ready。LG06/07仍pending，host無nonce限制、原D05成功/Human0、D06/save-a unknown/Human0、Keychain受限成功歷史、strictownership／cleanup／S08均保留，DPK暫停。

本Reviewer僅append既有自身evidence及LG05row；未改受審source/tests/作者或Tester結論，未tests/build/sign/launch/DPK、真人root／inputs/ready、security/assets、Git或E007操作。


## LG12：pre-trusted-D 四欄位實作獨立審查（2026-10-22）

- Role：獨立 Reviewer。
- Verdict：**approved（僅工具候選，可交Human審具體新段落scope／freshready）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`803ab4ea4097b79b5476463724af7ec1ae7bf3664ce281c540e785135004468c`；全部歷史保留。

只審LG09所採pre-trusted-D四欄位delta。直接讀實際runner guard/API/projection／amendment與main例外邊界、必要actualCLI fake assertions、README及LG11獨立結果；未以自身planningapproval當code證據、不重開LG05 publication。九validation葉實際SHA全部符合LG11 freeze，其他六host葉保持。

| 修改葉 | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `3bb4d411ebc8ef961c29d756fb9f2e613b3e4b571d8d9746230d21ff0c9632a1` |
| Tests/test_live_protocol.py | `13f95da8b1c5b7a80799ee20f5f72246864ded2b195c347eec0486b2141e479a` |
| README.md | `b98fb6aeb5e7cf7a9f2a7f8a72eab81bb984d670dfbc22b2f1f2e3bd66450f5f` |

Invocation-local dict與optional參數只傳遞觀測，不新建global狀態。每point先重置；wrapper只執行原native function一次、原參數及require條件保持，set_errno/get_errno僅讀取本次thread-local觀測。原native失敗／errno0或不可取得仍unknown，成功API後buffer界線拒絕保留returned分類，不把上個point或invocation errno沿用為本次根因。未知exception／metadata讀取失敗也由封閉projection fallback有限unknown，不序列化error、PID、path、argv、buffer或環境。

main只對launcher-amendment且尚未trusted D的拒絕增加guardPoint/apiOutcome/apiReturn/errnoKind；trusted標記在既有D ownership成立後設定。Observe與trusted-D原例外邊界、五key結果／native／publication／Human契約保持；未為診斷繼續spawn、重查或放寬snapshot。四key allowlist不輸出內部trusted標記或其他dict內容。ActualCLI tests以全fake ctypes驗各point、真return／errno分類、純guard／邊界拒絕、敏感sentinel／零spawn及成功trusted-D舊schema，與LG11獨立負例一致。

LG11的99/99零skip、AST/Ruff、額外跨invocation staleerrno／metadata getter例外及九freeze核對僅引用為Tester的獨立執行證據，Reviewer未跑測試或真API。未見本delta實質code／scope缺口。

**未來方式仍具體**：沿LG05已審同一launcher-amendment subcommand、固定manifest/context來源與既有必要flags；沒有新leaf／flag／caller／namespace或待補前置程式。須外部核本次approved runner freeze，再交Human決定本段scope及freshready；原LG06 ready不可沿用，preflight不過仍停止，並非自動retry授權。LG06原stdout SHA b3d71cb085489be348cd23a361040f247b5b2bbc139b8ae8dd9bbf497885db66／Human0／未建D與未native結果不回填新欄位，歷史精確原因仍未知。Hostconfirmed／DPK／cleanup及原D05/D06／Keychain／S08界線不變。

本Reviewer只append自身既有review evidence及LG12row；未改受審code/tests／其他角色結果，未tests/CLI/snapshot/OSprobe/App/sign/build/DPK或真人root／ready／cleanup操作。


## LG13後：Human boundary與目標化snapshot規劃方向分類（2026-10-22）

- Role：獨立 Reviewer／Planner（限定分類，不建立新計畫）。
- Verdict：**human-check；停止同流程重跑**。
- 本輪不開code required fixes，不核准新guard政策、實作或live。
- 追加前evidence SHA-256：`809cc6d5fb9b47bd70cef3e65302a805246544c255f57330a768aeb9d0dc0506`；全部歷史保留。

核既有LG13 Tester及live-validation：本次真stdoutSHA c1eac0c28c5b3dcc31cf7218d0ff1263a41dd32f31214611ca09a701e8863c9e、snapshot-path／returned／zero／notFound與Human全程0次已記；D未建、未spawn、無binding／不observe。工具有限logging目標已有實際結果，launch／host驗收仍unknown。不能再把同程式freshready當可解此guard的下一步，亦不能由缺D重用ready或自動重試。

只知道proc_pidpath此次return0且errno被合併notFound，現有證據不辨PID、ENOENT／ESRCH或歷史根因。依呼叫端轉交Explorer的Apple source判讀，ESRCH不只等於程序已消失，不能全略過。呼叫端另轉交Tester之knownfakePID實驗只證有限self讀取與小buffer拒絕，copied sleep皆自身native exit -9、原因未知，未驗長名／argv0分辨；本Reviewer未重跑、未將source推論當本機完整證明或實驗成功。

**可供Human決定的最小方向已具體，但只到規劃／非真人驗證：** 是否採用「目標化snapshot」作受限planning候選。明確scope變更是從現契約要求所有ownUID PID的fullpath可讀，改為只有經可信正向辨識、可確定不匹配目標者才排除fullpath查詢；known host／native open候選仍強制完整path及原exact guards，空白／未知／歧義／錯誤一律fail closed。這不是忽略ESRCH、依缺path當不匹配，或直接採用尚未驗證的proc_name演算法。

該方向足以決定是否進入受限規劃；尚不足給實作／execution approval。具體正向辨識依據、長名／截斷與argv0處置及失敗分類仍須後續bounded契約與non-live驗收證據，獨立Plan-Reviewer／Tester／code Reviewer及新freeze；此處不代寫新方案或鎖定API。任何未來launch仍另需Human具體scope／freshready。Host／storage／DPK、安全／trust、paid／assets及cleanup不改，原D05/D06/LG06/LG13／Keychain受限結果、historical unknownchild與S08保留。

只append自身既有evidence／step分類，未改code／作者計畫或Tester結果，未新tests／更多OSprobe／App/sign/build/DPK/root/ready操作。


### LG13後授權判定更正：non-live準備不另設Human gate（2026-10-22）

重新核對本輪Human standing授權「唯讀定位／必要工具補修／非真人測試與審查」後，**更正上段將規劃方向也列為Human採用前提的分類**：未找到Human明確鎖定所有ownUID PID fullpath必讀的產品／秘密存取保護決策；該項是先前agent工具契約的技術設計。因此正向辨識prefilter在維持「unknown target仍阻擋」、scope／資料最少化與無live的條件下，受限規劃及non-live驗證已在既有授權內，可繼續，不必再向Human要求先核准規劃。

Decision：**non-live規劃／證據準備可前進；只有實際launch仍human-check停止。** 技術契約變更須先由原planning角色具體化，再獨立PlanReview、實作／Tester／codeReview與新freeze；既有standing授權不等本Reviewer已approved尚不存在的prefilter演算法／可行性或實際採用。不可直接改碼忽略ESRCH／unknown、重跑現有CLI、擴host/storage/DPK／安全設定或清理。未來具體launch仍須Human當段scope／freshready。

原LG13真stdout與Human0、未spawn／noD／無binding的事實及logging完成／host驗收unknown不變；不再以另一輪同流程ready作下一步。來源／實驗限制仍適用：copied sleep的-9只屬轉交的實際return，原因未知，不推定自行退出或安全政策原因。此更正只調整自身授權分類，不覆寫Tester結果或原證據。


## LG18：正向名稱前篩成果與單次純launch可審程度（2026-10-22）

- Role：獨立 Reviewer。
- Verdict：**approved（僅受限工具候選，可交Human審具體同N單次pure-launch scope／freshready）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`b15b8b00a49ed6ce689784d6aa00926871ba97b76d7d6b18cd915cf2108e81cf`；全部舊審查、實驗限制與真人歷史保留。

讀LG15最終approved／RF解除、LG16實作、LG17已append/readback的獨立approved/fixes=[]及N07原機native等價fixture澄清，再直接讀runner／tests／README實際內容。九validation葉逐一SHA與LG17相符；三個修改葉為：

| leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `a2ea02691abe9059300a2af7810fddc128a97c5bc35aba230a28ec381cebfae4` |
| Tests/test_live_protocol.py | `a6a6275ae6d68c045ec0d7503826a62d1b8ec8345b14016a2e9346299d0c0cf7` |
| README.md | `20bca7090ab9182616f19db70e2ec2d7800f162af6c17871e79c9c2d7e0403ba` |

其餘六host/project/resources保持。未以自身planningapproval當code證據，未重跑Tester：104/104零skip、AST/Ruff及另3項40子例僅引用LG17獨立執行結果；新的完整known-child限制仍清楚保留。

### 實作與負例判讀

同次listed PID只單次proc_name、32-byte零buffer、return1…31、return處NUL／之前無NUL及strictUTF-8；失敗／空／編碼／長度未知均finite snapshot-name guard，不跳ESRCH／ENOENT。候選集合只固定兩host basename及open、full／31/15 aliases，casefold後保留相等／alias／prefix；非ASCII或格式別名不能排除者仍candidate。可信disjoint15/31不再因長度被全域送path；只有確定非目標才省path／argv，candidate原proc_pidpath與僅exact-open boundedargv保持。Name不是identity，查核不完整或candidate path錯誤仍阻擋，不推historical settlement／無寫。

Actual入口assertions直接驗新增5個multi-branch cases與原99：disjoint短名/15/31零path/args、known/prefix/case/alias／非ASCII候選、name格式/API unknown拒絕、candidate path失敗仍guard及敏感fixture不出stdout；LG17另40子例含各長prefix與candidate path不同errno。snapshot-name僅原有限point enum，pre-trusted-D四欄／trusted-D舊schema保持；無新flag/privateleaf/caller或重試。

N07澄清屬既有standing non-live工具驗證內的一個原機未修改／未複製/bin/sleep有限child，僅Popen直接取得ownPID，無UID列舉／其他PID。LG17已依修訂契約執行並自然exit0，name對native basename／path對原binary／kernelargv0對spoof且不同name皆true，支持本機此一API接線及argv0不當name identity。原Python path/argv0 mismatch與copied sleep -9未知限制保留，不以新fixture覆寫，不宣稱長名／PID重用／exec競態或本機全snapshot必過。Reviewer未新跑known-child或任何API。

原invalid sentinel在env漏送的legacy／diagnostic args guard仍早於request/store，未改host／binary／manifest／identity／source snapshot。Publication最後atomiclink／pending四態Human binding、有限metadata、同N唯一D directory-or-marker partial spent、不重放／kill／delete／cleanup，及hostConfirmed／attributable=false均維持既有邊界；無新namespace／全域框架或隱藏OS修復。

### Human可審的一次段落與停止條件

未來方式仍具體，無待補caller或未定義輸入：從README已指定既有D05 execution metadata安全取同N，外部逐字核本次approved runner／九葉及原host/history pins；Human本段明確scope與freshready後，才產新UUID傳既有launcher-amendment的--manifest／--manifest-sha／--ready-uuid／--ready-confirmed。只有這一次CLI，先current-state正向前篩與完整候選查核，通過才同N唯一sentinel純launch；不build/sign、不做DPK/storage或其他phase。

Human觀察範圍為通知開始至本次CLI停止的完整期間，之後實答promptCount／actions／whole；pre-D拒絕綁真stdoutSHA敘述，有published binding才用已審observe綁真bytes。任何name／path／argv／permission／unknown／matching worker／pin不符或已spent即停止，不override／忽略errno／再invoke；若spawn後30秒timeout或native／receipt／publication異常亦保留有限結果停止，不kill／retry。任何新cert/security/trust/paid／assets需要不在scope。不能從D不存在、Human0、native0或新valid receipt推hostpass。

此approval只供Human決定新段落freshready，不代授權或實際snapshot／launch可行。Host無nonce，結果仍不作新host歸屬／歷史無寫／ownership或cleanup證明；原LG13真stdout/Human0/noD/noSpawn、D05/D06及Keychain受限成功歷史、DPK／S08停點均不改。內部non-live規劃不另設Human gate。

Reviewer只append自身既有review evidence／LG18row，未改受審source/tests或Tester結論，未tests／known-child／CLI／OSprobe／App/build/sign/DPK/root/ready/cleanup或其他worktree操作。


## LG24：fullinfo／status／instance成果獨立審查（2026-10-22）

- Role：獨立 Reviewer。
- Verdict：**approved（僅受限工具候選成果；真人／DPK繼續暫停）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`4b4e4dc97b25082da1f24d243ddac357774c79d2ac1f40595054885159621a97`；全部舊結果、限制與Human歷史保留。

直接讀LG20／M01–07、LG21最終契約、LG22實作與LG23已append/readback的獨立approved/fixes=[]，再審實際runner bsdinfo/metadata/classification/snapshot/aggregate/projection/main、tests必要assertions及README現行段。未以自身planningapproval代code證據，不重跑測試或native。九validation葉實際SHA逐一符合LG23，其他六host葉保持；三修改葉：

| leaf | SHA-256 |
| --- | --- |
| scripts/credential_storage_live.py | `c36e0959b35b6f4ed45fd91ec752053a0e308017f5969cafbfda61c7c3618108` |
| Tests/test_live_protocol.py | `d302bef7a93032f1cf13de9f3f1a4c01a43be607a926144054f03aa839b05a62` |
| README.md | `d4deaeeae5207b4c4b55fbd95c9528157631a99baabe4b0c9490132e721ddb9d` |

### 1. 已證結構問題與未證LG19原因

舊列表涵蓋active/zombie而proc_name wrapper的TBSDINFO arg0不能處理該正向zombie，是原語配對的結構缺口。LG23實際known finite child取得相同starttime的live及SZOMB，arg1 full metadata可讀、arg0回0／非零errno、自然wait後reaped仍guard，提供本機此一受控對照；不是只靠公開main source推本機binary。仍無LG19當時PID／精確errno／status，不能把此結構缺口寫成LG19已確認根因；所有舊stdout與Human0不回填。

### 2. 保護目的與實作判讀

公開SDK逐欄ctypes Struct、native alignment、136-byte exact return，PID/ownUID/starttime/status先核，可信SZOMB才正向排除，不由空name或errno推出gone。Live仍限定有效status與有界NUL/UTF8 name/comm，確定非目標才依原alias/prefix排除；candidate仍兩次完整path／selected-open bounded argv分類，再讀B核PID/UID/starttime及status／全部raw name/comm一致。真host/open衝突立即停，不等第二次或新instance洗掉；metadata短/零／denied/unknown、reaped、可觀測instance/classification變動皆拒絕，不membership重讀／errno skip／重試迴圈。

ProcessEvidence是可追溯實際事件的八key allowlist：正向zombie/noncandidate事實保留於aggregate，後續拒絕不抹掉；instanceChecked完整A/B才置，checksFinished僅本次流程全完成。Permission只依已知errno，projection／reset故障預設notChecked/allfalse而非授launch；沒有公開PID/UID/starttime/name/path/argv/rawerror或buffer。只launcher stdout新增此物件，原publication／Human／其他CLI不擴。未見實質code／scope缺口。

### 3. 驗證及限制

LG23的114/114零skip、SDK sizeof136/native alignment/22offset靜態斷言、唯一known child自然running→zombie→reaped、AST/Ruff與另4 tests/9反例，僅引用為其獨立執行證據。直接assertions及額外反例涵蓋B0/denied/short、第二次才見host/open、先前zombie/noncandidate後instance變動、raw comm/NUL與status變動及敏感projection。原104 publication／fsync反例／binding／sentinel／quota及Swift fake paths保持，無新host/sign/build/DPK結果。

PID+starttime只是有界一致性證據，不是不可偽造或形式唯一token；同instance A/B相同仍有中間exec/ABA、postcheck新process/exec，非原子／非完整快照。原UID列表無complete flag，checksFinished／processCheckComplete只表示本次契約完成。Reaped仍guard，真snapshot未測且下一次prelaunch可能再拒絕，不能保證已排除全部無關阻擋或真host可用。原Python mismatch、copied sleep -9與歷史unknown、Keychain受限成功範圍保留。

### 4. 下一次診斷的新證據及caller是否具體

既有launcher-amendment caller／同N metadata來源、--manifest／--manifest-sha／--ready-uuid／--ready-confirmed與外部新freeze／九葉／原host/context/history pins前提完整，沒有待寫私有caller或未定義步驟。新版相較LG19只得snapshot-name zero/notFound，能在下一次被另授的單次段落如實提供正向zombie/noncandidate排除、metadata/permission、instance/classification變動或真衝突及是否本次checksFinished；若native開始，原finite native/receipt觀察保持。這些是有效新增觀測，不只是改label，構成可供Human評估診斷價值的具體理由，但不授執行或保證會spawn。

真人仍依Human目前停止指示暫停；沒有自動freshready／下一invoke。若Human另明確要求，僅同N一次sentinel純launch、不build/sign/DPK，通知開始至CLI停止後實答count/actions/whole；所有guard／unknown／match／pin／spent或native timeout/receipt/write異常即停，不override/retry/kill，原ready不重用。Pre-D無binding只記真stdoutSHA，有published binding才observe。Host無nonce，hostConfirmed/attributable仍false，native0／Human0／valid新receipt不作host歸屬、歷史無寫／ownership或cleanup證明，DPK／S08停點不改。

本Reviewer只append自身既有review evidence及LG24row；未code/tests/SDKcompile/knownchild/probe／launcher/App/build/sign/DPK/root/ready/cleanup／其他worktree或新agent操作，未修改Tester或作者結論。


## LG30 Reviewer：path失敗單次post-metadata成果審查（2026-10-22）

**Verdict：approved；required fixes=[]。** 僅核LG26/P01–05與LG27批准契約之三葉成果，不放行真人／DPK／cleanup或新freshready。追加前本evidence SHA=`bf17061ce993cef7a0f216cd187e703a24ce511a4a4a6cf4698aae24b3c38172`；原歷史完整保留。已讀LG29最終approved/fixes=[]、122/122零skip及4 tests/7負例；其執行結果只作Tester證據，本Reviewer未重跑測試或probe。

直接核runner、tests實際assertions及README：僅可信live candidate A的first/second path原生完成返回≤0才同PID單次arg1 fullinfo；API exception不進post，無path/list retry。原四guard及實得finite errno在post前保存，post獨立observer；只有相同PID/UID/start且可信SZOMB才continue。不同instance即使zombie、liveSame、class變動、denied、zero、invalid／unknown仍拒絕。恢復PID不再讀第二path或normal B；既有名字predicate、真正host/open衝突及sentinel防store路徑保持。

五key pathFailureEvidence由A與當次pass明傳，enum嚴格投影、不含PID／UID／start／name／path／argv／raw error。每invocation重設；只保留最近path失敗，後續path事件替換，恢復或後續非path錯誤仍在pre-D／trusted-D stdout序列化原nested事件，外層維持後續guard。舊processEvidence aggregate不被當作該失敗PID證明。LG29獨立反例另確認原EACCES不被post ESRCH覆蓋、後續metadata denied不抹nested、native exception零post、不同PID/UID/start-usec zombie拒絕。

三葉直接SHA核對與LG28/LG29一致：runner `5a05d52836ccf7c5dadd1968cf69685ec46a5e3af39004ed6fc64c6445e0d8a5`；tests `46ef326d66a81fbde7bdc6ebb58bcd1b07d0fa1c49b260f5139e91e28132f898`；README `81783d041a47ed6a48866a0c8b29e485536caef7ba78578152b32894244dc459`。其餘六validation葉直接核與既有freeze相符；無新leaf、flag、caller、namespace，host／production／原context及歷史不變。

### 診斷價值、具體入口與停點

LG25歷史kernel原因仍未知；本修補不能回推當時就是zombie或race。新診斷可如實提供最近失敗的first/second pass、A名字來源類別、原有限errno與單次post狀態，並在恢復及後續失敗保留，屬有效新觀測而非改label。只有正向同instance zombie可排除；reaped／liveSame／permission／unknown仍guard。PID+starttime非形式唯一token，端點一致仍有exec/ABA／postcheck殘餘；非原子或complete snapshot，不保證下次可過。

既有README `launcher-amendment`、`--manifest`／`--manifest-sha`／`--ready-uuid`／`--ready-confirmed`之單次caller與輸入前提仍具體：沿同N及原host/context/history pins，外部核最新三葉／九葉freeze，使用新且當段Human ready，舊ready不重用。就此局部補修未發現待實作caller或額外準備缺口；本輪仍停止真人，不自動要求或執行下一次freshready／invoke。

若Human日後另授單次純launch，觀察範圍仍為開始至CLI結束之實際count/actions/whole，pre-D僅綁真stdoutSHA；published binding成立才observe。Guard／pin不符／spent／未知／conflict／timeout／receipt或publication錯誤均停，不override/retry/kill。Host無nonce，hostConfirmed／attributable仍false；native0、Human0或receipt存在不證host歸屬、歷史無寫或ownership，DPK／精確清理／S08未放行。

本Reviewer僅追加本既有evidence與自身LG30 row/交接；未執行tests、CLI、native/UID/PID probe、App、build/sign、DPK/SecItem、真人root/ready/cleanup，未改source、作者／Tester結果或其他worktree。


## LG35 Reviewer：離線launch-report binding成果審查（2026-11-03）

**Verdict：approved；required fixes=[]。** 僅LG31／LB01–06、RF-LG32-01兩private schema及LG33最終四葉工具成果；不是signed-host歸屬、真人提示或DPK驗收。追加前本review SHA=`5801252d2d8f7086ca3ecf9e02f0d995eccc5a4ce815829a5d58608bf4880445`。已讀LG34初輪needs-rework與RF-LG34-01最後獨立approved/fixes=[]，包含146/146零skip、Swift17 shared cases、原above-created reversal反例現拒絕與equal-clock完整fake鏈；原FAIL／144green與全部舊歷史保持。本Reviewer直接判讀source/assertions，未以自身LG32 planning approval代code證據，未重跑測試。

### 實際契約與source核對

- 新Swift selected分支在legacy前，固定sentinel或任一新env皆先選入；execute先核exact argv/env，完全env遺失亦不進credential path。LaunchReportHooks只具檔案、self executable、own instance／clock與ACK等待，無store/provider/SecItem/SecTask能力。Actual shared Swift fake入口覆dispatch／缺env／錯argv、錯hash/binary/ACK、timeout與新clock cases；舊三類入口保持。
- Context/request/report/ACK/final與consume/machine exact keys、UUID／hash、整數拒bool、nullable／native矩陣及B／receipt hash鏈有實際驗證。Context綁九source snapshot／固定App binary與opaque build/signing proof原bytes；proof hash只證bytes，signed-host來源／identity／有效期／reviewed operational freeze仍是外部trusted operator權威，預設verify hook不自行產生簽章approval。Nonce/processUUID不作auth/fresh proof。
- Runner對report pid獨立讀ownUID/live metadata及expected path，兩次核PID/start與expected binary bytes／created時間；ACK只在兩次成功後發布，host讀exact ACK binding才產final，runner核完整鏈與native rc0/settled，最後machine已發布才可signed-host attributed。Fake-only硬性hostAttributed=false/outcome=unknown；native0無receipt／UUID-only／PIDreuse／timeout或錯binding皆不成功。
- 雙方各invocation-local last-observed-wall拒絕已觀測下降，包括T→T+10→T+5；等值容許。Runner wait/instance/settle與Swift before-report/ACK等待走同一各自observer，保留monotonic30秒及原native rc/signal/exception，沒有改OS clock／查詢重試或共享新框架。原Tester反例保持原期望，最終新binary對應新main freeze。
- Owned root0700／regular0600／canonical與no-symlink、讀取O_NOFOLLOW、固定leaf及exclusive輸出、consume或attempt任何partial即永久耗額守約。Pending完整同步與parent fsync後最後no-clobber link，消費需同inode/bytes及完整schema/binding；machine自身無自身SHA，外層只用發布原bytes SHA。Publication失敗有限unknown/null，不認完整pending、不覆寫／刪除／kill/retry。公開投影無PID/path/私ID/raw error，早期無可信output不補造B。

### 最終freeze與驗證引用

直接核9/9 SHA。四葉：main `421648eb28456bb43bdaa0e6082e8dfe09f0a329cd7c10f6fe9892f2fdec042b`；runner `bff4d6b609fe9880f92dc081252ad5560b10fe9293e26f08ff972751d8c5c879`；tests `47cf4c827bbe6b25555dfb958e9ac28b4c8a6a0e583750f531ff988dd5a0b264`；README `21eb46c83978b999b6d03417bdc5499cb599bc3d063f473e81c67f1cc65784b2`。其餘五PBX／兩scheme／Info／entitlements逐檔等於原freeze，production未納修改。LG34最終evidence SHA=`61071e4b0a571099ac712d798441d727d23bfdd79870e6e76aa5147a206b036a`；其獨立146/146、Swift17、AST/Ruff/Swift strict與新unsigned binary sourceproof是Tester執行證據，不當signed實證。

### 操作提案可審範圍與尚未完成

README已提供可審順序與固定介面：先受限唯讀核已有資產／適用性／有效期，另授精確signed build/verify產物，取得final binary SHA後凍結source／signature／build proof，再建新R及exact context，最後另freshready單次`binding-launch --context --context-sha --attempt-uuid --ready-uuid --ready-confirmed`。舊N恢復非前提、不reset舊quota。新R實際位置／UUID、當前資產及精確build argv目前仍是下一操作提案待具體化，不能將本code approved或上述概念順序稱為Human已可直接照做的建置命令；具體命令／輸入準備好再交Human採用，不要求Human先批准未定動作。缺資產／expired或需新cert/profile、trust/security／paid皆停，不自動新增資產。

Signed-host attribution、真LaunchServices env傳遞／kernel交叉觀察與Human UX仍未驗。正常時鐘／trusted operator及同UID惡意不抵抗、未觀測exec/ABA/postcheck與非原子限制明列；本approval不改舊unknown／受限成功，不證歷史無寫／ownership或解鎖DPK/cleanup。Offline交付已可收尾，不需再問本輪ready；新context／signedbuild／App／DPK仍未授。

只追加自身既有review及LG35 row/交接，未改source/tests/作者或Tester結論，未tests/compile/probe/真UIDscan/私有root/context/ready/App/sign/build/DPK/cleanup/Git或新agent。


## LG40 Reviewer：已採用profile-free工具成果（2026-11-04）

**Verdict：approved；required fixes=[]。** 僅LG36／PF01–05及已採LG37之四葉code與離線驗證成果；非signed App／私鑰可用／真OS啟動／host attribution或DPK通過。追加前本review SHA=`3a2336540c5a4913c14e00a6a93513bbc933b65d2a5f624e3e196041d7504fc9`。已讀LG39最終approved/fixes=[]、37 targeted零skip與2獨立fake負例、兩unsigned binary來源及strictchecks；本Reviewer直接讀source/assertions與README，不以自身LG37規劃審查代成果證據，也不重跑測試。

**實際purpose fence與proof。** `#if LAUNCH_REPORT_ONLY`頂層只呼LaunchReport.run，無default/legacy/fake fallback；共用execute先核唯一argv及拒未知RIVET env，再驗兩新env/request，env loss／legacy/unknown皆先於store/provider/SecTask/SecItem拒絕。Default compile保留原分派及fake入口。新hooks mode不從request任選；host/runner皆驗兩proof exact schema/purpose/profile-free/mode/DEBUG+LAUNCH_REPORT_ONLY／九source／build→sign→context→selfbinary鏈，拒舊opaque/DPK proof。Fake-only永不attributed，新marker／nonce不自證身分或approval。

**身分／簽章觀察與既有binding。** Static verifier驗固定App Info/executable、無embedded profile、空claims與frozen PBX的原BID；code identity檢查strict-v、非adhoc、CodeIdentifier/Team、canonical DR、原leaf DER SHA256、Apple Development用途／當前日期/Team，並與purpose proof交叉核對。Dynamic使用同一reported PID的十進位target，經同helper取dynamic validity/identity，沒有用path取代PID；兩次kernel PID/UID/start/path/binary/freshness及ACK前deadline保持。LG39本機primary man核numericPID/-v語意作來源證據，本Reviewer未真執行codesign。兩次dynamic與metadata並不消除exec/ABA/postcheck競態，該限制明列，未誇大為原子證明。

LG39獨立fake驗首次dynamic後start漂移由第二metadata拒絕、dynamic耗盡deadline亦noACK；source仍保留lastwall／monotonic、完整report→ACK→final、native0 settled後machine publication、exactbytes/pendingpair、partialquota、不retry/kill與有限privacy。新static/dynamic結果來自實際工具驗證而非opaque proof自稱；外部source/build provenance與獨立approved freeze仍由trusted operator核。新variant不具DPK權利，也不改原DPK host group/profile gate。

**準備helpers／授權界線。** Original-certificate helper只限明確既有login keychain及選定family公開cert，記憶體唯一DER pin；sign preparation先pin原DER再核用途/日期/Team/BID，從同DER導SHA1返回private argv，不sign或查私鑰。Code沒有在binding-launch或module load自動呼此query/preparation；真query可能auth，留最後集中窗口。Actual argv不傳entitlements/deep/preserve舊claims，SHA256 pin不充selector；錯DER在decode前拒絕。沒有自動newcert/profile/import/trust/ACL/partition-list／Appleportal設定動作；private result/raw errors不應公開。當前原certificate來源/class/trust/sign-use仍未現場核，失敗具體停、不讓Human排profile障。

**Freeze及Tester證據。** 直接核9/9：main `2fd43e08f6c43cd3ee91edbc649ae97a7062aace8315bcfdc19435de2889f766`；runner `b12a752362831433c5a9d8210324fd51145f83294dc0f4a40bdc312a1977c902`；tests `ae5729a4e8f20b7479c06dd09e640b27476351e364efa08a55744d24143026fc`；README `fa9da261ac82fdd5f19790f556b99e731ebc61b6451f14920ac5bd715e435666`，其餘五PBX/schemes/Info/entitlements等原freeze。LG39 evidence SHA=`7ed52a83eea0edbb9b174b104202cebfb27d494e6cb37af2652ae47e591ac7e4`；其37/37、Swift共用22新binding／原22diagnostic／12operation、variant七類拒絕、2獨立負例及AST/Ruff/Swift strict是其實際執行證據，不稱全repo／146重跑或signedApp成功。原146及全部成功/失敗/unknown歷史保留。

### LG41正常routine待完成（不是required fix）

1. 沿已授routine準備同topic private project copy、own package/locked dependencies及實際unsigned `.app`，固定CredentialStorageProbe/Debug/原BID，NO signing/空entitlements/不注入claims/LAUNCH_REPORT_ONLY/debug dylib關閉；核source/flags／產物來源與精確owned位置、無profile/未知nested code，留build命令與unsigned bytes SHA/proof，五模板/原App不改。
2. 在ordinary私有準備區完成可審caller及固定輸入：exact login keychain、新App/後續R規劃、原PBX/Info expected BID/codeID、原DER精確pin／SHA1導出與Team來源、簽章argv、postverify與成功proof/finalbinaryfreeze程序；須排除raw private值／錯誤外露、partial覆寫／額度重放。不預填未實得DER/Team/signature/trust或成功proof。若真publiccert查詢會auth，不提前觸發；把已審helper接到最後集中Human窗口，毋須Human提供欄位。
3. 提供完整集中窗口操作順序與停點供獨立審閱：原cert查詢如需auth→原key當次sign→staticpostverify/原DER/Team/BID/codeID/emptyclaims/no profile/DR/finalbinary→才新context/proof freeze→單次binding-launch及真Human prompt全程觀察。Expired/wrongidentity/缺原key、需新cert/profile/AlwaysAllow/ACL/trust/security/paid或OS拒絕即停，不補資產、不重試LS/kill。實際sign/LS仍待最後Human明確ready，不能由方案採用預填。

上述routine preparation可依Human最新授權自主完成，不逐欄再問Human、不以舊N缺失阻擋；目前未備unsignedApp/caller是正常LG41工作，非本code blocker。Host attribution/LS/UX未驗，DPK/清理仍停。本Reviewer只追加自己原review及LG40 row/交接，未改source/tests/作者或Tester結論，未tests/compile/probe/真codesign/security/Keychain/privatekey/新context/App/LS/DPK/cleanup/Git或新agent。


## LG42 Reviewer：實際unsigned App與私有caller準備（2026-11-04）

**Verdict：approved；required fixes=[]。** 僅LG41已完成的準備產物、私有caller/config/proof及最後集中窗口可審性；不是certificate-signed/OSlaunch/host attribution/DPK成功，也不代Human ready。追加前本review SHA=`8d78bd76ea23fedf82c5b9a5fdfa941ec243d6c245e5d8ff601ca444298bb05c`。已讀LG41原implementation evidence，實讀SHA=`966d11eaa5ce68fa92e0b8c3503c8afeee239b9b8e408c80cd9cc3d5fd664176`。

**實際檔案與來源。** 先核owned scratch `rivet-lg41-preparation-3rjw9k7l`之canonical/nosymlink、currentUID/0700及指定private直接檔0600，再讀caller/config/OPERATIONS/tests/proof與build transcript。Config的精確第二build argv與build proof互符：CredentialStorageProbe/Debug、macOS arm64、signAllowed/Required=NO、Manual、空entitlements/no base、DEBUG LAUNCH_REPORT_ONLY/no debugdylib，無portal/auth/device flags。既有log有BUILD SUCCEEDED及compile條件、無CodeSign step；保留第一次build失敗，不混作診斷重試。Source snapshots/current九葉與package inputs逐hash匹配，依賴／lockfile未升級。

Unsigned原件與to-be-signed副本實讀binary SHA均`ad1e4f4fdb2b9da08603aa969d58a5bc6b6830775922cc67b087bff6871d1a0b`；獨立重算完整relative tree/content/modes SHA均`e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614`。兩App Info匹配expected原BID，profile absent；unsigned artifact記empty claims／0 nested MachO／linker adhoc且certificateSigned=false。臨時linker CodeIdentifier不是final身分；不刪seal，只有受控副本在將來原DER sign --identifier原值後須postverify。原件唯讀保留，不能以暫態差異偷偷更換最終identity。

**Caller實際guards與不可回放。** Guard在native前核external caller/config SHA、root/source/runner/privatePBX/package/unsigned-original tree及build bytes；dry-check沒有native動作。Sign必explicit ready，controlled副本仍同unsignedtree後，exclusive/fsync marker先於可能auth的publiccert query；partial／existing marker永久耗額。Query只固定existing login和selected family、memory按原DER pin挑一份；用途/class/date/Team→同DER SHA1 selector由agent完成，不由Human填私欄。Helper只準備argv，caller才在armed sign執行，無new/revoke cert、privatekey export、profile取得、trust/ACL/partition-list變更或隱式下一phase。

簽章後讀actual identity/原DER/Team/codeID、Info BID、emptyclaims/no profile及final binary/DR，成功才發布paired signing proof／signed artifact／sign-operation；原件仍須相同。Context只在上述paired成功鏈後exclusive建立planned新R，逐byte複製source/proofs/簽署App，重新static驗才產success context-operation；partial context不reuse/delete。Launch另ready且不等sign ready，exclusive launch marker先於既有frozen binding_launch一次；原static/dynamic exactPID、雙metadata/clock/ACK/final/native/pendingpublication不降低，unknown無retry/kill。Raw private結構不print，caller公開只finite status/stage/receiptSHA，bootstrap/guard失敗有限unknown/null。

**凍結與驗證引用。** Caller=`fa37d3ae267865dc0c2546f1c3806c588501ad4802f0dba851009a03788df5dd`；config=`f850bcfa2421a17f9c442048a12c3eddeb6a3455a92d383722a7a8128b213be3`；build proof=`9746cf38165eaddbb6fa2cf0ace9942e236c6e7b758e200f3a7b00fe145f7e1f`；preparation freeze=`03c9ab921c7addd91c70552f874be3b25c8c30a47003fc7b8e6deeca21677bba`，實讀皆符。7 NoApp tests之實際source全mock native/query/copy/launch，覆unarmed零query、queryfail marker spent、fake sign/context鏈原件不變、partial context拒絕、舊ready/unknown單次、fsync未發布及不覆寫；LG41記錄7/7及actual dry/wrongSHA/AST/Ruff，僅引用為作者執行證據，本Reviewer未重跑或import caller。實讀目前future-context、sign/launch markers、簽署proof及operation receipts均不存在。

### 最後集中Human窗口：已備命令與前提（現在不執行）

共同前提：外部核本次approved caller/config/freeze與完整source，使用private PREP/CONFIG_SHA/CALLER_SHA固定值，不以工具自算approval。

- **Sign/auth段**：`python3 "$PREP/caller.py" sign --config-sha "$CONFIG_SHA" --caller-sha "$CALLER_SHA" --ready-uuid "$SIGN_READY_UUID" --ready-confirmed`。SIGN_READY只取本段實答；query30秒、DER decode10秒、sign180秒、每次code identity verification30秒。可能有公開cert查詢／Keychain授權及原privatekey當次授權提示，0次不能預填。只對受控unsigned副本原identity簽章，輸出有限sign-operation原bytes SHA。
- **簽後新context前提**：sign-operation/status=success、兩paired proof/artifact互綁、finalbinary/原identity已驗後，依同窗口明確newcontext authority才跑 `python3 "$PREP/caller.py" context --config-sha "$CONFIG_SHA" --caller-sha "$CALLER_SHA" --ready-uuid "$CONTEXT_READY_UUID" --ready-confirmed`；目前不建R、不預填成功SHA。Context copy timeout60秒，static核完成才可下一段。
- **單次LS段**：context-operation成功及原pins仍符，另當段freshready且UUID不等sign ready，`python3 "$PREP/caller.py" launch --config-sha "$CONFIG_SHA" --caller-sha "$CALLER_SHA" --ready-uuid "$LAUNCH_READY_UUID" --ready-confirmed`。沿existing binding窗口monotonic30秒，動態verification在同deadline；實際runtime/OS提示與sign/auth分開記count/actions/whole及真receiptSHA。不能從前段Human配合或0提示推本段ready/結果。

集中明示stop：取消/denied/timeout/無原identity/expired/wrongidentity、未知nested code、沒有當次允許選項或需AlwaysAllow／解鎖安全設定／ACL/partition-list/trust/newcert/profile/paid、任何pin/schema/path/publication不符或正常OS拒絕皆停；不改政策、不重試LS／kill／刪partial或舊root。可用identity/trust/sign-use/真LS與prompt數仍未知，不能把準備或NoApp測試升格signed/live驗收。

只追加自身原review及LG42 row/交接，不改caller/config/產物/source/作者結果，未import/執行caller或NoApp測試，未certquery/Keychain/sign/真codesign/launch/App/新context/ready/DPK/cleanup/Git/新agent。全部舊146/history及DPK停點保持。


## LG48 Reviewer：certificate split parser與stdin修補（2026-11-04）

**Verdict：approved；required fixes=[]。** 僅SP01–05的runner/tests/README局部成果，LG49 actual amendment caller/config/controller尚待準備不當本輪code blocker。追加前review SHA=`460e90a1101fa3990a55e2d0727f99cc64eaf9c44d0059870c6ac2a626de4e82`。已讀LG47初輪needs-rework／RF-LG47-01與最後approved/fixes=[]、44/44零skip及原stdin反例底層1/1；原FAIL／41green／3額外green保留，不用舊證據取代新wrapper觀測。Tester evidence final SHA=`01d6e62c18b230bf3988de2b138cf090dd8da537bdf809edd22b52819d057c1d`。本Reviewer只讀source/assertions，未重跑測試或query。

**實際parser。** 原DER type=bytes且SHA256精確pin先於任何decode/path/selector。Team只取獨立單一subject記錄；scanner按escape邊界拆RDN，再嚴格解碼attribute，escaped comma/plus/hex不注入OU；重複subject／額外行／非法escape/UTF8/control／multivalued RDN／多OU（含同值重複）拒絕。Subject OU不得從issuer/fulltext補取。Dates恰兩唯一notBefore/notAfter及UTC有效期；class需真正Extended Key Usage區域Code Signing及兩原OID，Team格式/DER/class/date/原code identity標準未降低。修補證明結構缺口可解，不證無原decoder紀錄之LG43原因。

**實際native stdin。** Preparation default與shared static/dynamic postverify共用三固定argv分subject/dates/class。Shared helper先提取原DER/read/pin，再讓其local wrapper逐call核raw pin/type／exact argv／input bytes；最後`subprocess.run(arguments, **options)`保留同一memory bytes stdin，不追加-in、不走一般adapter DEVNULL、不重讀檔。固定C locale/OpenSSL config、每call最多10秒裁切原remaining deadline；nonzero/signal維持CalledProcessError原rc/stdout/stderr，timeout/OSError原exception不變，後續call不抹先錯。General codesign/csreq adapter及static/dynamic identity條件不因RF改寫。底層fake assertions穿過default shared helper/native wrapper，核三argv/同bytes/no-in/no-stdin/text-mode衝突、wrong bytes/type/argv先拒與later native failure停止，觀測點足夠。

SP02九keys invocation-local finite evidence具有實際guardPoint/part/outcome/returnCode/OUcount及四nullable bool，未查null、parse失敗false、成功true，helper拒絕後mutable dict仍可讀。測試含realistic issuer+Subject fulltext與獨立subject、原config形狀真helper，零codesign；selector仍同DER SHA1，非SHA256。有限evidence不含subject/日期原文/Team/CN/path/rawerror/prepared argv，原錯誤只private保留。新版preparation成功不當LG43歷史通過，舊Human0及ended readies不動。

**Freeze及範圍。** 本Reviewer實核9葉SHA：runner `3511c3f4d42e8ee2016cb0c9c28b36691c35d653eb8c77a6f32e0f7ecbd5ebc9`；tests `9c6de3cd9bd5f0fdd4f6eaf3252127e91a38ae87ad7d30ef6b7574591ebb6602`；README `1ac021d7b3199fb6b6bcf331f9b18569720ec4ec23886d92d7fd5f173d945ea5`。Main仍LG40 `2fd43e08f6c43cd3ee91edbc649ae97a7062aace8315bcfdc19435de2889f766`，其餘五模板等原freeze，無App/Swift重建或新compile證據聲稱。LG47另實讀parent六檔/pair/原private9source/兩App tree未變，僅引用為其檢查證據，本Reviewer未另碰真人root。44適用fake回歸及AST/Ruff是Tester結果，不稱真原certificate／signedApp／OS成功。

### LG49必要實際接線（正常routine待辦）

1. 同原owned prep root，僅SP03固定新caller/config/controller/freeze/once/proof leaves，exact parent LG43 opSHA `d123529e216fd44ffdce0bfd4b82343e6851a00996513b9abefc1d37af5edf26`與caller/config/consumed rawbytes/pair、unknown/sign-preparation及雙App原tree等guard先成立；controller bytes等新reviewed runner，config/prepfreeze綁所有parent與新三工具freeze。原marker/operation/ready不改；新consumed/operation pending/final任一存在永久spent。這些actual private guards本輪尚未存在，留LG49實作／LG50實讀，不能宣稱已驗。
2. 原App九source與build proof永遠原版本，不更新sourceHashes假重建；現repo三工具另核approved新freeze，main/五模板/package仍原。後續新簽proof引用原build；context producer只接受成功amendment operation/新signproof，不fallback父unknown，保持oldmain exact schema與完整共用binding驗證，不monkeypatch／省略proof或identity guard。
3. 真實NoApp跨phase fixture必先核unsigned副本，fake sign實際改其binary/tree後，context/launch用新signed-artifact/proof/finalbinary核；不能每phase要求簽副本仍unsigned。Unsigned原件和buildsource始終不變。Native query/sign/copy/verify/launch可fake provider，但actual caller/phase/guard/schema/proof資料接線要走到底，不能用data-layer相容性或本44tests替代。LG50再獨立審actual files/freezes/命令及partial/freshready/failed-publication。

可交LG49 routine準備，不增加內部Human gate；準備與獨立審查通過前不發ready。原certquery/sign僅最後新集中freshready，LG43兩ready已結束不能carry；原identity/Team/BID/trustACL／newcert/paid停點、DPK/cleanup及所有歷史保持。新privatecaller準備未完成不是本code required fix，也不允本approval自動query/sign/context/launch。

只追加自身原review evidence與LG48 row/交接，未改source/tests/作者或Tester結果，未tests/compile/Keychain/openssl/codesign/PIDquery/App/build/新context/ready/DPK/cleanup/Git或新agent。


## LG50 Reviewer：唯一amendment實際私有準備審查（2026-11-04）

**Verdict：approved；required fixes=[]。** 僅LG49 actual caller/config/controller/freeze、SP01–05及六leaf澄清之準備成果；不是query/sign/OS/LS/hostAttributed/DPK成功，也不代Human ready。追加前review SHA=`6c5a11c38384de1e30c16f14e9db4440ccab9666b4c27bf02b46c1866bcf5614`。已讀LG49 completed/readback與原LG48 approval；原LG43 unknown、Human0、ended readies及所有歷史保持。

**實際檔案／parent。** 先核同owned prep root canonical/no-symlink/currentUID0700及四新private檔regular0600，逐讀source/config/freeze及NoApp測試。四SHA實符：caller `4b3be2ed3d4238826679d46d13da0d8ed77bb39038bf0a25300ce5b1105d0d2f`；config `463ba3c0622568053b4c59cdde3b74cbb34662ab869a5614d5b9220e27fe7a68`；controller `3511c3f4d42e8ee2016cb0c9c28b36691c35d653eb8c77a6f32e0f7ecbd5ebc9`；freeze `12724d99d156d5ef0a442dbbb4e2269919e900739fa3d62fd83dc22e6580f4d7`。Parent op/caller/config/consumed hashes皆match，新config原keys和值逐項保留只加amendment；原op/pending同inode/bytes。原private source9/package inputs仍match，原buildproof/prepfreeze仍原SHA，雙App tree仍`e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614`。三工具current freeze與newcontroller另綁，沒有假重build或更動oldmain JSON/proof schema。

**Actual caller與配額。** Guard實查原parent unknown/sign-preparation、原build/private9source/unsigned原件與newreviewedToolSourceHashes；controller bytes等新runner，不monkeypatch驗收。Sign/dry才要求副本unsigned與future-context absent；context/launch改核同一child success/pair/proof/signed tree與finalbinary。Spent檢consume/operation pending/final，sign另拒既有child proof/artifact；先exclusive/fsync新consume才query/copy/launch，原budget不reset、不新namespace、不因unknown再試。Ready UUID拒原sign及child先前phase UUID，外部operator實答/approved hashes仍是權威，不由flags自證approval。

Sign走真reviewed helper的公cert pin／獨立subject-date-class stdin／SHA1selector與原Team/BID/CodeIdentifier，只有原controlled副本會被簽；postverify通過才paired發布新signproof/artifact/op，有限preparation在拒絕時保存原guard/decoder rc/outcome/nullable布林。不輸出rawsubject/Team/path/error或私有argv。Context只child success後copy簽後tree與原build/source bytes，actual共用binding_context/verify_static驗證，launch再核該context operation/bytes/static後一次actual binding_launch；原static/dynamic/instance/clock/ACK/final/native/publication未被繞過。Stage/error/unknown不升格成功，pending/existing不覆寫或刪除。

**獨立NoApp檢查。** 先讀整份`lg49-test-caller.py`，確認只有ordinary temp fixture／最低層subprocess及既有hooks fake；candidate逐byte等實際caller，測試SHA=`264a24e49d59ae244277ba99301c4e8160fba51b1b1f01cdcda7dfbc2278f279`。本Reviewer依本次明確允許，獨立執行此現成selector一次：**7/7、exit0、0 skip、0.424s**。Actual main/guard/helper/schema/context與binding協定未整體mock；fixture以自己的合成parent golden hashes/DER pin、signed-host模式fake native來源走分支，不改production pins，該欄不是signed實證。Happy鏈fake sign確改副本binary/tree後context/launch成功，原件/build/source保持；duplicate subject及dates rc7拒絕zero codesign且有限證據保真，parent/source/pair/replay/partial/舊ready拒絕成立。未nativequery或App執行。真root只唯讀，14個future操作paths全absent。

### 最後集中Human窗口之已備操作（現在不執行）

共同命令形狀：`python3 "$LG49_ROOT/caller-sign-amendment-1.py" <sign|context|launch> --config-sha 463ba3c0622568053b4c59cdde3b74cbb34662ab869a5614d5b9220e27fe7a68 --caller-sha 4b3be2ed3d4238826679d46d13da0d8ed77bb39038bf0a25300ce5b1105d0d2f --ready-uuid "$NEW_PHASE_READY" --ready-confirmed`。Private root由agent已知定位，不請Human提供DER/Team/BID。外部核本次freeze/actual bytes才可呼叫；每phase單獨執行/觀察，不串自動流程。

- Sign是同prep root**唯一LG43-sign-preparation-amendment-1**，明確連原失敗，非reset或第三自動retry。先新sign freshready，可能有公cert query/Keychain與原key當次授權；query30秒、每decode10秒、sign180秒、identity總30秒。失敗整輪停，oldready不可carry。
- 只有child sign/postverify/paired success後，context當段明確authority與不同新UUID才建一次既定future-context；copy60秒及static驗證，原source/buildproof不改。尚未到此條件不能預建或填成功SHA。
- Context success後另launch freshready與不同新UUID，一次LS，binding原monotonic30秒（dynamic同deadline）。Runtime提示與sign/auth分開實答count/actions/whole，綁本段真receiptSHA；native0／0提示不等hostpass。

可供主線使用的確認scope：是否同意在全程觀察下執行上述唯一sign amendment，僅原key當次允許；成功後仍依context/launch各段條件與fresh authority，不沿原窗口。此段僅供具體交付，不是本Reviewer向Human發ready。取消/denied/timeout、缺原key／wrong class/date/identity、需AlwaysAllow/newcert/profile/revoke/trust/ACL/partition-list/security/paid/改TeamBID/quarantine或正常OS拒絕皆停，不repair、不retry/kill/清理。原LG43精確拒絕原因仍unknown；本準備不證trust/privatekey可用或實際OS/UX成功，DPK仍停。

只追加自己的原review/LG50 row及交接；未改caller/config/source/parent/產物或其他角色結果，未import/armed真caller／query/openssl/codesign/Keychain/sign/真context/LS/DPK/cleanup/Git或新agent。唯一執行為已明確授權、事前靜態核安全的NoApp七項fake測試。


## LG56 Reviewer：LG52 startup/wire/native成果審查（2026-11-04）

**Status：completed；verdict：approved；required fixes=[]。** 只核LG54四工具葉對LG52 A–F／RTT01–06的成果與LG55獨立證據；可交LG57 routine新unsigned App／實際私有caller準備，非Humanready或sign/LS/DPK驗收。追加前本review SHA=`736300f4e6b34b6753627ba2568eccf6b18f7be19b6d143e7931162ff5c44d99`。已讀LG55 completed/approved、40/40零skip及4/4 actual入口負例，evidence SHA實讀=`2225fef51af91e1515fa4374fa8cb733d0c94c1e48365be3c909838ee5040e18`。未用自身LG53 planning approval代code判讀，未重跑測試／compile或做新native probe。

**Canonical修補仍有嚴格保護。** 直接讀LaunchReportFiles：絕對路徑、不含重複slash／dot components、POSIX realpath與原path相等，contained root到leaf逐層lstat拒symlink並核ownUID，root/attempt0700、file regular0600／O_NOFOLLOW/fstat/size限制保持。這修正Foundation去掉/private alias的比對問題，不是允許symlink alias或放寬owner/mode。修改只LaunchReport局部；LG55另逐byte核legacy prefix等原source。原trace core自行重編red line714及新版同rawbytes真FS/core green、NSNumber/bool/type/permission負例與SDK self-only accessor是其實際驗證證據；只能證固定guard缺口，不認定LG51歷史首拒於此，也不把OS lifecycle當Swift入口。

**Wire／可信診斷與成功。** Parser只接受完整五argv／兩env，優先argv pair，env僅bootstrap fallback；exactshape/雙channel完整一致/未知RIVET檢查不通過即wirefailure，不fallback credential。Bootstrap核物理固定path/owned root/attempt、原bytesSHA/request exactschema/UUID等後才有同B entry；fullcontext/source/proof/自身binary/instance/clock仍之後必要，entry不作authentication。Failure與stderr均固定有限schema，nullable欄只實得才填，無rawargv/env/ID/path/error。Runner嚴核pair/schema/B，新success另需entry非null/failure不存在，原static/dynamic/雙metadata/freshness/clock/ACK/final/native0 settled/machine publication全在；沒有exit0、entry或nonce單獨作hostAttributed。

**Native／streams。** 精確open -W/-a、兩env、兩App stream redirect及五hostargs，無-n或其他launch策略；App與native streams分開。App output只65536內成功讀原bytes的size/hash，oversize只size，read錯不可得有限null，不公開raw內容、不宣稱final。每wait迭代及finally poll既有Popen，已settled不再poll，真rc/signal保留，poll OSError有限waitOS而不假結算；原30秒、不kill/retry不變。Missing report即使native0仍timeout/unknown。Fullchain後wait timeout亦非成功；機器schema/partialpublication保持fail closed。

LG55四獨立入口負例已核source與assertions：report有但entry缺→零inspect/ACK；錯B failure不採；已poll0不因後續error覆寫；native waitTimeout保有限unknown且無raw PRIVATE。加上既有40所覆真FS／原bytesSwift／native非App finite child／wire/nullability/streams與variant拒絕，受影響驗證足夠；沒有再廣測146/37/44或擴新實驗。原certificate parser／identity規則本輪未改，不把新startup code當真簽章/trust/privatekey證明。

**Freeze與history。** 直接實核9/9：main `d9d3aa68d4f006f2d273e9eb41346446645d89a8df8f1183da7cae04a63f5328`；runner `1591468a2de9878cd0d39c6d9c3b4a45c845ee84290d29c882df143c3f553bb1`；tests `b1ac37798a44ffad1a5f39cb0a865ee3e067da80ad6c3cd088022f3a548bf2f4`；README `8264f2c6cbe8f04a8d17c555958dfe581e428c7dabea38c345eeeffd5d0f5c5e`。五PBX/schemes/Info/entitlements仍原pin。Final CLI來源/兩binary及原LG51七固定bytes/source9/signedApp未變，引用LG55獨立核驗；本Reviewer未再讀真人root或執行replay。原sign/context success、launch unknown與全窗口Human原實答／spent保持，不補各stage數字或歷史機器欄。

**LG57接線注意。** 本階段只有unsigned CLI，新main必須實際新unsigned App、新build proof/source9/final產物SHA；不得借原LG51signedApp冒充。依既定同prep root一次LG51-report-timeout-amendment-1/固定manifest備actualcaller/config/controller/freezes與NoApp跨phase，parent原success/unknown/ready/consumed immutable。Sign前unsignedcopy、簽後newproof/signedtree/context/launch，原件不變；新entry/failure/app streams及新增machine projection要到actualproducer與old/new schema邊界，不monkeypatch驗收或偽造buildsource。原已pin public DER copy可準備，不須新cert或預查Keychain；原key使用/sign/newcontext/單次LS仍LG58後最後新Human authority，現在不問ready。

普通可離線修的問題不設Human blocker；無required fix。DPK/no-new-key/trustACL/TeamBID/profile/paid與no kill/-n/autoretry/cleanup停點維持。Reviewer只追加自己的原review evidence及LG56 row，未改source/tests/作者或Tester結論，未tests/build/sign/LS/App/真context/DPK/query/probe/Git或新agent。


## LG58 Reviewer：report-timeout子amendment最終準備（2026-11-04）

**Status：completed；verdict：approved；required fixes=[]。** 僅LG57 actual私有caller/config/controller/freeze、新unsigned App/source/build與NoApp準備成果，非ready/sign/新context/LS/hostAttributed/DPK通過。已讀LG57 completed交接及LG56 source approval；追加前review SHA=`5033b06e398e7e43d5120975a1bde7ca5b0003c0dac2378eac92b887a6429ff3`。未重做LG55 core compile/40 selectors或廣測。

**實際產物。** 先核同prep root canonical/nosymlink/currentUID0700及四新檔regular0600。實讀SHA：caller `a437302534e2f538d52e6ed22ab4f8f7da599f0452c8f607ce8ef3a3b6d83861`；config `541587eff1e965c45a6a615b144c0d80519cf0377ce2d5d635716deda5b04504`；controller `1591468a2de9878cd0d39c6d9c3b4a45c845ee84290d29c882df143c3f553bb1`；freeze `5d6732ab358467fd086d9813ff16ff36f0bb27538845ad53d1cfb25f282b8d3d`。Source/privateproject各九leaf、current source/package pins、四工具freeze、privatePBX/newbuildproof/command皆互符；project唯一Package.resolved副本等原root lock。成功build transcript有BUILD SUCCEEDED且無CodeSign、stderr空，unsigned固定flags含no sign/Manual/空claims/no base/DEBUG LAUNCH_REPORT_ONLY/no debugdylib。首sandbox74歷史保留，不混作App重試。

兩新App binary實讀均`b4be9446130371c2ab33b800410f093103ec71b58e1d24e5f0621d1860efb51d`；獨立重算tree均`d51713c80af7bfa08f1464c0496b5c7ced6a67bb7ed0dcd4201004f31a8b216e`，Info BID匹配／profile absent。新buildproof SHA=`40202feeebcd3e9ce09a318707071478b1d362e3d969715b6ff536b9b6a86a99`且pending-final同inode/bytes，綁新main/source9/flags/unsignedbinary與command。作者純檔案Mach-O preflight記no CMS/claims/profile、linker adhoc／0 nested；暫態seal非finalidentity，簽後必原DER/Team/BID/codeID/emptyclaims/no profile/DR再次驗，不能以unsigned結果當簽署驗收。原signedApp/build/proof未被更新成新版本。

**Parent與actual guards。** 逐一實核config中11個LG51 parent pins，6個pair同inode/bytes，包含舊caller/config/controller/freeze、sign/context成功、launch machine report-timeout/native未結算及原context。Actual parent_guard用frozen舊controller解舊machine，不將舊schema餵新版；新controller/proof/current4tool另核，沒有monkeypatch或偽造buildhistory。原Human實答/原ready-consumed/history保持，LG51具體入口首錯仍未知。公DER副本canonical/owned0600/size/pin實核原5c2675…9440，公開資料只讀，不須Keychain查詢或讓Human找Team/DER。

Caller dry/sign前核新unsigned副本、新context absent及spent；各phase先exclusive/fsync新consume，既有/pending/partial即耗額，不overwrite/reset。Ready拒所有原與先前childphase UUID。Sign直接讀公DER、split strict parser→同DER SHA1 selector→原key手動sign受控新副本，postverify才發布新proof/artifact/op；簽後context/launch以new signed tree/成功鏈驗，不重核副本仍unsigned，unsigned原件保持。Context只新簽proof/finalbinary後copy/static驗；launch只新context合法後一次actual binding_launch，含新5argv/兩env、entry/failure/appOutput與原static/dynamic/雙instance/clock/ACK/final/native/發布條件，不把entry/exit0當hostpass。共用核心guard沒有被覆寫成成功。

**獨立NoApp。** 靜態讀完整test，先核candidate逐byte等actualcaller、draft config等final，test SHA=`76b57d93a1f6f2d61c3ff2837883818597b0c9c96797e007f17ace6efbb0adfa`。依本次允許獨立跑7項一次：**7/7、exit0、0 skip、1.337s**。Script初始化僅用已pin公開DER做三份離線openssl解碼取得格式fixture，無Keychain/codesign/trust/privatekey；之後最底層subprocess與existing binding hooks fake。Actual main/helper/schema/guard/context/binding未整體mock，實際parent rawbytes/pins與公DER未換成假production pin；fake sign真改fixture副本binary/tree，context/launch用新proof，原件/parent不變。Bad subject/decoder rc7、parent/source/pair/replay/partial、bound failure及新projection都保真拒絕。Fixture signed-host分支不作OS/sign實證。真prep root唯讀，14個future operation/consumed/proof/context paths仍全absent。

### 可交主線的最後集中窗口（不是本審查授權）

操作文件`lg57-OPERATIONS.md`實讀SHA=`e785db0d198ab45f78441f328cceb0c726126c1ffe03f443f7287dd6e700c117`。外部以本LG58 actual freeze而非舊審查/自填hash為準；private ROOT由agent已知定位，不請Human提供私有值。唯一scope為同root **LG51-report-timeout-amendment-1**，不重置原LS/parent配額，失敗就停、不換UUID再試。

共同exact CLI：`python3 "$PREP/caller-report-timeout-amendment-1.py" <sign|context|launch> --config-sha 541587eff1e965c45a6a615b144c0d80519cf0377ce2d5d635716deda5b04504 --caller-sha a437302534e2f538d52e6ed22ab4f8f7da599f0452c8f607ce8ef3a3b6d83861 --ready-uuid "$NEW_PHASE_UUID" --ready-confirmed`。不串自動流程，各phase只在實際新當段authority下執行。

- 人工重點一：**原key當次簽章授權**。`sign`只讀已pin公DER，不再security find-certificate；class/date/Team與selector由agent處理。Decoder各10秒、sign180秒、identity總30秒；sign operation/paired signproof/artifact原bytes SHA是本段輸出。取消/denied或沒有當次允許選項即停，不要求AlwaysAllow。
- `context`僅sign/postverify/paired success後、具有明確conditional或當段authority且不同新UUID時建立固定新child；copy60秒、static verify完成，輸出context-operation/context SHA。未成功不預建context或成功proof，不回舊context。
- 人工重點二：**真啟動全段觀察**。`launch`需context已驗且本段新freshready，binding monotonic30秒、dynamic同deadline。輸出wrapper operation與新machine/entry/failure/app stream有限snapshot hashes；Human分段如實記提示數/動作/whole，沒有觀察或只報permissionRequests時不補成全部prompt0。原全部ready不可carry。

所有phase：pin/path/schema/identity/class/date不符、timeout/取消/denied/缺原key、需newcert/profile/revoke/trust/ACL/partitionlist/AlwaysAllow/security/paid/改TeamBID/quarantine或正常OS拒絕均停，不repair/-n/kill/retry/cleanup；不證OS/trust/privatekey成功或DPK。現在不發ready、不執行armed。

只追加自己既有review及LG58 row/交接，未改caller/config/source/產物/parent/其他角色結果。唯一執行為已明確允許且事前靜態核對之ordinary NoApp七項與其已pin公開DER離線解碼；未真codesign/securityquery/sign/LS/App/正式context/DPK/build/cleanup/Git或新agent。


### LG64 Reviewer：profile 取得最終交付審查（2026-11-04）

**completed／approved；required fixes=[]。** 已唯讀核PA01–05、LG62/LG63、固定七leaf實際SHA/owned0600與inputs-before-consumed-pending-operation-after-profile互綁；取得root/子目錄ownUID0700及RF11目錄回修、七leaf原bytes保持。Profile SHA88ec674b614b3400203013a0d6b6c79c83bfc8516ec6eac4a49cefb00ae58026；獨立result SHA4314e75e0461d0d4c409ef4c488cc170a62b354fbe3b52a802b67e8cd55ecf4e符合。實際CMSDecoderCopySignerStatus/evaluateSecTrust、Apple macOS profile用途policy/chain及原DER/class/date/Team/AppID/prefix/group/本機ProvisioningUDID/profile日期紀錄全成立；有效至2026-11-11T08:43:09Z，本次有效profile可交付。

原operation unknown及歷史bytes不改，以LG63追加驗真與本review完成交付。Human全程0只count0/wholetrue，actions未報；profile僅原cert不推全域無新增或遠端未撤銷。DPK整套仍未通過，本輪停止、不授sign/LS/context/DPK/cleanup續行。本人未重跑crypto/tests/native query或資產操作。最新Human Execution Authorized與LG60 Written/Modify明允owner自身evidence/row；本次僅必要metadata追加。


### LG69 Reviewer：LG67/68 affected DPK source（2026-11-04）

**completed／approved；required fixes=[]。** 實讀四葉finalfreeze與LG68 final/RF解除證據：DPK purpose/claims/profile分支保持report-only拒profile；ACK前不store，ACK後同host正式Probe.perform與deadline store入口、六欄comparison/ownership result綁同B final及machine。Previous machine當round/phase、report digest與完整B先驗後才exact previous-instance查核/delegation，RF原反例已由TesteractualFS/pair複驗。Ownership nil/absence/write-attempt與後段真讀、完整替換/錯誤不假pass、finiteprivacy及deadline/no retry/cleanup邊界符合LG65；source未改production/templates。本人未測試/compile/native/資產或live。

只交LG70實際雙config unsignedApp、manual-sign caller/proofs與五phase＋Rebuilt actual NoApp準備，必經LG71獨立實讀；本approval不是actualcaller已備或Human授權。固定deadline含等待不延長、剩餘不足不start；真sign/App/DPK仍未授，既有profile/history/spent保持。


### LG69 static evidence-mode source delta（2026-11-04）

**approved；required fixes=[]。** 實讀static verifier新增內部mode預設signed-host並僅傳既有proof validator；原profile/claims/binary/DER/DR核對保持，非CLI fake開關。四葉deltafreeze及LG68 2/2 actual-validator複驗/RF保持已核。本人未tests/compile/native或live。只核此source delta，不核准LG70尚未完成的完整五phase/Rebuilt NoApp、actualcaller或LG71；真人授權/live未開始，完整DPK仍未通過。硬deadline後不新增operation，只保存既有結果，不kill/cleanup。


### LG70-R Reviewer：offline NoApp里程碑（2026-11-05）

**completed／approved；required fixes=[]，僅offline里程碑。** 實讀operative-resume-2 actualcaller/NoApp腳本/Swift driver、LG70-T結果與凍結方法；handoff全部file SHA符合，Swift前112361bytes逐byte等原core，追加僅隔離clock/test入口與fake store/最低nativeidentity。原producer先unsigned原DER/preparation核對再同once嵌profile，fake sign真改副本；真parser/FS/Probe.perform/ownership/report-ACK-final及前段digest/完整B鏈保留。Tester獨立15actions/5runtime紀錄實讀，各operationVerified=true且hostAttributed=false/fake-only；fake Rebuilt有新binary/proofs/context，自有child自然wait及spent重放零native負例有證據。本人未廣測/compile/native/資產操作。

原buildsource9與新controllerfreeze分離、原profileAbsent red/候選/歷史保持；productionRoundAbsent/operationsEmpty實讀成立。LG70整體仍pending，非LG71/liveReady。舊窗口/readies已關閉，production cutoff仍過期；新window/authority/deadline綁定須另受限規劃，不用fakeclock live、不rearm舊quota。此尚未授live前置不否定本offline成果。未sign/App/DPK/context/provision或cleanup。


### LG77 Reviewer：LG75/76 window source（2026-11-05）

**completed／approved；required fixes=[]。** 已實讀LG73契約、LG75/LG76/RF解除與四葉finalfreeze。Exact descriptor/Human/authority工廠、不可覆once/partial、kernel boot canonical hash與UTC/continuous-mono、顯式verified window傳operation/store、authoritySHA→round/context→既有B/proof/report/ACK/final接線成立；無authority仍舊expired，不提供CLI fakeclock/mode或rearm舊ready。RF shared三decoder現經同window.native，成功接受前核clock/boot，保持pinned DER stdin/剩餘timeout/原native例外；LG76獨立counter/shared12+指定5+exception1證據核符。到期不新native/postverify/store，已開始只自然結算保存，不kill/cleanup；信任仍是外部operator工作流，非UUID認證或同UID惡意防禦。本人未重測/compile/資產或live。

只交LG78新schema雙unsignedApp/actualcaller/descriptor/full15-action Rebuilt NoApp與實際命令凍結，再LG79獨立準備審查；本sourceapproval不代該準備或liveReady。新≤60min窗口/提示提案仍待最後Human採用與freshready，未mint真window/authority/context/sign/App/DPK，原所有歷史/資產/spent保持。


### LG79 Reviewer：actual live準備（2026-11-05）

**completed／approved；required fixes=[]，僅準備可交Human。** Actual caller/config/controller/descriptor/OPERATIONS與freeze及parents/source9逐檔核符；新Debug/Rebuilt兩unsigned clean-build命令Manual/noSign/noBaseInjection/noProvision/locked依賴，原Appbuild史與新controller來源分離。新NoApp Swift前127981bytes逐byte等凍結main；原profile bytes保持，不重CMS/取得。原draft與final config僅descriptorSHA不同，fixture依clone真descriptor重新計hash，actualcaller未改。

獨立重跑已pin NoApp腳本exit0：record-ready→真factory→15actions/5runtime全通，operationVerified皆true、hostAttributed皆false/fake-only，fake sign真改copy/readB後fake rebuild產新binary/proofs/context，自有普通CLI自然wait；ordinary result SHA0177150395445a6d8135fdae06b604851c4dfd3cfb855e842339cfc6eb712c13。未mock整validator，最低native/clock/boot/store/身份fake不等真signedApp/DPK。Production Human/authority/ready/round/context均仍absent、operations空，未真sign/App/DPK。

CLI／固定輸入／輸出及270/120/540秒start reserve、180/30/480秒native bounds、原key/profile/claims簽後proof→context、真readB+Human後cleanbuild已具體可審。單次開窗/phase-ready/partial-spent與原quota保持；新ready起60min含等待及replacement0/buildsign原key當次≤1仍待Human明示採用，save≤1/freshreads0不變。必當段freshready/實際whole/count/actions；未知/失敗/到期或不足bounds即停，不新native/DPK/postverify、不kill/cleanup/retry或資產變更。原窗口不復活。本approval只可交集中Human採用/授權，不代授權或完整DPK通過；本人僅普通NoApp fixture及自己的metadata，未操作真人資產。


### LG79 Cap amendment Reviewer（2026-11-05）

**completed／approved；required fixes=[]，僅actual cap準備。** 實讀parent-linked child caller/config/descriptor/OPS差異與freeze、LG81-Cap-T 6+1負例及完整15actions/5runtime結果。初始record-ready必顯式cap且等config固定值；真time_ns floor剩餘秒數、>270且≤3600，不改ready起點，factory延後不延end；get_window每次拒超cap authority。新增Rebuilt實際command digest對應child命令，原Appbuild9/controller/main/schema不改。實際parents/frozenleaf hashes相符，production Human/ready/authority/consume/round皆absent、operations/phase-ready空。

原scope/policy已採，不重新問整套或重啟一小時；只可交root取新sign-debug freshready，hardend仍2026-11-05T06:48:07Z，剩餘不足原bounds不start。原LG81 RO permissionCount0/wholetrue不擴其他prompts/actions、不當sign/DPK成功；原readies/stop/failedproducer及歷史保持。本人只RO與自身metadata，未true record/open/sign/App/DPK或資產操作，未重測/compile。


### LG81-Cap-R Reviewer：本窗口 DPK 完整結果（2026-11-05）

**completed／approved；required fixes=[]；本窗口DPK完整驗收通過。** 只純檔實讀既有reviewer index及最後Human-complete補索引：100筆已存在refs實際hash全部相符，最後原pending由獨立補索引與原machine綁定解決、不改舊索引。五runtime request/entry/report/ACK/final/machine exact同B及hash鏈、published同inode/bytes、operationResult六欄/ownership/其digest與operation→machine/Human→machine皆成立；全部signed-host、hostAttributed/operationVerified/liveinstance/binary/binding/nativeSettled=true、nativeRC0/無failure。不同process tuple及已審真stage前置exact previous-instance-gone guard的實際成功執行，不只marker/exit0，支持Writer結束後freshA/B與重建freshB。

原namespace nil/absence/write-attempt證據正確綁round/service/group/account；A→freshA→wholeB→freshB成立。真readB Human收據早於實際clean/build；重建operation時間、正式command canonical hash/clean-build/無provision flags/DPK+Rebuilt marker、BUILD SUCCEEDED log及buildproof一致，非preparedcopy。新unsigned/signedbinary均不同，context各自綁真build/signproof；source9同、原cert/Team/BID/codeID/DR/profile/group/claims八項同，固定App位置/新context與舊App preserved核符。

Authority原starts06:02:49Z/end06:48:06Z早於外部cap06:48:07Z，Human/descriptor/boot與authority/round/context/proof同鏈，10個phase-ready唯一且在窗內；既有受審clock/boot/native/store guards與成功路徑支持各bound，真build剩餘540秒成立，最後reader停止06:26:37Z。User五runtime均0提示/wholetrue並綁實際machine；其他階段依原文，首sign只permission0/wholetrue不擴all-prompts或actions，符合原key當次auth≤1；其他context/build/rebuilt-sign總0/wholetrue。

結論限本機指定環境、原cert/已驗profile、單一隔離namespace及完整假憑證；不是真OAuth登入/遠端refresh/API或所有OS/發行/簽章環境保證，不代整Topic完成/commit或後續操作授權。舊失敗/unknown/spent及資產保留，未retry/reset/cleanup；本次Reviewer只有檔案read/hash/既有紀錄與自己的metadata，未native/OSPID/Keychain/App/DPK/build/sign/provision或其他實驗。窗口結果交root收尾，不再App/DPK。
