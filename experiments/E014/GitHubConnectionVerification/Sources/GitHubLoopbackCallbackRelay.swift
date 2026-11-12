import Foundation
import GitHubIntegration
import Network

/// Bounded HTTP parsing is independent of the socket and never emits the request target.
enum LoopbackRequestParser {
  enum Result: Equatable {
    case incomplete
    case badRequest
    case notFound
    case callback(URL)
  }
  static let maximumHeaderBytes = 8 * 1024

  static func parse(_ data: Data, port: UInt16) -> Result {
    guard data.count <= maximumHeaderBytes else { return .badRequest }
    guard let ending = data.range(of: Data("\r\n\r\n".utf8)) else { return .incomplete }
    let header = data[..<ending.lowerBound]
    guard let text = String(data: header, encoding: .utf8),
      let line = text.components(separatedBy: "\r\n").first
    else { return .badRequest }
    let parts = line.split(separator: " ", omittingEmptySubsequences: false)
    guard parts.count == 3, parts[0] == "GET", parts[2] == "HTTP/1.1" || parts[2] == "HTTP/1.0",
      parts[1].hasPrefix("/"), !parts[1].hasPrefix("//"), !parts[1].contains("#"),
      let url = URL(string: "http://127.0.0.1:\(port)" + parts[1]),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return .badRequest }
    guard components.percentEncodedPath == "/oauth/callback" else { return .notFound }
    return .callback(url)
  }
}

actor GitHubLoopbackCallbackRelay {
  private let queue = DispatchQueue(
    label: "local.rivet.github-connection-verification.oauth.loopback")
  private let testPort: UInt16?
  private var listener: NWListener?
  private var port: UInt16?
  private var started = false
  private var ready: CheckedContinuation<URL, any Error>?
  private var callback: CheckedContinuation<URL, any Error>?
  private var result: Result<URL, GitHubOAuthError>?
  private var connections: [UUID: NWConnection] = [:]
  private var connectionTimers: [UUID: Task<Void, Never>] = [:]
  private var deadline: Task<Void, Never>?

  init() { testPort = nil }
  // Injects only the listener-ready event; parser, delivery, timeout and cancellation stay identical.
  init(testPort: UInt16) { self.testPort = testPort }

  func start() async throws -> URL {
    guard !started else { throw GitHubOAuthError.sessionConsumed }
    started = true
    if let testPort {
      port = testPort
      return redirect(testPort)
    }
    let parameters = NWParameters.tcp
    parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
    parameters.allowLocalEndpointReuse = false
    let listener: NWListener
    do { listener = try NWListener(using: parameters) } catch { throw GitHubOAuthError.transport }
    self.listener = listener
    listener.stateUpdateHandler = { [weak self] state in
      Task { await self?.listenerChanged(state) }
    }
    listener.newConnectionHandler = { [weak self] connection in
      Task { await self?.accept(connection) }
    }
    deadline = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(300)) } catch { return }
      await self?.expire()
    }
    return try await withCheckedThrowingContinuation { ready in
      self.ready = ready
      listener.start(queue: queue)
    }
  }

  func waitForCallback() async throws -> URL {
    if let result { return try result.get() }
    guard started, callback == nil else { throw GitHubOAuthError.sessionConsumed }
    return try await withCheckedThrowingContinuation { callback = $0 }
  }

  func stop() {
    finish(.failure(.cancelled))
    listener?.cancel()
    listener = nil
    for connection in connections.values { connection.cancel() }
    connections.removeAll()
    for timer in connectionTimers.values { timer.cancel() }
    connectionTimers.removeAll()
    deadline?.cancel()
    deadline = nil
  }

  func expire() {
    finish(.failure(.expiredSession))
    stop()
  }

  // Fake listener seam projects a completed static response through the real delivery transition.
  func consume(_ data: Data) -> LoopbackRequestParser.Result {
    guard let port, result == nil else { return .badRequest }
    let parsed = LoopbackRequestParser.parse(data, port: port)
    if case .callback(let url) = parsed { finish(.success(url)) }
    return parsed
  }

  private func redirect(_ port: UInt16) -> URL {
    URL(string: "http://127.0.0.1:\(port)/oauth/callback")!
  }

  private func listenerChanged(_ state: NWListener.State) {
    switch state {
    case .ready:
      guard let listenerPort = listener?.port?.rawValue else {
        finish(.failure(.transport))
        return
      }
      port = listenerPort
      ready?.resume(returning: redirect(listenerPort))
      ready = nil
    case .failed:
      finish(.failure(.transport))
      stop()
    case .cancelled: finish(.failure(.cancelled))
    default: break
    }
  }

  private func finish(_ result: Result<URL, GitHubOAuthError>) {
    guard self.result == nil else { return }
    self.result = result
    callback?.resume(with: result.mapError { $0 as any Error })
    callback = nil
    if case .failure(let error) = result {
      ready?.resume(throwing: error)
      ready = nil
    }
    deadline?.cancel()
  }

  private func accept(_ connection: NWConnection) {
    guard result == nil else {
      connection.cancel()
      return
    }
    let id = UUID()
    connections[id] = connection
    connection.start(queue: queue)
    connectionTimers[id] = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(5)) } catch { return }
      await self?.close(id)
    }
    receive(connection, id: id, accumulated: Data())
  }

  private func receive(_ connection: NWConnection, id: UUID, accumulated: Data) {
    connection.receive(
      minimumIncompleteLength: 1, maximumLength: 8193
    ) { [weak self] data, _, complete, error in
      Task {
        await self?.received(
          data, complete: complete, failed: error != nil, id: id, accumulated: accumulated)
      }
    }
  }

  private func received(_ data: Data?, complete: Bool, failed: Bool, id: UUID, accumulated: Data) {
    guard let connection = connections[id] else { return }
    var buffer = accumulated
    if let data { buffer.append(data) }
    let parsed = port.map { LoopbackRequestParser.parse(buffer, port: $0) } ?? .badRequest
    switch parsed {
    case .incomplete:
      if complete || failed { close(id) } else { receive(connection, id: id, accumulated: buffer) }
    case .badRequest:
      respond(connection, id: id, status: "400 Bad Request", text: "Invalid request.")
    case .notFound: respond(connection, id: id, status: "404 Not Found", text: "Not found.")
    case .callback(let url):
      respond(
        connection, id: id, status: "200 OK",
        text: "Return to GitHubConnectionVerification to view the connection result.",
        callbackURL: url)
    }
  }

  private func respond(
    _ connection: NWConnection, id: UUID, status: String, text: String, callbackURL: URL? = nil
  ) {
    let response =
      "HTTP/1.1 \(status)\r\nContent-Type: text/plain; charset=utf-8\r\n"
      + "Content-Length: \(text.utf8.count)\r\nConnection: close\r\nCache-Control: no-store\r\n\r\n"
      + text
    connection.send(
      content: Data(response.utf8),
      completion: .contentProcessed { [weak self] _ in
        Task { await self?.responseCompleted(id, callbackURL: callbackURL) }
      })
  }

  private func responseCompleted(_ id: UUID, callbackURL: URL?) {
    close(id)
    if let callbackURL { finish(.success(callbackURL)) }
  }

  private func close(_ id: UUID) {
    connections.removeValue(forKey: id)?.cancel()
    connectionTimers.removeValue(forKey: id)?.cancel()
  }
}

@MainActor final class LiveGitHubAuthorizationFlow: GitHubAuthorizationFlow {
  private let configuration: GitHubOAuthAppConfiguration
  private let openBrowser: (URL) -> Bool
  private let relay = GitHubLoopbackCallbackRelay()
  private var session: GitHubOAuthAuthorizationSession?
  private var cancelled = false

  init(configuration: GitHubOAuthAppConfiguration, openBrowser: @escaping (URL) -> Bool) {
    self.configuration = configuration
    self.openBrowser = openBrowser
  }

  func run(
    onExchange: @escaping @MainActor () -> Void
  ) async throws -> GitHubOAuthCredentialBundle {
    do {
      guard !cancelled else { throw GitHubOAuthError.cancelled }
      let redirect = try await relay.start()
      guard !cancelled else { throw GitHubOAuthError.cancelled }
      let session = try GitHubOAuth.makeAuthorizationSession(
        configuration: configuration, redirectURI: redirect)
      self.session = session
      guard openBrowser(session.authorizationURL) else { throw GitHubOAuthError.transport }
      let callback = try await relay.waitForCallback()
      onExchange()
      let bundle = try await session.complete(callbackURL: callback)
      await relay.stop()
      await session.cancel()
      self.session = nil
      return bundle
    } catch {
      await relay.stop()
      await session?.cancel()
      session = nil
      throw error
    }
  }

  func cancel() async {
    cancelled = true
    await relay.stop()
    await session?.cancel()
  }
}
