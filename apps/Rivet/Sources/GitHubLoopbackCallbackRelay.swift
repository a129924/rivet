import Foundation
import Network

/// All mutable listener/continuation state is confined to queue.
final class GitHubLoopbackCallbackRelay: @unchecked Sendable {
  private let queue = DispatchQueue(label: "Rivet.oauth.loopback")
  private var listener: NWListener?
  private var startup: CheckedContinuation<URL, any Error>?
  private var waiter: CheckedContinuation<URL, any Error>?
  private var pending: [URL] = []
  private var connections: [UUID: NWConnection] = [:]
  private var redirectURI: URL?
  private var stopped = false

  enum Failure: Error { case unavailable, cancelled }

  func start() async throws -> URL {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        queue.async {
          guard !self.stopped, self.listener == nil else {
            continuation.resume(throwing: Failure.unavailable)
            return
          }
          self.startup = continuation
          do {
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
            parameters.allowLocalEndpointReuse = false
            let listener = try NWListener(using: parameters)
            self.listener = listener
            listener.stateUpdateHandler = { [weak self] state in
              guard let self, !self.stopped else { return }
              switch state {
              case .ready:
                guard let port = self.listener?.port else {
                  self.shutdown(Failure.unavailable)
                  return
                }
                let url = URL(string: "http://127.0.0.1:\(port.rawValue)/oauth/callback")!
                self.redirectURI = url
                self.startup?.resume(returning: url)
                self.startup = nil
              case .failed: self.shutdown(Failure.unavailable)
              default: break
              }
            }
            listener.newConnectionHandler = { [weak self] in self?.accept($0) }
            listener.start(queue: self.queue)
            self.queue.asyncAfter(deadline: .now() + 10) {
              if self.startup != nil { self.shutdown(Failure.unavailable) }
            }
          } catch { self.shutdown(Failure.unavailable) }
        }
      }
    } onCancel: {
      self.cancel()
    }
  }

  func next() async throws -> URL {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        queue.async {
          guard !self.stopped else {
            continuation.resume(throwing: Failure.cancelled)
            return
          }
          if !self.pending.isEmpty {
            continuation.resume(returning: self.pending.removeFirst())
          } else if self.waiter == nil {
            self.waiter = continuation
          } else {
            continuation.resume(throwing: Failure.unavailable)
          }
        }
      }
    } onCancel: {
      self.cancel()
    }
  }

  func cancel() { queue.async { self.shutdown(Failure.cancelled) } }

  private func shutdown(_ error: Failure) {
    guard !stopped else { return }
    stopped = true
    startup?.resume(throwing: error)
    startup = nil
    waiter?.resume(throwing: error)
    waiter = nil
    pending.removeAll()
    redirectURI = nil
    listener?.cancel()
    listener = nil
    for connection in connections.values { connection.cancel() }
    connections.removeAll()
  }

  private func accept(_ connection: NWConnection) {
    guard !stopped, connections.count < 16 else {
      connection.cancel()
      return
    }
    let id = UUID()
    connections[id] = connection
    connection.start(queue: queue)
    queue.asyncAfter(deadline: .now() + 5) { [weak self] in self?.close(id) }
    receive(id, accumulated: Data())
  }

  private func receive(_ id: UUID, accumulated: Data) {
    guard let connection = connections[id] else { return }
    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: 8193
    ) { [weak self] data, _, complete, error in
      guard let self, self.connections[id] != nil, !self.stopped else { return }
      var header = accumulated
      header.append(data ?? Data())
      guard header.count <= 8192 else {
        self.respond(id, valid: false)
        return
      }
      if header.range(of: Data("\r\n\r\n".utf8)) != nil {
        let callback = self.redirectURI.flatMap { Self.callback(from: header, redirectURI: $0) }
        if let callback {
          if let waiter = self.waiter {
            self.waiter = nil
            waiter.resume(returning: callback)
          } else if self.pending.count < 8 {
            self.pending.append(callback)
          }
        }
        self.respond(id, valid: callback != nil)
      } else if complete || error != nil {
        self.close(id)
      } else {
        self.receive(id, accumulated: header)
      }
    }
  }

  static func callback(from data: Data, redirectURI: URL) -> URL? {
    guard data.count <= 8192, let header = String(data: data, encoding: .utf8),
      let end = header.range(of: "\r\n\r\n"),
      let redirect = URLComponents(url: redirectURI, resolvingAgainstBaseURL: false)
    else { return nil }
    let lines = header[..<end.lowerBound].components(separatedBy: "\r\n")
    let request = (lines.first ?? "").split(separator: " ", omittingEmptySubsequences: false)
    guard request.count == 3, request[0] == "GET",
      request[2] == "HTTP/1.1" || request[2] == "HTTP/1.0",
      request[1].hasPrefix("/"), !request[1].hasPrefix("//"),
      let parts = URLComponents(string: String(request[1])), parts.path == "/oauth/callback",
      parts.host == nil, parts.scheme == nil, parts.fragment == nil
    else { return nil }
    let hosts = lines.dropFirst().compactMap { line -> String? in
      guard let colon = line.firstIndex(of: ":"), line[..<colon].lowercased() == "host" else {
        return nil
      }
      return line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
    }
    guard hosts.count == 1, hosts[0] == "127.0.0.1:\(redirect.port ?? 0)" else { return nil }
    return URL(string: "http://127.0.0.1:\(redirect.port ?? 0)" + String(request[1]))
  }

  private func respond(_ id: UUID, valid: Bool) {
    let body = valid ? "已收到回呼，請返回 Rivet 查看結果。" : "此要求不是有效的本機回呼。"
    let status = valid ? "200 OK" : "400 Bad Request"
    let response = [
      "HTTP/1.1 \(status)", "Content-Type: text/plain; charset=utf-8",
      "Content-Length: \(body.utf8.count)", "Cache-Control: no-store", "Connection: close", "",
      body,
    ].joined(separator: "\r\n")
    connections[id]?.send(
      content: Data(response.utf8),
      completion: .contentProcessed { [weak self] _ in self?.close(id) })
  }

  private func close(_ id: UUID) { connections.removeValue(forKey: id)?.cancel() }
}
