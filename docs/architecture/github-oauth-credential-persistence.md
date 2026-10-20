# GitHub OAuth 憑證儲存

`GitHubOAuthDataProtectionStores` 是 non-BC GitHubIntegration 內的 DPK adapter。它只保存／還原，provider 繼續擁有 restore、expiry-first refresh、rotation persistence 與停止行為。與 E007、signed host、初次登入及整套驗證分開交付。

## Caller composition

```swift
let configuration = try GitHubOAuthAppConfiguration(clientID: clientID, clientSecret: clientSecret)
let stores = try GitHubOAuthDataProtectionStores(accessGroup: entitledPrivateGroup)
try await stores.configurationStore.save(configuration)
let credentialStore = stores.credentialStore(clientID: configuration.clientID)
// 初次授權取得完整 bundle 後：
try await credentialStore.save(bundle)
let provider = OAuthTokenProvider(store: credentialStore, fetcher: fetcher)
```

`accessGroup` 必須由具有效 signing／entitlements 的 host 明確提供；空值與 wildcard 拒絕。Constructor 不呼叫 Security。重啟時完整 inspect 的 clientID 是既存身分依據；caller 必須另比較 configuration ID，不把不同 App 設定混用。本 adapter 不實作重新授權、清除或自動修復。

## 保存與失敗

- Service 預設 `local.rivet.github.oauth.v1`；generic-password accounts 分別為 `configuration`、`credential`。每次操作明選 DPK、禁止同步且限定 group／service／account；新增採 `AfterFirstUnlockThisDeviceOnly`。[Apple DPK selector](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain)與[Keychain 實作說明](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)說明系統前提，文件不能代替本機 UX 實測。
- Private JSON schemaVersion=1。設定保存完整 clientID／secret；credential 保存 clientID、access token、refresh token、兩個有限到期日期（millisecondsSince1970）、bearer type 與 scope 字串。允許過期及空 scope；不改 public bundle 為 Codable。
- 各 views 共用同 facade 的單一 actor；同步 read-check-write 中無 suspension。不同 facade／程序不協調。同一 credential item 的 value 完整 update；不存在才 add，duplicate 僅補一次 update。兩個 items 沒有 transaction，設定先存成功不因後續 bundle 失敗而回滾。
- Bound load／save 拒絕不同 clientID；corrupt、denied 或 unavailable 的既存 credential 不被 save 覆寫。Inspect 不從壞資料擷取身分。只有真正不存在回 nil。
- Public errors 是無 payload 的 `denied`、`unavailable`、`corrupt`、`identityMismatch`、`invalidConfiguration`。Auth failure／user cancel 為 denied；interaction-not-allowed／missing entitlement／其他技術失敗為 unavailable。錯誤與診斷不帶秘密或原始系統 error。
- 保存失敗不刪舊 item、不補寫舊資料，不回成功。遠端接受輪替後的本地保存失敗仍由既有 provider 永久停止該 instance，不能推論舊資料遠端有效。
- 新設定與 stored credential wrapper 的 description／debugDescription／reflection 脫敏；不改既有 bundle 的 reflection，也不宣稱記憶體或 debugger 防護。Caller 不應自行印出公開 secret／token properties。

## 驗證範圍

契約測試使用注入的 internal fake Security，涵蓋六欄與設定往返、錯誤、完整替換、不同 views 序列化、受控 provider rotation／persist-stop；跨 target consumer 測試只建構 public API，不呼叫真 Security。

未驗證：真 DPK／磁碟 durability、真正程序終止後還原、signed host、profile 更新、系統拒絕與提示、真 OAuth refresh／產品登入。模擬 backend 的舊資料保留不構成系統原子性證據。

[保存與還原 sequence](diagrams/github-oauth-credential-persistence/storage-sequence.html)以繁中作者內容呈現；固定 Viewer UI／HTML lang 使用 English fallback。本圖補充既有邊界，不重畫其他工作線的架構。
