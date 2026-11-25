import Testing

@testable import InboxI1Verification

@MainActor
struct InboxSessionTests {
  let idA = "sample/core#42"
  let idB = "sample/ui#42"
  let idC = "sample/ui#43"

  @Test func firstContentSelectsTheFirstPR() {
    let session = InboxSession()
    #expect(session.selection == idA)
    #expect(session.rows.map(\.id) == [idA, idB, idC])
  }

  @Test func reorderKeepsCompleteIDAndRemovingItFallsBackToFirst() {
    let session = InboxSession()
    session.select(idB, focus: .list)
    #expect(session.show(.reordered, focus: .list) == .list)
    #expect(session.rows.map(\.id) == [idB, idA, idC])
    #expect(session.selection == idB)
    #expect(session.show(.removedB, focus: .list) == .list)
    #expect(session.selection == idA)
    #expect(session.openCount == 0)
  }

  @Test func staleAndNonSelectedRequestsDoNotOpenTheCurrentSelection() {
    var trace: [InboxTrace] = []
    let session = InboxSession { trace.append($0) }
    session.select(idB, focus: .list)
    session.show(.removedB, focus: .list)
    #expect(!session.open(idB, focus: .list, injected: true))
    #expect(session.selection == idA)
    #expect(trace.last?.focus == .list)
    #expect(trace.last?.openDelta == 0)
    #expect(!session.open(idC, focus: .list))
    #expect(session.open(idA, focus: .list))
    #expect(trace.last?.openID == idA)
    #expect(trace.last?.openDelta == 1)
    #expect(session.openCount == 1)
  }

  @Test func openCapabilityIsIndependentOfSelectionAndReadability() {
    let session = InboxSession()
    session.select(idC, focus: .list)
    #expect(session.selection == idC)
    #expect(!session.open(idC, focus: .list))
    session.show(.unknownOpen, focus: .list)
    session.select(idB, focus: .list)
    #expect(!session.open(idB, focus: .list))
    for scenario in [InboxScenario.readableError, .readableOffline] {
      #expect(session.show(scenario, focus: .list) == .list)
      #expect(session.selection == idB)
      #expect(session.rows.map(\.id) == [idA, idB, idC])
      #expect(!session.open(idB, focus: .list))
      #expect(session.status?.recovery != nil)
    }
    #expect(session.openCount == 0)
  }

  @Test func loadingRetainsIdentityAndUsesTheRemainingFocus() {
    let session = InboxSession()
    session.select(idB, focus: .list)
    #expect(session.show(.loading, focus: .list) == .heading)
    #expect(session.selection == nil)
    #expect(session.selectedIdentity == idB)
    #expect(!session.canOpen(idB))
    #expect(session.show(.loading, focus: .verification) == .verification)
    #expect(session.show(.content, focus: .heading) == .list)
    #expect(session.selection == idB)
  }

  @Test func unavailableStatesHaveHeadingFocusAndNoVisibleRows() {
    let session = InboxSession()
    session.select(idB, focus: .list)
    for scenario in [InboxScenario.empty, .unreadableError, .missingAvailability, .offline] {
      #expect(session.show(scenario, focus: .list) == .heading)
      #expect(session.rows.isEmpty)
      #expect(session.selection == nil)
      #expect(session.selectedIdentity == idB)
      #expect(!session.open(idB, focus: .heading))
    }
    #expect(session.status?.title == "目前離線")
    #expect(session.openCount == 0)
  }

  @Test func staleRowsAreTheActualPreviousReadableSnapshot() {
    let session = InboxSession()
    session.show(.reordered, focus: .list)
    session.select(idC, focus: .list)
    #expect(session.show(.readableError, focus: nil) == .heading)
    #expect(session.rows.map(\.id) == [idB, idA, idC])
    #expect(session.selection == idC)
    session.show(.loading, focus: .heading)
    #expect(session.show(.readableOffline, focus: .heading) == .list)
    #expect(session.rows.map(\.id) == [idB, idA, idC])
    #expect(session.selection == idC)
    session.show(.empty, focus: .list)
    #expect(session.show(.readableOffline, focus: .heading) == .heading)
    #expect(session.rows.isEmpty)
  }
}
