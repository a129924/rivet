import Foundation
import Testing

@testable import RefreshCore

@Test(arguments: [
  "code=x", "state=good", "state=good&code=", "state=bad&code=x", "state=good&state=good&code=x",
  "state=good&code=x&code=y",
])
func invalidCallbacks(target: String) {
  let decision = Callback.evaluate(
    method: "GET", target: "/oauth/callback?" + target, expectedState: "good")
  guard case .finish(.failure) = decision else {
    Issue.record("Invalid callback accepted")
    return
  }
}
@Test func validCallback() {
  guard
    case .finish(.success(let code)) = Callback.evaluate(
      method: "GET", target: "/oauth/callback?state=good&code=reserved%2Bcode",
      expectedState: "good")
  else {
    Issue.record("Valid callback rejected")
    return
  }
  #expect(code == "reserved+code")
}
@Test func deniedCallback() {
  guard
    case .finish(.failure(.denied)) = Callback.evaluate(
      method: "GET", target: "/oauth/callback?state=good&error=access_denied", expectedState: "good"
    )
  else {
    Issue.record("Denial accepted")
    return
  }
}
@Test func authorizationParameters() throws {
  let configuration = try ProbeConfiguration(arguments: ["--client-id", "identifier"])
  let url = try #require(
    configuration.authorizationURL(
      redirect: "http://127.0.0.1:1234/oauth/callback", state: "s", challenge: "c"))
  let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
  let fields = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
  #expect(fields["scope"] == "offline_access")
  #expect(fields["code_challenge_method"] == "S256")
  #expect(fields["code_challenge"] == "c")
  #expect(fields["state"] == "s")
  #expect(fields["redirect_uri"] == "http://127.0.0.1:1234/oauth/callback")
}
@Test func formReservedCharacters() throws {
  let request = LiveIO.exchangeRequest(
    clientID: "id+&=", secret: "secret+&=",
    authorization: Authorization(
      code: "code+&=", redirect: "http://127.0.0.1:1234/oauth/callback"), verifier: "verifier+&=")
  let data = try #require(request.httpBody)
  let body = try #require(String(data: data, encoding: .utf8))
  #expect(body.contains("client_secret=secret%2B%26%3D"))
  #expect(body.contains("code=code%2B%26%3D"))
  #expect(body.contains("redirect_uri=http%3A%2F%2F127.0.0.1%3A1234%2Foauth%2Fcallback"))
  #expect(request.httpMethod == "POST")
  #expect(request.timeoutInterval == 30)
}
@Test(arguments: [
  [], ["--client-id", "x", "--timeout-seconds", "181"], ["--secret", "sentinel"],
  ["--client-id", ""],
])
func invalidArguments(arguments: [String]) {
  #expect(throws: ProbeFailure.self) { _ = try ProbeConfiguration(arguments: arguments) }
}
@Test func randomVerifierShape() throws {
  let first = try PKCE.random()
  let second = try PKCE.random()
  #expect(first.count == 43)
  #expect(first != second)
  #expect(first.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
}
