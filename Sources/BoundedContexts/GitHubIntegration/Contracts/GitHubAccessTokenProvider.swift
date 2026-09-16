public protocol GitHubAccessTokenProvider: Sendable {
  func token() async throws(GitHubCredentialError) -> GitHubAccessToken
}
