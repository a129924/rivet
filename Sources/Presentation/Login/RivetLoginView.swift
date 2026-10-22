import AppKit
import SwiftUI

public struct RivetLoginView: View {
  public let phase: RivetLoginPhase
  private let footer: String
  private let onIntent: (RivetLoginIntent) -> Void
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var contrast
  @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 13
  @State private var token = RivetLoginTokenInput()
  @FocusState private var focus: Focus?
  @AccessibilityFocusState private var statusFocused: Bool
  private enum Focus: Hashable { case primary, token, cancel, retry }

  public init(
    phase: RivetLoginPhase, footer: String, onIntent: @escaping (RivetLoginIntent) -> Void
  ) {
    self.phase = phase
    self.footer = footer
    self.onIntent = onIntent
  }

  private var palette: RivetLoginPalette { RivetLoginPalette(dark: scheme == .dark) }
  private var scale: CGFloat { bodySize / 13 }

  public var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        RivetLoginBrand().frame(width: geometry.size.width * 0.4)
        ScrollView(.vertical) {
          VStack(alignment: .leading, spacing: 0) {
            eyebrow("GITHUB CONNECTION")
            content
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .padding(.vertical, phase.isTokenForm ? 18 : 28)
            footerView
          }
          .frame(minHeight: max(0, geometry.size.height - 85), alignment: .topLeading)
          .padding(.horizontal, 47)
          .padding(.top, 58)
          .padding(.bottom, 27)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .foregroundStyle(palette.primary)
        .font(.system(size: bodySize))
      }
    }
    .onAppear { moveFocus() }
    .onChange(of: phase) { oldPhase, newPhase in
      if oldPhase.isTokenForm && !newPhase.isTokenForm { token.clear() }
      moveFocus()
      announceStatus()
    }
    .onDisappear { token.clear() }
  }

  @ViewBuilder private var content: some View {
    if phase.isTokenForm {
      tokenForm
    } else {
      switch phase {
      case .welcome: welcome
      case .waitingForBrowser: waiting
      case .verifyingAccount: progress(title: "Simulating account\nverification…")
      case .verifyingToken: progress(title: "Simulating token\nverification…")
      case .failure(let failure): browserFailure(failure)
      case .connected: connected
      case .tokenEntry: EmptyView()
      }
    }
  }

  private var welcome: some View {
    VStack(alignment: .leading, spacing: 0) {
      eyebrow("WELCOME TO RIVET").padding(.bottom, 12)
      heading("Review code,\nnot clutter.")
      description(
        "Connect your GitHub account to explore pull requests, read diffs, and stay focused on changes."
      )
      .padding(.top, 14)
      primaryButton("Continue with GitHub", intent: .beginGitHubSignIn, github: true)
        .focused($focus, equals: .primary)
        .padding(.top, 30)
      textButton("Use a personal access token →", intent: .showTokenEntry)
        .frame(maxWidth: .infinity).padding(.top, 16)
    }
  }

  private var tokenForm: some View {
    VStack(alignment: .leading, spacing: 0) {
      textButton("← Back to GitHub sign in", intent: .backToWelcome)
        .padding(.bottom, 12)
      eyebrow("ALTERNATIVE SIGN IN").padding(.bottom, 10)
      heading("Connect with\nan access token.", size: 24)
      description("Use a fine-grained personal access token for GitHub.com.").padding(.top, 10)
      Text("Personal access token").font(.system(size: 12 * scale, weight: .semibold))
        .padding(.top, 16).padding(.bottom, 8)
      tokenField
      if case .failure(let failure) = phase {
        Label(failure.message, systemImage: "exclamationmark.circle")
          .font(.system(size: 11 * scale)).foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
      }
      Text("Recommended: grant only the repository access Rivet needs.")
        .font(.system(size: 11 * scale)).foregroundStyle(palette.secondary)
        .fixedSize(horizontal: false, vertical: true).padding(.top, 9)
      Button("Create a fine-grained token ↗") {}.buttonStyle(.link)
        .font(.system(size: 12 * scale, weight: .semibold))
        .disabled(true)
        .help("Unavailable in this UI demonstration. No browser will open.")
        .accessibilityHint("Unavailable in this UI demonstration. No browser will open.")
        .padding(.top, 10)
      Button(action: submitToken) {
        Text("Connect to GitHub").font(.system(size: 13 * scale, weight: .semibold))
          .frame(maxWidth: .infinity, minHeight: 42)
      }
      .buttonStyle(LoginPrimaryButtonStyle(palette: palette, contrast: contrast))
      .disabled(!token.canSubmit).keyboardShortcut(.defaultAction)
      .padding(.top, 14)
    }
  }

  private var tokenField: some View {
    HStack(spacing: 8) {
      Group {
        if token.showsToken {
          TextField("github_pat_…", text: $token.text)
        } else {
          SecureField("github_pat_…", text: $token.text)
        }
      }
      .textFieldStyle(.plain).font(.system(size: 12 * scale, design: .monospaced))
      .focused($focus, equals: .token)
      .accessibilityLabel("Personal access token — example input only")
      .onSubmit(submitToken)
      Button(token.showsToken ? "Hide" : "Show") {
        token.showsToken.toggle()
        focus = .token
      }
      .buttonStyle(.plain).foregroundStyle(palette.secondary)
      .accessibilityLabel(token.showsToken ? "Hide token" : "Show token")
    }
    .padding(.horizontal, 13).frame(minHeight: 40)
    .background(palette.field, in: RoundedRectangle(cornerRadius: 9))
    .overlay {
      RoundedRectangle(cornerRadius: 9)
        .stroke(
          focus == .token ? Color.accentColor : palette.border,
          lineWidth: focus == .token || contrast == .increased ? 2 : 1)
    }
  }

  private var waiting: some View {
    VStack(alignment: .leading, spacing: 16) {
      statusIcon { ProgressView().controlSize(.regular) }
      heading("Finish signing in\non GitHub")
      description(
        "This is a simulated browser handoff. Use the separate Demo Controls window to return.")
      VStack(alignment: .leading, spacing: 5) {
        Text("Waiting for simulated authorization…")
        Text("This demonstration cannot connect to GitHub.").fontWeight(.semibold)
      }
      .font(.system(size: 12 * scale)).foregroundStyle(palette.secondary)
      .frame(maxWidth: .infinity, alignment: .leading).padding(10)
      .background(palette.surface, in: RoundedRectangle(cornerRadius: 9))
      textButton("Cancel sign in", intent: .cancelSignIn)
        .focused($focus, equals: .cancel).frame(maxWidth: .infinity)
        .keyboardShortcut(.cancelAction)
    }
  }

  private func progress(title: String) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      statusIcon { ProgressView().controlSize(.regular) }
      heading(title)
      description(
        "UI demonstration only. No request is sent and no credential is stored. Complete the simulation in Demo Controls."
      )
    }
  }

  private func browserFailure(_ failure: RivetLoginFailure) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      statusIcon {
        Image(systemName: "exclamationmark.circle").font(.system(size: 24)).foregroundStyle(.red)
      }
      heading("Couldn't connect\nto GitHub.")
      description(failure.message)
      primaryButton("Try again", intent: .retry).focused($focus, equals: .retry)
      textButton("Use a personal access token →", intent: .showTokenEntry).frame(
        maxWidth: .infinity)
    }
  }

  private var connected: some View {
    VStack(alignment: .leading, spacing: 16) {
      statusIcon {
        Image(systemName: "checkmark.circle").font(.system(size: 24)).foregroundStyle(.green)
      }
      heading("You're connected.\nIn this simulation.")
      description(
        "The UI demonstration is complete. No GitHub account was connected. Use Demo Controls to reset or inspect another state."
      )
    }
  }

  private var footerView: some View {
    VStack(alignment: .leading, spacing: 20) {
      Rectangle().fill(contrast == .increased ? palette.secondary : palette.border).frame(height: 1)
      Label(footer, systemImage: "lock")
        .font(.system(size: 10.5 * scale)).foregroundStyle(palette.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func heading(_ text: String, size: CGFloat = 26) -> some View {
    Text(text).font(.system(size: size * scale, weight: .bold)).tracking(-0.65)
      .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
      .accessibilityFocused($statusFocused)
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 10 * scale, weight: .bold)).tracking(1.2).foregroundStyle(
      palette.secondary)
  }

  private func description(_ text: String) -> some View {
    Text(text).font(.system(size: bodySize)).lineSpacing(3).foregroundStyle(palette.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  private func statusIcon<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    content().frame(width: 44, height: 44).background(
      palette.surface, in: RoundedRectangle(cornerRadius: 13)
    )
    .accessibilityHidden(true)
  }

  private func primaryButton(
    _ title: String, intent: RivetLoginIntent, github: Bool = false
  ) -> some View {
    Button {
      onIntent(intent)
    } label: {
      HStack(spacing: 9) {
        if github {
          Image(nsImage: githubMark).renderingMode(.template).resizable().frame(
            width: 18, height: 18
          )
          .accessibilityHidden(true)
        }
        Text(title).font(.system(size: 13 * scale, weight: .semibold))
      }
      .frame(maxWidth: .infinity, minHeight: 42)
    }
    .buttonStyle(LoginPrimaryButtonStyle(palette: palette, contrast: contrast))
    .keyboardShortcut(.defaultAction)
  }

  private var githubMark: NSImage {
    guard let url = Bundle.module.url(forResource: "GitHubMark", withExtension: "pdf"),
      let image = NSImage(contentsOf: url)
    else { return NSImage(size: NSSize(width: 18, height: 18)) }
    image.isTemplate = true
    return image
  }

  private func textButton(_ title: String, intent: RivetLoginIntent) -> some View {
    Button {
      token.clear()
      onIntent(intent)
    } label: {
      Text(title).underline().font(.system(size: 12 * scale))
    }
    .buttonStyle(.link).foregroundStyle(palette.secondary)
  }

  private func submitToken() {
    guard let value = token.takeSubmission() else { return }
    onIntent(.submitToken(value))
  }

  private func moveFocus() {
    switch phase {
    case .welcome: focus = .primary
    case .tokenEntry: focus = .token
    case .waitingForBrowser: focus = .cancel
    case .failure(let failure): focus = failure.origin == .token ? .token : .retry
    default:
      focus = nil
      statusFocused = true
    }
  }

  private func announceStatus() {
    let message: String
    switch phase {
    case .waitingForBrowser: message = "Waiting for simulated authorization."
    case .verifyingAccount, .verifyingToken: message = "Simulated verification in progress."
    case .failure(let failure): message = failure.message
    case .connected: message = "Simulation complete. No account was connected."
    default: return
    }
    NSAccessibility.post(
      element: NSApp as Any, notification: .announcementRequested,
      userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium.rawValue]
    )
  }
}

private struct LoginPrimaryButtonStyle: ButtonStyle {
  let palette: RivetLoginPalette
  let contrast: ColorSchemeContrast
  @Environment(\.isEnabled) private var enabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(palette.buttonLabel)
      .background(
        palette.button.opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.5),
        in: RoundedRectangle(cornerRadius: 10)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(
          palette.secondary.opacity(contrast == .increased ? 1 : 0), lineWidth: 1)
      )
      .contentShape(RoundedRectangle(cornerRadius: 10))
  }
}
