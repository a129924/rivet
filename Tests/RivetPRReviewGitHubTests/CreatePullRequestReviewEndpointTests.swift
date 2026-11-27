import RivetHTTPClient
import RivetPRReviewGitHub
import Testing

struct CreatePullRequestReviewEndpointTests {
  @Test
  func createsPostForExactPullRequest() throws {
    let endpoint = GitHubCreatePullRequestReviewEndpoint(
      owner: "An-Owner", repository: "rivet.repo_name", pullNumber: 42)
    let url = try endpoint.makeURL()
    #expect(endpoint.method == .post)
    #expect(
      url.value.absoluteString
        == "https://api.github.com/repos/An-Owner/rivet.repo_name/pulls/42/reviews")
  }

  @Test(arguments: ["", ".", "..", "a/b", "a%2Fb", "a?b", "a#b", "a b", "a\\b", "é"])
  func rejectsUnsafeOwnerAndRepository(_ value: String) {
    #expect(throws: (any Error).self) {
      try GitHubCreatePullRequestReviewEndpoint(
        owner: value, repository: "rivet", pullNumber: 42
      ).makeURL()
    }
    #expect(throws: (any Error).self) {
      try GitHubCreatePullRequestReviewEndpoint(
        owner: "owner", repository: value, pullNumber: 42
      ).makeURL()
    }
  }

  @Test(arguments: [0, -1])
  func rejectsNonpositivePullNumber(_ number: Int) {
    #expect(throws: (any Error).self) {
      try GitHubCreatePullRequestReviewEndpoint(
        owner: "owner", repository: "rivet", pullNumber: number
      ).makeURL()
    }
  }
}
