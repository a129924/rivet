> **歷史版本：正式產品歸屬與完成宣稱已撤回。** 下方原文保留 `ca00bc074f77fa21a7fac1aaae07dc1059de5b01` 的觀察／hash／verdict；source commit `7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18` 僅供追溯，真人build實際在commit前，仍依原文source-hash provenance，不能改稱由該commit建置。舊host與0提示不冒充搬移後驗收。請讀[新host結果](verification-host-live.md)、[新版歸屬清單](verification-host-manifest.md)及[獨立審查](verification-host-review.md)；profile更新後讀回仍未驗證、使用者已接受限制。

# S08a：正式產品儲存驗收待執行

- 狀態：notExecuted；V06 未驗證；所有 Human prompt counts=null。
- S08a 整體 needs-rework／RF-P01，fake-only 通過詳見 contracts.md。未進行真 credential operations，未讀取／刪除／重設產品資料或修改 Apple assets。

RF-P01 修正與獨立重驗後，root 再協調 Human 選定單一 private Rivet.app 安裝位置與正式產品 App ID，沿用原免費 Personal Team／既有 Apple Development certificate。raw path／Team／profile 只私有設定；repo 僅必要 hashes／布林。機器先核對真正產品來源、有效 embedded profile／同身分 private group、macOS15／Swift6、debug-dylib關與non-Sandbox，不使用 E007 資產。

最短分段：首次正式保存（Human 全段≤1提示）→同 binary 真正退出／重啟（0）→同身分真正重建、同安裝位置啟動（0）→真 rotation 保存後新程序還原。每段先 Human ready、結束等完整觀察；機器不填 prompt0。私有 project copy／DerivedData 如有需要，先核對同 feature source hashes／實際 products provenance，不改版控注入私人身分、不用 CLI provisioning updates。

產品憑證保留；不得擅刪、rollback 舊 token 或套用 E007 cleanup。遇新 certificate／安全設定／付費／不明安裝衝突即停止，保留原資產。denied／unavailable 只明確重試；accepted rotation 保存失敗維持停止／重新授權契約。這是既有 V06 的操作準備，不新增 gate 或驗證框架。


## RF-P01 重驗及位置準備現況

RF-P01已獨立通過29hosted／三檔checks，無requiredfix。Human已選個人Applications中的Rivet.app固定位置，唯讀preflight：目標不存在、parent是目前user擁有的非symlink目錄；位置SHA-256=`4c67ba05977057c032438aa0399114ea61784448c4a43046a409ce333dff968b`，未安裝／寫該位置。已在自有0700private scratch準備正式projectcopy：只rebase localpackage到本feature，其他host／scheme／resource／test copy hashes相符，linkedpackagesourcehashes在私有manifest；projectlint0，無Team／profile操作、無live開始。

目前human-check：只等當段freshready，之後先由Human在私有project指定本輪project-specific DerivedData、選原PersonalTeam／既有certificate，確認正式產品AppID及group並Build；機器核對簽章／有效profile／來源後，才分段開始儲存與提示觀察。先前notExecuted／prompt=null維持。raw位置與manifest僅private，不入repo。


## 正式輪開始與首段停點

Human 實際 fresh ready「現在可以配合，開始正式驗收」，本輪開始 UTC 2026-10-20 08:25:01（台灣16:25:01）；這不是 E007 舊窗口。已透過 Xcode UI 開啟本輪私有正式 Rivet project、設定 project-specific owned DerivedData、到 Rivet Target Signing & Capabilities。尚待 Human 選原 Personal Team／既有 certificate並回報本段提示，不擅填0；未 Build／Run、未 credential存取或 browser。其餘 V06／V07 notExecuted維持。


## 首段 Human 回覆與首次 GUI Build 停止

Human 實際回覆「0 次 可核對簽帳並建置」，接收 UTC08:29:26（接收時刻，不冒稱操作精確時刻）；只綁先前 setup／選Team 段。CUA核對原Personal Team／AppleDevelopment／Signing無錯誤，機器核對privateproject與package來源hash、固定產品ID、ownedDerivedData。隨後正式GUI⌘B因x86_64 App與arm64 localpackage module不匹配而失敗，未Run／credential／browser；這不是簽章／profile拒絕。Build段提示尚待Human回報，count=null，不沿用先段0。停止後不自行重建或改設定，交原Implementer修RF-P02。


本次選Team→首GUIBuildFailed全段，Human後續實際回「0次都沒顯示過」，receivedAtUTC08:31:46（非操作精確時刻）。僅綁這次failed-build phase，promptCount=0；沒有credential存取，不算首存或下一次Build提示。私有projectSHA256=`86ae6ea28f3c5a9518c9de6102ef850368b0e84a7532ffecdf61a99255117645`，ownedGUIactivitylogSHA256=`267d0e8aba97011151e9b166577330cd55ef8efa5446fa785345947a562a190d`；rawlog／路徑只私有manifest。


## 修正後正式產品 build／安裝／首入口

正常GUI BuildSucceeded，真GUI來源／strictcodesign／有效profile／原certificate／目前Mac授權／產品ID-privategroup／Swift6-macOS15／nonSandbox-debugdylib關均由機器核對。Human對RF-P02同步→本次成功Build全段實際回「0次」，receivedAtUTC08:37:40（接收時刻），只綁本成功Build段，與前failedBuild0分開。

目標再核不存在、parent安全後，已將此真GUI產品安裝至Human凍結位置；安裝後signature驗證及binary／Info／profile／CodeResources hashes與來源一致，sameFrozenLocation=true、locationSHA256維持`4c67ba05977057c032438aa0399114ea61784448c4a43046a409ce333dff968b`。無覆寫既有App。正式首launch開始新的storage觀察段，真安裝位置程序唯一且已顯示初次設定畫面；尚待Human輸入ClientID／SecureField與登入，agent未輸入／點授權。首launch→首存全段promptCount=null，不能由前兩個Build段0補填。


首授權後正式App已顯示有效目前帳號，source鏈顯示保存成功／strict provider restore後才有該結果；normalmode沒有初次validationreceipt，initialbundlehash未測、不得補造。Human到browser結束頁的部分回報0（receivedAtUTC08:42:19）已綁partialscope；至App顯示有效結果的完整段提示數仍pending。下一段規劃先完整Quit並核精確PID退出，再同binary／同固定位置observe新程序，不新增browser授權或額外probe。


## 完整首段 Human 觀察與同 binary 真新程序還原

Human對首次launch／設定／browser授權至正式App結果完整段，實際回答「0次顯示授權」，receivedAtUTC08:44:52（接收時刻）；依所問完整scope記promptCount=0，不grill措辭、不把browser靜態字串當唯一成功證據。首次≤1提示判準在此實際段成立。

隨後先CUA確認目前帳號ready／無busy，再正常Quit；機器確認原精確安裝PID已結束，以同binaryhash／固定位置／有效signature，透過本機官方open支援的單次--env observe＋私有新receipt啟動一個真新程序。不用-n／不改globalenv／不以rawexecutable啟動。新PID不同、原PID仍不存在、精確安裝executable唯一；其他同名程序不算本產品、不操作。

實際App直接顯示已連線與有效同帳號、configuration欄位隱藏；未重新輸入／browser授權。App生成owned0700父目錄中的0600exclusive有限receipt，mode=observe、forcedExpiryApplied=false、refreshAttempts=0／accepted=0／saves=0、accountConfirmed=true。完整六欄restoredCredentialDigest與providerLoadedCredentialDigest均為`4c4da8d8ad3e49fdc706d2c5dca5732938045c278fbad77eee695984dd704f61`；receiptSHA256=`96afaa8c557d4f5109844999692026d8816f147e377659451317bdf23a692d94`。這是正式真DPK／真新程序restore，不是兩個fakecoordinator；初normal程序沒有digest仍維持未測，沒有虛構初始比較。

此新程序段Human完整promptCount仍null待回覆，不能先填0；本輪尚未真正rebuild或遠端refresh。


## Same-binary Human結果與真正重建機器結果

Human對samebinary完整退出→新程序顯示結果全段回「皆為0次」，receivedAtUTC08:49:29（接收時刻），該段promptCount=0；與firstconnection／兩個Build段分列。samebinaryfresh-zero判準有實際Human觀察。

真正rebuild段先正常Quit／精確PID退出，GUI CleanBuildFolder成功後，機器確認舊ownedDerivedData/Rivet.app不存在、固定安裝App保留，才正常GUI⌘B。BuildSucceeded的新activitylog含四個確切privatehostsource重新SwiftCompile／link／codesign及Swift6，沒有x86_64命令／外部architectureoverride；formal／linkedsourcehashes不變。新binarySHA256=`8693fbc21152cb7413cd4529934370beb3b9631b0f95ce5102bd4af5f61c14bf`，確與舊binary不同；GUIactivitylogSHA256=`5f753f2dff11c5b3e01cf75e45879a19139b2d74d1db6b8c92dd13c2378a1e01`。不是取舊product假裝重建。

新產品strictsignature／有效profile／原certificate／同產品AppID-privategroup／目前MacprovisioningUDID／macOS15-Swift6／arm64／debugdylib關／nonSandbox均核對成功。profileSHA仍`f8bc28109f7df3933ec3f20772d7d7afe73e7a155d6519e80c6d4b53c57d8802`，此段不是renewal、不補E007unknown。

舊安裝Apphash／所有權／精確PID退出核實後，將舊App保留ownedprivatebackup，以驗好的新產品原子替換同凍結位置；未動credential。新PID同位置observe直接顯示有效同帳號，原PID仍不存在、安裝executable唯一。0600exclusive receipt的restore/providerload完整六欄digest與上一freshprocess相同`4c4da8d8ad3e49fdc706d2c5dca5732938045c278fbad77eee695984dd704f61`；refresh/save=0、forced=false、accountConfirmed=true，receiptSHA256=`1dbae4dc4fdaf6c45688ac2d8b19f8e3be7dd2b6eb159d571ae8e16a041f61ec`。

重建整段HumanpromptCount=null待回覆，不能先判rebuild-zero；controlledexpiry真refresh尚未開始。


## 真正重建 Human0與真 rotation 保存

Human對退出／Clean／Build／替換／新程序帳號結果完整段回「0次」，receivedAtUTC08:53:29（接收時刻），rebuildpromptCount=0。這是同身分真正重建段，不是profile renewal；E007unknown保持。

接著正常Quit並核精確PID退出，用同已重建binary／同固定安裝位置，以expire-restored-once與全新privateleaf啟動一個真新程序。OSclock／保存bundle日期未改，只有原provider的到期判定受控；原productiontokenfetcher仍以真receipt時間處理GitHub回應。

正式0600exclusive收據：forcedExpiryApplied=true、refreshAttempts=1／acceptedRefreshes=1／successfulSaves=1、clockReturnedToRealTime=true、tokenPairChanged=true、accountConfirmed=true。原restored/providerloaded完整六欄digest=`4c4da8d8ad3e49fdc706d2c5dca5732938045c278fbad77eee695984dd704f61`；accepted與persisted完整六欄digest同為`893b2c89ad4b58f66f0a9b15d9bb3f27d6961436c31518e4040e9b92d409bc6d`，與舊bundle不同。receiptSHA256=`32024b80b49135d0017c53e68c5563f1f7063ef156fd3f4b7cebc00e78c61ac5`。現有有限投影只含tokenpair變更布林，沒有個別access／refreshhash；未額外讀rawbundle，不宣稱兩者個別變更已獨立測得。

CUA正式App仍有效同帳號，無busy／保存或連線停止錯誤。上述是真GitHub刷新／真DPK保存，觸發expiry為受控，不是自然等待八小時；productionwiring／accepted等有限事件與UI構成證據，沒有保存rawHTTPbody或tokens。這段HumanpromptCount仍null待回覆，尚未做rotation後新程序observe。


## 真refresh段Human0與輪替後真新程序durability

Human對受控expiry退出→真refresh／保存／有效帳號完整段回「0次授權畫面」，receivedAtUTC08:55:41（接收時刻），按所問macOS全段scope記promptCount=0，不把措辭變成新的阻擋或假設另有提示。

之後確認App帳號ready／無busy，正常Quit並核該精確PID退出；同已重建binary／同固定位置以observe而非expire-restored-once及全新privateleaf啟動真新PID。原PID不存在、精確安裝executable唯一，UI直接有效同帳號、不需browser再授權。

0600exclusive有限receipt：mode=observe、forcedExpiryApplied=false、refreshAttempts=0／accepted=0／saves=0、accountConfirmed=true；restoredCredentialDigest與providerLoadedCredentialDigest均為`893b2c89ad4b58f66f0a9b15d9bb3f27d6961436c31518e4040e9b92d409bc6d`，精確等前真accepted=persisted新bundle、不同pre-rotation舊bundle。receiptSHA256=`cbc5b4a634fe57bb99d3bd2297c85377249b75be5f10ea92b93809488fdc7e7c`。真完整退出／不同PID與installedbinary來源有外部核對，非以observationUUID假裝freshprocess。

最後durability段HumanpromptCount仍null待回覆，S08a尚不預填整體approved。產品憑證與目前可用App保留；必要privateprovenance／receipts／GUIactivitylogs與ownedbackup先保留供獨立Reviewer，未刪Appleassets或安裝App。


## S08a 最終結果：正式真儲存驗證通過

最後輪替後退出→未強制到期的新程序帳號結果完整段，Human實際回「0次授權畫面」，receivedAtUTC08:58:02（接收時刻），promptCount=0。S08a Tester verdict=`approved`、requiredFixes=`[]`，只交S08b獨立Reviewer，不代其審查或S11最終Human接受。前述notExecuted／pending段落為當時準備及逐段歷史，此處為最新實際結果。

| 正式產品路徑 | 真機結果與受控界線 | Human全段macOS提示 | receivedAt UTC（非操作精確時刻） |
|---|---|---|---|
| 首次設定／授權／保存／帳號 | 真browserOAuth、真DPK、正式入口有效帳號；保存及strictload先後由凍結source與UI結果補證；normal初程序無digest不補造 | 0（符合首次≤1） | 08:44:52 |
| 同binary完整退出／新程序 | 精確PID退出、不同新PID、同binary／位置；observe六欄restore=providerload、API同帳號，refresh/save0 | 0 | 08:49:29 |
| 同身分真正重建／新程序 | GUIclean後舊product消失、重新compile/link/sign、新binarybytes不同；同ID/group/cert／有效同profile；observe六欄hash同前、API同帳號 | 0 | 08:53:29 |
| 受控expiry／真遠端refresh／完整保存／API | 僅provider到期判定受控，真GitHubfetcheraccepted1、真DPKsave1，accepted=persisted新六欄hash、pairchanged，保存後回真clock；非自然等待8h | 0 | 08:55:41 |
| 輪替後完整退出／未強制新程序 | observe新PID，六欄restore=providerload=前accepted/persisted新hash，與舊不同，forcedfalse／refresh-save0，API同帳號 | 0 | 08:58:02 |

這些prompt數來自逐段實際Human回覆，非機器估計；rawPID／UUID／路徑／profiles／signing設定留私有manifest。真profile為有效前提，這輪未更新profile，不外推E007renewal／過期恢復／certificate rotation／公開發行；E007兩輪仍unknown，Human只接受該未知。

保留目前固定位置的可用Rivet.app及兩個真DPKitems，不Quit、不delete／rollbackcredential。待S08b核證後，privateownedsourcecopy／DerivedData／舊Appbackup／公開certificateDER copies／GUIlogs與有限receipts可依證據保存需要精確列為清理候選；目前先保留供審查，不自行清除。Appleprofiles／certificate資產不屬清理候選。
