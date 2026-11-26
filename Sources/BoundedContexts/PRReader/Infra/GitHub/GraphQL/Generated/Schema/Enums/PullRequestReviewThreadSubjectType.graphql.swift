// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// The possible subject types of a pull request review comment.
  nonisolated enum PullRequestReviewThreadSubjectType: String, EnumType {
    /// A comment that has been made against the file of a pull request
    case file = "FILE"
    /// A comment that has been made against the line of a pull request
    case line = "LINE"
  }

}
