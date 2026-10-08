import Testing

@testable import RefreshCore

@Test func rfc7636Vector() {
  #expect(
    PKCE.challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
      == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
}
