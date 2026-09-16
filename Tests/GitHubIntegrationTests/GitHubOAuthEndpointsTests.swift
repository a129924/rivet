import Foundation
import Testing

@testable import GitHubIntegration

@Suite("GitHub OAuth endpoints")
struct GitHubOAuthEndpointsTests {
  @Test
  func authorizationURLIsTheFixedGitHubOAuthEndpoint() {
    assertGitHubOAuthURL(
      GitHubOAuthEndpoints.authorizationURL,
      equals: "https://github.com/login/oauth/authorize",
      path: "/login/oauth/authorize"
    )
  }

  @Test
  func tokenURLIsTheFixedGitHubOAuthEndpoint() {
    assertGitHubOAuthURL(
      GitHubOAuthEndpoints.tokenURL,
      equals: "https://github.com/login/oauth/access_token",
      path: "/login/oauth/access_token"
    )
  }
}

private func assertGitHubOAuthURL(
  _ url: URL,
  equals expectedValue: String,
  path expectedPath: String
) {
  #expect(url.absoluteString == expectedValue)
  #expect(url.scheme == "https")
  #expect(url.host == "github.com")
  #expect(url.path == expectedPath)
  #expect(url.query == nil)
  #expect(url.fragment == nil)
}
