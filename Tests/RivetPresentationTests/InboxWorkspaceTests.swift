import Testing

@testable import RivetPresentation

struct InboxWorkspaceTests {
  @Test func compactLayoutUsesTheFullWorkspaceWidth() {
    #expect(InboxWorkspaceLayout.isCompact(width: 420))
    #expect(InboxWorkspaceLayout.isCompact(width: 619))
    #expect(!InboxWorkspaceLayout.isCompact(width: 620))
    #expect(!InboxWorkspaceLayout.isCompact(width: 940))
  }
}
