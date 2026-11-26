import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader
import RivetPRReaderGitHub
import Testing

@Suite("GitHub GraphQL PR review and merge state source")
struct GitHubReviewMergeStateSourceTests {
  private let id = ReaderPullRequestID(owner: "Owner", repository: "Repo", number: 42)

  @Test
  func requestsOnePullRequestAndReturnsTheFiveFields() async throws {
    let session = ReviewMergeStateSession([.body(pullRequestResponse())])
    let result = await read(session)
    #expect(
      result
        == .success(
          .init(
            reviewDecision: .approved, mergeable: .mergeable, mergeStateStatus: .clean,
            isDraft: false, headRefOid: "abc123")))

    let requests = await session.requests
    #expect(requests.count == 1)
    let request = try #require(requests.first)
    #expect(request.httpMethod == "POST")
    #expect(request.url?.absoluteString == "https://api.github.com/graphql")
    let body = try #require(request.httpBody)
    let payload = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(payload["operationName"] as? String == "PullRequestReviewMergeState")
    let variables = try #require(payload["variables"] as? [String: Any])
    #expect(Set(variables.keys) == ["owner", "name", "number"])
    #expect(variables["owner"] as? String == "Owner")
    #expect(variables["name"] as? String == "Repo")
    #expect(variables["number"] as? Int == 42)
    let query = try #require(payload["query"] as? String)
    for field in ["reviewDecision", "mergeable", "mergeStateStatus", "isDraft", "headRefOid"] {
      #expect(query.contains(field))
    }
  }

  @Test
  func preservesEveryMergeStatusAndTheIndependentDraftFlag() async {
    let statuses: [(String, ReaderMergeStateStatus)] = [
      ("BEHIND", .behind), ("BLOCKED", .blocked), ("CLEAN", .clean), ("DIRTY", .dirty),
      ("DRAFT", .draft), ("HAS_HOOKS", .hasHooks), ("UNKNOWN", .unknown), ("UNSTABLE", .unstable),
    ]
    for (wireStatus, expected) in statuses {
      let draft = expected == .clean
      let body = pullRequestResponse {
        $0["reviewDecision"] = NSNull()
        $0["mergeStateStatus"] = wireStatus
        $0["mergeable"] = "UNKNOWN"
        $0["isDraft"] = draft
        $0["headRefOid"] = "  opaque-oid  "
      }
      #expect(
        await read(ReviewMergeStateSession([.body(body)]))
          == .success(
            .init(
              reviewDecision: nil, mergeable: .unknown, mergeStateStatus: expected,
              isDraft: draft, headRefOid: "  opaque-oid  ")), "\(wireStatus)")
    }
  }

  @Test
  func preservesTheOtherReviewDecisionsAndAConflict() async {
    let decisions: [(String, ReviewDecision)] = [
      ("CHANGES_REQUESTED", .changesRequested), ("REVIEW_REQUIRED", .reviewRequired),
    ]
    for (wireDecision, expected) in decisions {
      let body = pullRequestResponse {
        $0["reviewDecision"] = wireDecision
        $0["mergeable"] = "CONFLICTING"
      }
      #expect(
        await read(ReviewMergeStateSession([.body(body)]))
          == .success(
            .init(
              reviewDecision: expected, mergeable: .conflicting, mergeStateStatus: .clean,
              isDraft: false, headRefOid: "abc123")), "\(wireDecision)")
    }
  }

  @Test
  func invalidIdentityMakesNoRequest() async {
    let session = ReviewMergeStateSession([])
    for (owner, repository, number) in [
      ("Owner", "Repo", Int.max), ("Owner", "Repo", 0), ("bad/owner", "Repo", 42),
      ("Owner", "", 42),
    ] {
      let invalid = ReaderPullRequestID(owner: owner, repository: repository, number: number)
      #expect(await read(session, id: invalid) == .failure(.notReadable))
    }
    #expect(await session.requests.isEmpty)
  }

  @Test
  func rejectsMismatchedRepositoryNameAndPullRequestIdentity() async {
    let bodies = [
      pullRequestResponse(repositoryName: "Owner/Other"),
      pullRequestResponse { $0["number"] = 43 },
      pullRequestResponse { $0["repository"] = ["__typename": "Repository", "id": "other"] },
    ]
    for body in bodies {
      let session = ReviewMergeStateSession([.body(body)])
      #expect(await read(session) == .failure(.unavailable), "\(body)")
      #expect(await session.requests.count == 1)
    }
  }

  @Test
  func distinguishesConfirmedDenialFromUncertainOrPartialResponses() async {
    let denied = graphQLError("FORBIDDEN", path: ["repository", "pullRequest"])
    let missing: [String: Any] = [
      "message": "Missing", "extensions": ["type": "NOT_FOUND"], "path": ["repository"],
    ]
    let rate = graphQLError("RATE_LIMITED", path: ["repository"])
    let fieldDenied = graphQLError(
      "FORBIDDEN", path: ["repository", "pullRequest", "reviewDecision"])
    var contradictory = denied
    contradictory["extensions"] = ["type": "RATE_LIMITED"]

    let cases: [(ReviewMergeStateSession.Reply, PRReaderFailure)] = [
      (.body(wire(["repository": NSNull()])), .notReadable),
      (.body(wire(["repository": repository(pullRequest: nil)])), .notReadable),
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
      (
        .body(wire(nil, errors: [graphQLError("FORBIDDEN", path: ["repository", 0])])), .unavailable
      ),
      (
        .body(pullRequestResponse(errors: [fieldDenied]) { $0["reviewDecision"] = NSNull() }),
        .unavailable
      ),
    ]
    for (reply, expected) in cases {
      let session = ReviewMergeStateSession([reply])
      #expect(await read(session) == .failure(expected), "\(reply)")
      #expect(await session.requests.count == 1)
    }
  }

  @Test
  func distinguishesUnrepresentableValuesFromMalformedFields() async {
    let unrepresentable = [
      pullRequestResponse { $0["reviewDecision"] = "FUTURE" },
      pullRequestResponse { $0["mergeable"] = "FUTURE" },
      pullRequestResponse { $0["mergeStateStatus"] = "FUTURE" },
      pullRequestResponse { $0["headRefOid"] = " \n" },
      pullRequestResponse(repositoryName: " "),
      pullRequestResponse(repositoryID: ""),
      pullRequestResponse { $0["repository"] = ["__typename": "Repository", "id": " "] },
    ]
    for body in unrepresentable {
      #expect(
        await read(ReviewMergeStateSession([.body(body)])) == .failure(.contentNotRepresentable),
        "\(body)")
    }
    let malformed = [
      pullRequestResponse { $0["reviewDecision"] = nil },
      pullRequestResponse { $0["reviewDecision"] = 12 },
      pullRequestResponse { $0["headRefOid"] = NSNull() },
      pullRequestResponse { $0["isDraft"] = nil },
    ]
    for body in malformed {
      #expect(
        await read(ReviewMergeStateSession([.body(body)])) == .failure(.unavailable), "\(body)")
    }
  }

  @Test
  func cancellationBeforeFetchMakesNoRequest() async {
    let gate = ReviewMergeStateGate()
    let session = ReviewMergeStateSession([.body(pullRequestResponse())])
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
  func cancellationDiscardsLateDataOrDenial() async {
    let replies: [ReviewMergeStateSession.Reply] = [
      .body(pullRequestResponse()), .failure(.authenticationRequired),
    ]
    for reply in replies {
      let gate = ReviewMergeStateGate()
      let session = ReviewMergeStateSession([reply])
      let client = ReviewMergeStateClient(session: session, deliveryGate: gate)
      let task = Task {
        await GitHubPullRequestReviewMergeStateSource(client: client).fetchReviewMergeState(for: id)
      }
      await gate.waitUntilPaused()
      task.cancel()
      await gate.release()
      #expect(await task.value == .failure(.unavailable))
      #expect(await session.requests.count == 1)
    }
  }

  private func read(
    _ session: ReviewMergeStateSession, id: ReaderPullRequestID? = nil
  ) async -> Outcome<ReaderPullRequestReviewMergeState, PRReaderFailure> {
    await GitHubPullRequestReviewMergeStateSource(client: ReviewMergeStateClient(session: session))
      .fetchReviewMergeState(for: id ?? self.id)
  }
}

private func pullRequestResponse(
  repositoryName: String = "OWNER/repo",
  repositoryID: String = "repo",
  errors: [[String: Any]] = [],
  configure: (inout [String: Any]) -> Void = { _ in }
) -> String {
  var pullRequest: [String: Any] = [
    "__typename": "PullRequest", "number": 42,
    "repository": ["__typename": "Repository", "id": repositoryID],
    "reviewDecision": "APPROVED", "mergeable": "MERGEABLE", "mergeStateStatus": "CLEAN",
    "isDraft": false, "headRefOid": "abc123",
  ]
  configure(&pullRequest)
  return wire(
    ["repository": repository(pullRequest: pullRequest, name: repositoryName, id: repositoryID)],
    errors: errors)
}

private func repository(
  pullRequest: [String: Any]?, name: String = "OWNER/repo", id: String = "repo"
) -> [String: Any] {
  [
    "__typename": "Repository", "id": id, "nameWithOwner": name,
    "pullRequest": pullRequest as Any? ?? NSNull(),
  ]
}

private func graphQLError(_ type: String, path: [Any]) -> [String: Any] {
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

private struct ReviewMergeStateClient: GitHubGraphQLServing {
  private let client: ApolloClient
  private let deliveryGate: ReviewMergeStateGate?

  init(session: ReviewMergeStateSession, deliveryGate: ReviewMergeStateGate? = nil) {
    self.deliveryGate = deliveryGate
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
    let result: Result<GraphQLResponse<Query>, GitHubGraphQLClientError>
    do {
      result = .success(
        try await client.fetch(
          query: query, cachePolicy: .networkOnly,
          requestConfiguration: .init(writeResultsToCache: false)))
    } catch let error as GitHubGraphQLClientError {
      result = .failure(error)
    } catch {
      result = .failure(.executionFailed)
    }
    await deliveryGate?.pause()
    return try result.get()
  }

  func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<
    Mutation
  >
  where Mutation.ResponseFormat == SingleResponseFormat {
    throw GitHubGraphQLClientError.executionFailed
  }
}

private actor ReviewMergeStateSession: ApolloURLSession {
  enum Reply: Sendable {
    case body(String)
    case failure(GitHubGraphQLClientError)
  }

  private var replies: [Reply]
  private(set) var requests: [URLRequest] = []

  init(_ replies: [Reply]) {
    self.replies = replies
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requests.append(request)
    guard !replies.isEmpty else { throw GitHubGraphQLClientError.executionFailed }
    switch replies.removeFirst() {
    case .failure(let error):
      throw error
    case .body(let body):
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"])!
      return (ReviewMergeStateChunks(data: Data(body.utf8)), response)
    }
  }
}

private struct ReviewMergeStateChunks: AsyncChunkSequence, AsyncIteratorProtocol {
  var data: Data?
  func makeAsyncIterator() -> Self { self }
  mutating func next() async -> Data? {
    defer { data = nil }
    return data
  }
}

private actor ReviewMergeStateGate {
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
