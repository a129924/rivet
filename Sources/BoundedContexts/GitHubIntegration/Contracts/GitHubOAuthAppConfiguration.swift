import Foundation

public struct GitHubOAuthAppConfiguration: Sendable, CustomReflectable {
  internal let clientID: String
  internal let clientSecret: String

  public init(clientID: String, clientSecret: String) throws {
    guard !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw GitHubOAuthAuthorizationError.clientConfiguration }
    self.clientID = clientID
    self.clientSecret = clientSecret
  }

  public var customMirror: Mirror { Mirror(self, children: [:]) }
}

extension GitHubOAuthAppConfiguration: CustomStringConvertible {
  public var description: String { "GitHubOAuthAppConfiguration(<redacted>)" }
}

extension GitHubOAuthAppConfiguration: CustomDebugStringConvertible {
  public var debugDescription: String { description }
}
