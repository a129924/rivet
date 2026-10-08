import Foundation
import Testing

@testable import RefreshCore

private func credential(
  access: String = "access-old", refresh: String = "refresh-old", scope: String = "repo,gist",
  accessSeconds: Int = 3600, refreshSeconds: Int = 7200
) -> Data {
  Data(
    """
    {"access_token":"\(access)","refresh_token":"\(refresh)","expires_in":\(accessSeconds),
    "refresh_token_expires_in":\(refreshSeconds),"token_type":"bearer","scope":"\(scope)"}
    """.utf8)
}

private actor MockIO: ProbeIO {
  let initial: HTTPResult
  let rotated: HTTPResult
  let oldReuse: HTTPResult
  let users: [HTTPResult]
  let loseRefresh: Bool
  let cancelAfterInitialUser: Bool
  private(set) var authorizeCount = 0
  private(set) var exchangeCount = 0
  private(set) var refreshTokens: [String] = []
  private(set) var userTokens: [String] = []
  private(set) var closed = false

  init(
    initial: HTTPResult = HTTPResult(status: 200, body: credential()),
    rotated: HTTPResult = HTTPResult(
      status: 200,
      body: credential(
        access: "access-new", refresh: "refresh-new", scope: "gist,repo")),
    oldReuse: HTTPResult = HTTPResult(
      status: 200, body: Data("{\"error\":\"bad_refresh_token\"}".utf8)),
    users: [HTTPResult] = [
      HTTPResult(status: 200, body: Data("{\"id\":123,\"login\":\"person\"}".utf8)),
      HTTPResult(status: 200, body: Data("{\"id\":123,\"login\":\"person\"}".utf8)),
    ],
    loseRefresh: Bool = false,
    cancelAfterInitialUser: Bool = false
  ) {
    self.initial = initial
    self.rotated = rotated
    self.oldReuse = oldReuse
    self.users = users
    self.loseRefresh = loseRefresh
    self.cancelAfterInitialUser = cancelAfterInitialUser
  }

  func authorize(state: String, challenge: String) async throws -> Authorization {
    authorizeCount += 1
    return Authorization(code: "code-sentinel", redirect: "http://127.0.0.1:1234/oauth/callback")
  }
  func exchange(authorization: Authorization, verifier: String) async throws -> HTTPResult {
    exchangeCount += 1
    return initial
  }
  func refresh(token: String) async throws -> HTTPResult {
    refreshTokens.append(token)
    if loseRefresh && refreshTokens.count == 1 { throw ProbeFailure.network }
    return refreshTokens.count == 1 ? rotated : oldReuse
  }
  func user(accessToken: String) async throws -> HTTPResult {
    userTokens.append(accessToken)
    if cancelAfterInitialUser && userTokens.count == 1 {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    return users[userTokens.count - 1]
  }
  func close() async { closed = true }
}

@Test func refreshRotationHappyPath() async {
  let mock = MockIO()
  let result = await Experiment.run(transport: mock)
  #expect(result.overall == .success)
  #expect(result.initial == .success)
  #expect(result.refresh == .success)
  #expect(result.newUser == .success)
  #expect(result.oldRefresh == .success)
  #expect(await mock.authorizeCount == 1)
  #expect(await mock.exchangeCount == 1)
  #expect(await mock.refreshTokens == ["refresh-old", "refresh-old"])
  #expect(await mock.userTokens == ["access-old", "access-new"])
  #expect(await mock.closed)
  for sentinel in [
    "access-old", "access-new", "refresh-old", "refresh-new", "code-sentinel", "person", "123",
  ] {
    #expect(!result.safeReport.contains(sentinel))
  }
}

@Test func changedIdentityStillMeasuresOldRefresh() async {
  let mock = MockIO(users: [
    HTTPResult(status: 200, body: Data("{\"id\":123,\"login\":\"a\"}".utf8)),
    HTTPResult(status: 200, body: Data("{\"id\":456,\"login\":\"b\"}".utf8)),
  ])
  let result = await Experiment.run(transport: mock)
  #expect(result.newUser == .failed)
  #expect(result.oldRefresh == .success)
  #expect(result.overall == .failed)
  #expect(await mock.refreshTokens.count == 2)
}

@Test func lostRefreshResponseStopsWithoutRetry() async {
  let mock = MockIO(loseRefresh: true)
  let result = await Experiment.run(transport: mock)
  #expect(result.refresh == .indeterminate)
  #expect(result.oldRefresh == .indeterminate)
  #expect(await mock.refreshTokens.count == 1)
  #expect(await mock.userTokens.count == 1)
  #expect(await mock.closed)
}

@Test func unreadableOldRejectionIsIndeterminate() async {
  let mock = MockIO(oldReuse: HTTPResult(status: 401, body: Data("{}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.oldRefresh == .indeterminate)
  #expect(result.overall == .indeterminate)
}

@Test(arguments: [200, 400])
func readableOtherOldOAuthErrorFails(status: Int) async {
  let mock = MockIO(
    oldReuse: HTTPResult(
      status: status, body: Data("{\"error\":\"incorrect_client_credentials\"}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.oldRefresh == .failed)
  #expect(result.oldRefreshStatus == status)
  #expect(result.overall == .failed)
  #expect(await mock.refreshTokens.count == 2)
}

@Test func unexpectedTokenFromOldRefreshFails() async {
  let mock = MockIO(
    oldReuse: HTTPResult(
      status: 200,
      body: credential(
        access: "access-third", refresh: "refresh-third")))
  let result = await Experiment.run(transport: mock)
  #expect(result.oldRefresh == .failed)
  #expect(result.overall == .failed)
  #expect(await mock.refreshTokens.count == 2)
}

@Test func unchangedRefreshPairFailsBeforeFurtherCalls() async {
  let mock = MockIO(rotated: HTTPResult(status: 200, body: credential()))
  let result = await Experiment.run(transport: mock)
  #expect(result.refresh == .failed)
  #expect(await mock.refreshTokens.count == 1)
  #expect(await mock.userTokens.count == 1)
}

@Test func nonPositiveExpiryFailsBeforeFurtherCalls() async {
  let mock = MockIO(rotated: HTTPResult(status: 200, body: credential(accessSeconds: 0)))
  let result = await Experiment.run(transport: mock)
  #expect(result.refresh == .failed)
  #expect(await mock.refreshTokens.count == 1)
}

@Test func changedScopeFailsBeforeFurtherCalls() async {
  let mock = MockIO(
    rotated: HTTPResult(
      status: 200,
      body: credential(
        access: "access-new", refresh: "refresh-new", scope: "repo")))
  let result = await Experiment.run(transport: mock)
  #expect(result.refresh == .failed)
  #expect(await mock.refreshTokens.count == 1)
}

@Test func sixFieldSchemaAndReceiptTimeMapping() throws {
  let receivedAt = Date(timeIntervalSince1970: 1000)
  let body = credential(scope: "gist,repo")
  let decoded = try JSONDecoder().decode(CredentialResponse.self, from: body)
  #expect(decoded.valid)
  let bundle = decoded.bundle(receivedAt: receivedAt)
  #expect(bundle.accessTokenExpiresAt == receivedAt.addingTimeInterval(3600))
  #expect(bundle.refreshTokenExpiresAt == receivedAt.addingTimeInterval(7200))
  #expect(bundle.grantedScopes == "gist,repo")
  #expect(ResponseCheck.scopes("gist,repo") == ResponseCheck.scopes("repo,gist"))

  let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
  for key in object.keys {
    var missing = object
    missing.removeValue(forKey: key)
    let missingBody = try JSONSerialization.data(withJSONObject: missing)
    #expect(throws: (any Error).self) {
      _ = try JSONDecoder().decode(CredentialResponse.self, from: missingBody)
    }
  }
}

@Test(arguments: [
  credential(access: ""), credential(refresh: "  "),
  credential(accessSeconds: 0), credential(refreshSeconds: -1),
])
func invalidCredentialValuesFail(body: Data) {
  let response = HTTPResult(status: 200, body: body)
  let check = ResponseCheck.credential(response)
  #expect(check.verdict == .failed)
  #expect(check.reason == .invalidCredential)
}

@Test func refreshRequestHasOnlyExpectedFormFields() throws {
  let request = LiveIO.refreshRequest(
    clientID: "client-sentinel", secret: "secret&sentinel", token: "refresh+sentinel")
  #expect(request.httpMethod == "POST")
  #expect(request.url?.absoluteString == "https://github.com/login/oauth/access_token")
  #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
  #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
  let body = try #require(request.httpBody.flatMap { String(data: $0, encoding: .utf8) })
  #expect(body.contains("client_id=client-sentinel"))
  #expect(body.contains("client_secret=secret%26sentinel"))
  #expect(body.contains("grant_type=refresh_token"))
  #expect(body.contains("refresh_token=refresh%2Bsentinel"))
  #expect(!request.url!.absoluteString.contains("sentinel"))
}

@Test func initialInvalidUserStopsBeforeRefresh() async {
  let mock = MockIO(users: [
    HTTPResult(status: 200, body: Data("{\"id\":true,\"login\":\"person\"}".utf8))
  ])
  let result = await Experiment.run(transport: mock)
  #expect(result.initial == .failed)
  #expect(await mock.refreshTokens.isEmpty)
  #expect(await mock.closed)
}

@Test func readableExchangeOAuthErrorFailsWithoutInitialUserStatus() async {
  let mock = MockIO(
    initial: HTTPResult(
      status: 401, body: Data("{\"error\":\"incorrect_client_credentials\"}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.initial == .failed)
  #expect(result.initialReason == .oauthRejected)
  #expect(result.initialStatus == nil)
  #expect(await mock.userTokens.isEmpty)
}

@Test func failedExchangeDoesNotClaimInitialUserStatus() async {
  let mock = MockIO(initial: HTTPResult(status: 200, body: Data("{}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.initial == .failed)
  #expect(result.initialStatus == nil)
  #expect(await mock.userTokens.isEmpty)
  #expect(result.safeReport.contains("T01=失敗, http=未取得"))
}

@Test func oldRefreshRejectionCanArriveWithNonSuccessHTTPStatus() async {
  let mock = MockIO(
    oldReuse: HTTPResult(status: 400, body: Data("{\"error\":\"bad_refresh_token\"}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.oldRefresh == .success)
  #expect(result.oldRefreshStatus == 400)
}

@Test func freshRefreshBadTokenIsMeasuredFailure() async {
  let mock = MockIO(
    rotated: HTTPResult(status: 200, body: Data("{\"error\":\"bad_refresh_token\"}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.initial == .success)
  #expect(result.refresh == .failed)
  #expect(result.overall == .failed)
  #expect(await mock.refreshTokens.count == 1)
  #expect(await mock.userTokens.count == 1)
}

@Test(arguments: [200, 401])
func readableRefreshOAuthErrorIsFailure(status: Int) async {
  let mock = MockIO(
    rotated: HTTPResult(
      status: status, body: Data("{\"error\":\"incorrect_client_credentials\"}".utf8)))
  let result = await Experiment.run(transport: mock)
  #expect(result.initial == .success)
  #expect(result.refresh == .failed)
  #expect(result.refreshStatus == status)
  #expect(result.overall == .failed)
  #expect(await mock.refreshTokens.count == 1)
  #expect(await mock.userTokens.count == 1)
}

@Test func cancellationBeforeRefreshDoesNotClaimRotation() async {
  let mock = MockIO(cancelAfterInitialUser: true)
  let probe = Task { await Experiment.run(transport: mock) }
  let result = await probe.value
  #expect(result.initial == .success)
  #expect(result.refresh == .indeterminate)
  #expect(result.refreshReason == .interrupted)
  #expect(await mock.refreshTokens.isEmpty)
  #expect(await mock.closed)
}
