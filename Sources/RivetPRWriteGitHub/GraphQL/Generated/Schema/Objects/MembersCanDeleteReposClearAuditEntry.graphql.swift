// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Audit log entry for a members_can_delete_repos.clear event.
  nonisolated static let MembersCanDeleteReposClearAuditEntry = ApolloAPI.Object(
    typename: "MembersCanDeleteReposClearAuditEntry",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.AuditEntry.self,
      PRWriteGitHubGraphQL.Interfaces.EnterpriseAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self
    ],
    keyFields: nil
  )
}
