// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// A team of users in an organization.
  nonisolated static let Team = ApolloAPI.Object(
    typename: "Team",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.MemberStatusable.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.Subscribable.self,
      ReaderGitHubGraphQL.Interfaces.TeamReviewRequestable.self
    ],
    keyFields: nil
  )
}
