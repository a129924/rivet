import AppKit
import Darwin
import Foundation
import PKCECore

let configuration: ProbeConfiguration
do {
  configuration = try ProbeConfiguration(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
  print("用法：oauth-pkce-probe --client-id <Client-ID> [--timeout-seconds <1…180>]")
  exit(2)
}

// readpassphrase restores terminal echo and re-raises caught signals after restoration.
func readSecret() -> String? {
  guard isatty(STDIN_FILENO) == 1 else { return nil }
  var buffer = [CChar](repeating: 0, count: 4096)
  defer { for index in buffer.indices { buffer[index] = 0 } }
  guard readpassphrase("Client secret（隱藏輸入）: ", &buffer, buffer.count, RPP_REQUIRE_TTY) != nil
  else { return nil }
  let secret = String(
    bytes: buffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, encoding: .utf8)
  return secret?.isEmpty == false ? secret : nil
}
guard let secret = readSecret() else {
  print("需要本機 TTY 隱藏輸入非空 secret；未執行授權。")
  exit(2)
}
let transport = LiveIO(configuration: configuration, secret: secret) { url, completion in
  DispatchQueue.main.async { completion(NSWorkspace.shared.open(url)) }
}
print("最多兩次新授權；結果只輸出遮蔽分類。按 Ctrl-C 中止。")
let task = Task {
  let result = await Experiment.run(transport: transport)
  print(result.safeReport)
  exit(result.overall == .success ? 0 : 1)
}
signal(SIGINT, SIG_IGN)
signal(SIGTERM, SIG_IGN)
let interrupts = [SIGINT, SIGTERM].map { number in
  let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
  source.setEventHandler { task.cancel() }
  source.resume()
  return source
}
RunLoop.main.run()
