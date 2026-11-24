import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

struct GitHubPullRequestDetailEndpoint {
  private enum ValidationError: Error {
    case invalidIdentity
  }

  let method: HTTPMethod = .get
  let id: ReaderPullRequestID

  func makeURL() throws -> HTTPURL {
    guard Self.isPathComponent(id.owner), Self.isPathComponent(id.repository), id.number > 0 else {
      throw ValidationError.invalidIdentity
    }

    return try GitHubRESTDestination.makeURL(
      path: "/repos/\(id.owner)/\(id.repository)/pulls/\(id.number)")
  }

  private static func isPathComponent(_ value: String) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && value.utf8.allSatisfy { byte in
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
          || byte == 45 || byte == 46 || byte == 95
      }
  }
}
