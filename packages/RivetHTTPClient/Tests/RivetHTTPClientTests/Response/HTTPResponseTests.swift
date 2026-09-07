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

  enum UnvalidatedResponseCase: CaseIterable {
    case nonSuccessStatus
    case plainTextContentType
    case missingContentType

    var response: HTTPResponse {
      switch self {
      case .nonSuccessStatus:
        HTTPResponse(
          statusCode: 404,
          headers: ["Content-Type": "application/json"],
          body: Data(#"{"message":"hello"}"#.utf8)
        )
      case .plainTextContentType:
        HTTPResponse(
          statusCode: 200,
          headers: ["Content-Type": "text/plain"],
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
  func retainsRawTransportResponseValues() {
    let response = HTTPResponse.fixture

    #expect(response.statusCode == 200)
    #expect(response.headers == ["Content-Type": "application/json"])
    #expect(response.body == Data("{}".utf8))
  }

  @Test
  func decodesBodyWithCallerProvidedDecoder() throws {
    let response = HTTPResponse(
      statusCode: 200,
      headers: ["Content-Type": "application/json"],
      body: Data(#"{"message":"hello"}"#.utf8)
    )

    let payload = try response.json(MessagePayload.self, decoder: JSONDecoder())

    #expect(payload == MessagePayload(message: "hello"))
  }

  @Test
  func usesCallerProvidedDecoderConfiguration() throws {
    let response = HTTPResponse(
      statusCode: 200,
      headers: ["Content-Type": "application/json"],
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
  }

  @Test(arguments: UnvalidatedResponseCase.allCases)
  func decodesRawBodyWithoutResponseValidation(_ responseCase: UnvalidatedResponseCase) throws {
    let payload = try responseCase.response.json(MessagePayload.self, decoder: JSONDecoder())

    #expect(payload == MessagePayload(message: "hello"))
  }
}
