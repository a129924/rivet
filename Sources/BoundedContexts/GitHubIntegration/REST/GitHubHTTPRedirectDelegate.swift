import Foundation

internal protocol RedirectPolicy: Sendable {
  func allows(_ proposedRequest: URLRequest, from response: HTTPURLResponse) -> Bool
}

internal struct DefaultGitHubRESTRedirectPolicy: RedirectPolicy {
  func allows(_ proposedRequest: URLRequest, from response: HTTPURLResponse) -> Bool {
    false
  }
}

internal final class GitHubHTTPRedirectDelegate: NSObject, URLSessionTaskDelegate, Sendable {
  private let policy: any RedirectPolicy

  internal init(policy: any RedirectPolicy) {
    self.policy = policy
  }

  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    completionHandler(policy.allows(request, from: response) ? request : nil)
  }
}
