import SwiftUI
import MenaceCore

/// The controls the first-run guide points at, in order.
enum CoachTarget: Int, CaseIterable {
    case pet, feed, play, nap, points

    var title: String {
        switch self {
        case .pet: return "Tap to pet"
        case .feed: return "Feed it"
        case .play: return "Play for points"
        case .nap: return "Let it nap"
        case .points: return "Your points"
        }
    }

    var body: String {
        switch self {
        case .pet: return "Pets make it happy. Too many, too fast, and it gets annoyed."
        case .feed: return "Tap, or drag the snack to its mouth. Don't feed a full belly."
        case .play: return "Three tiny games. Better rounds earn more points."
        case .nap: return "Naps restore energy. Waking it early costs points."
        case .points: return "Care earns points. Neglect costs them. Tap here for the rules."
        }
    }
}

struct CoachAnchorKey: PreferenceKey {
    static var defaultValue: [CoachTarget: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [CoachTarget: Anchor<CGRect>], nextValue: () -> [CoachTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func coachTarget(_ target: CoachTarget) -> some View {
        anchorPreference(key: CoachAnchorKey.self, value: .bounds) { [target: $0] }
    }
}

/// First-run guide: dims the real home screen and spotlights each control in turn.
/// Shown once to new players; reopened from Settings.
struct CoachMarks: View {
    @Environment(GameModel.self) private var model
    let anchors: [CoachTarget: Anchor<CGRect>]
    @State private var step = 0

    var body: some View {
        GeometryReader { proxy in
            let target = CoachTarget.allCases[min(step, CoachTarget.allCases.count - 1)]
            let rect = anchors[target].map { proxy[$0] } ?? CGRect(x: proxy.size.width / 2, y: proxy.size.height / 2, width: 0, height: 0)
            let hole = rect.insetBy(dx: -12, dy: -12)
            let below = rect.midY < proxy.size.height * 0.45
            ZStack {
                Path { p in
                    p.addRect(CGRect(origin: .zero, size: proxy.size).insetBy(dx: -200, dy: -200))
                    p.addRoundedRect(in: hole, cornerSize: CGSize(width: 28, height: 28))
                }
                .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
                .contentShape(Rectangle())
                .onTapGesture(perform: next)

                callout(target)
                    .frame(maxWidth: min(proxy.size.width - 32, 380))
                    .position(x: proxy.size.width / 2,
                              y: below ? min(hole.maxY + 110, proxy.size.height - 110) : max(hole.minY - 110, 110))
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        #if DEBUG
        .onAppear { step = min(CoachTarget.allCases.count - 1, UserDefaults.standard.integer(forKey: "LMPage")) }
        #endif
    }

    private func callout(_ target: CoachTarget) -> some View {
        let last = step >= CoachTarget.allCases.count - 1
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(target.title).font(.system(.title3, design: .rounded).weight(.heavy))
                Spacer()
                Text("\(step + 1) of \(CoachTarget.allCases.count)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .opacity(0.6)
            }
            Text(target.body)
                .font(.system(.body, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if !last {
                    Button("Skip") { model.finishHowToPlay() }
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .frame(minHeight: 44)
                }
                Spacer()
                Button(action: next) {
                    Text(last ? "Let's go" : "Next")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .padding(.horizontal, 22).frame(minHeight: 44)
                        .background(Ink.body, in: Capsule())
                        .foregroundStyle(Ink.eye)
                }
                .buttonStyle(SquishButtonStyle())
            }
        }
        .foregroundStyle(Ink.body)
        .padding(18)
        .background(Ink.eye, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    private func next() {
        if step < CoachTarget.allCases.count - 1 { step += 1 } else { model.finishHowToPlay() }
    }
}
