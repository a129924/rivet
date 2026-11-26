// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// A review object for a given pull request.
  nonisolated static let PullRequestReview = ApolloAPI.Object(
    typename: "PullRequestReview",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.Comment.self,
      ReaderGitHubGraphQL.Interfaces.Deletable.self,
      ReaderGitHubGraphQL.Interfaces.Minimizable.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.Reactable.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryNode.self,
      ReaderGitHubGraphQL.Interfaces.Updatable.self,
      ReaderGitHubGraphQL.Interfaces.UpdatableComment.self
    ],
    keyFields: nil
  )
}
