// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Audit log entry for a team.remove_repository event.
  nonisolated static let TeamRemoveRepositoryAuditEntry = ApolloAPI.Object(
    typename: "TeamRemoveRepositoryAuditEntry",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.AuditEntry.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.RepositoryAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.TeamAuditEntryData.self
    ],
    keyFields: nil
  )
}
