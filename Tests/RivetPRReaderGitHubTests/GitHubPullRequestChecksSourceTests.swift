import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader
import RivetPRReaderGitHub
import Testing

@Suite("GitHub GraphQL PR checks source")
struct GitHubPullRequestChecksSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: 42)

  @Test
  func emptyRollupReturnsItsOverallState() async {
    let session = ChecksSession([.body(page([]))])
    #expect(await read(session) == .success(.init(overallState: .pending, checks: [])))
    #expect(await session.requests.count == 1)
  }

  @Test
  func cleanFirstPageCanHaveNoRollup() async {
    let session = ChecksSession([.body(page([]) { $0.hasRollup = false })])
    #expect(await read(session) == .success(nil))
    #expect(await session.requests.count == 1)
  }

  @Test
  func preservesBothTypesAndSourceOrderAcrossPages() async throws {
    let session = ChecksSession([
      .body(page([run("A"), status("B")], total: 4, cursor: "opaque cursor")),
      .body(page([status("C"), run("D", status: "COMPLETED", conclusion: "SUCCESS")], total: 4)),
    ])
    let rollup = ReaderCheckRollup(
      overallState: .pending,
      checks: [
        .run(name: "  測試  ", status: .inProgress, conclusion: nil),
        .commitStatus(context: "checks/build", state: .success),
        .commitStatus(context: "checks/build", state: .success),
        .run(name: "  測試  ", status: .completed, conclusion: .success),
      ])
    #expect(await read(session) == .success(rollup))

    let requests = await session.requests
    #expect(requests.map(\.httpMethod) == ["POST", "POST"])
    let payloads = try requests.map { request in
      let body = try #require(request.httpBody)
      return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
    #expect(
      payloads.compactMap { $0["operationName"] as? String }
        == Array(repeating: "PullRequestChecks", count: 2))
    #expect(
      payloads.allSatisfy {
        ($0["query"] as? String)?.contains("contexts(first: 100, after: $after)") == true
      })
    let variables = try payloads.map { try #require($0["variables"] as? [String: Any]) }
    let first = try #require(variables.first)
    #expect(first["after"] == nil)
    #expect(variables.compactMap { $0["after"] as? String } == ["opaque cursor"])
    for request in variables {
      #expect(request["owner"] as? String == "Owner")
      #expect(request["name"] as? String == "Repo")
      #expect(request["number"] as? Int == 42)
    }
  }

  @Test
  func invalidIdentityPreventsRequests() async {
    let session = ChecksSession([])
    for (owner, number) in [("Owner", Int.max), ("Owner", 0), ("bad/owner", 42)] {
      let invalid = ReaderPullRequestID(owner: owner, repository: "Repo", number: number)
      #expect(await read(session, id: invalid) == .failure(.notReadable))
    }
    #expect(await session.requests.isEmpty)
  }

  @Test
  func continuationMustRetainEveryIdentityAndIndicator() async {
    let first = page([run("A")], total: 2, cursor: "next")
    let second = [status("B")]
    let continuations = [
      page(second, total: 2) { $0.repositoryName = "someone/other" },
      page(second, total: 2) {
        $0.repositoryID = "elsewhere"
        $0.pullRequestRepositoryID = "elsewhere"
      },
      page(second, total: 2) { $0.pullRequestRepositoryID = "elsewhere" },
      page(second, total: 2) { $0.pullRequestID = "another" },
      page(second, total: 2) { $0.number = 43 },
      page(second, total: 2) { $0.head = "changed" },
      page(second, total: 2) { $0.rollupID = "changed" },
      page(second, total: 2) { $0.state = "SUCCESS" },
      page(second, total: 3),
      page(second, total: 2) { $0.hasRollup = false },
    ]
    for continuation in continuations {
      let session = ChecksSession([.body(first), .body(continuation)])
      #expect(await read(session) == .failure(.unavailable))
      #expect(await session.requests.count == 2)
    }
  }

  @Test
  func rejectsIncompleteOrRepeatedPagesWithoutAnotherRequest() async {
    let first = page([run("A")], total: 3, cursor: "aaa")
    let cases = [
      [page([run("A")], total: 2, hasNext: true)],
      [page([run("A")], total: 2, cursor: " ")],
      [page([], total: 2, cursor: "first")],
      [page([run("A")], total: 0)],
      [page([run("A"), status("A")])],
      [first, page([status("A")], total: 3)],
      [first, page([], total: 3)],
      [first, page([status("B")], total: 3)],
      [first, page([status("B")], total: 3, cursor: "aaa")],
      [
        page([run("A")], total: 4, cursor: "aaa"),
        page([status("B")], total: 4, cursor: "bbb"),
        page([run("C")], total: 4, cursor: "aaa"),
      ],
    ]
    for replies in cases {
      let session = ChecksSession(replies.map(ChecksSession.Reply.body))
      #expect(await read(session) == .failure(.unavailable))
      #expect(await session.requests.count == replies.count)
    }
  }

  @Test
  func rejectsUnknownUnionEnumsAndMissingContent() async {
    let replies = [
      page(nil),
      page([NSNull()]),
      page([["__typename": "FutureCheck"]]),
      page([run(" ", status: "IN_PROGRESS")]),
      page([run("A", status: "FUTURE")]),
      page([run("A", conclusion: "FUTURE")]),
      page([status("A", state: "FUTURE")]),
      page([]) { $0.state = "FUTURE" },
      page([]) { $0.head = " " },
    ]
    for reply in replies {
      #expect(
        await read(ChecksSession([.body(reply)])) == .failure(.contentNotRepresentable), "\(reply)")
    }
    var malformed = run("A")
    malformed.removeValue(forKey: "name")
    #expect(await read(ChecksSession([.body(page([malformed]))])) == .failure(.unavailable))
  }

  @Test
  func distinguishesConfirmedAccessFailureAndRejectsPartialResults() async {
    let denied = error("FORBIDDEN", ["repository", "pullRequest"])
    let missing: [String: Any] = [
      "message": "Missing", "extensions": ["type": "NOT_FOUND"], "path": ["repository"],
    ]
    let rate = error("RATE_LIMITED", ["repository"])
    let checkDenied = error("FORBIDDEN", ["repository", "pullRequest", "statusCheckRollup"])
    let partial = error(
      "FORBIDDEN", ["repository", "pullRequest", "statusCheckRollup", "contexts", "nodes", 0])
    var contradictory = denied
    contradictory["extensions"] = ["type": "RATE_LIMITED"]
    let cases: [(ChecksSession.Reply, PRReaderFailure)] = [
      (.body(wire(["repository": NSNull()])), .notReadable),
      (.body(page([]) { $0.hasPullRequest = false }), .notReadable),
      (.body(wire(nil, errors: [denied])), .notReadable),
      (.body(wire(["repository": NSNull()], errors: [missing])), .notReadable),
      (.failure(.authenticationRequired), .notReadable),
      (.failure(.httpStatus(401)), .notReadable),
      (.failure(.httpStatus(403)), .unavailable),
      (.failure(.httpStatus(429)), .unavailable),
      (.failure(.executionFailed), .unavailable),
      (.body(wire(nil)), .unavailable),
      (.body(wire(nil, errors: [denied, rate])), .unavailable),
      (.body(wire(nil, errors: [contradictory])), .unavailable),
      (.body(wire(nil, errors: [error("FORBIDDEN", ["repository", false])])), .unavailable),
      (
        .body(
          page([]) {
            $0.errors = [checkDenied]
            $0.hasRollup = false
          }), .unavailable
      ),
      (.body(page([run("A")]) { $0.errors = [partial] }), .unavailable),
    ]
    for (reply, failure) in cases {
      #expect(await read(ChecksSession([reply])) == .failure(failure), "\(reply)")
    }
    let after = ChecksSession([
      .body(page([run("A")], total: 2, cursor: "next")), .failure(.executionFailed),
    ])
    #expect(await read(after) == .failure(.unavailable))
    #expect(await after.requests.count == 2)
  }

  @Test
  func cancellationBeforeRequestMakesNoRequest() async {
    let gate = ChecksGate()
    let session = ChecksSession([.body(page([]))])
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
  func cancellationDuringContinuationWinsOverSuccessOrAccessFailure() async {
    let first = page([run("A")], total: 2, cursor: "next")
    for late: ChecksSession.Reply in [
      .body(page([status("B")], total: 2)), .failure(.authenticationRequired),
    ] {
      let gate = ChecksGate()
      let session = ChecksSession([.body(first), late], gate: gate)
      let task = Task { await read(session) }
      await gate.waitUntilPaused()
      task.cancel()
      await gate.release()
      #expect(await task.value == .failure(.unavailable))
      #expect(await session.requests.count == 2)
    }
  }

  private func read(
    _ session: ChecksSession, id: ReaderPullRequestID? = nil
  ) async -> Outcome<ReaderCheckRollup?, PRReaderFailure> {
    await GitHubPullRequestChecksSource(client: ChecksClient(session: session))
      .fetchChecks(for: id ?? self.id)
  }
}

private struct PageIdentity {
  var repositoryID = "repo"
  var repositoryName = "OWNER/repo"
  var pullRequestRepositoryID = "repo"
  var pullRequestID = "pr"
  var number = 42
  var head = "head"
  var rollupID = "rollup"
  var state = "PENDING"
  var hasPullRequest = true
  var hasRollup = true
  var errors: [[String: Any]] = []
}

private func page(
  _ nodes: [Any]?, total: Int? = nil, cursor: String? = nil, hasNext: Bool? = nil,
  configure: (inout PageIdentity) -> Void = { _ in }
) -> String {
  var id = PageIdentity()
  configure(&id)
  let rollup: [String: Any] = [
    "__typename": "StatusCheckRollup", "id": id.rollupID, "state": id.state,
    "contexts": [
      "__typename": "StatusCheckRollupContextConnection", "totalCount": total ?? nodes?.count ?? 0,
      "pageInfo": [
        "__typename": "PageInfo", "hasNextPage": hasNext ?? (cursor != nil),
        "endCursor": cursor as Any? ?? NSNull(),
      ],
      "nodes": nodes as Any? ?? NSNull(),
    ] as [String: Any],
  ]
  let pullRequest: [String: Any] = [
    "__typename": "PullRequest", "id": id.pullRequestID, "number": id.number, "headRefOid": id.head,
    "repository": ["__typename": "Repository", "id": id.pullRequestRepositoryID],
    "statusCheckRollup": id.hasRollup ? rollup as Any : NSNull(),
  ]
  return wire(
    [
      "repository": [
        "__typename": "Repository", "id": id.repositoryID, "nameWithOwner": id.repositoryName,
        "pullRequest": id.hasPullRequest ? pullRequest as Any : NSNull(),
      ] as [String: Any]
    ], errors: id.errors)
}

private func run(
  _ id: String, status: String = "IN_PROGRESS", conclusion: String? = nil
) -> [String: Any] {
  [
    "__typename": "CheckRun", "id": id, "name": "  測試  ", "status": status,
    "conclusion": conclusion as Any? ?? NSNull(),
  ]
}

private func status(_ id: String, state: String = "SUCCESS") -> [String: Any] {
  ["__typename": "StatusContext", "id": id, "context": "checks/build", "state": state]
}

private func error(_ type: String, _ path: [Any]) -> [String: Any] {
  ["message": "Controlled GraphQL error", "type": type, "path": path]
}

private func wire(_ data: [String: Any]?, errors: [[String: Any]] = []) -> String {
  var body: [String: Any] = ["data": data as Any? ?? NSNull()]
  if !errors.isEmpty { body["errors"] = errors }
  guard let data = try? JSONSerialization.data(withJSONObject: body),
    let json = String(data: data, encoding: .utf8)
  else { preconditionFailure("Invalid controlled GraphQL response") }
  return json
}

private struct ChecksClient: GitHubGraphQLServing {
  private let client: ApolloClient

  init(session: ChecksSession) {
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

private actor ChecksSession: ApolloURLSession {
  enum Reply: Sendable {
    case body(String)
    case failure(GitHubGraphQLClientError)
  }

  private var replies: [Reply]
  private let gate: ChecksGate?
  private(set) var requests: [URLRequest] = []

  init(_ replies: [Reply], gate: ChecksGate? = nil) {
    self.replies = replies
    self.gate = gate
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requests.append(request)
    guard !replies.isEmpty else { throw GitHubGraphQLClientError.executionFailed }
    let reply = replies.removeFirst()
    if requests.count == 2 { await gate?.pause() }
    switch reply {
    case .failure(let error):
      throw error
    case .body(let body):
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"])!
      return (ChecksChunks(data: Data(body.utf8)), response)
    }
  }
}

private struct ChecksChunks: AsyncChunkSequence, AsyncIteratorProtocol {
  var data: Data?
  func makeAsyncIterator() -> Self { self }
  mutating func next() async -> Data? {
    defer { data = nil }
    return data
  }
}

private actor ChecksGate {
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
    guard suspended == nil else { return }
    await withCheckedContinuation { observer = $0 }
  }

  func release() {
    suspended?.resume()
    suspended = nil
  }
}
