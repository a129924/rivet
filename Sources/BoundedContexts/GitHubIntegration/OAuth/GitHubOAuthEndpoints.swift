import Foundation

struct GitHubOAuthEndpoint: Sendable {
  static let authorization = Self(url: URL(string: "https://github.com/login/oauth/authorize")!)
  static let token = Self(url: URL(string: "https://github.com/login/oauth/access_token")!)

  let url: URL

  private init(url: URL) {
    self.url = url
  }
}
