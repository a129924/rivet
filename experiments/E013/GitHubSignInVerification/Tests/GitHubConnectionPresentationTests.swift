import Testing

@testable import GitHubSignInVerification

struct GitHubConnectionPresentationTests {
  @Test func copyRequiresActiveAttemptAndConsumedAttemptCannotRestart() {
    let settled = GitHubConnectionPresentation(
      status: "已停止", isBusy: false, canRetry: false, canQuery: false,
      canStart: false, canCopyAuthorizationURL: true)
    #expect(!settled.canStart)
    #expect(!settled.canCopyAuthorizationURL)
  }

  @Test func busyPresentationDisablesConflictingActions() {
    let input = GitHubConnectionPresentation(
      status: "等待授權", isBusy: true, canRetry: true, canQuery: true)
    #expect(input.canCancel)
    #expect(!input.canStart)
    #expect(!input.canRetry)
    #expect(!input.canQuery)
  }
}

@MainActor final class BrowserPresentationCalls {
  var opens = 0
  var copies = 0
}
