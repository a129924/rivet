// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Interfaces {
  /// Common fields across different issue field types
  nonisolated static let IssueFieldCommon = ApolloAPI.Interface(
    name: "IssueFieldCommon",
    keyFields: nil,
    implementingObjects: [
      "IssueFieldDate",
      "IssueFieldMultiSelect",
      "IssueFieldNumber",
      "IssueFieldSingleSelect",
      "IssueFieldText"
    ]
  )
}
