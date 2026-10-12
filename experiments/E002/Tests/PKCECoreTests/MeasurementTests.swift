import Foundation
import Testing

@testable import PKCECore

private let credentialJSON = Data(
  """
  {"access_token":"access-sentinel","refresh_token":"refresh-sentinel","expires_in":3600,
  "refresh_token_expires_in":7200,"token_type":"bearer","scope":""}
  """.utf8)

actor MockIO: ProbeIO {
  var authorizations: [(String, String)] = []
  var exchanges: [(Authorization, String)] = []
  var userCount = 0
  var closed = false
  let positive: HTTPResult
  let negative: HTTPResult
  let userResponse: HTTPResult
  let failUser: Bool
  init(
    positive: Data = credentialJSON,
    negative: Data = Data("{\"error\":\"bad_verification_code\"}".utf8),
    userStatus: Int = 200, failUser: Bool = false
  ) {
    self.positive = HTTPResult(status: 200, body: positive)
    self.negative = HTTPResult(status: 200, body: negative)
    userResponse = HTTPResult(
      status: userStatus, body: Data("{\"id\":123,\"login\":\"login-sentinel\"}".utf8))
    self.failUser = failUser
  }
  func authorize(state: String, challenge: String) async throws -> Authorization {
    authorizations.append((state, challenge))
    return Authorization(
      code: "code-sentinel-\(authorizations.count)",
      redirect: "http://127.0.0.1:1234/oauth/callback")
  }
  func exchange(authorization: Authorization, verifier: String) async throws -> HTTPResult {
    exchanges.append((authorization, verifier))
    return exchanges.count == 1 ? positive : negative
  }
  func user(accessToken: String) async throws -> HTTPResult {
    userCount += 1
    if failUser { throw ProbeFailure.network }
    return userResponse
  }
  func close() async { closed = true }
}

@Test func controlledPositiveAndNegative() async {
  let transport = MockIO()
  let result = await Experiment.run(transport: transport)
  #expect(result.overall == .success)
  let authorizations = await transport.authorizations
  let exchanges = await transport.exchanges
  #expect(authorizations.count == 2)
  #expect(exchanges.count == 2)
  #expect(exchanges[0].0.code != exchanges[1].0.code)
  #expect(authorizations[0].0 != authorizations[1].0)
  #expect(PKCE.challenge(exchanges[0].1) == authorizations[0].1)
  #expect(PKCE.challenge(exchanges[1].1) != authorizations[1].1)
  #expect(await transport.userCount == 1)
  #expect(await transport.closed)
  for sentinel in ["access-sentinel", "refresh-sentinel", "login-sentinel", "code-sentinel"] {
    #expect(!result.safeReport.contains(sentinel))
  }
}

@Test func missingSchemaStillCallsUserAndNegative() async {
  let transport = MockIO(
    positive: Data("{\"access_token\":\"access-sentinel\"}".utf8), userStatus: 403)
  let result = await Experiment.run(transport: transport)
  #expect(result.exchange == .success)
  #expect(result.schema == .failed)
  #expect(result.api == .failed)
  #expect(result.pkce == .success)
  #expect(result.overall == .failed)
  #expect(await transport.authorizations.count == 2)
}

@Test func noBaselineStopsAtOneAuthorization() async {
  let transport = MockIO(positive: Data("{\"error\":\"bad_verification_code\"}".utf8))
  let result = await Experiment.run(transport: transport)
  #expect(result.exchange == .indeterminate)
  #expect(result.pkce == .indeterminate)
  #expect(await transport.authorizations.count == 1)
  #expect(await transport.userCount == 0)
  #expect(await transport.closed)
}

@Test func networkStopsWithoutNegative() async {
  let transport = MockIO(failUser: true)
  let result = await Experiment.run(transport: transport)
  #expect(result.exchange == .success)
  #expect(result.api == .indeterminate)
  #expect(result.pkce == .indeterminate)
  #expect(await transport.authorizations.count == 1)
  #expect(await transport.closed)
}

@Test(arguments: ["access_token", "refresh_token"])
func unexpectedNegativeTokenFails(key: String) async {
  let transport = MockIO(
    negative: Data("{\"\(key)\":\"token-sentinel\",\"error\":\"bad_verification_code\"}".utf8))
  #expect(await Experiment.run(transport: transport).pkce == .failed)
}

@Test func unknownNegativeErrorIsIndeterminate() async {
  let transport = MockIO(negative: Data("{\"error\":\"unconfirmed\"}".utf8))
  #expect(await Experiment.run(transport: transport).pkce == .indeterminate)
}

@Test func sixFieldsAndExpiry() throws {
  let time = Date(timeIntervalSince1970: 1000)
  let credential = try JSONDecoder().decode(CredentialResponse.self, from: credentialJSON).bundle(
    receivedAt: time)
  #expect(credential.accessTokenExpiresAt == time.addingTimeInterval(3600))
  #expect(credential.refreshTokenExpiresAt == time.addingTimeInterval(7200))
  #expect(credential.grantedScopes.isEmpty)
  let object = try #require(JSONSerialization.jsonObject(with: credentialJSON) as? [String: Any])
  for key in object.keys {
    var missing = object
    missing.removeValue(forKey: key)
    let data = try JSONSerialization.data(withJSONObject: missing)
    #expect(throws: (any Error).self) {
      _ = try JSONDecoder().decode(CredentialResponse.self, from: data)
    }
    var wrong = object
    wrong[key] = key.contains("expires") ? "string" : 123
    let invalid = try JSONSerialization.data(withJSONObject: wrong)
    #expect(throws: (any Error).self) {
      _ = try JSONDecoder().decode(CredentialResponse.self, from: invalid)
    }
  }
}

@Test func validUserRequiresShape() {
  for body in [
    "[]", "{\"id\":true,\"login\":\"x\"}", "{\"id\":1.5,\"login\":\"x\"}",
    "{\"id\":1,\"login\":\"\"}", "{\"id\":0,\"login\":\"x\"}",
  ] {
    #expect(!ResponseCheck.validUser(HTTPResult(status: 200, body: Data(body.utf8))))
  }
}

@Test(arguments: [
  "incorrect_client_credentials", "redirect_uri_mismatch", "unconfirmed-sentinel-error",
])
func prerequisiteOAuthErrorIsIndeterminate(errorCode: String) async {
  let transport = MockIO(
    positive: Data("{\"error\":\"\(errorCode)\",\"error_description\":\"secret-sentinel\"}".utf8))
  let result = await Experiment.run(transport: transport)
  #expect(result.exchange == .indeterminate)
  #expect(result.overall == .indeterminate)
  #expect(await transport.authorizations.count == 1)
  #expect(await transport.exchanges.count == 1)
  #expect(await transport.userCount == 0)
  #expect(await transport.closed)
  #expect(!result.safeReport.contains("sentinel"))
}

@Test func schemaFailureReasonSurvivesNegativeSuccess() async {
  let transport = MockIO(positive: Data("{\"access_token\":\"access-sentinel\"}".utf8))
  let result = await Experiment.run(transport: transport)
  #expect(result.schema == .failed)
  #expect(result.pkce == .success)
  #expect(result.safeReport.contains("schema 六欄不相容"))
  #expect(!result.safeReport.contains("sentinel"))
}

@Test func apiFailureReasonSurvivesNegativeSuccess() async {
  let transport = MockIO(userStatus: 403)
  let result = await Experiment.run(transport: transport)
  #expect(result.api == .failed)
  #expect(result.pkce == .success)
  #expect(result.safeReport.contains("API status 或 user shape 不符"))
  #expect(!result.safeReport.contains("sentinel"))
}

@Test func apiNetworkReasonAndUnexecutedPKCEArePreserved() async {
  let transport = MockIO(failUser: true)
  let result = await Experiment.run(transport: transport)
  #expect(result.api == .indeterminate)
  #expect(result.pkce == .indeterminate)
  #expect(result.safeReport.contains("API：網路、逾時或取消阻止測量"))
  #expect(result.safeReport.contains("PKCE：前序中止，未執行反向授權"))
  #expect(await transport.authorizations.count == 1)
  #expect(await transport.closed)
  #expect(!result.safeReport.contains("sentinel"))
}

@Test func validExchangeWithoutTokenRemainsMeasuredFailure() async {
  let transport = MockIO(positive: Data("{}".utf8))
  let result = await Experiment.run(transport: transport)
  #expect(result.exchange == .failed)
  #expect(result.overall == .failed)
  #expect(result.exchangeReason == .noToken)
  #expect(result.schemaReason == .notExecuted)
  #expect(result.apiReason == .notExecuted)
  #expect(result.pkceReason == .notExecuted)
  #expect(await transport.authorizations.count == 1)
  #expect(await transport.userCount == 0)
  #expect(await transport.closed)
}
