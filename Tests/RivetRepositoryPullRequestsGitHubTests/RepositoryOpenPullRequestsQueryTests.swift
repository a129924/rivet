import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetRepositoryPullRequestsGitHub
import Testing

@Suite("GitHub repository open pull requests query")
struct RepositoryOpenPullRequestsQueryTests {
  @Test
  func readsOnePageThroughThePackageEntryPoint() async throws {
    let rest = ScriptedREST(responses: [
      response(#"[{"number":17,"title":" First PR ","state":"open","draft":true}]"#)
    ])
    let query = GitHubRepositoryOpenPullRequestsQuery(rest: rest)

    let summaries = try await query.fetch(owner: "Owner", repository: "Repo").get()

    #expect(summaries.map(\.number) == [17])
    #expect(summaries.map(\.title) == [" First PR "])
    try await expectRequests(rest, pages: [1])
  }

  @Test
  func followsNamedAndProvenNumericLinksWithOriginalRequests() async throws {
    let rest = ScriptedREST(responses: [
      response(
        """
        [
          {"number":9,"title":"Draft","state":"open","draft":true,"user":{"login":"other"},
           "base":{"repo":{"id":42,"full_name":"owner/REPO"}}},
          {"number":1,"title":"Other author","state":"open","user":{"login":"another"}}
        ]
        """,
        link:
          #"<https://api.github.com:443/repos/owner/REPO/pulls?page=2&per_page=100>; title="a, b; \"c\""; REL="alternate NeXt""#
      ),
      response(
        "[]",
        link:
          #"<https://api.github.com/repositories/42/pulls?per_page=100&page=3&state=open>; rel=next"#
      ),
      response(
        #"[{"number":9,"title":"Repeated","state":"open","base":{"repo":{"id":42}}}]"#,
        link: #"</repos/Owner/Repo/pulls?note=a,b>; rel="prev"; title="not; rel=next""#),
    ])

    let result = try await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo").get()

    #expect(result.map(\.number) == [9, 1, 9])
    #expect(result.map(\.title) == ["Draft", "Other author", "Repeated"])
    try await expectRequests(rest, pages: [1, 2, 3])
  }

  @Test
  func returnsAnEmptyListAsSuccess() async throws {
    let rest = ScriptedREST(responses: [response("[]")])

    let result = try await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo").get()

    #expect(result.isEmpty)
    try await expectRequests(rest, pages: [1])
  }

  @Test(arguments: [("invalid/owner", "Repo"), ("Owner", "%52epo"), ("Owner", "..")])
  func rejectsInvalidRepositoriesBeforeSending(owner: String, repository: String) async {
    let rest = ScriptedREST(responses: [])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: owner, repository: repository)

    #expect(result == .failure(.invalidRepository))
    #expect(await rest.requests.isEmpty)
  }

  @Test(arguments: [
    "https://other.example/repos/Owner/Repo/pulls?per_page=100&page=2",
    "http://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2",
    "https://api.github.com:444/repos/Owner/Repo/pulls?per_page=100&page=2",
    "https://user@api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2#fragment",
    "/repos/Owner/Repo/pulls?per_page=100&page=2",
    "https://api.github.com/repos/Other/Repo/pulls?per_page=100&page=2",
    "https://api.github.com/repos/Owner/Else/pulls?per_page=100&page=2",
    "https://api.github.com/repos/%4Fwner/Repo/pulls?per_page=100&page=2",
    "https://api.github.com/repos/Owner/Repo/pulls/2?per_page=100&page=2",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=50&page=2",
    "https://api.github.com/repos/Owner/Repo/pulls?page=2",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2&state=closed",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2&sort=updated",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2&page=2",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2&per_page=100",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2&state=open&state=open",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=0",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=1",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=3",
    "https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=9223372036854775808",
    "https://api.github.com/repositories/43/pulls?per_page=100&page=2",
  ])
  func refusesOutOfScopeAndNonconsecutiveLinks(_ target: String) async throws {
    let rest = ScriptedREST(responses: [
      response(provenRepositoryPage, link: "<\(target)>; rel=next")
    ])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(result == .failure(.invalidPagination))
    try await expectRequests(rest, pages: [1])
  }

  @Test(arguments: [
    "",
    " \t",
    "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2; rel=next",
    #"<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; title="unterminated"#,
    "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>",
    "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel=",
    "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel=next; rel=prev",
    #"<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel="next NEXT""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel=next; anchor="/some/path""#,
    "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel=next, </other>; rel=NEXT",
    "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel=prev,",
  ])
  func rejectsMalformedAndAmbiguousLinkHeaders(_ link: String) async throws {
    let rest = ScriptedREST(responses: [response(provenRepositoryPage, link: link)])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(result == .failure(.invalidPagination))
    try await expectRequests(rest, pages: [1])
  }

  @Test(arguments: [
    "[]",
    #"[{"number":1,"title":"PR","state":"open","base":{"repo":{"id":42}}}]"#,
    #"[{"number":1,"title":"PR","state":"open","base":{"repo":{"full_name":"Owner/Repo"}}}]"#,
  ])
  func requiresRepositoryNameAndIDInOneItemToProveTheAlias(_ page: String) async throws {
    let rest = ScriptedREST(responses: [
      response(
        page, link: "<https://api.github.com/repositories/42/pulls?per_page=100&page=2>; rel=next")
    ])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(result == .failure(.invalidPagination))
    try await expectRequests(rest, pages: [1])
  }

  @Test(arguments: [
    #"{"id":43,"full_name":"Owner/Repo"}"#,
    #"{"id":43}"#,
    #"{"id":0}"#,
    #"{"full_name":"Other/Repo"}"#,
    #"{"id":"42","full_name":"Owner/Repo"}"#,
    #"{"id":42,"full_name":true}"#,
  ])
  func rejectsInvalidAndContradictoryRepositoryEvidence(_ repoJSON: String) async throws {
    let rest = ScriptedREST(responses: [
      response(provenRepositoryPage, link: nextNamedLink),
      response(#"[{"number":2,"title":"PR","state":"open","base":{"repo":\#(repoJSON)}}]"#),
    ])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(result == .failure(.invalidResponse))
    try await expectRequests(rest, pages: [1, 2])
  }

  @Test(arguments: [
    "not JSON",
    "{}",
    #"[{"number":0,"title":"PR","state":"open"}]"#,
    #"[{"number":1,"state":"open"}]"#,
    #"[{"number":1,"title":42,"state":"open"}]"#,
    #"[{"number":1,"title":"PR","state":"closed"}]"#,
  ])
  func discardsAllResultsAfterInvalidLaterContent(_ body: String) async throws {
    let rest = ScriptedREST(responses: [
      response(provenRepositoryPage, link: nextNamedLink), response(body),
    ])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(result == .failure(.invalidResponse))
    try await expectRequests(rest, pages: [1, 2])
  }

  @Test(arguments: [201, 304, 404, 500])
  func discardsAllResultsAfterNonSuccessHTTPResponse(_ status: Int) async throws {
    let rest = ScriptedREST(responses: [
      response(provenRepositoryPage, link: nextNamedLink), response("[]", status: status),
    ])

    let result = await GitHubRepositoryOpenPullRequestsQuery(rest: rest)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(result == .failure(.requestFailed))
    try await expectRequests(rest, pages: [1, 2])
  }

  @Test
  func classifiesTransportErrorsAndCancellation() async throws {
    let failed = ScriptedREST(responses: [response(provenRepositoryPage, link: nextNamedLink)])
    let cancelled = ScriptedREST(responses: [], failure: CancellationError())

    let failedResult = await GitHubRepositoryOpenPullRequestsQuery(rest: failed)
      .fetch(owner: "Owner", repository: "Repo")
    let cancelledResult = await GitHubRepositoryOpenPullRequestsQuery(rest: cancelled)
      .fetch(owner: "Owner", repository: "Repo")

    #expect(failedResult == .failure(.requestFailed))
    #expect(cancelledResult == .failure(.cancelled))
    try await expectRequests(failed, pages: [1, 2])
    try await expectRequests(cancelled, pages: [1])
  }

  @Test
  func cancelledTaskSendsNoRequests() async {
    let rest = ScriptedREST(responses: [response("[]")])
    let query = GitHubRepositoryOpenPullRequestsQuery(rest: rest)
    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await query.fetch(owner: "Owner", repository: "Repo")
    }.value

    #expect(result == .failure(.cancelled))
    #expect(await rest.requests.isEmpty)
  }

  @Test
  func ignoresLateSuccessAfterCancellationWithoutRequestingAnotherPage() async throws {
    let rest = ScriptedREST(
      responses: [response(provenRepositoryPage, link: nextNamedLink)],
      suspendFirstRequest: true)
    let query = GitHubRepositoryOpenPullRequestsQuery(rest: rest)
    let task = Task { await query.fetch(owner: "Owner", repository: "Repo") }

    await rest.waitForSuspendedRequest()
    task.cancel()
    await rest.releaseSuspendedRequest()

    #expect(await task.value == .failure(.cancelled))
    try await expectRequests(rest, pages: [1])
  }

  private func expectRequests(_ rest: ScriptedREST, pages: [Int]) async throws {
    let requests = await rest.requests
    let headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    #expect(
      requests.map(\.url.value.absoluteString)
        == pages.map {
          "https://api.github.com/repos/Owner/Repo/pulls?state=open&per_page=100&page=\($0)"
        })
    for request in requests {
      #expect(request.method == .get)
      #expect(request.headers == headers)
      #expect(request.body == nil)
    }
  }
}

private let provenRepositoryPage =
  #"[{"number":1,"title":"PR","state":"open","base":{"repo":{"id":42,"full_name":"Owner/Repo"}}}]"#
private let nextNamedLink =
  "<https://api.github.com/repos/Owner/Repo/pulls?per_page=100&page=2>; rel=next"

private func response(_ body: String, status: Int = 200, link: String? = nil) -> HTTPResponse {
  var headers = HTTPHeaders()
  headers.link = link
  return HTTPResponse(statusCode: status, headers: headers, body: Data(body.utf8))
}

private actor ScriptedREST: GitHubRestClient {
  private enum StubError: Error {
    case unexpectedCall
  }

  private let responses: [HTTPResponse]
  private let failure: any Error
  private let suspendFirstRequest: Bool
  private var waitingForSuspension: CheckedContinuation<Void, Never>?
  private var suspendedRequest: CheckedContinuation<Void, Never>?
  private(set) var requests: [HTTPRequest] = []

  init(
    responses: [HTTPResponse], failure: (any Error)? = nil, suspendFirstRequest: Bool = false
  ) {
    self.responses = responses
    self.failure = failure ?? StubError.unexpectedCall
    self.suspendFirstRequest = suspendFirstRequest
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let index = requests.count
    requests.append(request)
    if suspendFirstRequest && index == 0 {
      await withCheckedContinuation {
        suspendedRequest = $0
        waitingForSuspension?.resume()
        waitingForSuspension = nil
      }
    }
    guard index < responses.count else { throw failure }
    return responses[index]
  }

  func waitForSuspendedRequest() async {
    if suspendedRequest == nil {
      await withCheckedContinuation { waitingForSuspension = $0 }
    }
  }

  func releaseSuspendedRequest() {
    suspendedRequest?.resume()
    suspendedRequest = nil
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw StubError.unexpectedCall
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw StubError.unexpectedCall
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw StubError.unexpectedCall
  }
}
