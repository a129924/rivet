import Foundation
import Testing

@testable import ProbeCore

struct CallbackTests {
  @Test func acceptsMatchingCallback() {
    #expect(evaluate("code=test-code&state=test-state") == .finish(.success))
    #expect(evaluate("code=encoded%2Bvalue&state=test%2Dstate") == .finish(.success))
  }

  @Test(arguments: ["state=test-state", "code=&state=test-state", "code=x", "code=x&state="])
  func missingValuesFail(query: String) {
    #expect(evaluate(query) == .finish(.invalidCallback))
  }

  @Test func rejectsMismatchedStateAndAuthorizationError() {
    #expect(evaluate("code=x&state=wrong") == .finish(.stateMismatch))
    #expect(evaluate("error=access_denied&state=test-state") == .finish(.authorizationDenied))
  }

  @Test(arguments: [
    "code=x&code=y&state=test-state", "code=x&state=test-state&state=test-state",
    "code=x&state=test-state&extra=x&extra=y", "code=x&co%64e=y&state=test-state",
  ])
  func rejectsDuplicateParameters(query: String) {
    #expect(evaluate(query) == .finish(.invalidCallback))
  }

  @Test func ignoresOtherRequests() {
    #expect(
      Callback.evaluate(method: "GET", target: "/favicon.ico", expectedState: "s")
        == .ignore(status: 404))
    #expect(
      Callback.evaluate(method: "POST", target: "/oauth/callback", expectedState: "s")
        == .ignore(status: 405))
    #expect(
      Callback.evaluate(method: "GET", target: "//evil.example/oauth/callback", expectedState: "s")
        == .ignore(status: 400))
  }

  @Test func outcomeAndHTTPResponseDoNotExposeValues() {
    let marker = "sensitive-test-marker"
    let decision = Callback.evaluate(
      method: "GET", target: "/oauth/callback?code=\(marker)&state=\(marker)", expectedState: marker
    )
    #expect(decision == .finish(.success))
    let response =
      String(
        bytes: HTTPHeader.response(status: 200, message: ProbeOutcome.success.message),
        encoding: .utf8) ?? marker
    #expect(!response.contains(marker))
    #expect(response.contains("Cache-Control: no-store"))
    #expect(ProbeOutcome.success.exitCode == 0)
    #expect(ProbeOutcome.timeout.exitCode == 1)
    #expect(ProbeOutcome.interrupted.exitCode == 130)
  }

  private func evaluate(_ query: String) -> CallbackDecision {
    Callback.evaluate(
      method: "GET", target: "/oauth/callback?" + query, expectedState: "test-state")
  }
}
