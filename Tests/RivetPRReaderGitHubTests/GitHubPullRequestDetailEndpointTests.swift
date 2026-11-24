import RivetPRReader
import Testing

@testable import RivetPRReaderGitHub

@Suite("GitHub pull request detail endpoint")
struct GitHubPullRequestDetailEndpointTests {
  @Test
  func buildsTheFixedGETDestination() throws {
    let id = ReaderPullRequestID(owner: "Owner-1", repository: "Repo.name_2", number: 42)
    let endpoint = GitHubPullRequestDetailEndpoint(id: id)

    #expect(endpoint.method == .get)
    #expect(
      try endpoint.makeURL().value.absoluteString
        == "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42")
  }

  @Test(arguments: ["", ".", "..", "a/b", "a\\b", "%2f", "a?b", "a#b", "a b", "a\nb", "é"])
  func rejectsUnsafePathComponents(_ component: String) {
    let invalidOwner = ReaderPullRequestID(owner: component, repository: "repo", number: 42)
    let invalidRepo = ReaderPullRequestID(owner: "owner", repository: component, number: 42)

    #expect(throws: (any Error).self) {
      try GitHubPullRequestDetailEndpoint(id: invalidOwner).makeURL()
    }
    #expect(throws: (any Error).self) {
      try GitHubPullRequestDetailEndpoint(id: invalidRepo).makeURL()
    }
  }

  @Test(arguments: [0, -1])
  func rejectsNonpositiveNumbers(_ number: Int) {
    let id = ReaderPullRequestID(owner: "owner", repository: "repo", number: number)

    #expect(throws: (any Error).self) {
      try GitHubPullRequestDetailEndpoint(id: id).makeURL()
    }
  }
}
