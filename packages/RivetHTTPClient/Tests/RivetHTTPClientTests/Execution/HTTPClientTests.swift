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
  func forwardsTransportErrorWithoutMapping() async throws {
    let client = HTTPClient(transport: FailingTransport())
    let url = try HTTPURL(#require(URL(string: "https://example.com")))

    await #expect(throws: TransportFailure.unavailable) {
      try await client.execute(HTTPRequest(url: url, method: .get))
    }
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
    let headers: HTTPHeaders = ["Accept": "application/json", "X-Request-ID": "123"]
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
  let headers: HTTPHeaders = ["Accept": "application/json", "X-Request-ID": "123"]
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

  await #expect(throws: TransportFailure.unavailable) {
    try await invoke(client, url, HTTPHeaders(), nil)
  }
}
