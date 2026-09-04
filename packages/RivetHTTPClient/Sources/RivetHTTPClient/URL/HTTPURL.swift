import Foundation

public enum HTTPURLValidationError: Error, Equatable, Sendable {
  case unsupportedScheme(String?)
  case missingHost
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
