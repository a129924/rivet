import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader
import RivetPRReaderGitHub
import Testing

@Suite("GitHub GraphQL review threads source")
struct GitHubReviewThreadsSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: 42)

  @Test
  func emptyThreadPageIsSuccessful() async {
    let session = ReviewThreadsSession([.body(outer([]))])
    #expect(await read(session) == .success([]))
    #expect(await session.requests.count == 1)
  }

  @Test
  func readsBothLevelsInSourceOrderAndPreservesFields() async throws {
    let markdown = "  **Review**\n> café  "
    let session = ReviewThreadsSession([
      .body(
        outer(
          [
            thread(
              "thread-1", comments: [comment("one", body: markdown, author: "octocat")],
              commentCursor: "same cursor", subject: "LINE", lines: [11, 9, 21, 19],
              resolved: true),
            thread(
              "thread-2", comments: [comment("three", reply: "not-in-result")],
              commentCursor: "same cursor", outdated: true),
          ], cursor: "same cursor")),
      .body(inner("thread-1", [comment("two", reply: "one")])),
      .body(inner("thread-2", [comment("four", body: "")])),
      .body(outer([thread("thread-3", comments: [comment("five")], subject: "LINE")])),
    ])

    let threads = try await read(session).get()
    #expect(threads.map(\.id) == ["thread-1", "thread-2", "thread-3"])
    #expect(
      threads.map { $0.comments.map(\.id) } == [["one", "two"], ["three", "four"], ["five"]])
    #expect(threads.map(\.subject) == [.line, .file, .line])
    #expect(threads.map(\.line) == [11, nil, nil])
    #expect(threads.map(\.startLine) == [9, nil, nil])
    #expect(threads.map(\.originalLine) == [21, nil, nil])
    #expect(threads.map(\.originalStartLine) == [19, nil, nil])
    #expect(threads.map(\.isResolved) == [true, false, false])
    #expect(threads.map(\.isOutdated) == [false, true, false])
    #expect(threads.map(\.path) == Array(repeating: "Sources/測試.swift", count: 3))
    let first = try #require(threads.first)
    #expect(first.comments.map(\.body) == [markdown, "comment"])
    #expect(first.comments.map(\.author) == ["octocat", nil])
    #expect(first.comments.map(\.replyToID) == [nil, "one"])
    let second = try #require(threads.dropFirst().first)
    #expect(second.comments.map(\.replyToID) == ["not-in-result", nil])
    #expect(second.comments.last?.body == "")

    let requests = await session.requests
    #expect(requests.map(\.httpMethod) == Array(repeating: "POST", count: 4))
    let payloads = try requests.map { request in
      let body = try #require(request.httpBody)
      return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
    #expect(
      payloads.compactMap { $0["operationName"] as? String } == [
        "ReviewThreads", "ReviewThreadComments", "ReviewThreadComments", "ReviewThreads",
      ])
    let variables = try payloads.map { try #require($0["variables"] as? [String: Any]) }
    let initial = try #require(variables.first)
    #expect(initial["owner"] as? String == "Owner")
    #expect(initial["name"] as? String == "Repo")
    #expect(initial["number"] as? Int == 42)
    #expect(initial["after"] == nil)
    #expect(
      variables.dropFirst().compactMap { $0["after"] as? String }
        == Array(repeating: "same cursor", count: 3))
    #expect(variables.compactMap { $0["threadID"] as? String } == ["thread-1", "thread-2"])
  }

  @Test
  func invalidIdentityUsesNoRequests() async {
    let session = ReviewThreadsSession([])
    let number = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: Int.max)
    let name = ReaderPullRequestID(owner: "not/owner", repository: "Repo", number: 42)
    for invalid in [number, name] {
      #expect(await read(session, id: invalid) == .failure(.notReadable))
    }
    #expect(await session.requests.isEmpty)
  }

  @Test
  func detectsWrongOuterOrInnerIdentity() async {
    let initial = outer([thread("thread-1", comments: [comment("one")])], cursor: "next")
    let nested = outer([thread("thread-1", comments: [comment("one")], commentCursor: "next")])
    let cases: [(String, [String])] = [
      ("owner", [outer([], repoName: "Other/Repo")]),
      ("number", [outer([], number: 43)]),
      ("ownership", [outer([], prRepoID: "wrong")]),
      ("other PR page", [initial, outer([], prID: "wrong")]),
      ("other repository page", [initial, outer([], repoID: "wrong", prRepoID: "wrong")]),
      ("thread PR", [outer([thread("thread-1", prID: "wrong")])]),
      ("comment PR", [outer([thread("thread-1", comments: [comment("one", prID: "wrong")])])]),
      ("other thread", [nested, inner("different", [])]),
      ("other node type", [nested, wire(["node": ["__typename": "User"]])]),
      ("missing thread", [nested, wire(["node": NSNull()])]),
      ("inner PR", [nested, inner("thread-1", [], prID: "wrong")]),
      ("inner comment PR", [nested, inner("thread-1", [comment("two", prID: "wrong")])]),
    ]
    for (name, replies) in cases {
      let session = ReviewThreadsSession(replies.map(ReviewThreadsSession.Reply.body))
      #expect(await read(session) == .failure(.unavailable), "\(name)")
      #expect(await session.requests.count == replies.count, "\(name)")
    }
  }

  @Test
  func detectsStalledConnectionsCyclesAndDuplicateIdentities() async {
    let one = thread("thread-1", comments: [comment("one")])
    let nested = outer([thread("thread-1", comments: [comment("one")], commentCursor: "A")])
    let cases: [(String, [String])] = [
      ("empty outer page", [outer([], cursor: "A")]),
      ("missing outer cursor", [outer([one], hasNext: true)]),
      ("blank outer cursor", [outer([one], cursor: " ")]),
      (
        "repeated outer cursor",
        [outer([one], cursor: "A"), outer([thread("thread-2")], cursor: "A")]
      ),
      (
        "outer cycle",
        [
          outer([one], cursor: "A"), outer([thread("thread-2")], cursor: "B"),
          outer([thread("thread-3")], cursor: "A"),
        ]
      ),
      ("duplicate thread", [outer([one], cursor: "A"), outer([one])]),
      ("duplicate thread on same page", [outer([one, one])]),
      (
        "duplicate comment across threads",
        [outer([one, thread("thread-2", comments: [comment("one")])])]
      ),
      ("empty inner page", [nested, inner("thread-1", [], cursor: "B")]),
      ("missing inner cursor", [nested, inner("thread-1", [comment("two")], hasNext: true)]),
      (
        "inner cycle",
        [
          nested, inner("thread-1", [comment("two")], cursor: "B"),
          inner("thread-1", [comment("three")], cursor: "A"),
        ]
      ),
      ("duplicate inner comment", [nested, inner("thread-1", [comment("one")])]),
    ]
    for (name, replies) in cases {
      let session = ReviewThreadsSession(replies.map(ReviewThreadsSession.Reply.body))
      #expect(await read(session) == .failure(.unavailable), "\(name)")
      #expect(await session.requests.count == replies.count, "\(name)")
    }
  }

  @Test
  func separatesConfirmedLackOfAccessFromOpaqueErrors() async {
    let denied: [String: Any] = [
      "message": "Denied", "type": "FORBIDDEN", "path": ["repository", "pullRequest"],
    ]
    let absent: [String: Any] = [
      "message": "Missing", "extensions": ["type": "NOT_FOUND"], "path": ["repository"],
    ]
    let rateLimited: [String: Any] = [
      "message": "Rate limited", "type": "RATE_LIMITED", "path": ["repository"],
    ]
    let mixedPath: [String: Any] = [
      "message": "Denied", "type": "FORBIDDEN", "path": ["repository", false],
    ]
    let conflict: [String: Any] = [
      "message": "Denied", "type": "FORBIDDEN", "path": ["repository"],
      "extensions": ["type": "RATE_LIMITED"],
    ]
    let cases: [(ReviewThreadsSession.Reply, PRReaderFailure)] = [
      (.body(wire(["repository": NSNull()])), .notReadable),
      (
        .body(
          wire([
            "repository": [
              "__typename": "Repository", "id": "repo", "nameWithOwner": "Owner/Repo",
              "pullRequest": NSNull(),
            ]
          ])), .notReadable
      ),
      (.body(wire(nil, errors: [denied])), .notReadable),
      (.body(wire(["repository": NSNull()], errors: [absent])), .notReadable),
      (.failure(.authenticationRequired), .notReadable),
      (.failure(.httpStatus(403)), .unavailable),
      (.failure(.httpStatus(404)), .unavailable),
      (.failure(.httpStatus(429)), .unavailable),
      (.failure(.executionFailed), .unavailable),
      (.body(wire(nil, errors: [rateLimited])), .unavailable),
      (.body(wire(nil, errors: [denied, rateLimited])), .unavailable),
      (.body(wire(nil, errors: [mixedPath])), .unavailable),
      (.body(wire(nil, errors: [conflict])), .unavailable),
      (.body(wire(nil, errors: [["message": "Forbidden"]])), .unavailable),
      (.body(wire(nil)), .unavailable),
      (.body("not-json"), .unavailable),
    ]
    for (reply, expected) in cases {
      #expect(await read(ReviewThreadsSession([reply])) == .failure(expected))
    }

    let partial = ReviewThreadsSession([
      .body(outer([thread("thread-1")], cursor: "A")),
      .body(
        outer(
          [],
          errors: [
            [
              "message": "Incomplete",
              "path": [
                "repository", "pullRequest",
                "reviewThreads",
              ],
            ]
          ])),
    ])
    #expect(await read(partial) == .failure(.unavailable))
    #expect(await partial.requests.count == 2)

    let innerError = ReviewThreadsSession([
      .body(outer([thread("thread-1", comments: [comment("one")], commentCursor: "A")])),
      .body(wire(nil, errors: [["message": "Missing", "type": "NOT_FOUND", "path": ["node"]]])),
    ])
    #expect(await read(innerError) == .failure(.unavailable))
    #expect(await innerError.requests.count == 2)
  }

  @Test
  func separatesConfirmedRepresentationFailuresFromDecodeFailures() async {
    let cases = [
      outer(NSNull()),
      outer([NSNull()]),
      outer([thread(" ")]),
      outer([thread("thread-1", path: "")]),
      outer([thread("thread-1", subject: "UNRECOGNIZED")]),
      outer([thread("thread-1", comments: NSNull())]),
      outer([thread("thread-1", comments: [NSNull()])]),
      outer([thread("thread-1", comments: [comment("")])]),
      outer([thread("thread-1", comments: [comment("one", reply: " ")])]),
    ]
    for reply in cases {
      #expect(
        await read(ReviewThreadsSession([.body(reply)])) == .failure(.contentNotRepresentable))
    }
    var missing = thread("thread-1")
    missing.removeValue(forKey: "isOutdated")
    #expect(await read(ReviewThreadsSession([.body(outer([missing]))])) == .failure(.unavailable))
  }

  @Test
  func cancellationBeforeReadingMakesNoRequest() async {
    let gate = ReviewThreadsGate()
    let session = ReviewThreadsSession([.body(outer([]))])
    let task = Task {
      await gate.pause()
      return await read(session)
    }
    await gate.waitUntilPaused()
    task.cancel()
    await gate.release()
    #expect(await task.value == .failure(.unavailable))
    #expect(await session.requests.isEmpty)
  }

  @Test
  func cancellationDuringContinuationWinsOverLateSuccessOrFailure() async {
    let initial = outer(
      [thread("thread-1", comments: [comment("one")], commentCursor: "A")],
      cursor: "B")
    for late: ReviewThreadsSession.Reply in [
      .body(inner("thread-1", [])), .failure(.authenticationRequired),
    ] {
      let gate = ReviewThreadsGate()
      let session = ReviewThreadsSession([.body(initial), late], gate: gate, pauseOn: 2)
      let task = Task { await read(session) }
      await gate.waitUntilPaused()
      task.cancel()
      await gate.release()
      #expect(await task.value == .failure(.unavailable))
      #expect(await session.requests.count == 2)
    }
  }

  private func read(
    _ session: ReviewThreadsSession, id: ReaderPullRequestID? = nil
  ) async -> Outcome<[ReaderReviewThread], PRReaderFailure> {
    await GitHubReviewThreadsSource(client: ReviewThreadsClient(session: session))
      .fetchReviewThreads(for: id ?? self.id)
  }
}

private func outer(
  _ threads: Any, cursor: String? = nil, hasNext: Bool? = nil, prID: String = "pr",
  repoID: String = "repo", prRepoID: String = "repo", repoName: String = "OWNER/repo",
  number: Int = 42, errors: [[String: Any]] = []
) -> String {
  wire(
    [
      "repository": [
        "__typename": "Repository", "id": repoID, "nameWithOwner": repoName,
        "pullRequest": [
          "__typename": "PullRequest", "id": prID, "number": number,
          "repository": ["__typename": "Repository", "id": prRepoID],
          "reviewThreads": connection(
            threads, cursor: cursor, hasNext: hasNext,
            type: "PullRequestReviewThreadConnection"),
        ],
      ]
    ], errors: errors)
}

private func inner(
  _ id: String, _ comments: Any, cursor: String? = nil, hasNext: Bool? = nil, prID: String = "pr"
) -> String {
  wire([
    "node": [
      "__typename": "PullRequestReviewThread", "id": id,
      "pullRequest": ["__typename": "PullRequest", "id": prID],
      "comments": connection(comments, cursor: cursor, hasNext: hasNext),
    ]
  ])
}

private func thread(
  _ id: String, comments: Any = [Any](), commentCursor: String? = nil, subject: String = "FILE",
  lines: [Int?] = [nil, nil, nil, nil], resolved: Bool = false, outdated: Bool = false,
  prID: String = "pr", path: String = "Sources/測試.swift"
) -> [String: Any] {
  [
    "__typename": "PullRequestReviewThread", "id": id, "path": path, "subjectType": subject,
    "isResolved": resolved, "isOutdated": outdated,
    "line": lines[0] as Any? ?? NSNull(), "startLine": lines[1] as Any? ?? NSNull(),
    "originalLine": lines[2] as Any? ?? NSNull(), "originalStartLine": lines[3] as Any? ?? NSNull(),
    "pullRequest": ["__typename": "PullRequest", "id": prID],
    "comments": connection(comments, cursor: commentCursor),
  ]
}

private func comment(
  _ id: String, body: String = "comment", author: String? = nil, reply: String? = nil,
  prID: String = "pr"
) -> [String: Any] {
  [
    "__typename": "PullRequestReviewComment", "id": id, "body": body,
    "author": author.map { ["__typename": "User", "login": $0] } as Any? ?? NSNull(),
    "replyTo": reply.map { ["__typename": "PullRequestReviewComment", "id": $0] } as Any?
      ?? NSNull(),
    "pullRequest": ["__typename": "PullRequest", "id": prID],
  ]
}

private func connection(
  _ nodes: Any, cursor: String?, hasNext: Bool? = nil,
  type: String = "PullRequestReviewCommentConnection"
) -> [String: Any] {
  [
    "__typename": type,
    "pageInfo": [
      "__typename": "PageInfo", "endCursor": cursor as Any? ?? NSNull(),
      "hasNextPage": hasNext ?? (cursor != nil),
    ],
    "nodes": nodes,
  ]
}

private func wire(_ data: [String: Any]?, errors: [[String: Any]] = []) -> String {
  var body: [String: Any] = ["data": data as Any? ?? NSNull()]
  if !errors.isEmpty { body["errors"] = errors }
  guard let data = try? JSONSerialization.data(withJSONObject: body),
    let json = String(data: data, encoding: .utf8)
  else { preconditionFailure("Invalid controlled GraphQL response") }
  return json
}

private struct ReviewThreadsClient: GitHubGraphQLServing {
  private let client: ApolloClient

  init(session: ReviewThreadsSession) {
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    client = ApolloClient(
      networkTransport: RequestChainNetworkTransport(
        urlSession: session, interceptorProvider: DefaultInterceptorProvider.shared,
        store: store, endpointURL: URL(string: "https://api.github.com/graphql")!,
        apqConfig: .init(autoPersistQueries: false)),
      store: store)
  }

  func fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    do {
      return try await client.fetch(
        query: query, cachePolicy: .networkOnly,
        requestConfiguration: .init(writeResultsToCache: false))
    } catch let error as GitHubGraphQLClientError {
      throw error
    } catch {
      throw GitHubGraphQLClientError.executionFailed
    }
  }

  func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<
    Mutation
  >
  where Mutation.ResponseFormat == SingleResponseFormat {
    throw GitHubGraphQLClientError.executionFailed
  }
}

private actor ReviewThreadsSession: ApolloURLSession {
  enum Reply: Sendable {
    case body(String)
    case failure(GitHubGraphQLClientError)
  }

  private var replies: [Reply]
  private let gate: ReviewThreadsGate?
  private let pauseOn: Int?
  private(set) var requests: [URLRequest] = []

  init(_ replies: [Reply], gate: ReviewThreadsGate? = nil, pauseOn: Int? = nil) {
    self.replies = replies
    self.gate = gate
    self.pauseOn = pauseOn
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requests.append(request)
    guard !replies.isEmpty else { throw GitHubGraphQLClientError.executionFailed }
    let reply = replies.removeFirst()
    if requests.count == pauseOn { await gate?.pause() }
    switch reply {
    case .failure(let error):
      throw error
    case .body(let body):
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
      )!
      return (ReviewThreadsChunks(data: Data(body.utf8)), response)
    }
  }
}

private struct ReviewThreadsChunks: AsyncChunkSequence, AsyncIteratorProtocol {
  var data: Data?
  func makeAsyncIterator() -> Self { self }
  mutating func next() async -> Data? {
    defer { data = nil }
    return data
  }
}

private actor ReviewThreadsGate {
  private var suspended: CheckedContinuation<Void, Never>?
  private var observer: CheckedContinuation<Void, Never>?

  func pause() async {
    await withCheckedContinuation {
      suspended = $0
      observer?.resume()
      observer = nil
    }
  }

  func waitUntilPaused() async {
    if suspended == nil { await withCheckedContinuation { observer = $0 } }
  }

  func release() {
    suspended?.resume()
    suspended = nil
  }
}
