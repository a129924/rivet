import RivetHTTPClient
import RivetRepositoryPullRequestsGitHub
import Testing

@Suite("GitHub repository open pull requests endpoint")
struct RepositoryOpenPullRequestsEndpointTests {
  @Test
  func buildsTheGETDestinationForTheDefaultAndSpecifiedPages() throws {
    let endpoint = GitHubRepositoryOpenPullRequestsEndpoint(
      owner: "Owner-1", repository: "Repo.name_2")

    #expect(endpoint.method == .get)
    #expect(
      try endpoint.makeURL().value.absoluteString
        == "https://api.github.com/repos/Owner-1/Repo.name_2/pulls?state=open&per_page=100&page=1")
    #expect(
      try endpoint.makeURL(page: 2).value.absoluteString
        == "https://api.github.com/repos/Owner-1/Repo.name_2/pulls?state=open&per_page=100&page=2")
  }

  @Test(arguments: ["", ".", "..", "a/b", "a\\b", "%2f", "a?b", "a#b", "a b", "a\nb", "é"])
  func rejectsUnsafePathComponents(_ component: String) {
    let invalidOwner = GitHubRepositoryOpenPullRequestsEndpoint(
      owner: component, repository: "repo")
    let invalidRepository = GitHubRepositoryOpenPullRequestsEndpoint(
      owner: "owner", repository: component)

    #expect(throws: (any Error).self) {
      try invalidOwner.makeURL()
    }
    #expect(throws: (any Error).self) {
      try invalidRepository.makeURL()
    }
  }

  @Test(arguments: [0, -1])
  func rejectsNonpositivePages(_ page: Int) {
    let endpoint = GitHubRepositoryOpenPullRequestsEndpoint(owner: "owner", repository: "repo")

    #expect(throws: (any Error).self) {
      try endpoint.makeURL(page: page)
    }
  }
}
