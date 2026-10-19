import Foundation

// Fake fixture and six equality fields match E005/Sources/KeychainProbe.swift.
// Experiment-local DTO: no dependency on production contracts or provider.
struct FakeBundle: Codable, Equatable, CustomStringConvertible, CustomDebugStringConvertible,
  CustomReflectable
{
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Date
  let refreshTokenExpiresAt: Date
  let tokenType: String
  let grantedScopes: String

  static let a = FakeBundle(
    accessToken: "fake-access-A", refreshToken: "fake-refresh-A",
    accessTokenExpiresAt: Date(timeIntervalSince1970: 2_000_000_120.125),
    refreshTokenExpiresAt: Date(timeIntervalSince1970: 2_000_008_640.5),
    tokenType: "bearer", grantedScopes: "repo read:user")
  var description: String { "FakeBundle(<redacted>)" }
  var debugDescription: String { description }
  var customMirror: Mirror { Mirror(self, children: ["credential": "<redacted>"]) }

  func comparisons() -> [String: Bool] {
    let expected = Self.a
    return ["accessToken": accessToken == expected.accessToken,
            "refreshToken": refreshToken == expected.refreshToken,
            "accessTokenExpiresAt": accessTokenExpiresAt == expected.accessTokenExpiresAt,
            "refreshTokenExpiresAt": refreshTokenExpiresAt == expected.refreshTokenExpiresAt,
            "tokenType": tokenType == expected.tokenType,
            "grantedScopes": grantedScopes == expected.grantedScopes]
  }
}

enum ProbeError: Error {
  case missing, invalidData, comparison, guardRejected
  case security(operation: String, status: Int32)

  var classification: String {
    switch self {
    case .missing: return "missing"
    case .invalidData: return "invalidData"
    case .comparison: return "comparison"
    case .guardRejected: return "guardRejected"
    case .security(_, let status):
      switch status {
      case -25293, -128: return "accessDenied"
      case -25308: return "interactionUnavailable"
      default: return "securityFailure"
      }
    }
  }
}

enum Operation: String { case saveReadA = "save-read-a", readA = "read-a", deleteReadAbsent = "delete-read-absent" }
protocol ExperimentStore: AnyObject {
  func save(_ data: Data) throws
  func load() throws -> Data?
  func delete() throws
}
struct OperationResult {
  var fields: [String: Bool] = [:]
  var absent: Bool?
}
struct ProbeCore {
  let store: any ExperimentStore
  func perform(_ operation: Operation) throws -> OperationResult {
    if operation == .deleteReadAbsent {
      try store.delete()
      guard try store.load() == nil else { throw ProbeError.comparison }
      return OperationResult(absent: true)
    }
    if operation == .saveReadA { try store.save(JSONEncoder().encode(FakeBundle.a)) }
    guard let data = try store.load() else { throw ProbeError.missing }
    let value: FakeBundle
    do { value = try JSONDecoder().decode(FakeBundle.self, from: data) }
    catch { throw ProbeError.invalidData }
    let fields = value.comparisons()
    guard fields.count == 6 && fields.values.allSatisfy({ $0 }) else { throw ProbeError.comparison }
    return OperationResult(fields: fields)
  }
}
