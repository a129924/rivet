import Apollo
import ApolloAPI
import Foundation

internal protocol ApolloGraphQLExecuting: Sendable {
  func fetch<Query: GraphQLQuery>(
    query: Query,
    accessToken: GitHubAccessToken
  ) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat
}

internal final class ApolloGraphQLClient: ApolloGraphQLExecuting {
  private let client: ApolloClient

  internal init(
    session: any ApolloURLSession = URLSession.shared,
    store: ApolloStore = ApolloStore(cache: InMemoryNormalizedCache())
  ) {
    let transport = RequestChainNetworkTransport(
      urlSession: GitHubGraphQLHTTPSession(base: session),
      interceptorProvider: GitHubGraphQLInterceptorProvider(),
      store: store,
      endpointURL: URL(string: "https://api.github.com/graphql")!,
      apqConfig: .init(autoPersistQueries: false),
      useGETForQueries: false
    )
    client = ApolloClient(networkTransport: transport, store: store)
  }

  internal func fetch<Query: GraphQLQuery>(
    query: Query,
    accessToken: GitHubAccessToken
  ) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    try await GitHubGraphQLHTTPInterceptor.$accessToken.withValue(accessToken) {
      try await client.fetch(
        query: query,
        cachePolicy: .networkOnly,
        requestConfiguration: .init(writeResultsToCache: false)
      )
    }
  }
}

private struct GitHubGraphQLHTTPSession: ApolloURLSession {
  let base: any ApolloURLSession

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    let (chunks, response) = try await base.chunks(for: request)
    guard response is HTTPURLResponse else {
      throw GitHubGraphQLClientError.executionFailed
    }
    return (chunks, response)
  }
}

private struct GitHubGraphQLInterceptorProvider: InterceptorProvider {
  func graphQLInterceptors<Operation: GraphQLOperation>(
    for operation: Operation
  ) -> [any GraphQLInterceptor] {
    [MaxRetryInterceptor(maxRetriesAllowed: 0)]
  }

  func httpInterceptors<Operation: GraphQLOperation>(
    for operation: Operation
  ) -> [any HTTPInterceptor] {
    [GitHubGraphQLHTTPInterceptor()]
  }
}
