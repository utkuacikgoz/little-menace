import Foundation

public struct Needs: Codable, Equatable, Sendable {
    public var fullness: Double
    public var energy: Double
    public var joy: Double

    public init(fullness: Double, energy: Double, joy: Double) {
        self.fullness = fullness
        self.energy = energy
        self.joy = joy
    }

    public static let fresh = Needs(fullness: 60, energy: 80, joy: 70)

    mutating func clamp() {
        fullness = min(100, max(0, fullness))
        energy = min(100, max(0, energy))
        joy = min(100, max(0, joy))
    }
}

public enum ActivityKind: String, Codable, CaseIterable, Sendable {
    case snackToss, sockTug, cushionHunt
}

/// A play round in progress. Deliberately not persisted: a round interrupted by
/// termination simply never happened (no cost, no reward).
public struct ActivitySession: Equatable, Sendable {
    public let id: UUID
    public let kind: ActivityKind
    public let startedAt: Date
}

public struct ActivityResult: Equatable, Sendable {
    public var kind: ActivityKind
    /// 0...1 quality of the round, drives XP and Crumb's reaction.
    public var quality: Double
    /// Activity-specific count: snacks caught, tug pulls won, guesses needed.
    public var score: Int
    public var won: Bool

    public init(kind: ActivityKind, quality: Double, score: Int, won: Bool) {
        self.kind = kind
        self.quality = min(1, max(0, quality))
        self.score = score
        self.won = won
    }
}

public struct Counters: Codable, Equatable, Sendable {
    public var feeds = 0
    public var pets = 0
    public var naps = 0
    public var rounds: [String: Int] = [:]
    public var wins: [String: Int] = [:]
    public var mischiefResolved = 0
    public var visitDays = 0
    public var lastVisitDay: String?
    /// Care XP earned on `careXPDay`; capped daily so tapping cannot grind levels.
    public var careXP = 0
    public var careXPDay: String?
    /// Activity kinds finished on `playedDay` (for the "play all three" challenge).
    public var playedKinds: [String] = []
    public var playedDay: String?

    public init() {}

    public func rounds(_ kind: ActivityKind) -> Int { rounds[kind.rawValue] ?? 0 }
    public func wins(_ kind: ActivityKind) -> Int { wins[kind.rawValue] ?? 0 }
}

public struct Wardrobe: Codable, Equatable, Sendable {
    /// Free items earned in play (level or weekly gifts). Paid items come from entitlements.
    public var earned: Set<String> = []
    public var hat: String?
    public var neck: String?
    public var theme: String = Catalog.defaultTheme
    public var sock: String = Catalog.defaultSock

    public init() {}

    public func equipped(_ slot: Slot) -> String? {
        switch slot {
        case .hat: return hat
        case .neck: return neck
        case .theme: return theme
        case .sock: return sock
        }
    }

    public mutating func equip(_ id: String?, in slot: Slot) {
        switch slot {
        case .hat: hat = id
        case .neck: neck = id
        case .theme: theme = id ?? Catalog.defaultTheme
        case .sock: sock = id ?? Catalog.defaultSock
        }
    }
}

public struct StampCard: Codable, Equatable, Sendable {
    public var weekKey: String = ""
    /// Day keys stamped this week. Gold means the daily challenge was done that day.
    public var days: [String] = []
    public var goldDays: [String] = []

    public init() {}
}

public struct ChallengeProgress: Codable, Equatable, Sendable {
    public var dayKey: String = ""
    public var progress = 0
    public var completed = false

    public init() {}
}

public struct MischiefState: Codable, Equatable, Sendable {
    public var nextAt: Date?
    public var recent: [String] = []

    public init() {}
}

public struct Preferences: Codable, Equatable, Sendable {
    public var sound = true
    public var haptics = true
    public var remindersEnabled = false
    /// Whether the soft in-app reminder offer has been shown. It is shown once.
    public var reminderOfferShown = false
    public var reminderHour = 18
    public var reminderMinute = 30

    public init() {}
}

/// Everything that persists. Decoding tolerates missing keys so older saves load.
public struct PetState: Codable, Equatable, Sendable {
    public var name: String
    public var createdAt: Date
    public var lastSimulated: Date
    public var needs: Needs
    public var napStartedAt: Date?
    /// Set when a nap ended on its own while the player was away, so the app can play the wake.
    public var pendingWake = false
    public var xp: Int
    public var discoveries: Set<String>
    /// -1 sweet … +1 menace. Nudged by mischief choices.
    public var personality: Double
    public var mischief: MischiefState
    public var stamps: StampCard
    public var challenge: ChallengeProgress
    /// Ledger of one-time grants ("challenge:2026-09-24", "week:2026-W39:gift"). Prevents double rewards.
    public var granted: Set<String>
    public var wardrobe: Wardrobe
    public var counters: Counters
    public var prefs: Preferences

    /// In-memory only.
    public var session: ActivitySession?

    public init(now: Date) {
        name = "Crumb"
        createdAt = now
        lastSimulated = now
        needs = .fresh
        napStartedAt = nil
        xp = 0
        discoveries = []
        personality = 0
        mischief = MischiefState()
        mischief.nextAt = now.addingTimeInterval(Tuning.firstMischiefDelay)
        stamps = StampCard()
        challenge = ChallengeProgress()
        granted = []
        wardrobe = Wardrobe()
        counters = Counters()
        prefs = Preferences()
        session = nil
    }

    public var isAsleep: Bool { napStartedAt != nil }
    public var level: Int { Tuning.level(forXP: xp) }

    enum CodingKeys: String, CodingKey {
        case name, createdAt, lastSimulated, needs, napStartedAt, pendingWake, xp, discoveries,
             personality, mischief, stamps, challenge, granted, wardrobe, counters, prefs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Only the clock anchor is required; everything else falls back to a fresh default.
        let anchor = try c.decode(Date.self, forKey: .lastSimulated)
        self.init(now: anchor)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? name
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? anchor
        needs = try c.decodeIfPresent(Needs.self, forKey: .needs) ?? needs
        needs.clamp()
        napStartedAt = try c.decodeIfPresent(Date.self, forKey: .napStartedAt)
        pendingWake = try c.decodeIfPresent(Bool.self, forKey: .pendingWake) ?? false
        xp = max(0, try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0)
        discoveries = try c.decodeIfPresent(Set<String>.self, forKey: .discoveries) ?? []
        personality = min(1, max(-1, try c.decodeIfPresent(Double.self, forKey: .personality) ?? 0))
        mischief = try c.decodeIfPresent(MischiefState.self, forKey: .mischief) ?? mischief
        stamps = try c.decodeIfPresent(StampCard.self, forKey: .stamps) ?? StampCard()
        challenge = try c.decodeIfPresent(ChallengeProgress.self, forKey: .challenge) ?? ChallengeProgress()
        granted = try c.decodeIfPresent(Set<String>.self, forKey: .granted) ?? []
        wardrobe = try c.decodeIfPresent(Wardrobe.self, forKey: .wardrobe) ?? Wardrobe()
        counters = try c.decodeIfPresent(Counters.self, forKey: .counters) ?? Counters()
        prefs = try c.decodeIfPresent(Preferences.self, forKey: .prefs) ?? Preferences()
    }
}
