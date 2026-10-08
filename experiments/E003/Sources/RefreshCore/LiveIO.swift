import Foundation

private final class RedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) { completionHandler(nil) }
}

/// The lock protects the cancellation handoff before the listener has started.
private final class AuthorizationWait: @unchecked Sendable {
  private let lock = NSLock()
  private var probe: LoopbackProbe?
  private var cancelled = false
  func install(_ probe: LoopbackProbe) {
    lock.lock()
    self.probe = probe
    let interrupted = cancelled
    lock.unlock()
    if interrupted { probe.interrupt() } else { probe.start() }
  }
  func cancel() {
    lock.lock()
    cancelled = true
    let probe = probe
    lock.unlock()
    probe?.interrupt()
  }
}

public final class LiveIO: ProbeIO, @unchecked Sendable {
  private let configuration: ProbeConfiguration
  private let secret: String
  private let session: URLSession
  private let openBrowser: LoopbackProbe.BrowserOpener

  public init(
    configuration: ProbeConfiguration, secret: String,
    openBrowser: @escaping LoopbackProbe.BrowserOpener
  ) {
    self.configuration = configuration
    self.secret = secret
    self.openBrowser = openBrowser
    let settings = URLSessionConfiguration.ephemeral
    settings.urlCache = nil
    settings.httpCookieStorage = nil
    settings.httpShouldSetCookies = false
    settings.requestCachePolicy = .reloadIgnoringLocalCacheData
    settings.timeoutIntervalForRequest = 30
    settings.timeoutIntervalForResource = 30
    session = URLSession(configuration: settings, delegate: RedirectBlocker(), delegateQueue: nil)
  }

  public func authorize(state: String, challenge: String) async throws -> Authorization {
    let wait = AuthorizationWait()
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        let probe = LoopbackProbe(
          configuration: configuration, state: state, challenge: challenge,
          openBrowser: openBrowser,
          completion: { continuation.resume(with: $0) })
        wait.install(probe)
      }
    } onCancel: {
      wait.cancel()
    }
  }

  public static func exchangeRequest(
    clientID: String, secret: String, authorization: Authorization, verifier: String
  ) -> URLRequest {
    var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
    request.httpMethod = "POST"
    request.timeoutInterval = 30
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let fields = [
      ("client_id", clientID), ("client_secret", secret), ("code", authorization.code),
      ("redirect_uri", authorization.redirect), ("code_verifier", verifier),
    ]
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    request.httpBody = Data(
      fields.map { key, value in
        key + "=" + (value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")
      }.joined(separator: "&").utf8)
    return request
  }

  public func exchange(authorization: Authorization, verifier: String) async throws -> HTTPResult {
    try await send(
      Self.exchangeRequest(
        clientID: configuration.clientID, secret: secret, authorization: authorization,
        verifier: verifier))
  }

  public static func refreshRequest(clientID: String, secret: String, token: String) -> URLRequest {
    var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
    request.httpMethod = "POST"
    request.timeoutInterval = 30
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let fields = [
      ("client_id", clientID), ("client_secret", secret), ("grant_type", "refresh_token"),
      ("refresh_token", token),
    ]
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    request.httpBody = Data(
      fields.map { key, value in
        key + "=" + (value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")
      }.joined(separator: "&").utf8)
    return request
  }

  public func refresh(token: String) async throws -> HTTPResult {
    try await send(
      Self.refreshRequest(clientID: configuration.clientID, secret: secret, token: token))
  }

  public func user(accessToken: String) async throws -> HTTPResult {
    var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
    request.timeoutInterval = 30
    request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    request.setValue("Rivet-E003", forHTTPHeaderField: "User-Agent")
    return try await send(request)
  }

  private func send(_ request: URLRequest) async throws -> HTTPResult {
    do {
      try Task.checkCancellation()
      let (data, response) = try await session.data(for: request)
      guard let response = response as? HTTPURLResponse else { throw ProbeFailure.network }
      return HTTPResult(status: response.statusCode, body: data)
    } catch { throw ProbeFailure.network }
  }

  public func close() async { session.invalidateAndCancel() }
}
