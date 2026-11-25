import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import Testing

@testable import RivetPRReaderGitHub

@Suite("GitHub pull request changed files source")
struct GitHubPullRequestChangedFilesSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: 42)

  @Test
  func emptyListUsesTheChangedFilesEndpoint() async throws {
    let client = ChangedFilesRESTStub([.success(response("[]"))])
    let source = GitHubPullRequestChangedFilesSource(client: client)

    #expect(await source.fetchChangedFiles(for: id) == .success([]))
    let requests = await client.requests
    try #require(requests.count == 1)
    #expect(requests[0].url.value.absoluteString == filesURL(page: 1))
    #expect(requests[0].method == .get)
    #expect(requests[0].body == nil)
    #expect(
      requests[0].headers
        == HTTPHeaders([
          "Accept": "application/vnd.github+json",
          "User-Agent": "Rivet",
          "X-GitHub-Api-Version": "2026-03-10",
        ]))
  }

  @Test
  func projectsAllSupportedStatusesAndPreservesOptionalFields() async throws {
    let payload = #"""
      [
        {"filename":" 雪.txt ","status":"renamed","additions":3,"deletions":2,"previous_filename":"old.txt","patch":"+snow\n"},
        {"filename":"added","status":"added","additions":1,"deletions":0,"sha":"shared"},
        {"filename":"removed","status":"removed","additions":0,"deletions":2,"patch":null,"sha":"shared"},
        {"filename":"modified","status":"modified","additions":1,"deletions":1,"previous_filename":null},
        {"filename":"copied","status":"copied","additions":0,"deletions":0,"patch":""}
      ]
      """#
    let client = ChangedFilesRESTStub([.success(response(payload))])
    let files = try await GitHubPullRequestChangedFilesSource(client: client)
      .fetchChangedFiles(for: id).get()

    #expect(files.map(\.path) == [" 雪.txt ", "added", "removed", "modified", "copied"])
    #expect(files.map(\.reference.value) == files.map(\.path))
    #expect(files.map(\.change) == [.renamed, .added, .removed, .modified, .copied])
    #expect(files.map(\.additions) == [3, 1, 0, 1, 0])
    #expect(files.map(\.deletions) == [2, 0, 2, 1, 0])
    #expect(files.map(\.previousPath) == ["old.txt", nil, nil, nil, nil])
    #expect(files.map(\.patch) == ["+snow\n", nil, nil, nil, ""])
  }

  @Test
  func readsCanonicalPagesInOrderWithoutGuessingAnExtraPage() async throws {
    let next =
      "<https://api.github.com/repos/owner/repo/pulls/42/files?per_page=100&page=2>; rel=next"
    let client = ChangedFilesRESTStub([
      .success(page(1, link: next)),
      .success(page(2, link: "<\(filesURL(page: 1))>; rel=\"prev\"")),
    ])
    let files = try await GitHubPullRequestChangedFilesSource(client: client)
      .fetchChangedFiles(for: id).get()

    #expect(files.map(\.path) == (0..<200).map { "file-\($0)" })
    let requests = await client.requests
    #expect(requests.map(\.url.value.absoluteString) == [filesURL(page: 1), filesURL(page: 2)])
    #expect(requests.allSatisfy { $0.method == .get && $0.body == nil })
    #expect(requests.map(\.headers) == Array(repeating: requests.first?.headers, count: 2))
  }

  @Test
  func verifiesNumericNextOnceAndRebuildsCanonicalRequests() async throws {
    let firstLinks =
      "<\(numericURL(page: 2))>; title=\"a, b; c\"; rel=\"next\", <\(numericURL(page: 3))>; rel=\"last\""
    let secondLinks = "<\(numericURL(page: 3))>; REL=\"next last\""
    let client = ChangedFilesRESTStub([
      .success(page(1, link: firstLinks)),
      .success(detail()),
      .success(page(2, link: secondLinks)),
      .success(page(3, count: 1, link: "<\(numericURL(page: 3))>; rel=\"last\"")),
    ])
    let files = try await GitHubPullRequestChangedFilesSource(client: client)
      .fetchChangedFiles(for: id).get()

    #expect(files.map(\.path) == (0..<201).map { "file-\($0)" })
    let requests = await client.requests
    #expect(
      requests.map(\.url.value.absoluteString)
        == [
          filesURL(page: 1), "https://api.github.com/repos/Owner/Repo/pulls/42", filesURL(page: 2),
          filesURL(page: 3),
        ])
    #expect(Set(requests.compactMap(\.headers.accept)) == ["application/vnd.github+json"])
    #expect(requests.allSatisfy { $0.method == .get && $0.body == nil })
  }

  @Test
  func terminalNumericLastDoesNotFetchDetails() async throws {
    let client = ChangedFilesRESTStub([
      .success(page(1, link: "<\(numericURL(page: 1))>; rel=\"last\""))
    ])
    let files = try await GitHubPullRequestChangedFilesSource(client: client)
      .fetchChangedFiles(for: id).get()
    #expect(files.count == 100)
    #expect(await client.requests.count == 1)
  }

  @Test(arguments: [
    "", "not a link",
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="next","#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="next"; rel="last""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=1&per_page=100>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=3&per_page=100>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Other/pulls/42/files?page=2&per_page=100>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/43/files?page=2&per_page=100>; rel="next""#,
    #"<https://api.github.com/repositories/55/pulls/43/files?page=2&per_page=100>; rel="next""#,
    #"<https://other.example/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="next""#,
    #"<http://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="next""#,
    #"<https://u@api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="next""#,
    #"<https://api.github.com:444/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100#x>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&page=2&per_page=100>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=10>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100&unknown=1>; rel="next""#,
    #"<https://api.github.com/repos/Owner/%52epo/pulls/42/files?page=2&per_page=100>; rel="next""#,
    #"<https://api.github.com/repos/Owner/Repo/pulls/42/files?page=2&per_page=100>; rel="last""#,
  ])
  func rejectsInvalidLinksBeforeAnyContinuation(_ link: String) async {
    let client = ChangedFilesRESTStub([.success(page(1, link: link))])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 1)
  }

  @Test
  func rejectsDuplicateAndContradictoryLastAndNext() async {
    let next = "<\(filesURL(page: 2))>; rel=next"
    let last = "<\(filesURL(page: 1))>; rel=last"
    for links in ["\(next), \(next)", "\(last), \(last)", "\(next), \(last)"] {
      let client = ChangedFilesRESTStub([.success(page(1, link: links))])
      let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
        for: id)
      #expect(result == .failure(.unavailable))
      #expect(await client.requests.count == 1)
    }

    let client = ChangedFilesRESTStub([
      .success(page(1, link: next)), .success(page(2, link: last)),
    ])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 2)
  }

  @Test
  func failsWhenThePageLengthCannotProveCompleteness() async {
    let next = "<\(filesURL(page: 2))>; rel=next"
    let scenarios = [
      [page(1, count: 99, link: next)],
      [page(1, count: 101)],
      [page(1, link: next), response("[]")],
    ]
    for pages in scenarios {
      let client = ChangedFilesRESTStub(pages.map { .success($0) })
      let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
        for: id)
      #expect(result == .failure(.unavailable))
      #expect(await client.requests.count == pages.count)
    }
  }

  @Test(arguments: [
    #"{"number":41,"base":{"repo":{"id":55,"full_name":"Owner/Repo"}}}"#,
    #"{"number":42,"base":{"repo":{"id":56,"full_name":"Owner/Repo"}}}"#,
    #"{"number":42,"base":{"repo":{"id":55,"full_name":"Owner/Other"}}}"#,
    #"{"base":{"repo":{"id":55,"full_name":"Owner/Repo"}}}"#,
    #"{"number":42,"base":{"repo":null}}"#,
    "not JSON",
  ])
  func rejectsAnUnverifiedNumericRepository(_ details: String) async {
    let link = "<\(numericURL(page: 2))>; rel=next"
    let client = ChangedFilesRESTStub([.success(page(1, link: link)), .success(response(details))])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.unavailable))
    let requests = await client.requests
    #expect(
      requests.map(\.url.value.path) == [
        "/repos/Owner/Repo/pulls/42/files", "/repos/Owner/Repo/pulls/42",
      ])
  }

  @Test
  func rejectsAnIDChangeAfterTheFirstVerification() async {
    let first = "<\(numericURL(page: 2))>; rel=next"
    let changed = "<\(numericURL(page: 3, repositoryID: 56))>; rel=next"
    let client = ChangedFilesRESTStub([
      .success(page(1, link: first)), .success(detail()), .success(page(2, link: changed)),
    ])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.count == 3)
  }

  @Test(arguments: [2999, 3000])
  func appliesTheFileLimitEvenWithoutNext(_ total: Int) async throws {
    let pages = (1...30).map { pageNumber in
      page(
        pageNumber, count: pageNumber == 30 ? total - 2900 : 100,
        link: pageNumber == 30 ? nil : "<\(filesURL(page: pageNumber + 1))>; rel=next")
    }
    let client = ChangedFilesRESTStub(pages.map { .success($0) })
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    if total == 2999 {
      let files = try result.get()
      #expect(files.map(\.path) == (0..<total).map { "file-\($0)" })
    } else {
      #expect(result == .failure(.unavailable))
    }
    #expect(await client.requests.count == 30)
  }

  @Test
  func fileLimitPrecedesProjectionAndStopsEvenWithNext() async {
    let firstPages = (1..<30).map { page($0, link: "<\(filesURL(page: $0 + 1))>; rel=next") }
    let malformed = "[" + Array(repeating: "null", count: 100).joined(separator: ",") + "]"
    let finalPages = [
      page(30, link: "<\(filesURL(page: 31))>; rel=next"),
      response(malformed),
    ]
    for finalPage in finalPages {
      let client = ChangedFilesRESTStub((firstPages + [finalPage]).map { .success($0) })
      let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
        for: id)
      #expect(result == .failure(.unavailable))
      #expect(await client.requests.count == 30)
    }
  }

  @Test(arguments: [
    "not JSON", "{}", "null", "[null]",
    #"[{"filename":"","status":"modified","additions":0,"deletions":0}]"#,
    #"[{"filename":"x","status":"changed","additions":0,"deletions":0}]"#,
    #"[{"filename":"x","status":"unchanged","additions":0,"deletions":0}]"#,
    #"[{"filename":"x","status":"future","additions":0,"deletions":0}]"#,
    #"[{"filename":"x","status":"added","deletions":0}]"#,
    #"[{"filename":"x","status":"added","additions":-1,"deletions":0}]"#,
    #"[{"filename":"x","status":"added","additions":1,"deletions":0.5}]"#,
    #"[{"filename":"x","status":"added","additions":9223372036854775808,"deletions":0}]"#,
    #"[{"filename":"x","status":"added","additions":true,"deletions":0}]"#,
    #"[{"filename":"x","status":"added","additions":1,"deletions":0,"patch":false}]"#,
    #"[{"filename":"x","status":"renamed","additions":1,"deletions":0,"previous_filename":5}]"#,
  ])
  func failsForBodiesThatCannotBeRepresented(_ body: String) async {
    let client = ChangedFilesRESTStub([.success(response(body))])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.contentNotRepresentable))
  }

  @Test
  func duplicatePathAcrossPagesFailsTheWholeRead() async {
    let client = ChangedFilesRESTStub([
      .success(page(1, link: "<\(filesURL(page: 2))>; rel=next")),
      .success(page(1, count: 1)),
    ])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.contentNotRepresentable))
  }

  @Test
  func respectsSwiftStringEqualityForFileReferences() async {
    let payload = #"""
      [
        {"filename":"\u00e9","status":"added","additions":0,"deletions":0},
        {"filename":"e\u0301","status":"added","additions":0,"deletions":0}
      ]
      """#
    let client = ChangedFilesRESTStub([.success(response(payload))])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure(.contentNotRepresentable))
  }

  @Test(arguments: [401, 403, 404, 422, 429, 503])
  func classifiesHTTPFailuresOnContinuation(_ status: Int) async {
    let client = ChangedFilesRESTStub([
      .success(page(1, link: "<\(filesURL(page: 2))>; rel=next")),
      .success(response("not JSON", status: status)),
    ])
    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)
    #expect(result == .failure([401, 403, 404].contains(status) ? .notReadable : .unavailable))
    #expect(await client.requests.count == 2)
  }

  @Test
  func usesSharedClassificationForForbiddenResponses() async {
    let limited = HTTPHeaders(["X-RateLimit-Remaining": "0"])
    for (body, expected) in [
      ("{}", PRReaderFailure.unavailable),
      (#"{"message":"Resource not accessible by integration."}"#, .notReadable),
    ] {
      let client = ChangedFilesRESTStub([.success(response(body, status: 403, headers: limited))])
      let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
        for: id)
      #expect(result == .failure(expected))
    }
  }

  @Test
  func mapsClientFailuresBeforeAndAfterFirstPage() async {
    let start = page(1, link: "<\(filesURL(page: 2))>; rel=next")
    let aliasStart = page(1, link: "<\(numericURL(page: 2))>; rel=next")
    for (responses, expected): ([Result<HTTPResponse, any Error>], PRReaderFailure) in [
      ([.failure(GitHubHTTPClientError.invalidRequest)], .notReadable),
      ([.success(start), .failure(GitHubHTTPClientError.invalidRequest)], .unavailable),
      ([.success(aliasStart), .failure(GitHubHTTPClientError.invalidRequest)], .unavailable),
      (
        [.success(aliasStart), .failure(GitHubHTTPClientError.authenticationRequired)], .notReadable
      ),
      ([.success(start), .failure(URLError(.timedOut))], .unavailable),
    ] {
      let client = ChangedFilesRESTStub(responses)
      let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
        for: id)
      #expect(result == .failure(expected))
      #expect(await client.requests.count == responses.count)
    }
  }

  @Test(arguments: [401, 403, 404])
  func retainsUnreadableDetailsResponseForChangedFiles(_ status: Int) async {
    let link = "<\(numericURL(page: 2))>; rel=next"
    let client = ChangedFilesRESTStub([
      .success(page(1, link: link)),
      .success(response("{}", status: status)),
    ])

    let result = await GitHubPullRequestChangedFilesSource(client: client).fetchChangedFiles(
      for: id)

    #expect(result == .failure(.notReadable))
    let requests = await client.requests
    #expect(
      requests.map(\.url.value.absoluteString) == [
        filesURL(page: 1), "https://api.github.com/repos/Owner/Repo/pulls/42",
      ])
  }

  @Test
  func invalidIdentityAndPrecancelledReadNeverCallREST() async {
    let client = ChangedFilesRESTStub([])
    let source = GitHubPullRequestChangedFilesSource(client: client)
    let invalid = ReaderPullRequestID(owner: "Owner", repository: "..", number: 42)
    #expect(await source.fetchChangedFiles(for: invalid) == .failure(.notReadable))
    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await source.fetchChangedFiles(for: id)
    }.value
    #expect(result == .failure(.unavailable))
    #expect(await client.requests.isEmpty)
  }

  @Test
  func cancellationDiscardsResponsesAndTakesPrecedenceOverAuthFailure() async {
    let start = page(1, link: "<\(filesURL(page: 2))>; rel=next")
    let aliasStart = page(1, link: "<\(numericURL(page: 2))>; rel=next")
    let cases: [[Result<HTTPResponse, any Error>]] = [
      [.success(start)],
      [.success(start), .success(page(2, count: 1))],
      [.success(aliasStart), .failure(GitHubHTTPClientError.authenticationRequired)],
    ]
    for responses in cases {
      let client = ChangedFilesRESTStub(responses, cancelOnRequest: responses.count)
      let source = GitHubPullRequestChangedFilesSource(client: client)
      let result = await Task { await source.fetchChangedFiles(for: id) }.value
      #expect(result == .failure(.unavailable))
      #expect(await client.requests.count == responses.count)
    }
  }

  private func page(_ number: Int, count: Int = 100, link: String? = nil) -> HTTPResponse {
    let offset = (number - 1) * 100
    let entries = (offset..<(offset + count)).map {
      #"{"filename":"file-\#($0)","status":"modified","additions":1,"deletions":0}"#
    }
    var headers = HTTPHeaders()
    headers.link = link
    return response("[\(entries.joined(separator: ","))]", headers: headers)
  }

  private func numericURL(page: Int, repositoryID: Int = 55) -> String {
    "https://api.github.com/repositories/\(repositoryID)/pulls/42/files?page=\(page)&per_page=100"
  }

  private func detail() -> HTTPResponse {
    response(#"{"number":42,"base":{"repo":{"id":55,"full_name":"OWNER/repo"}}}"#)
  }

  private func response(
    _ body: String, status: Int = 200, headers: HTTPHeaders = [:]
  ) -> HTTPResponse {
    HTTPResponse(statusCode: status, headers: headers, body: Data(body.utf8))
  }

  private func filesURL(page: Int) -> String {
    "https://api.github.com/repos/Owner/Repo/pulls/42/files?page=\(page)&per_page=100"
  }
}

private actor ChangedFilesRESTStub: GitHubRestClient {
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
