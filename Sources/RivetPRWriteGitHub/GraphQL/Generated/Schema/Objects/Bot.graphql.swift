// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// A special type of user which takes actions on behalf of GitHub Apps.
  nonisolated static let Bot = ApolloAPI.Object(
    typename: "Bot",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.Actor.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.UniformResourceLocatable.self
    ],
    keyFields: nil
  )
}
