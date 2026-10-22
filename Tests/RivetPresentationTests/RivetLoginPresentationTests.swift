import Testing

@testable import RivetPresentation

@Suite("Login local form")
struct RivetLoginPresentationTests {
  @Test func whitespaceCannotSubmit() {
    var form = RivetLoginTokenInput()
    form.text = " \n\t "
    #expect(!form.canSubmit)
    #expect(form.takeSubmission() == nil)
    #expect(form.text.isEmpty)
  }

  @Test func submitTrimsOnlyExteriorAndClearsImmediately() {
    var form = RivetLoginTokenInput()
    form.text = "  fake input with spaces \n"
    form.showsToken = true
    #expect(form.canSubmit)
    #expect(form.takeSubmission() == "fake input with spaces")
    #expect(form.text.isEmpty)
    #expect(!form.showsToken)
    #expect(form.takeSubmission() == nil)
  }

  @Test func visibilityTogglePreservesTextAndClearResetsIt() {
    var form = RivetLoginTokenInput()
    form.text = "illustrative-input"
    form.showsToken.toggle()
    #expect(form.text == "illustrative-input")
    form.clear()
    #expect(form.text.isEmpty)
    #expect(!form.showsToken)
  }

  @Test func onlyTokenPhasesExposeForm() {
    #expect(RivetLoginPhase.tokenEntry.isTokenForm)
    #expect(RivetLoginPhase.failure(.init(message: "Try again", origin: .token)).isTokenForm)
    #expect(!RivetLoginPhase.failure(.init(message: "Try again", origin: .browser)).isTokenForm)
    #expect(!RivetLoginPhase.verifyingToken.isTokenForm)
  }
}
