// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// The possible states for a check suite or run conclusion.
  nonisolated enum CheckConclusionState: String, EnumType {
    /// The check suite or run requires action.
    case actionRequired = "ACTION_REQUIRED"
    /// The check suite or run has been cancelled.
    case cancelled = "CANCELLED"
    /// The check suite or run has failed.
    case failure = "FAILURE"
    /// The check suite or run was neutral.
    case neutral = "NEUTRAL"
    /// The check suite or run was skipped.
    case skipped = "SKIPPED"
    /// The check suite or run was marked stale by GitHub. Only GitHub can use this conclusion.
    case stale = "STALE"
    /// The check suite or run has failed at startup.
    case startupFailure = "STARTUP_FAILURE"
    /// The check suite or run has succeeded.
    case success = "SUCCESS"
    /// The check suite or run has timed out.
    case timedOut = "TIMED_OUT"
  }

}
