import Foundation
import Testing

@testable import GitHubIntegration

@Suite("OAuth public construction")
struct GitHubOAuthFactoryTests {
  @Test func configurationRejectsEmptyAndRedactsSecret() throws {
    #expect(throws: GitHubOAuthAuthorizationError.clientConfiguration) {
      try GitHubOAuthAppConfiguration(clientID: "", clientSecret: "fixture-secret")
    }
    let config = try GitHubOAuthAppConfiguration(
      clientID: "fixture-id", clientSecret: "fixture-secret")
    #expect(!String(reflecting: config).contains("fixture-secret"))
    #expect(Mirror(reflecting: config).children.isEmpty)
    _ = try GitHubOAuth.makeTokenFetcher(configuration: config)
  }
}
