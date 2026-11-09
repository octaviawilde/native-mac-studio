import SwiftUI

/// Y2K cute-gore palette.
enum Palette {
    static let night = Color(red: 0.10, green: 0.02, blue: 0.13)
    static let plum = Color(red: 0.32, green: 0.04, blue: 0.30)
    static let hotPink = Color(red: 1.00, green: 0.18, blue: 0.58)
    static let bubblegum = Color(red: 1.00, green: 0.62, blue: 0.84)
    static let blood = Color(red: 0.78, green: 0.02, blue: 0.10)
    static let darkBlood = Color(red: 0.45, green: 0.00, blue: 0.05)
    static let chrome = LinearGradient(colors: [.white, Color(red: 0.80, green: 0.78, blue: 0.92), .white,
                                                Color(red: 0.98, green: 0.70, blue: 0.88), .white],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Four-pointed Y2K sparkle.
struct Sparkle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), w = r.width / 2, h = r.height / 2, k: CGFloat = 0.18
        p.move(to: CGPoint(x: c.x, y: c.y - h))
        p.addQuadCurve(to: CGPoint(x: c.x + w, y: c.y), control: CGPoint(x: c.x + w * k, y: c.y - h * k))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + h), control: CGPoint(x: c.x + w * k, y: c.y + h * k))
        p.addQuadCurve(to: CGPoint(x: c.x - w, y: c.y), control: CGPoint(x: c.x - w * k, y: c.y + h * k))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - h), control: CGPoint(x: c.x - w * k, y: c.y - h * k))
        return p
    }
}

/// A single blood drop (round bottom, pointed top).
struct Drop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY - r.width / 2),
                   control1: CGPoint(x: r.midX + r.width * 0.15, y: r.minY + r.height * 0.35),
                   control2: CGPoint(x: r.maxX, y: r.midY))
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY - r.width / 2), radius: r.width / 2,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.midY),
                   control2: CGPoint(x: r.midX - r.width * 0.15, y: r.minY + r.height * 0.35))
        return p
    }
}

/// Blood dripping from a top edge; `phase` (0...1) slowly stretches the drips.
struct Drips: Shape {
    var phase: CGFloat
    var animatableData: CGFloat { get { phase } set { phase = newValue } }

    func path(in r: CGRect) -> Path {
        var p = Path()
        let lengths: [CGFloat] = [0.35, 0.8, 0.5, 1.0, 0.3, 0.65, 0.45, 0.9]
        let n = lengths.count, step = r.width / CGFloat(n)
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        for i in 0..<n {
            let x0 = r.minX + CGFloat(i) * step
            let grow = 0.75 + 0.25 * sin((phase + CGFloat(i) * 0.37) * .pi * 2)
            let len = r.height * lengths[i] * grow
            let w = step * 0.42
            p.addLine(to: CGPoint(x: x0 + step / 2 - w / 2, y: r.minY + r.height * 0.12))
            p.addLine(to: CGPoint(x: x0 + step / 2 - w / 2, y: r.minY + len - w / 2))
            p.addArc(center: CGPoint(x: x0 + step / 2, y: r.minY + len - w / 2), radius: w / 2,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            p.addLine(to: CGPoint(x: x0 + step / 2 + w / 2, y: r.minY + r.height * 0.12))
            p.addLine(to: CGPoint(x: x0 + step, y: r.minY + r.height * 0.12))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Animated backdrop: plum-to-bubblegum gradient, a receding Y2K grid, twinkling sparkles,
/// slowly falling blood drops and floating hearts.
struct Backdrop: View {
    private struct Bit { let x, y, size, speed, offset: Double; let kind: Int }
    private let bits: [Bit] = (0..<46).map { i in
        var g = SeededRandom(seed: UInt64(i) &* 2654435761 &+ 7)
        return Bit(x: g.next(), y: g.next(), size: 6 + g.next() * 22, speed: 0.015 + g.next() * 0.04,
                   offset: g.next(), kind: i % 5)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(Gradient(colors: [Palette.night, Palette.plum, Palette.hotPink.opacity(0.85), Palette.bubblegum]),
                                               startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                drawGrid(&ctx, size, t)
                for b in bits {
                    let x = b.x * size.width
                    switch b.kind {
                    case 0, 1:  // sparkle, twinkling
                        let tw = 0.35 + 0.65 * abs(sin(t * (1.2 + b.speed * 20) + b.offset * 6))
                        let s = b.size * tw
                        ctx.fill(Sparkle().path(in: CGRect(x: x - s / 2, y: b.y * size.height - s / 2, width: s, height: s)),
                                 with: .color(.white.opacity(0.9 * tw)))
                    case 2:  // falling blood drop
                        let y = ((b.y + t * b.speed).truncatingRemainder(dividingBy: 1.1) - 0.05) * size.height
                        let w = b.size * 0.45
                        ctx.fill(Drop().path(in: CGRect(x: x, y: y, width: w, height: w * 1.5)),
                                 with: .color(Palette.blood.opacity(0.75)))
                    default:  // floating heart
                        let y = ((b.y - t * b.speed * 0.6).truncatingRemainder(dividingBy: 1.0) + 1.0)
                            .truncatingRemainder(dividingBy: 1.0) * size.height
                        let sway = sin(t * 0.8 + b.offset * 6) * 14
                        ctx.draw(Text(Image(systemName: "heart.fill")).font(.system(size: b.size))
                                    .foregroundColor(Palette.bubblegum.opacity(0.55)),
                                 at: CGPoint(x: x + sway, y: y))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func drawGrid(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let horizon = size.height * 0.62
        var lines = Path()
        for i in 0...18 {  // perspective lines
            let x = size.width * (CGFloat(i) / 18)
            lines.move(to: CGPoint(x: size.width / 2 + (x - size.width / 2) * 0.08, y: horizon))
            lines.addLine(to: CGPoint(x: size.width / 2 + (x - size.width / 2) * 2.2, y: size.height))
        }
        let scroll = t.truncatingRemainder(dividingBy: 1.0)
        for i in 0..<10 {  // rows scrolling toward the viewer
            let f = (CGFloat(i) + CGFloat(scroll)) / 10
            let y = horizon + (size.height - horizon) * f * f
            lines.move(to: CGPoint(x: 0, y: y)); lines.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(lines, with: .color(.white.opacity(0.22)), lineWidth: 1.2)
    }
}

/// Small deterministic generator so the backdrop looks the same every launch.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed | 1 }
    mutating func next() -> Double {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return Double(state % 10_000) / 10_000
    }
}
