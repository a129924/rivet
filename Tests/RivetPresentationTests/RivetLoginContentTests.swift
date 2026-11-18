import RivetPresentation
import SwiftUI
import Testing

@Suite("Login product content") @MainActor
struct RivetLoginContentTests {
  @Test func standardContentDescribesAnAttemptWithoutDemoOrSessionClaims() {
    let content = RivetLoginContent.standard
    let allText = [
      content.waitingDescription, content.waitingStatus, content.waitingNote,
      content.waitingCancelAccessibilityLabel, content.verifyingAccount.title,
      content.verifyingAccount.message, content.verifyingAccount.announcement,
      content.verifyingToken.title, content.verifyingToken.message,
      content.verifyingToken.announcement, content.connected.title,
      content.connected.message, content.connected.announcement,
      content.tokenFieldAccessibilityLabel, content.createTokenUnavailableMessage,
    ].joined(separator: " ").lowercased()
    for term in ["simulat", "demo controls", "example input only", "session", "stored"] {
      #expect(!allText.contains(term))
    }
    #expect(content.connected.title == "Sign-in completed.")
    #expect(content.connected.message == "This sign-in attempt completed successfully.")
  }

  @Test func consumersCanSupplyContentAndKeepBothInitializerShapes() {
    let status = RivetLoginStatusContent(
      title: "Checking", message: "Please wait", announcement: "Checking.")
    let content = RivetLoginContent(
      waitingDescription: "Continue in the browser", waitingStatus: "Waiting",
      waitingNote: "Return here",
      waitingCancelAccessibilityLabel: "Waiting. Cancel.", verifyingAccount: status,
      verifyingToken: status, connected: status, tokenFieldAccessibilityLabel: "Token",
      createTokenUnavailableMessage: "Unavailable"
    )
    #expect(content.verifyingAccount == status)
    let _: RivetLoginView = RivetLoginView(phase: .welcome, footer: "Footer") { _ in }
    let _: RivetLoginView = RivetLoginView(
      phase: .tokenEntry, footer: "Footer", bodyPointSize: 17,
      content: content, canCreateToken: true
    ) { _ in }
    #expect(RivetLoginIntent.createPersonalAccessToken != .showTokenEntry)
  }
}
