# github-keychain-token-store：需求

## Goal

讓 `GitHubIntegration` 的呼叫端以既有 `GitHubTokenStore` contract 安全保存、讀取、覆寫與刪除一個 GitHub access token。production adapter 與真實 integration tests 都使用 legacy macOS Keychain；integration evidence 由一般 SwiftPM `@testable` test target 提供。

## In Scope

- public `KeychainTokenStore` 的單一 GitHub access-token persistence，以及 load、save、overwrite、idempotent delete、new-instance reload 與 technical-failure semantics。
- legacy macOS Keychain generic-password item：固定 private service/account、`kSecAttrSynchronizable = false`，不設定 Data Protection Keychain query 或 explicit accessibility attribute。
- 一般 SwiftPM `@testable import GitHubIntegration` 的 real Keychain tests，以 UUID service namespace、direct Security fixture setup 與 exact cleanup 驗證 adapter 行為。
- SwiftPM unit/public/static checks、consumer public conformer compile check，以及 production source static isolation。
- 移除先前 signed-host route 的五個受管 artifacts：`Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/project.pbxproj`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/xcshareddata/xcschemes/KeychainIntegrationHost.xcscheme`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost/AppDelegate.swift`、`Tests/KeychainIntegrationHost/KeychainIntegrationHostTests/KeychainTokenStoreIntegrationTests.swift` 與 `scripts/run-keychain-integration-tests.sh`。不處理 Xcode `xcuserdata` 或其他使用者產物。
- 實作完成後最小回寫已交付 legacy Keychain persistence 的長期 architecture facts；`docs/architecture/README.md` 需先與其 active worktree owner 協調。

## Non-Goal

- `kSecUseDataProtectionKeychain`、`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`、`kSecAttrAccessGroup`、Keychain Sharing、App Group、iCloud、mock Keychain client、Keychain abstraction、fake Security implementation。
- signed app host、hosted XCTest、Xcode project、Automatic Signing、team identifier、codesign preflight 或 signed-integration CI state。
- OAuth、token refresh／rotation、re-auth、401 retry、authorization header、HTTP／network、REST／GraphQL request execution、多帳號、migration、biometric、user-presence 或跨裝置共享。
- 改變 `GitHubTokenStore`、`GitHubAccessToken`、`TokenStoreError`、`GitHubCredentialError`、`GitHubTokenProvider`、`TokenStoreGitHubTokenProvider` 或 `InMemoryGitHubTokenStore` 的 public contract 或現有行為。
- thread-safety、`Sendable`、actor isolation、async、跨 process 同時寫入保證、runtime product UI、log 或新的 Bounded Context。

## Success Criteria

- `KeychainTokenStore` 只透過 legacy macOS Keychain 保存單一 UTF-8 token；不得產生檔案、UserDefaults、網路或 log 副本。
- empty load 回傳 `nil`；save 後原樣 load；後次 save 覆寫舊值；delete（含 item 不存在）後 load 為 `nil`；同一 identity 的新 store instance 可讀回值。
- 只有 `errSecItemNotFound` 可表示缺少 item；其他 OSStatus 或不合法 Keychain data 必須成為既有 `TokenStoreError`，不得誤回傳 `nil`。
- SwiftPM `KeychainTokenStoreTests` 使用 UUID service namespace 與 exact cleanup；`swift test` 成功才可作為 legacy Keychain integration evidence，沒有 signed-host 額外 gate 或狀態。
- 只移除列明的五個受管 signed-host artifacts；不得以 directory delete 處理 `Tests/KeychainIntegrationHost/`，也不得變動其 Xcode `xcuserdata`、workspace user-interface state 或其他使用者產物。production、tests、scripts 與 project scope 不得殘留 Team ID、signed-host、hosted XCTest、Automatic Signing 或 codesign runner。
- long-lived docs 只在實作及 SwiftPM evidence 後回寫；未完成 shared-doc coordination 的 `docs/architecture/README.md` 不得宣稱已更新。
