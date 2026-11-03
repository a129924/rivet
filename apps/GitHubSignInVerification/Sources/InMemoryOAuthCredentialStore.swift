import GitHubIntegration

actor InMemoryOAuthCredentialStore: OAuthCredentialStore {
  private var credential: GitHubOAuthCredentialBundle?
  func load() -> GitHubOAuthCredentialBundle? { credential }
  func save(_ credential: GitHubOAuthCredentialBundle) { self.credential = credential }
}
