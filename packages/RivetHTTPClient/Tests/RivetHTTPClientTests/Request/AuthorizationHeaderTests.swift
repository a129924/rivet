import RivetHTTPClient
import Testing

@Suite("AuthorizationHeader")
struct AuthorizationHeaderTests {
  @Test(arguments: ["token-123", "AZaz09-._~+/", "a", "a=", "a==", "a===", "a========"])
  func formatsEveryAllowedTokenWithoutRewriting(token: String) throws {
    #expect(try AuthorizationHeader.bearerValue(token: token) == "Bearer \(token)")
    #expect(
      try AuthorizationHeader.applyingBearer(token: token, to: [:])
        == ["Authorization": "Bearer \(token)"])
  }

  @Test(arguments: [
    "", "=", "===", "=abc", "a=b", "a==b", " a", "a ", "a b", "a\tb",
    "a\r", "a\n", "a\r\nInjected: value", "a\0b", "é", "a😀", "a:", "a@", "a%", "a\\b", "a?",
  ])
  func rejectsInvalidTokensWithoutChangingInput(token: String) {
    let headers = ["authorization": "Basic old", "X-Trace": "original"]
    let snapshot = headers

    #expect(throws: AuthorizationHeaderError.invalidToken) {
      try AuthorizationHeader.bearerValue(token: token)
    }
    #expect(throws: AuthorizationHeaderError.invalidToken) {
      try AuthorizationHeader.applyingBearer(token: token, to: headers)
    }
    #expect(headers == snapshot)
  }

  @Test(arguments: ["Authorization", "authorization", "AUTHORIZATION", "aUtHoRiZaTiOn"])
  func replacesExistingAuthorizationRegardlessOfCasing(headerName: String) throws {
    let result = try AuthorizationHeader.applyingBearer(
      token: "new-token",
      to: [headerName: "Basic old"]
    )

    #expect(result == ["Authorization": "Bearer new-token"])
  }

  @Test
  func removesAllAuthorizationVariantsAndPreservesOtherHeaders() throws {
    let headers = [
      "Authorization": "Basic old",
      "authorization": "Bearer stale",
      "AUTHORIZATION": "another old value",
      "aUtHoRiZaTiOn": "last old value",
      "Accept": "application/json",
      "X-Trace": "Keep My Case",
      "x-trace": "separate original entry",
      "X-Empty": "",
      "X-Unicode": "繁體中文",
    ]
    let snapshot = headers

    let result = try AuthorizationHeader.applyingBearer(token: "new-token", to: headers)

    #expect(
      result == [
        "Authorization": "Bearer new-token",
        "Accept": "application/json",
        "X-Trace": "Keep My Case",
        "x-trace": "separate original entry",
        "X-Empty": "",
        "X-Unicode": "繁體中文",
      ])
    #expect(headers == snapshot)
  }

  @Test
  func matchesOnlyTheExactASCIIHeaderName() throws {
    let headers = [
      " Authorization": "leading space",
      "Authorization ": "trailing space",
      "X-Authorization": "different name",
      "Authorızation": "non-ASCII dotless i",
      "Authorization\u{0}": "embedded NUL",
    ]

    let result = try AuthorizationHeader.applyingBearer(token: "a", to: headers)

    for (key, value) in headers {
      #expect(result[key] == value)
    }
    #expect(result["Authorization"] == "Bearer a")
    #expect(result.count == headers.count + 1)
  }

  @Test
  func addsAuthorizationAndPreservesAnInputWithoutIt() throws {
    let headers = ["Accept": "application/json"]
    let result = try AuthorizationHeader.applyingBearer(token: "a", to: headers)

    #expect(result == ["Accept": "application/json", "Authorization": "Bearer a"])
    #expect(headers == ["Accept": "application/json"])
  }

  @Test
  func isIdempotentAndCanReplaceTheToken() throws {
    let first = try AuthorizationHeader.applyingBearer(
      token: "first",
      to: ["authorization": "old", "X-Trace": "keep"]
    )
    let repeated = try AuthorizationHeader.applyingBearer(token: "first", to: first)
    let replaced = try AuthorizationHeader.applyingBearer(token: "second", to: repeated)

    #expect(repeated == first)
    #expect(replaced == ["Authorization": "Bearer second", "X-Trace": "keep"])
    #expect(first == ["Authorization": "Bearer first", "X-Trace": "keep"])
  }

  @Test
  func dictionaryInsertionOrderDoesNotChangeTheResultContent() throws {
    let entries = [
      ("Authorization", "old"), ("authorization", "stale"), ("X-Trace", "keep"),
      ("Accept", "application/json"),
    ]
    let forward = Dictionary(uniqueKeysWithValues: entries)
    let reverse = Dictionary(uniqueKeysWithValues: entries.reversed())

    #expect(
      try AuthorizationHeader.applyingBearer(token: "a", to: forward)
        == AuthorizationHeader.applyingBearer(token: "a", to: reverse))
  }

  @Test
  func errorDiagnosticsDoNotContainTheInvalidToken() throws {
    let sentinel = "invalid-token-sentinel-do-not-log!"
    let error = try #require(
      #expect(throws: AuthorizationHeaderError.self) {
        try AuthorizationHeader.bearerValue(token: sentinel)
      })
    let mirror = Mirror(reflecting: error)
    let descriptions = [
      String(describing: error),
      String(reflecting: error),
      String(describing: mirror),
      String(describing: mirror.children.map(\.value)),
    ]

    #expect(error == .invalidToken)
    #expect(mirror.children.isEmpty)
    for description in descriptions {
      #expect(!description.contains(sentinel))
    }
  }
}
