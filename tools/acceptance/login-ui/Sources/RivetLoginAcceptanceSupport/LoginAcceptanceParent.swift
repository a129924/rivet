import Foundation
import Observation
import RivetPresentation

@MainActor @Observable
final class LoginAcceptanceParent {
  enum ContentSelection: String, CaseIterable { case standard, controlled }
  enum EventKind: String {
    case beginGitHubSignIn, showTokenEntry, backToWelcome, cancelSignIn
    case submitToken, retry, createPersonalAccessToken
  }

  private(set) var phase: RivetLoginPhase
  private(set) var bodyPointSize: CGFloat
  private(set) var contentSelection = ContentSelection.standard
  private(set) var canCreateToken = false
  private(set) var formGeneration = UUID()
  private(set) var lastEventKind: EventKind?
  private(set) var eventCount = 0

  var content: RivetLoginContent {
    contentSelection == .standard ? .standard : LoginAcceptanceFixtures.controlledContent
  }

  init(configuration: LoginAcceptanceConfiguration) {
    phase = LoginAcceptanceFixtures.phase(for: configuration.scene)
    bodyPointSize = configuration.bodyPointSize
  }

  func selectScene(_ scene: LoginAcceptanceConfiguration.Scene) {
    phase = LoginAcceptanceFixtures.phase(for: scene)
  }

  func setBodyPointSize(_ value: CGFloat) {
    guard value.isFinite, (13...21).contains(value) else { return }
    bodyPointSize = value
  }

  func selectContent(_ selection: ContentSelection) { contentSelection = selection }
  func setCanCreateToken(_ enabled: Bool) { canCreateToken = enabled }

  func reset() {
    formGeneration = UUID()
    lastEventKind = nil
    eventCount = 0
  }

  func handle(_ intent: RivetLoginIntent) {
    let kind: EventKind
    switch (phase, intent) {
    case (.welcome, .beginGitHubSignIn):
      phase = .waitingForBrowser
      kind = .beginGitHubSignIn
    case (.welcome, .showTokenEntry):
      phase = .tokenEntry
      kind = .showTokenEntry
    case (.failure(let failure), .showTokenEntry) where failure.origin == .browser:
      phase = .tokenEntry
      kind = .showTokenEntry
    case (.failure(let failure), .retry) where failure.origin == .browser:
      phase = .waitingForBrowser
      kind = .retry
    case (.waitingForBrowser, .cancelSignIn):
      phase = .welcome
      kind = .cancelSignIn
    case (_, .backToWelcome) where phase.isTokenForm:
      phase = .welcome
      kind = .backToWelcome
    case (_, .submitToken) where phase.isTokenForm:
      // Do not bind, inspect, copy, log, hash, or retain the associated string.
      phase = .verifyingToken
      kind = .submitToken
    case (_, .createPersonalAccessToken) where phase.isTokenForm && canCreateToken:
      kind = .createPersonalAccessToken
    default: return
    }
    lastEventKind = kind
    eventCount += 1
  }
}
