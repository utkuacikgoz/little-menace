import SwiftUI
import UIKit
import MenaceCore

/// The gremlin hides under a cushion, the cushions shuffle, you get two guesses.
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
    /// Review S27 D: the tail flicks out of the right cushion once during the shuffle.
    @State private var tailPeek = false

    private let colors = [Color(hex: 0xFFD166), Color(hex: 0x06D6A0), Color(hex: 0xEF476F)]
    /// Spoken names, so VoiceOver players can follow the same cushion sighted players watch.
    private let colorNames = ["yellow", "green", "red"]
    private static let spots = ["left", "middle", "right"]

    /// Review S27 (DEBUG only): B identical cushions, C boxes, D cushions with a tail tell.
    /// Identical props make the shuffle the actual game; VoiceOver then hears each swap.
    private var look: CushionView.Look {
        Variant.on("S27C") ? .box : (Variant.on("S27B") || Variant.on("S27D")) ? .puffy : .flat
    }
    private var identical: Bool { look != .flat }

    var body: some View {
        GeometryReader { geo in
            let y = geo.size.height * 0.56
            ZStack {
                if phase == .peek || lifted.contains(hidden) {
                    GremlinView(pose: gremlinPose, hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck, fur: model.state.wardrobe.fur, size: 110)
                        .position(x: x(for: hidden, width: geo.size.width), y: y - 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityHidden(true)
                }

                ForEach(0..<3, id: \.self) { c in
                    Button { guess(c) } label: {
                        CushionView(color: colors[c], look: look)
                    }
                    .buttonStyle(SquishButtonStyle())
                    .disabled(phase != .guess || lifted.contains(c))
                    .offset(y: lifted.contains(c) ? -90 : 0)
                    .position(x: x(for: c, width: geo.size.width), y: y)
                    .zIndex(Double(slot[c]))
                    .accessibilityLabel(identical ? "Cushion, \(Self.spots[slot[c]])" : "\(colorNames[c].capitalized) cushion, \(Self.spots[slot[c]])")
                    .accessibilityHint(phase == .guess ? "Look under this one" : "")
                }

                if tailPeek {
                    TailShape()
                        .stroke(Ink.body, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 30, height: 36)
                        .position(x: x(for: hidden, width: geo.size.width) + 52, y: y - 10)
                        .transition(.scale(scale: 0.2, anchor: .bottomLeading).combined(with: .opacity))
                        .accessibilityHidden(true)
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

    private var gremlinPose: GremlinPose {
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
        #if DEBUG
        // Screenshot tours: `-LMFreeze YES` holds the shuffle, with D's tail showing.
        if UserDefaults.standard.bool(forKey: "LMFreeze") {
            phase = .shuffle
            slot = [2, 0, 1]
            tailPeek = Variant.on("S27D")
            return
        }
        #endif
        Announcer.say(identical ? "It's hiding under the \(Self.spots[slot[hidden]]) cushion. Listen for the swaps."
                                : "It's hiding under the \(colorNames[hidden]) cushion. Watch the cushions.")
        try? await Task.sleep(for: .seconds(1.3))
        withAnimation(.easeIn(duration: 0.3)) { phase = .shuffle }
        model.sounds.play(.whoosh)
        try? await Task.sleep(for: .seconds(0.45))

        let swaps = reduceMotion ? 4 : 6
        // With identical cushions VoiceOver players follow spoken swaps, which need time to be heard.
        let speed = identical && UIAccessibility.isVoiceOverRunning ? 1.2 : reduceMotion ? 0.7 : 0.42
        for i in 0..<swaps {
            guard !Task.isCancelled else { return }
            let a = Int.random(in: 0...2)
            let b = (a + Int.random(in: 1...2)) % 3
            if identical {
                let cols = [slot[a], slot[b]].sorted()
                Announcer.say("\(Self.spots[cols[0]].capitalized) and \(Self.spots[cols[1]]) swap.")
            }
            withAnimation(.easeInOut(duration: speed)) { slot.swapAt(a, b) }
            model.haptics.play(.tap, intensity: 0.4)
            try? await Task.sleep(for: .seconds(speed + 0.06))
            if Variant.on("S27D") && i == swaps / 2 {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { tailPeek = true }
                try? await Task.sleep(for: .seconds(0.45))
                withAnimation(.easeOut(duration: 0.2)) { tailPeek = false }
            }
        }
        phase = .guess
        Announcer.say("Where did it go?")
    }

    private func guess(_ c: Int) {
        guard phase == .guess else { return }
        guesses += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { _ = lifted.insert(c) }
        if c == hidden {
            found = true
            model.sounds.play(.pop)
            model.haptics.play(.success)
            Announcer.say(guesses == 1 ? "Found it, first try!" : "Found it!")
            end()
        } else if guesses >= 2 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.4)) { _ = lifted.insert(hidden) }
            model.sounds.play(.boing)
            Announcer.say(identical ? "Not there. It was under the \(Self.spots[slot[hidden]]) cushion." : "Not there. It was under the \(colorNames[hidden]) cushion.")
            end()
        } else {
            model.haptics.play(.nope)
            model.sounds.play(.miss)
            Announcer.say("Not there. One guess left.")
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
