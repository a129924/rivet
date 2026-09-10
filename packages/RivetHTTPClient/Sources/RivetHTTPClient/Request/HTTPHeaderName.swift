public struct HTTPHeaderName: Hashable, Sendable {
  public let rawValue: String

  public static let accept = Self("accept")
  public static let authorization = Self("authorization")
  public static let contentType = Self("content-type")
  public static let userAgent = Self("user-agent")
  public static let etag = Self("etag")
  public static let ifNoneMatch = Self("if-none-match")
  public static let location = Self("location")
  public static let link = Self("link")
  public static let retryAfter = Self("retry-after")

  public static func custom(_ name: String) -> Self {
    Self(name)
  }

  private init(_ rawValue: String) {
    self.rawValue = rawValue.lowercased()
  }
}
