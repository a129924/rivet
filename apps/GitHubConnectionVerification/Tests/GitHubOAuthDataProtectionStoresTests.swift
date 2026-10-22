import Foundation
import GitHubIntegration
import Security
import Synchronization
import Testing

@testable import GitHubConnectionVerification

@Suite("GitHub OAuth Data Protection stores, fake Security only")
struct GitHubOAuthDataProtectionStoresTests {
  @Test func missingIsDistinctFromDeniedUnavailableAndCorrupt() async throws {
    let security = FakeOAuthSecurity()
    let stores = makeStores(security)
    #expect(try await stores.configurationStore.load() == nil)
    #expect(try await stores.inspectCredential() == nil)
    for (status, expected) in [
      (errSecAuthFailed, GitHubOAuthStoreError.denied),
      (errSecInteractionNotAllowed, .denied), (errSecMissingEntitlement, .unavailable),
    ] {
      security.setReply(status: status)
      await #expect(throws: expected) { try await stores.configurationStore.load() }
    }
    security.setReply(status: errSecSuccess, data: Data("bad json".utf8))
    await #expect(throws: GitHubOAuthStoreError.corrupt) { try await stores.inspectCredential() }
    security.setReply(status: errSecSuccess, data: nil)
    await #expect(throws: GitHubOAuthStoreError.corrupt) { try await stores.inspectCredential() }
  }

  @Test func configurationAndFullExpiredBundleRoundTripWithBinding() async throws {
    let security = FakeOAuthSecurity()
    let stores = makeStores(security)
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fake-id", clientSecret: "fake-secret")
    try await stores.configurationStore.save(configuration)
    let loaded = try #require(try await stores.configurationStore.load())
    #expect(loaded.clientID == configuration.clientID)
    #expect(loaded.clientSecret == configuration.clientSecret)
    let store = stores.credentialStore(clientID: configuration.clientID)
    try await store.save(storedBundle())
    let inspected = try #require(try await stores.inspectCredential())
    #expect(inspected.clientID == configuration.clientID)
    let bundle = try #require(try await store.load())
    #expect(bundle.accessToken.rawValue == "fake-access")
    #expect(bundle.refreshToken.rawValue == "fake-refresh")
    #expect(bundle.accessTokenExpiresAt == Date(timeIntervalSince1970: 123.456))
    #expect(bundle.refreshTokenExpiresAt == Date(timeIntervalSince1970: 234.567))
    #expect(bundle.tokenType == .bearer)
    #expect(bundle.grantedScopes.isEmpty)
    await #expect(throws: GitHubOAuthStoreError.identityMismatch) {
      try await stores.credentialStore(clientID: "another-id").load()
    }
    let payload = try #require(security.data(account: "credential"))
    let object = try #require(JSONSerialization.jsonObject(with: payload) as? [String: Any])
    #expect(object["schemaVersion"] as? Int == 1)
    #expect(
      object["accessTokenExpiresAt"] as? Double == storedBundle().accessTokenExpiresAt
        .timeIntervalSince1970 * 1000)
    #expect(
      object["refreshTokenExpiresAt"] as? Double == storedBundle().refreshTokenExpiresAt
        .timeIntervalSince1970 * 1000)
  }

  @Test func replacementPersistsWholeBundleAndFreshAdapterReadsIt() async throws {
    let security = FakeOAuthSecurity()
    let first = makeStores(security)
    try await first.credentialStore(clientID: "fake-id").save(storedBundle())
    let replacement = GitHubOAuthCredentialBundle(
      accessToken: .init(rawValue: "fake-replacement-access"),
      refreshToken: .init(rawValue: "fake-replacement-refresh"),
      accessTokenExpiresAt: Date(timeIntervalSince1970: 9_000),
      refreshTokenExpiresAt: Date(timeIntervalSince1970: 99_000), tokenType: .bearer,
      grantedScopes: "offline_access")
    try await makeStores(security).credentialStore(clientID: "fake-id").save(replacement)
    let loaded = try #require(
      try await makeStores(security).credentialStore(clientID: "fake-id").load())
    #expect(loaded.accessToken.rawValue == replacement.accessToken.rawValue)
    #expect(loaded.refreshToken.rawValue == replacement.refreshToken.rawValue)
    #expect(loaded.accessTokenExpiresAt == replacement.accessTokenExpiresAt)
    #expect(loaded.refreshTokenExpiresAt == replacement.refreshTokenExpiresAt)
    #expect(loaded.tokenType == replacement.tokenType)
    #expect(loaded.grantedScopes == replacement.grantedScopes)
    #expect(security.operations.map(\.kind) == ["update", "add", "update", "copy"])
    let query = try #require(security.operations.last?.query)
    #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
    #expect(query[kSecAttrSynchronizable as String] as? Bool == false)
    #expect(query[kSecMatchLimit as String] as? String == kSecMatchLimitOne as String)
    #expect(query[kSecReturnData as String] as? Bool == true)
    #expect(query[kSecAttrAccessGroup as String] as? String == "fake-group")
    #expect(query[kSecAttrService as String] as? String == "fake-service")
    #expect(query[kSecAttrAccount as String] as? String == "credential")
  }

  @Test(arguments: [
    "{}", "{\"schemaVersion\":2,\"clientID\":\"fake-id\",\"clientSecret\":\"fake-secret\"}",
    "{\"schemaVersion\":1,\"clientID\":\"fake-id\"}",
    "{\"schemaVersion\":1,\"clientID\":\"fake-id\",\"clientSecret\":\"\"}",
    "{\"schemaVersion\":1,\"clientID\":\"\",\"clientSecret\":\"fake-secret\"}",
  ])
  func configurationSchemaIsStrict(_ json: String) async throws {
    let security = FakeOAuthSecurity()
    security.setReply(status: errSecSuccess, data: Data(json.utf8))
    await #expect(throws: GitHubOAuthStoreError.corrupt) {
      try await makeStores(security).configurationStore.load()
    }
  }

  @Test func everyOperationIsDPKScopedAndDuplicateAddOnlyRetriesUpdateOnce() async throws {
    let security = FakeOAuthSecurity()
    security.setWriteStatuses(
      update: [errSecItemNotFound, errSecSuccess], add: [errSecDuplicateItem])
    let stores = makeStores(security)
    try await stores.credentialStore(clientID: "fake-id").save(storedBundle())
    #expect(security.operations.map(\.kind) == ["update", "add", "update"])
    for call in security.operations {
      #expect(call.query[kSecClass as String] as? String == kSecClassGenericPassword as String)
      #expect(call.query[kSecUseDataProtectionKeychain as String] as? Bool == true)
      #expect(call.query[kSecAttrSynchronizable as String] as? Bool == false)
      #expect(call.query[kSecAttrAccessGroup as String] as? String == "fake-group")
      #expect(call.query[kSecAttrService as String] as? String == "fake-service")
      #expect(call.query[kSecAttrAccount as String] as? String == "credential")
      if call.kind == "add" {
        #expect(
          call.query[kSecAttrAccessible as String] as? String
            == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
      }
    }
    let failed = FakeOAuthSecurity()
    failed.setWriteStatuses(
      update: [errSecItemNotFound, errSecItemNotFound], add: [errSecDuplicateItem])
    await #expect(throws: GitHubOAuthStoreError.unavailable) {
      try await makeStores(failed).credentialStore(clientID: "fake-id").save(storedBundle())
    }
    #expect(failed.operations.map(\.kind) == ["update", "add", "update"])
  }

  @Test func deniedWriteDoesNotAddOrOverwrite() async throws {
    let security = FakeOAuthSecurity()
    security.setWriteStatuses(update: [errSecAuthFailed], add: [])
    await #expect(throws: GitHubOAuthStoreError.denied) {
      try await makeStores(security).configurationStore.save(
        GitHubOAuthAppConfiguration(clientID: "fake-id", clientSecret: "fake-secret"))
    }
    #expect(security.operations.map(\.kind) == ["update"])
  }

  @Test(arguments: [
    "{}", "{\"schemaVersion\":2,\"clientID\":\"fake-id\"}",
    "{\"schemaVersion\":1,\"clientID\":\"fake-id\",\"accessToken\":\"fake\"}",
    """
    {"schemaVersion":1,"clientID":"","accessToken":"fake","refreshToken":"fake",
    "accessTokenExpiresAt":1,"refreshTokenExpiresAt":2,"tokenType":"bearer","grantedScopes":""}
    """,
    """
    {"schemaVersion":1,"clientID":"fake-id","accessToken":"fake","refreshToken":"fake",
    "accessTokenExpiresAt":1,"refreshTokenExpiresAt":2,"tokenType":"mac","grantedScopes":""}
    """,
  ])
  func corruptEnvelopeNeverExposesPartialID(_ json: String) async throws {
    let security = FakeOAuthSecurity()
    security.setReply(status: errSecSuccess, data: Data(json.utf8))
    let stores = makeStores(security)
    await #expect(throws: GitHubOAuthStoreError.corrupt) { try await stores.inspectCredential() }
    await #expect(throws: GitHubOAuthStoreError.corrupt) {
      try await stores.credentialStore(clientID: "different-id").load()
    }
  }

  @Test func invalidBundleIsRejectedBeforeAnySecurityOperation() async throws {
    let security = FakeOAuthSecurity()
    let store = makeStores(security).credentialStore(clientID: "fake-id")
    await #expect(throws: GitHubOAuthStoreError.corrupt) {
      try await store.save(storedBundle(expiry: Date(timeIntervalSince1970: .infinity)))
    }
    await #expect(throws: GitHubOAuthStoreError.corrupt) {
      try await store.save(storedBundle(access: ""))
    }
    #expect(security.operations.isEmpty)
  }

  @Test func oneActorSerializesConcurrentConfigurationAndCredentialWrites() async throws {
    let security = FakeOAuthSecurity()
    let stores = makeStores(security)
    try await withThrowingTaskGroup(of: Void.self) { group in
      for index in 0..<20 {
        group.addTask {
          if index.isMultiple(of: 2) {
            try await stores.configurationStore.save(
              GitHubOAuthAppConfiguration(clientID: "fake-id", clientSecret: "fake-secret"))
          } else {
            try await stores.credentialStore(clientID: "fake-id").save(storedBundle())
          }
        }
      }
      try await group.waitForAll()
    }
    #expect(security.operations.count == 22)
    let calls = security.operations
    for index in calls.indices where calls[index].kind == "add" {
      #expect(index > 0)
      #expect(calls[index - 1].kind == "update")
      #expect(
        calls[index - 1].query[kSecAttrAccount as String] as? String
          == calls[index].query[kSecAttrAccount as String] as? String)
    }
    #expect(try await stores.configurationStore.load()?.clientID == "fake-id")
    #expect(try await stores.inspectCredential()?.clientID == "fake-id")
  }
}

private func makeStores(_ security: FakeOAuthSecurity) -> GitHubOAuthDataProtectionStores {
  GitHubOAuthDataProtectionStores(
    accessGroup: "fake-group", service: "fake-service", security: security)
}

private func storedBundle(
  access: String = "fake-access", expiry: Date = Date(timeIntervalSince1970: 123.456)
) -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: .init(rawValue: access), refreshToken: .init(rawValue: "fake-refresh"),
    accessTokenExpiresAt: expiry, refreshTokenExpiresAt: Date(timeIntervalSince1970: 234.567),
    tokenType: .bearer, grantedScopes: "")
}

private final class FakeOAuthSecurity: GitHubOAuthSecurityClient, @unchecked Sendable {
  struct Call {
    let kind: String
    let query: [String: Any]
  }
  private struct State {
    var calls: [Call] = []
    var items: [String: Data] = [:]
    var reply: (OSStatus, Data?)?
    var updateStatuses: [OSStatus] = []
    var addStatuses: [OSStatus] = []
  }
  // The fake synchronously owns and records non-Sendable Security dictionaries behind one lock.
  private let lock = NSLock()
  private var state = State()
  var operations: [Call] { lock.withLock { state.calls } }
  func setReply(status: OSStatus, data: Data? = nil) {
    lock.withLock { state.reply = (status, data) }
  }
  func setWriteStatuses(update: [OSStatus], add: [OSStatus]) {
    lock.withLock {
      state.updateStatuses = update
      state.addStatuses = add
    }
  }
  func data(account: String) -> Data? { lock.withLock { state.items[account] } }
  func copy(_ query: [String: Any]) -> (OSStatus, Data?) {
    lock.withLock {
      state.calls.append(Call(kind: "copy", query: query))
      if let reply = state.reply { return reply }
      let data = state.items[query[kSecAttrAccount as String] as? String ?? ""]
      return (data == nil ? errSecItemNotFound : errSecSuccess, data)
    }
  }
  func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus {
    lock.withLock {
      state.calls.append(Call(kind: "update", query: query))
      let account = query[kSecAttrAccount as String] as? String ?? ""
      let result =
        state.updateStatuses.isEmpty
        ? (state.items[account] == nil ? errSecItemNotFound : errSecSuccess)
        : state.updateStatuses.removeFirst()
      if result == errSecSuccess {
        state.items[account] = attributes[kSecValueData as String] as? Data
      }
      return result
    }
  }
  func add(_ query: [String: Any]) -> OSStatus {
    lock.withLock {
      state.calls.append(Call(kind: "add", query: query))
      let result = state.addStatuses.isEmpty ? errSecSuccess : state.addStatuses.removeFirst()
      if result == errSecSuccess {
        state.items[query[kSecAttrAccount as String] as? String ?? ""] =
          query[kSecValueData as String] as? Data
      }
      return result
    }
  }
}
