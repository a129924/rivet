public enum PRReaderFailure: Error, Equatable, Sendable {
  case notReadable
  case unavailable
  case contentNotRepresentable
}
