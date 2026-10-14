import Foundation
import RivetHTTPClient

/// 多 request 的組裝生命週期，共用 caller 保留的 credential provider。
/// Ready 僅表示本地準備完成，不保證遠端認證或權限。
public struct GitHubClientScope: Sendable {
  private let provider: OAuthTokenProvider
  public let rest: any GitHubRestClient
  public let graphql: any GitHubGraphQLServing

  // private provider 使合成的 memberwise initializer 保持 private。

  public static func prepare(provider: OAuthTokenProvider) async throws -> GitHubClientScope {
    try await prepare(provider: provider) { provider in
      (GitHubHTTPClient(provider: provider), GitHubGraphQLClient(provider: provider))
    }
  }

  // 僅供內部組裝驗證；production 保持各 client 的 transport policy。
  internal static func prepare(
    provider: OAuthTokenProvider,
    makeClients:
      @Sendable (OAuthTokenProvider) -> (
        rest: any GitHubRestClient, graphql: any GitHubGraphQLServing
      )
  ) async throws -> GitHubClientScope {
    try Task.checkCancellation()
    let snapshot: TokenSnapshot
    do {
      snapshot = try await provider.snapshot()
    } catch {
      if Task.isCancelled || isCancellation(error) { throw CancellationError() }
      throw preparationError(error)
    }
    try Task.checkCancellation()
    do {
      _ = try BearerAuth(token: snapshot.accessToken.rawValue)
    } catch {
      if Task.isCancelled { throw CancellationError() }
      throw GitHubClientPreparationError.invalidAuthorizationToken
    }
    let clients = makeClients(provider)
    try Task.checkCancellation()
    return GitHubClientScope(provider: provider, rest: clients.rest, graphql: clients.graphql)
  }

  private static func isCancellation(_ error: any Error) -> Bool {
    if error is CancellationError { return true }
    if let error = error as? URLError, error.code == .cancelled { return true }
    if let error = error as? OAuthTokenRefreshError, case .cancelled = error { return true }
    guard let error = error as? OAuthTokenProviderError else { return false }
    switch error {
    case .missingCredential, .authenticationRequired: return false
    case .restore(let underlying), .refresh(let underlying), .persist(let underlying):
      return isCancellation(underlying)
    }
  }

  private static func preparationError(
    _ error: OAuthTokenProviderError
  ) -> GitHubClientPreparationError {
    switch error {
    case .missingCredential: .missingCredential
    case .authenticationRequired: .authenticationRequired
    case .restore: .credentialLifecycle(stage: .restore)
    case .refresh: .credentialLifecycle(stage: .refresh)
    case .persist: .credentialLifecycle(stage: .persist)
    }
  }
}
