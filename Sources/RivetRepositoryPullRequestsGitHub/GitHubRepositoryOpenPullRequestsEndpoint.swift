import Foundation
import GitHubIntegration
import RivetHTTPClient

package struct GitHubRepositoryOpenPullRequestsEndpoint: Sendable {
  private enum ValidationError: Error {
    case invalidInput
  }

  package let method: HTTPMethod = .get
  private let owner: String
  private let repository: String

  package init(owner: String, repository: String) {
    self.owner = owner
    self.repository = repository
  }

  package func makeURL(page: Int = 1) throws -> HTTPURL {
    guard Self.isPathComponent(owner), Self.isPathComponent(repository), page > 0 else {
      throw ValidationError.invalidInput
    }

    return try GitHubRESTDestination.makeURL(
      path: "/repos/\(owner)/\(repository)/pulls",
      queryItems: [
        URLQueryItem(name: "state", value: "open"),
        URLQueryItem(name: "per_page", value: "100"),
        URLQueryItem(name: "page", value: String(page)),
      ])
  }

  private static func isPathComponent(_ value: String) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && value.utf8.allSatisfy { byte in
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
          || byte == 45 || byte == 46 || byte == 95
      }
  }
}
