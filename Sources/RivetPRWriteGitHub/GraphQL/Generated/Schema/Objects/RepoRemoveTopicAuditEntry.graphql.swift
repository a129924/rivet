// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Audit log entry for a repo.remove_topic event.
  nonisolated static let RepoRemoveTopicAuditEntry = ApolloAPI.Object(
    typename: "RepoRemoveTopicAuditEntry",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.AuditEntry.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.RepositoryAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.TopicAuditEntryData.self
    ],
    keyFields: nil
  )
}
