import Foundation
import Security
import Testing

@testable import GitHubIntegration

@Suite("OAuth data protection stores (fake Security only)")
struct GitHubOAuthDataProtectionStoresTests {
  @Test
  func configurationRoundTripsWithoutDiagnosticDisclosure() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "app-id", clientSecret: "private-secret")
    #expect(try await stores.configurationStore.load() == nil)
    try await stores.configurationStore.save(configuration)
    let loaded = try #require(try await stores.configurationStore.load())
    #expect(loaded.clientID == "app-id")
    #expect(loaded.clientSecret == "private-secret")
    #expect(!String(describing: loaded).contains("private-secret"))
    #expect(!String(reflecting: loaded).contains("app-id"))
    #expect(Mirror(reflecting: loaded).children.isEmpty)
    let data = try #require(security.item("configuration"))
    #expect(String(data: data, encoding: .utf8)?.contains("private-secret") == true)
  }

  @Test
  func absentAndCompleteReplacementRoundTripThroughNewFacade() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    let store = stores.credentialStore(clientID: "app-id")
    #expect(try await store.load() == nil)
    #expect(try await stores.inspectCredential() == nil)
    try await store.save(bundle("A"))
    expectBundle(try await store.load(), equals: bundle("A"))
    try await store.save(bundle("B", expired: true))
    let recreated = try makeStores(security)
    let inspected = try #require(try await recreated.inspectCredential())
    #expect(inspected.clientID == "app-id")
    expectBundle(inspected.credential, equals: bundle("B", expired: true))
    #expect(Mirror(reflecting: inspected).children.isEmpty)
    #expect(!String(reflecting: inspected).contains("access-B"))
  }

  @Test
  func mismatchedIdentityCannotLoadOrOverwriteExistingCredential() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    try await stores.credentialStore(clientID: "app-id").save(bundle("A"))
    let calls = security.calls.count
    let mismatched = stores.credentialStore(clientID: "another-app")
    await #expect(throws: GitHubOAuthDataProtectionStoreError.identityMismatch) {
      try await mismatched.load()
    }
    await #expect(throws: GitHubOAuthDataProtectionStoreError.identityMismatch) {
      try await mismatched.save(bundle("B"))
    }
    #expect(security.calls.dropFirst(calls).allSatisfy { $0.operation == "copy" })
    expectBundle(try await stores.credentialStore(clientID: "app-id").load(), equals: bundle("A"))
  }

  @Test(arguments: invalidCredentialPayloads)
  func corruptPayloadIsNeitherMissingNorOverwritten(_ data: Data) async throws {
    let security = FakeOAuthSecurity()
    security.setItem(data, account: "credential")
    let stores = try makeStores(security)
    await #expect(throws: GitHubOAuthDataProtectionStoreError.corrupt) {
      try await stores.inspectCredential()
    }
    await #expect(throws: GitHubOAuthDataProtectionStoreError.corrupt) {
      try await stores.credentialStore(clientID: "app-id").save(bundle("B"))
    }
    #expect(security.item("credential") == data)
    #expect(security.calls.allSatisfy { $0.operation == "copy" })
  }

  @Test(arguments: [
    errSecAuthFailed, errSecUserCanceled, errSecInteractionNotAllowed, errSecMissingEntitlement,
    errSecNotAvailable, errSecDecode, errSecParam,
  ])
  func accessFailuresStayDistinctAndDoNotWrite(_ status: OSStatus) async throws {
    let security = FakeOAuthSecurity()
    security.readStatus = status
    let stores = try makeStores(security)
    let expected: GitHubOAuthDataProtectionStoreError =
      switch status {
      case errSecAuthFailed, errSecUserCanceled: .denied
      case errSecDecode: .corrupt
      default: .unavailable
      }
    await #expect(throws: expected) { try await stores.inspectCredential() }
    await #expect(throws: expected) { try await stores.configurationStore.load() }
    await #expect(throws: expected) {
      try await stores.credentialStore(clientID: "app-id").save(bundle("B"))
    }
    #expect(security.calls.allSatisfy { $0.operation == "copy" })
  }

  @Test
  func invalidConfigurationAndBundleFailBeforeWriting() async throws {
    let security = FakeOAuthSecurity()
    #expect(throws: GitHubOAuthAppConfigurationError.invalidConfiguration) {
      try GitHubOAuthAppConfiguration(clientID: "", clientSecret: "secret")
    }
    #expect(throws: GitHubOAuthAppConfigurationError.invalidConfiguration) {
      try GitHubOAuthAppConfiguration(clientID: "app", clientSecret: "")
    }
    for group in ["", "team.*"] {
      #expect(throws: GitHubOAuthDataProtectionStoreError.invalidConfiguration) {
        try GitHubOAuthDataProtectionStores(accessGroup: group, service: "test", security: security)
      }
    }
    #expect(throws: GitHubOAuthDataProtectionStoreError.invalidConfiguration) {
      try GitHubOAuthDataProtectionStores(
        accessGroup: "test.group", service: "", security: security)
    }
    let stores = try makeStores(security)
    let invalid = stores.credentialStore(clientID: "")
    await #expect(throws: GitHubOAuthDataProtectionStoreError.invalidConfiguration) {
      try await invalid.load()
    }
    await #expect(throws: GitHubOAuthDataProtectionStoreError.invalidConfiguration) {
      try await invalid.save(bundle("A"))
    }
    let nonfinite = GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: "valid"),
      refreshToken: GitHubOAuthRefreshToken(rawValue: "refresh"),
      accessTokenExpiresAt: Date(timeIntervalSince1970: .infinity),
      refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer, grantedScopes: ""
    )
    await #expect(throws: GitHubOAuthDataProtectionStoreError.corrupt) {
      try await stores.credentialStore(clientID: "app-id").save(nonfinite)
    }
    #expect(security.calls.isEmpty)
  }

  @Test
  func queriesSelectOnlyExplicitLocalDPKItemsAndCompleteValues() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    try await stores.configurationStore.save(
      GitHubOAuthAppConfiguration(clientID: "app-id", clientSecret: "secret"))
    try await stores.credentialStore(clientID: "app-id").save(bundle("A"))
    _ = try await stores.inspectCredential()
    for call in security.calls {
      #expect(call.query[kSecClass] as? String == kSecClassGenericPassword as String)
      #expect(call.query[kSecUseDataProtectionKeychain] as? Bool == true)
      #expect(call.query[kSecAttrSynchronizable] as? Bool == false)
      #expect(call.query[kSecAttrAccessGroup] as? String == "test.group")
      #expect(call.query[kSecAttrService] as? String == "test.service")
      #expect(
        ["configuration", "credential"].contains(call.query[kSecAttrAccount] as? String ?? ""))
      #expect(call.query[kSecAttrAccessControl] == nil)
      if call.operation == "copy" {
        #expect(call.query[kSecReturnData] as? Bool == true)
        #expect(call.query[kSecMatchLimit] as? String == kSecMatchLimitOne as String)
      } else if call.operation == "add" {
        #expect(
          call.query[kSecAttrAccessible] as? String
            == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        #expect(call.query[kSecValueData] is Data)
      } else {
        #expect(call.query[kSecReturnData] == nil)
        #expect(call.attributes.count == 1)
        #expect(call.attributes[kSecValueData] is Data)
      }
    }
  }

  @Test
  func duplicateAddRetriesExactlyOneCompleteUpdate() async throws {
    let security = FakeOAuthSecurity()
    security.updateStatuses = [errSecItemNotFound, errSecSuccess]
    security.addStatuses = [errSecDuplicateItem]
    let stores = try makeStores(security)
    try await stores.credentialStore(clientID: "app-id").save(bundle("B"))
    #expect(security.calls.map(\.operation) == ["copy", "update", "add", "update"])
    expectBundle(try await stores.credentialStore(clientID: "app-id").load(), equals: bundle("B"))
  }

  @Test(arguments: [errSecAuthFailed, errSecInteractionNotAllowed, errSecDecode])
  func failedReplacementPreservesCompleteCommittedItem(_ status: OSStatus) async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    let store = stores.credentialStore(clientID: "app-id")
    try await store.save(bundle("A"))
    let previous = security.item("credential")
    let calls = security.calls.count
    security.updateStatuses = [status]
    let expected: GitHubOAuthDataProtectionStoreError =
      status == errSecAuthFailed ? .denied : (status == errSecDecode ? .corrupt : .unavailable)
    await #expect(throws: expected) { try await store.save(bundle("B")) }
    #expect(security.item("credential") == previous)
    #expect(security.calls.dropFirst(calls).map(\.operation) == ["copy", "update"])
  }

  @Test
  func configurationFirstPartialSaveDoesNotRollbackConfiguration() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    try await stores.configurationStore.save(
      GitHubOAuthAppConfiguration(clientID: "app-id", clientSecret: "secret"))
    security.addStatuses = [errSecNotAvailable]
    await #expect(throws: GitHubOAuthDataProtectionStoreError.unavailable) {
      try await stores.credentialStore(clientID: "app-id").save(bundle("A"))
    }
    #expect(try await stores.configurationStore.load()?.clientID == "app-id")
    #expect(try await stores.inspectCredential() == nil)
  }

  @Test
  func concurrentBoundViewsKeepEachReadAndWriteTogether() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    try await stores.credentialStore(clientID: "app-id").save(bundle("initial"))
    let start = security.calls.count
    try await withThrowingTaskGroup(of: Void.self) { group in
      for index in 0..<20 {
        let view = stores.credentialStore(clientID: "app-id")
        group.addTask { try await view.save(bundle(String(index))) }
      }
      try await group.waitForAll()
    }
    let calls = Array(security.calls.dropFirst(start)).map(\.operation)
    #expect(calls == Array(repeating: ["copy", "update"], count: 20).flatMap { $0 })
    #expect(try await stores.inspectCredential() != nil)
  }

  @Test
  func providerRestoresAndPersistsCompleteRotation() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    let store = stores.credentialStore(clientID: "app-id")
    try await store.save(bundle("A", expired: true))
    let fetcher = StoreRotationFetcher()
    let provider = OAuthTokenProvider(
      store: store, fetcher: fetcher, now: { Date(timeIntervalSince1970: 100) })
    let snapshot = try await provider.snapshot()
    #expect(snapshot.accessToken.rawValue == "access-B")
    expectBundle(try await store.load(), equals: bundle("B"))
    #expect(await fetcher.count == 1)
    let restored = OAuthTokenProvider(
      store: store, fetcher: fetcher, now: { Date(timeIntervalSince1970: 100) })
    #expect(try await restored.snapshot().accessToken.rawValue == "access-B")
    #expect(await fetcher.count == 1)
  }

  @Test
  func acceptedRotationWriteFailureStopsProviderWithoutFurtherCalls() async throws {
    let security = FakeOAuthSecurity()
    let stores = try makeStores(security)
    let store = stores.credentialStore(clientID: "app-id")
    try await store.save(bundle("A", expired: true))
    security.updateStatuses = [errSecNotAvailable]
    let fetcher = StoreRotationFetcher()
    let provider = OAuthTokenProvider(
      store: store, fetcher: fetcher, now: { Date(timeIntervalSince1970: 100) })
    do {
      _ = try await provider.snapshot()
      Issue.record("Expected persistence failure")
    } catch {
      guard case .persist(let underlying) = error else {
        Issue.record("Expected persist")
        return
      }
      #expect(underlying as? GitHubOAuthDataProtectionStoreError == .unavailable)
    }
    let calls = security.calls.count
    do {
      _ = try await provider.snapshot()
      Issue.record("Expected stopped provider")
    } catch {
      guard case .persist = error else {
        Issue.record("Expected persist")
        return
      }
    }
    #expect(security.calls.count == calls)
    #expect(await fetcher.count == 1)
    expectBundle(try await store.load(), equals: bundle("A", expired: true))
  }
}

private func makeStores(_ security: FakeOAuthSecurity) throws -> GitHubOAuthDataProtectionStores {
  try GitHubOAuthDataProtectionStores(
    accessGroup: "test.group", service: "test.service", security: security)
}

private func bundle(_ suffix: String, expired: Bool = false) -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: GitHubAccessToken(rawValue: "access-\(suffix)"),
    refreshToken: GitHubOAuthRefreshToken(rawValue: "refresh-\(suffix)"),
    accessTokenExpiresAt: Date(timeIntervalSince1970: expired ? 1 : 1000),
    refreshTokenExpiresAt: Date(timeIntervalSince1970: 2000), tokenType: .bearer, grantedScopes: ""
  )
}

private func expectBundle(
  _ actual: GitHubOAuthCredentialBundle?, equals expected: GitHubOAuthCredentialBundle
) {
  #expect(actual?.accessToken.rawValue == expected.accessToken.rawValue)
  #expect(actual?.refreshToken.rawValue == expected.refreshToken.rawValue)
  #expect(actual?.accessTokenExpiresAt == expected.accessTokenExpiresAt)
  #expect(actual?.refreshTokenExpiresAt == expected.refreshTokenExpiresAt)
  #expect(actual?.tokenType == expected.tokenType)
  #expect(actual?.grantedScopes == expected.grantedScopes)
}

private var invalidCredentialPayloads: [Data] {
  let valid: [String: Any] = [
    "schemaVersion": 1, "clientID": "app-id", "accessToken": "access",
    "refreshToken": "refresh", "accessTokenExpiresAt": 1000, "refreshTokenExpiresAt": 2000,
    "tokenType": "bearer", "grantedScopes": "",
  ]
  var variants: [[String: Any]] = []
  for key in valid.keys {
    var missing = valid
    missing.removeValue(forKey: key)
    variants.append(missing)
    var null = valid
    null[key] = NSNull()
    variants.append(null)
  }
  for (key, value) in [
    ("schemaVersion", 2), ("clientID", ""), ("accessToken", ""),
    ("refreshToken", ""), ("tokenType", "mac"), ("grantedScopes", 42),
    ("accessTokenExpiresAt", "NaN"),
  ] as [(String, Any)] {
    var invalid = valid
    invalid[key] = value
    variants.append(invalid)
  }
  return variants.compactMap { try? JSONSerialization.data(withJSONObject: $0) } + [
    Data([0xFF]), Data("{}".utf8),
  ]
}

private actor StoreRotationFetcher: OAuthTokenFetcher {
  typealias Credential = GitHubOAuthCredentialBundle
  private(set) var count = 0
  func refresh(_ credential: Credential) async throws(OAuthTokenRefreshError) -> Credential {
    count += 1
    return bundle("B")
  }
}

private final class FakeOAuthSecurity: GitHubOAuthSecurityClient, @unchecked Sendable {
  struct Call {
    let operation: String
    let query: [CFString: Any]
    let attributes: [CFString: Any]
  }
  private let lock = NSLock()
  private var items: [String: Data] = [:]
  private var recordedCalls: [Call] = []
  private var forcedReadStatus: OSStatus?
  private var forcedUpdateStatuses: [OSStatus] = []
  private var forcedAddStatuses: [OSStatus] = []

  var calls: [Call] { lock.withLock { recordedCalls } }
  var readStatus: OSStatus? {
    get { lock.withLock { forcedReadStatus } }
    set { lock.withLock { forcedReadStatus = newValue } }
  }
  var updateStatuses: [OSStatus] {
    get { lock.withLock { forcedUpdateStatuses } }
    set { lock.withLock { forcedUpdateStatuses = newValue } }
  }
  var addStatuses: [OSStatus] {
    get { lock.withLock { forcedAddStatuses } }
    set { lock.withLock { forcedAddStatuses = newValue } }
  }
  func item(_ account: String) -> Data? { lock.withLock { items[account] } }
  func setItem(_ data: Data, account: String) { lock.withLock { items[account] = data } }

  func copyMatching(_ query: [CFString: Any]) -> (OSStatus, Data?) {
    lock.withLock {
      recordedCalls.append(Call(operation: "copy", query: query, attributes: [:]))
      if let forcedReadStatus { return (forcedReadStatus, nil) }
      let data = items[query[kSecAttrAccount] as? String ?? ""]
      return (data == nil ? errSecItemNotFound : errSecSuccess, data)
    }
  }
  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus {
    lock.withLock {
      recordedCalls.append(Call(operation: "update", query: query, attributes: attributes))
      let account = query[kSecAttrAccount] as? String ?? ""
      let status =
        forcedUpdateStatuses.isEmpty
        ? (items[account] == nil ? errSecItemNotFound : errSecSuccess)
        : forcedUpdateStatuses.removeFirst()
      if status == errSecSuccess { items[account] = attributes[kSecValueData] as? Data }
      return status
    }
  }
  func add(_ query: [CFString: Any]) -> OSStatus {
    lock.withLock {
      recordedCalls.append(Call(operation: "add", query: query, attributes: [:]))
      let account = query[kSecAttrAccount] as? String ?? ""
      let status =
        forcedAddStatuses.isEmpty
        ? (items[account] == nil ? errSecSuccess : errSecDuplicateItem)
        : forcedAddStatuses.removeFirst()
      if status == errSecSuccess { items[account] = query[kSecValueData] as? Data }
      return status
    }
  }
}
