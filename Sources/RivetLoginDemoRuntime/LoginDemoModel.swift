import Foundation
import Observation
import RivetPresentation

@MainActor @Observable
public final class LoginDemoModel {
  public static let failureMessage = "This simulated attempt failed. Try again with example input."
  public private(set) var phase: RivetLoginPhase = .welcome
  public private(set) var formIdentity = UUID()
  public var shouldFail = false

  public init() {}

  public func handle(_ intent: RivetLoginIntent) {
    switch (phase, intent) {
    case (.welcome, .beginGitHubSignIn):
      phase = .waitingForBrowser
    case (.welcome, .showTokenEntry):
      phase = .tokenEntry
    case (.failure(let failure), .showTokenEntry) where failure.origin == .browser:
      phase = .tokenEntry
    case (.failure(let failure), .retry) where failure.origin == .browser:
      phase = .waitingForBrowser
    case (.waitingForBrowser, .cancelSignIn):
      phase = .welcome
    case (_, .backToWelcome) where phase.isTokenForm:
      resetForm()
      phase = .welcome
    case (_, .submitToken(let value)) where phase.isTokenForm:
      guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
      phase = .verifyingToken
    default:
      break
    }
  }

  public func simulateReturn() {
    guard phase == .waitingForBrowser else { return }
    phase = .verifyingAccount
  }

  public func completeSimulation() {
    let origin: RivetLoginFailure.Origin
    switch phase {
    case .verifyingAccount: origin = .browser
    case .verifyingToken: origin = .token
    default: return
    }
    phase = shouldFail ? .failure(.init(message: Self.failureMessage, origin: origin)) : .connected
  }

  public func show(_ phase: RivetLoginPhase) {
    resetForm()
    self.phase = phase
  }

  public func reset() {
    resetForm()
    shouldFail = false
    phase = .welcome
  }

  private func resetForm() { formIdentity = UUID() }
}
