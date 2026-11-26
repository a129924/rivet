import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import RivetPRReaderGitHub
import Testing

private typealias RESTResponse = RivetHTTPClient.HTTPResponse

@Suite("GitHub inline review content source")
struct GitHubInlineReviewContentSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: 42)

  @Test
  func acceptsEmptyGraphQLAsCompleteWithoutReadingREST() async throws {
    let script = InlineReviewScript([
      .graphQL(threadPage([])),
      .rest(restPage("[]")),
    ])

    #expect(await read(script) == .success(.graphQLThreads([])))
    let requests = await script.requests
    #expect(requests.count == 1)
    try checkOuterRequest(try #require(requests.first?.graphQL), after: nil)
  }

  @Test
  func preservesGraphQLPagesThreadsAndCommentsWithoutReadingREST() async throws {
    let script = InlineReviewScript([
      .graphQL(
        threadPage(
          [reviewThread("one", comments: [reviewComment("shared")], after: "more-comments")],
          after: "more-threads")),
      .graphQL(commentPage("one", [reviewComment("reply", replyTo: "shared")])),
      .graphQL(
        threadPage([
          reviewThread("two", comments: [reviewComment("graph-only")], outdated: true)
        ])),
      .rest(restPage(sharedComment)),
    ])

    let result = try await read(script).get()
    guard case .graphQLThreads(let threads) = result else {
      Issue.record("Expected GraphQL threads")
      return
    }
    #expect(threads.map(\.id) == ["one", "two"])
    #expect(threads.map(\.path) == ["Sources/A.swift", "Sources/A.swift"])
    #expect(threads.map(\.subject) == [.line, .line])
    #expect(threads.map(\.line) == [12, 12])
    #expect(threads.map(\.isResolved) == [true, false])
    #expect(threads.map(\.isOutdated) == [false, true])
    #expect(threads.map { $0.comments.map(\.id) } == [["shared", "reply"], ["graph-only"]])
    #expect(threads.first?.comments.map(\.body) == [reviewMarkdown, reviewMarkdown])
    #expect(threads.first?.comments.map(\.replyToID) == [nil, "shared"])

    let requests = await script.requests
    let graphQL = requests.compactMap(\.graphQL)
    try #require(graphQL.count == 3)
    #expect(requests.count == 3)
    try checkOuterRequest(graphQL[0], after: nil)
    let continuation = try payload(graphQL[1])
    #expect(continuation["operationName"] as? String == "ReviewThreadComments")
    let variables = try #require(continuation["variables"] as? [String: Any])
    #expect(variables["threadID"] as? String == "one")
    #expect(variables["after"] as? String == "more-comments")
    try checkOuterRequest(graphQL[2], after: "more-threads")
  }

  @Test
  func replacesPartialGraphQLWithCompleteRESTForTheSamePR() async throws {
    let script = InlineReviewScript([
      .graphQL(
        threadPage(
          [
            reviewThread("one", comments: [reviewComment("shared"), reviewComment("graph-only")])
          ], after: "more-threads")),
      .graphQLFailure(.executionFailed),
      .rest(restPage(sharedComment, next: 2)),
      .rest(restPage(restReply)),
    ])

    let result = try await read(script).get()
    guard case .restComments(let comments) = result else {
      Issue.record("Expected REST comments")
      return
    }
    #expect(comments.map(\.id) == [9_007_199_254_740_993, 7])
    #expect(comments.map(\.nodeID) == ["shared", "rest-only"])
    #expect(comments.map(\.sourcePage) == [1, 2])
    #expect(comments.map(\.line) == [12, nil])
    #expect(comments.map(\.side) == ["RIGHT", nil])
    #expect(comments.map(\.inReplyToID) == [nil, 9_007_199_254_740_993])
    #expect(comments.map(\.body) == [reviewMarkdown, "REST reply"])
    #expect(comments.map(\.path) == ["Sources/A.swift", "Sources/A.swift"])

    let requests = await script.requests
    try #require(requests.count == 4)
    try checkOuterRequest(try #require(requests[0].graphQL), after: nil)
    try checkOuterRequest(try #require(requests[1].graphQL), after: "more-threads")
    #expect(requests.suffix(2).compactMap(\.restURL) == [restURL(1), restURL(2)])
  }

  @Test
  func acceptsAnEmptyRESTFallback() async {
    let script = InlineReviewScript([.graphQLFailure(.executionFailed), .rest(restPage("[]"))])
    #expect(await read(script) == .success(.restComments([])))
    let requests = await script.requests
    #expect(requests.count == 2)
    #expect(requests.first?.graphQL != nil)
    #expect(requests.last?.restURL == restURL(1))
  }

  @Test
  func forwardsTerminalGraphQLFailuresWithoutReadingREST() async {
    let cases: [(InlineReviewScript.Reply, PRReaderFailure)] = [
      (.graphQLFailure(.authenticationRequired), .notReadable),
      (
        .graphQL(threadPage([reviewThread("", comments: [reviewComment("one")])])),
        .contentNotRepresentable
      ),
    ]
    for (reply, failure) in cases {
      let script = InlineReviewScript([reply, .rest(restPage("[]"))])
      #expect(await read(script) == .failure(failure))
      let requests = await script.requests
      #expect(requests.count == 1)
      #expect(requests.first?.graphQL != nil)
    }
  }

  @Test
  func forwardsEveryRESTFailureAndDiscardsPartialREST() async {
    let cases: [(RESTResponse, PRReaderFailure)] = [
      (restPage("{}", status: 404), .notReadable),
      (restPage("{}", status: 503), .unavailable),
      (restPage("{}"), .contentNotRepresentable),
    ]
    for (response, failure) in cases {
      let script = InlineReviewScript([
        .graphQLFailure(.executionFailed),
        .rest(restPage(sharedComment, next: 2)),
        .rest(response),
      ])
      #expect(await read(script) == .failure(failure))
      let requests = await script.requests
      #expect(requests.count == 3)
      #expect(requests.first?.graphQL != nil)
      #expect(requests.compactMap(\.restURL) == [restURL(1), restURL(2)])
    }
  }

  @Test
  func cancellationBeforeReadingMakesNoRequest() async {
    let script = InlineReviewScript([.graphQL(threadPage([])), .rest(restPage("[]"))])
    let result = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await read(script)
    }.value
    #expect(result == .failure(.unavailable))
    #expect(await script.requests.isEmpty)
  }

  @Test
  func cancellationDuringGraphQLRejectsLateRepliesWithoutReadingREST() async {
    let replies: [InlineReviewScript.Reply] = [
      .graphQL(threadPage([reviewThread("late", comments: [reviewComment("late")])])),
      .graphQLFailure(.authenticationRequired),
    ]
    for reply in replies {
      let script = InlineReviewScript([reply, .rest(restPage("[]"))], pauseOn: 1)
      #expect(await readAndCancel(script) == .failure(.unavailable))
      let requests = await script.requests
      #expect(requests.count == 1)
      #expect(requests.first?.graphQL != nil)
    }
  }

  @Test
  func cancellationDuringRESTRejectsLateRepliesAndSkipsRemainingPages() async {
    let replies = [restPage(restReply, next: 3), restPage("{}", status: 404)]
    for reply in replies {
      let script = InlineReviewScript(
        [
          .graphQLFailure(.executionFailed),
          .rest(restPage(sharedComment, next: 2)),
          .rest(reply),
          .rest(restPage("[]")),
        ], pauseOn: 3)
      #expect(await readAndCancel(script) == .failure(.unavailable))
      let requests = await script.requests
      #expect(requests.count == 3)
      #expect(requests.first?.graphQL != nil)
      #expect(requests.compactMap(\.restURL) == [restURL(1), restURL(2)])
    }
  }

  private func read(
    _ script: InlineReviewScript
  ) async -> Outcome<ReaderInlineReviewContent, PRReaderFailure> {
    await GitHubInlineReviewContentSource(graphql: InlineReviewApolloClient(script), rest: script)
      .fetchInlineReviewContent(for: id)
  }

  private func readAndCancel(
    _ script: InlineReviewScript
  ) async -> Outcome<ReaderInlineReviewContent, PRReaderFailure> {
    let task = Task {
      let result = await read(script)
      await script.finish()
      return result
    }
    let paused = await script.waitForPause()
    #expect(paused)
    task.cancel()
    await script.release()
    return await task.value
  }

  private func checkOuterRequest(_ request: URLRequest, after: String?) throws {
    #expect(request.httpMethod == "POST")
    #expect(request.url?.absoluteString == "https://api.github.com/graphql")
    let body = try payload(request)
    #expect(body["operationName"] as? String == "ReviewThreads")
    let variables = try #require(body["variables"] as? [String: Any])
    #expect(variables["owner"] as? String == id.owner)
    #expect(variables["name"] as? String == id.repository)
    #expect(variables["number"] as? Int == id.number)
    #expect(variables["after"] as? String == after)
  }

  private func payload(_ request: URLRequest) throws -> [String: Any] {
    let body = try #require(request.httpBody)
    return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
  }
}

private let reviewMarkdown = "  **Review**\n> café  "
private let sharedComment = #"""
  [{"id":9007199254740993,"node_id":"shared","path":"Sources/A.swift","line":12,"side":"RIGHT",
    "body":"  **Review**\n> café  "}]
  """#
private let restReply = #"""
  [{"id":7,"node_id":"rest-only","path":"Sources/A.swift","body":"REST reply",
    "in_reply_to_id":9007199254740993,"line":null}]
  """#

private func restURL(_ page: Int) -> String {
  "https://api.github.com/repos/Owner/Repo/pulls/42/comments?page=\(page)&per_page=100"
}

private func restPage(_ body: String, status: Int = 200, next: Int? = nil) -> RESTResponse {
  var headers = HTTPHeaders()
  if let next { headers.link = "<\(restURL(next))>; rel=next" }
  return RESTResponse(statusCode: status, headers: headers, body: Data(body.utf8))
}

private func threadPage(_ threads: [[String: Any]], after: String? = nil) -> String {
  graphQLBody([
    "repository": [
      "__typename": "Repository", "id": "repo", "nameWithOwner": "Owner/Repo",
      "pullRequest": [
        "__typename": "PullRequest", "id": "pr", "number": 42,
        "repository": ["__typename": "Repository", "id": "repo"],
        "reviewThreads": connection(
          threads, after: after, type: "PullRequestReviewThreadConnection"),
      ],
    ]
  ])
}

private func commentPage(_ thread: String, _ comments: [[String: Any]]) -> String {
  graphQLBody([
    "node": [
      "__typename": "PullRequestReviewThread", "id": thread,
      "pullRequest": ["__typename": "PullRequest", "id": "pr"],
      "comments": connection(comments, after: nil, type: "PullRequestReviewCommentConnection"),
    ]
  ])
}

private func reviewThread(
  _ id: String, comments: [[String: Any]], after: String? = nil, outdated: Bool = false
) -> [String: Any] {
  [
    "__typename": "PullRequestReviewThread", "id": id, "path": "Sources/A.swift",
    "subjectType": "LINE", "isResolved": !outdated, "isOutdated": outdated,
    "line": 12, "startLine": NSNull(), "originalLine": NSNull(), "originalStartLine": NSNull(),
    "pullRequest": ["__typename": "PullRequest", "id": "pr"],
    "comments": connection(comments, after: after, type: "PullRequestReviewCommentConnection"),
  ]
}

private func reviewComment(_ id: String, replyTo: String? = nil) -> [String: Any] {
  [
    "__typename": "PullRequestReviewComment", "id": id, "body": reviewMarkdown,
    "author": NSNull(),
    "replyTo": replyTo.map { ["__typename": "PullRequestReviewComment", "id": $0] } as Any?
      ?? NSNull(),
    "pullRequest": ["__typename": "PullRequest", "id": "pr"],
  ]
}

private func connection(_ nodes: [[String: Any]], after: String?, type: String) -> [String: Any] {
  [
    "__typename": type, "nodes": nodes,
    "pageInfo": [
      "__typename": "PageInfo", "hasNextPage": after != nil,
      "endCursor": after as Any? ?? NSNull(),
    ],
  ]
}

private func graphQLBody(_ data: [String: Any]) -> String {
  guard let encoded = try? JSONSerialization.data(withJSONObject: ["data": data]),
    let body = String(bytes: encoded, encoding: .utf8)
  else { preconditionFailure("Invalid GraphQL test data") }
  return body
}

private struct InlineReviewApolloClient: GitHubGraphQLServing {
  private let client: ApolloClient

  init(_ script: InlineReviewScript) {
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    client = ApolloClient(
      networkTransport: RequestChainNetworkTransport(
        urlSession: script, interceptorProvider: DefaultInterceptorProvider.shared,
        store: store, endpointURL: URL(string: "https://api.github.com/graphql")!,
        apqConfig: .init(autoPersistQueries: false)),
      store: store)
  }

  func fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    try await client.fetch(
      query: query, cachePolicy: .networkOnly,
      requestConfiguration: .init(writeResultsToCache: false))
  }

  func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<
    Mutation
  >
  where Mutation.ResponseFormat == SingleResponseFormat {
    throw InlineReviewScript.UnexpectedRequest.call
  }
}

private actor InlineReviewScript: ApolloURLSession, GitHubRestClient {
  enum Reply: Sendable {
    case graphQL(String)
    case graphQLFailure(GitHubGraphQLClientError)
    case rest(RESTResponse)
  }

  enum Request: Sendable {
    case query(URLRequest)
    case get(HTTPURL)

    var graphQL: URLRequest? {
      guard case .query(let request) = self else { return nil }
      return request
    }

    var restURL: String? {
      guard case .get(let url) = self else { return nil }
      return url.value.absoluteString
    }
  }

  enum UnexpectedRequest: Error {
    case call
  }

  private let replies: [Reply]
  private let pauseOn: Int?
  private var paused: CheckedContinuation<Void, Never>?
  private var observer: CheckedContinuation<Bool, Never>?
  private var finished = false
  private(set) var requests: [Request] = []

  init(_ replies: [Reply], pauseOn: Int? = nil) {
    self.replies = replies
    self.pauseOn = pauseOn
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    switch try await reply(to: .query(request)) {
    case .graphQL(let json):
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"])!
      return (InlineReviewChunk(data: Data(json.utf8)), response)
    case .graphQLFailure(let error):
      throw error
    case .rest:
      throw UnexpectedRequest.call
    }
  }

  func executeGet(_ request: HTTPRequest) async throws -> RESTResponse {
    guard case .rest(let response) = try await reply(to: .get(request.url))
    else { throw UnexpectedRequest.call }
    return response
  }

  func executePost(_ request: HTTPRequest) async throws -> RESTResponse {
    throw UnexpectedRequest.call
  }

  func executePut(_ request: HTTPRequest) async throws -> RESTResponse {
    throw UnexpectedRequest.call
  }

  func executePatch(_ request: HTTPRequest) async throws -> RESTResponse {
    throw UnexpectedRequest.call
  }

  private func reply(to request: Request) async throws -> Reply {
    let index = requests.count
    requests.append(request)
    guard replies.indices.contains(index) else { throw UnexpectedRequest.call }
    if requests.count == pauseOn {
      await withCheckedContinuation {
        paused = $0
        observer?.resume(returning: true)
        observer = nil
      }
    }
    return replies[index]
  }

  func waitForPause() async -> Bool {
    if paused != nil { return true }
    if finished { return false }
    return await withCheckedContinuation { observer = $0 }
  }

  func release() {
    paused?.resume()
    paused = nil
  }

  func finish() {
    finished = true
    observer?.resume(returning: false)
    observer = nil
  }
}

private struct InlineReviewChunk: AsyncChunkSequence, AsyncIteratorProtocol {
  var data: Data?

  func makeAsyncIterator() -> Self { self }

  mutating func next() async -> Data? {
    defer { data = nil }
    return data
  }
}
