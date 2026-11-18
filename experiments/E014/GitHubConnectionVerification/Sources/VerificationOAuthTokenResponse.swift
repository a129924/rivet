import Foundation
import GitHubIntegration

struct VerificationOAuthTokenResponse: Decodable {
  let accessToken: String
  let tokenType: GitHubOAuthTokenType
  let grantedScopes: String
  let expiresIn: Int
  let refreshToken: String
  let refreshTokenExpiresIn: Int

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case tokenType = "token_type"
    case grantedScopes = "scope"
    case expiresIn = "expires_in"
    case refreshToken = "refresh_token"
    case refreshTokenExpiresIn = "refresh_token_expires_in"
  }

  func credential(receivedAt: Date) -> GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: accessToken),
      refreshToken: GitHubOAuthRefreshToken(rawValue: refreshToken),
      accessTokenExpiresAt: receivedAt.addingTimeInterval(TimeInterval(expiresIn)),
      refreshTokenExpiresAt: receivedAt.addingTimeInterval(TimeInterval(refreshTokenExpiresIn)),
      tokenType: tokenType,
      grantedScopes: grantedScopes
    )
  }
}
