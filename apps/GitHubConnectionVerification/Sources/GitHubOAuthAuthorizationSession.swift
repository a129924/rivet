import CryptoKit
import Foundation
import GitHubIntegration
import RivetHTTPClient

/// One attempt owns its state and PKCE verifier. Consuming any callback ends that attempt.
actor GitHubOAuthAuthorizationSession {
  nonisolated let authorizationURL: URL
  private let configuration: GitHubOAuthAppConfiguration
  private let redirectURI: URL
  private let state: String
  private var verifier: String?
  private let deadline: Date
  private let now: @Sendable () -> Date
  private let exchange: @Sendable (URLRequest) async throws -> HTTPResponse
  private var status: Status = .waiting

  private enum Status { case waiting, consumed, cancelled }

  init(
    configuration: GitHubOAuthAppConfiguration, redirectURI: URL, state: String, verifier: String,
    now: @escaping @Sendable () -> Date,
    exchange: @escaping @Sendable (URLRequest) async throws -> HTTPResponse
  ) throws {
    guard let redirect = URLComponents(url: redirectURI, resolvingAgainstBaseURL: false),
      redirect.scheme == "http", redirect.host == "127.0.0.1",
      let port = redirect.port, (1...65535).contains(port), redirect.path == "/oauth/callback",
      redirect.user == nil, redirect.password == nil, redirect.fragment == nil,
      redirect.query == nil,
      !state.isEmpty, !verifier.isEmpty
    else { throw GitHubOAuthError.clientConfiguration }
    self.configuration = configuration
    self.redirectURI = redirectURI
    self.state = state
    self.verifier = verifier
    self.now = now
    self.exchange = exchange
    deadline = now().addingTimeInterval(300)
    let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    var authorization = URLComponents(
      url: VerificationOAuthEndpoints.authorizationURL, resolvingAgainstBaseURL: false)!
    authorization.queryItems = [
      URLQueryItem(name: "client_id", value: configuration.clientID),
      URLQueryItem(name: "redirect_uri", value: redirectURI.absoluteString),
      URLQueryItem(name: "scope", value: "offline_access"),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: challenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
    ]
    guard let authorizationURL = authorization.url else {
      throw GitHubOAuthError.clientConfiguration
    }
    self.authorizationURL = authorizationURL
  }

  func cancel() {
    guard status == .waiting else { return }
    status = .cancelled
    verifier = nil
  }

  func complete(callbackURL: URL) async throws -> GitHubOAuthCredentialBundle {
    guard status != .cancelled else { throw GitHubOAuthError.cancelled }
    guard status == .waiting else { throw GitHubOAuthError.sessionConsumed }
    // Consume before the first await, including malformed callbacks and expired attempts.
    status = .consumed
    defer { verifier = nil }
    let currentTime = now()
    guard currentTime.timeIntervalSinceReferenceDate.isFinite else {
      throw GitHubOAuthError.invalidTokenResponse
    }
    guard currentTime < deadline else { throw GitHubOAuthError.expiredSession }
    guard !Task.isCancelled else { throw GitHubOAuthError.cancelled }
    let code = try validate(callbackURL)
    guard let verifier else { throw GitHubOAuthError.sessionConsumed }
    let request = try tokenRequest(code: code, verifier: verifier)
    let response: HTTPResponse
    do { response = try await exchange(request) } catch { throw GitHubOAuthError.transport }
    return try decode(response, receivedAt: now())
  }

  private func validate(_ callbackURL: URL) throws -> String {
    guard let callback = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
      let expected = URLComponents(url: redirectURI, resolvingAgainstBaseURL: false),
      callback.scheme == expected.scheme, callback.host == expected.host,
      callback.port == expected.port, callback.percentEncodedPath == expected.percentEncodedPath,
      callback.user == nil, callback.password == nil, callback.fragment == nil
    else { throw GitHubOAuthError.invalidCallback }
    let query = callback.queryItems ?? []
    guard Set(query.map(\.name)).count == query.count else {
      throw GitHubOAuthError.invalidCallback
    }
    let states = query.filter { $0.name == "state" }
    let codes = query.filter { $0.name == "code" }
    let errors = query.filter { $0.name == "error" }
    guard states.count == 1, states.first?.value == state else {
      throw GitHubOAuthError.invalidCallback
    }
    if errors.count == 1, codes.isEmpty, let error = errors.first?.value, !error.isEmpty {
      if error == "access_denied" { throw GitHubOAuthError.denied }
      throw GitHubOAuthError.exchangeRejected
    }
    guard errors.isEmpty, codes.count == 1, let code = codes.first?.value, !code.isEmpty else {
      throw GitHubOAuthError.invalidCallback
    }
    return code
  }

  private func tokenRequest(code: String, verifier: String) throws -> URLRequest {
    let fields = [
      ("client_id", configuration.clientID), ("client_secret", configuration.clientSecret),
      ("code", code), ("redirect_uri", redirectURI.absoluteString), ("code_verifier", verifier),
    ]
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    let encoded = try fields.map { key, value in
      guard let value = value.addingPercentEncoding(withAllowedCharacters: allowed) else {
        throw GitHubOAuthError.clientConfiguration
      }
      return key + "=" + value
    }
    var request = URLRequest(url: VerificationOAuthEndpoints.tokenURL, timeoutInterval: 30)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data(encoded.joined(separator: "&").utf8)
    return request
  }

  private func decode(
    _ response: HTTPResponse, receivedAt: Date
  ) throws -> GitHubOAuthCredentialBundle {
    guard (200..<300).contains(response.statusCode) || (400..<500).contains(response.statusCode),
      let envelope = try? JSONDecoder().decode(AuthorizationResponse.self, from: response.body)
    else { throw GitHubOAuthError.invalidTokenResponse }
    if let error = envelope.error {
      guard !envelope.containsTokenFields else { throw GitHubOAuthError.invalidTokenResponse }
      if error == "incorrect_client_credentials" { throw GitHubOAuthError.clientConfiguration }
      throw GitHubOAuthError.exchangeRejected
    }
    guard (200..<300).contains(response.statusCode), let token = envelope.token,
      !token.accessToken.isEmpty, !token.refreshToken.isEmpty,
      token.expiresIn > 0, token.refreshTokenExpiresIn > 0,
      receivedAt.timeIntervalSinceReferenceDate.isFinite
    else { throw GitHubOAuthError.invalidTokenResponse }
    let bundle = token.credential(receivedAt: receivedAt)
    guard bundle.accessTokenExpiresAt.timeIntervalSinceReferenceDate.isFinite,
      bundle.refreshTokenExpiresAt.timeIntervalSinceReferenceDate.isFinite,
      bundle.accessTokenExpiresAt > receivedAt, bundle.refreshTokenExpiresAt > receivedAt
    else { throw GitHubOAuthError.invalidTokenResponse }
    return bundle
  }
}

private struct AuthorizationResponse: Decodable {
  let error: String?
  let containsTokenFields: Bool
  let token: VerificationOAuthTokenResponse?

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
      token = try VerificationOAuthTokenResponse(from: decoder)
    }
  }
}
