#if DEBUG
  import SwiftUI

  private struct LoginPreview: View {
    @State private var phase: RivetLoginPhase
    @State private var bodyPointSize: CGFloat
    @State private var usesControlledContent = false
    @State private var canCreateToken = false
    @State private var formGeneration = UUID()
    @State private var lastEventKind = "None"
    @State private var eventCount = 0

    init(phase: RivetLoginPhase = .welcome, bodyPointSize: CGFloat = 13) {
      self._phase = State(initialValue: phase)
      self._bodyPointSize = State(initialValue: bodyPointSize)
    }

    var body: some View {
      VStack(spacing: 0) {
        GroupBox("Controlled Preview · outside the login component") {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Picker(
                "Phase",
                selection: Binding(
                  get: { PreviewPhase(phase) }, set: { phase = $0.phase }
                )
              ) {
                ForEach(PreviewPhase.allCases, id: \.self) { Text($0.rawValue).tag($0) }
              }
              Picker("Text size", selection: $bodyPointSize) {
                ForEach([CGFloat(13), 17, 21], id: \.self) { Text("\(Int($0)) pt").tag($0) }
              }
              .pickerStyle(.segmented)
            }
            HStack {
              Toggle("Controlled copy", isOn: $usesControlledContent)
              Toggle("Enable token creation", isOn: $canCreateToken)
              Button("Reset") {
                formGeneration = UUID()
                lastEventKind = "None"
                eventCount = 0
              }
              Text("Last event: \(lastEventKind) · Count: \(eventCount)").font(.caption)
            }
          }
        }
        .padding(8)
        Divider()
        RivetLoginView(
          phase: phase,
          footer: "Connect your GitHub account to Rivet.",
          bodyPointSize: bodyPointSize,
          content: usesControlledContent ? Self.controlledContent : .standard,
          canCreateToken: canCreateToken,
          onIntent: handle
        )
        .id(formGeneration)
        .frame(width: 780, height: 500)
      }
      .frame(width: 780)
    }

    private func handle(_ intent: RivetLoginIntent) {
      let kind: String
      switch (phase, intent) {
      case (.welcome, .beginGitHubSignIn):
        phase = .waitingForBrowser
        kind = "beginGitHubSignIn"
      case (.welcome, .showTokenEntry):
        phase = .tokenEntry
        kind = "showTokenEntry"
      case (.failure(let failure), .showTokenEntry) where failure.origin == .browser:
        phase = .tokenEntry
        kind = "showTokenEntry"
      case (.failure(let failure), .retry) where failure.origin == .browser:
        phase = .waitingForBrowser
        kind = "retry"
      case (.waitingForBrowser, .cancelSignIn):
        phase = .welcome
        kind = "cancelSignIn"
      case (_, .backToWelcome) where phase.isTokenForm:
        phase = .welcome
        kind = "backToWelcome"
      case (_, .submitToken) where phase.isTokenForm:
        // Deliberately ignore the associated string; only a finite event kind is retained.
        phase = .verifyingToken
        kind = "submitToken"
      case (_, .createPersonalAccessToken) where phase.isTokenForm && canCreateToken:
        kind = "createPersonalAccessToken"
      default: return
      }
      lastEventKind = kind
      eventCount += 1
    }

    private static let controlledContent = RivetLoginContent(
      waitingDescription: "Controlled browser-step description.",
      waitingStatus: "Controlled waiting.",
      waitingNote: "Selected preview copy.",
      waitingCancelAccessibilityLabel: "Controlled waiting. Cancel sign in.",
      verifyingAccount: .init(
        title: "Controlled account check", message: "Selected preview copy.",
        announcement: "Controlled account check."),
      verifyingToken: .init(
        title: "Controlled token check", message: "Selected preview copy.",
        announcement: "Controlled token check."),
      connected: .init(
        title: "Controlled completion", message: "Selected preview copy.",
        announcement: "Controlled completion."),
      tokenFieldAccessibilityLabel: "Controlled token field",
      createTokenUnavailableMessage: "Creation is disabled in this selected configuration."
    )
  }

  private enum PreviewPhase: String, CaseIterable {
    case welcome = "Welcome"
    case pat = "PAT"
    case waiting = "Waiting"
    case account = "Account check"
    case token = "Token check"
    case browserFailure = "Browser failure"
    case tokenFailure = "Token failure"
    case completed = "Completed"

    init(_ phase: RivetLoginPhase) {
      switch phase {
      case .welcome: self = .welcome
      case .tokenEntry: self = .pat
      case .waitingForBrowser: self = .waiting
      case .verifyingAccount: self = .account
      case .verifyingToken: self = .token
      case .connected: self = .completed
      case .failure(let failure): self = failure.origin == .token ? .tokenFailure : .browserFailure
      }
    }

    var phase: RivetLoginPhase {
      switch self {
      case .welcome: .welcome
      case .pat: .tokenEntry
      case .waiting: .waitingForBrowser
      case .account: .verifyingAccount
      case .token: .verifyingToken
      case .completed: .connected
      case .browserFailure:
        .failure(
          .init(message: "Sign-in couldn't be completed. Please try again.", origin: .browser))
      case .tokenFailure:
        .failure(
          .init(message: "The token couldn't be verified. Check it and try again.", origin: .token))
      }
    }
  }

  #Preview("Welcome · Light") { LoginPreview().preferredColorScheme(.light) }
  #Preview("Welcome · Dark") { LoginPreview().preferredColorScheme(.dark) }
  #Preview("PAT · Dark") { LoginPreview(phase: .tokenEntry).preferredColorScheme(.dark) }
  #Preview("Waiting") { LoginPreview(phase: .waitingForBrowser) }
  #Preview("Token failure") { LoginPreview(phase: PreviewPhase.tokenFailure.phase) }
  #Preview("Increased contrast") { LoginPreview().environment(\._colorSchemeContrast, .increased) }
  #Preview("PAT · 21 pt") { LoginPreview(phase: .tokenEntry, bodyPointSize: 21) }
#endif
