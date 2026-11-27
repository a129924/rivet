import Foundation
import RivetHTTPClient

struct GitHubUnreadNotificationsEndpoint {
  static let path = "/notifications"
  static let pageParameter = "page"
  static let scope = [
    URLQueryItem(name: "all", value: "false"),
    URLQueryItem(name: "per_page", value: "50"),
  ]

  let method: HTTPMethod = .get
  let successStatus = 200

  func makeURL(page: Int = 1) throws -> HTTPURL {
    guard page > 0 else { throw InvalidPage() }

    var query = Self.scope
    if page > 1 {
      query.append(URLQueryItem(name: Self.pageParameter, value: String(page)))
    }
    return try GitHubRESTDestination.makeURL(path: Self.path, queryItems: query)
  }

  private struct InvalidPage: Error {}
}
