import SwiftUI
import MenaceCore

/// Under the score while the gremlin is cross: a temper gauge (Annoyed → Angry → Furious) and what to do about it.
struct MoodMeter: View {
    let mood: Mood
    let temper: Double

    private static let steps = [Color(hex: 0xFFD166), Color(hex: 0xFF8A3D), Color(hex: 0xFF3B3B)]

    var body: some View {
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
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Ink.body.opacity(0.85), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mood: \(mood.label)")
        .accessibilityHint(mood == .furious ? "Pet it to calm it down" : "")
    }
}

/// Red sky while it's furious.
struct FuriousSky: View {
    var body: some View {
        ZStack {
            Color(hex: 0xB71C1C).opacity(0.8)
            RadialGradient(colors: [.clear, .black.opacity(0.3)], center: .center, startRadius: 120, endRadius: 520)
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

/// What's left on the floor after force-feeding. Tap to clean.
struct Puddle: View {
    private let goo = Color(hex: 0x9BD84E)
    private let gooDark = Color(hex: 0x6FAE2E)

    var body: some View {
        ZStack {
            Ellipse().fill(gooDark).frame(width: 128, height: 34).offset(y: 3)
            Ellipse().fill(goo).frame(width: 124, height: 30)
            Ellipse().fill(goo).frame(width: 44, height: 18).offset(x: 62, y: 7)
            Circle().fill(goo).frame(width: 12, height: 12).offset(x: -72, y: -5)
            Circle().fill(goo).frame(width: 7, height: 7).offset(x: 84, y: -8)
            Ellipse().fill(.white.opacity(0.45)).frame(width: 30, height: 6).offset(x: -26, y: -7)
            Circle().fill(Color(hex: 0xC98A3D)).frame(width: 8, height: 8).offset(x: 12, y: 2)
            Circle().fill(Color(hex: 0xC98A3D)).frame(width: 6, height: 6).offset(x: -10, y: 6)
            Circle().fill(Color(hex: 0xC98A3D)).frame(width: 5, height: 5).offset(x: 34, y: -3)
        }
        .frame(width: 180, height: 60)
    }
}

/// Small cream "tap to clean" label.
struct CleanChip: View {
    var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
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

/// A matchstick propping an eye open (awake out of spite).
struct Matchstick: View {
    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color(hex: 0xE53935)).frame(width: 9, height: 11)
            Rectangle().fill(Color(hex: 0xE8C27A)).frame(width: 5, height: 40)
        }
        .accessibilityHidden(true)
    }
}
