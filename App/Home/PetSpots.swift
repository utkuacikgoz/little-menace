import SwiftUI
import MenaceCore

/// Where a tap landed on the gremlin. Coordinates are in the rig's 200 × 220 canvas.
enum PetZone: String, CaseIterable {
    case head, chin, ears, belly, tail

    init(_ p: CGPoint) {
        let dx = abs(p.x - 100)
        if p.x > 168 && p.y > 105 { self = .tail }
        else if p.y < 62 && dx > 24 { self = .ears }
        else if p.y >= 132 && p.y < 148 && dx < 40 { self = .chin }
        else if p.y >= 148 && dx < 48 { self = .belly }
        else { self = .head }
    }
}

/// Review S32 (DEBUG only): petting hot spots. A none; B chin, ears, belly and tail each react;
/// C B plus a secret favourite spot each day that sends up hearts; D B plus the belly trap that bites.
enum PetSpots {
    static var level: Int {
        Variant.on("S32D") ? 3 : Variant.on("S32C") ? 2 : Variant.on("S32B") ? 1 : 0
    }

    /// Today's favourite spot (option C): the same all day, a different one most days.
    static func favourite(dayKey: String) -> PetZone {
        let spots: [PetZone] = [.chin, .ears, .belly, .tail]
        #if DEBUG
        if let forced = UserDefaults.standard.string(forKey: "LMFavourite").flatMap(PetZone.init(rawValue:)) { return forced }
        #endif
        return spots[Int(stableHash("spot:" + dayKey) % UInt64(spots.count))]
    }
}

/// What appears around the gremlin after a hot-spot pet.
enum PetFlourish: Equatable {
    case hearts, bite
}

/// A few hearts floating up from the gremlin.
struct HeartsBurst: View {
    @State private var up = false
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: [26, 34, 22, 30, 24][i], weight: .bold))
                    .foregroundStyle(Color(hex: 0xFF6B8B))
                    .offset(x: [-70, -24, 18, 62, 96][i] - 12, y: up ? [-90, -130, -70, -115, -60][i] : 0)
                    .opacity(up ? 0.95 : 0)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { up = true } }
        .accessibilityHidden(true)
    }
}

/// Two arcs of tooth marks: the belly trap closed on your finger.
struct BiteMarks: View {
    var body: some View {
        ZStack {
            arc(top: true)
            arc(top: false)
        }
        .frame(width: 120, height: 90)
        .accessibilityHidden(true)
    }

    private func arc(top: Bool) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let angle = Angle.degrees(Double(i) * 24 - 60)
                Capsule()
                    .fill(Color(hex: 0xB0293B).opacity(0.75))
                    .frame(width: 9, height: 16)
                    .rotationEffect(angle)
                    .offset(x: sin(angle.radians) * 48, y: (top ? -1 : 1) * (cos(angle.radians) * 26 - 8))
            }
        }
    }
}
