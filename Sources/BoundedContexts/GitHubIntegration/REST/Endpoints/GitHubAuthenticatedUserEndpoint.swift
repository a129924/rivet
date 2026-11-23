import RivetHTTPClient

package struct GitHubAuthenticatedUserEndpoint: Sendable {
  package static let shared = Self()

  package var method: HTTPMethod { .get }

  package init() {}

  package func makeURL() throws -> HTTPURL {
    try GitHubRESTDestination.makeURL(path: "/user")
  }
}
