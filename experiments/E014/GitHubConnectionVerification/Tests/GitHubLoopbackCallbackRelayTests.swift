import Foundation
import GitHubIntegration
import XCTest

@testable import GitHubConnectionVerification

final class GitHubLoopbackCallbackRelayTests: XCTestCase {
  func testRejectsOversizedAndIncompleteHeaders() {
    XCTAssertEqual(
      LoopbackRequestParser.parse(Data(repeating: 65, count: 8193), port: 43210), .badRequest)
    XCTAssertEqual(
      LoopbackRequestParser.parse(Data(repeating: 65, count: 8192), port: 43210), .incomplete)
    XCTAssertEqual(
      LoopbackRequestParser.parse(Data("GET /oauth/callback HTTP/1.1\r\n".utf8), port: 43210),
      .incomplete)
  }

  func testExactPathAndOriginFormAreRequiredWithoutInspectingOAuthState() {
    let expected = URL(string: "http://127.0.0.1:43210/oauth/callback?state=fake&code=fake")!
    XCTAssertEqual(parse("GET /oauth/callback?state=fake&code=fake HTTP/1.1"), .callback(expected))
    XCTAssertEqual(parse("GET /other?code=fake HTTP/1.1"), .notFound)
    XCTAssertEqual(parse("GET /oauth/%63allback HTTP/1.1"), .notFound)
    XCTAssertEqual(parse("POST /oauth/callback HTTP/1.1"), .badRequest)
    XCTAssertEqual(parse("GET http://127.0.0.1/oauth/callback HTTP/1.1"), .badRequest)
    XCTAssertEqual(parse("GET //other/oauth/callback HTTP/1.1"), .badRequest)
    XCTAssertEqual(parse("GET /oauth/callback#fragment HTTP/1.1"), .badRequest)
  }

  func testFakeListenerDeliversOnlyOneCallback() async throws {
    let relay = GitHubLoopbackCallbackRelay(testPort: 43210)
    let redirect = try await relay.start()
    XCTAssertEqual(redirect.absoluteString, "http://127.0.0.1:43210/oauth/callback")
    let parsed = await relay.consume(Data("GET /oauth/callback?code=fake HTTP/1.1\r\n\r\n".utf8))
    guard case .callback(let expected) = parsed else {
      XCTFail("Expected callback")
      return
    }
    let callback = try await relay.waitForCallback()
    XCTAssertEqual(callback, expected)
    let duplicate = await relay.consume(
      Data("GET /oauth/callback?code=second HTTP/1.1\r\n\r\n".utf8))
    XCTAssertEqual(duplicate, .badRequest)
    await relay.stop()
  }

  func testCancellationAndDeadlineResumeWaitersWithDistinctFiniteErrors() async throws {
    let cancelled = GitHubLoopbackCallbackRelay(testPort: 43210)
    _ = try await cancelled.start()
    await cancelled.stop()
    do {
      _ = try await cancelled.waitForCallback()
      XCTFail("Expected cancellation")
    } catch { XCTAssertEqual(error as? GitHubOAuthError, .cancelled) }
    let expired = GitHubLoopbackCallbackRelay(testPort: 43210)
    _ = try await expired.start()
    await expired.expire()
    do {
      _ = try await expired.waitForCallback()
      XCTFail("Expected expiry")
    } catch { XCTAssertEqual(error as? GitHubOAuthError, .expiredSession) }
  }

  private func parse(_ line: String) -> LoopbackRequestParser.Result {
    LoopbackRequestParser.parse(Data((line + "\r\nHost: 127.0.0.1\r\n\r\n").utf8), port: 43210)
  }
}
