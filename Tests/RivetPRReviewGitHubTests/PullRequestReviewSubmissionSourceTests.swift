import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReviewGitHub
import Testing

struct PullRequestReviewSubmissionSourceTests {
  private typealias Submission = GitHubPullRequestReviewSubmissionSource
  private static let commitSHA = "a559F7a69f2fda6d25c6e50298905f777cd831b4"

  @Test(arguments: [
    SubmissionCase(action: .approve, body: nil, event: "APPROVE", state: .approved),
    SubmissionCase(
      action: .approve, body: "  LGTM  ", event: "APPROVE", state: .approved),
    SubmissionCase(
      action: .requestChanges, body: "  Fix scope.\n", event: "REQUEST_CHANGES",
      state: .changesRequested),
    SubmissionCase(action: .comment, body: "繁體中文", event: "COMMENT", state: .commented),
  ])
  func sendsExactReviewAndReturnsReceipt(_ testCase: SubmissionCase) async throws {
    let standardHeaders = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    let rest = ReviewRESTStub(.success(response(200, body: receipt(state: testCase.state))))
    let result = await Submission(rest: rest).submit(
      input(action: testCase.action, body: testCase.body))
    guard case .accepted(let receipt) = result else {
      Issue.record("Expected an accepted review with receipt, got \(result)")
      return
    }
    #expect(receipt.id == 91)
    #expect(receipt.state == testCase.state)

    let requests = await rest.requests
    #expect(requests.count == 1)
    let request = try #require(requests.first)
    #expect(request.method == .post)
    #expect(
      request.url.value.absoluteString
        == "https://api.github.com/repos/Owner/rivet.repo/pulls/42/reviews")
    var expectedHeaders = standardHeaders
    expectedHeaders.contentType = "application/json"
    #expect(request.headers == expectedHeaders)
    #expect(
      try GitHubHeadersFactory.standard.make(requirements: [.standardREST]) == standardHeaders)
    var expectedJSON = ["event": testCase.event, "commit_id": Self.commitSHA]
    expectedJSON["body"] = testCase.body
    let body = try #require(request.body)
    #expect(try JSONSerialization.jsonObject(with: body) as? [String: String] == expectedJSON)
  }

  @Test
  func doesNotCallClientForInvalidInputOrPrecancelledTask() async {
    let rest = ReviewRESTStub(.success(response(200, body: receipt())))
    let submission = Submission(rest: rest)
    let invalid = [
      input(owner: ""),
      input(owner: ".."),
      input(owner: "owner%2Fother"),
      input(repository: "."),
      input(repository: "other/repo"),
      input(repository: "rivet?number=2"),
      input(repository: "rivet#42"),
      input(repository: "two words"),
      input(number: 0),
      input(number: -1),
      input(sha: "HEAD"),
      input(sha: "a" + Self.commitSHA),
      input(sha: "é" + Self.commitSHA.dropFirst()),
      input(action: .requestChanges),
      input(action: .requestChanges, body: "\n"),
      input(action: .comment),
      input(action: .comment, body: " \t\n"),
    ]
    for value in invalid {
      #expect(await submission.submit(value) == .notSubmitted)
    }
    let alreadyCancelled = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await submission.submit(input())
    }
    #expect(await alreadyCancelled.value == .notSubmitted)
    #expect(await rest.requests.isEmpty)
  }

  @Test(arguments: [
    "", "bad JSON", #"{"state":"APPROVED"}"#, #"{"id":0,"state":"APPROVED"}"#,
    #"{"id":-1,"state":"APPROVED"}"#, #"{"id":1}"#, #"{"id":1,"state":"PENDING"}"#,
    #"{"id":1,"state":"COMMENTED"}"#,
  ])
  func keepsAcceptanceWhenReceiptCannotBeUsed(_ body: String) async {
    let rest = ReviewRESTStub(.success(response(200, body: body)))
    #expect(await Submission(rest: rest).submit(input()) == .acceptedWithoutReceipt)
    #expect(await rest.requests.count == 1)
  }

  @Test(arguments: [401, 403, 404, 422, 429])
  func reportsExplicitRejection(_ status: Int) async {
    let rest = ReviewRESTStub(.success(response(status)))
    #expect(await Submission(rest: rest).submit(input()) == .rejected(statusCode: status))
    #expect(await rest.requests.count == 1)
  }

  @Test(arguments: [201, 302, 408, 500, 503])
  func unexpectedResponseNeedsReconciliation(_ status: Int) async {
    let rest = ReviewRESTStub(.success(response(status)))
    #expect(await Submission(rest: rest).submit(input()) == .needsReconciliation)
    #expect(await rest.requests.count == 1)
  }

  @Test(arguments: [
    GitHubHTTPClientError.authenticationRequired,
    .credentialLifecycle(stage: .restore),
    .credentialLifecycle(stage: .refresh),
    .credentialLifecycle(stage: .persist),
  ])
  func distinguishesAuthenticationFailure(_ error: GitHubHTTPClientError) async {
    let rest = ReviewRESTStub(.failure(error))
    #expect(await Submission(rest: rest).submit(input()) == .authenticationIncomplete)
    #expect(await rest.requests.count == 1)
  }

  @Test
  func distinguishesLocalClientRejection() async {
    let rest = ReviewRESTStub(.failure(GitHubHTTPClientError.invalidRequest))
    #expect(await Submission(rest: rest).submit(input()) == .notSubmitted)
    #expect(await rest.requests.count == 1)
  }

  @Test(arguments: [URLError.Code.timedOut, .networkConnectionLost, .cancelled])
  func transportErrorNeedsReconciliation(_ code: URLError.Code) async {
    let rest = ReviewRESTStub(.failure(URLError(code)))
    #expect(await Submission(rest: rest).submit(input()) == .needsReconciliation)
    #expect(await rest.requests.count == 1)
  }

  @Test
  func unknownClientExecutionFailureNeedsReconciliation() async {
    let rest = ReviewRESTStub(.failure(GitHubHTTPClientError.executionFailed))
    #expect(await Submission(rest: rest).submit(input()) == .needsReconciliation)
    #expect(await rest.requests.count == 1)
  }

  @Test
  func keepsReceivedSuccessDespiteCancellation() async {
    let rest = ReviewRESTStub(.success(response(200, body: receipt())), cancelling: true)
    let task = Task { await Submission(rest: rest).submit(input()) }
    guard case .accepted(let receipt) = await task.value else {
      Issue.record("Received 200 must win once the adapter sees it")
      return
    }
    #expect(receipt.id == 91)
    #expect(await rest.requests.count == 1)
  }

  @Test
  func cancellationReportedByClientNeedsReconciliation() async {
    let rest = ReviewRESTStub(.failure(CancellationError()), cancelling: true)
    let task = Task { await Submission(rest: rest).submit(input()) }
    #expect(await task.value == .needsReconciliation)
    #expect(await rest.requests.count == 1)
  }

  private func input(
    owner: String = "Owner", repository: String = "rivet.repo", number: Int = 42,
    sha: String = Self.commitSHA, action: Submission.Action = .approve, body: String? = nil
  ) -> Submission.Request {
    Submission.Request(
      owner: owner, repository: repository, pullNumber: number, commitSHA: sha,
      action: action, body: body)
  }

  private func response(_ status: Int, body: String = "") -> HTTPResponse {
    HTTPResponse(statusCode: status, headers: [:], body: Data(body.utf8))
  }

  private func receipt(state: Submission.State = .approved) -> String {
    #"{"id":91,"state":"\#(state.rawValue)","commit_id":null}"#
  }
}

struct SubmissionCase: Sendable {
  let action: GitHubPullRequestReviewSubmissionSource.Action
  let body: String?
  let event: String
  let state: GitHubPullRequestReviewSubmissionSource.State
}

private actor ReviewRESTStub: GitHubRestClient {
  private let result: Result<HTTPResponse, any Error>
  private let cancelling: Bool
  private(set) var requests: [HTTPRequest] = []

  init(_ result: Result<HTTPResponse, any Error>, cancelling: Bool = false) {
    self.result = result
    self.cancelling = cancelling
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    requests.append(request)
    if cancelling {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    return try result.get()
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    unexpectedMethod(request)
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    unexpectedMethod(request)
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    unexpectedMethod(request)
  }

  private func unexpectedMethod(_ request: HTTPRequest) -> HTTPResponse {
    requests.append(request)
    Issue.record("Unexpected method: \(request.method)")
    return HTTPResponse(statusCode: 500, headers: [:], body: Data())
  }
}
