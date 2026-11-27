import RivetHTTPClient

package struct GitHubNotificationReadMarker: Sendable {
  package enum Outcome: Equatable, Sendable {
    case confirmed
    case notModified
    case accessRejected
    case rateLimited
    case resultUnknown
    case unexpectedResponse(statusCode: Int)
    case invalidThreadID
    case invalidRequest
    case cancelledBeforeSubmission
  }

  private let httpClient: HTTPClient

  package init() {
    self.init(httpClient: GitHubHTTPClient.makeHTTPClient())
  }

  internal init(httpClient: HTTPClient) {
    self.httpClient = httpClient
  }

  /// The caller supplies the thread ID and classic PAT for the same account.
  package func markAsRead(threadID: String, using token: PersonalAccessToken) async -> Outcome {
    guard !Task.isCancelled else { return .cancelledBeforeSubmission }
    guard let endpoint = try? GitHubNotificationMarkAsReadEndpoint(threadID: threadID) else {
      return .invalidThreadID
    }

    let request: HTTPRequest
    do {
      let url = try endpoint.makeURL()
      let headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
      let original = HTTPRequest(url: url, method: endpoint.method, headers: headers)
      request = try BearerAuth(token: token.rawValue).applying(to: original)
    } catch {
      return .invalidRequest
    }

    guard !Task.isCancelled else { return .cancelledBeforeSubmission }
    do {
      let response = try await httpClient.execute(request)
      return outcome(for: response)
    } catch {
      // A submitted write can take effect even when the response never arrives.
      return .resultUnknown
    }
  }

  private func outcome(for response: HTTPResponse) -> Outcome {
    switch response.statusCode {
    case 205: .confirmed
    case 304: .notModified
    case 401: .accessRejected
    case 403:
      GitHubResponseClassifier().classifyFailure(response) == .rateLimited
        ? .rateLimited : .accessRejected
    case 429: .rateLimited
    case 500...599: .resultUnknown
    default: .unexpectedResponse(statusCode: response.statusCode)
    }
  }
}
