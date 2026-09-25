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

            VStack {
                HStack {
                    Button {
                        model.cancelActivity()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.heavy))
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
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("+\(xp)")
            }
            .font(.system(.title2, design: .rounded).weight(.heavy))
            .foregroundStyle(.white)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(result.won ? "Won" : "Lost"). Plus \(xp) experience")

            HStack(spacing: 24) {
                Button(action: replay) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title.weight(.heavy))
                        .frame(width: 72, height: 72)
                        .background(Ink.eye, in: Circle())
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
    }
}
