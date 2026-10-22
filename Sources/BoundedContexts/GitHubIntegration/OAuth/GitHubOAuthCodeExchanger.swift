import Foundation
import RivetHTTPClient

internal struct GitHubOAuthCodeExchanger: Sendable {
  private let httpClient: HTTPClient
  private let now: @Sendable () -> Date

  init(httpClient: HTTPClient, now: @escaping @Sendable () -> Date = Date.init) {
    self.httpClient = httpClient
    self.now = now
  }

  init() throws {
    let settings = URLSessionConfiguration.ephemeral
    settings.urlCache = nil
    settings.httpCookieStorage = nil
    settings.httpShouldSetCookies = false
    settings.requestCachePolicy = .reloadIgnoringLocalCacheData
    settings.timeoutIntervalForRequest = 30
    settings.timeoutIntervalForResource = 30
    let session = URLSession(
      configuration: settings, delegate: InitialOAuthRedirectBlocker(), delegateQueue: nil)
    self.init(
      httpClient: HTTPClient(
        configuration: try HTTPClient.Configuration(timeout: 30),
        transport: URLSessionTransport(session: session)))
  }

  func exchange(
    configuration: GitHubOAuthAppConfiguration, code: String, redirectURI: URL, verifier: String
  ) async throws -> GitHubOAuthCredentialBundle {
    if Task.isCancelled { throw GitHubOAuthAuthorizationError.cancelled }
    let fields = [
      ("client_id", configuration.clientID), ("client_secret", configuration.clientSecret),
      ("code", code), ("redirect_uri", redirectURI.absoluteString), ("code_verifier", verifier),
    ]
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    let body = fields.map { key, value in
      key + "=" + (value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")
    }
    .joined(separator: "&")
    let response: HTTPResponse
    do {
      response = try await httpClient.post(
        url: HTTPURL(GitHubOAuthEndpoints.tokenURL),
        headers: [.accept: "application/json", .contentType: "application/x-www-form-urlencoded"],
        body: Data(body.utf8))
    } catch {
      if Task.isCancelled { throw GitHubOAuthAuthorizationError.cancelled }
      throw GitHubOAuthAuthorizationError.transport
    }
    if Task.isCancelled { throw GitHubOAuthAuthorizationError.cancelled }
    guard (200..<300).contains(response.statusCode) else {
      throw GitHubOAuthAuthorizationError.exchangeRejected
    }
    return try credential(from: response.body)
  }

  private func credential(from body: Data) throws -> GitHubOAuthCredentialBundle {
    let envelope: InitialOAuthEnvelope
    do {
      envelope = try JSONDecoder().decode(InitialOAuthEnvelope.self, from: body)
    } catch {
      throw GitHubOAuthAuthorizationError.invalidTokenResponse
    }
    guard !envelope.hasError else { throw GitHubOAuthAuthorizationError.exchangeRejected }
    guard let token = envelope.token else {
      throw GitHubOAuthAuthorizationError.invalidTokenResponse
    }
    let receivedAt = now()
    guard !token.accessToken.isEmpty, !token.refreshToken.isEmpty,
      token.expiresIn > 0, token.refreshTokenExpiresIn > 0,
      receivedAt.timeIntervalSinceReferenceDate.isFinite
    else { throw GitHubOAuthAuthorizationError.invalidTokenResponse }
    do { _ = try BearerAuth(token: token.accessToken) } catch {
      throw GitHubOAuthAuthorizationError.invalidTokenResponse
    }
    let credential = token.credential(receivedAt: receivedAt)
    guard credential.accessTokenExpiresAt.timeIntervalSinceReferenceDate.isFinite,
      credential.refreshTokenExpiresAt.timeIntervalSinceReferenceDate.isFinite,
      credential.accessTokenExpiresAt > receivedAt, credential.refreshTokenExpiresAt > receivedAt
    else { throw GitHubOAuthAuthorizationError.invalidTokenResponse }
    return credential
  }
}

private struct InitialOAuthEnvelope: Decodable {
  let hasError: Bool
  let token: GitHubOAuthTokenResponse?
  private enum CodingKeys: String, CodingKey { case error }
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    hasError = container.contains(.error)
    token = hasError ? nil : try GitHubOAuthTokenResponse(from: decoder)
  }
}

private final class InitialOAuthRedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) { completionHandler(nil) }
}
