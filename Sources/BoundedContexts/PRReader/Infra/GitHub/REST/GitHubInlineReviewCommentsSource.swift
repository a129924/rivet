import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

package struct GitHubInlineReviewCommentsSource: Sendable {
  private let client: any GitHubRestClient

  package init(client: any GitHubRestClient) {
    self.client = client
  }

  package func fetchInlineReviewComments(
    for id: ReaderPullRequestID
  ) async -> Outcome<[ReaderInlineReviewComment], PRReaderFailure> {
    do {
      let comments = try await readComments(for: id)
      return Task.isCancelled ? .failure(.unavailable) : .success(comments)
    } catch {
      return .failure(Task.isCancelled ? .unavailable : error)
    }
  }

  private func readComments(
    for id: ReaderPullRequestID
  ) async throws(PRReaderFailure) -> [ReaderInlineReviewComment] {
    guard !Task.isCancelled else { throw .unavailable }
    let endpoint = GitHubInlineReviewCommentsEndpoint(id: id)
    var page = 1
    var comments: [ReaderInlineReviewComment] = []
    var repositoryID: Int?

    while true {
      guard let url = try? endpoint.makeURL(page: page)
      else { throw page == 1 ? .notReadable : .unavailable }
      let response = try await getCommentsPage(url, isFirstPage: page == 1)
      guard
        let records = try? response.json([InlineReviewCommentRecord].self, decoder: JSONDecoder())
      else { throw .contentNotRepresentable }
      for record in records {
        comments.append(try ReaderInlineReviewComment(record: record, sourcePage: page))
      }

      let links = try GitHubPullRequestPageLinks(
        header: response.headers.link, id: id, route: .inlineReviewComments)
      try links.checkPage(current: page)
      let candidateID = links.next?.repositoryID ?? links.last?.repositoryID
      if repositoryID == nil, let candidateID {
        try links.checkRepositoryID(candidateID)
        repositoryID = try await verifyDetails(for: id, matching: candidateID)
      }
      try links.checkRepositoryID(repositoryID)
      guard let next = links.next else { return comments }
      page = next.page
    }
  }

  private func request(_ url: HTTPURL) async throws -> HTTPResponse {
    try Task.checkCancellation()
    let headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    let response = try await client.get(url: url, headers: headers, body: nil)
    try Task.checkCancellation()
    return response
  }

  private func getCommentsPage(
    _ url: HTTPURL, isFirstPage: Bool
  ) async throws(PRReaderFailure) -> HTTPResponse {
    let response: HTTPResponse
    do {
      response = try await request(url)
    } catch GitHubHTTPClientError.authenticationRequired {
      throw .notReadable
    } catch GitHubHTTPClientError.invalidRequest {
      throw isFirstPage ? .notReadable : .unavailable
    } catch {
      throw .unavailable
    }

    guard response.statusCode != 200 else { return response }
    if response.statusCode == 410 { throw .notReadable }
    switch GitHubResponseClassifier().classifyFailure(response) {
    case .unauthorized, .notFound, .forbidden, .unclassifiedForbidden:
      throw .notReadable
    case .rateLimited, .serverError, .unexpectedStatus:
      throw .unavailable
    }
  }

  private func verifyDetails(
    for id: ReaderPullRequestID, matching candidateID: Int
  ) async throws(PRReaderFailure) -> Int {
    guard
      let url = try? GitHubPullRequestDetailEndpoint(id: id).makeURL(),
      let response = try? await request(url),
      response.statusCode == 200,
      let repositoryID = GitHubPullRequestRepositoryIdentity.verifiedRepositoryID(
        in: response, for: id, matching: candidateID)
    else { throw .unavailable }
    return repositoryID
  }
}

package struct ReaderInlineReviewComment: Equatable, Sendable {
  package let sourcePage: Int
  package let id: Int64
  package let nodeID: String
  package let body: String
  package let path: String
  package let diffHunk: String?
  package let position: Int?
  package let originalPosition: Int?
  package let line: Int?
  package let originalLine: Int?
  package let startLine: Int?
  package let originalStartLine: Int?
  package let side: String?
  package let startSide: String?
  package let commitID: String?
  package let originalCommitID: String?
  package let subjectType: String?
  package let inReplyToID: Int64?
  package let pullRequestReviewID: Int64?

  fileprivate init(record: InlineReviewCommentRecord, sourcePage: Int) throws(PRReaderFailure) {
    guard record.id > 0, !record.nodeID.isEmpty, !record.path.isEmpty
    else { throw .contentNotRepresentable }
    self.sourcePage = sourcePage
    id = record.id
    nodeID = record.nodeID
    body = record.body
    path = record.path
    diffHunk = record.diffHunk
    position = record.position
    originalPosition = record.originalPosition
    line = record.line
    originalLine = record.originalLine
    startLine = record.startLine
    originalStartLine = record.originalStartLine
    side = record.side
    startSide = record.startSide
    commitID = record.commitID
    originalCommitID = record.originalCommitID
    subjectType = record.subjectType
    inReplyToID = record.inReplyToID
    pullRequestReviewID = record.pullRequestReviewID
  }
}

private struct InlineReviewCommentRecord: Decodable {
  let id: Int64
  let nodeID: String
  let body: String
  let path: String
  let diffHunk: String?
  let position: Int?
  let originalPosition: Int?
  let line: Int?
  let originalLine: Int?
  let startLine: Int?
  let originalStartLine: Int?
  let side: String?
  let startSide: String?
  let commitID: String?
  let originalCommitID: String?
  let subjectType: String?
  let inReplyToID: Int64?
  let pullRequestReviewID: Int64?

  enum CodingKeys: String, CodingKey {
    case id
    case nodeID = "node_id"
    case body
    case path
    case diffHunk = "diff_hunk"
    case position
    case originalPosition = "original_position"
    case line
    case originalLine = "original_line"
    case startLine = "start_line"
    case originalStartLine = "original_start_line"
    case side
    case startSide = "start_side"
    case commitID = "commit_id"
    case originalCommitID = "original_commit_id"
    case subjectType = "subject_type"
    case inReplyToID = "in_reply_to_id"
    case pullRequestReviewID = "pull_request_review_id"
  }
}
