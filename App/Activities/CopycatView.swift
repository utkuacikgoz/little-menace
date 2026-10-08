import SwiftUI
import UIKit
import MenaceCore

/// Copycat Dance: it dances a routine, you copy it move by move. Every routine copied adds a move;
/// the first slip ends the round. Played on a disco floor: tap the glowing tiles or swipe.
struct CopycatView: View {
    var finish: (ActivityResult) -> Void

    private enum Phase { case watch, copy, over }

    @Environment(GameModel.self) private var model
    @State private var match = CopycatMatch(seed: UInt64.random(in: 0...UInt64.max))
    @State private var phase: Phase = .watch
    /// The move it is dancing right now, and its place in the routine.
    @State private var dancing: DanceMove?
    @State private var demoIndex = -1
    /// The player's last move, lit for a moment.
    @State private var flash: DanceMove?
    @State private var flashID = 0
    @State private var demo: Task<Void, Never>?

    private static let colors: [DanceMove: Color] = [
        .up: Color(hex: 0xFFD166), .right: Color(hex: 0x06D6A0), .left: Color(hex: 0xEF476F), .down: Color(hex: 0x4CC9F0),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                DiscoLights(width: w, height: h)

                GremlinView(pose: pose, hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck,
                            fur: model.state.wardrobe.fur, size: min(w * 0.5, 200))
                    .position(x: w / 2, y: h * 0.33)
                    .accessibilityHidden(true)

                if phase == .watch, let dancing {
                    Image(systemName: Self.arrow(dancing))
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(Ink.eye)
                        .shadow(color: .black.opacity(0.3), radius: 0, x: 3, y: 3)
                        .position(x: w * 0.85, y: h * 0.3)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }

                if match.best > 0 {
                    Text("×\(match.best)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFF4FD8))
                        .shadow(color: Color(hex: 0xFF4FD8).opacity(0.8), radius: 8)
                        .position(x: w - 52, y: 40)
                        .accessibilityLabel("Best \(match.best) moves")
                }

                VStack(spacing: 10) {
                    Text(status)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        ForEach(0..<match.routine.count, id: \.self) { i in
                            Circle().fill(i < lit ? Ink.eye : Color.white.opacity(0.3)).frame(width: 14, height: 14)
                        }
                    }
                    .accessibilityHidden(true)
                }
                .position(x: w / 2, y: h * 0.56)

                controls(width: w, height: h)
                    .position(x: w / 2, y: h * 0.8)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 30).onEnded { v in
                let dx = v.translation.width, dy = v.translation.height
                if abs(dx) > abs(dy) { input(dx > 0 ? .right : .left) } else { input(dy > 0 ? .down : .up) }
            })
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: dancing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Up") { input(.up) }
        .accessibilityAction(named: "Down") { input(.down) }
        .accessibilityAction(named: "Left") { input(.left) }
        .accessibilityAction(named: "Right") { input(.right) }
        .task { await start() }
        .onDisappear { demo?.cancel() }
    }

    private var status: String {
        switch phase {
        case .watch: return "Watch…"
        case .copy: return "Your turn"
        case .over: return match.outcome == true ? "\(match.best) moves!" : "Oops!"
        }
    }

    private var lit: Int {
        switch phase {
        case .watch: return demoIndex + 1
        case .copy: return match.copied
        case .over: return 0
        }
    }

    // MARK: Controls

    private func controls(width w: CGFloat, height h: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) { tile(.up, w); tile(.right, w) }
            HStack(spacing: 12) { tile(.left, w); tile(.down, w) }
        }
    }

    private func tile(_ m: DanceMove, _ w: CGFloat) -> some View {
        let color = Self.colors[m] ?? .white
        let on = flash == m || (phase == .watch && dancing == m)
        return Button { input(m) } label: {
            Image(systemName: Self.arrow(m))
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(color)
                .frame(width: min(160, w * 0.4), height: 84)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(on ? 0.15 : 0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(color, lineWidth: 4)
                )
                .shadow(color: color.opacity(on ? 1 : 0.6), radius: on ? 18 : 8)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(phase != .copy)
        .accessibilityLabel(Self.name(m))
    }

    // MARK: Round

    private func start() async {
        #if DEBUG
        if Self.frozen { freeze(); return }
        #endif
        try? await Task.sleep(for: .seconds(0.8))
        guard !Task.isCancelled else { return }
        playDemo()
    }

    private func playDemo() {
        demo?.cancel()
        phase = .watch
        let routine = match.routine
        // Longer routines are danced a little faster.
        let beat = max(0.32, 0.62 - 0.025 * Double(routine.count))
        demo = Task {
            for (i, move) in routine.enumerated() {
                guard !Task.isCancelled else { return }
                demoIndex = i
                dancing = move
                model.sounds.play(.pop)
                model.haptics.play(.tap, intensity: 0.4)
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .announcement, argument: Self.name(move))
                }
                try? await Task.sleep(for: .seconds(beat))
                dancing = nil
                try? await Task.sleep(for: .seconds(0.16))
            }
            guard !Task.isCancelled else { return }
            demoIndex = -1
            phase = .copy
            UIAccessibility.post(notification: .announcement, argument: "Your turn")
        }
    }

    private func input(_ move: DanceMove) {
        guard phase == .copy else { return }
        flash = move
        flashID += 1
        let id = flashID
        Task {
            try? await Task.sleep(for: .seconds(0.25))
            if flashID == id { flash = nil }
        }
        switch match.input(move) {
        case .correct:
            model.sounds.play(.pop)
            model.haptics.play(.tap)
        case .routineDone:
            model.sounds.play(.stamp)
            model.haptics.play(.success)
            phase = .watch
            demo?.cancel()
            demo = Task {
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { return }
                playDemo()
            }
        case .mistake, .finished:
            model.haptics.play(match.outcome == true ? .success : .nope)
            end()
        }
    }

    private func end() {
        demo?.cancel()
        phase = .over
        let result = match.result
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            finish(result)
        }
    }

    // MARK: Looks

    private var pose: GremlinPose {
        switch phase {
        case .watch: return dancing.map(Self.pose(for:)) ?? .pose(for: .play)
        case .copy: return flash.map(Self.pose(for:)) ?? .pose(for: .attention)
        case .over: return .pose(for: match.outcome == true ? .win : .lose)
        }
    }

    static func pose(for m: DanceMove) -> GremlinPose {
        var p = GremlinPose.pose(for: .play)
        switch m {
        case .up: p.armsUp = 1; p.hop = 16; p.squash = 1.08; p.lean = 0
        case .down: p.armsUp = 0; p.squash = 0.82; p.lean = 0; p.eyeHappy = 1
        case .left: p.lean = -16; p.look = CGSize(width: -1, height: 0); p.armsUp = 0.5
        case .right: p.lean = 16; p.look = CGSize(width: 1, height: 0); p.armsUp = 0.5
        }
        return p
    }

    static func arrow(_ m: DanceMove) -> String {
        switch m {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }

    static func name(_ m: DanceMove) -> String {
        switch m {
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        }
    }

    #if DEBUG
    /// Screenshot tours: `-LMFreeze YES` holds the round mid-copy (one routine done, two moves in).
    private static let frozen = UserDefaults.standard.bool(forKey: "LMFreeze")

    private func freeze() {
        for m in match.routine { match.input(m) }
        match.input(match.routine[0])
        match.input(match.routine[1])
        phase = .copy
        flash = match.routine[1]
    }
    #endif
}

/// A dark club with two coloured spotlights and a disco ball.
private struct DiscoLights: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            Spotlight()
                .fill(LinearGradient(colors: [Color(hex: 0xFF4FD8).opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: width * 0.7, height: height * 0.62)
                .rotationEffect(.degrees(-20), anchor: .top)
                .position(x: width * 0.15, y: height * 0.31)
            Spotlight()
                .fill(LinearGradient(colors: [Color(hex: 0x4CC9F0).opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: width * 0.7, height: height * 0.62)
                .rotationEffect(.degrees(20), anchor: .top)
                .position(x: width * 0.85, y: height * 0.31)
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.8), radius: 10)
                .position(x: width / 2, y: 24)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Spotlight: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - 8, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + 8, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
