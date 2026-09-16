# github-keychain-token-store：Implementation Plan

## Goal

僅在 `feat/github-keychain-token-store` feature worktree 交付 public `KeychainTokenStore` 的 real legacy macOS Keychain implementation，並由一般 SwiftPM `@testable` tests 驗證實際 Keychain behavior。PR #32 thread 1 的已選定 correction 補上 parent／child cross-process reload acceptance；既有 GitHub token contract、opaque Security failure、single current-user identity 與 worktree policy 不變。

## Public API and Legacy Keychain Contract

```swift
public final class KeychainTokenStore: GitHubTokenStore {
  public init()

  public func load() throws(TokenStoreError) -> GitHubAccessToken?
  public func save(_ token: GitHubAccessToken) throws(TokenStoreError)
  public func delete() throws(TokenStoreError)
}
```

- production identity 是 private `kSecClassGenericPassword` service `com.rivet.github-integration`、account `github-access-token`、`kSecAttrSynchronizable = false`。public initializer 不接受 identity；internal `init(service:account:)` 僅是 SwiftPM `@testable` test seam。
- four SecItem operations 都必須由只含 class、service、account、synchronizable false 的 common private legacy base query 衍生。不得使用 `kSecUseDataProtectionKeychain`、`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`、其他 explicit accessibility attribute、access group、Keychain Sharing 或 App Group。
- load 僅將 `errSecItemNotFound` 映射 `nil`；save 是 update 後僅 `errSecItemNotFound` add；delete 將 `errSecItemNotFound` 視為成功。其餘 OSStatus、invalid UTF-8 或 non-data result 使用相應 operation 的 `TokenStoreError` 與 private payload-free `KeychainStoreFailure.operationFailed`，不露出 OSStatus、Security text、query、metadata 或 secret。
- 不新增 mock／Keychain abstraction、OAuth、network、authorization、多帳號、sync 或 product behavior。

## File Contract

### Written

- `Sources/BoundedContexts/GitHubIntegration/Stores/KeychainTokenStore.swift`
- `Tests/GitHubIntegrationTests/KeychainTokenStoreTests.swift`

### Modify

- `Tests/GitHubIntegrationTests/KeychainTokenStoreTests.swift`：保留既有 same-process new-instance adapter-load test，並替換 blocked one-shot route 為既有 SwiftPM `swiftpm-testing-helper` subprocess acceptance。parent 用 `KeychainTokenStore(service:account:)` 對 UUID service／fixed account 寫入同一個 non-secret、source-held fixed sentinel，將 child `Process.executableURL` 設為 `CommandLine.arguments[0]`，並由既有 `--test-bundle-path` argument 取得同一 bundle binary。child args 精確為 `--test-bundle-path <bundle>`、`--testing-library swift-testing`、`--filter GitHubIntegrationTests.KeychainTokenStoreTests/aFreshProcessLoadsTheParentSavedSentinel`；parent 繼承 environment、只覆寫 reader-mode／service／fixed-account keys，stdout／stderr 為 null。reader mode 以 fresh internal store load 比對 parent 所 save 的同一 source-held sentinel，直接 return 且不再 spawn；parent wait 後只以 generic assertion 檢查 exit status，並 deferred exact cleanup。不得傳遞或輸出 sentinel、token、query、OSStatus 或 metadata。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：exact source set 為 six production files；Security 只允許 new adapter；全 target 禁止 `Keychain`、`RivetHTTPClient`、`Network`、`FoundationNetworking`、Apollo、ApolloAPI；adapter source 拒絕 OAuth、Authorization、Bearer、URLSession、HTTP、`kSecUseDataProtectionKeychain`、`kSecAttrAccessible` 與 signed-host／codesign markers，並驗證 CopyMatching／Update／Add／Delete 都基於同一 legacy base query。
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`：external consumer 可把 `KeychainTokenStore()` 建為 `any GitHubTokenStore`；不得做 Keychain I/O。
- `docs/architecture/README.md` 的兩個 `GitHubIntegration` capability 敘述、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`：只在 implementation 與 SwiftPM legacy Keychain evidence 後回寫 Keychain-backed、single-current-user、cross-process legacy persistence，並維持 authorization、OAuth、transport、headers、pagination、retry 與 BC-local responsibility deferred。`docs/architecture/README.md` 先需與其他 active worktree owner 協調；未協調時不得修改或宣稱完成。

### Deleted

- `Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/project.pbxproj`
- `Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/xcshareddata/xcschemes/KeychainIntegrationHost.xcscheme`
- `Tests/KeychainIntegrationHost/KeychainIntegrationHost/AppDelegate.swift`
- `Tests/KeychainIntegrationHost/KeychainIntegrationHostTests/KeychainTokenStoreIntegrationTests.swift`
- `scripts/run-keychain-integration-tests.sh`

以上是已受管的 signed-host project/source/hosted-test/runner artifacts 的精確移除清單；不得以 `Tests/KeychainIntegrationHost/**` 或其他 broad directory delete 取代。

### ReadOnly / Explicitly Excluded

- `Package.swift`、product／target graph、existing contracts、provider、`InMemoryGitHubTokenStore`、既有非 Keychain tests、consumer package manifest、toolchain、hooks、entitlements、diagrams，以及其他 docs／BC files。cross-process acceptance 不得新增或修改 target、product、package manifest、Xcode host 或 repository helper executable；child 不得執行 `swift test`、使用 temporary direct-Security script，或自行 lookup/build `.build`、解析 package／manifest／targets。
- `Tests/KeychainIntegrationHost/` 內所有不在 Deleted 清單的檔案（尤其 Xcode `xcuserdata`、workspace user-interface state 與其他使用者產物）不得刪除、修改、搬移或以 cleanup 涵蓋。不可新增任何 Xcode project／hosted XCTest／Automatic Signing／codesign artifacts；不得硬編 `DEVELOPMENT_TEAM`。
- 所有 HTTP、OAuth、authorization、network、multi-account、sharing／sync、biometric、migration、logging 與 secret-storage abstraction paths。

## Test and Acceptance Plan

- SwiftPM real Keychain tests：以 UUID test service、legacy generic-password query、direct Security fixture setup 與 exact cleanup，驗證 empty、round-trip、overwrite、delete、repeated delete、new instance reload、invalid UTF-8 經 provider 為 `.tokenStore(.load)`；不用 production identity、mock、DPK attribute、explicit accessibility attribute 或真實 token。
- Cross-process acceptance：parent 以 adapter 對 UUID service／fixed account 寫入同一個 non-secret、source-held fixed sentinel；重用 current `swiftpm-testing-helper` executable (`CommandLine.arguments[0]`) 並從現有 `--test-bundle-path` argument 取得同一 bundle binary。child args 依序固定為 `--test-bundle-path <bundle>`、`--testing-library swift-testing`、`--filter GitHubIntegrationTests.KeychainTokenStoreTests/aFreshProcessLoadsTheParentSavedSentinel`。parent 繼承 environment、只覆寫 reader-mode／UUID service／fixed-account keys，將 stdout／stderr 設為 null，等待後只以 generic assertion 驗證 exit status，再 deferred exact cleanup。reader branch 以 fresh internal store load 比對 parent 所 save 的同一 source-held fixed sentinel，直接 return、絕不 spawn。不得使用 `swift test`、`swift -e`、temporary direct-Security script、package resolution、`.build` lookup/build、manifest／target access、IPC payload 或任何 child output。
- Static isolation：驗證 six-file source set、Security 只存在 adapter、no OAuth/network/header behavior、四個 SecItem calls 共用 legacy base query，且 adapter 不含 DPK、explicit accessibility、access-group/sharing 或 signed-host markers。
- Implementer completion evidence 必須逐一列出五個 Deleted paths 已移除，確認 production、tests、scripts 與 project scope 沒有 Team ID、signed-host、hosted XCTest、Automatic Signing 或 codesign runner remnants，並確認 real integration route 僅為 SwiftPM `@testable` legacy Keychain tests。
- `swift test` 是 real legacy Keychain integration、unit、public API 與 static-query evidence；consumer wrapper、format、SwiftLint、diff check 是附加品質檢查。沒有 signed-host precondition、codesign gate 或 `integration not run`／`integration green` 分類。
- `HC-01` 的 shared-doc coordination authorization 已完成並保留為歷史；PC-06／PC-07／PC-08／PC-09 不新增 docs writeback scope。唯一未完成的人類邊界是 `HC-02`：draft PR 建立後的 human review／approval／merge decision；不得以任何 automated verdict 取代。

## Boundaries

- 不改 protocol、provider mapping 或 InMemory store；missing item 的 `nil` 仍只由 provider 映射 `.missingCredential`。
- 不新增 runtime app、BC、diagram、Keychain Sharing、App Group、access group、Data Protection Keychain policy 或 long-lived architecture decision。
- 不新增 target、product、`Package.swift` mutation、Xcode host、helper executable、IPC protocol 或以 child output payload 取代 exit-status result。
