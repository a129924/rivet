// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// Entities that can be deleted.
  nonisolated static let Deletable = ApolloAPI.Interface(
    name: "Deletable",
    keyFields: nil,
    implementingObjects: [
      "CommitComment",
      "Discussion",
      "DiscussionComment",
      "GistComment",
      "Issue",
      "IssueComment",
      "PullRequestReview",
      "PullRequestReviewComment"
    ]
  )
}
