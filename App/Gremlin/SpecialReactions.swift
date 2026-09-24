import SwiftUI
import MenaceCore

/// Authored multi-beat reactions sold in collections. Long-press the gremlin to play an owned one;
/// the wardrobe lets anyone preview them before buying.
struct SpecialReaction {
    let id: String
    let name: String
    let prop: String
    let line: String
    let beats: [(pose: GremlinPose, seconds: Double)]

    static func find(_ id: String) -> SpecialReaction? { all.first { $0.id == id } }

    static let all: [SpecialReaction] = [
        SpecialReaction(id: "fridgeRaid", name: "Fridge Raid", prop: "refrigerator.fill", line: "midnight snack run.", beats: [
            (with(.mischief) { $0.look = CGSize(width: 1, height: 0) }, 0.6),
            (with(.feed) { $0.hop = 10 }, 0.35),
            (with(.feed) { $0.mouthOpen = 0.3 }, 0.3),
            (with(.feed) { $0.hop = 10 }, 0.35),
            (with(.touch) { $0.lean = -8 }, 0.8),
        ]),
        SpecialReaction(id: "moonHowl", name: "Moon Howl", prop: "moon.stars.fill", line: "awooo. menacingly.", beats: [
            (with(.attention) { $0.look = CGSize(width: 0, height: -1) }, 0.5),
            (with(.idle) { $0.eyeOpen = 0; $0.sleeping = false; $0.eyeHappy = 1; $0.mouthOpen = 1; $0.mouthSmile = 0; $0.lean = -10; $0.squash = 1.1; $0.earDroop = -14 }, 1.2),
            (with(.win) { $0.hop = 6 }, 0.7),
        ]),
        SpecialReaction(id: "blanketCape", name: "Blanket Cape", prop: "bed.double.fill", line: "I am the night.", beats: [
            (with(.mischief) { $0.armsUp = 0.3 }, 0.5),
            (with(.win) { $0.armsUp = 1; $0.lean = 10; $0.hop = 18 }, 0.5),
            (with(.mischief) { $0.armsUp = 0.8; $0.lean = -6; $0.browAsym = 1 }, 1.0),
        ]),
    ]

    private static func with(_ r: Reaction, _ edit: (inout GremlinPose) -> Void) -> GremlinPose {
        var p = GremlinPose.pose(for: r)
        edit(&p)
        return p
    }
}
