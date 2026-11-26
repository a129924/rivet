// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// The possible types of patch statuses.
  nonisolated enum PatchStatus: String, EnumType {
    /// The file was added. Git status 'A'.
    case added = "ADDED"
    /// The file's type was changed. Git status 'T'.
    case changed = "CHANGED"
    /// The file was copied. Git status 'C'.
    case copied = "COPIED"
    /// The file was deleted. Git status 'D'.
    case deleted = "DELETED"
    /// The file's contents were changed. Git status 'M'.
    case modified = "MODIFIED"
    /// The file was renamed. Git status 'R'.
    case renamed = "RENAMED"
  }

}
