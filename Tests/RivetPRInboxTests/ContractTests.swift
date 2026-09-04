import RivetPRInbox
import Testing

@Suite("PRInbox contract")
struct PRInboxContractTests {
  @Test
  func publicValueTypesAreSendable() {
    assertSendable(Outcome<[InboxItem], PRInboxFailure>.self)
    assertSendable(InboxItem.self)
    assertSendable(ReviewRequestCandidate.self)
    assertSendable(PRInboxFailure.self)
    assertSendable(PRInboxFacade.self)
  }

  @Test
  func candidateRetainsSemanticMembershipInputs() {
    let item = InboxItem(owner: "octo", repository: "rivet", number: 42, title: "Review")
    let candidate = ReviewRequestCandidate(
      item: item,
      isOpen: true,
      isDirectlyRequestedForCurrentUser: true
    )

    #expect(candidate.item == item)
    #expect(candidate.isOpen)
    #expect(candidate.isDirectlyRequestedForCurrentUser)
  }

  @Test
  func outcomeIsUsableAsTheStandardLibraryResult() {
    let item = InboxItem(owner: "octo", repository: "rivet", number: 42, title: "Review")
    let success: Outcome<InboxItem, PRInboxFailure> = .success(item)
    let failure: Outcome<InboxItem, PRInboxFailure> = .failure(.unavailable)

    acceptStandardResult(success)
    acceptStandardResult(failure)
  }
}

private func assertSendable<Value: Sendable>(_ type: Value.Type) {}

private func acceptStandardResult(_ result: Result<InboxItem, PRInboxFailure>) {}
