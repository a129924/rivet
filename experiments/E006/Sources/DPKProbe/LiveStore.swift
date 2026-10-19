import Foundation
import Security

// Sole SecItem call site. Constructed only after LiveGate returns authorization.
final class LiveStore: ExperimentStore {
  private let authorization: LiveAuthorization
  init(authorization: LiveAuthorization) { self.authorization = authorization }
  private var query: [CFString: Any] {
    [kSecClass: kSecClassGenericPassword,
     kSecAttrService: authorization.service, kSecAttrAccount: authorization.account,
     kSecAttrAccessGroup: authorization.group, kSecUseDataProtectionKeychain: true,
     kSecAttrSynchronizable: false]
  }
  func save(_ data: Data) throws {
    guard authorization.action == .saveReadA else { throw ProbeError.guardRejected }
    var request = query
    request[kSecValueData] = data
    request[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let status = SecItemAdd(request as CFDictionary, nil)
    guard status == errSecSuccess else { throw ProbeError.security(operation: "add", status: status) }
  }
  func load() throws -> Data? {
    var request = query
    request[kSecReturnData] = true; request[kSecMatchLimit] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw ProbeError.security(operation: "load", status: status) }
    guard let data = result as? Data else { throw ProbeError.invalidData }
    return data
  }
  func delete() throws {
    guard authorization.action == .deleteReadAbsent else { throw ProbeError.guardRejected }
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { throw ProbeError.security(operation: "delete", status: status) }
  }
}
