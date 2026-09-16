import Foundation
import Testing
@testable import GitHubIntegration

@Suite("GitHub OAuth credential bundle")
struct GitHubOAuthCredentialBundleTests {
  @Test
  func tokenResponseDecodesAllRequiredGitHubOAuthAppFields() throws {
    let response = try decodeTokenResponse()
    let hasExpectedAccessToken = isExpectedAccessToken(response.accessToken)
    let hasExpectedRefreshToken = isExpectedRefreshToken(response.refreshToken)

    #expect(hasExpectedAccessToken)
    #expect(response.tokenType == .bearer)
    #expect(response.grantedScopes == "repo,gist")
    #expect(response.expiresIn == 28_800)
    #expect(hasExpectedRefreshToken)
    #expect(response.refreshTokenExpiresIn == 15_897_600)
  }

  @Test
  func credentialMapsRelativeExpiryAtTheCallerSuppliedReceiptTime() throws {
    let receivedAt = Date(timeIntervalSinceReferenceDate: 1_000)
    let credential = try decodeTokenResponse().credential(receivedAt: receivedAt)
    let hasExpectedAccessToken = isExpectedAccessToken(credential.accessToken.rawValue)
    let hasExpectedRefreshToken = isExpectedRefreshToken(credential.refreshToken.rawValue)

    #expect(hasExpectedAccessToken)
    #expect(hasExpectedRefreshToken)
    #expect(credential.accessTokenExpiresAt == receivedAt.addingTimeInterval(28_800))
    #expect(
      credential.refreshTokenExpiresAt
        == receivedAt.addingTimeInterval(15_897_600)
    )
    #expect(credential.tokenType == .bearer)
    #expect(credential.grantedScopes == "repo,gist")
  }

  @Test(arguments: [
    "access_token",
    "token_type",
    "scope",
    "expires_in",
    "refresh_token",
    "refresh_token_expires_in",
  ])
  func missingAnyRequiredFieldFailsToDecode(_ field: String) {
    let json = tokenResponseJSON(removing: field)

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(GitHubOAuthTokenResponse.self, from: json)
    }
  }

  @Test
  func unknownTokenTypeFailsToDecode() {
    let json = tokenResponseJSON(
      replacing: "\"token_type\": \"bearer\"",
      with: "\"token_type\": \"token\""
    )

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(GitHubOAuthTokenResponse.self, from: json)
    }
  }

  @Test
  func publicCredentialValuesAreSendable() {
    let credential = GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: "test-access-token"),
      refreshToken: GitHubOAuthRefreshToken(rawValue: "test-refresh-token"),
      accessTokenExpiresAt: .distantFuture,
      refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer,
      grantedScopes: "repo,gist"
    )

    assertSendable(GitHubOAuthRefreshToken(rawValue: "test-refresh-token"))
    assertSendable(GitHubOAuthTokenType.bearer)
    assertSendable(credential)
  }
}

private func decodeTokenResponse() throws -> GitHubOAuthTokenResponse {
  try JSONDecoder().decode(GitHubOAuthTokenResponse.self, from: tokenResponseJSON())
}

private func tokenResponseJSON(
  removing field: String? = nil,
  replacing original: String? = nil,
  with replacement: String? = nil
) -> Data {
  let fields = [
    ("access_token", "\"gho_access_fixture\""),
    ("token_type", "\"bearer\""),
    ("scope", "\"repo,gist\""),
    ("expires_in", "28800"),
    ("refresh_token", "\"ghr_refresh_fixt\""),
    ("refresh_token_expires_in", "15897600"),
  ]

  let entries =
    fields
    .filter { $0.0 != field }
    .map { "  \"\($0.0)\": \($0.1)" }
    .joined(separator: ",\n")

  var json = "{\n\(entries)\n}"

  if let original, let replacement {
    json = json.replacingOccurrences(of: original, with: replacement)
  }

  return Data(json.utf8)
}

private func assertSendable<Value: Sendable>(_ value: Value) {}

private func isExpectedAccessToken(_ value: String) -> Bool {
  value == "gho_access_fixture"
}

private func isExpectedRefreshToken(_ value: String) -> Bool {
  value == "ghr_refresh_fixt"
}
