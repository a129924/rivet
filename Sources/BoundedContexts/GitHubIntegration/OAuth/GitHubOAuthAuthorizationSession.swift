import CryptoKit
import Foundation

/// One attempt owns the verifier and admits a single exchange. No raw diagnostics escape.
public actor GitHubOAuthAuthorizationSession: CustomReflectable {
  public nonisolated var customMirror: Mirror { Mirror(self, children: [:]) }
  public nonisolated let authorizationURL: URL
  private let redirectURI: URL
  private let deadline: ContinuousClock.Instant
  private let clock: @Sendable () -> ContinuousClock.Instant
  private let exchange: @Sendable (String, String) async throws -> GitHubOAuthCredentialBundle
  private var state: String?
  private var verifier: String?
  private var status = Status.waiting
  private var exchangeTask: Task<GitHubOAuthCredentialBundle, any Error>?

  private enum Status { case waiting, claimed, completed, cancelled, expired }

  internal init(
    configuration: GitHubOAuthAppConfiguration, redirectURI: URL,
    state: String, verifier: String, lifetime: Duration = .seconds(300),
    clock: @escaping @Sendable () -> ContinuousClock.Instant = { .now },
    exchange: @escaping @Sendable (String, String) async throws -> GitHubOAuthCredentialBundle
  ) throws {
    guard let redirect = URLComponents(url: redirectURI, resolvingAgainstBaseURL: false),
      redirect.scheme == "http", redirect.host == "127.0.0.1",
      let port = redirect.port, (1...65535).contains(port),
      redirect.path == "/oauth/callback", redirect.query == nil, redirect.fragment == nil,
      redirect.user == nil, redirect.password == nil
    else { throw GitHubOAuthAuthorizationError.clientConfiguration }
    self.redirectURI = redirectURI
    self.state = state
    self.verifier = verifier
    self.clock = clock
    deadline = clock().advanced(by: lifetime)
    self.exchange = exchange
    let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    var url = URLComponents(
      url: GitHubOAuthEndpoints.authorizationURL, resolvingAgainstBaseURL: false)!
    url.queryItems = [
      .init(name: "client_id", value: configuration.clientID),
      .init(name: "redirect_uri", value: redirectURI.absoluteString),
      .init(name: "scope", value: "offline_access"), .init(name: "state", value: state),
      .init(name: "code_challenge", value: challenge),
      .init(name: "code_challenge_method", value: "S256"),
    ]
    authorizationURL = url.url!
  }

  public func complete(callbackURL: URL) async throws -> GitHubOAuthCredentialBundle {
    try checkAdmission()
    let code = try validatedCode(callbackURL)
    guard let verifier else { throw GitHubOAuthAuthorizationError.alreadyCompleted }
    status = .claimed
    self.state = nil
    self.verifier = nil
    let exchange = self.exchange
    let task = Task { try await exchange(code, verifier) }
    exchangeTask = task
    defer {
      exchangeTask = nil
      if status == .claimed { status = .completed }
    }
    do {
      let credential = try await withTaskCancellationHandler {
        try await task.value
      } onCancel: {
        task.cancel()
      }
      guard status != .cancelled, !Task.isCancelled else {
        throw GitHubOAuthAuthorizationError.cancelled
      }
      guard clock() < deadline else {
        status = .expired
        throw GitHubOAuthAuthorizationError.expiredSession
      }
      return credential
    } catch {
      if status == .cancelled || Task.isCancelled || error is CancellationError {
        throw GitHubOAuthAuthorizationError.cancelled
      }
      if clock() >= deadline {
        status = .expired
        throw GitHubOAuthAuthorizationError.expiredSession
      }
      throw (error as? GitHubOAuthAuthorizationError) ?? .transport
    }
  }

  public func cancel() {
    status = .cancelled
    state = nil
    verifier = nil
    exchangeTask?.cancel()
  }

  private func checkAdmission() throws {
    if status == .cancelled { throw GitHubOAuthAuthorizationError.cancelled }
    if status == .expired { throw GitHubOAuthAuthorizationError.expiredSession }
    guard status == .waiting else { throw GitHubOAuthAuthorizationError.alreadyCompleted }
    guard !Task.isCancelled else {
      cancel()
      throw GitHubOAuthAuthorizationError.cancelled
    }
    guard clock() < deadline else {
      status = .expired
      state = nil
      verifier = nil
      throw GitHubOAuthAuthorizationError.expiredSession
    }
  }

  private func validatedCode(_ callback: URL) throws -> String {
    guard let parts = URLComponents(url: callback, resolvingAgainstBaseURL: false),
      let expected = URLComponents(url: redirectURI, resolvingAgainstBaseURL: false),
      parts.scheme == expected.scheme, parts.host == expected.host, parts.port == expected.port,
      parts.path == expected.path, parts.user == nil, parts.password == nil, parts.fragment == nil
    else { throw GitHubOAuthAuthorizationError.invalidCallback }
    let items = parts.queryItems ?? []
    func values(_ name: String) -> [String] {
      items.filter { $0.name == name }.map { $0.value ?? "" }
    }
    let states = values("state")
    let codes = values("code")
    let errors = values("error")
    guard states.count == 1, states.first == state,
      (codes.count == 1 && errors.isEmpty && !codes[0].isEmpty)
        || (errors.count == 1 && codes.isEmpty && !errors[0].isEmpty)
    else { throw GitHubOAuthAuthorizationError.invalidCallback }
    if let error = errors.first {
      status = .completed
      state = nil
      verifier = nil
      throw error == "access_denied" ? GitHubOAuthAuthorizationError.denied : .exchangeRejected
    }
    return codes[0]
  }
}
