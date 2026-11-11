import Foundation
import Security

// Sole SecItem entry point; no constructor/call occurs before LiveGate authorization.
final class LiveStore: ExperimentStore {
  let permit: LiveAuthorization
  var calls = 0
  var lastStatus: Int32?
  init(_ permit: LiveAuthorization) { self.permit = permit }
  private var query: [CFString: Any] {
    [kSecClass: kSecClassGenericPassword, kSecUseDataProtectionKeychain: true,
     kSecAttrSynchronizable: false, kSecAttrAccessGroup: permit.accessGroup,
     kSecAttrService: permit.service, kSecAttrAccount: permit.account]
  }
  func add(_ data: Data) throws {
    guard permit.action == .seed else { throw ProbeError.guardRejected }
    try LiveGate.write(permit.root, "write-attempts/\(permit.ticketID).app.json", ["namespace": permit.namespace,
      "synthetic": false, "operation": "seed-read-a", "state": "add-starting", "ticket": permit.ticketID])
    var request = query; request[kSecValueData] = data
    request[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    calls += 1; let status = SecItemAdd(request as CFDictionary, nil); lastStatus = status
    guard status == errSecSuccess else { throw ProbeError.security("add", status) }
  }
  func load() throws -> Data? {
    var request = query; request[kSecReturnData] = true; request[kSecMatchLimit] = kSecMatchLimitOne
    var output: CFTypeRef?; calls += 1
    let status = SecItemCopyMatching(request as CFDictionary, &output); lastStatus = status
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw ProbeError.security("load", status) }
    guard let data = output as? Data else { throw ProbeError.invalidData }; return data
  }
  func delete() throws {
    guard permit.action == .cleanup else { throw ProbeError.guardRejected }
    calls += 1; let status = SecItemDelete(query as CFDictionary); lastStatus = status
    guard status == errSecSuccess || status == errSecItemNotFound else { throw ProbeError.security("delete", status) }
  }
}
