import SwiftUI

/// Hats and neckwear, drawn in the gremlin's 200×220 design space so they follow every pose.
struct Wearables: View {
    var hat: String?
    var neck: String?

    var body: some View {
        ZStack {
            if let neck { neckwear(neck).position(x: 100, y: 172) }
            if let hat { headwear(hat).position(x: 100, y: 46) }
        }
        .frame(width: 200, height: 220)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func headwear(_ id: String) -> some View {
        switch id {
        case "leaf":
            ZStack {
                Capsule().fill(Color(hex: 0x2E8B3A)).frame(width: 3, height: 16).offset(x: 2, y: 10)
                Ellipse().fill(Color(hex: 0x4CC35A)).frame(width: 34, height: 18).rotationEffect(.degrees(-30))
                Capsule().fill(Color(hex: 0x2E8B3A)).frame(width: 24, height: 2).rotationEffect(.degrees(-30))
            }
        case "crown":
            CrownShape().fill(Color(hex: 0xFFC83D))
                .overlay(CrownShape().stroke(Color(hex: 0xC98A00), lineWidth: 2))
                .frame(width: 56, height: 30)
        case "bow":
            ZStack {
                FangShape().fill(Color(hex: 0xFF4F8B)).frame(width: 26, height: 22).rotationEffect(.degrees(90)).offset(x: -13)
                FangShape().fill(Color(hex: 0xFF4F8B)).frame(width: 26, height: 22).rotationEffect(.degrees(-90)).offset(x: 13)
                Circle().fill(Color(hex: 0xD62E6A)).frame(width: 12, height: 12)
            }
            .offset(x: 26, y: 8)
        case "nightcap":
            ZStack(alignment: .topTrailing) {
                NightcapShape().fill(Color(hex: 0x3B4BD8))
                    .overlay(NightcapShape().stroke(Color(hex: 0x27309A), lineWidth: 2))
                    .frame(width: 84, height: 54)
                Circle().fill(Ink.cream).frame(width: 16, height: 16).offset(x: 6, y: 6)
                Capsule().fill(Ink.cream).frame(width: 84, height: 12).offset(y: 44)
            }
            .offset(y: 4)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private func neckwear(_ id: String) -> some View {
        switch id {
        case "scarf":
            ZStack {
                Capsule().fill(Color(hex: 0xE63946)).frame(width: 120, height: 18)
                RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xC5283D)).frame(width: 18, height: 38).rotationEffect(.degrees(12)).offset(x: 34, y: 18)
                HStack(spacing: 10) { ForEach(0..<5, id: \.self) { _ in Capsule().fill(.white.opacity(0.5)).frame(width: 3, height: 14) } }
            }
            .offset(y: -18)
        case "bell":
            collar(Color(hex: 0x2FBF9B)) {
                ZStack {
                    Circle().fill(Color(hex: 0xFFC83D)).frame(width: 20, height: 20)
                    Capsule().fill(Color(hex: 0x9A6A00)).frame(width: 10, height: 3).offset(y: 3)
                }
            }
        case "moon":
            collar(Color(hex: 0x3B4BD8)) {
                ZStack {
                    Circle().fill(Color(hex: 0xFFE27A)).frame(width: 20, height: 20)
                    Circle().fill(Color(hex: 0x3B4BD8)).frame(width: 16, height: 16).offset(x: 6, y: -3)
                }
            }
        default:
            EmptyView()
        }
    }

    private func collar<Charm: View>(_ color: Color, @ViewBuilder charm: () -> Charm) -> some View {
        ZStack {
            Capsule().fill(color).frame(width: 112, height: 10)
            charm().offset(y: 12)
        }
        .offset(y: -18)
    }
}

struct CrownShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.3))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.25, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.25, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.3))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct NightcapShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 6), control: CGPoint(x: r.minX + r.width * 0.2, y: r.minY - 10))
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.maxY), control: CGPoint(x: r.maxX - r.width * 0.25, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// One-piece sock outline: ribbed cuff, straight leg, rounded heel, foot and toe.
/// The foot points right; the leg grows with the rect's height.
struct SockShape: Shape {
    func path(in r: CGRect) -> Path {
        let legL = r.minX + 4, legR = r.minX + r.width * 0.62
        let footTop = r.maxY - r.height * 0.3
        var p = Path()
        p.move(to: CGPoint(x: legL, y: r.minY + 4))
        p.addQuadCurve(to: CGPoint(x: legR, y: r.minY + 4), control: CGPoint(x: (legL + legR) / 2, y: r.minY))
        p.addLine(to: CGPoint(x: legR, y: footTop - 10))
        p.addQuadCurve(to: CGPoint(x: legR + 14, y: footTop), control: CGPoint(x: legR, y: footTop))
        p.addLine(to: CGPoint(x: r.maxX - 16, y: footTop))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: footTop + (r.maxY - footTop) / 2), control: CGPoint(x: r.maxX, y: footTop))
        p.addQuadCurve(to: CGPoint(x: r.maxX - 16, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: legL + 22, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: legL, y: r.maxY - 24), control: CGPoint(x: legL - 2, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// The tug-of-war sock. `stretch` elongates the leg as the rope moves.
struct SockView: View {
    var style: String
    var stretch: CGFloat = 0

    private static let width: CGFloat = 76
    private static let height: CGFloat = 126

    var body: some View {
        let base = style == "glow" ? Color(hex: 0x9CFF6E) : style == "argyle" ? Color(hex: 0x7A5CFF) : Ink.cream
        let accent = style == "glow" ? Color(hex: 0x2BD66A) : style == "argyle" ? Color(hex: 0xFFC83D) : Color(hex: 0xE63946)
        let h = Self.height + stretch
        let legW = Self.width * 0.62
        ZStack(alignment: .topLeading) {
            base
            // Ribbed cuff.
            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { _ in Capsule().fill(.black.opacity(0.08)).frame(width: 2) }
            }
            .frame(width: legW, height: 16)
            .background(base.opacity(0.9))
            // Leg pattern.
            VStack(spacing: style == "argyle" ? 6 : 9) {
                ForEach(0..<4, id: \.self) { i in
                    if style == "argyle" {
                        Rectangle().fill(accent).frame(width: 12, height: 12).rotationEffect(.degrees(45))
                            .offset(x: i.isMultiple(of: 2) ? -7 : 7)
                    } else {
                        Rectangle().fill(accent).frame(height: 6)
                    }
                }
            }
            .frame(width: legW)
            .padding(.top, 24)
            // Heel and toe patches.
            Circle().fill(accent).frame(width: 34, height: 34).offset(x: -8, y: h - 26)
            Circle().fill(accent).frame(width: 34, height: 34).offset(x: Self.width - 22, y: h - 38)
        }
        .frame(width: Self.width, height: h, alignment: .topLeading)
        .clipShape(SockShape())
        .overlay(SockShape().stroke(.black.opacity(0.12), lineWidth: 1.5))
        .shadow(color: style == "glow" ? accent.opacity(0.9) : .clear, radius: 12)
        .accessibilityHidden(true)
    }
}
