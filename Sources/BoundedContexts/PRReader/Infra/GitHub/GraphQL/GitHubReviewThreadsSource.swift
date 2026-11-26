import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration
import RivetPRReader

package struct GitHubReviewThreadsSource: Sendable {
  private typealias ThreadPage =
    ReaderGitHubGraphQL.ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads
  private typealias ThreadNode = ThreadPage.Node
  private typealias CommentFields = ReaderGitHubGraphQL.ReviewThreadCommentFields

  private let client: any GitHubGraphQLServing

  package init(client: any GitHubGraphQLServing) {
    self.client = client
  }

  package func fetchReviewThreads(
    for id: ReaderPullRequestID
  ) async -> Outcome<[ReaderReviewThread], PRReaderFailure> {
    do {
      try Task.checkCancellation()
      guard let number = Int32(exactly: id.number),
        (try? GitHubPullRequestDetailEndpoint.validateIdentity(id)) != nil
      else { throw PRReaderFailure.notReadable }

      let threads = try await readThreads(for: id, number: number)
      return Task.isCancelled ? .failure(.unavailable) : .success(threads)
    } catch let failure as PRReaderFailure {
      return .failure(Task.isCancelled ? .unavailable : failure)
    } catch let error as GitHubGraphQLClientError {
      let denied = error == .authenticationRequired || error == .httpStatus(401)
      return .failure(denied && !Task.isCancelled ? .notReadable : .unavailable)
    } catch {
      return .failure(.unavailable)
    }
  }

  private func readThreads(
    for id: ReaderPullRequestID, number: Int32
  ) async throws -> [ReaderReviewThread] {
    var identity: PullRequestIdentity?
    var cursor: String?
    var seenCursors: Set<String> = []
    var threadIDs: Set<String> = []
    var commentIDs: Set<String> = []
    var threads: [ReaderReviewThread] = []

    repeat {
      let (page, current) = try await readThreadPage(
        for: id, number: number, after: cursor, identity: identity)
      identity = current

      guard let nodes = page.nodes else { throw PRReaderFailure.contentNotRepresentable }
      cursor = try Self.continuation(
        hasNextPage: page.pageInfo.hasNextPage, endCursor: page.pageInfo.endCursor,
        hasNodes: !nodes.isEmpty, seen: &seenCursors)

      for candidate in nodes {
        guard let node = candidate else { throw PRReaderFailure.contentNotRepresentable }
        try Self.requireValue(node.id)
        try Self.requireValue(node.path)
        guard node.pullRequest.id == current.pullRequestID, threadIDs.insert(node.id).inserted
        else {
          throw PRReaderFailure.unavailable
        }
        let subject: ReaderReviewThread.Subject
        switch node.subjectType {
        case .case(.file): subject = .file
        case .case(.line): subject = .line
        case .unknown: throw PRReaderFailure.contentNotRepresentable
        }
        let comments = try await readComments(
          for: node, prID: current.pullRequestID, seen: &commentIDs)
        threads.append(
          ReaderReviewThread(
            id: node.id, path: node.path, subject: subject, line: node.line,
            startLine: node.startLine,
            originalLine: node.originalLine, originalStartLine: node.originalStartLine,
            isResolved: node.isResolved, isOutdated: node.isOutdated, comments: comments))
      }
    } while cursor != nil

    return threads
  }

  private func readThreadPage(
    for id: ReaderPullRequestID, number: Int32, after: String?, identity: PullRequestIdentity?
  ) async throws -> (ThreadPage, PullRequestIdentity) {
    let requestedRepository = "\(id.owner)/\(id.repository)"
    let response = try await fetch(
      ReaderGitHubGraphQL.ReviewThreadsQuery(
        owner: id.owner, name: id.repository, number: number,
        after: after.map { .some($0) } ?? .none))
    if let errors = response.errors, !errors.isEmpty {
      throw errors.allSatisfy(Self.confirmsPullRequestUnavailable)
        ? PRReaderFailure.notReadable : PRReaderFailure.unavailable
    }
    guard let data = response.data else { throw PRReaderFailure.unavailable }
    guard let repository = data.repository else { throw PRReaderFailure.notReadable }
    try Self.requireValue(repository.id)
    guard repository.nameWithOwner.caseInsensitiveCompare(requestedRepository) == .orderedSame,
      identity == nil || identity?.repositoryID == repository.id
    else { throw PRReaderFailure.unavailable }
    guard let pullRequest = repository.pullRequest else { throw PRReaderFailure.notReadable }
    try Self.requireValue(pullRequest.id)
    guard pullRequest.number == id.number, pullRequest.repository.id == repository.id else {
      throw PRReaderFailure.unavailable
    }
    let current = PullRequestIdentity(repositoryID: repository.id, pullRequestID: pullRequest.id)
    if let identity, identity != current { throw PRReaderFailure.unavailable }
    return (pullRequest.reviewThreads, current)
  }

  private func readComments(
    for thread: ThreadNode, prID: String, seen: inout Set<String>
  ) async throws -> [ReaderReviewThread.Comment] {
    let initial = thread.comments
    var comments: [ReaderReviewThread.Comment] = []
    var cursors: Set<String> = []
    try Self.appendComments(
      initial.nodes?.map { $0?.fragments.reviewThreadCommentFields }, prID: prID,
      seen: &seen, into: &comments)
    var cursor = try Self.continuation(
      hasNextPage: initial.pageInfo.hasNextPage, endCursor: initial.pageInfo.endCursor,
      hasNodes: !comments.isEmpty, seen: &cursors)

    while let after = cursor {
      let response = try await fetch(
        ReaderGitHubGraphQL.ReviewThreadCommentsQuery(threadID: thread.id, after: after))
      guard response.errors?.isEmpty != false,
        let node = response.data?.node?.asPullRequestReviewThread,
        node.id == thread.id, node.pullRequest.id == prID
      else { throw PRReaderFailure.unavailable }
      let page = node.comments
      try Self.appendComments(
        page.nodes?.map { $0?.fragments.reviewThreadCommentFields }, prID: prID,
        seen: &seen, into: &comments)
      cursor = try Self.continuation(
        hasNextPage: page.pageInfo.hasNextPage, endCursor: page.pageInfo.endCursor,
        hasNodes: page.nodes?.isEmpty == false, seen: &cursors)
    }
    return comments
  }

  private func fetch<Query: GraphQLQuery>(_ query: Query) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat {
    try Task.checkCancellation()
    let response = try await client.fetch(query: query)
    try Task.checkCancellation()
    return response
  }

  private static func appendComments(
    _ fields: [CommentFields?]?, prID: String, seen: inout Set<String>,
    into comments: inout [ReaderReviewThread.Comment]
  ) throws {
    guard let fields else { throw PRReaderFailure.contentNotRepresentable }
    for field in fields {
      guard let field else { throw PRReaderFailure.contentNotRepresentable }
      try requireValue(field.id)
      let replyToID = field.replyTo?.id
      if let replyToID { try requireValue(replyToID) }
      guard field.pullRequest.id == prID, seen.insert(field.id).inserted else {
        throw PRReaderFailure.unavailable
      }
      comments.append(
        .init(id: field.id, body: field.body, author: field.author?.login, replyToID: replyToID))
    }
  }

  private static func continuation(
    hasNextPage: Bool, endCursor: String?, hasNodes: Bool, seen: inout Set<String>
  ) throws -> String? {
    guard hasNextPage else { return nil }
    guard hasNodes, let endCursor, !isBlank(endCursor), seen.insert(endCursor).inserted else {
      throw PRReaderFailure.unavailable
    }
    return endCursor
  }

  private static func requireValue(_ value: String) throws {
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

  private struct PullRequestIdentity: Equatable {
    let repositoryID: String
    let pullRequestID: String
  }
}
