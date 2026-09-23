public protocol PRContentSource: Sendable {
  func fetchContent(for id: ReaderPullRequestID) async
    -> Outcome<PRContentSnapshot, PRReaderFailure>
}
