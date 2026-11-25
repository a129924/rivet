package struct PRReaderBackgroundFacade: Sendable {
  private let loadBackground: LoadBackground

  package init(source: any PRBackgroundSource) {
    loadBackground = LoadBackground(source: source)
  }

  package func fetchBackground(
    for id: ReaderPullRequestID
  ) async -> Outcome<ReaderBackground, PRReaderFailure> {
    await loadBackground.execute(for: id)
  }
}

private struct LoadBackground: Sendable {
  let source: any PRBackgroundSource

  func execute(for id: ReaderPullRequestID) async -> Outcome<ReaderBackground, PRReaderFailure> {
    await source.fetchBackground(for: id)
  }
}
