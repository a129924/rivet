import Foundation

public enum HTTPURLValidationError: Error, Equatable, Sendable {
  case unsupportedScheme(String?)
  case missingHost
  case invalidTimeout
  case missingBaseURL
  case baseURLHasQuery
  case baseURLHasFragment
  case baseURLHasDotSegment
  case relativePathIsNotRelative
  case relativePathHasFragment
  case relativePathHasDotSegment
  case malformedRelativePath
  case malformedRelativePathPercentEncoding
}

public struct HTTPURL: Equatable, Sendable {
  public let value: URL

  public init(_ value: URL) throws(HTTPURLValidationError) {
    guard let scheme = value.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
      throw .unsupportedScheme(value.scheme)
    }

    guard let host = value.host, !host.isEmpty else {
      throw .missingHost
    }

    self.value = value
  }
}
