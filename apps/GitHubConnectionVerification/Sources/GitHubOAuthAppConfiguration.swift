/// Local OAuth App configuration. Diagnostic and reflection output deliberately omits both fields.
struct GitHubOAuthAppConfiguration: Sendable, CustomReflectable {
  let clientID: String
  let clientSecret: String

  init(clientID: String, clientSecret: String) throws {
    guard !clientID.isEmpty, !clientSecret.isEmpty else {
      throw GitHubOAuthError.clientConfiguration
    }
    self.clientID = clientID
    self.clientSecret = clientSecret
  }

  var customMirror: Mirror { Mirror(self, children: EmptyCollection<Mirror.Child>()) }
}

/// Finite initial-authorization classifications; no response, callback, or underlying error escapes.
enum GitHubOAuthError: Error, Equatable, Sendable {
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
  var description: String { "GitHubOAuthAppConfiguration(<redacted>)" }
  var debugDescription: String { description }
}
