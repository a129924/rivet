import SwiftUI

struct LoginPATForm: View {
  let failure: RivetLoginFailure?
  let content: RivetLoginContent
  let canCreateToken: Bool
  let styles: LoginStyles
  let onBack: () -> Void
  let onSubmit: (String) -> Void
  let onCreateToken: () -> Void
  @State private var token = RivetLoginTokenInput()
  @State private var active = false
  @State private var activeFailure: RivetLoginFailure?
  @FocusState private var focus: Field?
  @AccessibilityFocusState private var inputFocused: Bool

  private enum Field { case secure, visible }
  private var tokenFocus: Field { token.showsToken ? .visible : .secure }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      styles.textButton("← Back to GitHub sign in") {
        token.clear()
        onBack()
      }.padding(.bottom, 12)
      styles.eyebrow("ALTERNATIVE SIGN IN").padding(.bottom, 10)
      styles.heading("Connect with\nan access token.", size: 24)
      styles.description("Use a fine-grained personal access token for GitHub.com.").padding(
        .top, 10)
      Text("Personal access token").font(.system(size: 12 * styles.scale, weight: .semibold))
        .padding(.top, 16).padding(.bottom, 8)
      tokenField
      if let failure {
        Label(failure.message, systemImage: "exclamationmark.circle")
          .font(.system(size: 11 * styles.scale)).foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
      }
      Text("Recommended: grant only the repository access Rivet needs.")
        .font(.system(size: 11 * styles.scale)).foregroundStyle(styles.palette.secondary)
        .fixedSize(horizontal: false, vertical: true).padding(.top, 9)
      Button("Create a fine-grained token ↗") {
        guard canCreateToken else { return }
        onCreateToken()
      }
      .buttonStyle(.link).font(.system(size: 12 * styles.scale, weight: .semibold))
      .disabled(!canCreateToken)
      .help(
        canCreateToken ? "Create a personal access token" : content.createTokenUnavailableMessage
      )
      .accessibilityHint(
        canCreateToken ? "Create a personal access token" : content.createTokenUnavailableMessage
      )
      .padding(.top, 10)
      styles.primaryButton("Connect to GitHub", action: submit)
        .disabled(!token.canSubmit).padding(.top, 14)
    }
    .onAppear { active = true }
    .onChange(of: failure, initial: true) { _, value in
      activeFailure = value
      focus = nil
      inputFocused = false
    }
    .task(id: failure) { await enter(failure) }
    .onDisappear {
      active = false
      focus = nil
      inputFocused = false
      token.clear()
    }
  }

  private var tokenField: some View {
    HStack(spacing: 8) {
      Group {
        if token.showsToken {
          TextField("github_pat_…", text: $token.text).focused($focus, equals: .visible)
        } else {
          SecureField("github_pat_…", text: $token.text).focused($focus, equals: .secure)
        }
      }
      .textFieldStyle(.plain).font(.system(size: 12 * styles.scale, design: .monospaced))
      .accessibilityLabel(content.tokenFieldAccessibilityLabel)
      .accessibilityFocused($inputFocused).onSubmit(submit)
      Button(token.showsToken ? "Hide" : "Show") {
        inputFocused = false
        token.showsToken.toggle()
      }
      .buttonStyle(.plain).foregroundStyle(styles.palette.secondary)
      .accessibilityLabel(token.showsToken ? "Hide token" : "Show token")
    }
    .padding(.horizontal, 13).frame(minHeight: 40)
    .background(styles.palette.field, in: RoundedRectangle(cornerRadius: 9))
    .overlay {
      RoundedRectangle(cornerRadius: 9).stroke(
        focus == tokenFocus ? Color.accentColor : styles.palette.border,
        lineWidth: focus == tokenFocus || styles.contrast == .increased ? 2 : 1
      )
    }
    .task(id: token.showsToken) {
      let entry = failure
      await Task.yield()
      guard !Task.isCancelled, active, activeFailure == entry else { return }
      focus = tokenFocus
      inputFocused = true
    }
  }

  private func submit() {
    guard let value = token.takeSubmission() else { return }
    onSubmit(value)
  }

  private func enter(_ entry: RivetLoginFailure?) async {
    await Task.yield()
    guard !Task.isCancelled, active, activeFailure == entry else { return }
    focus = tokenFocus
    await Task.yield()
    guard !Task.isCancelled, active, activeFailure == entry else { return }
    inputFocused = true
    await Task.yield()
    guard !Task.isCancelled, active, activeFailure == entry else { return }
    if let entry { LoginStyles.announce(entry.message) }
  }
}
