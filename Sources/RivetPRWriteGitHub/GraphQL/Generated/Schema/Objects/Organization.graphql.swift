// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// An account on GitHub, with one or more owners, that has repositories, members and teams.
  nonisolated static let Organization = ApolloAPI.Object(
    typename: "Organization",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.Actor.self,
      PRWriteGitHubGraphQL.Interfaces.MemberStatusable.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.PackageOwner.self,
      PRWriteGitHubGraphQL.Interfaces.ProfileOwner.self,
      PRWriteGitHubGraphQL.Interfaces.ProjectOwner.self,
      PRWriteGitHubGraphQL.Interfaces.ProjectV2Owner.self,
      PRWriteGitHubGraphQL.Interfaces.ProjectV2Recent.self,
      PRWriteGitHubGraphQL.Interfaces.RepositoryDiscussionAuthor.self,
      PRWriteGitHubGraphQL.Interfaces.RepositoryDiscussionCommentAuthor.self,
      PRWriteGitHubGraphQL.Interfaces.RepositoryOwner.self,
      PRWriteGitHubGraphQL.Interfaces.Sponsorable.self,
      PRWriteGitHubGraphQL.Interfaces.UniformResourceLocatable.self
    ],
    keyFields: nil
  )
}
