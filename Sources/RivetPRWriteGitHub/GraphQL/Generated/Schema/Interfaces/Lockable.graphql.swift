// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// An object that can be locked.
  nonisolated static let Lockable = ApolloAPI.Interface(
    name: "Lockable",
    keyFields: nil,
    implementingObjects: [
      "Discussion",
      "Issue",
      "PullRequest"
    ]
  )
}
