import Foundation

public struct HTTPClient: Sendable {
  private let requester: Requester
  private let configuration: Configuration

  public struct Configuration: Equatable, Sendable {
    public let baseURL: URL?
    public let timeout: TimeInterval
    public let defaultHeaders: HTTPHeaders

    public init(
      baseURL: URL? = nil,
      timeout: TimeInterval = 60,
      defaultHeaders: HTTPHeaders = HTTPHeaders()
    ) throws(HTTPURLValidationError) {
      guard timeout.isFinite, timeout > 0 else {
        throw .invalidTimeout
      }

      if let baseURL {
        try Self.validate(baseURL: baseURL)
      }

      self.baseURL = baseURL
      self.timeout = timeout
      self.defaultHeaders = defaultHeaders
    }

    fileprivate static let `default` = Configuration(
      uncheckedBaseURL: nil,
      timeout: 60,
      defaultHeaders: HTTPHeaders()
    )

    private init(
      uncheckedBaseURL baseURL: URL?,
      timeout: TimeInterval,
      defaultHeaders: HTTPHeaders
    ) {
      self.baseURL = baseURL
      self.timeout = timeout
      self.defaultHeaders = defaultHeaders
    }

    private static func validate(baseURL: URL) throws(HTTPURLValidationError) {
      _ = try HTTPURL(baseURL)

      guard let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
        throw .baseURLHasDotSegment
      }
      if components.percentEncodedQuery != nil {
        throw .baseURLHasQuery
      }
      if components.percentEncodedFragment != nil {
        throw .baseURLHasFragment
      }
      if HTTPClient.containsDotSegment(in: components.percentEncodedPath) {
        throw .baseURLHasDotSegment
      }
    }
  }

  public init() {
    self.init(configuration: Configuration.default)
  }

  public init(configuration: Configuration) {
    self.init(configuration: configuration, transport: URLSessionTransport())
  }

  public init(transport: any Transport) {
    self.init(configuration: Configuration.default, transport: transport)
  }

  public init(configuration: Configuration, transport: any Transport) {
    self.configuration = configuration
    requester = Requester(transport: transport)
  }

  public func execute(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
    try await requester.execute(
      HTTPRequest(
        url: request.url,
        method: request.method,
        headers: mergedHeaders(with: request.headers),
        body: request.body
      ),
      timeout: configuration.timeout
    )
  }

  public func request(
    method: HTTPMethod,
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await execute(HTTPRequest(url: url, method: method, headers: headers, body: body))
  }

  public func request(
    method: HTTPMethod,
    url: URL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: method, url: HTTPURL(url), headers: headers, body: body)
  }

  public func request(
    method: HTTPMethod,
    path: String,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(
      method: method,
      url: HTTPURL(try resolvedURL(for: path)),
      headers: headers,
      body: body
    )
  }

  public func get(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .get, url: url, headers: headers, body: body)
  }

  public func get(
    url: URL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .get, url: url, headers: headers, body: body)
  }

  public func get(
    path: String,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .get, path: path, headers: headers, body: body)
  }

  public func post(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .post, url: url, headers: headers, body: body)
  }

  public func post(
    url: URL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .post, url: url, headers: headers, body: body)
  }

  public func post(
    path: String,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .post, path: path, headers: headers, body: body)
  }

  public func put(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .put, url: url, headers: headers, body: body)
  }

  public func put(
    url: URL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .put, url: url, headers: headers, body: body)
  }

  public func put(
    path: String,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .put, path: path, headers: headers, body: body)
  }

  public func patch(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .patch, url: url, headers: headers, body: body)
  }

  public func patch(
    url: URL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .patch, url: url, headers: headers, body: body)
  }

  public func patch(
    path: String,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .patch, path: path, headers: headers, body: body)
  }

  public func delete(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .delete, url: url, headers: headers, body: body)
  }

  public func delete(
    url: URL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .delete, url: url, headers: headers, body: body)
  }

  public func delete(
    path: String,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws -> HTTPResponse {
    try await request(method: .delete, path: path, headers: headers, body: body)
  }

  private func mergedHeaders(with requestHeaders: HTTPHeaders) -> HTTPHeaders {
    var headers = configuration.defaultHeaders
    for (name, value) in requestHeaders.values {
      headers[.custom(name)] = value
    }
    return headers
  }

  private func resolvedURL(for relativePath: String) throws(HTTPURLValidationError) -> URL {
    guard let baseURL = configuration.baseURL else {
      throw .missingBaseURL
    }
    guard !relativePath.isEmpty else {
      throw .malformedRelativePath
    }
    guard Self.hasValidPercentEncoding(relativePath) else {
      throw .malformedRelativePathPercentEncoding
    }
    guard let relativeComponents = URLComponents(string: relativePath) else {
      throw .malformedRelativePath
    }
    guard relativeComponents.scheme == nil, relativeComponents.host == nil else {
      throw .relativePathIsNotRelative
    }
    guard relativeComponents.percentEncodedFragment == nil else {
      throw .relativePathHasFragment
    }
    guard !Self.containsDotSegment(in: relativeComponents.percentEncodedPath) else {
      throw .relativePathHasDotSegment
    }
    guard var baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      throw .malformedRelativePath
    }

    baseComponents.percentEncodedPath = Self.join(
      basePath: baseComponents.percentEncodedPath,
      relativePath: relativeComponents.percentEncodedPath
    )
    baseComponents.percentEncodedQuery = relativeComponents.percentEncodedQuery
    guard let url = baseComponents.url else {
      throw .malformedRelativePath
    }
    return url
  }

  private static func hasValidPercentEncoding(_ value: String) -> Bool {
    let characters = Array(value.utf8)
    var index = 0

    while index < characters.count {
      guard characters[index] == 37 else {
        index += 1
        continue
      }
      guard index + 2 < characters.count,
        isHexDigit(characters[index + 1]),
        isHexDigit(characters[index + 2])
      else {
        return false
      }
      index += 3
    }

    return true
  }

  private static func isHexDigit(_ value: UInt8) -> Bool {
    (48...57).contains(value) || (65...70).contains(value) || (97...102).contains(value)
  }

  private static func containsDotSegment(in percentEncodedPath: String) -> Bool {
    percentEncodedPath
      .split(separator: "/", omittingEmptySubsequences: false)
      .contains { segment in
        guard let decoded = segment.removingPercentEncoding else {
          return false
        }
        return decoded == "." || decoded == ".."
      }
  }

  private static func join(basePath: String, relativePath: String) -> String {
    guard !relativePath.isEmpty else {
      return basePath
    }

    let baseWithoutTrailingSlashes = basePath.reversed().drop(while: { $0 == "/" }).reversed()
    let relativeWithoutLeadingSlashes = relativePath.drop(while: { $0 == "/" })
    guard !relativeWithoutLeadingSlashes.isEmpty else {
      return baseWithoutTrailingSlashes.isEmpty ? "/" : String(baseWithoutTrailingSlashes) + "/"
    }
    guard !baseWithoutTrailingSlashes.isEmpty else {
      return "/" + relativeWithoutLeadingSlashes
    }
    return String(baseWithoutTrailingSlashes) + "/" + relativeWithoutLeadingSlashes
  }
}
