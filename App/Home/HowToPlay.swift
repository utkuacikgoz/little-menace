import SwiftUI
import MenaceCore

/// First-run guide: what to do, and what costs points. Also reachable from Settings.
struct GuideStep: Identifiable {
    let id: Int
    let title: String
    let body: String
    let symbol: String
    let reaction: Reaction

    static let all: [GuideStep] = [
        GuideStep(id: 0, title: "Meet your menace",
                  body: "It's small, it's yours, and it has opinions. Tap it to pet it.",
                  symbol: "hand.tap.fill", reaction: .touch),
        GuideStep(id: 1, title: "Keep it going",
                  body: "Feed it when it's hungry. Let it nap when it's sleepy. The rings show how it's doing.",
                  symbol: "fork.knife", reaction: .feed),
        GuideStep(id: 2, title: "Play for points",
                  body: "Three tiny games. Better rounds earn more. Daily challenges and stamps pay extra.",
                  symbol: "star.fill", reaction: .win),
        GuideStep(id: 3, title: "Don't push it",
                  body: "Leaving it hungry, waking it early, poking nonstop or force-feeding costs points. Your level stays.",
                  symbol: "exclamationmark.triangle.fill", reaction: .grumpyWake),
    ]
}

// MARK: A — full-screen pages

struct HowToPlayPages: View {
    @Environment(GameModel.self) private var model
    @State private var page = 0

    var body: some View {
        let steps = GuideStep.all
        ZStack {
            ThemeBackground(themeID: model.state.wardrobe.theme)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { model.finishHowToPlay() }
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Ink.eye)
                        .padding(.horizontal, 16).frame(minHeight: 44)
                        .background(Ink.body.opacity(0.5), in: Capsule())
                }
                .padding(.horizontal, 16)

                TabView(selection: $page) {
                    ForEach(steps) { step in
                        VStack(spacing: 24) {
                            Spacer(minLength: 0)
                            GremlinView(pose: .pose(for: step.reaction), hat: model.state.wardrobe.hat,
                                        neck: model.state.wardrobe.neck, size: 200)
                                .accessibilityHidden(true)
                            VStack(spacing: 12) {
                                Text(step.title)
                                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                                    .multilineTextAlignment(.center)
                                Text(step.body)
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(Ink.body)
                            .padding(24)
                            .background(Ink.eye, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .padding(.horizontal, 20)
                            Spacer(minLength: 0)
                        }
                        .tag(step.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < steps.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        model.finishHowToPlay()
                    }
                } label: {
                    Text(page < steps.count - 1 ? "Next" : "Let's go")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Ink.body, in: Capsule())
                        .foregroundStyle(Ink.eye)
                }
                .buttonStyle(SquishButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        #if DEBUG
        .onAppear { page = min(steps.count - 1, UserDefaults.standard.integer(forKey: "LMPage")) }
        #endif
    }
}

// MARK: B — one sheet with everything

struct HowToPlaySheet: View {
    @Environment(GameModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("How to play")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                ForEach(GuideStep.all) { step in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: step.symbol)
                            .font(.title2.weight(.bold))
                            .frame(width: 52, height: 52)
                            .background(Ink.body.opacity(0.08), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title).font(.system(.title3, design: .rounded).weight(.heavy))
                            Text(step.body).font(.system(.body, design: .rounded))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                Button { model.finishHowToPlay() } label: {
                    Text("Let's go")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Ink.body, in: Capsule())
                        .foregroundStyle(Ink.eye)
                }
                .buttonStyle(SquishButtonStyle())
                .padding(.top, 4)
            }
            .padding(24)
        }
        .foregroundStyle(Ink.body)
        .presentationDetents([.large])
        .presentationBackground(Ink.eye)
        .interactiveDismissDisabled()
    }
}

// MARK: C — coach marks over the real home screen

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
