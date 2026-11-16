import Foundation

/// A PAT request cannot be constructed from locally empty input.
public enum PATInputError: Error, Equatable, Sendable {
  case empty
}

/// Local input only: this value does not establish remote validity or permissions.
public struct PersonalAccessToken: Equatable, Sendable {
  public let rawValue: String

  public init(rawValue: String) throws(PATInputError) {
    let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { throw .empty }
    self.rawValue = value
  }
}

extension PersonalAccessToken: CustomStringConvertible {
  public var description: String { "PersonalAccessToken(<redacted>)" }
}

extension PersonalAccessToken: CustomDebugStringConvertible {
  public var debugDescription: String { description }
}

extension PersonalAccessToken: CustomReflectable {
  public var customMirror: Mirror { Mirror(self, children: [] as [Mirror.Child]) }
}

/// OAuth configuration belongs to service composition, not individual requests.
public enum LoginRequest: Equatable, Sendable {
  case oauth
  case pat(PersonalAccessToken)
}

extension LoginRequest: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
  public var description: String {
    switch self {
    case .oauth: "LoginRequest.oauth"
    case .pat: "LoginRequest.pat(<redacted>)"
    }
  }

  public var debugDescription: String { description }
  public var customMirror: Mirror { Mirror(self, children: [] as [Mirror.Child]) }
}

/// An attempt did not complete; this does not prove that credentials are invalid.
public enum LoginFailure: Error, Equatable, Sendable {
  case authenticationFailed
}

/// Success is a marker only; it does not hand off an account, session or clients.
public enum LoginOutcome: Equatable, Sendable {
  case success
  case failure(LoginFailure)
  case cancelled
}

/// A common nonthrowing boundary for GitHub.com OAuth and PAT login requests.
///
/// Conformers must return `cancelled` without starting work when already cancelled.
/// During execution, propagate cancellation and wait for the original work to settle.
/// Immediately before returning, synchronously check cancellation: observed cancellation
/// takes priority over success or failure, with no subsequent suspension. A result already
/// returned is not rewritten. These are conformer obligations, not protocol enforcement.
public protocol LoginAuthenticating: Sendable {
  func authenticate(_ request: LoginRequest) async -> LoginOutcome
}
