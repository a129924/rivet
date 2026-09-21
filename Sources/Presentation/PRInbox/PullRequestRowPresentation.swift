public struct PullRequestRowPresentation: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let repositoryLabel: String
  public let numberLabel: String
  public let authorLabel: String
  public let relativeTimeLabel: String
  public let contextLabel: String?
  public let secondaryMetadataLabels: [String]

  public init(
    id: String,
    title: String,
    repositoryLabel: String,
    numberLabel: String,
    authorLabel: String,
    relativeTimeLabel: String,
    contextLabel: String? = nil,
    secondaryMetadataLabels: [String] = []
  ) {
    self.id = id
    self.title = title
    self.repositoryLabel = repositoryLabel
    self.numberLabel = numberLabel
    self.authorLabel = authorLabel
    self.relativeTimeLabel = relativeTimeLabel
    self.contextLabel = contextLabel
    self.secondaryMetadataLabels = secondaryMetadataLabels
  }

  var accessibilityLabelText: String {
    [
      title,
      "\(repositoryLabel) \(numberLabel)",
      authorLabel,
      contextLabel,
    ]
    .compactMap { $0 }
    .joined(separator: ", ")
  }

  var accessibilityValueText: String {
    ([relativeTimeLabel] + secondaryMetadataLabels)
      .joined(separator: ", ")
  }
}
