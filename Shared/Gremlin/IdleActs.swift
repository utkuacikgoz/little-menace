import SwiftUI
import MenaceCore

/// Little things it does on its own while you just watch: sneezes, yawns, chasing its tail.
/// Played now and then by the home ticker when nothing else is going on.
struct IdleAct {
    let id: String
    let line: String
    /// Which beat is the big moment (a small haptic marks it).
    let peak: Int
    let beats: [(pose: GremlinPose, seconds: Double)]

    static func find(_ id: String) -> IdleAct? { all.first { $0.id == id } }

    static let all: [IdleAct] = [
        IdleAct(id: "sneeze", line: "*sneeze*", peak: 1, beats: [
            (with(.idle) { $0.eyeOpen = 0.25; $0.browTilt = -10; $0.mouthOpen = 0.55; $0.mouthSmile = 0; $0.lean = -8; $0.squash = 1.06; $0.fang = 0 }, 0.7),
            (with(.idle) { $0.eyeOpen = 0; $0.sleeping = false; $0.eyeHappy = 1; $0.mouthOpen = 0.9; $0.mouthSmile = -0.2; $0.lean = 12; $0.squash = 0.86; $0.earDroop = -16; $0.hop = 6 }, 0.45),
            (with(.touch) { $0.lean = 0; $0.tailWag = 1.2 }, 0.8),
        ]),
        IdleAct(id: "yawn", line: "*yaaawn*", peak: 0, beats: [
            (with(.idle) { $0.eyeOpen = 0.15; $0.mouthOpen = 1; $0.mouthSmile = 0; $0.armsUp = 0.8; $0.squash = 1.08; $0.earDroop = 12; $0.fang = 1 }, 1.4),
            (with(.sleepy) { $0.eyeOpen = 0.7 }, 0.8),
        ]),
        IdleAct(id: "tailChase", line: "the tail. it's back.", peak: 2, beats: [
            (with(.attention) { $0.look = CGSize(width: 1, height: 0.4) }, 0.5),
            (with(.play) { $0.lean = 16; $0.hop = 10; $0.look = CGSize(width: 1, height: 0.4) }, 0.35),
            (with(.play) { $0.lean = -16; $0.hop = 10; $0.look = CGSize(width: -1, height: 0.4) }, 0.35),
            (with(.play) { $0.lean = 16; $0.hop = 10; $0.look = CGSize(width: 1, height: 0.4) }, 0.35),
            (with(.lose) { $0.squash = 0.92 }, 0.8),
        ]),
        IdleAct(id: "scratch", line: "itchy ear. one sec.", peak: 1, beats: [
            (with(.idle) { $0.eyeHappy = 1; $0.lean = 8; $0.armsUp = 0.7; $0.earDroop = 14 }, 0.3),
            (with(.idle) { $0.eyeHappy = 1; $0.lean = 10; $0.armsUp = 0.9; $0.earDroop = 20; $0.mouthSmile = 0.9 }, 0.3),
            (with(.idle) { $0.eyeHappy = 1; $0.lean = 8; $0.armsUp = 0.7; $0.earDroop = 14 }, 0.3),
            (with(.touch) { $0.lean = 0 }, 0.7),
        ]),
        IdleAct(id: "stretch", line: "big stretch.", peak: 0, beats: [
            (with(.idle) { $0.eyeOpen = 0; $0.sleeping = false; $0.eyeHappy = 1; $0.armsUp = 1; $0.squash = 1.16; $0.mouthOpen = 0.4 }, 1.1),
            (with(.idle) { $0.squash = 0.92 }, 0.4),
        ]),
        IdleAct(id: "hiccup", line: "*hic*", peak: 1, beats: [
            (GremlinPose.idle, 0.4),
            (with(.idle) { $0.eyeOpen = 1.2; $0.hop = 12; $0.mouthOpen = 0.3; $0.mouthSmile = 0; $0.earDroop = -12 }, 0.25),
            (GremlinPose.idle, 0.6),
            (with(.idle) { $0.eyeOpen = 1.2; $0.hop = 12; $0.mouthOpen = 0.3; $0.mouthSmile = 0; $0.earDroop = -12 }, 0.25),
            (with(.idle) { $0.browTilt = -6; $0.mouthSmile = 0.2 }, 0.8),
        ]),
        IdleAct(id: "doze", line: "I wasn't asleep.", peak: 1, beats: [
            (with(.sleepy) { $0.eyeOpen = 0.4 }, 0.8),
            (with(.sleepy) { $0.eyeOpen = 0.08; $0.lean = 10; $0.earDroop = 30 }, 1.0),
            (with(.wake) { $0.armsUp = 0.4 }, 0.6),
        ]),
        IdleAct(id: "lookAround", line: "did you hear that?", peak: 1, beats: [
            (with(.idle) { $0.look = CGSize(width: -1, height: 0); $0.browAsym = 1 }, 0.7),
            (with(.idle) { $0.look = CGSize(width: 1, height: 0); $0.browAsym = 1; $0.eyeOpen = 0.7 }, 0.7),
            (with(.attention) { $0.look = .zero }, 0.6),
        ]),
        IdleAct(id: "sniff", line: "smells like crumbs.", peak: 1, beats: [
            (with(.idle) { $0.look = CGSize(width: 0, height: 1); $0.squash = 0.94; $0.mouthOpen = 0 }, 0.4),
            (with(.idle) { $0.look = CGSize(width: 0.5, height: 1); $0.squash = 0.92; $0.mouthOpen = 0; $0.earDroop = -10 }, 0.4),
            (with(.mischief) { $0.look = .zero }, 0.8),
        ]),
        IdleAct(id: "giggle", line: "hehe. a thought.", peak: 0, beats: [
            (with(.touch) { $0.squash = 0.9 }, 0.25),
            (with(.touch) { $0.squash = 1.04 }, 0.25),
            (with(.touch) { $0.squash = 0.9 }, 0.25),
            (with(.mischief) { $0.blush = 1 }, 0.8),
        ]),
    ]

    /// Reactions to the phone itself (`PhoneEvent` raw values): a low battery, a charger, a shake,
    /// a screenshot, a screen recording. `percent` is the battery left, or -1 when unknown.
    static func phone(_ id: String, percent: Int) -> IdleAct? {
        switch id {
        case "lowBattery":
            let line = percent >= 0 ? "\(percent)% battery. feed it, not me." : "your battery’s low. feed it, not me."
            return IdleAct(id: id, line: line, peak: 1, beats: [
                (with(.sleepy) { $0.look = CGSize(width: 0, height: -1); $0.eyeOpen = 0.6 }, 0.6),
                (with(.sleepy) { $0.eyeOpen = 0.35; $0.earDroop = 30; $0.squash = 0.9; $0.lean = -6; $0.browTilt = -10 }, 1.2),
                (with(.idle) { $0.browTilt = -6; $0.mouthSmile = 0 }, 0.8),
            ])
        case "charging":
            return IdleAct(id: id, line: "ooh. warm cable.", peak: 1, beats: [
                (with(.attention) { $0.look = CGSize(width: 0, height: 1); $0.earDroop = -12 }, 0.5),
                (with(.touch) { $0.eyeHappy = 1; $0.blush = 1; $0.squash = 0.9; $0.tailWag = 1.6 }, 1.2),
                (with(.touch) { $0.lean = 0 }, 0.6),
            ])
        case "shake":
            return IdleAct(id: id, line: "the room is spinning.", peak: 3, beats: [
                (with(.idle) { $0.lean = 16; $0.look = CGSize(width: 1, height: 0); $0.eyeOpen = 1.2 }, 0.2),
                (with(.idle) { $0.lean = -16; $0.look = CGSize(width: -1, height: 0); $0.eyeOpen = 1.2 }, 0.2),
                (with(.idle) { $0.lean = 12; $0.look = CGSize(width: 0, height: -1); $0.eyeOpen = 1.2 }, 0.2),
                (with(.idle) { $0.lean = -8; $0.eyeOpen = 0.6; $0.browAsym = 1; $0.mouthSmile = -0.4; $0.mouthOpen = 0.3; $0.sick = 0.5 }, 1.2),
                (with(.idle) { $0.browTilt = 4 }, 0.6),
            ])
        case "screenshot":
            return IdleAct(id: id, line: "did you just screenshot me?", peak: 1, beats: [
                (with(.attention) { $0.eyeOpen = 1.2; $0.look = .zero; $0.earDroop = -14 }, 0.5),
                (with(.mischief) { $0.armsUp = 0.8; $0.blush = 1; $0.browAsym = 1; $0.lean = 8 }, 1.4),
                (with(.mischief) { $0.armsUp = 0 }, 0.6),
            ])
        case "recording":
            return IdleAct(id: id, line: "are we live? hi chat.", peak: 1, beats: [
                (with(.attention) { $0.look = .zero; $0.eyeOpen = 1.2 }, 0.4),
                (with(.win) { $0.armsUp = 1; $0.hop = 10; $0.lean = -6 }, 0.5),
                (with(.win) { $0.armsUp = 0.6; $0.hop = 0; $0.lean = 6 }, 0.5),
                (with(.touch) { $0.lean = 0 }, 0.6),
            ])
        default:
            return nil
        }
    }

    private static func with(_ r: Reaction, _ edit: (inout GremlinPose) -> Void) -> GremlinPose {
        var p = GremlinPose.pose(for: r)
        edit(&p)
        return p
    }
}
