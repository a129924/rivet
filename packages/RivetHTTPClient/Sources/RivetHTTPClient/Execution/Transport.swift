import Foundation

public protocol Transport: Sendable {
    func execute(_ request: URLRequest) async throws -> HTTPResponse
}
