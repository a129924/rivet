// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension ReaderGitHubGraphQL {
  nonisolated struct PullRequestFilesViewedQuery: GraphQLQuery {
    static let operationName: String = "PullRequestFilesViewed"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PullRequestFilesViewed($owner: String!, $name: String!, $number: Int!, $after: String) { repository(owner: $owner, name: $name) { __typename id nameWithOwner pullRequest(number: $number) { __typename id number repository { __typename id } headRefOid files(first: 100, after: $after) { __typename totalCount pageInfo { __typename hasNextPage endCursor } nodes { __typename path changeType additions deletions viewerViewedState } } } } }"#
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
        PullRequestFilesViewedQuery.Data.self
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
          PullRequestFilesViewedQuery.Data.Repository.self
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
            .field("files", Files?.self, arguments: [
              "first": 100,
              "after": .variable("after")
            ]),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PullRequestFilesViewedQuery.Data.Repository.PullRequest.self
          ] }

          /// The Node ID of the PullRequest object
          var id: ReaderGitHubGraphQL.ID { __data["id"] }
          /// Identifies the pull request number.
          var number: Int { __data["number"] }
          /// The repository associated with this node.
          var repository: Repository { __data["repository"] }
          /// Identifies the oid of the head ref associated with the pull request, even if the ref has been deleted.
          var headRefOid: ReaderGitHubGraphQL.GitObjectID { __data["headRefOid"] }
          /// Lists the files changed within this pull request.
          var files: Files? { __data["files"] }

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
              PullRequestFilesViewedQuery.Data.Repository.PullRequest.Repository.self
            ] }

            /// The Node ID of the Repository object
            var id: ReaderGitHubGraphQL.ID { __data["id"] }
          }

          /// Repository.PullRequest.Files
          ///
          /// Parent Type: `PullRequestChangedFileConnection`
          nonisolated struct Files: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestChangedFileConnection }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("totalCount", Int.self),
              .field("pageInfo", PageInfo.self),
              .field("nodes", [Node?]?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PullRequestFilesViewedQuery.Data.Repository.PullRequest.Files.self
            ] }

            /// Identifies the total count of items in the connection.
            var totalCount: Int { __data["totalCount"] }
            /// Information to aid in pagination.
            var pageInfo: PageInfo { __data["pageInfo"] }
            /// A list of nodes.
            var nodes: [Node?]? { __data["nodes"] }

            /// Repository.PullRequest.Files.PageInfo
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
                PullRequestFilesViewedQuery.Data.Repository.PullRequest.Files.PageInfo.self
              ] }

              /// When paginating forwards, are there more items?
              var hasNextPage: Bool { __data["hasNextPage"] }
              /// When paginating forwards, the cursor to continue.
              var endCursor: String? { __data["endCursor"] }
            }

            /// Repository.PullRequest.Files.Node
            ///
            /// Parent Type: `PullRequestChangedFile`
            nonisolated struct Node: ReaderGitHubGraphQL.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestChangedFile }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("path", String.self),
                .field("changeType", GraphQLEnum<ReaderGitHubGraphQL.PatchStatus>.self),
                .field("additions", Int.self),
                .field("deletions", Int.self),
                .field("viewerViewedState", GraphQLEnum<ReaderGitHubGraphQL.FileViewedState>.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                PullRequestFilesViewedQuery.Data.Repository.PullRequest.Files.Node.self
              ] }

              /// The path of the file.
              var path: String { __data["path"] }
              /// How the file was changed in this PullRequest
              var changeType: GraphQLEnum<ReaderGitHubGraphQL.PatchStatus> { __data["changeType"] }
              /// The number of additions to the file.
              var additions: Int { __data["additions"] }
              /// The number of deletions to the file.
              var deletions: Int { __data["deletions"] }
              /// The state of the file for the viewer.
              var viewerViewedState: GraphQLEnum<ReaderGitHubGraphQL.FileViewedState> { __data["viewerViewedState"] }
            }
          }
        }
      }
    }
  }

}
