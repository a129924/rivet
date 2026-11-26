import SwiftUI

struct RivetBrandMark: View {
  let size: CGFloat
  let foreground: Color

  var body: some View {
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
        path, with: .color(foreground),
        style: StrokeStyle(lineWidth: 1.7 * scale, lineCap: .round))
    }
    .frame(width: size, height: size)
  }
}
