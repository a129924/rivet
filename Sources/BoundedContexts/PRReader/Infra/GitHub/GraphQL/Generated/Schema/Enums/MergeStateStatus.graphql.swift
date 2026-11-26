// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension ReaderGitHubGraphQL {
  /// Detailed status information about a pull request merge.
  nonisolated enum MergeStateStatus: String, EnumType {
    /// The head ref is out of date.
    case behind = "BEHIND"
    /// The merge is blocked.
    case blocked = "BLOCKED"
    /// Mergeable and passing commit status.
    case clean = "CLEAN"
    /// The merge commit cannot be cleanly created.
    case dirty = "DIRTY"
    /// The merge is blocked due to the pull request being a draft.
    ///
    /// **Deprecated**: DRAFT state will be removed from this enum and `isDraft` should be used instead Use PullRequest.isDraft instead. Removal on 2021-01-01 UTC.
    case draft = "DRAFT"
    /// Mergeable with passing commit status and pre-receive hooks.
    case hasHooks = "HAS_HOOKS"
    /// The state cannot currently be determined.
    case unknown = "UNKNOWN"
    /// Mergeable with non-passing commit status.
    case unstable = "UNSTABLE"
  }

}
