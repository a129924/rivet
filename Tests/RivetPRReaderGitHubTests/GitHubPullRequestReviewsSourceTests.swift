import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import Testing

@testable import RivetPRReaderGitHub

@Suite("GitHub pull request reviews source")
struct GitHubPullRequestReviewsSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner-1", repository: "Repo.name_2", number: 42)
  private let first =
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=1&per_page=100"
  private let second =
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100"
  private let third =
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=3&per_page=100"
  private let detail = "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42"
  private let confirmed =
    #"{"number":42,"base":{"repo":{"id":817,"full_name":"OWNER-1/repo.NAME_2"}}}"#

  @Test
  func projectsAllReviewStatesWithoutLosingReviewContent() async throws {
    let body = #"""
      [
        {"id":9007199254740993,"body":"  **Hello**\n> quote  ","user":{"login":"build[bot]"},"state":"APPROVED"},
        {"id":4,"body":"","user":null,"state":"CHANGES_REQUESTED"},
        {"id":5,"body":"no author","state":"COMMENTED","commit_id":null},
        {"id":6,"body":"dismissed","user":{"login":"build[bot]"},"state":"DISMISSED"},
        {"id":7,"body":"pending","state":"PENDING"}
      ]
      """#
    let client = ReviewsRESTSpy([.success(response(body))])

    let reviews = try await fetch(client).get()

    #expect(
      reviews == [
        ReaderReview(
          id: "9007199254740993", body: "  **Hello**\n> quote  ", author: "build[bot]",
          state: .approved),
        ReaderReview(id: "4", body: "", author: nil, state: .changesRequested),
        ReaderReview(id: "5", body: "no author", author: nil, state: .commented),
        ReaderReview(id: "6", body: "dismissed", author: "build[bot]", state: .dismissed),
        ReaderReview(id: "7", body: "pending", author: nil, state: .pending),
      ])
    check(await client.requests, urls: [first])
  }

  @Test
  func emptyReviewsAreSuccessful() async {
    let client = ReviewsRESTSpy([.success(response("[]"))])
    #expect(await fetch(client) == .success([]))
    check(await client.requests, urls: [first])
  }

  @Test
  func invalidIdentitySkipsRequests() async {
    let client = ReviewsRESTSpy([])
    let invalid = ReaderPullRequestID(owner: "Owner-1", repository: "..", number: 42)
    let source = GitHubPullRequestReviewsSource(client: client)

    #expect(await source.fetchReviews(for: invalid) == .failure(.notReadable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func rebuildsNamedNextAndPreservesPageOrderAndDuplicates() async throws {
    let target =
      "https://api.github.com/repos/owner-1/REPO.NAME_2/pulls/42/reviews?per_page=100&page=2"
    let link = "<\(target)>; " + #"title="notes, more; here"; REL="next last""#
    let client = ReviewsRESTSpy([
      .success(
        response(
          #"[{"id":7,"body":"a","state":"APPROVED"},{"id":3,"body":"b","state":"COMMENTED"}]"#,
          link: link)),
      .success(
        response(
          #"[{"id":7,"body":"a","state":"APPROVED"},{"id":6,"body":"c","state":"PENDING"}]"#,
          link: "<\(second)>; rel=last")),
    ])

    let reviews = try await fetch(client).get()

    #expect(reviews.map(\.id) == ["7", "3", "7", "6"])
    #expect(reviews.map(\.body) == ["a", "b", "a", "c"])
    #expect(reviews.map(\.state) == [.approved, .commented, .approved, .pending])
    check(await client.requests, urls: [first, second])
  }

  @Test
  func checksNumericNextViaOriginalPullRequestOnce() async throws {
    let client = ReviewsRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next, <\(numeric(3))>; rel=last")),
      .success(response(confirmed)),
      .success(page(2, link: "<\(numeric(3))>; rel=\"next last\"")),
      .success(page(3)),
    ])

    #expect(try await fetch(client).get().map(\.id) == ["1", "2", "3"])
    check(await client.requests, urls: [first, detail, second, third])
  }

  @Test
  func terminalNumericLastNeedsNoDetails() async throws {
    let client = ReviewsRESTSpy([.success(page(1, link: "<\(numeric(1))>; rel=last"))])
    #expect(try await fetch(client).get().map(\.id) == ["1"])
    check(await client.requests, urls: [first])
  }

  @Test(arguments: [
    "https://elsewhere.example/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100",
    "http://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100",
    "https://api.github.com:444/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100",
    "https://api.github.com/repos/Other/Repo.name_2/pulls/42/reviews?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Other/pulls/42/reviews?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/43/reviews?page=2&per_page=100",
    "https://api.github.com/repos/Owner%2D1/Repo.name_2/pulls/42/reviews?page=2&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=1&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=3&per_page=100",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100&page=2",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=50",
    "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100&since=now",
    "https://api.github.com/repositories/0/pulls/42/reviews?page=2&per_page=100",
    "https://api.github.com/repositories/817/pulls/42/reviews?page=9223372036854775808&per_page=100",
  ])
  func rejectsUnverifiableNextBeforeRequest(_ url: String) async {
    let client = ReviewsRESTSpy([.success(page(1, link: "<\(url)>; rel=next"))])
    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [first])
  }

  @Test
  func rejectsMalformedAndContradictoryLinks() async {
    for link in [
      "not a link",
      "<\(second)>; rel=next,",
      "<\(second)>; rel=next; anchor=\"https://api.github.com/\"",
      "<\(second)>; rel=next, <\(second)>; rel=next",
      "<\(second)>; rel=next, <\(first)>; rel=last",
      "<\(second)>; rel=last",
    ] {
      let client = ReviewsRESTSpy([.success(page(1, link: link))])
      #expect(await fetch(client) == .failure(.unavailable), "Link = \(link)")
      check(await client.requests, urls: [first])
    }
  }

  @Test(arguments: [
    #"{"number":41,"base":{"repo":{"id":817,"full_name":"Owner-1/Repo.name_2"}}}"#,
    #"{"number":"42","base":{"repo":{"id":817,"full_name":"Owner-1/Repo.name_2"}}}"#,
    #"{"number":42,"base":{"repo":{"id":817,"full_name":"Owner-1/Other"}}}"#,
    #"{"number":42,"base":{"repo":{"id":817,"full_name":null}}}"#,
    #"{"number":42,"base":{"repo":{"id":818,"full_name":"Owner-1/Repo.name_2"}}}"#,
    #"{"number":42,"base":{"repo":{"id":"817","full_name":"Owner-1/Repo.name_2"}}}"#,
  ])
  func rejectsUnverifiedDetails(_ body: String) async {
    let client = ReviewsRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next")), .success(response(body)),
    ])

    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [first, detail])
  }

  @Test(arguments: [401, 403, 404, 503])
  func detailsHTTPFailureMakesReviewsUnavailable(_ status: Int) async {
    let client = ReviewsRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next")),
      .success(response(confirmed, status: status)),
    ])

    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [first, detail])
  }

  @Test(arguments: ["next", "last"])
  func rejectsChangedNumericIDWithoutASecondDetailsRequest(_ relation: String) async {
    let client = ReviewsRESTSpy([
      .success(page(1, link: "<\(numeric(2))>; rel=next")),
      .success(response(confirmed)),
      .success(
        page(
          2, link: "<\(numeric(relation == "next" ? 3 : 2, repositoryID: 818))>; rel=\(relation)")),
    ])

    #expect(await fetch(client) == .failure(.unavailable))
    check(await client.requests, urls: [first, detail, second])
  }

  @Test(arguments: [
    "not JSON", "{}", "[null]",
    #"[{"body":"missing id","state":"APPROVED"}]"#,
    #"[{"id":0,"body":"zero","state":"APPROVED"}]"#,
    #"[{"id":9223372036854775808,"body":"too large","state":"APPROVED"}]"#,
    #"[{"id":"8","body":"string id","state":"APPROVED"}]"#,
    #"[{"id":8,"state":"APPROVED"}]"#,
    #"[{"id":8,"body":null,"state":"APPROVED"}]"#,
    #"[{"id":8,"body":"missing state"}]"#,
    #"[{"id":8,"body":"unknown state","state":"UNKNOWN"}]"#,
    #"[{"id":8,"body":"invalid author","state":"APPROVED","user":{}}]"#,
    #"[{"id":8,"body":"invalid author","state":"APPROVED","user":{"login":""}}]"#,
    #"[{"id":8,"body":"invalid author","state":"APPROVED","user":{"login":42}}]"#,
  ])
  func rejectsUnrepresentableReviews(_ body: String) async {
    let firstPage = ReviewsRESTSpy([.success(response(body))])
    #expect(await fetch(firstPage) == .failure(.contentNotRepresentable))
    check(await firstPage.requests, urls: [first])

    let laterPage = ReviewsRESTSpy([
      .success(page(1, link: "<\(second)>; rel=next")), .success(response(body)),
    ])
    #expect(await fetch(laterPage) == .failure(.contentNotRepresentable))
    check(await laterPage.requests, urls: [first, second])
  }

  @Test(arguments: [401, 403, 404, 410, 422, 429, 503])
  func classifiesReviewsFailuresOnFirstAndLaterPages(_ status: Int) async {
    let failure: PRReaderFailure = [401, 403, 404].contains(status) ? .notReadable : .unavailable
    let denied = response("not JSON", status: status)
    let firstPage = ReviewsRESTSpy([.success(denied)])
    let laterPage = ReviewsRESTSpy([
      .success(page(1, link: "<\(second)>; rel=next")), .success(denied),
    ])

    #expect(await fetch(firstPage) == .failure(failure))
    #expect(await fetch(laterPage) == .failure(failure))
    check(await laterPage.requests, urls: [first, second])
  }

  @Test
  func distinguishesForbiddenRateLimitFromPermissionFailure() async {
    let headers = HTTPHeaders(["X-RateLimit-Remaining": "0"])
    let limited = ReviewsRESTSpy([.success(response("{}", status: 403, headers: headers))])
    let denied = ReviewsRESTSpy([
      .success(
        response(
          #"{"message":"Resource not accessible by integration."}"#, status: 403, headers: headers))
    ])

    #expect(await fetch(limited) == .failure(.unavailable))
    #expect(await fetch(denied) == .failure(.notReadable))
  }

  @Test
  func classifiesThrownFailuresByRequestStage() async {
    let start = page(1, link: "<\(second)>; rel=next")
    let numericStart = page(1, link: "<\(numeric(2))>; rel=next")
    let cases: [ThrownCase] = [
      ThrownCase([.failure(GitHubHTTPClientError.invalidRequest)], [first], .notReadable),
      ThrownCase([.failure(GitHubHTTPClientError.authenticationRequired)], [first], .notReadable),
      ThrownCase([.failure(URLError(.timedOut))], [first], .unavailable),
      ThrownCase(
        [.success(start), .failure(GitHubHTTPClientError.invalidRequest)], [first, second],
        .unavailable),
      ThrownCase([.success(start), .failure(URLError(.timedOut))], [first, second], .unavailable),
      ThrownCase(
        [.success(start), .failure(GitHubHTTPClientError.authenticationRequired)],
        [first, second], .notReadable),
      ThrownCase(
        [.success(numericStart), .failure(GitHubHTTPClientError.authenticationRequired)],
        [first, detail], .unavailable),
    ]
    for scenario in cases {
      let client = ReviewsRESTSpy(scenario.results)
      #expect(await fetch(client) == .failure(scenario.failure))
      check(await client.requests, urls: scenario.urls)
    }
  }

  @Test
  func cancellationBeforeRequestSkipsGET() async {
    let client = ReviewsRESTSpy([])
    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await fetch(client)
    }.value

    #expect(result == .failure(.unavailable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func cancellationDiscardsLateSuccessOrFailure() async {
    let start = page(1, link: "<\(second)>; rel=next")
    let firstPage = ReviewsRESTSpy([.success(page(1))], cancelOnRequest: 1)
    let laterPage = ReviewsRESTSpy([.success(start), .success(page(2))], cancelOnRequest: 2)
    let denied = ReviewsRESTSpy(
      [.success(start), .failure(GitHubHTTPClientError.authenticationRequired)], cancelOnRequest: 2)
    let details = ReviewsRESTSpy(
      [
        .success(page(1, link: "<\(numeric(2))>; rel=next")),
        .success(response(confirmed)),
      ], cancelOnRequest: 2)

    #expect(await Task { await fetch(firstPage) }.value == .failure(.unavailable))
    #expect(await Task { await fetch(laterPage) }.value == .failure(.unavailable))
    #expect(await Task { await fetch(denied) }.value == .failure(.unavailable))
    #expect(await Task { await fetch(details) }.value == .failure(.unavailable))
    check(await firstPage.requests, urls: [first])
    check(await laterPage.requests, urls: [first, second])
    check(await denied.requests, urls: [first, second])
    check(await details.requests, urls: [first, detail])
  }

  private struct ThrownCase {
    let results: [Result<HTTPResponse, any Error>]
    let urls: [String]
    let failure: PRReaderFailure

    init(
      _ results: [Result<HTTPResponse, any Error>], _ urls: [String], _ failure: PRReaderFailure
    ) {
      self.results = results
      self.urls = urls
      self.failure = failure
    }
  }

  private func fetch(_ client: ReviewsRESTSpy) async -> Outcome<
    [ReaderReview], PRReaderFailure
  > {
    await GitHubPullRequestReviewsSource(client: client).fetchReviews(for: id)
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

  private func page(_ id: Int, link: String? = nil) -> HTTPResponse {
    response(#"[{"id":\#(id),"body":"page \#(id)","state":"COMMENTED"}]"#, link: link)
  }

  private func numeric(_ page: Int, repositoryID: Int = 817) -> String {
    "https://api.github.com/repositories/\(repositoryID)/pulls/42/reviews?page=\(page)&per_page=100"
  }

  private func response(
    _ body: String, status: Int = 200, headers: HTTPHeaders = [:], link: String? = nil
  ) -> HTTPResponse {
    var fields = headers
    fields.link = link
    return HTTPResponse(statusCode: status, headers: fields, body: Data(body.utf8))
  }
}

private actor ReviewsRESTSpy: GitHubRestClient {
  enum UnexpectedCall: Error {
    case request
  }

  private let results: [Result<HTTPResponse, any Error>]
  private let cancelOnRequest: Int?
  private(set) var requests: [HTTPRequest] = []

  init(_ results: [Result<HTTPResponse, any Error>], cancelOnRequest: Int? = nil) {
    self.results = results
    self.cancelOnRequest = cancelOnRequest
  }

  func get(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    requests.append(HTTPRequest(url: url, method: .get, headers: headers, body: body))
    if requests.count == cancelOnRequest {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    let index = requests.count - 1
    guard results.indices.contains(index) else { throw UnexpectedCall.request }
    return try results[index].get()
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
