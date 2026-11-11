import Foundation
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

@Suite("Login typography")
struct RivetLoginTypographyTests {
  @Test(arguments: [CGFloat(13), 15, 17, 17.5, 21])
  func supportedSizesUseTheRequestedPointSize(_ size: CGFloat) {
    let typography = RivetLoginTypography(bodyPointSize: size)
    #expect(typography.bodyPointSize == size)
    #expect(typography.scale == size / 13)
  }

  @Test func finiteSizesClampAtTheSupportedBounds() {
    #expect(RivetLoginTypography(bodyPointSize: -100).bodyPointSize == 13)
    #expect(RivetLoginTypography(bodyPointSize: 12.999).bodyPointSize == 13)
    #expect(RivetLoginTypography(bodyPointSize: 21.001).bodyPointSize == 21)
    #expect(RivetLoginTypography(bodyPointSize: .greatestFiniteMagnitude).bodyPointSize == 21)
  }

  @Test(arguments: [CGFloat.nan, .infinity, -.infinity])
  func nonfiniteSizesUseTheDefault(_ size: CGFloat) {
    let typography = RivetLoginTypography(bodyPointSize: size)
    #expect(typography.bodyPointSize == 13)
    #expect(typography.scale == 1)
  }
}
