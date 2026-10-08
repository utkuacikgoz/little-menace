import SwiftUI
import MenaceCore

/// Under the score while the gremlin is cross: three steps, Annoyed → Angry → Furious.
struct MoodMeter: View {
    let mood: Mood
    let temper: Double

    private static let steps = [Color(hex: 0xFFD166), Color(hex: 0xFF8A3D), Color(hex: 0xFF3B3B)]

    var body: some View {
        Group {
            if Variant.on("S15B") { gauge } else { segments }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Ink.body.opacity(0.85), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mood: \(mood.label)")
        .accessibilityHint(mood == .furious ? "Pet it to calm it down" : "")
    }

    private var segments: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1..<4, id: \.self) { i in
                    Capsule().fill(i <= mood.rawValue ? Self.steps[i - 1] : .white.opacity(0.22))
                        .frame(width: 22, height: 8)
                }
            }
            Text(mood.label)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Ink.eye)
        }
    }

    /// Option B: a temper gauge with what to do about it.
    private var gauge: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill").foregroundStyle(Self.steps[max(0, mood.rawValue - 1)])
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.22))
                Capsule().fill(LinearGradient(colors: Self.steps, startPoint: .leading, endPoint: .trailing))
                    .frame(width: 90 * min(1, temper / Tuning.temperMax))
            }
            .frame(width: 90, height: 10)
            Text(mood == .furious ? "Pet to calm" : mood.label)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Ink.eye)
        }
    }
}

/// Red sky while it's furious.
struct FuriousSky: View {
    var storm = false
    var body: some View {
        ZStack {
            Color(hex: 0xB71C1C).opacity(storm ? 0.9 : 0.8)
            RadialGradient(colors: [.clear, .black.opacity(storm ? 0.55 : 0.3)], center: .center, startRadius: 120, endRadius: 520)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Puffs of steam rising off its head.
struct SteamPuffs: View {
    var width: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 0.3 : ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    let side: CGFloat = i % 2 == 0 ? -1 : 1
                    let phase = CGFloat((t * 0.7 + Double(i) / 6).truncatingRemainder(dividingBy: 1))
                    Circle()
                        .fill(.white.opacity(0.8 * (1 - phase)))
                        .frame(width: 14 + phase * 26, height: 14 + phase * 26)
                        .offset(x: side * (width * 0.36 + phase * 26), y: -phase * 70)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Bold comic lettering ("ACHOO!", "BLEURGH!", "FURIOUS").
struct ComicWord: View {
    let text: String
    var color = Color(hex: 0xFFD166)
    var angle = -8.0

    var body: some View {
        Text(text)
            .font(.system(size: 42, weight: .black, design: .rounded))
            .foregroundStyle(Ink.body)
            .padding(.horizontal, 16).padding(.vertical, 4)
            .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Ink.body, lineWidth: 4))
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.25), radius: 0, x: 4, y: 4)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// What's left on the floor after force-feeding. Tap to clean.
struct Puddle: View {
    var big = false
    private let goo = Color(hex: 0x9BD84E)
    private let gooDark = Color(hex: 0x6FAE2E)

    var body: some View {
        ZStack {
            Ellipse().fill(gooDark).frame(width: 128, height: 34).offset(y: 3)
            Ellipse().fill(goo).frame(width: 124, height: 30)
            Ellipse().fill(goo).frame(width: 44, height: 18).offset(x: 62, y: 7)
            Circle().fill(goo).frame(width: 12, height: 12).offset(x: -72, y: -5)
            Circle().fill(goo).frame(width: 7, height: 7).offset(x: 84, y: -8)
            if big {
                Circle().fill(goo).frame(width: 16, height: 16).offset(x: -88, y: -26)
                Circle().fill(goo).frame(width: 10, height: 10).offset(x: 70, y: -34)
                Circle().fill(goo).frame(width: 8, height: 8).offset(x: -40, y: -40)
            }
            Ellipse().fill(.white.opacity(0.45)).frame(width: 30, height: 6).offset(x: -26, y: -7)
            Circle().fill(Color(hex: 0xC98A3D)).frame(width: 8, height: 8).offset(x: 12, y: 2)
            Circle().fill(Color(hex: 0xC98A3D)).frame(width: 6, height: 6).offset(x: -10, y: 6)
            Circle().fill(Color(hex: 0xC98A3D)).frame(width: 5, height: 5).offset(x: 34, y: -3)
        }
        .scaleEffect(big ? 1.25 : 1)
        .frame(width: 180, height: 60)
    }
}

/// Two little flies circling a mess.
struct Flies: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 0.5 : ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<2, id: \.self) { i in
                    let a = t * (2.2 + Double(i) * 0.7) + Double(i) * 2
                    fly.offset(x: CGFloat(cos(a)) * 40, y: CGFloat(sin(a * 1.3)) * 14 - 30)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var fly: some View {
        ZStack {
            Ellipse().fill(.white.opacity(0.8)).frame(width: 8, height: 5).offset(x: -3, y: -4)
            Ellipse().fill(.white.opacity(0.8)).frame(width: 8, height: 5).offset(x: 3, y: -4)
            Circle().fill(Ink.pupil).frame(width: 7, height: 7)
        }
    }
}

/// Small cream "tap to clean" label.
struct CleanChip: View {
    var text: String
    var symbol = "sparkles"

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(.subheadline, design: .rounded).weight(.heavy))
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .foregroundStyle(Ink.body)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Ink.eye, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

/// A matchstick propping an eye open (spite, option C).
struct Matchstick: View {
    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color(hex: 0xE53935)).frame(width: 9, height: 11)
            Rectangle().fill(Color(hex: 0xE8C27A)).frame(width: 5, height: 40)
        }
        .accessibilityHidden(true)
    }
}
