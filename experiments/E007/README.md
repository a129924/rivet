# E007：同身分 profile 更新後的 DPK 讀回

## PR #62 RF-C01：新版匯出／清理協定

本節為2026-10-21的工具修正。下方兩輪E007及所有既有run receipts均來自原版本 `62dece35`，其runner SHA `62ca01370b78578db5ac3e45836b747765d7b201dbbf77438458a6003b90c484`；不回寫舊sourceSHA／final.index，也不宣稱新版runner有真人驗收。原兩輪renewal read均未執行，仍為無法判定；profile更新後讀回未驗證、Human已接受限制，不新增第三輪。

新版 `export-clean` 保持原namespace／owned0700非symlink root、Human關閉project、App退出，以及可能首存後的精確item cleanup＋read-absent／Human SHA綁定守衛。流程固定為：

1. 在evidence同filesystem的獨占0700 staging，先準備全部脫敏machine／Human投影、source hashes、逐檔SHA／bytes及 `final.index.json`；每檔flush／fsync、staging directory fsync、完整讀回核對。任何hash／stat／write／flush／fsync失敗都不刪private。
2. private root的同層建立0600外部checkpoint，綁namespace、window／index SHA、原root與stage的device／inode／uid／mode、原已退出PID及前置守衛；rawpaths只在此private checkpoint。checkpoint先flush／fsync／exclusive發布與parent fsync。macOS使用 `renamex_np(RENAME_EXCL)` 原子不覆寫發布staging，拒絕未知同名directory／symlink。發布後parent fsync並再驗完整final，之後才允許刪除原private root。
3. 不可變index始終記 `exportState=published`、`cleanupState=pending`、`privateFilesRemoved=false`、`cleanupComplete=false`。只有實際root不存在且其parent fsync成功後，才exclusive發布獨立 `cleanup.completed.json`，以 `indexSHA256` 綁原index並記實際ended／deadline結果、completed與兩true。沒有完整耐久completion就不宣稱整體清理完成；不將未來狀態寫入index。

失敗後使用**相同root、namespace與命令**，再次確認project已關閉。checkpoint可在private JSON部分刪除或root已不存在時接續；重試先核完整已發布集合／hash／size、原inode身分、PID／Humanclosure與checkpoint，再完成清理或完成收據。completed再次執行僅核對與補足fsync，不覆寫原index／completion。checkpoint保留於原private root的同層作恢復依據；它不是公開證據，不加入repository。未知collision、錯run、root換身分、symlink或hash損壞均停下保留，不盲刪或覆寫。不要手動移除checkpoint／pending發布物；需先保留並核對其來源。尚未建立checkpoint的失敗staging只精確清理本次已證owned staging，下次可重新準備。

合成測試只驗證可觀察的失敗安全、重試及OS成功fsync順序；不是停電耐久、真Keychain／Apple cache／profile更新或新版真人觀察證據。Python控制測試可獨立跑，不啟動既有Swift pure harness：

```sh
(cd experiments/E007/Tests && python3 -m unittest test_protocol.ProtocolTests test_protocol.ExportRecoveryTests -v)
```

## 1. 驗證什麼

- 實驗編號 E007，2026-10-19 設計；建立前確認未占用。Topic 為 `github-persistent-connection`。
- 主要問題：同 App ID／private group／certificate／GUI user 下，換用真正不同且有效的 development profile，是否能零提示讀回更新前保存的完整假 bundle？
- 假設：profile 更新不破壞上述條件下的資料存取；只檢驗本輪，不保證所有後續週期。

## 2. 為什麼

E006 已驗證有效且相同 profile 下的 fresh-process／重建，未驗 profile renewal。Apple 文件能解釋 profile 與 DPK 前提，不能代替實際提示觀察；此差異直接影響正式儲存採用。

依據為 E006 的 reviewed selected-App inspection、[TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)、[TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles) 與 [Personal Team 限制](https://developer.apple.com/help/account/basics/about-your-developer-account)。E006 source／證據只讀，本 runner 只重用其指定 App 檢查函式，不重用同 profile 的 live gate。

## 3. 成功與失敗判準

- 成功：有效不同 profile bytes、同 App ID／唯一 group／certificate／DR、完整六欄相符；initial 正常存取最多一次提示、renewal read 零提示；精確清理完成且符合原窗口。
- 失敗：前提與 Human 全程觀察完整，但讀回拒絕／內容不符或提示超標。
- 無法判定：無不同 profile、前提／觀察不足、有效機器收據缺失、清理或原時間窗口不足。初始 UX 的已知失敗另外保留，不外推 renewal 未執行的結果。
- 單輪 45 分鐘，setup 前 exclusive window 固定 t0；35 分鐘停止新測量，10 分鐘清理。不能 reset／延長；逾時仍可精確清理，但不得宣稱如期成功。
- 遇到新 certificate、安全設定或付費資格需求即停；不切其他儲存候選、不修改舊實驗。

## 4. 環境與前置條件

準備環境為 Xcode 26.6／Swift 6.3.3、macOS GUI user。模板固定 macOS 15+、Swift 6、Apple Development、有效 embedded profile、non-Sandbox、ENABLE_DEBUG_DYLIB=NO、唯一 private group；沒有版控 Team／profile。

Live 需要 Human 的 fresh ready、免費 Personal Team 來源聲明，以及指定 App／profile 更新與逐段提示觀察。先前「可即時配合」僅為時間安排，不是開始訊號或成功證據。2026-10-20 已收到 Human 當次開始、免費 Personal Team 與沿用既有 certificate 聲明；實際執行見下列結果。

只有隔離固定假 bundle；不碰產品 credential、真 OAuth 或遠端 GitHub。DPK service 含本輪 UUID，account 固定 oauth-bundle；每次指定 DPK=true、synchronizable=false、精確 group／service／account，新增採 AfterFirstUnlockThisDeviceOnly。Profile B 只能 read，不能 add／update；cleanup 只能刪該 UUID item。

## 5. 重現步驟

所有指令從 feature worktree 執行；私有 root 名稱須為 `rivet-E007-<UUID>`，owner 為目前 GUI user、權限 0700。公開文件不記本機絕對路徑；下列 `$RUN_ROOT` 是私有選定位置。

準備期可獨立執行：

```sh
python3 -m unittest discover -s experiments/E007/Tests -v
swift format lint --strict experiments/E007/Sources/ProfileRenewalProbe.swift
swiftlint lint --no-cache --strict experiments/E007/Sources/ProfileRenewalProbe.swift
xcodebuild build -project experiments/E007/ProfileRenewalProbe.xcodeproj -scheme ProfileRenewalProbe -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath "$PREPARATION_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

下列是既有 runner 的共通 live 協定；第一輪依此完成。第二輪另受 §9 的精確 cache 方法與恢復順序約束，不重跑第一輪：

Live 經獨立準備審查後，由 Tester 協調，逐段停止等待 Human：

1. Human fresh ready 與免費來源聲明到位後才呼叫 `begin --live --root "$RUN_ROOT" --namespace "$UUID" --human-ready "$ACTUAL_READY" --free-personal-team "$ACTUAL_DECLARATION"`。此刻先凍結 window，再複製私有 Setup project；不能用 availability 回覆代填。
2. Human 在私有 Xcode project 選原免費 Personal Team，取得有效 A-profile 並建置。只允許私人簽章配置，不改 probe source；不自動呼叫 provisioning updates、inventory 或建立 certificate。記錄實際選定 App 路徑，不掃描其他 App／account assets。
3. `phase --phase save --app "$APP_A" ... --human-ready "$ACTUAL_READY"`：核對指定 App、profile／device／chain／DR／group、原窗口及來源；複製至同輪固定 `current/ProfileRenewalProbe.app`，LaunchServices 新程序保存／讀回假 A 後退出。Initial Human 觀察包含 setup／簽章建置至本段結束。
4. Human 回報全段提示數、動作及目的；`observe --phase 1 --whole-stage --prompt-count N ... --statement "$ACTUAL_OBSERVATION"` 綁 exact machine SHA。零提示時 action／purpose 為空；有提示則每筆各提供一個 action／purpose。不要在聊天或收據提供密碼、token 或 raw profile。
5. Human 在同一私有 project 取得不同 bytes 的有效 B-profile 並建置，保持同 App ID／group／certificate。`phase --phase read --app "$APP_B" ... --human-ready "$ACTUAL_READY"` 先驗 profile 真不同與雙向 DR，再於同固定位置 fresh-process 唯讀 A。不能取得新 profile 就停止測量，不偽造差異。
6. 綁定 phase 2 machine SHA 記錄實際 Human 觀察；任何失敗／不足均保留，不能當作零提示。
7. 無論 renewal 是否完成，`phase --phase cleanup ... --human-ready "$ACTUAL_READY"` 使用保留的原 A-profile host，精確 delete＋read-absent；即使逾時仍允許 cleanup，不重開測量。Human cleanup 觀察另綁機器 SHA。
8. `finalize ...` 僅整理本輪有限分類，taskComplete 保持 false；不能代替獨立 Tester／Reviewer 或 Human 採用。
9. Human 停止 Build 並關閉本輪私有 project 後，`export-clean ... --human-project-closed "$ACTUAL_CLOSURE"`：確認本輪 App 程序已退出、任何可能寫入都有 read-absent，匯出 bounded receipts 並精確移除 begin 建立的私有 root。本輪 private root 內由 begin 建立的 project／App 副本／DerivedData 屬精確清理；root 外的 Human-owned selected source App、Apple assets 與未能證實 owned 的 DerivedData 保留。相關殘留如實列出，不宣稱已清。

上述 subcommands 均透過 `python3 experiments/E007/scripts/run_profile_renewal.py`，共同帶 `--root`／`--namespace`。每次 operation／收據 exclusive-create，不能以重跑覆蓋舊結果。同一 run 的私人 source Hash 必須與準備版相符。Human 原始 statement／actions／purposes 僅留私有資料；公開收據只含數字／布林、machine SHA、原觀察 SHA，action／purpose 僅保留有限值，其他記 other。Public evidence 路徑由 frozen t0／UUID 決定，final.index 列 live receipts hashes；後續獨立驗證收據另外引用，不回寫 index。

## 6. 是否成功

目前總結：兩輪均無法判定、renewal read 均未執行；唯一額外第二輪已完成有限證據與安全收尾，詳見 §10。Human 後續已接受唯一未知限制並授權繼續產品，S04e completed；實驗仍未知，採用決策見 §11，不再等開始訊號、不自動第三輪。下列原列項為第一輪結果。

- 實驗狀態：**無法判定**。2026-10-20 已執行首存與更新嘗試，但 B profile bytes 與 A 相同，未符合 renewal 前提。
- Renewal read：**未執行**；沒有 phase 2 permit／機器收據／Human sidecar，不把 B 設定與建置零提示當作讀回證據。
- 本輪有限驗證收尾：**完成**；精確憑證與私有檔案清理、獨立 Tester／Reviewer 證據審查均完成。Runner 原 `taskComplete=false` 保留，renewal 目標及 topic 尚未完成。
- 正式 DPK 採用：**未批准**；流程停於 S04e Human Check。準備測試與本輪有限成功均不能補足真正不同 profile 的缺口。

## 7. 結果與證據

準備過程先確認未實作 runner 的 red；新增完整負向案例後，Human SHA 不符曾錯判成功，該 red 已修為無法判定。另修正 reflection 測試以檢查實際 mirror children，沒有以 Mirror 摘要字串推論內容。

純控制測試覆蓋固定窗口、same-profile rejection、same-identity、Human exact SHA、無效觀察不成功、live opt-in、可能寫入後必須先清理、exclusive receipt／symlink、脫敏，以及 Swift fake 六欄往返／只讀／精確刪除／corrupt 不改寫。另涵蓋 Human 敏感自由文字 export 不外洩，以及 guard／technical／無效機器身分或形狀保留無法判定；只有可信已執行 read 的拒絕／不符才判失敗。此段僅指準備控制測試，不涵蓋真 Security／拒絕／提示／profile 更新；第一輪真實執行另列於下。

實際準備與獨立驗證結果以 `evidence/preparation-tests.json`、`evidence/preparation-review.json` 及兩份 r1 修正後收據與 step 為準。未保存 raw build logs、私人路徑或 profile IDs；模擬結果不提升為 live 結論。

### 2026-10-20 真實執行

本輪證據位於 [run 目錄](evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/)。全程使用 Human 聲明的免費 Personal Team 與 E006 相同 certificate；Tester 沒有使用 `-allowProvisioningUpdates`，沒有要求建立新 certificate、修改安全設定或刪除 Apple assets。

| 階段 | 實際結果 | Human 全段提示 |
|---|---|---|
| Setup／A 建置／首存 | Signed build 與 selected-App inspection 通過，假 bundle 六欄保存／讀回相符 | 0 |
| B 設定／建置 | 自動簽章取消再勾回後建置成功；profile 與 binary SHA 仍相同，`profileDidNotChange` 即停，未啟動讀回 | 0；只屬設定／建置觀察 |
| 原 A 精確清理 | 本輪 UUID item delete＋read-absent，App 已退出 | 0 |
| 私有檔案收尾 | Human 停止 Build 並關閉專案後匯出；移除本輪 owned root、App 副本與 DerivedData，Apple assets 保留 | Human 已確認關閉 |

固定 t0 為台灣 13:59:23.200801（UTC 05:59:23.200801）；原 35 分鐘 cutoff 為 14:34:23，45 分鐘 deadline 為 14:44:23，均未重設／延長。首存完成 14:04:11.388，憑證清理完成 14:09:12.603；私有檔案於 14:11:42.206791 移除，距 t0 739.00599 秒，符合原窗口。

A／B profile SHA 同為 `c7c363547cd64a4120ea23f7e90ecf7270c5f8b1b9dde4eb0d6e2399da9d36ef`。同 App ID／group／certificate／DR 的核對由 Tester 在清除私有 proofs 前執行；Reviewer 核對公開 hashes 與交接，無法重看已依契約刪除的原 App／profile。公開 Human sidecars 綁 exact machine bytes，machine `promptCount=null` 不回填。

[Tester 收據](evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/tester-validation.json)及[Reviewer 收據](evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/reviewer-verdict.json)均 `approved`、required fixes=[]；只接受有限證據與安全收尾。Reviewer 明示 `human-check`，不放行採用或自動重跑。`final.index.json` 與所有原收據保持 immutable；本節是 live 結束及獨立審查後的文件回寫，準備收據中的 README SHA 是當時版本，其他七份 W06 source 未改。

## 8. 第一輪結束時的結論與限制（歷史）

本輪缺少不同 profile 的必要前提，不能判為 renewal 成功或失敗，也不能核准正式 DPK adapter。依既定 gate，無法判定停止採用並回 Human 儲存決策；不自動重跑或延長原窗口。第一輪收尾後 Human 已另授權一次受限補驗證，其已獨立審查的方法如下；該授權不是新窗口開始訊號或 DPK 採用確認。

只支持本輪有效 profile、同 Mac／GUI user／App ID／group／certificate／DR；不證明已過期恢復、certificate rotation、所有未來續期或公開發行。Apple assets 保留，不能藉 cleanup revoke／刪除。

PR Lens 待實際 commit diff；Graphify 已確認 pin 0.9.73，沒有可用圖，採限定 source fallback、不建立圖。兩者不作為 DPK UX 證據。產品與正式圖交付仍在後續步驟。

## 9. 第二輪受限補驗證方法（已獨立計畫審查）

本節保留第二輪事前方法與停止條件；唯一額外輪已執行並按前提停止，實際結果見 §10。程序中的 fresh ready／開始前文字為當時前提，不代表目前仍待執行，也不授權第三輪。

### 9.1 範圍、官方方法與停止點

Human 已授權保留 `github-persistent-connection` 主軸，再補一次方法明確的 E007 驗證。這是**唯一額外一輪**：新 UUID、新私有 root、新 t0，另有 45 分鐘（35 分鐘停止新增測量，含 cache 恢復的 10 分鐘收尾）；不改第一輪任何收據、結果或窗口。既有 reviewed probe／runner／測試不改，不另設實驗編號、cache framework 或新 gate。獨立 Plan-Reviewer 審本方法修訂後，Tester 取得新 Human fresh ready／免費 Personal Team／沿用原 certificate 聲明才可 `begin`。本節撰寫不啟動計時，先前 45 分鐘可配合聲明不得延用。

Apple [Edit, download, or delete provisioning profiles](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles/) 說明：Xcode 找得到符合條件的本機 profile 時會沿用，更新方法包括先備份、移除快取，再 Build 讓 Xcode 重新請求。這只提供重新請求方法，不保證下載的 profile bytes 會不同。[Xcode 16 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes) 的 Signing 修正（54347894）說明新位置與仍載入舊位置；這兩個位置僅作精確候選基礎，實際存在、型態與 ownership 必須當輪唯讀核對。

只進行一次 cache 移出／refetch／B 建置嘗試。仍同 bytes、找不到唯一安全範圍、任何非本輪／wildcard App ID profile、需新 certificate／付費資格／安全設定，或時間不足，即停止新測量並清理／恢復；不再試下一方法、不擴掃目錄或其他資產。不得透過 portal revoke／delete、改 profile bytes、整目錄清空或 CLI `-allowProvisioningUpdates` 製造差異。首次 ≤1、renewal read 0、六欄相符、同 App ID／實際 private group／certificate／DR／固定 App 位置與雙向 DR 判準全部保留。

### 9.2 先首存，再定位唯一 profile

1. 依 §5 begin 後，**A 建置前**由 Human 在本輪私有 project 的 File > Project Settings（或現版對應的 project-specific 設定）將 GUI DerivedData 明確指定為本輪 owned root 的 `DerivedData`；現場核對實際 UI 確認是此 project 的設定，不修改全域 Xcode DerivedData、不影響其他 project；若無法限定為此私有 project 或需要全域改動即停止。[Apple 的 DerivedData 說明](https://help.apple.com/xcode/mac/current/en.lproj/deva52afe8a4.html) 可支持 custom／relative output 設定概念，但不證明現版 per-project 的確切 UI。原始路徑僅存私有 session／journal。A／B 均沿用此設定，各由 Human 在 GUI 按 Build 一次，Tester 只做 preflight／runner，不混用 CLI build。從這次 A 的實際 GUI Build 記錄／built products 揭露取得精確 `APP_A`，核對產物位於 owned root、來源是本輪私有 project／凍結 source、embedded profile 為本次 A 且沿用既有 certificate；不能確認輸出／來源即停止，不猜外部 DerivedData、不另建或再 Build。再 save 並確認完整假 bundle 六欄讀回成功。取得並記錄 Human setup 至首存的全段提示，綁 phase-1 machine SHA；未完整或超標即停止，不能先移快取再補觀察。
2. Human 停止 Build、關閉本輪私有 Xcode project，Tester 核對 probe 已退出；取得下一段實際 ready。保留 `initial/ProfileRenewalProbe.app`，不得以 B 覆蓋它；A host、embedded profile、備份／journal 保留至 item 清理和 cache 恢復完畢。
3. 從保留 A App 的 embedded profile 唯讀解碼 UUID，以 `private/first.json` 的 profileSHA256／certificateSHA256／App ID／private group 核對。必須是本輪 unique namespace 對應的精確 ApplicationIdentifier，不能含 App ID `*`；profile 的 keychain-access-groups 可能含 team.* 授權 pattern，不能只憑該 pattern 判共享，實際 App private group 仍須精確符合原 preflight。
4. 不 list 整目錄、不 inventory 帳號／certificate、不解碼其他 profiles。只對以下四個精確候選作 existence／lstat 與核對，其中 `$PROFILE_UUID` 只在私有 session 使用：
   - `~/Library/Developer/Xcode/UserData/Provisioning Profiles/$PROFILE_UUID.mobileprovision`
   - `~/Library/Developer/Xcode/UserData/Provisioning Profiles/$PROFILE_UUID.provisionprofile`
   - `~/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.mobileprovision`
   - `~/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.provisionprofile`
5. 每個存在候選及其 parent chain 須非 symlink，候選是目前 GUI user 擁有的 regular file；bytes 的 SHA 必須等於 A embedded profile，解碼 UUID／精確 App ID／原 certificate／授權 group 均相符。缺席可記錄；任何存在候選無法證明上述前提就停止。最多四個候選全部檢查後才可變動；符合的同 UUID 同 bytes 副本視為同一 profile 的本輪快取副本，逐檔列私有 journal。若一個都未找到，不另列舉尋找，也不換方法。

### 9.3 先備份，再暫移；只 Build 一次

6. 在本輪 0700 私有 root 的 `private/cache-backup` exclusive 建立逐檔備份，並用私有 journal 記原始精確路徑、lstat 身分、owner／mode／timestamps 等恢復 metadata、原 bytes SHA、backup SHA、動作時間與狀態。copy 後 fsync 檔案／journal 及相關目錄、重新讀取備份驗 SHA；用私有 restore-check 副本核對 bytes／metadata 可恢復後移除 check 副本。原 parent 須仍可安全寫回。所有備份與恢復可用性檢查完成前，不移出任何原檔。
7. 暫移前逐檔再次核對 lstat 身分／非 symlink／owner／SHA 無變化，只移出 journal 中的精確原檔至本輪私有 quarantine（或在已驗證備份留存下精確移除該檔）；不使用 glob、遞迴刪除或目錄級操作。逐筆寫私有 journal 並 fsync；任一步不符即停止，已移出的檔案進恢復流程，不重做嘗試。
8. Human 重開**同一**私有 Xcode project，先核對 §9.2 設定仍指向本輪 owned root 的 `DerivedData`，保留原 Team／certificate／App ID／private group，只在 GUI 按 Build **一次**讓 Xcode 自動取得符合條件的 profile。從此次 B 的實際 GUI Build 記錄／built products 揭露取得精確 `APP_B`，核對它位於同一 owned DerivedData、來源是本輪私有 project／凍結 source，並檢查此 GUI 產物內的新 embedded profile；不得把先前 CLI／A 舊 App 當作 B。私有 journal 保存兩次實際 selected product 原始路徑及來源核對，既有 tester-validation 只記有限的來源已確認／同 owned DerivedData 布林，不新增收據框架。無法確認 GUI 輸出或來源即停止，不猜或另建外部 DerivedData、不再建置第二次。禁止 CLI provisioning updates、建立 certificate、刪遠端資產或修改安全設定。若 Xcode 要求超界動作就停止；完成後等待 Human 全段提示觀察／fresh ready，不推定零提示。
9. Tester 先核對 B profile bytes 確實不同、各自操作時有效、同 App ID／group／原 certificate／GUI user、雙向 DR 及原固定位置；全部成立才呼叫既有 `phase --phase read --app "$APP_B"`，在 `current/ProfileRenewalProbe.app` fresh process 唯讀原 A。不能取得不同 bytes 就停止、不啟動 read、不再刷新第二次；保留實際 B 設定／建置觀察，不能當 renewal-read 觀察。實際 read 後另取 Human 更新操作至讀回結束的全段提示並綁 machine SHA。

### 9.4 所有結果都恢復；恢復前禁止 export-clean

10. 成功、失敗、無法判定或 cutoff 都先執行既有 `phase cleanup`：使用保留原 A host 精確 delete 本輪 UUID 假 item、read-absent，取得 Human 清理全段觀察。35 分鐘後不新增測量；必要安全清理即使逾時仍做，時間如實記錄。
11. Human 停 Build／關閉本輪 project、確認 probe 退出後，逐檔依 journal 恢復**原 cache bytes／metadata 至原精確路徑**，核對 parent／ownership／非 symlink 與可寫性。原位置 absent 時用不覆寫的方式建立並 fsync，再核對原 SHA；已同 bytes 且恢復 metadata 可核對時記為已恢復。原位置若已有其他 bytes、出現 symlink／ownership 改變或恢復失敗，**不得覆寫或刪除衝突檔**；保留唯一 backup／journal／A host，停於 human-check，禁止 export-clean／private-root 刪除，也不得宣稱 cleanupComplete。
12. 新下載的 B profile 和其他 Apple assets 保留，不做遠端 revoke／delete。若 B 與原快取路徑衝突，仍按上一步停留人工處置，不以「保留 B」之名覆寫原備份。全部原檔恢復、逐檔 hash／metadata 與原路徑核對完成，並取得 Human 實際確認後，才可 `finalize`／`export-clean`。既有 runner **不會自動核對外部 cache 恢復**；Tester／Human 必須在呼叫 export-clean 前依本順序人工核對並硬停止。不能把未修改的 runner 宣稱為 cache guard。
13. 若正常完成，export-clean 先匯出原 runner bounded receipts，再移除 owned 私有 root；已恢復原快取，因此其內 backup／journal 此時才可移除。若逾時，保留實際時間與不足，不重開窗口。Apple 資產保留與所有殘留如實報告。原 runner `taskComplete=false` 維持。

### 9.5 最小額外證據與採用路由

不改 runner／final.index schema。Tester 依實際私有逐步操作紀錄，先在私有區準備有限投影，正常 export-clean 後於**第二輪** public run dir exclusive-create `cache-transition.machine.json` 與 `cache-recovery.machine.json`。名稱中的 machine 只是 manifest 約定，兩者必須明示 `evidenceSource=manual-record-review`，不是自動感測。若恢復未完成而無法 export-clean，私有紀錄保留，先回 Human，不能為了公開收據刪備份。

兩份共同只允許：`schemaVersion`、`evidenceSource`、`windowSHA256`、`phase1MachineSHA256`、`privateJournalSHA256`、`startedUTC`、`endedUTC` 與下列有限欄位：

- transition：`outcome`（notStarted／stopped／completed）、`candidateCount`（0–4）、`matchedCount`（0–4）、`backupCount`（0–4）、`removedCount`（0–4）、`allCandidatesChecked`、`allMatchedExclusiveToRun`、`allBackupsVerifiedBeforeRemoval`、`restoreCheckPassed`、`refetchBuildAttemptCount`（0–1）、`oldProfileSHA256`、`newProfileSHA256`（未取得則 null）、`profileBytesDiffer`（未取得則 null）。
- recovery：`outcome`（notRequired／restored／conflict／failed）、`requiredCount`（0–4）、`restoredCount`（0–4）、`conflictCount`（0–4）、`originalBytesRestored`、`metadataVerified`、`hashesVerified`、`noOtherBytesOverwritten`、`humanProjectClosedDeclared`、`humanRecoveryConfirmed`、`newDownloadedProfileRetained`、`backupRetained`、`recoveryBeforeExport`。

只輸出有限值、hashes、計數、布林或明訂 null；raw profile UUID／identifier／path／profile bytes／certificate identifiers／自由 Human 私文均不公開。不記錄未操作的成功值；無執行依實際記 notStarted／notRequired。Tester 在獨立 `tester-validation.json` 引用兩收據 SHA 與未修改 final.index SHA，並核對 cache 先恢復再 export 的順序；Reviewer 獨立核對 SHA／有限來源／原判準與恢復結果。原 immutable run 與其收據完全不改，不另建準備測試 revision。

沿用 S04c Tester → S04d Reviewer → S04e Human 採用。通過只代表本輪同身分有效不同 profile 的有限證據；真正不同有效 profile、同身分、六欄／UX、精確恢復清理全部符合原判準，且獨立 Tester／Reviewer 明示真成功、無重大問題時，S04e 依本次 Human「通過就回產品」條件授權記錄條件成立，回 S05 繼續登入、保存、重啟還原、自動刷新及 API 使用，不再重問同一採用許可。這不預填成功或替代當輪 fresh ready／全段觀察。第二輪仍無新 profile 就停止追查，保留未知；後續只有 Human 可選擇接受「profile 更新後尚未驗證」並修 gate，或另選儲存方案，不預先填決策。

方法審查紀錄：原獨立 Plan-Reviewer 已明示 approved、requiredFixes=[]，RF-M01 已解除。這是第二輪開始前對唯一補驗證的方法放行；後續已取得新 Human ready、執行並結束，詳見 §10。主假設與採用條件尚未成立，不代表仍待下一輪審查或開始。

## 10. 第二輪唯一補驗證實際結果

2026-10-20 已使用 Human 新回覆「現在開始，能配合45分鐘」執行唯一額外輪。證據位於 [第二輪 run](evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/)。原 t0 UTC 06:58:27.242710（台灣14:58:27），35 分鐘 cutoff 07:33:27／15:33:27、45 分鐘 deadline 07:43:27／15:43:27 均未 reset／延長。

| 階段 | 實際結果 | Human 觀察／界線 |
|---|---|---|
| A GUI 建置與首存 | GUI Build 一次；Tester 當輪核對 project-specific owned DerivedData、實際 GUI product／source／原 certificate。07:04:39.596Z 六欄全相符 | 首段全程 0 提示，exact phase-1 machine SHA 綁 sidecar |
| 精確定位／備份預檢 | 四候選全查、匹配一份。raw backup=1，bytes/hash 與 owner／mode／mtime／atime 相符；backup／restore-check 多一個系統 provenance xattr，原檔為零，native raw data 確認是真集合差異。完整 verified backup=0、restoreCheckPassed=false | Human 僅有限回報未見視窗，confirmedWholeStagePromptCount=null，不補成全段零提示或 phase 2 觀察 |
| cache 移出／refetch／B／renewal read | 預檢不足，按原停止條件在移出前停止；removed=0、refetch=0、B GUI Build=0。renewal read 未執行，無 phase 2 machine／Human sidecar | 不能說已執行官方 refetch 仍同 profile；不外推普遍不可複製或不可恢復 |
| 原 A 精確清理 | 07:17:11.446Z 本輪 UUID item delete＋read-absent | Human 清理全段 0 提示，exact cleanup machine SHA 綁 sidecar |
| cache／私有檔案收尾 | export 前原 cache bytes／identity／metadata／xattrs 完全未變；requiredRestore=0、notRequired、restoreOperations=0。原 cache／Apple assets 保留；owned root 07:20:14.453347Z（台灣15:20:14.453347）移除，耗時1307.210637秒，符合原窗口 | humanRecoveryConfirmed=false 表示無須恢復確認，非待補；project 閉合與 Xcode 未執行已核對 |

**結論：無法判定；renewal read 未執行。** [Tester](evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/tester-validation.json)／[Reviewer](evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/reviewer-verdict.json)均明示 approved、requiredFixes=[]，只接受有限證據與安全收尾；verificationClosureComplete=true 不代表主假設或 topic 完成。runnerTaskComplete=false、dpkAdoptionApproved=false 保留。

| 收據 | SHA256 |
|---|---|
| final.index.json | `874b50d21938d94606bd386edafe4c93cddbc3472af852598c4fad5af6f85548` |
| phase-1.machine.json | `af8830c32241409bf9a125f02be1de8fccc764598bfca789eac182b603db826c` |
| cleanup.machine.json | `26125b6a8f902420f9aa49497559226f32139bc3eb8c5c7fb10c169b4122afef` |
| cache-transition.machine.json | `32a8fc78a9a645bb1fcf828820bccfffc59847e64b2f5fb46115dc0eb77b9c75` |
| cache-recovery.machine.json | `b817492a883c4d32b4cdd9c5106695b80777575accbbb49986a41b6be8cbc6b6` |
| tester-validation.json | `fcd273cd697a34f21d02536452805fcc588e24bad7dc143b5a6118d646a5b133` |
| reviewer-verdict.json | `9cd28d7bb548849e310005c72d1811ccde889033bf41fff0f735532cd5d2457b` |

兩份 cache 收據為 export 後 exclusive 追加的有限 `manual-record-review` 投影，Tester／Reviewer 另引用 SHA；原 final.index 未改，不冒稱 runner 自動 cache guard。七份 reviewed source／tests 及第一輪 immutable 收據均未改。第二輪方法 README SHA `f90878100b843c4303f5190ee3b7c23423fccd1b1bd0f741dfba2d095d87b06b` 指當時受審版，本節是結果回寫。

唯一額外輪已用完；此輪 Reviewer 當時明示 human-check／停止自動前進／不允許第三輪，原「通過就回產品」真成功條件未成立。後續 Human 已明確接受唯一未知限制並授權繼續產品，另記 §11；本節實驗分類、收據與當時 verdict 保持不變，不再等待新的開始訊號或第三輪。

## 11. 後續 Human 接受未知與受限採用

Human 實際決策：「接受 profile 更新後尚未驗證的限制，修訂 gate 並繼續產品實作」。所答問題明示：只解除 renewal 必須先驗證的 gate，其他驗收維持，仍保留連線失效處理與重新授權路徑。S04e 因這項實際決策 completed；唯一 gate amendment 待獨立 Plan-Reviewer 回查後交 S05 Implementer，不重問採用、不跑第三輪。

接受的未知只限同身分 profile 更新後讀回未驗證。兩輪實驗仍**無法判定**、phase 2 未執行、runnerTaskComplete=false；原收據 `dpkAdoptionApproved=false` 是當時判讀，不改寫、不把 unknown 升為 pass。後續受限 DPK 採用另依本 Human 決策，不宣稱 renewal／refresh 或正式產品已驗證。

首版本機自用仍限有效 embedded development profile、同 Mac／GUI user／App ID／private group／原 certificate 與固定位置。七日到期與過期不可用、已過期恢復／certificate rotation／公開發行未驗證限制保留。產品首次≤1／fresh 0／真正 rebuild 0／輪替後新程序、真 OAuth／重啟／GET /user／真遠端 refresh 與受控時鐘分列、V08 regressions／V09 圖工具與 Human 產品 UX 均不降低；明確失效／必要 reauth、denied 不覆寫、accepted rotation 保存失敗停止 provider、雙 client 共用 lifecycle 與 topic scope 不變。
