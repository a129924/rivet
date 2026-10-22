import Testing

@testable import GitHubSignInVerification

struct GitHubConnectionPresentationTests {
  @Test func busyPresentationDisablesConflictingActions() {
    let input = GitHubConnectionPresentation(
      status: "等待授權", isBusy: true, canRetry: true, canQuery: true)
    #expect(input.canCancel)
    #expect(!input.canStart)
    #expect(!input.canRetry)
    #expect(!input.canQuery)
  }
}
