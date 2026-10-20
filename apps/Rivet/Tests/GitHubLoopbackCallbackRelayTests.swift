import Foundation
import Testing

@testable import Rivet

struct GitHubLoopbackCallbackRelayTests {
  @Test func validatesMethodHostAndBoundsWithoutReflectingInput() {
    let redirect = URL(string: "http://127.0.0.1:49152/oauth/callback")!
    func parsed(_ request: String) -> URL? {
      GitHubLoopbackCallbackRelay.callback(from: Data(request.utf8), redirectURI: redirect)
    }
    #expect(
      parsed("GET /oauth/callback?state=s&code=c HTTP/1.1\r\nHost: 127.0.0.1:49152\r\n\r\n") != nil)
    #expect(parsed("GET /oauth/callback HTTP/1.1\r\nHost: evil.example\r\n\r\n") == nil)
    #expect(parsed("POST /oauth/callback HTTP/1.1\r\nHost: 127.0.0.1:49152\r\n\r\n") == nil)
    #expect(
      parsed("GET //evil.example/oauth/callback HTTP/1.1\r\nHost: 127.0.0.1:49152\r\n\r\n") == nil)
    #expect(parsed(String(repeating: "x", count: 8193)) == nil)
  }

  @Test func realLoopbackDeliversCallbackAndCancellationSettlesWaiter() async throws {
    let relay = GitHubLoopbackCallbackRelay()
    let redirect = try await relay.start()
    #expect(redirect.host == "127.0.0.1")
    let waiter = Task { try await relay.next() }
    let settings = URLSessionConfiguration.ephemeral
    let session = URLSession(configuration: settings)
    defer {
      session.invalidateAndCancel()
      relay.cancel()
    }
    _ = try await session.data(
      from: URL(string: redirect.absoluteString + "?state=fixture&code=fixture")!)
    let callback = try await waiter.value
    #expect(callback.query?.contains("state=fixture") == true)
    let cancelled = Task { try await relay.next() }
    cancelled.cancel()
    await #expect(throws: (any Error).self) { try await cancelled.value }
  }
}
