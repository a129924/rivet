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
