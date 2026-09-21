public protocol OAuthTokenFetcher: Sendable {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle
}
