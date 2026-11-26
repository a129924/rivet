import Foundation
import Testing

@testable import GitHubIntegration

struct GitHubUnreadNotificationsEndpointTests {
  @Test
  func firstPageUsesFixedGETDestinationAndQuery() throws {
    let endpoint = GitHubUnreadNotificationsEndpoint()

    #expect(endpoint.method.rawValue == "GET")
    #expect(endpoint.successStatus == 200)
    let url = try endpoint.makeURL().value
    #expect(url.absoluteString == "https://api.github.com/notifications?all=false&per_page=50")
  }

  @Test
  func continuationKeepsTheScopeAndIncludesTheRequestedPage() throws {
    let endpoint = GitHubUnreadNotificationsEndpoint()
    let url = try endpoint.makeURL(page: 3).value
    #expect(
      url.absoluteString == "https://api.github.com/notifications?all=false&per_page=50&page=3")
  }

  @Test(arguments: [0, -1])
  func invalidPageCannotBuildAURL(page: Int) {
    #expect(throws: (any Error).self) {
      try GitHubUnreadNotificationsEndpoint().makeURL(page: page)
    }
  }
}
