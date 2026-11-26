// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Interfaces {
  /// Represents a subject that can be reacted on.
  nonisolated static let Reactable = ApolloAPI.Interface(
    name: "Reactable",
    keyFields: nil,
    implementingObjects: [
      "CommitComment",
      "Discussion",
      "DiscussionComment",
      "Issue",
      "IssueComment",
      "PullRequest",
      "PullRequestReview",
      "PullRequestReviewComment",
      "Release"
    ]
  )
}
