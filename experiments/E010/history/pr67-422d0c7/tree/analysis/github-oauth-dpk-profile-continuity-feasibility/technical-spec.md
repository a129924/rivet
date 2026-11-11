# DPK profile-only 自然到期受限規格

本規格只準備可測的最小實驗，不是正式 adapter。需求／來源／九欄見 [requirements](requirements.md)。目前主假設未執行，live／跨週留存必須另過 Human 邊界。

## 固定 host、資料與控制

新 E008 候選 `DPKContinuityProbe.xcodeproj` 單一 AppKit Application target、`Sources/DPKContinuityProbe/`。main executable 在同非 root GUI/console user 執行 SecItem；透過 LaunchServices 正常啟動，每 process 一個 operation 後保存結果並退出。無 helper/daemon/產品 UI，視窗僅顯示階段，無跳關／手動寫 token 按鈕。

新 UUID namespace、bundle ID `local.rivet.dpkcontinuity.<無連字號UUID>`、固定實驗 App 安裝路徑。Keychain Sharing capability 僅一 app 專用 group `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`；Xcode解析，完整 group 等於已簽 App identifier，不能手填 Team ID 或縮為 bundle ID。使用 DPK=true、synchronizable=false、generic-password、UUID service/account、AfterFirstUnlockThisDeviceOnly，不加 user-presence/biometry/ACL。不 silent fallback、不 update/rewrite、不列舉別人項目。

六欄 fixture 固定假 A：accessToken、refreshToken、accessTokenExpiresAt、refreshTokenExpiresAt、tokenType、grantedScopes，JSON單筆編碼；延用 E006/E005 語意但只引用已合併來源，不改其 source。新 seed 只一次 SecItemAdd，後續只有 read-original 或 exact delete/read-absent，禁止 save-upsert。fixture/query/schema/config與核心 source hashes 凍結；profile cycle只換簽章 profile素材，true rebuild可改獨立 build marker／對應編譯條件，核心不改。

控制：同 Mac/user、同免費來源 Human 聲明、相同 selected leaf certificate SHA、bundle、完整 group、必要 entitlements/query/source/config。P0/P1 實際 profile SHA及建立／到期日期均須記錄，P1 bytes SHA 必須不同且日期證明是有效新profile。驗證其簽署、certificate membership、device/平台適用性與授權覆蓋；允許合法 wildcard覆蓋，不要求profileallowlist字串等於group。P1沿用或certificate混變→profile-only無法判定，不改候選。

每版記實際 executable/App hash、DR、profile/certificate SHA與有效期。binary hash改變不能代替profile變更；profile-only正常restore不強求main hash不同。true rebuild階段另要求編譯marker證據及main hash不同，並維持P1/certificate/group；DR記錄與解釋，不拿E006的相同profile/DR gate阻擋已授權profile cycle。

## 準備與 live 的隔離

新增 `scripts/prepare.py`、`continuity.py`、`proof.py`，只實驗需要的函式／手動多窗口 CLI，不建泛用orchestration framework。pure core／store interface與LiveStore隔離。unsigned build固定 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`，無Team值、無帳號資產存取，不launch產物。pure tests用假clock/mock launcher/asset verifier/store，synthetic=true。不得呼叫codesign身份清單、Xcode account、personalprofile/privatecert、Security/Keychain；準備亦不建立真persistent run、arm時鐘或seed。E008 README結果保持未執行。

未來 live 必須同時有適用scope的Human資產授權、跨週留存／recovery授權、當段ready、真實proof及matching immutable manifest。缺任一項在建構live backend／任何livecommand前 fail closed。mock proof絕不作liveproof，不能單靠 --live flag放行。選定App檢查將來只對Human選定素材，不 inventory unrelatedassets；由Human Xcode操作，不呼叫 `-allowProvisioningUpdates`、自行revoke或強迫刪profiles。

expired-host診斷是新harness明確唯讀operation；僅在已授權、P0確實自然過期、同namespace/group/user與原hosthash符合時可嘗試launch/read。不拿改系統clock、偽造日期或關掉guard取代；不得在此模式add/update或轉新group。launch rejected、App guard rejected、實際SecItem結果分開；沒有SecItem call即status=null/callAttempted=false，不能報missing或data loss。

## 手動resume、時間與證據

未來runroot須Human明確選定的非Git、非易消失tmp之私有持久位置，owner-only（0700）且無symlink越界。run manifest/selection/fullprivateproof保留最低必要資訊，不export私鑰，不持久化真token。公開證據只hash/日期/必要bool/有限錯誤分類，無TeamID、certsubject、deviceID、使用者絕對路徑；私人proof在精確清理後移除。新machine/Human/index JSON在第一次落盤前固定UTF-8序列化、terminal LF及鍵排序規則，exclusive-write原bytes後才算SHA；後續不formatter覆寫已完成bytes。pure test驗證序列化可重現且formatter檢查不改bytes，不另建發布pipeline，不回修E006/E007歷史收據。

S06-BOOTSTRAP 使用 immutable anchor → setup-only proof → 完整 global 的兩階段建立，取代「global 一開始必填實際日期」。未來第一次設定前，適用的三份 assets/retention/recovery grants 與 begin-ready 先就新 namespace／私有 root／凍結來源明確成立；exclusive `anchor.json` 固定實際原 t0、globalDeadline=t0+10days、W1 cutoff=t0+25min／deadline=t0+30min、三窗口上限、Mac/user binding、source/config/query/fixture/service/account 及三 grants／begin-ready SHA。anchor 不含猜測的 P0expiry／certificateNotAfter，不接受 E006/E007 舊素材替代；anchor 不是 live authorization。

W1 exclusive 記錄只單向綁 anchor SHA，不要求尚不存在的 global SHA；之後完整 global 綁 anchor SHA 與 W1 SHA，避免互相 hash 循環。setup fresh-ready 必須綁 anchor／W1／適用 grants 與來源，晚於前段完整回報。原 W1 從 anchor t0 開始，等待 ready、Human Xcode 登入／設定／簽章及所選素材檢查全部計入，不補發新 t0。尚未 complete-global 時其他階段及 LiveBackend 一律拒絕。


真App LiveGate相容性限定：W1驗證不可變anchor bytes及SHA、W1→anchor、完整global→anchor/W1的單向鏈，確認namespace/source/config/query/host/grants與原t0/時窗一致，仍要求完整actualproof與另seed-ready才可建構LiveStore。缺anchor/任一binding、hash不符、partialglobal或setup-onlyproof一律拒絕。W2/W3繼續要求既有window.globalSHA256等於globalHash，不走W1例外。只修改LiveGate這一W1分支，其他grants/ready/source/device/expiry/cleanup/RF01–RF06原條件不放寬；不改main/Core/LiveStore功能。需純Swift測W1合法鏈與缺漏/tamper/partialglobal拒絕、W2/W3原鏈回歸，並重建Debug/Rebuilt unsigned產物；不簽章、不launch，不能沿舊Swiftbuild evidence當新revision通過。

setup-only verifier 只允許 Human 明選的本輪已簽 App／source 的實際前提檢查：原 grants/scope、anchor/W1/time、binding/source/freshready 先核對，再依適用授權取得 actual P0/certificate 日期／簽章與 profile/device/group 證據。此入口不得要求已有完整 global；但絕不能執行 App executable、launch、建構 LiveBackend 或呼叫 SecItem，也不能擴成 assets inventory／automatic provisioning。CMS／Security 驗證仍屬另待 Human 真實資產操作授權，當前只可 mock。以窄幅 setup context 供 selected verifier 使用，不建立泛用 bypass。

取得實際素材後，在同 W1 cutoff 前一次 exclusive 保存 actual setup proof／完整 `global.json` 與相應 binding；global.startUTC 必須等於 anchor.t0，globalDeadline 也沿原 t0，並凍結 actual P0expiry／certificateNotAfter／selected hashes。P0expiry必須落在此上限並至少為末段清理預留一個30分鐘窗口，否則不seed。選定certificate實際NotAfter至少覆蓋原globalDeadline+35min；不硬編一年，若未涵蓋不seed。P0於baseline當下有效；P1須於後續讀取/清理當下有效並留至少35min，不假設整個10日P0都有效。

finalize 重新核對原 anchor/W1/grants/source/binding、實際日期與預算，完整 proof 不能只信 caller 宣告；日期／授權不符或到 cutoff 就拒絕，不延長、不更換日期。完整 global/actual proof 成立後，Human 完整 setup 觀察綁 machine SHA，再取得另一次 seed-ready，才可進 baseline；anchor／setup-only proof／setup-ready 均不能替代 seed-ready。設定與簽章提示另記，不混 DPK prompt。

crash/resume/duplicate finalize 不得新時計、重寫既有 bytes 或因部分完成就放行；resume 只重核原 anchor／W1／已寫 proof/global 的一致性，過截止只停止／精確清理。部分 finalization 不具 live 權限；matching bytes 僅可續完尚缺的非覆寫連結，不能換 proof/global 內容。所有新 JSON 延用固定序列化／terminal LF／exclusive-write／先落盤後 hash。setup 失敗保存獨立停止／清理紀錄，零 seed；尚無 SecItem write 明記零假項目，只清 proven-owned setup 私有素材、不碰 Apple assets；無法清理明列殘留。既有 source/evidence approval、RF01–RF06 與 later-window guards 不因此放寬。

最多三個主動窗口：W1 baseline、W2到期診斷＋Human重新佈建/P1 read、W3 true rebuild＋cleanup。各window在第一筆當段設定／live操作前exclusive保存start/cutoff+25min/deadline+30min，Human/Xcode/簽章操作計入；不能arm後重設。等待是明確retained狀態，不跑背景timer/automation/daemon。若window不足不增第4個測量窗口。globalDeadline或windowcutoff一到禁止新測量；未運行程序不保證自動喚醒／清理，必須明列Human手動回來復原責任。

每次resume核manifest hash、namespace、凍結項、系統實際UTC、已使用window序號與既有exclusive收據；不重seed、不重計10日。用`read-stage`類手動resume，不自動排程。每段機器receipt含起訖、window/phase、實際hash/profile/cert驗證、callAttempted/OSStatus、六欄bool、launch/guard/classification/cleanup，machine提示null保留。sidecar綁receiptSHA、wholeStageObserved、phaseIdentified、promptCount及actions/purposes。gate引用上一matchingSHA、觀察及freshHumanReady；receipt exclusive、不覆寫。無完整觀察、SHA不符、assets/source/control變更即停測，不依exitcode/耗時推提示。

## 狀態與操作

操作固定：begin-anchor/W1（bookkeeping，需另授權與ready）→setup-only inspection（零App executor／launch／SecItem）→complete-global/actual-proof→獨立seed-ready→preflight（無SecItem）→seed-read-A→fresh-read-A→retained/wait→expired-host-diagnostic→Human P1 setup→P1 fresh-read-original-A→retained待W3→true-rebuilt-read-original-A→delete-read-absent。setup／expired診斷／正常read／cleanup的Human觀察各自分段，不合併prompt。

只在baseline完整、matching跨週保留grant/recovery方案已明確、無其他故障時可進retained；W2完整且P1證據成立可依同grant短暫retained至W3。這兩個plannedretention是finally不刪dummy的唯一正常例外，不能籠統以「等待」跳過失敗清理。所有abort、未ready、timeout、無效Humanreceipt或執行失敗優先finallycleanup，禁止續測；cleanup不等下一段正常ready，但需要系統/資產授權仍交Human。

到期前優先原有效host exactdelete/read-absent；到期後使用另獲授權、同完整group有效recoveryhost。取得方式是Human以Xcode重新佈建/簽章同App/cert/group，在seed前須Human接受此程序及失敗處置。quota/帳號/簽章無法取得時不revoke別人資產、不換cert、不付費。清理不能保證總能成功：無有效host即記owned假item可能殘留、任務cleanup未完成，保留最低復原材料，向Human交接，不先把恢復工具刪光。global10日是停止新測量與要求人工cleanup，不保證無程序時自動執行。完成精確delete/read-absent後刪provenowned App/私有proof/runroot，保留去識別證據；Apple開發資產由Human保留管理。

## S06 exact-window 操作 checkpoint（2026-10-22，無source/schema變更）

以下是operator手動核對與安全補充證據，僅適用未來Human另明確批准的新輪，不執行新CLI、不擴現有harness parser或LiveGate。保持原scope/grants/ready/anchor/W1與RF01–RF06/bootstrap guards。所有設定、確認、取Report與等待均計入原W1；第25分鐘停止新操作，最後5分鐘只清理；global10日／三窗／同leaf/fullgroup／不rewrite A不變。

1. **開始停點**：Human明示新輪與適用範圍／最新S／三grant／新namespace-root及begin-ready後，才依既有begin-anchor固定t0。begin machine之完整Human回報後另取得setup-ready；anchor前不得登入帳號或簽章設定。舊closed run不復活。這不是今日新建這些資料的授權。
2. **配置停點**：在既有scope內準備並open同私有project，Human只先選免費Team與合格既有certificate，不Build/Run；無合格cert停問。以獲授權的單一exact project window核對frontmost與所屬project、sharedscheme、application target、initial Debug configuration、同Mac目的地、UUID bundle、Team已選、automatic signing、Info/entitlements與owned build-output設定。UI讀到／Human確認／CLI解析分別記來源；CLI或open exit0不能替代可辨識GUI。不能匹配exactwindow、某項無法核實或讀取需超scope，即停，不能用猜測通過。
3. **Build停點**：配置核對machine與完整Human回報匹配後，另取Human明確build-ready；Human只一次⌘B、不Run。operator不自行Build，不自動重試、不更改scheme/config補救後續跑。沿同窗保留來源，在Report與來源證據核完前不先close；若Human要求先close，先停並說明會失去本階段來源證據，不能close後補作已觀察。
4. **Report停點**：Human回報Build完成後，仍於同exactwindow取得該次Report，確認無search/recent-only遮蔽、All tasks可見，核本次target/config/result與actualproduct來源，將Report與同UUID/privateproject/source/config/output連結。empty／不屬本次／無可核product來源即受控stop；不以CLIshowBuildSettings、template設定或Human「成功」字樣取代Report，亦不據缺Report否定Human宣告。
5. **Host停點**：只在proven-owned product確有Info.plist/main/embeddedprofile、namespace/marker/source對得上時，另依原授權及既有setup-ready/時間規則進setup-only實際selected檢查，再complete-global。GUI/檔案完整性並非CMS/certificate/profile proof；完整setupHuman與另seed-ready仍是baseline必需。若原ready已不適用或過期，先停依原schema另取得適用ready，不回填／覆寫舊ready。

### 未來安全補充證據欄位

operator可依實際觀察另存canonical/exclusive machine與Human sidecar，chain綁前一收據／matching machine SHA；這些是人工操作補充，**不是程式已新增讀取的強制欄位或自動GUI gate**。原CLI ready/phase/ticket/proof格式不變；不得把新operator build-ready塞進CLI當seed-ready。原setup Human回報仍須於真正setup完成才填，不能預填。

machine按實際適用內容留namespace/anchorSHA/windowSHA/sourceMapSHA/previousOperatorReceiptSHA、起訖與checklist：`actualReadUI`、`matchingPrivateProjectWindow`、`frontmostMatched`、`schemeMatches`、`appTargetMatches`、`configurationMatches`、`MacDestinationMatches`、`namespaceBundleMatches`、`TeamSelected`、`automaticSigningObserved`、`InfoEntitlementsMatch`、`ownedOutputSettingsMatch`、`GUIReportObserved`、`reportMatchesThisBuild`、`reportFiltersUnmasked`、`actualProductProvenanceEstablished`及其可公開hash。每項來源標GUI實讀／Human回報／CLIparsed／未驗；未驗值null，不把CLIparsed升成UIobserved。GUIReport target/config/result如含私人值只存匹配bool/hash，不輸出原始文字。promptCount留null，Human sidecar才依全程觀察記count/actions/purposes並綁SHA；build-ready以獨立operator sidecar明確記Human當下答覆及配置收據SHA，不偽造既有CLI gate。

不存raw AX、私有project/product path、TeamID、certificate subject、deviceUUID、私鑰或token。必要private location僅本輪已授權私有控制資料使用，公開僅bool/hash。若單一exactwindow／現有入口無法完成某核對或證據綁定，具體記缺哪項並停止，不自行改source/schema、建立泛用UI框架、擴掃其他windows/全域DD/資產。bootstrap failure沿原先durable export-before-delete／zero-item精確FS cleanup；未App/SecItem時不能稱DPK delete/read-absent完成。
