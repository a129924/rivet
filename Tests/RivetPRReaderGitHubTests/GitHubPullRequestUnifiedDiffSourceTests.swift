import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import Testing

@testable import RivetPRReaderGitHub

@Suite("GitHub pull request unified diff")
struct GitHubPullRequestUnifiedDiffSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner-1", repository: "Repo.name_2", number: 42)

  @Test
  func readsDiffAndBackgroundUsingDifferentAcceptValuesForTheSamePR() async throws {
    let backgroundBody = Data(
      #"{"title":"Title","body":"Description","user":{"login":"alice"}}"#.utf8)
    let diffBody = Data("diff --git a/file b/file\r\n@@ -1 +1 @@\r\n-old\r\n+new  \r\n".utf8)
    let client = UnifiedDiffRESTStub(
      .success(response(body: backgroundBody)), .success(response(body: diffBody)))
    let background = GitHubPullRequestBackgroundSource(client: client)
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(
      await background.fetchBackground(for: id)
        == .success(ReaderBackground(title: "Title", body: "Description", author: "alice")))
    #expect(await source.fetchUnifiedDiff(for: id) == .success(diffBody))

    let requests = await client.requests
    try #require(requests.count == 2)
    let expectedURL = "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42"
    for request in requests {
      #expect(request.method == .get)
      #expect(request.url.value.absoluteString == expectedURL)
      #expect(request.body == nil)
    }
    #expect(
      requests[0].headers.values == [
        "accept": "application/vnd.github+json",
        "user-agent": "Rivet",
        "x-github-api-version": "2026-03-10",
      ])
    #expect(
      requests[1].headers.values == [
        "accept": "application/vnd.github.diff",
        "user-agent": "Rivet",
        "x-github-api-version": "2026-03-10",
      ])
  }

  @Test(arguments: [Data(), Data([0xFF, 0xFE, 0x0A, 0x00])])
  func returnsRawBodyWithoutDecoding(_ body: Data) async {
    let client = UnifiedDiffRESTStub(.success(response(body: body)))
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(await source.fetchUnifiedDiff(for: id) == .success(body))
  }

  @Test
  func rejectsInvalidIdentityWithoutGET() async {
    let client = UnifiedDiffRESTStub()
    let source = GitHubPullRequestUnifiedDiffSource(client: client)
    let invalidID = ReaderPullRequestID(owner: "owner", repository: "..", number: 42)

    #expect(await source.fetchUnifiedDiff(for: invalidID) == .failure(.notReadable))
    #expect(await client.requests.isEmpty)
  }

  @Test(arguments: [401, 404])
  func mapsUnreadableStatus(_ status: Int) async {
    let client = UnifiedDiffRESTStub(.success(response(status: status)))
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(await source.fetchUnifiedDiff(for: id) == .failure(.notReadable))
    #expect(await client.requests.count == 1)
  }

  @Test(arguments: [201, 304, 406, 429, 503])
  func mapsUnavailableStatus(_ status: Int) async {
    let client = UnifiedDiffRESTStub(.success(response(status: status)))
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(await source.fetchUnifiedDiff(for: id) == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test(arguments: [
    ForbiddenCase(
      body: #"{"message":"Resource not accessible by integration."}"#,
      headers: [.custom("X-RateLimit-Remaining"): "0"], failure: .notReadable),
    ForbiddenCase(body: "", headers: [:], failure: .notReadable),
    ForbiddenCase(
      body: #"{"message":"You have exceeded a secondary rate limit."}"#,
      headers: [:], failure: .unavailable),
  ])
  func mapsForbiddenResponseThroughClassifier(_ fixture: ForbiddenCase) async {
    let client = UnifiedDiffRESTStub(
      .success(response(status: 403, headers: fixture.headers, body: Data(fixture.body.utf8))))
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(await source.fetchUnifiedDiff(for: id) == .failure(fixture.failure))
  }

  @Test(arguments: [GitHubHTTPClientError.authenticationRequired, .invalidRequest])
  func mapsUnreadableClientError(_ error: GitHubHTTPClientError) async {
    let client = UnifiedDiffRESTStub(.failure(error))
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(await source.fetchUnifiedDiff(for: id) == .failure(.notReadable))
  }

  @Test
  func mapsOtherClientFailures() async {
    let client = UnifiedDiffRESTStub(
      .failure(GitHubHTTPClientError.executionFailed), .failure(CancellationError()))
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    #expect(await source.fetchUnifiedDiff(for: id) == .failure(.unavailable))
    #expect(await source.fetchUnifiedDiff(for: id) == .failure(.unavailable))
  }

  @Test
  func cancellationBeforeRequestSkipsGET() async {
    let client = UnifiedDiffRESTStub()
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await source.fetchUnifiedDiff(for: id)
    }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func cancellationDuringGETDiscardsSuccessfulResponse() async {
    let client = UnifiedDiffRESTStub(
      .success(response(body: Data([0xFF]))), cancelOnResponse: true)
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    let result = await Task { await source.fetchUnifiedDiff(for: id) }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test(arguments: [GitHubHTTPClientError.authenticationRequired, .invalidRequest])
  func cancellationDuringGETTakesPrecedenceOverClientError(_ error: GitHubHTTPClientError) async {
    let client = UnifiedDiffRESTStub(.failure(error), cancelOnResponse: true)
    let source = GitHubPullRequestUnifiedDiffSource(client: client)

    let result = await Task { await source.fetchUnifiedDiff(for: id) }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  struct ForbiddenCase: Sendable {
    let body: String
    let headers: HTTPHeaders
    let failure: PRReaderFailure
  }

  private func response(
    status: Int = 200, headers: HTTPHeaders = [:], body: Data = Data()
  ) -> HTTPResponse {
    HTTPResponse(statusCode: status, headers: headers, body: body)
  }
}

private actor UnifiedDiffRESTStub: GitHubRestClient {
  enum UnexpectedCall: Error {
    case execute
  }

  private let outcomes: [Result<HTTPResponse, any Error>]
  private let cancelOnResponse: Bool
  private(set) var requests: [HTTPRequest] = []

  init(_ outcomes: Result<HTTPResponse, any Error>..., cancelOnResponse: Bool = false) {
    self.outcomes = outcomes
    self.cancelOnResponse = cancelOnResponse
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let index = requests.count
    requests.append(request)
    guard outcomes.indices.contains(index) else { throw UnexpectedCall.execute }
    if cancelOnResponse { withUnsafeCurrentTask { $0?.cancel() } }
    return try outcomes[index].get()
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
