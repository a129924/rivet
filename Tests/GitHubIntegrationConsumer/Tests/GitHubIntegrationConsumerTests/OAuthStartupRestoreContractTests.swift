import Foundation
import GitHubIntegration
import Testing

@Suite("Public OAuth startup restore contract")
struct OAuthStartupRestoreContractTests {
  @Test(arguments: [false, true])
  func publicConsumerRestoresAndKeepsProvider(expired: Bool) async throws {
    let configuration = try ConsumerStartupConfiguration()
    let store = ConsumerStartupCredentials(expired: expired)
    let fetcher = ConsumerStartupFetcher()
    let owner = GitHubOAuthStartupRestorer(
      configurationStore: configuration,
      makeCredentialStore: { clientID in
        #expect(clientID == "offline-client")
        return store
      },
      makeTokenFetcher: { configuration in
        #expect(configuration.clientID == "offline-client")
        return fetcher
      })
    #expect(await configuration.loads == 0)
    for _ in 0..<2 {
      guard case .ready(let scope) = await owner.restore() else {
        Issue.record("Public consumer must receive a ready scope")
        return
      }
      let _: any GitHubRestClient = scope.rest
      let _: any GitHubGraphQLServing = scope.graphql
      requireSendable(scope)
    }
    #expect(await configuration.loads == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == (expired ? 1 : 0))
    #expect(await fetcher.calls == (expired ? 1 : 0))
  }

  @Test
  func productionConvenienceOnlyConstructs() throws {
    let stores = try GitHubOAuthDataProtectionStores(accessGroup: "offline.construction.only")
    let owner = GitHubOAuthStartupRestorer(stores: stores)
    requireSendable(owner)
    // Do not call restore: this only verifies the public initializer, never live Security.
  }

  @Test
  func publicOutcomeAndFailureAreSendable() {
    requireSendable(GitHubOAuthStartupRestoreOutcome.notConfigured)
    requireSendable(GitHubOAuthStartupRestoreOutcome.notSignedIn)
    requireSendable(GitHubOAuthStartupRestoreOutcome.authenticationRequired)
    requireSendable(GitHubOAuthStartupRestoreOutcome.cancelled)
    requireSendable(GitHubOAuthStartupRestoreOutcome.busy)
    requireSendable(GitHubOAuthStartupRestoreFailure.configurationStore(.identityMismatch))
    requireSendable(GitHubOAuthStartupRestoreFailure.configurationLoad)
    requireSendable(GitHubOAuthStartupRestoreFailure.fetcherCreation)
    requireSendable(GitHubOAuthStartupRestoreFailure.preparation(.invalidAuthorizationToken))
    requireSendable(GitHubOAuthStartupRestoreFailure.preparationFailed)
  }

  private func requireSendable<Value: Sendable>(_ value: Value) {}
}

private actor ConsumerStartupConfiguration: GitHubOAuthAppConfigurationStore {
  let value: GitHubOAuthAppConfiguration
  private(set) var loads = 0
  init() throws {
    value = try .init(clientID: "offline-client", clientSecret: "offline-secret")
  }
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? {
    loads += 1
    return value
  }
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {}
}

private actor ConsumerStartupCredentials: OAuthCredentialStore {
  private var value: GitHubOAuthCredentialBundle
  private(set) var loads = 0
  private(set) var saves = 0
  init(expired: Bool) { value = consumerStartupCredential(expired: expired) }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    return value
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    value = credential
  }
}

private actor ConsumerStartupFetcher: OAuthTokenFetcher {
  private(set) var calls = 0
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    return consumerStartupCredential(expired: false)
  }
}

private func consumerStartupCredential(expired: Bool) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: "offline-token"), refreshToken: .init(rawValue: "offline-refresh"),
    accessTokenExpiresAt: expired ? .distantPast : .distantFuture,
    refreshTokenExpiresAt: .distantFuture, tokenType: .bearer, grantedScopes: "")
}
