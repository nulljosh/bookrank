import SwiftUI

/// The Kernel mark, drawn from brand/mark.svg in its 1024 box and scaled to `side`.
/// Three rounded lines (the last one shorter) and the seed that sits under the end of them.
enum KernelMarkGeometry {
    static let unit: CGFloat = 1024
    static let strokeWidth: CGFloat = 84
    /// (from, to) for each line, in SVG units.
    static let lines: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 262, y: 352), CGPoint(x: 762, y: 352)),
        (CGPoint(x: 262, y: 512), CGPoint(x: 762, y: 512)),
        (CGPoint(x: 262, y: 672), CGPoint(x: 520, y: 672)),
    ]
}

/// One of the three lines. A Shape, so `.trim` can draw it on.
struct MarkLine: Shape {
    let index: Int
    func path(in rect: CGRect) -> Path {
        let s = rect.width / KernelMarkGeometry.unit
        let (a, b) = KernelMarkGeometry.lines[index]
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + a.x * s, y: rect.minY + a.y * s))
        p.addLine(to: CGPoint(x: rect.minX + b.x * s, y: rect.minY + b.y * s))
        return p
    }
}

/// The seed: the closed teardrop from brand/mark.svg.
struct MarkSeed: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / KernelMarkGeometry.unit
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(650, 716))
        p.addCurve(to: pt(600, 652), control1: pt(629, 712), control2: pt(600, 684))
        p.addCurve(to: pt(650, 602), control1: pt(600, 625), control2: pt(622, 602))
        p.addCurve(to: pt(700, 652), control1: pt(678, 602), control2: pt(700, 625))
        p.addCurve(to: pt(650, 716), control1: pt(700, 684), control2: pt(671, 712))
        p.closeSubpath()
        return p
    }
}

/// The mark at a fixed size. Each line and the seed are driven by the caller, so the splash can
/// animate them and the onboarding can show the finished mark.
struct KernelMark: View {
    let side: CGFloat
    var lines: [Bool] = [true, true, true]
    var seed: Bool = true
    var color: Color = amber

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                MarkLine(index: i)
                    .trim(from: 0, to: lines[i] ? 1 : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: KernelMarkGeometry.strokeWidth * side / KernelMarkGeometry.unit, lineCap: .round))
            }
            MarkSeed()
                .fill(color)
                .opacity(seed ? 1 : 0)
                .offset(y: seed ? 0 : -side * 0.08)
                .scaleEffect(seed ? 1 : 1.25)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

/// Cold-launch splash: the three lines draw left to right, the seed drops onto them with a small
/// spring, the mark holds for about a second, then the whole thing fades out and `onFinished` runs.
/// Reduce Motion: the finished mark appears at once, holds, and fades.
struct SplashView: View {
    var onFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lines = [false, false, false]
    @State private var seed = false
    @State private var fading = false
    @AppStorage("spine-theme") private var theme: String = "system"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            KernelMark(side: min(min(geo.size.width, geo.size.height) * 0.8, 320), lines: lines, seed: seed)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Self.background.ignoresSafeArea())
        // preferredColorScheme reaches the window a beat late, so a dark theme on a light phone showed the
        // splash white; set here, it applies from the first frame.
        .environment(\.colorScheme, theme == "dark" ? .dark : theme == "light" ? .light : scheme)
        .opacity(fading ? 0 : 1)
        .ignoresSafeArea()
        .task { await run() }
    }

    private static var background: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private func run() async {
        if reduceMotion {
            lines = [true, true, true]
            seed = true
            try? await Task.sleep(for: .milliseconds(1000))
        } else {
            // Lines: 0.0s, 0.15s, 0.3s, each 0.3s long, so the last one is done by 0.6s.
            for i in 0..<3 {
                withAnimation(.easeOut(duration: 0.3)) { lines[i] = true }
                try? await Task.sleep(for: .milliseconds(150))
            }
            // Seed drops onto the end of the lines at 0.6s, with a small spring.
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { seed = true }
            try? await Task.sleep(for: .milliseconds(400))   // hold until 1.0s
        }
        withAnimation(.easeOut(duration: 0.35)) { fading = true }
        try? await Task.sleep(for: .milliseconds(350))
        onFinished()
    }
}
