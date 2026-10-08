import Foundation
import Testing

@testable import RefreshCore

private struct LocalRun: Sendable {
  let result: Result<Authorization, ProbeFailure>?
  let authorizationURL: URL?
}

private func localRun(
  timeout: Int = 1, browserOpens: Bool = true,
  client: @escaping @Sendable (URL, URLSession) async throws -> Void = { _, _ in }
) async throws -> LocalRun {
  let configuration = try ProbeConfiguration(arguments: [
    "--client-id", "synthetic", "--timeout-seconds", "\(timeout)",
  ])
  let events = AsyncStream<Result<Authorization, ProbeFailure>>.makeStream()
  let browser = AsyncStream<URL>.makeStream()
  let settings = URLSessionConfiguration.ephemeral
  settings.timeoutIntervalForRequest = 2
  settings.timeoutIntervalForResource = 3
  let session = URLSession(configuration: settings)
  let clientTask = Task { () throws -> URL? in
    var urls = browser.stream.makeAsyncIterator()
    guard let url = await urls.next() else { return nil }
    try await client(url, session)
    return url
  }
  let probe = LoopbackProbe(
    configuration: configuration, state: "test-state", challenge: "test-challenge",
    openBrowser: { url, completion in
      if browserOpens { browser.continuation.yield(url) }
      completion(browserOpens)
    },
    completion: {
      browser.continuation.finish()
      events.continuation.yield($0)
      events.continuation.finish()
    })
  defer {
    session.invalidateAndCancel()
    withExtendedLifetime(probe) {}
  }
  probe.start()
  var outcomes = events.stream.makeAsyncIterator()
  let result = await outcomes.next()
  let url = try await clientTask.value
  return LocalRun(result: result, authorizationURL: url)
}

private func callbackURL(_ url: URL, state: String = "test-state") throws -> URL {
  let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
  let redirect = try #require(items.first { $0.name == "redirect_uri" }?.value)
  var components = try #require(URLComponents(string: redirect))
  components.queryItems = [
    .init(name: "state", value: state), .init(name: "code", value: "synthetic-code"),
  ]
  return try #require(components.url)
}

@Test func callbackPayloadAndListenerCleanup() async throws {
  let run = try await localRun { url, session in
    let callback = try callbackURL(url)
    #expect(callback.host == "127.0.0.1")
    let (data, response) = try await session.data(from: callback)
    #expect((response as? HTTPURLResponse)?.statusCode == 200)
    let body = try #require(String(bytes: data, encoding: .utf8))
    #expect(!body.contains("synthetic-code"))
  }
  let payload = try #require(run.result).get()
  #expect(payload.code == "synthetic-code")
  let url = try callbackURL(#require(run.authorizationURL))
  #expect(payload.redirect == url.absoluteString.components(separatedBy: "?")[0])
  await #expect(throws: (any Error).self) {
    _ = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 1))
  }
}

@Test func finiteTimeoutAndBrowserFailure() async throws {
  #expect(try await localRun().result == .failure(.timeout))
  #expect(try await localRun(browserOpens: false).result == .failure(.browser))
}

@Test func badStateTerminatesWithoutCode() async throws {
  let run = try await localRun { url, session in
    _ = try await session.data(from: callbackURL(url, state: "wrong"))
  }
  #expect(run.result == .failure(.callback))
}

@Test func interruptCompletesOnce() async throws {
  let events = AsyncStream<Result<Authorization, ProbeFailure>>.makeStream()
  let configuration = try ProbeConfiguration(arguments: ["--client-id", "synthetic"])
  let probe = LoopbackProbe(
    configuration: configuration, state: "state", challenge: "challenge",
    openBrowser: { _, completion in completion(true) },
    completion: {
      events.continuation.yield($0)
      events.continuation.finish()
    })
  probe.start()
  probe.interrupt()
  probe.interrupt()
  var iterator = events.stream.makeAsyncIterator()
  #expect(await iterator.next() == .failure(.interrupted))
  #expect(await iterator.next() == nil)
  withExtendedLifetime(probe) {}
}

@Test func boundedHeaders() {
  var header = HTTPHeader()
  #expect(header.append(Data(repeating: 65, count: HTTPHeader.maximumBytes + 1)) == .rejected)
  var split = HTTPHeader()
  #expect(split.append(Data("GET /oauth/callback HTTP/1.1\r\n".utf8)) == .incomplete)
  #expect(split.append(Data("\r\n".utf8)) == .request(method: "GET", target: "/oauth/callback"))
}

@Test func liveAuthorizationCancellationClosesListener() async throws {
  let configuration = try ProbeConfiguration(arguments: ["--client-id", "synthetic"])
  let urls = AsyncStream<URL>.makeStream()
  let opener: LoopbackProbe.BrowserOpener = { url, completion in
    urls.continuation.yield(url)
    completion(true)
  }
  let transport = LiveIO(
    configuration: configuration, secret: "synthetic-secret", openBrowser: opener)
  let authorizationTask = Task {
    try await transport.authorize(state: "test-state", challenge: "test-challenge")
  }
  var iterator = urls.stream.makeAsyncIterator()
  let url = try #require(await iterator.next())
  authorizationTask.cancel()
  await #expect(throws: ProbeFailure.self) { _ = try await authorizationTask.value }
  await transport.close()
  let callback = try callbackURL(url)
  await #expect(throws: (any Error).self) {
    _ = try await URLSession.shared.data(for: URLRequest(url: callback, timeoutInterval: 1))
  }
  urls.continuation.finish()
}
