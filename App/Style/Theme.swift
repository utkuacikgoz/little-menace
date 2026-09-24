import SwiftUI
import MenaceCore

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// One dominant background per theme, with a deeper night variant for dark mode.
struct ThemePalette {
    let day: Color
    let night: Color
    let glow: Color
    let starry: Bool

    func background(_ scheme: ColorScheme) -> Color { scheme == .dark ? night : day }

    static func forID(_ id: String) -> ThemePalette {
        switch id {
        case "grape": return ThemePalette(day: Color(hex: 0x7B4DFF), night: Color(hex: 0x3F1FA6), glow: Color(hex: 0xB9A2FF), starry: false)
        case "pool": return ThemePalette(day: Color(hex: 0x14B0E0), night: Color(hex: 0x0A5F80), glow: Color(hex: 0x9BE6FF), starry: false)
        case "bubblegum": return ThemePalette(day: Color(hex: 0xFF6FB5), night: Color(hex: 0xA33570), glow: Color(hex: 0xFFC2DF), starry: false)
        case "midnight": return ThemePalette(day: Color(hex: 0x1D2560), night: Color(hex: 0x0D1236), glow: Color(hex: 0x6F7BFF), starry: true)
        default: return ThemePalette(day: Color(hex: 0xFF7A2F), night: Color(hex: 0xB9480F), glow: Color(hex: 0xFFC49B), starry: false)
        }
    }
}

enum Ink {
    static let body = Color(hex: 0x241F33)
    static let bodyLight = Color(hex: 0x3A3350)
    static let bodyDark = Color(hex: 0x16121F)
    static let bellyDark = Color(hex: 0x2E2842)
    static let iris = Color(hex: 0xE59A2E)
    static let irisLight = Color(hex: 0xFFD46B)
    static let belly = Color(hex: 0x3B3452)
    static let eye = Color(hex: 0xFFF7EA)
    static let pupil = Color(hex: 0x120F1C)
    static let blush = Color(hex: 0xFF8FA3)
    static let mouth = Color(hex: 0x5A1830)
    static let tongue = Color(hex: 0xFF6F86)
    static let cream = Color(hex: 0xFFF3DF)
}

/// Full-bleed theme background: one colour, a soft glow behind the gremlin, stars for Midnight.
struct ThemeBackground: View {
    let themeID: String
    var dimmed = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThemePalette.forID(themeID)
        ZStack {
            palette.background(scheme)
            RadialGradient(colors: [palette.glow.opacity(0.55), .clear], center: .init(x: 0.5, y: 0.52), startRadius: 10, endRadius: 320)
            if palette.starry { Starfield() }
            if dimmed { Color.black.opacity(0.35) }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: dimmed)
    }
}

private struct Starfield: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SplitMix64(seed: 7)
            for _ in 0..<60 {
                let x = Double.random(in: 0...1, using: &rng) * size.width
                let y = Double.random(in: 0...1, using: &rng) * size.height
                let r = Double.random(in: 0.6...1.8, using: &rng)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(0.7)))
            }
        }
        .accessibilityHidden(true)
    }
}
