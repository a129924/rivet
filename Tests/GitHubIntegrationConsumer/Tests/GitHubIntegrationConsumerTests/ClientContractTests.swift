import Apollo
@_spi(Execution) @_spi(Unsafe) import ApolloAPI
import Foundation
import GitHubIntegration
import RivetHTTPClient
import Testing

@Suite("Public dual-client contracts")
struct ClientContractTests {
  @Test
  func restRequirementsAndDefaultBuildersWorkThroughNormalImport() async throws {
    let fake = ConsumerREST()
    let client: any GitHubRestClient = fake
    let url = try HTTPURL(URL(string: "https://offline.example/probe")!)
    let headers: HTTPHeaders = [.custom("X-Fixture"): "kept"]
    let body = Data("fixture".utf8)
    let responses = [
      try await client.get(url: url, headers: headers, body: body),
      try await client.post(url: url, headers: headers, body: body),
      try await client.put(url: url, headers: headers, body: body),
      try await client.patch(url: url, headers: headers, body: body),
      try await client.executeGet(
        HTTPRequest(url: url, method: .get, headers: headers, body: body)),
      try await client.executePost(
        HTTPRequest(url: url, method: .post, headers: headers, body: body)),
      try await client.executePut(
        HTTPRequest(url: url, method: .put, headers: headers, body: body)),
      try await client.executePatch(
        HTTPRequest(url: url, method: .patch, headers: headers, body: body)),
    ]
    #expect(responses.allSatisfy { $0.statusCode == 429 && $0.body == body })
    let requests = await fake.requests
    #expect(requests.map(\.method) == [.get, .post, .put, .patch, .get, .post, .put, .patch])
    #expect(requests.allSatisfy { $0.url == url && $0.headers == headers && $0.body == body })
  }

  @Test
  func graphQLQueryAndMutationUseAnOfflineInjectedContract() async throws {
    let fake = ConsumerGraphQL()
    let client: any GitHubGraphQLServing = fake
    let query = try await client.fetch(query: ConsumerProbeQuery(value: "query"))
    let mutation = try await client.perform(mutation: ConsumerProbeMutation(value: "mutation"))
    #expect(query.errors?.first?.message == "offline errors-only response")
    #expect(mutation.errors?.first?.message == "offline errors-only response")
    #expect(query.data == nil)
    #expect(mutation.data == nil)
    #expect(await fake.queries == 1)
    #expect(await fake.mutations == 1)
  }

  @Test
  func publicScopeAndSafeErrorsAreAvailableWithoutTestableImport() async throws {
    let provider = OAuthTokenProvider(store: ConsumerCredentials(), fetcher: ConsumerRefresh())
    let scope = try await GitHubClientScope.prepare(provider: provider)
    requireSendable(scope)
    requireSendable(scope.rest)
    requireSendable(scope.graphql)
    let errors: [GitHubClientPreparationError] = [
      .missingCredential, .authenticationRequired, .credentialLifecycle(stage: .restore),
      .credentialLifecycle(stage: .refresh), .credentialLifecycle(stage: .persist),
      .invalidAuthorizationToken,
    ]
    for error in errors {
      requireSendable(error)
      #expect(!String(reflecting: error).contains("offline-access"))
      #expect(!String(reflecting: error).contains("underlying"))
    }
    requireSendable(GitHubHTTPClientError.credentialLifecycle(stage: .persist))
    requireSendable(GitHubGraphQLClientError.credentialLifecycle(stage: .refresh))
    requireSendable(GitHubGraphQLClientError.httpStatus(403))
  }
}

private func requireSendable<Value: Sendable>(_ value: Value) {}

private actor ConsumerREST: GitHubRestClient {
  private(set) var requests: [HTTPRequest] = []
  private func respond(_ request: HTTPRequest) -> RivetHTTPClient.HTTPResponse {
    requests.append(request)
    return RivetHTTPClient.HTTPResponse(statusCode: 429, headers: [:], body: request.body ?? Data())
  }
  func executeGet(_ request: HTTPRequest) async throws -> RivetHTTPClient.HTTPResponse {
    respond(request)
  }
  func executePost(_ request: HTTPRequest) async throws -> RivetHTTPClient.HTTPResponse {
    respond(request)
  }
  func executePut(_ request: HTTPRequest) async throws -> RivetHTTPClient.HTTPResponse {
    respond(request)
  }
  func executePatch(_ request: HTTPRequest) async throws -> RivetHTTPClient.HTTPResponse {
    respond(request)
  }
}

private actor ConsumerGraphQL: GitHubGraphQLServing {
  private(set) var queries = 0
  private(set) var mutations = 0
  func fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    queries += 1
    return .init(
      data: nil, extensions: nil,
      errors: [GraphQLError(["message": "offline errors-only response"])],
      source: .server, dependentKeys: nil)
  }
  func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<
    Mutation
  >
  where Mutation.ResponseFormat == SingleResponseFormat {
    mutations += 1
    return .init(
      data: nil, extensions: nil,
      errors: [GraphQLError(["message": "offline errors-only response"])],
      source: .server, dependentKeys: nil)
  }
}

private struct ConsumerCredentials: OAuthCredentialStore {
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    .init(
      accessToken: .init(rawValue: "offline-access"),
      refreshToken: .init(rawValue: "offline-refresh"),
      accessTokenExpiresAt: .distantFuture, refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer, grantedScopes: "")
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {}
}

private struct ConsumerRefresh: OAuthTokenFetcher {
  typealias Credential = GitHubOAuthCredentialBundle
  func refresh(
    _ credential: Credential
  ) async throws(OAuthTokenRefreshError) -> Credential {
    Issue.record("Valid local readiness must not refresh")
    throw .knownTechnicalFailure
  }
}

struct ConsumerProbeQuery: GraphQLQuery {
  typealias Data = ConsumerProbeData
  static let operationName = "InfrastructureConsumerProbe"
  static let operationDocument = OperationDocument(
    operationIdentifier: "test-only-probe",
    definition: .init("query InfrastructureConsumerProbe($value: String!) { probe(value: $value) }")
  )
  let value: String
  // Apollo's test operation must implement this exact protocol witness.
  // swiftlint:disable identifier_name
  // swift-format-ignore: AlwaysUseLowerCamelCase
  var __variables: Variables? { ["value": value] }
  // swiftlint:enable identifier_name
}

struct ConsumerProbeData: RootSelectionSet {
  typealias Schema = ConsumerProbeSchema
  // Exact Apollo selection-set witnesses; these names cannot be changed.
  // swiftlint:disable identifier_name
  // swift-format-ignore: AlwaysUseLowerCamelCase
  static let __parentType: any ParentType = ConsumerProbeSchema.query
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

struct ConsumerProbeMutation: GraphQLMutation {
  typealias Data = ConsumerProbeMutationData
  static let operationName = "InfrastructureMutationConsumerProbe"
  static let operationDocument = OperationDocument(
    operationIdentifier: "test-only-mutation-probe",
    definition: .init(
      "mutation InfrastructureMutationConsumerProbe($value: String!) { probe(value: $value) }")
  )
  let value: String
  // Apollo's test operation must implement this exact protocol witness.
  // swiftlint:disable identifier_name
  // swift-format-ignore: AlwaysUseLowerCamelCase
  var __variables: Variables? { ["value": value] }
  // swiftlint:enable identifier_name
}

struct ConsumerProbeMutationData: RootSelectionSet {
  typealias Schema = ConsumerProbeSchema
  // Exact Apollo selection-set witnesses; these names cannot be changed.
  // swiftlint:disable identifier_name
  // swift-format-ignore: AlwaysUseLowerCamelCase
  static let __parentType: any ParentType = ConsumerProbeSchema.mutation
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

enum ConsumerProbeSchema: SchemaMetadata {
  static let mutation = Object(typename: "Mutation", implementedInterfaces: [])
  static let query = Object(typename: "Query", implementedInterfaces: [])
  static var configuration: any SchemaConfiguration.Type { ConsumerProbeConfiguration.self }
  static func objectType(forTypename typename: String) -> Object? {
    switch typename {
    case "Query": query
    case "Mutation": mutation
    default: nil
    }
  }
}

enum ConsumerProbeConfiguration: SchemaConfiguration {
  static func cacheKeyInfo(for type: Object, object: ObjectData) -> CacheKeyInfo? { nil }
}
