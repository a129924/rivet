import Foundation

enum GitHubOAuthEndpoints {
  static let authorizationURL = URL(
    string: "https://github.com/login/oauth/authorize"
  )!
  static let tokenURL = URL(
    string: "https://github.com/login/oauth/access_token"
  )!
}
