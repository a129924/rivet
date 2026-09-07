import Foundation
import RivetHTTPClient
import Testing

@Suite("URLSessionTransport", .serialized)
struct URLSessionTransportTests {
  @Test
  func forwardsRequestAndMapsRawHTTPResponse() async throws {
    let url = try #require(URL(string: "https://example.invalid/pulls?state=open"))
    let body = Data("request-body".utf8)
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body

    URLProtocolStub.configure(
      result: .response(
        HTTPURLResponse(
          url: url,
          statusCode: 503,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json", "X-Request-ID": "request-1"]
        )!,
        Data("response-body".utf8)
      )
    )
    defer { URLProtocolStub.reset() }

    let response = try await executeUsingStub(request)

    let forwarded = try #require(URLProtocolStub.capturedRequest)
    #expect(forwarded.url == request.url)
    #expect(forwarded.httpMethod == "PATCH")
    #expect(forwarded.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(requestBody(forwarded) == body)
    #expect(response.statusCode == 503)
    #expect(response.headers.values["content-type"] == "application/json")
    #expect(response.headers.values["x-request-id"] == "request-1")
    #expect(response.body == Data("response-body".utf8))
  }

  @Test
  func mapsNonHTTPResponse() async throws {
    let url = try #require(URL(string: "https://example.invalid/non-http"))
    let response = URLResponse(
      url: url,
      mimeType: nil,
      expectedContentLength: 0,
      textEncodingName: nil
    )
    URLProtocolStub.configure(result: .response(response, Data()))
    defer { URLProtocolStub.reset() }

    let error = await #expect(throws: HTTPClientError.self) {
      try await executeUsingStub(URLRequest(url: url))
    }

    guard case .nonHTTPResponse = error else {
      Issue.record("Expected nonHTTPResponse, got \(String(describing: error))")
      return
    }
  }

  @Test
  func mapsURLLoadingFailureWithoutLosingCode() async throws {
    let url = try #require(URL(string: "https://example.invalid/network"))
    URLProtocolStub.configure(result: .failure(URLError(.notConnectedToInternet)))
    defer { URLProtocolStub.reset() }

    let error = await #expect(throws: HTTPClientError.self) {
      try await executeUsingStub(URLRequest(url: url))
    }

    guard case .urlLoading(let urlError) = error else {
      Issue.record("Expected urlLoading, got \(String(describing: error))")
      return
    }
    #expect(urlError.code == .notConnectedToInternet)
  }

  @Test
  func preservesCancellationAsURLLoadingFailure() async throws {
    let url = try #require(URL(string: "https://example.invalid/cancelled"))
    URLProtocolStub.configure(result: .failure(URLError(.cancelled)))
    defer { URLProtocolStub.reset() }

    let error = await #expect(throws: HTTPClientError.self) {
      try await executeUsingStub(URLRequest(url: url))
    }

    guard case .urlLoading(let urlError) = error else {
      Issue.record("Expected urlLoading, got \(String(describing: error))")
      return
    }
    #expect(urlError.code == .cancelled)
  }

  @Test
  func mapsUnexpectedFailureWithoutDiscardingUnderlyingError() async throws {
    let url = try #require(URL(string: "https://example.invalid/unexpected"))
    let failure = NSError(
      domain: UnexpectedTransportFailure.domain,
      code: UnexpectedTransportFailure.code
    )
    URLProtocolStub.configure(result: .failure(failure))
    defer { URLProtocolStub.reset() }

    let error = await #expect(throws: HTTPClientError.self) {
      try await executeUsingStub(URLRequest(url: url))
    }

    guard case .unexpected(let underlyingError) = error else {
      Issue.record("Expected unexpected, got \(String(describing: error))")
      return
    }
    let underlyingNSError = underlyingError as NSError
    #expect(underlyingNSError.domain == UnexpectedTransportFailure.domain)
    #expect(underlyingNSError.code == UnexpectedTransportFailure.code)
  }
}

private enum UnexpectedTransportFailure {
  static let domain = "RivetHTTPClientTests.UnexpectedTransportFailure"
  static let code = 1
}

private enum StubResult {
  case response(URLResponse, Data)
  case failure(any Error)
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
  private static let state = URLProtocolStubState()

  override static func canInit(with request: URLRequest) -> Bool {
    true
  }

  override static func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    URLProtocolStub.state.capture(request)
    guard let result = URLProtocolStub.state.result else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    switch result {
    case .response(let response, let body):
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: body)
      client?.urlProtocolDidFinishLoading(self)
    case .failure(let error):
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}

  static func configure(result: StubResult) {
    state.configure(result: result)
  }

  static func reset() {
    state.reset()
  }

  static var capturedRequest: URLRequest? {
    state.capturedRequest
  }

  static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }
}

private final class URLProtocolStubState: @unchecked Sendable {
  private let lock = NSLock()
  private var storedResult: StubResult?
  private var storedRequest: URLRequest?

  var result: StubResult? {
    lock.withLock { storedResult }
  }

  var capturedRequest: URLRequest? {
    lock.withLock { storedRequest }
  }

  func configure(result: StubResult) {
    lock.withLock {
      storedResult = result
      storedRequest = nil
    }
  }

  func capture(_ request: URLRequest) {
    lock.withLock {
      storedRequest = request
    }
  }

  func reset() {
    lock.withLock {
      storedResult = nil
      storedRequest = nil
    }
  }
}

private func requestBody(_ request: URLRequest) -> Data? {
  if let body = request.httpBody {
    return body
  }

  guard let stream = request.httpBodyStream else {
    return nil
  }

  stream.open()
  defer { stream.close() }

  var body = Data()
  let bufferSize = 1_024
  let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
  defer { buffer.deallocate() }

  while stream.hasBytesAvailable {
    let count = stream.read(buffer, maxLength: bufferSize)
    guard count > 0 else {
      break
    }
    body.append(buffer, count: count)
  }

  return body
}

private func executeUsingStub(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
  let transport = URLSessionTransport(session: URLProtocolStub.makeSession())
  return try await transport.execute(request)
}
