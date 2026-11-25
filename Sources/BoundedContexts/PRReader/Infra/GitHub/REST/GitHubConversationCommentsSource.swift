import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

package struct GitHubConversationCommentsSource: Sendable {
  private let client: any GitHubRestClient

  package init(client: any GitHubRestClient) {
    self.client = client
  }

  package func fetchConversationComments(
    for id: ReaderPullRequestID
  ) async -> Outcome<[ReaderComment], PRReaderFailure> {
    do {
      let comments = try await readComments(for: id)
      return Task.isCancelled ? .failure(.unavailable) : .success(comments)
    } catch {
      return .failure(Task.isCancelled ? .unavailable : error)
    }
  }

  private func readComments(
    for id: ReaderPullRequestID
  ) async throws(PRReaderFailure) -> [ReaderComment] {
    guard !Task.isCancelled else { throw .unavailable }
    let endpoint = GitHubConversationCommentsEndpoint(id: id)
    var page = 1
    var comments: [ReaderComment] = []
    var repositoryID: Int?

    while true {
      guard let url = try? endpoint.makeURL(page: page)
      else { throw page == 1 ? .notReadable : .unavailable }
      let response = try await getCommentsPage(url, isFirstPage: page == 1)
      guard let entries = try? response.json([IssueComment].self, decoder: JSONDecoder())
      else { throw .contentNotRepresentable }

      for entry in entries {
        guard entry.id > 0, entry.user?.login.isEmpty != true else {
          throw .contentNotRepresentable
        }
        comments.append(
          ReaderComment(id: String(entry.id), body: entry.body, author: entry.user?.login))
      }

      let links = try GitHubPullRequestPageLinks(
        header: response.headers.link, id: id, route: .conversationComments)
      try links.checkPage(current: page)
      if let candidateID = links.next?.repositoryID, repositoryID == nil {
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
      throw Task.isCancelled ? .unavailable : .notReadable
    } catch GitHubHTTPClientError.invalidRequest {
      throw isFirstPage && !Task.isCancelled ? .notReadable : .unavailable
    } catch {
      throw .unavailable
    }

    guard response.statusCode != 200 else { return response }
    switch GitHubResponseClassifier().classifyFailure(response) {
    case .unauthorized, .notFound, .forbidden, .unclassifiedForbidden,
      .unexpectedStatus(statusCode: 410):
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

private struct IssueComment: Decodable, Sendable {
  struct User: Decodable, Sendable {
    let login: String
  }

  let id: Int64
  let body: String
  let user: User?
}
