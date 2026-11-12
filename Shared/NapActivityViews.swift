import SwiftUI
import MenaceCore

/// The Lock Screen banner (and the expanded Dynamic Island body): who is napping and a countdown to waking.
struct NapBanner: View {
    let attributes: NapAttributes
    let state: NapAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            GremlinView(pose: .pose(for: .asleep), hat: attributes.hat, neck: attributes.neck, fur: attributes.fur,
                        size: 64, animated: false)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(attributes.name) is napping").font(.system(.headline, design: .rounded).weight(.heavy)).lineLimit(1)
                HStack(spacing: 4) {
                    Text("Wakes in")
                    Text(timerInterval: Date()...state.wakesAt, countsDown: true).monospacedDigit()
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .opacity(0.8)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Ink.eye)
        .padding(16)
    }
}

/// Dynamic Island, compact: a moon on the left, the countdown on the right.
struct NapIslandLeading: View {
    var body: some View {
        Image(systemName: "moon.zzz.fill").foregroundStyle(Color(hex: 0xFFD46B))
    }
}

struct NapIslandTrailing: View {
    let state: NapAttributes.ContentState
    var body: some View {
        Text(timerInterval: Date()...state.wakesAt, countsDown: true)
            .monospacedDigit()
            .frame(maxWidth: 48)
            .foregroundStyle(Color(hex: 0xFFD46B))
    }
}
