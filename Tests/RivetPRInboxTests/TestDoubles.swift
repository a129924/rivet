@testable import RivetPRInbox

actor FakeReviewRequestSource: ReviewRequestSource {
  private let result: Outcome<[ReviewRequestCandidate], PRInboxFailure>
  private(set) var fetchCount = 0

  init(result: Outcome<[ReviewRequestCandidate], PRInboxFailure>) {
    self.result = result
  }

  func fetchReviewRequestCandidates() async -> Outcome<[ReviewRequestCandidate], PRInboxFailure> {
    fetchCount += 1
    return result
  }
}
