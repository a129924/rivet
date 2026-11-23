import Foundation
import Testing

@testable import RivetPRInboxGitHub

struct GitHubSelfReviewSearchEndpointTests {
  @Test
  func buildsAnOpenPullRequestSearchForTheAuthor() throws {
    let endpoint = GitHubSelfReviewSearchEndpoint(author: "my-user")
    let url = try endpoint.makeURL().value
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(endpoint.method.rawValue == "GET")
    #expect(components.scheme == "https")
    #expect(components.host == "api.github.com")
    #expect(components.percentEncodedPath == "/search/issues")
    #expect(components.percentEncodedQuery?.contains("is:pr%20is:open%20author:my-user") == true)
    #expect(
      components.queryItems == [
        URLQueryItem(name: "q", value: "is:pr is:open author:my-user"),
        URLQueryItem(name: "per_page", value: "100"),
      ])
  }
}
