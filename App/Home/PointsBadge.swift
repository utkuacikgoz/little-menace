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

/// The score on the home screen: a big number with today's gains and losses under it.
/// Tapping it opens the points page.
struct PointsBadge: View {
    @Environment(GameModel.self) private var model
    var open: () -> Void

    var body: some View {
        let s = model.state
        let today = model.game.days.dayKey(model.now)
        let gained = s.points.day == today ? s.points.gainedToday : 0
        let lost = s.points.day == today ? s.points.lostToday : 0
        Button(action: open) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").foregroundStyle(Ink.irisLight)
                    Text(s.points.total, format: .number)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(s.points.total)))
                }
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                // The change pops on the free left side, so nothing shifts and the menu stays clear.
                .overlay(alignment: .leading) {
                    if let d = model.pointsDelta {
                        // A zero-width frame anchored at the star's left edge; the chip grows leftwards from it.
                        PointsDeltaChip(amount: d.amount)
                            .fixedSize()
                            .frame(width: 0, alignment: .trailing)
                            .offset(x: -8)
                            .id(d.id)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
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
            }
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        .buttonStyle(SquishButtonStyle())
        // One plain button for VoiceOver, so the scoreboard's words don't show up on their own.
        .accessibilityRepresentation {
            Button("Points", action: open)
                .accessibilityValue("\(s.points.total). Today plus \(gained), minus \(lost).")
                .accessibilityHint("Shows how points work")
        }
        .accessibilityIdentifier("points")
    }
}
