// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// Audit log entry for a repo.config.disable_collaborators_only event.
  nonisolated static let RepoConfigDisableCollaboratorsOnlyAuditEntry = ApolloAPI.Object(
    typename: "RepoConfigDisableCollaboratorsOnlyAuditEntry",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.AuditEntry.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryAuditEntryData.self
    ],
    keyFields: nil
  )
}
