import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPURL")
struct HTTPURLTests {
  @Test(arguments: ["http://example.com", "https://example.com/path"])
  func acceptsHTTPSchemes(value: String) throws {
    let url = try #require(URL(string: value))

    let httpURL = try HTTPURL(url)

    #expect(httpURL.value == url)
  }

  @Test(arguments: ["ftp://example.com", "file:///tmp/example"])
  func rejectsUnsupportedScheme(value: String) throws {
    let url = try #require(URL(string: value))

    #expect(throws: HTTPURLValidationError.unsupportedScheme(url.scheme)) {
      try HTTPURL(url)
    }
  }

  @Test
  func rejectsMissingHost() throws {
    let url = try #require(URL(string: "https:///path"))

    #expect(throws: HTTPURLValidationError.missingHost) {
      try HTTPURL(url)
    }
  }

  @Test
  func rejectsEmptyHost() throws {
    let url = try #require(URL(string: "https://:443/path"))

    #expect(throws: HTTPURLValidationError.missingHost) {
      try HTTPURL(url)
    }
  }
}
