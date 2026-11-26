import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader

package struct GitHubPullRequestReviewMergeStateSource: Sendable {
  private typealias PullRequest =
    ReaderGitHubGraphQL.PullRequestReviewMergeStateQuery.Data.Repository.PullRequest

  private let client: any GitHubGraphQLServing

  package init(client: any GitHubGraphQLServing) {
    self.client = client
  }

  package func fetchReviewMergeState(
    for id: ReaderPullRequestID
  ) async -> Outcome<ReaderPullRequestReviewMergeState, PRReaderFailure> {
    do {
      try Task.checkCancellation()
      guard let number = Int32(exactly: id.number),
        (try? GitHubPullRequestDetailEndpoint.validateIdentity(id)) != nil
      else { throw PRReaderFailure.notReadable }

      let pullRequest = try await readPullRequest(for: id, number: number)
      let state = try Self.mapState(pullRequest)
      try Task.checkCancellation()
      return .success(state)
    } catch let failure as PRReaderFailure {
      return .failure(Task.isCancelled ? .unavailable : failure)
    } catch let error as GitHubGraphQLClientError {
      let denied = error == .authenticationRequired || error == .httpStatus(401)
      return .failure(denied && !Task.isCancelled ? .notReadable : .unavailable)
    } catch {
      return .failure(.unavailable)
    }
  }

  private func readPullRequest(
    for id: ReaderPullRequestID, number: Int32
  ) async throws -> PullRequest {
    let response = try await client.fetch(
      query: ReaderGitHubGraphQL.PullRequestReviewMergeStateQuery(
        owner: id.owner, name: id.repository, number: number))
    try Task.checkCancellation()

    if let errors = response.errors, !errors.isEmpty {
      throw errors.allSatisfy(Self.confirmsPullRequestUnavailable)
        ? PRReaderFailure.notReadable : PRReaderFailure.unavailable
    }
    guard let data = response.data else { throw PRReaderFailure.unavailable }
    guard let repository = data.repository else { throw PRReaderFailure.notReadable }
    try Self.requireNonBlank(repository.id, repository.nameWithOwner)

    let expectedName = "\(id.owner)/\(id.repository)"
    guard repository.nameWithOwner.caseInsensitiveCompare(expectedName) == .orderedSame
    else { throw PRReaderFailure.unavailable }
    guard let pullRequest = repository.pullRequest else { throw PRReaderFailure.notReadable }
    try Self.requireNonBlank(pullRequest.repository.id)
    guard pullRequest.number == id.number, pullRequest.repository.id == repository.id
    else { throw PRReaderFailure.unavailable }
    return pullRequest
  }

  private static func mapState(
    _ pullRequest: PullRequest
  ) throws -> ReaderPullRequestReviewMergeState {
    try requireNonBlank(pullRequest.headRefOid)
    return ReaderPullRequestReviewMergeState(
      reviewDecision: try pullRequest.reviewDecision.map(mapReviewDecision),
      mergeable: try mapMergeable(pullRequest.mergeable),
      mergeStateStatus: try mapMergeStateStatus(pullRequest.mergeStateStatus),
      isDraft: pullRequest.isDraft, headRefOid: pullRequest.headRefOid)
  }

  private static func mapReviewDecision(
    _ decision: GraphQLEnum<ReaderGitHubGraphQL.PullRequestReviewDecision>
  ) throws -> ReviewDecision {
    switch decision {
    case .case(.approved): .approved
    case .case(.changesRequested): .changesRequested
    case .case(.reviewRequired): .reviewRequired
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func mapMergeable(
    _ mergeable: GraphQLEnum<ReaderGitHubGraphQL.MergeableState>
  ) throws -> ReaderMergeableState {
    switch mergeable {
    case .case(.conflicting): .conflicting
    case .case(.mergeable): .mergeable
    case .case(.unknown): .unknown
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func mapMergeStateStatus(
    _ status: GraphQLEnum<ReaderGitHubGraphQL.MergeStateStatus>
  ) throws -> ReaderMergeStateStatus {
    switch status {
    case .case(.behind): .behind
    case .case(.blocked): .blocked
    case .case(.clean): .clean
    case .case(.dirty): .dirty
    case .case(.draft): .draft
    case .case(.hasHooks): .hasHooks
    case .case(.unknown): .unknown
    case .case(.unstable): .unstable
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func requireNonBlank(_ values: String...) throws {
    guard values.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    else { throw PRReaderFailure.contentNotRepresentable }
  }

  private static func confirmsPullRequestUnavailable(_ error: GraphQLError) -> Bool {
    let types = [error["type"], error.extensions?["type"]].compactMap { $0 }
    guard let type = types.first as? String, type == "NOT_FOUND" || type == "FORBIDDEN",
      types.allSatisfy({ ($0 as? String) == type }),
      let path = error["path"] as? [String]
    else { return false }
    return path == ["repository"] || path == ["repository", "pullRequest"]
  }
}
