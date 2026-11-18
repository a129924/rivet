# OAuth 冷啟動連線還原

`GitHubOAuthStartupRestorer` 是 non-BC GitHubIntegration 的 caller-owned actor。呼叫端為單一GitHub.com OAuth連線保留唯一owner；`restore()` 讀既存設定、組裝provider並沿既有scope準備，取得本地ready或有限未完成結果。它不新增BC、產品登入UI或遠端帳號驗證。

## 公開使用
```swift
let stores = try GitHubOAuthDataProtectionStores(accessGroup: entitledPrivateGroup)
let restorer = GitHubOAuthStartupRestorer(stores: stores)
let outcome = await restorer.restore()
```
Host依原DPK契約提供有效簽章與explicit access group；建構不做Security操作。Ports-based initializer可供caller組裝與受控使用，不公開provider、token或transport控制。

## Outcome
ready(GitHubClientScope)、notConfigured、notSignedIn、authenticationRequired、failed、cancelled、busy皆為Sendable結果。Failed保留有限configuration-store原因、configurationLoad、fetcherCreation、既有preparation error或無payload preparationFailed；不附任意underlying error／秘密。
Configuration nil才是notConfigured，credential nil才是notSignedIn；讀取故障不得誤報未登入。Ready只表示本地準備與必要保存成功，不保證遠端認證、repository權限或後續request。

## Owner與取消
同owner執行或收尾時重疊立即busy。Provider尚未建立時可明示重試組裝；建立後固定同instance與clientID，不重讀設定、不快取ready、不自動retry、不繞過terminal。
每次只沿GitHubClientScope.prepare一次，不前置snapshot。所有已交付scope共用原provider；原single-flight、refresh／401與rotation policy不變。
Task取消後仍等tracked work及原provider工作settled才解除busy；發布前取消不交付ready。成功保存不rollback，流程不clear、signOut、互動登入或切換帳號。
Caller不得建立第二個仍可寫入同credential的owner來繞過狀態；跨程序唯一writer不在保證範圍。

## Goal / Non-Goal / In-Scope / Out-Of-Scope
Goal為既存連線正式還原；Non-Goal為產品登入與遠端權限保證。In-Scope含正式組裝、有限結果、取消／busy／明示重試及受控consumer；Out-Of-Scope含首次登入、重新授權、清除、PAT、多帳號、UI、跨程序、migration；live原不在實作Mission，2026-11-18依Human追加授權另作E018驗證。

## ReadOnly / Written / Modify / Deleted
既有production Sources／manifests為ReadOnly；Written為新增actor、outcome、root／consumer測試、topic artifacts與本長期說明／必要圖。Modify為既有四份導覽／採用文件及StaticIsolation expectedPaths的必要兩檔登記；Deleted無。Floorplan產物僅本機ignored，不commit。

## TestCase與證據
TC01–TC11由17個owner tests、3個public consumer tests及既有scope／provider／clients回歸涵蓋；另含參數化情境。獨立Tester：root375tests、consumer22tests、strictformat、明確159Swift檔strictlint與diffcheck通過。原lint script的vendor build污染失敗與替代驗證分列，不改vendor或config。
TC12 Floorplan先planned blueprint後原碼map，13files、0unassigned、13/13描述；只導航topic及直接依賴，非全repo／完整Swift語義圖。
[責任canvas](diagrams/github-oauth-startup-restore-runtime/index.html)、[還原lifecycle](diagrams/github-oauth-startup-restore-runtime/restore-lifecycle-v3.html)與[驗證及限制](diagrams/github-oauth-startup-restore-runtime/BUILD.md)保留各自證據。原受控實作及圖的Human最終review仍pending；後續E018結果另列，不繼承E014的live結論。

## 2026-11-18：E018 有限 live 結果

正式入口已在真DPK與GitHub.com上完成既存連線還原：first讀入已到期credential，prepare真refresh accepted1／完整save1後ready，配置保持、完整readback及GET/user成功；同signedbinary新process的fresh讀回first最後保存值、同帳號與ready，refresh0／save0。Human各段全程觀察0提示，獨立attestation綁原machine收據，不回填原unknown欄位。

本輪使用既有有效profile與原certificate，但新host AppID不同於舊E014；只給被profile允許的exact舊group，未啟動或重簽舊App。結果不證明舊AppID的profile續期、其他環境或公開分發。日期HMAC為整毫秒canonical比較，不宣稱原JSON bytes相同。

[本輪結果與安全收據](../../plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)分列準備、離線、live、Human與獨立審查。first/fresh各1/1已用完，停止重試；未新登入、清除、強制到期或回滾rotation，正式Sources與root manifests不變。Human最終topic接受仍pending。

## 正式 hosted integration 測試設施

[正式測試設施](../../Tests/GitHubIntegrationHostedTests/README.md)取代 active E018 工具：薄 signed App host 僅供 lifecycle／權限，hosted Swift Testing bundle 組裝唯一正式 runtime 並作斷言；既有 fake／consumer 保持。Offline 為日常明確入口，真 DPK／OAuth 手動測試需另行授權，不從舊驗證 App 推導環境。這是測試設施，不是產品 handler 或新實驗；產品 E2E 待正式 App／啟動組裝交付。原 E018 來源以 `0debe0b` Git 歷史保留，所有有限 live 證據、SHA 與 Human 觀察不改寫，也不當作新設施通過。
