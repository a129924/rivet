> **歷史版本：正式產品歸屬與完成宣稱已撤回。** 下方原文保留 `ca00bc074f77fa21a7fac1aaae07dc1059de5b01` 的觀察／hash／verdict；source commit `7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18` 僅供追溯，真人build實際在commit前，仍依原文source-hash provenance，不能改稱由該commit建置。舊host與0提示不冒充搬移後驗收。請讀[新host結果](verification-host-live.md)、[新版歸屬清單](verification-host-manifest.md)及[獨立審查](verification-host-review.md)；profile更新後讀回仍未驗證、使用者已接受限制。

# S08a：正式產品端到端驗收待執行

- 狀態：notExecuted；沒有真 GitHub OAuth／API／遠端 refresh 結果。
- S08a 整體 needs-rework／requiredFixes=[RF-P01]；23 hosted／226 root fake-only 通過不等於產品端到端。

RF-P01 缺口是正式 provider 無受控 expiry clock；修正限既有 host／coordinator／tests，保留正常真時鐘與 token fetch receipt 真時鐘。應明示可用的有限脫敏方式核對真 refresh／輪替保存／新程序還原；能使用既有觀測即沿用，不要求另建 probe／框架。不改 OS clock 或已保存 bundle 日期，不自然等待八小時替代原 V07。

完成修正及 storage-live.md 的 host 前置後，最短真人步驟：在正式 App 輸入自有 OAuth App ID／secret（callback 為 http://127.0.0.1/oauth/callback），完成 browser 授權並取得 GET /user；正常退出後同位置重啟，無重新授權仍取得帳號；再以明確 opt-in 受控 expiry 觸發真 refresh／保存，退出並清除控制條件後，新程序還原輪替結果。只請求 offline_access。

秘密只在正式 App SecureField 輸入，不貼對話或 logs；不保存 raw tokens／secret／code／完整 callback query。每段機器有限結果與 Human 全段提示分列，尚未回報皆保持未驗證；受控 expiry與真 GitHub／真DPK來源分列。E007 unknown／其他 V06–V09 gate 不變，不進 S08b／S09，不新增測量框架。


## RF-P01 已解除，真路徑仍待ready

獨立boundedretest29hosted通過，正常預設／receipt時鐘不變。真驗收已有精確private啟動介面：`RIVET_GITHUB_VALIDATION_MODE=expire-restored-once`＋`RIVET_GITHUB_VALIDATION_RECEIPT=<private不存在leaf>`，僅既有可信credential的新程序；再真正退出，用`observe`與另一新leaf核對restored/provider-loaded digest等於前次persisted，forced=false／refresh=0。前段須accepted=1／save=1、accepted=persisted digest、pairChanged／clockReleased／accountConfirmed；receipt不完整不能算通過。這些仍是方法、不是live結果。

正式privateproject／固定位置preflight已準備，root正等Human freshready；本角色未開browser／liveKeychain／安裝／輸入secret。S08a目前human-check，V06／V07 notExecuted，所有提示null，不越S08b。


正式signed產品已在Human固定位置開啟，顯示初次ClientID／SecureField／儲存並登入畫面；agent未輸入secret、未點登入或掃browser callback。唯一精確安裝程序已確認，真正授權／API／重啟／refresh尚待Human操作與機器驗收。正常GUIbuild缺口RF-P02已獨立解除，S08a仍human-check，非完整E2Epass。


## 首次真授權後產品結果

Human回報曾看見relay靜態結束字串，該字串只證browser完成回應，不直接算產品成功。Tester後續在正式安裝App的CUA有限核對，確實顯示「已連線GitHub／已取得目前GitHub帳號結果」，可見非空login及正數id、配置欄位已隱藏、沒有busy或授權／保存錯誤。未輸出raw帳號、SecureField或browserURL／callback。這是正式入口真授權及GET/user成功的UI證據；對完整bundle保存、provider strictload與有效200結果的先後，由凍結source鏈補證，非另行封包／rawpayload擷取。normal首程序無validationreceipt，不捏造initialdigest；獨立六欄fingerprint留後續observe程序。

Human先前到browser靜態回應的有限0提示，receivedAtUTC08:42:19；正式App結果確認後的全段觀察仍待Human回覆，不能直接填完整段0。還未退出／新程序restore／rebuild／真refresh，故S08a仍未全通過。


首次完整正常程序授權→保存→有效帳號結果，Human全段0（receivedAtUTC08:44:52）。其後真Quit／原PID退出→同固定位置與binary的新PID，無重新授權直接GET/user同帳號結果；有限observe收據restored/providerload六欄hash相等、無forcedexpiry／refresh／save、accountConfirmed。詳見storage-live.md；新程序段Human提示尚待回報，不把UI或機器無對話推成prompt0。rebuild／真遠端refresh未執行。


Samebinary完整段Human0（receivedAtUTC08:49:29）已到。接著真正GUIclean／重compile-link-sign，新binarybytes不同、同identity／有效profile，在舊精確PID退出後同固定位置替換，新PID直接還原有效同帳號，六欄hash與先前samebinary相等且沒有refresh或save。這是正式真rebuild-path；本段Human提示尚待回報，真refresh仍未執行。


真rebuild完整段Human0已到（receivedAtUTC08:53:29）。受控provider expiry→原正式GitHubfetcher真refresh accepted1→真DPK完整save1→解除控制回真時鐘→有效GET/user同帳號已完成，finiteaccepted/persisted六欄hash相同且與舊不同、tokenPairChanged=true。這不是自然等八小時，也不是fakefetcher；詳見storage-live.md。此段Human提示待回、rotation後新程序還原尚未做，不提前完成S08a。


受控expiry真refresh完整段Human0（receivedAtUTC08:55:41）。隨後真Quit／原PID退出→同binary同位置observe真新程序，沒有強制到期／refresh／save，正式GET/user同帳號有效，嚴格六欄restore/providerloadhash等前accepted=persisted新bundle且不同舊bundle。最後段Human提示等待，機器成功不代填0或整步approved。


## S08a 最終產品驗證結論

Tester verdict=`approved`、requiredFixes=`[]`。首次真授權／保存／有效帳號、同binary真新程序、真正重建同身分新程序、受控expiry觸發真refresh與完整rotation保存、輪替後未forced真新程序五路徑均已實際成功；五段Human各0提示，最後receivedAtUTC08:58:02。完整逐段時間／來源／receipt SHA與六欄fingerprint見storage-live.md。先前pending與needs-rework保留為過程歷史，RF-P01／RF-P02均經獨立證據解除。

真與受控／fake界線：live使用正式signed產品、真GitHub／真DPK／真程序與真GUI重建；到期只有providerclock受控，原tokenreceipt真時鐘／OSclock／stored日期不改，不聲稱自然等8h。取消／denied／callback-invalid／技術失敗／accepted-save-failure／terminal／settlement等由已獨立fakecontracts證明，不捏造成真人故意破壞產品憑證的live測試。normal首程序沒有validationdigest、個別tokenhash未測不補造。

尚未驗證／本階段未交付：profile更新與過期恢復／certificate rotation／公開發行、Intelhost、V09文件圖工具／最終成果審查、S11Human整體接受／DraftPR後review。不是全topic完成或S08b approval。現在交獨立S08bReviewer，保留可用installedApp與livecredentials，不擅清Appleassets／私有review證據。
