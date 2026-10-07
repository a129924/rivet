import Apollo
import Foundation
import Testing

@testable import GitHubIntegration

@Suite("GitHub GraphQL auth wrapper")
struct GitHubGraphQLClientTests {
  @Test
  func unauthorizedRecoversOnceWithReplacementTokenAndOriginalQuery() async throws {
    let store = GraphQLCredentialStore()
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
    let executor = GraphQLStubExecutor(statuses: [401, 200])
    let client = GitHubGraphQLClient(provider: provider, executor: executor)
    _ = try await client.fetch(query: ProbeQuery(value: "same"))
    #expect(await executor.tokens == ["initial", "replacement"])
    #expect(await executor.queries.count == 2)
    #expect(await executor.queries.first == executor.queries.last)
    #expect(await fetcher.calls == 1)
    #expect(await store.saves == 1)
  }

  @Test
  func secondUnauthorizedIsTerminal() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let executor = GraphQLStubExecutor(statuses: [401, 401, 200])
    let client = GitHubGraphQLClient(provider: provider, executor: executor)
    await #expect(throws: GitHubGraphQLClientError.authenticationRequired) {
      try await client.fetch(query: ProbeQuery(value: "same"))
    }
    #expect(await executor.tokens.count == 2)
    #expect(await fetcher.calls == 1)
  }

  @Test(arguments: [403, 404, 429, 500])
  func otherHTTPFailuresDoNotRecover(_ status: Int) async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let executor = GraphQLStubExecutor(statuses: [status])
    await #expect(throws: GitHubGraphQLClientError.httpStatus(status)) {
      try await GitHubGraphQLClient(provider: provider, executor: executor).fetch(
        query: ProbeQuery(value: "same"))
    }
    #expect(await fetcher.calls == 0)
    #expect(await executor.tokens.count == 1)
  }

  @Test
  func missingCredentialIsAuthenticationRequired() async throws {
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(credential: nil), fetcher: GraphQLTokenFetcher())
    let executor = GraphQLStubExecutor()
    await #expect(throws: GitHubGraphQLClientError.authenticationRequired) {
      try await GitHubGraphQLClient(provider: provider, executor: executor).fetch(
        query: ProbeQuery(value: "same"))
    }
    #expect(await executor.tokens.isEmpty)
  }

  @Test
  func restoreRefreshAndPersistFailuresPreserveStage() async throws {
    for stage in [GitHubGraphQLClientError.CredentialLifecycleStage.restore, .refresh, .persist] {
      let store = GraphQLCredentialStore(
        loadError: stage == .restore ? GraphQLTestFailure.expected : nil,
        saveError: stage == .persist ? GraphQLTestFailure.expected : nil
      )
      let fetcher = GraphQLTokenFetcher(
        error: stage == .refresh ? GraphQLTestFailure.expected : nil)
      let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
      let executor = GraphQLStubExecutor(statuses: [401])
      await #expect(throws: GitHubGraphQLClientError.credentialLifecycle(stage: stage)) {
        try await GitHubGraphQLClient(provider: provider, executor: executor).fetch(
          query: ProbeQuery(value: "same"))
      }
      #expect(await executor.tokens.count == (stage == .restore ? 0 : 1))
    }
  }

  @Test
  func executionFailureIsFiniteAndDoesNotRecover() async throws {
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let executor = GraphQLStubExecutor(error: GraphQLTestFailure.expected)
    await #expect(throws: GitHubGraphQLClientError.executionFailed) {
      try await GitHubGraphQLClient(provider: provider, executor: executor).fetch(
        query: ProbeQuery(value: "same"))
    }
    #expect(await fetcher.calls == 0)
  }

  @Test
  func cancelledTransportAndWrappedProviderCancellationNormalize() async throws {
    for error in [CancellationError() as any Error & Sendable, URLError(.cancelled)] {
      let provider = OAuthTokenProvider(
        store: GraphQLCredentialStore(), fetcher: GraphQLTokenFetcher(), now: { graphQLTestDate })
      await #expect(throws: CancellationError.self) {
        try await GitHubGraphQLClient(
          provider: provider, executor: GraphQLStubExecutor(error: error)
        )
        .fetch(query: ProbeQuery(value: "same"))
      }
      let wrapped = OAuthTokenProvider(
        store: GraphQLCredentialStore(loadError: error),
        fetcher: GraphQLTokenFetcher()
      )
      await #expect(throws: CancellationError.self) {
        try await GitHubGraphQLClient(provider: wrapped, executor: GraphQLStubExecutor())
          .fetch(query: ProbeQuery(value: "same"))
      }
    }
  }

  @Test
  func callerCancellationBeatsUnauthorizedAndPreventsRecovery() async throws {
    let gate = GraphQLGate()
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let executor = GraphQLStubExecutor(statuses: [401], gate: gate)
    let client = GitHubGraphQLClient(provider: provider, executor: executor)
    let task = Task { try await client.fetch(query: ProbeQuery(value: "same")) }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await fetcher.calls == 0)
    #expect(await executor.tokens.count == 1)
  }

  @Test
  func cancellationDuringRecoveryDoesNotCancelSharedRefreshOrSendRetry() async throws {
    let gate = GraphQLGate()
    let fetcher = GraphQLTokenFetcher(gate: gate)
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let executor = GraphQLStubExecutor(statuses: [401, 200])
    let task = Task {
      try await GitHubGraphQLClient(provider: provider, executor: executor).fetch(
        query: ProbeQuery(value: "same"))
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await executor.tokens.count == 1)
    #expect(await fetcher.calls == 1)
    #expect(await fetcher.wasCancelled == false)
    #expect(try await provider.snapshot().accessToken.rawValue == "replacement")
  }

  @Test
  func alreadyCancelledCallerDoesNotAcquireOrSend() async throws {
    let gate = GraphQLGate()
    let store = GraphQLCredentialStore()
    let provider = OAuthTokenProvider(store: store, fetcher: GraphQLTokenFetcher())
    let executor = GraphQLStubExecutor()
    let task = Task {
      await gate.enter()
      return try await GitHubGraphQLClient(provider: provider, executor: executor)
        .fetch(query: ProbeQuery(value: "same"))
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await store.loads == 0)
    #expect(await executor.tokens.isEmpty)
  }

  @Test
  func cancellationDuringRestoreDoesNotSendAfterProviderReturns() async throws {
    let gate = GraphQLGate()
    let store = GraphQLCredentialStore(loadGate: gate)
    let provider = OAuthTokenProvider(
      store: store, fetcher: GraphQLTokenFetcher(), now: { graphQLTestDate })
    let executor = GraphQLStubExecutor()
    let task = Task {
      try await GitHubGraphQLClient(provider: provider, executor: executor)
        .fetch(query: ProbeQuery(value: "same"))
    }
    await gate.waitForArrival()
    task.cancel()
    await gate.open()
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(await executor.tokens.isEmpty)
    #expect(try await provider.snapshot().accessToken.rawValue == "initial")
  }

  @Test
  func refreshAndPersistWrappedCancellationRemainCancellation() async throws {
    for stage in [GitHubGraphQLClientError.CredentialLifecycleStage.refresh, .persist] {
      for error in [CancellationError() as any Error & Sendable, URLError(.cancelled)] {
        let store = GraphQLCredentialStore(saveError: stage == .persist ? error : nil)
        let fetcher = GraphQLTokenFetcher(error: stage == .refresh ? error : nil)
        let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { graphQLTestDate })
        let executor = GraphQLStubExecutor(statuses: [401])
        await #expect(throws: CancellationError.self) {
          try await GitHubGraphQLClient(provider: provider, executor: executor)
            .fetch(query: ProbeQuery(value: "same"))
        }
        #expect(await executor.tokens.count == 1)
        #expect(await fetcher.calls == 1)
      }
    }
  }

  @Test
  func rejectedOriginalSnapshotUsesProviderStaleVersionFastPath() async throws {
    let gate = GraphQLGate()
    let fetcher = GraphQLTokenFetcher()
    let provider = OAuthTokenProvider(
      store: GraphQLCredentialStore(), fetcher: fetcher, now: { graphQLTestDate })
    let original = try await provider.snapshot()
    let executor = GraphQLStubExecutor(statuses: [401, 200], gate: gate)
    let task = Task {
      try await GitHubGraphQLClient(provider: provider, executor: executor)
        .fetch(query: ProbeQuery(value: "same"))
    }
    await gate.waitForArrival()
    let replacement = try await provider.replacementSnapshot(afterUnauthorized: original)
    #expect(replacement.version != original.version)
    await gate.open()
    _ = try await task.value
    #expect(await executor.tokens == ["initial", "replacement"])
    #expect(await fetcher.calls == 1)
  }
}
