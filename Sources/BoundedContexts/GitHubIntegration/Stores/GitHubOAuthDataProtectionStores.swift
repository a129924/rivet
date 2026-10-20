import Foundation
import Security

public enum GitHubOAuthDataProtectionStoreError: Error, Sendable {
  case denied
  case unavailable
  case corrupt
  case identityMismatch
  case invalidConfiguration
}

public struct GitHubOAuthStoredCredential: Sendable {
  public let clientID: String
  public let credential: GitHubOAuthCredentialBundle

  fileprivate init(clientID: String, credential: GitHubOAuthCredentialBundle) {
    self.clientID = clientID
    self.credential = credential
  }
}

extension GitHubOAuthStoredCredential: CustomStringConvertible {
  public var description: String { "GitHubOAuthStoredCredential(<redacted>)" }
}

extension GitHubOAuthStoredCredential: CustomDebugStringConvertible {
  public var debugDescription: String { description }
}

extension GitHubOAuthStoredCredential: CustomReflectable {
  public var customMirror: Mirror { Mirror(self, children: [] as [Mirror.Child]) }
}

/// Caller-owned stores. A signed host must supply its entitled, explicit access group.
/// Construction performs no Keychain operations. All views share one serial actor.
public struct GitHubOAuthDataProtectionStores: Sendable {
  public let configurationStore: any GitHubOAuthAppConfigurationStore
  private let storage: OAuthDataProtectionStorage

  public init(
    accessGroup: String,
    service: String = "local.rivet.github.oauth.v1"
  ) throws(GitHubOAuthDataProtectionStoreError) {
    try self.init(
      accessGroup: accessGroup, service: service, security: LiveGitHubOAuthSecurityClient())
  }

  init(
    accessGroup: String,
    service: String,
    security: any GitHubOAuthSecurityClient
  ) throws(GitHubOAuthDataProtectionStoreError) {
    guard !accessGroup.isEmpty, !accessGroup.contains("*"), !service.isEmpty else {
      throw .invalidConfiguration
    }
    let storage = OAuthDataProtectionStorage(
      accessGroup: accessGroup, service: service, security: security)
    self.storage = storage
    configurationStore = ConfigurationStore(storage: storage)
  }

  public func inspectCredential() async throws -> GitHubOAuthStoredCredential? {
    try await storage.inspectCredential()
  }

  public func credentialStore(clientID: String) -> any OAuthCredentialStore {
    BoundCredentialStore(storage: storage, clientID: clientID)
  }
}

/// Synchronous calls keep each actor operation (including read-check-write) uninterrupted.
protocol GitHubOAuthSecurityClient: Sendable {
  func copyMatching(_ query: [CFString: Any]) -> (OSStatus, Data?)
  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus
  func add(_ query: [CFString: Any]) -> OSStatus
}

private struct LiveGitHubOAuthSecurityClient: GitHubOAuthSecurityClient {
  func copyMatching(_ query: [CFString: Any]) -> (OSStatus, Data?) {
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    return (status, result as? Data)
  }

  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus {
    SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
  }

  func add(_ query: [CFString: Any]) -> OSStatus {
    SecItemAdd(query as CFDictionary, nil)
  }
}

private struct ConfigurationStore: GitHubOAuthAppConfigurationStore {
  let storage: OAuthDataProtectionStorage

  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? {
    try await storage.loadConfiguration()
  }

  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {
    try await storage.saveConfiguration(configuration)
  }
}

private struct BoundCredentialStore: OAuthCredentialStore {
  let storage: OAuthDataProtectionStorage
  let clientID: String

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try await storage.loadCredential(clientID: clientID)
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    try await storage.saveCredential(credential, clientID: clientID)
  }
}

private typealias StoreError = GitHubOAuthDataProtectionStoreError

private actor OAuthDataProtectionStorage {
  let accessGroup: String
  let service: String
  let security: any GitHubOAuthSecurityClient

  init(accessGroup: String, service: String, security: any GitHubOAuthSecurityClient) {
    self.accessGroup = accessGroup
    self.service = service
    self.security = security
  }

  func loadConfiguration() throws(StoreError) -> GitHubOAuthAppConfiguration? {
    guard let data = try loadData(account: "configuration") else { return nil }
    do {
      let payload = try JSONDecoder().decode(ConfigurationPayload.self, from: data)
      guard payload.schemaVersion == 1 else { throw GitHubOAuthDataProtectionStoreError.corrupt }
      return try GitHubOAuthAppConfiguration(
        clientID: payload.clientID, clientSecret: payload.clientSecret)
    } catch {
      throw .corrupt
    }
  }

  func saveConfiguration(_ configuration: GitHubOAuthAppConfiguration) throws(StoreError) {
    let payload = ConfigurationPayload(
      schemaVersion: 1, clientID: configuration.clientID, clientSecret: configuration.clientSecret)
    try saveData(encode(payload), account: "configuration")
  }

  func inspectCredential() throws(StoreError) -> GitHubOAuthStoredCredential? {
    guard let data = try loadData(account: "credential") else { return nil }
    do {
      let payload = try JSONDecoder().decode(CredentialPayload.self, from: data)
      try payload.validate()
      return GitHubOAuthStoredCredential(clientID: payload.clientID, credential: payload.credential)
    } catch {
      throw .corrupt
    }
  }

  func loadCredential(clientID: String) throws(StoreError) -> GitHubOAuthCredentialBundle? {
    guard !clientID.isEmpty else { throw .invalidConfiguration }
    guard let stored = try inspectCredential() else { return nil }
    guard stored.clientID == clientID else { throw .identityMismatch }
    return stored.credential
  }

  func saveCredential(
    _ credential: GitHubOAuthCredentialBundle, clientID: String
  ) throws(StoreError) {
    guard !clientID.isEmpty else { throw .invalidConfiguration }
    let payload = CredentialPayload(clientID: clientID, credential: credential)
    try payload.validate()
    let data = try encode(payload)
    if let existing = try inspectCredential(), existing.clientID != clientID {
      throw .identityMismatch
    }
    try saveData(data, account: "credential")
  }

  private func query(account: String) -> [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessGroup: accessGroup,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecUseDataProtectionKeychain: true,
      kSecAttrSynchronizable: false,
    ]
  }

  private func loadData(account: String) throws(StoreError) -> Data? {
    var query = query(account: account)
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = true
    let (status, data) = security.copyMatching(query)
    if status == errSecItemNotFound { return nil }
    try requireSuccess(status)
    guard let data else { throw .corrupt }
    return data
  }

  private func saveData(_ data: Data, account: String) throws(StoreError) {
    let query = query(account: account)
    let attributes: [CFString: Any] = [kSecValueData: data]
    let updateStatus = security.update(query, attributes: attributes)
    guard updateStatus == errSecItemNotFound else {
      try requireSuccess(updateStatus)
      return
    }
    var addition = query
    addition[kSecValueData] = data
    addition[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let addStatus = security.add(addition)
    if addStatus == errSecDuplicateItem {
      try requireSuccess(security.update(query, attributes: attributes))
    } else {
      try requireSuccess(addStatus)
    }
  }

  private func encode<Value: Encodable>(_ value: Value) throws(StoreError) -> Data {
    do { return try JSONEncoder().encode(value) } catch { throw .corrupt }
  }

  private func requireSuccess(_ status: OSStatus) throws(StoreError) {
    switch status {
    case errSecSuccess: return
    case errSecAuthFailed, errSecUserCanceled: throw .denied
    case errSecDecode: throw .corrupt
    default: throw .unavailable
    }
  }
}

private struct ConfigurationPayload: Codable {
  let schemaVersion: Int
  let clientID: String
  let clientSecret: String
}

private struct CredentialPayload: Codable {
  let schemaVersion: Int
  let clientID: String
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Double
  let refreshTokenExpiresAt: Double
  let tokenType: String
  let grantedScopes: String

  init(clientID: String, credential: GitHubOAuthCredentialBundle) {
    schemaVersion = 1
    self.clientID = clientID
    accessToken = credential.accessToken.rawValue
    refreshToken = credential.refreshToken.rawValue
    accessTokenExpiresAt = credential.accessTokenExpiresAt.timeIntervalSince1970 * 1000
    refreshTokenExpiresAt = credential.refreshTokenExpiresAt.timeIntervalSince1970 * 1000
    tokenType = credential.tokenType.rawValue
    grantedScopes = credential.grantedScopes
  }

  var credential: GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: accessToken),
      refreshToken: GitHubOAuthRefreshToken(rawValue: refreshToken),
      accessTokenExpiresAt: Date(timeIntervalSince1970: accessTokenExpiresAt / 1000),
      refreshTokenExpiresAt: Date(timeIntervalSince1970: refreshTokenExpiresAt / 1000),
      tokenType: .bearer, grantedScopes: grantedScopes
    )
  }

  func validate() throws(StoreError) {
    guard schemaVersion == 1, !clientID.isEmpty, !accessToken.isEmpty, !refreshToken.isEmpty,
      tokenType == GitHubOAuthTokenType.bearer.rawValue,
      accessTokenExpiresAt.isFinite, refreshTokenExpiresAt.isFinite,
      credential.accessTokenExpiresAt.timeIntervalSince1970.isFinite,
      credential.refreshTokenExpiresAt.timeIntervalSince1970.isFinite
    else { throw .corrupt }
  }
}
