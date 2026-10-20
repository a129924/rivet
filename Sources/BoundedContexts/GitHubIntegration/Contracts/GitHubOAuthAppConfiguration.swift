/// Local OAuth App configuration. Diagnostic and reflection output deliberately omits both fields.
public struct GitHubOAuthAppConfiguration: Sendable, CustomReflectable {
  public let clientID: String
  public let clientSecret: String

  public init(clientID: String, clientSecret: String) throws {
    guard !clientID.isEmpty, !clientSecret.isEmpty else {
      throw GitHubOAuthError.clientConfiguration
    }
    self.clientID = clientID
    self.clientSecret = clientSecret
  }

  public var customMirror: Mirror { Mirror(self, children: EmptyCollection<Mirror.Child>()) }
}

/// Finite initial-authorization classifications; no response, callback, or underlying error escapes.
public enum GitHubOAuthError: Error, Equatable, Sendable {
  case clientConfiguration
  case invalidCallback
  case denied
  case cancelled
  case expiredSession
  case sessionConsumed
  case exchangeRejected
  case transport
  case invalidTokenResponse
}

extension GitHubOAuthAppConfiguration: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { "GitHubOAuthAppConfiguration(<redacted>)" }
  public var debugDescription: String { description }
}
