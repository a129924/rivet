public struct HTTPHeaders: Equatable, ExpressibleByDictionaryLiteral, Sendable {
  public let values: [String: String]

  public var accept: String? { value(for: HTTPHeaderName.accept) }
  public var authorization: String? { value(for: HTTPHeaderName.authorization) }
  public var contentType: String? { value(for: HTTPHeaderName.contentType) }
  public var userAgent: String? { value(for: HTTPHeaderName.userAgent) }
  public var etag: String? { value(for: HTTPHeaderName.etag) }
  public var ifNoneMatch: String? { value(for: HTTPHeaderName.ifNoneMatch) }
  public var location: String? { value(for: HTTPHeaderName.location) }
  public var link: String? { value(for: HTTPHeaderName.link) }
  public var retryAfter: String? { value(for: HTTPHeaderName.retryAfter) }

  public init(_ values: [String: String] = [:]) {
    self.init(normalizing: values.sorted { $0.key < $1.key })
  }

  public init(dictionaryLiteral elements: (String, String)...) {
    self.init(normalizing: elements)
  }

  public func value(for name: String) -> String? {
    values[name.lowercased()]
  }

  private init(normalizing elements: [(String, String)]) {
    var values: [String: String] = [:]

    for (name, value) in elements {
      values[name.lowercased()] = value
    }

    self.values = values
  }
}
