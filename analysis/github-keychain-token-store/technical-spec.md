# github-keychain-token-store：技術規格

## Locked Decisions

- `GitHubIntegration` 維持 BC 外、且不依賴任何 BC 的 shared GitHub-specific integration module。本 topic 不改 existing protocol/provider/InMemory store、BC、target、product 或 package manifest。
- topic 的 planning、implementation 與 verification 僅可在 feature worktree 的 `feat/github-keychain-token-store` branch 進行；不得在 dev worktree 寫入或執行 topic work。
- Human 已鎖定方案 B：production `KeychainTokenStore` 與 real tests 使用 legacy macOS Keychain。移除 `kSecUseDataProtectionKeychain = true` 與 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`；不得以其他 explicit accessibility policy 取代。
- 保留 direct real Security implementation；不新增 mock、KeychainClient abstraction、fake client、`kSecAttrAccessGroup`、Keychain Sharing 或 App Group。
- public surface 維持：

```swift
public final class KeychainTokenStore: GitHubTokenStore {
  public init()

  public func load() throws(TokenStoreError) -> GitHubAccessToken?
  public func save(_ token: GitHubAccessToken) throws(TokenStoreError)
  public func delete() throws(TokenStoreError)
}
```

- public `init()` 固定使用 private production generic-password service `com.rivet.github-integration`、account `github-access-token`。internal `init(service:account:)` 只供 SwiftPM `@testable` tests 使用；它不是 public configuration、consumer API 或 multi-account behavior。

## Legacy Keychain and Failure Contract

- private `baseQuery` 固定只包含 `kSecClassGenericPassword`、service、account、`kSecAttrSynchronizable = false`。所有 `SecItemCopyMatching`、`SecItemUpdate`、`SecItemAdd`、`SecItemDelete` 都從這個 base query 衍生；source 不得出現 `kSecUseDataProtectionKeychain`。
- add/update 的 attributes 只有 UTF-8 value data；source 不得設定 `kSecAttrAccessible` 或任何 explicit accessibility attribute。不得設定 access group、App Group、Keychain Sharing、iCloud、label 或其他共享 metadata。
- save 固定 update，僅 update 的 `errSecItemNotFound` 改 add；load 的 `errSecItemNotFound` 回 `nil`；delete 的 `errSecItemNotFound` 成功。非 data result、invalid UTF-8 與其他 OSStatus 都是相應 operation 的 technical failure。
- `TokenStoreError.underlyingError` 固定是無 payload 的 private `KeychainStoreFailure.operationFailed`。不得傳遞 OSStatus、Security error text、query、service、account、token data 或 token value；不得 print、log、assert-message 或反射它們。
- `Security` 是唯一可在 `Sources/BoundedContexts/GitHubIntegration/Stores/KeychainTokenStore.swift` import 的 extra framework。所有其餘 production source 禁止 `Security`；全 target 仍禁止 `Keychain`、`RivetHTTPClient`、`Network`、`FoundationNetworking`、Apollo、ApolloAPI，以及 OAuth／Authorization／Bearer／URLSession／HTTP capability markers。

## SwiftPM Integration and Documentation Contract

- `Tests/GitHubIntegrationTests/KeychainTokenStoreTests.swift` 保留為一般 SwiftPM `@testable import GitHubIntegration` real legacy Keychain integration test。每個 test service 為 `com.rivet.github-integration.tests.<UUID>`，account 是 `github-access-token`；test helper 在開始時清除 exact identity、以 `defer` cleanup，並將 cleanup failure 記為測試失敗。不得使用 production identity、mock 或 Keychain abstraction，且不得輸出 token、query、OSStatus 或 metadata。
- SwiftPM test 覆蓋 empty load、save/load raw round-trip、overwrite、delete、repeated delete、new-instance reload，以及以 isolated identity 預先放入 invalid UTF-8 data 時，provider 回 `.tokenStore`（operation `.load`）而不是 `.missingCredential`。fixture setup／cleanup 只使用 legacy generic-password query，沒有 DPK 或 explicit accessibility attribute。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 驗證 exact six-file production source set、Security 僅限 adapter、四個 SecItem operation 共用 legacy base query，並拒絕 `kSecUseDataProtectionKeychain`、`kSecAttrAccessible` 與 signed-host／codesign markers。`Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` 只編譯 public `KeychainTokenStore()` existential，不做 Keychain I/O。
- Implementer 必須精確移除 signed-host route 的五個受管 paths：`Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/project.pbxproj`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/xcshareddata/xcschemes/KeychainIntegrationHost.xcscheme`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost/AppDelegate.swift`、`Tests/KeychainIntegrationHost/KeychainIntegrationHostTests/KeychainTokenStoreIntegrationTests.swift` 與 `scripts/run-keychain-integration-tests.sh`。這不是 `Tests/KeychainIntegrationHost/**` 的 broad delete，且不包含 Xcode `xcuserdata`、workspace user-interface state 或其他非受管使用者檔案。
- 刪除後，SwiftPM `@testable` legacy Keychain test 是唯一 real integration route。不得新增或遺留 signed host、hosted XCTest、Xcode signing、codesign runner 或 hardcoded `DEVELOPMENT_TEAM`；所有 source、project、script 與 planning artifacts 均禁止 hardcoded `DEVELOPMENT_TEAM`。
- intended docs writeback 限 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`。`docs/architecture/README.md` 有其他 active worktree 未完成變更；Implementer 必須先與 owner 協調再修改，否則保留未寫入並明示。任何 writeback 都不得在 implementation、SwiftPM legacy Keychain tests 與 coordination 未完成時宣稱完成。
