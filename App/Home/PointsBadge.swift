import SwiftUI
import UIKit
import MenaceCore

enum PointColor {
    /// Bright enough to read on the dark pills.
    static let gainOnDark = Color(hex: 0x7CFFB2)
    static let lossOnDark = Color(hex: 0xFF9A9A)
    /// Dark on white and cream, light on dark backgrounds.
    static let gain = adaptive(light: 0x157A43, dark: 0x7CFFB2)
    static let loss = adaptive(light: 0xC62828, dark: 0xFF9A9A)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

func signedPoints(_ n: Int) -> String { n >= 0 ? "+\(n)" : "−\(-n)" }

/// "+2" / "−5" that pops next to the score when points change.
struct PointsDeltaChip: View {
    let amount: Int
    var body: some View {
        Text(signedPoints(amount))
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .monospacedDigit()
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .foregroundStyle(amount > 0 ? PointColor.gainOnDark : PointColor.lossOnDark)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Ink.body.opacity(0.9), in: Capsule())
            .accessibilityHidden(true)
    }
}

/// The score on the home screen. Tapping it opens the points page.
struct PointsBadge: View {
    @Environment(GameModel.self) private var model
    var open: () -> Void

    var body: some View {
        let s = model.state
        Button(action: open) {
            switch DesignAlt.current {
            case "B": ringStyle(s)
            case "C": scoreboardStyle(s)
            default: pillStyle(s)
            }
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel("Points")
        .accessibilityValue("\(s.points.total)")
        .accessibilityHint("Shows how points work")
        .accessibilityIdentifier("points")
    }

    // A: a dark pill with a star, next to where the delta pops.
    private func pillStyle(_ s: PetState) -> some View {
        HStack(spacing: 8) {
            pill(s)
            delta
        }
    }

    private func pill(_ s: PetState) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill").foregroundStyle(Ink.irisLight)
            Text(s.points.total, format: .number)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(s.points.total)))
        }
        .font(.system(.title3, design: .rounded).weight(.heavy))
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .foregroundStyle(Ink.eye)
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Ink.body.opacity(0.85), in: Capsule())
    }

    // B: a level ring with the score beside it.
    private func ringStyle(_ s: PetState) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Ink.body.opacity(0.85))
                Circle().stroke(.white.opacity(0.2), lineWidth: 4).padding(3)
                Circle().trim(from: 0, to: max(0.03, levelProgress(s)))
                    .stroke(Ink.irisLight, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(3)
                Text("\(s.level)")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Ink.eye)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 0) {
                Text(s.points.total, format: .number)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(s.points.total)))
                Text("points")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .opacity(0.85)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            delta
        }
    }

    // C: a big scoreboard number with today's gains and losses under it.
    private func scoreboardStyle(_ s: PetState) -> some View {
        let today = model.game.days.dayKey(model.now)
        let book = s.points
        let gained = book.day == today ? book.gainedToday : 0
        let lost = book.day == today ? book.lostToday : 0
        return VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundStyle(Ink.irisLight)
                Text(s.points.total, format: .number)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(s.points.total)))
            }
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            HStack(spacing: 6) {
                Text("today")
                Text(signedPoints(gained)).foregroundStyle(PointColor.gainOnDark)
                if lost > 0 { Text(signedPoints(-lost)).foregroundStyle(PointColor.lossOnDark) }
            }
            .font(.system(.caption, design: .rounded).weight(.heavy))
            .monospacedDigit()
            .foregroundStyle(Ink.eye)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(Ink.body.opacity(0.85), in: Capsule())
            delta.frame(height: 30)
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    @ViewBuilder private var delta: some View {
        if let d = model.pointsDelta {
            PointsDeltaChip(amount: d.amount)
                .id(d.id)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
        }
    }

    private func levelProgress(_ s: PetState) -> Double {
        let lo = Tuning.xpForLevel(s.level), hi = Tuning.xpForLevel(s.level + 1)
        return Double(s.xp - lo) / Double(max(1, hi - lo))
    }
}
