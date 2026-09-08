public struct JSONSemanticDecodingError: Error {
  public enum Kind {
    case dataCorrupted
    case keyNotFound
    case typeMismatch
    case valueNotFound
    case other
  }

  public let kind: Kind
  public let underlyingError: any Error

  init(underlyingError: any Error) {
    self.underlyingError = underlyingError
    kind = Self.kind(for: underlyingError)
  }

  private static func kind(for error: any Error) -> Kind {
    guard let decodingError = error as? DecodingError else {
      return .other
    }

    switch decodingError {
    case .dataCorrupted:
      return .dataCorrupted
    case .keyNotFound:
      return .keyNotFound
    case .typeMismatch:
      return .typeMismatch
    case .valueNotFound:
      return .valueNotFound
    @unknown default:
      return .other
    }
  }
}
