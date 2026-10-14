import Foundation
import SQLiteProbeCore

@main struct ProbeMain {
  static func main() async {
    // A bounded watchdog also covers blocked child processes and fake gates.
    let watchdog = Task.detached {
      try? await Task.sleep(for: .seconds(30))
      if !Task.isCancelled {
        print("probe_status=unable_to_determine reason=watchdog_timeout")
        exit(2)
      }
    }
    defer { watchdog.cancel() }
    do {
      try await run(arguments: Array(CommandLine.arguments.dropFirst()))
    } catch {
      // Inputs are fake; report assertion labels only, never raw database errors.
      if case ProbeFailure.assertion(let message) = error {
        print("probe_status=failed assertion=\(message)")
      } else {
        print("probe_status=failed reason=unexpected_local_error")
      }
      exit(1)
    }
  }

  private static func run(arguments: [String]) async throws {
    if arguments.count == 3 && arguments[0] == "seed" {
      try require(arguments[2] == "A", "seed fixture must be A")
      try await SQLiteCredentialStore(path: arguments[1]).save(FakeCredentials.bundle("A"))
      print("child_seed=A status=passed")
      return
    }
    if arguments.count == 3 && arguments[0] == "verify" {
      try require(["A", "B"].contains(arguments[2]), "unknown fixture")
      try await RuntimeScenarios.restore(path: arguments[1], name: arguments[2])
      print("child_verify=\(arguments[2]) fields=6 refresh_calls=0 status=passed")
      return
    }
    try require(arguments.isEmpty, "usage: oauth-sqlite-probe [seed|verify DB A|B]")
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "rivet-e004-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let path = directory.appendingPathComponent("credential.sqlite").path
    try child(["seed", path, "A"])
    try child(["verify", path, "A"])
    print("T01=passed fields=6 independent_writer_and_reader=true refresh_calls=0")
    try await RuntimeScenarios.rotation(path: path)
    try child(["verify", path, "B"])
    print("T02=passed pair_changed=true fields=6 new_process=true refresh_calls=1")
    try await RuntimeScenarios.singleFlight(path: path)
    print("T03=passed demands=12 refresh_calls=1 equal_snapshots=true stale_refresh_calls=0")
    try await RuntimeScenarios.rollback(path: path)
    try child(["verify", path, "A"])
    print("T04=passed partial_sql_observed=true rollback_complete_A=true")
    try await RuntimeScenarios.persistenceFailure(path: path)
    try child(["verify", path, "A"])
    print(
      "T05=passed fake_rotation_accepted=true terminal_persist=true refresh_calls=1 save_calls=2 disk_A=true"
    )
    try await RuntimeScenarios.storageFailures(directory: directory)
    print("T06=passed empty=missingCredential corrupt=restore readonly=write_failure")
    print("overall=passed live_github=false encryption_tested=false sandbox_tested=false")
  }

  private static func child(_ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    try require(
      process.terminationReason == .exit && process.terminationStatus == 0,
      "child process must pass")
  }
}
