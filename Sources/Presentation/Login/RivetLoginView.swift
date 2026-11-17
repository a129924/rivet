import SwiftUI

/// A parent-driven login surface. Authentication and session ownership stay outside Presentation.
public struct RivetLoginView: View {
  public let phase: RivetLoginPhase
  private let footer: String
  private let typography: RivetLoginTypography
  private let content: RivetLoginContent
  private let canCreateToken: Bool
  private let onIntent: (RivetLoginIntent) -> Void
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var contrast

  public init(
    phase: RivetLoginPhase, footer: String, bodyPointSize: CGFloat = 13,
    content: RivetLoginContent = .standard, canCreateToken: Bool = false,
    onIntent: @escaping (RivetLoginIntent) -> Void
  ) {
    self.phase = phase
    self.footer = footer
    self.typography = RivetLoginTypography(bodyPointSize: bodyPointSize)
    self.content = content
    self.canCreateToken = canCreateToken
    self.onIntent = onIntent
  }

  private var styles: LoginStyles {
    LoginStyles(
      palette: RivetLoginPalette(dark: scheme == .dark), contrast: contrast, typography: typography)
  }

  public var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        RivetLoginBrand().frame(width: geometry.size.width * 0.4)
        ScrollView(.vertical) {
          VStack(alignment: .leading, spacing: 0) {
            styles.eyebrow("GITHUB CONNECTION")
            section
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .padding(.vertical, phase.isTokenForm ? 18 : 28)
            footerView
          }
          .frame(minHeight: max(0, geometry.size.height - 85), alignment: .topLeading)
          .padding(.horizontal, 47).padding(.top, 58).padding(.bottom, 27)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(styles.palette.background).foregroundStyle(styles.palette.primary)
        .font(.system(size: typography.bodyPointSize))
      }
    }
  }

  @ViewBuilder private var section: some View {
    if phase.isTokenForm {
      LoginPATForm(
        failure: tokenFailure, content: content, canCreateToken: canCreateToken, styles: styles,
        onBack: { onIntent(.backToWelcome) }, onSubmit: { onIntent(.submitToken($0)) },
        onCreateToken: { onIntent(.createPersonalAccessToken) }
      )
    } else {
      switch phase {
      case .welcome:
        LoginMethodSelection(
          styles: styles, onGitHub: { onIntent(.beginGitHubSignIn) },
          onToken: { onIntent(.showTokenEntry) }
        )
      case .waitingForBrowser:
        oauthSection(.waiting)
      case .failure(let failure):
        oauthSection(.failure(failure))
      case .verifyingAccount:
        LoginStatusNotice(content: content.verifyingAccount, completed: false, styles: styles)
      case .verifyingToken:
        LoginStatusNotice(content: content.verifyingToken, completed: false, styles: styles)
      case .connected:
        LoginStatusNotice(content: content.connected, completed: true, styles: styles)
      case .tokenEntry: EmptyView()
      }
    }
  }

  private var tokenFailure: RivetLoginFailure? {
    if case .failure(let failure) = phase { failure } else { nil }
  }

  private func oauthSection(_ mode: LoginOAuthSection.Mode) -> some View {
    LoginOAuthSection(
      mode: mode, content: content, styles: styles,
      onCancel: { onIntent(.cancelSignIn) }, onRetry: { onIntent(.retry) },
      onToken: { onIntent(.showTokenEntry) }
    )
  }

  private var footerView: some View {
    VStack(alignment: .leading, spacing: 20) {
      Rectangle().fill(contrast == .increased ? styles.palette.secondary : styles.palette.border)
        .frame(height: 1)
      Label(footer, systemImage: "lock")
        .font(.system(size: 10.5 * typography.scale)).foregroundStyle(styles.palette.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
