public struct HTTPHeaders: Equatable, ExpressibleByDictionaryLiteral, Sendable {
    public let values: [String: String]

    public init(_ values: [String: String] = [:]) {
        self.values = values
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}
