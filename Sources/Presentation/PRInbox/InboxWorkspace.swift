import SwiftUI

enum InboxWorkspaceLayout {
  static func isCompact(width: CGFloat) -> Bool {
    width < 620
  }
}

/// The Inbox composition surface. The caller retains selection, focus and Open handling.
public struct InboxWorkspace<Sidebar: View, Content: View, Footer: View>: View {
  @Environment(\.colorScheme) private var colorScheme
  private let header: InboxHeaderPresentation
  @Binding private var selectedFilter: InboxHeaderFilter
  private let isFilterEnabled: Bool
  private let sidebar: Sidebar
  private let content: Content
  private let footer: Footer

  public init(
    header: InboxHeaderPresentation,
    selectedFilter: Binding<InboxHeaderFilter>,
    isFilterEnabled: Bool,
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder content: () -> Content,
    @ViewBuilder footer: () -> Footer
  ) {
    self.header = header
    self._selectedFilter = selectedFilter
    self.isFilterEnabled = isFilterEnabled
    self.sidebar = sidebar()
    self.content = content()
    self.footer = footer()
  }

  public var body: some View {
    let palette = RivetPalette(dark: colorScheme == .dark)
    GeometryReader { geometry in
      let compact = InboxWorkspaceLayout.isCompact(width: geometry.size.width)
      let layout =
        compact
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
        : AnyLayout(HStackLayout(alignment: .top, spacing: 0))
      layout {
        sidebarContent(compact: compact, palette: palette)
        pane(palette: palette)
      }
    }
    .background(palette.background)
  }

  private func sidebarContent(compact: Bool, palette: RivetPalette) -> some View {
    let layout =
      compact
      ? AnyLayout(HStackLayout(alignment: .center, spacing: 16))
      : AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
    return layout {
      HStack(spacing: 6) {
        RivetBrandMark(size: 16, foreground: palette.primary)
          .accessibilityHidden(true)
        Text("Rivet")
          .font(.headline)
          .foregroundStyle(palette.primary)
      }
      sidebar
        .foregroundStyle(palette.secondary)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity, alignment: .topLeading)
    .frame(width: compact ? nil : 174)
    .overlay(alignment: compact ? .bottom : .trailing) {
      if compact {
        VStack { Divider() }
      } else {
        HStack { Divider() }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("側欄")
  }

  private func pane(palette: RivetPalette) -> some View {
    VStack(spacing: 0) {
      InboxHeader(
        presentation: header, selectedFilter: $selectedFilter,
        palette: palette, isFilterEnabled: isFilterEnabled
      )
      Divider()
      content
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.surface)
        .padding(12)
      Divider()
      footer
    }
  }
}
