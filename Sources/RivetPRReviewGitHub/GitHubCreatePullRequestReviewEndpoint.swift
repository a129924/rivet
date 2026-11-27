import GitHubIntegration
import RivetHTTPClient

package struct GitHubCreatePullRequestReviewEndpoint: Sendable {
  private enum ValidationError: Error {
    case invalidInput
  }

  package let method: HTTPMethod = .post
  private let owner: String
  private let repository: String
  private let pullNumber: Int

  package init(owner: String, repository: String, pullNumber: Int) {
    self.owner = owner
    self.repository = repository
    self.pullNumber = pullNumber
  }

  package func makeURL() throws -> HTTPURL {
    guard Self.isPathComponent(owner), Self.isPathComponent(repository), pullNumber > 0 else {
      throw ValidationError.invalidInput
    }
    return try GitHubRESTDestination.makeURL(
      path: "/repos/\(owner)/\(repository)/pulls/\(pullNumber)/reviews")
  }

  private static func isPathComponent(_ value: String) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && value.utf8.allSatisfy { byte in
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
          || byte == 45 || byte == 46 || byte == 95
      }
  }
}
