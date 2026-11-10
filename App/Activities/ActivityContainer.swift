import SwiftUI
import StoreKit
import MenaceCore

/// Hosts one round at a time: close button, the game, then the round's result with replay.
struct ActivityContainer: View {
    let kind: ActivityKind
    @Environment(GameModel.self) private var model
    @Environment(\.requestReview) private var requestReview
    @State private var round = 0
    @State private var result: ActivityResult?
    @State private var earnedXP = 0
    @AccessibilityFocusState private var resultFocused: Bool
    /// Screenshot tours only: rewards to show on a faked result.
    @State private var debugRewards: [Toast]?

    var body: some View {
        ZStack {
            ThemeBackground(themeID: model.state.wardrobe.theme)

            // The finished round steps aside so the result card is the only gremlin on screen.
            game
                .id(round)
                .disabled(result != nil)
                .opacity(result == nil ? 1 : 0)

            if let result {
                RoundResult(result: result, points: earnedXP, rewards: debugRewards ?? model.roundRewards,
                            focus: $resultFocused, replay: replay, done: { model.closeActivity(won: result.won) })
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
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
            .allowsHitTesting(result == nil)
            .accessibilityHidden(result != nil)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: result)
        #if DEBUG
        .onAppear {
            // Screenshot tours: `-LMResult win|lose` shows the result card straight away.
            if let r = UserDefaults.standard.string(forKey: "LMResult") {
                earnedXP = r == "win" ? 26 : 8
                result = ActivityResult(kind: kind, quality: r == "win" ? 0.8 : 0.25, score: r == "win" ? 6 : 3, won: r == "win")
                if r == "win" {
                    debugRewards = [Toast(symbol: "arrow.up.circle.fill", text: "\(model.state.level)", spoken: "Level \(model.state.level)"),
                                    Toast(symbol: "seal.fill", text: "3", spoken: "Stamp 3 this week")]
                }
            }
        }
        #endif
    }

    private var hint: String {
        switch kind {
        case .snackToss: return "Tap to toss the snack"
        case .sockTug: return "Pull when it gets tired"
        case .cushionHunt: return "Watch which cushion"
        case .copycat: return "Watch, then copy the moves"
        }
    }

    @ViewBuilder private var game: some View {
        let finish: (ActivityResult) -> Void = { r in
            earnedXP = model.finishActivity(r)
            result = r
            // VoiceOver lands on the result instead of staying on the finished game.
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                resultFocused = true
            }
            if model.takeReviewMoment(won: r.won) {
                // Let the win card land first, then Apple's rating prompt.
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    requestReview()
                }
            }
        }
        switch kind {
        case .snackToss: SnackTossView(finish: finish)
        case .sockTug: SockTugView(sock: model.state.wardrobe.sock, finish: finish)
        case .cushionHunt: CushionHuntView(finish: finish)
        case .copycat: CopycatView(finish: finish)
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
