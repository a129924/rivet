import AppKit
import CryptoKit
import Darwin
import Foundation

// Public executable fingerprint only. Never place App credentials in this file.
let expectedBinarySHA256 = "781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153"

struct VerificationProcessIdentity {
  let bundleID: String?
  let bundleURL: URL?
  let executableURL: URL?
  let pid: pid_t
  let terminated: Bool
}

enum LocalLaunchFailure: String, Error {
  case invalidArguments = "參數無效；只接受已核對的 App bundle 路徑。"
  case invalidBundle = "App bundle 或執行檔指紋未通過；未啟動。"
  case existingApplication = "既有驗證 App 仍在執行；請先完成指定 App 的切換準備。"
  case terminalRequired = "請由開發端在未錄製的本機互動終端執行；未讀取設定。"
  case invalidConfiguration = "開發端設定未完整提供；未啟動。"
  case launchFailed = "新版 App 啟動失敗；未啟動 OAuth。"
  case identityMismatch = "新程序身分無法確認；不得繼續授權。"
  case selfTestFailed = "啟動器本機自我檢查失敗。"
}

@MainActor enum LocalVerificationLaunch {
  static let bundleID = "local.rivet.github-sign-in-verification"
  static let executableName = "GitHubSignInVerification"
  static let idKey = "RIVET_VERIFY_GITHUB_CLIENT_ID"
  static let secretKey = "RIVET_VERIFY_GITHUB_CLIENT_SECRET"

  static func canonical(_ url: URL) -> URL {
    url.standardizedFileURL.resolvingSymlinksInPath()
  }

  static func matches(
    _ identity: VerificationProcessIdentity, bundle: URL, executable: URL,
    previousPIDs: Set<pid_t>
  ) -> Bool {
    guard identity.bundleID == bundleID, !identity.terminated, identity.pid > 0,
      !previousPIDs.contains(identity.pid), let actualBundle = identity.bundleURL,
      let actualExecutable = identity.executableURL
    else { return false }
    return canonical(actualBundle) == canonical(bundle)
      && canonical(actualExecutable) == canonical(executable)
  }

  static func requireNoExistingApplication(_ pids: Set<pid_t>) throws {
    guard pids.isEmpty else { throw LocalLaunchFailure.existingApplication }
  }

  static func environment(clientID: String, secret: String) throws -> [String: String] {
    guard !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw LocalLaunchFailure.invalidConfiguration }
    return [idKey: clientID, secretKey: secret]
  }

  static func runningPIDs() -> Set<pid_t> {
    Set(
      NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).map(
        \.processIdentifier))
  }

  static func preflight(bundle: URL) throws -> URL {
    try requireNoExistingApplication(runningPIDs())
    guard let metadata = Bundle(url: bundle), metadata.bundleIdentifier == bundleID,
      let executable = metadata.executableURL,
      canonical(executable)
        == canonical(bundle.appendingPathComponent("Contents/MacOS/" + executableName)),
      FileManager.default.isExecutableFile(atPath: executable.path),
      expectedBinarySHA256.count == 64
    else { throw LocalLaunchFailure.invalidBundle }
    let bytes: Data
    do { bytes = try Data(contentsOf: executable) } catch { throw LocalLaunchFailure.invalidBundle }
    let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    guard digest == expectedBinarySHA256 else { throw LocalLaunchFailure.invalidBundle }
    return canonical(executable)
  }

  static func hiddenInput(prompt: String) throws -> String {
    var bytes = [CChar](repeating: 0, count: 4096)
    defer { _ = bytes.withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) } }
    let read = bytes.withUnsafeMutableBufferPointer {
      readpassphrase(prompt, $0.baseAddress, $0.count, RPP_REQUIRE_TTY)
    }
    guard read != nil else { throw LocalLaunchFailure.invalidConfiguration }
    let payload = bytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
    guard payload.count < bytes.count - 1, let value = String(bytes: payload, encoding: .utf8)
    else {
      throw LocalLaunchFailure.invalidConfiguration
    }
    return value
  }

  static func selfTest() throws {
    // Synthetic local paths and values only; no Keychain, UI, browser or launch calls.
    let bundle = URL(fileURLWithPath: "/fixture/Verification.app")
    let executable = bundle.appendingPathComponent("Contents/MacOS/" + executableName)
    let valid = VerificationProcessIdentity(
      bundleID: bundleID, bundleURL: bundle, executableURL: executable, pid: 101, terminated: false)
    guard matches(valid, bundle: bundle, executable: executable, previousPIDs: []),
      !matches(valid, bundle: bundle, executable: executable, previousPIDs: [101])
    else { throw LocalLaunchFailure.selfTestFailed }
    let invalid = [
      VerificationProcessIdentity(
        bundleID: "invalid", bundleURL: bundle, executableURL: executable, pid: 101,
        terminated: false),
      VerificationProcessIdentity(
        bundleID: bundleID, bundleURL: URL(fileURLWithPath: "/other.app"),
        executableURL: executable, pid: 101, terminated: false),
      VerificationProcessIdentity(
        bundleID: bundleID, bundleURL: bundle, executableURL: nil, pid: 101, terminated: false),
      VerificationProcessIdentity(
        bundleID: bundleID, bundleURL: bundle, executableURL: URL(fileURLWithPath: "/other"),
        pid: 101, terminated: false),
      VerificationProcessIdentity(
        bundleID: bundleID, bundleURL: bundle, executableURL: executable, pid: 0, terminated: false),
      VerificationProcessIdentity(
        bundleID: bundleID, bundleURL: bundle, executableURL: executable, pid: 101, terminated: true
      ),
    ]
    guard
      invalid.allSatisfy({ !matches($0, bundle: bundle, executable: executable, previousPIDs: []) })
    else { throw LocalLaunchFailure.selfTestFailed }
    do {
      try requireNoExistingApplication([101])
      throw LocalLaunchFailure.selfTestFailed
    } catch LocalLaunchFailure.existingApplication {}
    try requireNoExistingApplication([])
    guard try environment(clientID: "fixture-id", secret: "fixture-secret").count == 2 else {
      throw LocalLaunchFailure.selfTestFailed
    }
    for pair in [("", "fixture"), ("fixture", "  ")] {
      do {
        _ = try environment(clientID: pair.0, secret: pair.1)
        throw LocalLaunchFailure.selfTestFailed
      } catch LocalLaunchFailure.invalidConfiguration {}
    }
    print("self_test_passed=true; live_launch_performed=false; credential_input_performed=false")
  }

  static func run() async throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments == ["--self-test"] {
      try selfTest()
      return
    }
    let checkOnly = arguments.first == "--preflight"
    let args = checkOnly ? Array(arguments.dropFirst()) : arguments
    guard args.count == 2, args[0] == "--app-bundle", args[1].hasSuffix(".app") else {
      throw LocalLaunchFailure.invalidArguments
    }
    let bundle = canonical(URL(fileURLWithPath: args[1]))
    let executable = try preflight(bundle: bundle)
    if checkOnly {
      print("preflight_passed=true; credential_input_performed=false")
      return
    }
    guard isatty(STDIN_FILENO) == 1, isatty(STDOUT_FILENO) == 1, isatty(STDERR_FILENO) == 1 else {
      throw LocalLaunchFailure.terminalRequired
    }
    print("僅供 OAuth App 開發端管理者於未錄製的本機終端準備；登入驗證者不需提供 App 憑證。")
    let clientID = try hiddenInput(prompt: "開發端 App ID（隱藏輸入）：")
    let secret = try hiddenInput(prompt: "開發端 App Secret（隱藏輸入）：")
    let settings = try environment(clientID: clientID, secret: secret)
    // Recheck after human input; another app may have launched while we waited.
    let previousPIDs = runningPIDs()
    try requireNoExistingApplication(previousPIDs)
    _ = try preflight(bundle: bundle)
    let launch = NSWorkspace.OpenConfiguration()
    launch.createsNewApplicationInstance = false
    launch.allowsRunningApplicationSubstitution = false
    launch.arguments = []
    launch.environment = settings
    let app: NSRunningApplication
    do {
      app = try await NSWorkspace.shared.openApplication(at: bundle, configuration: launch)
    } catch { throw LocalLaunchFailure.launchFailed }
    let identity = VerificationProcessIdentity(
      bundleID: app.bundleIdentifier, bundleURL: app.bundleURL, executableURL: app.executableURL,
      pid: app.processIdentifier, terminated: app.isTerminated)
    guard matches(identity, bundle: bundle, executable: executable, previousPIDs: previousPIDs),
      runningPIDs() == [app.processIdentifier]
    else { throw LocalLaunchFailure.identityMismatch }
    print("launch_identity_verified=true; OAuth_started=false")
    print("請在工具確認「開發端設定已準備」；待本輪 browser／帳號 ready 後再準備手動登入。")
  }
}

Task { @MainActor in
  do {
    try await LocalVerificationLaunch.run()
    exit(0)
  } catch let failure as LocalLaunchFailure {
    print(failure.rawValue)
    exit(2)
  } catch {
    print("本機啟動準備未完成；不得啟動 OAuth。")
    exit(2)
  }
}
RunLoop.main.run()
