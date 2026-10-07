import AppKit
import Darwin
import Foundation
import ProbeCore

let configuration: ProbeConfiguration
do {
  configuration = try ProbeConfiguration(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
  print("用法：oauth-redirect-probe --client-id <Client-ID> [--timeout-seconds <正整數>]")
  exit(2)
}

let probe = LoopbackProbe(
  configuration: configuration,
  openBrowser: { url, callback in
    DispatchQueue.main.async {
      callback(NSWorkspace.shared.open(url))
    }
  },
  completion: { outcome in
    print(outcome.message)
    exit(outcome.exitCode)
  })
signal(SIGINT, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
interrupt.setEventHandler { probe.interrupt() }
interrupt.resume()
print("等待系統瀏覽器授權返回；按 Ctrl-C 中止。")
probe.start()
RunLoop.main.run()
