import Apollo
import ApolloAPI

/// 供 consuming infrastructure 使用的 GraphQL technical capability。
public protocol GitHubGraphQLServing: Sendable {
  func fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat

  func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<
    Mutation
  >
  where Mutation.ResponseFormat == SingleResponseFormat
}
