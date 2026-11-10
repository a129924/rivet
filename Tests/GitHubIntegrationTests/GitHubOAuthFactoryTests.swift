import Foundation
import Testing

@testable import GitHubIntegration

@Suite("OAuth public construction")
struct GitHubOAuthFactoryTests {
  @Test func configurationRejectsEmptyAndRedactsSecret() throws {
    #expect(throws: GitHubOAuthAppConfigurationError.invalidConfiguration) {
      try GitHubOAuthAppConfiguration(clientID: "", clientSecret: "fixture-secret")
    }
    let config = try GitHubOAuthAppConfiguration(
      clientID: "fixture-id", clientSecret: "fixture-secret")
    #expect(!String(reflecting: config).contains("fixture-secret"))
    #expect(Mirror(reflecting: config).children.isEmpty)
    _ = try GitHubOAuth.makeTokenFetcher(configuration: config)
  }

  @Test(arguments: [" ", "\t\n"])
  func factoriesRejectBlankClientID(_ blank: String) throws {
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: blank, clientSecret: "fixture-secret")
    #expect(throws: GitHubOAuthAuthorizationError.clientConfiguration) {
      try GitHubOAuth.makeTokenFetcher(configuration: configuration)
    }
    #expect(throws: GitHubOAuthAuthorizationError.clientConfiguration) {
      try GitHubOAuth.makeAuthorizationSession(
        configuration: configuration,
        redirectURI: URL(string: "http://127.0.0.1:49152/oauth/callback")!)
    }
  }

  @Test(arguments: [" ", "\t\n"])
  func factoriesRejectBlankSecret(_ blank: String) throws {
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fixture-id", clientSecret: blank)
    #expect(throws: GitHubOAuthAuthorizationError.clientConfiguration) {
      try GitHubOAuth.makeTokenFetcher(configuration: configuration)
    }
    #expect(throws: GitHubOAuthAuthorizationError.clientConfiguration) {
      try GitHubOAuth.makeAuthorizationSession(
        configuration: configuration,
        redirectURI: URL(string: "http://127.0.0.1:49152/oauth/callback")!)
    }
  }
}
