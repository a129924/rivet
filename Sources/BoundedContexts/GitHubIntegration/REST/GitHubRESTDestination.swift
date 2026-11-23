import Foundation
import RivetHTTPClient

package enum GitHubRESTDestination {
  private static let scheme = "https"
  private static let host = "api.github.com"

  package static func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> HTTPURL {
    var components = URLComponents()
    components.scheme = scheme
    components.host = host
    components.path = path
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    guard let url = components.url else { throw URLError(.badURL) }
    return try HTTPURL(url)
  }

  package static func isAllowed(_ components: URLComponents) -> Bool {
    components.scheme?.lowercased() == scheme
      && components.host?.lowercased() == host
      && (components.port == nil || components.port == 443)
      && components.user == nil && components.password == nil && components.fragment == nil
  }
}
