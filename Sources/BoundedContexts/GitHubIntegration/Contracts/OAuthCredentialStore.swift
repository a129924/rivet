public protocol OAuthCredentialStore: Sendable {
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle?
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable)
}
