public struct ReaderCheckRollup: Equatable, Sendable {
  public let overallState: ReaderCheckState
  public let checks: [ReaderCheck]

  public init(overallState: ReaderCheckState, checks: [ReaderCheck]) {
    self.overallState = overallState
    self.checks = checks
  }
}

public enum ReaderCheck: Equatable, Sendable {
  case run(name: String, status: ReaderRunStatus, conclusion: ReaderRunConclusion?)
  case commitStatus(context: String, state: ReaderCheckState)
}

public enum ReaderRunStatus: Equatable, Sendable {
  case requested
  case queued
  case inProgress
  case completed
  case waiting
  case pending
}

public enum ReaderRunConclusion: Equatable, Sendable {
  case actionRequired
  case timedOut
  case cancelled
  case failure
  case success
  case neutral
  case skipped
  case startupFailure
  case stale
}

public enum ReaderCheckState: Equatable, Sendable {
  case expected
  case error
  case failure
  case pending
  case success
}
