// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// The possible commit status states.
  nonisolated enum StatusState: String, EnumType {
    /// Status is errored.
    case error = "ERROR"
    /// Status is expected.
    case expected = "EXPECTED"
    /// Status is failing.
    case failure = "FAILURE"
    /// Status is pending.
    case pending = "PENDING"
    /// Status is successful.
    case success = "SUCCESS"
  }

}
