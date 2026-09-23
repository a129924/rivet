import SwiftUI

#if DEBUG
  struct PullRequestListDoubleClickDiagnostic {
    let targets: Set<PullRequestRowPresentation.ID>
    let selectedAtEvent: PullRequestRowPresentation.ID?
    let focusedAtEvent: Bool
    let emittedOpenIntent: Bool
  }

  private struct PullRequestListDoubleClickDiagnosticKey: EnvironmentKey {
    static var defaultValue: ((PullRequestListDoubleClickDiagnostic) -> Void)? { nil }
  }

  extension EnvironmentValues {
    var pullRequestListDoubleClickDiagnostic: ((PullRequestListDoubleClickDiagnostic) -> Void)? {
      get { self[PullRequestListDoubleClickDiagnosticKey.self] }
      set { self[PullRequestListDoubleClickDiagnosticKey.self] = newValue }
    }
  }
#endif

enum PullRequestListSelection {
  static func valid(
    _ selected: PullRequestRowPresentation.ID?,
    in ids: [PullRequestRowPresentation.ID]
  ) -> PullRequestRowPresentation.ID? {
    guard let selected, ids.contains(selected) else { return nil }
    return selected
  }
}

enum PullRequestListOpen {
  static func allowed(
    target: PullRequestRowPresentation.ID,
    selected: PullRequestRowPresentation.ID?,
    ids: [PullRequestRowPresentation.ID],
    canOpen: (PullRequestRowPresentation.ID) -> Bool
  ) -> Bool {
    ids.contains(target) && selected == target && canOpen(target)
  }

  @discardableResult
  static func activate(
    target: PullRequestRowPresentation.ID,
    selected: PullRequestRowPresentation.ID?,
    ids: [PullRequestRowPresentation.ID],
    canOpen: (PullRequestRowPresentation.ID) -> Bool,
    onOpen: (PullRequestRowPresentation.ID) -> Void
  ) -> Bool {
    guard allowed(target: target, selected: selected, ids: ids, canOpen: canOpen) else {
      return false
    }
    onOpen(target)
    return true
  }

  @discardableResult
  static func activatePrimaryAction(
    targets: Set<PullRequestRowPresentation.ID>,
    selected: PullRequestRowPresentation.ID?,
    ids: [PullRequestRowPresentation.ID],
    canOpen: (PullRequestRowPresentation.ID) -> Bool,
    onOpen: (PullRequestRowPresentation.ID) -> Void
  ) -> Bool {
    guard targets.count == 1, let target = targets.first else { return false }
    return activate(
      target: target,
      selected: selected,
      ids: ids,
      canOpen: canOpen,
      onOpen: onOpen
    )
  }
}

public struct PullRequestList: View {
  private let items: [PullRequestRowPresentation]
  @Binding private var selection: PullRequestRowPresentation.ID?
  private let focus: FocusState<Bool>.Binding
  private let canOpen: (PullRequestRowPresentation.ID) -> Bool
  private let onOpen: (PullRequestRowPresentation.ID) -> Void
  #if DEBUG
    @Environment(\.pullRequestListDoubleClickDiagnostic)
    private var doubleClickDiagnostic
  #endif

  public init(
    items: [PullRequestRowPresentation],
    selection: Binding<PullRequestRowPresentation.ID?>,
    focus: FocusState<Bool>.Binding,
    canOpen: @escaping (PullRequestRowPresentation.ID) -> Bool,
    onOpen: @escaping (PullRequestRowPresentation.ID) -> Void
  ) {
    self.items = items
    self._selection = selection
    self.focus = focus
    self.canOpen = canOpen
    self.onOpen = onOpen
  }

  private var ids: [PullRequestRowPresentation.ID] { items.map(\.id) }

  private var nativeSelection: Binding<PullRequestRowPresentation.ID?> {
    Binding(
      get: { PullRequestListSelection.valid(selection, in: ids) },
      set: { selection = PullRequestListSelection.valid($0, in: ids) }
    )
  }

  public var body: some View {
    List(selection: nativeSelection) {
      ForEach(items) { presentation in
        PullRequestRow(presentation: presentation)
          .contentShape(Rectangle())
          .tag(presentation.id)
      }
    }
    .contextMenu(forSelectionType: PullRequestRowPresentation.ID.self) { _ in
      EmptyView()
    } primaryAction: { targets in
      let selectedAtEvent = nativeSelection.wrappedValue
      let emitted = PullRequestListOpen.activatePrimaryAction(
        targets: targets,
        selected: selectedAtEvent,
        ids: ids,
        canOpen: canOpen,
        onOpen: onOpen
      )
      #if DEBUG
        doubleClickDiagnostic?(
          PullRequestListDoubleClickDiagnostic(
            targets: targets,
            selectedAtEvent: selectedAtEvent,
            focusedAtEvent: focus.wrappedValue,
            emittedOpenIntent: emitted
          )
        )
      #endif
    }
    .focused(focus)
    .onKeyPress(keys: [.home, .end, .return], phases: [.down]) { press in
      guard focus.wrappedValue, press.modifiers.isEmpty else { return .ignored }

      switch press.key {
      case .home:
        guard let first = ids.first else { return .ignored }
        selection = first
      case .end:
        guard let last = ids.last else { return .ignored }
        selection = last
      case .return:
        guard let selected = nativeSelection.wrappedValue else { return .ignored }
        activate(selected)
      default:
        return .ignored
      }
      return .handled
    }
    .onChange(of: ids, initial: true) { _, newIDs in
      normalizeSelection(in: newIDs)
    }
    .onChange(of: selection) { _, _ in
      normalizeSelection(in: ids)
    }
  }

  private func normalizeSelection(in ids: [PullRequestRowPresentation.ID]) {
    let valid = PullRequestListSelection.valid(selection, in: ids)
    if selection != valid { selection = valid }
  }

  @discardableResult
  private func activate(_ target: PullRequestRowPresentation.ID) -> Bool {
    PullRequestListOpen.activate(
      target: target,
      selected: nativeSelection.wrappedValue,
      ids: ids,
      canOpen: canOpen,
      onOpen: onOpen
    )
  }
}
