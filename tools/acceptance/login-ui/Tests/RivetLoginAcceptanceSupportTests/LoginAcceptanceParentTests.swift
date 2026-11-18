import RivetPresentation
import Testing

@testable import RivetLoginAcceptanceSupport

@Suite("Acceptance finite parent") @MainActor
struct LoginAcceptanceParentTests {
  @Test func callbacksAdvanceOnlyLegalCurrentPhases() throws {
    let parent = LoginAcceptanceParent(configuration: try .init(arguments: []))
    parent.handle(.retry)
    parent.handle(.cancelSignIn)
    parent.handle(.submitToken("discarded-input"))
    #expect(parent.phase == .welcome)
    #expect(parent.eventCount == 0)
    parent.handle(.beginGitHubSignIn)
    #expect(parent.phase == .waitingForBrowser)
    #expect(parent.lastEventKind == .beginGitHubSignIn)
    parent.handle(.beginGitHubSignIn)
    #expect(parent.eventCount == 1)
    parent.handle(.cancelSignIn)
    #expect(parent.phase == .welcome)
    #expect(parent.eventCount == 2)
    parent.handle(.showTokenEntry)
    parent.handle(.submitToken("discarded-input"))
    #expect(parent.phase == .verifyingToken)
    #expect(parent.lastEventKind == .submitToken)
    #expect(parent.eventCount == 4)
    parent.handle(.submitToken("also-discarded"))
    #expect(parent.eventCount == 4)
    #expect(parent.phase == .verifyingToken)
  }

  @Test func formConfigurationChangesKeepGenerationUntilExplicitReset() throws {
    let parent = LoginAcceptanceParent(configuration: try .init(arguments: ["--state", "pat"]))
    let generation = parent.formGeneration
    parent.setBodyPointSize(21)
    parent.selectContent(.controlled)
    parent.setCanCreateToken(true)
    parent.selectScene(.tokenFailure)
    #expect(parent.phase.isTokenForm)
    #expect(parent.formGeneration == generation)
    parent.selectScene(.pat)
    #expect(parent.formGeneration == generation)
    #expect(parent.bodyPointSize == 21)
    #expect(parent.contentSelection == .controlled)
    parent.reset()
    #expect(parent.formGeneration != generation)
    #expect(parent.phase == .tokenEntry)
    #expect(parent.bodyPointSize == 21)
    #expect(parent.contentSelection == .controlled)
    #expect(parent.canCreateToken)
    #expect(parent.lastEventKind == nil)
    #expect(parent.eventCount == 0)
  }

  @Test func creationRecordsOnlyAReceiptAndRequiresEnabledForm() throws {
    let parent = LoginAcceptanceParent(configuration: try .init(arguments: ["--state", "pat"]))
    parent.handle(.createPersonalAccessToken)
    #expect(parent.eventCount == 0)
    parent.setCanCreateToken(true)
    parent.handle(.createPersonalAccessToken)
    #expect(parent.phase == .tokenEntry)
    #expect(parent.lastEventKind == .createPersonalAccessToken)
    #expect(parent.eventCount == 1)
    parent.selectScene(.completed)
    parent.handle(.createPersonalAccessToken)
    #expect(parent.eventCount == 1)
  }

  @Test func selectedFailuresPermitOnlyTheirOwnRecovery() throws {
    let parent = LoginAcceptanceParent(
      configuration: try .init(arguments: ["--state", "browser-failure"]))
    parent.handle(.retry)
    #expect(parent.phase == .waitingForBrowser)
    parent.selectScene(.browserFailure)
    parent.handle(.showTokenEntry)
    #expect(parent.phase == .tokenEntry)
    parent.selectScene(.tokenFailure)
    let count = parent.eventCount
    parent.handle(.retry)
    #expect(parent.eventCount == count)
    parent.handle(.backToWelcome)
    #expect(parent.phase == .welcome)
  }
}
