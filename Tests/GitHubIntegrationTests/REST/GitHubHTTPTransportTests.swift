import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("GitHub REST transport")
struct GitHubHTTPTransportTests {
  @Test
  func defaultPolicyRejectsSameAndCrossHostRedirects() throws {
    let source = try GitHubAuthenticatedUserEndpoint.shared.makeURL().value
    let policy = DefaultGitHubRESTRedirectPolicy()
    let cases = [
      (302, "https://api.github.com/user/repos"),
      (302, "https://not-github.example/collect"),
      (307, "https://api.github.com/user/repos"),
    ]

    for (statusCode, location) in cases {
      let destination = try #require(URL(string: location))
      let response = try #require(
        HTTPURLResponse(
          url: source, statusCode: statusCode, httpVersion: "HTTP/1.1",
          headerFields: ["Location": location]))
      #expect(!policy.allows(URLRequest(url: destination), from: response))
    }
  }

  @Test(arguments: [true, false])
  func delegateTranslatesPolicyDecision(allowed: Bool) throws {
    let source = try GitHubAuthenticatedUserEndpoint.shared.makeURL().value
    let location = "https://not-github.example/collect"
    let destination = try #require(URL(string: location))
    let response = try #require(
      HTTPURLResponse(
        url: source, statusCode: 307, httpVersion: "HTTP/1.1",
        headerFields: ["Location": location]))
    var proposedRequest = URLRequest(url: destination)
    proposedRequest.httpMethod = "POST"
    proposedRequest.httpBody = Data("fixture body".utf8)
    proposedRequest.setValue("fixture", forHTTPHeaderField: "X-Redirect-Fixture")
    let policy = RecordingRedirectPolicy(allowed: allowed)
    let delegate = GitHubHTTPRedirectDelegate(policy: policy)
    let session = URLSession(configuration: .ephemeral)
    defer { session.invalidateAndCancel() }
    let task = session.dataTask(with: URLRequest(url: source))
    defer { task.cancel() }
    let completion = RedirectCompletion()

    delegate.urlSession(
      session, task: task, willPerformHTTPRedirection: response,
      newRequest: proposedRequest
    ) { request in
      completion.record(request)
    }

    let inputs = policy.inputs
    #expect(inputs.count == 1)
    #expect(inputs.first?.response === response)
    #expect(inputs.first?.request == proposedRequest)
    #expect(inputs.first?.request.httpBody == proposedRequest.httpBody)
    #expect(inputs.first?.request.allHTTPHeaderFields == proposedRequest.allHTTPHeaderFields)
    let completedRequests = completion.requests
    let expectedRequest = allowed ? proposedRequest : nil
    #expect(completedRequests == [expectedRequest])
    let completedRequest = completedRequests.first ?? nil
    #expect(completedRequest?.httpBody == expectedRequest?.httpBody)
    #expect(completedRequest?.allHTTPHeaderFields == expectedRequest?.allHTTPHeaderFields)
  }

  @Test
  func productionSessionRejectsRedirectToAnotherDestination() throws {
    let session = GitHubHTTPClient.makeSession()
    defer { session.invalidateAndCancel() }
    let delegate = try #require(session.delegate as? GitHubHTTPRedirectDelegate)
    let source = try GitHubAuthenticatedUserEndpoint.shared.makeURL().value
    let destination = try #require(URL(string: "https://not-github.example/collect"))
    let response = try #require(
      HTTPURLResponse(
        url: source, statusCode: 302, httpVersion: "HTTP/1.1",
        headerFields: ["Location": destination.absoluteString]))
    let task = session.dataTask(with: URLRequest(url: source))
    defer { task.cancel() }
    let completion = RedirectCompletion()
    delegate.urlSession(
      session, task: task, willPerformHTTPRedirection: response,
      newRequest: URLRequest(url: destination)
    ) { request in
      completion.record(request)
    }
    #expect(completion.requests == [nil])
  }

  @Test
  func rawRedirectResponseIsPreservedByProductionTransport() async throws {
    RawRedirectURLProtocol.reset()
    defer { RawRedirectURLProtocol.reset() }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RawRedirectURLProtocol.self]
    let client = GitHubRESTTransport.makeClient(configuration: configuration)
    let endpoint = GitHubAuthenticatedUserEndpoint.shared
    let original = HTTPRequest(url: try endpoint.makeURL(), method: endpoint.method)
    let authenticated = try BearerAuth(token: "local-test-token").applying(to: original)
    let response = try await client.execute(authenticated)
    #expect(response.statusCode == 302)
    #expect(response.headers[.custom("Location")] == RawRedirectURLProtocol.location)
    #expect(response.body == RawRedirectURLProtocol.body)
    let requests = RawRedirectURLProtocol.requests
    #expect(requests.count == 1)
    #expect(requests.first?.url == original.url.value)
    #expect(requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer local-test-token")
  }
}

private final class RecordingRedirectPolicy: RedirectPolicy, @unchecked Sendable {
  private let allowed: Bool
  private let lock = NSLock()
  private var storedInputs: [(request: URLRequest, response: HTTPURLResponse)] = []

  init(allowed: Bool) {
    self.allowed = allowed
  }

  var inputs: [(request: URLRequest, response: HTTPURLResponse)] {
    lock.withLock { storedInputs }
  }

  func allows(_ proposedRequest: URLRequest, from response: HTTPURLResponse) -> Bool {
    lock.withLock { storedInputs.append((proposedRequest, response)) }
    return allowed
  }
}

private final class RedirectCompletion: @unchecked Sendable {
  private let lock = NSLock()
  private var storedRequests: [URLRequest?] = []
  var requests: [URLRequest?] { lock.withLock { storedRequests } }

  func record(_ request: URLRequest?) {
    lock.withLock { storedRequests.append(request) }
  }
}

private final class RawRedirectURLProtocol: URLProtocol, @unchecked Sendable {
  private static let state = RedirectRequestState()
  static let location = "https://not-github.example/collect"
  static let body = Data("redirect response".utf8)

  override static func canInit(with request: URLRequest) -> Bool { true }
  override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.state.capture(request)
    guard let source = request.url,
      let response = HTTPURLResponse(
        url: source, statusCode: 302, httpVersion: "HTTP/1.1",
        headerFields: ["Location": Self.location])
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Self.body)
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
