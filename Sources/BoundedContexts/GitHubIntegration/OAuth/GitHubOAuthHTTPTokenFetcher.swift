import Foundation
import RivetHTTPClient

/// The adapter never retries a refresh request: transport failure may hide a rotation.
struct GitHubOAuthHTTPTokenFetcher: OAuthTokenFetcher {
  struct Configuration: Sendable {
    let clientID: String
    let clientSecret: String
  }

  private let httpClient: HTTPClient
  private let configuration: Configuration
  private let now: @Sendable () -> Date

  init(
    httpClient: HTTPClient,
    configuration: Configuration,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.httpClient = httpClient
    self.configuration = configuration
    self.now = now
  }

  init(configuration: Configuration, now: @escaping @Sendable () -> Date = Date.init) throws {
    let settings = URLSessionConfiguration.ephemeral
    settings.urlCache = nil
    settings.httpCookieStorage = nil
    settings.httpShouldSetCookies = false
    settings.requestCachePolicy = .reloadIgnoringLocalCacheData
    settings.timeoutIntervalForRequest = 30
    settings.timeoutIntervalForResource = 30
    let session = URLSession(
      configuration: settings, delegate: OAuthRefreshRedirectBlocker(), delegateQueue: nil)
    self.init(
      httpClient: HTTPClient(
        configuration: try HTTPClient.Configuration(timeout: 30),
        transport: URLSessionTransport(session: session)),
      configuration: configuration, now: now)
  }

  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    guard !Task.isCancelled else { throw .cancelled(stage: .beforeRequest) }
    guard !configuration.clientID.isEmpty, !configuration.clientSecret.isEmpty else {
      throw .clientConfiguration
    }
    let fields = [
      ("client_id", configuration.clientID),
      ("client_secret", configuration.clientSecret),
      ("grant_type", "refresh_token"),
      ("refresh_token", credential.refreshToken.rawValue),
    ]
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    var encodedFields: [String] = []
    for (key, value) in fields {
      guard let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) else {
        throw .knownTechnicalFailure
      }
      encodedFields.append(key + "=" + encoded)
    }
    let url: HTTPURL
    do {
      url = try HTTPURL(GitHubOAuthEndpoints.tokenURL)
    } catch {
      throw .knownTechnicalFailure
    }
    guard !Task.isCancelled else { throw .cancelled(stage: .beforeRequest) }
    let response: HTTPResponse
    do {
      response = try await httpClient.post(
        url: url,
        headers: [.accept: "application/json", .contentType: "application/x-www-form-urlencoded"],
        body: Data(encodedFields.joined(separator: "&").utf8))
    } catch {
      if case .cancelled = error { throw .cancelled(stage: .afterRequestStarted) }
      throw .rotationIndeterminate
    }
    // A trustworthy response wins over task cancellation, including a newly rotated pair.
    let receivedAt = now()
    return try decode(response, receivedAt: receivedAt)
  }

  private func decode(
    _ response: HTTPResponse, receivedAt: Date
  ) throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    guard (200..<300).contains(response.statusCode) || (400..<500).contains(response.statusCode)
    else {
      throw .rotationIndeterminate
    }
    let envelope: OAuthRefreshResponseEnvelope
    do {
      envelope = try JSONDecoder().decode(OAuthRefreshResponseEnvelope.self, from: response.body)
    } catch {
      throw .rotationIndeterminate
    }
    if let error = envelope.error {
      guard !envelope.containsTokenFields else { throw .rotationIndeterminate }
      switch error {
      case "bad_refresh_token": throw .credentialRejected
      case "incorrect_client_credentials": throw .clientConfiguration
      default: throw .rotationIndeterminate
      }
    }
    guard (200..<300).contains(response.statusCode), let token = envelope.token,
      !token.accessToken.isEmpty, !token.refreshToken.isEmpty,
      token.expiresIn > 0, token.refreshTokenExpiresIn > 0,
      receivedAt.timeIntervalSinceReferenceDate.isFinite
    else { throw .rotationIndeterminate }
    let credential = token.credential(receivedAt: receivedAt)
    guard credential.accessTokenExpiresAt.timeIntervalSinceReferenceDate.isFinite,
      credential.refreshTokenExpiresAt.timeIntervalSinceReferenceDate.isFinite,
      credential.accessTokenExpiresAt > receivedAt, credential.refreshTokenExpiresAt > receivedAt
    else { throw .rotationIndeterminate }
    return credential
  }
}

private struct OAuthRefreshResponseEnvelope: Decodable {
  let error: String?
  let containsTokenFields: Bool
  let token: GitHubOAuthTokenResponse?

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case error
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case tokenType = "token_type"
    case scope
    case expiresIn = "expires_in"
    case refreshTokenExpiresIn = "refresh_token_expires_in"
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    containsTokenFields = CodingKeys.allCases.filter { $0 != .error }.contains {
      container.contains($0)
    }
    if container.contains(.error) {
      error = try container.decode(String.self, forKey: .error)
      token = nil
    } else {
      error = nil
      token = try GitHubOAuthTokenResponse(from: decoder)
    }
  }
}

private final class OAuthRefreshRedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    completionHandler(nil)
  }
}
