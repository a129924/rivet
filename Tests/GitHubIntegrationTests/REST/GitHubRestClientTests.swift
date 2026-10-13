import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

private let restMethods: [HTTPMethod] = [.get, .post, .put, .patch]

@Suite("GitHub REST method contract")
struct GitHubRestClientTests {
  @Test(arguments: restMethods, [false, true])
  func methodsPreserveRequestAndRawResponse(method: HTTPMethod, builder: Bool) async throws {
    let transport = MethodTransport(statuses: [201])
    let client: any GitHubRestClient = liveClient(transport)
    let request = try methodRequest(method)
    let response = try await invoke(client, request, builder: builder)
    #expect(response.statusCode == 201)
    #expect(response.headers == [.custom("X-Response"): "raw"])
    #expect(response.body == Data("response".utf8))
    let sent = try #require(await transport.requests.first)
    assertPreserved(sent, original: request, token: "initial")
    #expect(request.headers[.authorization] == "old")
  }

  @Test(arguments: restMethods, [false, true])
  func firstUnauthorizedReplaysOnlyAuthorization(method: HTTPMethod, builder: Bool) async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = makeProvider(fetcher: fetcher)
    // A nonzero used version catches an implementation that recovers with an invented snapshot.
    let used = try await provider.snapshot()
    #expect(used.version > 0)
    let transport = MethodTransport(statuses: [401, 200])
    let client: any GitHubRestClient = GitHubHTTPClient(
      provider: provider, httpClient: HTTPClient(transport: transport))
    let request = try methodRequest(method)
    #expect(try await invoke(client, request, builder: builder).statusCode == 200)
    let sent = await transport.requests
    #expect(sent.count == 2)
    assertPreserved(sent[0], original: request, token: "initial")
    assertPreserved(sent[1], original: request, token: "replacement")
    #expect(await fetcher.calls == 1)
  }

  @Test(arguments: restMethods, [false, true])
  func secondUnauthorizedStops(method: HTTPMethod, builder: Bool) async throws {
    let fetcher = GraphQLTokenFetcher()
    let transport = MethodTransport(statuses: [401, 401, 200])
    let client: any GitHubRestClient = liveClient(transport, fetcher: fetcher)
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await invoke(client, methodRequest(method), builder: builder)
    }
    #expect(await transport.requests.count == 2)
    #expect(await fetcher.calls == 1)
  }

  @Test(arguments: restMethods)
  func wrongMethodStopsBeforeCredentials(method: HTTPMethod) async throws {
    let store = GraphQLCredentialStore()
    let fetcher = GraphQLTokenFetcher()
    let transport = MethodTransport(statuses: [200])
    let client: any GitHubRestClient = liveClient(transport, store: store, fetcher: fetcher)
    let wrong: HTTPMethod = method == .get ? .post : .get
    let request = try methodRequest(wrong)
    await #expect(throws: GitHubHTTPClientError.invalidRequest) {
      try await execute(client, request, as: method)
    }
    #expect(await store.loads == 0)
    #expect(await fetcher.calls == 0)
    #expect(await transport.requests.isEmpty)
  }

  @Test(arguments: restMethods, [false, true])
  func invalidURLStopsBeforeCredentials(method: HTTPMethod, builder: Bool) async throws {
    let store = GraphQLCredentialStore()
    let fetcher = GraphQLTokenFetcher()
    let transport = MethodTransport(statuses: [200])
    let client: any GitHubRestClient = liveClient(transport, store: store, fetcher: fetcher)
    let request = HTTPRequest(
      url: try HTTPURL(URL(string: "https://github.com/user")!), method: method)
    await #expect(throws: GitHubHTTPClientError.invalidRequest) {
      try await invoke(client, request, builder: builder)
    }
    #expect(await store.loads == 0)
    #expect(await fetcher.calls == 0)
    #expect(await transport.requests.isEmpty)
  }

  @Test(arguments: restMethods, [false, true])
  func substituteReceivesAllEightEntrypoints(method: HTTPMethod, builder: Bool) async throws {
    let spy = MethodSpy()
    let client: any GitHubRestClient = spy
    let request = try methodRequest(method)
    #expect(try await invoke(client, request, builder: builder).statusCode == 202)
    let calls = await spy.calls
    #expect(calls.count == 1)
    #expect(calls[0].builder == builder)
    #expect(calls[0].request.method == method)
    #expect(calls[0].request.url == request.url)
    #expect(calls[0].request.headers == request.headers)
    #expect(calls[0].request.body == request.body)
  }
}

extension GitHubRestClientTests {
  @Test(arguments: restMethods)
  func defaultBuildersDispatchExecutionWitness(method: HTTPMethod) async throws {
    let spy = DefaultMethodSpy()
    let request = try methodRequest(method)
    #expect(try await invoke(spy, request, builder: true).statusCode == 203)
    let recorded = try #require(await spy.requests.first)
    #expect(recorded.method == request.method)
    #expect(recorded.url == request.url)
    #expect(recorded.headers == request.headers)
    #expect(recorded.body == request.body)
  }

  @Test(arguments: [200, 302, 403, 429, 503])
  func writeStatusRemainsRaw(status: Int) async throws {
    let fetcher = GraphQLTokenFetcher()
    let transport = MethodTransport(statuses: [status])
    let response = try await invoke(
      liveClient(transport, fetcher: fetcher), methodRequest(.post), builder: true)
    #expect(response.statusCode == status)
    #expect(response.headers == [.custom("X-Response"): "raw"])
    #expect(response.body == Data("response".utf8))
    #expect(await fetcher.calls == 0)
    #expect(await transport.requests.count == 1)
  }

  @Test
  func writeTransportErrorsDoNotRecover() async throws {
    let errors: [HTTPClientError] = [
      .networkFailure(URLError(.timedOut)), .networkFailure(URLError(.notConnectedToInternet)),
      .nonHTTPResponse(response: URLResponse(), body: Data()),
    ]
    for error in errors {
      let fetcher = GraphQLTokenFetcher()
      let transport = MethodTransport(statuses: [], error: error)
      await #expect(throws: GitHubHTTPClientError.executionFailed) {
        try await invoke(
          liveClient(transport, fetcher: fetcher), methodRequest(.put), builder: false)
      }
      #expect(await transport.requests.count == 1)
      #expect(await fetcher.calls == 0)
    }
  }

  @Test
  func writeCredentialFailuresPreserveClassification() async throws {
    for stage in [GitHubHTTPClientError.CredentialLifecycleStage.restore, .refresh, .persist] {
      let store = GraphQLCredentialStore(
        loadError: stage == .restore ? URLError(.notConnectedToInternet) : nil,
        saveError: stage == .persist ? URLError(.notConnectedToInternet) : nil)
      let fetcher = GraphQLTokenFetcher(
        error: stage == .refresh ? OAuthTokenRefreshError.knownTechnicalFailure : nil)
      let transport = MethodTransport(statuses: [401])
      await #expect(throws: GitHubHTTPClientError.credentialLifecycle(stage: stage)) {
        try await invoke(
          liveClient(transport, store: store, fetcher: fetcher), methodRequest(.post), builder: true
        )
      }
      #expect(await transport.requests.count == (stage == .restore ? 0 : 1))
    }
    let missing = MethodTransport(statuses: [200])
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await invoke(
        liveClient(missing, store: GraphQLCredentialStore(credential: nil)), methodRequest(.patch),
        builder: false)
    }
    #expect(await missing.requests.isEmpty)
    let rejected = MethodTransport(statuses: [401])
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await invoke(
        liveClient(
          rejected, fetcher: GraphQLTokenFetcher(error: OAuthTokenRefreshError.credentialRejected)),
        methodRequest(.put), builder: true)
    }
    #expect(await rejected.requests.count == 1)
  }

  @Test(arguments: [false, true])
  func invalidWriteTokenNeverSendsInvalidBearer(replacement: Bool) async throws {
    let fetcher = GraphQLTokenFetcher(
      replacementToken: replacement ? "invalid token" : "replacement")
    let store = GraphQLCredentialStore(
      credential: graphQLCredential(replacement ? "initial" : "invalid token"))
    let transport = MethodTransport(statuses: [401, 200])
    await #expect(throws: GitHubHTTPClientError.executionFailed) {
      try await invoke(
        liveClient(transport, store: store, fetcher: fetcher), methodRequest(.patch), builder: true)
    }
    #expect(await transport.requests.count == (replacement ? 1 : 0))
    #expect(await fetcher.calls == (replacement ? 1 : 0))
  }

  @Test
  func writeCancellationBeforeRecoveryAndDuringSharedRefresh() async throws {
    let fetcher = GraphQLTokenFetcher()
    let before = MethodTransport(statuses: [401], cancelOnFirst: true)
    let task = Task {
      try await invoke(liveClient(before, fetcher: fetcher), methodRequest(.post), builder: true)
    }
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await before.requests.count == 1)
    #expect(await fetcher.calls == 0)

    let gate = GraphQLGate()
    let sharedFetcher = GraphQLTokenFetcher(gate: gate)
    let provider = makeProvider(fetcher: sharedFetcher)
    let during = MethodTransport(statuses: [401, 200])
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: during))
    let cancelled = Task { try await invoke(client, methodRequest(.patch), builder: false) }
    await gate.waitForArrival()
    cancelled.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await cancelled.value }
    #expect(await during.requests.count == 1)
    #expect(await sharedFetcher.calls == 1)
    #expect(await sharedFetcher.wasCancelled == false)
    #expect(try await provider.snapshot().accessToken.rawValue == "replacement")
  }

  @Test
  func writeCancellationBeforeCredentialsAndWrappedErrors() async throws {
    let gate = GraphQLGate()
    let store = GraphQLCredentialStore()
    let transport = MethodTransport(statuses: [200])
    let client = liveClient(transport, store: store)
    let task = Task {
      await gate.enter()
      return try await invoke(client, methodRequest(.put), builder: true)
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await store.loads == 0)
    #expect(await transport.requests.isEmpty)

    let wrapped = MethodTransport(statuses: [200])
    await #expect(throws: CancellationError.self) {
      try await invoke(
        liveClient(wrapped, store: GraphQLCredentialStore(loadError: URLError(.cancelled))),
        methodRequest(.post), builder: false)
    }
    #expect(await wrapped.requests.isEmpty)
    let cancelled = MethodTransport(
      statuses: [], error: .cancelled(underlying: URLError(.cancelled)))
    await #expect(throws: CancellationError.self) {
      try await invoke(liveClient(cancelled), methodRequest(.patch), builder: true)
    }
    #expect(await cancelled.requests.count == 1)
  }
}

extension GitHubRestClientTests {
  @Test
  func concurrentWritesShareOneRecovery() async throws {
    let refreshGate = GraphQLGate()
    let joined = GraphQLGate()
    let fetcher = GraphQLTokenFetcher(gate: refreshGate)
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate },
      onInFlightTaskJoin: { await joined.enter() })
    _ = try await provider.snapshot()
    let post = MethodTransport(statuses: [401, 200])
    let initialGate = GraphQLGate()
    let patch = MethodTransport(statuses: [401, 200], firstGate: initialGate)
    let first = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: post))
    let second = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: patch))
    // Hold PATCH's initial response so both executions use the same initial snapshot.
    let patchTask = Task { try await invoke(second, methodRequest(.patch), builder: false) }
    await initialGate.waitForArrival()
    let postTask = Task { try await invoke(first, methodRequest(.post), builder: true) }
    await refreshGate.waitForArrival()
    await initialGate.open()
    await joined.waitForArrival()
    await joined.open()
    await refreshGate.open()
    #expect(try await postTask.value.statusCode == 200)
    #expect(try await patchTask.value.statusCode == 200)
    #expect(await fetcher.calls == 1)
    for (transport, method) in [(post, HTTPMethod.post), (patch, .patch)] {
      let sent = await transport.requests
      #expect(sent.count == 2)
      assertPreserved(sent[0], original: try methodRequest(method), token: "initial")
      assertPreserved(sent[1], original: try methodRequest(method), token: "replacement")
    }
  }

  @Test
  func lateStaleUnauthorizedUsesCurrentReplacement() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = makeProvider(fetcher: fetcher)
    let lateGate = GraphQLGate()
    let patch = MethodTransport(statuses: [401, 200], firstGate: lateGate)
    let lateClient = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: patch))
    let lateTask = Task { try await invoke(lateClient, methodRequest(.patch), builder: false) }
    await lateGate.waitForArrival()
    let post = MethodTransport(statuses: [401, 200])
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: post))
    #expect(try await invoke(client, methodRequest(.post), builder: true).statusCode == 200)
    await lateGate.open()
    #expect(try await lateTask.value.statusCode == 200)
    #expect(await fetcher.calls == 1)
    let sent = await patch.requests
    #expect(sent.count == 2)
    assertPreserved(sent[0], original: try methodRequest(.patch), token: "initial")
    assertPreserved(sent[1], original: try methodRequest(.patch), token: "replacement")
  }
}

private func methodRequest(_ method: HTTPMethod) throws -> HTTPRequest {
  HTTPRequest(
    url: try HTTPURL(URL(string: "https://API.GITHUB.COM:443/user?probe=1")!), method: method,
    headers: [.accept: "application/json", .authorization: "old", .custom("X-Probe"): "kept"],
    body: Data("original-\(method.rawValue)".utf8))
}

private func makeProvider(
  store: GraphQLCredentialStore = GraphQLCredentialStore(),
  fetcher: GraphQLTokenFetcher = GraphQLTokenFetcher()
) -> OAuthTokenProvider {
  OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
}

private func liveClient(
  _ transport: MethodTransport,
  store: GraphQLCredentialStore = GraphQLCredentialStore(),
  fetcher: GraphQLTokenFetcher = GraphQLTokenFetcher()
) -> GitHubHTTPClient {
  GitHubHTTPClient(
    provider: makeProvider(store: store, fetcher: fetcher),
    httpClient: HTTPClient(transport: transport))
}

private func invoke(
  _ client: any GitHubRestClient, _ request: HTTPRequest, builder: Bool
) async throws -> HTTPResponse {
  guard builder else { return try await execute(client, request, as: request.method) }
  switch request.method {
  case .get:
    return try await client.get(url: request.url, headers: request.headers, body: request.body)
  case .post:
    return try await client.post(url: request.url, headers: request.headers, body: request.body)
  case .put:
    return try await client.put(url: request.url, headers: request.headers, body: request.body)
  case .patch:
    return try await client.patch(url: request.url, headers: request.headers, body: request.body)
  default: throw GitHubHTTPClientError.invalidRequest
  }
}

private func execute(
  _ client: any GitHubRestClient, _ request: HTTPRequest, as method: HTTPMethod
) async throws -> HTTPResponse {
  switch method {
  case .get: return try await client.executeGet(request)
  case .post: return try await client.executePost(request)
  case .put: return try await client.executePut(request)
  case .patch: return try await client.executePatch(request)
  default: throw GitHubHTTPClientError.invalidRequest
  }
}

private func assertPreserved(_ sent: URLRequest, original: HTTPRequest, token: String) {
  #expect(sent.httpMethod == original.method.rawValue)
  #expect(sent.url == original.url.value)
  #expect(sent.httpBody == original.body)
  #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
  #expect(sent.value(forHTTPHeaderField: "Accept") == "application/json")
  #expect(sent.value(forHTTPHeaderField: "X-Probe") == "kept")
  #expect(sent.allHTTPHeaderFields?.count == 3)
}

private actor MethodTransport: Transport {
  var statuses: [Int]
  let error: HTTPClientError?
  let cancelOnFirst: Bool
  let firstGate: GraphQLGate?
  private(set) var requests: [URLRequest] = []

  init(
    statuses: [Int], error: HTTPClientError? = nil, cancelOnFirst: Bool = false,
    firstGate: GraphQLGate? = nil
  ) {
    self.statuses = statuses
    self.error = error
    self.cancelOnFirst = cancelOnFirst
    self.firstGate = firstGate
  }

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    let status = statuses.isEmpty ? 200 : statuses.removeFirst()
    if requests.count == 1 {
      if cancelOnFirst { withUnsafeCurrentTask { $0?.cancel() } }
      if let firstGate { await firstGate.enter() }
    }
    if let error { throw error }
    return HTTPResponse(
      statusCode: status, headers: [.custom("X-Response"): "raw"], body: Data("response".utf8))
  }
}

private actor MethodSpy: GitHubRestClient {
  struct Call: Sendable {
    let builder: Bool
    let request: HTTPRequest
  }
  private(set) var calls: [Call] = []

  func get(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    record(HTTPRequest(url: url, method: .get, headers: headers, body: body), builder: true)
  }
  func post(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    record(HTTPRequest(url: url, method: .post, headers: headers, body: body), builder: true)
  }
  func put(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    record(HTTPRequest(url: url, method: .put, headers: headers, body: body), builder: true)
  }
  func patch(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    record(HTTPRequest(url: url, method: .patch, headers: headers, body: body), builder: true)
  }
  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    record(request, builder: false)
  }
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    record(request, builder: false)
  }
  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    record(request, builder: false)
  }
  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    record(request, builder: false)
  }

  private func record(_ request: HTTPRequest, builder: Bool) -> HTTPResponse {
    calls.append(Call(builder: builder, request: request))
    return HTTPResponse(statusCode: 202, headers: [:], body: Data())
  }
}

private actor DefaultMethodSpy: GitHubRestClient {
  private(set) var requests: [HTTPRequest] = []
  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse { record(request) }
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse { record(request) }
  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse { record(request) }
  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse { record(request) }

  private func record(_ request: HTTPRequest) -> HTTPResponse {
    requests.append(request)
    return HTTPResponse(statusCode: 203, headers: [:], body: Data())
  }
}
