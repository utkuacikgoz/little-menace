import SwiftUI
import MenaceCore

/// Every expressive parameter of the gremlin's rig. Poses are values; SwiftUI springs between them,
/// so any reaction can interrupt any other without snapping.
struct GremlinPose: Equatable {
    var eyeOpen: CGFloat = 1        // 0 closed … 1.2 wide
    var eyeHappy: CGFloat = 0       // 1 = ^ ^ squint
    var browTilt: CGFloat = 0       // + cross, − worried (degrees)
    var browLift: CGFloat = 0       // raise both
    var browAsym: CGFloat = 0       // 1 = one brow cocked (mischief)
    var mouthOpen: CGFloat = 0.1
    var mouthSmile: CGFloat = 0.5   // −1 frown … 1 grin
    var fang: CGFloat = 0.6
    var blush: CGFloat = 0.35
    var earDroop: CGFloat = 0       // degrees; negative perks up
    var squash: CGFloat = 1         // <1 squash, >1 stretch
    var lean: CGFloat = 0           // degrees
    var hop: CGFloat = 0            // points upward
    var armsUp: CGFloat = 0         // 0 down … 1 raised
    var tailWag: CGFloat = 1        // wag amplitude multiplier
    var look: CGSize = .zero        // −1…1 pupil direction
    var sleeping = false

    static let idle = GremlinPose()

    static func base(asleep: Bool, energy: Double) -> GremlinPose {
        if asleep { return pose(for: .asleep) }
        if energy < 30 { return pose(for: .sleepy) }
        return .idle
    }

    static func pose(for reaction: Reaction) -> GremlinPose {
        var p = GremlinPose()
        switch reaction {
        case .idle:
            break
        case .attention, .busy, .discovery:
            p.eyeOpen = 1.15; p.mouthOpen = 0.35; p.mouthSmile = 0.3; p.earDroop = -12; p.squash = 1.04; p.browLift = 4
        case .touch:
            p.eyeHappy = 1; p.mouthOpen = 0.5; p.mouthSmile = 1; p.squash = 0.93; p.blush = 1; p.tailWag = 2.2
        case .feed: // chewing: puffed cheeks, closed mouth
            p.eyeHappy = 1; p.mouthOpen = 0.08; p.mouthSmile = 0.6; p.squash = 1.06; p.blush = 0.9; p.tailWag = 1.6
        case .play:
            p.eyeOpen = 1.1; p.mouthOpen = 0.45; p.mouthSmile = 0.85; p.armsUp = 0.6; p.lean = 5; p.tailWag = 2
        case .sleepy:
            p.eyeOpen = 0.35; p.browTilt = -8; p.mouthOpen = 0.05; p.mouthSmile = 0.1; p.earDroop = 22; p.squash = 0.97; p.tailWag = 0.3
        case .asleep:
            p.eyeOpen = 0; p.sleeping = true; p.mouthOpen = 0.15; p.mouthSmile = 0.1; p.fang = 0; p.earDroop = 32; p.squash = 0.88; p.tailWag = 0.1
        case .wake:
            p.eyeOpen = 1.2; p.mouthOpen = 0.85; p.mouthSmile = 0.2; p.armsUp = 1; p.squash = 1.08; p.earDroop = -8
        case .grumpyWake: // huff: turns away with a big frown
            p.eyeOpen = 0.45; p.browTilt = 20; p.mouthSmile = -0.8; p.armsUp = 0.3; p.lean = -6; p.look = CGSize(width: -1, height: 0); p.fang = 1
        case .mischief:
            p.eyeOpen = 0.7; p.browAsym = 1; p.mouthSmile = 0.95; p.mouthOpen = 0.05; p.fang = 1; p.lean = 7; p.tailWag = 1.6
        case .refuseFood: // pout: brows down, arms half up, fang out
            p.eyeOpen = 0.5; p.browTilt = 14; p.mouthSmile = -0.7; p.mouthOpen = 0; p.armsUp = 0.3; p.fang = 1
        case .refuseNap:
            p.eyeOpen = 1.15; p.browLift = 6; p.mouthSmile = 0.7; p.mouthOpen = 0.3; p.armsUp = 0.5; p.hop = 8
        case .tooSleepy:
            p.eyeOpen = 0.3; p.browTilt = -10; p.mouthOpen = 0.7; p.mouthSmile = 0; p.earDroop = 26; p.squash = 0.95
        case .win, .levelUp:
            p.eyeHappy = 1; p.armsUp = 1; p.mouthOpen = 0.7; p.mouthSmile = 1; p.squash = 1.06; p.hop = 14; p.blush = 0.9; p.tailWag = 2.4
        case .lose:
            p.eyeOpen = 0.8; p.browTilt = -12; p.mouthSmile = -0.5; p.mouthOpen = 0.05; p.earDroop = 16; p.squash = 0.96
        }
        return p
    }
}
