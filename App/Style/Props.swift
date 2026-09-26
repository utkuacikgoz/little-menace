import SwiftUI

/// The gremlin's snack. Also the feed button's icon.
struct CookieView: View {
    static let chips: [CGPoint] = [CGPoint(x: -0.2, y: -0.15), CGPoint(x: 0.18, y: -0.2), CGPoint(x: 0.05, y: 0.18), CGPoint(x: -0.22, y: 0.2), CGPoint(x: 0.25, y: 0.12)]
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xE8A04C))
            Circle().stroke(Color(hex: 0xB86F24), lineWidth: size * 0.06)
            ForEach(0..<Self.chips.count, id: \.self) { i in
                Circle().fill(Color(hex: 0x5A3214))
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: size * Self.chips[i].x, y: size * Self.chips[i].y)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct CushionView: View {
    var color: Color = Color(hex: 0xFFD166)
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(color)
            RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.black.opacity(0.12), lineWidth: 3)
            Circle().fill(.black.opacity(0.15)).frame(width: 10, height: 10)
        }
        .frame(width: 96, height: 70)
        .accessibilityHidden(true)
    }
}

/// Round icon button with an optional thin ring that shows a need (0…1).
struct RingButton<Icon: View>: View {
    var ring: Double?
    var label: String
    /// Short text under the button, e.g. the need as a percentage.
    var caption: String? = nil
    var action: () -> Void
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(.white.opacity(0.22))
                    if let ring {
                        Circle().stroke(.white.opacity(0.25), lineWidth: 4)
                        Circle().trim(from: 0, to: max(0.02, ring))
                            .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.5), value: ring)
                    }
                    icon()
                }
                .frame(width: 66, height: 66)
                .contentShape(Circle())
                if let caption {
                    // Dark pill: readable on every theme, light or dark.
                    Text(caption)
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                        .dynamicTypeSize(...DynamicTypeSize.xLarge) // stays one line at the largest sizes
                        .foregroundStyle(Ink.eye)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Ink.body.opacity(0.85), in: Capsule())
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel(label)
        .accessibilityValue(ring.map { "\(Int($0 * 100)) percent" } ?? "")
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct SpeechBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .foregroundStyle(Ink.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Ink.eye, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            .accessibilityHidden(true) // announced when shown
    }
}

struct ToastChip: View {
    let toast: Toast
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.symbol).font(.title3.weight(.bold))
            if let text = toast.text {
                Text(text).font(.system(.headline, design: .rounded).weight(.heavy))
            }
        }
        .foregroundStyle(Ink.body)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Ink.eye, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}

