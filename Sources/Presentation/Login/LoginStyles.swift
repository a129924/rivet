import AppKit
import SwiftUI

@MainActor
struct LoginStyles {
  let palette: RivetLoginPalette
  let contrast: ColorSchemeContrast
  let typography: RivetLoginTypography
  var scale: CGFloat { typography.scale }
  var bodySize: CGFloat { typography.bodyPointSize }

  static func announce(_ message: String) {
    NSAccessibility.post(
      element: NSApp as Any, notification: .announcementRequested,
      userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium.rawValue]
    )
  }

  func heading(_ text: String, size: CGFloat = 26) -> some View {
    Text(text).font(.system(size: size * scale, weight: .bold)).tracking(-0.65)
      .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
  }

  func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 10 * scale, weight: .bold)).tracking(1.2).foregroundStyle(
      palette.secondary)
  }

  func description(_ text: String) -> some View {
    Text(text).font(.system(size: bodySize)).lineSpacing(3).foregroundStyle(palette.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  func statusIcon<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    content().frame(width: 44, height: 44).background(
      palette.surface, in: RoundedRectangle(cornerRadius: 13)
    )
    .accessibilityHidden(true)
  }

  func primaryButton(
    _ title: String, github: Bool = false, action: @escaping () -> Void
  ) -> some View {
    Button {
      action()
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

  func textButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button {
      action()
    } label: {
      Text(title).underline().font(.system(size: 12 * scale))
    }
    .buttonStyle(.link).foregroundStyle(palette.secondary)
  }

}

struct LoginPrimaryButtonStyle: ButtonStyle {
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
