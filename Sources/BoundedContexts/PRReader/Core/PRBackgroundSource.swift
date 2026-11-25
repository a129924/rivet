package protocol PRBackgroundSource: Sendable {
  func fetchBackground(for id: ReaderPullRequestID) async
    -> Outcome<ReaderBackground, PRReaderFailure>
}
