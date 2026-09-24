import SwiftUI
import UIKit
import MenaceCore

/// Drag the sock down. Crumb yanks back hard, then tires for a moment: that's when to pull.
struct SockTugView: View {
    var sock: String
    var finish: (ActivityResult) -> Void

    @Environment(GameModel.self) private var model
    @State private var match = TugMatch(seed: UInt64.random(in: 0...UInt64.max))
    @State private var lastFrame: Date?
    @State private var wasTired = false
    @State private var reported = false
    @State private var assistUntil = Date.distantPast
    @State private var lastSlip = Date.distantPast
    @GestureState private var depth: CGFloat = 0

    private static let maxDepth: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let crumbY = h * 0.28 + CGFloat(match.rope) * 50
            let gripY = h * 0.66 + depth * 0.5 + CGFloat(match.rope) * 40
            TimelineView(.animation) { ctx in
                ZStack {
                    SockView(style: sock, stretch: max(0, gripY - crumbY - 150))
                        .rotationEffect(.degrees(180))
                        .position(x: geo.size.width / 2 + 10, y: (crumbY + gripY) / 2 + 20)

                    CrumbView(pose: pose, hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck, size: 170)
                        .position(x: geo.size.width / 2, y: crumbY)

                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Ink.body)
                        .frame(width: 70, height: 70)
                        .background(Ink.eye.opacity(depth > 0 ? 1 : 0.8), in: Circle())
                        .scaleEffect(depth > 0 ? 1.1 : 1)
                        .position(x: geo.size.width / 2, y: gripY + 40)
                        .accessibilityHidden(true)

                    Capsule().fill(.white.opacity(0.25)).frame(width: 180, height: 8)
                        .overlay(alignment: .leading) {
                            Capsule().fill(.white).frame(width: 180 * CGFloat(match.timeLeft / TugMatch.duration), height: 8)
                        }
                        .position(x: geo.size.width / 2, y: h - 24)
                        .accessibilityHidden(true)
                }
                .onChange(of: ctx.date) { _, date in step(to: date) }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($depth) { v, state, _ in
                        state = max(0, min(Self.maxDepth, v.translation.height))
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Sock tug")
            .accessibilityValue(match.crumbTired ? "Crumb is tired. Pull now!" : "Crumb is pulling hard")
            .accessibilityAction(named: "Pull") { assistUntil = Date().addingTimeInterval(0.4) }
        }
    }

    private var pose: CrumbPose {
        if let outcome = match.outcome { return .pose(for: outcome ? .lose : .win) }
        if match.isWarmingUp { return .pose(for: .mischief) }
        var p = CrumbPose()
        if match.crumbTired {
            p.eyeOpen = 0.45; p.mouthOpen = 0.55; p.mouthSmile = 0; p.browTilt = -10; p.earDroop = 20; p.squash = 1.03
        } else {
            p.eyeOpen = 0.75; p.browTilt = 16; p.fang = 1; p.mouthSmile = -0.2; p.mouthOpen = 0.2; p.squash = 0.93; p.earDroop = -6
        }
        p.lean = CGFloat(-match.rope * 6)
        p.tailWag = 2
        return p
    }

    private func step(to date: Date) {
        defer { lastFrame = date }
        guard let last = lastFrame, match.outcome == nil else { return }
        let pull = max(Double(depth / Self.maxDepth), date < assistUntil ? 1 : 0)
        match.step(dt: date.timeIntervalSince(last), pull: pull)

        if match.crumbTired != wasTired {
            wasTired = match.crumbTired
            if wasTired {
                model.haptics.play(.tap, intensity: 1)
                UIAccessibility.post(notification: .announcement, argument: "Now!")
            }
        } else if pull > 0.6 && !match.crumbTired && !match.isWarmingUp && date.timeIntervalSince(lastSlip) > 0.25 {
            lastSlip = date
            model.haptics.play(.squish, intensity: 0.4) // the sock slipping
        }

        if let outcome = match.outcome, !reported {
            reported = true
            model.haptics.play(outcome ? .success : .thud)
            let result = match.result
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                finish(result)
            }
        }
    }
}
