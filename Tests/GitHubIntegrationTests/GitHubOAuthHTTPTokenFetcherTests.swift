import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("GitHub OAuth HTTP refresh")
struct GitHubOAuthHTTPTokenFetcherTests {
  @Test
  func requestUsesFixedEndpointEscapedFormHeadersAndOneAttempt() async throws {
    let transport = RefreshTestTransport(result: .success(refreshResponse()))
    let fetcher = try refreshFetcher(transport, clientID: "id +&=字", secret: "secret +&=")
    let original = refreshCredential(refreshToken: "old +&=字")
    _ = try await fetcher.refresh(original)
    let requests = await transport.requests
    let request = try #require(requests.first)
    #expect(requests.count == 1)
    #expect(request.url == URL(string: "https://github.com/login/oauth/access_token"))
    #expect(request.httpMethod == "POST")
    #expect(request.timeoutInterval == 30)
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(
      request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    let expectedBody = [
      "client_id=id%20%2B%26%3D%E5%AD%97", "client_secret=secret%20%2B%26%3D",
      "grant_type=refresh_token", "refresh_token=old%20%2B%26%3D%E5%AD%97",
    ].joined(separator: "&")
    #expect(String(data: try #require(request.httpBody), encoding: .utf8) == expectedBody)
  }

  @Test
  func successfulPairUsesReceiptClockAndAllowsEmptyScope() async throws {
    let transport = RefreshTestTransport(result: .success(refreshResponse()))
    let receivedAt = graphQLTestDate.addingTimeInterval(50)
    let fetcher = try refreshFetcher(transport, now: { receivedAt })
    let result = try await fetcher.refresh(refreshCredential())
    #expect(result.accessToken.rawValue == "new-access")
    #expect(result.refreshToken.rawValue == "new-refresh")
    #expect(result.grantedScopes.isEmpty)
    #expect(result.tokenType == .bearer)
    #expect(result.accessTokenExpiresAt == receivedAt.addingTimeInterval(3600))
    #expect(result.refreshTokenExpiresAt == receivedAt.addingTimeInterval(7200))
  }

  @Test(arguments: [
    "access_token", "refresh_token", "token_type", "expires_in", "refresh_token_expires_in",
    "scope",
  ])
  func eachMissingSuccessFieldIsIndeterminate(_ field: String) async throws {
    let body = refreshJSON(removing: field)
    await expectRefreshClassification(body: body, expected: "indeterminate")
  }

  @Test(arguments: [
    ("access_token", ""), ("refresh_token", ""), ("token_type", "not-bearer"),
    ("expires_in", "0"), ("expires_in", "-1"), ("expires_in", "1.5"),
    ("expires_in", "999999999999999999999999999999"),
    ("refresh_token_expires_in", "0"), ("refresh_token_expires_in", "-1"),
  ])
  func invalidSuccessValuesAreIndeterminate(_ field: String, _ value: String) async throws {
    let numeric = field.hasSuffix("in")
    let valid = refreshJSON()
    let originalValue: String
    switch field {
    case "access_token": originalValue = "\"new-access\""
    case "refresh_token": originalValue = "\"new-refresh\""
    case "token_type": originalValue = "\"bearer\""
    case "expires_in": originalValue = "3600"
    default: originalValue = "7200"
    }
    let from = "\"\(field)\":\(originalValue)"
    let replacementValue = numeric ? value : "\"\(value)\""
    let replacement = "\"\(field)\":\(replacementValue)"
    await expectRefreshClassification(
      body: valid.replacingOccurrences(of: from, with: replacement), expected: "indeterminate")
  }

  @Test(arguments: [200, 201, 400, 401, 403, 422])
  func trustworthyErrorBodyClassifiesOnSuccessOrClientStatus(_ status: Int) async {
    await expectRefreshClassification(
      status: status, body: "{\"error\":\"bad_refresh_token\"}", expected: "rejected")
    await expectRefreshClassification(
      status: status, body: "{\"error\":\"incorrect_client_credentials\"}",
      expected: "configuration")
  }

  @Test(arguments: [300, 302, 500, 503])
  func otherStatusWithKnownErrorIsStillIndeterminate(_ status: Int) async {
    await expectRefreshClassification(
      status: status, body: "{\"error\":\"bad_refresh_token\"}", expected: "indeterminate")
    await expectRefreshClassification(
      status: status, body: "{\"error\":\"incorrect_client_credentials\"}",
      expected: "indeterminate")
  }

  @Test(arguments: [
    "not-json", "[]", "{}", "{\"error\":null}", "{\"error\":\"future_error\"}",
    "{\"error\":\"bad_refresh_token\",\"access_token\":\"unexpected\"}",
    "{\"error\":\"incorrect_client_credentials\",\"refresh_token\":\"unexpected\"}",
  ])
  func unknownMalformedOrMixedBodyCannotProveRejection(_ body: String) async {
    await expectRefreshClassification(body: body, expected: "indeterminate")
  }

  @Test(arguments: [401, 403])
  func statusAloneCannotProveCredentialRejection(_ status: Int) async {
    await expectRefreshClassification(status: status, body: "{}", expected: "indeterminate")
    await expectRefreshClassification(
      status: status, body: refreshJSON(), expected: "indeterminate")
  }

  @Test(arguments: [URLError.Code.timedOut, .notConnectedToInternet, .networkConnectionLost])
  func networkFailureCannotProveNoRemoteRotation(_ code: URLError.Code) async throws {
    let transport = RefreshTestTransport(result: .failure(.networkFailure(URLError(code))))
    let fetcher = try refreshFetcher(transport)
    #expect(await refreshFailure(fetcher) == "indeterminate")
    #expect(await transport.requests.count == 1)
  }

  @Test
  func missingConfigurationNeverBeginsTransport() async throws {
    let transport = RefreshTestTransport(result: .success(refreshResponse()))
    let fetcher = try refreshFetcher(transport, clientID: "", secret: "")
    #expect(await refreshFailure(fetcher) == "configuration")
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func unsafeReceiptClockCannotPublishAValidPair() async throws {
    let transport = RefreshTestTransport(result: .success(refreshResponse()))
    let fetcher = try refreshFetcher(
      transport, now: { Date(timeIntervalSinceReferenceDate: .infinity) })
    #expect(await refreshFailure(fetcher) == "indeterminate")
  }

  @Test
  func cancelledBeforeRequestNeverBeginsTransport() async throws {
    let transport = RefreshTestTransport(result: .success(refreshResponse()))
    let fetcher = try refreshFetcher(transport)
    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await refreshFailure(fetcher)
    }.value
    #expect(result == "cancelled-before")
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func transportCancellationIsAfterRequestStarted() async throws {
    let transport = RefreshTestTransport(
      result: .failure(.cancelled(underlying: CancellationError())))
    let fetcher = try refreshFetcher(transport)
    #expect(await refreshFailure(fetcher) == "cancelled-after")
    #expect(await transport.requests.count == 1)
  }

  @Test
  func configurationResponseAfterCancellationRemainsRetryable() async throws {
    let transport = RefreshTestTransport(
      result: .success(refreshResponse(body: "{\"error\":\"incorrect_client_credentials\"}")),
      cancelOnResponse: true)
    let store = RefreshTestStore(credential: refreshCredential(expired: true))
    let provider = OAuthTokenProvider(
      store: store, fetcher: try refreshFetcher(transport), now: { graphQLTestDate })
    #expect(await providerFailure(provider) == "configuration")
    #expect(await providerFailure(provider) == "configuration")
    #expect(await store.saves == 0)
    #expect(await transport.requests.count == 2)
  }

  @Test(arguments: [true, false])
  func trustworthyResponseWinsEvenWhenSharedTaskWasCancelled(_ success: Bool) async throws {
    let response =
      success ? refreshResponse() : refreshResponse(body: "{\"error\":\"bad_refresh_token\"}")
    let transport = RefreshTestTransport(result: .success(response), cancelOnResponse: true)
    let store = RefreshTestStore(credential: refreshCredential(expired: true))
    let provider = OAuthTokenProvider(
      store: store, fetcher: try refreshFetcher(transport), now: { graphQLTestDate })
    if success {
      let snapshot = try await provider.snapshot()
      #expect(snapshot.accessToken.rawValue == "new-access")
      #expect(await store.saves == 1)
    } else {
      #expect(await providerFailure(provider) == "authentication")
      #expect(await providerFailure(provider) == "authentication")
      #expect(await store.saves == 0)
    }
    #expect(await transport.requests.count == 1)
  }
}

@Suite("OAuth classified provider states")
struct OAuthClassifiedProviderTests {
  @Test(arguments: [false, true])
  func classifiedCredentialRejectionStopsBothProviderEntrypoints(
    _ initiallyExpired: Bool
  ) async throws {
    let store = RefreshTestStore(credential: refreshCredential(expired: initiallyExpired))
    let fetcher = RefreshClassifiedFetcher(failures: [.credentialRejected])
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
    let used = initiallyExpired ? nil : try await provider.snapshot()
    #expect(await providerFailure(provider, used: used) == "authentication")
    #expect(await providerFailure(provider) == "authentication")
    let stale = TokenSnapshot(accessToken: .init(rawValue: "unrelated"), version: 999)
    #expect(await providerFailure(provider, used: stale) == "authentication")
    #expect(await fetcher.calls == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == 0)
    #expect(await store.credential.accessToken.rawValue == "old-access")
  }

  @Test(arguments: [false, true])
  func indeterminateStopsBothEntrypointsAndPreservesStore(_ initiallyExpired: Bool) async throws {
    let store = RefreshTestStore(credential: refreshCredential(expired: initiallyExpired))
    let fetcher = RefreshClassifiedFetcher(failures: [.rotationIndeterminate])
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
    let used = initiallyExpired ? nil : try await provider.snapshot()
    #expect(await providerFailure(provider, used: used) == "indeterminate")
    #expect(await providerFailure(provider) == "indeterminate")
    let stale = TokenSnapshot(accessToken: .init(rawValue: "unrelated"), version: 999)
    #expect(await providerFailure(provider, used: stale) == "indeterminate")
    #expect(await fetcher.calls == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == 0)
    #expect(await store.credential.accessToken.rawValue == "old-access")
    try await store.save(refreshCredential(accessToken: "reauthorized"))
    let restored = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
    #expect(try await restored.snapshot().accessToken.rawValue == "reauthorized")
    #expect(await providerFailure(provider) == "indeterminate")
  }

  @Test(arguments: [
    OAuthTokenRefreshError.clientConfiguration, .knownTechnicalFailure,
    .cancelled(stage: .beforeRequest),
  ])
  func confirmedNoRotationFailuresRemainRetryable(_ failure: OAuthTokenRefreshError) async throws {
    let store = RefreshTestStore(credential: refreshCredential(expired: true))
    let fetcher = RefreshClassifiedFetcher(failures: [failure])
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
    #expect(await providerFailure(provider) == refreshClassification(failure))
    #expect(try await provider.snapshot().accessToken.rawValue == "replacement")
    #expect(await fetcher.calls == 2)
    #expect(await store.loads == 1)
    #expect(await store.saves == 1)
  }

  @Test
  func postStartCancellationIsCurrentCancellationThenTechnicalTerminal() async {
    let store = RefreshTestStore(credential: refreshCredential(expired: true))
    let fetcher = RefreshClassifiedFetcher(failures: [.cancelled(stage: .afterRequestStarted)])
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
    #expect(await providerFailure(provider) == "cancelled-after")
    #expect(await providerFailure(provider) == "indeterminate")
    let stale = TokenSnapshot(accessToken: .init(rawValue: "unrelated"), version: 999)
    #expect(await providerFailure(provider, used: stale) == "indeterminate")
    #expect(await fetcher.calls == 1)
    #expect(await store.loads == 1)
    #expect(await store.saves == 0)
  }
}

private func refreshJSON(removing field: String? = nil) -> String {
  let fields = [
    ("access_token", "\"new-access\""), ("refresh_token", "\"new-refresh\""),
    ("token_type", "\"bearer\""), ("scope", "\"\""),
    ("expires_in", "3600"), ("refresh_token_expires_in", "7200"),
  ]
  return "{" + fields.filter { $0.0 != field }.map { "\"\($0.0)\":\($0.1)" }.joined(separator: ",")
    + "}"
}

private func refreshResponse(status: Int = 200, body: String = refreshJSON()) -> HTTPResponse {
  .init(statusCode: status, headers: .init(), body: Data(body.utf8))
}

private func refreshCredential(
  expired: Bool = false, accessToken: String = "old-access", refreshToken: String = "old-refresh"
) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: accessToken), refreshToken: .init(rawValue: refreshToken),
    accessTokenExpiresAt: expired ? graphQLTestDate : graphQLTestDate.addingTimeInterval(100),
    refreshTokenExpiresAt: graphQLTestDate.addingTimeInterval(-1), tokenType: .bearer,
    grantedScopes: "")
}

private func refreshFetcher(
  _ transport: RefreshTestTransport, clientID: String = "test-id", secret: String = "test-secret",
  now: @escaping @Sendable () -> Date = { graphQLTestDate }
) throws -> GitHubOAuthHTTPTokenFetcher {
  .init(
    httpClient: HTTPClient(configuration: try .init(timeout: 30), transport: transport),
    configuration: .init(clientID: clientID, clientSecret: secret), now: now)
}

private func refreshFailure(_ fetcher: GitHubOAuthHTTPTokenFetcher) async -> String {
  do {
    _ = try await fetcher.refresh(refreshCredential())
    return "success"
  } catch { return refreshClassification(error) }
}

private func expectRefreshClassification(status: Int = 200, body: String, expected: String) async {
  let transport = RefreshTestTransport(
    result: .success(refreshResponse(status: status, body: body)))
  do {
    let fetcher = try refreshFetcher(transport)
    #expect(await refreshFailure(fetcher) == expected)
    #expect(await transport.requests.count == 1)
  } catch { Issue.record("Could not configure test fetcher") }
}

private func refreshClassification(_ error: OAuthTokenRefreshError) -> String {
  switch error {
  case .credentialRejected: "rejected"
  case .clientConfiguration: "configuration"
  case .knownTechnicalFailure: "technical"
  case .rotationIndeterminate: "indeterminate"
  case .cancelled(stage: .beforeRequest): "cancelled-before"
  case .cancelled(stage: .afterRequestStarted): "cancelled-after"
  }
}

private func providerFailure(
  _ provider: OAuthTokenProvider, used: TokenSnapshot? = nil
) async -> String {
  do {
    if let used {
      _ = try await provider.replacementSnapshot(afterUnauthorized: used)
    } else {
      _ = try await provider.snapshot()
    }
    return "success"
  } catch {
    switch error {
    case .authenticationRequired: return "authentication"
    case .refresh(let underlying):
      guard let classified = underlying as? OAuthTokenRefreshError else {
        return "local-exhaustion"
      }
      return refreshClassification(classified)
    default: return "unexpected-stage"
    }
  }
}

private actor RefreshTestTransport: Transport {
  let result: Result<HTTPResponse, HTTPClientError>
  let cancelOnResponse: Bool
  private(set) var requests: [URLRequest] = []
  init(result: Result<HTTPResponse, HTTPClientError>, cancelOnResponse: Bool = false) {
    self.result = result
    self.cancelOnResponse = cancelOnResponse
  }
  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    if cancelOnResponse { withUnsafeCurrentTask { $0?.cancel() } }
    return try result.get()
  }
}

private actor RefreshTestStore: OAuthCredentialStore {
  private(set) var credential: GitHubOAuthCredentialBundle
  private(set) var loads = 0
  private(set) var saves = 0
  init(credential: GitHubOAuthCredentialBundle) { self.credential = credential }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    return credential
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    self.credential = credential
  }
}

private actor RefreshClassifiedFetcher: OAuthTokenFetcher {
  private var failures: [OAuthTokenRefreshError]
  private(set) var calls = 0
  init(failures: [OAuthTokenRefreshError]) { self.failures = failures }
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    if !failures.isEmpty { throw failures.removeFirst() }
    return graphQLCredential("replacement")
  }
}
