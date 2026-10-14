import Foundation
import Testing

@Suite("GraphQL internal boundary")
struct GraphQLIsolationTests {
  @Test
  func sessionValidatesResponseBeforeEnteringApollo() throws {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    let executor = try String(
      contentsOf: root.appendingPathComponent(
        "Sources/BoundedContexts/GitHubIntegration/GraphQL/ApolloGraphQLClient.swift"),
      encoding: .utf8)
    #expect(executor.contains("urlSession: GitHubGraphQLHTTPSession(base: session)"))
    #expect(executor.contains("guard response is HTTPURLResponse else"))
  }

  @Test
  func clientAndExecutorRemainInternalQueryAndMutation() throws {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    let directory = root.appendingPathComponent("Sources/BoundedContexts/GitHubIntegration/GraphQL")
    let client = try String(
      contentsOf: directory.appendingPathComponent("GitHubGraphQLClient.swift"), encoding: .utf8)
    let executor = try String(
      contentsOf: directory.appendingPathComponent("ApolloGraphQLClient.swift"), encoding: .utf8)
    #expect(client.contains("internal final class GitHubGraphQLClient"))
    #expect(client.contains("maximumAuthenticationRecoveries = 1"))
    #expect(client.contains("func fetch<Query: GraphQLQuery>"))
    #expect(executor.contains("internal protocol ApolloGraphQLExecuting: Sendable"))
    #expect(client.contains("GitHubGraphQLClient: GitHubGraphQLServing"))
    #expect(!client.contains("public "))
    let serving = try String(
      contentsOf: directory.appendingPathComponent("GitHubGraphQLServing.swift"), encoding: .utf8)
    #expect(serving.contains("public protocol GitHubGraphQLServing: Sendable"))
    #expect(serving.contains("Query.ResponseFormat == SingleResponseFormat"))
    #expect(serving.contains("Mutation.ResponseFormat == SingleResponseFormat"))
    #expect(!executor.contains("public "))
    #expect(client.contains("func perform<Mutation: GraphQLMutation>"))
    #expect(executor.contains("func perform<Mutation: GraphQLMutation>"))
    #expect(!client.contains("GraphQLSubscription"))
  }
}
