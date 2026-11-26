import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader

package struct GitHubPullRequestFilesViewedSource: Sendable {
  private typealias PullRequest =
    ReaderGitHubGraphQL.PullRequestFilesViewedQuery.Data.Repository.PullRequest
  private typealias FileNode = PullRequest.Files.Node

  private let client: any GitHubGraphQLServing

  package init(client: any GitHubGraphQLServing) {
    self.client = client
  }

  package func fetchFilesViewed(
    for id: ReaderPullRequestID
  ) async -> Outcome<[ReaderFileViewed], PRReaderFailure> {
    do {
      try Task.checkCancellation()
      guard let number = Int32(exactly: id.number),
        (try? GitHubPullRequestDetailEndpoint.validateIdentity(id)) != nil
      else { throw PRReaderFailure.notReadable }

      let files = try await readFiles(for: id, number: number)
      try Task.checkCancellation()
      return .success(files)
    } catch let failure as PRReaderFailure {
      return .failure(Task.isCancelled ? .unavailable : failure)
    } catch let error as GitHubGraphQLClientError {
      let denied = error == .authenticationRequired || error == .httpStatus(401)
      return .failure(denied && !Task.isCancelled ? .notReadable : .unavailable)
    } catch {
      return .failure(.unavailable)
    }
  }

  private func readFiles(
    for id: ReaderPullRequestID, number: Int32
  ) async throws -> [ReaderFileViewed] {
    var firstPage: PageIdentity?
    var cursor: String?
    var seenCursors: Set<String> = []
    var seenPaths: Set<Data> = []
    var files: [ReaderFileViewed] = []

    while true {
      let pullRequest = try await readPullRequest(
        for: id, number: number, after: cursor, expectedRepositoryID: firstPage?.repositoryID)
      guard let page = pullRequest.files else { throw PRReaderFailure.unavailable }
      let current = PageIdentity(
        repositoryID: pullRequest.repository.id, pullRequestID: pullRequest.id,
        head: pullRequest.headRefOid, totalCount: page.totalCount)
      if let firstPage, current != firstPage { throw PRReaderFailure.unavailable }
      firstPage = current

      guard let nodes = page.nodes else { throw PRReaderFailure.contentNotRepresentable }
      guard cursor == nil || !nodes.isEmpty else { throw PRReaderFailure.unavailable }
      try Self.appendFiles(nodes, seen: &seenPaths, into: &files)

      if !page.pageInfo.hasNextPage {
        guard files.count == current.totalCount else { throw PRReaderFailure.unavailable }
        return files
      }
      guard !nodes.isEmpty, files.count < current.totalCount,
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
      query: ReaderGitHubGraphQL.PullRequestFilesViewedQuery(
        owner: id.owner, name: id.repository, number: number,
        after: after.map { .some($0) } ?? .none))
    try Task.checkCancellation()

    if let errors = response.errors, !errors.isEmpty {
      throw errors.allSatisfy(Self.confirmsPullRequestUnavailable)
        ? PRReaderFailure.notReadable : PRReaderFailure.unavailable
    }
    guard let data = response.data else { throw PRReaderFailure.unavailable }
    guard let repository = data.repository else { throw PRReaderFailure.notReadable }

    let expectedName = "\(id.owner)/\(id.repository)"
    guard !Self.isBlank(repository.id),
      repository.nameWithOwner.caseInsensitiveCompare(expectedName) == .orderedSame,
      expectedRepositoryID == nil || repository.id == expectedRepositoryID
    else { throw PRReaderFailure.unavailable }
    guard let pullRequest = repository.pullRequest else { throw PRReaderFailure.notReadable }
    guard !Self.isBlank(pullRequest.id), !Self.isBlank(pullRequest.headRefOid),
      pullRequest.number == id.number, pullRequest.repository.id == repository.id
    else { throw PRReaderFailure.unavailable }
    return pullRequest
  }

  private static func appendFiles(
    _ nodes: [FileNode?], seen: inout Set<Data>, into files: inout [ReaderFileViewed]
  ) throws {
    for node in nodes {
      guard let node, !node.path.isEmpty, node.additions >= 0, node.deletions >= 0,
        seen.insert(Data(node.path.utf8)).inserted
      else { throw PRReaderFailure.contentNotRepresentable }
      files.append(
        ReaderFileViewed(
          path: node.path, change: try mapChange(node.changeType), additions: node.additions,
          deletions: node.deletions, viewedState: try mapViewedState(node.viewerViewedState)))
    }
  }

  private static func mapChange(
    _ status: GraphQLEnum<ReaderGitHubGraphQL.PatchStatus>
  ) throws -> FileChange {
    switch status {
    case .case(.added): .added
    case .case(.deleted): .removed
    case .case(.modified): .modified
    case .case(.renamed): .renamed
    case .case(.copied): .copied
    case .case(.changed): .typeChanged
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
  }

  private static func mapViewedState(
    _ state: GraphQLEnum<ReaderGitHubGraphQL.FileViewedState>
  ) throws -> ReaderFileViewedState {
    switch state {
    case .case(.unviewed): .unviewed
    case .case(.viewed): .viewed
    case .case(.dismissed): .dismissed
    case .unknown: throw PRReaderFailure.contentNotRepresentable
    }
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
    let totalCount: Int
  }
}
