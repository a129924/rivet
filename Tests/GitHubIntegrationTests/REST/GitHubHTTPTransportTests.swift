import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("GitHub GET transport")
struct GitHubHTTPTransportTests {
  @Test
  func productionSessionRejectsRedirectToAnotherDestination() throws {
    let session = GitHubHTTPClient.makeSession()
    let delegate = try #require(session.delegate as? GitHubHTTPRedirectBlocker)
    let source = try #require(URL(string: "https://api.github.com/user"))
    let destination = try #require(URL(string: "https://not-github.example/collect"))
    let response = try #require(
      HTTPURLResponse(
        url: source, statusCode: 302, httpVersion: "HTTP/1.1",
        headerFields: ["Location": destination.absoluteString]))
    let task = session.dataTask(with: URLRequest(url: source))
    let completion = RedirectCompletion()
    delegate.urlSession(
      session, task: task, willPerformHTTPRedirection: response,
      newRequest: URLRequest(url: destination)
    ) { request in
      completion.record(request)
    }
    #expect(completion.wasCalled)
    #expect(completion.request == nil)
    task.cancel()
    session.invalidateAndCancel()
  }

  @Test
  func rawRedirectResponseIsPreservedByProductionTransport() async throws {
    RawRedirectURLProtocol.reset()
    defer { RawRedirectURLProtocol.reset() }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RawRedirectURLProtocol.self]
    let client = GitHubHTTPClient.makeHTTPClient(configuration: configuration)
    let original = HTTPRequest(
      url: try HTTPURL(URL(string: "https://api.github.com/user")!), method: .get)
    let authenticated = try BearerAuth(token: "local-test-token").applying(to: original)
    let response = try await client.execute(authenticated)
    #expect(response.statusCode == 302)
    let requests = RawRedirectURLProtocol.requests
    #expect(requests.count == 1)
    #expect(requests.first?.url == original.url.value)
    #expect(requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer local-test-token")
  }
}

private final class RedirectCompletion: @unchecked Sendable {
  private let lock = NSLock()
  private var called = false
  private var storedRequest: URLRequest?
  var wasCalled: Bool { lock.withLock { called } }
  var request: URLRequest? { lock.withLock { storedRequest } }
  func record(_ request: URLRequest?) {
    lock.withLock {
      called = true
      storedRequest = request
    }
  }
}

private final class RawRedirectURLProtocol: URLProtocol, @unchecked Sendable {
  private static let state = RedirectRequestState()

  override static func canInit(with request: URLRequest) -> Bool { true }
  override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.state.capture(request)
    guard let source = request.url,
      let response = HTTPURLResponse(
        url: source, statusCode: 302, httpVersion: "HTTP/1.1",
        headerFields: ["Location": "https://not-github.example/collect"])
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

  static func reset() { state.reset() }
  static var requests: [URLRequest] { state.requests }
}

private final class RedirectRequestState: @unchecked Sendable {
  private let lock = NSLock()
  private var storedRequests: [URLRequest] = []
  var requests: [URLRequest] { lock.withLock { storedRequests } }
  func capture(_ request: URLRequest) { lock.withLock { storedRequests.append(request) } }
  func reset() { lock.withLock { storedRequests.removeAll() } }
}
