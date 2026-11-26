import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader
import RivetPRReaderGitHub
import Testing

@Suite("GitHub GraphQL PR files viewed source")
struct GitHubPullRequestFilesViewedSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: 42)

  @Test
  func readsASinglePage() async throws {
    let session = FilesSession([.body(page([file("Sources/Rivet.swift")]))])
    let result = await read(session)
    let files = try result.get()
    #expect(files.map(\.path) == ["Sources/Rivet.swift"])
    #expect(files.map(\.viewedState) == [.unviewed])
    #expect(await session.requests.count == 1)
  }

  @Test
  func preservesFileDataAndSourceOrderAcrossPages() async throws {
    let paths = ["z.swift", " path.swift ", " ", "\u{00E9}.swift", "e\u{0301}.swift", "a.swift"]
    let session = FilesSession([
      .body(
        page(
          [
            file(paths[0], change: "ADDED", additions: 3, deletions: 0),
            file(paths[1], change: "DELETED", viewed: "VIEWED", additions: 0, deletions: 4),
            file(paths[2], change: "MODIFIED", viewed: "DISMISSED"),
          ], total: 6, cursor: " cursor ")),
      .body(
        page(
          [
            file(paths[3], change: "RENAMED"),
            file(paths[4], change: "COPIED", viewed: "VIEWED"),
            file(paths[5], change: "CHANGED", viewed: "DISMISSED"),
          ], total: 6)),
    ])
    let result = await read(session)
    let files = try result.get()
    #expect(files.map { Array($0.path.utf8) } == paths.map { Array($0.utf8) })
    #expect(files.map(\.change) == [.added, .removed, .modified, .renamed, .copied, .typeChanged])
    #expect(
      files.map(\.viewedState) == [.unviewed, .viewed, .dismissed, .unviewed, .viewed, .dismissed])
    #expect(files.map(\.additions) == [3, 0, 2, 2, 2, 2])
    #expect(files.map(\.deletions) == [0, 4, 1, 1, 1, 1])

    let requests = await session.requests
    #expect(requests.map(\.httpMethod) == ["POST", "POST"])
    #expect(requests.allSatisfy { $0.url?.absoluteString == "https://api.github.com/graphql" })
    let payloads = try requests.map { request in
      let body = try #require(request.httpBody)
      return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
    #expect(
      payloads.compactMap { $0["operationName"] as? String }
        == Array(repeating: "PullRequestFilesViewed", count: 2))
    #expect(
      payloads.allSatisfy {
        ($0["query"] as? String)?.contains("files(first: 100, after: $after)") == true
      })
    let variables = try payloads.map { try #require($0["variables"] as? [String: Any]) }
    let first = try #require(variables.first)
    #expect(first["after"] == nil)
    #expect(variables.compactMap { $0["after"] as? String } == [" cursor "])
    for request in variables {
      #expect(request["owner"] as? String == "Owner")
      #expect(request["name"] as? String == "Repo")
      #expect(request["number"] as? Int == 42)
    }
  }

  @Test
  func acceptsConfirmedEmptyList() async throws {
    let session = FilesSession([.body(page([]))])
    let result = await read(session)
    #expect(try result.get().isEmpty)
    #expect(await session.requests.count == 1)
  }

  @Test
  func rejectsInvalidIdentityWithoutARequest() async {
    let session = FilesSession([])
    for (owner, repo, number) in [
      ("Owner", "Repo", Int.max), ("Owner", "Repo", 0), ("Owner", "Repo", -1),
      ("bad/owner", "Repo", 42), ("Owner", "bad/repo", 42),
    ] {
      let invalid = ReaderPullRequestID(owner: owner, repository: repo, number: number)
      await expectFailure(.notReadable, reading: session, id: invalid)
    }
    #expect(await session.requests.isEmpty)
  }

  @Test
  func allPagesMustBelongToTheSamePullRequestAndHead() async {
    let first = page([file("A")], total: 2, cursor: "next")
    let second = [file("B")]
    let invalidPages = [
      page(second, total: 2) { $0.repositoryName = "other/repo" },
      page(second, total: 2) {
        $0.repositoryID = "other-repo"
        $0.pullRequestRepositoryID = "other-repo"
      },
      page(second, total: 2) { $0.pullRequestRepositoryID = "other-repo" },
      page(second, total: 2) { $0.pullRequestID = "other-request" },
      page(second, total: 2) { $0.number = 43 },
      page(second, total: 2) { $0.head = "new-head" },
      page(second, total: 2) { $0.head = " " },
      page(second, total: 3),
    ]
    for reply in invalidPages {
      let session = FilesSession([.body(first), .body(reply)])
      await expectFailure(.unavailable, reading: session)
      #expect(await session.requests.count == 2)
    }
  }

  @Test
  func failsWithoutAPartialListWhenPaginationCannotBeVerified() async {
    let first = page([file("A")], total: 3, cursor: "one")
    for pages in [
      [page([]) { $0.hasFiles = false }],
      [page([file("A")], total: 2, hasNext: true)],
      [page([file("A")], total: 2, cursor: " ")],
      [page([], total: 1, cursor: "one")],
      [page([], total: 1)],
      [page([file("A")], total: 0)],
      [page([file("A")], total: 1, cursor: "one")],
      [first, page([], total: 3)],
      [first, page([file("B")], total: 3)],
      [first, page([file("B")], total: 3) { $0.hasFiles = false }],
      [first, page([file("B")], total: 3, cursor: "one")],
      [
        page([file("A")], total: 4, cursor: "one"),
        page([file("B")], total: 4, cursor: "two"),
        page([file("C")], total: 4, cursor: "one"),
      ],
    ] {
      let session = FilesSession(pages.map(FilesSession.Reply.body))
      await expectFailure(.unavailable, reading: session)
      #expect(await session.requests.count == pages.count)
    }
  }

  @Test
  func rejectsUnrepresentableDecodedFileData() async {
    for reply in [
      page(nil),
      page([NSNull()]),
      page([file("A", change: "FUTURE")]),
      page([file("A", viewed: "FUTURE")]),
      page([file("")]),
      page([file("A", additions: -1)]),
      page([file("A", deletions: -1)]),
      page([file("A"), file("A")]),
    ] {
      let session = FilesSession([.body(reply)])
      await expectFailure(.contentNotRepresentable, reading: session)
      #expect(await session.requests.count == 1)
    }
    let duplicates = FilesSession([
      .body(page([file("A")], total: 2, cursor: "next")),
      .body(page([file("A")], total: 2)),
    ])
    await expectFailure(.contentNotRepresentable, reading: duplicates)
    #expect(await duplicates.requests.count == 2)
  }

  @Test
  func distinguishesPullRequestAccessAndIncompleteResponse() async {
    let denied = graphQLError("FORBIDDEN", ["repository", "pullRequest"])
    let missing: [String: Any] = [
      "message": "Missing", "extensions": ["type": "NOT_FOUND"], "path": ["repository"],
    ]
    let rate = graphQLError("RATE_LIMITED", ["repository"])
    let fileDenied = graphQLError("FORBIDDEN", ["repository", "pullRequest", "files"])
    var conflicting = denied
    conflicting["extensions"] = ["type": "NOT_FOUND"]
    let first = page([file("A")], total: 2, cursor: "next")
    let unavailable: [(FilesSession.Reply, PRReaderFailure)] = [
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
      (.body(wire(nil, errors: [conflicting])), .unavailable),
      (.body(page([file("B")], total: 2) { $0.errors = [fileDenied] }), .unavailable),
      (
        .body(
          page([], total: 2) {
            $0.hasFiles = false
            $0.errors = [fileDenied]
          }), .unavailable
      ),
    ]
    for (reply, failure) in unavailable {
      let initial = FilesSession([reply])
      await expectFailure(failure, reading: initial)
      #expect(await initial.requests.count == 1)

      let continuation = FilesSession([.body(first), reply])
      await expectFailure(failure, reading: continuation)
      #expect(await continuation.requests.count == 2)
    }
  }

  @Test
  func malformedRequiredFieldsAreUnavailable() async {
    var missingPath = file("A")
    missingPath.removeValue(forKey: "path")
    var wrongCount = file("B")
    wrongCount["additions"] = "two"
    for node in [missingPath, wrongCount] {
      await expectFailure(.unavailable, reading: FilesSession([.body(page([node]))]))
    }
  }

  @Test
  func cancellationBeforeRequestMakesNoRequest() async {
    let gate = FilesGate()
    let session = FilesSession([.body(page([]))])
    let task = Task {
      await gate.pause()
      return await read(session)
    }
    await gate.waitUntilPaused()
    task.cancel()
    await gate.release()
    let result = await task.value
    #expect(throws: PRReaderFailure.unavailable) { try result.get() }
    #expect(await session.requests.isEmpty)
  }

  @Test
  func cancellationDuringContinuationWinsOverSuccessOrAccessFailure() async {
    let first = page([file("A")], total: 2, cursor: "next")
    for late: FilesSession.Reply in [
      .body(page([file("B")], total: 2)), .failure(.authenticationRequired),
    ] {
      let gate = FilesGate()
      let session = FilesSession([.body(first), late], gate: gate)
      let task = Task { await read(session) }
      await gate.waitUntilPaused()
      task.cancel()
      await gate.release()
      let result = await task.value
      #expect(throws: PRReaderFailure.unavailable) { try result.get() }
      #expect(await session.requests.count == 2)
    }
  }

  private func expectFailure(
    _ failure: PRReaderFailure, reading session: FilesSession, id: ReaderPullRequestID? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
  ) async {
    let result = await read(session, id: id)
    #expect(throws: failure, sourceLocation: sourceLocation) { try result.get() }
  }

  private func read(
    _ session: FilesSession, id: ReaderPullRequestID? = nil
  ) async -> Outcome<[ReaderFileViewed], PRReaderFailure> {
    await GitHubPullRequestFilesViewedSource(client: FilesClient(session: session))
      .fetchFilesViewed(for: id ?? self.id)
  }
}

private struct PageIdentity {
  var repositoryID = "repo"
  var repositoryName = "OWNER/repo"
  var pullRequestRepositoryID = "repo"
  var pullRequestID = "pr"
  var number = 42
  var head = "head"
  var hasPullRequest = true
  var hasFiles = true
  var errors: [[String: Any]] = []
}

private func page(
  _ nodes: [Any]?, total: Int? = nil, cursor: String? = nil, hasNext: Bool? = nil,
  configure: (inout PageIdentity) -> Void = { _ in }
) -> String {
  var id = PageIdentity()
  configure(&id)
  let files: [String: Any] = [
    "__typename": "PullRequestChangedFileConnection",
    "totalCount": total ?? nodes?.count ?? 0,
    "pageInfo": [
      "__typename": "PageInfo", "hasNextPage": hasNext ?? (cursor != nil),
      "endCursor": cursor as Any? ?? NSNull(),
    ],
    "nodes": nodes as Any? ?? NSNull(),
  ]
  let pullRequest: [String: Any] = [
    "__typename": "PullRequest", "id": id.pullRequestID, "number": id.number, "headRefOid": id.head,
    "repository": ["__typename": "Repository", "id": id.pullRequestRepositoryID],
    "files": id.hasFiles ? files as Any : NSNull(),
  ]
  return wire(
    [
      "repository": [
        "__typename": "Repository", "id": id.repositoryID, "nameWithOwner": id.repositoryName,
        "pullRequest": id.hasPullRequest ? pullRequest as Any : NSNull(),
      ] as [String: Any]
    ], errors: id.errors)
}

private func file(
  _ path: String, change: String = "ADDED", viewed: String = "UNVIEWED",
  additions: Int = 2, deletions: Int = 1
) -> [String: Any] {
  [
    "__typename": "PullRequestChangedFile", "path": path, "changeType": change,
    "viewerViewedState": viewed, "additions": additions, "deletions": deletions,
  ]
}

private func graphQLError(_ type: String, _ path: [Any]) -> [String: Any] {
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

private struct FilesClient: GitHubGraphQLServing {
  private let client: ApolloClient

  init(session: FilesSession) {
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

private actor FilesSession: ApolloURLSession {
  enum Reply: Sendable {
    case body(String)
    case failure(GitHubGraphQLClientError)
  }

  private var replies: [Reply]
  private let gate: FilesGate?
  private(set) var requests: [URLRequest] = []

  init(_ replies: [Reply], gate: FilesGate? = nil) {
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
      return (FilesChunks(data: Data(body.utf8)), response)
    }
  }
}

private struct FilesChunks: AsyncChunkSequence, AsyncIteratorProtocol {
  var data: Data?
  func makeAsyncIterator() -> Self { self }
  mutating func next() async -> Data? {
    defer { data = nil }
    return data
  }
}

private actor FilesGate {
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
