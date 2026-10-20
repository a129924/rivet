import Foundation
import GitHubIntegration
import Testing

@testable import GitHubSignInVerification

@MainActor
struct GitHubConnectionCoordinatorTests {
  @Test func startupMakesNoLiveCallsAndRepeatedQueryReusesPreparation() async {
    let calls = AppCalls()
    let model = configuredModel(calls)
    #expect(await calls.authorizations == 0)
    #expect(await calls.preparations.isEmpty)
    model.signIn()
    await model.waitUntilSettled()
    #expect(model.identity?.id == 42)
    model.query()
    await model.waitUntilSettled()
    #expect(await calls.authorizations == 1)
    #expect(await calls.preparations.count == 1)
    #expect(await calls.probes == 2)
  }

  @Test func prepareRetryRetainsExactProvider() async {
    let calls = AppCalls(failFirstPrepare: true)
    let model = configuredModel(calls)
    model.signIn()
    await model.waitUntilSettled()
    #expect(model.identity == nil)
    #expect(model.presentation.canRetry)
    model.retry()
    await model.waitUntilSettled()
    let identities = await calls.preparations
    #expect(identities.count == 2)
    #expect(identities.first == identities.last)
    #expect(model.identity?.id == 42)
  }

  @Test func cancelledRefreshSettlesBeforeNewAuthorizationAndProvider() async throws {
    let gate = AppGate()
    let calls = AppCalls()
    var dependencies = appDependencies(calls)
    dependencies.authorize = { _ in
      await calls.authorize()
      guard await calls.authorizations == 1 else { return appFixtureCredential() }
      return GitHubOAuthCredentialBundle(
        accessToken: .init(rawValue: "expired-fixture"),
        refreshToken: .init(rawValue: "fixture-refresh"),
        accessTokenExpiresAt: .distantPast, refreshTokenExpiresAt: .distantFuture,
        tokenType: .bearer, grantedScopes: "fixture-scope")
    }
    dependencies.makeFetcher = { _ in GatedAppFixtureFetcher(gate: gate) }
    let model = GitHubConnectionCoordinator(dependencies: dependencies)
    model.clientID = "fixture-id"
    model.clientSecret = "fixture-secret"
    model.signIn()
    await gate.waitUntilStarted()
    let original = try #require(await calls.providers.first)
    model.cancel()
    model.signIn()
    #expect(model.isBusy)
    #expect(await calls.authorizations == 1)
    #expect(await calls.probes == 0)
    #expect(model.identity == nil)
    await gate.release()
    await model.waitUntilSettled()
    #expect(!model.isBusy)
    #expect(model.identity == nil)
    #expect(await calls.probes == 0)
    // Real provider publishes only after the actual in-memory rotation save returns.
    let rotated = try await original.snapshot()
    #expect(rotated.accessToken.rawValue == "rotated-fixture")
    model.signIn()
    await model.waitUntilSettled()
    let providers = await calls.providers
    #expect(await calls.authorizations == 2)
    #expect(providers.count == 2)
    #expect(providers.first !== providers.last)
    #expect(await calls.probes == 1)
    #expect(model.identity?.id == 42)
  }

  @Test func cancellationWaitsForRealSettlementAndDropsLateResult() async {
    let gate = AppGate()
    let calls = AppCalls()
    var dependencies = appDependencies(calls)
    dependencies.authorize = { _ in
      await gate.wait()
      return appFixtureCredential()
    }
    let model = GitHubConnectionCoordinator(dependencies: dependencies)
    model.clientID = "fixture-id"
    model.clientSecret = "fixture-secret"
    model.signIn()
    await gate.waitUntilStarted()
    model.cancel()
    model.signIn()
    #expect(model.isBusy)
    #expect(!model.presentation.canStart)
    await gate.release()
    await model.waitUntilSettled()
    #expect(!model.isBusy)
    #expect(model.identity == nil)
    #expect(await calls.preparations.isEmpty)
  }
}

@MainActor func configuredModel(_ calls: AppCalls) -> GitHubConnectionCoordinator {
  let model = GitHubConnectionCoordinator(dependencies: appDependencies(calls))
  model.clientID = "fixture-id"
  model.clientSecret = "fixture-secret"
  return model
}

func appDependencies(_ calls: AppCalls) -> GitHubConnectionDependencies {
  GitHubConnectionDependencies(
    authorize: { _ in
      await calls.authorize()
      return appFixtureCredential()
    },
    makeFetcher: { _ in AppFixtureFetcher() },
    prepare: { provider in
      try await calls.prepare(provider)
      return try await GitHubClientScope.prepare(provider: provider)
    },
    probe: { _ in
      await calls.probe()
      return .init(login: "fixture-user", id: 42)
    })
}

struct AppFixtureFetcher: OAuthTokenFetcher {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    appFixtureCredential()
  }
}

actor AppCalls {
  var authorizations = 0
  var preparations: [ObjectIdentifier] = []
  var providers: [OAuthTokenProvider] = []
  var probes = 0
  let failFirstPrepare: Bool
  init(failFirstPrepare: Bool = false) { self.failFirstPrepare = failFirstPrepare }
  func authorize() { authorizations += 1 }
  func prepare(_ provider: OAuthTokenProvider) throws {
    preparations.append(ObjectIdentifier(provider))
    providers.append(provider)
    if failFirstPrepare && preparations.count == 1 {
      throw GitHubClientPreparationError.invalidAuthorizationToken
    }
  }
  func probe() { probes += 1 }
}

actor AppGate {
  private var continuation: CheckedContinuation<Void, Never>?
  private var observers: [CheckedContinuation<Void, Never>] = []
  private var started = false
  func wait() async {
    started = true
    for observer in observers { observer.resume() }
    observers.removeAll()
    await withCheckedContinuation { continuation = $0 }
  }
  func waitUntilStarted() async {
    if !started { await withCheckedContinuation { observers.append($0) } }
  }
  func release() {
    continuation?.resume()
    continuation = nil
  }
}

private struct GatedAppFixtureFetcher: OAuthTokenFetcher {
  let gate: AppGate
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    await gate.wait()
    return appFixtureCredential(access: "rotated-fixture")
  }
}
