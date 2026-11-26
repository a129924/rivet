// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// An Identity Provider configured to provision SAML and SCIM identities for
  /// Organizations. Visible to (1) organization owners, (2) organization owners'
  /// personal access tokens (classic) with read:org or admin:org scope, (3) GitHub
  /// App with an installation token with read or write access to members.
  nonisolated static let OrganizationIdentityProvider = ApolloAPI.Object(
    typename: "OrganizationIdentityProvider",
    implementedInterfaces: [ReaderGitHubGraphQL.Interfaces.Node.self],
    keyFields: nil
  )
}
