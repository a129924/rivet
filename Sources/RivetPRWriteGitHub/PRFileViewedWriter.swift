import Apollo
import ApolloAPI
import Foundation
import GitHubIntegration

package struct PRFileViewedWriter: Sendable {
  package enum Action: Sendable {
    case mark
    case unmark
  }

  package struct Request: Sendable {
    package let pullRequestID: String
    package let path: String
    package let action: Action

    package init(pullRequestID: String, path: String, action: Action) {
      self.pullRequestID = pullRequestID
      self.path = path
      self.action = action
    }
  }

  package enum Outcome: Sendable, Equatable {
    case confirmed(pullRequestID: String)
    case invalidInput
    case cancelledBeforeSubmission
    case rejected(Rejection)
    case needsVerification
  }

  package enum Rejection: Sendable, Equatable {
    case authenticationRequired
    case forbidden
    case notFound
  }

  private static let invalidIDCharacters = CharacterSet.whitespacesAndNewlines.union(
    .controlCharacters)
  private let client: any GitHubGraphQLServing

  package init(client: any GitHubGraphQLServing) {
    self.client = client
  }

  package func setViewed(_ request: Request) async -> Outcome {
    guard !request.pullRequestID.isEmpty,
      !request.pullRequestID.unicodeScalars.contains(where: Self.invalidIDCharacters.contains),
      !request.path.isEmpty, !request.path.utf8.contains(0)
    else { return .invalidInput }
    guard !Task.isCancelled else { return .cancelledBeforeSubmission }

    do {
      switch request.action {
      case .mark:
        let response = try await client.perform(
          mutation: PRWriteGitHubGraphQL.MarkPullRequestFileAsViewedMutation(
            pullRequestId: request.pullRequestID, path: request.path))
        let payload = response.data?.markFileAsViewed
        return Self.outcome(
          response,
          hasPayload: payload != nil, receivedID: payload?.pullRequest?.id,
          requestedID: request.pullRequestID, field: "markFileAsViewed")
      case .unmark:
        let response = try await client.perform(
          mutation: PRWriteGitHubGraphQL.UnmarkPullRequestFileAsViewedMutation(
            pullRequestId: request.pullRequestID, path: request.path))
        let payload = response.data?.unmarkFileAsViewed
        return Self.outcome(
          response,
          hasPayload: payload != nil, receivedID: payload?.pullRequest?.id,
          requestedID: request.pullRequestID, field: "unmarkFileAsViewed")
      }
    } catch let error as GitHubGraphQLClientError {
      switch error {
      case .authenticationRequired, .invalidAuthorizationToken, .httpStatus(401):
        return .rejected(.authenticationRequired)
      default:
        return .needsVerification
      }
    } catch {
      return .needsVerification
    }
  }

  private static func outcome<Operation: GraphQLOperation>(
    _ response: GraphQLResponse<Operation>, hasPayload: Bool,
    receivedID: String?, requestedID: String, field: String
  ) -> Outcome {
    guard response.source == .server else { return .needsVerification }

    let errors = response.errors ?? []
    let receiptPath: [PathComponent] = [.field(field), .field("pullRequest"), .field("id")]
    let receiptUncontested = errors.allSatisfy { isUnrelated($0, to: receiptPath) }
    if let receivedID, receivedID.utf8.elementsEqual(requestedID.utf8), receiptUncontested {
      return .confirmed(pullRequestID: receivedID)
    }
    guard !hasPayload, let firstError = errors.first,
      let rejection = rejection(for: firstError, field: field),
      errors.dropFirst().allSatisfy({ Self.rejection(for: $0, field: field) == rejection })
    else { return .needsVerification }

    return .rejected(rejection)
  }

  private static func isUnrelated(_ error: GraphQLError, to receiptPath: [PathComponent]) -> Bool {
    guard let rawPath = error["path"] as? [Any], let path = error.path,
      path.count == rawPath.count, case .some(.field) = path.first
    else { return false }
    return !path.starts(with: receiptPath) && !receiptPath.starts(with: path)
  }

  private static func rejection(for error: GraphQLError, field: String) -> Rejection? {
    let types = [error["type"], error.extensions?["type"]].compactMap { $0 }
    guard error["path"] as? [String] == [field],
      let type = types.first as? String, types.allSatisfy({ ($0 as? String) == type })
    else { return nil }
    switch type {
    case "FORBIDDEN": return .forbidden
    case "UNAUTHORIZED": return .authenticationRequired
    case "NOT_FOUND": return .notFound
    default: return nil
    }
  }
}
