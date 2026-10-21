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
    dependencies.authorize = { _, _ in
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
    dependencies.authorize = { _, _ in
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

  @Test func manualAttemptWaitsForSameAuthorizationBeforeReadingAccount() async {
    let gate = AppGate()
    let calls = AppCalls()
    let browser = BrowserPresentationCalls()
    var dependencies = appDependencies(calls)
    dependencies.authorize = { _, presenter in
      await calls.authorize()
      try await presenter.present(URL(string: "https://example.invalid/fixture")!)
      await gate.wait()
      return appFixtureCredential()
    }
    dependencies.openBrowser = { _ in
      browser.opens += 1
      return true
    }
    dependencies.copyAuthorizationURL = { _ in
      browser.copies += 1
      return true
    }
    let model = GitHubConnectionCoordinator(dependencies: dependencies)
    model.clientID = "fixture-id"
    model.clientSecret = "fixture-secret"
    model.startManualSignIn()
    await gate.waitUntilStarted()
    #expect(model.isBusy)
    #expect(model.presentation.canCopyAuthorizationURL)
    #expect(model.identity == nil)
    #expect(await calls.probes == 0)
    model.copyAuthorizationURL()
    model.startManualSignIn()
    model.signIn()
    #expect(browser.opens == 0)
    #expect(browser.copies == 1)
    #expect(await calls.authorizations == 1)
    await gate.release()
    await model.waitUntilSettled()
    #expect(model.identity?.id == 42)
    #expect(await calls.probes == 1)
    #expect(!model.presentation.canCopyAuthorizationURL)
    #expect(!model.presentation.canStart)
    model.startManualSignIn()
    model.signIn()
    #expect(await calls.authorizations == 1)
  }

  @Test func automaticModeStillUsesBrowserPresenter() async {
    let calls = AppCalls()
    let browser = BrowserPresentationCalls()
    var dependencies = appDependencies(calls)
    dependencies.authorize = { _, presenter in
      try await presenter.present(URL(string: "https://example.invalid/fixture")!)
      return appFixtureCredential()
    }
    dependencies.openBrowser = { _ in
      browser.opens += 1
      return true
    }
    let model = GitHubConnectionCoordinator(dependencies: dependencies)
    model.clientID = "fixture-id"
    model.clientSecret = "fixture-secret"
    model.signIn()
    await model.waitUntilSettled()
    #expect(browser.opens == 1)
    #expect(!model.presentation.canCopyAuthorizationURL)
    #expect(model.identity?.id == 42)
  }

  @Test func manualCancellationDiscardsLateCredentialAndCopyCapability() async {
    let gate = AppGate()
    let calls = AppCalls()
    var dependencies = appDependencies(calls)
    dependencies.authorize = { _, presenter in
      try await presenter.present(URL(string: "https://example.invalid/fixture")!)
      await gate.wait()
      return appFixtureCredential()
    }
    let model = GitHubConnectionCoordinator(dependencies: dependencies)
    model.clientID = "fixture-id"
    model.clientSecret = "fixture-secret"
    model.startManualSignIn()
    await gate.waitUntilStarted()
    model.cancel()
    #expect(!model.presentation.canCopyAuthorizationURL)
    await gate.release()
    await model.waitUntilSettled()
    #expect(model.identity == nil)
    #expect(await calls.probes == 0)
    #expect(!model.presentation.canStart)
  }

  @Test(arguments: [false, true])
  func manualDenialOrTimeoutStopsWithoutProbeOrRetry(timeout: Bool) async {
    let calls = AppCalls()
    var dependencies = appDependencies(calls)
    dependencies.authorize = { _, presenter in
      await calls.authorize()
      try await presenter.present(URL(string: "https://example.invalid/fixture")!)
      if timeout { throw GitHubConnectionFailure.timeout }
      throw GitHubOAuthAuthorizationError.denied
    }
    let model = GitHubConnectionCoordinator(dependencies: dependencies)
    model.clientID = "fixture-id"
    model.clientSecret = "fixture-secret"
    model.startManualSignIn()
    await model.waitUntilSettled()
    #expect(model.identity == nil)
    #expect(!model.presentation.canCopyAuthorizationURL)
    #expect(!model.presentation.canRetry)
    model.startManualSignIn()
    model.signIn()
    #expect(await calls.authorizations == 1)
    #expect(await calls.probes == 0)
  }

  @Test func preparedConfigurationDoesNotRequireCredentialFields() async throws {
    let calls = AppCalls()
    let configuration = try GitHubVerificationComposition.configuration(environment: [
      "RIVET_VERIFY_GITHUB_CLIENT_ID": "fixture-id",
      "RIVET_VERIFY_GITHUB_CLIENT_SECRET": "fixture-secret",
    ])
    let model = GitHubConnectionCoordinator(
      dependencies: appDependencies(calls), configuration: configuration,
      allowsManualConfiguration: false)
    #expect(model.clientID.isEmpty && model.clientSecret.isEmpty)
    #expect(model.presentation.hasPreparedConfiguration)
    #expect(!model.presentation.showsConfigurationFields)
    #expect(model.presentation.canStart)
    model.startManualSignIn()
    await model.waitUntilSettled()
    #expect(model.identity?.id == 42)
    #expect(await calls.authorizations == 1)
  }

  @Test func absentOrPartialConfigurationNeverStartsLiveAuthorization() async {
    let environments: [[String: String]] = [
      [:], ["RIVET_VERIFY_GITHUB_CLIENT_ID": "fixture-id"],
      ["RIVET_VERIFY_GITHUB_CLIENT_SECRET": "fixture-secret"],
      [
        "RIVET_VERIFY_GITHUB_CLIENT_ID": "  ",
        "RIVET_VERIFY_GITHUB_CLIENT_SECRET": "fixture-secret",
      ],
      ["RIVET_VERIFY_GITHUB_CLIENT_ID": "fixture-id", "RIVET_VERIFY_GITHUB_CLIENT_SECRET": "  "],
    ]
    for environment in environments {
      let model = GitHubVerificationComposition.makeCoordinator(environment: environment)
      #expect(!model.presentation.canStart)
      #expect(!model.presentation.showsConfigurationFields)
      model.clientID = "fixture-id"
      model.clientSecret = "fixture-secret"
      model.startManualSignIn()
      await model.waitUntilSettled()
      #expect(!model.isBusy && model.identity == nil)
      #expect(!model.presentation.canCopyAuthorizationURL)
    }
  }

  @Test func unitTestModeIgnoresEvenCompleteEnvironmentConfiguration() async {
    let model = GitHubVerificationComposition.makeCoordinator(environment: [
      "GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE": "1",
      "RIVET_VERIFY_GITHUB_CLIENT_ID": "fixture-id",
      "RIVET_VERIFY_GITHUB_CLIENT_SECRET": "fixture-secret",
    ])
    #expect(!model.presentation.hasPreparedConfiguration)
    #expect(!model.presentation.showsConfigurationFields)
    model.signIn()
    await model.waitUntilSettled()
    #expect(!model.isBusy && model.identity == nil)
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
    authorize: { _, _ in
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
