// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// Metadata for an audit entry with action oauth_application.*
  nonisolated static let OauthApplicationAuditEntryData = ApolloAPI.Interface(
    name: "OauthApplicationAuditEntryData",
    keyFields: nil,
    implementingObjects: [
      "OauthApplicationCreateAuditEntry",
      "OrgOauthAppAccessApprovedAuditEntry",
      "OrgOauthAppAccessBlockedAuditEntry",
      "OrgOauthAppAccessDeniedAuditEntry",
      "OrgOauthAppAccessRequestedAuditEntry",
      "OrgOauthAppAccessUnblockedAuditEntry"
    ]
  )
}
