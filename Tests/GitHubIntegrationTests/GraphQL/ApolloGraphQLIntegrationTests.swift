import Apollo
import Foundation
import Testing

@testable import GitHubIntegration

@Suite("Apollo GitHub GraphQL request chain")
struct ApolloGraphQLIntegrationTests {
  @Test(arguments: ["", "not-json"])
  func unauthorizedBeforeParsingRecoversAndPreservesBody(_ rejectedBody: String) async throws {
    let session = GraphQLSession(replies: [.init(401, rejectedBody), .init()])
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let response = try await GitHubGraphQLClient(
      provider: provider, executor: ApolloGraphQLClient(session: session)
    )
    .fetch(query: ProbeQuery(value: "same-value"))
    #expect(response.data?.probe == "ok")
    let requests = await session.requests
    #expect(requests.count == 2)
    #expect(requests[0].url?.absoluteString == "https://api.github.com/graphql")
    #expect(requests[0].httpMethod == "POST")
    #expect(requests[0].httpBody == requests[1].httpBody)
    #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer initial")
    #expect(requests[1].value(forHTTPHeaderField: "Authorization") == "Bearer replacement")
    let bodyData = try #require(requests[0].httpBody)
    let body = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
    #expect((body["variables"] as? [String: String]) == ["value": "same-value"])
    #expect((body["query"] as? String)?.contains("InfrastructureProbe") == true)
    #expect((body["extensions"] as? [String: Any])?["persistedQuery"] == nil)
    #expect(await fetcher.calls == 1)
  }

  @Test
  func emptySecondUnauthorizedIsTerminalAndEmptyForbiddenDoesNotRefresh() async throws {
    for status in [401, 403] {
      let session = GraphQLSession(
        replies: status == 401 ? [.init(401, ""), .init(401, "")] : [.init(403, "")])
      let fetcher = GraphQLTokenFetcher()
      let provider = OAuthTokenProvider(
        store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
      let expected: GitHubGraphQLClientError =
        status == 401 ? .authenticationRequired : .httpStatus(403)
      await #expect(throws: expected) {
        try await GitHubGraphQLClient(
          provider: provider, executor: ApolloGraphQLClient(session: session)
        )
        .fetch(query: ProbeQuery(value: "same"))
      }
      #expect(await session.requests.count == (status == 401 ? 2 : 1))
      #expect(await fetcher.calls == (status == 401 ? 1 : 0))
    }
  }

  @Test
  func partialAndErrorsOnlyResponsesPassThroughWithoutAPQRetry() async throws {
    for body in [
      #"{"data":{"probe":"partial"},"errors":[{"message":"partial failure"}]}"#,
      #"{"errors":[{"message":"PersistedQueryNotFound","extensions":{"code":"PERSISTED_QUERY_NOT_FOUND"}}]}"#,
    ] {
      let session = GraphQLSession(replies: [.init(200, body)])
      let fetcher = GraphQLTokenFetcher()
      let provider = OAuthTokenProvider(
        store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
      let result = try await GitHubGraphQLClient(
        provider: provider, executor: ApolloGraphQLClient(session: session)
      )
      .fetch(query: ProbeQuery(value: "same"))
      #expect(result.errors?.count == 1)
      #expect(result.data?.probe == (body.contains("partial failure") ? "partial" : nil))
      #expect(await session.requests.count == 1)
      #expect(await fetcher.calls == 0)
    }
  }

  @Test
  func networkParserAndHTTPFailuresHaveNoHiddenRetries() async throws {
    let cases: [(GraphQLSession, GitHubGraphQLClientError)] = [
      (GraphQLSession(error: URLError(.timedOut)), .executionFailed),
      (GraphQLSession(replies: [.init(200, "not-json")]), .executionFailed),
      (GraphQLSession(replies: [.init(500, "")]), .httpStatus(500)),
    ]
    for (session, expected) in cases {
      let fetcher = GraphQLTokenFetcher()
      let provider = OAuthTokenProvider(
        store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
      await #expect(throws: expected) {
        try await GitHubGraphQLClient(
          provider: provider, executor: ApolloGraphQLClient(session: session)
        )
        .fetch(query: ProbeQuery(value: "same"))
      }
      #expect(await session.requests.count == 1)
      #expect(await fetcher.calls == 0)
    }
  }

  @Test
  func nonHTTPResponseFailsWithoutRecoveryOrRetry() async throws {
    let session = GraphQLSession(nonHTTPResponse: true)
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    await #expect(throws: GitHubGraphQLClientError.executionFailed) {
      try await GitHubGraphQLClient(
        provider: provider, executor: ApolloGraphQLClient(session: session)
      )
      .fetch(query: ProbeQuery(value: "same"))
    }
    #expect(await session.requests.count == 1)
    #expect(await fetcher.calls == 0)
  }

  @Test
  func networkOnlyNeitherReadsNorWritesNormalizedCache() async throws {
    let cache = GraphQLCacheProbe()
    let session = GraphQLSession()
    let executor = ApolloGraphQLClient(session: session, store: ApolloStore(cache: cache))
    _ = try await executor.fetch(
      query: ProbeQuery(value: "same"), accessToken: .init(rawValue: "initial"))
    #expect(await cache.reads == 0)
    #expect(await cache.writes == 0)
    #expect(await session.requests.count == 1)
  }

  @Test
  func concurrentExecutionsKeepTaskLocalBearerSeparate() async throws {
    let gate = GraphQLGate()
    let session = GraphQLSession(initialGate: gate)
    let executor = ApolloGraphQLClient(session: session)
    let first = Task {
      try await executor.fetch(
        query: ProbeQuery(value: "first"), accessToken: .init(rawValue: "initial"))
    }
    await gate.waitForArrival()
    let second = Task {
      try await executor.fetch(
        query: ProbeQuery(value: "second"), accessToken: .init(rawValue: "second-token"))
    }
    _ = try await second.value
    await gate.open()
    _ = try await first.value
    let requests = await session.requests
    #expect(requests.count == 2)
    #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer initial")
    #expect(requests[1].value(forHTTPHeaderField: "Authorization") == "Bearer second-token")
  }

  @Test
  func concurrentUnauthorizedQueriesShareProviderRefresh() async throws {
    let requestsGate = GraphQLGate()
    let refreshGate = GraphQLGate()
    let joinGate = GraphQLGate()
    let session = GraphQLSession(
      replies: [.init(401, ""), .init(401, ""), .init(), .init()], initialGate: requestsGate)
    let fetcher = GraphQLTokenFetcher(gate: refreshGate)
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate },
      onInFlightTaskJoin: { await joinGate.enter() }
    )
    _ = try await provider.snapshot()
    let client = GitHubGraphQLClient(
      provider: provider, executor: ApolloGraphQLClient(session: session))
    let first = Task { try await client.fetch(query: ProbeQuery(value: "first")) }
    await session.waitForRequests(1)
    let second = Task { try await client.fetch(query: ProbeQuery(value: "second")) }
    await session.waitForRequests(2)
    await requestsGate.open()
    await refreshGate.waitForArrival()
    await joinGate.waitForArrival()
    await joinGate.open()
    await refreshGate.open()
    _ = try await first.value
    _ = try await second.value
    #expect(await fetcher.calls == 1)
    #expect(await session.requests.count == 4)
    let replacements = await session.requests.suffix(2).map {
      $0.value(forHTTPHeaderField: "Authorization")
    }
    #expect(replacements == ["Bearer replacement", "Bearer replacement"])
  }
}
