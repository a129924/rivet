import Foundation
import Security
import Testing

@testable import GitHubIntegration

@Suite("PAT data protection store (fake Security only)")
struct GitHubPATDataProtectionStoreTests {
  @Test
  func missingRoundTripAndCompleteReplacement() async throws {
    let security = FakePATSecurity()
    let store = try makePATStore(security)
    #expect(try await store.load() == nil)
    let first = try PersonalAccessToken(rawValue: " example-A ")
    try await store.save(first)
    #expect(try await store.load() == first)
    let replacement = try PersonalAccessToken(rawValue: "example-B-with-different-content")
    try await store.save(replacement)
    let recreated = try makePATStore(security)
    #expect(try await recreated.load() == replacement)
    let data = try #require(security.patItem)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(Set(object.keys) == ["schemaVersion", "token"])
    #expect(object["schemaVersion"] as? Int == 1)
    #expect(object["token"] as? String == replacement.rawValue)
  }

  @Test(arguments: invalidPATPayloads)
  func corruptItemCannotLoadOrBeOverwritten(_ data: Data) async throws {
    let security = FakePATSecurity()
    security.patItem = data
    let store = try makePATStore(security)
    await #expect(throws: GitHubPATDataProtectionStoreError.corrupt) { try await store.load() }
    await #expect(throws: GitHubPATDataProtectionStoreError.corrupt) {
      try await store.save(PersonalAccessToken(rawValue: "replacement"))
    }
    #expect(security.patItem == data)
    #expect(security.calls.map(\.operation) == ["copy", "copy"])
  }

  @Test(arguments: [
    errSecAuthFailed, errSecUserCanceled, errSecDecode, errSecInteractionNotAllowed,
    errSecMissingEntitlement, errSecNotAvailable, errSecParam, errSecSuccess,
  ])
  func failedReadAndSuccessWithoutDataNeverWrite(_ status: OSStatus) async throws {
    let security = FakePATSecurity()
    security.readStatus = status
    let store = try makePATStore(security)
    let expected = patError(status)
    await #expect(throws: expected) { try await store.load() }
    await #expect(throws: expected) {
      try await store.save(PersonalAccessToken(rawValue: "example-B"))
    }
    #expect(security.calls.map(\.operation) == ["copy", "copy"])
  }

  @Test
  func invalidConfigurationFailsWithoutSecurityAndValidNamespaceIsNotTrimmed() async throws {
    let security = FakePATSecurity()
    for group in ["", " \n", "team.*"] {
      #expect(throws: GitHubPATDataProtectionStoreError.invalidConfiguration) {
        try GitHubPATDataProtectionStore(accessGroup: group, service: "service", security: security)
      }
    }
    for service in ["", " \t\n"] {
      #expect(throws: GitHubPATDataProtectionStoreError.invalidConfiguration) {
        try GitHubPATDataProtectionStore(accessGroup: "group", service: service, security: security)
      }
    }
    #expect(security.calls.isEmpty)
    let store = try GitHubPATDataProtectionStore(
      accessGroup: " group ", service: " service ", security: security)
    #expect(security.calls.isEmpty)
    #expect(try await store.load() == nil)
    let call = try #require(security.calls.first)
    #expect(call.query[kSecAttrAccessGroup] as? String == " group ")
    #expect(call.query[kSecAttrService] as? String == " service ")
  }

  @Test
  func queriesExplicitlySelectOnlyThePATItemAndCompleteValue() async throws {
    let security = FakePATSecurity()
    let store = try makePATStore(security)
    try await store.save(PersonalAccessToken(rawValue: "example-A"))
    _ = try await store.load()
    for call in security.calls {
      #expect(call.query[kSecClass] as? String == kSecClassGenericPassword as String)
      #expect(call.query[kSecUseDataProtectionKeychain] as? Bool == true)
      #expect(call.query[kSecAttrSynchronizable] as? Bool == false)
      #expect(call.query[kSecAttrAccessGroup] as? String == "test.group")
      #expect(call.query[kSecAttrService] as? String == "test.service")
      #expect(call.query[kSecAttrAccount] as? String == "pat")
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
        #expect(call.query[kSecAttrAccessible] == nil)
        #expect(Set(call.attributes.keys) == [kSecValueData])
        #expect(call.attributes[kSecValueData] is Data)
      }
    }
    // Legacy service/account are never selected; all production calls are explicit DPK calls.
    #expect(
      security.calls.allSatisfy {
        $0.query[kSecAttrService] as? String != "com.rivet.github-integration"
          && $0.query[kSecAttrAccount] as? String != "github-access-token"
      })
  }

  @Test
  func sameServiceKeepsOAuthItemsAndPATSeparate() async throws {
    let security = FakePATSecurity()
    let oauth = try GitHubOAuthDataProtectionStores(
      accessGroup: "test.group", service: "test.service", security: security)
    let configuration = try GitHubOAuthAppConfiguration(clientID: "app", clientSecret: "secret")
    let credential = GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: "oauth-access"),
      refreshToken: GitHubOAuthRefreshToken(rawValue: "oauth-refresh"),
      accessTokenExpiresAt: Date(timeIntervalSince1970: 1000),
      refreshTokenExpiresAt: Date(timeIntervalSince1970: 2000), tokenType: .bearer,
      grantedScopes: "")
    try await oauth.configurationStore.save(configuration)
    try await oauth.credentialStore(clientID: "app").save(credential)
    let store = try makePATStore(security)
    #expect(try await store.load() == nil)
    let pat = try PersonalAccessToken(rawValue: "pat-example")
    try await store.save(pat)
    #expect(try await store.load() == pat)
    #expect(try await oauth.configurationStore.load()?.clientSecret == "secret")
    #expect(try await oauth.inspectCredential()?.credential.accessToken.rawValue == "oauth-access")
    let anotherService = try GitHubPATDataProtectionStore(
      accessGroup: "test.group", service: "other.service", security: security)
    #expect(try await anotherService.load() == nil)
    let anotherGroup = try GitHubPATDataProtectionStore(
      accessGroup: "other.group", service: "test.service", security: security)
    #expect(try await anotherGroup.load() == nil)
  }

  @Test
  func duplicateAddPerformsExactlyOneCompleteUpdate() async throws {
    let security = FakePATSecurity()
    security.updateStatuses = [errSecItemNotFound, errSecSuccess]
    security.addStatuses = [errSecDuplicateItem]
    let store = try makePATStore(security)
    let token = try PersonalAccessToken(rawValue: "example-B")
    try await store.save(token)
    #expect(security.calls.map(\.operation) == ["copy", "update", "add", "update"])
    #expect(try await store.load() == token)
  }

  @Test(arguments: [errSecAuthFailed, errSecInteractionNotAllowed, errSecDecode])
  func failedReplacementLeavesPreviouslyCommittedItem(_ status: OSStatus) async throws {
    let security = FakePATSecurity()
    let store = try makePATStore(security)
    try await store.save(PersonalAccessToken(rawValue: "example-A"))
    let original = security.patItem
    let count = security.calls.count
    security.updateStatuses = [status]
    await #expect(throws: patError(status)) {
      try await store.save(PersonalAccessToken(rawValue: "example-B"))
    }
    #expect(security.patItem == original)
    #expect(security.calls.dropFirst(count).map(\.operation) == ["copy", "update"])
  }

  @Test(arguments: [errSecAuthFailed, errSecInteractionNotAllowed, errSecDecode])
  func failedAddDoesNotRetryOrClaimSuccess(_ status: OSStatus) async throws {
    let security = FakePATSecurity()
    security.addStatuses = [status]
    let store = try makePATStore(security)
    await #expect(throws: patError(status)) {
      try await store.save(PersonalAccessToken(rawValue: "example-B"))
    }
    #expect(security.calls.map(\.operation) == ["copy", "update", "add"])
    #expect(security.patItem == nil)
  }

  @Test(arguments: [errSecItemNotFound, errSecDuplicateItem, errSecAuthFailed])
  func failedDuplicateRetryIsTerminal(_ status: OSStatus) async throws {
    let security = FakePATSecurity()
    security.updateStatuses = [errSecItemNotFound, status]
    security.addStatuses = [errSecDuplicateItem]
    let store = try makePATStore(security)
    await #expect(throws: patError(status)) {
      try await store.save(PersonalAccessToken(rawValue: "example-B"))
    }
    #expect(security.calls.map(\.operation) == ["copy", "update", "add", "update"])
    #expect(security.patItem == nil)
  }

  @Test
  func concurrentOperationsDoNotInterleaveReadCheckWrite() async throws {
    let security = FakePATSecurity()
    let store = try makePATStore(security)
    try await store.save(PersonalAccessToken(rawValue: "initial"))
    let count = security.calls.count
    try await withThrowingTaskGroup(of: Void.self) { group in
      for index in 0..<24 {
        group.addTask {
          try await store.save(PersonalAccessToken(rawValue: "controlled-\(index)"))
        }
      }
      try await group.waitForAll()
    }
    #expect(
      security.calls.dropFirst(count).map(\.operation)
        == Array(repeating: ["copy", "update"], count: 24).flatMap { $0 })
    #expect(try await store.load() != nil)
  }

  @Test
  func restoredValueAndFiniteErrorsHaveNoSecretDiagnostics() async throws {
    let security = FakePATSecurity()
    let store = try makePATStore(security)
    try await store.save(PersonalAccessToken(rawValue: "controlled-secret-sentinel"))
    let token = try #require(try await store.load())
    #expect(String(describing: token) == "PersonalAccessToken(<redacted>)")
    #expect(String(reflecting: token) == "PersonalAccessToken(<redacted>)")
    #expect(Mirror(reflecting: token).children.isEmpty)
    for error: GitHubPATDataProtectionStoreError in [
      .denied, .unavailable, .corrupt, .invalidConfiguration,
    ] {
      #expect(Mirror(reflecting: error).children.isEmpty)
      #expect(!String(reflecting: error).contains("controlled-secret-sentinel"))
    }
  }

}

private func makePATStore(_ security: FakePATSecurity) throws -> GitHubPATDataProtectionStore {
  try GitHubPATDataProtectionStore(
    accessGroup: "test.group", service: "test.service", security: security)
}

private final class FakePATSecurity: GitHubPATSecurityClient, @unchecked Sendable {
  struct Call {
    let operation: String
    let query: [CFString: Any]
    let attributes: [CFString: Any]
  }
  private let lock = NSLock()
  private var items: [String: Data] = [:]
  private var history: [Call] = []
  private var forcedRead: OSStatus?
  private var forcedUpdates: [OSStatus] = []
  private var forcedAdds: [OSStatus] = []

  var calls: [Call] { lock.withLock { history } }
  var patItem: Data? {
    get { lock.withLock { items["test.group|test.service|pat"] } }
    set { lock.withLock { items["test.group|test.service|pat"] = newValue } }
  }
  var readStatus: OSStatus? {
    get { lock.withLock { forcedRead } }
    set { lock.withLock { forcedRead = newValue } }
  }
  var updateStatuses: [OSStatus] {
    get { lock.withLock { forcedUpdates } }
    set { lock.withLock { forcedUpdates = newValue } }
  }
  var addStatuses: [OSStatus] {
    get { lock.withLock { forcedAdds } }
    set { lock.withLock { forcedAdds = newValue } }
  }

  private func key(_ query: [CFString: Any]) -> String {
    [kSecAttrAccessGroup, kSecAttrService, kSecAttrAccount]
      .map { query[$0] as? String ?? "" }.joined(separator: "|")
  }

  func copyMatching(_ query: [CFString: Any]) -> (OSStatus, Data?) {
    lock.withLock {
      history.append(Call(operation: "copy", query: query, attributes: [:]))
      if let forcedRead { return (forcedRead, nil) }
      let data = items[key(query)]
      return (data == nil ? errSecItemNotFound : errSecSuccess, data)
    }
  }

  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus {
    lock.withLock {
      history.append(Call(operation: "update", query: query, attributes: attributes))
      let itemKey = key(query)
      let status =
        forcedUpdates.isEmpty
        ? (items[itemKey] == nil ? errSecItemNotFound : errSecSuccess)
        : forcedUpdates.removeFirst()
      if status == errSecSuccess { items[itemKey] = attributes[kSecValueData] as? Data }
      return status
    }
  }

  func add(_ query: [CFString: Any]) -> OSStatus {
    lock.withLock {
      history.append(Call(operation: "add", query: query, attributes: [:]))
      let itemKey = key(query)
      let status =
        forcedAdds.isEmpty
        ? (items[itemKey] == nil ? errSecSuccess : errSecDuplicateItem)
        : forcedAdds.removeFirst()
      if status == errSecSuccess { items[itemKey] = query[kSecValueData] as? Data }
      return status
    }
  }
}

private func patError(_ status: OSStatus) -> GitHubPATDataProtectionStoreError {
  switch status {
  case errSecAuthFailed, errSecUserCanceled: .denied
  case errSecDecode, errSecSuccess: .corrupt
  default: .unavailable
  }
}

private var invalidPATPayloads: [Data] {
  let variants: [[String: Any]] = [
    [:], ["schemaVersion": 1], ["token": "example"],
    ["schemaVersion": 2, "token": "example"],
    ["schemaVersion": "1", "token": "example"],
    ["schemaVersion": NSNull(), "token": "example"],
    ["schemaVersion": 1, "token": NSNull()],
    ["schemaVersion": 1, "token": 17],
    ["schemaVersion": 1, "token": ""],
    ["schemaVersion": 1, "token": " \n"],
    ["schemaVersion": 1, "token": " example"],
    ["schemaVersion": 1, "token": "example\n"],
  ]
  return variants.compactMap { try? JSONSerialization.data(withJSONObject: $0) }
    + [Data([0xFF]), Data("[]".utf8)]
}

extension FakePATSecurity: GitHubOAuthSecurityClient {}
