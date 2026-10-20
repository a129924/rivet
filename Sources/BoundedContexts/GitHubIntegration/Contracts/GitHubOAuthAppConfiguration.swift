public enum GitHubOAuthAppConfigurationError: Error, Sendable {
  case invalidConfiguration
}

public struct GitHubOAuthAppConfiguration: Sendable {
  public let clientID: String
  public let clientSecret: String

  public init(clientID: String, clientSecret: String) throws(GitHubOAuthAppConfigurationError) {
    guard !clientID.isEmpty, !clientSecret.isEmpty else { throw .invalidConfiguration }
    self.clientID = clientID
    self.clientSecret = clientSecret
  }
}

extension GitHubOAuthAppConfiguration: CustomStringConvertible {
  public var description: String { "GitHubOAuthAppConfiguration(<redacted>)" }
}

extension GitHubOAuthAppConfiguration: CustomDebugStringConvertible {
  public var debugDescription: String { description }
}

extension GitHubOAuthAppConfiguration: CustomReflectable {
  public var customMirror: Mirror { Mirror(self, children: [] as [Mirror.Child]) }
}

public protocol GitHubOAuthAppConfigurationStore: Sendable {
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration?
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable)
}
