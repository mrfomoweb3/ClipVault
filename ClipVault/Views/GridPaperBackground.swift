import SwiftUI

/// The warm off-white "graph paper" canvas from the ClipVault website —
/// faint 26pt grid lines over the paper color. Used behind the popover
/// and the welcome window so the app matches the marketing site.
struct GridPaperBackground: View {
    var spacing: CGFloat = 26

    var body: some View {
        Color.cvBackground
            .overlay(
                Canvas { ctx, size in
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    ctx.stroke(path, with: .color(Color.cvBorder.opacity(0.05)), lineWidth: 1)
                }
            )
    }
}

/// A chunky, outlined "pop" pill with an offset hard shadow — the
/// website's signature button. Wrap any label in it.
struct ChunkyPill<Label: View>: View {
    var fill: Color = .cvYellow
    @ViewBuilder var label: () -> Label

    var body: some View {
        label()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.cvBorder)
                        .offset(y: 3)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.cvBorder, lineWidth: 2)
                        )
                }
            )
    }
}
