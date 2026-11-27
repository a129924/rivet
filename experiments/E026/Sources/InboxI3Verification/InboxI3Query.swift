import Foundation
import GitHubIntegration
import InboxExperimentSupport
import RivetHTTPClient
import RivetPRInbox
import RivetPRInboxGitHub
import RivetPresentation

protocol InboxI3ReadOnlyREST: GitHubRestClient {}

extension InboxI3ReadOnlyREST {
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw InboxI3RESTError.unexpectedRequest
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw InboxI3RESTError.unexpectedRequest
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw InboxI3RESTError.unexpectedRequest
  }
}

enum InboxI3RESTError: Error {
  case unexpectedRequest
}

struct InboxI3Identity: Hashable, Sendable {
  let owner: String
  let repository: String
  let number: Int

  var id: String { "\(owner)/\(repository)#\(number)" }
  var repositoryLabel: String { "\(owner)/\(repository)" }
}

func loadInboxI3(
  using rest: any InboxI3ReadOnlyREST, referenceDate: Date
) async -> InboxExperimentSession.LoadResult {
  let observed = InboxUpdateTimeREST(rest: rest)
  let facade = PRInboxFacade(selfReviewSource: GitHubSelfReviewSource(rest: observed))
  guard case .success(let items) = await facade.refresh(), !Task.isCancelled else {
    return .unavailable
  }
  let dates = await observed.dates
  let formatter = RelativeDateTimeFormatter()
  formatter.locale = Locale(identifier: "zh-Hant-TW")
  return .success(
    items.map { item in
      let identity = InboxI3Identity(
        owner: item.owner, repository: item.repository, number: item.number)
      let label = dates[identity].map {
        formatter.localizedString(for: $0, relativeTo: referenceDate)
          .replacingOccurrences(of: #"(?<=\d)(?=\p{Han})"#, with: " ", options: .regularExpression)
      }
      return PullRequestRowPresentation(
        id: identity.id, title: item.title, repositoryLabel: identity.repositoryLabel,
        numberLabel: "#\(identity.number)", relativeTimeLabel: label)
    })
}
