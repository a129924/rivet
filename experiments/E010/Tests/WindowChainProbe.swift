import Foundation
@main enum WindowChainProbe {
  static func main() {
    do {
      let args = CommandLine.arguments
      let root = URL(fileURLWithPath: args[1]); let (global, raw) = try LiveGate.object(root, "global.json")
      guard args.count == 4, let seconds = Double(args[3]) else { throw ProbeError.guardRejected }
      if args[2] == "--synthetic-consent" {
        guard global["synthetic"] as? Bool == true else { throw ProbeError.guardRejected }
        try LiveGate.validateMainConsent(root, global: global, now: Date(timeIntervalSince1970: seconds))
      } else {
        guard let number = Int(args[2]) else { throw ProbeError.guardRejected }
        try LiveGate.validateWindowChain(root, global: global, globalHash: LiveGate.hash(raw), number: number, now: Date(timeIntervalSince1970: seconds))
      }
      print("accepted")
    } catch { print("rejected"); exit(2) }
  }
}
