import Foundation

public struct HTTPRequest: Equatable, Sendable {
  public let url: HTTPURL
  public let method: HTTPMethod
  public let headers: HTTPHeaders
  public let body: Data?

  public init(
    url: HTTPURL,
    method: HTTPMethod,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) {
    self.url = url
    self.method = method
    self.headers = headers
    self.body = body
  }
}
