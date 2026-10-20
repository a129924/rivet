# GitHub OAuth 正式憑證儲存：技術契約

- Topic：`github-oauth-credential-persistence`；受限執行契約；規劃審查及修訂結果見 [evidence/planning-review.md](../../plan/github-oauth-credential-persistence/evidence/planning-review.md)。
- 配對：[需求](requirements.md)、[計畫](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.plan.md)、[帳本](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.step.md)。

## 1. 既有邊界與 additive API

GitHubIntegration 仍是 non-BC。既有 `OAuthCredentialStore.load/save` 維持 async typed throws(any Error & Sendable)；bundle 六欄、fetcher、provider、snapshot、scope／clients／Package.swift 不改。沒有既存 OAuthCredentialStoreError 型別可沿用，不建立 shared BC failure contract。

新增 `GitHubOAuthAppConfiguration: Sendable`，public immutable clientID／clientSecret，`init(clientID:clientSecret:) throws(GitHubOAuthAppConfigurationError)`；空字串拒絕、不 trim，有限 enum 僅 invalidConfiguration。description／debugDescription／customMirror 全脫敏，不輸出 ID 或 secret。

同檔新增 `GitHubOAuthAppConfigurationStore: Sendable`：`load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration?`、`save(_ configuration:) async throws(any Error & Sendable)`。

新增 `GitHubOAuthDataProtectionStores: Sendable`：
- public `init(accessGroup: String, service: String = "local.rivet.github.oauth.v1") throws(GitHubOAuthDataProtectionStoreError)`；空 group／service 或含 wildcard 的 group 在建立時回 invalidConfiguration，不呼叫 Security。
- public `configurationStore: any GitHubOAuthAppConfigurationStore`。
- public `inspectCredential() async throws -> GitHubOAuthStoredCredential?`。
- public `credentialStore(clientID: String) -> any OAuthCredentialStore`。
- `GitHubOAuthStoredCredential: Sendable` 公開唯讀 clientID、credential（完整 bundle）；建立由內部驗證後進行。
- `GitHubOAuthDataProtectionStoreError: Error, Sendable` 僅 denied／unavailable／corrupt／identityMismatch／invalidConfiguration，無 associated payload。
- bound clientID 空字串於 operation 回 invalidConfiguration，且不得呼叫 Security。bound load 完整 decode 後比較 ID。bound save 在同一 actor operation 先讀完整 existing envelope；已有不同 ID 回 identityMismatch，corrupt／denied／unavailable 原樣回有限分類，均零 write；不存在或同 ID 才以綁定 ID 建完整新 envelope並寫入。不新增 clear／repair API。

Configuration／stored credential 的 diagnostics 均脫敏；不變更既有 bundle 的 reflection 契約或宣稱防止記憶體／debugger 存取。

## 2. 同步 Security seam 與 actor

同一 stores facade 建立唯一 internal actor；configuration store、inspect、各 bound stores 均共用它，不設 global singleton／registry。各 actor operation 內的 validate／codec／Security read-check-write 或 update-add-update 全程同步，無 suspension point，避免 actor reentrancy 拆開完整操作。不同 facade／程序不承諾協調。

internal Sendable Security seam 提供同步 copy／update／add，production wrapper 只在實際 operation 呼叫 SecItem APIs；public API 不暴露 seam。測試用 internal initializer 注入 fake，觀察完整 query／attributes／calls，禁止 live Security side effects。Fake complete-item commit 或失敗不變；不靠 sleep 測排序。

DPK generic-password service 預設 `local.rivet.github.oauth.v1`，account 分別 configuration／credential。每次操作明指定 class、group、service、account、`kSecUseDataProtectionKeychain=true`、`kSecAttrSynchronizable=false`；copy 指定 matchLimitOne／returnData。Add 指定 AfterFirstUnlockThisDeviceOnly，無 access-control／presence／biometry／ACL。Update 僅完整 value Data；查無才 add，duplicate 才補一次完整 update；最後狀態直接分類，不再 retry。無 delete API。

Read errSecItemNotFound → nil；errSecAuthFailed／errSecUserCanceled → denied；errSecDecode 或成功但非 Data／無有效 payload → corrupt；其他非 success（含 interactionNotAllowed、missing entitlement、notAvailable）→ unavailable。Write 只有 success 為成功；authFailed／userCanceled → denied，decode → corrupt，其餘 → unavailable。原 status／underlying error 不出現在 public errors／logs。

## 3. Strict codec、替換與 provider

Private JSON DTO，不為公用 bundle 增加 Codable：
- configuration：schemaVersion=1、完整 clientID／clientSecret。
- credential：schemaVersion=1、clientID、accessToken、refreshToken、accessTokenExpiresAt、refreshTokenExpiresAt、tokenType、grantedScopes。
- schemaVersion 必須 Int 1；必要欄位型別正確；ID／secret／tokens 非空；tokenType 只接受 bearer；scope 為字串可空。日期為有限 JSON number millisecondsSince1970，換算 Date 後也有限；允許過期值。額外未知 keys 忽略，未知 version／缺值／null／型別錯／invalid value 整筆 corrupt。
- inspect 與 load 共用唯一 codec；不從壞資料擷取 ID。讀取 decode failure 為 corrupt，bound mismatch 為 identityMismatch；save 的無效 bundle 為 corrupt且零 Security write。

完整 payload 先成功 encode 才操作單一 item。整個 value 一次替換，不逐欄寫，不 delete、不 rollback 補舊值。失敗不回保存成功；fake 可證明失敗保留完整 A、成功換完整 B。真 Security commit／durability 不以 fake 測試宣稱已實證；兩 items 不具 transaction，configuration-first partial-save 不回滾已保存設定。

Adapter 不自行 refresh、retry lifecycle、建立 provider 或決定 UI repair。以既有 provider＋受控 fetcher／clock 驗證 restore／rotation；accepted remote rotation 保存失敗後同一 provider terminal persist、後續無額外 refresh／save。保留舊 item 不表示遠端舊 token 有效。

## 4. 文件與工具

一張 `storage-sequence`（Archify sequence）描述 inspect／bound restore、完整 rotation save，以及保存失敗回 provider stop；無新責任邊界圖，不新增登入全流程。作者繁中、預設無動畫、omit meta.locale，Viewer／HTML lang 英文 fallback。

Archify 2.16：showcase 九 checks、零 errors／warnings，validate→freeze→deliver；visual-check 四桌面尺寸及兩 theme，人工檢視實際截圖，未 Human 觀察維持 pending，不發布。PR Lens 0.11.0 只於真 diff／實 commit IDs 後在外部 scratch validate/render及讀 manifest；Graphify 0.9.73 每 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1，有既存圖才 bounded query並 source verify，無圖 targeted rg；不 build／refresh／install／改設定。兩輔助工具 fallback 不新增 gate，必要 Archify 不可用則文件交付仍 incomplete。
