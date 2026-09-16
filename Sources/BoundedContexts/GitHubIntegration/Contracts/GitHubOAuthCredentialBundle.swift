import Foundation

public struct GitHubOAuthRefreshToken: Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public enum GitHubOAuthTokenType: String, Decodable, Sendable {
  case bearer
}

public struct GitHubOAuthCredentialBundle: Sendable {
  public let accessToken: GitHubAccessToken
  public let refreshToken: GitHubOAuthRefreshToken
  public let accessTokenExpiresAt: Date
  public let refreshTokenExpiresAt: Date
  public let tokenType: GitHubOAuthTokenType
  public let grantedScopes: String

  public init(
    accessToken: GitHubAccessToken,
    refreshToken: GitHubOAuthRefreshToken,
    accessTokenExpiresAt: Date,
    refreshTokenExpiresAt: Date,
    tokenType: GitHubOAuthTokenType,
    grantedScopes: String
  ) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.accessTokenExpiresAt = accessTokenExpiresAt
    self.refreshTokenExpiresAt = refreshTokenExpiresAt
    self.tokenType = tokenType
    self.grantedScopes = grantedScopes
  }
}

struct GitHubOAuthTokenResponse: Decodable {
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
