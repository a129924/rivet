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
Goal為既存連線正式還原；Non-Goal為產品登入與遠端權限保證。In-Scope含正式組裝、有限結果、取消／busy／明示重試及受控consumer；Out-Of-Scope含首次登入、重新授權、清除、PAT、多帳號、UI、跨程序、migration與live驗收。

## ReadOnly / Written / Modify / Deleted
既有production Sources／manifests為ReadOnly；Written為新增actor、outcome、root／consumer測試、topic artifacts與本長期說明／必要圖。Modify為既有四份導覽／採用文件及StaticIsolation expectedPaths的必要兩檔登記；Deleted無。Floorplan產物僅本機ignored，不commit。

## TestCase與證據
TC01–TC11由17個owner tests、3個public consumer tests及既有scope／provider／clients回歸涵蓋；另含參數化情境。獨立Tester：root375tests、consumer22tests、strictformat、明確159Swift檔strictlint與diffcheck通過。原lint script的vendor build污染失敗與替代驗證分列，不改vendor或config。
TC12 Floorplan先planned blueprint後原碼map，13files、0unassigned、13/13描述；只導航topic及直接依賴，非全repo／完整Swift語義圖。
[責任canvas](diagrams/github-oauth-startup-restore-runtime/index.html)、[還原lifecycle](diagrams/github-oauth-startup-restore-runtime/restore-lifecycle-v3.html)與[驗證及限制](diagrams/github-oauth-startup-restore-runtime/BUILD.md)保留各自證據。Human最終review pending；未執行真人OAuth／DPK或E014，不繼承其live結論。
