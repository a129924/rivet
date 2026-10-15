import Foundation
import Security

// Experimental host only; the three production contract sources are compiled read-only.
private struct CredentialDTO: Codable {
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Date
  let refreshTokenExpiresAt: Date
  let tokenType: String
  let grantedScopes: String

  init(_ bundle: GitHubOAuthCredentialBundle) {
    accessToken = bundle.accessToken.rawValue
    refreshToken = bundle.refreshToken.rawValue
    accessTokenExpiresAt = bundle.accessTokenExpiresAt
    refreshTokenExpiresAt = bundle.refreshTokenExpiresAt
    tokenType = bundle.tokenType.rawValue
    grantedScopes = bundle.grantedScopes
  }

  func bundle() throws -> GitHubOAuthCredentialBundle {
    guard let type = GitHubOAuthTokenType(rawValue: tokenType) else {
      throw ProbeFailure.invalidData
    }
    return GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: accessToken),
      refreshToken: GitHubOAuthRefreshToken(rawValue: refreshToken),
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      tokenType: type, grantedScopes: grantedScopes)
  }
}

private enum Backend: String, Sendable { case legacy, dpk }
private enum ProbeFailure: Error, Sendable {
  case security(operation: String, status: OSStatus)
  case invalidData
  case comparison
  case arguments
}

private func decodeLoad(status: OSStatus, result: CFTypeRef?) throws
  -> GitHubOAuthCredentialBundle?
{
  if status == errSecItemNotFound { return nil }
  guard status == errSecSuccess else {
    throw ProbeFailure.security(operation: "load", status: status)
  }
  guard let data = result as? Data else { throw ProbeFailure.invalidData }
  do { return try JSONDecoder().decode(CredentialDTO.self, from: data).bundle() }
  catch { throw ProbeFailure.invalidData }
}

private struct ProbeStore: OAuthCredentialStore {
  let namespace: UUID
  let backend: Backend

  private var query: [CFString: Any] {
    [kSecClass: kSecClassGenericPassword,
     kSecAttrService: "com.rivet.experiments.E005.\(namespace.uuidString)",
     kSecAttrAccount: "oauth-bundle",
     kSecUseDataProtectionKeychain: backend == .dpk,
     kSecAttrSynchronizable: false]
  }

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    var request = query
    request[kSecMatchLimit] = kSecMatchLimitOne
    request[kSecReturnData] = true
    var result: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    return try decodeLoad(status: status, result: result)
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    try saveData(JSONEncoder().encode(CredentialDTO(credential)))
  }

  func saveData(_ data: Data) throws {
    let update = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
    if update == errSecSuccess { return }
    guard update == errSecItemNotFound else {
      throw ProbeFailure.security(operation: "update", status: update)
    }
    var request = query
    request[kSecValueData] = data
    let add = SecItemAdd(request as CFDictionary, nil)
    guard add == errSecSuccess else {
      throw ProbeFailure.security(operation: "add", status: add)
    }
  }

  // Explicitly experiment-only. Never invoked automatically by a child writer/reader.
  func delete() throws {
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw ProbeFailure.security(operation: "delete", status: status)
    }
  }
}

private func fixture(_ name: String) -> GitHubOAuthCredentialBundle {
  let isA = name == "A"
  return GitHubOAuthCredentialBundle(
    accessToken: GitHubAccessToken(rawValue: isA ? "fake-access-A" : "fake-access-B"),
    refreshToken: GitHubOAuthRefreshToken(rawValue: isA ? "fake-refresh-A" : "fake-refresh-B"),
    accessTokenExpiresAt: Date(timeIntervalSince1970: isA ? 2_000_000_120.125 : 2_000_003_600.25),
    refreshTokenExpiresAt: Date(timeIntervalSince1970: isA ? 2_000_008_640.5 : 2_000_017_280.75),
    tokenType: .bearer, grantedScopes: isA ? "repo read:user" : "repo read:user workflow")
}

private func comparisons(_ value: GitHubOAuthCredentialBundle?, _ name: String) -> [String: Bool] {
  guard let value else { return ["present": false] }
  let expected = fixture(name)
  return ["accessToken": value.accessToken == expected.accessToken,
          "refreshToken": value.refreshToken.rawValue == expected.refreshToken.rawValue,
          "accessTokenExpiresAt": value.accessTokenExpiresAt == expected.accessTokenExpiresAt,
          "refreshTokenExpiresAt": value.refreshTokenExpiresAt == expected.refreshTokenExpiresAt,
          "tokenType": value.tokenType == expected.tokenType,
          "grantedScopes": value.grantedScopes == expected.grantedScopes]
}

private func emit(_ value: [String: Any]) {
  if let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
    let line = String(data: data, encoding: .utf8) { print(line) }
}

@main
private enum Main {
  static func main() async {
    do {
      let args = Array(CommandLine.arguments.dropFirst())
      guard args.count == 3, let backend = Backend(rawValue: args[1]),
        let namespace = UUID(uuidString: args[2]) else { throw ProbeFailure.arguments }
      let mode = args[0]
      let store = ProbeStore(namespace: namespace, backend: backend)
      switch mode {
      case "identity":
        #if REBUILT
          emit(["buildMarker": "rebuilt"])
        #else
          emit(["buildMarker": "initial"])
        #endif
      case "write-a", "replace-b":
        try await store.save(fixture(mode == "write-a" ? "A" : "B"))
        emit(["operation": mode, "saved": true])
      case "read-a", "read-b":
        let fields = comparisons(try await store.load(), mode == "read-a" ? "A" : "B")
        emit(["operation": mode, "fields": fields])
        guard fields.count == 6 && fields.values.allSatisfy({ $0 }) else {
          throw ProbeFailure.comparison
        }
      case "write-invalid":
        try store.saveData(Data("invalid-json-fixture".utf8))
        emit(["operation": mode, "saved": true])
      case "read-invalid":
        do { _ = try await store.load(); throw ProbeFailure.comparison }
        catch ProbeFailure.invalidData { emit(["operation": mode, "decodeFailure": true]) }
      case "read-absent":
        guard try await store.load() == nil else { throw ProbeFailure.comparison }
        emit(["operation": mode, "absent": true])
      case "delete":
        try store.delete()
        emit(["operation": mode, "deleted": true])
      case "synthetic-check":
        var checks: [String: Bool] = [:]
        checks["absent"] = try decodeLoad(status: errSecItemNotFound, result: nil) == nil
        for (label, status) in [("denied", errSecAuthFailed), ("cancelled", errSecUserCanceled),
                                ("interactionUnavailable", errSecInteractionNotAllowed),
                                ("unavailable", errSecNotAvailable)] {
          do { _ = try decodeLoad(status: status, result: nil); checks[label] = false }
          catch ProbeFailure.security(_, let actual) { checks[label] = actual == status }
        }
        do { _ = try decodeLoad(status: errSecSuccess, result: Data("invalid".utf8) as CFData)
          checks["malformed"] = false
        } catch ProbeFailure.invalidData { checks["malformed"] = true }
        let data = try JSONEncoder().encode(CredentialDTO(fixture("A")))
        let fields = comparisons(try decodeLoad(status: errSecSuccess, result: data as CFData), "A")
        checks["sixFieldRoundTrip"] = fields.count == 6 && fields.values.allSatisfy({ $0 })
        emit(["synthetic": true, "checks": checks])
        guard checks.values.allSatisfy({ $0 }) else { throw ProbeFailure.comparison }
      default: throw ProbeFailure.arguments
      }
    } catch ProbeFailure.security(let operation, let status) {
      let classification: String
      switch status {
      case errSecAuthFailed, errSecUserCanceled: classification = "accessDenied"
      case errSecInteractionNotAllowed: classification = "interactionUnavailable"
      default: classification = "securityFailure"
      }
      emit(["error": classification, "operation": operation, "status": status]); exit(2)
    } catch ProbeFailure.invalidData {
      emit(["error": "decodeFailure"]); exit(2)
    } catch {
      emit(["error": "probeFailure"]); exit(2)
    }
  }
}
