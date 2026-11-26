import AppKit
import SwiftUI

@main
private enum VisualDesignPreview {
  @MainActor
  static func main() {
    guard let configuration = PreviewConfiguration(arguments: CommandLine.arguments.dropFirst())
    else {
      let usage =
        "Usage: RivetDesignLanguagePreview --view samples|inbox --appearance light|dark --width 760|420\n"
      FileHandle.standardError.write(Data(usage.utf8))
      exit(64)
    }

    let app = NSApplication.shared
    let delegate = PreviewWindow(configuration: configuration)
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
    withExtendedLifetime(delegate) {}
  }
}

private struct PreviewConfiguration {
  enum Page: String {
    case samples
    case inbox
  }

  enum Appearance: String {
    case light
    case dark

    var appKit: NSAppearance.Name { self == .dark ? .darkAqua : .aqua }
  }

  let page: Page
  let appearance: Appearance
  let width: CGFloat

  init?(arguments: ArraySlice<String>) {
    var arguments = arguments
    var options: [String: String] = [:]
    let flags = ["--view", "--appearance", "--width"]
    while let flag = arguments.popFirst() {
      guard flags.contains(flag), options[flag] == nil, let value = arguments.popFirst() else {
        return nil
      }
      options[flag] = value
    }
    guard
      let page = options["--view"].flatMap(Page.init(rawValue:)),
      let appearance = options["--appearance"].flatMap(Appearance.init(rawValue:)),
      let width = options["--width"], ["760", "420"].contains(width)
    else { return nil }

    self.page = page
    self.appearance = appearance
    self.width = width == "760" ? 760 : 420
  }
}

@MainActor
private final class PreviewWindow: NSObject, NSApplicationDelegate {
  let configuration: PreviewConfiguration
  private var window: NSWindow?

  init(configuration: PreviewConfiguration) {
    self.configuration = configuration
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "Quit Rivet Design Preview", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    let menuBar = NSMenu()
    let appItem = NSMenuItem()
    appItem.submenu = appMenu
    menuBar.addItem(appItem)
    NSApp.mainMenu = menuBar

    let content = PreviewSurface(configuration: configuration)
    let window = NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: configuration.width, height: 560),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false)
    // AppKit owns the window's appearance and activation. SwiftUI keeps all fixture state.
    window.appearance = NSAppearance(named: configuration.appearance.appKit)
    window.title =
      "Rivet Design Preview · \(configuration.page.rawValue) · \(configuration.appearance.rawValue)"
    window.contentView = NSHostingView(rootView: content)
    window.center()
    self.window = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

private struct PreviewPalette {
  let appearance: PreviewConfiguration.Appearance

  var background: Color { Color(sRGB: appearance == .dark ? 0x161C26 : 0xFCFDFF) }
  var primary: Color { Color(sRGB: appearance == .dark ? 0xF4F6FA : 0x192533) }
  var secondary: Color { Color(sRGB: appearance == .dark ? 0x9AA9B9 : 0x647386) }
}

extension Color {
  fileprivate init(sRGB hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255,
      blue: Double(hex & 255) / 255, opacity: 1)
  }
}

private struct PreviewSurface: View {
  let configuration: PreviewConfiguration

  var body: some View {
    let palette = PreviewPalette(appearance: configuration.appearance)
    Group {
      switch configuration.page {
      case .samples:
        DesignSamples(palette: palette)
      case .inbox:
        InboxCandidate(palette: palette, width: configuration.width)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(palette.background)
  }
}

private struct BrandGlyph: View {
  let size: CGFloat
  let color: Color

  var body: some View {
    Canvas { context, canvas in
      let scale = canvas.width / 24
      var path = Path()
      for (centerX, centerY) in [(6.0, 4.0), (6.0, 20.0), (18.0, 6.0)] {
        path.addEllipse(
          in: CGRect(
            x: (centerX - 2) * scale, y: (centerY - 2) * scale, width: 4 * scale, height: 4 * scale)
        )
      }
      path.move(to: CGPoint(x: 6 * scale, y: 6 * scale))
      path.addLine(to: CGPoint(x: 6 * scale, y: 18 * scale))
      path.move(to: CGPoint(x: 18 * scale, y: 8 * scale))
      path.addCurve(
        to: CGPoint(x: 12 * scale, y: 14 * scale),
        control1: CGPoint(x: 18 * scale, y: 11.3 * scale),
        control2: CGPoint(x: 15.3 * scale, y: 14 * scale))
      path.addLine(to: CGPoint(x: 6 * scale, y: 14 * scale))
      context.stroke(
        path, with: .color(color), style: StrokeStyle(lineWidth: 1.7 * scale, lineCap: .round))
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

private struct DesignSamples: View {
  let palette: PreviewPalette

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Visual language").font(.largeTitle.weight(.semibold)).foregroundStyle(
            palette.primary)
          Text("Presentation roles for onboarding and workspace surfaces.")
            .foregroundStyle(palette.secondary)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Color roles").font(.headline).foregroundStyle(palette.primary)
          HStack(spacing: 12) {
            swatch("Background", color: palette.background)
            swatch("Primary text", color: palette.primary)
            swatch("Secondary text", color: palette.secondary)
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Content surface").font(.headline)
          Text("Workspace title").font(.title2.weight(.semibold))
          Text("Item title").font(.body.weight(.semibold))
          Text("Metadata uses the system secondary style.").font(.caption).foregroundStyle(
            .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))

        VStack(alignment: .leading, spacing: 8) {
          Text("Brand mark").font(.headline).foregroundStyle(palette.primary)
          HStack(spacing: 16) {
            BrandGlyph(size: 22, color: palette.primary)
            BrandGlyph(size: 16, color: palette.primary)
            Text("22 pt and 16 pt").font(.caption).foregroundStyle(palette.secondary)
          }
        }
      }
    }
  }

  private func swatch(_ name: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      RoundedRectangle(cornerRadius: 6)
        .fill(color)
        .strokeBorder(palette.secondary.opacity(0.42))
        .frame(height: 42)
        .accessibilityHidden(true)
      Text(name).font(.caption).foregroundStyle(palette.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct InboxCandidate: View {
  private enum Filter: String, CaseIterable, Identifiable {
    case needsReview = "Needs Review"
    case mentioned = "Mentioned"
    case all = "All"
    var id: Self { self }
  }

  private struct PullRequest: Identifiable {
    let id: Int
    let title: String
    let repository: String
    let updated: String
  }

  private let rows: [PullRequest] = [
    .init(
      id: 72, title: "Keep the selection when the list refreshes", repository: "rivet",
      updated: "14 min ago"),
    .init(
      id: 68, title: "Preserve review notes when moving between several changed files",
      repository: "rivet", updated: "42 min ago"),
    .init(
      id: 61, title: "Group keyboard actions in the review menu", repository: "rivet",
      updated: "1 hr ago"),
    .init(
      id: 46, title: "Describe loading and empty review states", repository: "rivet",
      updated: "Yesterday"),
  ]
  @State private var selection: PullRequest.ID? = 72
  @State private var filter: Filter = .needsReview

  let palette: PreviewPalette
  let width: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          BrandGlyph(size: 16, color: palette.primary)
          Text("PR Inbox").font(.title2.weight(.semibold)).foregroundStyle(palette.primary)
        }
        Text("Pull requests waiting for your attention.")
          .font(.subheadline)
          .foregroundStyle(palette.secondary)
      }

      Picker("Review filter", selection: $filter) {
        ForEach(Filter.allCases) { filter in
          Text(filter.rawValue).tag(filter)
        }
      }
      .labelsHidden()
      .pickerStyle(.segmented)

      Divider()

      List(rows, selection: $selection) { row in
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(row.title).font(.headline).lineLimit(1).truncationMode(.tail)
            Text("\(row.repository) #\(row.id)").font(.caption).foregroundStyle(.secondary)
          }
          if width == 760 {
            Spacer(minLength: 8)
            Text(row.updated).font(.caption).foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 6)
        .tag(row.id)
      }
      .listStyle(.inset)
      .accessibilityLabel("Pull requests")

      Button("Open pull request") {}.disabled(true)
    }
  }
}
