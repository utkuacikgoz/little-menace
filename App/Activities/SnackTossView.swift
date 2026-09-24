import SwiftUI
import MenaceCore

/// Flick snacks up; Crumb sways side to side and catches what reaches its mouth.
/// Catches are decided analytically at launch (ballistic arc vs. Crumb's known sway),
/// so frame drops never change the outcome.
struct SnackTossView: View {
    var finish: (ActivityResult) -> Void

    static let snacks = 8
    static let gravity: CGFloat = 1900
    static let catchRadius: CGFloat = 48

    @Environment(GameModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Flight: Identifiable {
        let id = UUID()
        let start: Date
        let origin: CGPoint
        let velocity: CGVector
        /// Seconds after `start` when the snack reaches the mouth line, if it gets there.
        let caughtAfter: Double?
    }

    @State private var roundStart = Date()
    @State private var flights: [Flight] = []
    @State private var thrown = 0
    @State private var caught = 0
    @State private var resolved = 0
    @State private var chomp: Reaction?
    @State private var aim: CGSize = .zero
    @State private var done = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            TimelineView(.animation) { ctx in
                let now = ctx.date
                let cx = crumbX(at: now, width: size.width)
                let crumbY = size.height * 0.26
                ZStack {
                    CrumbView(pose: crumbPose, hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck, size: 150)
                        .position(x: cx, y: crumbY)
                        .accessibilityHidden(true)

                    ForEach(flights) { f in
                        let t = now.timeIntervalSince(f.start)
                        if f.caughtAfter.map({ t < $0 }) ?? (t < 2) {
                            CookieView(size: 40)
                                .rotationEffect(.degrees(t * 540))
                                .position(position(of: f, after: t))
                        }
                    }

                    if thrown < Self.snacks {
                        CookieView(size: 56)
                            .offset(aim)
                            .position(launchPoint(in: size))
                            .gesture(flick(in: size))
                            .accessibilityElement()
                            .accessibilityLabel("Snack")
                            .accessibilityHint("Swipe up to throw. Or use the throw action.")
                            .accessibilityAction(named: "Throw to Crumb") { autoThrow(in: size) }
                    }

                    scoreDots
                        .position(x: size.width / 2, y: size.height - 24)
                }
            }
        }
        .onAppear { roundStart = Date() }
    }

    private var crumbPose: CrumbPose {
        var p = CrumbPose.pose(for: chomp ?? .play)
        if chomp == nil { p.mouthOpen = 0.6 }
        return p
    }

    private var scoreDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<Self.snacks, id: \.self) { i in
                Circle()
                    .fill(i < caught ? Ink.eye : .white.opacity(i < resolved ? 0.15 : 0.35))
                    .frame(width: 12, height: 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Caught \(caught) of \(Self.snacks)")
    }

    // MARK: Physics

    private func launchPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * 0.84)
    }

    private func crumbX(at date: Date, width: CGFloat) -> CGFloat {
        let t = date.timeIntervalSince(roundStart)
        let amplitude = width * (reduceMotion ? 0.14 : 0.28)
        let period = reduceMotion ? 5.0 : 3.2
        return width / 2 + amplitude * CGFloat(sin(t * 2 * .pi / period))
    }

    private func position(of f: Flight, after t: Double) -> CGPoint {
        let t = CGFloat(t)
        return CGPoint(x: f.origin.x + f.velocity.dx * t,
                       y: f.origin.y + f.velocity.dy * t + 0.5 * Self.gravity * t * t)
    }

    private func flick(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in aim = CGSize(width: v.translation.width * 0.4, height: min(0, v.translation.height) * 0.4) }
            .onEnded { v in
                aim = .zero
                let velocity = CGVector(dx: max(-900, min(900, v.velocity.width)), dy: max(-2600, v.velocity.height))
                guard velocity.dy < -500 else { return } // a tap or a downward swipe is not a throw
                launch(from: launchPoint(in: size), velocity: velocity, size: size)
            }
    }

    /// VoiceOver / Switch Control: aims at where Crumb will be. Still misses sometimes.
    private func autoThrow(in size: CGSize) {
        let origin = launchPoint(in: size)
        let mouthY = size.height * 0.26 + 150 * 0.08
        let vy: CGFloat = -1650
        guard let t = crossing(originY: origin.y, vy: vy, targetY: mouthY) else { return }
        let target = crumbX(at: Date().addingTimeInterval(t), width: size.width) + CGFloat.random(in: -40...40)
        launch(from: origin, velocity: CGVector(dx: (target - origin.x) / CGFloat(t), dy: vy), size: size)
    }

    private func crossing(originY: CGFloat, vy: CGFloat, targetY: CGFloat) -> Double? {
        // originY + vy t + g t²/2 = targetY  →  smallest positive root (on the way up).
        let a = Self.gravity / 2, b = vy, c = originY - targetY
        let disc = b * b - 4 * a * c
        guard disc >= 0 else { return nil }
        let t = (-b - disc.squareRoot()) / (2 * a)
        return t > 0 ? Double(t) : nil
    }

    private func launch(from origin: CGPoint, velocity: CGVector, size: CGSize) {
        guard thrown < Self.snacks else { return }
        let now = Date()
        let mouthY = size.height * 0.26 + 150 * 0.08
        var catchTime: Double?
        if let t = crossing(originY: origin.y, vy: velocity.dy, targetY: mouthY) {
            let snackX = origin.x + velocity.dx * CGFloat(t)
            let crumbAtThen = crumbX(at: now.addingTimeInterval(t), width: size.width)
            if abs(snackX - crumbAtThen) < Self.catchRadius { catchTime = t }
        }
        flights.append(Flight(start: now, origin: origin, velocity: velocity, caughtAfter: catchTime))
        thrown += 1
        model.sounds.play(.whoosh)
        model.haptics.play(.tap)

        let settle = catchTime ?? 0.9
        let caughtIt = catchTime != nil
        Task {
            try? await Task.sleep(for: .seconds(settle))
            resolved += 1
            if caughtIt {
                caught += 1
                react(.feed)
                model.sounds.play(.chomp)
                model.haptics.play(.thud, intensity: 0.7)
            } else {
                react(.lose)
            }
            if resolved == Self.snacks { end() }
        }
    }

    private func react(_ r: Reaction) {
        chomp = r
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            if chomp == r { chomp = nil }
        }
    }

    private func end() {
        guard !done else { return }
        done = true
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            finish(ActivityResult(kind: .snackToss, quality: Double(caught) / Double(Self.snacks), score: caught, won: caught >= 5))
        }
    }
}
