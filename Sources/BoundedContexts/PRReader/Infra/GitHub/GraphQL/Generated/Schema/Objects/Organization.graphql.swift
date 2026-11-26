// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// An account on GitHub, with one or more owners, that has repositories, members and teams.
  nonisolated static let Organization = ApolloAPI.Object(
    typename: "Organization",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.Actor.self,
      ReaderGitHubGraphQL.Interfaces.MemberStatusable.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.PackageOwner.self,
      ReaderGitHubGraphQL.Interfaces.ProfileOwner.self,
      ReaderGitHubGraphQL.Interfaces.ProjectOwner.self,
      ReaderGitHubGraphQL.Interfaces.ProjectV2Owner.self,
      ReaderGitHubGraphQL.Interfaces.ProjectV2Recent.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryDiscussionAuthor.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryDiscussionCommentAuthor.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryOwner.self,
      ReaderGitHubGraphQL.Interfaces.Sponsorable.self,
      ReaderGitHubGraphQL.Interfaces.UniformResourceLocatable.self
    ],
    keyFields: nil
  )
}
