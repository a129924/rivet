import Foundation
import CoreFoundation

// Experiment-local six-field fake A, copied semantically from committed E006 only.
struct FakeBundle: Codable, Equatable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Double
  let refreshTokenExpiresAt: Double
  let tokenType: String
  let grantedScopes: String
  static let a = FakeBundle(accessToken: "fake-access-A", refreshToken: "fake-refresh-A",
    accessTokenExpiresAt: 2_000_000_120.125, refreshTokenExpiresAt: 2_000_008_640.5,
    tokenType: "bearer", grantedScopes: "repo read:user")
  var description: String { "FakeBundle(<redacted>)" }
  var debugDescription: String { description }
  var customMirror: Mirror { Mirror(self, children: ["credential": "<redacted>"]) }
  func comparisons() -> [String: Bool] {
    let expected = Self.a
    return ["accessToken": accessToken == expected.accessToken, "refreshToken": refreshToken == expected.refreshToken,
      "accessTokenExpiresAt": accessTokenExpiresAt == expected.accessTokenExpiresAt,
      "refreshTokenExpiresAt": refreshTokenExpiresAt == expected.refreshTokenExpiresAt,
      "tokenType": tokenType == expected.tokenType, "grantedScopes": grantedScopes == expected.grantedScopes]
  }
}

enum ProbeError: Error {
  case guardRejected, missing, invalidData, comparison
  case security(String, Int32)
  var classification: String {
    switch self {
    case .guardRejected: return "guardRejected"
    case .missing: return "missing"
    case .invalidData: return "invalidData"
    case .comparison: return "comparison"
    case .security(_, let status):
      switch status {
      case -25293, -128: return "accessDenied"
      case -25308: return "interactionUnavailable"
      case -34018: return "missingEntitlement"
      default: return "securityFailure"
      }
    }
  }
}

enum Operation: String { case seed = "seed-read-a", read = "read-original-a", cleanup = "delete-read-absent" }
protocol ExperimentStore: AnyObject {
  func add(_ data: Data) throws
  func load() throws -> Data?
  func delete() throws
}
struct OperationResult { var fields: [String: Bool] = [:]; var absent: Bool? }
struct ProbeCore {
  let store: any ExperimentStore
  func perform(_ operation: Operation) throws -> OperationResult {
    if operation == .cleanup {
      try store.delete()
      guard try store.load() == nil else { throw ProbeError.comparison }
      return OperationResult(absent: true)
    }
    if operation == .seed { try store.add(JSONEncoder().encode(FakeBundle.a)) }
    guard let raw = try store.load() else { throw ProbeError.missing }
    let value: FakeBundle
    do { value = try JSONDecoder().decode(FakeBundle.self, from: raw) }
    catch { throw ProbeError.invalidData }
    let fields = value.comparisons()
    guard fields.count == 6 && fields.values.allSatisfy({ $0 }) else { throw ProbeError.comparison }
    return OperationResult(fields: fields)
  }
}

enum CanonicalJSON {
  // Match continuity.canonical for receipt values: Unicode scalar key order, two-space
  // indentation, ": ", inline empty collections, UTF-8 strings and one final LF.
  // Receipt numbers are integers (PID/OSStatus); reject floating/non-finite values.
  static func data(_ value: [String: Any]) throws -> Data {
    Data((try render(value, depth: 0) + "\n").utf8)
  }
  private static func quoted(_ value: String) -> String {
    var result = "\""
    for scalar in value.unicodeScalars {
      switch scalar.value {
      case 0x22: result += "\\\""
      case 0x5c: result += "\\\\"
      case 0x08: result += "\\b"
      case 0x0c: result += "\\f"
      case 0x0a: result += "\\n"
      case 0x0d: result += "\\r"
      case 0x09: result += "\\t"
      case 0..<0x20: result += String(format: "\\u%04x", scalar.value)
      default: result.unicodeScalars.append(scalar)
      }
    }
    return result + "\""
  }
  private static func render(_ value: Any, depth: Int) throws -> String {
    let indent = String(repeating: "  ", count: depth)
    let childIndent = indent + "  "
    if value is NSNull { return "null" }
    if let object = value as? [String: Any] {
      if object.isEmpty { return "{}" }
      let keys = object.keys.sorted { left, right in
        left.unicodeScalars.lexicographicallyPrecedes(right.unicodeScalars) { $0.value < $1.value }
      }
      let members = try keys.map { key in childIndent + quoted(key) + ": " + (try render(object[key]!, depth: depth + 1)) }
      return "{\n" + members.joined(separator: ",\n") + "\n" + indent + "}"
    }
    if let array = value as? [Any] {
      if array.isEmpty { return "[]" }
      let members = try array.map { childIndent + (try render($0, depth: depth + 1)) }
      return "[\n" + members.joined(separator: ",\n") + "\n" + indent + "]"
    }
    if let string = value as? String { return quoted(string) }
    if let number = value as? NSNumber {
      if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? "true" : "false" }
      guard !["f", "d"].contains(String(cString: number.objCType)) else { throw ProbeError.guardRejected }
      return number.stringValue
    }
    throw ProbeError.guardRejected
  }
}
