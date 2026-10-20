import Foundation
import Testing

@testable import GitHubIntegration

@Suite("GitHub OAuth public factories")
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
  @Test func productionSessionPolicyAndRandomnessNeedNoCredentialIO() async throws {
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
  func productionRejectsInvalidRedirect(_ raw: String) throws {
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fake-id", clientSecret: "fake-secret")
    #expect(throws: GitHubOAuthError.clientConfiguration) {
      try GitHubOAuth.makeAuthorizationSession(
        configuration: configuration, redirectURI: URL(string: raw)!)
    }
  }

}

// Shared only with the additive provider test; keeps the pre-existing 790-line test file bounded.
func exerciseProviderDispositionContract() async throws {
  let cases: [(OAuthTokenRefreshError, OAuthTokenProviderDisposition)] = [
    (.knownTechnicalFailure, .notStopped), (.clientConfiguration, .notStopped),
    (.credentialRejected, .authenticationRequired), (.rotationIndeterminate, .stopped),
    (.cancelled(stage: .beforeRequest), .notStopped),
    (.cancelled(stage: .afterRequestStarted), .stopped),
  ]
  for (failure, expected) in cases {
    let store = DispositionStore()
    let fetcher = DispositionFetcher(failure: failure)
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { dispositionDate })
    #expect(await provider.disposition() == .notStopped)
    #expect(await provider.disposition() == .notStopped)
    #expect(await store.counts() == [0, 0])
    #expect(await fetcher.count() == 0)
    do { _ = try await provider.snapshot() } catch {}
    #expect(await provider.disposition() == expected)
    #expect(await provider.disposition() == expected)
    #expect(await store.counts() == [1, 0])
    #expect(await fetcher.count() == 1)
  }
  let store = DispositionStore(failSave: true)
  let fetcher = DispositionFetcher(failure: nil)
  let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { dispositionDate })
  do { _ = try await provider.snapshot() } catch {}
  #expect(await provider.disposition() == .stopped)
  #expect(await provider.disposition() == .stopped)
  #expect(await store.counts() == [1, 1])
  #expect(await fetcher.count() == 1)
}

private let dispositionDate = Date(timeIntervalSince1970: 1_800_000_000)
private func dispositionBundle(expired: Bool) -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: .init(rawValue: "fake-access"), refreshToken: .init(rawValue: "fake-refresh"),
    accessTokenExpiresAt: dispositionDate.addingTimeInterval(expired ? 0 : 60),
    refreshTokenExpiresAt: dispositionDate.addingTimeInterval(600), tokenType: .bearer,
    grantedScopes: "")
}

private actor DispositionStore: OAuthCredentialStore {
  private var loads = 0
  private var saves = 0
  let failSave: Bool
  init(failSave: Bool = false) { self.failSave = failSave }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    return dispositionBundle(expired: true)
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    if failSave { throw GitHubOAuthStoreError.unavailable }
  }
  func counts() -> [Int] { [loads, saves] }
}

private actor DispositionFetcher: OAuthTokenFetcher {
  let failure: OAuthTokenRefreshError?
  private var calls = 0
  init(failure: OAuthTokenRefreshError?) { self.failure = failure }
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    if let failure { throw failure }
    return dispositionBundle(expired: false)
  }
  func count() -> Int { calls }
}
