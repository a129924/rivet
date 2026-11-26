import GitHubIntegration
import RivetPRReader

package enum ReaderInlineReviewContent: Equatable, Sendable {
  case graphQLThreads([ReaderReviewThread])
  case restComments([ReaderInlineReviewComment])
}

package struct GitHubInlineReviewContentSource: Sendable {
  private let threads: GitHubReviewThreadsSource
  private let comments: GitHubInlineReviewCommentsSource

  package init(graphql: any GitHubGraphQLServing, rest: any GitHubRestClient) {
    threads = GitHubReviewThreadsSource(client: graphql)
    comments = GitHubInlineReviewCommentsSource(client: rest)
  }

  package func fetchInlineReviewContent(
    for id: ReaderPullRequestID
  ) async -> Outcome<ReaderInlineReviewContent, PRReaderFailure> {
    guard !Task.isCancelled else { return .failure(.unavailable) }

    let threadResult = await threads.fetchReviewThreads(for: id)
    guard !Task.isCancelled else { return .failure(.unavailable) }

    switch threadResult {
    case .success(let threads):
      return .success(.graphQLThreads(threads))
    case .failure(.unavailable):
      let commentResult = await comments.fetchInlineReviewComments(for: id)
      guard !Task.isCancelled else { return .failure(.unavailable) }
      return commentResult.map(ReaderInlineReviewContent.restComments)
    case .failure(let failure):
      return .failure(failure)
    }
  }
}
