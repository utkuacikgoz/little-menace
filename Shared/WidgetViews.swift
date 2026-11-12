import AppIntents
import SwiftUI
import WidgetKit
import MenaceCore

/// One widget, any size: the gremlin and its needs as rings. Interactive: the buttons pet and feed it through the shared save.
struct GremlinWidgetView: View {
    let family: WidgetFamily
    let state: PetState
    /// False in the in-app review gallery, where intent buttons can't run: same look, no action.
    var interactive = true

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: Text(OffscreenCare.summary(state))
        case .systemMedium: medium
        default: small
        }
    }

    // MARK: Home Screen

    private var pose: GremlinPose {
        GremlinPose.base(asleep: state.isAsleep, energy: state.needs.energy, mood: state.mood)
    }

    private func gremlin(_ size: CGFloat) -> some View {
        GremlinView(pose: pose, hat: state.wardrobe.hat, neck: state.wardrobe.neck, fur: state.wardrobe.fur,
                    size: size, animated: false)
            .accessibilityHidden(true)
    }

    private var small: some View {
        VStack(spacing: 4) {
            gremlin(92)
            needRings(size: 26)
        }
    }

    private var medium: some View {
        HStack(spacing: 12) {
            gremlin(112)
            VStack(alignment: .leading, spacing: 8) {
                nameTag
                needRings(size: 30)
                Spacer(minLength: 0)
                buttons
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nameTag: some View {
        HStack(spacing: 4) {
            Text(state.titleName).lineLimit(1)
            Text("· \(state.level)").opacity(0.7)
        }
        .font(.system(.subheadline, design: .rounded).weight(.heavy))
        .foregroundStyle(Ink.eye)
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Ink.body.opacity(0.85), in: Capsule())
    }

    private func needRings(size: CGFloat) -> some View {
        HStack(spacing: 8) {
            ring(state.needs.fullness, "fork.knife", size)
            ring(state.needs.joy, "tennisball.fill", size)
            ring(state.needs.energy, "moon.fill", size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(OffscreenCare.summary(state))
    }

    private func ring(_ value: Double, _ symbol: String, _ size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Ink.body.opacity(0.35))
            Circle().inset(by: 2).trim(from: 0, to: max(0.03, value / 100))
                .stroke(Ink.eye, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: symbol).font(.system(size: size * 0.38, weight: .bold)).foregroundStyle(Ink.eye)
        }
        .frame(width: size, height: size)
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            if interactive {
                Button(intent: PetGremlinIntent()) { Label("Pet", systemImage: "hand.raised.fill") }
                Button(intent: FeedGremlinIntent()) { Label("Feed", systemImage: "fork.knife") }
            } else {
                Button {} label: { Label("Pet", systemImage: "hand.raised.fill") }
                Button {} label: { Label("Feed", systemImage: "fork.knife") }
            }
        }
        .font(.system(.caption, design: .rounded).weight(.heavy))
        .buttonStyle(.borderedProminent)
        .tint(Ink.body)
        .disabled(state.isAsleep)
    }

    // MARK: Lock Screen

    private var circular: some View {
        ZStack {
            if interactive { AccessoryWidgetBackground() }
            GremlinView(pose: pose, fur: state.wardrobe.fur, size: 46, animated: false).accessibilityHidden(true)
        }
        .accessibilityLabel(OffscreenCare.summary(state))
    }

    private var rectangular: some View {
        HStack(spacing: 6) {
            GremlinView(pose: pose, fur: state.wardrobe.fur, size: 40, animated: false).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.titleName).font(.headline).lineLimit(1)
                Text(OffscreenCare.summary(state)).font(.caption2).lineLimit(2)
            }
        }
    }
}

/// The widget's background: its theme colour, or a red sky when it's furious.
struct GremlinWidgetBackground: View {
    let state: PetState
    var body: some View {
        if state.mood == .furious && !state.isAsleep {
            ZStack { ThemeBackground(themeID: state.wardrobe.theme); FuriousSky() }
        } else {
            ThemeBackground(themeID: state.wardrobe.theme, dimmed: state.isAsleep)
        }
    }
}
