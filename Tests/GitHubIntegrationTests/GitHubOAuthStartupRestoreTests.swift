import Foundation
import RivetHTTPClient
import Synchronization
import Testing

@testable import GitHubIntegration

@Suite("OAuth startup restore")
struct GitHubOAuthStartupRestoreTests {
  @Test
  func absentConfigurationIsDistinctAndCanBeRetried() async throws {
    let configuration = StartupConfiguration(value: nil)
    let store = StartupCredentials()
    let owner = startupOwner(configuration, store)
    guard case .notConfigured = await owner.restore() else {
      Issue.record("Expected notConfigured")
      return
    }
    await configuration.setValue(try startupConfiguration())
    guard case .ready = await owner.restore() else {
      Issue.record("Expected ready after caller supplied existing configuration")
      return
    }
    #expect(await configuration.loads == 2)
    #expect(await configuration.saves == 0)
  }

  @Test
  func credentialAbsenceIsNotStorageFailure() async throws {
    let store = StartupCredentials(value: nil)
    let owner = startupOwner(try StartupConfiguration(), store)
    guard case .notSignedIn = await owner.restore() else {
      Issue.record("Expected notSignedIn")
      return
    }
    #expect(await store.clears == 0)
  }

  @Test(arguments: [
    GitHubOAuthDataProtectionStoreError.denied, .unavailable, .corrupt,
    .identityMismatch, .invalidConfiguration,
  ])
  func knownConfigurationErrorsRemainTyped(
    failure: GitHubOAuthDataProtectionStoreError
  ) async throws {
    let configuration = try StartupConfiguration(failure: failure)
    let owner = startupOwner(configuration, StartupCredentials())
    guard case .failed(.configurationStore(let actual)) = await owner.restore() else {
      Issue.record("Expected typed store failure")
      return
    }
    #expect(String(describing: actual) == String(describing: failure))
    await configuration.setFailure(nil)
    guard case .ready = await owner.restore() else {
      Issue.record("Pre-provider failure must allow explicit retry")
      return
    }
  }

  @Test
  func unknownConfigurationErrorIsSanitized() async throws {
    let owner = startupOwner(
      try StartupConfiguration(failure: StartupFailure.privatePayload), StartupCredentials())
    guard case .failed(.configurationLoad) = await owner.restore() else {
      Issue.record("Expected finite configurationLoad")
      return
    }
  }

  @Test
  func factoryFailureDoesNotLeaveProvider() async throws {
    let count = Mutex(0)
    let configuration = try StartupConfiguration()
    let store = StartupCredentials()
    let owner = GitHubOAuthStartupRestorer(
      configurationStore: configuration, makeCredentialStore: { _ in store },
      makeTokenFetcher: { _ in
        let attempt = count.withLock { value in
          value += 1
          return value
        }
        if attempt == 1 { throw StartupFailure.privatePayload }
        return StartupFetcher()
      })
    guard case .failed(.fetcherCreation) = await owner.restore() else {
      Issue.record("Expected fetcherCreation")
      return
    }
    guard case .ready = await owner.restore() else {
      Issue.record("Expected explicit retry")
      return
    }
    #expect(await configuration.loads == 2)
    #expect(await store.loads == 1)
  }

  @Test(arguments: [false, true])
  func readinessAndSequentialPrepareKeepOriginalProvider(expired: Bool) async throws {
    let configuration = try StartupConfiguration()
    let store = StartupCredentials(value: startupCredential(expired: expired))
    let fetcher = StartupFetcher()
    let owner = startupOwner(configuration, store, fetcher)
    for _ in 0..<2 {
      guard case .ready = await owner.restore() else {
        Issue.record("Expected local ready")
        return
      }
    }
    #expect(await configuration.loads == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == (expired ? 1 : 0))
    #expect(await fetcher.calls == (expired ? 1 : 0))
    #expect(await store.clears == 0)
  }

  @Test
  func credentialReadFailureKeepsOriginalProvider() async throws {
    let configuration = try StartupConfiguration()
    let store = StartupCredentials(
      loadFailure: GitHubOAuthDataProtectionStoreError.identityMismatch)
    let owner = startupOwner(configuration, store)
    guard case .failed(.preparation(.credentialLifecycle(stage: .restore))) = await owner.restore()
    else {
      Issue.record("Expected restore failure")
      return
    }
    await store.setLoadFailure(nil)
    guard case .ready = await owner.restore() else {
      Issue.record("Expected retry")
      return
    }
    #expect(await configuration.loads == 1)
    #expect(await store.loads == 2)
    #expect(await store.clears == 0)
  }

  @Test
  func invalidBearerNeverBecomesReady() async throws {
    let owner = startupOwner(
      try StartupConfiguration(), StartupCredentials(value: startupCredential(token: "bad token")))
    guard case .failed(.preparation(.invalidAuthorizationToken)) = await owner.restore() else {
      Issue.record("Expected invalidAuthorizationToken")
      return
    }
  }

  @Test
  func temporaryRefreshFailureRetriesOnlyWhenCallerAsks() async throws {
    let store = StartupCredentials(value: startupCredential(expired: true))
    let fetcher = StartupFetcher(failure: .knownTechnicalFailure)
    let owner = startupOwner(try StartupConfiguration(), store, fetcher)
    guard case .failed(.preparation(.credentialLifecycle(stage: .refresh))) = await owner.restore()
    else {
      Issue.record("Expected refresh failure")
      return
    }
    #expect(await fetcher.calls == 1)
    await fetcher.setFailure(nil)
    guard case .ready = await owner.restore() else {
      Issue.record("Expected retry")
      return
    }
    #expect(await fetcher.calls == 2)
    #expect(await store.loads == 1)
    #expect(await store.saves == 1)
  }

  @Test(arguments: [OAuthTokenRefreshError.credentialRejected, .rotationIndeterminate])
  func terminalRefreshCannotBeBypassed(failure: OAuthTokenRefreshError) async throws {
    let store = StartupCredentials(value: startupCredential(expired: true))
    let fetcher = StartupFetcher(failure: failure)
    let owner = startupOwner(try StartupConfiguration(), store, fetcher)
    for _ in 0..<2 {
      let outcome = await owner.restore()
      if case .credentialRejected = failure {
        guard case .authenticationRequired = outcome else {
          Issue.record("Expected authenticationRequired")
          return
        }
      } else {
        guard case .failed(.preparation(.credentialLifecycle(stage: .refresh))) = outcome else {
          Issue.record("Expected terminal refresh failure")
          return
        }
      }
    }
    #expect(await fetcher.calls == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == 0)
    #expect(await store.clears == 0)
  }

  @Test
  func persistenceFailureRemainsTerminal() async throws {
    let store = StartupCredentials(
      value: startupCredential(expired: true), saveFailure: StartupFailure.privatePayload)
    let fetcher = StartupFetcher()
    let owner = startupOwner(try StartupConfiguration(), store, fetcher)
    for _ in 0..<2 {
      guard
        case .failed(.preparation(.credentialLifecycle(stage: .persist))) = await owner.restore()
      else {
        Issue.record("Expected persist-stop")
        return
      }
    }
    #expect(await fetcher.calls == 1)
    #expect(await store.saves == 1)
    #expect(await store.clears == 0)
  }

  @Test(arguments: [StartupPause.configuration, .credential, .refresh, .save])
  func cancellationWaitsForSettlementAndRejectsOverlap(pause: StartupPause) async throws {
    let gate = StartupGate()
    let configuration = try StartupConfiguration(gate: pause == .configuration ? gate : nil)
    let store = StartupCredentials(
      value: startupCredential(expired: true),
      loadGate: pause == .credential ? gate : nil, saveGate: pause == .save ? gate : nil)
    let fetcher = StartupFetcher(gate: pause == .refresh ? gate : nil)
    let owner = startupOwner(configuration, store, fetcher)
    let task = Task { await owner.restore() }
    await gate.waitForArrival()
    guard case .busy = await owner.restore() else {
      Issue.record("Expected busy")
      return
    }
    task.cancel()
    guard case .busy = await owner.restore() else {
      Issue.record("Cancellation must not release ownership before settlement")
      return
    }
    await gate.open()
    guard case .cancelled = await task.value else {
      Issue.record("Expected cancelled")
      return
    }
    #expect(await store.saves == (pause == .configuration ? 0 : 1))
    #expect(await store.clears == 0)
    guard case .ready = await owner.restore() else {
      Issue.record("Expected later restore")
      return
    }
    #expect(await fetcher.calls == 1)
    #expect(await configuration.loads == (pause == .configuration ? 2 : 1))
    #expect(await store.loads == 1)
    #expect(await store.value?.accessToken.rawValue == "rotated")
  }

  @Test
  func alreadyCancelledDoesNoIO() async throws {
    let gate = StartupGate()
    let configuration = try StartupConfiguration()
    let owner = startupOwner(configuration, StartupCredentials())
    let task = Task {
      await gate.enter()
      return await owner.restore()
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    guard case .cancelled = await task.value else {
      Issue.record("Expected cancelled")
      return
    }
    #expect(await configuration.loads == 0)
  }

  @Test(arguments: [false, true])
  func dependencyCancellationIsNotTechnicalFailure(url: Bool) async throws {
    let failure: any Error & Sendable = url ? URLError(.cancelled) : CancellationError()
    let owner = startupOwner(try StartupConfiguration(failure: failure), StartupCredentials())
    guard case .cancelled = await owner.restore() else {
      Issue.record("Expected cancelled")
      return
    }
  }

  @Test
  func scopeRefreshCancellationPreservesProviderTerminalState() async throws {
    let fetcher = StartupFetcher(failure: .cancelled(stage: .afterRequestStarted))
    let owner = startupOwner(
      try StartupConfiguration(), StartupCredentials(value: startupCredential(expired: true)),
      fetcher)
    guard case .cancelled = await owner.restore() else {
      Issue.record("Expected cancelled")
      return
    }
    guard case .failed(.preparation(.credentialLifecycle(stage: .refresh))) = await owner.restore()
    else {
      Issue.record("Expected terminal uncertainty")
      return
    }
    #expect(await fetcher.calls == 1)
  }

  @Test
  func deliveredClientCanMakeProviderTerminalAndReprepareDoesNotCacheReady() async throws {
    let store = StartupCredentials()
    let fetcher = StartupFetcher(failure: .credentialRejected)
    let transport = StartupTransport()
    let owner = GitHubOAuthStartupRestorer(
      configurationStore: try StartupConfiguration(), makeCredentialStore: { _ in store },
      makeTokenFetcher: { _ in fetcher },
      prepareScope: { provider in
        try await GitHubClientScope.prepare(provider: provider) { provider in
          (
            GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport)),
            GitHubGraphQLClient(provider: provider)
          )
        }
      })
    guard case .ready(let scope) = await owner.restore() else {
      Issue.record("Expected ready")
      return
    }
    let endpoint = GitHubAuthenticatedUserEndpoint.shared
    let request = HTTPRequest(url: try endpoint.makeURL(), method: endpoint.method)
    _ = try? await scope.rest.executeGet(request)
    #expect(await transport.calls == 1)
    #expect(await fetcher.calls == 1)
    guard case .authenticationRequired = await owner.restore() else {
      Issue.record("Must not return an old ready scope")
      return
    }
    #expect(await store.loads == 1)
    #expect(await store.clears == 0)
  }

  @Test
  func unexpectedPreparationFailureIsFinite() async throws {
    let owner = GitHubOAuthStartupRestorer(
      configurationStore: try StartupConfiguration(),
      makeCredentialStore: { _ in StartupCredentials() },
      makeTokenFetcher: { _ in StartupFetcher() },
      prepareScope: { _ in
        throw StartupFailure.privatePayload
      })
    guard case .failed(.preparationFailed) = await owner.restore() else {
      Issue.record("Expected preparationFailed")
      return
    }
  }
}

private func startupConfiguration() throws -> GitHubOAuthAppConfiguration {
  try .init(clientID: "offline-client", clientSecret: "offline-secret")
}

private func startupCredential(
  token: String = "initial", expired: Bool = false
) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: token), refreshToken: .init(rawValue: "offline-refresh"),
    accessTokenExpiresAt: expired ? .distantPast : .distantFuture,
    refreshTokenExpiresAt: .distantFuture, tokenType: .bearer, grantedScopes: "")
}

private func startupOwner(
  _ configuration: StartupConfiguration, _ store: StartupCredentials,
  _ fetcher: StartupFetcher = StartupFetcher()
) -> GitHubOAuthStartupRestorer {
  GitHubOAuthStartupRestorer(
    configurationStore: configuration, makeCredentialStore: { _ in store },
    makeTokenFetcher: { _ in fetcher })
}

private enum StartupFailure: Error { case privatePayload }
enum StartupPause: Sendable { case configuration, credential, refresh, save }

private actor StartupGate {
  private var arrived = false
  private var opened = false
  private var arrivals: [CheckedContinuation<Void, Never>] = []
  private var waiters: [CheckedContinuation<Void, Never>] = []
  func enter() async {
    arrived = true
    for waiter in arrivals { waiter.resume() }
    arrivals.removeAll()
    if !opened { await withCheckedContinuation { waiters.append($0) } }
  }
  func waitForArrival() async {
    if !arrived { await withCheckedContinuation { arrivals.append($0) } }
  }
  func open() {
    opened = true
    for waiter in waiters { waiter.resume() }
    waiters.removeAll()
  }
}

private actor StartupConfiguration: GitHubOAuthAppConfigurationStore {
  private var value: GitHubOAuthAppConfiguration?
  private var failure: (any Error & Sendable)?
  let gate: StartupGate?
  private(set) var loads = 0
  private(set) var saves = 0
  init(value: GitHubOAuthAppConfiguration?, gate: StartupGate? = nil) {
    self.value = value
    self.gate = gate
  }
  init(failure: (any Error & Sendable)? = nil, gate: StartupGate? = nil) throws {
    value = try startupConfiguration()
    self.failure = failure
    self.gate = gate
  }
  func setValue(_ value: GitHubOAuthAppConfiguration?) { self.value = value }
  func setFailure(_ failure: (any Error & Sendable)?) { self.failure = failure }
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? {
    loads += 1
    if let gate { await gate.enter() }
    if let failure { throw failure }
    return value
  }
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {
    saves += 1
  }
}

private actor StartupCredentials: OAuthCredentialClearingStore {
  private(set) var value: GitHubOAuthCredentialBundle?
  private var loadFailure: (any Error & Sendable)?
  let saveFailure: (any Error & Sendable)?
  let loadGate: StartupGate?
  let saveGate: StartupGate?
  private(set) var loads = 0
  private(set) var saves = 0
  private(set) var clears = 0
  init(
    value: GitHubOAuthCredentialBundle? = startupCredential(),
    loadFailure: (any Error & Sendable)? = nil, saveFailure: (any Error & Sendable)? = nil,
    loadGate: StartupGate? = nil, saveGate: StartupGate? = nil
  ) {
    self.value = value
    self.loadFailure = loadFailure
    self.saveFailure = saveFailure
    self.loadGate = loadGate
    self.saveGate = saveGate
  }
  func setLoadFailure(_ failure: (any Error & Sendable)?) { loadFailure = failure }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    if let loadGate { await loadGate.enter() }
    if let loadFailure { throw loadFailure }
    return value
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    if let saveGate { await saveGate.enter() }
    if let saveFailure { throw saveFailure }
    value = credential
  }
  func clear() async throws(any Error & Sendable) { clears += 1 }
}

private actor StartupFetcher: OAuthTokenFetcher {
  private var failure: OAuthTokenRefreshError?
  let gate: StartupGate?
  private(set) var calls = 0
  init(failure: OAuthTokenRefreshError? = nil, gate: StartupGate? = nil) {
    self.failure = failure
    self.gate = gate
  }
  func setFailure(_ failure: OAuthTokenRefreshError?) { self.failure = failure }
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    if let gate { await gate.enter() }
    if let failure { throw failure }
    return startupCredential(token: "rotated")
  }
}

private actor StartupTransport: Transport {
  private(set) var calls = 0
  func execute(
    _ request: URLRequest
  ) async throws(HTTPClientError) -> RivetHTTPClient.HTTPResponse {
    calls += 1
    return .init(statusCode: 401, headers: [:], body: Data())
  }
}
