import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("OAuth initial code exchange")
struct GitHubOAuthCodeExchangerTests {
  @Test(
    arguments: [
      ("access_token", "illegal token"), ("refresh_token", ""), ("expires_in", 0),
      ("refresh_token_expires_in", -1), ("token_type", "other"),
    ] as [(String, InvalidInitialValue)])
  func rejectsInvalidValues(_ key: String, _ value: InvalidInitialValue) async throws {
    var json = try #require(
      JSONSerialization.jsonObject(with: Data(initialJSON.utf8)) as? [String: Any])
    switch value {
    case .text(let text): json[key] = text
    case .number(let number): json[key] = number
    }
    let transport = InitialTransport(
      body: try #require(
        String(data: try JSONSerialization.data(withJSONObject: json), encoding: .utf8)))
    let exchanger = GitHubOAuthCodeExchanger(httpClient: HTTPClient(transport: transport))
    await #expect(throws: GitHubOAuthAuthorizationError.invalidTokenResponse) {
      try await exchanger.exchange(
        configuration: .init(clientID: "id", clientSecret: "secret"), code: "c",
        redirectURI: callback(), verifier: "v")
    }
  }

  @Test func formAndReceiptMapping() async throws {
    let transport = InitialTransport(body: initialJSON)
    let date = Date(timeIntervalSince1970: 1000)
    let exchanger = GitHubOAuthCodeExchanger(
      httpClient: HTTPClient(transport: transport), now: { date })
    let config = try GitHubOAuthAppConfiguration(clientID: "id +&", clientSecret: "secret +&")
    let result = try await exchanger.exchange(
      configuration: config, code: "code +&", redirectURI: callback(), verifier: "verifier +&")
    #expect(result.accessTokenExpiresAt == date.addingTimeInterval(3600))
    #expect(result.refreshTokenExpiresAt == date.addingTimeInterval(7200))
    let request = try #require(await transport.requests.first)
    #expect(request.url?.absoluteString == "https://github.com/login/oauth/access_token")
    #expect(request.httpMethod == "POST")
    let body = String(data: try #require(request.httpBody), encoding: .utf8) ?? ""
    #expect(body.contains("client_secret=secret%20%2B%26"))
    #expect(body.contains("code_verifier=verifier%20%2B%26"))
    #expect(await transport.requests.count == 1)
  }

  @Test(arguments: [
    "{}", "[]", "not-json", "{\"error\":\"bad_verification_code\"}",
    "{\"error\":\"bad_verification_code\",\"access_token\":\"fixture\"}",
  ])
  func rejectsIncompleteAndErrorEnvelopes(_ body: String) async throws {
    let transport = InitialTransport(body: body)
    let exchanger = GitHubOAuthCodeExchanger(httpClient: HTTPClient(transport: transport))
    await #expect(throws: GitHubOAuthAuthorizationError.self) {
      try await exchanger.exchange(
        configuration: .init(clientID: "id", clientSecret: "secret"), code: "code",
        redirectURI: callback(), verifier: "verifier")
    }
    #expect(await transport.requests.count == 1)
  }

  @Test(arguments: [
    "access_token", "refresh_token", "expires_in", "refresh_token_expires_in", "token_type",
    "scope",
  ])
  func rejectsEachMissingField(_ key: String) async throws {
    var json = try #require(
      JSONSerialization.jsonObject(with: Data(initialJSON.utf8)) as? [String: Any])
    json.removeValue(forKey: key)
    let transport = InitialTransport(
      body: try #require(
        String(data: try JSONSerialization.data(withJSONObject: json), encoding: .utf8)))
    let exchanger = GitHubOAuthCodeExchanger(httpClient: HTTPClient(transport: transport))
    await #expect(throws: GitHubOAuthAuthorizationError.invalidTokenResponse) {
      try await exchanger.exchange(
        configuration: .init(clientID: "id", clientSecret: "secret"), code: "c",
        redirectURI: callback(), verifier: "v")
    }
  }
}

let initialJSON = """
  {"access_token":"fixture-access","refresh_token":"fixture-refresh",
   "token_type":"bearer","scope":"","expires_in":3600,"refresh_token_expires_in":7200}
  """

actor InitialTransport: Transport {
  var requests: [URLRequest] = []
  let body: String
  init(body: String) { self.body = body }
  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    return HTTPResponse(statusCode: 200, headers: [:], body: Data(body.utf8))
  }
}

enum InvalidInitialValue: Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
  case text(String)
  case number(Int)
  init(stringLiteral value: String) { self = .text(value) }
  init(integerLiteral value: Int) { self = .number(value) }
}
