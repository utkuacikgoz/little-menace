import Foundation

public enum ChallengeKind: String, CaseIterable, Sendable {
    case catchSix, winTug, firstTryFind, petEight, restfulNap, playAllThree

    public var target: Int {
        switch self {
        case .catchSix: return 6
        case .petEight: return 8
        case .playAllThree: return 3
        case .winTug, .firstTryFind, .restfulNap: return 1
        }
    }

    /// SF Symbol shown on the stamp card. The challenge is communicated by icon, not copy.
    public var symbol: String {
        switch self {
        case .catchSix: return "fork.knife"
        case .winTug: return "hand.draw"
        case .firstTryFind: return "eye"
        case .petEight: return "hand.raised"
        case .restfulNap: return "moon.zzz"
        case .playAllThree: return "die.face.3"
        }
    }

    /// Short VoiceOver description.
    public var spoken: String {
        switch self {
        case .catchSix: return "Catch six snacks in one toss"
        case .winTug: return "Win a sock tug"
        case .firstTryFind: return "Find the gremlin on the first try"
        case .petEight: return "Give eight pets"
        case .restfulNap: return "Let it have a proper nap"
        case .playAllThree: return "Play three different games"
        }
    }

    public static func forDay(_ dayKey: String) -> ChallengeKind {
        let all = allCases
        return all[Int(stableHash("challenge:" + dayKey) % UInt64(all.count))]
    }
}

public enum Discovery: String, CaseIterable, Sendable {
    case firstBite, firstNap, firstTugWin, perfectToss, firstTryFind, nightOwl
    case menace, softie, fullCard, regular

    public var symbol: String {
        switch self {
        case .firstBite: return "fork.knife"
        case .firstNap: return "moon.zzz.fill"
        case .firstTugWin: return "hand.draw.fill"
        case .perfectToss: return "star.fill"
        case .firstTryFind: return "eye.fill"
        case .nightOwl: return "moon.stars.fill"
        case .menace: return "flame.fill"
        case .softie: return "heart.fill"
        case .fullCard: return "seal.fill"
        case .regular: return "house.fill"
        }
    }

    public var spoken: String {
        switch self {
        case .firstBite: return "First snack"
        case .firstNap: return "First nap"
        case .firstTugWin: return "Won a sock tug"
        case .perfectToss: return "Perfect snack toss"
        case .firstTryFind: return "Found it on the first try"
        case .nightOwl: return "Played after midnight"
        case .menace: return "Turned properly menacing"
        case .softie: return "Turned soft"
        case .fullCard: return "Seven stamps in a week"
        case .regular: return "Visited on five days"
        }
    }

    /// How to earn it, shown when a locked one is tapped.
    public var hint: String {
        switch self {
        case .firstBite: return "Feed it a snack."
        case .firstNap: return "Let it nap for 5 minutes."
        case .firstTugWin: return "Win a sock tug."
        case .perfectToss: return "Catch all 8 snacks in a toss."
        case .firstTryFind: return "Find it on your first guess."
        case .nightOwl: return "Play a round after midnight."
        case .menace: return "Let its mischief happen. Often."
        case .softie: return "Stop its mischief. Often."
        case .fullCard: return "Get a stamp all 7 days of a week."
        case .regular: return "Visit on 5 different days."
        }
    }

    /// A nudge in its own voice for one not found yet: enough to chase, not the answer.
    public var teaser: String {
        switch self {
        case .firstBite: return "Something about snacks…"
        case .firstNap: return "It’s tired of you. Let it be."
        case .firstTugWin: return "It won’t let go of something."
        case .perfectToss: return "Eight for eight."
        case .firstTryFind: return "One guess. That’s all."
        case .nightOwl: return "Past its bedtime. And yours."
        case .menace: return "What if you just… let it?"
        case .softie: return "What if you always said no?"
        case .fullCard: return "Every day. All week."
        case .regular: return "Keep coming back."
        }
    }
}

public enum GameEvent: Equatable, Sendable {
    case xp(Int)
    /// Points changed (negative for a loss).
    case points(Int, PointReason)
    case levelUp(Int)
    case unlocked(String)
    case discovery(Discovery)
    case challengeComplete(ChallengeKind)
    case stamp(gold: Bool)
    case stampBonus
    case weeklyGift(String)
    case autoWoke
}
