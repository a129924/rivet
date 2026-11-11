import SwiftUI

struct RivetLoginPalette {
  let dark: Bool
  var background: Color { Color(hex: dark ? 0x161C26 : 0xFCFDFF) }
  var primary: Color { Color(hex: dark ? 0xF4F6FA : 0x192533) }
  var secondary: Color { Color(hex: dark ? 0x9AA9B9 : 0x647386) }
  var border: Color { Color(hex: dark ? 0x323C49 : 0xE1E7EE) }
  var surface: Color { Color(hex: dark ? 0x222C39 : 0xF1F4F8) }
  var field: Color { Color(hex: dark ? 0x19232E : 0xFFFFFF) }
  var button: Color { Color(hex: dark ? 0xF3F6FA : 0x252B33) }
  var buttonLabel: Color { Color(hex: dark ? 0x19212C : 0xFFFFFF) }
}

extension Color {
  fileprivate init(hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1
    )
  }
}

struct RivetLoginBrand: View {
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 11) {
        branchMark
        Text("RIVET").font(.system(size: 13, weight: .heavy)).tracking(1.3)
      }
      .frame(height: 36)
      Spacer().frame(height: 48)
      diffCard
        .rotationEffect(.degrees(-1.2))
      Spacer().frame(height: 30)
      Text("Review the change.\nNot the noise.")
        .font(.system(size: 23, weight: .bold)).tracking(-0.8)
        .fixedSize(horizontal: false, vertical: true)
      Text("A focused workspace for\npull request reviews.")
        .font(.system(size: 12)).lineSpacing(6)
        .foregroundStyle(Color(hex: 0xB1C3D5))
        .padding(.top, 12)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 30)
    .padding(.top, 66)
    .padding(.bottom, 32)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .foregroundStyle(Color(hex: 0xF4F9FF))
    .background {
      LinearGradient(
        colors: scheme == .dark
          ? [Color(hex: 0x19293C), Color(hex: 0x111E2E), Color(hex: 0x0E1725)]
          : [Color(hex: 0x223A54), Color(hex: 0x17293F), Color(hex: 0x0F1C2F)],
        startPoint: .topLeading, endPoint: .bottomTrailing
      )
      RadialGradient(
        colors: [Color(hex: 0x56B8BD).opacity(0.14), .clear],
        center: UnitPoint(x: 0.88, y: 0.35), startRadius: 0, endRadius: 150
      )
      Canvas { context, size in
        for horizontal in stride(from: 11.0, to: size.width, by: 21) {
          for vertical in stride(from: 11.0, to: size.height, by: 21) {
            let dot = Path(ellipseIn: CGRect(x: horizontal, y: vertical, width: 0.7, height: 0.7))
            context.fill(dot, with: .color(.white.opacity(0.03 + 0.05 * horizontal / size.width)))
          }
        }
      }
    }
    .clipped()
    .accessibilityHidden(true)
  }

  private var branchMark: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .fill(.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.24), lineWidth: 1))
      Canvas { context, size in
        let scale = size.width / 24
        var path = Path()
        for center in [CGPoint(x: 6, y: 4), CGPoint(x: 6, y: 20), CGPoint(x: 18, y: 6)] {
          path.addEllipse(
            in: CGRect(
              x: (center.x - 2) * scale, y: (center.y - 2) * scale, width: 4 * scale,
              height: 4 * scale))
        }
        path.move(to: CGPoint(x: 6 * scale, y: 6 * scale))
        path.addLine(to: CGPoint(x: 6 * scale, y: 18 * scale))
        path.move(to: CGPoint(x: 18 * scale, y: 8 * scale))
        path.addCurve(
          to: CGPoint(x: 12 * scale, y: 14 * scale),
          control1: CGPoint(x: 18 * scale, y: 11.3 * scale),
          control2: CGPoint(x: 15.3 * scale, y: 14 * scale)
        )
        path.addLine(to: CGPoint(x: 6 * scale, y: 14 * scale))
        context.stroke(
          path, with: .color(Color(hex: 0xCBE7FF)),
          style: StrokeStyle(lineWidth: 1.7 * scale, lineCap: .round))
      }
      .frame(width: 22, height: 22)
    }
    .frame(width: 36, height: 36)
  }

  private var diffCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("ReviewDiff.swift").foregroundStyle(Color(hex: 0xB1C3D5))
        Spacer(minLength: 0)
        Text("+2 −1").bold().foregroundStyle(Color(hex: 0x6EE7B7))
      }
      .font(.system(size: 10)).padding(.horizontal, 12).frame(height: 36)
      Rectangle().fill(Color(hex: 0x26394D)).frame(height: 1)
      VStack(alignment: .leading, spacing: 3) {
        Text("@@ -42,4 +42,5 @@").foregroundStyle(Color(hex: 0xADB9F1)).padding(.bottom, 5)
        diffLine("42", "func loadDiff() async {", color: 0xADB9C9)
        diffLine("43", "- let diff = raw", color: 0xF5ACAF, background: 0x512E36)
        diffLine("43", "+ let diff = parse(raw)", color: 0x9DE4BC, background: 0x1D4D3D)
        diffLine("44", "+ await render(diff)", color: 0x9DE4BC, background: 0x1D4D3D)
        diffLine("45", "}", color: 0xADB9C9)
      }
      .font(.system(size: 10.5, design: .monospaced))
      .padding(.horizontal, 9).padding(.top, 12).padding(.bottom, 15)
    }
    .frame(height: 184)
    .background(Color(hex: 0x0C1828))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x344A60), lineWidth: 1))
    .shadow(color: .black.opacity(0.2), radius: 15, y: 14)
  }

  private func diffLine(
    _ number: String, _ text: String, color: UInt32, background: UInt32? = nil
  ) -> some View {
    HStack(spacing: 8) {
      Text(number).foregroundStyle(Color(hex: 0x637B92))
      Text(text).foregroundStyle(Color(hex: color))
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 5).frame(height: 17)
    .background(
      background.map { Color(hex: $0).opacity(0.56) } ?? .clear,
      in: RoundedRectangle(cornerRadius: 4))
  }
}
