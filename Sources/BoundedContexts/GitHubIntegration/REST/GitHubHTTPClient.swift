import Foundation
import RivetHTTPClient

internal final class GitHubHTTPClient: Sendable {
  private let provider: OAuthTokenProvider
  private let httpClient: HTTPClient

  internal init(provider: OAuthTokenProvider) {
    self.provider = provider
    httpClient = Self.makeHTTPClient()
  }

  internal static func makeHTTPClient(
    configuration: URLSessionConfiguration = .ephemeral
  ) -> HTTPClient {
    HTTPClient(transport: URLSessionTransport(session: makeSession(configuration: configuration)))
  }

  internal static func makeSession(
    configuration: URLSessionConfiguration = .ephemeral
  ) -> URLSession {
    URLSession(
      configuration: configuration,
      delegate: GitHubHTTPRedirectBlocker(),
      delegateQueue: nil)
  }

  // Internal seam for deterministic transport tests; production always owns its redirect policy.
  internal init(provider: OAuthTokenProvider, httpClient: HTTPClient) {
    self.provider = provider
    self.httpClient = httpClient
  }

  internal func executeGET(_ originalRequest: HTTPRequest) async throws -> HTTPResponse {
    guard Self.isAllowed(originalRequest) else {
      throw GitHubHTTPClientError.invalidRequest
    }
    let usedSnapshot = try await atAsyncBoundary { try await provider.snapshot() }
    let initialResponse = try await send(originalRequest, using: usedSnapshot)
    guard initialResponse.statusCode == 401 else { return initialResponse }

    let replacementSnapshot = try await atAsyncBoundary {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    let retryResponse = try await send(originalRequest, using: replacementSnapshot)
    guard retryResponse.statusCode != 401 else {
      throw GitHubHTTPClientError.authenticationRequired
    }
    return retryResponse
  }

  private func send(
    _ originalRequest: HTTPRequest, using snapshot: TokenSnapshot
  ) async throws -> HTTPResponse {
    let request = BearerAuth(token: snapshot.accessToken.rawValue)
      .applying(to: originalRequest)
    return try await atAsyncBoundary {
      try await httpClient.execute(request)
    }
  }

  private static func isAllowed(_ request: HTTPRequest) -> Bool {
    guard request.method == .get,
      let parts = URLComponents(url: request.url.value, resolvingAgainstBaseURL: false),
      parts.scheme?.lowercased() == "https",
      parts.host?.lowercased() == "api.github.com",
      parts.user == nil, parts.password == nil,
      parts.fragment == nil,
      parts.port == nil || parts.port == 443
    else { return false }
    return true
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
    if let error = error as? HTTPClientError { return isCancellation(error) }
    if let error = error as? OAuthTokenProviderError { return isCancellation(error) }
    return false
  }

  private func isCancellation(_ error: HTTPClientError) -> Bool {
    switch error {
    case .cancelled: return true
    case .networkFailure(let underlying): return isCancellation(underlying)
    case .underlyingFailure(let underlying): return isCancellation(underlying)
    case .authFlowFinishedWithoutResponse, .nonHTTPResponse: return false
    }
  }

  private func isCancellation(_ error: OAuthTokenProviderError) -> Bool {
    switch error {
    case .missingCredential, .authenticationRequired: return false
    case .restore(let underlying), .refresh(let underlying), .persist(let underlying):
      return isCancellation(underlying)
    }
  }

  private func map(_ error: any Error) -> GitHubHTTPClientError {
    if let error = error as? GitHubHTTPClientError { return error }
    guard let error = error as? OAuthTokenProviderError else { return .executionFailed }
    switch error {
    case .missingCredential, .authenticationRequired: return .authenticationRequired
    case .restore: return .credentialLifecycle(stage: .restore)
    case .refresh: return .credentialLifecycle(stage: .refresh)
    case .persist: return .credentialLifecycle(stage: .persist)
    }
  }
}

internal final class GitHubHTTPRedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    completionHandler(nil)
  }
}
