import SwiftUI

struct LoginStatusNotice: View {
  let content: RivetLoginStatusContent
  let completed: Bool
  let styles: LoginStyles
  @AccessibilityFocusState private var headingFocused: Bool
  @State private var activeContent: RivetLoginStatusContent?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      styles.statusIcon {
        if completed {
          Image(systemName: "checkmark.circle").font(.system(size: 24)).foregroundStyle(.green)
        } else {
          ProgressView().controlSize(.regular)
        }
      }
      styles.heading(content.title).accessibilityFocused($headingFocused)
      styles.description(content.message)
    }
    .onChange(of: content, initial: true) { _, value in
      activeContent = value
      headingFocused = false
    }
    .task(id: content) {
      let entry = content
      await Task.yield()
      guard !Task.isCancelled, activeContent == entry else { return }
      headingFocused = true
      await Task.yield()
      guard !Task.isCancelled, activeContent == entry else { return }
      LoginStyles.announce(entry.announcement)
    }
    .onDisappear {
      activeContent = nil
      headingFocused = false
    }
  }
}
