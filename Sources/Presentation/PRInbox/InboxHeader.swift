import SwiftUI

private struct InboxHeaderWideFitLayout: Layout {
  private let minimumWidth: CGFloat = 620

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let width = max(proposal.width ?? minimumWidth, minimumWidth)
    let contentSize =
      subviews.first?.sizeThatFits(
        ProposedViewSize(width: width, height: proposal.height)
      ) ?? .zero
    return CGSize(width: width, height: contentSize.height)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    subviews.first?.place(
      at: bounds.origin,
      anchor: .topLeading,
      proposal: ProposedViewSize(width: bounds.width, height: proposal.height ?? bounds.height)
    )
  }
}

public enum InboxHeaderFilter: CaseIterable, Hashable, Sendable {
  case needsReview
  case mentioned
  case all

  public var title: String {
    switch self {
    case .needsReview: "Needs Review"
    case .mentioned: "Mentioned"
    case .all: "All"
    }
  }
}

public struct InboxHeaderPresentation: Equatable, Sendable {
  public let title: String
  public let subtitle: String

  public init(title: String, subtitle: String) {
    self.title = title
    self.subtitle = subtitle
  }
}

public struct InboxHeader: View {
  private let presentation: InboxHeaderPresentation
  @Binding var selectedFilter: InboxHeaderFilter

  public init(
    presentation: InboxHeaderPresentation,
    selectedFilter: Binding<InboxHeaderFilter>
  ) {
    self.presentation = presentation
    self._selectedFilter = selectedFilter
  }

  public var body: some View {
    ViewThatFits(in: .horizontal) {
      InboxHeaderWideFitLayout {
        HStack(alignment: .center, spacing: 16) {
          heading
            .frame(maxWidth: .infinity, alignment: .leading)

          filterPicker
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }

      VStack(alignment: .leading, spacing: 12) {
        heading

        filterPicker
          .frame(maxWidth: .infinity)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
  }

  private var heading: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(verbatim: presentation.title)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)
        .accessibilityAddTraits(.isHeader)

      Text(verbatim: presentation.subtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.tail)
    }
  }

  private var filterPicker: some View {
    Picker("Inbox filter", selection: $selectedFilter) {
      ForEach(InboxHeaderFilter.allCases, id: \.self) { filter in
        Text(filter.title).tag(filter)
      }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    .accessibilityLabel("Inbox filter")
  }
}
