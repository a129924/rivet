// Rivet Login UI — visual reference implementation (macOS 13+, SwiftUI)
// Authentication, Keychain, and GitHub networking are intentionally NOT implemented.
// Supply an official GitHub mark named "GitHubMark" in Assets.xcassets.
// Copy the Window scene setup from Rivet-Login-Spec.md into your existing App.

import SwiftUI

public enum RivetLoginPhase: Equatable {
    case welcome
    case waitingForBrowser
    case verifyingAccount
    case tokenEntry
    case verifyingToken
    case failure(message: String)
    case connected
}

public struct RivetLoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding private var phase: RivetLoginPhase
    private let onGitHubSignIn: () -> Void
    private let onCancelSignIn: () -> Void
    private let onTokenSignIn: (String) -> Void
    private let onRetry: () -> Void

    @State private var personalAccessToken = ""
    @State private var showsToken = false

    public init(
        phase: Binding<RivetLoginPhase>,
        onGitHubSignIn: @escaping () -> Void,
        onCancelSignIn: @escaping () -> Void,
        onTokenSignIn: @escaping (String) -> Void,
        onRetry: @escaping () -> Void
    ) {
        self._phase = phase
        self.onGitHubSignIn = onGitHubSignIn
        self.onCancelSignIn = onCancelSignIn
        self.onTokenSignIn = onTokenSignIn
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(spacing: 0) {
            RivetBrandPanel()
                .frame(width: 312, height: 500)

            authPanel
                .frame(width: 468, height: 500)
        }
        .frame(width: 780, height: 500)
        .accessibilityElement(children: .contain)
        .onChange(of: phase) { nextPhase in
            if nextPhase != .tokenEntry {
                personalAccessToken = ""
                showsToken = false
            }
        }
    }

    private var palette: RivetAuthPalette {
        RivetAuthPalette(dark: colorScheme == .dark)
    }

    private var authPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("GITHUB CONNECTION")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(palette.secondary)
                .frame(height: 17, alignment: .topLeading)

            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)

            Rectangle()
                .fill(palette.border)
                .frame(height: 1)

            HStack(spacing: 8) {
                Image(systemName: "lock")
                    .font(.system(size: 12))
                Text(phase == .tokenEntry
                     ? "Token stored in macOS Keychain in the finished app"
                     : "Rivet never asks for your GitHub password")
                    .font(.system(size: 10.5))
                    .lineLimit(2)
            }
            .foregroundStyle(palette.secondary)
            .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)
        }
        .padding(.leading, 47)
        .padding(.trailing, 47)
        .padding(.top, 58)
        .padding(.bottom, 27)
        .background(palette.background)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .welcome:
            welcomeContent
        case .tokenEntry:
            tokenContent
        case .waitingForBrowser:
            waitingContent
        case .verifyingAccount:
            progressContent(title: "Connecting your\nGitHub account…",
                            subtitle: "Checking your GitHub identity and saving your local session securely.")
        case .verifyingToken:
            progressContent(title: "Checking your token…",
                            subtitle: "Verifying access with GitHub. This may take a moment.")
        case .failure(let message):
            failureContent(message: message)
        case .connected:
            connectedContent
        }
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("WELCOME TO RIVET")
            heading("Review code,\nnot clutter.")
            paragraph("Connect your GitHub account to explore pull requests, read diffs, and stay focused on changes.")

            VStack(spacing: 16) {
                primaryButton("Continue with GitHub", githubMark: true, action: onGitHubSignIn)
                secondaryButton("Use a personal access token →") {
                    phase = .tokenEntry
                }
            }
            .padding(.top, 30)
        }
    }

    private var tokenContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("← Back to GitHub sign in") {
                personalAccessToken = ""
                showsToken = false
                phase = .welcome
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(palette.secondary)
            .padding(.bottom, 14)

            eyebrow("ALTERNATIVE SIGN IN")
            heading("Connect with\nan access token.", size: 24)
            paragraph("Use a fine-grained personal access token for GitHub.com.")

            VStack(alignment: .leading, spacing: 8) {
                Text("Personal access token")
                    .font(.system(size: 12, weight: .semibold))

                HStack(spacing: 9) {
                    Group {
                        if showsToken {
                            TextField("github_pat_…", text: $personalAccessToken)
                        } else {
                            SecureField("github_pat_…", text: $personalAccessToken)
                        }
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(.plain)
                    .privacySensitive()
                    .onSubmit(submitToken)

                    Button(showsToken ? "Hide" : "Show") {
                        showsToken.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondary)
                    .accessibilityLabel(showsToken ? "Hide personal access token" : "Show personal access token")
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(palette.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(palette.border, lineWidth: 1)
                }

                Text("Recommended: grant only the repository access Rivet needs.")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 18)

            Link(destination: URL(string: "https://github.com/settings/personal-access-tokens/new")!) {
                Label("Create a fine-grained token", systemImage: "arrow.up.right")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.top, 12)

            primaryButton("Connect to GitHub", disabled: personalAccessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, action: submitToken)
                .padding(.top, 17)
        }
    }

    private var waitingContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusProgressIcon
                .padding(.bottom, 13)
            heading("Finish signing in\non GitHub")
            paragraph("Your browser is handling authorization. Rivet will continue automatically when you return.")

            Text("Waiting for GitHub authorization…")
                .font(.system(size: 12))
                .foregroundStyle(palette.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(palette.quiet)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .padding(.top, 18)

            secondaryButton("Cancel sign in", action: onCancelSignIn)
                .padding(.top, 23)
        }
    }

    private var connectedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28))
                .foregroundStyle(Color(hex: 0x40A77A))
                .padding(.bottom, 24)
            heading("You're connected.")
            paragraph("Your GitHub account is ready. Rivet will now open your pull requests.")
        }
    }

    private func failureContent(message: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 28))
                .foregroundStyle(Color(hex: 0xDA636A))
                .padding(.bottom, 24)
            heading("Couldn't connect\nto GitHub.")
            paragraph(message)

            VStack(spacing: 15) {
                primaryButton("Try again", action: onRetry)
                secondaryButton("Use a personal access token") {
                    phase = .tokenEntry
                }
            }
            .padding(.top, 28)
        }
    }

    private func progressContent(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            statusProgressIcon
                .padding(.bottom, 21)
            heading(title)
            paragraph(subtitle)
        }
    }

    private var statusProgressIcon: some View {
        ProgressView()
            .controlSize(.regular)
            .frame(width: 44, height: 44)
            .background(palette.quiet)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Waiting for GitHub")
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(palette.secondary)
            .padding(.bottom, 12)
    }

    private func heading(_ text: String, size: CGFloat = 26) -> some View {
        Text(text)
            .font(.system(size: size, weight: .bold))
            .tracking(-0.65)
            .foregroundStyle(palette.text)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 13)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(palette.secondary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func primaryButton(
        _ title: String,
        githubMark: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if githubMark {
                    Image("GitHubMark")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(palette.buttonText)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(palette.buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(disabled ? 0.55 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .underline()
                .foregroundStyle(palette.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func submitToken() {
        let trimmed = personalAccessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onTokenSignIn(trimmed)
        // The parent should clear the token field after handing it to the
        // authentication service. Do not log the value or use UserDefaults.
    }
}

private struct RivetBrandPanel: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: 0x19293C), Color(hex: 0x111E2E), Color(hex: 0x0E1725)]
                    : [Color(hex: 0x223A54), Color(hex: 0x17293F), Color(hex: 0x0F1C2F)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 11) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color(hex: 0xCBE7FF))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        }

                    Text("RIVET")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(1.3)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 40)
                RivetDiffPreview()
                    .rotationEffect(.degrees(-1.2))
                Spacer(minLength: 34)

                Text("Review the change.\nNot the noise.")
                    .font(.system(size: 23, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A focused workspace for\npull request reviews.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xB3C4D6))
                    .lineSpacing(3)
                    .padding(.top, 11)
            }
            .padding(.top, 66)
            .padding(.horizontal, 30)
            .padding(.bottom, 32)
        }
    }
}

private struct RivetDiffPreview: View {
    private let mono = Font.system(size: 10.5, weight: .regular, design: .monospaced)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ReviewDiff.swift")
                    .foregroundStyle(Color(hex: 0xB0C1D5))
                Spacer()
                Text("+2 −1")
                    .foregroundStyle(Color(hex: 0x77DBAF))
            }
            .font(.system(size: 10))
            .padding(.horizontal, 12)
            .frame(height: 36)

            Rectangle().fill(Color(hex: 0x48637B).opacity(0.5)).frame(height: 1)

            VStack(alignment: .leading, spacing: 4) {
                line("@@ -42,4 +42,5 @@", color: Color(hex: 0xA6B3ED))
                line("42  func loadDiff() async {")
                line("43  - let diff = raw", color: Color(hex: 0xF4B2B6), bg: Color(hex: 0x512E36))
                line("43  + let diff = parse(raw)", color: Color(hex: 0x9FE3BA), bg: Color(hex: 0x1D4D3D))
                line("44  + await render(diff)", color: Color(hex: 0x9FE3BA), bg: Color(hex: 0x1D4D3D))
                line("45  }")
            }
            .padding(10)
        }
        .background(Color(hex: 0x0C1828))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: 0x58718B).opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 14, y: 9)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Decorative pull request diff preview")
    }

    private func line(_ code: String,
                      color: Color = Color(hex: 0xB5C2D1),
                      bg: Color = .clear) -> some View {
        Text(code)
            .font(mono)
            .foregroundStyle(color)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(bg.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

private struct RivetAuthPalette {
    let background: Color
    let text: Color
    let secondary: Color
    let border: Color
    let quiet: Color
    let fieldBackground: Color
    let buttonBackground: Color
    let buttonText: Color

    init(dark: Bool) {
        background = Color(hex: dark ? 0x161C26 : 0xFCFDFF)
        text = Color(hex: dark ? 0xF4F6FA : 0x192533)
        secondary = Color(hex: dark ? 0x9AA9B9 : 0x647386)
        border = Color(hex: dark ? 0x323C49 : 0xE1E7EE)
        quiet = Color(hex: dark ? 0x222C39 : 0xF1F4F8)
        fieldBackground = Color(hex: dark ? 0x19232E : 0xFFFFFF)
        buttonBackground = Color(hex: dark ? 0xF3F6FA : 0x252B33)
        buttonText = Color(hex: dark ? 0x19212C : 0xFFFFFF)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// Xcode preview/demo harness. Buttons intentionally simulate state changes.
private struct RivetLoginDemo: View {
    @State private var phase: RivetLoginPhase = .welcome

    var body: some View {
        RivetLoginView(
            phase: $phase,
            onGitHubSignIn: { phase = .waitingForBrowser },
            onCancelSignIn: { phase = .welcome },
            onTokenSignIn: { _ in phase = .verifyingToken },
            onRetry: { phase = .waitingForBrowser }
        )
    }
}

#Preview("Light") {
    RivetLoginDemo()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RivetLoginDemo()
        .preferredColorScheme(.dark)
}
