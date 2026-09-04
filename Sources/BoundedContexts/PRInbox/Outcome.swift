public enum Outcome<Success: Sendable, Failure: Error & Sendable>: Sendable {
  case success(Success)
  case failure(Failure)
}
