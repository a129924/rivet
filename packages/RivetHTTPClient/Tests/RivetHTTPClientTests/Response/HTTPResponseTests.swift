import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPResponse")
struct HTTPResponseTests {
  private struct MessagePayload: Decodable, Equatable {
    let message: String
  }

  private struct UserPayload: Decodable, Equatable {
    let displayName: String
  }

  private struct CountPayload: Decodable {
    let count: Int
  }

  private struct CustomFailurePayload: Decodable {
    init(from decoder: any Decoder) throws {
      throw CustomDecodingFailure.expected
    }
  }

  private enum CustomDecodingFailure: Error {
    case expected
  }

  enum UnvalidatedResponseCase: CaseIterable {
    case nonSuccessStatus
    case plainTextContentType
    case missingContentType

    var response: HTTPResponse {
      switch self {
      case .nonSuccessStatus:
        HTTPResponse(
          statusCode: 404,
          headers: [.contentType: "application/json"],
          body: Data(#"{"message":"hello"}"#.utf8)
        )
      case .plainTextContentType:
        HTTPResponse(
          statusCode: 200,
          headers: [.contentType: "text/plain"],
          body: Data(#"{"message":"hello"}"#.utf8)
        )
      case .missingContentType:
        HTTPResponse(
          statusCode: 200,
          headers: [:],
          body: Data(#"{"message":"hello"}"#.utf8)
        )
      }
    }
  }

  @Test
  func decodesUTF8BodyUsingDefaultEncoding() {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [.contentType: "text/plain"],
      body: Data("Rivet".utf8)
    )

    #expect(response.text() == "Rivet")
  }

  @Test
  func decodesBodyUsingExplicitEncoding() {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [:],
      body: Data([0xE9])
    )

    #expect(response.text(encoding: .isoLatin1) == "é")
  }

  @Test
  func returnsNilForBodyIncompatibleWithRequestedEncodingWithoutMutatingResponse() {
    let headers: HTTPHeaders = [.contentType: "application/octet-stream"]
    let body = Data([0xFF])
    let response = HTTPResponse(statusCode: 418, headers: headers, body: body)

    #expect(response.text() == nil)
    #expect(response.statusCode == 418)
    #expect(response.headers == headers)
    #expect(response.body == body)
  }

  @Test
  func retainsRawTransportResponseValues() {
    let response = HTTPResponse.fixture

    #expect(response.statusCode == 200)
    #expect(response.headers == [.contentType: "application/json"])
    #expect(response.body == Data("{}".utf8))
  }

  @Test
  func decodesBodyWithCallerProvidedDecoder() throws {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [.contentType: "application/json"],
      body: Data(#"{"message":"hello"}"#.utf8)
    )

    let payload = try response.json(MessagePayload.self, decoder: JSONDecoder())

    #expect(payload == MessagePayload(message: "hello"))
  }

  @Test
  func usesCallerProvidedDecoderConfiguration() throws {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [.contentType: "application/json"],
      body: Data(#"{"display_name":"Ada"}"#.utf8)
    )
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let payload = try response.json(UserPayload.self, decoder: decoder)

    #expect(payload == UserPayload(displayName: "Ada"))
  }

  @Test
  func preservesDecodingErrorForInvalidJSON() {
    let response = HTTPResponse(statusCode: 200, headers: [:], body: Data("not-json".utf8))
    var caughtError: (any Error)?

    do {
      _ = try response.json(MessagePayload.self, decoder: JSONDecoder())
    } catch {
      caughtError = error
    }

    #expect(caughtError is DecodingError)
    #expect(!(caughtError is JSONSemanticDecodingError))
  }

  @Test(arguments: UnvalidatedResponseCase.allCases)
  func decodesRawBodyWithoutResponseValidation(_ responseCase: UnvalidatedResponseCase) throws {
    let payload = try responseCase.response.json(MessagePayload.self, decoder: JSONDecoder())

    #expect(payload == MessagePayload(message: "hello"))
  }

  @Test
  func semanticallyDecodesBodyWithCallerProvidedDecoder() throws {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [.contentType: "application/json"],
      body: Data(#"{"message":"hello"}"#.utf8)
    )

    let payload = try response.jsonSemantic(MessagePayload.self, decoder: JSONDecoder())

    #expect(payload == MessagePayload(message: "hello"))
  }

  @Test
  func semanticallyUsesCallerProvidedDecoderConfiguration() throws {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [.contentType: "application/json"],
      body: Data(#"{"display_name":"Ada"}"#.utf8)
    )
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let payload = try response.jsonSemantic(UserPayload.self, decoder: decoder)

    #expect(payload == UserPayload(displayName: "Ada"))
  }

  @Test
  func mapsDataCorruptedAndRetainsUnderlyingError() {
    let response = HTTPResponse(statusCode: 200, headers: [:], body: Data("not-json".utf8))
    let error = semanticError {
      _ = try response.jsonSemantic(MessagePayload.self, decoder: JSONDecoder())
    }

    #expect(hasKind(.dataCorrupted, in: error))
    #expect(hasDecodingErrorCase(.dataCorrupted, in: error))
  }

  @Test
  func mapsKeyNotFoundAndRetainsUnderlyingError() {
    let response = HTTPResponse(statusCode: 200, headers: [:], body: Data("{}".utf8))
    let error = semanticError {
      _ = try response.jsonSemantic(MessagePayload.self, decoder: JSONDecoder())
    }

    #expect(hasKind(.keyNotFound, in: error))
    #expect(hasDecodingErrorCase(.keyNotFound, in: error))
  }

  @Test
  func mapsTypeMismatchAndRetainsUnderlyingError() {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [:],
      body: Data(#"{"count":"wrong"}"#.utf8)
    )
    let error = semanticError {
      _ = try response.jsonSemantic(CountPayload.self, decoder: JSONDecoder())
    }

    #expect(hasKind(.typeMismatch, in: error))
    #expect(hasDecodingErrorCase(.typeMismatch, in: error))
  }

  @Test
  func mapsValueNotFoundAndRetainsUnderlyingError() {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [:],
      body: Data(#"{"message":null}"#.utf8)
    )
    let error = semanticError {
      _ = try response.jsonSemantic(MessagePayload.self, decoder: JSONDecoder())
    }

    #expect(hasKind(.valueNotFound, in: error))
    #expect(hasDecodingErrorCase(.valueNotFound, in: error))
  }

  @Test
  func mapsCustomDecodableErrorToOtherAndRetainsUnderlyingError() {
    let response = HTTPResponse(statusCode: 200, headers: [:], body: Data("{}".utf8))
    let error = semanticError {
      _ = try response.jsonSemantic(CustomFailurePayload.self, decoder: JSONDecoder())
    }

    #expect(hasKind(.other, in: error))
    #expect(error?.underlyingError is CustomDecodingFailure)
  }

  @Test(arguments: UnvalidatedResponseCase.allCases)
  func semanticallyDecodesRawBodyWithoutResponseValidation(
    _ responseCase: UnvalidatedResponseCase
  ) throws {
    let response = responseCase.response
    let statusCode = response.statusCode
    let headers = response.headers
    let body = response.body

    let payload = try response.jsonSemantic(MessagePayload.self, decoder: JSONDecoder())

    #expect(payload == MessagePayload(message: "hello"))
    #expect(response.statusCode == statusCode)
    #expect(response.headers == headers)
    #expect(response.body == body)
  }

  private func semanticError(
    from operation: () throws -> Void
  ) -> JSONSemanticDecodingError? {
    do {
      try operation()
      return nil
    } catch let error as JSONSemanticDecodingError {
      return error
    } catch {
      return nil
    }
  }

  private func hasKind(
    _ expectedKind: JSONSemanticDecodingError.Kind,
    in error: JSONSemanticDecodingError?
  ) -> Bool {
    guard let error else { return false }

    switch (expectedKind, error.kind) {
    case (.dataCorrupted, .dataCorrupted),
      (.keyNotFound, .keyNotFound),
      (.typeMismatch, .typeMismatch),
      (.valueNotFound, .valueNotFound),
      (.other, .other):
      return true
    default:
      return false
    }
  }

  private func hasDecodingErrorCase(
    _ expectedKind: JSONSemanticDecodingError.Kind,
    in error: JSONSemanticDecodingError?
  ) -> Bool {
    guard let underlyingError = error?.underlyingError as? DecodingError else { return false }

    switch (expectedKind, underlyingError) {
    case (.dataCorrupted, .dataCorrupted),
      (.keyNotFound, .keyNotFound),
      (.typeMismatch, .typeMismatch),
      (.valueNotFound, .valueNotFound):
      return true
    default:
      return false
    }
  }
}
