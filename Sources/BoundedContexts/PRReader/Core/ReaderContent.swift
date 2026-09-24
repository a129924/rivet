public struct PRContentSnapshot: Equatable, Sendable {
  public let id: ReaderPullRequestID
  public let background: ReaderBackground
  public let conversation: [ReaderComment]
  public let reviews: [ReaderReview]
  public let inlineThreads: [ReaderInlineThread]
  public let files: [ReaderFile]
  public let reviewDecision: ReviewDecision?
  public let checkRollup: ReaderCheckRollup?

  public init(
    id: ReaderPullRequestID,
    background: ReaderBackground,
    conversation: [ReaderComment],
    reviews: [ReaderReview],
    inlineThreads: [ReaderInlineThread],
    files: [ReaderFile],
    reviewDecision: ReviewDecision?,
    checkRollup: ReaderCheckRollup?
  ) {
    self.id = id
    self.background = background
    self.conversation = conversation
    self.reviews = reviews
    self.inlineThreads = inlineThreads
    self.files = files
    self.reviewDecision = reviewDecision
    self.checkRollup = checkRollup
  }
}

public struct ReaderBackground: Equatable, Sendable {
  public let title: String
  public let body: String?
  public let author: String?

  public init(title: String, body: String?, author: String?) {
    self.title = title
    self.body = body
    self.author = author
  }
}

public struct ReaderComment: Equatable, Sendable {
  public let id: String
  public let body: String
  public let author: String?

  public init(id: String, body: String, author: String?) {
    self.id = id
    self.body = body
    self.author = author
  }
}

public struct ReaderReview: Equatable, Sendable {
  public let id: String
  public let body: String
  public let author: String?
  public let state: ReviewState

  public init(id: String, body: String, author: String?, state: ReviewState) {
    self.id = id
    self.body = body
    self.author = author
    self.state = state
  }
}

public struct ReaderInlineThread: Equatable, Sendable {
  public let id: String
  public let path: String
  public let line: Int?
  public let isResolved: Bool
  public let isOutdated: Bool
  public let comments: [ReaderComment]

  public init(
    id: String,
    path: String,
    line: Int?,
    isResolved: Bool,
    isOutdated: Bool,
    comments: [ReaderComment]
  ) {
    self.id = id
    self.path = path
    self.line = line
    self.isResolved = isResolved
    self.isOutdated = isOutdated
    self.comments = comments
  }
}

public struct ReaderFile: Equatable, Sendable {
  public let reference: ReaderFileReference
  public let path: String
  public let previousPath: String?
  public let change: FileChange
  public let additions: Int
  public let deletions: Int
  public let patch: String?

  public init(
    reference: ReaderFileReference,
    path: String,
    previousPath: String?,
    change: FileChange,
    additions: Int,
    deletions: Int,
    patch: String?
  ) {
    self.reference = reference
    self.path = path
    self.previousPath = previousPath
    self.change = change
    self.additions = additions
    self.deletions = deletions
    self.patch = patch
  }
}

public enum FileChange: Equatable, Sendable {
  case added
  case removed
  case modified
  case renamed
  case copied
  case typeChanged
}

public enum ReviewState: Equatable, Sendable {
  case pending
  case commented
  case approved
  case changesRequested
  case dismissed
}

public enum ReviewDecision: Equatable, Sendable {
  case approved
  case changesRequested
  case reviewRequired
}
