// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// Entities that can be subscribed to for web and email notifications.
  nonisolated static let Subscribable = ApolloAPI.Interface(
    name: "Subscribable",
    keyFields: nil,
    implementingObjects: [
      "Commit",
      "Discussion",
      "Issue",
      "PullRequest",
      "Repository",
      "Team"
    ]
  )
}
