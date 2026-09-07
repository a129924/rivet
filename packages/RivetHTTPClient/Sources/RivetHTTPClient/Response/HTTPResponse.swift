import Foundation

public struct HTTPResponse: Equatable, Sendable {
  public let statusCode: Int
  public let headers: HTTPHeaders
  public let body: Data

  public init(statusCode: Int, headers: HTTPHeaders, body: Data) {
    self.statusCode = statusCode
    self.headers = headers
    self.body = body
  }

  public func text(encoding: String.Encoding = .utf8) -> String? {
    String(data: body, encoding: encoding)
  }

  public func json<T: Decodable>(_ type: T.Type, decoder: JSONDecoder) throws -> T {
    try decoder.decode(type, from: body)
  }
}
