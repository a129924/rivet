import Foundation
import GitHubIntegration
import Testing

struct GitHubRESTDestinationTests {
  @Test(arguments: [
    "https://api.github.com/user", "HTTPS://API.GITHUB.COM:443/search/issues",
    "https://api.github.com:443/user?sample=1",
  ])
  func acceptsGitHubHTTPS(_ address: String) throws {
    let components = try #require(URLComponents(string: address))
    #expect(GitHubRESTDestination.isAllowed(components))
  }

  @Test(arguments: [
    "http://api.github.com/user", "ftp://api.github.com/user", "https://github.com/user",
    "https://api.github.com.example.org/user", "https://api.github.com:444/user",
    "https://user:password@api.github.com/user", "https://@api.github.com/user",
    "https://api.github.com/user#fragment", "https://api.github.com/user#",
  ])
  func rejectsOtherDestinations(_ address: String) throws {
    let components = try #require(URLComponents(string: address))
    #expect(!GitHubRESTDestination.isAllowed(components))
  }
}
