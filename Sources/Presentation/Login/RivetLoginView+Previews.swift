#if DEBUG
  import SwiftUI

  private struct LoginPreview: View {
    var phase: RivetLoginPhase = .welcome
    var body: some View {
      RivetLoginView(
        phase: phase,
        footer: "UI demonstration · No requests or credential storage.",
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
  #Preview("Large text") { LoginPreview(phase: .tokenEntry).dynamicTypeSize(.accessibility3) }
#endif
