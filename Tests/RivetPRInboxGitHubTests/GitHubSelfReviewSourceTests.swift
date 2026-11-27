import Foundation
import RivetHTTPClient
import RivetPRInbox
import RivetPRInboxGitHub
import Testing

@testable import GitHubIntegration

@Suite("GitHub self-review inbox")
struct GitHubSelfReviewSourceTests {
  @Test(arguments: [
    "https://api.github.com/search/issues?q=is%3Apr+is%3Aopen+author%3Amy-user&per_page=100&page=2",
    "https://api.github.com:443/search/issues?page=2&per_page=100&q=is:pr%20is:open%20author:my-user",
  ])
  func facadeReturnsOnlyOpenItemsAuthoredByTheOAuthViewerInPageOrder(
    _ nextAddress: String
  ) async throws {
    let stub = RESTStub([
      .success(.viewer),
      .success(
        try .page(
          [
            .init(number: 1),
            .init(number: 2, author: "someone-else", requestedReviewers: [.init(login: "my-user")]),
            .init(number: 3, state: "closed"),
            .init(number: 4, state: "closed", merged: true),
            .init(number: 5, author: nil),
          ],
          total: 7, link: "<\(nextAddress)>; rel=\"next\"")),
      .success(
        try .page(
          [
            .init(number: 6, author: "MY-USER", draft: true),
            .init(number: 7, author: "fork-author"),
          ],
          total: 7)),
    ])
    let result = await inbox(stub).refresh()
    #expect(
      try result.get() == [
        InboxItem(owner: "destination", repository: "rivet", number: 1, title: "PR 1"),
        InboxItem(owner: "destination", repository: "rivet", number: 6, title: "PR 6"),
      ])

    let requests = await stub.requests
    #expect(requests.map(\.url.value.path) == ["/user", "/search/issues", "/search/issues"])
    #expect(requests.last?.url.value.absoluteString == nextAddress)
    let firstSearch = try #require(requests.dropFirst().first)
    let query = URLComponents(url: firstSearch.url.value, resolvingAgainstBaseURL: false)?
      .queryItems
    #expect(
      query == [
        URLQueryItem(name: "q", value: "is:pr is:open author:my-user"),
        URLQueryItem(name: "per_page", value: "100"),
      ])
    for request in requests {
      #expect(request.method == .get)
      #expect(request.url.value.host == "api.github.com")
      #expect(request.headers.accept == "application/vnd.github+json")
      #expect(request.headers.userAgent == "Rivet")
      #expect(request.headers.value(for: "X-GitHub-Api-Version") == "2026-03-10")
      #expect(request.body == nil)
    }
  }

  @Test
  func usesInjectedHeadersForAccountAndSearch() async throws {
    let configuration = try GitHubHeadersConfiguration(
      restAccept: "application/json", standardUserAgent: "Inbox Fixture",
      loginUserAgent: "Login Fixture", apiVersion: "2040-01-01")
    let stub = RESTStub([.success(.viewer), .success(try .page([], total: 0))])
    let source = GitHubSelfReviewSource(
      rest: stub, headersFactory: GitHubHeadersFactory(configuration: configuration))

    #expect(try await source.fetchSelfReviewCandidates().get().isEmpty)
    let requests = await stub.requests
    #expect(requests.map(\.url.value.path) == ["/user", "/search/issues"])
    for request in requests {
      #expect(request.headers.accept == "application/json")
      #expect(request.headers.userAgent == "Inbox Fixture")
      #expect(request.headers.value(for: "X-GitHub-Api-Version") == "2040-01-01")
    }
  }

  @Test
  func completeEmptySearchIsSuccessful() async throws {
    let stub = RESTStub([.success(.viewer), .success(try .page([], total: 0))])
    #expect(try await inbox(stub).refresh().get().isEmpty)
  }

  @Test
  func invalidViewerDoesNotSearch() async {
    let stub = RESTStub([.success(.json(#"{"login":"bad author:other"}"#))])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(await stub.requests.map(\.url.value.path) == ["/user"])
  }

  @Test(arguments: [401, 404, 422, 429, 503, 201, 302])
  func rejectedAccountResponseStopsBeforeSearch(_ status: Int) async {
    let stub = RESTStub([.success(.json(#"{"login":"my-user"}"#, status: status))])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(await stub.requests.map(\.url.value.path) == ["/user"])
  }

  @Test(arguments: [
    HTTPResponse.json(#"{"message":"Resource not accessible by integration"}"#, status: 403),
    HTTPResponse.json(#"{"message":"You have exceeded a secondary rate limit"}"#, status: 403),
    HTTPResponse.json("{}", status: 403, headers: HTTPHeaders(["X-RateLimit-Remaining": "0"])),
    HTTPResponse.json("{}", status: 403),
  ])
  func forbiddenSearchResponseIsUnavailableWithoutResending(_ response: HTTPResponse) async {
    let stub = RESTStub([.success(.viewer), .success(response)])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(await stub.requests.map(\.url.value.path) == ["/user", "/search/issues"])
  }

  @Test
  func laterPageFailureDiscardsEarlierCandidates() async throws {
    let stub = RESTStub([
      .success(.viewer),
      .success(try .page([.init(number: 1)], total: 2, link: nextLink)),
      .success(.json("{}", status: 403)),
    ])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(
      await stub.requests.map(\.url.value.path) == ["/user", "/search/issues", "/search/issues"])
  }

  @Test(arguments: [
    #"<https://other.example/search/issues?q=is%3Apr+is%3Aopen+author%3Amy-user&per_page=100&page=2>; rel="next""#,
    #"<https://api.github.com/search/issues?q=is%3Apr+is%3Aopen+author%3Asomeone-else&per_page=100&page=2>; rel="next""#,
    #"<https://api.github.com/search/issues?q=is%3Apr+is%3Aopen+author%3Amy-user&per_page=100&page=1>; rel="next""#,
    #"<https://api.github.com/%73earch/issues?q=is:pr%20is:open%20author:my-user&per_page=100&page=2>; rel="next""#,
    #"<https://api.github.com/search/issues?q=is:pr%20is:open%20author:my-user&per_page=100&page=3>; rel="next""#,
    #"<https://api.github.com/search/issues?q=is:pr%20is:open%20author:my-user&per_page=100&page=2&page=2>; rel="next""#,
  ])
  func rejectsNextLinkOutsideTheOriginalSearch(_ link: String) async throws {
    let stub = RESTStub([
      .success(.viewer), .success(try .page([.init(number: 1)], total: 2, link: link)),
    ])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(await stub.requests.count == 2)
  }

  @Test
  func incompleteUnreadableOrTruncatedPagesFail() async throws {
    let pages: [HTTPResponse] = [
      try .page([], total: 0, incomplete: true),
      try .page([], total: 1_001),
      try .page([.init(number: 1)], total: 2),
      .json(#"{"total_count":1,"incomplete_results":false,"items":[{"number":1}]}"#),
    ]
    for page in pages {
      let stub = RESTStub([.success(.viewer), .success(page)])
      #expect(await inbox(stub).refresh() == .failure(.unavailable))
      #expect(await stub.requests.count == 2)
    }
  }

  @Test(arguments: [
    GitHubHTTPClientError.authenticationRequired,
    .invalidRequest,
    .executionFailed,
    .credentialLifecycle(stage: .refresh),
  ])
  func requestExecutionFailureIsUnavailableWithoutResending(_ error: GitHubHTTPClientError) async {
    let stub = RESTStub([.success(.viewer), .failure(error)])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(await stub.requests.map(\.url.value.path) == ["/user", "/search/issues"])
  }

  @Test
  func cancellationMapsToUnavailableWithoutResending() async {
    let stub = RESTStub([.success(.viewer), .failure(CancellationError())])
    #expect(await inbox(stub).refresh() == .failure(.unavailable))
    #expect(await stub.requests.count == 2)
  }

  private func inbox(_ stub: RESTStub) -> PRInboxFacade {
    PRInboxFacade(selfReviewSource: GitHubSelfReviewSource(rest: stub))
  }
}

private let nextLink =
  #"<https://api.github.com/search/issues?q=is%3Apr+is%3Aopen+author%3Amy-user&per_page=100&page=2>; rel="next""#

private struct Item: Encodable {
  struct User: Encodable {
    let login: String
  }

  let repositoryURL = "https://api.github.com/repos/destination/rivet"
  let number: Int
  let title: String
  let state: String
  let draft: Bool
  let user: User?
  let requestedReviewers: [User]
  let pullRequest: [String: String]

  enum CodingKeys: String, CodingKey {
    case repositoryURL = "repository_url"
    case requestedReviewers = "requested_reviewers"
    case pullRequest = "pull_request"
    case number, title, state, draft, user
  }

  init(
    number: Int, author: String? = "my-user", state: String = "open",
    draft: Bool = false, merged: Bool = false, requestedReviewers: [User] = []
  ) {
    self.number = number
    title = "PR \(number)"
    self.state = state
    self.draft = draft
    user = author.map { User(login: $0) }
    self.requestedReviewers = requestedReviewers
    pullRequest = merged ? ["merged_at": "2026-11-18T00:00:00Z"] : [:]
  }
}

private struct Page: Encodable {
  let items: [Item]
  let totalCount: Int
  let incompleteResults: Bool

  enum CodingKeys: String, CodingKey {
    case items
    case totalCount = "total_count"
    case incompleteResults = "incomplete_results"
  }
}

extension HTTPResponse {
  fileprivate static var viewer: Self { .json(#"{"login":"my-user"}"#) }

  fileprivate static func json(
    _ body: String, status: Int = 200, headers: HTTPHeaders = [:]
  ) -> Self {
    .init(statusCode: status, headers: headers, body: Data(body.utf8))
  }

  fileprivate static func page(
    _ items: [Item], total: Int, link: String? = nil, incomplete: Bool = false
  ) throws -> Self {
    var headers = HTTPHeaders()
    headers.link = link
    let body = try JSONEncoder().encode(
      Page(items: items, totalCount: total, incompleteResults: incomplete))
    return .init(statusCode: 200, headers: headers, body: body)
  }
}

private actor RESTStub: GitHubRestClient {
  enum Error: Swift.Error {
    case unexpectedRequest
  }

  private var responses: [Result<HTTPResponse, any Swift.Error>]
  private(set) var requests: [HTTPRequest] = []

  init(_ responses: [Result<HTTPResponse, any Swift.Error>]) {
    self.responses = responses
  }

  func get(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse {
    requests.append(HTTPRequest(url: url, method: .get, headers: headers, body: body))
    guard !responses.isEmpty else { throw Error.unexpectedRequest }
    return try responses.removeFirst().get()
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw Error.unexpectedRequest
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw Error.unexpectedRequest
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw Error.unexpectedRequest
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw Error.unexpectedRequest
  }
}
