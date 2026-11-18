import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRInbox
import Testing

@testable import InboxSearch

struct GitHubReviewRequestSourceTests {
  private static let query = "is:pr is:open user-review-requested:@me"
  private static let nextURL =
    "https://api.github.com/search/issues?q=is%3Apr+is%3Aopen+user-review-requested%3A%40me&per_page=100&page=2"

  @Test
  func exactRequestAndOrderedBaseRepositoryMapping() async throws {
    let client = ScriptedREST([
      .response(Self.page([Self.item(number: 9, title: "First")], total: 2, link: Self.link())),
      .response(Self.page([Self.item(number: 1, title: "Second")], total: 2)),
    ])

    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()

    #expect(
      try result.get() == [
        InboxItem(owner: "base-owner", repository: "base.repo", number: 9, title: "First"),
        InboxItem(owner: "base-owner", repository: "base.repo", number: 1, title: "Second"),
      ])
    let requests = await client.requests
    #expect(requests.count == 2)
    let request = try #require(requests.first)
    let parts = try #require(URLComponents(url: request.url.value, resolvingAgainstBaseURL: false))
    #expect(parts.scheme == "https")
    #expect(parts.host == "api.github.com")
    #expect(parts.path == "/search/issues")
    #expect(
      parts.queryItems == [
        URLQueryItem(name: "q", value: Self.query), URLQueryItem(name: "per_page", value: "100"),
      ])
    #expect(request.method == .get)
    #expect(request.body == nil)
    #expect(request.headers.accept == "application/vnd.github+json")
    #expect(request.headers.value(for: "X-GitHub-Api-Version") == "2026-03-10")
    let next = try #require(requests.last)
    #expect(next.url.value.absoluteString == Self.nextURL)
    #expect(next.headers == request.headers)
  }

  @Test
  func emptySuccess() async {
    let client = ScriptedREST([.response(Self.page([], total: 0))])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .success([]))
  }

  @Test
  func failedSecondPageDiscardsFirst() async {
    let client = ScriptedREST([
      .response(Self.page([Self.item(number: 1, title: "First")], total: 2, link: Self.link())),
      .response(Self.page([], total: 0, status: 503)),
    ])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 2)
  }

  @Test(arguments: [401, 403, 429, 500])
  func nonOKResponseIsUnavailable(status: Int) async {
    let client = ScriptedREST([.response(Self.page([], total: 0, status: status))])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test(arguments: [false, true])
  func transportAndCancellationAreUnavailable(cancelled: Bool) async {
    let client = ScriptedREST([cancelled ? .cancelled : .transportError])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test(
    arguments: [
      "<https://example.invalid/search/issues?q=anything&page=2>; rel=\"next\"",
      "<https://api.github.com/user?q=anything&page=2>; rel=\"next\"",
      "<https://api.github.com/search/issues?q=is%3Aopen&per_page=100&page=2>; rel=\"next\"",
      "malformed; rel=\"next\"",
    ])
  func unacceptableNextLinksDoNotSendSecondRequest(link: String) async {
    let client = ScriptedREST([
      .response(Self.page([Self.item(number: 1, title: "PR")], total: 2, link: link))
    ])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test
  func loopingNextStopsBeforeResending() async {
    let client = ScriptedREST([
      .response(Self.page([Self.item(number: 1, title: "First")], total: 3, link: Self.link())),
      .response(Self.page([Self.item(number: 2, title: "Second")], total: 3, link: Self.link())),
    ])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 2)
  }

  @Test
  func incompleteAndOverLimitAndTruncatedPagesAreUnavailable() async {
    let responses = [
      Self.page([], total: 0, incomplete: true),
      Self.page([], total: 1_001),
      Self.page([], total: 1),
    ]
    for response in responses {
      let client = ScriptedREST([.response(response)])
      let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
      #expect(result == .failure(.unavailable))
    }
  }

  @Test
  func neverRequestsAnEleventhPage() async {
    let pages = (1...10).map { page in
      let url = Self.nextURL.replacingOccurrences(of: "&page=2", with: "&page=\(page + 1)")
      let response = Self.page(
        [Self.item(number: page, title: "PR")], total: 1_000, link: "<\(url)>; rel=\"next\"")
      return ScriptedREST.Step.response(response)
    }
    let client = ScriptedREST(pages)
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 10)
  }

  @Test
  func expiredBudgetStartsNoRequest() async {
    let client = ScriptedREST([])
    let source = GitHubReviewRequestSource(
      rest: client, deadline: ContinuousClock.now.advanced(by: .seconds(-1)))
    let result = await PRInboxFacade(source: source).refresh()
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func malformedDTOIsUnavailable() async {
    let badShape = HTTPResponse(statusCode: 200, headers: [:], body: Data("{}".utf8))
    let notPR = Self.page([Self.item(number: 1, title: "Issue", marker: "null")], total: 1)
    let badRepository = Self.page(
      [Self.item(number: 1, title: "PR", repository: "https://api.github.com/repos/only-owner")],
      total: 1)
    for response in [badShape, notPR, badRepository] {
      let client = ScriptedREST([.response(response)])
      let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
      #expect(result == .failure(.unavailable))
    }
  }

  @Test
  func facadeStillFiltersClosedCandidates() async {
    let client = ScriptedREST([
      .response(Self.page([Self.item(number: 1, title: "Closed", state: "closed")], total: 1))
    ])
    let result = await PRInboxFacade(source: GitHubReviewRequestSource(rest: client)).refresh()
    #expect(result == .success([]))
  }

  private static func link() -> String {
    "<\(nextURL)>; rel=\"next\", <\(nextURL)>; rel=\"last\""
  }

  private static func page(
    _ rows: [String], total: Int, incomplete: Bool = false, link: String? = nil,
    status: Int = 200
  ) -> HTTPResponse {
    let items = rows.joined(separator: ",")
    let json = #"{"total_count":\#(total),"incomplete_results":\#(incomplete),"items":[\#(items)]}"#
    var headers = HTTPHeaders()
    headers.link = link
    return HTTPResponse(statusCode: status, headers: headers, body: Data(json.utf8))
  }

  private static func item(
    number: Int, title: String, state: String = "open",
    repository: String = "https://api.github.com/repos/base-owner/base.repo",
    marker: String = #"{"url":"https://api.github.com/repos/another/repo/pulls/1"}"#
  ) -> String {
    """
    {"number":\(number),"title":"\(title)","state":"\(state)",
     "repository_url":"\(repository)","pull_request":\(marker)}
    """
  }
}

private actor ScriptedREST: GitHubRestClient {
  enum Step: Sendable {
    case response(HTTPResponse)
    case transportError
    case cancelled
  }

  private var remaining: [Step]
  private(set) var requests: [HTTPRequest] = []

  init(_ steps: [Step]) {
    remaining = steps
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    requests.append(request)
    guard !remaining.isEmpty else { throw URLError(.badServerResponse) }
    switch remaining.removeFirst() {
    case .response(let response): return response
    case .transportError: throw URLError(.notConnectedToInternet)
    case .cancelled: throw CancellationError()
    }
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw URLError(.unsupportedURL)
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw URLError(.unsupportedURL)
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw URLError(.unsupportedURL)
  }
}
