// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// The possible viewed states of a file .
  nonisolated enum FileViewedState: String, EnumType {
    /// The file has new changes since last viewed.
    case dismissed = "DISMISSED"
    /// The file has not been marked as viewed.
    case unviewed = "UNVIEWED"
    /// The file has been marked as viewed.
    case viewed = "VIEWED"
  }

}
