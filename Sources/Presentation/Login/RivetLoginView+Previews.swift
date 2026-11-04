#if DEBUG
  import SwiftUI

  private struct LoginPreview: View {
    var phase: RivetLoginPhase = .welcome
    var bodyPointSize: CGFloat = 13
    var body: some View {
      RivetLoginView(
        phase: phase,
        footer: "UI demonstration · No requests or credential storage.",
        bodyPointSize: bodyPointSize,
        onIntent: ignoreIntent
      )
      .frame(width: 780, height: 500)
    }

    private func ignoreIntent(_ intent: RivetLoginIntent) {}
  }

  #Preview("Welcome · Light") { LoginPreview().preferredColorScheme(.light) }
  #Preview("Welcome · Dark") { LoginPreview().preferredColorScheme(.dark) }
  #Preview("PAT · Dark") { LoginPreview(phase: .tokenEntry).preferredColorScheme(.dark) }
  #Preview("Waiting") { LoginPreview(phase: .waitingForBrowser) }
  #Preview("Token failure") {
    LoginPreview(
      phase: .failure(.init(message: "Simulated failure. Please try again.", origin: .token)))
  }
  #Preview("Increased contrast") { LoginPreview().environment(\._colorSchemeContrast, .increased) }
  #Preview("PAT · 21 pt") { LoginPreview(phase: .tokenEntry, bodyPointSize: 21) }
#endif
