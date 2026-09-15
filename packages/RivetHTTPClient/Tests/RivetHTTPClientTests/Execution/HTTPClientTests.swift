import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPClient")
struct HTTPClientTests {
  @Test
  func clientAndRequesterAreSendable() {
    assertSendable(HTTPClient.self)
    assertSendable(Requester.self)
  }

  @Test
  func forwardsToTransportAndReturnsRawResponse() async throws {
    let captured = LockedBox<URLRequest?>(nil)
    let expected = HTTPResponse.fixture
    let transport = CapturingTransport(captured: captured, response: expected)
    let client = HTTPClient(transport: transport)
    let url = try HTTPURL(#require(URL(string: "https://example.com")))

    let response = try await client.execute(HTTPRequest(url: url, method: .get))

    #expect(captured.value?.url == url.value)
    #expect(response == expected)
  }

  @Test
  func forwardsHTTPClientError() async throws {
    let client = HTTPClient(transport: FailingTransport())
    let url = try HTTPURL(#require(URL(string: "https://example.com")))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await client.execute(HTTPRequest(url: url, method: .get))
      }
    )
    assertUnexpectedTransportFailure(error)
  }

  @Test
  func verbFacadesForwardFixedMethodsAndRequestValues() async throws {
    try await assertFacade(method: .get) { client, url, headers, body in
      try await client.get(url: url, headers: headers, body: body)
    }
    try await assertFacade(method: .post) { client, url, headers, body in
      try await client.post(url: url, headers: headers, body: body)
    }
    try await assertFacade(method: .put) { client, url, headers, body in
      try await client.put(url: url, headers: headers, body: body)
    }
    try await assertFacade(method: .patch) { client, url, headers, body in
      try await client.patch(url: url, headers: headers, body: body)
    }
    try await assertFacade(method: .delete) { client, url, headers, body in
      try await client.delete(url: url, headers: headers, body: body)
    }
  }

  @Test
  func requestForwardsAnArbitraryMethodAndMatchesExecuteSemantics() async throws {
    let url = try HTTPURL(#require(URL(string: "https://example.com/issues?state=open")))
    let method = HTTPMethod(rawValue: "REPORT")
    let headers: HTTPHeaders = [.accept: "application/json", .custom("X-Request-ID"): "123"]
    let body = Data("payload".utf8)
    let expected = HTTPResponse.fixture
    let requestCapture = LockedBox<URLRequest?>(nil)
    let executeCapture = LockedBox<URLRequest?>(nil)
    let requestClient = HTTPClient(
      transport: CapturingTransport(captured: requestCapture, response: expected)
    )
    let executeClient = HTTPClient(
      transport: CapturingTransport(captured: executeCapture, response: expected)
    )

    let requestResponse = try await requestClient.request(
      method: method,
      url: url,
      headers: headers,
      body: body
    )
    let executeResponse = try await executeClient.execute(
      HTTPRequest(url: url, method: method, headers: headers, body: body)
    )

    let forwarded = try #require(requestCapture.value)
    let executed = try #require(executeCapture.value)
    #expect(requestResponse == expected)
    #expect(executeResponse == expected)
    #expect(forwarded.url == executed.url)
    #expect(forwarded.httpMethod == executed.httpMethod)
    #expect(forwarded.allHTTPHeaderFields == executed.allHTTPHeaderFields)
    #expect(forwarded.httpBody == executed.httpBody)
  }

  @Test
  func facadeDefaultsUseEmptyHeadersAndNilBody() async throws {
    let captured = LockedBox<URLRequest?>(nil)
    let client = HTTPClient(transport: CapturingTransport(captured: captured, response: .fixture))
    let url = try HTTPURL(#require(URL(string: "https://example.com")))

    _ = try await client.get(url: url)

    let forwarded = try #require(captured.value)
    #expect(forwarded.allHTTPHeaderFields?.isEmpty == true)
    #expect(forwarded.httpBody == nil)
  }

  @Test
  func facadeEntriesForwardTransportErrorsWithoutMapping() async throws {
    try await assertTransportFailure { client, url, headers, body in
      try await client.request(method: .get, url: url, headers: headers, body: body)
    }
    try await assertTransportFailure { client, url, headers, body in
      try await client.get(url: url, headers: headers, body: body)
    }
    try await assertTransportFailure { client, url, headers, body in
      try await client.post(url: url, headers: headers, body: body)
    }
    try await assertTransportFailure { client, url, headers, body in
      try await client.put(url: url, headers: headers, body: body)
    }
    try await assertTransportFailure { client, url, headers, body in
      try await client.patch(url: url, headers: headers, body: body)
    }
    try await assertTransportFailure { client, url, headers, body in
      try await client.delete(url: url, headers: headers, body: body)
    }
  }

  @Test
  func configurationHasValidatedDefaultsAndConfiguredTransportInjection() async throws {
    let configuration = try HTTPClient.Configuration()
    let state = RecordingTransportState()
    let client = HTTPClient(
      configuration: configuration,
      transport: RecordingTransport(state: state, response: .fixture)
    )
    let url = try HTTPURL(#require(URL(string: "https://example.com")))

    _ = HTTPClient()
    _ = try await client.execute(HTTPRequest(url: url, method: .get))

    let forwarded = try #require(state.executedRequests.first)
    #expect(configuration.baseURL == nil)
    #expect(configuration.timeout == 60)
    #expect(configuration.defaultHeaders == HTTPHeaders())
    #expect(forwarded.timeoutInterval == 60)
  }

  @Test(arguments: [TimeInterval(0), -1, .nan, .infinity, -TimeInterval.infinity])
  func configurationRejectsNonFiniteOrNonPositiveTimeout(timeout: TimeInterval) {
    #expect(throws: HTTPURLValidationError.invalidTimeout) {
      try HTTPClient.Configuration(timeout: timeout)
    }
  }

  @Test
  func configuredEntriesMergeHeadersAndForwardTimeout() async throws {
    let state = RecordingTransportState()
    let configuration = try HTTPClient.Configuration(
      baseURL: URL(string: "https://example.com/api")!,
      timeout: 2.5,
      defaultHeaders: [
        .accept: "application/json",
        .custom("X-Default"): "default",
      ]
    )
    let client = HTTPClient(
      configuration: configuration,
      transport: RecordingTransport(state: state, response: .fixture)
    )
    let url = try HTTPURL(#require(URL(string: "https://example.com/existing")))
    let requestHeaders: HTTPHeaders = [
      .custom("ACCEPT"): "text/plain",
      .custom("X-Request"): "request",
    ]

    _ = try await client.execute(HTTPRequest(url: url, method: .get, headers: requestHeaders))
    _ = try await client.get(url: url, headers: requestHeaders)
    _ = try await client.get(
      url: URL(string: "https://elsewhere.example/absolute")!,
      headers: requestHeaders
    )
    _ = try await client.get(path: "/relative", headers: requestHeaders)
    _ = try await client.request(
      method: HTTPMethod(rawValue: "REPORT"),
      url: URL(string: "https://elsewhere.example/direct")!,
      headers: requestHeaders
    )
    _ = try await client.request(
      method: HTTPMethod(rawValue: "REPORT"),
      path: "/direct-relative",
      headers: requestHeaders
    )

    #expect(state.executedRequests.count == 6)
    for request in state.executedRequests {
      #expect(request.timeoutInterval == 2.5)
      #expect(request.value(forHTTPHeaderField: "Accept") == "text/plain")
      #expect(request.value(forHTTPHeaderField: "X-Default") == "default")
      #expect(request.value(forHTTPHeaderField: "X-Request") == "request")
    }
    #expect(state.executedRequests[3].url?.absoluteString == "https://example.com/api/relative")
    #expect(state.executedRequests[4].url?.absoluteString == "https://elsewhere.example/direct")
    #expect(
      state.executedRequests[5].url?.absoluteString
        == "https://example.com/api/direct-relative"
    )
  }

  @Test
  func foundationURLFacadesForwardFixedMethodsAndValues() async throws {
    try await assertURLFacade(method: .get) { client, url, headers, body in
      try await client.get(url: url, headers: headers, body: body)
    }
    try await assertURLFacade(method: .post) { client, url, headers, body in
      try await client.post(url: url, headers: headers, body: body)
    }
    try await assertURLFacade(method: .put) { client, url, headers, body in
      try await client.put(url: url, headers: headers, body: body)
    }
    try await assertURLFacade(method: .patch) { client, url, headers, body in
      try await client.patch(url: url, headers: headers, body: body)
    }
    try await assertURLFacade(method: .delete) { client, url, headers, body in
      try await client.delete(url: url, headers: headers, body: body)
    }
  }

  @Test
  func relativePathFacadesForwardFixedMethodsAndValues() async throws {
    try await assertPathFacade(method: .get) { client, path, headers, body in
      try await client.get(path: path, headers: headers, body: body)
    }
    try await assertPathFacade(method: .post) { client, path, headers, body in
      try await client.post(path: path, headers: headers, body: body)
    }
    try await assertPathFacade(method: .put) { client, path, headers, body in
      try await client.put(path: path, headers: headers, body: body)
    }
    try await assertPathFacade(method: .patch) { client, path, headers, body in
      try await client.patch(path: path, headers: headers, body: body)
    }
    try await assertPathFacade(method: .delete) { client, path, headers, body in
      try await client.delete(path: path, headers: headers, body: body)
    }
  }

  @Test
  func absoluteURLNeverUsesConfiguredBaseURL() async throws {
    let captured = LockedBox<URLRequest?>(nil)
    let client = HTTPClient(
      configuration: try HTTPClient.Configuration(
        baseURL: URL(string: "https://base.example/api")!
      ),
      transport: CapturingTransport(captured: captured, response: .fixture)
    )
    let absoluteURL = try #require(URL(string: "https://other.example/users?state=open"))

    _ = try await client.get(url: absoluteURL)

    #expect(captured.value?.url == absoluteURL)
  }

  @Test(arguments: pathCompositionCases)
  func relativePathCompositionPreservesBaseSubpathAndSlashBoundary(
    testCase: PathCompositionCase
  ) async throws {
    let captured = LockedBox<URLRequest?>(nil)
    let client = HTTPClient(
      configuration: try HTTPClient.Configuration(baseURL: URL(string: testCase.baseURL)!),
      transport: CapturingTransport(captured: captured, response: .fixture)
    )

    _ = try await client.get(path: testCase.path)

    #expect(captured.value?.url?.absoluteString == testCase.expectedURL)
  }

  @Test
  func relativePathPreservesRawQueryAndEncodedSlashSegment() async throws {
    let captured = LockedBox<URLRequest?>(nil)
    let client = HTTPClient(
      configuration: try HTTPClient.Configuration(baseURL: URL(string: "https://example.com/api")!),
      transport: CapturingTransport(captured: captured, response: .fixture)
    )

    _ = try await client.get(path: "/users%2Factive?filter=name%2Fstate&sort=updated%20desc")

    #expect(
      captured.value?.url?.absoluteString
        == "https://example.com/api/users%2Factive?filter=name%2Fstate&sort=updated%20desc"
    )
  }

  @Test
  func validationFailuresDoNotReachTransport() async throws {
    try assertConfigurationValidation(
      baseURL: "ftp://example.com",
      expected: .unsupportedScheme("ftp")
    )
    try assertConfigurationValidation(
      baseURL: "https:///path",
      expected: .missingHost
    )
    try assertConfigurationValidation(
      baseURL: "https://example.com/api?version=1",
      expected: .baseURLHasQuery
    )
    try assertConfigurationValidation(
      baseURL: "https://example.com/api#section",
      expected: .baseURLHasFragment
    )
    try assertConfigurationValidation(
      baseURL: "https://example.com/api/../users",
      expected: .baseURLHasDotSegment
    )
    try assertConfigurationValidation(
      baseURL: "https://example.com/api/%2E%2E/users",
      expected: .baseURLHasDotSegment
    )

    try await assertPathValidation(
      path: "/users",
      configuration: try HTTPClient.Configuration(),
      expected: .missingBaseURL
    )
    try await assertPathValidation(
      path: "https://other.example/users",
      expected: .relativePathIsNotRelative
    )
    try await assertPathValidation(
      path: "//other.example/users",
      expected: .relativePathIsNotRelative
    )
    try await assertPathValidation(path: "/users#section", expected: .relativePathHasFragment)
    try await assertPathValidation(path: "/users/../private", expected: .relativePathHasDotSegment)
    try await assertPathValidation(path: "/users/%2e%2E", expected: .relativePathHasDotSegment)
    try await assertPathValidation(path: "", expected: .malformedRelativePath)
    try await assertPathValidation(path: "/users%", expected: .malformedRelativePathPercentEncoding)
  }

  @Test
  func foundationURLValidationDoesNotReachTransport() async throws {
    let state = RecordingTransportState()
    let client = HTTPClient(transport: RecordingTransport(state: state, response: .fixture))
    let invalidURL = try #require(URL(string: "file:///tmp/unsupported"))

    let error = try #require(
      await #expect(throws: HTTPURLValidationError.self) {
        try await client.get(url: invalidURL)
      }
    )

    #expect(error == .unsupportedScheme("file"))
    #expect(state.executedRequests.isEmpty)
  }

}

private func assertSendable<Value: Sendable>(_ value: Value.Type) {}

private func assertFacade(
  method: HTTPMethod,
  invoke: (HTTPClient, HTTPURL, HTTPHeaders, Data?) async throws -> HTTPResponse
) async throws {
  let captured = LockedBox<URLRequest?>(nil)
  let expected = HTTPResponse.fixture
  let client = HTTPClient(transport: CapturingTransport(captured: captured, response: expected))
  let url = try HTTPURL(#require(URL(string: "https://example.com/issues?state=open")))
  let headers: HTTPHeaders = [.accept: "application/json", .custom("X-Request-ID"): "123"]
  let body = Data("payload".utf8)

  let response = try await invoke(client, url, headers, body)

  let forwarded = try #require(captured.value)
  #expect(response == expected)
  #expect(forwarded.url == url.value)
  #expect(forwarded.httpMethod == method.rawValue)
  #expect(forwarded.value(forHTTPHeaderField: "Accept") == "application/json")
  #expect(forwarded.value(forHTTPHeaderField: "X-Request-ID") == "123")
  #expect(forwarded.httpBody == body)
}

private func assertTransportFailure(
  invoke: (HTTPClient, HTTPURL, HTTPHeaders, Data?) async throws -> HTTPResponse
) async throws {
  let client = HTTPClient(transport: FailingTransport())
  let url = try HTTPURL(#require(URL(string: "https://example.com")))

  let error = try #require(
    await #expect(throws: HTTPClientError.self) {
      try await invoke(client, url, HTTPHeaders(), nil)
    }
  )
  assertUnexpectedTransportFailure(error)
}

private func assertURLFacade(
  method: HTTPMethod,
  invoke: (HTTPClient, URL, HTTPHeaders, Data?) async throws -> HTTPResponse
) async throws {
  let captured = LockedBox<URLRequest?>(nil)
  let expected = HTTPResponse.fixture
  let client = HTTPClient(transport: CapturingTransport(captured: captured, response: expected))
  let url = try #require(URL(string: "https://example.com/issues?state=open"))
  let headers: HTTPHeaders = [.accept: "application/json", .custom("X-Request-ID"): "123"]
  let body = Data("payload".utf8)

  let response = try await invoke(client, url, headers, body)

  let forwarded = try #require(captured.value)
  #expect(response == expected)
  #expect(forwarded.url == url)
  #expect(forwarded.httpMethod == method.rawValue)
  #expect(forwarded.value(forHTTPHeaderField: "Accept") == "application/json")
  #expect(forwarded.value(forHTTPHeaderField: "X-Request-ID") == "123")
  #expect(forwarded.httpBody == body)
}

private func assertPathFacade(
  method: HTTPMethod,
  invoke: (HTTPClient, String, HTTPHeaders, Data?) async throws -> HTTPResponse
) async throws {
  let captured = LockedBox<URLRequest?>(nil)
  let expected = HTTPResponse.fixture
  let client = HTTPClient(
    configuration: try HTTPClient.Configuration(baseURL: URL(string: "https://example.com/api")!),
    transport: CapturingTransport(captured: captured, response: expected)
  )
  let headers: HTTPHeaders = [.accept: "application/json", .custom("X-Request-ID"): "123"]
  let body = Data("payload".utf8)

  let response = try await invoke(client, "/issues?state=open", headers, body)

  let forwarded = try #require(captured.value)
  #expect(response == expected)
  #expect(forwarded.url?.absoluteString == "https://example.com/api/issues?state=open")
  #expect(forwarded.httpMethod == method.rawValue)
  #expect(forwarded.value(forHTTPHeaderField: "Accept") == "application/json")
  #expect(forwarded.value(forHTTPHeaderField: "X-Request-ID") == "123")
  #expect(forwarded.httpBody == body)
}

private func assertConfigurationValidation(
  baseURL: String,
  expected: HTTPURLValidationError
) throws {
  #expect(throws: expected) {
    try HTTPClient.Configuration(baseURL: URL(string: baseURL)!)
  }
}

private func assertPathValidation(
  path: String,
  configuration: HTTPClient.Configuration? = nil,
  expected: HTTPURLValidationError
) async throws {
  let state = RecordingTransportState()
  let resolvedConfiguration =
    try configuration
    ?? HTTPClient.Configuration(
      baseURL: URL(string: "https://example.com/api")!
    )
  let client = HTTPClient(
    configuration: resolvedConfiguration,
    transport: RecordingTransport(state: state, response: .fixture)
  )

  let error = try #require(
    await #expect(throws: HTTPURLValidationError.self) {
      try await client.get(path: path)
    }
  )

  #expect(error == expected)
  #expect(state.executedRequests.isEmpty)
}

struct PathCompositionCase: Sendable {
  let baseURL: String
  let path: String
  let expectedURL: String
}

let pathCompositionCases = [
  PathCompositionCase(
    baseURL: "https://example.com",
    path: "users",
    expectedURL: "https://example.com/users"
  ),
  PathCompositionCase(
    baseURL: "https://example.com/",
    path: "/users",
    expectedURL: "https://example.com/users"
  ),
  PathCompositionCase(
    baseURL: "https://example.com/api",
    path: "/users",
    expectedURL: "https://example.com/api/users"
  ),
  PathCompositionCase(
    baseURL: "https://example.com/api/",
    path: "users",
    expectedURL: "https://example.com/api/users",
  ),
]

private func assertUnexpectedTransportFailure(_ error: HTTPClientError) {
  guard case .underlyingFailure(let underlyingError) = error else {
    Issue.record("Expected underlyingFailure HTTPClientError, got \(String(describing: error))")
    return
  }
  #expect((underlyingError as? TransportFailure) == .unavailable)
}
