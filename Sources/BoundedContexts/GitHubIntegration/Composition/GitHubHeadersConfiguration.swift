import Foundation

struct GitHubHeadersConfiguration: Sendable {
  enum Field: Equatable, Sendable {
    case restAccept
    case standardUserAgent
    case loginUserAgent
    case apiVersion
  }

  enum ValidationError: Error, Equatable, Sendable {
    case invalidValue(Field)
  }

  static let rivet: Self = {
    do {
      return try Self(
        restAccept: "application/vnd.github+json", standardUserAgent: "Rivet",
        loginUserAgent: "RivetLoginRuntime", apiVersion: "2026-03-10")
    } catch {
      preconditionFailure("Invalid built-in GitHub header configuration")
    }
  }()

  let restAccept: String
  let standardUserAgent: String
  let loginUserAgent: String
  let apiVersion: String

  init(
    restAccept: String,
    standardUserAgent: String,
    loginUserAgent: String,
    apiVersion: String
  ) throws(ValidationError) {
    self.restAccept = try Self.validated(restAccept, field: .restAccept)
    self.standardUserAgent = try Self.validated(standardUserAgent, field: .standardUserAgent)
    self.loginUserAgent = try Self.validated(loginUserAgent, field: .loginUserAgent)
    self.apiVersion = try Self.validated(apiVersion, field: .apiVersion)
  }

  private static func validated(_ value: String, field: Field) throws(ValidationError) -> String {
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !value.utf8.contains(0x0D), !value.utf8.contains(0x0A)
    else { throw .invalidValue(field) }
    return value
  }
}
