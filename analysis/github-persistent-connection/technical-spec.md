# GitHub 持續連線：獨立驗證 App 技術契約

## 現行補充：RF-C01 export-clean 契約（待獨立 Plan-Reviewer）

本補充僅解鎖 plan C-M01–03，其他歷史證據不改。原兩輪使用 `62dece35` 的工具，不是新runner；下方App契約繼續有效。九欄見requirements現行補充，精確檔案與cases見plan。

1. 保持 namespace、owned0700root／非symlink、safe paths、window身分、Human projectclosed、App已退出與曾可能寫入必須有精確cleanup completed/absent＋SHA綁Human觀察的守衛；不碰Applecache或來源App。所有錯誤有限分類，不洩rawpaths／secret／Human私文。
2. 在evidence同filesystem的proven-owned0700staging準備全部boundedreceipts、sourceSHA、逐檔hash／bytes與`final.index.json`。所有檔案（包括raw machine複製）flush/fsync，再fsync staging directory；重讀完整集合與hash／size。任何validation/hash/stat/write/fsync失敗不得刪private；只留可辨識ownedstage或精確清它，不能建立partial final，重試不得被partialstage永久阻擋。
3. 同filesystem原子**不覆寫**發布至原frozen t0＋UUID名稱；不能以exists-check加一般rename當no-clobber。macOS可用exclusive rename，unsupported即failclosed。parent/stage/final查owner與非symlink；collision／未知既有final拒絕且不改它。發布後fsync parent並再驗完整final/index，這些完成前不irreversiblecleanup。發布後失敗保留完整final，不刪唯一公開副本。
4. 兩階段真實狀態：不可變`final.index.json`明示`exportState=published`、`cleanupState=pending`、`privateFilesRemoved=false`、`cleanupComplete=false`；published只在final內才作發布事實，不把未來清理結果預寫。刪ownedprivate、觀察不存在且fsync其parent後，另以有限`cleanup.completed.json`記completed與兩true、實際ended/deadline及原indexSHA。completion需exclusive原子發布、fsync檔案與directory，不循環加入原index。不覆寫任何舊run index；未有完整completion就是pending，不因root已不存在假定整體收據耐久成功。
5. cleanup前建立不隨rmtree消失的owned runtime checkpoint/journal，綁原run／window及root所有權身分，保留足以部分刪除後resume的資訊；rawpaths只留private。cleanup開始前、部分rmtree、刪完但completion write/fsync失敗，同命令能驗完整已發布index/receipts與自身checkpoint接續，不能依賴已可能刪掉的window/first.json。既有完整自身pending發布可恢復、completed重試核驗而不覆寫；未知collision、錯run、symlink／owner改變、hash損壞停且不盲刪。再核適用的process／Humanclosure守衛；checkpoint自身也durable/atomic/no-clobber，若更新只限已驗owned原身分journal原子替換，不泛用覆寫未知檔。
checkpoint 的 schemaVersion 固定為新版有限整數；至少保存 namespace、原 windowSHA256、完整 published indexSHA256、root 的 device/inode/uid/mode 與清理階段（pending/completed），以及恢復所需的原前置守衛觀察；不得靠 namespace 字串 alone 授權刪除。root 絕對路徑只在 owned private checkpoint，public index／completion 不含它。checkpoint 路徑必須可由既定 namespace／window 有限決定，在 root 不存在時仍可找到；root 原身分不符則不刪，新出現同名root也不冒認。checkpoint 的 fsync 成功先於 cleanup，部分刪除後仍能核對原 root 身分；完成收據由實際不存在的觀察產生，不能只信 journal 的預期狀態。這是 export-clean 專用協定，不建立通用 transaction framework。

6. README分清新協定、pending恢復／collision停點、舊版本與兩輪unknown。新runtime狀態不回填tracked歷史收據或hash；三檔新舊SHA追加manifest，真命令／獨立結果追加review。測試只證合成failure safety與OS成功fsync順序，不冒稱停電耐久／真人新版／自然到期／profile更新已驗證。fsync錯誤須傳遞，不降級成功。不改App、production或圖面。

---

- Topic：`github-persistent-connection`；2026-10-21 scope correction，待獨立 Plan-Reviewer。
- 本文取代舊正式產品定位／新增正式 public API 決策；舊版在 `ca00bc0`，僅供歷史。配對：[需求](requirements.md)、[計畫及精確 manifest](../../plan/github-persistent-connection/github-persistent-connection.plan.md)、[帳本](../../plan/github-persistent-connection/github-persistent-connection.step.md)。

## 九欄與檔案契約

精確逐檔 from／to、Written／Deleted／Modify／ReadOnly 以配對 plan §2 為唯一 manifest；本技術契約不授權額外檔案。

| 欄位 | 技術約束 |
|---|---|
| In-Scope | 獨立驗證 App 的完整 OAuth／DPK／restore／refresh／輪替讀回／API、controlled expiry／receipt 與必要測試 |
| Out-Of-Scope | 正式產品整合、PR #61 合流或去重、新正式 API、E007 新輪次與帳號管理 |
| ReadOnly | plan R；既有正式 public contracts／internal visibility、Package 與 locks、E007／舊 native evidence |
| Written | plan D 表的新路徑、W01–W07；local source／UI／adapters／tracker／tests／project／新證據圖 |
| Deleted | plan D19 舊 production 路徑，保留舊安裝 App／真 DPK 與 Apple 資產 |
| Modify | plan M01–M06；四正式檔精確撤 topic delta，其餘僅 scope／truth／banner |
| Goal | App 單向使用既有 contracts；移除整個 App 時 production 無需修改仍 build／test |
| Non-Goal | 任何驗證專用 production 契約／共用 UI／control／receipt，或冒稱新 App 已沿用舊 live 通過 |
| TestCase | plan TC01–TC10，尤其 local tracker／refresh、settlement／test guard／隔離與真人六段 |

## 1. Ownership 與依賴

所有本 topic 新增 authorization／configuration／DPK adapter、UI、composition、relay、probe、受控到期、收據與相關測試收於 `apps/GitHubConnectionVerification`。跟 PR #61 `apps/GitHubSignInVerification` 一樣使用獨立 Xcode App／hosted tests，App-local UI 不連 `RivetPresentation`；只借其分離方式，不搬用／修改／去重其 implementation。

App 只依賴既有 `GitHubIntegration` 與 `RivetHTTPClient` public products，以及系統 frameworks Foundation／SwiftUI／AppKit／Network／Security／CryptoKit／Observation／Synchronization／Darwin。正式 targets 不依賴 App；Package.swift、既有產品清單、production internal visibility 不改。App-local型別／函式採 internal／private，不能藉 production `@testable import` 取得 internal。

`OAuthCredentialStore`／`OAuthTokenFetcher`／bundle／snapshot／`OAuthTokenProvider`／`GitHubClientScope`／REST／GraphQL 等 topic 前 public 契約原樣保留；四個原正式修改檔精確撤本 topic delta。**不保留或新增任何正式契約**，包含撤回 `OAuthTokenProviderDisposition`／`disposition()` 及本輪 public factories／configuration／authorization／DPK surfaces。若實作發現不可撤回，先報具體必要性，不默認保留。

既有 internal `GitHubOAuthHTTPTokenFetcher`、`GitHubOAuthEndpoints`、`GitHubOAuthTokenResponse` 不擴大 visibility。App-local `VerificationOAuthHTTPTokenFetcher`／`VerificationOAuthEndpoints`／`VerificationOAuthTokenResponse` 自持所需HTTP refresh與DTO／URLs，public bundle只透過既有 public initializer 建立；複製既有有限policy是驗證App內實作，不抽共用重構。

## 2. 名稱、identity 與 host

| 項目 | 鎖定值 |
|---|---|
| 路徑／project | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj` |
| App target／module／scheme／product | `GitHubConnectionVerification`／`GitHubConnectionVerification.app` |
| Test target／module／product | `GitHubConnectionVerificationTests`／`GitHubConnectionVerificationTests.xctest` |
| bundle ID | `local.rivet.github-connection-verification`；tests 加 `.tests` |
| group | `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`，唯一驗證私有group，不沿舊 `local.rivet.app` |
| service／accounts | `local.rivet.github-connection-verification.oauth.v1`；`configuration`／`credential` |
| Info.plist group key | `GitHubConnectionVerificationKeychainAccessGroup` |
| UI／window | `GitHubConnectionVerification — GitHub 持續連線驗證`，常駐「驗證用途，非 Rivet 正式產品」 |
| User-Agent／queue | `GitHubConnectionVerification`／`local.rivet.github-connection-verification.oauth.loopback` |
| test key | `GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE=1` |
| 受控 key | `GITHUB_CONNECTION_VERIFICATION_MODE=expire-restored-once|observe`；`GITHUB_CONNECTION_VERIFICATION_RECEIPT` |
| TEST_HOST | `$(BUILT_PRODUCTS_DIR)/GitHubConnectionVerification.app/Contents/MacOS/GitHubConnectionVerification`；BUNDLE_LOADER指向它 |

macOS15+／Swift6、Debug ONLY_ACTIVE_ARCH=YES、ENABLE_DEBUG_DYLIB=NO、non-Sandbox、有效 embedded development profile／Apple Development簽章。Team／profile／certificate／安裝原始路徑只在本機私有 setup，repo不入raw identity。使用原免費PersonalTeam與既有certificate；不能產生新certificate或修改安全設定。真人前確認新的驗證bundle identity可由既有Team簽章，失敗即停，不切換舊產品identity。固定Human個人Applications中的**新** `GitHubConnectionVerification.app`；如已有不同來源同名App先停，不能覆蓋未知資產。保留原 `Rivet.app`／真items，無遷移。重啟與重建只替換本輪proven-owned新驗證App同位置。

## 3. Authorization、refresh 與 callback

維持原已實作安全及失敗契約：GitHub.com固定HTTPS endpoints；scope `offline_access`，state／verifier獨立32bytes cryptographicrandom，base64url／S256。自有OAuth App註冊 `http://127.0.0.1/oauth/callback`；listener只綁127.0.0.1系統port，ready後才開始授權，authorize與exchange相同實際帶port redirect。exact scheme／host／port／path，禁止userinfo／fragment，state/code/error唯一值且互斥，invalid／denied／cancelled／expired分列。單session5分鐘，GET callback、8KiB header／target、connection5秒，其他path404；靜態callback結束文字明示驗證App，不含query。

Exchange／refresh使用30秒ephemeral transport、無cookie／cache、不跟redirect、不自動重送。code exchange含clientID／secret／code／redirectURI／verifier；refresh含clientID／secret／refresh token／grant_type。six-field DTO嚴格驗證token非空、bearer、正expires與有限receivedAt／dates，scope允許空。refresh可信純error：bad_refresh_token→credentialRejected；incorrect_client_credentials→clientConfiguration；混token／無法判明／未知回應→rotationIndeterminate。beforeRequest取消可再次明確嘗試；afterRequestStarted停止。可信accepted回應優先於取消，必須先保存。全程不曝raw body／underlying敏感資料。

## 4. DPK 與修復

驗證App-local兩generic-password items；每次明確DPK=true、synchronizable=false、uniquegroup／service／account，add為AfterFirstUnlockThisDeviceOnly，無presence／biometry／ACL。完整update，不存在才add，duplicate僅重試完整update；actor序列化。兩items不是跨item transaction。

Configuration schemaVersion1含clientID／secret；credential envelope version1含clientID／完整六欄，millisecondsSince1970 dates有限且可已過期、tokens非空／bearer／scope字串。整份codec可信才能取ID；不新增production Codable。denied／unavailable／corrupt／identityMismatch分列，不能當missing。

| 情況 | 行為 |
|---|---|
| both absent | 輸入自有設定；先保存configuration再授權 |
| valid config，credential absent/corrupt | 同configID重新授權成功才完整覆寫credential |
| valid credential，config absent/corrupt/mismatch | credentialID權威，鎖同ID修復secret，先保存config再重新授權 |
| 無可信ID且有corrupt | Human明確提供並確認原AppID／secret；不猜App身分 |
| denied/unavailable | 保留items，僅明確重試，不修復覆寫 |

新App新namespace不接觸舊items。無logout／revoke／自動刪除／rollback到可能已失效token。

## 5. Coordinator 與本地停止觀察

App-owned唯一provider／scope；全程一次一個tracked operation Task。UI取消不釋放admission，await實際Task.value settled才清handle；舊shared refresh/save settled前不可寫configuration／新bundle。所有reauth／修復先退休舊provider／scope，包括取消、grant或save失敗都不恢復；新授權完整保存後才能建新provider。正常fresh process初次restore允許依同ID資料建provider，不可在同程序用重建繞過停止。

`VerificationLifecycleObservation`是每一provider generation一份App-local、併發安全tracker，透過包裝 **真實** `OAuthTokenFetcher.refresh`／`OAuthCredentialStore.save` 記錄已發生結果：credentialRejected→authenticationRequired；rotationIndeterminate／afterRequestStarted取消→stopped；accepted rotation後save失敗→stopped；knownTechnical／clientConfiguration／beforeRequest取消保持非terminal。save前必須已有本輪accepted-refresh標記，初次授權保存不誤標terminal。tracker與provider同generation一起建立／退休，保留原error/cancellation傳遞。可信accepted但連續已過期rotation達provider原limit的非terminal行為不得擅改。

分類只讀local tracker及正在處理的既有public error，不再次呼叫snapshot／replacementSnapshot、不額外prepare／網路探測、不暴露provider內部、不宣稱完整複刻其state。scope可能抹除底層error時，tracker仍由相同實際wrapper取得事實；未知技術失敗保持有限fallback，禁止默認重建。temporary明確retry原provider。latch測試覆蓋settlement、兩輪refresh／save與所有terminal分類；不能以sleep推定完成。

GET /user只用scope.rest，固定Accept／驗證User-Agent，200＋positiveid／nonemptylogin才呈現帳號；403等為probe failure。重新授權清舊顯示；雙client原有限401 policy不改。

## 6. 受控到期、收據與測試隔離

`GitHubExpiryValidation`及其store/fetcher wrappers全部App-local。只有明確環境key才開；trusted restore後單次把provider注入clock指向原expiry，accepted真refresh並真save後回realclock。原OSclock、fetcher receivedAt與保存dates不改。observe新程序不得強制到期。六欄digest、pairChanged、attempt／accepted／savecounts、PID／observationID、source／binary／identityhash建立輪替證據；不記rawsecret。私有0700ownedparent、0600exclusive receipt，不覆寫未知檔，不掃全機。單一pairChanged不得虛稱個別tokenhash已測。

App entry最先檢查新testkey，早於任何DPK／listener／OAuth／restore／validation初始化；scheme注入同key，hosted fake-only測試驗證live counters全0。App-local XCTest可採用既有Testing測試框架，但不得殘留root測試依賴；module import改新App，不加productiontesthooks。

## 7. 證據與文件

E00732檔逐bytes保留、兩輪unknown及profile更新未驗證限制沿用。原5個evidence只頂部加歷史banner，不改觀察／hash／verdict；標source version、當時precommitbuild、scope宣稱現已撤回，連新版。四舊圖scene／spec／HTML／native receipts／PNG不改，用原BUILD／visual-review／tool-evidence頂部historyindex標明舊版且指向新圖。新圖另revision，反映App-local與production單向依賴、無dispositionAPI。

新host真人六段在實際操作前全pending：簽章準備、首次真授權保存API、samebinaryfresh、真CleanBuildfresh、受控expiry真refreshsave、輪替後無forcefresh。每段先通知Human留意系統提示，收到後才寫count；不重用舊0次、不預填。有效profile／同identity與固定位置、首次≤1／fresh0／rebuild0保留。首次段、重啟、重建、refresh、輪替後fresh均需新host新provenance；controlled不等naturalexpiry。無法配合時停Human段，其他非相依工作先完成。

README／design-principles／architectureREADME／dual-clientdoc修成「驗證工具與可行性結果／限制」，既有productionlifecycle保持，不宣稱正式產品登入完成。archify／architecture-canvas依skills真QA；pr-lens使用真base/head與覆蓋邊界，graphify禁自動refresh並沿可用graph或sourcefallback，不能為此去建索引／裝hooks／改工具設定／公開發布。
