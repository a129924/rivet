// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Represents a Git commit.
  nonisolated static let Commit = ApolloAPI.Object(
    typename: "Commit",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.GitObject.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.Subscribable.self,
      PRWriteGitHubGraphQL.Interfaces.UniformResourceLocatable.self
    ],
    keyFields: nil
  )
}
