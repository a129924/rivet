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

## N：正式 hosted 有限 Live 驗收

本節是 Human 新授權的正式 hosted 有限 Live 契約；M 的未執行 Live 敘述保留為該輪歷史，不阻止此獨立 N 授權。正式 runtime、既有 runner／test bundle／project、context schema 與 exit 0／1／2／3 契約均保持，不藉本次驗收改 source。

### N 來源與環境資格

準備基準為 feature `df801f6`。使用 M 已交付的正式 runner、host／test bundle 及來源／artifact／xctestrun／control pins。已取得的唯讀 inventory 為：一份匹配 profile、對應有效 signing identity／裝置及 explicit AppID；profile SHA256 `6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`，有效至 `2026-11-23T06:19:04Z`；當次 related writers 為 0。這是 inventory 快照，不證明 fixture 存在或 hosted runtime 已可執行，每次必要前置仍須重新核對。
Exact group／service 由 repository `experiments/E014/GitHubConnectionVerification/README.md` 既有公式與目前 profile 的 AppIdentifierPrefix 明示核對，不讀 installed 舊 App 或其 private controls／keys／assets／logs。私有 context 才保存具體 profilePath 等環境值，公開證據不保存原值。
Profile 缺 `get-task-allow` 本身不直接判為不合格；macOS unrestricted entitlement 與目前 hosted／LLDB 資格仍需按實際設定判斷及 preflight，不能因 inventory 即宣稱已通過。參照 [Apple TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)。必要資格未能確認或工具失敗時停止，不更改工具探路。

### N03 純 build-only preflight 例外

正式 CLI 的 first 會在 qualification／build 前 bind context 並建立 `first.attempt`，因此不得用它做準備試跑。允許在獨立新 owner-only preflight root，只呼叫現有 `root_control(root, 'live', ctx)`、`build(root, 'live', ctx)`，完成 Live build／sign、signature／profile／產物驗證與測試列舉。
嚴禁在 preflight 呼叫 `bind_context`、`execute_phase`、`main --live` 或任何 authorize；不得讀 DPK fixture／呼 GitHub／執行 first／fresh。不建立或消耗 context phase journal／attempt。若意外出現 host hello，不 authorize，停止並回報；不能把它算成可重用 first 或成功 runtime。
此例外只涵蓋純建置及能安全核對的資格，不冒稱完整 runtime 已通過。Preflight artifacts 不作正式 first 結果，正式 first 仍使用正常 CLI 在另一新 root 建置並固定自身 pins；不同 root 不是重設已使用額度。

### N context / first→Human→fresh

建立新的 owner-only N context，沿用 M 最小欄位與 `budget: {"first":1,"fresh":1}`，`authorizationRef` 固定參照 `human-2026-11-18-hosted-live-first-fresh`；只用既存 fixture，不包含 raw token／client secret。舊 L／E018 的 context／markers／已耗額度不讀、不匯入。

1. N02 approved、N03 離線／資產／純建置 preflight 完成後，主 session 通知 Human 準備完成；待本輪明確可觀察回覆，才 first。
2. 正常 `--live --context PRIVATE_CONTEXT --run-root RUN_ROOT --phase first`，phase 只啟動一次、不 retry；M 原 120 秒、single writer、原生 Swift Testing／xcresult、actual-process handshake 與來源核對保持。
3. First 機器結果完成且程序退出後，重新詢問本段全程觀察與實際提示次數。僅依實答使用 `--attest` 綁定原 machine receipt SHA；不預填 0、不把先前回覆當本段觀察，不改 machine／projection placeholder。
4. 只有 first machine passed、process exited、Human fully observed 且 prompt count 0 的既有 policy 通過，才執行同一 context／run-root 的 fresh 一次。Fresh 後同樣重新詢問並獨立 attest。
5. 任何 runtime／原生測試失敗、timeout、資格問題、Human 不完整／非 0 提示均停止；不重試、登入、seed、clear 或強制 expiry。

CLI 與 M 相同；attestation 的 `--fully-observed` 與 `--prompt-count` 依當次 Human 實答，範例值不是事實。Context 或簽章資格可先 blocked；fixture 存在／expiry 只能正式 first 讀取後得知，缺 fixture 回報並停止，不以 new root／context 再試。有效憑證還原成功可通過本輪 restore 路徑，但真 refresh 未發生時 coverage 必須明寫未涵蓋。

### N assertions / coverage / safe evidence

業務成功仍由 test bundle 的正式 restore／API／完整 readback assertions 決定，不改 runner policy：prepare 與 API 計數分開，GET /user 後最後成功 save 的完整 bundle 為 oracle，無 save 則 load；fresh 起始 load 比對 first 最終 persisted digest，並核對同帳號、不同實際 PID／starttime、前程序退出與同一受測產物。只使用安全布林／計數／不透明 tags，不輸出 token、secret、raw clientID／account。
新 safe projections／Human attestation 與 SHA 可寫入本 topic evidence 的 `hosted-live-first.json`、`hosted-live-first-human.json`、`hosted-live-fresh.json`、`hosted-live-fresh-human.json` 及 `hosted-live.md`。只寫實際完成的段，未執行不得製造 passed 收據。公開不得含 token／secret／raw clientID／account／profilePath／使用者家目錄或其他私有路徑；raw controls／key／journal／build／machine／Human 等留 owner-only 新 run roots。原 machine placeholder 不回填，Human 綁定另檔保存。
原 evidence／pins／觀察保持 bytes 不變，新結果須獨立 Reviewer，不能把 L／M 通過挪作 N 結果。此為正式 integration 的有限結果，不代表產品 E2E、所有環境或普遍遠端權限。

## N-R：nested test bundle 簽章路徑受限修正

### 固定修正與 ReadOnly 例外

此 project 的實際產物已在 N03 build 證明為 `Build/Products/Live/GitHubIntegrationTestHost.app/Contents/PlugIns/GitHubIntegrationHostedTests.xctest`；不是外置 `Build/Products/Live/GitHubIntegrationHostedTests.xctest`。這是本 project 產物位置，不泛稱所有 Swift／Xcode 測試都必然使用此路徑。
受限允許 `scripts/check-github-integration-hosted-tests.py` 中 `sign_products` 以既有 products 根目錄組成上述 expected nested path；先確認 host 與 nested test bundle 均存在，再依序簽 nested test bundle、host。任一預期產物缺失必須 fail-closed，不以外置 decoy、glob／掃描或其他 fallback 路徑掩蓋。
僅在 `Tests/GitHubIntegrationHostedTests/test_driver.py` 以 mock command recorder／暫存 fixture 做 red→green 回歸：實際 signing target 是 nested bundle、順序 bundle→host、缺 host 或 nested bundle 在任何 signing 前停止；只有外置假目標不能通過。不執行真 codesign／Security／網路作此回歸。
其餘 runner 邏輯、tests／project／正式 Sources／manifests／public contracts、CLI、context schema、phase budget、Apple 資產及舊 evidence 仍 ReadOnly。本節只取代 N 既有 ReadOnly 對上述兩個檔案明示範圍的限制，不擴大任何 Live 授權。

### 修後驗證與來源

修後先完整 canonical Offline 加新增回歸；再於同一私有 parent 下另一獨立 `preflight-fixed` root，沿 N 純建置例外只用 `root_control(...,'live',ctx)`／`build(...,'live',ctx)`，不 bind／execute phase／main --live／authorize／讀 fixture／呼 API。原失敗 preflight root、safe proof 與 source pins immutable；修後 root 使用修後 source／artifact pins，不能將兩次來源合併為同一 frozen run。
同一已建立 N context 保持原 authorizationRef／fixture／budget；沒有 journal、尚未 bind、正式 run-root 不存在。First／fresh 仍各使用 0/1。新的純建置 root 不是 Live phase retry，更不能重設已使用 phase。Reviewer 必須審查修後 source／新 pins；通過後仍須 Human 本輪 ready 才 first。若新的 preflight 再失敗，停止並回報，不暗中擴修或自動嘗試其他 root。

## N-R2：App 內嵌程式碼 inside-out signing 受限修正

本節僅追加 App 複本內 executable code 的受限 discovery／簽章責任；N-R 的固定 nested test bundle 位置及其餘既有契約保持。只可修改 runner sign_products／內部 bounded discovery helper 與 test_driver.py 純 mock／temp fixture 回歸，不修改 project／Swift／其他邏輯／context。Inside-out 依 [Apple TN2206](https://developer.apple.com/library/archive/technotes/tn2206/_index.html) 的 nested code 原則；不是放寬驗證或改 SDK。
候選只取本次建置 App 中的實際 executable frameworks／dylibs 及巢狀 code，resolve 必須仍在 App 邊界內；逃逸立即停止，不能 sign SDK 或 App 外檔案。簽章順序為最內層 code → 外層 embedded code → test bundle → host，host 必須最後；同一既有 identity，僅 host 使用既定 DPK entitlements。Resource-only bundles 跳過；任何內層失敗不繼續父層，保留既有 --deep --strict verify，禁止刪 CodeResources／seal、降格檢查或 --deep --force 簽章。
TDD 只用 mock／temp fixture，涵蓋多 framework＋dylib、巢狀順序、host-only entitlements、resolved path 逃逸停止、內層失敗停止與 resource-only bundle 跳過。修後 full Offline 與新增回歸通過後，同一私有 parent／context 下新 preflight-insideout root 只執行一次既有 helper 純 build／sign／verify／列舉；不 bind／authorize／execute phase／讀 DPK／呼 API。原兩個失敗 roots／proof／pins不動，新 source／artifact pins 獨立審查。若再失敗停止回報，不擴 scope 或自動重試。

### N執行結果與待審邊界（2026-11-18）

正式hosted first／fresh各一次取得ready／API／完整讀回及同帳號新程序continuity，兩段Human重新全程觀察各0提示、原SHA分別綁定。兩段credential未到期，prepare／final refresh與save皆0，無本輪真refresh／rotation-save coverage。兩phase各1/1已耗盡，停止額外操作。原工具缺陷與失敗preflight、受限修正與NR13準備審查、新機器／Human結果各留來源；[新安全結果](../../plan/github-oauth-startup-restore-runtime/evidence/hosted-live.md)已由N06獨立有限結果review approved、無required finding；N07交付中，不改source或原machine。H01／M06及Human最終接受pending。
