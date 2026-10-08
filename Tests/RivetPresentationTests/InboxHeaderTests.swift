import SwiftUI
import Testing

@testable import RivetPresentation

@Suite("InboxHeader presentation")
struct InboxHeaderTests {
  @Test
  func filtersHaveFixedOrderUniqueIdentityAndLabels() {
    let filters = InboxHeaderFilter.allCases

    #expect(filters == [.needsReview, .mentioned, .all])
    #expect(Set(filters).count == 3)
    #expect(filters.map(\.title) == ["Needs Review", "Mentioned", "All"])
  }

  @Test
  func presentationPreservesDisplayReadyInput() {
    let presentation = InboxHeaderPresentation(
      title: "Review queue",
      subtitle: "A parent-provided subtitle with no filtering policy"
    )

    #expect(presentation.title == "Review queue")
    #expect(presentation.subtitle == "A parent-provided subtitle with no filtering policy")
    #expect(
      presentation
        == InboxHeaderPresentation(
          title: "Review queue",
          subtitle: "A parent-provided subtitle with no filtering policy"
        )
    )
  }

  @Test @MainActor
  func headerSelectionReadsAndWritesTheParentBinding() {
    let parent = InboxHeaderFilterParent()
    let binding = Binding<InboxHeaderFilter>(
      get: { parent.selection },
      set: { newValue in
        parent.selection = newValue
        parent.writes.append(newValue)
      }
    )
    let header = InboxHeader(
      presentation: InboxHeaderPresentation(title: "PR Inbox", subtitle: "Waiting for review"),
      selectedFilter: binding
    )

    #expect(header.selectedFilter == .needsReview)
    header.selectedFilter = .mentioned
    #expect(parent.selection == .mentioned)
    #expect(parent.writes == [.mentioned])

    parent.selection = .all
    #expect(header.selectedFilter == .all)
    #expect(parent.writes == [.mentioned])
  }
}

@MainActor
private final class InboxHeaderFilterParent {
  var selection: InboxHeaderFilter = .needsReview
  var writes: [InboxHeaderFilter] = []
}
