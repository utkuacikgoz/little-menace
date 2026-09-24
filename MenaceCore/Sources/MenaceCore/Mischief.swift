import Foundation

/// A brief authored moment: Crumb is up to something, the player picks one of two responses.
/// Indulging nudges personality toward menace (+), redirecting toward sweet (−).
public struct MischiefEvent: Identifiable, Equatable, Sendable {
    public struct Choice: Equatable, Sendable {
        public let symbol: String
        public let spoken: String
        public let personality: Double
        public let joy: Double
        public let fullness: Double
        public let line: String
    }

    public let id: String
    /// SF Symbol of the prop Crumb is holding; it is the only on-screen hint.
    public let prop: String
    public let line: String
    public let indulge: Choice
    public let redirect: Choice
}

public enum MischiefBook {
    private static func c(_ symbol: String, _ spoken: String, _ p: Double, joy: Double = 0, fullness: Double = 0, _ line: String) -> MischiefEvent.Choice {
        .init(symbol: symbol, spoken: spoken, personality: p, joy: joy, fullness: fullness, line: line)
    }

    public static let events: [MischiefEvent] = [
        .init(id: "sock", prop: "shoe.2", line: "I found a sock. It's mine now.",
              indulge: c("hand.thumbsup", "Let it keep the sock", 0.12, joy: 8, "Best day. Worst sock."),
              redirect: c("arrow.uturn.backward", "Trade it for a snack", -0.1, fullness: 10, "Fine. Crunchy ransom.")),
        .init(id: "cable", prop: "cable.connector", line: "This noodle tastes electric.",
              indulge: c("hand.thumbsup", "Pretend not to see", 0.15, joy: 6, "Bzzt. Delicious."),
              redirect: c("arrow.uturn.backward", "Swap for a chew toy", -0.12, joy: 4, "Chewy. Acceptable.")),
        .init(id: "plant", prop: "leaf", line: "The plant looked at me.",
              indulge: c("hand.thumbsup", "Let it win the stare-off", 0.1, joy: 6, "Plant: zero. Me: one."),
              redirect: c("arrow.uturn.backward", "Introduce them politely", -0.12, joy: 4, "Hello, leafy friend.")),
        .init(id: "cup", prop: "cup.and.saucer", line: "Cup. Edge. Gravity?",
              indulge: c("hand.thumbsup", "Science must happen", 0.15, joy: 8, "Science happened."),
              redirect: c("arrow.uturn.backward", "Move the cup", -0.1, joy: 2, "Spoilsport. Cute spoilsport.")),
        .init(id: "keys", prop: "key", line: "Shiny jangly things. Hidden.",
              indulge: c("hand.thumbsup", "Play hunt the keys", 0.1, joy: 8, "Warmer. Colder. Mine."),
              redirect: c("arrow.uturn.backward", "Ask nicely for them", -0.14, joy: 3, "...here. Nicely.")),
        .init(id: "crumbs", prop: "birthday.cake", line: "Crumbs on the counter. My name!",
              indulge: c("hand.thumbsup", "Let it vacuum them", 0.1, fullness: 8, "Nom. Evidence gone."),
              redirect: c("arrow.uturn.backward", "Offer a proper plate", -0.1, fullness: 12, "Fancy crumbs.")),
        .init(id: "paper", prop: "doc", line: "Important paper. Now confetti.",
              indulge: c("hand.thumbsup", "Throw the confetti", 0.14, joy: 10, "Party! Unplanned!"),
              redirect: c("arrow.uturn.backward", "Fold it a paper boat", -0.12, joy: 6, "Boat. I am captain.")),
        .init(id: "blanket", prop: "bed.double", line: "Blanket fort. No adults.",
              indulge: c("hand.thumbsup", "Guard the door", 0.08, joy: 8, "Password: snacks."),
              redirect: c("arrow.uturn.backward", "Ask to be invited", -0.12, joy: 8, "...okay. You may enter.")),
        .init(id: "bell", prop: "bell", line: "Ding. Ding. Ding. Ding.",
              indulge: c("hand.thumbsup", "Ding along", 0.12, joy: 8, "DING DUET."),
              redirect: c("arrow.uturn.backward", "Hum a lullaby", -0.1, joy: 4, "Ding... zz... ding.")),
        .init(id: "pen", prop: "pencil", line: "I drew on the wall. It's you.",
              indulge: c("hand.thumbsup", "Admire the portrait", 0.1, joy: 10, "Masterpiece. Obviously."),
              redirect: c("arrow.uturn.backward", "Offer real paper", -0.14, joy: 6, "Gallery opening soon.")),
        .init(id: "remote", prop: "tv", line: "The remote lives here now.",
              indulge: c("hand.thumbsup", "Let it pick the show", 0.12, joy: 6, "Channel: Crumb TV."),
              redirect: c("arrow.uturn.backward", "Trade for belly rubs", -0.12, joy: 10, "Deal. Rub.")),
        .init(id: "sneeze", prop: "wind", line: "I sneezed on purpose.",
              indulge: c("hand.thumbsup", "Say bless you", 0.06, joy: 6, "Bless ME. Correct."),
              redirect: c("arrow.uturn.backward", "Offer a tissue", -0.1, joy: 4, "Honk. Thank you.")),
    ]

    public static func event(_ id: String) -> MischiefEvent? { events.first { $0.id == id } }

    /// Deterministic pick that avoids the last few events seen.
    public static func next(after recent: [String], seed: String) -> MischiefEvent {
        let fresh = events.filter { !recent.suffix(6).contains($0.id) }
        let pool = fresh.isEmpty ? events : fresh
        return pool[Int(stableHash("mischief:" + seed) % UInt64(pool.count))]
    }

    /// Gap until the next event, jittered deterministically between min and max.
    public static func gap(seed: String) -> TimeInterval {
        let span = Tuning.mischiefGapMax - Tuning.mischiefGapMin
        let unit = Double(stableHash("gap:" + seed) % 1000) / 1000
        return Tuning.mischiefGapMin + span * unit
    }
}
