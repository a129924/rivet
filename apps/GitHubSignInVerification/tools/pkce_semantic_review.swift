import AppKit
import CryptoKit
import Foundation
import Translation

// Private bounded single-record helper. No credential, case, outcome or expected label enters.
struct ReviewOutput: Encodable {
  let protocolVersion = 1
  var semanticCategory = "indeterminate"
  var reviewStatus = "unreviewable"
  var revealStarted = false
  var userConfirmed = false

  private enum CodingKeys: String, CodingKey {
    case protocolVersion = "protocol_version"
    case semanticCategory = "semantic_category"
    case reviewStatus = "review_status"
    case revealStarted = "reveal_started"
    case userConfirmed = "user_confirmed"
  }
}

func emit(_ result: ReviewOutput, status: Int32 = 0) -> Never {
  if let data = try? JSONEncoder().encode(result), data.count <= 512 {
    FileHandle.standardOutput.write(data)
  }
  exit(status)
}

// Exact two-key JSON parser: Foundation decodes individual strings, this parser rejects duplicates.
struct InputParser {
  let bytes: [UInt8]
  var offset = 0
  var protocolVersion = 1

  mutating func whitespace() {
    while offset < bytes.count && [9, 10, 13, 32].contains(bytes[offset]) { offset += 1 }
  }

  mutating func consume(_ byte: UInt8) -> Bool {
    whitespace()
    guard offset < bytes.count, bytes[offset] == byte else { return false }
    offset += 1
    return true
  }

  mutating func string() -> String? {
    whitespace()
    let start = offset
    guard offset < bytes.count, bytes[offset] == 34 else { return nil }
    offset += 1
    var escaped = false
    while offset < bytes.count {
      let byte = bytes[offset]
      offset += 1
      if escaped {
        escaped = false
        continue
      }
      if byte == 92 {
        escaped = true
        continue
      }
      if byte == 34 {
        let data = Data(bytes[start..<offset])
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed))
          as? String
      }
    }
    return nil
  }

  mutating func description() -> String? {
    guard consume(123) else { return nil }
    var seen: Set<String> = []
    var text: String?
    for index in 0..<2 {
      if index > 0 && !consume(44) { return nil }
      guard let key = string(), seen.insert(key).inserted, consume(58) else { return nil }
      if key == "protocol_version" {
        whitespace()
        guard offset < bytes.count, bytes[offset] == 49 || bytes[offset] == 51 else { return nil }
        protocolVersion = bytes[offset] == 51 ? 3 : 1
        offset += 1
      } else if key == "description" {
        guard let value = string(), !value.isEmpty, value.utf8.count <= 4096 else { return nil }
        text = value
      } else {
        return nil
      }
    }
    guard consume(125), seen == ["protocol_version", "description"] else { return nil }
    whitespace()
    return offset == bytes.count ? text : nil
  }
}

final class NonCopyingTextView: NSTextView {
  override func menu(for event: NSEvent) -> NSMenu? { nil }
  override func validRequestor(
    forSendType sendType: NSPasteboard.PasteboardType?,
    returnType: NSPasteboard.PasteboardType?
  ) -> Any? { nil }
  override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
    false
  }
}

@MainActor
final class ReviewController: NSObject, NSWindowDelegate {
  var descriptionText: String
  var window: NSWindow?
  var textView: NSTextView?
  var timer: Timer?
  var revealed = false
  var completed = false
  var choice = "indeterminate"
  let categories = [
    "verifier_mismatch_asserted", "grant_or_code_asserted",
    "client_redirect_configuration_asserted", "indeterminate",
  ]
  var radios: [NSButton] = []

  init(_ description: String) { descriptionText = description }

  func button(_ title: String, action: Selector) -> NSButton {
    let button = NSButton(title: title, target: self, action: action)
    button.bezelStyle = .rounded
    return button
  }

  func start() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.mainMenu = NSMenu()
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 760, height: 620),
      styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = "Provider 文字語義檢視（本機 Human）"
    window.isRestorable = false
    window.isReleasedWhenClosed = false
    window.isExcludedFromWindowsMenu = true
    window.sharingType = .none
    window.delegate = self
    self.window = window
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.spacing = 18
    stack.edgeInsets = NSEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
    let prompt = NSTextField(
      wrappingLabelWithString:
        "文字目前密封。只有你按下「顯示一次」才會呈現，最多 60 秒。\n請勿截圖、複製或記錄原文；未操作 30 秒即丟棄。\n這是你的語義觀察，不是 PKCE 因果證明。")
    stack.addArrangedSubview(prompt)
    stack.addArrangedSubview(button("顯示一次", action: #selector(reveal)))
    stack.addArrangedSubview(button("不檢視並關閉", action: #selector(decline)))
    window.contentView = stack
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    arm(seconds: 30)
  }

  func arm(seconds: TimeInterval) {
    timer?.invalidate()
    timer = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.finish(status: "expired", confirmed: false) }
    }
    if let timer { RunLoop.main.add(timer, forMode: .common) }
  }

  @objc func reveal() {
    guard !revealed, !completed, let window else { return }
    revealed = true
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 12
    stack.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
    let note = NSTextField(
      wrappingLabelWithString:
        "請閱讀完整文字，選擇它是否明說當次拒絕原因。條件、否定、例子、多候選或矛盾請選無法判定。\n此觀察不能替代遠端證明。60 秒後自動關閉，無第二次顯示。")
    stack.addArrangedSubview(note)
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    scroll.borderType = .bezelBorder
    let text = NonCopyingTextView(frame: NSRect(x: 0, y: 0, width: 690, height: 260))
    text.isEditable = false
    text.isSelectable = false
    text.isRichText = false
    text.isAutomaticLinkDetectionEnabled = false
    text.isAutomaticDataDetectionEnabled = false
    text.isAutomaticTextReplacementEnabled = false
    text.isAutomaticSpellingCorrectionEnabled = false
    text.isGrammarCheckingEnabled = false
    text.isContinuousSpellCheckingEnabled = false
    text.isHorizontallyResizable = false
    text.isVerticallyResizable = true
    text.textContainer?.widthTracksTextView = true
    text.textContainerInset = NSSize(width: 10, height: 10)
    text.font = .systemFont(ofSize: 14)
    text.string = descriptionText
    descriptionText = ""
    textView = text
    scroll.documentView = text
    scroll.heightAnchor.constraint(equalToConstant: 260).isActive = true
    scroll.widthAnchor.constraint(equalToConstant: 690).isActive = true
    stack.addArrangedSubview(scroll)
    let labels = [
      "明確斷言 verifier／challenge 不相符是當次拒絕原因",
      "明確斷言 grant／code 問題是當次拒絕原因",
      "明確斷言 client／redirect／configuration 問題是當次拒絕原因",
      "無法判定（含否定、條件、例子、矛盾或不完整）",
    ]
    for (index, title) in labels.enumerated() {
      let radio = NSButton(
        radioButtonWithTitle: title, target: self, action: #selector(selectChoice(_:)))
      radio.tag = index
      radio.state = index == 3 ? .on : .off
      radios.append(radio)
      stack.addArrangedSubview(radio)
    }
    let row = NSStackView(views: [
      button("確認這個語義觀察", action: #selector(confirm)),
      button("無法檢視並關閉", action: #selector(decline)),
    ])
    stack.addArrangedSubview(row)
    window.contentView = stack
    arm(seconds: 60)
  }

  @objc func selectChoice(_ sender: NSButton) {
    guard categories.indices.contains(sender.tag) else { return }
    choice = categories[sender.tag]
    for radio in radios { radio.state = radio === sender ? .on : .off }
  }

  @objc func confirm() { finish(status: "confirmed", confirmed: true) }
  @objc func decline() { finish(status: "declined", confirmed: false) }
  func windowWillClose(_ notification: Notification) {
    finish(status: "declined", confirmed: false)
  }

  func finish(status: String, confirmed: Bool) {
    guard !completed else { return }
    completed = true
    timer?.invalidate()
    timer = nil
    descriptionText = ""
    textView?.string = ""
    textView = nil
    radios.removeAll()
    window?.orderOut(nil)
    window?.contentView = nil
    window?.delegate = nil
    window?.close()
    window = nil
    emit(
      ReviewOutput(
        semanticCategory: confirmed && revealed ? choice : "indeterminate",
        reviewStatus: status, revealStarted: revealed,
        userConfirmed: confirmed && revealed))
  }
}

// W: Copy-only acknowledgement. No semantic answer or source text is emitted.
enum DescriptionCopyStatus: String, Encodable {
  case copied, cancelled, expired, unreviewable
}

struct DescriptionCopyOutput: Encodable {
  let protocolVersion = 3
  let copyStatus: DescriptionCopyStatus
  private enum CodingKeys: String, CodingKey {
    case protocolVersion = "protocol_version"
    case copyStatus = "copy_status"
  }
}

func emitCopy(_ status: DescriptionCopyStatus) -> Never {
  let output = DescriptionCopyOutput(copyStatus: status)
  if let data = try? JSONEncoder().encode(output), data.count <= 512 {
    FileHandle.standardOutput.write(data)
  }
  exit(0)
}

@MainActor
final class DescriptionCopyState {
  private var description: String
  private let write: (String) -> Bool
  private(set) var status: DescriptionCopyStatus?

  init(_ description: String, write: @escaping (String) -> Bool) {
    self.description = description
    self.write = write
  }

  func explicitMouseClick(_ isMouseClick: Bool) {
    guard status == nil, isMouseClick else { return }
    status = write(description) ? .copied : .unreviewable
    description = ""
  }

  func end(_ status: DescriptionCopyStatus) {
    guard self.status == nil else { return }
    self.status = status
    description = ""
  }
}

@MainActor
final class MouseOnlyCopyButton: NSButton {
  private(set) var handlingMouseClick = false

  override func mouseDown(with event: NSEvent) {
    guard event.type == .leftMouseDown else { return }
    handlingMouseClick = true
    defer { handlingMouseClick = false }
    super.mouseDown(with: event)
  }

  override func keyDown(with event: NSEvent) {
    // No keyboard copy action.
  }
  override func performKeyEquivalent(with event: NSEvent) -> Bool { false }
}

@MainActor
final class DescriptionCopyController: NSObject, NSWindowDelegate {
  let state: DescriptionCopyState
  var window: NSWindow?
  var timer: Timer?
  var completed = false

  init(
    _ description: String,
    write: @escaping (String) -> Bool = { text in
      NSPasteboard.general.clearContents()
      return NSPasteboard.general.setString(text, forType: .string)
    }
  ) {
    state = DescriptionCopyState(description, write: write)
  }

  func start() {
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.mainMenu = NSMenu()
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 690, height: 360),
      styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = "單欄描述複製：隱私風險確認"
    window.isRestorable = false
    window.isReleasedWhenClosed = false
    window.sharingType = .none
    window.delegate = self
    self.window = window
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.spacing = 20
    stack.edgeInsets = NSEdgeInsets(top: 26, left: 30, bottom: 26, right: 30)
    let warning = NSTextField(
      wrappingLabelWithString:
        "只有按下「複製單一描述」才會把這一欄完整文字寫入剪貼簿；此窗不顯示原文。\n"
        + "其他程式、剪貼簿同步或歷史工具可能讀取並留存；你手動貼給 AI 後，內容可能離開 Mac 並留於服務或對話。\n"
        + "安全檢查不能保證排除未知秘密，也不能保證清除。我們不讀取既有剪貼簿、不自動還原或清除、不自動傳送。\n"
        + "複製只記操作，不代表語義確認或 PKCE 證明。30 秒未操作即取消本次機會。")
    stack.addArrangedSubview(warning)
    let copy = MouseOnlyCopyButton(
      title: "複製單一描述", target: self, action: #selector(copyDescription(_:)))
    copy.bezelStyle = .rounded
    copy.keyEquivalent = ""
    let cancel = NSButton(title: "取消", target: self, action: #selector(cancel))
    cancel.bezelStyle = .rounded
    cancel.keyEquivalent = "\u{1b}"
    stack.addArrangedSubview(copy)
    stack.addArrangedSubview(cancel)
    window.contentView = stack
    window.defaultButtonCell = nil
    window.initialFirstResponder = cancel
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    timer = Timer(timeInterval: 30, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.finish(.expired) }
    }
    if let timer { RunLoop.main.add(timer, forMode: .common) }
  }

  @objc func copyDescription(_ sender: MouseOnlyCopyButton) {
    guard !completed, sender.handlingMouseClick else { return }
    state.explicitMouseClick(true)
    finish(state.status ?? .unreviewable)
  }

  @objc func cancel() { finish(.cancelled) }
  func windowWillClose(_ notification: Notification) { finish(.cancelled) }

  func finish(_ status: DescriptionCopyStatus) {
    guard !completed else { return }
    completed = true
    timer?.invalidate()
    timer = nil
    state.end(status)
    window?.orderOut(nil)
    window?.contentView = nil
    window?.delegate = nil
    window?.close()
    window = nil
    emitCopy(state.status ?? .unreviewable)
  }
}

// V: Same installed-only operation for normal v2 and the compile-time synthetic runner.
struct LocalTranslationResult: Sendable {
  var status: String
  var text = ""
}

func translatedTextAllowed(_ text: String) -> Bool {
  guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
    text.utf8.count <= 8192
  else { return false }
  let blocked: Set<UInt32> = [
    0x061c, 0x200e, 0x200f, 0x202a, 0x202b, 0x202c,
    0x202d, 0x202e, 0x2066, 0x2067, 0x2068, 0x2069,
  ]
  guard
    !text.unicodeScalars.contains(where: {
      $0.value < 32 || (0x7f...0x9f).contains($0.value) || blocked.contains($0.value)
    })
  else { return false }
  let patterns = [
    #"(?i)(?:[a-z][a-z0-9+.-]*://|www\.|https?%3a|https?&#|https?\\u003a)"#,
    #"(?<![A-Za-z0-9_])[A-Za-z0-9_+/=-]{24,}(?![A-Za-z0-9_])"#,
  ]
  return !patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
}

func installedTranslation(_ source: String) async -> LocalTranslationResult {
  guard #available(macOS 26.0, *) else {
    return LocalTranslationResult(status: "unavailable")
  }
  guard !Task.isCancelled else { return LocalTranslationResult(status: "cancelled") }
  let english = Locale.Language(identifier: "en")
  let chinese = Locale.Language(identifier: "zh-Hant")
  guard await LanguageAvailability().status(from: english, to: chinese) == .installed else {
    return LocalTranslationResult(status: "unavailable")
  }
  guard !Task.isCancelled else { return LocalTranslationResult(status: "cancelled") }
  // This session never leaves its worker task. No download UI or prepareTranslation call.
  let session = TranslationSession(installedSource: english, target: chinese)
  defer { session.cancel() }
  guard !session.canRequestDownloads, await session.isReady else {
    return LocalTranslationResult(status: "unavailable")
  }
  guard !Task.isCancelled else { return LocalTranslationResult(status: "cancelled") }
  do {
    let response = try await session.translate(source)
    guard !Task.isCancelled else { return LocalTranslationResult(status: "cancelled") }
    guard translatedTextAllowed(response.targetText) else {
      return LocalTranslationResult(status: "translation_failed")
    }
    return LocalTranslationResult(status: "translated", text: response.targetText)
  } catch {
    return LocalTranslationResult(status: Task.isCancelled ? "cancelled" : "translation_failed")
  }
}

private actor TranslationDeadline {
  private var continuation: CheckedContinuation<LocalTranslationResult, Never>?
  private var terminal: LocalTranslationResult?
  private var worker: Task<Void, Never>?
  private var timer: Task<Void, Never>?

  func run(
    _ source: String, seconds: Double,
    operation: @escaping @Sendable (String) async -> LocalTranslationResult
  ) async -> LocalTranslationResult {
    if let terminal { return terminal }
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      worker = Task.detached { [weak self] in
        let result = await operation(source)
        await self?.finish(result)
      }
      timer = Task { [weak self] in
        do {
          try await Task.sleep(for: .seconds(seconds))
          await self?.finish(LocalTranslationResult(status: "timed_out"))
        } catch {
          // Timer cancellation never changes the already sealed result.
        }
      }
    }
  }

  func finish(_ result: LocalTranslationResult) {
    guard terminal == nil else { return }
    terminal = result
    continuation?.resume(returning: result)
    continuation = nil
    worker?.cancel()
    timer?.cancel()
    worker = nil
    timer = nil
  }
}

func translateForReview(
  _ source: String, seconds: Double = 20,
  operation: @escaping @Sendable (String) async -> LocalTranslationResult = installedTranslation
) async -> LocalTranslationResult {
  guard !source.isEmpty, source.utf8.count <= 4096 else {
    return LocalTranslationResult(status: "translation_failed")
  }
  let deadline = TranslationDeadline()
  return await withTaskCancellationHandler {
    let result = await deadline.run(source, seconds: seconds, operation: operation)
    guard !Task.isCancelled else { return LocalTranslationResult(status: "cancelled") }
    guard result.status != "translated" || translatedTextAllowed(result.text) else {
      return LocalTranslationResult(status: "translation_failed")
    }
    return result
  } onCancel: {
    Task { await deadline.finish(LocalTranslationResult(status: "cancelled")) }
  }
}

#if SYNTHETIC_TRANSLATION_VALIDATION
  // This entry is absent from the normal GUI build. Only frozen public synthetic input may exit.
  struct SyntheticTranslationFixture: Decodable {
    let schemaVersion: Int
    let cases: [Record]
    struct Record: Decodable {
      let id: String
      let description: String
    }
    private enum CodingKeys: String, CodingKey {
      case schemaVersion = "schema_version"
      case cases
    }
  }

  func runFrozenSyntheticTranslations() async -> Int32 {
    guard CommandLine.arguments.count == 1,
      ((try? FileHandle.standardInput.read(upToCount: 1)) ?? Data()).isEmpty
    else { return 2 }
    let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .appendingPathComponent("fixtures/semantic-review-zh-v1.json")
    let expectedSHA = "2be946fe6ce64f5ed29e39aaa8c183e336b5112271e1482f7410f9ee3d387827"
    guard let raw = try? Data(contentsOf: path), raw.count <= 131072,
      SHA256.hash(data: raw).map({ String(format: "%02x", $0) }).joined() == expectedSHA,
      let fixture = try? JSONDecoder().decode(SyntheticTranslationFixture.self, from: raw),
      fixture.schemaVersion == 1, fixture.cases.count == 16
    else { return 2 }
    for (index, record) in fixture.cases.enumerated() {
      guard record.id == String(format: "v%02d", index + 1),
        !record.description.isEmpty, record.description.utf8.count <= 4096
      else { return 2 }
      let result = await translateForReview(record.description)
      var output = [
        "kind": "public_synthetic_translation_validation", "id": record.id,
        "translation_status": result.status,
      ]
      if result.status == "translated" { output["translated_text"] = result.text }
      guard let encoded = try? JSONSerialization.data(withJSONObject: output, options: .sortedKeys)
      else { return 2 }
      FileHandle.standardOutput.write(encoded)
      FileHandle.standardOutput.write(Data([10]))
      if result.status != "translated" { return 2 }
    }
    return 0
  }
#endif

// V_NORMAL_ENTRY
#if SYNTHETIC_TRANSLATION_VALIDATION
  Task { exit(await runFrozenSyntheticTranslations()) }
  dispatchMain()
#else
  var input = (try? FileHandle.standardInput.read(upToCount: 16385)) ?? Data()
  guard input.count <= 16384, String(data: input, encoding: .utf8) != nil else {
    emit(ReviewOutput(), status: 2)
  }
  var parser = InputParser(bytes: Array(input))
  var parsedDescription = parser.description()
  let requestProtocolVersion = parser.protocolVersion
  input = Data()
  parser = InputParser(bytes: [])
  guard parsedDescription != nil else { emit(ReviewOutput(), status: 2) }
  if CommandLine.arguments.dropFirst() == ["--protocol-check"] {
    if requestProtocolVersion == 3 { emitCopy(.unreviewable) }
    emit(ReviewOutput())
  }
  guard CommandLine.arguments.count == 1 else { emit(ReviewOutput(), status: 2) }
  if requestProtocolVersion == 3 {
    let controller = DescriptionCopyController(parsedDescription!)
    parsedDescription = nil
    controller.start()
    NSApplication.shared.run()
  } else {
    let controller = ReviewController(parsedDescription!)
    parsedDescription = nil
    controller.start()
    NSApplication.shared.run()
  }

#endif
