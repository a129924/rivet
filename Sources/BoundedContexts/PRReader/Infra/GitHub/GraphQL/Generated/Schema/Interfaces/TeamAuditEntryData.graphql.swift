// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Interfaces {
  /// Metadata for an audit entry with action team.*
  nonisolated static let TeamAuditEntryData = ApolloAPI.Interface(
    name: "TeamAuditEntryData",
    keyFields: nil,
    implementingObjects: [
      "OrgRestoreMemberMembershipTeamAuditEntryData",
      "TeamAddMemberAuditEntry",
      "TeamAddRepositoryAuditEntry",
      "TeamChangeParentTeamAuditEntry",
      "TeamRemoveMemberAuditEntry",
      "TeamRemoveRepositoryAuditEntry"
    ]
  )
}
