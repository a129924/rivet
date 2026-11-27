import RivetHTTPClient

internal struct GitHubNotificationMarkAsReadEndpoint: Sendable {
  internal enum ValidationError: Error {
    case invalidThreadID
  }

  private let threadID: String

  internal var method: HTTPMethod { .patch }

  internal init(threadID: String) throws(ValidationError) {
    let zero = UInt8(ascii: "0")
    let digits = zero...UInt8(ascii: "9")
    guard
      threadID.utf8.allSatisfy(digits.contains),
      threadID.utf8.contains(where: { $0 != zero })
    else {
      throw .invalidThreadID
    }
    self.threadID = threadID
  }

  internal func makeURL() throws -> HTTPURL {
    try GitHubRESTDestination.makeURL(path: "/notifications/threads/\(threadID)")
  }
}
