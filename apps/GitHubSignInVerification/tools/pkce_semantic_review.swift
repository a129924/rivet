import AppKit
import Foundation

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
        guard consume(49) else { return nil }
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

var input = (try? FileHandle.standardInput.read(upToCount: 16385)) ?? Data()
guard input.count <= 16384, String(data: input, encoding: .utf8) != nil else {
  emit(ReviewOutput(), status: 2)
}
var parser = InputParser(bytes: Array(input))
var parsedDescription = parser.description()
input = Data()
parser = InputParser(bytes: [])
guard parsedDescription != nil else { emit(ReviewOutput(), status: 2) }
if CommandLine.arguments.dropFirst() == ["--protocol-check"] { emit(ReviewOutput()) }
guard CommandLine.arguments.count == 1 else { emit(ReviewOutput(), status: 2) }
let controller = ReviewController(parsedDescription!)
parsedDescription = nil
controller.start()
NSApplication.shared.run()
