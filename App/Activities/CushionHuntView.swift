import SwiftUI
import UIKit
import MenaceCore

/// Crumb hides under a cushion, the cushions shuffle, you get two guesses.
struct CushionHuntView: View {
    var finish: (ActivityResult) -> Void

    private enum Phase { case peek, shuffle, guess, over }

    @Environment(GameModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .peek
    /// slot[cushion] = column 0…2.
    @State private var slot = [0, 1, 2]
    @State private var hidden = Int.random(in: 0...2)
    @State private var lifted: Set<Int> = []
    @State private var guesses = 0
    @State private var found = false

    private let colors = [Color(hex: 0xFFD166), Color(hex: 0x06D6A0), Color(hex: 0xEF476F)]

    var body: some View {
        GeometryReader { geo in
            let y = geo.size.height * 0.56
            ZStack {
                if phase == .peek || lifted.contains(hidden) {
                    CrumbView(pose: crumbPose, hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck, size: 110)
                        .position(x: x(for: hidden, width: geo.size.width), y: y - 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityHidden(true)
                }

                ForEach(0..<3, id: \.self) { c in
                    Button { guess(c) } label: {
                        CushionView(color: colors[c])
                    }
                    .buttonStyle(SquishButtonStyle())
                    .disabled(phase != .guess || lifted.contains(c))
                    .offset(y: lifted.contains(c) ? -90 : 0)
                    .position(x: x(for: c, width: geo.size.width), y: y)
                    .zIndex(Double(slot[c]))
                    .accessibilityLabel("Cushion \(["left", "middle", "right"][slot[c]])")
                    .accessibilityHint(phase == .guess ? "Look under this one" : "")
                }

                HStack(spacing: 10) {
                    ForEach(0..<2, id: \.self) { i in
                        Image(systemName: i < guesses ? "eye.slash" : "eye.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white.opacity(i < guesses ? 0.4 : 1))
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height - 28)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(2 - guesses) guesses left")
            }
        }
        .task { await play() }
    }

    private var crumbPose: CrumbPose {
        switch phase {
        case .peek: return .pose(for: .mischief)
        case .over: return .pose(for: found ? .touch : .mischief)
        default: return .pose(for: .attention)
        }
    }

    private func x(for cushion: Int, width: CGFloat) -> CGFloat {
        width * (0.2 + 0.3 * CGFloat(slot[cushion]))
    }

    private func play() async {
        UIAccessibility.post(notification: .announcement, argument: "Watch the cushions")
        try? await Task.sleep(for: .seconds(1.3))
        withAnimation(.easeIn(duration: 0.3)) { phase = .shuffle }
        model.sounds.play(.whoosh)
        try? await Task.sleep(for: .seconds(0.45))

        let swaps = reduceMotion ? 4 : 6
        let speed = reduceMotion ? 0.7 : 0.42
        for _ in 0..<swaps {
            guard !Task.isCancelled else { return }
            let a = Int.random(in: 0...2)
            let b = (a + Int.random(in: 1...2)) % 3
            withAnimation(.easeInOut(duration: speed)) { slot.swapAt(a, b) }
            model.haptics.play(.tap, intensity: 0.4)
            try? await Task.sleep(for: .seconds(speed + 0.06))
        }
        phase = .guess
        UIAccessibility.post(notification: .announcement, argument: "Where is Crumb?")
    }

    private func guess(_ c: Int) {
        guard phase == .guess else { return }
        guesses += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { _ = lifted.insert(c) }
        if c == hidden {
            found = true
            model.sounds.play(.pop)
            end()
        } else if guesses >= 2 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.4)) { _ = lifted.insert(hidden) }
            model.sounds.play(.boing)
            end()
        } else {
            model.haptics.play(.nope)
        }
    }

    private func end() {
        phase = .over
        let result = ActivityResult(kind: .cushionHunt, quality: found ? (guesses == 1 ? 1 : 0.6) : 0.2,
                                    score: guesses, won: found)
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            finish(result)
        }
    }
}
