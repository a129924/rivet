import RivetPRReader
import Testing

@Suite("PR Reader Core contract")
struct PRReaderContractTests {
  @Test
  func publicValuesRepresentACompleteOrderedSnapshot() async {
    let id = ReaderPullRequestID(owner: "octo", repository: "rivet", number: 42)
    let files = FileChange.allCases.enumerated().map { index, change in
      ReaderFile(
        reference: ReaderFileReference(value: "file-\(index)"),
        path: "Sources/File\(index).swift",
        previousPath: change == .renamed ? "Sources/Old.swift" : nil,
        change: change,
        additions: index + 1,
        deletions: index,
        patch: index == 0 ? "@@ -0,0 +1 @@\n+line" : nil
      )
    }
    let checks = ReaderCheckRollup(
      overallState: .pending,
      checks: [
        .run(name: "build", status: .completed, conclusion: .success),
        .run(name: "test", status: .inProgress, conclusion: nil),
        .commitStatus(context: "lint", state: .expected),
      ]
    )
    let snapshot = PRContentSnapshot(
      id: id,
      background: ReaderBackground(title: "Core contract", body: nil, author: "octocat"),
      conversation: [ReaderComment(id: "comment-1", body: "Looks good", author: nil)],
      reviews: [ReaderReview(id: "review-1", body: "Review", author: "hubot", state: .approved)],
      inlineThreads: [
        ReaderInlineThread(
          id: "thread-1",
          path: "Sources/File0.swift",
          line: nil,
          isResolved: false,
          isOutdated: true,
          comments: [ReaderComment(id: "inline-1", body: "Question", author: "octocat")]
        )
      ],
      files: files,
      reviewDecision: .reviewRequired,
      checkRollup: checks
    )
    let result = await FakePRContentSource(result: .success(snapshot)).fetchContent(for: id)

    #expect(result == .success(snapshot))
    #expect(snapshot.files.map(\.change) == FileChange.allCases)
    #expect(snapshot.files.first?.patch != nil)
    #expect(snapshot.files.dropFirst().allSatisfy { $0.patch == nil })
    #expect(snapshot.checkRollup?.checks == checks.checks)
  }

  @Test
  func optionalRollupAndEmptyRollupRemainDistinct() {
    let id = ReaderPullRequestID(owner: "octo", repository: "rivet", number: 1)
    let background = ReaderBackground(title: "Empty", body: nil, author: nil)
    let absent = PRContentSnapshot(
      id: id,
      background: background,
      conversation: [],
      reviews: [],
      inlineThreads: [],
      files: [],
      reviewDecision: nil,
      checkRollup: nil
    )
    let empty = PRContentSnapshot(
      id: id,
      background: background,
      conversation: [],
      reviews: [],
      inlineThreads: [],
      files: [],
      reviewDecision: nil,
      checkRollup: ReaderCheckRollup(overallState: .success, checks: [])
    )

    #expect(absent.checkRollup == nil)
    #expect(empty.checkRollup?.checks == [])
    #expect(absent != empty)
  }

  @Test(arguments: PRReaderFailure.allCases)
  func portReturnsEveryReaderFailure(_ failure: PRReaderFailure) async {
    let source = FakePRContentSource(result: .failure(failure))
    let id = ReaderPullRequestID(owner: "octo", repository: "rivet", number: 7)

    #expect(await source.fetchContent(for: id) == .failure(failure))
  }

  @Test(arguments: ReviewState.allCases)
  func everyReviewStateIsRepresentable(_ state: ReviewState) {
    let review = ReaderReview(id: "review", body: "body", author: nil, state: state)

    #expect(review.state == state)
  }

  @Test(arguments: ReviewDecision.allCases)
  func everyReviewDecisionIsRepresentable(_ decision: ReviewDecision) {
    let snapshot = emptySnapshot(reviewDecision: decision)

    #expect(snapshot.reviewDecision == decision)
  }

  @Test(arguments: ReaderRunStatus.allCases)
  func everyRunStatusIsRepresentable(_ status: ReaderRunStatus) {
    let check = ReaderCheck.run(name: "run", status: status, conclusion: nil)

    #expect(check == .run(name: "run", status: status, conclusion: nil))
  }

  @Test(arguments: ReaderRunConclusion.allCases)
  func everyRunConclusionIsRepresentable(_ conclusion: ReaderRunConclusion) {
    let check = ReaderCheck.run(name: "run", status: .completed, conclusion: conclusion)

    #expect(check == .run(name: "run", status: .completed, conclusion: conclusion))
  }

  @Test(arguments: ReaderCheckState.allCases)
  func everyCheckStateIsRepresentable(_ state: ReaderCheckState) {
    let check = ReaderCheck.commitStatus(context: "context", state: state)

    #expect(check == .commitStatus(context: "context", state: state))
  }

  @Test
  func publicContractIsSendable() {
    assertSendable(Outcome<PRContentSnapshot, PRReaderFailure>.self)
    assertSendable(ReaderPullRequestID.self)
    assertSendable(ReaderFileReference.self)
    assertSendable(PRContentSnapshot.self)
    assertSendable(ReaderCheck.self)
    assertSendable(PRReaderFailure.self)
  }
}

private struct FakePRContentSource: PRContentSource {
  let result: Outcome<PRContentSnapshot, PRReaderFailure>

  func fetchContent(
    for _: ReaderPullRequestID
  ) async -> Outcome<PRContentSnapshot, PRReaderFailure> {
    result
  }
}

private func assertSendable<Value: Sendable>(_ type: Value.Type) {}

private func emptySnapshot(reviewDecision: ReviewDecision?) -> PRContentSnapshot {
  PRContentSnapshot(
    id: ReaderPullRequestID(owner: "octo", repository: "rivet", number: 1),
    background: ReaderBackground(title: "Empty", body: nil, author: nil),
    conversation: [],
    reviews: [],
    inlineThreads: [],
    files: [],
    reviewDecision: reviewDecision,
    checkRollup: nil
  )
}

extension FileChange {
  fileprivate static let allCases: [FileChange] = [
    .added, .removed, .modified, .renamed, .copied, .typeChanged,
  ]
}

extension PRReaderFailure {
  fileprivate static let allCases: [PRReaderFailure] = [
    .notReadable, .unavailable, .contentNotRepresentable,
  ]
}

extension ReviewState {
  fileprivate static let allCases: [ReviewState] = [
    .pending, .commented, .approved, .changesRequested, .dismissed,
  ]
}

extension ReviewDecision {
  fileprivate static let allCases: [ReviewDecision] = [
    .approved, .changesRequested, .reviewRequired,
  ]
}

extension ReaderRunStatus {
  fileprivate static let allCases: [ReaderRunStatus] = [
    .requested, .queued, .inProgress, .completed, .waiting, .pending,
  ]
}

extension ReaderRunConclusion {
  fileprivate static let allCases: [ReaderRunConclusion] = [
    .actionRequired, .timedOut, .cancelled, .failure, .success, .neutral,
    .skipped, .startupFailure, .stale,
  ]
}

extension ReaderCheckState {
  fileprivate static let allCases: [ReaderCheckState] = [
    .expected, .error, .failure, .pending, .success,
  ]
}
