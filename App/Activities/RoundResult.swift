import SwiftUI
import MenaceCore

/// The end of a round: a full-screen celebration (confetti on a win), what happened, the points counting up,
/// the level bar filling, the rewards earned, the gremlin's own take on it, and a brag button.
struct RoundResult: View {
    let result: ActivityResult
    let points: Int
    let rewards: [Toast]
    var focus: AccessibilityFocusState<Bool>.Binding
    let replay: () -> Void
    let done: () -> Void

    @Environment(GameModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0
    @State private var progress = 0.0
    @State private var line: String?

    var body: some View {
        celebration
            .task { await countUp() }
            .onAppear { line = model.roundLine(won: result.won) }
    }

    // MARK: Layouts

    private var celebration: some View {
        GeometryReader { geo in
            ZStack {
                if result.won { Confetti(still: reduceMotion).ignoresSafeArea().allowsHitTesting(false) }
                VStack(spacing: 18) {
                    Spacer(minLength: 40)
                    Text(headline)
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(Ink.eye)
                        .padding(.horizontal, 22).padding(.vertical, 8)
                        .background(Ink.body.opacity(0.85), in: Capsule())
                    if let line {
                        SpeechBubble(text: line)
                            .accessibilityLabel("\(model.state.titleName): \(line)")
                    }
                    // Smaller on short screens (iPhone SE), so the buttons and the brag link always fit.
                    GremlinView(pose: .pose(for: result.won ? .win : .lose), hat: wardrobe.hat, neck: wardrobe.neck, fur: wardrobe.fur,
                                size: min(210, geo.size.height * 0.24))
                        .accessibilityHidden(true)
                    VStack(spacing: 12) {
                        Text(detail).font(.system(.headline, design: .rounded).weight(.bold)).opacity(0.7)
                        pointsPill
                        levelBar
                        rewardChips
                    }
                    .foregroundStyle(Ink.body)
                    .padding(18)
                    .background(Ink.eye, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 24)
                    Spacer(minLength: 12)
                    buttons.padding(.horizontal, 24)
                    ShareLink(item: AppLinks.site, subject: Text("Little Menace"), message: Text(bragText)) {
                        Label("Brag about it", systemImage: "square.and.arrow.up")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Ink.eye)
                            .frame(minHeight: 44)
                    }
                    Spacer(minLength: 8)
                }
            }
        }
    }

    // MARK: Pieces

    private var wardrobe: Wardrobe { model.state.wardrobe }

    private var headline: String { result.won ? "You won!" : "So close." }

    private var detail: String {
        switch result.kind {
        case .snackToss: return "\(result.score) of \(SnackTossView.snacks) caught"
        case .sockTug: return result.won ? "The sock is yours" : "It kept the sock"
        case .cushionHunt: return result.won ? (result.score == 1 ? "Found it first try" : "Found it") : "It hid too well"
        case .copycat: return "\(result.score) moves copied"
        }
    }

    private var bragText: String {
        let name = model.state.titleName
        switch result.kind {
        case .snackToss: return "\(result.score) of 8 snacks into \(name)’s mouth. It’s furious."
        case .sockTug: return result.won ? "I won the sock off \(name). It will not forget this." : "\(name) kept the sock. Again."
        case .cushionHunt: return result.won ? "Found \(name) under a cushion. It was not pleased." : "\(name) out-hid me."
        case .copycat: return "Copied \(name)’s dance \(result.score) moves deep."
        }
    }

    private var pointsPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill").foregroundStyle(Ink.irisLight)
            Text(signedPoints(shown)).monospacedDigit().contentTransition(.numericText(value: Double(shown)))
        }
        .font(.system(.title2, design: .rounded).weight(.heavy))
        .foregroundStyle(Ink.eye)
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(Ink.body, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(result.won ? "Won" : "Lost"). \(detail). \(points >= 0 ? "Plus" : "Minus") \(abs(points)) points")
        .accessibilityFocused(focus)
    }

    private var levelBar: some View {
        let s = model.state
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Level \(s.level)").font(.system(.subheadline, design: .rounded).weight(.heavy))
                Spacer()
                Text("\(s.pointsToNextLevel) to level \(s.level + 1)").font(.system(.footnote, design: .rounded).weight(.bold)).opacity(0.6)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Ink.body.opacity(0.12))
                    Capsule().fill(Color(hex: 0xE59A2E)).frame(width: max(10, g.size.width * progress))
                }
            }
            .frame(height: 10)
        }
        .frame(maxWidth: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(s.level). \(s.pointsToNextLevel) points to level \(s.level + 1).")
    }

    @ViewBuilder private var rewardChips: some View {
        if !rewards.isEmpty {
            HStack(spacing: 8) {
                ForEach(rewards) { r in
                    HStack(spacing: 6) {
                        Image(systemName: r.symbol)
                        if let text = r.text { Text(text) }
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(hex: 0xFFD46B), in: Capsule())
                    .foregroundStyle(Ink.body)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(r.spoken)
                }
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(action: replay) {
                Label("Again", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Ink.body.opacity(0.12), in: Capsule())
                    .foregroundStyle(Ink.body)
            }
            .accessibilityLabel("Play again")
            Button(action: done) {
                Text("Done")
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Ink.body, in: Capsule())
                    .foregroundStyle(Ink.eye)
            }
        }
        .font(.system(.headline, design: .rounded).weight(.heavy))
        .buttonStyle(SquishButtonStyle())
        // The secondary button would sit on the theme colour, so the pair gets its own cream ground.
        .padding(6)
        .background(Ink.eye, in: Capsule())
    }

    private func countUp() async {
        let s = model.state
        let lo = Double(Tuning.xpForLevel(s.level)), hi = Double(Tuning.xpForLevel(s.level + 1))
        let target = hi > lo ? min(1, max(0, (Double(s.xp) - lo) / (hi - lo))) : 1
        guard !reduceMotion else { shown = points; progress = target; return }
        try? await Task.sleep(for: .seconds(0.25))
        let steps = 14
        for i in 1...steps {
            withAnimation(.snappy(duration: 0.05)) { shown = Int((Double(points) * Double(i) / Double(steps)).rounded()) }
            try? await Task.sleep(for: .seconds(0.045))
        }
        withAnimation(.easeOut(duration: 0.6)) { progress = target }
    }
}

/// A short burst of falling paper bits. Still frames only with Reduce Motion.
private struct Confetti: View {
    let still: Bool
    @State private var start = Date()
    private static let colors = [Color(hex: 0xFFD46B), Color(hex: 0xFF6FB5), Color(hex: 0x7B4DFF), Color(hex: 0x14B0E0), Color(hex: 0x06D6A0), .white]
    private static let pieces: [(x: Double, delay: Double, speed: Double, spin: Double, color: Int, w: Double)] = (0..<70).map { i in
        var g = SplitMix64(seed: UInt64(i + 1))
        return (Double.random(in: 0...1, using: &g), Double.random(in: 0...0.6, using: &g), Double.random(in: 0.25...0.5, using: &g),
                Double.random(in: -6...6, using: &g), Int.random(in: 0..<colors.count, using: &g), Double.random(in: 6...11, using: &g))
    }

    var body: some View {
        TimelineView(.animation(paused: still)) { ctx in
            Canvas { gc, size in
                let t = still ? 0.9 : ctx.date.timeIntervalSince(start)
                for p in Self.pieces {
                    let age = t - p.delay
                    guard age > 0 else { continue }
                    let y = -20 + age * p.speed * size.height
                    guard y < size.height + 20 else { continue }
                    let x = p.x * size.width + sin(age * 3 + p.spin) * 18
                    var piece = gc
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(age * p.spin))
                    piece.fill(Path(CGRect(x: -p.w / 2, y: -p.w / 4, width: p.w, height: p.w / 2)), with: .color(Self.colors[p.color]))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
