public struct HTTPHeaders: Equatable, ExpressibleByDictionaryLiteral, Sendable {
  public let values: [String: String]

  public init(_ values: [String: String] = [:]) {
    self.init(normalizing: values.sorted { $0.key < $1.key })
  }

  public init(dictionaryLiteral elements: (String, String)...) {
    self.init(normalizing: elements)
  }

  private init(normalizing elements: [(String, String)]) {
    var values: [String: String] = [:]

    for (name, value) in elements {
      values[name.lowercased()] = value
    }

    self.values = values
  }
}
