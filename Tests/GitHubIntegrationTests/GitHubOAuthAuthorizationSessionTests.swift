import CryptoKit
import Foundation
import RivetHTTPClient
import Synchronization
import Testing

@testable import GitHubIntegration

@Suite("GitHub initial OAuth authorization")
struct GitHubOAuthAuthorizationSessionTests {
  @Test func authorizationUsesStatePKCEAndNoSecret() async throws {
    let session = try makeSession()
    let components = try #require(
      URLComponents(url: session.authorizationURL, resolvingAgainstBaseURL: false))
    let query = Dictionary(
      uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    #expect(components.scheme == "https")
    #expect(components.host == "github.com")
    #expect(components.path == "/login/oauth/authorize")
    #expect(query["scope"] == "offline_access")
    #expect(query["state"] == "fake-state")
    #expect(query["code_challenge_method"] == "S256")
    let digest = Data(SHA256.hash(data: Data("fake-verifier".utf8))).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    #expect(query["code_challenge"] == digest)
    #expect(query["client_secret"] == nil)
    #expect(!session.authorizationURL.absoluteString.contains("fake-secret"))
  }

  @Test(arguments: [
    "https://127.0.0.1:43210/oauth/callback?state=fake-state&code=fake-code",
    "http://localhost:43210/oauth/callback?state=fake-state&code=fake-code",
    "http://127.0.0.1:43211/oauth/callback?state=fake-state&code=fake-code",
    "http://127.0.0.1:43210/wrong?state=fake-state&code=fake-code",
    "http://user@127.0.0.1:43210/oauth/callback?state=fake-state&code=fake-code",
    "http://127.0.0.1:43210/oauth/callback?state=fake-state&code=fake-code#fragment",
    "http://127.0.0.1:43210/oauth/callback?state=wrong&code=fake-code",
    "http://127.0.0.1:43210/oauth/callback?state=fake-state&state=fake-state&code=fake-code",
    "http://127.0.0.1:43210/oauth/callback?state=fake-state&code=one&code=two",
    "http://127.0.0.1:43210/oauth/callback?state=fake-state&code=fake-code&error=access_denied",
    "http://127.0.0.1:43210/oauth/callback?state=fake-state&code=",
    "http://127.0.0.1:43210/oauth/callback?code=fake-code",
    "http://127.0.0.1:43210/oauth/%63allback?state=fake-state&code=fake-code",
    "http://127.0.0.1:43210/oauth/callback?state=fake-state&code=fake-code&extra=one&extra=two",
  ])
  func invalidCallbacksTerminateWithoutExchange(_ rawURL: String) async throws {
    let calls = ExchangeRecorder()
    let session = try makeSession(exchange: calls.exchange)
    await #expect(throws: GitHubOAuthError.invalidCallback) {
      try await session.complete(callbackURL: URL(string: rawURL)!)
    }
    await #expect(throws: GitHubOAuthError.sessionConsumed) {
      try await session.complete(callbackURL: validCallback)
    }
    #expect(calls.count == 0)
  }

  @Test func deniedCancellationAndExpiryAreDistinct() async throws {
    let denied = try makeSession()
    await #expect(throws: GitHubOAuthError.denied) {
      try await denied.complete(
        callbackURL: URL(
          string: "http://127.0.0.1:43210/oauth/callback?state=fake-state&error=access_denied")!)
    }
    let cancelled = try makeSession()
    await cancelled.cancel()
    await #expect(throws: GitHubOAuthError.cancelled) {
      try await cancelled.complete(callbackURL: validCallback)
    }
    let clock = AuthorizationClock()
    let expired = try makeSession(now: { clock.now() })
    clock.advance(300)
    await #expect(throws: GitHubOAuthError.expiredSession) {
      try await expired.complete(callbackURL: validCallback)
    }
  }

  @Test func exchangeUsesExactFormAndConsumesCodeOnce() async throws {
    let recorder = ExchangeRecorder()
    let session = try makeSession(exchange: recorder.exchange)
    let bundle = try await session.complete(callbackURL: validCallback)
    #expect(bundle.accessToken.rawValue == "fake-access")
    #expect(bundle.refreshToken.rawValue == "fake-refresh")
    #expect(bundle.accessTokenExpiresAt == authorizationDate.addingTimeInterval(60))
    #expect(bundle.refreshTokenExpiresAt == authorizationDate.addingTimeInterval(600))
    #expect(bundle.grantedScopes.isEmpty)
    #expect(recorder.count == 1)
    let request = try #require(recorder.request)
    #expect(request.url == GitHubOAuthEndpoints.tokenURL)
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(
      request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    let body = try #require(String(data: request.httpBody ?? Data(), encoding: .utf8))
    let fields = URLComponents(string: "http://example.test/?" + body)?.queryItems
    let values = Dictionary(uniqueKeysWithValues: (fields ?? []).map { ($0.name, $0.value ?? "") })
    #expect(
      values == [
        "client_id": "fake-id", "client_secret": "fake-secret", "code": "fake-code",
        "redirect_uri": redirect.absoluteString, "code_verifier": "fake-verifier",
      ])
    await #expect(throws: GitHubOAuthError.sessionConsumed) {
      try await session.complete(callbackURL: validCallback)
    }
    #expect(recorder.count == 1)
  }

  @Test
  func concurrentCompleteAndLateCancelPreserveResponse() async throws {
    let latch = AuthorizationLatch()
    let session = try makeSession(exchange: { _ in
      await latch.arriveAndWait()
      return tokenResponse()
    })
    let first = Task { try await session.complete(callbackURL: validCallback) }
    await latch.waitForArrival()
    await #expect(throws: GitHubOAuthError.sessionConsumed) {
      try await session.complete(callbackURL: validCallback)
    }
    await session.cancel()
    await latch.open()
    #expect(try await first.value.accessToken.rawValue == "fake-access")
  }

  @Test(arguments: [
    "{}", "{\"error\":\"bad_verification_code\",\"access_token\":\"fake\"}",
  ])
  func invalidResponsesAreFinite(_ body: String) async throws {
    let session = try makeSession(exchange: { _ in
      HTTPResponse(statusCode: 200, headers: [:], body: Data(body.utf8))
    })
    await #expect(throws: GitHubOAuthError.invalidTokenResponse) {
      try await session.complete(callbackURL: validCallback)
    }
  }

  @Test(arguments: [
    "missing-access_token", "missing-refresh_token", "missing-token_type", "missing-scope",
    "missing-expires_in", "missing-refresh_token_expires_in", "empty-refresh", "non-bearer",
    "negative-expiry", "fractional-expiry", "zero-refresh-expiry", "wrong-scope", "mixed-error",
    "null-error", "bad-error-type", "zero-expiry", "empty-access",
  ])
  func validatesEveryTokenField(_ variant: String) async throws {
    var object: [String: Any] = [
      "access_token": "fake-access", "refresh_token": "fake-refresh", "token_type": "bearer",
      "scope": "", "expires_in": 60, "refresh_token_expires_in": 600,
    ]
    if variant.hasPrefix("missing-") { object.removeValue(forKey: String(variant.dropFirst(8))) }
    let mutations: [String: (String, Any)] = [
      "empty-access": ("access_token", ""), "empty-refresh": ("refresh_token", ""),
      "non-bearer": ("token_type", "mac"), "negative-expiry": ("expires_in", -1),
      "zero-expiry": ("expires_in", 0), "fractional-expiry": ("expires_in", 0.5),
      "zero-refresh-expiry": ("refresh_token_expires_in", 0), "wrong-scope": ("scope", [String]()),
      "mixed-error": ("error", "incorrect_client_credentials"), "null-error": ("error", NSNull()),
      "bad-error-type": ("error", 1),
    ]
    if let (key, value) = mutations[variant] { object[key] = value }
    let body = try JSONSerialization.data(withJSONObject: object)
    let session = try makeSession(exchange: { _ in
      HTTPResponse(statusCode: 200, headers: [:], body: body)
    })
    await #expect(throws: GitHubOAuthError.invalidTokenResponse) {
      try await session.complete(callbackURL: validCallback)
    }
  }

  @Test(arguments: [300, 302, 400, 401, 500])
  func tokenShapedUnsuccessfulHTTPIsNeverAccepted(_ status: Int) async throws {
    let session = try makeSession(exchange: { _ in
      HTTPResponse(statusCode: status, headers: [:], body: tokenResponse().body)
    })
    await #expect(throws: GitHubOAuthError.invalidTokenResponse) {
      try await session.complete(callbackURL: validCallback)
    }
  }

  @Test func responseReceiptMustHaveFiniteDateAndTransportIsNotRetried() async throws {
    let clock = AuthorizationClock()
    let session = try makeSession(
      now: { clock.now() },
      exchange: { _ in
        clock.advance(.infinity)
        return tokenResponse()
      })
    await #expect(throws: GitHubOAuthError.invalidTokenResponse) {
      try await session.complete(callbackURL: validCallback)
    }
    let calls = Mutex(0)
    let failed = try makeSession(exchange: { _ in
      calls.withLock { $0 += 1 }
      throw FakeAuthorizationFailure.failed
    })
    await #expect(throws: GitHubOAuthError.transport) {
      try await failed.complete(callbackURL: validCallback)
    }
    await #expect(throws: GitHubOAuthError.sessionConsumed) {
      try await failed.complete(callbackURL: validCallback)
    }
    #expect(calls.withLock { $0 } == 1)
  }

  @Test func requestEscapingPreservesReservedCharacters() async throws {
    let secret = "fake-secret &+=?/☃"
    let code = "fake-code &+=?/☃"
    let configuration = try GitHubOAuthAppConfiguration(clientID: "fake-id", clientSecret: secret)
    let recorder = ExchangeRecorder()
    let session = try GitHubOAuthAuthorizationSession(
      configuration: configuration, redirectURI: redirect, state: "fake-state",
      verifier: "fake-verifier", now: { authorizationDate }, exchange: recorder.exchange)
    var callback = URLComponents(url: redirect, resolvingAgainstBaseURL: false)!
    callback.queryItems = [
      .init(name: "state", value: "fake-state"), .init(name: "code", value: code),
    ]
    _ = try await session.complete(callbackURL: callback.url!)
    let request = try #require(recorder.request)
    let body = try #require(String(data: request.httpBody ?? Data(), encoding: .utf8))
    let fields = URLComponents(string: "http://example.test/?" + body)?.queryItems ?? []
    #expect(fields.first { $0.name == "client_secret" }?.value == secret)
    #expect(fields.first { $0.name == "code" }?.value == code)
    #expect(!session.authorizationURL.absoluteString.contains("client_secret"))
  }

  @Test func rejectsConfigurationAndTransportWithoutLeakingPayload() async throws {
    let session = try makeSession(exchange: { _ in
      HTTPResponse(
        statusCode: 401, headers: [:],
        body: Data("{\"error\":\"incorrect_client_credentials\"}".utf8))
    })
    await #expect(throws: GitHubOAuthError.clientConfiguration) {
      try await session.complete(callbackURL: validCallback)
    }
    let transport = try makeSession(exchange: { _ in throw FakeAuthorizationFailure.failed })
    await #expect(throws: GitHubOAuthError.transport) {
      try await transport.complete(callbackURL: validCallback)
    }
    let invalidClock = try makeSession(now: { Date(timeIntervalSince1970: .infinity) })
    await #expect(throws: GitHubOAuthError.invalidTokenResponse) {
      try await invalidClock.complete(callbackURL: validCallback)
    }
  }
}

private let authorizationDate = Date(timeIntervalSince1970: 1_800_000_000)
private let redirect = URL(string: "http://127.0.0.1:43210/oauth/callback")!
private let validCallback = URL(
  string: redirect.absoluteString + "?state=fake-state&code=fake-code")!
private enum FakeAuthorizationFailure: Error { case failed }

private func makeSession(
  now: @escaping @Sendable () -> Date = { authorizationDate },
  exchange: @escaping @Sendable (URLRequest) async throws -> HTTPResponse = { _ in tokenResponse() }
) throws -> GitHubOAuthAuthorizationSession {
  try GitHubOAuthAuthorizationSession(
    configuration: GitHubOAuthAppConfiguration(clientID: "fake-id", clientSecret: "fake-secret"),
    redirectURI: redirect, state: "fake-state", verifier: "fake-verifier", now: now,
    exchange: exchange)
}

private func tokenResponse() -> HTTPResponse {
  HTTPResponse(
    statusCode: 200, headers: [:],
    body: Data(
      """
      {"access_token":"fake-access","refresh_token":"fake-refresh","token_type":"bearer",
      "scope":"","expires_in":60,"refresh_token_expires_in":600}
      """.utf8))
}

private final class ExchangeRecorder: Sendable {
  private let requests = Mutex<[URLRequest]>([])
  var count: Int { requests.withLock { $0.count } }
  var request: URLRequest? { requests.withLock { $0.first } }
  func exchange(_ request: URLRequest) async throws -> HTTPResponse {
    requests.withLock { $0.append(request) }
    return tokenResponse()
  }
}

private final class AuthorizationClock: Sendable {
  private let value = Mutex(authorizationDate)
  func now() -> Date { value.withLock { $0 } }
  func advance(_ seconds: TimeInterval) { value.withLock { $0 += seconds } }
}

private actor AuthorizationLatch {
  private var arrived = false
  private var arrival: CheckedContinuation<Void, Never>?
  private var release: CheckedContinuation<Void, Never>?
  func arriveAndWait() async {
    arrived = true
    arrival?.resume()
    arrival = nil
    await withCheckedContinuation { release = $0 }
  }
  func waitForArrival() async {
    if !arrived { await withCheckedContinuation { arrival = $0 } }
  }
  func open() {
    release?.resume()
    release = nil
  }
}
