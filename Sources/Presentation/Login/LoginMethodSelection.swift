import SwiftUI

struct LoginMethodSelection: View {
  let styles: LoginStyles
  let onGitHub: () -> Void
  let onToken: () -> Void
  @FocusState private var primaryFocused: Bool
  @AccessibilityFocusState private var actionFocused: Bool
  @State private var active = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      styles.eyebrow("WELCOME TO RIVET").padding(.bottom, 12)
      styles.heading("Review code,\nnot clutter.")
      styles.description(
        "Connect your GitHub account to explore pull requests, read diffs, and stay focused on changes."
      )
      .padding(.top, 14)
      styles.primaryButton("Continue with GitHub", github: true, action: onGitHub)
        .focused($primaryFocused).accessibilityFocused($actionFocused).padding(.top, 30)
      styles.textButton("Use a personal access token →", action: onToken)
        .frame(maxWidth: .infinity).padding(.top, 16)
    }
    .onAppear { active = true }
    .task {
      await Task.yield()
      guard !Task.isCancelled, active else { return }
      primaryFocused = true
      await Task.yield()
      guard !Task.isCancelled, active else { return }
      actionFocused = true
    }
    .onDisappear {
      active = false
      primaryFocused = false
      actionFocused = false
    }
  }
}
