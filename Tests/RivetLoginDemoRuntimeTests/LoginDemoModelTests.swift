import RivetPresentation
import Testing

@testable import RivetLoginDemoRuntime

@Suite("Login mock flow") @MainActor
struct LoginDemoModelTests {
  @Test func browserFlowWaitsForExplicitReturnAndCompletion() {
    let model = LoginDemoModel()
    model.handle(.beginGitHubSignIn)
    #expect(model.phase == .waitingForBrowser)
    model.completeSimulation()
    #expect(model.phase == .waitingForBrowser)
    model.handle(.beginGitHubSignIn)
    #expect(model.phase == .waitingForBrowser)
    model.simulateReturn()
    #expect(model.phase == .verifyingAccount)
    model.completeSimulation()
    #expect(model.phase == .connected)
    model.handle(.retry)
    model.simulateReturn()
    #expect(model.phase == .connected)
  }

  @Test func cancelAndStaleIntentsDoNotStartOrShowError() {
    let model = LoginDemoModel()
    model.handle(.submitToken("example"))
    model.handle(.retry)
    #expect(model.phase == .welcome)
    model.handle(.beginGitHubSignIn)
    model.handle(.cancelSignIn)
    #expect(model.phase == .welcome)
    model.simulateReturn()
    model.completeSimulation()
    #expect(model.phase == .welcome)
  }

  @Test func browserFailureCanRetryOrChooseToken() {
    let model = LoginDemoModel()
    model.shouldFail = true
    model.handle(.beginGitHubSignIn)
    model.simulateReturn()
    model.completeSimulation()
    #expect(
      model.phase == .failure(.init(message: LoginDemoModel.failureMessage, origin: .browser)))
    model.handle(.retry)
    #expect(model.phase == .waitingForBrowser)
    model.simulateReturn()
    model.completeSimulation()
    model.handle(.showTokenEntry)
    #expect(model.phase == .tokenEntry)
  }

  @Test func tokenFailureKeepsFormAvailableAndDoesNotRetainInput() {
    let model = LoginDemoModel()
    model.handle(.showTokenEntry)
    model.handle(.submitToken(" \n "))
    #expect(model.phase == .tokenEntry)
    model.shouldFail = true
    model.handle(.submitToken(" arbitrary fake input "))
    #expect(model.phase == .verifyingToken)
    model.handle(.submitToken("duplicate"))
    model.completeSimulation()
    #expect(model.phase == .failure(.init(message: LoginDemoModel.failureMessage, origin: .token)))
    model.shouldFail = false
    model.handle(.submitToken("replacement"))
    model.completeSimulation()
    #expect(model.phase == .connected)
  }

  @Test func resetInvalidatesFormIdentityAndReturnsWelcome() {
    let model = LoginDemoModel()
    let identity = model.formIdentity
    model.handle(.showTokenEntry)
    model.reset()
    #expect(model.phase == .welcome)
    #expect(model.formIdentity != identity)
    #expect(!model.shouldFail)
  }
}
