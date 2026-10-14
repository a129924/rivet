import Apollo
import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("GitHub client scope")
struct GitHubClientScopeTests {
  @Test
  func missingCredentialDoesNotReturnScope() async {
    let provider = OAuthTokenProvider(store: ScopeStore(credential: nil), fetcher: ScopeFetcher())
    await #expect(throws: GitHubClientPreparationError.missingCredential) {
      try await GitHubClientScope.prepare(provider: provider)
    }
  }

  @Test(arguments: [false, true])
  func preparationCompletesLifecycleWithoutResourceProbe(expired: Bool) async throws {
    let store = ScopeStore(credential: scopeCredential(expired: expired))
    let fetcher = ScopeFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher)
    let rest = ScopeTransport()
    let graphql = ScopeSession()
    _ = try await prepared(provider, rest, graphql)
    #expect(await store.loads == 1)
    #expect(await store.saves == (expired ? 1 : 0))
    #expect(await fetcher.calls == (expired ? 1 : 0))
    #expect(await rest.requests.isEmpty)
    #expect(await graphql.requests.isEmpty)
  }

  @Test(arguments: [
    GitHubClientPreparationError.CredentialLifecycleStage.restore, .refresh, .persist,
  ])
  func lifecycleFailuresAreSanitized(
    stage: GitHubClientPreparationError.CredentialLifecycleStage
  ) async {
    let store = ScopeStore(
      credential: scopeCredential(expired: true),
      loadError: stage == .restore ? ScopeFailure.secret : nil,
      saveError: stage == .persist ? ScopeFailure.secret : nil)
    let fetcher = ScopeFetcher(error: stage == .refresh ? .knownTechnicalFailure : nil)
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher)
    let error = await #expect(
      throws: GitHubClientPreparationError.credentialLifecycle(stage: stage)
    ) {
      try await GitHubClientScope.prepare(provider: provider)
    }
    let description = String(reflecting: error)
    #expect(!description.contains("secret"))
    #expect(!description.contains("underlying"))
    #expect(!description.contains("initial"))
  }

  @Test
  func invalidBearerFailsBeforeClientConstruction() async {
    let provider = OAuthTokenProvider(
      store: ScopeStore(credential: scopeCredential(token: "invalid token")),
      fetcher: ScopeFetcher())
    await #expect(throws: GitHubClientPreparationError.invalidAuthorizationToken) {
      try await GitHubClientScope.prepare(provider: provider) { _ in
        Issue.record("Clients must not be constructed before readiness")
        return (GitHubHTTPClient(provider: provider), GitHubGraphQLClient(provider: provider))
      }
    }
  }

  @Test(arguments: [
    OAuthTokenRefreshError.credentialRejected, .rotationIndeterminate,
    .cancelled(stage: .afterRequestStarted),
  ])
  func terminalProviderCannotBeBypassedByRepreparing(failure: OAuthTokenRefreshError) async {
    let store = ScopeStore(credential: scopeCredential(expired: true))
    let fetcher = ScopeFetcher(error: failure)
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher)
    if case .cancelled = failure {
      await #expect(throws: CancellationError.self) {
        try await GitHubClientScope.prepare(provider: provider)
      }
    } else {
      await expectTerminalPreparation(provider, failure)
    }
    await expectTerminalPreparation(provider, failure)
    #expect(await fetcher.calls == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == 0)
  }

  @Test
  func persistenceFailureRemainsTerminalOnOriginalProvider() async {
    let store = ScopeStore(
      credential: scopeCredential(expired: true), saveError: ScopeFailure.secret)
    let fetcher = ScopeFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher)
    for _ in 0..<2 {
      await #expect(throws: GitHubClientPreparationError.credentialLifecycle(stage: .persist)) {
        try await GitHubClientScope.prepare(provider: provider)
      }
    }
    #expect(await fetcher.calls == 1)
    #expect(await store.saves == 1)
  }

  @Test
  func cancellationDuringAcceptedRotationStillPersistsAndDoesNotReturnScope() async throws {
    let saveGate = ScopeGate()
    let store = ScopeStore(credential: scopeCredential(expired: true), saveGate: saveGate)
    let fetcher = ScopeFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher)
    let task = Task { try await GitHubClientScope.prepare(provider: provider) }
    await saveGate.waitForArrival()
    task.cancel()
    await saveGate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await store.saves == 1)
    #expect(await fetcher.wasCancelled == false)
    #expect(try await provider.snapshot().accessToken.rawValue == "replacement")
    _ = try await GitHubClientScope.prepare(provider: provider)
    #expect(await fetcher.calls == 1)
  }

  @Test(arguments: [false, true])
  func wrappedAndTypedCancellationRemainCancellation(typed: Bool) async {
    let provider = OAuthTokenProvider(
      store: ScopeStore(
        credential: scopeCredential(expired: typed), loadError: typed ? nil : URLError(.cancelled)),
      fetcher: ScopeFetcher(error: typed ? .cancelled(stage: .beforeRequest) : nil))
    await #expect(throws: CancellationError.self) {
      try await GitHubClientScope.prepare(provider: provider)
    }
  }

  @Test
  func underlyingCancellationErrorRemainsCancellation() async {
    let provider = OAuthTokenProvider(
      store: ScopeStore(loadError: CancellationError()), fetcher: ScopeFetcher())
    await #expect(throws: CancellationError.self) {
      try await GitHubClientScope.prepare(provider: provider)
    }
  }

  @Test
  func alreadyCancelledCallerDoesNotRestore() async {
    let gate = ScopeGate()
    let store = ScopeStore()
    let provider = OAuthTokenProvider(store: store, fetcher: ScopeFetcher())
    let task = Task {
      await gate.enter()
      return try await GitHubClientScope.prepare(provider: provider)
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await store.loads == 0)
  }

  @Test
  func finalCancellationCheckDoesNotDeliverScope() async {
    let provider = OAuthTokenProvider(store: ScopeStore(), fetcher: ScopeFetcher())
    let task = Task {
      try await GitHubClientScope.prepare(provider: provider) { provider in
        withUnsafeCurrentTask { $0?.cancel() }
        return (GitHubHTTPClient(provider: provider), GitHubGraphQLClient(provider: provider))
      }
    }
    await #expect(throws: CancellationError.self) { try await task.value }
  }

  @Test(arguments: [false, true])
  func realClientsShareRecoveryAndLateUnauthorizedUsesAdvancedVersion(late: Bool) async throws {
    let initialGate = ScopeGate()
    let refreshGate = ScopeGate()
    let joinGate = ScopeGate()
    let store = ScopeStore()
    let fetcher = ScopeFetcher(gate: refreshGate)
    let provider = OAuthTokenProvider(
      store: store, fetcher: fetcher, onInFlightTaskJoin: { await joinGate.enter() })
    let rest = ScopeTransport(statuses: [401, 200])
    let graphql = ScopeSession(statuses: [401, 200], initialGate: initialGate)
    let scope = try await prepared(provider, rest, graphql)
    let query = Task { try await scope.graphql.fetch(query: ProbeQuery(value: "scope")) }
    await initialGate.waitForArrival()
    let request = Task { try await scope.rest.executeGet(scopeRequest()) }
    await refreshGate.waitForArrival()
    if late {
      await refreshGate.open()
      #expect(try await request.value.statusCode == 200)
      await initialGate.open()
    } else {
      await initialGate.open()
      await joinGate.waitForArrival()
      await joinGate.open()
      await refreshGate.open()
      #expect(try await request.value.statusCode == 200)
    }
    #expect(try await query.value.data?.probe == "ok")
    #expect(await fetcher.calls == 1)
    #expect(await store.saves == 1)
    #expect(await store.loads == 1)
    #expect(await rest.tokens == ["Bearer initial", "Bearer replacement"])
    #expect(await graphql.tokens == ["Bearer initial", "Bearer replacement"])
    _ = try await scope.rest.executeGet(scopeRequest())
    _ = try await scope.graphql.perform(mutation: ProbeMutation(value: "new"))
    #expect(await rest.tokens.last == "Bearer replacement")
    #expect(await graphql.tokens.last == "Bearer replacement")
    #expect(await store.loads == 1)
    #expect(await fetcher.calls == 1)
  }

  @Test
  func readinessDoesNotGuaranteeFutureRemoteSuccess() async throws {
    let fetcher = ScopeFetcher()
    let provider = OAuthTokenProvider(store: ScopeStore(), fetcher: fetcher)
    let rest = ScopeTransport(statuses: [403])
    let graphql = ScopeSession(statuses: [403])
    let scope = try await prepared(provider, rest, graphql)
    #expect(try await scope.rest.executeGet(scopeRequest()).statusCode == 403)
    await #expect(throws: GitHubGraphQLClientError.httpStatus(403)) {
      try await scope.graphql.fetch(query: ProbeQuery(value: "scope"))
    }
    #expect(await fetcher.calls == 0)
  }
}

private func expectTerminalPreparation(
  _ provider: OAuthTokenProvider, _ failure: OAuthTokenRefreshError
) async {
  let expected: GitHubClientPreparationError
  if case .credentialRejected = failure {
    expected = .authenticationRequired
  } else {
    expected = .credentialLifecycle(stage: .refresh)
  }
  await #expect(throws: expected) { try await GitHubClientScope.prepare(provider: provider) }
}

private func prepared(
  _ provider: OAuthTokenProvider, _ rest: ScopeTransport, _ graphql: ScopeSession
) async throws -> GitHubClientScope {
  try await GitHubClientScope.prepare(provider: provider) { provider in
    (
      GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: rest)),
      GitHubGraphQLClient(provider: provider, executor: ApolloGraphQLClient(session: graphql))
    )
  }
}

private func scopeRequest() throws -> HTTPRequest {
  HTTPRequest(url: try HTTPURL(URL(string: "https://api.github.com/user")!), method: .get)
}

private func scopeCredential(
  token: String = "initial", expired: Bool = false
) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: token), refreshToken: .init(rawValue: "offline-refresh"),
    accessTokenExpiresAt: expired ? .distantPast : .distantFuture,
    refreshTokenExpiresAt: .distantFuture, tokenType: .bearer, grantedScopes: "")
}

private enum ScopeFailure: Error { case secret }

private actor ScopeGate {
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

private actor ScopeStore: OAuthCredentialStore {
  let credential: GitHubOAuthCredentialBundle?
  let loadError: (any Error & Sendable)?
  let saveError: (any Error & Sendable)?
  let saveGate: ScopeGate?
  private(set) var loads = 0
  private(set) var saves = 0
  init(
    credential: GitHubOAuthCredentialBundle? = scopeCredential(),
    loadError: (any Error & Sendable)? = nil, saveError: (any Error & Sendable)? = nil,
    saveGate: ScopeGate? = nil
  ) {
    self.credential = credential
    self.loadError = loadError
    self.saveError = saveError
    self.saveGate = saveGate
  }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    if let loadError { throw loadError }
    return credential
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    if let saveGate { await saveGate.enter() }
    if let saveError { throw saveError }
  }
}

private actor ScopeFetcher: OAuthTokenFetcher {
  let error: OAuthTokenRefreshError?
  let gate: ScopeGate?
  private(set) var calls = 0
  private(set) var wasCancelled = false
  init(error: OAuthTokenRefreshError? = nil, gate: ScopeGate? = nil) {
    self.error = error
    self.gate = gate
  }
  typealias Credential = GitHubOAuthCredentialBundle
  func refresh(
    _ credential: Credential
  ) async throws(OAuthTokenRefreshError) -> Credential {
    calls += 1
    if let gate { await gate.enter() }
    wasCancelled = Task.isCancelled
    if let error { throw error }
    return scopeCredential(token: "replacement")
  }
}

private actor ScopeTransport: Transport {
  private var statuses: [Int]
  private(set) var requests: [URLRequest] = []
  var tokens: [String?] { requests.map { $0.value(forHTTPHeaderField: "Authorization") } }
  init(statuses: [Int] = [200]) { self.statuses = statuses }
  func execute(
    _ request: URLRequest
  ) async throws(HTTPClientError) -> RivetHTTPClient.HTTPResponse {
    requests.append(request)
    return RivetHTTPClient.HTTPResponse(
      statusCode: statuses.isEmpty ? 200 : statuses.removeFirst(), headers: [:], body: Data())
  }
}

private actor ScopeSession: ApolloURLSession {
  private var statuses: [Int]
  let initialGate: ScopeGate?
  private(set) var requests: [URLRequest] = []
  var tokens: [String?] { requests.map { $0.value(forHTTPHeaderField: "Authorization") } }
  init(statuses: [Int] = [200], initialGate: ScopeGate? = nil) {
    self.statuses = statuses
    self.initialGate = initialGate
  }
  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requests.append(request)
    let status = statuses.isEmpty ? 200 : statuses.removeFirst()
    if request.value(forHTTPHeaderField: "Authorization") == "Bearer initial", let initialGate {
      await initialGate.enter()
    }
    let response = HTTPURLResponse(
      url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"])!
    return (GraphQLChunks(chunks: [Data(#"{"data":{"probe":"ok"}}"#.utf8)]), response)
  }
}
