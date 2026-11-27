import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("GitHub single notification mark as read")
struct GitHubNotificationReadMarkerTests {
  private static let longID = "000184467440737095516160"
  private static let token = "local-notification-test-token"

  @Test
  func endpointPreservesLongIDAndDescribesOnlyTheFixedPatchRoute() throws {
    let endpoint = try GitHubNotificationMarkAsReadEndpoint(threadID: Self.longID)
    let url = try endpoint.makeURL().value

    #expect(endpoint.method == .patch)
    #expect(url.absoluteString == "https://api.github.com/notifications/threads/\(Self.longID)")
    #expect(url.query == nil)
  }

  @Test
  func markerSendsOneBodylessPatchWithStandardHeadersAndClassicPAT() async throws {
    let transport = MarkerTransport(.success(Self.response(205)))
    let result = try await Self.mark(using: transport, threadID: Self.longID)

    #expect(result == .confirmed)
    let requests = await transport.requests
    let request = try #require(requests.first)
    #expect(requests.count == 1)
    #expect(
      request.url?.absoluteString == "https://api.github.com/notifications/threads/\(Self.longID)")
    #expect(request.httpMethod == "PATCH")
    #expect(request.httpBody == nil)
    #expect(request.httpBodyStream == nil)
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Self.token)")
    let standard = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    for (name, value) in standard.values {
      #expect(request.value(forHTTPHeaderField: name) == value)
    }
  }

  @Test(arguments: ["", "0", "000", " 1", "1 ", "1\n", "１", "١", "/1", "1?all=true", "1%2F2", "-1"])
  func invalidIDIsRejectedByEndpointAndNeverSubmitted(id: String) async throws {
    #expect(throws: GitHubNotificationMarkAsReadEndpoint.ValidationError.invalidThreadID) {
      try GitHubNotificationMarkAsReadEndpoint(threadID: id)
    }
    let transport = MarkerTransport(.success(Self.response(205)))

    #expect(try await Self.mark(using: transport, threadID: id) == .invalidThreadID)
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func malformedBearerValueNeverReachesTransport() async throws {
    let transport = MarkerTransport(.success(Self.response(205)))

    #expect(try await Self.mark(using: transport, token: "local token") == .invalidRequest)
    #expect(await transport.requests.isEmpty)
  }

  @Test
  func cancellationBeforeSubmissionNeverReachesTransport() async throws {
    let transport = MarkerTransport(.success(Self.response(205)))
    let task = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await Self.mark(using: transport)
    }

    #expect(try await task.value == .cancelledBeforeSubmission)
    #expect(await transport.requests.isEmpty)
  }

  struct StatusCase: Sendable {
    let statusCode: Int
    let expected: GitHubNotificationReadMarker.Outcome
  }

  @Test(arguments: [
    StatusCase(statusCode: 304, expected: .notModified),
    StatusCase(statusCode: 401, expected: .accessRejected),
    StatusCase(statusCode: 403, expected: .accessRejected),
    StatusCase(statusCode: 429, expected: .rateLimited),
    StatusCase(statusCode: 500, expected: .resultUnknown),
    StatusCase(statusCode: 503, expected: .resultUnknown),
    StatusCase(statusCode: 200, expected: .unexpectedResponse(statusCode: 200)),
    StatusCase(statusCode: 404, expected: .unexpectedResponse(statusCode: 404)),
  ])
  func statusMappingWithoutRetry(testCase: StatusCase) async throws {
    let transport = MarkerTransport(.success(Self.response(testCase.statusCode)))

    #expect(try await Self.mark(using: transport) == testCase.expected)
    #expect(await transport.requests.count == 1)
  }

  @Test
  func rateLimitEvidenceDistinguishesA403FromAccessRejection() async throws {
    let rateLimit = Self.response(403, headers: [.custom("X-RateLimit-Remaining"): "0"])
    let transport = MarkerTransport(.success(rateLimit))

    #expect(try await Self.mark(using: transport) == .rateLimited)
    #expect(await transport.requests.count == 1)
  }

  @Test
  func rawRedirectResponseDoesNotTriggerASubsequentPatch() async throws {
    let redirect = Self.response(
      302, headers: [.custom("Location"): "https://not-github.example/collect"])
    let transport = MarkerTransport(.success(redirect))

    #expect(try await Self.mark(using: transport) == .unexpectedResponse(statusCode: 302))
    #expect(await transport.requests.count == 1)
    #expect(await transport.requests.first?.url?.host == "api.github.com")
  }

  @Test
  func transportFailuresRemainUnknownAndKeepDiagnosticsFreeOfCredentials() async throws {
    let failures: [HTTPClientError] = [
      .networkFailure(URLError(.timedOut)),
      .networkFailure(URLError(.networkConnectionLost)),
      .nonHTTPResponse(response: URLResponse(), body: Data(Self.token.utf8)),
      .underlyingFailure(NSError(domain: Self.token, code: 1)),
    ]
    for failure in failures {
      let transport = MarkerTransport(.failure(failure))
      let result = try await Self.mark(using: transport)

      #expect(result == .resultUnknown)
      #expect(!String(reflecting: result).contains(Self.token))
      #expect(await transport.requests.count == 1)
    }
  }

  @Test
  func cancellationAfterSubmissionWithoutAResponseRemainsUnknown() async throws {
    let transport = MarkerTransport(
      .failure(.cancelled(underlying: CancellationError())), cancelsTask: true)
    let task = Task { try await Self.mark(using: transport) }

    #expect(try await task.value == .resultUnknown)
    #expect(task.isCancelled)
    #expect(await transport.requests.count == 1)
  }

  @Test
  func aReceivedHTTPResponseWinsAgainstCancellation() async throws {
    let transport = MarkerTransport(.success(Self.response(205)), cancelsTask: true)
    let task = Task { try await Self.mark(using: transport) }

    #expect(try await task.value == .confirmed)
    #expect(task.isCancelled)
    #expect(await transport.requests.count == 1)
  }

  private static func mark(
    using transport: MarkerTransport,
    threadID: String = "1",
    token: String = Self.token
  ) async throws -> GitHubNotificationReadMarker.Outcome {
    let marker = GitHubNotificationReadMarker(httpClient: HTTPClient(transport: transport))
    return await marker.markAsRead(
      threadID: threadID, using: try PersonalAccessToken(rawValue: token))
  }

  private static func response(_ statusCode: Int, headers: HTTPHeaders = [:]) -> HTTPResponse {
    HTTPResponse(statusCode: statusCode, headers: headers, body: Data())
  }
}

private actor MarkerTransport: Transport {
  private let result: Result<HTTPResponse, HTTPClientError>
  private let cancelsTask: Bool
  private(set) var requests: [URLRequest] = []

  init(_ result: Result<HTTPResponse, HTTPClientError>, cancelsTask: Bool = false) {
    self.result = result
    self.cancelsTask = cancelsTask
  }

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    if cancelsTask {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    return try result.get()
  }
}
