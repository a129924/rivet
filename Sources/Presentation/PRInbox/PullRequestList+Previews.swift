#if DEBUG
  import SwiftUI

  private enum PullRequestListPreviewFixtures {
    static let six: [PullRequestRowPresentation] =
      PullRequestRowPreviewFixtures.all + [
        PullRequestRowPresentation(
          id: "preview/selection#604",
          title: "Keep a selected pull request stable after updates",
          repositoryLabel: "selection",
          numberLabel: "#604",
          authorLabel: "Jordan Park",
          relativeTimeLabel: "3h",
          contextLabel: "Selection check"
        )
      ]

    static let long: [PullRequestRowPresentation] =
      six
      + (7...36).map { index in
        PullRequestRowPresentation(
          id: "preview/long-list#\(index)",
          title: "Pull request \(index) in the long list",
          repositoryLabel: "long-list",
          numberLabel: "#\(index)",
          authorLabel: "Preview Author",
          relativeTimeLabel: "1d"
        )
      }
  }

  private struct PullRequestListPreviewHarness: View {
    @State private var items: [PullRequestRowPresentation]
    @State private var selection: PullRequestRowPresentation.ID?
    @FocusState private var listFocused: Bool
    @FocusState private var otherFocused: Bool
    @State private var otherText = ""
    @State private var openAllowed = true
    @State private var lastOpened: PullRequestRowPresentation.ID?
    @State private var openCount = 0
    @State private var removedID: PullRequestRowPresentation.ID?
    @State private var probeBefore = "—"
    @State private var probeAfter = "—"
    @State private var probeName = "None"
    @State private var doubleClickCallbacks = 0
    @State private var lastDoubleClick = "none"

    private let listWidth: CGFloat
    private let listHeight: CGFloat

    init(
      items: [PullRequestRowPresentation] = PullRequestListPreviewFixtures.six,
      width: CGFloat = 680,
      height: CGFloat = 340
    ) {
      _items = State(initialValue: items)
      _selection = State(initialValue: items.dropFirst().first?.id)
      listWidth = width
      listHeight = height
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        Text(
          "Single click selects only. Clear selection, then double-click a row to check one Open for that ID."
        )
        .font(.caption)

        PullRequestList(
          items: items,
          selection: $selection,
          focus: $listFocused,
          canOpen: { _ in openAllowed },
          onOpen: { id in
            lastOpened = id
            openCount += 1
          }
        )
        .environment(\.pullRequestListDoubleClickDiagnostic) { event in
          doubleClickCallbacks += 1
          let targets = event.targets.sorted().joined(separator: ",")
          lastDoubleClick = [
            "targets=\(targets.isEmpty ? "none" : targets)",
            "selected=\(event.selectedAtEvent ?? "none")",
            "focused=\(event.focusedAtEvent)",
            "emitted=\(event.emittedOpenIntent)",
          ].joined(separator: ", ")
        }
        .frame(width: listWidth, height: listHeight)

        Text("Selection: \(selection ?? "none")  ·  List focus: \(listFocused ? "yes" : "no")")
        Text("Last Open intent: \(lastOpened ?? "none")  ·  Count: \(openCount)")
        Text("Native double-click callbacks: \(doubleClickCallbacks)")
        Text("Last primary action: \(lastDoubleClick)")

        HStack {
          Button("Clear selection") { selection = nil }
          TextField("Other focus control", text: $otherText)
            .focused($otherFocused)
            .frame(width: 180)
          Button("Focus List") { listFocused = true }
        }

        Toggle("Open known-safe", isOn: $openAllowed)

        HStack {
          Button("Remove selected for missing probe") {
            guard let selection else { return }
            removedID = selection
            items.removeAll { $0.id == selection }
            self.selection = nil
          }
          .disabled(selection == nil)

          Button("Probe missing ID") {
            guard let removedID else { return }
            openAllowed = true
            probe("Missing", target: removedID)
          }
          .disabled(removedID == nil)
        }

        HStack {
          Button("Probe nonselected ID") {
            guard let target = items.first(where: { $0.id != selection })?.id else { return }
            openAllowed = true
            probe("Nonselected", target: target)
          }
          .disabled(selection == nil || items.allSatisfy { $0.id == selection })

          Button("Probe unsafe selected ID") {
            guard let selection else { return }
            openAllowed = false
            probe("Unsafe", target: selection)
          }
          .disabled(selection == nil)

          Button("Restore fixtures") {
            items = PullRequestListPreviewFixtures.six
            selection = items.dropFirst().first?.id
            removedID = nil
            openAllowed = true
          }
        }

        Text("Probe: \(probeName)")
        Text("Before: \(probeBefore)")
        Text("After: \(probeAfter)")
      }
      .font(.caption)
      .padding()
    }

    private var snapshot: String {
      "selection=\(selection ?? "none"), focus=\(listFocused), intent=\(lastOpened ?? "none"), count=\(openCount)"
    }

    private func probe(_ name: String, target: PullRequestRowPresentation.ID) {
      probeName = name
      probeBefore = snapshot
      PullRequestListOpen.activate(
        target: target,
        selected: PullRequestListSelection.valid(selection, in: items.map(\.id)),
        ids: items.map(\.id),
        canOpen: { _ in openAllowed },
        onOpen: { id in
          lastOpened = id
          openCount += 1
        }
      )
      probeAfter = snapshot
    }
  }

  #Preview("Six PRs and Open probes") {
    PullRequestListPreviewHarness()
  }

  #Preview("Narrow List") {
    PullRequestListPreviewHarness(width: 300)
  }

  #Preview("Long List") {
    PullRequestListPreviewHarness(items: PullRequestListPreviewFixtures.long, height: 420)
  }

  #Preview("Increased Contrast") {
    PullRequestListPreviewHarness()
      .environment(\._colorSchemeContrast, .increased)
  }

  #Preview("Inactive Control State") {
    PullRequestListPreviewHarness()
      .environment(\.controlActiveState, .inactive)
  }
#endif
