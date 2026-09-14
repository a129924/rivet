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
  func authExecutionSendsTheStartActionAndReturnsItsResponseAfterOneReceive() async throws {
    let originalRequest = try makeRequest(path: "original")
    let sentRequest = try makeRequest(path: "auth")
    let response = HTTPResponse.fixture
    let flow = RecordingAuthState(startAction: .send(sentRequest), receiveActions: [.finish])
    let transport = SequencedTransportState(outcomes: [.success(response)])
    let client = HTTPClient(transport: SequencedTransport(state: transport))

    let result = try await client.execute(originalRequest, auth: RecordingAuth(state: flow))

    #expect(result == response)
    #expect(flow.madeFlowRequests == [originalRequest])
    #expect(flow.starts == 1)
    #expect(flow.received == [response])
    #expect(transport.executedRequests.map(\.url) == [sentRequest.url.value])
  }

  @Test
  func authExecutionFollowsMultipleSendReceiveActionsAndReturnsTheLastResponse() async throws {
    let originalRequest = try makeRequest(path: "original")
    let firstRequest = try makeRequest(path: "first")
    let secondRequest = try makeRequest(path: "second")
    let firstResponse = HTTPResponse(
      statusCode: 201,
      headers: HTTPHeaders(),
      body: Data("first".utf8)
    )
    let secondResponse = HTTPResponse(
      statusCode: 202,
      headers: HTTPHeaders(),
      body: Data("second".utf8)
    )
    let flow = RecordingAuthState(
      startAction: .send(firstRequest),
      receiveActions: [.send(secondRequest), .finish]
    )
    let transport = SequencedTransportState(
      outcomes: [.success(firstResponse), .success(secondResponse)]
    )
    let client = HTTPClient(transport: SequencedTransport(state: transport))

    let result = try await client.execute(
      originalRequest,
      auth: RecordingAuth(state: flow)
    )

    #expect(result == secondResponse)
    #expect(flow.madeFlowRequests == [originalRequest])
    #expect(flow.starts == 1)
    #expect(flow.received == [firstResponse, secondResponse])
    #expect(
      transport.executedRequests.map(\.url) == [firstRequest.url.value, secondRequest.url.value]
    )
  }

  @Test
  func authExecutionRejectsDirectFinishWithoutSendingOrReceiving() async throws {
    let request = try makeRequest(path: "direct-finish")
    let flow = RecordingAuthState(startAction: .finish, receiveActions: [])
    let transport = SequencedTransportState(outcomes: [])
    let client = HTTPClient(transport: SequencedTransport(state: transport))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await client.execute(request, auth: RecordingAuth(state: flow))
      }
    )

    guard case .authFlowFinishedWithoutResponse = error else {
      Issue.record("Expected authFlowFinishedWithoutResponse, got \(String(describing: error))")
      return
    }
    #expect(flow.madeFlowRequests == [request])
    #expect(flow.starts == 1)
    #expect(flow.received.isEmpty)
    #expect(transport.executedRequests.isEmpty)
  }

  @Test
  func authExecutionPropagatesTheFirstTransportErrorWithoutReceivingOrRetrying() async throws {
    let request = try makeRequest(path: "first-failure")
    let flow = RecordingAuthState(startAction: .send(request), receiveActions: [])
    let transport = SequencedTransportState(
      outcomes: [.failure(.underlyingFailure(TransportFailure.unavailable))]
    )
    let client = HTTPClient(transport: SequencedTransport(state: transport))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await client.execute(request, auth: RecordingAuth(state: flow))
      }
    )

    assertUnexpectedTransportFailure(error)
    #expect(flow.received.isEmpty)
    #expect(transport.executedRequests.count == 1)
  }

  @Test
  func authExecutionPropagatesFollowUpTransportErrorWithoutAnotherReceiveOrRetry() async throws {
    let firstRequest = try makeRequest(path: "first")
    let secondRequest = try makeRequest(path: "second")
    let firstResponse = HTTPResponse.fixture
    let flow = RecordingAuthState(
      startAction: .send(firstRequest),
      receiveActions: [.send(secondRequest)]
    )
    let transport = SequencedTransportState(outcomes: [
      .success(firstResponse),
      .failure(.underlyingFailure(TransportFailure.unavailable)),
    ])
    let client = HTTPClient(transport: SequencedTransport(state: transport))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await client.execute(firstRequest, auth: RecordingAuth(state: flow))
      }
    )

    assertUnexpectedTransportFailure(error)
    #expect(flow.received == [firstResponse])
    #expect(
      transport.executedRequests.map(\.url) == [firstRequest.url.value, secondRequest.url.value]
    )
  }

  @Test(arguments: [404, 503])
  func authExecutionPassesRawNonSuccessResponsesToTheFlow(statusCode: Int) async throws {
    let request = try makeRequest(path: "status-\(statusCode)")
    let response = HTTPResponse(
      statusCode: statusCode,
      headers: HTTPHeaders(),
      body: Data("raw".utf8)
    )
    let flow = RecordingAuthState(startAction: .send(request), receiveActions: [.finish])
    let client = HTTPClient(
      transport: SequencedTransport(state: SequencedTransportState(outcomes: [.success(response)]))
    )

    let result = try await client.execute(request, auth: RecordingAuth(state: flow))

    #expect(result == response)
    #expect(flow.received == [response])
  }
}

private func makeRequest(path: String) throws -> HTTPRequest {
  let url = try HTTPURL(#require(URL(string: "https://example.com/\(path)")))
  return HTTPRequest(url: url, method: .get)
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

private func assertUnexpectedTransportFailure(_ error: HTTPClientError) {
  guard case .underlyingFailure(let underlyingError) = error else {
    Issue.record("Expected underlyingFailure HTTPClientError, got \(String(describing: error))")
    return
  }
  #expect((underlyingError as? TransportFailure) == .unavailable)
}
