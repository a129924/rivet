import SwiftUI

enum PullRequestRowLayoutContract {
  static let titleLineLimit = 1
}

enum PullRequestRowLayoutTier: Equatable, Sendable {
  case full
  case withoutMetadata
  case withoutAuthorTime
  case primaryOnly

  static let fullMinimumWidth: CGFloat = 620
  static let withoutMetadataMinimumWidth: CGFloat = 480
  static let withoutAuthorTimeMinimumWidth: CGFloat = 340

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
    if availableWidth >= fullMinimumWidth {
      .full
    } else if availableWidth >= withoutMetadataMinimumWidth {
      .withoutMetadata
    } else if availableWidth >= withoutAuthorTimeMinimumWidth {
      .withoutAuthorTime
    } else {
      .primaryOnly
    }
  }
}

public struct PullRequestRow: View {
  private let presentation: PullRequestRowPresentation

  public init(presentation: PullRequestRowPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    ViewThatFits(in: .horizontal) {
      PullRequestRowCandidate(presentation: presentation, tier: .full)
      PullRequestRowCandidate(presentation: presentation, tier: .withoutMetadata)
      PullRequestRowCandidate(presentation: presentation, tier: .withoutAuthorTime)
      PullRequestRowCandidate(presentation: presentation, tier: .primaryOnly)
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
    ZStack(alignment: .leading) {
      if let minimumWidth = tier.minimumWidth {
        PullRequestRowFitProbe(minimumWidth: minimumWidth)
      }

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

private struct PullRequestRowFitProbe: View {
  let minimumWidth: CGFloat

  var body: some View {
    Color.clear
      .frame(minWidth: minimumWidth, maxWidth: .infinity)
      .frame(height: 0)
      .accessibilityHidden(true)
  }
}
