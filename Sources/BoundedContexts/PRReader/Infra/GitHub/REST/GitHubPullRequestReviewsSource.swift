import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

package struct GitHubPullRequestReviewsSource: Sendable {
  private let client: any GitHubRestClient

  package init(client: any GitHubRestClient) {
    self.client = client
  }

  package func fetchReviews(
    for id: ReaderPullRequestID
  ) async -> Outcome<[ReaderReview], PRReaderFailure> {
    do {
      let reviews = try await readReviews(for: id)
      return Task.isCancelled ? .failure(.unavailable) : .success(reviews)
    } catch {
      return .failure(Task.isCancelled ? .unavailable : error)
    }
  }

  private func readReviews(
    for id: ReaderPullRequestID
  ) async throws(PRReaderFailure) -> [ReaderReview] {
    guard !Task.isCancelled else { throw .unavailable }
    let endpoint = GitHubPullRequestReviewsEndpoint(id: id)
    var page = 1
    var reviews: [ReaderReview] = []
    var repositoryID: Int?

    while true {
      guard let url = try? endpoint.makeURL(page: page)
      else { throw page == 1 ? .notReadable : .unavailable }
      let response = try await getReviewsPage(url, isFirstPage: page == 1)
      guard let entries = try? response.json([ReviewRecord].self, decoder: JSONDecoder())
      else { throw .contentNotRepresentable }

      for entry in entries {
        reviews.append(try entry.makeReview())
      }

      let links = try GitHubPullRequestPageLinks(
        header: response.headers.link, id: id, route: .reviews)
      try links.checkPage(current: page)
      if let candidateID = links.next?.repositoryID, repositoryID == nil {
        repositoryID = try await verifyDetails(for: id, matching: candidateID)
      }
      try links.checkRepositoryID(repositoryID)
      guard let next = links.next else { return reviews }
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

  private func getReviewsPage(
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

private struct ReviewRecord: Decodable {
  struct User: Decodable {
    let login: String
  }

  enum State: String, Decodable {
    case approved = "APPROVED"
    case changesRequested = "CHANGES_REQUESTED"
    case commented = "COMMENTED"
    case dismissed = "DISMISSED"
    case pending = "PENDING"

    var reviewState: ReviewState {
      switch self {
      case .approved: .approved
      case .changesRequested: .changesRequested
      case .commented: .commented
      case .dismissed: .dismissed
      case .pending: .pending
      }
    }
  }

  let id: Int64
  let body: String
  let user: User?
  let state: State

  func makeReview() throws(PRReaderFailure) -> ReaderReview {
    guard id > 0, user?.login.isEmpty != true else { throw .contentNotRepresentable }
    return ReaderReview(id: String(id), body: body, author: user?.login, state: state.reviewState)
  }
}
