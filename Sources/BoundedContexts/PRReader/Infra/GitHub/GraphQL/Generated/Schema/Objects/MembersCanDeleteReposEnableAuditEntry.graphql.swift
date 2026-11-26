// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// Audit log entry for a members_can_delete_repos.enable event.
  nonisolated static let MembersCanDeleteReposEnableAuditEntry = ApolloAPI.Object(
    typename: "MembersCanDeleteReposEnableAuditEntry",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.AuditEntry.self,
      ReaderGitHubGraphQL.Interfaces.EnterpriseAuditEntryData.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self
    ],
    keyFields: nil
  )
}
