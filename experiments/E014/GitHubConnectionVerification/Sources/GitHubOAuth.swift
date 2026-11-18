import Foundation
import GitHubIntegration
import RivetHTTPClient
import Security

/// Verification-App construction boundary; adapters stay inside this App.
enum GitHubOAuth {
  static func makeTokenFetcher(
    configuration: GitHubOAuthAppConfiguration
  ) throws -> any OAuthTokenFetcher {
    try VerificationOAuthHTTPTokenFetcher(
      configuration: .init(
        clientID: configuration.clientID, clientSecret: configuration.clientSecret))
  }

  static func makeAuthorizationSession(
    configuration: GitHubOAuthAppConfiguration, redirectURI: URL
  ) throws -> GitHubOAuthAuthorizationSession {
    let state = try randomValue()
    let verifier = try randomValue()
    let settings = authorizationSessionConfiguration()
    let session = URLSession(
      configuration: settings, delegate: AuthorizationRedirectBlocker(), delegateQueue: nil)
    let transport = URLSessionTransport(session: session)
    return try GitHubOAuthAuthorizationSession(
      configuration: configuration, redirectURI: redirectURI, state: state, verifier: verifier,
      now: Date.init, exchange: { request in try await transport.execute(request) })
  }

  // Shared with App-local tests so verification session policy is checked without performing I/O.
  static func authorizationSessionConfiguration() -> URLSessionConfiguration {
    let settings = URLSessionConfiguration.ephemeral
    settings.urlCache = nil
    settings.httpCookieStorage = nil
    settings.httpShouldSetCookies = false
    settings.requestCachePolicy = .reloadIgnoringLocalCacheData
    settings.timeoutIntervalForRequest = 30
    settings.timeoutIntervalForResource = 30
    return settings
  }

  private static func randomValue() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
      throw GitHubOAuthError.clientConfiguration
    }
    return Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

final class AuthorizationRedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    completionHandler(nil)
  }
}
