import Foundation
import GitHubIntegration
import Testing

struct GitHubAuthenticatedUserEndpointTests {
  @Test
  func directInstanceAndSharedInstanceDescribeTheSameQuerylessGET() throws {
    for endpoint in [GitHubAuthenticatedUserEndpoint(), .shared] {
      let url = try endpoint.makeURL().value
      #expect(endpoint.method.rawValue == "GET")
      #expect(url.absoluteString == "https://api.github.com/user")
      #expect(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems == nil)
    }
  }
}
