import SwiftUI

enum PullRequestRowLayoutContract {
  static let titleLineLimit = 1
}

enum PullRequestRowLayoutTier: Equatable, Hashable, Sendable {
  case full
  case withoutMetadata
  case withoutAuthorTime
  case primaryOnly

  static let fullMinimumWidth: CGFloat = 620
  static let withoutMetadataMinimumWidth: CGFloat = 480
  static let withoutAuthorTimeMinimumWidth: CGFloat = 340
  static let orderedFitCandidates: [Self] = [
    .full,
    .withoutMetadata,
    .withoutAuthorTime,
    .primaryOnly,
  ]

  var minimumWidth: CGFloat? {
    switch self {
    case .full:
      Self.fullMinimumWidth
    case .withoutMetadata:
      Self.withoutMetadataMinimumWidth
    case .withoutAuthorTime:
      Self.withoutAuthorTimeMinimumWidth
    case .primaryOnly:
      nil
    }
  }

  var showsContext: Bool {
    self != .primaryOnly
  }

  var showsAuthorTime: Bool {
    self == .full || self == .withoutMetadata
  }

  var showsMetadata: Bool {
    self == .full
  }

  static func resolve(availableWidth: CGFloat) -> Self {
    orderedFitCandidates.first { tier in
      availableWidth >= (tier.minimumWidth ?? 0)
    } ?? .primaryOnly
  }
}

struct PullRequestRowFitLayout: Layout {
  let tier: PullRequestRowLayoutTier

  static func reportedWidth(
    proposedWidth: CGFloat?,
    contentIdealWidth _: CGFloat,
    tier: PullRequestRowLayoutTier
  ) -> CGFloat {
    let minimumWidth = tier.minimumWidth ?? 0
    return max(proposedWidth ?? minimumWidth, minimumWidth)
  }

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let minimumWidth = tier.minimumWidth ?? 0
    let contentWidth = proposal.width ?? minimumWidth
    let contentProposal = ProposedViewSize(
      width: contentWidth,
      height: proposal.height
    )
    let contentSize = subviews.first?.sizeThatFits(contentProposal) ?? .zero

    return CGSize(
      width: Self.reportedWidth(
        proposedWidth: proposal.width,
        contentIdealWidth: contentSize.width,
        tier: tier
      ),
      height: contentSize.height
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    guard let content = subviews.first else { return }

    content.place(
      at: bounds.origin,
      anchor: .topLeading,
      proposal: ProposedViewSize(
        width: bounds.width,
        height: proposal.height ?? bounds.height
      )
    )
  }
}

public struct PullRequestRow: View {
  private let presentation: PullRequestRowPresentation

  public init(presentation: PullRequestRowPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    ViewThatFits(in: .horizontal) {
      ForEach(PullRequestRowLayoutTier.orderedFitCandidates, id: \.self) { tier in
        PullRequestRowCandidate(presentation: presentation, tier: tier)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: presentation.accessibilityLabelText))
    .accessibilityValue(Text(verbatim: presentation.accessibilityValueText))
  }
}

private struct PullRequestRowCandidate: View {
  let presentation: PullRequestRowPresentation
  let tier: PullRequestRowLayoutTier

  var body: some View {
    PullRequestRowFitLayout(tier: tier) {
      content
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(presentation.title)
        .font(.headline)
        .foregroundStyle(.primary)
        .lineLimit(PullRequestRowLayoutContract.titleLineLimit)
        .truncationMode(.tail)

      HStack(spacing: 8) {
        Text("\(presentation.repositoryLabel) \(presentation.numberLabel)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
          .layoutPriority(3)

        if tier.showsContext, let contextLabel = presentation.contextLabel {
          Text(contextLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .layoutPriority(2)
        }

        Spacer(minLength: 8)

        if tier.showsAuthorTime {
          Text("\(presentation.authorLabel) · \(presentation.relativeTimeLabel)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .layoutPriority(1)
        }

        if tier.showsMetadata, !presentation.secondaryMetadataLabels.isEmpty {
          Text(presentation.secondaryMetadataLabels.joined(separator: " · "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 4)
  }
}
