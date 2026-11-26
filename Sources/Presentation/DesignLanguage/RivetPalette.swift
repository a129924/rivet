import SwiftUI

struct RivetPalette {
  let dark: Bool

  var background: Color { Self.color(sRGB: dark ? 0x161C26 : 0xFCFDFF) }
  var primary: Color { Self.color(sRGB: dark ? 0xF4F6FA : 0x192533) }
  var secondary: Color { Self.color(sRGB: dark ? 0x9AA9B9 : 0x647386) }
  var surface: Color { Self.color(sRGB: dark ? 0x222C39 : 0xF1F4F8) }

  static func color(sRGB hex: UInt32) -> Color {
    Color(
      .sRGB, red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1
    )
  }
}
