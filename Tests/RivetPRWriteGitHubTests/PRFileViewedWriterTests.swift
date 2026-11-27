import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRWriteGitHub
import Testing

@Suite("GraphQL 將單一 PR 檔案標記或取消已讀")
struct PRFileViewedWriterTests {
  private let pullRequestID = "PR_test"

  @Test
  func sendsExactlyTheRequestedActionAndOriginalPath() async throws {
    let actions = [
      OperationFixture(
        action: .mark, operation: "MarkPullRequestFileAsViewed",
        field: "markFileAsViewed", path: " Sources/\u{00E9}.swift "),
      OperationFixture(
        action: .unmark, operation: "UnmarkPullRequestFileAsViewed",
        field: "unmarkFileAsViewed", path: " Sources/e\u{0301}.swift "),
      OperationFixture(
        action: .mark, operation: "MarkPullRequestFileAsViewed",
        field: "markFileAsViewed", path: " "),
    ]
    for fixture in actions {
      let (operation, field, path) = (fixture.operation, fixture.field, fixture.path)
      let client = ViewedClient(.body(wire(field: field, pullRequestID: pullRequestID)))
      let result = await PRFileViewedWriter(client: client).setViewed(
        .init(pullRequestID: pullRequestID, path: path, action: fixture.action))
      #expect(result == .confirmed(pullRequestID: pullRequestID))
      #expect(await client.operations == [operation])

      let requests = await client.session.requests
      #expect(requests.count == 1)
      let request = try #require(requests.first)
      #expect(request.httpMethod == "POST")
      let body = try #require(request.httpBody)
      let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
      #expect(json["operationName"] as? String == operation)
      let document = try #require(json["query"] as? String)
      #expect(document.contains("\(field)(input: { pullRequestId: $pullRequestId, path: $path })"))
      let variables = try #require(json["variables"] as? [String: String])
      #expect(Set(variables.keys) == ["pullRequestId", "path"])
      #expect(variables["pullRequestId"] == pullRequestID)
      #expect(variables["path"]?.utf8.elementsEqual(path.utf8) == true)
    }
  }

  @Test
  func rejectsInvalidInputAndEarlyCancellationBeforeAnyClientCall() async {
    let client = ViewedClient(.body(wire(pullRequestID: pullRequestID)))
    let writer = PRFileViewedWriter(client: client)
    for (id, path) in [
      ("", "file"), ("PR test", "file"), ("PR\u{0000}", "file"),
      ("PR\u{000A}", "file"), (pullRequestID, ""), (pullRequestID, "file\u{0000}"),
    ] {
      let result = await writer.setViewed(.init(pullRequestID: id, path: path, action: .mark))
      #expect(result == .invalidInput)
    }
    let cancelled = await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await writer.setViewed(
        .init(pullRequestID: pullRequestID, path: "file", action: .mark))
    }.value
    #expect(cancelled == .cancelledBeforeSubmission)
    #expect(await client.operations.isEmpty)
    #expect(await client.session.requests.isEmpty)
  }

  @Test
  func requiresAnExactReceiptAndUnaffectedReceiptFields() async {
    let root = "markFileAsViewed"
    await expect(
      .confirmed(pullRequestID: pullRequestID),
      .body(
        wire(
          pullRequestID: pullRequestID, errors: [graphError("FORBIDDEN", [root, "otherField"])])))
    for reply in [
      wire(pullRequestID: "other"),
      wire(pullRequestID: nil),
      wire(pullRequestID: nil, hasPayload: false),
      wire(pullRequestID: pullRequestID, errors: [graphError("FORBIDDEN", nil)]),
      wire(pullRequestID: pullRequestID, errors: [graphError("FORBIDDEN", [root])]),
      wire(
        pullRequestID: pullRequestID, errors: [graphError("UNAVAILABLE", [root, "pullRequest"])]),
      wire(
        pullRequestID: pullRequestID,
        errors: [graphError("UNAVAILABLE", [root, "pullRequest", "id"])]),
    ] {
      await expect(.needsVerification, .body(reply))
    }
    await expect(.needsVerification, .body(wire(pullRequestID: "PR_\u{00E9}")), id: "PR_e\u{0301}")
  }

  @Test
  func needsAConsistentStructuredRejectionOfTheMutation() async {
    let root = "markFileAsViewed"
    let forbidden = graphError("FORBIDDEN", [root])
    let notFound = graphError("NOT_FOUND", [root])
    for (errors, rejection): ([[String: Any]], PRFileViewedWriter.Rejection) in [
      ([forbidden, forbidden], .forbidden),
      ([notFound], .notFound),
      (
        [["message": "Rejected", "extensions": ["type": "UNAUTHORIZED"], "path": [root]]],
        .authenticationRequired
      ),
    ] {
      await expect(
        .rejected(rejection), .body(wire(pullRequestID: nil, hasPayload: false, errors: errors)))
    }

    var conflictingType = forbidden
    conflictingType["extensions"] = ["type": "NOT_FOUND"]
    for errors in [
      [forbidden, notFound], [forbidden, graphError("FORBIDDEN", ["unmarkFileAsViewed"])],
      [graphError("INTERNAL", [root])], [conflictingType],
      [graphError("FORBIDDEN", [root, "pullRequest", "id"])],
      [graphError("FORBIDDEN", [root, 0])],
    ] {
      await expect(
        .needsVerification, .body(wire(pullRequestID: nil, hasPayload: false, errors: errors)))
    }
    await expect(.needsVerification, .body(wire(pullRequestID: nil, errors: [forbidden])))
  }

  @Test
  func reportsAuthenticationOrUncertaintyAfterEnteringPerform() async {
    for error: GitHubGraphQLClientError in [
      .authenticationRequired, .invalidAuthorizationToken, .httpStatus(401),
    ] {
      await expect(.rejected(.authenticationRequired), .failure(error))
    }
    for reply: ViewedClient.Reply in [
      .failure(.httpStatus(403)), .failure(.httpStatus(429)), .failure(.httpStatus(500)),
      .failure(.executionFailed), .network(.timedOut), .network(.networkConnectionLost), .cancelled,
    ] {
      await expect(.needsVerification, reply)
    }
  }

  @Test
  func keepsTheReceiptIfTheClientReturnsItAfterCancellation() async {
    await Task {
      await expect(
        .confirmed(pullRequestID: pullRequestID),
        .body(
          wire(pullRequestID: pullRequestID), cancelAfterResponse: true))
    }.value
  }

  private func expect(
    _ expected: PRFileViewedWriter.Outcome,
    _ reply: ViewedClient.Reply,
    id: String? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
  ) async {
    let client = ViewedClient(reply)
    let result = await PRFileViewedWriter(client: client).setViewed(
      .init(pullRequestID: id ?? pullRequestID, path: "file", action: .mark))
    #expect(result == expected, sourceLocation: sourceLocation)
    #expect(
      await client.operations == ["MarkPullRequestFileAsViewed"], sourceLocation: sourceLocation)
  }
}

private struct OperationFixture {
  let action: PRFileViewedWriter.Action
  let operation: String
  let field: String
  let path: String
}

private func graphError(_ type: String, _ path: [Any]?) -> [String: Any] {
  var error: [String: Any] = ["message": "Controlled GraphQL error", "type": type]
  error["path"] = path
  return error
}

private func wire(
  field: String = "markFileAsViewed",
  pullRequestID: String?,
  hasPayload: Bool = true,
  errors: [[String: Any]] = []
) -> String {
  let pullRequest = pullRequestID.map { ["__typename": "PullRequest", "id": $0] }
  let payload: [String: Any] = [
    "__typename": field == "markFileAsViewed"
      ? "MarkFileAsViewedPayload" : "UnmarkFileAsViewedPayload",
    "pullRequest": pullRequest as Any? ?? NSNull(),
  ]
  var body: [String: Any] = ["data": [field: hasPayload ? payload as Any : NSNull()]]
  if !errors.isEmpty { body["errors"] = errors }
  guard let json = try? JSONSerialization.data(withJSONObject: body),
    let text = String(data: json, encoding: .utf8)
  else { preconditionFailure("Invalid controlled GraphQL response") }
  return text
}

private actor ViewedClient: GitHubGraphQLServing {
  enum Reply: Sendable {
    case body(String, cancelAfterResponse: Bool = false)
    case failure(GitHubGraphQLClientError)
    case network(URLError.Code)
    case cancelled
  }

  private let reply: Reply
  private let apollo: ApolloClient
  let session: ViewedSession
  private(set) var operations: [String] = []

  init(_ reply: Reply) {
    self.reply = reply
    if case .body(let json, _) = reply {
      session = ViewedSession(json: json)
    } else {
      session = ViewedSession(json: "")
    }
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    apollo = ApolloClient(
      networkTransport: RequestChainNetworkTransport(
        urlSession: session, interceptorProvider: DefaultInterceptorProvider.shared, store: store,
        endpointURL: URL(string: "https://api.github.com/graphql")!,
        apqConfig: .init(autoPersistQueries: false)),
      store: store)
  }

  func fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    operations.append(Query.operationName)
    throw GitHubGraphQLClientError.executionFailed
  }

  func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<
    Mutation
  >
  where Mutation.ResponseFormat == SingleResponseFormat {
    operations.append(Mutation.operationName)
    switch reply {
    case .body(_, let cancelAfterResponse):
      let response = try await apollo.perform(
        mutation: mutation, requestConfiguration: .init(writeResultsToCache: false))
      if cancelAfterResponse {
        withUnsafeCurrentTask { $0?.cancel() }
      }
      return response
    case .failure(let error):
      throw error
    case .network(let code):
      throw URLError(code)
    case .cancelled:
      throw CancellationError()
    }
  }
}

private actor ViewedSession: ApolloURLSession {
  let json: String
  private(set) var requests: [URLRequest] = []

  init(json: String) {
    self.json = json
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requests.append(request)
    let response = HTTPURLResponse(
      url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"])!
    return (ViewedChunks(data: Data(json.utf8)), response)
  }
}

private struct ViewedChunks: AsyncChunkSequence, AsyncIteratorProtocol {
  var data: Data?
  func makeAsyncIterator() -> Self { self }
  mutating func next() async -> Data? {
    defer { data = nil }
    return data
  }
}
