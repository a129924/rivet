import Apollo
@_spi(Execution) @_spi(Unsafe) import ApolloAPI
import Foundation

@testable import GitHubIntegration

struct ProbeQuery: GraphQLQuery {
  typealias Data = ProbeData
  static let operationName = "InfrastructureProbe"
  static let operationDocument = OperationDocument(
    operationIdentifier: "test-only-probe",
    definition: .init("query InfrastructureProbe($value: String!) { probe(value: $value) }")
  )
  let value: String
  // Apollo's test operation must implement this exact protocol witness.
  // swiftlint:disable identifier_name
  // swift-format-ignore: AlwaysUseLowerCamelCase
  var __variables: Variables? { ["value": value] }
  // swiftlint:enable identifier_name
}

struct ProbeData: RootSelectionSet {
  typealias Schema = ProbeSchema
  // Exact Apollo selection-set witnesses; these names cannot be changed.
  // swiftlint:disable identifier_name
  // swift-format-ignore: AlwaysUseLowerCamelCase
  static let __parentType: any ParentType = ProbeSchema.query
  // swift-format-ignore: AlwaysUseLowerCamelCase
  static var __selections: [Selection] { [.field("probe", String?.self)] }
  // swift-format-ignore: AlwaysUseLowerCamelCase
  static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }
  // swift-format-ignore: AlwaysUseLowerCamelCase
  let __data: DataDict
  // swiftlint:enable identifier_name
  init(_dataDict dataDict: DataDict) { __data = dataDict }
  var probe: String? { __data["probe"] }
}

enum ProbeSchema: SchemaMetadata {
  static let query = Object(typename: "Query", implementedInterfaces: [])
  static var configuration: any SchemaConfiguration.Type { ProbeConfiguration.self }
  static func objectType(forTypename typename: String) -> Object? {
    typename == "Query" ? query : nil
  }
}

enum ProbeConfiguration: SchemaConfiguration {
  static func cacheKeyInfo(for type: Object, object: ObjectData) -> CacheKeyInfo? { nil }
}

let graphQLTestDate = Date(timeIntervalSince1970: 1_000)

func graphQLCredential(_ token: String) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: token),
    refreshToken: .init(rawValue: "test-refresh"),
    accessTokenExpiresAt: graphQLTestDate.addingTimeInterval(100),
    refreshTokenExpiresAt: graphQLTestDate.addingTimeInterval(1_000),
    tokenType: .bearer,
    grantedScopes: ""
  )
}

actor GraphQLGate {
  private var arrived = false
  private var opened = false
  private var arrivals: [CheckedContinuation<Void, Never>] = []
  private var waiters: [CheckedContinuation<Void, Never>] = []

  func enter() async {
    arrived = true
    for arrival in arrivals { arrival.resume() }
    arrivals.removeAll()
    if !opened {
      await withCheckedContinuation { waiters.append($0) }
    }
  }

  func waitForArrival() async {
    if !arrived {
      await withCheckedContinuation { arrivals.append($0) }
    }
  }

  func open() {
    opened = true
    for waiter in waiters { waiter.resume() }
    waiters.removeAll()
  }
}

actor GraphQLCredentialStore: OAuthCredentialStore {
  let credential: GitHubOAuthCredentialBundle?
  let loadError: (any Error & Sendable)?
  let saveError: (any Error & Sendable)?
  let loadGate: GraphQLGate?
  private(set) var loads = 0
  private(set) var saves = 0

  init(
    credential: GitHubOAuthCredentialBundle? = graphQLCredential("initial"),
    loadError: (any Error & Sendable)? = nil,
    saveError: (any Error & Sendable)? = nil,
    loadGate: GraphQLGate? = nil
  ) {
    self.credential = credential
    self.loadError = loadError
    self.saveError = saveError
    self.loadGate = loadGate
  }

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    if let loadGate { await loadGate.enter() }
    if let loadError { throw loadError }
    return credential
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    if let saveError { throw saveError }
  }
}

actor GraphQLTokenFetcher: OAuthTokenFetcher {
  typealias Credential = GitHubOAuthCredentialBundle
  let error: (any Error & Sendable)?
  let gate: GraphQLGate?
  private(set) var calls = 0
  private(set) var wasCancelled = false

  init(error: (any Error & Sendable)? = nil, gate: GraphQLGate? = nil) {
    self.error = error
    self.gate = gate
  }

  func refresh(_ credential: Credential) async throws(any Error & Sendable) -> Credential {
    calls += 1
    if let gate { await gate.enter() }
    wasCancelled = Task.isCancelled
    if let error { throw error }
    return graphQLCredential("replacement")
  }
}

actor GraphQLStubExecutor: ApolloGraphQLExecuting {
  private var statuses: [Int]
  let error: (any Error & Sendable)?
  let gate: GraphQLGate?
  private(set) var tokens: [String] = []
  private(set) var queries: [String] = []

  init(statuses: [Int] = [200], error: (any Error & Sendable)? = nil, gate: GraphQLGate? = nil) {
    self.statuses = statuses
    self.error = error
    self.gate = gate
  }

  func fetch<Query: GraphQLQuery>(
    query: Query,
    accessToken: GitHubAccessToken
  ) async throws -> GraphQLResponse<Query> where Query.ResponseFormat == SingleResponseFormat {
    tokens.append(accessToken.rawValue)
    queries.append(String(describing: query))
    if let gate { await gate.enter() }
    if let error { throw error }
    let status = statuses.isEmpty ? 200 : statuses.removeFirst()
    if status != 200 { throw GitHubGraphQLClientError.httpStatus(status) }
    return .init(data: nil, extensions: nil, errors: nil, source: .server, dependentKeys: nil)
  }
}

enum GraphQLTestFailure: Error, Sendable { case expected }
