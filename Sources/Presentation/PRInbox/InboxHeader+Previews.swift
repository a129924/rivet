#if DEBUG
  import SwiftUI

  private enum InboxHeaderPreviewFixtures {
    static let standard = InboxHeaderPresentation(
      title: "PR Inbox",
      subtitle: "Pull requests waiting for your attention."
    )

    static let longSubtitle = InboxHeaderPresentation(
      title: "PR Inbox",
      subtitle:
        "Pull requests waiting for your attention across several repositories and a much longer explanation."
    )
  }

  private struct InboxHeaderPreviewHarness: View {
    let presentation: InboxHeaderPresentation
    let width: CGFloat
    @State private var selectedFilter: InboxHeaderFilter

    init(
      presentation: InboxHeaderPresentation = InboxHeaderPreviewFixtures.standard,
      initialFilter: InboxHeaderFilter = .needsReview,
      width: CGFloat = 700
    ) {
      self.presentation = presentation
      self.width = width
      self._selectedFilter = State(initialValue: initialFilter)
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        InboxHeader(presentation: presentation, selectedFilter: $selectedFilter)

        Text("Selected filter: \(selectedFilter.title)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16)
      }
      .frame(width: width)
    }
  }

  #Preview("Standard · Needs Review") {
    InboxHeaderPreviewHarness()
  }

  #Preview("Mentioned") {
    InboxHeaderPreviewHarness(initialFilter: .mentioned)
  }

  #Preview("All") {
    InboxHeaderPreviewHarness(initialFilter: .all)
  }

  #Preview("620 pt checkpoint") {
    InboxHeaderPreviewHarness(width: 620)
  }

  #Preview("300 pt narrow") {
    InboxHeaderPreviewHarness(width: 300)
  }

  #Preview("Long subtitle") {
    InboxHeaderPreviewHarness(
      presentation: InboxHeaderPreviewFixtures.longSubtitle,
      width: 620
    )
  }

  #Preview("Increased Contrast") {
    InboxHeaderPreviewHarness()
      .environment(\._colorSchemeContrast, .increased)
  }

  #Preview("Inactive Control State") {
    InboxHeaderPreviewHarness()
      .environment(\.controlActiveState, .inactive)
  }
#endif
