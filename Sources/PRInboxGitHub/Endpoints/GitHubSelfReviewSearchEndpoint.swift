import Foundation
import GitHubIntegration
import RivetHTTPClient

struct GitHubSelfReviewSearchEndpoint {
  let method: HTTPMethod = .get
  let path = "/search/issues"
  let pageSize = 100
  let queryItems: [URLQueryItem]

  init(author: String) {
    queryItems = [
      URLQueryItem(name: "q", value: "is:pr is:open author:\(author)"),
      URLQueryItem(name: "per_page", value: String(pageSize)),
    ]
  }

  func makeURL() throws -> HTTPURL {
    try GitHubRESTDestination.makeURL(path: path, queryItems: queryItems)
  }
}
