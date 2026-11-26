import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import RivetPRReaderGitHub
import Testing

@Suite("GitHub inline review comments source")
struct GitHubInlineReviewCommentsSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner-1", repository: "Repo.name_2", number: 42)
  private let detail = "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42"
  private let identity =
    #"{"number":42,"base":{"repo":{"id":817,"full_name":"OWNER-1/repo.NAME_2"}}}"#

  @Test
  func preservesEveryFieldAndPageOrder() async throws {
    let full = #"""
      [
        {
          "id":9007199254740993,"node_id":"opaque/node:1","body":"  **Review**\n> café  ",
          "path":"Sources/測試.swift","diff_hunk":"@@ -1,2 +2,3 @@\n+value",
          "position":9,"original_position":10,"line":11,"original_line":12,
          "start_line":13,"original_start_line":14,"side":"RIGHT","start_side":"LEFT",
          "commit_id":"new-ref","original_commit_id":"old-ref","subject_type":"line",
          "in_reply_to_id":9007199254740995,"pull_request_review_id":9007199254740997
        },
        {
          "id":2,"node_id":"file","body":"","path":"README.md","subject_type":"file",
          "line":null,"in_reply_to_id":null
        }
      ]
      """#
    let duplicateAndPartial = #"""
      [
        {"id":9007199254740993,"node_id":"opaque/node:1","body":"duplicate","path":"Sources/測試.swift"},
        {"id":1,"node_id":"partial","body":"partial","path":"README.md","start_line":2}
      ]
      """#
    let named =
      "https://api.github.com/repos/owner-1/REPO.NAME_2/pulls/42/comments?per_page=100&page=2"
    let client = InlineRESTSpy([
      .success(response(full, link: "<\(named)>; rel=\"next last\"")),
      .success(response(duplicateAndPartial, link: "<\(pageURL(2))>; rel=last")),
    ])

    let comments = try await fetch(client).get()
    #expect(comments.map(\.id) == [9_007_199_254_740_993, 2, 9_007_199_254_740_993, 1])
    #expect(comments.map(\.sourcePage) == [1, 1, 2, 2])
    #expect(comments.map(\.body) == ["  **Review**\n> café  ", "", "duplicate", "partial"])
    let comment = try #require(comments.first)
    #expect(comment.nodeID == "opaque/node:1")
    #expect(comment.path == "Sources/測試.swift")
    #expect(comment.diffHunk == "@@ -1,2 +2,3 @@\n+value")
    #expect(comment.position == 9)
    #expect(comment.originalPosition == 10)
    #expect(comment.line == 11)
    #expect(comment.originalLine == 12)
    #expect(comment.startLine == 13)
    #expect(comment.originalStartLine == 14)
    #expect(comment.side == "RIGHT")
    #expect(comment.startSide == "LEFT")
    #expect(comment.commitID == "new-ref")
    #expect(comment.originalCommitID == "old-ref")
    #expect(comment.subjectType == "line")
    #expect(comment.inReplyToID == 9_007_199_254_740_995)
    #expect(comment.pullRequestReviewID == 9_007_199_254_740_997)

    let file = try #require(comments.dropFirst().first)
    #expect(file.subjectType == "file")
    #expect(file.line == nil)
    #expect(file.originalLine == nil)
    #expect(file.startLine == nil)
    #expect(file.startSide == nil)
    #expect(file.inReplyToID == nil)
    let partial = try #require(comments.last)
    #expect(partial.startLine == 2)
    #expect(partial.line == nil)
    check(await client.requests, urls: [pageURL(1), pageURL(2)])
  }

  @Test
  func emptyListIsSuccessful() async {
    let client = InlineRESTSpy([.success(response("[]"))])
    #expect(await fetch(client) == .success([]))
    check(await client.requests, urls: [pageURL(1)])
  }

  @Test
  func verifiesNumericLinksOnceAndRebuildsNamedRequests() async throws {
    let client = InlineRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next, <\(numeric(3))>; rel=last")),
      .success(response(identity)),
      .success(page(2, link: "<\(numeric(3))>; rel=\"next last\"")),
      .success(page(3, link: "<\(numeric(3))>; rel=last")),
    ])
    #expect(try await fetch(client).get().map(\.id) == [1, 2, 3])
    check(await client.requests, urls: [pageURL(1), detail, pageURL(2), pageURL(3)])
  }

  @Test
  func verifiesNumericLastEvenWithoutNext() async throws {
    let client = InlineRESTSpy([
      .success(page(1, link: "<\(numeric(1))>; rel=last")),
      .success(response(identity)),
    ])
    #expect(try await fetch(client).get().map(\.id) == [1])
    check(await client.requests, urls: [pageURL(1), detail])
  }

  @Test(arguments: [
    "https://elsewhere.example/repos/Owner-1/Repo.name_2/pulls/42/comments?page=2&per_page=100",
    "http://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=2&per_page=100",
    "https://api.github.com:444/repos/Owner-1/Repo.name_2/pulls/42/comments?page=2&per_page=100",
    "https://api.github.com/repos/Other/Repo.name_2/pulls/42/comments?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Other/pulls/42/comments?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/43/comments?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=1&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=3&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=2&per_page=50",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/comments?page=2&per_page=100&since=now",
  ])
  func rejectsInvalidNextBeforeRequest(_ target: String) async {
    let client = InlineRESTSpy([.success(page(1, link: "<\(target)>; rel=next"))])
    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [pageURL(1)])
  }

  @Test
  func rejectsMalformedAndContradictoryLinks() async {
    for link in [
      "not a link",
      "<\(pageURL(2))>; rel=next, <\(pageURL(2))>; rel=next",
      "<\(pageURL(2))>; rel=next, <\(pageURL(1))>; rel=last",
      "<\(numeric(2))>; rel=next, <\(numeric(3, repository: 818))>; rel=last",
      "<\(pageURL(2))>; rel=last",
    ] {
      let client = InlineRESTSpy([.success(page(1, link: link))])
      #expect(await fetch(client) == .failure(.unavailable), "Link = \(link)")
      check(await client.requests, urls: [pageURL(1)])
    }
  }

  @Test
  func rejectsChangedNumericLastAfterEarlierVerification() async {
    let client = InlineRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next")),
      .success(response(identity)),
      .success(page(2, link: "<\(numeric(2, repository: 818))>; rel=last")),
    ])
    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [pageURL(1), detail, pageURL(2)])
  }

  @Test(arguments: [
    #"{"number":43,"base":{"repo":{"id":817,"full_name":"Owner-1/Repo.name_2"}}}"#,
    #"{"number":42,"base":{"repo":{"id":817,"full_name":"Owner-1/Other"}}}"#,
    #"{"number":42,"base":{"repo":{"id":818,"full_name":"Owner-1/Repo.name_2"}}}"#,
    "{}",
  ])
  func rejectsUnverifiedDetails(_ body: String) async {
    let client = InlineRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next")), .success(response(body)),
    ])
    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [pageURL(1), detail])
  }

  @Test(arguments: [401, 403, 404, 503])
  func detailsFailureMakesReadUnavailable(_ status: Int) async {
    let client = InlineRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next")),
      .success(response(identity, status: status)),
    ])
    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [pageURL(1), detail])
  }

  @Test
  func rejectsInvalidIdentityWithoutRequest() async {
    let client = InlineRESTSpy([])
    let invalid = ReaderPullRequestID(owner: "Owner-1", repository: "..", number: 42)
    let source = GitHubInlineReviewCommentsSource(client: client)
    #expect(await source.fetchInlineReviewComments(for: invalid) == .failure(.notReadable))
    #expect(await client.requests.isEmpty)
  }

  @Test(arguments: [
    "not JSON", "{}", "[null]",
    #"[{"node_id":"node","body":"no ID","path":"file"}]"#,
    #"[{"id":0,"node_id":"node","body":"zero","path":"file"}]"#,
    #"[{"id":9223372036854775808,"node_id":"node","body":"overflow","path":"file"}]"#,
    #"[{"id":2,"node_id":"","body":"empty node","path":"file"}]"#,
    #"[{"id":2,"node_id":"node","body":"empty path","path":""}]"#,
    #"[{"id":2,"node_id":"node","body":null,"path":"file"}]"#,
    #"[{"id":2,"node_id":"node","body":"bad line","path":"file","line":"3"}]"#,
  ])
  func refusesLossyDataOnFirstOrLaterPage(_ body: String) async {
    await checkPageFailure(.success(response(body)), expected: .contentNotRepresentable)
  }

  @Test(arguments: [401, 403, 404, 410, 422, 429, 503])
  func mapsHTTPFailuresOnFirstOrLaterPage(_ status: Int) async {
    let expected: PRReaderFailure =
      [401, 403, 404, 410].contains(status)
      ? .notReadable : .unavailable
    await checkPageFailure(.success(response("{}", status: status)), expected: expected)
  }

  @Test
  func distinguishesRateLimitedAndPermissionDeniedForbidden() async {
    let headers = HTTPHeaders(["X-RateLimit-Remaining": "0"])
    let limited = response("{}", status: 403, headers: headers)
    let denied = response(
      #"{"message":"Resource not accessible by integration."}"#, status: 403, headers: headers)
    await checkPageFailure(.success(limited), expected: .unavailable)
    await checkPageFailure(.success(denied), expected: .notReadable)
  }

  @Test
  func mapsThrownFailuresByRequestStage() async {
    await checkPageFailure(.failure(URLError(.timedOut)), expected: .unavailable)
    await checkPageFailure(
      .failure(GitHubHTTPClientError.authenticationRequired), expected: .notReadable)

    let first = InlineRESTSpy([.failure(GitHubHTTPClientError.invalidRequest)])
    let second = InlineRESTSpy([
      .success(page(1, link: "<\(pageURL(2))>; rel=next")),
      .failure(GitHubHTTPClientError.invalidRequest),
    ])
    #expect(await fetch(first) == .failure(.notReadable))
    #expect(await fetch(second) == .failure(.unavailable))
    check(await first.requests, urls: [pageURL(1)])
    check(await second.requests, urls: [pageURL(1), pageURL(2)])
  }

  @Test
  func cancellationBeforeRequestSkipsGET() async {
    let client = InlineRESTSpy([])
    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await fetch(client)
    }.value
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func cancellationDiscardsLateSuccessAndFailure() async {
    let firstPage = page(1, link: "<\(pageURL(2))>; rel=next")
    let lateResults: [Result<HTTPResponse, any Error>] = [
      .success(page(2)), .failure(GitHubHTTPClientError.authenticationRequired),
    ]
    for lateResult in lateResults {
      let client = InlineRESTSpy([.success(firstPage), lateResult], cancelOnRequest: 2)
      #expect(await Task { await fetch(client) }.value == .failure(.unavailable))
      check(await client.requests, urls: [pageURL(1), pageURL(2)])
    }
  }

  private func fetch(_ client: InlineRESTSpy) async -> Outcome<
    [ReaderInlineReviewComment], PRReaderFailure
  > {
    await GitHubInlineReviewCommentsSource(client: client).fetchInlineReviewComments(for: id)
  }

  private func checkPageFailure(
    _ failure: Result<HTTPResponse, any Error>, expected: PRReaderFailure
  ) async {
    let first = InlineRESTSpy([failure])
    let later = InlineRESTSpy([.success(page(1, link: "<\(pageURL(2))>; rel=next")), failure])
    #expect(await fetch(first) == .failure(expected))
    #expect(await fetch(later) == .failure(expected))
    check(await first.requests, urls: [pageURL(1)])
    check(await later.requests, urls: [pageURL(1), pageURL(2)])
  }

  private func check(_ requests: [HTTPRequest], urls: [String]) {
    #expect(requests.map(\.url.value.absoluteString) == urls)
    let headers = HTTPHeaders([
      "Accept": "application/vnd.github+json",
      "User-Agent": "Rivet",
      "X-GitHub-Api-Version": "2026-03-10",
    ])
    #expect(requests.allSatisfy { $0.method == .get && $0.headers == headers && $0.body == nil })
  }

  private func pageURL(_ page: Int) -> String {
    "\(detail)/comments?page=\(page)&per_page=100"
  }

  private func numeric(_ page: Int, repository: Int = 817) -> String {
    "https://api.github.com/repositories/\(repository)/pulls/42/comments?page=\(page)&per_page=100"
  }

  private func page(_ id: Int, link: String? = nil) -> HTTPResponse {
    response(#"[{"id":\#(id),"node_id":"node","body":"page","path":"file"}]"#, link: link)
  }

  private func response(
    _ body: String, status: Int = 200, headers: HTTPHeaders = [:], link: String? = nil
  ) -> HTTPResponse {
    var fields = headers
    fields.link = link
    return HTTPResponse(statusCode: status, headers: fields, body: Data(body.utf8))
  }
}

private actor InlineRESTSpy: GitHubRestClient {
  enum UnexpectedCall: Error {
    case request
  }

  private let responses: [Result<HTTPResponse, any Error>]
  private let cancelOnRequest: Int?
  private(set) var requests: [HTTPRequest] = []

  init(_ responses: [Result<HTTPResponse, any Error>], cancelOnRequest: Int? = nil) {
    self.responses = responses
    self.cancelOnRequest = cancelOnRequest
  }

  func get(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    let index = requests.count
    requests.append(HTTPRequest(url: url, method: .get, headers: headers, body: body))
    if requests.count == cancelOnRequest {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    guard responses.indices.contains(index) else { throw UnexpectedCall.request }
    return try responses[index].get()
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.request
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.request
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.request
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedCall.request
  }
}
