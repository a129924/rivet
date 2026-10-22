import Foundation
import GitHubIntegration
import Testing

@testable import GitHubConnectionVerification

@Suite("GitHub OAuth factories")
struct GitHubOAuthFactoryTests {
  @Test func configurationIsValidatedAndRedacted() throws {
    #expect(throws: GitHubOAuthError.clientConfiguration) {
      try GitHubOAuthAppConfiguration(clientID: "", clientSecret: "fake-secret")
    }
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fake-id", clientSecret: "fake-secret")
    #expect(!String(describing: configuration).contains("fake-"))
    #expect(!String(reflecting: configuration).contains("fake-"))
    #expect(Mirror(reflecting: configuration).children.isEmpty)
    _ = try GitHubOAuth.makeTokenFetcher(configuration: configuration)
    let stores = GitHubOAuthDataProtectionStores(accessGroup: "fake-group", service: "fake-service")
    _ = stores.configurationStore
    _ = stores.credentialStore(clientID: "fake-id")
  }
  @Test func verificationSessionPolicyAndRandomnessNeedNoCredentialIO() async throws {
    let settings = GitHubOAuth.authorizationSessionConfiguration()
    #expect(settings.urlCache == nil)
    #expect(settings.httpCookieStorage == nil)
    #expect(!settings.httpShouldSetCookies)
    #expect(settings.requestCachePolicy == .reloadIgnoringLocalCacheData)
    #expect(settings.timeoutIntervalForRequest == 30)
    #expect(settings.timeoutIntervalForResource == 30)
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fake-id", clientSecret: "fake-secret")
    let redirect = URL(string: "http://127.0.0.1:43210/oauth/callback")!
    let first = try GitHubOAuth.makeAuthorizationSession(
      configuration: configuration, redirectURI: redirect)
    let second = try GitHubOAuth.makeAuthorizationSession(
      configuration: configuration, redirectURI: redirect)
    let firstItems =
      URLComponents(url: first.authorizationURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let secondItems =
      URLComponents(url: second.authorizationURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let state = try #require(firstItems.first { $0.name == "state" }?.value)
    let challenge = try #require(firstItems.first { $0.name == "code_challenge" }?.value)
    #expect(state.count == 43)
    #expect(challenge.count == 43)
    #expect(state != challenge)
    #expect(state != secondItems.first { $0.name == "state" }?.value)
    #expect(challenge != secondItems.first { $0.name == "code_challenge" }?.value)
    await first.cancel()
    await second.cancel()
  }

  @Test(arguments: [
    "https://127.0.0.1:43210/oauth/callback", "http://localhost:43210/oauth/callback",
    "http://127.0.0.1/oauth/callback", "http://127.0.0.1:43210/wrong",
    "http://user@127.0.0.1:43210/oauth/callback", "http://127.0.0.1:43210/oauth/callback#fragment",
    "http://127.0.0.1:43210/oauth/callback?state=preexisting",
  ])
  func verificationRejectsInvalidRedirect(_ raw: String) throws {
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fake-id", clientSecret: "fake-secret")
    #expect(throws: GitHubOAuthError.clientConfiguration) {
      try GitHubOAuth.makeAuthorizationSession(
        configuration: configuration, redirectURI: URL(string: raw)!)
    }
  }

}
