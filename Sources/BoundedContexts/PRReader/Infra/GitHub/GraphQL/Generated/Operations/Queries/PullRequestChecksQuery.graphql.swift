// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension ReaderGitHubGraphQL {
  nonisolated struct PullRequestChecksQuery: GraphQLQuery {
    static let operationName: String = "PullRequestChecks"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PullRequestChecks($owner: String!, $name: String!, $number: Int!, $after: String) { repository(owner: $owner, name: $name) { __typename id nameWithOwner pullRequest(number: $number) { __typename id number repository { __typename id } headRefOid statusCheckRollup { __typename id state contexts(first: 100, after: $after) { __typename totalCount pageInfo { __typename hasNextPage endCursor } nodes { __typename ... on CheckRun { id name status conclusion } ... on StatusContext { id context state } } } } } } }"#
      ))

    public var owner: String
    public var name: String
    public var number: Int32
    public var after: GraphQLNullable<String>

    public init(
      owner: String,
      name: String,
      number: Int32,
      after: GraphQLNullable<String>
    ) {
      self.owner = owner
      self.name = name
      self.number = number
      self.after = after
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "owner": owner,
      "name": name,
      "number": number,
      "after": after
    ] }

    nonisolated struct Data: ReaderGitHubGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("repository", Repository?.self, arguments: [
          "owner": .variable("owner"),
          "name": .variable("name")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PullRequestChecksQuery.Data.self
      ] }

      /// Lookup a given repository by the owner and repository name.
      var repository: Repository? { __data["repository"] }

      /// Repository
      ///
      /// Parent Type: `Repository`
      nonisolated struct Repository: ReaderGitHubGraphQL.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Repository }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", ReaderGitHubGraphQL.ID.self),
          .field("nameWithOwner", String.self),
          .field("pullRequest", PullRequest?.self, arguments: ["number": .variable("number")]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PullRequestChecksQuery.Data.Repository.self
        ] }

        /// The Node ID of the Repository object
        var id: ReaderGitHubGraphQL.ID { __data["id"] }
        /// The repository's name with owner.
        var nameWithOwner: String { __data["nameWithOwner"] }
        /// Returns a single pull request from the current repository by number.
        var pullRequest: PullRequest? { __data["pullRequest"] }

        /// Repository.PullRequest
        ///
        /// Parent Type: `PullRequest`
        nonisolated struct PullRequest: ReaderGitHubGraphQL.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequest }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", ReaderGitHubGraphQL.ID.self),
            .field("number", Int.self),
            .field("repository", Repository.self),
            .field("headRefOid", ReaderGitHubGraphQL.GitObjectID.self),
            .field("statusCheckRollup", StatusCheckRollup?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PullRequestChecksQuery.Data.Repository.PullRequest.self
          ] }

          /// The Node ID of the PullRequest object
          var id: ReaderGitHubGraphQL.ID { __data["id"] }
          /// Identifies the pull request number.
          var number: Int { __data["number"] }
          /// The repository associated with this node.
          var repository: Repository { __data["repository"] }
          /// Identifies the oid of the head ref associated with the pull request, even if the ref has been deleted.
          var headRefOid: ReaderGitHubGraphQL.GitObjectID { __data["headRefOid"] }
          /// Check and Status rollup information for the PR's head ref.
          var statusCheckRollup: StatusCheckRollup? { __data["statusCheckRollup"] }

          /// Repository.PullRequest.Repository
          ///
          /// Parent Type: `Repository`
          nonisolated struct Repository: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Repository }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", ReaderGitHubGraphQL.ID.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PullRequestChecksQuery.Data.Repository.PullRequest.Repository.self
            ] }

            /// The Node ID of the Repository object
            var id: ReaderGitHubGraphQL.ID { __data["id"] }
          }

          /// Repository.PullRequest.StatusCheckRollup
          ///
          /// Parent Type: `StatusCheckRollup`
          nonisolated struct StatusCheckRollup: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.StatusCheckRollup }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", ReaderGitHubGraphQL.ID.self),
              .field("state", GraphQLEnum<ReaderGitHubGraphQL.StatusState>.self),
              .field("contexts", Contexts.self, arguments: [
                "first": 100,
                "after": .variable("after")
              ]),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.self
            ] }

            /// The Node ID of the StatusCheckRollup object
            var id: ReaderGitHubGraphQL.ID { __data["id"] }
            /// The combined status for the commit.
            var state: GraphQLEnum<ReaderGitHubGraphQL.StatusState> { __data["state"] }
            /// A list of status contexts and check runs for this commit.
            var contexts: Contexts { __data["contexts"] }

            /// Repository.PullRequest.StatusCheckRollup.Contexts
            ///
            /// Parent Type: `StatusCheckRollupContextConnection`
            nonisolated struct Contexts: ReaderGitHubGraphQL.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.StatusCheckRollupContextConnection }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("totalCount", Int.self),
                .field("pageInfo", PageInfo.self),
                .field("nodes", [Node?]?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.self
              ] }

              /// Identifies the total count of items in the connection.
              var totalCount: Int { __data["totalCount"] }
              /// Information to aid in pagination.
              var pageInfo: PageInfo { __data["pageInfo"] }
              /// A list of nodes.
              var nodes: [Node?]? { __data["nodes"] }

              /// Repository.PullRequest.StatusCheckRollup.Contexts.PageInfo
              ///
              /// Parent Type: `PageInfo`
              nonisolated struct PageInfo: ReaderGitHubGraphQL.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PageInfo }
                static var __selections: [ApolloAPI.Selection] { [
                  .field("__typename", String.self),
                  .field("hasNextPage", Bool.self),
                  .field("endCursor", String?.self),
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.PageInfo.self
                ] }

                /// When paginating forwards, are there more items?
                var hasNextPage: Bool { __data["hasNextPage"] }
                /// When paginating forwards, the cursor to continue.
                var endCursor: String? { __data["endCursor"] }
              }

              /// Repository.PullRequest.StatusCheckRollup.Contexts.Node
              ///
              /// Parent Type: `StatusCheckRollupContext`
              nonisolated struct Node: ReaderGitHubGraphQL.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Unions.StatusCheckRollupContext }
                static var __selections: [ApolloAPI.Selection] { [
                  .field("__typename", String.self),
                  .inlineFragment(AsCheckRun.self),
                  .inlineFragment(AsStatusContext.self),
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node.self
                ] }

                var asCheckRun: AsCheckRun? { _asInlineFragment() }
                var asStatusContext: AsStatusContext? { _asInlineFragment() }

                /// Repository.PullRequest.StatusCheckRollup.Contexts.Node.AsCheckRun
                ///
                /// Parent Type: `CheckRun`
                nonisolated struct AsCheckRun: ReaderGitHubGraphQL.InlineFragment {
                  let __data: DataDict
                  init(_dataDict: DataDict) { __data = _dataDict }

                  typealias RootEntityType = PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node
                  static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.CheckRun }
                  static var __selections: [ApolloAPI.Selection] { [
                    .field("id", ReaderGitHubGraphQL.ID.self),
                    .field("name", String.self),
                    .field("status", GraphQLEnum<ReaderGitHubGraphQL.CheckStatusState>.self),
                    .field("conclusion", GraphQLEnum<ReaderGitHubGraphQL.CheckConclusionState>?.self),
                  ] }
                  static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                    PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node.self,
                    PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node.AsCheckRun.self
                  ] }

                  /// The Node ID of the CheckRun object
                  var id: ReaderGitHubGraphQL.ID { __data["id"] }
                  /// The name of the check for this check run.
                  var name: String { __data["name"] }
                  /// The current status of the check run.
                  var status: GraphQLEnum<ReaderGitHubGraphQL.CheckStatusState> { __data["status"] }
                  /// The conclusion of the check run.
                  var conclusion: GraphQLEnum<ReaderGitHubGraphQL.CheckConclusionState>? { __data["conclusion"] }
                }

                /// Repository.PullRequest.StatusCheckRollup.Contexts.Node.AsStatusContext
                ///
                /// Parent Type: `StatusContext`
                nonisolated struct AsStatusContext: ReaderGitHubGraphQL.InlineFragment {
                  let __data: DataDict
                  init(_dataDict: DataDict) { __data = _dataDict }

                  typealias RootEntityType = PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node
                  static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.StatusContext }
                  static var __selections: [ApolloAPI.Selection] { [
                    .field("id", ReaderGitHubGraphQL.ID.self),
                    .field("context", String.self),
                    .field("state", GraphQLEnum<ReaderGitHubGraphQL.StatusState>.self),
                  ] }
                  static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                    PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node.self,
                    PullRequestChecksQuery.Data.Repository.PullRequest.StatusCheckRollup.Contexts.Node.AsStatusContext.self
                  ] }

                  /// The Node ID of the StatusContext object
                  var id: ReaderGitHubGraphQL.ID { __data["id"] }
                  /// The name of this status context.
                  var context: String { __data["context"] }
                  /// The state of this status context.
                  var state: GraphQLEnum<ReaderGitHubGraphQL.StatusState> { __data["state"] }
                }
              }
            }
          }
        }
      }
    }
  }

}
