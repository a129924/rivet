import AsyncLifecycleProbe
import Foundation

@main
struct Probe {
  static func main() async throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    var failed = false
    for scenario in Scenario.allCases {
      let report = await run(scenario)
      var line = try encoder.encode(report)
      line.append(0x0A)
      FileHandle.standardOutput.write(line)
      failed = failed || !report.failures.isEmpty
    }
    if failed { exit(1) }
  }
}
