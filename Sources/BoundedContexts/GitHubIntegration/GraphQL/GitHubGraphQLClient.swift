import Apollo
import ApolloAPI
import Foundation

internal final class GitHubGraphQLClient: Sendable {
  private static let maximumAuthenticationRecoveries = 1
  private let provider: OAuthTokenProvider
  private let executor: any ApolloGraphQLExecuting

  internal init(provider: OAuthTokenProvider) {
    self.provider = provider
    executor = ApolloGraphQLClient()
  }

  internal init(provider: OAuthTokenProvider, executor: any ApolloGraphQLExecuting) {
    self.provider = provider
    self.executor = executor
  }

  internal func fetch<Query: GraphQLQuery>(
    query: Query
  ) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    var snapshot = try await atAsyncBoundary { try await provider.snapshot() }
    var recoveries = 0
    while true {
      do {
        return try await atAsyncBoundary {
          try await executor.fetch(query: query, accessToken: snapshot.accessToken)
        }
      } catch GitHubGraphQLClientError.httpStatus(401) {
        guard recoveries < Self.maximumAuthenticationRecoveries else {
          throw GitHubGraphQLClientError.authenticationRequired
        }
        let rejectedSnapshot = snapshot
        snapshot = try await atAsyncBoundary {
          try await provider.replacementSnapshot(afterUnauthorized: rejectedSnapshot)
        }
        recoveries += 1
      }
    }
  }

  private func atAsyncBoundary<Value: Sendable>(
    _ operation: () async throws -> Value
  ) async throws -> Value {
    try Task.checkCancellation()
    do {
      let value = try await operation()
      try Task.checkCancellation()
      return value
    } catch {
      if Task.isCancelled || isCancellation(error) {
        throw CancellationError()
      }
      throw map(error)
    }
  }

  private func isCancellation(_ error: any Error) -> Bool {
    if error is CancellationError { return true }
    if let error = error as? URLError, error.code == .cancelled { return true }
    if let error = error as? OAuthTokenRefreshError, case .cancelled = error { return true }
    guard let error = error as? OAuthTokenProviderError else { return false }
    switch error {
    case .missingCredential, .authenticationRequired:
      return false
    case .restore(let underlying), .refresh(let underlying), .persist(let underlying):
      return isCancellation(underlying)
    }
  }

  private func map(_ error: any Error) -> GitHubGraphQLClientError {
    if let error = error as? GitHubGraphQLClientError { return error }
    guard let error = error as? OAuthTokenProviderError else { return .executionFailed }
    switch error {
    case .missingCredential, .authenticationRequired: return .authenticationRequired
    case .restore: return .credentialLifecycle(stage: .restore)
    case .refresh: return .credentialLifecycle(stage: .refresh)
    case .persist: return .credentialLifecycle(stage: .persist)
    }
  }
}
