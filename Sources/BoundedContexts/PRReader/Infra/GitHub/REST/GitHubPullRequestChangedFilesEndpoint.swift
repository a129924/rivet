import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

struct GitHubPullRequestChangedFilesEndpoint {
  private enum ValidationError: Error {
    case invalidPage
  }

  let method: HTTPMethod = .get
  private let id: ReaderPullRequestID

  init(id: ReaderPullRequestID) {
    self.id = id
  }

  func makeURL(page: Int = 1) throws -> HTTPURL {
    guard page > 0 else {
      throw ValidationError.invalidPage
    }

    let pullRequestURL = try GitHubPullRequestDetailEndpoint(id: id).makeURL()
    return try GitHubRESTDestination.makeURL(
      path: pullRequestURL.value.path + "/files",
      queryItems: [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "per_page", value: "100"),
      ])
  }
}
