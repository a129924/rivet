import Foundation
import Testing

@testable import GitHubIntegration

@Suite("Formal login callback relay")
struct GitHubLoginCallbackRelayTests {
  @Test func shutdownIsAwaitableAndIdempotent() async throws {
    let relay = GitHubLoginCallbackRelay()
    let redirect = try await relay.start()
    #expect(redirect.host == "127.0.0.1")
    #expect(redirect.path == "/oauth/callback")
    await relay.shutdown()
    await relay.shutdown()
    await #expect(throws: (any Error).self) { try await relay.next() }
  }

  @Test func cancellingWaiterSettlesBeforeShutdown() async throws {
    let relay = GitHubLoginCallbackRelay()
    _ = try await relay.start()
    let task = Task { try await relay.next() }
    task.cancel()
    await #expect(throws: (any Error).self) { try await task.value }
    await relay.shutdown()
  }

  @Test(arguments: ["wrong.example", "127.0.0.1:12", "127.0.0.1:49152\r\nHost: 127.0.0.1:49152"])
  func rejectsOtherOrDuplicateHost(_ host: String) throws {
    let redirect = try #require(URL(string: "http://127.0.0.1:49152/oauth/callback"))
    let bytes = Data("GET /oauth/callback?code=fixture HTTP/1.1\r\nHost: \(host)\r\n\r\n".utf8)
    #expect(GitHubLoginCallbackRelay.callback(from: bytes, redirectURI: redirect) == nil)
  }
}
