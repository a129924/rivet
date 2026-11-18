import SwiftUI

struct LoginOAuthSection: View {
  enum Mode: Equatable {
    case waiting
    case failure(RivetLoginFailure)
  }
  let mode: Mode
  let content: RivetLoginContent
  let styles: LoginStyles
  let onCancel: () -> Void
  let onRetry: () -> Void
  let onToken: () -> Void
  @FocusState private var actionFocused: Bool
  @AccessibilityFocusState private var accessibleActionFocused: Bool
  @State private var activeMode: Mode?

  var body: some View {
    Group {
      switch mode {
      case .waiting: waiting
      case .failure(let failure): failureNotice(failure)
      }
    }
    .onChange(of: mode, initial: true) { _, value in
      activeMode = value
      actionFocused = false
      accessibleActionFocused = false
    }
    .task(id: mode) { await enter(mode) }
    .onDisappear {
      activeMode = nil
      actionFocused = false
      accessibleActionFocused = false
    }
  }

  private var waiting: some View {
    VStack(alignment: .leading, spacing: 16) {
      styles.statusIcon { ProgressView().controlSize(.regular) }
      styles.heading("Finish signing in\non GitHub")
      styles.description(content.waitingDescription)
      VStack(alignment: .leading, spacing: 5) {
        Text(content.waitingStatus)
        Text(content.waitingNote).fontWeight(.semibold)
      }
      .font(.system(size: 12 * styles.scale)).foregroundStyle(styles.palette.secondary)
      .frame(maxWidth: .infinity, alignment: .leading).padding(10)
      .background(styles.palette.surface, in: RoundedRectangle(cornerRadius: 9))
      styles.textButton("Cancel sign in", action: onCancel)
        .accessibilityLabel(content.waitingCancelAccessibilityLabel)
        .focused($actionFocused).accessibilityFocused($accessibleActionFocused)
        .frame(maxWidth: .infinity).keyboardShortcut(.cancelAction)
    }
  }

  private func failureNotice(_ failure: RivetLoginFailure) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      styles.statusIcon {
        Image(systemName: "exclamationmark.circle").font(.system(size: 24)).foregroundStyle(.red)
      }
      styles.heading("Couldn't connect\nto GitHub.")
      styles.description(failure.message)
      styles.primaryButton("Try again", action: onRetry)
        .focused($actionFocused).accessibilityFocused($accessibleActionFocused)
      styles.textButton("Use a personal access token →", action: onToken).frame(maxWidth: .infinity)
    }
  }

  private func enter(_ entry: Mode) async {
    await Task.yield()
    guard !Task.isCancelled, activeMode == entry else { return }
    actionFocused = true
    await Task.yield()
    guard !Task.isCancelled, activeMode == entry else { return }
    accessibleActionFocused = true
    await Task.yield()
    guard !Task.isCancelled, activeMode == entry else { return }
    if case .failure(let failure) = entry { LoginStyles.announce(failure.message) }
  }
}
