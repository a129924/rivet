import RivetPRReader
import Testing

@testable import RivetPRReaderGitHub

@Suite("GitHub pull request reviews endpoint")
struct GitHubPullRequestReviewsEndpointTests {
  @Test
  func buildsDifferentPagesForTheSamePullRequest() throws {
    let id = ReaderPullRequestID(owner: "Owner-1", repository: "Repo.name_2", number: 42)
    let endpoint = GitHubPullRequestReviewsEndpoint(id: id)

    #expect(endpoint.method == .get)
    #expect(
      try endpoint.makeURL().value.absoluteString
        == "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=1&per_page=100"
    )
    #expect(
      try endpoint.makeURL(page: 2).value.absoluteString
        == "https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42/reviews?page=2&per_page=100"
    )
  }

  @Test(arguments: [31, Int.max])
  func acceptsPositivePageNumbers(_ page: Int) throws {
    let id = ReaderPullRequestID(owner: "owner", repository: "repo", number: 42)
    let endpoint = GitHubPullRequestReviewsEndpoint(id: id)

    #expect(
      try endpoint.makeURL(page: page).value.absoluteString
        == "https://api.github.com/repos/owner/repo/pulls/42/reviews?page=\(page)&per_page=100")
  }

  @Test(arguments: ["", ".", "..", "a/b", "a\\b", "%2f", "a?b", "a#b", "a b", "a\nb", "é"])
  func rejectsUnsafePathComponents(_ component: String) {
    let invalidOwner = ReaderPullRequestID(owner: component, repository: "repo", number: 42)
    let invalidRepo = ReaderPullRequestID(owner: "owner", repository: component, number: 42)

    #expect(throws: (any Error).self) {
      try GitHubPullRequestReviewsEndpoint(id: invalidOwner).makeURL()
    }
    #expect(throws: (any Error).self) {
      try GitHubPullRequestReviewsEndpoint(id: invalidRepo).makeURL()
    }
  }

  @Test(arguments: [0, -1])
  func rejectsNonpositivePullRequestNumbers(_ number: Int) {
    let id = ReaderPullRequestID(owner: "owner", repository: "repo", number: number)

    #expect(throws: (any Error).self) {
      try GitHubPullRequestReviewsEndpoint(id: id).makeURL()
    }
  }

  @Test(arguments: [0, -1])
  func rejectsNonpositivePageNumbers(_ page: Int) {
    let id = ReaderPullRequestID(owner: "owner", repository: "repo", number: 42)
    let endpoint = GitHubPullRequestReviewsEndpoint(id: id)

    #expect(throws: (any Error).self) {
      try endpoint.makeURL(page: page)
    }
  }
}
