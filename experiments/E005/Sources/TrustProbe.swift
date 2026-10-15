import Foundation
import Security

// This helper reads or changes only one freshly generated experiment certificate.
@main
struct TrustProbe {
  static let policyKey = kSecTrustSettingsPolicy as String
  static let resultKey = kSecTrustSettingsResult as String
  static let policyNameKey = "kSecTrustSettingsPolicyName"
  // Apple Security SecPolicy.list defines this metadata label; the OID is still required.
  static let expectedPolicyName = "CodeSigning"

  static func codeSigningOnly(_ rows: [[String: Any]]) -> Bool {
    guard rows.count == 1, let row = rows.first,
      Set([policyKey, resultKey]).isSubset(of: Set(row.keys)),
      Set(row.keys).isSubset(of: Set([policyKey, resultKey, policyNameKey])),
      let result = row[resultKey] as? NSNumber,
      result.uint32Value == SecTrustSettingsResult.trustRoot.rawValue,
      let value = row[policyKey]
    else { return false }
    if let metadata = row[policyNameKey] {
      guard let name = metadata as? String, name == expectedPolicyName else { return false }
    }
    let object = value as CFTypeRef
    guard CFGetTypeID(object) == SecPolicyGetTypeID() else { return false }
    let policy = object as! SecPolicy
    let properties = SecPolicyCopyProperties(policy) as? [String: Any]
    return (properties?[kSecPolicyOid as String] as? String) == (kSecPolicyAppleCodeSigning as String)
  }

  static func constraintShape(_ rows: [[String: Any]]) -> [[String: Any]] {
    let knownKeys = [policyKey: "policy", resultKey: "result",
      policyNameKey: "policyName",
      kSecTrustSettingsApplication as String: "application",
      kSecTrustSettingsPolicyString as String: "policyString",
      kSecTrustSettingsAllowedError as String: "allowedError",
      kSecTrustSettingsKeyUsage as String: "keyUsage"]
    return rows.map { row in
      var oidMatches = false
      var policyObject = false
      if let value = row[policyKey] {
        let object = value as CFTypeRef
        policyObject = CFGetTypeID(object) == SecPolicyGetTypeID()
        if policyObject {
          let properties = SecPolicyCopyProperties(object as! SecPolicy) as? [String: Any]
          oidMatches = (properties?[kSecPolicyOid as String] as? String) == (kSecPolicyAppleCodeSigning as String)
        }
      }
      let name = row[policyNameKey] as? String
      return ["keyKinds": row.keys.map { knownKeys[$0] ?? "unknown" }.sorted(),
        "policyObjectIsSecPolicy": policyObject, "policyOIDIsCodeSigning": oidMatches,
        "resultIsTrustRoot": (row[resultKey] as? NSNumber)?.uint32Value == SecTrustSettingsResult.trustRoot.rawValue,
        "policyNameIsCanonicalCodeSigning": name == expectedPolicyName]
    }
  }

  static func snapshot(_ certificate: SecCertificate, _ domain: SecTrustSettingsDomain) -> [String: Any] {
    var settings: CFArray?
    let status = SecTrustSettingsCopyTrustSettings(certificate, domain, &settings)
    let rows = settings as? [[String: Any]]
    return [
      "status": status,
      "absent": status == errSecItemNotFound,
      "entryCount": rows?.count ?? -1,
      "constraintShape": rows.map(constraintShape) ?? [],
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
    var withMetadata = exact
    withMetadata[policyNameKey] = expectedPolicyName
    var wrongName = exact
    wrongName[policyNameKey] = "SSL"
    var wrongNameType = exact
    wrongNameType[policyNameKey] = NSNumber(value: 1)
    var unknownKey = exact
    unknownKey["unknownTrustKey"] = true
    let checks = [
      "exactCodeSigningAccepted": codeSigningOnly([exact]),
      "canonicalMetadataAccepted": codeSigningOnly([withMetadata]),
      "mismatchedMetadataRejected": !codeSigningOnly([wrongName]),
      "wrongMetadataTypeRejected": !codeSigningOnly([wrongNameType]),
      "unknownExtraKeyRejected": !codeSigningOnly([unknownKey]),
      "metadataCannotReplacePolicy": !codeSigningOnly([[policyNameKey: expectedPolicyName, resultKey: root]]),
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
