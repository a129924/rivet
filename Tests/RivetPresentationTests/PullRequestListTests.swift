import Foundation
import Testing

@testable import RivetPresentation

@Suite("PullRequestList selection and Open")
struct PullRequestListTests {
  private let first = "owner/one#1"
  private let second = "owner/two#2"

  @Test
  func selectionPreservesOnlyAnExistingIdentity() {
    #expect(PullRequestListSelection.valid("owner/one#1", in: [first, second]) == first)
    #expect(PullRequestListSelection.valid(first, in: [second, first]) == first)
    #expect(PullRequestListSelection.valid(nil, in: [first, second]) == nil)
    #expect(PullRequestListSelection.valid("missing", in: [first, second]) == nil)
    #expect(PullRequestListSelection.valid(first, in: []) == nil)
  }

  @Test
  func openRequiresExistingSelectedAndKnownSafeIdentity() {
    let ids = [first, second]
    #expect(
      PullRequestListOpen.allowed(
        target: first, selected: first, ids: ids, canOpen: { $0 == first }))
    #expect(
      !PullRequestListOpen.allowed(
        target: "missing", selected: "missing", ids: ids, canOpen: { _ in true }))
    #expect(
      !PullRequestListOpen.allowed(
        target: second, selected: first, ids: ids, canOpen: { _ in true }))
    #expect(
      !PullRequestListOpen.allowed(
        target: first, selected: first, ids: ids, canOpen: { _ in false }))
    #expect(
      !PullRequestListOpen.allowed(target: first, selected: nil, ids: ids, canOpen: { _ in true }))
  }

  @Test
  func activationEmitsExactlyOnceOnlyForTheSelectedSafeRow() {
    var opened: [String] = []
    let ids = [first, second]

    let valid = PullRequestListOpen.activate(
      target: second,
      selected: second,
      ids: ids,
      canOpen: { _ in true },
      onOpen: { opened.append($0) }
    )
    #expect(valid)
    #expect(opened == [second])

    for (target, selected, safe) in [
      ("missing", Optional("missing"), true),
      (first, Optional(second), true),
      (second, Optional(second), false),
    ] {
      let activated = PullRequestListOpen.activate(
        target: target,
        selected: selected,
        ids: ids,
        canOpen: { _ in safe },
        onOpen: { opened.append($0) }
      )
      #expect(!activated)
      #expect(opened == [second])
    }
  }

  @Test
  func invalidOpenNeverQueriesTheSafetyCapability() {
    var safetyChecks = 0
    let activated = PullRequestListOpen.activate(
      target: second,
      selected: first,
      ids: [first, second],
      canOpen: { _ in
        safetyChecks += 1
        return true
      },
      onOpen: { _ in Issue.record("Invalid target opened") }
    )

    #expect(!activated)
    #expect(safetyChecks == 0)
  }

  @Test
  func primaryActionRequiresExactlyOneSafeCurrentlySelectedIdentity() {
    var opened: [String] = []
    var safetyChecks = 0
    let ids = [first, second]
    let canOpen: (String) -> Bool = { id in
      safetyChecks += 1
      return id == second
    }

    let rejected: [(Set<String>, String?)] = [
      ([], second),
      ([first, second], second),
      ([first], second),
      (["missing"], "missing"),
      ([second], nil),
    ]
    for (targets, selected) in rejected {
      let activated = PullRequestListOpen.activatePrimaryAction(
        targets: targets,
        selected: selected,
        ids: ids,
        canOpen: canOpen,
        onOpen: { opened.append($0) }
      )
      #expect(!activated)
    }
    #expect(opened.isEmpty)
    #expect(safetyChecks == 0)

    let activated = PullRequestListOpen.activatePrimaryAction(
      targets: [second],
      selected: second,
      ids: ids,
      canOpen: canOpen,
      onOpen: { opened.append($0) }
    )
    #expect(activated)
    #expect(opened == [second])
    #expect(safetyChecks == 1)

    let unsafe = PullRequestListOpen.activatePrimaryAction(
      targets: [first],
      selected: first,
      ids: ids,
      canOpen: canOpen,
      onOpen: { opened.append($0) }
    )
    #expect(!unsafe)
    #expect(opened == [second])
  }

  @Test
  func previewSnapshotsUseUniqueActualFixtureIdentities() throws {
    let rowSource = try String(
      contentsOf: repositoryRoot.appendingPathComponent(
        "Sources/Presentation/PRInbox/PullRequestRow+Previews.swift"
      ),
      encoding: .utf8
    )
    let listSource = try String(
      contentsOf: repositoryRoot.appendingPathComponent(
        "Sources/Presentation/PRInbox/PullRequestList+Previews.swift"
      ),
      encoding: .utf8
    )

    let rowIDs = try captures(#"id: "([^"]+)""#, in: rowSource).map { $0[0] }
    let listLiterals = try captures(#"id: "([^"]+)""#, in: listSource)
      .map { $0[0] }
      .filter { !$0.contains(#"\("#) }
    #expect(rowIDs.count == 5)
    #expect(listLiterals.count == 1)
    #expect(
      rowSource.contains(
        "static let all = [standard, longTitle, longRepository, minimalMetadata, richMetadata]"))
    #expect(
      listSource.contains("static let six: [PullRequestRowPresentation] ="))
    #expect(listSource.contains("PullRequestRowPreviewFixtures.all + ["))
    #expect(
      listSource.contains(
        "PullRequestListPreviewHarness(items: PullRequestListPreviewFixtures.long"))

    let sixIDs = rowIDs + listLiterals
    #expect(sixIDs.count == 6)
    #expect(Set(sixIDs).count == sixIDs.count)

    let range = try #require(
      captures(
        #"static let long: \[PullRequestRowPresentation\]\s*=\s*six\s*\+\s*\(([0-9]+)\.\.\.([0-9]+)\)\.map \{ index in"#,
        in: listSource
      ).first
    )
    let lower = try #require(Int(range[0]))
    let upper = try #require(Int(range[1]))
    #expect(lower <= upper)
    let generatedPrefix = try #require(
      captures(#"id: "([^"]*)\\\(index\)""#, in: listSource).first?.first
    )
    let longIDs = sixIDs + (lower...upper).map { "\(generatedPrefix)\($0)" }
    #expect(Set(longIDs).count == longIDs.count)
  }
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func captures(_ pattern: String, in source: String) throws -> [[String]] {
  let expression = try NSRegularExpression(pattern: pattern)
  let range = NSRange(source.startIndex..., in: source)
  return expression.matches(in: source, range: range).map { match in
    (1..<match.numberOfRanges).compactMap { group in
      Range(match.range(at: group), in: source).map { String(source[$0]) }
    }
  }
}
