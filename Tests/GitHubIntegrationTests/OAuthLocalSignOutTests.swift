import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("OAuth local sign out")
struct OAuthLocalSignOutTests {
  @Test
  func retainedScopeCannotStartNewRESTOrGraphQLWork() async throws {
    let store = SignOutStore()
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    let transport = SignOutTransport()
    let executor = GraphQLStubExecutor()
    let scope = try await GitHubClientScope.prepare(provider: provider) { provider in
      (
        GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport)),
        GitHubGraphQLClient(provider: provider, executor: executor)
      )
    }
    try await provider.signOut()
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await scope.rest.get(
        url: HTTPURL(URL(string: "https://api.github.com/user")!), headers: [:], body: nil)
    }
    await #expect(throws: GitHubGraphQLClientError.authenticationRequired) {
      try await scope.graphql.fetch(query: ProbeQuery(value: "retained"))
    }
    #expect(await transport.calls == 0)
    #expect(await executor.tokens.isEmpty)
  }

  @Test
  func lateUnauthorizedResponsesCannotRecoverRetiredScope() async throws {
    let store = SignOutStore()
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    let restGate = SignOutGate()
    let graphGate = GraphQLGate()
    let transport = SignOutTransport(gate: restGate, status: 401)
    let executor = GraphQLStubExecutor(statuses: [401], gate: graphGate)
    let scope = try await GitHubClientScope.prepare(provider: provider) { provider in
      (
        GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport)),
        GitHubGraphQLClient(provider: provider, executor: executor)
      )
    }
    let rest = Task {
      try await scope.rest.get(
        url: HTTPURL(URL(string: "https://api.github.com/user")!), headers: [:], body: nil)
    }
    let graph = Task { try await scope.graphql.fetch(query: ProbeQuery(value: "late401")) }
    await restGate.arrived()
    await graphGate.waitForArrival()
    let saves = await store.saves
    try await provider.signOut()
    await restGate.open()
    await graphGate.open()
    do {
      _ = try await rest.value
      Issue.record("REST recovered")
    } catch { #expect(error as? GitHubHTTPClientError == .authenticationRequired) }
    do {
      _ = try await graph.value
      Issue.record("GraphQL recovered")
    } catch { #expect(error as? GitHubGraphQLClientError == .authenticationRequired) }
    #expect(await transport.calls == 1)
    #expect(await executor.tokens.count == 1)
    #expect(await store.saves == saves)
  }

  @Test
  func lateRefreshFailureCannotReplaceRetirement() async throws {
    let gate = SignOutGate()
    let store = SignOutStore()
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher(gate: gate, fail: true))
    let demand = Task { try await provider.snapshot() }
    await gate.arrived()
    try await provider.signOut()
    await gate.open()
    await expectSignedOut(demand)
    await expectSignedOut(Task { try await provider.snapshot() })
  }

  @Test
  func failedPendingSaveStillClears() async throws {
    let gate = SignOutGate()
    let store = SignOutStore(saveGate: gate, failSave: true)
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    let demand = Task { try await provider.snapshot() }
    await gate.arrived()
    let logout = Task { try await provider.signOut() }
    await confirmRetirement(provider, gate: gate)
    #expect(await store.clears == 0)
    await gate.open()
    try await logout.value
    _ = await demand.result
    #expect(await store.events == ["save", "clear-start", "clear"])
    #expect(await store.value == nil)
    await expectSignedOut(Task { try await provider.snapshot() })
  }

  @Test
  func retiredProviderCannotPrepareScope() async throws {
    let store = SignOutStore()
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    try await provider.signOut()
    do {
      _ = try await GitHubClientScope.prepare(provider: provider)
      Issue.record("prepared retired scope")
    } catch { #expect(error as? GitHubClientPreparationError == .authenticationRequired) }
  }

  @Test func lateRefreshCannotSave() async throws {
    let gate = SignOutGate()
    let store = SignOutStore()
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher(gate: gate))
    let demand = Task { try await provider.snapshot() }
    await gate.arrived()
    try await provider.signOut()
    await gate.open()
    await expectSignedOut(demand)
    #expect(await store.saves == 0)
    #expect(await store.clears == 1)
    #expect(await store.value == nil)
  }

  @Test func startedSaveSettlesBeforeDelete() async throws {
    let gate = SignOutGate()
    let clearGate = SignOutGate()
    let store = SignOutStore(saveGate: gate, clearGate: clearGate)
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    let demand = Task { try await provider.snapshot() }
    await gate.arrived()
    let logout = Task { try await provider.signOut() }
    await confirmRetirement(provider, gate: gate)
    #expect(await store.clears == 0)
    // The clear gate proves the write completed before deletion started.
    await gate.open()
    await clearGate.arrived()
    #expect(await store.events == ["save", "clear-start"])
    logout.cancel()
    await clearGate.open()
    try await logout.value
    _ = await demand.result
    await expectSignedOut(Task { try await provider.snapshot() })
    #expect(await store.events == ["save", "clear-start", "clear"])
    #expect(await store.value == nil)
  }

  @Test func lateRestoreCannotPublish() async throws {
    let gate = SignOutGate()
    let store = SignOutStore(loadGate: gate)
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    let demand = Task { try await provider.snapshot() }
    await gate.arrived()
    try await provider.signOut()
    await gate.open()
    await expectSignedOut(demand)
    #expect(await store.saves == 0)
  }

  @Test func failedClearCanRetryWithoutReviving() async throws {
    let store = SignOutStore(failClear: true)
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    do {
      try await provider.signOut()
      Issue.record("expected clear failure")
    } catch {
      guard case .clear = error else {
        Issue.record("wrong error")
        return
      }
    }
    await expectSignedOut(Task { try await provider.snapshot() })
    await store.allowClear()
    try await provider.signOut()
    try await provider.signOut()
    #expect(await store.clears == 2)
  }

  @Test func concurrentClearIsShared() async throws {
    let gate = SignOutGate()
    let store = SignOutStore(clearGate: gate)
    let provider = OAuthTokenProvider(store: store, fetcher: SignOutFetcher())
    let first = Task { try await provider.signOut() }
    await gate.arrived()
    let second = Task { try await provider.signOut() }
    await gate.open()
    try await first.value
    try await second.value
    #expect(await store.clears == 1)
    await expectSignedOut(
      Task {
        try await provider.replacementSnapshot(
          afterUnauthorized: TokenSnapshot(
            accessToken: GitHubAccessToken(rawValue: "fake"), version: 1))
      })
  }

  @Test func unsupportedStoreStillRetires() async {
    let provider = OAuthTokenProvider(store: LegacySignOutStore(), fetcher: SignOutFetcher())
    do {
      try await provider.signOut()
      Issue.record("expected unsupported")
    } catch {
      guard case .unsupportedStore = error else {
        Issue.record("wrong error")
        return
      }
    }
    await expectSignedOut(Task { try await provider.snapshot() })
  }
}

private func expectSignedOut(_ task: Task<TokenSnapshot, any Error>) async {
  do {
    _ = try await task.value
    Issue.record("retired provider supplied token")
  } catch {
    #expect(
      (error as? OAuthTokenProviderError).map { if case .signedOut = $0 { true } else { false } }
        == true)
  }
}

private func signOutCredential(expired: Bool = true) -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: GitHubAccessToken(rawValue: "fake-access"),
    refreshToken: GitHubOAuthRefreshToken(rawValue: "fake-refresh"),
    accessTokenExpiresAt: expired ? .distantPast : .distantFuture,
    refreshTokenExpiresAt: .distantFuture, tokenType: .bearer, grantedScopes: "")
}
private enum SignOutFailure: Error { case denied }
private actor SignOutStore: OAuthCredentialClearingStore {
  var value: GitHubOAuthCredentialBundle? = signOutCredential()
  var saves = 0
  var clears = 0
  var events: [String] = []
  let loadGate: SignOutGate?
  let saveGate: SignOutGate?
  let clearGate: SignOutGate?
  var failSave: Bool
  var failClear: Bool
  init(
    loadGate: SignOutGate? = nil, saveGate: SignOutGate? = nil, clearGate: SignOutGate? = nil,
    failClear: Bool = false, failSave: Bool = false
  ) {
    self.loadGate = loadGate
    self.saveGate = saveGate
    self.clearGate = clearGate
    self.failSave = failSave
    self.failClear = failClear
  }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    let loaded = value
    await loadGate?.wait()
    return loaded
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    await saveGate?.wait()
    saves += 1
    events.append("save")
    if failSave { throw SignOutFailure.denied }
    value = credential
  }
  func clear() async throws(any Error & Sendable) {
    clears += 1
    events.append("clear-start")
    await clearGate?.wait()
    if failClear { throw SignOutFailure.denied }
    value = nil
    events.append("clear")
  }
  func allowClear() { failClear = false }
}
private struct LegacySignOutStore: OAuthCredentialStore {
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? { nil }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {}
}
private struct SignOutFetcher: OAuthTokenFetcher {
  typealias Credential = GitHubOAuthCredentialBundle
  var gate: SignOutGate?
  var fail = false
  func refresh(_ credential: Credential) async throws(OAuthTokenRefreshError) -> Credential {
    await gate?.wait()
    if fail { throw .rotationIndeterminate }
    return signOutCredential(expired: false)
  }
}
private actor SignOutGate {
  var waiting: CheckedContinuation<Void, Never>?
  var arrival: CheckedContinuation<Void, Never>?
  var reached = false
  var opened = false
  func wait() async {
    reached = true
    arrival?.resume()
    arrival = nil
    if !opened { await withCheckedContinuation { waiting = $0 } }
  }
  func arrived() async {
    if !reached { await withCheckedContinuation { arrival = $0 } }
  }
  func open() {
    opened = true
    waiting?.resume()
    waiting = nil
  }
}

private func confirmRetirement(_ provider: OAuthTokenProvider, gate: SignOutGate) async {
  let retired = await withTaskGroup(of: Bool.self) { group in
    group.addTask {
      do {
        _ = try await provider.snapshot()
        return false
      } catch {
        if let error = error as? OAuthTokenProviderError, case .signedOut = error { return true }
        return false
      }
    }
    group.addTask {
      do { try await Task.sleep(for: .seconds(1)) } catch { return false }
      return false
    }
    let result = await group.next() ?? false
    if !result { await gate.open() }
    group.cancelAll()
    return result
  }
  #expect(retired, "retirement must be observed while save gate remains closed")
}

private actor SignOutTransport: Transport {
  let gate: SignOutGate?
  let status: Int
  var calls = 0
  init(gate: SignOutGate? = nil, status: Int = 200) {
    self.gate = gate
    self.status = status
  }
  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    calls += 1
    await gate?.wait()
    return HTTPResponse(statusCode: status, headers: [:], body: Data())
  }
}
