import Foundation

final class MemoryStore: ExperimentStore {
  var data: Data?
  var operations: [String] = []
  var failure: ProbeError?
  func save(_ data: Data) throws { operations.append("save"); if let failure { throw failure }; self.data = data }
  func load() throws -> Data? { operations.append("load"); if let failure { throw failure }; return data }
  func delete() throws { operations.append("delete"); if let failure { throw failure }; data = nil }
}
