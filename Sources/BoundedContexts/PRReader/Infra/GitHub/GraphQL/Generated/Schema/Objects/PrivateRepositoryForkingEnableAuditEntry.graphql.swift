// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// Audit log entry for a private_repository_forking.enable event.
  nonisolated static let PrivateRepositoryForkingEnableAuditEntry = ApolloAPI.Object(
    typename: "PrivateRepositoryForkingEnableAuditEntry",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.AuditEntry.self,
      ReaderGitHubGraphQL.Interfaces.EnterpriseAuditEntryData.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryAuditEntryData.self
    ],
    keyFields: nil
  )
}
