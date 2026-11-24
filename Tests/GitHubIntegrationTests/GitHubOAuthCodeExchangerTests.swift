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
    #expect(result.accessToken.rawValue == "fixture-access")
    #expect(result.refreshToken.rawValue == "fixture-refresh")
    #expect(result.accessTokenExpiresAt == date.addingTimeInterval(3600))
    #expect(result.refreshTokenExpiresAt == date.addingTimeInterval(7200))
    let request = try #require(await transport.requests.first)
    #expect(request.url?.absoluteString == "https://github.com/login/oauth/access_token")
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(
      request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    #expect(request.value(forHTTPHeaderField: "X-GitHub-Api-Version") == nil)
    let expectedBody = [
      "client_id=id%20%2B%26", "client_secret=secret%20%2B%26", "code=code%20%2B%26",
      "redirect_uri=http%3A%2F%2F127.0.0.1%3A49152%2Foauth%2Fcallback"
        + "%3Fstate%3Dfixture-state%26code%3Dfixture-code",
      "code_verifier=verifier%20%2B%26",
    ].joined(separator: "&")
    #expect(String(data: try #require(request.httpBody), encoding: .utf8) == expectedBody)
    #expect(await transport.requests.count == 1)
  }

  @Test(
    arguments: [
      ("{}", .invalidTokenResponse),
      ("[]", .invalidTokenResponse),
      ("not-json", .invalidTokenResponse),
      ("{\"error\":\"bad_verification_code\"}", .exchangeRejected),
      ("{\"error\":\"bad_verification_code\",\"access_token\":\"fixture\"}", .exchangeRejected),
    ] as [(String, GitHubOAuthAuthorizationError)])
  func classifiesResponseEnvelopes(
    _ body: String, _ expectedError: GitHubOAuthAuthorizationError
  ) async throws {
    let transport = InitialTransport(body: body)
    let exchanger = GitHubOAuthCodeExchanger(httpClient: HTTPClient(transport: transport))
    await #expect(throws: expectedError) {
      try await exchanger.exchange(
        configuration: .init(clientID: "id", clientSecret: "secret"), code: "code",
        redirectURI: callback(), verifier: "verifier")
    }
    #expect(await transport.requests.count == 1)
  }

  @Test func rejectsNonSuccessStatus() async throws {
    let transport = InitialTransport(body: initialJSON, statusCode: 400)
    let exchanger = GitHubOAuthCodeExchanger(httpClient: HTTPClient(transport: transport))
    await #expect(throws: GitHubOAuthAuthorizationError.exchangeRejected) {
      try await exchanger.exchange(
        configuration: .init(clientID: "id", clientSecret: "secret"), code: "code",
        redirectURI: callback(), verifier: "verifier")
    }
    #expect(await transport.requests.count == 1)
  }

  @Test func cancelledBeforeRequestNeverBeginsTransport() async throws {
    let transport = InitialTransport(body: initialJSON)
    let exchanger = GitHubOAuthCodeExchanger(httpClient: HTTPClient(transport: transport))
    let configuration = try GitHubOAuthAppConfiguration(clientID: "id", clientSecret: "secret")
    let task = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await exchanger.exchange(
        configuration: configuration, code: "code", redirectURI: callback(), verifier: "verifier")
    }
    await #expect(throws: GitHubOAuthAuthorizationError.cancelled) { try await task.value }
    #expect(await transport.requests.isEmpty)
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
  let statusCode: Int

  init(body: String, statusCode: Int = 200) {
    self.body = body
    self.statusCode = statusCode
  }

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    return HTTPResponse(statusCode: statusCode, headers: [:], body: Data(body.utf8))
  }
}

enum InvalidInitialValue: Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
  case text(String)
  case number(Int)
  init(stringLiteral value: String) { self = .text(value) }
  init(integerLiteral value: Int) { self = .number(value) }
}
