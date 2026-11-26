import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader

package struct GitHubPullRequestChecksSource: Sendable {
  private typealias PullRequest =
    ReaderGitHubGraphQL.PullRequestChecksQuery.Data.Repository.PullRequest
  private typealias CheckNode = PullRequest.StatusCheckRollup.Contexts.Node

  private let client: any GitHubGraphQLServing

  package init(client: any GitHubGraphQLServing) {
    self.client = client
  }

  package func fetchChecks(
    for id: ReaderPullRequestID
  ) async -> Outcome<ReaderCheckRollup?, PRReaderFailure> {
    do {
      try Task.checkCancellation()
      guard let number = Int32(exactly: id.number),
        (try? GitHubPullRequestDetailEndpoint.validateIdentity(id)) != nil
      else { throw PRReaderFailure.notReadable }

      let rollup = try await readChecks(for: id, number: number)
      try Task.checkCancellation()
      return .success(rollup)
    } catch let failure as PRReaderFailure {
      return .failure(Task.isCancelled ? .unavailable : failure)
    } catch let error as GitHubGraphQLClientError {
      let denied = error == .authenticationRequired || error == .httpStatus(401)
      return .failure(denied && !Task.isCancelled ? .notReadable : .unavailable)
    } catch {
      return .failure(.unavailable)
    }
  }

  private func readChecks(
    for id: ReaderPullRequestID, number: Int32
  ) async throws -> ReaderCheckRollup? {
    var firstPage: PageIdentity?
    var cursor: String?
    var seenCursors: Set<String> = []
    var seenChecks: Set<String> = []
    var checks: [ReaderCheck] = []

    while true {
      let pullRequest = try await readPullRequest(
        for: id, number: number, after: cursor, expectedRepositoryID: firstPage?.repositoryID)
      guard let rollup = pullRequest.statusCheckRollup else {
        guard firstPage == nil else { throw PRReaderFailure.unavailable }
        return nil
      }

      try Self.requireIdentity(rollup.id)
      let page = rollup.contexts
      let current = PageIdentity(
        repositoryID: pullRequest.repository.id, pullRequestID: pullRequest.id,
        head: pullRequest.headRefOid, rollupID: rollup.id, state: try Self.mapState(rollup.state),
        totalCount: page.totalCount)
      if let firstPage, current != firstPage { throw PRReaderFailure.unavailable }
      firstPage = current

      try Self.appendChecks(
        page.nodes, isContinuation: cursor != nil, seen: &seenChecks, into: &checks)

      if !page.pageInfo.hasNextPage {
        guard checks.count == current.totalCount else { throw PRReaderFailure.unavailable }
        return ReaderCheckRollup(overallState: current.state, checks: checks)
      }
      guard page.nodes?.isEmpty == false, checks.count < current.totalCount,
        let next = page.pageInfo.endCursor, !Self.isBlank(next), seenCursors.insert(next).inserted
      else { throw PRReaderFailure.unavailable }
      cursor = next
    }
  }

  private func readPullRequest(
    for id: ReaderPullRequestID, number: Int32, after: String?, expectedRepositoryID: String?
  ) async throws -> PullRequest {
    try Task.checkCancellation()
    let response = try await client.fetch(
      query: ReaderGitHubGraphQL.PullRequestChecksQuery(
        owner: id.owner, name: id.repository, number: number,
        after: after.map { .some($0) } ?? .none))
    try Task.checkCancellation()

    if let errors = response.errors, !errors.isEmpty {
      throw errors.allSatisfy(Self.confirmsPullRequestUnavailable)
        ? PRReaderFailure.notReadable : PRReaderFailure.unavailable
    }
    guard let data = response.data else { throw PRReaderFailure.unavailable }
    guard let repository = data.repository else { throw PRReaderFailure.notReadable }
    try Self.requireIdentity(repository.id)

    let expectedName = "\(id.owner)/\(id.repository)"
    guard repository.nameWithOwner.caseInsensitiveCompare(expectedName) == .orderedSame,
      expectedRepositoryID == nil || repository.id == expectedRepositoryID
    else { throw PRReaderFailure.unavailable }
    guard let pullRequest = repository.pullRequest else { throw PRReaderFailure.notReadable }
    try Self.requireIdentity(pullRequest.id)
    try Self.requireIdentity(pullRequest.headRefOid)
    guard pullRequest.number == id.number, pullRequest.repository.id == repository.id
    else { throw PRReaderFailure.unavailable }
    return pullRequest
  }

  private static func appendChecks(
    _ candidates: [CheckNode?]?, isContinuation: Bool, seen: inout Set<String>,
    into checks: inout [ReaderCheck]
  ) throws {
    guard let candidates else { throw PRReaderFailure.contentNotRepresentable }
    guard !isContinuation || !candidates.isEmpty else { throw PRReaderFailure.unavailable }
    for candidate in candidates {
      guard let candidate else { throw PRReaderFailure.contentNotRepresentable }
      let (id, check) = try mapCheck(candidate)
      try requireIdentity(id)
      guard seen.insert(id).inserted else { throw PRReaderFailure.unavailable }
      checks.append(check)
    }
  }

  private static func mapCheck(_ node: CheckNode) throws -> (String, ReaderCheck) {
    if let run = node.asCheckRun {
      return (
        run.id,
        .run(
          name: run.name, status: try mapStatus(run.status),
          conclusion: try run.conclusion.map(mapConclusion))
      )
    }
    if let status = node.asStatusContext {
      return (status.id, .commitStatus(context: status.context, state: try mapState(status.state)))
    }
    throw PRReaderFailure.contentNotRepresentable
  }

  private static func mapState(
    _ state: GraphQLEnum<ReaderGitHubGraphQL.StatusState>
  ) throws -> ReaderCheckState {
    switch state {
    case .case(.expected): .expected
    case .case(.error): .error
    case .case(.failure): .failure
    case .case(.pending): .pending
    case .case(.success): .success
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func mapStatus(
    _ status: GraphQLEnum<ReaderGitHubGraphQL.CheckStatusState>
  ) throws -> ReaderRunStatus {
    switch status {
    case .case(.requested): .requested
    case .case(.queued): .queued
    case .case(.inProgress): .inProgress
    case .case(.completed): .completed
    case .case(.waiting): .waiting
    case .case(.pending): .pending
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func mapConclusion(
    _ conclusion: GraphQLEnum<ReaderGitHubGraphQL.CheckConclusionState>
  ) throws -> ReaderRunConclusion {
    switch conclusion {
    case .case(.actionRequired): .actionRequired
    case .case(.timedOut): .timedOut
    case .case(.cancelled): .cancelled
    case .case(.failure): .failure
    case .case(.success): .success
    case .case(.neutral): .neutral
    case .case(.skipped): .skipped
    case .case(.startupFailure): .startupFailure
    case .case(.stale): .stale
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func requireIdentity(_ value: String) throws {
    if isBlank(value) { throw PRReaderFailure.contentNotRepresentable }
  }

  private static func isBlank(_ value: String) -> Bool {
    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private static func confirmsPullRequestUnavailable(_ error: GraphQLError) -> Bool {
    let types = [error["type"], error.extensions?["type"]].compactMap { $0 }
    guard let type = types.first as? String, type == "NOT_FOUND" || type == "FORBIDDEN",
      types.allSatisfy({ ($0 as? String) == type }),
      let path = error["path"] as? [String]
    else { return false }
    return path == ["repository"] || path == ["repository", "pullRequest"]
  }

  private struct PageIdentity: Equatable {
    let repositoryID: String
    let pullRequestID: String
    let head: String
    let rollupID: String
    let state: ReaderCheckState
    let totalCount: Int
  }
}
