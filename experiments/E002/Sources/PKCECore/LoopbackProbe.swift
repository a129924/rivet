import Foundation
import Network

/// Mutable state is confined to `queue`; callers only enqueue start/interrupt operations.
public final class LoopbackProbe: @unchecked Sendable {
  public typealias BrowserOpener = @Sendable (URL, @escaping @Sendable (Bool) -> Void) -> Void
  public typealias Completion = @Sendable (Result<Authorization, ProbeFailure>) -> Void

  struct Limits: Sendable {
    var startupSeconds: TimeInterval = 10
    var headerSeconds: TimeInterval = 5
  }

  private let queue = DispatchQueue(label: "E002.loopback-probe")
  private let configuration: ProbeConfiguration
  private let openBrowser: BrowserOpener
  private let completion: Completion
  private let limits: Limits
  private var listener: NWListener?
  private var timer: DispatchSourceTimer?
  private var connections: [UUID: NWConnection] = [:]
  private var readTimers: [UUID: DispatchSourceTimer] = [:]
  private var expectedState = ""
  private var redirect = ""
  private let challenge: String
  private let state: String
  private var started = false
  private var finished = false
  private var delivered = false

  public convenience init(
    configuration: ProbeConfiguration, state: String, challenge: String,
    openBrowser: @escaping BrowserOpener,
    completion: @escaping Completion
  ) {
    self.init(
      configuration: configuration, state: state, challenge: challenge, limits: Limits(),
      openBrowser: openBrowser,
      completion: completion)
  }

  init(
    configuration: ProbeConfiguration, state: String, challenge: String, limits: Limits,
    openBrowser: @escaping BrowserOpener,
    completion: @escaping Completion
  ) {
    self.configuration = configuration
    self.state = state
    self.challenge = challenge
    self.limits = limits
    self.openBrowser = openBrowser
    self.completion = completion
  }

  public func start() {
    queue.async { self.startListener() }
  }

  public func interrupt() {
    queue.async { self.finish(.failure(.interrupted)) }
  }

  private func startListener() {
    guard !started, !finished else { return }
    started = true
    let parameters = NWParameters.tcp
    parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
    parameters.allowLocalEndpointReuse = false
    do {
      let listener = try NWListener(using: parameters)
      self.listener = listener
      listener.stateUpdateHandler = { [weak self] state in
        guard let self, !self.finished else { return }
        switch state {
        case .ready: self.listenerReady()
        case .failed: self.finish(.failure(.listener))
        default: break
        }
      }
      listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
      armTimer(seconds: limits.startupSeconds, outcome: .failure(.listener))
      listener.start(queue: queue)
    } catch {
      finish(.failure(.listener))
    }
  }

  private func listenerReady() {
    guard expectedState.isEmpty, let port = listener?.port?.rawValue else { return }
    expectedState = state
    redirect = "http://127.0.0.1:\(port)/oauth/callback"
    guard
      let url = configuration.authorizationURL(
        redirect: redirect, state: expectedState, challenge: challenge)
    else {
      finish(.failure(.browser))
      return
    }
    // A distant deadline avoids integer overflow for large but valid positive CLI values.
    armTimer(seconds: TimeInterval(configuration.timeoutSeconds), outcome: .failure(.timeout))
    openBrowser(url) { [weak self] opened in
      guard let self else { return }
      self.queue.async {
        if !opened { self.finish(.failure(.browser)) }
      }
    }
  }

  private func armTimer(seconds: TimeInterval, outcome: Result<Authorization, ProbeFailure>) {
    timer?.cancel()
    let timer = makeTimer(seconds: seconds) { [weak self] in self?.finish(outcome) }
    self.timer = timer
    timer.resume()
  }

  private func makeTimer(
    seconds: TimeInterval,
    action: @escaping @Sendable () -> Void
  ) -> DispatchSourceTimer {
    let timer = DispatchSource.makeTimerSource(queue: queue)
    let nanoseconds = seconds * 1_000_000_000
    let deadline: DispatchTime =
      nanoseconds < Double(Int.max)
      ? .now() + .nanoseconds(Int(nanoseconds)) : .distantFuture
    timer.schedule(deadline: deadline)
    timer.setEventHandler(handler: action)
    return timer
  }

  private func accept(_ connection: NWConnection) {
    guard !finished else {
      connection.cancel()
      return
    }
    let identifier = UUID()
    connections[identifier] = connection
    let timer = makeTimer(seconds: limits.headerSeconds) { [weak self] in self?.close(identifier) }
    readTimers[identifier] = timer
    timer.resume()
    connection.start(queue: queue)
    receive(identifier, header: HTTPHeader())
  }

  private func receive(_ identifier: UUID, header: HTTPHeader) {
    guard let connection = connections[identifier], !finished else { return }
    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: HTTPHeader.maximumBytes + 1
    ) { [weak self] data, _, isComplete, error in
      guard let self, self.connections[identifier] != nil, !self.finished else { return }
      var updated = header
      let parsed = updated.append(data ?? Data())
      switch parsed {
      case .incomplete:
        if isComplete || error != nil {
          self.close(identifier)
        } else {
          self.receive(identifier, header: updated)
        }
      case .rejected:
        self.respond(identifier, status: 400, message: "無效 HTTP request。")
      case .request(let method, let target):
        self.handle(identifier, method: method, target: target)
      }
    }
  }

  private func handle(_ identifier: UUID, method: String, target: String) {
    switch Callback.evaluate(method: method, target: target, expectedState: expectedState) {
    case .ignore(let status):
      respond(identifier, status: status, message: "此 request 不屬於 OAuth callback。")
    case .finish(let outcome):
      finish(outcome.map { Authorization(code: $0, redirect: redirect) }, respondingTo: identifier)
    }
  }

  private func respond(_ identifier: UUID, status: Int, message: String) {
    guard let connection = connections[identifier] else { return }
    let sent: NWConnection.SendCompletion = .contentProcessed { [weak self] _ in
      self?.close(identifier)
    }
    connection.send(
      content: HTTPHeader.response(status: status, message: message), completion: sent)
  }

  private func close(_ identifier: UUID) {
    readTimers.removeValue(forKey: identifier)?.cancel()
    connections.removeValue(forKey: identifier)?.cancel()
  }

  private func finish(
    _ outcome: Result<Authorization, ProbeFailure>, respondingTo identifier: UUID? = nil
  ) {
    guard !finished else { return }
    finished = true
    timer?.cancel()
    timer = nil
    listener?.cancel()
    listener = nil
    expectedState = ""
    for key in Array(connections.keys) where key != identifier { close(key) }
    guard let identifier, let connection = connections[identifier] else {
      deliver(outcome)
      return
    }
    readTimers.removeValue(forKey: identifier)?.cancel()
    let timer = makeTimer(seconds: limits.headerSeconds) { [weak self] in
      self?.close(identifier)
      self?.deliver(outcome)
    }
    readTimers[identifier] = timer
    timer.resume()
    connection.send(
      content: HTTPHeader.response(
        status: 200, message: "Callback 已處理，請回終端機查看遮蔽結果。"),
      completion: .contentProcessed { [weak self] _ in
        self?.close(identifier)
        self?.deliver(outcome)
      })
  }

  private func deliver(_ outcome: Result<Authorization, ProbeFailure>) {
    guard !delivered else { return }
    delivered = true
    completion(outcome)
  }
}
