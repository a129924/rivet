// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Audit log entry for a repository_visibility_change.disable event.
  nonisolated static let RepositoryVisibilityChangeDisableAuditEntry = ApolloAPI.Object(
    typename: "RepositoryVisibilityChangeDisableAuditEntry",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.AuditEntry.self,
      PRWriteGitHubGraphQL.Interfaces.EnterpriseAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self
    ],
    keyFields: nil
  )
}
