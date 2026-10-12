import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("GitHub authenticated GET")
struct GitHubHTTPClientTests {
  @Test
  func unauthorizedReplaysOriginalGETOnceWithReplacementBearer() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [401, 200])
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport))
    let request = try probeRequest(
      headers: [.accept: "application/json", .authorization: "old", .custom("X-Probe"): "kept"],
      body: Data("original".utf8))
    let response = try await client.executeGET(request)
    #expect(response.statusCode == 200)
    let sent = await transport.requests
    #expect(sent.count == 2)
    #expect(
      sent.map { $0.value(forHTTPHeaderField: "Authorization") }
        == ["Bearer initial", "Bearer replacement"])
    #expect(sent.map { $0.value(forHTTPHeaderField: "X-Probe") } == ["kept", "kept"])
    #expect(sent.map(\.url) == [request.url.value, request.url.value])
    #expect(sent.map(\.httpMethod) == ["GET", "GET"])
    #expect(sent.map(\.httpBody) == [request.body, request.body])
    #expect(await fetcher.calls == 1)
  }

  @Test
  func invalidInitialTokenFailsBeforeSendOrRecovery() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(credential: graphQLCredential("invalid token")),
      fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [200])
    let error = await #expect(throws: GitHubHTTPClientError.executionFailed) {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(probeRequest())
    }
    #expect(await transport.requests.isEmpty)
    #expect(await fetcher.calls == 0)
    if let error {
      #expect(String(describing: error) == "executionFailed")
      #expect(Mirror(reflecting: error).children.isEmpty)
    }
  }

  @Test
  func invalidReplacementStopsBeforeRetryOrExtraRecovery() async throws {
    let fetcher = GraphQLTokenFetcher(replacementToken: "invalid replacement")
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [401, 200])
    await #expect(throws: GitHubHTTPClientError.executionFailed) {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(probeRequest())
    }
    #expect(await transport.requests.count == 1)
    #expect(await fetcher.calls == 1)
  }

  @Test
  func secondUnauthorizedTerminatesWithoutThirdSend() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [401, 401, 200])
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport))
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await client.executeGET(probeRequest())
    }
    #expect(await transport.requests.count == 2)
    #expect(await fetcher.calls == 1)
  }

  @Test(arguments: [200, 201, 302, 403, 404, 429, 500])
  func nonUnauthorizedStatusRemainsRawAndDoesNotRecover(_ status: Int) async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [status])
    let response = try await GitHubHTTPClient(
      provider: provider, httpClient: HTTPClient(transport: transport)
    ).executeGET(probeRequest())
    #expect(response.statusCode == status)
    #expect(await transport.requests.count == 1)
    #expect(await fetcher.calls == 0)
  }

  @Test(arguments: [
    "http://api.github.com/user", "https://github.com/user",
    "https://api.github.com.evil.example/user", "https://evil@api.github.com/user",
    "https://api.github.com:444/user", "https://api.github.com/user#fragment",
  ])
  func invalidDestinationFailsBeforeCredentialAcquisition(_ address: String) async throws {
    let store = GraphQLCredentialStore()
    let transport = RESTProbeTransport(statuses: [200])
    let provider = OAuthTokenProvider(store: store, fetcher: GraphQLTokenFetcher())
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport))
    let request = HTTPRequest(url: try HTTPURL(URL(string: address)!), method: .get)
    await #expect(throws: GitHubHTTPClientError.invalidRequest) {
      try await client.executeGET(request)
    }
    #expect(await store.loads == 0)
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func nonGETMethodFailsBeforeCredentialAcquisition() async throws {
    let store = GraphQLCredentialStore()
    let transport = RESTProbeTransport(statuses: [200])
    let provider = OAuthTokenProvider(store: store, fetcher: GraphQLTokenFetcher())
    let request = HTTPRequest(
      url: try HTTPURL(URL(string: "https://api.github.com/user")!), method: .post)
    await #expect(throws: GitHubHTTPClientError.invalidRequest) {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(request)
    }
    #expect(await store.loads == 0)
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func missingCredentialAndRejectedRefreshRequireAuthentication() async throws {
    let missing = OAuthTokenProvider(
      store: GraphQLCredentialStore(credential: nil), fetcher: GraphQLTokenFetcher())
    let missingTransport = RESTProbeTransport(statuses: [200])
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await GitHubHTTPClient(
        provider: missing, httpClient: HTTPClient(transport: missingTransport)
      ).executeGET(probeRequest())
    }
    #expect(await missingTransport.requests.isEmpty)

    let fetcher = GraphQLTokenFetcher(error: OAuthTokenRefreshError.credentialRejected)
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [401])
    await #expect(throws: GitHubHTTPClientError.authenticationRequired) {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(probeRequest())
    }
    #expect(await transport.requests.count == 1)
  }

  @Test
  func providerTechnicalFailuresPreserveLifecycleStage() async throws {
    for stage in [GitHubHTTPClientError.CredentialLifecycleStage.restore, .refresh, .persist] {
      let store = GraphQLCredentialStore(
        loadError: stage == .restore ? URLError(.notConnectedToInternet) : nil,
        saveError: stage == .persist ? URLError(.notConnectedToInternet) : nil)
      let fetcher = GraphQLTokenFetcher(
        error: stage == .refresh ? OAuthTokenRefreshError.knownTechnicalFailure : nil)
      let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
      let transport = RESTProbeTransport(statuses: [401])
      await #expect(throws: GitHubHTTPClientError.credentialLifecycle(stage: stage)) {
        try await GitHubHTTPClient(
          provider: provider, httpClient: HTTPClient(transport: transport)
        ).executeGET(probeRequest())
      }
      #expect(await transport.requests.count == (stage == .restore ? 0 : 1))
    }
  }

  @Test
  func transportFailureDoesNotStartRecovery() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(
      statuses: [], error: .networkFailure(URLError(.notConnectedToInternet)))
    await #expect(throws: GitHubHTTPClientError.executionFailed) {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(probeRequest())
    }
    #expect(await transport.requests.count == 1)
    #expect(await fetcher.calls == 0)
  }

  @Test
  func cancellationBefore401RecoveryPreventsRefresh() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [401], cancelOnFirst: true)
    let task = Task {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(probeRequest())
    }
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await transport.requests.count == 1)
    #expect(await fetcher.calls == 0)
  }

  @Test
  func cancellationDuringSharedRefreshPreventsReplay() async throws {
    let gate = GraphQLGate()
    let fetcher = GraphQLTokenFetcher(gate: gate)
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [401, 200])
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport))
    let task = Task { try await client.executeGET(probeRequest()) }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await transport.requests.count == 1)
    #expect(await fetcher.calls == 1)
    #expect(await fetcher.wasCancelled == false)
    #expect(try await provider.snapshot().accessToken.rawValue == "replacement")
  }

  @Test
  func alreadyCancelledCallerDoesNotAcquireCredentialOrSend() async throws {
    let gate = GraphQLGate()
    let store = GraphQLCredentialStore()
    let provider = OAuthTokenProvider(
      store: store, fetcher: GraphQLTokenFetcher(), now: { graphQLTestDate })
    let transport = RESTProbeTransport(statuses: [200])
    let client = GitHubHTTPClient(provider: provider, httpClient: HTTPClient(transport: transport))
    let task = Task {
      await gate.enter()
      return try await client.executeGET(probeRequest())
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await store.loads == 0)
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func wrappedCancellationAndTransportCancellationStayCancellation() async throws {
    let wrappedProvider = OAuthTokenProvider(
      store: GraphQLCredentialStore(loadError: URLError(.cancelled)),
      fetcher: GraphQLTokenFetcher())
    await #expect(throws: CancellationError.self) {
      try await GitHubHTTPClient(
        provider: wrappedProvider,
        httpClient: HTTPClient(transport: RESTProbeTransport(statuses: [200]))
      ).executeGET(probeRequest())
    }
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: GraphQLTokenFetcher(),
      now: { graphQLTestDate })
    let transport = RESTProbeTransport(
      statuses: [], error: .cancelled(underlying: URLError(.cancelled)))
    await #expect(throws: CancellationError.self) {
      try await GitHubHTTPClient(
        provider: provider, httpClient: HTTPClient(transport: transport)
      ).executeGET(probeRequest())
    }
  }
}

private func probeRequest(
  headers: HTTPHeaders = [:], body: Data? = nil
) throws -> HTTPRequest {
  HTTPRequest(
    url: try HTTPURL(URL(string: "https://api.github.com/user?probe=1")!),
    method: .get, headers: headers, body: body)
}

private actor RESTProbeTransport: Transport {
  private var statuses: [Int]
  private let error: HTTPClientError?
  private let cancelOnFirst: Bool
  private(set) var requests: [URLRequest] = []

  init(statuses: [Int], error: HTTPClientError? = nil, cancelOnFirst: Bool = false) {
    self.statuses = statuses
    self.error = error
    self.cancelOnFirst = cancelOnFirst
  }

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    if cancelOnFirst && requests.count == 1 {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    if let error { throw error }
    let status = statuses.isEmpty ? 200 : statuses.removeFirst()
    return HTTPResponse(statusCode: status, headers: [:], body: Data())
  }
}
