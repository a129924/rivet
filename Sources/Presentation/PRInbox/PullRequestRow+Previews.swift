#if DEBUG
  import SwiftUI

  enum PullRequestRowPreviewFixtures {
    static let standard = PullRequestRowPresentation(
      id: "sample-studio/atlas-desktop#87",
      title: "Clarify offline workspace state",
      repositoryLabel: "atlas-desktop",
      numberLabel: "#87",
      authorLabel: "Theo North",
      relativeTimeLabel: "38m",
      contextLabel: "Context prepared",
      secondaryMetadataLabels: ["priority"]
    )

    static let longTitle = PullRequestRowPresentation(
      id: "fixture-labs/long-title#501",
      title: "Preserve keyboard selection while filtering a very long list of pull request results",
      repositoryLabel: "long-title",
      numberLabel: "#501",
      authorLabel: "Morgan Reed",
      relativeTimeLabel: "1h",
      contextLabel: "Review requested",
      secondaryMetadataLabels: ["interface"]
    )

    static let longRepository = PullRequestRowPresentation(
      id: "fixture-labs/extraordinarily-long-desktop-workspace-repository#502",
      title: "Keep repository identity readable",
      repositoryLabel: "extraordinarily-long-desktop-workspace-repository",
      numberLabel: "#502",
      authorLabel: "Sam Lee",
      relativeTimeLabel: "2h",
      contextLabel: "Context available",
      secondaryMetadataLabels: ["desktop"]
    )

    static let minimalMetadata = PullRequestRowPresentation(
      id: "fixture-labs/minimal-row#503",
      title: "Simplify the empty state copy",
      repositoryLabel: "minimal-row",
      numberLabel: "#503",
      authorLabel: "Avery Quinn",
      relativeTimeLabel: "1d"
    )

    static let richMetadata = PullRequestRowPresentation(
      id: "example-labs/nebula-ui#142",
      title: "Tighten keyboard movement across command results",
      repositoryLabel: "nebula-ui",
      numberLabel: "#142",
      authorLabel: "Mira Vale",
      relativeTimeLabel: "12m",
      contextLabel: "Keyboard flow",
      secondaryMetadataLabels: ["mentioned", "keyboard"]
    )

    static let all = [standard, longTitle, longRepository, minimalMetadata, richMetadata]
  }

  private struct PullRequestRowFixtureMatrixPreview: View {
    @State private var selection: PullRequestRowPresentation.ID? =
      PullRequestRowPreviewFixtures.standard.id

    var body: some View {
      List(selection: $selection) {
        ForEach(PullRequestRowPreviewFixtures.all) { presentation in
          PullRequestRow(presentation: presentation)
            .tag(presentation.id)
        }
      }
      .frame(width: 680, height: 360)
    }
  }

  private struct PullRequestRowDegradationTiersPreview: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        tier("680 pt — full", width: 680)
        tier("560 pt — without metadata", width: 560)
        tier("400 pt — without author/time", width: 400)
        tier("300 pt — primary only", width: 300)
      }
      .padding()
    }

    private func tier(_ label: String, width: CGFloat) -> some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .font(.caption)
          .foregroundStyle(.secondary)

        PullRequestRow(presentation: PullRequestRowPreviewFixtures.richMetadata)
      }
      .frame(width: width, alignment: .leading)
    }
  }

  private struct PullRequestRowLongContentPreview: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        PullRequestRow(presentation: PullRequestRowPreviewFixtures.longTitle)
        PullRequestRow(presentation: PullRequestRowPreviewFixtures.longRepository)
      }
      .frame(width: 360)
      .padding()
    }
  }

  private struct PullRequestRowSemanticEnvironmentPreview: View {
    let presentations: [PullRequestRowPresentation]

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(presentations) { presentation in
          PullRequestRow(presentation: presentation)
        }
      }
      .frame(width: 680)
      .padding()
    }
  }

  #Preview("Fixture Matrix") {
    PullRequestRowFixtureMatrixPreview()
  }

  #Preview("Degradation Tiers") {
    PullRequestRowDegradationTiersPreview()
  }

  #Preview("Long Content") {
    PullRequestRowLongContentPreview()
  }

  #Preview("Increased Contrast") {
    PullRequestRowSemanticEnvironmentPreview(
      presentations: [
        PullRequestRowPreviewFixtures.standard,
        PullRequestRowPreviewFixtures.richMetadata,
      ]
    )
    .environment(\._colorSchemeContrast, .increased)
  }

  #Preview("Inactive Control State") {
    PullRequestRowSemanticEnvironmentPreview(
      presentations: [
        PullRequestRowPreviewFixtures.standard,
        PullRequestRowPreviewFixtures.richMetadata,
      ]
    )
    .environment(\.controlActiveState, .inactive)
  }
#endif
