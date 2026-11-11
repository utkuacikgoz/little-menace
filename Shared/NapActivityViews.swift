import AppIntents
import SwiftUI
import MenaceCore

/// Review S29 (DEBUG only): four looks for the nap Live Activity. A a countdown; B a bar filling as it rests;
/// C a "do not disturb" sign; D the bar plus a Wake button that wakes it grumpy, as in the app.
enum NapLook: String, CaseIterable {
    case countdown, progress, sign, wakeButton
}

/// The Lock Screen banner (and the expanded Dynamic Island body).
struct NapBanner: View {
    let look: NapLook
    let attributes: NapAttributes
    let state: NapAttributes.ContentState
    /// False in the in-app review gallery, where intent buttons can't run: same look, no action.
    var interactive = true

    var body: some View {
        HStack(spacing: 14) {
            GremlinView(pose: .pose(for: .asleep), hat: attributes.hat, neck: attributes.neck, fur: attributes.fur,
                        size: 64, animated: false)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                switch look {
                case .sign:
                    Text("Shh. Napping.").font(.system(.headline, design: .rounded).weight(.black))
                    HStack(spacing: 4) {
                        Text("Back in")
                        Text(timerInterval: Date()...state.wakesAt, countsDown: true).monospacedDigit()
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .opacity(0.8)
                default:
                    Text("\(attributes.name) is napping").font(.system(.headline, design: .rounded).weight(.heavy)).lineLimit(1)
                    if look == .countdown {
                        HStack(spacing: 4) {
                            Text("Wakes in")
                            Text(timerInterval: Date()...state.wakesAt, countsDown: true).monospacedDigit()
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .opacity(0.8)
                    } else {
                        ProgressView(timerInterval: state.startedAt...state.wakesAt, countsDown: false) {
                            EmptyView()
                        } currentValueLabel: {
                            Text(timerInterval: Date()...state.wakesAt, countsDown: true).monospacedDigit()
                        }
                        .tint(Color(hex: 0xFFD46B))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                    }
                }
                if look == .wakeButton {
                    Group {
                        if interactive {
                            Button(intent: WakeGremlinIntent()) { wakeLabel }
                        } else {
                            Button {} label: { wakeLabel }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0xFF7A2F))
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Ink.eye)
        .padding(16)
    }

    private var wakeLabel: some View {
        Label("Wake it (it’ll be grumpy)", systemImage: "alarm.fill")
            .font(.system(.caption, design: .rounded).weight(.heavy))
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
