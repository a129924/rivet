import Darwin
import Foundation
import Testing

@testable import ProbeCore

struct LoopbackProbeTests {
  @Test func localCallbackAndCleanup() async throws {
    let urls = URLBox()
    let outcome = try await run { url, session in
      urls.set(url)
      do {
        let callback = try Self.callbackURL(url)
        #expect(callback.host == "127.0.0.1")
        #expect((callback.port ?? 0) > 0)
        let (data, response) = try await session.data(from: callback)
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        let body = try #require(String(bytes: data, encoding: .utf8))
        #expect(!body.contains("test-code"))
      } catch { Issue.record("本機 callback request 失敗。") }
    }
    #expect(outcome == .success)
    let authorizationURL = try #require(urls.get())
    let callback = try Self.callbackURL(authorizationURL)
    do {
      _ = try await URLSession.shared.data(for: URLRequest(url: callback, timeoutInterval: 2))
      Issue.record("終結後 listener 仍接受 connection。")
    } catch {
      // Connection refusal confirms the listener was closed; this is a simulated callback only.
    }
  }

  @Test func waitsForClientWorkAfterProbeCompletion() async throws {
    let finished = CompletionCount()
    let outcome = try await run { url, session in
      _ = try await session.data(from: Self.callbackURL(url))
      try await Task.sleep(for: .milliseconds(150))
      finished.increment()
    }
    #expect(outcome == .success)
    #expect(finished.value == 1)
  }

  @Test func clientFailureIsJoinedAndPropagated() async {
    await #expect(throws: ClientError.self) {
      try await run(timeout: 1) { _, _ in throw ClientError.expected }
    }
  }

  @Test func startupFailureDoesNotWaitForMissingBrowserCallback() async throws {
    let invoked = CompletionCount()
    let outcome = try await run(limits: .init(startupSeconds: 0, headerSeconds: 5)) { _, _ in
      invoked.increment()
    }
    #expect(outcome == .listenerFailure)
    #expect(invoked.value == 0)
  }

  @Test func unrelatedRequestsKeepWaiting() async throws {
    let outcome = try await run { url, session in
      do {
        let callback = try Self.callbackURL(url)
        var wrongPath = try #require(URLComponents(url: callback, resolvingAgainstBaseURL: false))
        wrongPath.path = "/favicon.ico"
        let (_, notFound) = try await session.data(from: #require(wrongPath.url))
        #expect((notFound as? HTTPURLResponse)?.statusCode == 404)
        var post = URLRequest(url: callback)
        post.httpMethod = "POST"
        let (_, wrongMethod) = try await session.data(for: post)
        #expect((wrongMethod as? HTTPURLResponse)?.statusCode == 405)
        _ = try await session.data(from: callback)
      } catch { Issue.record("404／405 後的本機 callback 失敗。") }
    }
    #expect(outcome == .success)
  }

  @Test func timeoutAndBrowserFailure() async throws {
    #expect(try await run(timeout: 1) == .timeout)
    #expect(try await run(browserOpens: false) == .browserFailure)
  }

  @Test func interruptTerminatesOnce() async throws {
    let configuration = try ProbeConfiguration(arguments: ["--client-id", "test-client"])
    let events = AsyncStream<ProbeOutcome>.makeStream()
    let count = CompletionCount()
    let probe = LoopbackProbe(
      configuration: configuration, openBrowser: { _, opened in opened(true) },
      completion: {
        count.increment()
        events.continuation.yield($0)
        events.continuation.finish()
      })
    defer { withExtendedLifetime(probe) {} }
    probe.start()
    probe.interrupt()
    probe.interrupt()
    var iterator = events.stream.makeAsyncIterator()
    #expect(await iterator.next() == .interrupted)
    try await Task.sleep(for: .milliseconds(100))
    #expect(count.value == 1)
  }

  @Test func incompleteAndOversizedConnectionsDoNotBlockCallback() async throws {
    let limits = LoopbackProbe.Limits(startupSeconds: 10, headerSeconds: 0.15)
    let outcome = try await run(limits: limits) { url, session in
      do {
        let callback = try Self.callbackURL(url)
        #expect(Self.waitForSocketClose(port: try #require(callback.port), oversized: false))
        #expect(Self.waitForSocketClose(port: try #require(callback.port), oversized: true))
        _ = try await session.data(from: callback)
      } catch { Issue.record("有限 HTTP read 後的本機 callback 失敗。") }
    }
    #expect(outcome == .success)
  }

  private func run(
    timeout: Int = 3, limits: LoopbackProbe.Limits = .init(), browserOpens: Bool = true,
    client: @escaping @Sendable (URL, URLSession) async throws -> Void = { _, _ in }
  ) async throws -> ProbeOutcome? {
    let configuration = try ProbeConfiguration(arguments: [
      "--client-id", "test-client", "--timeout-seconds", "\(timeout)",
    ])
    let events = AsyncStream<ProbeOutcome>.makeStream()
    let browserURLs = AsyncStream<URL>.makeStream()
    let sessionConfiguration = URLSessionConfiguration.ephemeral
    sessionConfiguration.timeoutIntervalForRequest = 2
    sessionConfiguration.timeoutIntervalForResource = 5
    let session = URLSession(configuration: sessionConfiguration)
    // 在 test context 建立並保留 Task，讓 Swift Testing 的 assertions 屬於目前測試。
    let clientTask = Task {
      var iterator = browserURLs.stream.makeAsyncIterator()
      guard let url = await iterator.next() else { return }
      try await client(url, session)
    }
    let probe = LoopbackProbe(
      configuration: configuration, limits: limits,
      openBrowser: { url, opened in
        if browserOpens { browserURLs.continuation.yield(url) }
        opened(browserOpens)
      },
      completion: {
        // 啟動失敗時沒有 browser callback；finish 解除 client 的等待，再 join。
        browserURLs.continuation.finish()
        events.continuation.yield($0)
        events.continuation.finish()
      })
    defer {
      session.invalidateAndCancel()
      withExtendedLifetime(probe) {}
    }
    probe.start()
    var iterator = events.stream.makeAsyncIterator()
    let outcome = await iterator.next()
    try await clientTask.value
    return outcome
  }

  private enum ClientError: Error { case expected }

  private static func callbackURL(_ authorizationURL: URL) throws -> URL {
    let query = try #require(
      URLComponents(url: authorizationURL, resolvingAgainstBaseURL: false)?.queryItems)
    let redirect = try #require(query.first(where: { $0.name == "redirect_uri" })?.value)
    let state = try #require(query.first(where: { $0.name == "state" })?.value)
    var callback = try #require(URLComponents(string: redirect))
    callback.queryItems = [
      URLQueryItem(name: "code", value: "test-code"), URLQueryItem(name: "state", value: state),
    ]
    return try #require(callback.url)
  }

  private static func waitForSocketClose(port: Int, oversized: Bool) -> Bool {
    let descriptor = socket(AF_INET, SOCK_STREAM, 0)
    guard descriptor >= 0 else { return false }
    defer { Darwin.close(descriptor) }
    var timeout = timeval(tv_sec: 2, tv_usec: 0)
    setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = UInt16(port).bigEndian
    address.sin_addr.s_addr = inet_addr("127.0.0.1")
    let connected = withUnsafePointer(to: &address) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
      }
    }
    guard connected == 0 else { return false }
    let request =
      oversized
      ? Data(repeating: 65, count: HTTPHeader.maximumBytes + 1) : Data("GET /oauth/callback".utf8)
    let sent = request.withUnsafeBytes { send(descriptor, $0.baseAddress, $0.count, 0) }
    guard sent == request.count else { return false }
    var buffer = [UInt8](repeating: 0, count: 1024)
    while true {
      let count = recv(descriptor, &buffer, buffer.count, 0)
      if count == 0 { return true }
      if count < 0 { return false }
    }
  }
}

private final class URLBox: @unchecked Sendable {
  private let lock = NSLock()
  private var url: URL?
  func set(_ value: URL) { lock.withLock { url = value } }
  func get() -> URL? { lock.withLock { url } }
}

private final class CompletionCount: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0
  var value: Int { lock.withLock { count } }
  func increment() { lock.withLock { count += 1 } }
}
