import Foundation
import Security

public enum GitHubPATDataProtectionStoreError: Error, Sendable {
  case denied
  case unavailable
  case corrupt
  case invalidConfiguration
}

/// Caller-owned PAT storage. The signed host supplies its explicit, entitled access group.
/// Construction performs no Security calls. Coordination is limited to this actor instance.
public actor GitHubPATDataProtectionStore {
  private let accessGroup: String
  private let service: String
  private let security: any GitHubPATSecurityClient

  public init(
    accessGroup: String,
    service: String = "local.rivet.github.pat.v1"
  ) throws(GitHubPATDataProtectionStoreError) {
    try Self.validate(accessGroup: accessGroup, service: service)
    self.accessGroup = accessGroup
    self.service = service
    security = LiveGitHubPATSecurityClient()
  }

  init(
    accessGroup: String,
    service: String,
    security: any GitHubPATSecurityClient
  ) throws(GitHubPATDataProtectionStoreError) {
    try Self.validate(accessGroup: accessGroup, service: service)
    self.accessGroup = accessGroup
    self.service = service
    self.security = security
  }

  public func load() async throws(GitHubPATDataProtectionStoreError) -> PersonalAccessToken? {
    try loadToken()
  }

  public func save(_ token: PersonalAccessToken) async throws(GitHubPATDataProtectionStoreError) {
    // No suspension between validating the existing item and the complete write.
    _ = try loadToken()
    let data: Data
    do {
      data = try JSONEncoder().encode(PATPayload(schemaVersion: 1, token: token.rawValue))
    } catch {
      throw .corrupt
    }
    let query = itemQuery()
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

  private static func validate(
    accessGroup: String, service: String
  ) throws(GitHubPATDataProtectionStoreError) {
    guard !accessGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !accessGroup.contains("*"),
      !service.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw .invalidConfiguration }
  }

  private func itemQuery() -> [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessGroup: accessGroup,
      kSecAttrService: service,
      kSecAttrAccount: "pat",
      kSecUseDataProtectionKeychain: true,
      kSecAttrSynchronizable: false,
    ]
  }

  private func loadToken() throws(GitHubPATDataProtectionStoreError) -> PersonalAccessToken? {
    var query = itemQuery()
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = true
    let (status, data) = security.copyMatching(query)
    if status == errSecItemNotFound { return nil }
    try requireSuccess(status)
    guard let data else { throw .corrupt }
    do {
      let payload = try JSONDecoder().decode(PATPayload.self, from: data)
      let token = try PersonalAccessToken(rawValue: payload.token)
      guard payload.schemaVersion == 1, token.rawValue == payload.token else {
        throw GitHubPATDataProtectionStoreError.corrupt
      }
      return token
    } catch {
      throw .corrupt
    }
  }

  private func requireSuccess(_ status: OSStatus) throws(GitHubPATDataProtectionStoreError) {
    switch status {
    case errSecSuccess: return
    case errSecAuthFailed, errSecUserCanceled: throw .denied
    case errSecDecode: throw .corrupt
    default: throw .unavailable
    }
  }
}

/// Synchronous Security operations keep actor read-check-write uninterrupted.
protocol GitHubPATSecurityClient: Sendable {
  func copyMatching(_ query: [CFString: Any]) -> (OSStatus, Data?)
  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus
  func add(_ query: [CFString: Any]) -> OSStatus
}

private struct LiveGitHubPATSecurityClient: GitHubPATSecurityClient {
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

private struct PATPayload: Codable {
  let schemaVersion: Int
  let token: String
}
