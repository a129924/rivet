// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Interfaces {
  /// An object that can have labels assigned to it.
  nonisolated static let Labelable = ApolloAPI.Interface(
    name: "Labelable",
    keyFields: nil,
    implementingObjects: [
      "Discussion",
      "Issue",
      "PullRequest"
    ]
  )
}
