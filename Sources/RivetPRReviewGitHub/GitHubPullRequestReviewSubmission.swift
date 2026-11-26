import Foundation
import GitHubIntegration
import RivetHTTPClient

package struct GitHubPullRequestReviewSubmission: Sendable {
  package enum Action: String, Sendable {
    case approve = "APPROVE"
    case requestChanges = "REQUEST_CHANGES"
    case comment = "COMMENT"

    fileprivate var expectedState: State {
      switch self {
      case .approve: .approved
      case .requestChanges: .changesRequested
      case .comment: .commented
      }
    }
  }

  package enum State: String, Decodable, Sendable {
    case approved = "APPROVED"
    case changesRequested = "CHANGES_REQUESTED"
    case commented = "COMMENTED"
  }

  package struct Request: Sendable {
    let owner: String
    let repository: String
    let pullNumber: Int
    let commitSHA: String
    let action: Action
    let body: String?

    package init(
      owner: String, repository: String, pullNumber: Int, commitSHA: String,
      action: Action, body: String? = nil
    ) {
      self.owner = owner
      self.repository = repository
      self.pullNumber = pullNumber
      self.commitSHA = commitSHA
      self.action = action
      self.body = body
    }
  }

  package struct Receipt: Decodable, Equatable, Sendable {
    package let id: Int64
    package let state: State
  }

  package enum Outcome: Equatable, Sendable {
    case accepted(Receipt)
    case acceptedWithoutReceipt
    case notSubmitted
    case authenticationIncomplete
    case rejected(statusCode: Int)
    case needsReconciliation
  }

  private let rest: any GitHubRestClient

  package init(rest: any GitHubRestClient) {
    self.rest = rest
  }

  package func submit(_ input: Request) async -> Outcome {
    guard !Task.isCancelled, Self.isValid(input),
      let request = try? Self.makeRequest(input),
      !Task.isCancelled
    else { return .notSubmitted }

    let response: HTTPResponse
    do {
      response = try await rest.executePost(request)
    } catch let error as GitHubHTTPClientError {
      switch error {
      case .invalidRequest: return .notSubmitted
      case .authenticationRequired, .credentialLifecycle: return .authenticationIncomplete
      case .executionFailed: return .needsReconciliation
      }
    } catch {
      return .needsReconciliation
    }
    return Self.outcome(for: response, action: input.action)
  }

  private static func makeRequest(_ input: Request) throws -> HTTPRequest {
    let url = try GitHubRESTDestination.makeURL(
      path: "/repos/\(input.owner)/\(input.repository)/pulls/\(input.pullNumber)/reviews")
    var headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    headers.contentType = "application/json"
    let body = try JSONEncoder().encode(
      ReviewPayload(event: input.action.rawValue, commitID: input.commitSHA, body: input.body))
    return HTTPRequest(url: url, method: .post, headers: headers, body: body)
  }

  private static func outcome(for response: HTTPResponse, action: Action) -> Outcome {
    switch response.statusCode {
    case 200:
      guard let receipt = try? response.json(Receipt.self, decoder: JSONDecoder()),
        receipt.id > 0, receipt.state == action.expectedState
      else { return .acceptedWithoutReceipt }
      return .accepted(receipt)
    case 401, 403, 404, 422, 429:
      return .rejected(statusCode: response.statusCode)
    default:
      return .needsReconciliation
    }
  }

  private static func isValid(_ input: Request) -> Bool {
    guard isPathComponent(input.owner), isPathComponent(input.repository), input.pullNumber > 0,
      input.commitSHA.utf8.count == 40,
      input.commitSHA.utf8.allSatisfy({ byte in
        (48...57).contains(byte) || (65...70).contains(byte) || (97...102).contains(byte)
      })
    else { return false }

    return input.action == .approve
      || input.body?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  private static func isPathComponent(_ value: String) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && value.utf8.allSatisfy { byte in
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
          || byte == 45 || byte == 46 || byte == 95
      }
  }

}

private struct ReviewPayload: Encodable {
  let event: String
  let commitID: String
  let body: String?

  enum CodingKeys: String, CodingKey {
    case event
    case commitID = "commit_id"
    case body
  }
}
