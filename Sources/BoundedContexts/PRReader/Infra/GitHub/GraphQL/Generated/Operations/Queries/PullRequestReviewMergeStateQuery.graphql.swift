// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension ReaderGitHubGraphQL {
  nonisolated struct PullRequestReviewMergeStateQuery: GraphQLQuery {
    static let operationName: String = "PullRequestReviewMergeState"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PullRequestReviewMergeState($owner: String!, $name: String!, $number: Int!) { repository(owner: $owner, name: $name) { __typename id nameWithOwner pullRequest(number: $number) { __typename number repository { __typename id } reviewDecision mergeable mergeStateStatus isDraft headRefOid } } }"#
      ))

    public var owner: String
    public var name: String
    public var number: Int32

    public init(
      owner: String,
      name: String,
      number: Int32
    ) {
      self.owner = owner
      self.name = name
      self.number = number
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "owner": owner,
      "name": name,
      "number": number
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
        PullRequestReviewMergeStateQuery.Data.self
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
          PullRequestReviewMergeStateQuery.Data.Repository.self
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
            .field("number", Int.self),
            .field("repository", Repository.self),
            .field("reviewDecision", GraphQLEnum<ReaderGitHubGraphQL.PullRequestReviewDecision>?.self),
            .field("mergeable", GraphQLEnum<ReaderGitHubGraphQL.MergeableState>.self),
            .field("mergeStateStatus", GraphQLEnum<ReaderGitHubGraphQL.MergeStateStatus>.self),
            .field("isDraft", Bool.self),
            .field("headRefOid", ReaderGitHubGraphQL.GitObjectID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PullRequestReviewMergeStateQuery.Data.Repository.PullRequest.self
          ] }

          /// Identifies the pull request number.
          var number: Int { __data["number"] }
          /// The repository associated with this node.
          var repository: Repository { __data["repository"] }
          /// The current status of this pull request with respect to code review.
          var reviewDecision: GraphQLEnum<ReaderGitHubGraphQL.PullRequestReviewDecision>? { __data["reviewDecision"] }
          /// Whether or not the pull request can be merged based on the existence of merge conflicts.
          var mergeable: GraphQLEnum<ReaderGitHubGraphQL.MergeableState> { __data["mergeable"] }
          /// Detailed information about the current pull request merge state status.
          var mergeStateStatus: GraphQLEnum<ReaderGitHubGraphQL.MergeStateStatus> { __data["mergeStateStatus"] }
          /// Identifies if the pull request is a draft.
          var isDraft: Bool { __data["isDraft"] }
          /// Identifies the oid of the head ref associated with the pull request, even if the ref has been deleted.
          var headRefOid: ReaderGitHubGraphQL.GitObjectID { __data["headRefOid"] }

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
              PullRequestReviewMergeStateQuery.Data.Repository.PullRequest.Repository.self
            ] }

            /// The Node ID of the Repository object
            var id: ReaderGitHubGraphQL.ID { __data["id"] }
          }
        }
      }
    }
  }

}
