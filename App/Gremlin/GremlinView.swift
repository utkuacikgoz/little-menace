import SwiftUI
import MenaceCore

/// The gremlin, drawn as a vector rig in a 200×220 design space and scaled to `size`.
/// Pose changes spring; breathing, blinking and tail wag run on a timeline.
struct GremlinView: View {
    var pose: GremlinPose
    var hat: String?
    var neck: String?
    var size: CGFloat = 220
    /// Extra stretch from a drag, in design points (bounded by the caller).
    var stretch: CGSize = .zero
    /// False for snapshots (share card): no timeline, no blink.
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion && !pose.sleeping)) { ctx in
                    rig(time: ctx.date.timeIntervalSinceReferenceDate)
                }
            } else {
                rig(time: 1)
            }
        }
        .frame(width: 200, height: 220)
        .scaleEffect(size / 200)
        .frame(width: size, height: size * 1.1)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.55), value: pose)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7), value: stretch)
    }

    private func rig(time t: Double) -> some View {
        let breathe: CGFloat = reduceMotion ? 0 : CGFloat(sin(t * (pose.sleeping ? 1.4 : 2.4)) * (pose.sleeping ? 0.03 : 0.015))
        let blink: CGFloat = !pose.sleeping && pose.eyeOpen > 0.3 && blinkPhase(t) ? 0.08 : 1
        let wag: Double = reduceMotion ? 0 : sin(t * 5.5) * 9 * Double(pose.tailWag)
        let stretchY: CGFloat = 1 + max(-0.12, min(0.12, -stretch.height / 400))
        let stretchX: CGFloat = 1 + max(-0.1, min(0.1, abs(stretch.width) / 500)) - (stretchY - 1) * 0.5
        let lean = Double(pose.lean) + Double(stretch.width) / 12

        return ZStack {
            // Shadow stays on the ground while the gremlin hops.
            Ellipse().fill(.black.opacity(0.18))
                .frame(width: 130 - pose.hop * 2, height: 16)
                .position(x: 100, y: 210)

            ZStack {
                TailShape()
                    .stroke(Ink.body, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 60, height: 70)
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Ink.body).frame(width: 20, height: 20).offset(x: 4, y: -6)
                    }
                    .rotationEffect(.degrees(wag), anchor: .bottomLeading)
                    .position(x: 190, y: 160)

                ear(left: true)
                ear(left: false)

                // Arms sit behind the body so they read as tucked in when down.
                arm(left: true)
                arm(left: false)

                // Head tuft sits behind the body outline so only the spikes show.
                TuftShape().fill(Ink.body)
                    .frame(width: 44, height: 30)
                    .rotationEffect(.degrees(Double(pose.lean) * 0.6), anchor: .bottom)
                    .position(x: 104, y: 50)

                FluffShape(bumps: 26, depth: 3.2)
                    .fill(RadialGradient(colors: [Ink.bodyLight, Ink.body, Ink.bodyDark],
                                         center: UnitPoint(x: 0.36, y: 0.28), startRadius: 8, endRadius: 120))
                    .overlay(
                        // Rim light on the upper-left edge.
                        FluffShape(bumps: 26, depth: 3.2)
                            .stroke(LinearGradient(colors: [.white.opacity(0.22), .clear],
                                                   startPoint: .topLeading, endPoint: .center), lineWidth: 2.5)
                    )
                    .frame(width: 166, height: 158)
                    .position(x: 100, y: 128)

                FluffShape(bumps: 14, depth: 2.2)
                    .fill(LinearGradient(colors: [Ink.belly, Ink.bellyDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: 92, height: 70)
                    .position(x: 100, y: 170)

                HStack(spacing: 60) {
                    Foot()
                    Foot()
                }
                .position(x: 100, y: 203)

                face(blink: blink)
                    .offset(x: pose.look.width * 4 + stretch.width * 0.04, y: pose.look.height * 3)

                Wearables(hat: hat, neck: neck)
            }
            .scaleEffect(x: (2 - pose.squash) * stretchX * (1 - breathe * 0.5),
                         y: pose.squash * stretchY * (1 + breathe), anchor: .bottom)
            .rotationEffect(.degrees(lean), anchor: .bottom)
            .offset(x: stretch.width * 0.25, y: -pose.hop + min(0, stretch.height) * 0.1)

            if pose.sleeping { SleepZs(time: t).position(x: 160, y: 40) }
        }
        .frame(width: 200, height: 220)
    }

    private func blinkPhase(_ t: Double) -> Bool {
        let cycle = t.truncatingRemainder(dividingBy: 4.3)
        return cycle < 0.12 || (cycle > 2.1 && cycle < 2.18 && Int(t / 4.3) % 3 == 0)
    }

    private func ear(left: Bool) -> some View {
        let side: CGFloat = left ? -1 : 1
        return EarShape()
            .fill(Ink.body)
            .overlay(EarShape().inset(by: 12).fill(Ink.blush.opacity(0.45)).offset(y: 8))
            .frame(width: 58, height: 70)
            .rotationEffect(.degrees(Double(side) * (28 + Double(pose.earDroop))), anchor: .bottom)
            .position(x: 100 + side * 52, y: 58)
    }

    private func arm(left: Bool) -> some View {
        let side: CGFloat = left ? -1 : 1
        let angle = Double(side) * (20 + 130 * Double(pose.armsUp))
        return Capsule().fill(Ink.body)
            .frame(width: 22, height: 46)
            .rotationEffect(.degrees(angle), anchor: .top)
            .position(x: 100 + side * 70, y: 150)
    }

    private func face(blink: CGFloat) -> some View {
        let open = pose.eyeOpen * blink
        return ZStack {
            HStack(spacing: 34) {
                eye(open: open, cocked: false, blinking: blink < 1)
                eye(open: open, cocked: true, blinking: blink < 1)
            }
            .position(x: 100, y: 100)

            HStack(spacing: 58) {
                brow(left: true)
                brow(left: false)
            }
            .position(x: 100, y: 70 - pose.browLift)

            HStack(spacing: 86) {
                Ellipse().fill(Ink.blush.opacity(Double(pose.blush)))
                Ellipse().fill(Ink.blush.opacity(Double(pose.blush)))
            }
            .frame(width: 130, height: 12)
            .position(x: 100, y: 128)

            MouthShape(open: pose.mouthOpen, smile: pose.mouthSmile)
                .fill(Ink.mouth)
                .overlay(MouthShape(open: pose.mouthOpen, smile: pose.mouthSmile)
                    .stroke(Ink.pupil, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)))
                .overlay(alignment: .topTrailing) {
                    FangShape().fill(Ink.eye)
                        .frame(width: 8, height: 9)
                        .offset(x: -8, y: 9 - pose.mouthSmile * 3)
                        .opacity(Double(pose.fang))
                }
                .frame(width: 46, height: 26)
                .position(x: 100, y: 138)
        }
    }

    private func eye(open: CGFloat, cocked: Bool, blinking: Bool) -> some View {
        let cock: CGFloat = cocked ? pose.browAsym * 0.25 : 0
        let height = 42 * max(0.06, min(1.25, open + cock))
        let showWhite = open > 0.12 && pose.eyeHappy < 0.6
        return ZStack {
            Ellipse().fill(Ink.eye)
                .frame(width: 38, height: height)
                .overlay(
                    Circle().fill(RadialGradient(colors: [Ink.irisLight, Ink.iris], center: .center, startRadius: 2, endRadius: 13))
                        .frame(width: 25, height: 25)
                        .overlay(Circle().fill(Ink.pupil).frame(width: 14, height: 14))
                        .overlay(Circle().fill(.white).frame(width: 7, height: 7).offset(x: 5, y: -5))
                        .overlay(Circle().fill(.white.opacity(0.7)).frame(width: 3, height: 3).offset(x: -5, y: 5))
                        .offset(x: pose.look.width * 8, y: pose.look.height * 8 + (1 - min(1, open)) * 6)
                )
                .clipShape(Ellipse())
                .opacity(showWhite ? 1 : 0)

            LidArc(curve: pose.sleeping ? 1 : blinking ? 0.25 : -1)
                .stroke(Ink.eye, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                .frame(width: 30, height: 12)
                .opacity(showWhite ? 0 : 1)
        }
        .frame(width: 38, height: 50)
    }

    private func brow(left: Bool) -> some View {
        let side: Double = left ? -1 : 1
        let lift: CGFloat = left ? 0 : pose.browAsym * 8
        return Capsule().fill(Ink.pupil.opacity(0.9))
            .frame(width: 22, height: 5)
            .rotationEffect(.degrees(side * -Double(pose.browTilt) + (left ? 0 : -Double(pose.browAsym) * 14)))
            .offset(y: -lift)
    }
}

// MARK: Shapes

/// An ellipse whose edge is a ring of soft bumps: reads as fur without texture assets.
struct FluffShape: Shape {
    var bumps: Int
    var depth: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        let steps = bumps * 8
        let cx = r.midX, cy = r.midY, rx = r.width / 2, ry = r.height / 2
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            // |sin| makes rounded scallops rather than a sine wobble.
            let bump = depth * CGFloat(abs(sin(t * Double(bumps) / 2)))
            let x = cx + (rx - depth + bump) * CGFloat(cos(t))
            let y = cy + (ry - depth + bump) * CGFloat(sin(t))
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

/// Three curled spikes of hair on top of the head.
struct TuftShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let base = r.maxY
        let tips: [(CGFloat, CGFloat, CGFloat)] = [(0.2, 0.35, -0.12), (0.5, 0.0, 0.1), (0.8, 0.3, 0.14)]
        p.move(to: CGPoint(x: r.minX, y: base))
        for (x, y, lean) in tips {
            let tip = CGPoint(x: r.minX + r.width * (x + lean), y: r.minY + r.height * y)
            p.addQuadCurve(to: tip, control: CGPoint(x: r.minX + r.width * (x - 0.12), y: r.minY + r.height * 0.55))
            p.addQuadCurve(to: CGPoint(x: r.minX + r.width * (x + 0.12), y: base - r.height * 0.1),
                           control: CGPoint(x: r.minX + r.width * (x + 0.08), y: r.minY + r.height * 0.5))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: base))
        p.closeSubpath()
        return p
    }
}

private struct Foot: View {
    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Ink.bodyLight, Ink.bodyDark], startPoint: .top, endPoint: .bottom))
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(Ink.bodyDark.opacity(0.9)).frame(width: 2, height: 7)
                }
            }
            .offset(y: 3)
        }
        .frame(width: 42, height: 22)
    }
}

struct EarShape: InsettableShape {
    var inset: CGFloat = 0
    func path(in r: CGRect) -> Path {
        let r = r.insetBy(dx: inset, dy: inset)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.12, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.1, y: r.midY - r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.midY))
        p.closeSubpath()
        return p
    }
    func inset(by amount: CGFloat) -> EarShape { EarShape(inset: inset + amount) }
}

struct TailShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.maxX - 6, y: r.minY + 4),
                   control1: CGPoint(x: r.maxX + 10, y: r.maxY),
                   control2: CGPoint(x: r.minX + 10, y: r.minY + 10))
        return p
    }
}

/// Mouth with animatable openness and smile curvature.
struct MouthShape: Shape {
    var open: CGFloat
    var smile: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(open, smile) }
        set { open = newValue.first; smile = newValue.second }
    }

    func path(in r: CGRect) -> Path {
        let width = r.width * (0.7 + 0.3 * min(1, max(0, 1 - open * 0.4)))
        let left = CGPoint(x: r.midX - width / 2, y: r.minY + r.height * 0.3 - smile * r.height * 0.2)
        let right = CGPoint(x: r.midX + width / 2, y: left.y)
        let top = CGPoint(x: r.midX, y: r.minY + r.height * 0.3 + smile * r.height * 0.25 - open * r.height * 0.2)
        let bottom = CGPoint(x: r.midX, y: top.y + open * r.height * 1.3 + 0.5)
        var p = Path()
        p.move(to: left)
        p.addQuadCurve(to: right, control: top)
        p.addQuadCurve(to: left, control: bottom)
        p.closeSubpath()
        return p
    }
}

struct FangShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Closed-eye line. curve 1 = ‿ (asleep), −1 = ^ (delighted squint).
struct LidArc: Shape {
    var curve: CGFloat
    var animatableData: CGFloat {
        get { curve }
        set { curve = newValue }
    }
    func path(in r: CGRect) -> Path {
        var p = Path()
        let y = curve > 0 ? r.minY : r.maxY
        p.move(to: CGPoint(x: r.minX, y: y))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: y), control: CGPoint(x: r.midX, y: r.midY + curve * r.height))
        return p
    }
}

private struct SleepZs: View {
    let time: Double
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let phase = (time * 0.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                Text("z")
                    .font(.system(size: 14 + CGFloat(i) * 5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(1 - phase))
                    .offset(x: phase * 18, y: -phase * 40)
            }
        }
        .accessibilityHidden(true)
    }
}
