// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// Represents a object that belongs to a repository.
  nonisolated static let RepositoryNode = ApolloAPI.Interface(
    name: "RepositoryNode",
    keyFields: nil,
    implementingObjects: [
      "CommitComment",
      "CommitCommentThread",
      "DependabotUpdate",
      "Discussion",
      "DiscussionCategory",
      "Issue",
      "IssueComment",
      "PinnedDiscussion",
      "PullRequest",
      "PullRequestCommitCommentThread",
      "PullRequestReview",
      "PullRequestReviewComment",
      "RepositoryVulnerabilityAlert"
    ]
  )
}
