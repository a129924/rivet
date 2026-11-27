// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// A review comment associated with a given repository pull request.
  nonisolated static let PullRequestReviewComment = ApolloAPI.Object(
    typename: "PullRequestReviewComment",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.Comment.self,
      PRWriteGitHubGraphQL.Interfaces.Deletable.self,
      PRWriteGitHubGraphQL.Interfaces.Minimizable.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.Reactable.self,
      PRWriteGitHubGraphQL.Interfaces.RepositoryNode.self,
      PRWriteGitHubGraphQL.Interfaces.Updatable.self,
      PRWriteGitHubGraphQL.Interfaces.UpdatableComment.self
    ],
    keyFields: nil
  )
}
