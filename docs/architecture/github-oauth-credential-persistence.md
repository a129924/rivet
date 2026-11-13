# GitHub OAuth 憑證儲存

`GitHubOAuthDataProtectionStores` 是 non-BC GitHubIntegration 內的 DPK adapter。它只保存／還原，provider 繼續擁有 restore、expiry-first refresh、rotation persistence 與停止行為。與 E007、初次登入及整套 OAuth 驗證為獨立工作線；本 topic 的 signed validation host 只用於下述受限驗收。

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

2026-11-05 的 [LG81-Cap-R 獨立審查](../../plan/github-oauth-credential-persistence/evidence/live-preparation-review.md)確認，本機指定簽章環境以正式 public adapter、完整假 bundle 及單一隔離 namespace 完成：保存 A→writer 結束→fresh reader A→整筆替換 B→fresh reader B→真正 clean/build 並以同身分簽章→rebuilt fresh reader B。六欄與 ownership、同 attempt 的 report／ACK／final、實際新程序與不同重建 binary、原 certificate／Team／App ID／group／有效 profile／DR／固定位置皆有證據；五個 runtime 的 Human 全程觀察均為 0 提示。[逐段驗收紀錄](../../plan/github-oauth-credential-persistence/evidence/live-validation.md)保留實際結果；其他建置／簽章提示只依各段原文，不把首 sign 的「0 次權限申請」擴成所有提示皆 0。

本輪 live 只涵蓋 credential item，沒有因此驗證 configuration item、系統拒絕、crash／斷電 durability、跨程序 refresh 協調、真 OAuth／遠端 refresh／API／產品登入或其他 OS／公開發行／簽章環境。模擬 backend 的失敗一致性也不構成系統原子性或斷電證據。Cleanup（LC06）未做且本輪不授權；原資產、ownership proof、失敗／unknown 及已耗額度均保留。圖的 Human 視覺接受與 topic Human review（S08）仍 pending，不以技術審查或 Draft PR 代替。

[保存與還原 sequence](diagrams/github-oauth-credential-persistence/storage-sequence.html)以繁中作者內容呈現；固定 Viewer UI／HTML lang 使用 English fallback。本圖是初始 adapter 交付的歷史 snapshot，補充保存與 provider 邊界，沒有描繪後續驗證 host／authority 流程。原圖 bytes 與技術 QA 沿用，Human 視覺接受仍 pending；本輪不重畫或重新認證此圖。

## 本地 credential 清除

`credentialStore(clientID:)` 現回傳 `OAuthCredentialClearingStore`。`clear()` 在相同 storage actor、無 suspension 的操作內驗證既有 clientID binding，並以完整 class／access group／service／credential account／DPK／synchronizable=false selector 刪除。不存在是冪等成功；identity mismatch、損壞 payload 及 Security 錯誤保留 item 並明確報錯。configuration 與相鄰 namespace 不變。caller 應透過 provider 的 `signOut()` 協調退休和 pending write，不可把單獨 clear 當作停止 refresh 的保證。

此為正式 adapter 能力與 fake Security 測試契約；指定簽章環境的 fresh-process absence 尚未實證。原保存／替換真人證據不當作本次刪除證據。
