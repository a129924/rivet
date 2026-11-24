import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import Testing

@testable import RivetPRReaderGitHub

@Suite("GitHub pull request background source")
struct GitHubPullRequestBackgroundSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner-1", repository: "Repo.name_2", number: 42)

  @Test
  func callsGETOnceWithStandardHeadersAndReturnsBackground() async throws {
    let client = RESTStub(
      .success(
        response(
          #"{"title":"  A title  ","body":"line 1\nline 2","user":{"login":"build[bot]"},"number":42}"#
        )))
    let source = GitHubPullRequestBackgroundSource(client: client)

    let result = await source.fetchBackground(for: id)
    let requests = await client.requests

    #expect(
      result
        == .success(
          ReaderBackground(title: "  A title  ", body: "line 1\nline 2", author: "build[bot]")))
    try #require(requests.count == 1)
    #expect(
      requests[0].url.value.absoluteString
        == "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42")
    #expect(
      requests[0].headers
        == HTTPHeaders([
          "Accept": "application/vnd.github+json",
          "User-Agent": "Rivet",
          "X-GitHub-Api-Version": "2026-03-10",
        ]))
    #expect(requests[0].body == nil)
  }

  @Test(arguments: [#"{"title":"Title","body":null,"user":null}"#, #"{"title":"Title"}"#])
  func keepsValidMissingFields(_ json: String) async {
    let client = RESTStub(.success(response(json)))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(
      await source.fetchBackground(for: id)
        == .success(ReaderBackground(title: "Title", body: nil, author: nil)))
  }

  @Test(arguments: [
    "not JSON",
    #"{}"#,
    #"{"title":null}"#,
    #"{"title":42}"#,
    #"{"title":"Title","body":42}"#,
    #"{"title":"Title","user":[]}"#,
    #"{"title":"Title","user":{}}"#,
    #"{"title":"Title","user":{"login":null}}"#,
    #"{"title":"Title","user":{"login":42}}"#,
  ])
  func rejectsUnrepresentableSuccessBodies(_ json: String) async {
    let client = RESTStub(.success(response(json)))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(await source.fetchBackground(for: id) == .failure(.contentNotRepresentable))
  }

  @Test
  func rejectsInvalidIdentityBeforeCallingGET() async {
    let client = RESTStub(.success(response(#"{"title":"Title"}"#)))
    let source = GitHubPullRequestBackgroundSource(client: client)
    let invalidID = ReaderPullRequestID(owner: "owner", repository: "..", number: 42)

    #expect(await source.fetchBackground(for: invalidID) == .failure(.notReadable))
    #expect(await client.requests.isEmpty)
  }

  @Test(arguments: [401, 404])
  func mapsUnreadableStatus(_ status: Int) async {
    let client = RESTStub(.success(response("not JSON", status: status)))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(await source.fetchBackground(for: id) == .failure(.notReadable))
  }

  @Test(arguments: [304, 429, 503])
  func mapsUnavailableStatus(_ status: Int) async {
    let client = RESTStub(.success(response("not JSON", status: status)))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(await source.fetchBackground(for: id) == .failure(.unavailable))
  }

  @Test(arguments: [
    ForbiddenCase(["rEtRy-aFtEr": " 10 "], "not JSON", .notReadable),
    ForbiddenCase(
      [:], #"{"message":"You have exceeded a secondary rate limit."}"#, .unavailable),
    ForbiddenCase(
      ["x-RATElimit-remaining": " 0 "],
      #"{"message":"Resource not accessible by integration."}"#, .notReadable),
    ForbiddenCase(["Retry-After": " \t ", "X-RateLimit-Remaining": "1"], "not JSON", .notReadable),
  ])
  func mapsSharedClassificationForForbidden(_ fixture: ForbiddenCase) async {
    let client = RESTStub(
      .success(response(fixture.body, status: 403, headers: HTTPHeaders(fixture.headers))))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(await source.fetchBackground(for: id) == .failure(fixture.failure))
  }

  @Test(arguments: [GitHubHTTPClientError.authenticationRequired, .invalidRequest])
  func mapsUnreadableClientError(_ error: GitHubHTTPClientError) async {
    let client = RESTStub(.failure(error))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(await source.fetchBackground(for: id) == .failure(.notReadable))
  }

  @Test(arguments: [GitHubHTTPClientError.credentialLifecycle(stage: .refresh), .executionFailed])
  func mapsUnavailableClientError(_ error: GitHubHTTPClientError) async {
    let client = RESTStub(.failure(error))
    let source = GitHubPullRequestBackgroundSource(client: client)

    #expect(await source.fetchBackground(for: id) == .failure(.unavailable))
  }

  @Test
  func cancellationBeforeRequestSkipsGET() async {
    let client = RESTStub(.success(response(#"{"title":"Title"}"#)))
    let source = GitHubPullRequestBackgroundSource(client: client)

    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await source.fetchBackground(for: id)
    }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func cancellationDuringGETDiscardsTheResponse() async {
    let client = RESTStub(.success(response(#"{"title":"Title"}"#)), cancelOnResponse: true)
    let source = GitHubPullRequestBackgroundSource(client: client)

    let result = await Task { await source.fetchBackground(for: id) }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test(arguments: [GitHubHTTPClientError.authenticationRequired, .invalidRequest])
  func cancellationDuringGETTakesPrecedenceOverClientError(_ error: GitHubHTTPClientError) async {
    let client = RESTStub(.failure(error), cancelOnResponse: true)
    let source = GitHubPullRequestBackgroundSource(client: client)

    let result = await Task { await source.fetchBackground(for: id) }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  struct ForbiddenCase: Sendable {
    let headers: [String: String]
    let body: String
    let failure: PRReaderFailure

    init(_ headers: [String: String], _ body: String, _ failure: PRReaderFailure) {
      self.headers = headers
      self.body = body
      self.failure = failure
    }
  }

  private func response(
    _ body: String, status: Int = 200, headers: HTTPHeaders = [:]
  ) -> HTTPResponse {
    HTTPResponse(statusCode: status, headers: headers, body: Data(body.utf8))
  }
}

private actor RESTStub: GitHubRestClient {
  enum UnexpectedCall: Error {
    case execute
  }

  private let result: Result<HTTPResponse, any Error>
  private let cancelOnResponse: Bool
  private(set) var requests: [HTTPRequest] = []

  init(_ result: Result<HTTPResponse, any Error>, cancelOnResponse: Bool = false) {
    self.result = result
    self.cancelOnResponse = cancelOnResponse
  }

  func get(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    requests.append(HTTPRequest(url: url, method: .get, headers: headers, body: body))
    if cancelOnResponse { withUnsafeCurrentTask { $0?.cancel() } }
    return try result.get()
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.execute
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.execute
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.execute
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.execute
  }
}
