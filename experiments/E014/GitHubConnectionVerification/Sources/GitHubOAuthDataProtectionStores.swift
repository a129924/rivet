import Foundation
import GitHubIntegration
import Security

enum GitHubOAuthStoreError: Error, Equatable, Sendable {
  case denied
  case unavailable
  case corrupt
  case identityMismatch
}

protocol GitHubOAuthAppConfigurationStore: Sendable {
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration?
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable)
}

struct GitHubOAuthStoredCredential: Sendable {
  let clientID: String
  let bundle: GitHubOAuthCredentialBundle
}

/// The two items share one serialized backend, but are not a cross-item transaction.
struct GitHubOAuthDataProtectionStores: Sendable {
  private let backend: OAuthDataProtectionBackend

  init(accessGroup: String, service: String) {
    self.init(accessGroup: accessGroup, service: service, security: SystemOAuthSecurityClient())
  }

  init(accessGroup: String, service: String, security: any GitHubOAuthSecurityClient) {
    backend = OAuthDataProtectionBackend(
      accessGroup: accessGroup, service: service, security: security)
  }

  var configurationStore: any GitHubOAuthAppConfigurationStore {
    DataProtectionConfigurationStore(backend: backend)
  }

  func inspectCredential() async throws -> GitHubOAuthStoredCredential? {
    try await backend.inspectCredential()
  }

  func credentialStore(clientID: String) -> any OAuthCredentialStore {
    DataProtectionCredentialStore(backend: backend, clientID: clientID)
  }
}

// Synchronous calls ensure the backend never suspends between update / add / duplicate recovery.
protocol GitHubOAuthSecurityClient: Sendable {
  func copy(_ query: [String: Any]) -> (OSStatus, Data?)
  func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus
  func add(_ query: [String: Any]) -> OSStatus
}

private struct SystemOAuthSecurityClient: GitHubOAuthSecurityClient {
  func copy(_ query: [String: Any]) -> (OSStatus, Data?) {
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    return (status, result as? Data)
  }
  func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus {
    SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
  }
  func add(_ query: [String: Any]) -> OSStatus {
    SecItemAdd(query as CFDictionary, nil)
  }
}

private struct DataProtectionConfigurationStore: GitHubOAuthAppConfigurationStore {
  let backend: OAuthDataProtectionBackend
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? {
    try await backend.loadConfiguration()
  }
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {
    try await backend.save(configuration)
  }
}

private struct DataProtectionCredentialStore: OAuthCredentialStore {
  let backend: OAuthDataProtectionBackend
  let clientID: String
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try await backend.loadCredential(clientID: clientID)
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    try await backend.save(credential, clientID: clientID)
  }
}

private actor OAuthDataProtectionBackend {
  let accessGroup: String
  let service: String
  let security: any GitHubOAuthSecurityClient

  init(accessGroup: String, service: String, security: any GitHubOAuthSecurityClient) {
    self.accessGroup = accessGroup
    self.service = service
    self.security = security
  }

  func loadConfiguration() throws(GitHubOAuthStoreError) -> GitHubOAuthAppConfiguration? {
    guard let data = try load(account: "configuration") else { return nil }
    guard let envelope = try? JSONDecoder().decode(ConfigurationEnvelope.self, from: data),
      envelope.schemaVersion == 1,
      let configuration = try? GitHubOAuthAppConfiguration(
        clientID: envelope.clientID, clientSecret: envelope.clientSecret)
    else { throw .corrupt }
    return configuration
  }

  func save(_ configuration: GitHubOAuthAppConfiguration) throws(GitHubOAuthStoreError) {
    let envelope = ConfigurationEnvelope(
      schemaVersion: 1, clientID: configuration.clientID, clientSecret: configuration.clientSecret)
    try save(encode(envelope), account: "configuration")
  }

  func inspectCredential() throws(GitHubOAuthStoreError) -> GitHubOAuthStoredCredential? {
    guard let data = try load(account: "credential") else { return nil }
    guard let envelope = try? JSONDecoder().decode(CredentialEnvelope.self, from: data),
      envelope.schemaVersion == 1, envelope.isValid
    else { throw .corrupt }
    return GitHubOAuthStoredCredential(clientID: envelope.clientID, bundle: envelope.bundle)
  }

  func loadCredential(
    clientID: String
  ) throws(GitHubOAuthStoreError) -> GitHubOAuthCredentialBundle? {
    guard let credential = try inspectCredential() else { return nil }
    guard !clientID.isEmpty, credential.clientID == clientID else { throw .identityMismatch }
    return credential.bundle
  }

  func save(_ bundle: GitHubOAuthCredentialBundle, clientID: String) throws(GitHubOAuthStoreError) {
    let envelope = CredentialEnvelope(clientID: clientID, bundle: bundle)
    guard envelope.isValid else { throw .corrupt }
    try save(encode(envelope), account: "credential")
  }

  private func encode(_ value: some Encodable) throws(GitHubOAuthStoreError) -> Data {
    do { return try JSONEncoder().encode(value) } catch { throw .corrupt }
  }

  private func baseQuery(account: String) throws(GitHubOAuthStoreError) -> [String: Any] {
    guard !accessGroup.isEmpty, !service.isEmpty else { throw .unavailable }
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecUseDataProtectionKeychain as String: true,
      kSecAttrSynchronizable as String: false,
      kSecAttrAccessGroup as String: accessGroup,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  private func load(account: String) throws(GitHubOAuthStoreError) -> Data? {
    var query = try baseQuery(account: account)
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnData as String] = true
    let (status, data) = security.copy(query)
    if status == errSecItemNotFound { return nil }
    try check(status)
    guard let data else { throw .corrupt }
    return data
  }

  private func save(_ data: Data, account: String) throws(GitHubOAuthStoreError) {
    let query = try baseQuery(account: account)
    let attributes: [String: Any] = [kSecValueData as String: data]
    let status = security.update(query, attributes: attributes)
    if status == errSecSuccess { return }
    guard status == errSecItemNotFound else {
      try check(status)
      return
    }
    var addition = query
    addition[kSecValueData as String] = data
    addition[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let added = security.add(addition)
    if added == errSecDuplicateItem {
      try check(security.update(query, attributes: attributes))
    } else {
      try check(added)
    }
  }

  private func check(_ status: OSStatus) throws(GitHubOAuthStoreError) {
    switch status {
    case errSecSuccess: return
    case errSecAuthFailed, errSecInteractionNotAllowed, errSecUserCanceled: throw .denied
    default: throw .unavailable
    }
  }
}

private struct ConfigurationEnvelope: Codable {
  let schemaVersion: Int
  let clientID: String
  let clientSecret: String
}

// Millisecond numbers are explicit here; the domain bundle does not acquire Codable.
private struct CredentialEnvelope: Codable {
  let schemaVersion: Int
  let clientID: String
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Double
  let refreshTokenExpiresAt: Double
  let tokenType: String
  let grantedScopes: String

  init(clientID: String, bundle: GitHubOAuthCredentialBundle) {
    schemaVersion = 1
    self.clientID = clientID
    accessToken = bundle.accessToken.rawValue
    refreshToken = bundle.refreshToken.rawValue
    accessTokenExpiresAt = bundle.accessTokenExpiresAt.timeIntervalSince1970 * 1000
    refreshTokenExpiresAt = bundle.refreshTokenExpiresAt.timeIntervalSince1970 * 1000
    tokenType = bundle.tokenType.rawValue
    grantedScopes = bundle.grantedScopes
  }

  var isValid: Bool {
    !clientID.isEmpty && !accessToken.isEmpty && !refreshToken.isEmpty
      && tokenType == GitHubOAuthTokenType.bearer.rawValue
      && accessTokenExpiresAt.isFinite && refreshTokenExpiresAt.isFinite
  }

  var bundle: GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: .init(rawValue: accessToken), refreshToken: .init(rawValue: refreshToken),
      accessTokenExpiresAt: Date(timeIntervalSince1970: accessTokenExpiresAt / 1000),
      refreshTokenExpiresAt: Date(timeIntervalSince1970: refreshTokenExpiresAt / 1000),
      tokenType: .bearer, grantedScopes: grantedScopes)
  }
}
