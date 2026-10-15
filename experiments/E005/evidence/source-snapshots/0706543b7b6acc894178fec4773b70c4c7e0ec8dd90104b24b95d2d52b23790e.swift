import Foundation
import Security

// This helper reads or changes only one freshly generated experiment certificate.
@main
struct TrustProbe {
  static let policyKey = kSecTrustSettingsPolicy as String
  static let resultKey = kSecTrustSettingsResult as String

  static func codeSigningOnly(_ rows: [[String: Any]]) -> Bool {
    guard rows.count == 1, let row = rows.first,
      Set(row.keys) == Set([policyKey, resultKey]),
      let result = row[resultKey] as? NSNumber,
      result.uint32Value == SecTrustSettingsResult.trustRoot.rawValue,
      let value = row[policyKey]
    else { return false }
    let object = value as CFTypeRef
    guard CFGetTypeID(object) == SecPolicyGetTypeID() else { return false }
    let policy = object as! SecPolicy
    let properties = SecPolicyCopyProperties(policy) as? [String: Any]
    return (properties?[kSecPolicyOid as String] as? String) == (kSecPolicyAppleCodeSigning as String)
  }

  static func snapshot(_ certificate: SecCertificate, _ domain: SecTrustSettingsDomain) -> [String: Any] {
    var settings: CFArray?
    let status = SecTrustSettingsCopyTrustSettings(certificate, domain, &settings)
    let rows = settings as? [[String: Any]]
    return [
      "status": status,
      "absent": status == errSecItemNotFound,
      "entryCount": rows?.count ?? -1,
      "codeSigningOnly": status == errSecSuccess && rows.map(codeSigningOnly) == true,
    ]
  }

  static func inspection(_ certificate: SecCertificate) -> [String: Any] {
    ["user": snapshot(certificate, .user), "admin": snapshot(certificate, .admin),
     "system": snapshot(certificate, .system)]
  }

  static func allAbsent(_ state: [String: Any]) -> Bool {
    ["user", "admin", "system"].allSatisfy { name in
      (state[name] as? [String: Any])?["absent"] as? Bool == true
    }
  }

  static func emit(_ output: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: output, options: [.sortedKeys]),
      let text = String(data: data, encoding: .utf8)
    { print(text) }
  }

  static func selfCheck() -> Bool {
    guard let policy = SecPolicyCreateWithProperties(kSecPolicyAppleCodeSigning, nil) else { return false }
    let root = NSNumber(value: SecTrustSettingsResult.trustRoot.rawValue)
    let exact: [String: Any] = [policyKey: policy, resultKey: root]
    var extra = exact
    extra[kSecTrustSettingsAllowedError as String] = NSNumber(value: -1)
    let checks = [
      "exactCodeSigningAccepted": codeSigningOnly([exact]),
      "emptyAlwaysTrustRejected": !codeSigningOnly([]),
      "unconstrainedRootRejected": !codeSigningOnly([[resultKey: root]]),
      "SSLRejected": !codeSigningOnly([[policyKey: SecPolicyCreateSSL(true, nil), resultKey: root]]),
      "multipleEntriesRejected": !codeSigningOnly([exact, exact]),
      "allowedErrorRejected": !codeSigningOnly([extra]),
      "wrongResultRejected": !codeSigningOnly([[policyKey: policy,
        resultKey: NSNumber(value: SecTrustSettingsResult.deny.rawValue)]]),
    ]
    emit(["syntheticConstraintChecks": checks, "noTrustMutation": true])
    return checks.values.allSatisfy { $0 }
  }

  static func main() {
    let args = CommandLine.arguments
    if args.count == 2, args[1] == "self-check" {
      exit(selfCheck() ? 0 : 1)
    }
    guard args.count == 3, ["inspect", "add-code-signing", "remove-user"].contains(args[1]),
      let data = try? Data(contentsOf: URL(fileURLWithPath: args[2])),
      let certificate = SecCertificateCreateWithData(nil, data as CFData)
    else { emit(["error": "invalidArgumentsOrCertificate"]); exit(2) }
    var commonName: CFString?
    guard SecCertificateCopyCommonName(certificate, &commonName) == errSecSuccess,
      let commonName = commonName as String?, commonName.hasPrefix("Rivet-E005-"),
      UUID(uuidString: String(commonName.dropFirst("Rivet-E005-".count))) != nil
    else { emit(["error": "notAnIsolatedExperimentCertificate"]); exit(2) }
    if args[1] == "inspect" { emit(inspection(certificate)); return }
    if args[1] == "add-code-signing" {
      let baseline = inspection(certificate)
      guard allAbsent(baseline),
        let policy = SecPolicyCreateWithProperties(kSecPolicyAppleCodeSigning, nil)
      else { emit(["error": "baselineNotAbsent", "mutationAttempted": false, "baseline": baseline]); exit(2) }
      let constraints: [String: Any] = [policyKey: policy,
        resultKey: NSNumber(value: SecTrustSettingsResult.trustRoot.rawValue)]
      let status = SecTrustSettingsSetTrustSettings(certificate, .user, constraints as CFDictionary)
      emit(["status": status, "mutationAttempted": true, "domain": "user", "policy": "codeSign"])
      exit(status == errSecSuccess ? 0 : 1)
    }
    // The owning runner must have proved baseline absence and attempted its own add.
    let status = SecTrustSettingsRemoveTrustSettings(certificate, .user)
    emit(["status": status, "domain": "user", "operation": "remove-exact-certificate"])
    exit(status == errSecSuccess || status == errSecItemNotFound ? 0 : 1)
  }
}
