import Testing
@testable import RivetPRInbox

@Suite("PRInboxFacade")
struct PRInboxFacadeTests {
  @Test
  func refreshFiltersCandidatesInSourceOrderAndCallsSourceOnce() async {
    let first = ReviewRequestCandidate(
      item: InboxItem(owner: "octo", repository: "rivet", number: 1, title: "First"),
      isOpen: true,
      isDirectlyRequestedForCurrentUser: true
    )
    let closedCandidate = ReviewRequestCandidate(
      item: InboxItem(owner: "octo", repository: "rivet", number: 3, title: "Closed"),
      isOpen: false,
      isDirectlyRequestedForCurrentUser: true
    )
    let nonDirectCandidate = ReviewRequestCandidate(
      item: InboxItem(
        owner: "octo",
        repository: "rivet",
        number: 4,
        title: "Not directly requested"
      ),
      isOpen: true,
      isDirectlyRequestedForCurrentUser: false
    )
    let second = ReviewRequestCandidate(
      item: InboxItem(owner: "octo", repository: "rivet", number: 2, title: "Second"),
      isOpen: true,
      isDirectlyRequestedForCurrentUser: true
    )
    let source = FakeReviewRequestSource(
      result: .success([first, closedCandidate, nonDirectCandidate, second])
    )

    let result = await PRInboxFacade(source: source).refresh()

    #expect(inboxItems(from: result) == [first.item, second.item])
    #expect(await source.fetchCount == 1)
  }

  @Test
  func refreshReturnsAnEmptySuccessfulInbox() async {
    let source = FakeReviewRequestSource(result: .success([]))

    let result = await PRInboxFacade(source: source).refresh()

    #expect(inboxItems(from: result) == [])
    #expect(await source.fetchCount == 1)
  }

  @Test
  func refreshPassesUnavailableThroughUnchanged() async {
    let source = FakeReviewRequestSource(result: .failure(.unavailable))

    let result = await PRInboxFacade(source: source).refresh()

    #expect(failure(from: result) == .unavailable)
    #expect(await source.fetchCount == 1)
  }
}

private func inboxItems(
  from outcome: Outcome<[InboxItem], PRInboxFailure>
) -> [InboxItem]? {
  guard case .success(let items) = outcome else {
    return nil
  }

  return items
}

private func failure(
  from outcome: Outcome<[InboxItem], PRInboxFailure>
) -> PRInboxFailure? {
  guard case .failure(let failure) = outcome else {
    return nil
  }

  return failure
}
