import Foundation

public enum HTTPURLValidationError: Error, Equatable, Sendable {
    case unsupportedScheme(String?)
    case missingHost
}

public struct HTTPURL: Equatable, Sendable {
    public let value: URL

    public init(_ value: URL) throws(HTTPURLValidationError) {
        guard let scheme = value.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw .unsupportedScheme(value.scheme)
        }

        guard value.host != nil else {
            throw .missingHost
        }

        self.value = value
    }
}

public struct HTTPMethod: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let get = HTTPMethod(rawValue: "GET")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let patch = HTTPMethod(rawValue: "PATCH")
    public static let delete = HTTPMethod(rawValue: "DELETE")
}

public struct HTTPHeaders: Equatable, ExpressibleByDictionaryLiteral, Sendable {
    public let values: [String: String]

    public init(_ values: [String: String] = [:]) {
        self.values = values
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}

public struct HTTPRequest: Equatable, Sendable {
    public let url: HTTPURL
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let body: Data?

    public init(
        url: HTTPURL,
        method: HTTPMethod,
        headers: HTTPHeaders = HTTPHeaders(),
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

public struct HTTPResponse: Equatable, Sendable {
    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Data

    public init(statusCode: Int, headers: HTTPHeaders, body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public protocol Transport: Sendable {
    func execute(_ request: URLRequest) async throws -> HTTPResponse
}

public struct Requester {
    private let transport: any Transport

    public init(transport: any Transport) {
        self.transport = transport
    }

    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url.value)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (name, value) in request.headers.values {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        return try await transport.execute(urlRequest)
    }
}

public struct HTTPClient {
    private let requester: Requester

    public init(transport: any Transport) {
        requester = Requester(transport: transport)
    }

    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await requester.execute(request)
    }
}
