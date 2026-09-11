public struct HTTPHeaders: Equatable, ExpressibleByDictionaryLiteral, Sendable {
  public private(set) var values: [String: String]

  public var accept: String? {
    get { self[.accept] }
    set { self[.accept] = newValue }
  }

  public var authorization: String? {
    get { self[.authorization] }
    set { self[.authorization] = newValue }
  }

  public var contentType: String? {
    get { self[.contentType] }
    set { self[.contentType] = newValue }
  }

  public var userAgent: String? {
    get { self[.userAgent] }
    set { self[.userAgent] = newValue }
  }

  public var etag: String? {
    get { self[.etag] }
    set { self[.etag] = newValue }
  }

  public var ifNoneMatch: String? {
    get { self[.ifNoneMatch] }
    set { self[.ifNoneMatch] = newValue }
  }

  public var location: String? {
    get { self[.location] }
    set { self[.location] = newValue }
  }

  public var link: String? {
    get { self[.link] }
    set { self[.link] = newValue }
  }

  public var retryAfter: String? {
    get { self[.retryAfter] }
    set { self[.retryAfter] = newValue }
  }

  public init(_ values: [String: String] = [:]) {
    self.init(normalizing: values.sorted { $0.key < $1.key })
  }

  public init(dictionaryLiteral elements: (HTTPHeaderName, String)...) {
    self.init(normalizing: elements)
  }

  public func value(for name: HTTPHeaderName) -> String? {
    self[name]
  }

  public func value(for name: String) -> String? {
    values[name.lowercased()]
  }

  public subscript(_ name: HTTPHeaderName) -> String? {
    get { values[name.rawValue] }
    set { values[name.rawValue] = newValue }
  }

  private init(normalizing elements: [(String, String)]) {
    var values: [String: String] = [:]

    for (name, value) in elements {
      values[name.lowercased()] = value
    }

    self.values = values
  }

  private init(normalizing elements: [(HTTPHeaderName, String)]) {
    var values: [String: String] = [:]

    for (name, value) in elements {
      values[name.rawValue] = value
    }

    self.values = values
  }
}
