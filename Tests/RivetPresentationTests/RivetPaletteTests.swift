import AppKit
import SwiftUI
import Testing

@testable import RivetPresentation

struct RivetPaletteTests {
  private struct Sample {
    let name: String
    let value: Color
    let rgb: Int
  }

  @MainActor
  @Test(arguments: [false, true])
  func resolvesSharedRolesInSRGB(dark: Bool) throws {
    let palette = RivetPalette(dark: dark)
    let roles: [Sample] = [
      .init(name: "background", value: palette.background, rgb: dark ? 0x161C26 : 0xFCFDFF),
      .init(name: "primary", value: palette.primary, rgb: dark ? 0xF4F6FA : 0x192533),
      .init(name: "secondary", value: palette.secondary, rgb: dark ? 0x9AA9B9 : 0x647386),
      .init(name: "surface", value: palette.surface, rgb: dark ? 0x222C39 : 0xF1F4F8),
    ]

    for role in roles {
      let color = try #require(NSColor(role.value).usingColorSpace(.sRGB))
      let components = [color.redComponent, color.greenComponent, color.blueComponent]
      let rgb = components.reduce(0) { (result, component) in
        (result << 8) | Int((component * 255).rounded())
      }
      #expect(rgb == role.rgb, "\(role.name) in \(dark ? "Dark" : "Light")")
      #expect(Int((color.alphaComponent * 255).rounded()) == 255)
    }
  }
}
