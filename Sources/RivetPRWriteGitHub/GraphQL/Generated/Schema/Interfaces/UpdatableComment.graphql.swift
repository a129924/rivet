// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// Comments that can be updated.
  nonisolated static let UpdatableComment = ApolloAPI.Interface(
    name: "UpdatableComment",
    keyFields: nil,
    implementingObjects: [
      "CommitComment",
      "DiscussionComment",
      "GistComment",
      "Issue",
      "IssueComment",
      "PullRequest",
      "PullRequestReview",
      "PullRequestReviewComment"
    ]
  )
}
