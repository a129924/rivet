// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// Represents a Git commit.
  nonisolated static let Commit = ApolloAPI.Object(
    typename: "Commit",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.GitObject.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.Subscribable.self,
      ReaderGitHubGraphQL.Interfaces.UniformResourceLocatable.self
    ],
    keyFields: nil
  )
}
