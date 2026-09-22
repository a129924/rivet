import CoreGraphics
import Testing

@testable import RivetPresentation

@Suite("PullRequestRow presentation")
struct PullRequestRowPresentationTests {
  @Test
  func presentationStoresDisplayReadyValues() {
    let presentation = PullRequestRowPresentation(
      id: "sample-studio/atlas-desktop#87",
      title: "Clarify offline workspace state",
      repositoryLabel: "atlas-desktop",
      numberLabel: "#87",
      authorLabel: "Theo North",
      relativeTimeLabel: "38m",
      contextLabel: "Context prepared",
      secondaryMetadataLabels: ["priority"]
    )
    let equalPresentation = PullRequestRowPresentation(
      id: "sample-studio/atlas-desktop#87",
      title: "Clarify offline workspace state",
      repositoryLabel: "atlas-desktop",
      numberLabel: "#87",
      authorLabel: "Theo North",
      relativeTimeLabel: "38m",
      contextLabel: "Context prepared",
      secondaryMetadataLabels: ["priority"]
    )

    #expect(presentation.id == "sample-studio/atlas-desktop#87")
    #expect(presentation.title == "Clarify offline workspace state")
    #expect(presentation.repositoryLabel == "atlas-desktop")
    #expect(presentation.numberLabel == "#87")
    #expect(presentation.authorLabel == "Theo North")
    #expect(presentation.relativeTimeLabel == "38m")
    #expect(presentation.contextLabel == "Context prepared")
    #expect(presentation.secondaryMetadataLabels == ["priority"])
    #expect(presentation == equalPresentation)
    #expect(Set([presentation, equalPresentation]).count == 1)
  }

  @Test
  func optionalMetadataCanBeAbsent() {
    let presentation = PullRequestRowPresentation(
      id: "fixture-labs/minimal-row#503",
      title: "Simplify the empty state copy",
      repositoryLabel: "minimal-row",
      numberLabel: "#503",
      authorLabel: "Avery Quinn",
      relativeTimeLabel: "1d"
    )

    #expect(presentation.contextLabel == nil)
    #expect(presentation.secondaryMetadataLabels.isEmpty)
  }

  @Test
  func accessibilityTextIncludesRequiredSemantics() {
    let presentation = PullRequestRowPresentation(
      id: "sample-studio/atlas-desktop#87",
      title: "Clarify offline workspace state",
      repositoryLabel: "atlas-desktop",
      numberLabel: "#87",
      authorLabel: "Theo North",
      relativeTimeLabel: "38m",
      contextLabel: "Context prepared",
      secondaryMetadataLabels: ["priority"]
    )

    #expect(
      presentation.accessibilityLabelText
        == "Clarify offline workspace state, atlas-desktop #87, Theo North, Context prepared"
    )
    #expect(presentation.accessibilityValueText == "38m, priority")
  }

  @Test
  func accessibilityTextOmitsMissingMetadataWithoutPlaceholders() {
    let presentation = PullRequestRowPresentation(
      id: "fixture-labs/minimal-row#503",
      title: "Simplify the empty state copy",
      repositoryLabel: "minimal-row",
      numberLabel: "#503",
      authorLabel: "Avery Quinn",
      relativeTimeLabel: "1d"
    )

    #expect(
      presentation.accessibilityLabelText
        == "Simplify the empty state copy, minimal-row #503, Avery Quinn"
    )
    #expect(presentation.accessibilityValueText == "1d")
  }

  @Test
  func previewFixturesHaveUniqueIdentitiesAndAreDeterministic() {
    let expected: [PullRequestRowPresentation] = [
      PullRequestRowPresentation(
        id: "sample-studio/atlas-desktop#87",
        title: "Clarify offline workspace state",
        repositoryLabel: "atlas-desktop",
        numberLabel: "#87",
        authorLabel: "Theo North",
        relativeTimeLabel: "38m",
        contextLabel: "Context prepared",
        secondaryMetadataLabels: ["priority"]
      ),
      PullRequestRowPresentation(
        id: "fixture-labs/long-title#501",
        title:
          "Preserve keyboard selection while filtering a very long list of pull request results",
        repositoryLabel: "long-title",
        numberLabel: "#501",
        authorLabel: "Morgan Reed",
        relativeTimeLabel: "1h",
        contextLabel: "Review requested",
        secondaryMetadataLabels: ["interface"]
      ),
      PullRequestRowPresentation(
        id: "fixture-labs/extraordinarily-long-desktop-workspace-repository#502",
        title: "Keep repository identity readable",
        repositoryLabel: "extraordinarily-long-desktop-workspace-repository",
        numberLabel: "#502",
        authorLabel: "Sam Lee",
        relativeTimeLabel: "2h",
        contextLabel: "Context available",
        secondaryMetadataLabels: ["desktop"]
      ),
      PullRequestRowPresentation(
        id: "fixture-labs/minimal-row#503",
        title: "Simplify the empty state copy",
        repositoryLabel: "minimal-row",
        numberLabel: "#503",
        authorLabel: "Avery Quinn",
        relativeTimeLabel: "1d"
      ),
      PullRequestRowPresentation(
        id: "example-labs/nebula-ui#142",
        title: "Tighten keyboard movement across command results",
        repositoryLabel: "nebula-ui",
        numberLabel: "#142",
        authorLabel: "Mira Vale",
        relativeTimeLabel: "12m",
        contextLabel: "Keyboard flow",
        secondaryMetadataLabels: ["mentioned", "keyboard"]
      ),
    ]

    #expect(Set(expected.map(\.id)).count == expected.count)
    #expect(
      Set(expected.map { "\($0.repositoryLabel)\u{0}\($0.numberLabel)" }).count
        == expected.count
    )

    #if DEBUG
      #expect(PullRequestRowPreviewFixtures.all == expected)
    #endif
  }

  @Test
  func layoutTierBreakpointsFollowDegradationOrder() {
    #expect(PullRequestRowLayoutContract.titleLineLimit == 1)
    #expect(
      PullRequestRowLayoutTier.orderedFitCandidates
        == [.full, .withoutMetadata, .withoutAuthorTime, .primaryOnly]
    )

    let cases: [(width: CGFloat, expected: PullRequestRowLayoutTier)] = [
      (680, .full),
      (620, .full),
      (619, .withoutMetadata),
      (560, .withoutMetadata),
      (480, .withoutMetadata),
      (479, .withoutAuthorTime),
      (400, .withoutAuthorTime),
      (340, .withoutAuthorTime),
      (339, .primaryOnly),
      (300, .primaryOnly),
    ]

    for testCase in cases {
      #expect(
        PullRequestRowLayoutTier.resolve(availableWidth: testCase.width)
          == testCase.expected
      )

      for contentIdealWidth in [CGFloat(80), CGFloat(10_000)] {
        let resolvedByProductionFitPolicy =
          PullRequestRowLayoutTier.orderedFitCandidates.first { tier in
            PullRequestRowFitLayout.reportedWidth(
              proposedWidth: testCase.width,
              contentIdealWidth: contentIdealWidth,
              tier: tier
            ) <= testCase.width
          }

        #expect(resolvedByProductionFitPolicy == testCase.expected)
      }
    }

    for tier in PullRequestRowLayoutTier.orderedFitCandidates {
      #expect(
        PullRequestRowFitLayout.reportedWidth(
          proposedWidth: nil,
          contentIdealWidth: 10_000,
          tier: tier
        ) == (tier.minimumWidth ?? 0)
      )
    }
  }
}
