// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Interfaces {
  /// Common fields across different issue field value types
  nonisolated static let IssueFieldValueCommon = ApolloAPI.Interface(
    name: "IssueFieldValueCommon",
    keyFields: nil,
    implementingObjects: [
      "IssueFieldDateValue",
      "IssueFieldMultiSelectValue",
      "IssueFieldNumberValue",
      "IssueFieldSingleSelectValue",
      "IssueFieldTextValue"
    ]
  )
}
