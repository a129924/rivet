public protocol GitHubTokenProvider {
  func token() throws(GitHubCredentialError) -> GitHubAccessToken
}
