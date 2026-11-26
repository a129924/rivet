// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// The possible states for a check suite or run status.
  nonisolated enum CheckStatusState: String, EnumType {
    /// The check suite or run has been completed.
    case completed = "COMPLETED"
    /// The check suite or run is in progress.
    case inProgress = "IN_PROGRESS"
    /// The check suite or run is in pending state.
    case pending = "PENDING"
    /// The check suite or run has been queued.
    case queued = "QUEUED"
    /// The check suite or run has been requested.
    case requested = "REQUESTED"
    /// The check suite or run is in waiting state.
    case waiting = "WAITING"
  }

}
