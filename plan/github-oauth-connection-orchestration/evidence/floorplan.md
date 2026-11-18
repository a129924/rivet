# Floorplan 現況地圖來源與限制

日期 2026-11-17；source revision `ab77391b73291deb1ce3d96cef72f981aeb3104a`。本工作樹 status 為 none、legacy=false，故新建；沒有既有 annotations／notes／custom-flows 使用者內容可覆寫，未刪除來源或憑證。

範圍在 describe／build 前固定為以下 20 份 Swift 檔；exclude 其他檔僅為本 topic 現況導覽，不代表它們沒有能力。掃描器機械讀取 repo 2071 個檔，code 617；地圖只選其中 20 檔、2602 LOC，正式 12、E014 5、既有 tests 3；不得將本地圖當完整全 repo map。docs／config／其他 code 均未映射。

- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift`
- `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialClearingStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenFetcher.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthSignOutError.swift`
- `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift`
- `Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientScope.swift`
- `Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientPreparationError.swift`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthHTTPTokenFetcher.swift`
- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginService.swift`
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift`
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift`
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift`
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuth.swift`
- `experiments/E014/GitHubConnectionVerification/Sources/VerificationLifecycleObservation.swift`
- `Tests/GitHubIntegrationTests/OAuthLocalSignOutTests.swift`
- `Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift`
- `Tests/GitHubIntegrationTests/GitHubLoginServiceTests.swift`

## Swift 解析與人工查核

掃描器的 Swift imports／mentions 是靜態導覽提示，不解析 actor 重入、async 收尾、protocol 的真實動態 binding 或端到端執行。10 條 explicit injected-call edges 已逐項回 source-audit 的 S01–S06 及對應 source 核實；沒有加正式 login→scope 或產品 orchestrator 的不存在連線。E014 同名 App-local stores 與正式 stores 分開；cross-module port 使用不表示同名 adapter 被正式採用。

- `Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientScope.swift` → `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift`：snapshot()；scope prepare 原碼
- `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift` → `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift`：load／save；provider 注入 port
- `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift` → `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialClearingStore.swift`：signOut／clear；provider 動態查 clearing port
- `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift` → `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenFetcher.swift`：refresh；provider 注入 fetcher
- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginService.swift` → `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift`：取得 bound store／save；login public initializer
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift` → `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthHTTPTokenFetcher.swift`：建立 fetcher；正式 factory
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` → `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift`：注入驗證 dependencies；E014 composition
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` → `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift`：建立 App-local stores；E014 同名 local type
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift` → `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift`：建立驗證 provider；E014 makeProvider
- `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` → `Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientScope.swift`：注入 prepare closure；E014 composition prepare

## 實際檢查與保留

status → scan → 初次 build → describe →填 20 份中文描述 → recent → build，全採 unattended；describe 首次因沒有 graph 回失敗，已按工具流程先 build 後重做，不當作通過。最終 build exit 0，errors=0、warnings=0；descriptions 20/20、routes 0/0（沒有受查 endpoint，非 endpoint 驗證）、modules 7/7、unassigned 0。20 個相對 source 路徑存在；未實作 orchestration 只在 summary／annotation 說明，不偽造節點或 paths。Recent tasks=[]，本 topic 沒有 production code 變更。

Health high/medium/low 均 0，但 endpoint check 未執行，工具對範圍外 E013 Python server 回 loud 提醒；Supabase／Firebase／Stripe 不適用。Secrets check 機械讀 1189 檔不代表安全審查，也非本題新功能驗證。沒有執行 auto-fix。

不啟 server／Ask、不執行 model／上傳或外部發布。Floorplan 以自身目錄 .gitignore 保持本機，不改 root ignore／AGENTS／Git settings，不 untrack。原始使用者內容不存在；未來若已有內容，需先 inventory／雜湊並保留 custom flows，衍生項目淘汰須另記。本機靜態 index.html 供導覽，不能取代正式架構、實驗或獨立 review。

graph SHA-256 `99cb018e71753fa1286b9444ec82e109e1ebb1e02459204fd8f84ec4bb8ce2bb`；index SHA-256 `c66328070db96d999f9eb24e0ff2660ce6bf4963908ba4fe14bfdefb9033d530`。

此為 ignored 本機 Floorplan 的來源／查核索引；map 未附 PR 或上傳。
