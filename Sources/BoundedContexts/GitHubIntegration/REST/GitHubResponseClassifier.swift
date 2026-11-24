import Foundation
import RivetHTTPClient

package enum GitHubAPIFailure: Error, Sendable, Equatable {
  case unauthorized
  case forbidden
  case unclassifiedForbidden
  case notFound
  case rateLimited
  case serverError(statusCode: Int)
  case unexpectedStatus(statusCode: Int)
}

package struct GitHubResponseClassifier: Sendable {
  package init() {}

  package func classifyFailure(_ response: HTTPResponse) -> GitHubAPIFailure {
    switch response.statusCode {
    case 401: .unauthorized
    case 403: classifyForbidden(response)
    case 404: .notFound
    case 429: .rateLimited
    case 500...599: .serverError(statusCode: response.statusCode)
    default: .unexpectedStatus(statusCode: response.statusCode)
    }
  }

  private func classifyForbidden(_ response: HTTPResponse) -> GitHubAPIFailure {
    let message = (try? response.json(ErrorMessage.self, decoder: JSONDecoder()))?.message ?? ""
    let sentences = message.split(separator: /[\r\n]+|\.(?=\s|$)/).map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    let permissionDenied =
      sentences.contains("resource not accessible by integration")
      || sentences.contains("resource not accessible by personal access token")
    let secondaryRateLimited =
      sentences.contains("you have exceeded a secondary rate limit")
      || sentences.contains(
        "you have exceeded a secondary rate limit and have been temporarily blocked from content creation"
      )

    switch (permissionDenied, secondaryRateLimited) {
    case (true, true):
      return .unclassifiedForbidden
    case (true, false):
      return .forbidden
    case (false, true):
      return .rateLimited
    case (false, false):
      guard
        let remaining = response.headers.value(for: "X-RateLimit-Remaining")?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        remaining.utf8.allSatisfy({ (48...57).contains($0) }),
        Int(remaining) == 0
      else { return .unclassifiedForbidden }
      return .rateLimited
    }
  }

  private struct ErrorMessage: Decodable, Sendable {
    let message: String
  }
}
