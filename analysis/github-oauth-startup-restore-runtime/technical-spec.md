# OAuth 啟動還原執行設計

基準 d2332bf；non-BC GitHubIntegration，不新增 BC。參照 requirements.md 與對應 plan。

## Public contracts
新增 Sendable GitHubOAuthStartupRestoreOutcome：ready(GitHubClientScope)、notConfigured、notSignedIn、authenticationRequired、failed(GitHubOAuthStartupRestoreFailure)、cancelled、busy。
Failure 為 Sendable 有限 enum：configurationStore(GitHubOAuthDataProtectionStoreError)、configurationLoad、fetcherCreation、preparation(GitHubClientPreparationError)、preparationFailed，不保留任意 underlying error 或秘密。
新增 public actor GitHubOAuthStartupRestorer，restore() async -> GitHubOAuthStartupRestoreOutcome。
正式 init(stores: GitHubOAuthDataProtectionStores)；ports init(configurationStore:makeCredentialStore:makeTokenFetcher:)，後兩者為 Sendable factories，fetcher 預設 GitHubOAuth.makeTokenFetcher。建構不操作 Keychain／網路，不暴露 provider／token。

## Locked lifecycle
第一個 suspension 前保留 tracked Task，重疊立即 busy。Task cancellation handler 取消本次 tracked task，仍 await task.value；prepare 等 provider 既有工作 settled。設定 load 及發布前檢查取消。
Provider 尚無時可重讀設定；nil、load 或 factory 錯誤不建立半成品。成功組裝後保留唯一 provider，之後失敗／取消均不重建或切換設定。
每次 restore 僅呼 GitHubClientScope.prepare(provider:) 一次，不前置 snapshot、不自動 retry、不永久快取 scope。Provider 原 terminal、single-flight、rotation policy 保持。取消不 clear／signOut、不 rollback 已成功 save；解除 busy 僅在 tracked work settled 後。
已發布 scope 不因日後取消撤回。多 scope 共用唯一 provider，不增加 writer。

## Error mapping
Configuration nil -> notConfigured；load CancellationError／URLError.cancelled 或 caller cancellation -> cancelled；已知 configuration store error 保留有限 case，其他 -> configurationLoad。
Factory error -> fetcherCreation（取消優先）。Scope missingCredential -> notSignedIn；authenticationRequired -> authenticationRequired；其他 preparation error -> failed(preparation)；取消 -> cancelled。未知且非取消的 prepare error 一律 failed(.preparationFailed)，不附原文，不誤標既有 preparation stage。

## 文件與圖
Architecture-canvas 描述責任；archify lifecycle；Floorplan 補 planned files／實作後 source navigation，不替代架構真相。Floorplan plan.json.source 使用本 technical-spec，endpoints=[]；不新增 docs/prd.md。只做 bounded topic＋直接依賴，原碼 scan 的 inventory 為全 repo，board／descriptions 用 ignore 限定；無法限定則回報限制。
Floorplan 本機 ignored、不 commit、不執行 open/server/Ask/network；不修改 AGENTS、CLAUDE、根 gitignore、Git config 或索引。保留既有使用者內容。
Graphify 缺圖時用 rg，不建圖；每次 CLI 必設 GRAPHIFY_NO_AUTO_REFRESH=1。PR Lens 使用實際 diff／commit IDs，固定本機 CLI，外部暫存輸出，不發布。

## E018 live contract
新實驗host直接連結此worktree public GitHubIntegration。新host採現有有效profile之AppID，同原signer，單一exact舊E014 keychain group／service；不修改既有Apple assets或舊App。AppID差異與自然refresh有無分別記錄。
Controller前置source/signature/profile/unique-writer核對、exclusive first/fresh markers與actual-process hello/authorize握手。Wrappers pass-through，不為觀察多呼provider.snapshot或改expiry；six-field HMAC只作本機比較。每階段一次120秒；first機器結果與Human觀察／退出完成才fresh。所有錯誤停且不自清資料；只固定安全projection。

完整readback oracle固定為GET/user完成後最後成功save的完整bundle；若無save則最後成功load。Prepare計數在ready交付時freeze，API階段計數另列，避免將401 recovery輪替歸入啟動prepare。Fresh最初load須比對first最後persisted digest，不拿初始或ready快照當最終oracle。

## M：正式 hosted integration 測試設施修訂

本節為目前正式測試設施設計；前述 E018 live contract 保留為 `0debe0b` 的歷史契約，不是新設施的執行依賴。正式 runtime、public API 與既有 lifecycle／error mapping 不變。

### Targets / configurations / schemes

設施根目錄固定為 `Tests/GitHubIntegrationHostedTests/`，project 為 `GitHubIntegrationHostedTests.xcodeproj`。不另鎖定 Host／Tests／TestSupport 子目錄。

- `GitHubIntegrationTestHost` App target：薄 App lifecycle／event loop；不自行 restore、不含 first／fresh case。
- `GitHubIntegrationHostedTests` hosted test bundle：一般 import 正式 GitHubIntegration／RivetHTTPClient products，以 `TEST_HOST`／`BUNDLE_LOADER` 進入 host。Arrange、pass-through observers、Act、API／完整讀回與 Swift Testing assertions 均在測試碼。
- `Offline`／`Live` build configurations，對應 shared schemes `GitHubIntegration-Offline`／`GitHubIntegration-Live`。Offline 只使用 fake、無 DPK restricted entitlements、可 ad-hoc 執行；Live 才使用明示提供的有效 profile／signer／exact group／service。不得從已安裝 E014 App 推導配置。

```text
runner
└─ xcodebuild：建置、選定測試、產生 .xcresult
   └─ GitHubIntegrationTestHost
      │  Offline：fake、無 DPK restricted entitlements
      │  Live：合格 signing／profile／exact group
      └─ GitHubIntegrationHostedTests（注入的 test bundle）
         ├─ Arrange：測試依賴組裝
         ├─ Act：唯一 GitHubOAuthStartupRestorer.restore()
         └─ Assert：結果、API、完整讀回與計數

未來產品 E2E（本輪不建立）
XCUIApplication → 正式 Rivet App → 產品啟動組裝 → 使用者可觀察結果
```

Host 是具權限的測試執行容器，不是產品 handler 或另一個 E。上述目錄與命名是本案選擇。

### Runner / CLI

固定入口 `scripts/check-github-integration-hosted-tests.py`。無參數等同 `--offline`；Offline 先執行 driver 受控測試，再建置 hosted smoke。一般 `swift test`、consumer 與既有 hooks 不變；不因目錄位於 Tests 就自動執行 Xcode project。未來 CI 只能明確使用 Offline 命令，本輪不新增 CI workflow。

```sh
python3 -B scripts/check-github-integration-hosted-tests.py --offline

# 以下僅為未來已取得明確授權後的手動介面；本輪不執行。
python3 -B scripts/check-github-integration-hosted-tests.py \
  --live --context PRIVATE_CONTEXT --run-root RUN_ROOT --phase first

python3 -B scripts/check-github-integration-hosted-tests.py \
  --attest --context PRIVATE_CONTEXT --run-root RUN_ROOT \
  --phase first --fully-observed --prompt-count 0

python3 -B scripts/check-github-integration-hosted-tests.py \
  --live --context PRIVATE_CONTEXT --run-root RUN_ROOT --phase fresh

python3 -B scripts/check-github-integration-hosted-tests.py \
  --attest --context PRIVATE_CONTEXT --run-root RUN_ROOT \
  --phase fresh --fully-observed --prompt-count 0
```

RUN_ROOT 在 first 時為新目錄，後續必須使用同一目錄。Fully-observed 與 prompt-count 依 Human 實答填寫；上例 0 不代表新的觀察。

### Private context / phase budget

Owner-only private context 欄位固定為：`schemaVersion: 1`、唯一 `runID`、可追溯的 `authorizationRef`、`bundleID`、`signingIdentitySHA1`、`profilePath`、`profileSHA256`、`accessGroup`、`service`、`fixture: "existing"`、`budget: {"first":1,"fresh":1}`。
Context 只記錄當次已取得的明確 Human 授權與環境輸入，本身不是授權；不得含 token／client secret，本輪不簽發或執行 context。
同一 context 的 owner-only sidecar journal 綁定第一個 run-root，以 exclusive markers 消耗 phase 額度，換 run-root 不能重設。不得匯入舊 E018 context／markers 或重用其已耗額度。

### Native test execution / provenance

Offline 與未來 Live 均以一次 `build-for-testing`，兩次選定測試的 `test-without-building` 執行 first／fresh；先列舉實際 test identifiers。停用 parallel／retry／repetition，每段上限 120 秒。此為有官方工具能力支持的工程設計，先以 fake 證明不同實際 PID／starttime、前程序退出、每案恰好一次與相同 host／test bundle／依賴／執行設定 provenance，不僅以兩次命令當作程序分離證據。參照 [Apple TN2339](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)。
Live 在來源與環境資格核對後才進行 Live build／簽章；實際 host hello／授權握手確認程序後，test bundle 才能操作 DPK／網路。first 可遇有效或自然到期憑證，依實際記錄 coverage，不強制到期。
順序固定 first 機器結果成功且程序退出 → Human attestation 綁定原 receipt SHA → fresh → Human attestation。未完整觀察不能放行 fresh；完整觀察但提示非 0 記錄不通過。錯誤停、不自動 retry，不登入／seed／clear。

### Assertions / result contract

Swift Testing／`.xcresult` 判定業務結果，driver 只管理環境、程序、provenance、額度及 Human 綁定，不另外複製 runtime 成功邏輯。遷移原必要觀測能力：ready 時 freeze prepare 計數、API 階段另列；GET /user 後最後成功保存的完整 bundle 為 oracle，無 save 則成功 load；fresh 最初 load 比對 first 最後 persisted digest；完整六欄安全比較及來源 pins 保持責任。只斷言衍生布林／計數，避免 assertion 診斷捕捉秘密。

| Exit | 結果 |
| --- | --- |
| 0 | 指定驗證與所需 Human 觀察完整通過。 |
| 1 | runtime 斷言、執行、結果完整性或程序檢查失敗。 |
| 2 | 工具鏈、簽章或 context 等前提不足，blocked。 |
| 3 | 機器段完成，等待完整 Human 觀察。 |

缺簽章／context 可在 DPK 前 blocked；credential 不存在只能讀取後得知，此時由測試回報失敗，不冒稱全部資格均可前置判定。本輪只驗證 Offline／mock，手動 Live 路徑尚未實際驗證；原 E018 passed 不轉記為新設施 passed。

### 產品 E2E 邊界

查核時無正式 Rivet App target／Sources/main.swift。未來正式 App 與啟動 composition root 交付後，獨立 XCTest／XCUIAutomation target 透過 [XCUIApplication](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication) 啟動正式 App，驗證產品可觀察結果；不依賴本 integration host，不將測試 driver 塞入產品入口。
