// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// A special type of user which takes actions on behalf of GitHub Apps.
  nonisolated static let Bot = ApolloAPI.Object(
    typename: "Bot",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.Actor.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.UniformResourceLocatable.self
    ],
    keyFields: nil
  )
}
