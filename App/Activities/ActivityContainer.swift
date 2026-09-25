import SwiftUI
import MenaceCore

/// Hosts one round at a time: close button, the game, and a tiny result card with replay.
struct ActivityContainer: View {
    let kind: ActivityKind
    @Environment(GameModel.self) private var model
    @State private var round = 0
    @State private var result: ActivityResult?
    @State private var earnedXP = 0

    var body: some View {
        ZStack {
            ThemeBackground(themeID: model.state.wardrobe.theme)

            // The finished round steps aside so the result card is the only gremlin on screen.
            game
                .id(round)
                .disabled(result != nil)
                .opacity(result == nil ? 1 : 0)

            if let result {
                ResultCard(result: result, xp: earnedXP, hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck,
                           replay: replay, done: { model.closeActivity(won: result.won) })
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            if result == nil {
                // A one-line hint at the top while a round is on.
                VStack {
                    Text(hint)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Ink.eye)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Ink.body.opacity(0.85), in: Capsule())
                        .padding(.top, 70)
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            VStack {
                HStack {
                    Button {
                        model.cancelActivity()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.heavy))
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .accessibilityLabel("Close")
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
            .opacity(result == nil ? 1 : 0)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: result)
        #if DEBUG
        .onAppear {
            // Screenshot tours: `-LMResult win|lose` shows the result card straight away.
            if let r = UserDefaults.standard.string(forKey: "LMResult") {
                earnedXP = r == "win" ? 26 : 8
                result = ActivityResult(kind: kind, quality: r == "win" ? 0.8 : 0.25, score: 3, won: r == "win")
            }
        }
        #endif
    }

    private var hint: String {
        switch kind {
        case .snackToss: return "Tap to toss the snack"
        case .sockTug: return "Pull when it gets tired"
        case .cushionHunt: return "Watch which cushion"
        }
    }

    @ViewBuilder private var game: some View {
        let finish: (ActivityResult) -> Void = { r in
            earnedXP = model.finishActivity(r)
            result = r
        }
        switch kind {
        case .snackToss: SnackTossView(finish: finish)
        case .sockTug: SockTugView(sock: model.state.wardrobe.sock, finish: finish)
        case .cushionHunt: CushionHuntView(finish: finish)
        }
    }

    private func replay() {
        model.startActivity(kind)
        if model.session != nil {
            result = nil
            round += 1
        } else {
            // Too sleepy for another round: back home, where the gremlin shows why.
            model.closeActivity(won: nil)
        }
    }
}

private struct ResultCard: View {
    let result: ActivityResult
    let xp: Int
    let hat: String?
    let neck: String?
    let replay: () -> Void
    let done: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            GremlinView(pose: .pose(for: result.won ? .win : .lose), hat: hat, neck: neck, size: 150)
            // Dark pill so the reward reads on every background (white on orange was ~2.6:1).
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("+\(xp)")
            }
            .font(.system(.title2, design: .rounded).weight(.heavy))
            .foregroundStyle(Ink.eye)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Ink.body, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(result.won ? "Won" : "Lost"). Plus \(xp) experience")

            HStack(spacing: 24) {
                Button(action: replay) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title.weight(.heavy))
                        .frame(width: 72, height: 72)
                        .background(Ink.body.opacity(0.1), in: Circle())
                        .foregroundStyle(Ink.body)
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityLabel("Play again")
                Button(action: done) {
                    Image(systemName: "checkmark")
                        .font(.title.weight(.heavy))
                        .frame(width: 72, height: 72)
                        .background(Ink.body, in: Circle())
                        .foregroundStyle(Ink.eye)
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityLabel("Done")
            }
        }
        .padding(28)
        // Everything on one cream card.
        .background(Ink.eye, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
        .padding(.horizontal, 24)
    }
}
