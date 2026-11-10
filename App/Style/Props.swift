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
    enum Look { case flat, puffy, box }
    var color: Color = Color(hex: 0xFFD166)
    var look: Look = .flat

    var body: some View {
        Group {
            switch look {
            case .flat: flat
            case .puffy: puffy
            case .box: box
            }
        }
        .frame(width: 96, height: 70)
        .accessibilityHidden(true)
    }

    private var flat: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(color)
            RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.black.opacity(0.12), lineWidth: 3)
            Circle().fill(.black.opacity(0.15)).frame(width: 10, height: 10)
        }
    }

    /// Review S27 B/D: a plump cushion with a seam, a button tuft and corner tassels.
    private var puffy: some View {
        let base = Color(hex: 0xF4B942), dark = Color(hex: 0xC98A1F)
        return ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFFD77A), base, dark], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 28, style: .continuous).inset(by: 7)
                .stroke(dark.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            Ellipse().fill(.white.opacity(0.35)).frame(width: 46, height: 12).offset(x: -14, y: -20).blur(radius: 1)
            Circle().fill(dark).frame(width: 11, height: 11)
                .overlay(Circle().fill(.white.opacity(0.4)).frame(width: 4, height: 4).offset(x: -1.5, y: -1.5))
                .shadow(color: dark.opacity(0.6), radius: 2, y: 1)
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(Color(hex: 0xE5283B)).frame(width: 9, height: 9)
                    .offset(x: i % 2 == 0 ? -44 : 44, y: i < 2 ? -31 : 31)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
    }

    /// Review S27 C: a cardboard box with its flaps half open.
    private var box: some View {
        let card = Color(hex: 0xC98A4A), shade = Color(hex: 0x9C6430)
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [card, shade], startPoint: .top, endPoint: .bottom))
                .padding(.top, 14)
            Rectangle().fill(Color(hex: 0xE8C27A).opacity(0.8)).frame(width: 18).padding(.top, 14)
            HStack(spacing: 4) {
                Rectangle().fill(card).frame(height: 14).rotationEffect(.degrees(-14), anchor: .bottomTrailing)
                Rectangle().fill(card).frame(height: 14).rotationEffect(.degrees(14), anchor: .bottomLeading)
            }
            .overlay(alignment: .bottom) { Rectangle().fill(shade).frame(height: 2) }
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
    }
}

/// Round icon button with an optional thin ring that shows a need (0…1).
struct RingButton<Icon: View>: View {
    var ring: Double?
    var label: String
    /// Short text under the button, e.g. the need as a percentage.
    var caption: String? = nil
    /// Review S23 B–D: a darker disc so the white ring and icon pass contrast on bright themes.
    var darkDisc = false
    /// Review S23 D: a small "!" when this need is low.
    var lowBadge = false
    var action: () -> Void
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(darkDisc ? Ink.body.opacity(0.32) : .white.opacity(0.22))
                    if let ring {
                        // On the dark disc the ring sits just inside the edge, so all of it is on the dark.
                        Circle().inset(by: darkDisc ? 3 : 0).stroke(.white.opacity(0.25), lineWidth: 4)
                        Circle().inset(by: darkDisc ? 3 : 0).trim(from: 0, to: max(0.02, ring))
                            .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.5), value: ring)
                    }
                    icon()
                }
                .frame(width: 66, height: 66)
                .overlay(alignment: .topTrailing) {
                    if lowBadge {
                        Text("!")
                            .font(.system(.subheadline, design: .rounded).weight(.black))
                            .dynamicTypeSize(...DynamicTypeSize.xLarge)
                            .foregroundStyle(Ink.eye)
                            .frame(width: 24, height: 24)
                            .background(Color(hex: 0xE5283B), in: Circle())
                            .overlay(Circle().stroke(Ink.eye, lineWidth: 2))
                            .offset(x: 4, y: -4)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityHidden(true)
                    }
                }
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
        // Speak what the screen shows ("Hungry 50%"), not a bare percentage.
        .accessibilityValue(caption ?? ring.map { "\(Int($0 * 100)) percent" } ?? "")
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Squish(pressed: configuration.isPressed) { configuration.label }
    }
}

/// The press squish; with Reduce Motion a brief dim instead.
private struct Squish<Label: View>: View {
    let pressed: Bool
    @ViewBuilder var label: () -> Label
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        label()
            .scaleEffect(pressed && !reduceMotion ? 0.88 : 1)
            .opacity(pressed && reduceMotion ? 0.7 : 1)
            .animation(reduceMotion ? .easeOut(duration: 0.1) : .spring(response: 0.25, dampingFraction: 0.5), value: pressed)
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

