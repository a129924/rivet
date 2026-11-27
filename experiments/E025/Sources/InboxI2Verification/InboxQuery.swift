import GitHubIntegration
import RivetHTTPClient
import RivetPRInbox
import RivetPRInboxGitHub

protocol InboxReadOnlyREST: GitHubRestClient {}

extension InboxReadOnlyREST {
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw InboxRESTError.unexpectedRequest
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw InboxRESTError.unexpectedRequest
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw InboxRESTError.unexpectedRequest
  }
}

enum InboxRESTError: Error {
  case unexpectedRequest
}

func loadInbox(using rest: any GitHubRestClient) async -> InboxLoadResult {
  let facade = PRInboxFacade(selfReviewSource: GitHubSelfReviewSource(rest: rest))
  return switch await facade.refresh() {
  case .success(let items): .success(items)
  case .failure: .unavailable
  }
}
